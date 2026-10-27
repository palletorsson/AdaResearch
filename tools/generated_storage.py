"""Development model storage, outside the Godot resource tree.

ADA_GENERATED_ROOT overrides the local default. Public directory junctions are
installed by migrate_generated_models.py; HTTP URLs remain unchanged.
"""
import os
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
DEFAULT_ROOT = Path('D:/AdaGenerated/AdaResearch_46') if os.name == 'nt' else Path.home()/'.cache/ada-generated'/PROJECT.name

def generated_root() -> Path:
    root = Path(os.environ.get('ADA_GENERATED_ROOT', str(DEFAULT_ROOT))).expanduser().resolve()
    if root == PROJECT or root.is_relative_to(PROJECT):
        raise ValueError('Generated model storage must be outside the Godot project')
    return root

def model_directory(requested: str | Path) -> Path:
    """Preserve explicit external paths; relocate paths inside the source project."""
    path = Path(requested).expanduser().resolve()
    if path.is_relative_to(PROJECT):
        return generated_root()/'project'/path.relative_to(PROJECT)
    return path

def public_directory(relative: str) -> Path:
    path = (generated_root()/'public'/relative).resolve()
    if not path.is_relative_to(generated_root()/'public'):
        raise ValueError('Invalid public model directory')
    return path
