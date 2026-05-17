"""
Vocabulary management for sign language recognition.

Loads sign vocabulary from JSON file and provides utility functions.
"""
import json
from pathlib import Path
from typing import List, Dict

VOCABULARY_PATH = Path(__file__).parent.parent.parent / "vocabulary.json"


def load_vocabulary() -> List[str]:
    """
    Load vocabulary list from JSON file.
    
    Returns:
        List of sign text strings (e.g., ['xin_chào', 'cảm_ơn'])
    """
    try:
        with open(VOCABULARY_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return [sign['text'] for sign in data.get('signs', [])]
    except FileNotFoundError:
        # Return minimal default vocabulary if file not found
        return [
            'xin_chào', 'cảm_ơn', 'tạm_biệt',
            'tôi', 'bạn', 'anh', 'chị', 'em',
            'cha', 'mẹ', 'gia_đình'
        ]


def load_vocabulary_with_categories() -> List[Dict]:
    """
    Load vocabulary with category information.
    
    Returns:
        List of sign dictionaries: [{'id': str, 'text': str, 'category': str}]
    """
    try:
        with open(VOCABULARY_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data.get('signs', [])
    except FileNotFoundError:
        return []


# Load vocabulary at module import time
VOCABULARY: List[str] = load_vocabulary()
VOCABULARY_SET = set(VOCABULARY)


def validate_vocabulary_size(expected_classes: int) -> bool:
    """Check if vocabulary size matches expected number of classes."""
    return len(VOCABULARY) == expected_classes
