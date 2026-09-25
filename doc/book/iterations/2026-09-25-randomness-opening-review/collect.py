from pathlib import Path
import json,shutil,sys
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-randomness-opening-review';src=r/'ada_run/encounter_pilot'/sys.argv[1];dst=o/sys.argv[2];dst.mkdir(exist_ok=True)
for p in src.iterdir():
 if p.is_file() and (p.suffix=='.png' or p.name in ['report.json','source_manifest.json','stdout.log','engine.log','spec.json','control.json','probe-used.gd']):shutil.copy2(p,dst/p.name)
(dst/'process.json').write_text(json.dumps({'exit_code':int(sys.argv[3])}),encoding='utf-8')
print('Collected',dst)
