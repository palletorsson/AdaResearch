"""Compatibility entry point for the current Array trial, including its hand grid."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name("test_array_hand_index.py")), run_name="__main__")
