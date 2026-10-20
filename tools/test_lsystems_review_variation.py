"""Run the external reviewer's turn-reversal proposal, separate from museum code."""
from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-lsystems-feedback'
source=R/'commons/maps/LSystems_Grammar_Lab/tutorial.md'
blocks=dict(re.findall(r'<!-- student-code:([^ >]+) -->\s*```gdscript\n(.*?)\n```',source.read_text(encoding='utf-8'),re.S))
assert len(blocks)==4
turns={
    '\t\t\t"+": heading = heading.rotated(Vector3.FORWARD, deg_to_rad(angle))':
    '\t\t\t"+": heading = heading.rotated(Vector3.FORWARD, -deg_to_rad(angle))',
    '\t\t\t"-": heading = heading.rotated(Vector3.FORWARD, -deg_to_rad(angle))':
    '\t\t\t"-": heading = heading.rotated(Vector3.FORWARD, deg_to_rad(angle))',
}
manifest={'scope':'One proposed independent edit, reconstructed and tested by the authoring AI. Not independent-student or headset evidence.','files':{}}
for folder in ['printed','turns-reversed']:
    (O/folder).mkdir(exist_ok=True)
    for name,code in blocks.items():
        if name=='grammar.gd' and folder=='turns-reversed':
            assert all(code.count(line)==1 for line in turns)
            code='\n'.join(turns.get(line,line) for line in code.splitlines())
        data=(code+'\n').encode('utf-8')
        (O/folder/name).write_bytes(data)
        manifest['files'][folder+'/'+name]=hashlib.sha256(data).hexdigest()
assert (O/'printed/grammar.gd').read_bytes() != (O/'turns-reversed/grammar.gd').read_bytes()
for name in ['sentence.gd','point_body.gd','line_skin.gd']:
    assert (O/'printed'/name).read_bytes()==(O/'turns-reversed'/name).read_bytes()
(O/'variation-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),
        '--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),
        '--script','res://tools/probes/lsystems_review_variation.gd'],cwd=R,stdout=log,stderr=subprocess.STDOUT,
        timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors,(p.returncode,errors)
result=json.loads((O/'variation-checks.json').read_text(encoding='utf-8'))
assert result['passed'],result
print(json.dumps({'passed':True,'checks':len(result['checks']),'cases':result['model_cases'],'scope':manifest['scope']}))
