"""Extract, execute and vary the exact four files printed in the Curves lesson."""
from pathlib import Path
import hashlib, json, re, subprocess
R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-09-curves-one-sentence-three-readers'
S = R/'doc/book/studies/lsystems-through-the-hands/LSystems_Grammars_And_Curves'
blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', (R/'commons/maps/LSystems_Grammars_And_Curves/tutorial.md').read_text(encoding='utf-8'), re.S)
assert len(blocks) == 4
for folder in ['printed', 'variation', 'mutations']: (O/folder).mkdir(exist_ok=True)
hashes = {}
for name, code in blocks:
    data = (code+'\n').encode('utf-8')
    assert data == (S/name).read_bytes(), name
    assert '$' not in code
    (O/'printed'/name).write_bytes(data)
    hashes[name] = hashlib.sha256(data).hexdigest()
    if name == 'grammar.gd':
        code = code.replace('Vector3(heading.y, heading.x, 0)', 'Vector3(-heading.y, heading.x, 0)')
    (O/'variation'/name).write_bytes((code+'\n').encode('utf-8'))
for name in ['point_body.gd', 'line_skin.gd']:
    assert (S/name).read_bytes() == (S.parent/'LSystems_Growth'/name).read_bytes()
def rewrite(p):
    return p.read_text(encoding='utf-8').split('func rewrite(')[1].split('\nfunc ')[0]
assert rewrite(S/'grammar.gd') == rewrite(S.parent/'LSystems_Growth/grammar.gd')
code = (S/'grammar.gd').read_text(encoding='utf-8')
code = code.replace('state.pos += direction(state.heading, sideways) * STRIDE', 'state.heading = direction(state.heading, sideways)\n\t\t\t\tstate.pos += state.heading * STRIDE')
(O/'mutations/changed_heading.gd').write_bytes(code.encode('utf-8'))
(O/'printed-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
receipt = O/'checks.json'
if receipt.exists(): receipt.unlink()
with (O/'stdout.log').open('w', encoding='utf-8') as log:
    p = subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(R), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(O/'engine.log'), '--script', 'res://tools/probes/curves_reader_lesson.gd'], cwd=R, stdout=log, stderr=subprocess.STDOUT, timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
errors = [line for line in (O/'engine.log').read_text(encoding='utf-8', errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
assert p.returncode == 0 and not errors and receipt.exists(), (p.returncode, errors)
d = json.loads(receipt.read_text(encoding='utf-8'))
assert d['passed'], d['failures']
print(json.dumps({'passed':True, 'checks':len(d['checks']), 'production_comparisons':d['production_comparisons'], 'production_frames':d['production_frames'], 'files':list(hashes)}))
