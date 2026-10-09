from pathlib import Path
import json
import re
import shutil
import subprocess
import tempfile
from build import HERE, ROOT, put, sha

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
    'row': [],
    'plane': [('var depth := 1', 'var depth := 4')],
    'spaced': [('var depth := 1', 'var depth := 4'), ('var spacing := 1.6', 'var spacing := 2.0')],
    'turned': [('var depth := 1', 'var depth := 4'), ('    refresh_readout()\n\nfunc make_cube', '    cubes[1][0].rotation_degrees.y = 45.0\n    refresh_readout()\n\nfunc make_cube')],
    'choice': [('var depth := 1', 'var depth := 4'), ('    refresh_readout()\n\nfunc make_cube', '    cubes[2][1].rotation_degrees.y = 30.0\n    refresh_readout()\n\nfunc make_cube')],
    'empty_width': [('var width := 4', 'var width := 0')],
    'empty_depth': [('var depth := 1', 'var depth := 0')],
    'single': [('var width := 4', 'var width := 1')],
}
FAULTS = {
    'disconnected_signal': ('sensor.body_entered.connect(_on_body_entered.bind(x, z))', 'pass # Deliberately disconnect collection.', 'fault/collects_named_address'),
    'swapped_binding': ('_on_body_entered.bind(x, z)', '_on_body_entered.bind(z, x)', 'fault/collects_named_address'),
    'whole_study_removed': ('cubes[x][z].queue_free()', 'queue_free()', 'fault/study_survives'),
    'shift_slot': ('grid_data[x][z] = 0', 'grid_data[x].remove_at(z)', 'fault/retained_length'),
    'shared_rows': ('grid_data.append([])', 'grid_data.append(grid_data[0] if x > 0 else [])', 'fault/independent_rows'),
    'unrecorded_collection': ('grid_data[x][z] = 0', 'pass # Deliberately omit the occupancy write.', 'fault/presence_updated'),
}

def main():
    manuscript = (HERE / 'tutorial.md').read_text(encoding='utf-8')
    blocks = re.findall(r'<!-- student-code:lesson.gd -->\s*```gdscript\n(.*?)^```', manuscript, re.M | re.S)
    assert len(blocks) == 1
    source = blocks[0]
    assert source == (HERE / 'lesson.gd').read_text(encoding='utf-8')
    assert source.count('func _ready()') == 1 and '$' not in source
    protected = ['commons/maps/Array/tutorial.md', 'commons/maps/Array/final.md', 'commons/maps/Array/map_data.json', 'commons/maps/sequences/array_tutorial.json', 'doc/book/course/execution-plan/plan.json']
    before = {p: sha(ROOT / p) if (ROOT / p).exists() else None for p in protected}
    if not (HERE / 'preserved-before.json').exists():
        put(HERE / 'preserved-before.json', json.dumps(before, indent=2) + '\n')
    else:
        assert before == json.loads((HERE / 'preserved-before.json').read_text())
    work = Path(tempfile.mkdtemp(prefix='ada-array-draft-'))
    project = 'config_version=5\n[application]\nconfig/name="Ada Array exact tutorial checks"\nconfig/features=PackedStringArray("4.6")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
    put(work / 'project.godot', project)
    put(HERE / 'native-project.godot', project)
    shutil.copyfile(HERE / 'verify.gd', work / 'verify.gd')
    for group in ['normal', *FAULTS]:
        variants = VARIANTS if group == 'normal' else {'plane': VARIANTS['plane']}
        for name, edits in variants.items():
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
        print(name, result.returncode, log[-350:], flush=True)
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
    after = {p: sha(ROOT / p) if (ROOT / p).exists() else None for p in protected}
    assert after == before
    files = [HERE / name for name in ['tutorial.md', 'lesson.gd', 'verify.gd', 'run_checks.py', 'native-project.godot']]
    report = {
        'passed': True, 'engine':'Godot 4.6 stable',
        'assertions':len(results['normal']['checks']), 'variants':3,
        'transfer_examples':1, 'edge_case_variants':3, 'configurations_including_baseline':8,
        'variant_edits':VARIANTS, 'faults_rejected':len(FAULTS),
        'faults':{k:{'mutation':v[:2], 'required_failure':v[2], 'detected':True} for k,v in FAULTS.items()},
        'inputs':{p.relative_to(ROOT).as_posix():sha(p) for p in files},
        'preserved':after, 'test_project':str(work),
        'scope':'Exact printed self-contained study, actual native physics overlaps with synthetic CharacterBody3D capsules on declared desktop/XR layers; translated and rotated host; object and resource identity, retained slots, reference clearing, repeated collection, bounds, empty and single cases, readout initialization and exercise variants. No headset, full museum runtime integration or human learning test.'
    }
    put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
    print('PASS', report['assertions'], 'native checks;', len(FAULTS), 'faults rejected')

if __name__ == '__main__':
    main()
