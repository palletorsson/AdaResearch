from pathlib import Path
import json
import re
import shutil
import subprocess
import tempfile
from build import HERE, ROOT, put, sha

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
    'one': [],
    'grouped': [('[0, 0, 0, 0, 0]', '[1, 1, 2, 1, 2]')],
    'recoloured': [('[0, 0, 0, 0, 0]', '[1, 1, 2, 1, 2]'), ('Color(0.80, 0.16, 0.16)', 'Color(0.90, 0.22, 0.48)')],
    'alternating': [('[0, 0, 0, 0, 0]', '[1, 2, 1, 2, 1]')],
    'choice': [('[0, 0, 0, 0, 0]', '[2, 0, 1, 0, 2]')],
}
FAULTS = {
    'shared_material': ('    material.roughness = 0.55', '    material.roughness = 0.55\n    if not parts.is_empty():\n        material = parts[0].material_override', 'live/one_material_edit_is_local'),
    'ignored_assignment': ('material.albedo_color = palette[slot]', 'material.albedo_color = palette[0]', 'grouped/assigned_colours'),
    'wrong_palette_index': ('material.albedo_color = palette[slot]', 'material.albedo_color = palette[(slot + 1) % palette.size()]', 'one/assigned_colours'),
    'colour_moves_geometry': ('material.albedo_color = palette[slot]', 'material.albedo_color = palette[slot]\n        parts[i].position.y += 0.1', 'live/reassignment_preserves_geometry'),
    'rebuilds_mesh': ('material.albedo_color = palette[slot]', 'material.albedo_color = palette[slot]\n        parts[i].mesh = parts[i].mesh.duplicate()', 'one/repaint_preserves_objects_geometry_and_pose'),
}
PROTECTED = ['commons/maps/Color_Context_Placed/tutorial.md', 'commons/maps/Color_Context_Placed/final.md', 'commons/maps/Color_Context_Placed/map_data.json', 'commons/maps/sequences/color.json', 'commons/artifacts/chroma_stack/chroma_stack.gd', 'doc/book/course/execution-plan/plan.json']


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
    assert sha(HERE / 'final.md') == before['commons/maps/Color_Context_Placed/final.md']
    work = Path(tempfile.mkdtemp(prefix='ada-colour-draft-'))
    project = 'config_version=5\n[application]\nconfig/name="Ada Colour exact tutorial checks"\nconfig/features=PackedStringArray("4.6")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
    put(work / 'project.godot', project)
    put(HERE / 'native-project.godot', project)
    shutil.copyfile(HERE / 'verify.gd', work / 'verify.gd')
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
    base = [ENGINE, '--headless', '--path', str(work), '--xr-mode', 'off', '--audio-driver', 'Dummy']

    def run(name, args, expected):
        result = subprocess.run(base + args, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60, creationflags=subprocess.CREATE_NO_WINDOW)
        log = result.stdout + result.stderr
        put(HERE / 'logs' / (name + '.log'), log)
        print(name, result.returncode, log[-500:], flush=True)
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
    after = {p: sha(ROOT / p) for p in PROTECTED}
    assert after == before
    files = [HERE / name for name in ['tutorial.md', 'lesson.gd', 'verify.gd', 'run_checks.py', 'native-project.godot']]
    report = {
        'passed': True, 'engine': 'Godot 4.6 stable',
        'assertions': len(results['normal']['checks']), 'printed_exercise_variants': 3,
        'independent_choice_examples': 1, 'configurations_including_baseline': 5,
        'variant_edits': VARIANTS, 'faults_rejected': len(FAULTS),
        'faults': {k: {'mutation': v[:2], 'required_failure': v[2], 'detected': True} for k, v in FAULTS.items()},
        'inputs': {p.relative_to(ROOT).as_posix(): sha(p) for p in files},
        'preserved': after, 'test_project': str(work),
        'scope': 'Exact printed self-contained five-part program. Native meshes, dimensions, contiguous levels, material assignment and independence; live edits preserve object/resource identity, geometry and transforms; translated/rotated host; three printed edits and one transfer example. Headless: no rendered-pixel, full museum integration, headset or human-learning test.'
    }
    put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
    print('PASS', report['assertions'], 'native checks;', len(FAULTS), 'faults rejected')


if __name__ == '__main__':
    main()
