"""Extract only the fenced lesson listings; freeze provenance before engine runs."""
from pathlib import Path
import hashlib
import json
import math
import re
from datetime import datetime, timezone

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
INPUT = HERE.parent / 'input'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

text = (INPUT / 'tutorial.md').read_text(encoding='utf-8')
listings = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\s*\n(.*?)\n```', text, re.S)
expected = {'triangle_record.gd', 'euclid_study.gd', 'point_body.gd', 'line_skin.gd'}
assert {name for name, _ in listings} == expected
for name, source in listings:
    (HERE / name).write_text(source + '\n', encoding='utf-8', newline='\n')

(HERE / 'minimal.tscn').write_text('''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student/euclid_study.gd" id="1"]

[node name="EuclidStudy" type="Node3D"]
script = ExtResource("1")
''', encoding='utf-8')

reads = [
    (INPUT / 'tutorial.md', 'Only source of implementation; read complete text and extracted four exact listings.'),
    (INPUT / 'final.md', 'Read complete prose for stated concepts and expectations.'),
    (Path('C:/Users/palle/.codex/skills/ada-dispatcher/SKILL.md'), 'Required Ada skill routing; selected auditor.'),
    (Path('C:/Users/palle/.codex/skills/ada-auditor/SKILL.md'), 'Validation workflow only; broader repository audit omitted by task scope.'),
    (ROOT / 'commons/interactables/push_button.tscn', 'Declared dependency; identify button press interface.'),
    (ROOT / 'commons/interactables/push_button.gd', 'Declared transitive dependency; trace pressed callback.'),
    (ROOT / 'commons/interactables/interactable_area_button_pointer.gd', 'Declared transitive dependency; inspect pointer dispatch.'),
    (ROOT / 'addons/godot-xr-tools/interactables/interactable_area_button.gd', 'Declared transitive dependency; use actual area entry/exit callback chain.'),
]
reading_log = {
    'identity': 'Fresh experienced coding AI ghost student; not a novice human.',
    'reads': [{'path': str(p), 'sha256': sha(p), 'reason': reason} for p, reason in reads],
    'assistance': [
        'Parent assigned scope, runtime, output folder and required evaluation categories; no implementation hints or test results received.',
        'Used only tutorial.md and final.md as lesson content.',
        'Listed filenames matching *pointer*event* under declared XRTools dependency; no match, no extra source read.',
        'Godot automatically loads project/global-class/dependency infrastructure; the agent did not inspect that source.',
        'No web lookup, author tests, study implementation, earlier attempts, assessments or solution probes inspected.',
        'Reconstructed source is mechanically copied from supplied listings. The independent work is the test/oracle and shear variation, not the implementation.',
    ],
}
(HERE / 'reading_assistance_log.json').write_text(json.dumps(reading_log, indent=2), encoding='utf-8')

def angle_degrees(x, y):
    return math.degrees(math.atan2(y, x))

predictions = {
    'frozen_at_utc': datetime.now(timezone.utc).isoformat(),
    'engine_executed_yet': False,
    'host_transform': {'position': [4, 1, -3], 'rotation_radians': [.2, .65, -.12], 'scale': [1, 1, 1]},
    'right_triangle': {'points': [[0, 0], [1, 0], [0, 1]], 'angles_deg': [90, 45, 45], 'sum_deg': 180, 'area_m2': .5},
    'initial': {'points': [[-.7, .4], [.7, .4], [0, -.6]], 'angles_deg': [angle_degrees(.7, 1), angle_degrees(.7, 1), 180 - 2 * angle_degrees(.7, 1)], 'sum_deg': 180, 'area_m2': .7, 'guide_length_m': 2.5},
    'uniform_scaling': {'points': [[0, 0], [.8, 0], [.2, .6]], 'doubled': [[0, 0], [1.6, 0], [.4, 1.2]], 'angles_deg': [angle_degrees(.2, .6), 45, 135 - angle_degrees(.2, .6)], 'area_before_m2': .24, 'area_after_m2': .96, 'side_ratio': 2},
    'degeneracy': [
        'Coincident A/B and collinear A/B/C both yield valid=false, sum=0, angles=[]; host withholds reading, angle labels, face and guide.',
        'Triangle (0,0),(1,0),(.5,1e-6) is invalid due to relative area policy; height 2e-5 is valid.',
        'Uniformly tiny right triangle with legs 1e-6 is invalid because longest<=EPS. This is an instrument policy exception to mathematical scale invariance.',
        'A/B coincidence also produces no parallel endpoints.',
    ],
    'interactions': [
        'Initial host has 3 visible sphere point bodies, 3 finite edges, 3 corner labels, initialized readout, face, guide and both supplied controls.',
        'Translated/rotated unit-scale host uses its local frame. Synthetic grab at local (1.7,4.2,-1.4) records A=(1,-1) while held sphere remains at requested world position.',
        'Held-point label and edges display bounded projection at y=1.12. Reset while held does nothing.',
        'On drop, point returns to recorded projection; physics processing maintains it.',
        'Synthetic supplied-button area enter/exit invokes callback. Guide changes visibility without changing model points or measurements.',
        'Synthetic held-point action signal and G key toggle guide; key echo and release do not. R and Reset restore all initial points while preserving guide state.',
        'Degeneracy and recovery update labels, readout, face and guide consistently.',
    ],
    'independent_variation': {
        'operation': 'Area-preserving shear x_new=x+0.5*y, y_new=y. This is separate from the text\'s uniform scaling exercise.',
        'base_points': [[0, 0], [.8, 0], [.2, .6]],
        'sheared_points': [[0, 0], [.8, 0], [.5, .6]],
        'base_angles_deg': [angle_degrees(.2, .6), 45, 135 - angle_degrees(.2, .6)],
        'sheared_angles_deg': [angle_degrees(.5, .6), angle_degrees(.3, .6), 180-angle_degrees(.5, .6)-angle_degrees(.3, .6)],
        'area_both_m2': .24,
        'sum_both_deg': 180,
        'base_lengths_m': [.8, math.sqrt(.72), math.sqrt(.4)],
        'sheared_lengths_m': [.8, math.sqrt(.45), math.sqrt(.61)],
        'parallel': 'Guide stays centred on transformed C and parallel to AB; AB is unchanged by this shear.',
        'transfer_claim': 'Tests recognition that area and sum invariance do not imply unchanged angles or lengths. Copying the lesson scripts itself does not establish invention or novice learning.',
    },
    'limits': ['Headless software and synthetic events only.', 'No physical XR, pointer targeting, rendering, placement, museum navigation or human learning claim.'],
}
(HERE / 'predictions.json').write_text(json.dumps(predictions, indent=2), encoding='utf-8')
manifest = {'frozen_at_utc': datetime.now(timezone.utc).isoformat(), 'engine_executed_yet': False,
            'sha256': {p.name: sha(p) for p in sorted(HERE.iterdir()) if p.is_file() and p.name != 'pre_run_manifest.json'},
            'input_sha256': {p.name: sha(p) for p in (INPUT / 'tutorial.md', INPUT / 'final.md')}}
(HERE / 'pre_run_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps({'extracted': sorted(expected), 'input_sha256': manifest['input_sha256'], 'frozen_files': len(manifest['sha256'])}, indent=2))
