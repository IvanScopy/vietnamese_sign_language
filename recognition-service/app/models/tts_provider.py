"""
TTS Provider Abstraction

Provides a common interface for text-to-speech providers (Piper, eSpeak-ng)
with fallback support. Audio output is WAV format, 22050Hz, mono PCM.
"""
from abc import ABC, abstractmethod
from typing import Protocol, runtime_checkable
import subprocess
import struct
import os

@runtime_checkable
class TTSProvider(Protocol):
    """Protocol defining the interface for TTS providers."""
    def synthesize(self, text: str, voice: str = None, speed: float = 1.0) -> bytes:
        """Synthesize text to audio bytes (WAV format).
        
        Args:
            text: The text to synthesize (Vietnamese)
            voice: Optional voice identifier overrides provider default
            speed: Speech rate multiplier (0.8-1.2 typical)
            
        Returns:
            bytes: WAV formatted audio data (22050Hz, mono, 16-bit PCM)
            
        Raises:
            TTSError: If synthesis fails
        """
        ...


class TTSError(Exception):
    """Raised when TTS synthesis fails."""
    pass


class PiperTTS:
    """Piper TTS provider using piper CLI."""
    DEFAULT_VOICE = 'vivos'
    SAMPLE_RATE = 22050

    def __init__(self, voice: str = None):
        self.voice = voice or os.getenv('PIPER_VOICE', self.DEFAULT_VOICE)
        self.sample_rate = self.SAMPLE_RATE

    def synthesize(self, text: str, voice: str = None, speed: float = 1.0) -> bytes:
        """Synthesize text using Piper TTS.
        
        Piper outputs raw PCM; we wrap it in a WAV header.
        """
        voice = voice or self.voice
        # Piper CLI: --output_raw writes raw PCM to stdout
        cmd = [
            'piper', '--model', f'/usr/share/piper-voices/{voice}/model.onnx',
            '--output_raw'
        ]
        
        # Speed adjustment via length-scale (inverse): shorter = faster
        if speed != 1.0:
            # Piper uses --length_scale, where <1 is faster, >1 is slower
            length_scale = 1.0 / speed
            cmd.extend(['--length_scale', str(length_scale)])
        
        try:
            proc = subprocess.run(
                cmd,
                input=text.encode('utf-8'),
                capture_output=True,
                timeout=5
            )
        except subprocess.TimeoutExpired:
            raise TTSError('Piper synthesis timeout')
        except FileNotFoundError:
            raise TTSError('Piper binary not found (install piper-tts)')
        
        if proc.returncode != 0:
            error_msg = proc.stderr.decode('utf-8', errors='ignore') if proc.stderr else 'Unknown error'
            raise TTSError(f'Piper failed (exit {proc.returncode}): {error_msg}')
        
        # Convert raw PCM to WAV
        return self._pcm_to_wav(proc.stdout, self.sample_rate)

    def _pcm_to_wav(self, pcm: bytes, sample_rate: int) -> bytes:
        """Wrap raw PCM data in a WAV header."""
        num_channels = 1
        bits_per_sample = 16
        byte_rate = sample_rate * num_channels * bits_per_sample // 8
        block_align = num_channels * bits_per_sample // 8
        data_size = len(pcm)
        file_size = 36 + data_size

        # WAV header (little-endian)
        header = struct.pack(
            '<4sI4s4sIHHIIHH4sI',
            b'RIFF',           # ChunkID
            file_size,         # ChunkSize
            b'WAVE',           # Format
            b'fmt ',           # Subchunk1ID
            16,                # Subchunk1Size (16 for PCM)
            1,                 # AudioFormat (1 = PCM)
            num_channels,      # NumChannels
            sample_rate,       # SampleRate
            byte_rate,         # ByteRate
            block_align,       # BlockAlign
            bits_per_sample * num_channels,  # BitsPerSample
            b'data',           # Subchunk2ID
            data_size          # Subchunk2Size
        )
        return header + pcm


class EspeakTTS:
    """eSpeak-ng fallback provider."""
    DEFAULT_VOICE = 'vi'
    SAMPLE_RATE = 22050

    def __init__(self, voice: str = None):
        self.voice = voice or os.getenv('ESPEAK_VOICE', self.DEFAULT_VOICE)
        self.sample_rate = self.SAMPLE_RATE

    def synthesize(self, text: str, voice: str = None, speed: float = 1.0) -> bytes:
        """Synthesize text using eSpeak-ng.
        
        eSpeak-ng can output WAV directly with --wav flag.
        """
        voice = voice or self.voice
        
        # eSpeak-ng speed: words per minute. Default ~175. Convert speed multiplier.
        # 1.0 = default speed, 0.8 = slower (140 wpm), 1.2 = faster (210 wpm)
        default_wpm = 175
        wpm = int(default_wpm * speed)
        
        cmd = [
            'espeak-ng',
            '-v', voice,
            '--stdout',
            '--wav',
            '-s', str(wpm),
            text
        ]
        
        try:
            proc = subprocess.run(cmd, capture_output=True, timeout=5)
        except subprocess.TimeoutExpired:
            raise TTSError('eSpeak synthesis timeout')
        except FileNotFoundError:
            raise TTSError('eSpeak-ng binary not found (install espeak-ng)')
        
        if proc.returncode != 0:
            error_msg = proc.stderr.decode('utf-8', errors='ignore') if proc.stderr else 'Unknown error'
            raise TTSError(f'eSpeak failed (exit {proc.returncode}): {error_msg}')
        
        # eSpeak outputs WAV directly, but ensure it's at expected sample rate
        # eSpeak default is typically 22050Hz which matches our requirement
        return proc.stdout
