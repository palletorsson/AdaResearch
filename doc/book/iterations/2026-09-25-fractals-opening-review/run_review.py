"""Use the standard isolated runner with a distinct directory from the immersion task."""
from pathlib import Path
p=Path.cwd()/'tools/run_encounter_probe.py'
source=p.read_text(encoding='utf-8')
old="ROOT / 'ada_run/encounter_pilot' / args.room"
assert source.count(old)==1
source=source.replace(old,"ROOT / 'ada_run/encounter_pilot' / (args.room + '_opening_review')")
exec(compile(source,str(p),'exec'),{'__name__':'__main__','__file__':str(p)})
