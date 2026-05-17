"""
SPOTER classifier adapter for the trained VSL graph model.

The checkpoint in demo_model/best_epoch_8 expects 70 frames of 54 2D points.
The live mobile pipeline sends MediaPipe pose + hand landmarks instead:
33 pose landmarks + 21 left-hand + 21 right-hand landmarks, with 3 coordinates
each. This adapter owns the same joint selection, normalization, and shifting
used by the training transform.
"""

from __future__ import annotations

import csv
import importlib.util
import sys
import types
import warnings
from pathlib import Path
from typing import Any, Dict, List, Optional

import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_MODEL_PATH = REPO_ROOT / 'demo_model' / 'best_epoch_8'
DEFAULT_LABELS_PATH = REPO_ROOT / 'demo_model' / 'gloss.csv'

# Match src/features/transforms/spoter.py from the training project.
POSE_POINT_INDICES = (
    0,       # NOSE
    None,    # NECK: training transform emits zeros for MediaPipe pose input
    5,       # RIGHT_EYE
    2,       # LEFT_EYE
    8,       # RIGHT_EAR
    7,       # LEFT_EAR
    12,      # RIGHT_SHOULDER
    11,      # LEFT_SHOULDER
    14,      # RIGHT_ELBOW
    13,      # LEFT_ELBOW
    16,      # RIGHT_WRIST
    15,      # LEFT_WRIST
)

HAND_POINT_INDICES = (
    0,   # WRIST
    8,   # INDEX_FINGER_TIP
    7,   # INDEX_FINGER_DIP
    6,   # INDEX_FINGER_PIP
    5,   # INDEX_FINGER_MCP
    12,  # MIDDLE_FINGER_TIP
    11,  # MIDDLE_FINGER_DIP
    10,  # MIDDLE_FINGER_PIP
    9,   # MIDDLE_FINGER_MCP
    16,  # RING_FINGER_TIP
    15,  # RING_FINGER_DIP
    14,  # RING_FINGER_PIP
    13,  # RING_FINGER_MCP
    19,  # PINKY_DIP
    20,  # PINKY_TIP
    18,  # PINKY_PIP
    17,  # PINKY_MCP
    4,   # THUMB_TIP
    3,   # THUMB_IP
    2,   # THUMB_MCP
    1,   # THUMB_CMC
)

BODY_POINT_COUNT = 12
HAND_POINT_COUNT = 21
POSE_LANDMARK_COUNT = 33
LEGACY_POSE_LANDMARK_COUNT = 25
BODY_LANDMARK_NAMES = (
    'nose',
    'neck',
    'rightEye',
    'leftEye',
    'rightEar',
    'leftEar',
    'rightShoulder',
    'leftShoulder',
    'rightElbow',
    'leftElbow',
    'rightWrist',
    'leftWrist',
)
HAND_LANDMARK_NAMES = (
    'wrist',
    'indexTip',
    'indexDIP',
    'indexPIP',
    'indexMCP',
    'middleTip',
    'middleDIP',
    'middlePIP',
    'middleMCP',
    'ringTip',
    'ringDIP',
    'ringPIP',
    'ringMCP',
    'littleTip',
    'littleDIP',
    'littlePIP',
    'littleMCP',
    'thumbTip',
    'thumbIP',
    'thumbMP',
    'thumbCMC',
)
HAND_LANDMARK_KEYS = tuple(
    f'{landmark}_{suffix}'
    for landmark in HAND_LANDMARK_NAMES
    for suffix in ('0', '1')
)
LANDMARK_KEYS = BODY_LANDMARK_NAMES + HAND_LANDMARK_KEYS


class SPOTERClassifier:
    """Run inference with the trained SPOTER graph classifier."""

    model_name = 'spoter'
    feature_count = 225
    legacy_feature_count = 201

    def __init__(
        self,
        model_path: Optional[str | Path] = None,
        labels_path: Optional[str | Path] = None,
        device: Optional[str] = None,
    ) -> None:
        self.model_path = _resolve_path(model_path, DEFAULT_MODEL_PATH)
        self.labels_path = _resolve_path(labels_path, DEFAULT_LABELS_PATH)
        self.vocabulary = _load_labels(self.labels_path)
        self.label2id = {label: idx for idx, label in enumerate(self.vocabulary)}
        self.id2label = {idx: label for idx, label in enumerate(self.vocabulary)}

        torch, config_cls, model_cls = _load_model_code(self.model_path)
        self._torch = torch
        self.device = device or ('cuda' if torch.cuda.is_available() else 'cpu')

        config = config_cls.from_pretrained(self.model_path)
        config.label2id = self.label2id
        config.id2label = self.id2label

        self.window_size = int(getattr(config, 'num_frames', 70))
        self.num_points = int(getattr(config, 'num_points', 54))
        self.in_channels = int(getattr(config, 'in_channels', 2))

        self.model = self._load_checkpoint(model_cls, config)
        self.model.to(self.device)
        self.model.eval()
        self.loaded = True

    def predict(self, window: Any) -> Dict[str, Any]:
        """Predict a sign label from a sliding window of raw holistic features."""
        if not isinstance(window, np.ndarray):
            raise ValueError(f'Expected numpy array, got {type(window)}')

        poses = self._window_to_tensor(window)
        with self._torch.no_grad():
            output = self.model(poses=poses)
            probabilities = self._torch.softmax(output.logits, dim=-1).squeeze(0)
            confidence, label_id = self._torch.max(probabilities, dim=-1)

        idx = int(label_id.item())
        return {
            'sign': self.id2label[idx],
            'confidence': round(float(confidence.item()), 4),
        }

    def _window_to_tensor(self, window: np.ndarray):
        """Convert supported window shapes to model tensor shape [1, T, 54, 2]."""
        window = window.astype(np.float32, copy=False)

        if (
            window.ndim == 2
            and window.shape[1] in (self.feature_count, self.legacy_feature_count)
        ):
            points = np.stack([self._features_to_points(frame) for frame in window])
        elif window.ndim == 3 and window.shape[1:] == (self.num_points, self.in_channels):
            points = window
        elif window.ndim == 4 and window.shape[1:] == (
            self.window_size,
            self.num_points,
            self.in_channels,
        ):
            return self._torch.from_numpy(window).float().to(self.device)
        else:
            raise ValueError(
                f'Expected window shape (T, {self.feature_count}), '
                f'(T, {self.num_points}, {self.in_channels}), or '
                f'(B, {self.window_size}, {self.num_points}, {self.in_channels}); '
                f'got {window.shape}'
            )

        points = self._resample_frames(points, self.window_size)
        return self._torch.from_numpy(points).unsqueeze(0).float().to(self.device)

    def _features_to_points(self, frame: np.ndarray) -> np.ndarray:
        """Map raw holistic xyz features to SPOTER's normalized 54 xy graph points."""
        if frame.shape == (self.feature_count,):
            pose_count = POSE_LANDMARK_COUNT
        elif frame.shape == (self.legacy_feature_count,):
            pose_count = LEGACY_POSE_LANDMARK_COUNT
        else:
            raise ValueError(
                f'Expected feature vector shape ({self.feature_count},) or '
                f'({self.legacy_feature_count},), got {frame.shape}'
            )

        pose_size = pose_count * 3
        hand_size = HAND_POINT_COUNT * 3
        pose = np.zeros((POSE_LANDMARK_COUNT, 3), dtype=np.float32)
        pose[:pose_count] = frame[:pose_size].reshape(pose_count, 3)
        left = frame[pose_size:pose_size + hand_size].reshape(HAND_POINT_COUNT, 3)
        right = frame[pose_size + hand_size:pose_size + (2 * hand_size)].reshape(
            HAND_POINT_COUNT,
            3,
        )

        points = np.zeros((self.num_points, self.in_channels), dtype=np.float32)
        cursor = 0

        for pose_idx in POSE_POINT_INDICES:
            if pose_idx is not None:
                points[cursor] = pose[pose_idx, :2]
            cursor += 1

        points[cursor:cursor + HAND_POINT_COUNT] = left[list(HAND_POINT_INDICES), :2]
        cursor += HAND_POINT_COUNT
        points[cursor:cursor + HAND_POINT_COUNT] = right[list(HAND_POINT_INDICES), :2]

        return self._normalize_and_shift(points)

    @staticmethod
    def _normalize_and_shift(points: np.ndarray) -> np.ndarray:
        row = {
            key: points[index].copy()
            for index, key in enumerate(LANDMARK_KEYS)
        }

        SPOTERClassifier._normalize_body(row)
        SPOTERClassifier._normalize_hand(row, 0)
        SPOTERClassifier._normalize_hand(row, 1)

        normalized = np.array([row[key] for key in LANDMARK_KEYS], dtype=np.float32)
        return normalized - 0.5

    @staticmethod
    def _normalize_body(row: Dict[str, np.ndarray]) -> None:
        nose = row['nose']
        neck = row['neck']
        right_shoulder = row['rightShoulder']
        left_shoulder = row['leftShoulder']
        left_eye = row['leftEye']

        if (
            (left_shoulder[0] == 0 or right_shoulder[0] == 0)
            and (neck[0] == 0 or nose[0] == 0)
        ):
            return

        if left_shoulder[0] != 0 and right_shoulder[0] != 0:
            head_metric = SPOTERClassifier._distance(left_shoulder, right_shoulder)
        else:
            head_metric = SPOTERClassifier._distance(neck, nose)

        starting_point = np.array(
            [neck[0] - (3 * head_metric), left_eye[1] + head_metric],
            dtype=np.float32,
        )
        ending_point = np.array(
            [neck[0] + (3 * head_metric), starting_point[1] - (6 * head_metric)],
            dtype=np.float32,
        )
        starting_point = np.maximum(starting_point, 0)
        ending_point = np.maximum(ending_point, 0)

        width = ending_point[0] - starting_point[0]
        height = starting_point[1] - ending_point[1]
        if width == 0 or height == 0:
            return

        for key in BODY_LANDMARK_NAMES:
            if row[key][0] == 0:
                continue
            row[key][0] = (row[key][0] - starting_point[0]) / width
            row[key][1] = (row[key][1] - ending_point[1]) / height

    @staticmethod
    def _normalize_hand(row: Dict[str, np.ndarray], hand_index: int) -> None:
        keys = tuple(
            f'{landmark}_{hand_index}'
            for landmark in HAND_LANDMARK_NAMES
        )

        x_values = np.array(
            [row[key][0] for key in keys if row[key][0] != 0],
            dtype=np.float32,
        )
        y_values = np.array(
            [row[key][1] for key in keys if row[key][1] != 0],
            dtype=np.float32,
        )
        if x_values.size == 0 or y_values.size == 0:
            return

        width = float(x_values.max() - x_values.min())
        height = float(y_values.max() - y_values.min())
        if width > height:
            delta_x = 0.1 * width
            delta_y = delta_x + ((width - height) / 2)
        else:
            delta_y = 0.1 * height
            delta_x = delta_y + ((height - width) / 2)

        starting_point = np.array(
            [x_values.min() - delta_x, y_values.min() - delta_y],
            dtype=np.float32,
        )
        ending_point = np.array(
            [x_values.max() + delta_x, y_values.max() + delta_y],
            dtype=np.float32,
        )

        norm_width = ending_point[0] - starting_point[0]
        norm_height = ending_point[1] - starting_point[1]
        if norm_width == 0 or norm_height == 0:
            return

        for key in keys:
            if row[key][0] == 0:
                continue
            row[key][0] = (row[key][0] - starting_point[0]) / norm_width
            row[key][1] = (row[key][1] - starting_point[1]) / norm_height

    @staticmethod
    def _distance(first: np.ndarray, second: np.ndarray) -> float:
        return float(np.sqrt(((first[0] - second[0]) ** 2) + ((first[1] - second[1]) ** 2)))

    @staticmethod
    def _resample_frames(points: np.ndarray, target_frames: int) -> np.ndarray:
        if points.shape[0] == target_frames:
            return points
        if points.shape[0] == 0:
            raise ValueError('Cannot resample an empty window')

        indices = np.linspace(0, points.shape[0] - 1, target_frames)
        indices = np.rint(indices).astype(np.int64)
        return points[indices]

    def _load_checkpoint(self, model_cls, config):
        try:
            from transformers.utils import logging as hf_logging
            previous_verbosity = hf_logging.get_verbosity()
            hf_logging.set_verbosity_error()
        except Exception:
            hf_logging = None
            previous_verbosity = None

        try:
            with warnings.catch_warnings():
                warnings.filterwarnings(
                    'ignore',
                    message='enable_nested_tensor is True.*',
                    category=UserWarning,
                )
                return model_cls.from_pretrained(
                    self.model_path,
                    config=config,
                    label2id=self.label2id,
                    id2label=self.id2label,
                )
        finally:
            if hf_logging is not None and previous_verbosity is not None:
                hf_logging.set_verbosity(previous_verbosity)


def _resolve_path(value: Optional[str | Path], default: Path) -> Path:
    if value is None or str(value).strip() == '':
        return default

    path = Path(value).expanduser()
    if path.is_absolute() and path.exists():
        return path

    candidates = [
        Path.cwd() / path,
        REPO_ROOT / path,
        REPO_ROOT / 'recognition-service' / path,
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate.resolve()

    return path.resolve()


def _load_labels(labels_path: Path) -> List[str]:
    if not labels_path.exists():
        raise FileNotFoundError(f'SPOTER label file not found: {labels_path}')

    labels: List[str] = []
    with labels_path.open('r', encoding='utf-8') as handle:
        for row in csv.reader(handle):
            if len(row) < 2:
                continue
            labels.append(row[1].strip())

    if not labels:
        raise ValueError(f'SPOTER label file is empty: {labels_path}')
    return labels


def _load_model_code(model_path: Path):
    if not model_path.exists():
        raise FileNotFoundError(f'SPOTER model directory not found: {model_path}')

    import torch

    package_name = f'_vsl_spoter_{abs(hash(model_path.resolve()))}'
    if package_name not in sys.modules:
        package = types.ModuleType(package_name)
        package.__path__ = [str(model_path)]
        sys.modules[package_name] = package

    _load_module(package_name, 'configuration', model_path / 'configuration.py')
    modelling = _load_module(package_name, 'modelling', model_path / 'modelling.py')

    return torch, sys.modules[f'{package_name}.configuration'].SPOTERConfig, modelling.SPOTERForGraphClassification


def _load_module(package_name: str, module_name: str, path: Path):
    if not path.exists():
        raise FileNotFoundError(f'SPOTER module file not found: {path}')

    full_name = f'{package_name}.{module_name}'
    if full_name in sys.modules:
        return sys.modules[full_name]

    spec = importlib.util.spec_from_file_location(full_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f'Cannot load SPOTER module from {path}')

    module = importlib.util.module_from_spec(spec)
    sys.modules[full_name] = module
    spec.loader.exec_module(module)
    return module
