from pathlib import Path
import hashlib, json, re, shutil, subprocess, tempfile
from write_lesson import HERE, ROOT, put

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
    'still': {},
    'translate': {'var start := Vector3(0, 1, 0)': 'var start := Vector3(1, 1, 0)'},
    'turn': {'var turn_degrees := 0.0': 'var turn_degrees := 45.0'},
    'scale': {'var size_factor := 1.0': 'var size_factor := 1.5'},
    'other-angle': {'var turn_degrees := 0.0': 'var turn_degrees := -30.0'},
    'rise': {'var rise := 0.0': 'var rise := 1.0'},
    'slow': {'var rise := 0.0': 'var rise := 1.0', 'var duration := 2.0': 'var duration := 4.0'},
    'combine': {'var rise := 0.0': 'var rise := 1.0', 'var turn_degrees := 0.0': 'var turn_degrees := 45.0', 'var size_factor := 1.0': 'var size_factor := 1.5'},
}
FAULTS = {
    'no-signal': ('sensor.body_entered.connect(_on_body_entered)', 'pass # Deliberately disconnect collection.', 'pickup/physics_collects/em_walker'),
    'no-player-filter': ('if body.is_in_group("em_walker") or body.is_in_group("player_body"):', 'if true:', 'pickup/ordinary_body_ignored'),
    'wrong-axis': ('cube.rotation_degrees.y = turn_degrees', 'cube.rotation_degrees.x = turn_degrees', 'rotation/declared_y_axis'),
    'frame-clock': ('elapsed += delta', 'elapsed += 1.0', 'time/30/0.5'),
    'accumulated-position': ('cube.position = start + Vector3.UP * rise * t', 'cube.position += start + Vector3.UP * rise * t', 'still/clock_does_not_require_motion'),
}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    text = (ROOT/'commons/maps/Trans_Pre/tutorial.md').read_text(encoding='utf-8')
    sources = {}
    for name in ['lesson.gd']:
        blocks = re.findall(r'<!-- student-code:' + re.escape(name) + r' -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
        assert len(blocks) == 1 and blocks[0] == (HERE/name).read_text(encoding='utf-8'), name
        sources[name] = blocks[0]
    work = Path(tempfile.mkdtemp(prefix='ada-trans-pre-'))
    put(work/'project.godot', 'config_version=5\n[application]\nconfig/name="' + work.name + '"\nconfig/features=PackedStringArray("4.6")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    shutil.copyfile(work/'project.godot', HERE/'native-project.godot')
    shutil.copyfile(HERE/'verify.gd', work/'verify.gd')
    for group in ['normal', *FAULTS]:
        for variant, edits in VARIANTS.items():
            for name, source in sources.items():
                if name == 'lesson.gd':
                    for before, after in edits.items():
                        assert source.count(before) == 1
                        source = source.replace(before, after)
                    if group in FAULTS:
                        before, after, _ = FAULTS[group]
                        assert source.count(before) == 1
                        source = source.replace(before, after)
                put(work/group/variant/name, source)
                if group == 'normal': put(HERE/'variants'/variant/name, source)
    common = [ENGINE, '--headless', '--path', str(work), '--xr-mode', 'off', '--audio-driver', 'Dummy']
    def run(name, args, expected):
        proc = subprocess.run(common + args, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60, creationflags=subprocess.CREATE_NO_WINDOW)
        log = proc.stdout + proc.stderr
        put(HERE/'logs'/(name+'.log'), log)
        print(name, proc.returncode, flush=True)
        assert proc.returncode == expected and 'ERROR:' not in log, log
    run('import', ['--editor', '--import', '--quit'], 0)
    results = {}
    for group in ['normal', *FAULTS]:
        run(group, ['--script', 'res://verify.gd', '--', group, str(work/(group+'.json'))], 0 if group == 'normal' else 1)
        results[group] = json.loads((work/(group+'.json')).read_text())
        if group in FAULTS: assert FAULTS[group][2] in results[group]['failure_ids']
        put(HERE/(group+'-report.json'), json.dumps(results[group], indent=2)+'\n')
    pins = {p.relative_to(ROOT).as_posix(): sha(p) for p in [ROOT/'commons/maps/Trans_Pre/tutorial.md', HERE/'native-project.godot', HERE/'run_checks.py', HERE/'verify.gd', *[HERE/n for n in sources]]}
    preservation = {name: sha(ROOT/'commons/maps/Trans_Pre'/name) == sha(HERE/'before/commons/maps/Trans_Pre'/name) for name in ['final.md', 'map_data.json']}
    assert all(preservation.values())
    report = {'passed': results['normal']['passed'], 'engine': 'Godot 4.6 stable', 'assertions': len(results['normal']['checks']), 'variants': VARIANTS, 'faults': {name: {'mutation': FAULTS[name][:2], 'required_failure': FAULTS[name][2], 'detected': True} for name in FAULTS}, 'inputs': pins, 'unchanged_helpers': list(sources)[1:], 'preserved': preservation, 'test_project': str(work), 'scope': 'Exact printed code and value-edited variants in native Godot. Actual process callback plus controlled time steps. No headset or learner-understanding claim.'}
    put(HERE/'verification.json', json.dumps(report, indent=2)+'\n')
    print('PASS', report['assertions'], 'assertions;', len(FAULTS), 'deliberate faults rejected')

if __name__ == '__main__': main()
