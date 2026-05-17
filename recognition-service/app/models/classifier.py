"""
Classifier factory for sign recognition.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any, Optional

from app.models.mock_lstm import MockLSTM
from app.models.spoter_classifier import DEFAULT_MODEL_PATH, SPOTERClassifier


logger = logging.getLogger(__name__)


def create_classifier(window_size: Optional[int] = 30) -> Any:
    """
    Create the configured classifier.

    Configuration:
    - RECOGNITION_CLASSIFIER=mock|spoter|auto
    - RECOGNITION_MODEL_PATH=path/to/best_epoch
    - RECOGNITION_LABELS_PATH=path/to/gloss.csv
    - RECOGNITION_MODEL_FALLBACK=true|false
    """
    classifier_env = os.getenv('RECOGNITION_CLASSIFIER')
    model_path_env = os.getenv('RECOGNITION_MODEL_PATH')
    explicit_model = bool(classifier_env or model_path_env)
    classifier_name = (classifier_env or _auto_classifier_name()).strip().lower()

    if classifier_name in {'spoter', 'real'}:
        try:
            return SPOTERClassifier(
                model_path=model_path_env,
                labels_path=os.getenv('RECOGNITION_LABELS_PATH'),
                device=os.getenv('RECOGNITION_MODEL_DEVICE') or None,
            )
        except Exception:
            if _should_fallback_to_mock(explicit_model):
                logger.exception('Failed to load SPOTER classifier; falling back to MockLSTM')
                return MockLSTM(expected_window_size=window_size or 30)
            raise

    if classifier_name not in {'mock', 'mock_lstm'}:
        raise ValueError(f'Unknown RECOGNITION_CLASSIFIER: {classifier_name}')

    return MockLSTM(expected_window_size=window_size or 30)


def _auto_classifier_name() -> str:
    return 'spoter' if Path(DEFAULT_MODEL_PATH).exists() else 'mock'


def _should_fallback_to_mock(explicit_model: bool) -> bool:
    configured = os.getenv('RECOGNITION_MODEL_FALLBACK')
    if configured is not None:
        return configured.lower() in {'1', 'true', 'yes', 'mock'}
    return not explicit_model
