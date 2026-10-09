"""Run either real museum hall with separate evidence outputs."""
from pathlib import Path
p = Path.cwd() / 'tools/run_encounter_probe.py'
source = p.read_text(encoding='utf-8').replace(
    "ROOT / 'ada_run/encounter_pilot' / args.room",
    "ROOT / 'ada_run/encounter_pilot' / (args.room + '_column_side_controls')")
exec(compile(source, str(p), 'exec'), {'__name__': '__main__', '__file__': str(p)})
