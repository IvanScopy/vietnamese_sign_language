"""Integration tests for TTSService with fallback chain."""
import pytest
from unittest.mock import patch, MagicMock
from app.services.tts_service import TTSService, TTSError
from app.models.tts_provider import PiperTTS, EspeakTTS


class TestTTSService:
    """Test suite for TTS service with fallback."""

    def test_primary_provider_succeeds(self):
        """TTSService returns audio from primary provider when available."""
        service = TTSService(primary='piper', fallback='espeak')

        fake_audio = b'RIFFfake_wav_data_primary'
        with patch.object(PiperTTS, 'synthesize', return_value=fake_audio) as mock_piper:
            result = service.synthesize('hello')
            assert result == fake_audio
            mock_piper.assert_called_once()

    def test_primary_fails_fallback_succeeds(self):
        """TTSService falls back to secondary when primary fails."""
        service = TTSService(primary='piper', fallback='espeak')

        fake_audio = b'RIFFfake_wav_data_fallback'
        with patch.object(PiperTTS, 'synthesize', side_effect=TTSError('Piper down')):
            with patch.object(EspeakTTS, 'synthesize', return_value=fake_audio) as mock_espeak:
                result = service.synthesize('hello')
                assert result == fake_audio
                mock_espeak.assert_called_once()

    def test_both_providers_fail_raises_error(self):
        """TTSService raises combined error when both fail."""
        service = TTSService(primary='piper', fallback='espeak')

        with patch.object(PiperTTS, 'synthesize', side_effect=TTSError('Piper error')):
            with patch.object(EspeakTTS, 'synthesize', side_effect=TTSError('eSpeak error')):
                with pytest.raises(TTSError) as exc_info:
                    service.synthesize('hello')
                assert 'Both providers failed' in str(exc_info.value)
                assert 'Piper error' in str(exc_info.value)
                assert 'eSpeak error' in str(exc_info.value)

    def test_no_fallback_raises_primary_error(self):
        """TTSService without fallback raises primary error directly."""
        # Same primary and fallback means no fallback
        service = TTSService(primary='piper', fallback='piper')

        with patch.object(PiperTTS, 'synthesize', side_effect=TTSError('Piper error')):
            with pytest.raises(TTSError) as exc_info:
                service.synthesize('hello')
            # Should not mention fallback
            assert 'fallback' not in str(exc_info.value).lower()

    def test_synthesize_to_base64_returns_string(self):
        """TTSService.synthesize_to_base64() returns base64 string."""
        service = TTSService(primary='piper', fallback='espeak')

        fake_audio = b'RIFF\x00\x00wav_data'
        with patch.object(PiperTTS, 'synthesize', return_value=fake_audio):
            result = service.synthesize_to_base64('hello')
            assert isinstance(result, str)
            # Base64 encoded string should be decodable
            import base64
            decoded = base64.b64decode(result)
            assert decoded == fake_audio

    def test_environment_variable_provider_selection(self):
        """TTS_PROVIDER env var selects primary provider."""
        import os
        os.environ['TTS_PROVIDER'] = 'espeak'
        try:
            service = TTSService()
            assert isinstance(service.primary_provider, EspeakTTS)
        finally:
            os.environ.pop('TTS_PROVIDER', None)

    def test_piper_voice_from_environment(self):
        """PIPER_VOICE env var sets Piper voice."""
        import os
        os.environ['PIPER_VOICE'] = 'vais1000'
        try:
            service = TTSService(primary='piper')
            assert service.primary_provider.voice == 'vais1000'
        finally:
            os.environ.pop('PIPER_VOICE', None)

    def test_espeak_voice_from_environment(self):
        """ESPEAK_VOICE env var sets eSpeak voice."""
        import os
        os.environ['ESPEAK_VOICE'] = 'en-us'
        try:
            service = TTSService(primary='espeak')
            assert service.primary_provider.voice == 'en-us'
        finally:
            os.environ.pop('ESPEAK_VOICE', None)

    def test_voice_override_in_synthesize(self):
        """voice parameter overrides provider default."""
        service = TTSService(primary='piper')

        with patch.object(PiperTTS, 'synthesize', return_value=b'RIFFdata') as mock:
            service.synthesize('hello', voice='custom_voice')
            mock.assert_called_once_with('hello', voice='custom_voice', speed=1.0)

    def test_speed_parameter_passed_to_provider(self):
        """speed parameter is passed to provider."""
        service = TTSService(primary='piper')

        with patch.object(PiperTTS, 'synthesize', return_value=b'RIFFdata') as mock:
            service.synthesize('hello', speed=0.8)
            mock.assert_called_once_with('hello', voice=None, speed=0.8)
