"""
Recognition-related Pydantic schemas.
"""
from pydantic import BaseModel, field_validator
from typing import List, Optional, Dict, Any


class RecognitionResult(BaseModel):
    """Result of a single sign recognition."""
    sign: str
    confidence: float

    @field_validator('confidence')
    @classmethod
    def check_confidence_range(cls, v):
        if not 0.0 <= v <= 1.0:
            raise ValueError('Confidence must be between 0.0 and 1.0')
        return v


class PhraseComplete(BaseModel):
    """Event sent when a phrase is complete and ready for TTS."""
    text: str
    signs: List[RecognitionResult]
    audio: Optional[str] = None  # Base64 encoded WAV audio

    def has_audio(self) -> bool:
        """Check if this event includes audio data."""
        return self.audio is not None and len(self.audio) > 0


class TTSErrorResponse(BaseModel):
    """Error response when TTS fails."""
    provider: str
    message: str
    fallbackAttempted: Optional[bool] = False
