"""Execute the frozen printed reconstructions and student transfer edits."""
from pathlib import Path
import hashlib,json,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-ghost-student'
before=json.loads((O/'manifest-before.json').read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
with (O/'stdout.log').open('w',encoding='utf-8') as out:
 result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','gl_compatibility','--resolution','800x600','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/ca_ghost_student.gd'],cwd=R,stdout=out,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[s for s in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
unchanged=all(sha(R/p)==v for p,v in before['canonical'].items()) and all(sha(O/p)==v for p,v in before['printed'].items())
receipt={'returncode':result.returncode,'errors':errors,'canonical_and_printed_unchanged':unchanged,'scope':before['scope']}
(O/'run-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt))
assert result.returncode==0 and not errors and unchanged
d=json.loads((O/'checks.json').read_text(encoding='utf-8'));assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'observations':d['observations']}))
