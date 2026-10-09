"""Run this lesson's checks in an isolated copy of the existing museum host."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
runner = ROOT / 'tools/run_encounter_probe.py'
source = runner.read_text(encoding='utf-8')
source = source.replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_tutorial')")
sys.argv = [str(runner), 'Point_Coordinates', '--sequence', 'primitives', '--render', '--probe', str(Path(__file__).with_name('verify.gd'))]
exec(compile(source, str(runner), 'exec'), {'__name__': '__main__', '__file__': str(runner)})
