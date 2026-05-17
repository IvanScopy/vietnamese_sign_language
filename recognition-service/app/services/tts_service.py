"""
TTS Service Layer

Provides a high-level TTS interface with provider fallback chain.
Primary provider is tried first; on failure, fallback provider is used.
"""
import os
import base64
from typing import Optional
from app.models.tts_provider import TTSProvider, PiperTTS, EspeakTTS, TTSError


class TTSService:
    """
    Service layer for text-to-speech synthesis with fallback support.

    Configurable via environment variables:
    - TTS_PROVIDER: Primary provider name ('piper' or 'espeak'), default 'piper'
    - PIPER_VOICE: Piper voice model name, default 'vivos'
    - ESPEAK_VOICE: eSpeak voice, default 'vi'
    """

    def __init__(self, primary: str = None, fallback: str = 'espeak'):
        """
        Initialize TTS service with provider configuration.

        Args:
            primary: Primary provider name ('piper' or 'espeak').
                     Defaults to TTS_PROVIDER env var or 'piper'.
            fallback: Fallback provider name. Default 'espeak'.
        """
        primary = primary or os.getenv('TTS_PROVIDER', 'piper')
        self.primary_provider = self._create_provider(primary)

        # Only create fallback if different from primary
        if primary != fallback:
            self.fallback_provider = self._create_provider(fallback)
        else:
            self.fallback_provider = None

    def _create_provider(self, name: str) -> TTSProvider:
        """Create a TTS provider instance by name."""
        if name == 'piper':
            voice = os.getenv('PIPER_VOICE', 'vivos')
            return PiperTTS(voice=voice)
        elif name == 'espeak':
            voice = os.getenv('ESPEAK_VOICE', 'vi')
            return EspeakTTS(voice=voice)
        else:
            raise ValueError(f'Unknown TTS provider: {name}')

    def synthesize(self, text: str, voice: str = None, speed: float = 1.0) -> bytes:
        """
        Synthesize text to WAV audio bytes.

        Attempts primary provider first, falls back on error.

        Args:
            text: Vietnamese text to synthesize
            voice: Optional voice override (provider-specific)
            speed: Speech rate multiplier (0.8-1.2)

        Returns:
            bytes: WAV audio data (22050Hz, mono, 16-bit PCM)

        Raises:
            TTSError: If both primary and fallback providers fail
        """
        try:
            return self.primary_provider.synthesize(text, voice=voice, speed=speed)
        except TTSError as e:
            if self.fallback_provider:
                try:
                    return self.fallback_provider.synthesize(text, voice=voice, speed=speed)
                except TTSError as fallback_e:
                    raise TTSError(f'Both providers failed: primary={e}, fallback={fallback_e}')
            raise

    def synthesize_to_base64(self, text: str, voice: str = None, speed: float = 1.0) -> str:
        """
        Synthesize text and return base64-encoded WAV audio.

        Args:
            text: Vietnamese text to synthesize
            voice: Optional voice override
            speed: Speech rate multiplier

        Returns:
            str: Base64 encoded WAV audio (without data: prefix)
        """
        audio = self.synthesize(text, voice, speed)
        return base64.b64encode(audio).decode('utf-8')


# Global singleton instance for use throughout the application
tts_service = TTSService()
