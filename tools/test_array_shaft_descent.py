"""Compatibility entry point: the shaft study is now the collectible flight array."""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("test_array_flight.py")), run_name="__main__")
