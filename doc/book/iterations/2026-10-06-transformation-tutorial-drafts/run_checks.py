from pathlib import Path
import json
import re
import shutil
import subprocess
import tempfile
from build import HERE, ROOT, HALLS, put, sha

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
 'Trans_Pre': {
  'still': [('var rise := 0.35', 'var rise := 0.0'), ('var turn_speed := 45.0', 'var turn_speed := 0.0'), ('var pulse := 0.2', 'var pulse := 0.0')],
  'rise': [('var turn_speed := 45.0', 'var turn_speed := 0.0'), ('var pulse := 0.2', 'var pulse := 0.0')],
  'rise_turn': [('var pulse := 0.2', 'var pulse := 0.0')],
  'slow': [('var period := 4.0', 'var period := 8.0')]},
 'Trans_Introduction': {
  'near': [('var animate := true', 'var animate := false')],
  'far': [('var animate := true', 'var animate := false'), ('var pose := 0.0', 'var pose := 1.0')],
  'moved': [('var animate := true', 'var animate := false'), ('var pose := 0.0', 'var pose := 1.0'), ('var far_gap := 0.0', 'var far_gap := 0.5')],
  'middle': [('var animate := true', 'var animate := false'), ('var pose := 0.0', 'var pose := 0.5')]},
 'Trans_Translation': {
  'corner': [('var via_corner := false', 'var via_corner := true')],
  'diagonal': [('var via_corner := false', 'var via_corner := true'), ('var finish := Vector3(2, 3, 0)', 'var finish := Vector3(2, 3, 2)')]},
 'Trans_Rotation': {
  'orbit': [('var offset := Vector3.ZERO', 'var offset := Vector3(2, 0, 0)')],
  'vertical': [('var offset := Vector3.ZERO', 'var offset := Vector3(2, 0, 0)'), ('var axis := Vector3.UP', 'var axis := Vector3.FORWARD')]},
 'Trans_Scale': {
  'large': [('var factors := Vector3.ONE', 'var factors := Vector3(4, 4, 4)')],
  'wide': [('var factors := Vector3.ONE', 'var factors := Vector3(4, 1, 1)')],
  'double': [('var factors := Vector3.ONE', 'var factors := Vector3(2, 2, 1)')]},
 'Trans_Body': {
  'turn': [('var turn_instead := false', 'var turn_instead := true')],
  'far': [('var far_distance := 4.0', 'var far_distance := 6.0')]},
 'Trans_Pit': {
  'slow': [('var duration := 3.0', 'var duration := 6.0')],
  'wider': [('var slide := 1.15', 'var slide := 1.5')]},
}
FAULTS = {
 'curved_pre_timing': ('Trans_Pre', 'pingpong(2.0 * elapsed / period + 0.5, 1.0)', '0.5 + 0.5 * sin(TAU * elapsed / period)', 'pre/steady_midleg'),
 'frozen_turn': ('Trans_Pre', 'cube.rotation_degrees.y = turn_speed * elapsed', 'cube.rotation_degrees.y = turn_speed', 'pre/continuous_turn'),
 'disconnected_pickup': ('Trans_Pre', 'sensor.body_entered.connect(_on_body_entered)', 'pass # Deliberately disconnect pickup.', 'pre/overlap_em_walker'),
 'one_axis_growth': ('Trans_Introduction', 'grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)', 'grow.scale = Vector3(1.0, lerpf(0.25, 1.0, t), 1.0)', 'intro/start_growth'),
 'turning_translation': ('Trans_Translation', 'elapsed += delta', 'elapsed += delta\n    cube.rotation_degrees.y = elapsed * 30.0', 'translation/level_base30'),
 'wrong_pivot': ('Trans_Rotation', 'pivot.basis = Basis(axis.normalized(), angle)', 'cube.basis = Basis(axis.normalized(), angle)', 'rotation/quarter_centre_orbit'),
 'scaled_witness': ('Trans_Scale', 'add_child(point)', 'doorway.add_child(point)', 'scale/witness_fixed_large'),
 'height_leaks_into_distance': ('Trans_Body', 'separation.y = 0.0', 'pass # Deliberately retain height.', 'body/height_ignored_em_walker'),
 'floating_base': ('Trans_Body', 'cube.position.y = factor * 0.5', 'cube.position.y = 0.5', 'body/floor_em_walker0.0'),
 'frame_based_door': ('Trans_Pit', 'delta / duration', '1.0 / duration', 'pit/progress_slow30'),
 'missing_door_collision': ('Trans_Pit', 'body.add_child(collision)', 'collision.free()', 'pit/closed_blocks_em_walker'),
 'unshrunk_door_collision': ('Trans_Pit', 'shapes[i].size = LEAF_SIZE * factor', 'shapes[i].size = LEAF_SIZE', 'pit/withdrawn_collision_em_walker'),
}

def main():
    sources = {}
    for hall in HALLS:
        text = (HERE / hall / 'tutorial.md').read_text(encoding='utf-8')
        blocks = re.findall(r'<!-- student-code:lesson.gd -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
        assert len(blocks) == 1
        sources[hall] = blocks[0]
        assert sources[hall] == (HERE / hall / 'lesson.gd').read_text(encoding='utf-8')
        assert '$' not in sources[hall]
        assert sources[hall].count('func _ready()') == 1
    work = Path(tempfile.mkdtemp(prefix='ada-transformation-drafts-'))
    put(work / 'project.godot', 'config_version=5\n[application]\nconfig/name="Ada Transformation draft tests"\nconfig/features=PackedStringArray("4.6")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    shutil.copyfile(work / 'project.godot', HERE / 'native-project.godot')
    shutil.copyfile(HERE / 'verify.gd', work / 'verify.gd')
    for group in ['normal', *FAULTS]:
        for hall in HALLS:
            for variant, edits in {'base': [], **VARIANTS[hall]}.items():
                source = sources[hall]
                for before, after in edits:
                    assert source.count(before) == 1
                    source = source.replace(before, after)
                if group != 'normal' and FAULTS[group][0] == hall:
                    _, before, after, _ = FAULTS[group]
                    assert source.count(before) == 1
                    source = source.replace(before, after)
                put(work / group / hall / variant / 'lesson.gd', source)
                if group == 'normal': put(HERE / 'variants' / hall / variant / 'lesson.gd', source)
    common = [ENGINE, '--headless', '--path', str(work), '--xr-mode', 'off', '--audio-driver', 'Dummy']
    def run(name, args, expected):
        p = subprocess.run(common + args, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
        log = p.stdout + p.stderr
        put(HERE / 'logs' / (name + '.log'), log)
        print(name, p.returncode, log[-400:], flush=True)
        assert p.returncode == expected and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log, log
    run('import', ['--editor', '--import', '--quit'], 0)
    results = {}
    for group in ['normal', *FAULTS]:
        report = work / (group + '.json')
        run(group, ['--script', 'res://verify.gd', '--', group, str(report)], 0 if group == 'normal' else 1)
        results[group] = json.loads(report.read_text())
        if group != 'normal': assert FAULTS[group][3] in results[group]['failure_ids'], results[group]['failure_ids']
        put(HERE / (group + '-report.json'), json.dumps(results[group], indent=2) + '\n')
    pins = {}
    for p in [HERE / 'run_checks.py', HERE / 'verify.gd', HERE / 'native-project.godot', *[HERE / hall / name for hall in HALLS for name in ['tutorial.md', 'lesson.gd']]]:
        pins[p.relative_to(ROOT).as_posix()] = sha(p)
    preserved = {path: sha(ROOT / path) == digest for path, digest in json.loads((HERE / 'preserved-before.json').read_text()).items()}
    assert all(preserved.values())
    report = {'passed': True, 'engine': 'Godot 4.6 stable', 'assertions': len(results['normal']['checks']), 'variant_count': sum(len(v) for v in VARIANTS.values()), 'hall_count': len(HALLS), 'variants': VARIANTS, 'faults': {name: {'map': f[0], 'mutation': f[1:3], 'required_failure': f[3], 'detected': True} for name, f in FAULTS.items()}, 'inputs': pins, 'preserved': preserved, 'test_project': str(work), 'scope': 'Exact printed programs in native Godot; numeric transform/geometry checks; controlled time and real process/physics callbacks; physics overlaps with synthetic desktop/XR bodies; capsule collision blocks a closed door and passes an open door; intermediate collision dimensions match visuals; native query checks withdrawn collision. No headset, human-learning or full-museum rider-system claim.'}
    put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
    print('PASS', report['assertions'], 'checks;', len(FAULTS), 'faults rejected;', report['variant_count'], 'exercise variants')

if __name__ == '__main__':
    main()
