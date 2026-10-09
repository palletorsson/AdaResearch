"""Collect already-run checks with their actual native exit status."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
def read(path): return json.loads((HERE/path).read_text(encoding='utf-8-sig'))
def collect(result_path, run_path, scope):
    result, run = read(result_path), read(run_path)
    checks = result['checks']
    failed = result.get('failures', [])
    if isinstance(checks, list):
        failed = [c for c in checks if not c.get('ok', c.get('pass', False))]
        checks = len(checks)
    before = run.get('source_sha256_before', run.get('before'))
    after = run.get('source_sha256_after', run.get('after'))
    return dict(scope=scope, result=result_path, run=run_path, checks=checks,
                failed_checks=failed, returncode=run['returncode'],
                watched_sources_stable=(before == after) if before is not None else None,
                clean_exit_and_assertions=(run['returncode'] == 0 and not failed))

evidence = {
    'structure': read('structure/verification.json'),
    'relaxation_controls': collect('relaxation/control-final-v3/controls-checks.json', 'relaxation/control-final-v3/controls-run.json', 'Isolated controls and configuration lifecycle'),
    'relaxation_before': collect('relaxation/paired-before/museum-checks.json', 'relaxation/paired-before/museum-run.json', 'Original-script replay in actual museum'),
    'relaxation_after': collect('relaxation/final-visible-after/museum-checks.json', 'relaxation/final-visible-after/museum-run.json', 'Actual museum, final visible controls and matched experiments'),
    'diagram': collect('diagram/check.json', 'diagram/run.json', 'Isolated actual static artifact; same-camera original/current labels'),
    'optimizer': collect('search/after/optimizer/optimizer.json', 'search/after/optimizer/run.json', 'Isolated repaired optimizer, boundary and small-slope branches'),
    'annealing_q_isolated_unresolved': collect('search/after/annealing_q/focused.json', 'search/after/annealing_q/run.json', 'Behavior checks completed; native access violation during teardown; NOT a clean passing run'),
    'annealing_museum': collect('search/standing/Annealing/museum.json', 'search/standing/Annealing/run.json', 'Actual museum under frozen shared loader; world camera y=1.7 m. Q installed at half authored scale, explicitly recorded; see audit for footprint scope'),
    'forge_museum': collect('search/after/Forge/museum.json', 'search/after/Forge/run.json', 'Actual museum optimizer behavior; shared source changed during run, excluded from matched visual comparisons'),
    'historical_descent': {'checks':36, 'fresh_run':False, 'fingerprints': 'descent-historical-evidence.json'},
    'headset_tested':False, 'learner_tested':False,
    'diagram_wrapper_note':'Godot completed all seven checks and exited 0. A subsequent Python console print failed on a Unicode checkmark under cp1252; the wrapper now selects UTF-8. Saved native results are unaffected.'
}
(HERE/'runtime-evidence.json').write_text(json.dumps(evidence, indent=2), encoding='utf-8')
manifest = read('before/sha256.json')
for path in (HERE/'before').rglob('*'):
    if path.is_file() and path.name != 'sha256.json':
        key = path.relative_to(HERE/'before').as_posix()
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert key not in manifest or manifest[key] == digest, key
        manifest[key] = digest
(HERE/'before/sha256.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print('Recorded native outcomes and baseline hashes; unresolved teardown remains explicit.')
