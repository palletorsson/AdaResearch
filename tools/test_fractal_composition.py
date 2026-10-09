"""Check one possible response to Synthesis's open task, not an answer rubric.

The complete Trees lesson is extracted verbatim. A separate copy receives a
bounded noise offset. Museum generators and the printed required code stay intact.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess

R = Path(__file__).resolve().parents[1]
O = R / 'ada_run/fractal_composition_student'
O.mkdir(parents=True, exist_ok=True)
source = R / 'commons/maps/Fractal_RecursiveTrees/tutorial.md'
blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', source.read_text(encoding='utf-8'), re.S)
assert {name for name, _ in blocks} == {'tree.gd', 'point_body.gd', 'line_skin.gd'}
for name, body in blocks:
    assert '$' not in body
    (O / name).write_text(body + '\n', encoding='utf-8')

original = (O / 'tree.gd').read_text(encoding='utf-8')
variant = original.replace('var tree: Node3D', '''var influence := deg_to_rad(12.0)
var noise_seed := 2468
var field := FastNoiseLite.new()
var tree: Node3D''')
variant = variant.replace('func _ready() -> void:\n', '''func _ready() -> void:
    field.noise_type = FastNoiseLite.TYPE_SIMPLEX
    field.fractal_type = FastNoiseLite.FRACTAL_NONE
    field.seed = noise_seed
    field.frequency = 0.37
''')
variant = variant.replace('child.rotation.z = TURN * sign_value', '''var sample := clampf(field.get_noise_2d(float(remaining), sign_value), -1.0, 1.0)
        child.rotation.z = TURN * sign_value + sample * clampf(influence, 0.0, deg_to_rad(15.0))''')
assert variant != original and variant.count('field.get_noise_2d') == 1
(O / 'noise_tree.gd').write_text(variant, encoding='utf-8')
(O / 'recipe.json').write_text(json.dumps({
    'purpose': 'One feasibility example, authored by the writing agent; not an independent ghost-student submission.',
    'input': 'One static Simplex noise sample at (remaining depth, left/right sign).',
    'receiver': 'Child local Z turn during construction.',
    'choices': {'generations': 3, 'ratio': 0.7, 'seed': 2468, 'frequency': 0.37, 'noise_fractal': 'none', 'offset_degrees': 12, 'maximum_offset_degrees': 15},
    'prediction': '15 attached segments, same lengths; changed endpoints. Zero influence recovers the original. Same settings rebuild the same geometry before hand edits.',
    'limits': 'Branches at a common depth and side share their sample. No time animation, new collision or installation in a hall. Hand edits replace first-fork orientation, as in the carried lesson.',
}, indent=2) + '\n', encoding='utf-8')
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.gd')}
(O / 'extraction.json').write_text(json.dumps({'source': str(source.relative_to(R)), 'sha256': hashes}, indent=2) + '\n', encoding='utf-8')

report = O / 'assertions.json'
if report.exists():
    report.unlink()
log = O / 'engine.log'
with (O / 'stdout.log').open('w', encoding='utf-8') as out:
    result = subprocess.run([
        'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(R),
        '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(log),
        '--script', 'res://tools/probes/fractal_composition.gd',
    ], cwd=R, stdout=out, stderr=subprocess.STDOUT, timeout=75,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
errors = [s for s in log.read_text(encoding='utf-8', errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
assert result.returncode == 0 and not errors and report.exists(), (result.returncode, errors)
data = json.loads(report.read_text(encoding='utf-8'))
assert data['passed'], data['failures']
assert {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.gd')} == hashes
print(json.dumps({'checks': len(data['checks']), 'failures': data['failures'], 'source_hashes_unchanged_during_run': True}))
