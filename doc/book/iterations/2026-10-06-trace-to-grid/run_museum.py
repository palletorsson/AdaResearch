"""Use the project's existing isolated-output museum probe runner."""
from pathlib import Path
import sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
runner=ROOT/'tools/run_encounter_probe.py'
source=runner.read_text(encoding='utf-8')
source=source.replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_learner_grid_20261006')")
sys.argv=[str(runner),'Point_Line_Grid','--sequence','primitives','--render','--probe',str(HERE/'museum-check.gd')]
exec(compile(source,str(runner),'exec'),{'__name__':'__main__','__file__':str(runner)})
