from pathlib import Path
import json, sys, shutil
from concurrent.futures import ThreadPoolExecutor
from review_force_halls import run
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-selected-in-the-halls'
data=json.loads((OUT/'selection.json').read_text(encoding='utf8'))
maps=list(dict.fromkeys(x['map'] for x in data['artifacts']))
if len(sys.argv)>1:maps=sys.argv[1:]
def one(m):return run(m,'tools/probes/forces_selection_museum.gd',OUT/'museum'/m,True)
with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(one,maps))
status=OUT/'capture-status.json'
previous=json.loads(status.read_text(encoding='utf8')) if status.exists() else []
by_map={r['map']:r for r in previous}
by_map.update({r['map']:r for r in results})
status.write_text(json.dumps(list(by_map.values()),indent=2),encoding='utf8')
shutil.copy2(ROOT/'ada_run/forces_selection_models.json',OUT/'tests/models.json')
print(json.dumps(results,indent=2))
raise SystemExit(0 if all(x['passed'] for x in results) else 1)
