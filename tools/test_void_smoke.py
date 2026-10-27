"""Compatibility entry point for the current pinned-canister acceptance suite."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('test_void_pinned_smoke.py')), run_name='__main__')