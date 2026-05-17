"""Unit tests for EspeakTTS provider."""
import pytest
import subprocess
from unittest.mock import patch, MagicMock
from app.models.tts_provider import EspeakTTS, TTSError


class TestEspeakTTS:
    """Test suite for eSpeak-ng TTS provider."""

    def test_synthesize_returns_wav_bytes(self):
        """EspeakTTS.synthesize() returns WAV bytes."""
        provider = EspeakTTS(voice='vi')

        # eSpeak outputs WAV directly
        fake_wav = b'RIFF\x00\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00' + b'\x00' * 100
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = fake_wav
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result):
            audio = provider.synthesize('xin chào')

        assert isinstance(audio, bytes)
        assert audio.startswith(b'RIFF')

    def test_synthesize_with_custom_voice(self):
        """EspeakTTS respects custom voice parameter."""
        provider = EspeakTTS(voice='vi')

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = b'RIFFfake wav data'
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result) as mock_run:
            provider.synthesize('hello', voice='vi-vn')

            call_args = mock_run.call_args[0][0]
            assert 'vi-vn' in call_args

    def test_synthesize_with_speed(self):
        """EspeakTTS includes -s flag with adjusted WPM."""
        provider = EspeakTTS()

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = b'RIFFdata'
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result) as mock_run:
            provider.synthesize('test', speed=1.2)  # 20% faster

            call_args = mock_run.call_args[0][0]
            assert '-s' in call_args
            s_idx = call_args.index('-s')
            # 175 wpm * 1.2 = 210 wpm
            assert call_args[s_idx + 1] == '210'

    def test_synthesize_timeout_raises_error(self):
        """EspeakTTS raises TTSError on subprocess timeout."""
        provider = EspeakTTS()

        with patch('subprocess.run', side_effect=subprocess.TimeoutExpired('espeak-ng', 5)):
            with pytest.raises(TTSError) as exc_info:
                provider.synthesize('test')
            assert 'timeout' in str(exc_info.value).lower()

    def test_synthesize_failure_raises_error(self):
        """EspeakTTS raises TTSError when subprocess returns non-zero."""
        provider = EspeakTTS()

        mock_result = MagicMock()
        mock_result.returncode = 1
        mock_result.stderr = b'Voice not found'

        with patch('subprocess.run', return_value=mock_result):
            with pytest.raises(TTSError) as exc_info:
                provider.synthesize('test')
            assert 'eSpeak failed' in str(exc_info.value)

    def test_default_voice_from_env(self):
        """EspeakTTS reads ESPEAK_VOICE from environment."""
        import os
        os.environ['ESPEAK_VOICE'] = 'en-us'
        try:
            provider = EspeakTTS()
            assert provider.voice == 'en-us'
        finally:
            os.environ.pop('ESPEAK_VOICE', None)

    def test_output_is_valid_wav(self):
        """Returned audio has valid WAV header structure."""
        provider = EspeakTTS()

        # Create a minimal valid WAV header
        mock_wav = self._create_minimal_wav(22050, 1, 200)
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = mock_wav
        mock_result.stderr = b''

        with patch('subprocess.run', return_value=mock_result):
            audio = provider.synthesize('test')

        # Verify WAV header basics
        assert audio[:4] == b'RIFF'
        assert b'WAVE' in audio[:12]
        assert b'fmt ' in audio[:20]
        assert b'data' in audio[:44]

    def _create_minimal_wav(self, sample_rate: int, channels: int, data_len: int) -> bytes:
        """Helper to create a minimal WAV file header + data."""
        import struct
        bits_per_sample = 16
        byte_rate = sample_rate * channels * bits_per_sample // 8
        block_align = channels * bits_per_sample // 8
        file_size = 36 + data_len

        header = struct.pack(
            '<4sI4s4sIHHIIHH4sI',
            b'RIFF',
            file_size,
            b'WAVE',
            b'fmt ',
            16,
            1,  # PCM
            channels,
            sample_rate,
            byte_rate,
            block_align,
            bits_per_sample * channels,
            b'data',
            data_len
        )
        return header + b'\x00' * data_len
