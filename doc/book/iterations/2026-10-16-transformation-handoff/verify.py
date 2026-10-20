"""Reconstruct the student's files using tutorial edits, then run those files in Godot."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re
import shutil
import subprocess
import tempfile
from prepare import HERE, ROOT, HALLS, put, sha, code

EARLIER = ROOT / 'doc/book/iterations/2026-10-12-transformation-in-the-book'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def apply(files, op, new):
    name = op['file']
    source = files.get(name, '')
    kind = op['kind']
    if kind == 'create':
        assert name not in files, 'File already exists: ' + name
        files[name] = new
        return
    assert name in files, 'Missing incoming file: ' + name
    if kind == 'append':
        assert not re.search(r'^func ' + re.escape(new.split('func ', 1)[1].split('(', 1)[0]) + r'\(', source, re.M), 'Function already exists'
        files[name] = source.rstrip() + '\n\n' + new
        return
    assert op['old'] and source.count(op['old']) == 1, 'Missing or ambiguous anchor: ' + op['id']
    replacement = op['old'] + '\n' + new if kind == 'insert_after' else new + '\n' + op['old'] if kind == 'insert_before' else new
    files[name] = source.replace(op['old'], replacement)

def assemble():
    manifest = json.loads((HERE / 'edits.json').read_text(encoding='utf-8'))
    origin = (HERE / manifest['incoming']).read_text(encoding='utf-8')
    assert origin == code((ROOT / 'commons/maps/Primitives_Melencolia/tutorial.md').read_text(encoding='utf-8'))
    assert origin == code((HERE / 'before/Primitives_Melencolia/tutorial.md').read_text(encoding='utf-8'))
    files = {'lesson.gd': origin}
    records, rejected = [], []
    snapshots = {}
    for op in manifest['operations']:
        hall = 'Trans_Introduction' if op['stage'] == 'comparison' else 'Trans_Pre'
        text = (ROOT / 'commons/maps' / hall / 'tutorial.md').read_text(encoding='utf-8')
        assert op['instruction'] in text, 'Printed location instruction changed: ' + op['id']
        pattern = r'<!-- student-edit:' + re.escape(op['marker']) + r' -->\s*(?:<!-- student-code:[^>]+ -->\s*)?```gdscript\n(.*?)^```'
        blocks = re.findall(pattern, text, re.M | re.S)
        assert len(blocks) == 1, op['id']
        new = blocks[0]
        assert hashlib.sha256(new.encode()).hexdigest() == op['expected_sha256'], 'Printed edit changed; review its contract: ' + op['id']
        source = files.get(op['file'], '')
        line = source[:source.index(op['old'])].count('\n') + 1 if op['old'] else None
        if op['kind'] in ['replace', 'insert_after', 'insert_before']:
            for fault, changed in [('missing', source.replace(op['old'], '')), ('ambiguous', source + '\n' + op['old'])]:
                try:
                    apply({**files, op['file']: changed}, op, new)
                except AssertionError:
                    rejected.append(op['id'] + '/' + fault)
                else:
                    raise AssertionError('Unsafe edit accepted: ' + op['id'] + '/' + fault)
        apply(files, op, new)
        records.append({'id':op['id'], 'file':op['file'], 'stage':op['stage'], 'incoming_line':line,
                        'instruction':op['instruction'], 'sha256_after':hashlib.sha256(files[op['file']].encode()).hexdigest()})
        if op['id'] in ['pre-clock', 'pre-collect', 'intro-clock']:
            state = {'pre-clock':'movement', 'pre-collect':'Trans_Pre', 'intro-clock':'Trans_Introduction'}[op['id']]
            snapshots[state] = dict(files)
    for state, files in snapshots.items():
        hall = 'Trans_Pre' if state == 'movement' else state
        for name, source in files.items():
            expected_name = 'movement.gd' if state == 'movement' and name == 'lesson.gd' else name
            expected = (HERE / hall / expected_name).read_text(encoding='utf-8')
            assert source == expected, 'Assembled file differs from full file: ' + state + '/' + name
            put(HERE / 'assembled' / state / name, source)
        if state != 'movement':
            assert code((ROOT / 'commons/maps' / hall / 'tutorial.md').read_text(encoding='utf-8')) == files['lesson.gd']
            assert files['lesson.gd'].count('func _ready()') == 1
            assert '$' not in files['lesson.gd']
    assert snapshots['Trans_Pre']['box_body.gd'] == snapshots['Trans_Introduction']['box_body.gd']
    result = dict(passed=True, transitions=3, printed_edits=len(records), rejected_anchor_faults=rejected, edits=records,
                  untouched_helper_sha256=hashlib.sha256(snapshots['Trans_Pre']['box_body.gd'].encode()).hexdigest())
    put(HERE / 'assembly-report.json', json.dumps(result, indent=2) + '\n')
    return snapshots, result

def main():
    snapshots, assembly = assemble()
    spec = importlib.util.spec_from_file_location('archived_checks', EARLIER / 'run_checks.py')
    archived = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(archived)
    variants = {hall:archived.VARIANTS[hall] for hall in HALLS}
    faults = {name:f for name,f in archived.FAULTS.items() if f[0] in HALLS}
    work = Path(tempfile.mkdtemp(prefix='ada-transformation-handoff-'))
    config = '''config_version=5
[application]
config/name="Ada — reconstructed tutorial handoff"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
'''
    put(work / 'project.godot', config)
    put(HERE / 'native-project.godot', config)
    addon = ROOT / 'doc/book/studies/ada-xr-starter/addons/godot-xr-tools'
    shutil.copytree(addon, work / 'addons/godot-xr-tools', ignore=shutil.ignore_patterns('.git', '*.import', '*.uid'))
    shutil.copytree(HERE / 'Primitives_Melencolia', work / 'predecessor')
    shutil.copyfile(HERE / 'verify.gd', work / 'verify.gd')
    for group in ['normal', *faults]:
        for hall in HALLS:
            for variant, changes in {'base':[], **variants[hall]}.items():
                source = snapshots[hall]['lesson.gd']
                for old, new in changes:
                    assert source.count(old) == 1
                    source = source.replace(old, new)
                if group != 'normal' and faults[group][0] == hall:
                    _, old, new, _ = faults[group]
                    assert source.count(old) == 1
                    source = source.replace(old, new)
                put(work / group / hall / variant / 'lesson.gd', source)
                put(work / group / hall / variant / 'box_body.gd', snapshots[hall]['box_body.gd'])
        for name, source in snapshots['movement'].items():
            put(work / group / 'movement/base' / name, source)
    common = [ENGINE, '--headless', '--path', str(work), '--xr-mode', 'off', '--audio-driver', 'Dummy']
    def run(name, args, expected):
        p = subprocess.run(common + args, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120, creationflags=subprocess.CREATE_NO_WINDOW)
        log = p.stdout + p.stderr
        put(HERE / 'logs' / (name + '.log'), log)
        print(name, p.returncode, log[-600:], flush=True)
        assert p.returncode == expected and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log, log[-8000:]
    run('import', ['--editor', '--import', '--quit'], 0)
    results = {}
    for group in ['normal', *faults]:
        dest = work / (group + '.json')
        run(group, ['--script', 'res://verify.gd', '--', group, str(dest)], 0 if group == 'normal' else 1)
        results[group] = json.loads(dest.read_text(encoding='utf-8'))
        if group != 'normal':
            assert faults[group][3] in results[group]['failure_ids']
        put(HERE / (group + '-report.json'), json.dumps(results[group], indent=2) + '\n')
    preserved = {name:sha(ROOT / name) == value for name,value in json.loads((HERE / 'before.json').read_text()).items() if name.endswith('/final.md')}
    assert all(preserved.values())
    inputs = {str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in [HERE / 'verify.py', HERE / 'verify.gd', HERE / 'edits.json', *[ROOT / 'commons/maps' / h / 'tutorial.md' for h in ['Point_Animatedcube','Primitives_Melencolia',*HALLS]], *[p for p in (HERE / 'assembled').rglob('*.gd')], *[p for p in (HERE / 'Primitives_Melencolia').glob('*.gd')]]}
    report = dict(passed=True, engine='Godot 4.6 stable', assertions=len(results['normal']['checks']), variants=sum(map(len,variants.values())),
                  assembly=assembly, faults={name:dict(detected=True, required_failure=f[3]) for name,f in faults.items()},
                  inputs=inputs, preserved=preserved, test_project=str(work),
                  scope='Native runtime, actual prior Melencolia program with real XR Tools, printed-edit assembly, movement checkpoint, independent meshes, timing and real physics overlap. Synthetic museum player bodies; no headset, rider-system or human-learning claim.')
    put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
    print('PASS', report['assertions'], 'native assertions;', report['variants'], 'variants;', len(faults), 'behaviour faults detected;', len(assembly['rejected_anchor_faults']), 'bad anchors rejected')

if __name__ == '__main__':
    main()
