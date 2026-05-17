"""Unit tests for PiperTTS provider."""
import pytest
import struct
import subprocess
from unittest.mock import patch, MagicMock
from app.models.tts_provider import PiperTTS, TTSError


class TestPiperTTS:
    """Test suite for Piper TTS provider."""

    def test_synthesize_returns_wav_bytes(self):
        """PiperTTS.synthesize() returns bytes starting with WAV header 'RIFF'."""
        provider = PiperTTS(voice='vivos')

        # Mock subprocess.run to return fake PCM data
        fake_pcm = b'\x00\x01' * 1000  # 2000 bytes of PCM data
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = fake_pcm
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result):
            audio = provider.synthesize('xin chào')

        # Should return WAV with RIFF header
        assert isinstance(audio, bytes)
        assert audio.startswith(b'RIFF'), "Output should be WAV format with RIFF header"
        # WAV header includes 'WAVE' fmt chunk
        assert b'WAVE' in audio[:44]

    def test_synthesize_with_custom_voice(self):
        """PiperTTS respects custom voice parameter."""
        provider = PiperTTS(voice='default')

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = b'\x00\x01' * 100
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result) as mock_run:
            provider.synthesize('hello', voice='vais1000')

            # Check the command includes the custom voice model path
            call_args = mock_run.call_args[0][0]
            assert 'vais1000' in ' '.join(call_args)

    def test_synthesize_timeout_raises_error(self):
        """PiperTTS raises TTSError on subprocess timeout."""
        provider = PiperTTS()

        with patch('subprocess.run', side_effect=subprocess.TimeoutExpired('piper', 5)):
            with pytest.raises(TTSError) as exc_info:
                provider.synthesize('test')
            assert 'timeout' in str(exc_info.value).lower()

    def test_synthesize_failure_raises_error(self):
        """PiperTTS raises TTSError when subprocess returns non-zero."""
        provider = PiperTTS()

        mock_result = MagicMock()
        mock_result.returncode = 1
        mock_result.stderr = b'Model not found'

        with patch('subprocess.run', return_value=mock_result):
            with pytest.raises(TTSError) as exc_info:
                provider.synthesize('test')
            assert 'Piper failed' in str(exc_info.value)

    def test_synthesize_with_speed(self):
        """PiperTTS includes length_scale flag when speed != 1.0."""
        provider = PiperTTS()

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = b'\x00\x01' * 100
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result) as mock_run:
            provider.synthesize('test', speed=0.8)  # faster

            call_args = mock_run.call_args[0][0]
            # Speed 0.8 -> length_scale = 1/0.8 = 1.25
            assert '--length_scale' in call_args
            idx = call_args.index('--length_scale')
            assert call_args[idx + 1] == '1.25'

    def test_wav_header_correct_format(self):
        """WAV header has correct sample rate and format specifications."""
        provider = PiperTTS()

        fake_pcm = b'\x00\x01' * 1000
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = fake_pcm
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result):
            audio = provider.synthesize('test')

        # Parse WAV header (first 44 bytes)
        header = audio[:44]
        # Unpack and verify key fields
        unpacked = struct.unpack('<4sI4s4sIHHIIHH4sI', header)
        chunk_id = unpacked[0]
        wave_identifier = unpacked[2]
        fmt_chunk_id = unpacked[3]
        audio_format = unpacked[5]
        num_channels = unpacked[6]
        sample_rate = unpacked[7]
        bits_per_sample = unpacked[10]
        subchunk2_id = unpacked[11]
        subchunk2_size = unpacked[12]

        assert chunk_id == b'RIFF'
        assert wave_identifier == b'WAVE'
        assert fmt_chunk_id == b'fmt '
        assert audio_format == 1  # PCM
        assert num_channels == 1  # Mono
        assert sample_rate == 22050
        assert bits_per_sample == 16
        assert subchunk2_id == b'data'
        assert subchunk2_size == len(fake_pcm)
