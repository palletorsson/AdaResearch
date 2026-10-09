from pathlib import Path
import sys, json, shutil
from write_lesson import ROOT, HERE

runner = ROOT/'tools/run_encounter_probe.py'
source = runner.read_text(encoding='utf-8').replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_three_operations_20261006')")
namespace = {'__name__': 'museum_probe', '__file__': str(runner)}
exec(compile(source, str(runner), 'exec'), namespace)
sys.argv = [str(runner), 'Trans_Pre', '--sequence', 'transformation', '--render', '--probe', str(HERE/'museum_study.gd')]
result = namespace['main']()
folder = ROOT/'ada_run/encounter_pilot/Trans_Pre_three_operations_20261006'
dest = HERE/'museum'
dest.mkdir(exist_ok=True)
for name in ['still.png', 'translate.png', 'turn.png', 'scale.png', 'rise.png', 'report.json', 'source_manifest.json']:
    if (folder/name).exists(): shutil.copyfile(folder/name, dest/name)
assert result == 0 and json.loads((dest/'report.json').read_text())['passed']
