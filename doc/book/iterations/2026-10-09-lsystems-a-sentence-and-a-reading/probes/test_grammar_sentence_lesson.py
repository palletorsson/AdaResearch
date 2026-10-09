"""Extract exactly what the student reads, then run native Godot assertions."""
from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading'
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/LSystems_Grammar_Lab/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==4
(O/'printed').mkdir(exist_ok=True)
hashes={}
for name,code in blocks:
    data=(code+'\n').encode('utf-8')
    assert data==(S/name).read_bytes(),name
    assert '$' not in code
    (O/'printed'/name).write_bytes(data)
    hashes[name]=hashlib.sha256(data).hexdigest()
    d=O/'variation';d.mkdir(exist_ok=True)
    if name=='sentence.gd': code=code.replace('const CURVE := {"F": "F+F-F-F+F"}', 'const CURVE := {"F": "F+F"}')
    (d/name).write_text(code+'\n',encoding='utf-8')
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/fractals-through-the-hands/Fractal_Synthesis/point_body.gd').read_bytes()
assert (S/'line_skin.gd').read_bytes()==(R/'doc/book/studies/fractals-through-the-hands/Fractal_KochSierpinski/line_skin.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/grammar_sentence_lesson.gd'],cwd=R,stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[line for line in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text(encoding='utf-8')); assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'printed_files':list(hashes)}))
