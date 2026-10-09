"""Extract the printed student files and run real Godot assertions on them."""
from pathlib import Path
import hashlib, json, os, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'ada_run/fractal_lesson_student'
manifest = {}
for hall in ['Fractal_Recursion', 'Fractal_RecursiveTrees']:
    source = ROOT / 'commons/maps' / hall / 'tutorial.md'
    text = source.read_text(encoding='utf-8')
    blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', text, re.S)
    expected = {'frames.gd', 'line_skin.gd'} if hall == 'Fractal_Recursion' else {'tree.gd', 'line_skin.gd', 'point_body.gd'}
    assert {name for name, _ in blocks} == expected
    assert len(blocks) == len(expected)
    for name, code in blocks:
        assert '$' not in code
        target = TARGET / hall / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(code + '\n', encoding='utf-8')
        manifest[f'{hall}/{name}'] = hashlib.sha256(target.read_bytes()).hexdigest()
(TARGET / 'extraction.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
report = ROOT / 'ada_run/fractal_lesson_student_tests.json'
if report.exists(): report.unlink()
log = ROOT / 'ada_run/fractal-lesson-student-engine.log'
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(log), '--script', 'res://tools/probes/fractal_lesson_student.gd']
with (TARGET / 'stdout.log').open('w', encoding='utf-8') as output:
    result = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, timeout=75, creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
errors = [line for line in log.read_text(encoding='utf-8', errors='replace').splitlines() if 'SCRIPT ERROR' in line]
print('Engine exit:', result.returncode, 'Script errors:', errors)
if report.exists():
    data = json.loads(report.read_text()); print('Checks:', len(data['checks']), 'Failures:', data['failures'])
assert result.returncode == 0 and not errors and report.exists()
assert json.loads(report.read_text())['passed']
