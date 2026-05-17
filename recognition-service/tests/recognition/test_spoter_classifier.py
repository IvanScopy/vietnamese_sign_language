"""Tests for the trained SPOTER classifier adapter."""

from pathlib import Path

import numpy as np
import pytest

from app.models.spoter_classifier import SPOTERClassifier


MODEL_PATH = Path(__file__).resolve().parents[3] / 'demo_model' / 'best_epoch_8'
LABELS_PATH = Path(__file__).resolve().parents[3] / 'demo_model' / 'gloss.csv'
SAMPLE_POSE_PATH = Path(__file__).resolve().parents[3] / 'demo_model' / 'sample_poses' / 'Gạo__018856.pose'


@pytest.mark.skipif(not MODEL_PATH.exists(), reason='demo SPOTER model is not present')
def test_spoter_classifier_predicts_label_from_holistic_window():
    classifier = SPOTERClassifier(model_path=MODEL_PATH, labels_path=LABELS_PATH, device='cpu')
    window = np.zeros((classifier.window_size, classifier.feature_count), dtype=np.float32)

    result = classifier.predict(window)

    assert classifier.window_size == 70
    assert classifier.num_points == 54
    assert result['sign'] in classifier.vocabulary
    assert 0.0 <= result['confidence'] <= 1.0


@pytest.mark.skipif(
    not MODEL_PATH.exists() or not SAMPLE_POSE_PATH.exists(),
    reason='demo SPOTER model or sample poses are not present',
)
def test_spoter_classifier_matches_training_pose_format_sample():
    pose_format = pytest.importorskip('pose_format')
    classifier = SPOTERClassifier(model_path=MODEL_PATH, labels_path=LABELS_PATH, device='cpu')
    pose = pose_format.Pose.read(SAMPLE_POSE_PATH.read_bytes())
    data = pose.body.data[:, 0, :, :3]
    window = np.zeros((data.shape[0], classifier.feature_count), dtype=np.float32)
    window[:, :99] = data[:, :33, :3].reshape(data.shape[0], 99)
    window[:, 99:162] = data[:, 501:522, :3].reshape(data.shape[0], 63)
    window[:, 162:225] = data[:, 522:543, :3].reshape(data.shape[0], 63)

    result = classifier.predict(window)

    assert result['sign'] == 'Gạo'
    assert result['confidence'] > 0.9
