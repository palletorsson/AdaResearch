"""Render the real Point Lines museum hall with isolated output files."""
from pathlib import Path
import sys

p = Path.cwd() / 'tools/run_encounter_probe.py'
stage = 'before' if '--before' in sys.argv else 'after'
if '--before' in sys.argv:
    sys.argv.remove('--before')
s = p.read_text(encoding='utf-8').replace(
    "ROOT / 'ada_run/encounter_pilot' / args.room",
    f"ROOT / 'ada_run/encounter_pilot' / (args.room + '_podiums_{stage}')")
exec(compile(s, str(p), 'exec'), {'__name__': '__main__', '__file__': str(p)})
