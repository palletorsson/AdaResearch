from pathlib import Path
import sys,shutil,json
r=Path.cwd();o=Path(__file__).parent;src=r/'ada_run/encounter_pilot/Random_Space';dst=o/sys.argv[1];dst.mkdir(exist_ok=True)
for n in ['floor-overview.png','cellular-field.png','report.json','source_manifest.json','stdout.log','engine.log','spec.json','control.json','probe-used.gd']:
 p=src/n
 if p.exists():shutil.copy2(p,dst/n)
(dst/'process.json').write_text(json.dumps({'exit_code':int(sys.argv[2])})+'\n')
print('Collected '+str(dst))
