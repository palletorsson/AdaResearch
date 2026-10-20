"""Verify the architecture using the shared complete Void dependency stage."""
from pathlib import Path
import subprocess
import sys
root = Path(__file__).resolve().parents[1]
raise SystemExit(subprocess.call([sys.executable, str(root/'tools/test_void_game.py'), '--reuse', '--layout-only', '--out='+str(root/'doc/book/iterations/2026-10-18-the-void-layout')]))