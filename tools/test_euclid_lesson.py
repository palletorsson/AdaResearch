"""Extract printed Euclid scripts and execute the complete host in Godot."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-11-euclid-the-same-triangle/author'
OUT.mkdir(parents=True, exist_ok=True)
PRINT = OUT/'printed'
PRINT.mkdir(exist_ok=True)
source = ROOT/'commons/maps/Euclid_Parallel/tutorial.md'
blocks = re.findall(r'<!-- student-code:([\w_]+\.gd) -->\s*```gdscript\n(.*?)\n```', source.read_text(encoding='utf-8'), re.S)
assert len(blocks) == 4
for name, code in blocks:
    (PRINT/name).write_text(code+'\n', encoding='utf-8')
    assert code+'\n' == (ROOT/'doc/book/studies/euclid-lineage'/name).read_text(encoding='utf-8')
stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
log = OUT/(stamp+'.log')
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/euclid_lesson_test.gd','--','--no-bridges']
with log.open('w',encoding='utf-8') as f:
    try:
        result = subprocess.run(command, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT, timeout=60, creationflags=subprocess.CREATE_NO_WINDOW)
        code = result.returncode
    except subprocess.TimeoutExpired:
        code = 124
text = log.read_text(encoding='utf-8')
print(text[-6500:])
(OUT/(stamp+'.json')).write_text(json.dumps({'command':command,'exit_code':code,'tutorial_sha256':hashlib.sha256(source.read_bytes()).hexdigest()},indent=2),encoding='utf-8')
assert code == 0 and 'SCRIPT ERROR' not in text and 'EUCLID PASS' in text
assert json.loads((OUT/'results.json').read_text())['passed']
