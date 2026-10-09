from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from build import HERE, ROOT, put, sha

ENGINE = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
VARIANTS = {
    'start': [],
    'red': [('var start := Vector3(0.48, 0.12, 0.36)', 'var start := Vector3(0.6, 0, 0)')],
    'wide': [('var box_size := Vector3(0.6, 0.6, 0.6)', 'var box_size := Vector3(1.2, 0.6, 0.6)')],
    'outside': [('var start := Vector3(0.48, 0.12, 0.36)', 'var start := Vector3(-0.2, 0.9, 0.3)')],
    'choice': [('var start := Vector3(0.48, 0.12, 0.36)', 'var start := Vector3(0.12, 0.48, 0.36)')],
    'transfer': [
        ('var readout: Label3D', 'var readout: Label3D\nvar other: MeshInstance3D\nvar other_material: StandardMaterial3D'),
        ('    add_child(preview)\n', '''    add_child(preview)

    other = MeshInstance3D.new()
    var other_box := BoxMesh.new()
    other_box.size = Vector3(0.32, 0.32, 0.04)
    other.mesh = other_box
    other.position = Vector3(-0.75, 0.3, 0)
    other_material = StandardMaterial3D.new()
    other_material.roughness = 0.35
    other.material_override = other_material
    add_child(other)
'''),
        ('    swatch.albedo_color = chosen', '    swatch.albedo_color = chosen\n    other_material.albedo_color = chosen'),
    ],
}
FAULTS = {
    'no_clamp': ('(p / size).clamp(Vector3.ZERO, Vector3.ONE)', '(p / size)', 'start/clamped_outside'),
    'wrong_frame': ('to_local(point.global_position)', 'point.global_position', 'start/local_frame_readout'),
    'one_divisor': ('(p / size).clamp', '(p / size.x).clamp', 'start/unequal_dimensions'),
    'missing_assignment': ('    swatch.albedo_color = chosen', '    pass # deliberate missing receiver assignment', 'start/material_assignment'),
    'swapped_channels': ('return Color(channels.x, channels.y, channels.z)', 'return Color(channels.z, channels.y, channels.x)', 'start/red_axis'),
}
PROTECTED = [
    'commons/maps/Color_Nails/tutorial.md', 'commons/maps/Color_Nails/final.md',
    'commons/maps/Color_Nails/map_data.json', 'commons/maps/sequences/color.json',
    'commons/interfaces/value_mapper_3d.gd', 'commons/interfaces/nail_color_controller.gd',
    'commons/artifacts/nail_salon/nail_salon.gd', 'commons/maps/Point_Lines/tutorial.md',
    'doc/book/course/execution-plan/plan.json',
]


def extract(text, filename):
    fence = chr(96) * 3
    blocks = re.findall(r'<!-- student-code:' + re.escape(filename) + r' -->\s*' + fence + r'gdscript\n(.*?)^' + fence, text, re.M | re.S)
    assert len(blocks) == 1
    return blocks[0]


def main():
    source = extract((HERE / 'tutorial.md').read_text(encoding='utf-8'), 'lesson.gd')
    assert source == (HERE / 'lesson.gd').read_text(encoding='utf-8')
    assert source.count('func _ready()') == 1 and '$' not in source
    prior = (ROOT / 'commons/maps/Point_Lines/tutorial.md').read_text(encoding='utf-8-sig')
    for name in ['point_body.gd', 'line_skin.gd']:
        assert (HERE / name).read_text(encoding='utf-8') == extract(prior, name)
    before = {p: sha(ROOT / p) for p in PROTECTED}
    snapshot = HERE / 'preserved-before.json'
    if snapshot.exists():
        assert before == json.loads(snapshot.read_text())
    else:
        put(snapshot, json.dumps(before, indent=2) + '\n')
    assert sha(HERE / 'final.md') == before['commons/maps/Color_Nails/final.md']
    work = Path(tempfile.mkdtemp(prefix='ada-nails-draft-'))
    addon = ROOT / 'addons/godot-xr-tools'
    shutil.copytree(addon, work / 'addons/godot-xr-tools')
    extensions = {'.gd', '.tscn', '.tres', '.gdshader'}
    dependencies = {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(addon.rglob('*')) if p.is_file() and p.suffix in extensions}
    assert all(sha(work / p) == h for p, h in dependencies.items())
    project = '''config_version=5
[application]
config/name="Ada Nails exact tutorial checks"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
[display]
window/size/viewport_width=64
window/size/viewport_height=64
'''
    put(work / 'project.godot', project)
    put(HERE / 'native-project.godot', project)
    for file in ['verify.gd', 'render_check.gd']:
        shutil.copyfile(HERE / file, work / file)
    for group in ['normal', *FAULTS]:
        for name, edits in VARIANTS.items():
            code = source
            for old, new in edits:
                assert code.count(old) == 1
                code = code.replace(old, new)
            if group != 'normal':
                old, new, _ = FAULTS[group]
                assert code.count(old) == 1
                code = code.replace(old, new)
            put(work / group / name / 'lesson.gd', code)
            if group == 'normal':
                put(HERE / 'variants' / name / 'lesson.gd', code)
            for helper in ['point_body.gd', 'line_skin.gd']:
                shutil.copyfile(HERE / helper, work / group / name / helper)
    base = [ENGINE, '--path', str(work), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--max-fps', '120']

    def run(name, args, expected, headless=True):
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = subprocess.SW_HIDE
        result = subprocess.run(base + (['--headless'] if headless else ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3']) + args, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60, creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=startup)
        log = result.stdout + result.stderr
        put(HERE / 'logs' / (name + '.log'), log)
        print(name, result.returncode, log[-450:], flush=True)
        assert result.returncode == expected and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log, log

    run('import', ['--editor', '--import', '--quit'], 0)
    results = {}
    for group in ['normal', *FAULTS]:
        path = work / (group + '.json')
        run(group, ['--script', 'res://verify.gd', '--', group, str(path)], 0 if group == 'normal' else 1)
        results[group] = json.loads(path.read_text())
        if group != 'normal':
            assert FAULTS[group][2] in results[group]['failure_ids']
        put(HERE / (group + '-report.json'), json.dumps(results[group], indent=2) + '\n')
    run('render', ['--script', 'res://render_check.gd', '--', str(HERE)], 0, headless=False)
    rendered = json.loads((HERE / 'render-report.json').read_text())
    assert rendered['passed']
    assert {p: sha(ROOT / p) for p in PROTECTED} == before
    assert all(sha(ROOT / p) == h for p, h in dependencies.items())
    names = ['tutorial.md', 'lesson.gd', 'point_body.gd', 'line_skin.gd', 'verify.gd', 'render_check.gd', 'run_checks.py', 'native-project.godot']
    report = {
        'passed': True, 'engine': 'Godot 4.6 stable', 'renderer': rendered['renderer'],
        'native_assertions': len(results['normal']['checks']), 'render_assertions': len(rendered['checks']),
        'printed_exercise_variants': 3, 'independent_choice_examples': 1, 'transfer_examples': 1,
        'variant_edits': VARIANTS, 'faults_rejected': len(FAULTS),
        'faults': {k: {'mutation': v[:2], 'required_failure': v[2], 'detected': True} for k, v in FAULTS.items()},
        'inputs': {str((HERE / n).relative_to(ROOT).as_posix()): sha(HERE / n) for n in names},
        'images': {p.name: sha(p) for p in HERE.glob('*.png')},
        'dependencies': dependencies, 'preserved': before, 'test_project': str(work),
        'scope': 'Exact printed continuation and inherited classes; native mapping/material/geometry checks; actual XR Tools grab driver with synthetic controller; isolated GPU fixture. No headset, full museum integration or human-learning test.'
    }
    put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
    print('PASS', report['native_assertions'], 'native;', report['render_assertions'], 'render;', len(FAULTS), 'faults rejected')


if __name__ == '__main__':
    main()
