"""Execute the novel exercise predicted in the eight-hall ghost-student manifest."""
from pathlib import Path
import hashlib, json, subprocess
R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-09-lsystems-ghost-student'
latest = json.loads((O/'latest-run.json').read_text())
assert latest['complete'] and latest['passed']
run = R/latest['directory']
out = run/'transfer-exercise'
out.mkdir(exist_ok=True)
files = {}
for p in (run/'LSystems_Competition/printed').glob('*.gd'):
    for folder in ['original','quarter']:
        target = out/folder/p.name
        target.parent.mkdir(exist_ok=True)
        source = p.read_text(encoding='utf-8')
        if folder == 'quarter' and p.name == 'soil.gd':
            assert source.count('const FRACTION := 0.15') == 1
            source = source.replace('const FRACTION := 0.15','const FRACTION := 0.25')
        target.write_bytes(source.encode())
        files[target.relative_to(out).as_posix()] = hashlib.sha256(target.read_bytes()).hexdigest()
manifest = json.loads((run/'manifest.json').read_text(encoding='utf-8'))
(out/'manifest.json').write_text(json.dumps({'prediction_recorded_before_run': manifest['chosen_variation_before_execution'], 'files': files}, indent=2)+'\n')
probe = R/'tools/probes/lsystems_ghost_variation.gd'
(out/'run.gd').write_bytes(probe.read_bytes())
assert not (out/'checks.json').exists(), 'Keep previous exercise evidence; start a fresh whole-sequence run before repeating.'
prefix = 'res://'+out.relative_to(R).as_posix()+'/'
with (out/'stdout.log').open('w', encoding='utf-8') as log:
    p = subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(out/'engine.log'),'--script',prefix+'run.gd','--',prefix], stdout=log, stderr=subprocess.STDOUT, timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
errors = [line for line in (out/'engine.log').read_text(encoding='utf-8', errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
assert p.returncode == 0 and not errors, (p.returncode, errors)
result = json.loads((out/'checks.json').read_text())
assert result['passed'],result['failures']
print(json.dumps({'passed': True, 'checks': len(result['checks']), 'directory': str(out)}))
