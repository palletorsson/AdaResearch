from pathlib import Path
import json
import re
import shutil
import subprocess
import tempfile
from build import HERE, ROOT, put, sha

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
    'separate': [],
    'blue': [('var beam_colour := Color(1, 0, 0)', 'var beam_colour := Color(0, 0, 1)')],
    'overlap': [('var first_target := Vector3(-1, 1.5, 0)', 'var first_target := Vector3(1, 1.5, 0)')],
    'away': [('var first_target := Vector3(-1, 1.5, 0)', 'var first_target := Vector3(-1, 1.5, 5)')],
    'choice': [('var first_target := Vector3(-1, 1.5, 0)', 'var first_target := Vector3(0, 2, 0)')],
}
FAULTS = {
    'repainted_surface': ('surface.albedo_color = Color(0.9, 0.9, 0.9)', 'surface.albedo_color = beam_colour', 'separate/material_unchanged'),
    'local_used_as_world': ('lamp.look_at(to_global(target))', 'lamp.look_at(target)', 'separate/first_world_target'),
    'backward_aim': ('lamp.look_at(to_global(target))', 'lamp.look_at(to_global(target), Vector3.UP, true)', 'separate/first_world_target'),
    'zero_energy': ('lamp.light_energy = 2.5', 'lamp.light_energy = 0.0', 'separate/range_angle_energy_0'),
    'shared_light': ('second_light = make_light(Color(0, 1, 0), Vector3(1, 1.5, 2.5), Vector3(1, 1.5, 0))', 'second_light = first_light', 'separate/distinct_lights'),
}
PROTECTED = [
    'commons/maps/Color_Flashlight/tutorial.md',
    'commons/maps/Color_Flashlight/final.md',
    'commons/maps/Color_Flashlight/map_data.json',
    'commons/maps/sequences/color.json',
    'algorithms/postprocessing/flashlight_demo/flashlight_color.gd',
    'algorithms/postprocessing/flashlight_demo/flashlight.tscn',
    'algorithms/postprocessing/flashlight_demo/flashlight_demo.gd',
    'doc/book/course/execution-plan/plan.json',
]


def main():
    manuscript = (HERE / 'tutorial.md').read_text(encoding='utf-8')
    fence = chr(96) * 3
    blocks = re.findall(r'<!-- student-code:lesson.gd -->\s*' + fence + r'gdscript\n(.*?)^' + fence, manuscript, re.M | re.S)
    assert len(blocks) == 1
    source = blocks[0]
    assert source == (HERE / 'lesson.gd').read_text(encoding='utf-8')
    assert source.count('func _ready()') == 1 and '$' not in source and 'preload(' not in source
    before = {p: sha(ROOT / p) for p in PROTECTED}
    snapshot = HERE / 'preserved-before.json'
    put(HERE / 'run-source-start.json', json.dumps(before, indent=2) + '\n')
    assert sha(HERE / 'final.md') == before['commons/maps/Color_Flashlight/final.md']
    work = Path(tempfile.mkdtemp(prefix='ada-flashlight-draft-'))
    project = 'config_version=5\n[application]\nconfig/name="Ada Flashlight exact tutorial checks"\nconfig/features=PackedStringArray("4.6")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[display]\nwindow/size/viewport_width=64\nwindow/size/viewport_height=64\n'
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
    base = [ENGINE, '--path', str(work), '--xr-mode', 'off', '--audio-driver', 'Dummy']

    def run(name, args, expected, headless=True):
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = subprocess.SW_HIDE
        result = subprocess.run(base + (['--headless'] if headless else ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3']) + args, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=45, creationflags=subprocess.CREATE_NO_WINDOW, startupinfo=startup)
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
    after = {p: sha(ROOT / p) for p in PROTECTED}
    assert after == before
    files = [HERE / name for name in ['tutorial.md', 'lesson.gd', 'verify.gd', 'render_check.gd', 'run_checks.py', 'native-project.godot']]
    report = {
        'passed': True, 'engine': 'Godot 4.6 stable', 'renderer': rendered['renderer'],
        'native_assertions': len(results['normal']['checks']), 'render_assertions': len(rendered['checks']),
        'printed_exercise_variants': 3, 'independent_choice_examples': 1,
        'variant_edits': VARIANTS, 'faults_rejected': len(FAULTS),
        'faults': {k: {'mutation': v[:2], 'required_failure': v[2], 'detected': True} for k, v in FAULTS.items()},
        'inputs': {p.relative_to(ROOT).as_posix(): sha(p) for p in files},
        'images': {p.name: sha(p) for p in HERE.glob('*.png')},
        'preserved': after, 'test_project': str(work),
        'scope': 'Exact printed program; native scene/material/light behaviour in translated/rotated host; exact exercise variants; isolated GPU renders sampled for colour, overlap and withdrawal with fixed camera, board and ambient light. No full museum integration, headset or human-learning test.'
    }
    put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
    print('PASS', report['native_assertions'], 'native;', report['render_assertions'], 'render;', len(FAULTS), 'faults rejected')


if __name__ == '__main__':
    main()
