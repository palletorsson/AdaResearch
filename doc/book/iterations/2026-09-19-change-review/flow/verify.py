from pathlib import Path
import difflib
import hashlib
import json

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[4]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def executable_lines(path):
    return [line for line in path.read_text(encoding='utf-8-sig').splitlines()
            if line.strip() and not line.lstrip().startswith('#')]

snapshots = json.loads((BASE / 'before-sha256.json').read_text(encoding='utf-8-sig'))
manifest = []
for item in snapshots:
    relative = item['path']
    before = BASE / 'before' / relative
    current = ROOT / relative
    diff = ''.join(difflib.unified_diff(
        before.read_text(encoding='utf-8-sig').splitlines(keepends=True),
        current.read_text(encoding='utf-8-sig').splitlines(keepends=True),
        fromfile='before/' + relative, tofile=relative))
    destination = BASE / 'diffs' / (Path(relative).name + '.diff')
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(diff, encoding='utf-8')
    manifest.append({'path': relative, 'before_sha256': digest(before),
                     'recorded_snapshot_matches': digest(before) == item['sha256'],
                     'after_sha256': digest(current), 'changed': digest(before) != digest(current)})

painter = 'commons/artifacts/flow_field_painter/flow_field_painter.gd'
checks = {
    'snapshot_hashes_match': all(row['recorded_snapshot_matches'] for row in manifest),
    'only_two_artifact_scripts_changed': {row['path'] for row in manifest if row['changed']} == {
        painter, 'commons/artifacts/flow_field_painter/shared_field_lesson.gd'},
    'painter_executable_lines_unchanged': executable_lines(ROOT / painter) == executable_lines(BASE / 'before' / painter),
    'map_final_tutorial_scene_unchanged': all(not row['changed'] for row in manifest if not row['path'].endswith('.gd')),
}
sources = [
    'commons/data/artifact_roles.json', 'commons/data/museum_core_encounters.json',
    'commons/artifacts/vector_field_visualizer/vector_field_visualizer.gd',
    'algorithms/change/vector_field_grid.gd', 'algorithms/change/particle_flow_swarm.gd',
    'algorithms/steering/noc_ch05/noc_5_04_flow_field_vr.gd',
    'commons/artifacts/grand_zoetrope/grand_zoetrope.gd',
    'commons/interactables/slider_horizontal.gd',
    'commons/scenes/endless_museum.gd', 'commons/scenes/em/em_detail.gd',
    'doc/book/REVIEW_PRINCIPLES.md', 'doc/book/review-feedback/2026-09-18/change/01-review.md',
    'doc/book/iterations/2026-09-19-change-review/flow/probe_flow.gd',
    'doc/book/iterations/2026-09-19-change-review/flow/run_probe.py',
]
chain = {p: digest(ROOT / p) for p in sources}
(BASE / 'source-manifest.json').write_text(json.dumps({'snapshots': manifest, 'inspected_sources_sha256': chain}, indent=2), encoding='utf-8')
runtime = {}
for phase in ['runtime-headless-v2', 'before-headless-v2', 'final-headless', 'before-runtime', 'after-runtime']:
    report = BASE / phase / 'checks.json'
    run_path = BASE / phase / 'run.json'
    if report.exists():
        data = json.loads(report.read_text())
        run = json.loads(run_path.read_text())
        runtime[phase] = {'checks': len(data['checks']), 'failures': data['failures'],
                          'returncode': run['returncode'],
                          'source_hashes_stable_during_run': run['source_sha256_before'] == run['source_sha256_after']}
pairs = []
for view in ['standing-hidden', 'standing-shown', 'near-arrows-trails']:
    first, second = BASE / 'before-runtime' / (view + '-camera.json'), BASE / 'after-runtime' / (view + '-camera.json')
    if first.exists() and second.exists():
        a, b = json.loads(first.read_text()), json.loads(second.read_text())
        pairs.append({'view': view, 'before': f'before-runtime/{view}.png', 'after': f'after-runtime/{view}.png',
                      'same_camera': all(a[k] == b[k] for k in ['position', 'target', 'fov', 'viewport']),
                      'before_sha256': digest(first.with_name(view + '.png')), 'after_sha256': digest(second.with_name(view + '.png'))})
if pairs:
    checks['paired_cameras_match'] = len(pairs) == 3 and all(pair['same_camera'] for pair in pairs)
    checks['paired_particle_states_match'] = digest(BASE / 'before-runtime/capture-particles.json') == digest(BASE / 'after-runtime/capture-particles.json')
    before_run = json.loads((BASE / 'before-runtime/run.json').read_text())
    after_run = json.loads((BASE / 'after-runtime/run.json').read_text())
    checks['paired_shared_museum_sources_match'] = all(before_run['source_sha256_before'][p] == after_run['source_sha256_before'][p] for p in ['commons/scenes/endless_museum.gd', 'commons/scenes/em/em_detail.gd'])
    (BASE / 'image-pairs.json').write_text(json.dumps(pairs, indent=2), encoding='utf-8')
result = {'checks': checks, 'runtime': runtime, 'headset_tested': False, 'learner_verified': False}
(BASE / 'verification.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result, indent=2))
assert all(checks.values())
assert all(not run['failures'] and run['returncode'] == 0 and run['source_hashes_stable_during_run'] for run in runtime.values())
