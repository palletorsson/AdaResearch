"""Fresh, isolated validation receipts for the four built uncertainty studies."""
from pathlib import Path
import json,hashlib,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-camera-image-becomes-body/validation';O.mkdir(parents=True,exist_ok=True)
studies=[('G0','geometry_noise_test.gd','2026-10-09-geometry-noise-test'),('G1','pendulum_noise_test.gd','2026-10-09-pendulum-a-recorded-push'),('G2','navigator_noise_test.gd','2026-10-09-navigator-an-imperfect-observation'),('P1','euler_step_test.gd','2026-10-09-the-same-throw-different-steps')]
results=[]
for key,probe,report in studies:
 folder=O/key;folder.mkdir(exist_ok=True)
 sources=json.loads((R/'doc/book/iterations'/report/'source-manifest.json').read_text(encoding='utf-8'))
 changed=[p for p,h in sources.items() if not (R/p).exists() or hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
 dest=folder/'checks.json'
 if dest.exists():dest.unlink()
 with (folder/'stdout.log').open('w',encoding='utf-8') as out:
  p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(folder/'engine.log'),'--script','res://tools/probes/'+probe,'--','res://'+dest.relative_to(R).as_posix()],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW)
 errors=[s for s in (folder/'engine.log').read_text(encoding='utf-8').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
 d=json.loads(dest.read_text(encoding='utf-8')) if dest.exists() else {}
 row={'study':key,'exit':p.returncode,'checks':len(d.get('checks',[])),'passed':p.returncode==0 and d.get('passed',False) and not errors,'errors':errors,'failures':d.get('failures',d.get('failed',[])),'changed_since_previous_receipt':changed}
 results.append(row);print(json.dumps(row),flush=True)
(O/'built-studies.json').write_text(json.dumps({'scope':'Fresh native model/scene checks, previous source-hash comparison; not fresh headset tests.','results':results},indent=2),encoding='utf-8')
assert all(r['passed'] for r in results),results
