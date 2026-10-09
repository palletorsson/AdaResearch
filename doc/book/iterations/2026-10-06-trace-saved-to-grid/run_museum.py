from pathlib import Path
import sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
runner=ROOT/'tools/run_encounter_probe.py'
source=runner.read_text(encoding='utf-8').replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_saved_student_20261006')")
namespace={'__name__':'museum_probe','__file__':str(runner)}
exec(compile(source,str(runner),'exec'),namespace)
for hall in ['Point_Trace','Point_Line_Grid']:
    sys.argv=[str(runner),hall,'--sequence','primitives','--render','--probe',str(HERE/'museum_handoff.gd')]
    result=namespace['main']()
    if result:raise SystemExit(result)
