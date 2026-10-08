"""Make the starter execute the programs printed in the current museum tutorials.

No hand-maintained second lesson implementation. Room/player scenes are supplied;
each lesson file comes verbatim from a named student-code block in tutorial.md.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
LESSONS = [
    ('Point_Zero', 'point_zero', 'counter.gd'),
    ('Point_One', 'point_one', 'point.gd'),
    ('Point_Coordinates', 'point_coordinates', 'point.gd'),
    ('Point_Lines', 'point_lines', 'line.gd'),
    ('Point_Trace', 'point_trace', 'trace.gd'),
    ('Point_Line_Grid', 'point_grid', 'grid.gd'),
    ('Point_Triangle_Context', 'point_triangle', 'lesson.gd'),
    ('Primitives_Polythedra', 'point_polyhedra', 'lesson.gd'),
    ('Point_Animatedcube', 'point_cube', 'lesson.gd'),
    ('Primitives_Ignorance', 'primitive_rules', 'lesson.gd'),
    ('Primitives_Godot', 'primitive_godot', 'lesson.gd'),
    ('Primitives_Columns', 'primitive_column', 'lesson.gd'),
    ('Primitives_Profiles', 'primitive_profiles', 'lesson.gd'),
    ('Primitives_Portals', 'primitive_portals', 'lesson.gd'),
    ('Primitives_Melencolia', 'primitive_composition', 'lesson.gd'),
]

def sha(data):
    return hashlib.sha256(data).hexdigest()

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')

def sync_lessons():
    rows = []
    for hall, scene, main in LESSONS:
        source = ROOT / 'commons/maps' / hall / 'tutorial.md'
        text = source.read_text(encoding='utf-8')
        dest = STARTER / 'lessons' / hall
        files = {}
        for name, code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)^```', text, re.M | re.S):
            if not name.endswith('.gd'):
                continue  # A labelled edit is not a complete executable file.
            assert '/' not in name and '\\' not in name
            assert name not in files, (hall, name)
            write(dest / name, code)
            files[name] = sha(code.encode('utf-8'))
        assert main in files, (hall, main)
        # A part first printed in an earlier hall is carried, not reprinted (VOICE_DECISION.md,
        # 8 October): the tutorial names it in one fixed line, and the file comes from that hall.
        carried = {}
        for other, names in re.findall(r'Carried unchanged from \[[^\]]+\]\(\.\./([A-Za-z_]+)/tutorial\.md\): ((?:`[^`]+`(?:, )?)+)\.', text):
            for name in re.findall(r'`([^`]+)`', names):
                origin = STARTER / 'lessons' / other / name
                assert origin.exists(), (hall, name, 'not yet synced from', other)
                assert name not in files, (hall, name, 'both printed and carried')
                shutil.copy2(origin, dest / name)
                carried[name] = {'from': other, 'sha256': sha(origin.read_bytes())}
        if hall == 'Primitives_Profiles':
            for name in ['JetBrainsMono-Medium.ttf', 'OFL.txt']:
                shutil.copy2(ROOT / 'commons/font' / name, dest / name)
                files[name] = sha((dest / name).read_bytes())
        # Keep local code links inspectable without the Ada repository.
        text = text.replace('../Point_Coordinates/tutorial.md', '../Point_Coordinates/TUTORIAL.md')
        for other, _, _ in LESSONS:
            text = text.replace('../' + other + '/tutorial.md', '../' + other + '/TUTORIAL.md')
        text = text.replace('../../../doc/book/', 'http://localhost:3003/book-review/doc/book/')
        write(dest / 'TUTORIAL.md', text)
        study_y = 1.5 if hall == 'Point_Zero' else 0.0
        title = text.splitlines()[0].lstrip('# ').replace('"', '\\"')
        write(STARTER / (scene + '.tscn'), f'''[gd_scene load_steps=5 format=3]

[ext_resource type="PackedScene" path="res://base.tscn" id="Room"]
[ext_resource type="Script" path="res://lessons/{hall}/{main}" id="Lesson"]

[sub_resource type="StandardMaterial3D" id="BackdropFinish"]
albedo_color = Color(0.24, 0.23, 0.25, 1)
roughness = 0.95

[sub_resource type="BoxMesh" id="BackdropShape"]
size = Vector3(7.2, 3.0, 0.06)

[node name="AdaRoom" instance=ExtResource("Room")]
setup_check = false

[node name="PointStudy" type="Node3D" parent="."]
position = Vector3(0, {study_y}, -0.7)
script = ExtResource("Lesson")

[node name="Backdrop" type="MeshInstance3D" parent="."]
position = Vector3(0, 1.5, -3.0)
mesh = SubResource("BackdropShape")
material_override = SubResource("BackdropFinish")

[node name="Title" type="Label3D" parent="."]
position = Vector3(0, 3.1, -2.8)
pixel_size = 0.002
font_size = 36
outline_size = 0
text = "{title}"
''')
        exercises = {}
        edits = {
            'Point_Zero': ('counter_once.gd', '\nfunc _process(_delta: float) -> void:\n', ''),
            'Point_Lines': ('line_reversed.gd', 'var displacement := b - a', 'var displacement := a - b'),
            'Point_Line_Grid': ('grid_flat_y.gd', 'roundi(p.y / grid_step)', '0'),
        }
        if hall in edits:
            name, before, after = edits[hall]
            code = (dest / main).read_text(encoding='utf-8')
            assert code.count(before) == 1
            write(dest / name, code.replace(before, after))
            exercises[name] = sha((dest / name).read_bytes())
        rows.append({'hall': hall, 'scene': scene + '.tscn', 'main': main,
                     'source': source.relative_to(ROOT).as_posix(),
                     'source_sha256': sha(source.read_bytes()), 'files_sha256': files, 'carried': carried,
                     'exercises_sha256': exercises})
    write(STARTER / 'LESSONS.json', json.dumps({'edition': '2026-10-06',
        'authority': 'Current museum tutorial.md student-code blocks', 'lessons': rows}, indent=2) + '\n')
    assert_printed_code()
    # Read-only review server serves iteration evidence, not internal study folders.
    review = ROOT / 'doc/book/iterations/2026-10-06-starter-one-course/lessons'
    for row in rows:
        folder = review / row['hall']
        folder.mkdir(parents=True, exist_ok=True)
        for name in [*row['files_sha256'], *row['carried'], *row['exercises_sha256'], 'TUTORIAL.md']:
            shutil.copy2(STARTER / 'lessons' / row['hall'] / name, folder / name)
    return rows

def assert_printed_code():
    manifest = json.loads((STARTER / 'LESSONS.json').read_text())
    for row in manifest['lessons']:
        text = (STARTER / 'lessons' / row['hall'] / 'TUTORIAL.md').read_text(encoding='utf-8')
        for name, expected in row['files_sha256'].items():
            path = STARTER / 'lessons' / row['hall'] / name
            assert sha(path.read_bytes()) == expected, path
            if name.endswith('.gd'):
                block = re.findall(r'<!-- student-code:' + re.escape(name) + r' -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
                assert len(block) == 1 and block[0] == path.read_text(encoding='utf-8'), path
        for name, info in row.get('carried', {}).items():
            path = STARTER / 'lessons' / row['hall'] / name
            origin = STARTER / 'lessons' / info['from'] / name
            assert sha(path.read_bytes()) == info['sha256'] == sha(origin.read_bytes()), path
            assert not re.search(r'<!-- student-code:' + re.escape(name) + r' -->', text), (path, 'carried but also printed')

if __name__ == '__main__':
    print('Synced', len(sync_lessons()), 'museum lessons, including Coordinates.')
