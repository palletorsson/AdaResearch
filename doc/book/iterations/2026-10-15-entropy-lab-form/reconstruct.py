"""Build a fresh scene from the printed model and the declared supplied host."""
from pathlib import Path
import hashlib, json, re, shutil, subprocess
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
OUT=HERE/'reconstruction'
OUT.mkdir(exist_ok=True)
text=(ROOT/'commons/maps/Random_Entropy/tutorial.md').read_text(encoding='utf8')
blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
assert set(blocks)=={'compartment_model.gd'}
(OUT/'compartment_model.gd').write_text(blocks['compartment_model.gd']+'\n',encoding='utf8')
src=ROOT/'commons/artifacts/entropy_compartments'
assert blocks['compartment_model.gd']==(src/'compartment_model.gd').read_text(encoding='utf8').rstrip()
for name in ['entropy_compartments.gd','entropy_compartments.tscn','preview.tscn']:
    shutil.copy2(src/name,OUT/name)
prefix='res://'+OUT.relative_to(ROOT).as_posix()+'/'
probe=(HERE/'verify.gd').read_text(encoding='utf8').replace('res://doc/book/iterations/2026-10-15-entropy-lab-form/',prefix)
probe=probe.replace('res://commons/artifacts/entropy_compartments/',prefix)
(OUT/'verify.gd').write_text(probe,encoding='utf8')
engine='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
with (OUT/'verification.log').open('w',encoding='utf8') as log:
    run=subprocess.run([engine,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script',prefix+'verify.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
report=json.loads((OUT/'verification.json').read_text(encoding='utf8'))
output=(OUT/'verification.log').read_text(encoding='utf8')
assert run.returncode==0 and report['passed'] and 'SCRIPT ERROR' not in output,output[-5000:]
(OUT/'manifest.json').write_text(json.dumps({'scope':'Fresh extracted model with explicitly supplied host, scene and preview; not an independent human reconstruction.','sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.iterdir() if p.suffix in ['.gd','.tscn']}},indent=2),encoding='utf8')
print('Printed model reconstructed:',len(report['checks']),'checks passed')
