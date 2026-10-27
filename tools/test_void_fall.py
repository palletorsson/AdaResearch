"""Current Void fall contract: safe landings and silent body feedback.

The former one-storey lethal contract is superseded by Palle's 27 October
request. Keep the established test entry point on the current physics probe.
"""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('test_void_safe_fall.py')),run_name='__main__')
