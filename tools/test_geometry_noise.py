"""Run native assertions with logs; GUI executable exit code is captured by Python."""
from pathlib import Path
import json,subprocess,sys
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-geometry-noise-test'
exe='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
with (O/'core-stdout.log').open('w',encoding='utf-8') as out:
 p=subprocess.run([exe,'--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy',
 '--log-file',str(O/'core-engine.log'),'--script','res://tools/probes/geometry_noise_test.gd','--',
 'res://doc/book/iterations/2026-10-09-geometry-noise-test/checks.json'],cwd=R,stdout=out,stderr=subprocess.STDOUT,
 timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'core-engine.log').read_text(encoding='utf-8')
errors=[s for s in log.splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert p.returncode==0 and not errors,(p.returncode,errors)
d=json.loads((O/'checks.json').read_text(encoding='utf-8'))
assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'observations':d['observations']}))
