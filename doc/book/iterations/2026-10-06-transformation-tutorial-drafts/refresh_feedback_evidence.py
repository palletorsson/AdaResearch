"""Retain native evidence only when a prose revision leaves all tested code exact."""
import copy
import difflib
import json
import re
from build import HERE, ROOT, HALLS, put, sha

saved = HERE / 'before-feedback'
previous = json.loads((saved / 'verification.json').read_text(encoding='utf-8'))
assert previous['passed']
report = copy.deepcopy(previous)
refreshed = []
for path, digest in previous['inputs'].items():
    source = ROOT / path
    if source.name != 'tutorial.md':
        assert sha(source) == digest, 'Tested input changed: ' + path
        continue
    hall = source.parent.name
    before = saved / hall / 'tutorial.md'
    assert sha(before) == digest
    old = before.read_text(encoding='utf-8')
    current = source.read_text(encoding='utf-8')
    pattern = r'<!-- student-code:lesson.gd -->\s*```gdscript\n(.*?)^```'
    old_blocks = re.findall(pattern, old, re.M | re.S)
    new_blocks = re.findall(pattern, current, re.M | re.S)
    assert len(new_blocks) == len(old_blocks) == 1
    assert new_blocks == old_blocks
    assert new_blocks[0] == (HERE / hall / 'lesson.gd').read_text(encoding='utf-8')
    assert current.count('```gdscript') == 1
    assert current.count('func _ready()') == 1
    if current != old:
        refreshed.append(hall)
    report['inputs'][path] = sha(source)
    put(HERE / 'feedback' / (hall + '-tutorial.diff'), ''.join(difflib.unified_diff(old.splitlines(keepends=True), current.splitlines(keepends=True), fromfile='before-feedback/' + hall + '/tutorial.md', tofile=hall + '/tutorial.md')))

assert set(refreshed) == {'Trans_Pre', 'Trans_Introduction', 'Trans_Translation', 'Trans_Body'}
for path, digest in json.loads((HERE / 'preserved-before.json').read_text()).items():
    assert sha(ROOT / path) == digest, 'Canonical source changed: ' + path
reflection_changes = []
for hall in HALLS:
    old = (saved / hall / 'final.md').read_text(encoding='utf-8')
    current = (HERE / hall / 'final.md').read_text(encoding='utf-8')
    if old != current:
        reflection_changes.append(hall)
        put(HERE / 'feedback' / (hall + '-final.diff'), ''.join(difflib.unified_diff(old.splitlines(keepends=True), current.splitlines(keepends=True), fromfile='before-feedback/' + hall + '/final.md', tofile=hall + '/final.md')))
assert reflection_changes == ['Trans_Body']
evidence = {
    'passed': True,
    'kind': 'prose-only-code-equivalence',
    'engine_rerun': False,
    'basis': 'before-feedback/verification.json',
    'basis_sha256': sha(saved / 'verification.json'),
    'native_assertions_retained': previous['assertions'],
    'native_faults_retained': len(previous['faults']),
    'all_seven_printed_programs_unchanged': True,
    'non_prose_test_inputs_unchanged': True,
    'canonical_manuscripts_and_maps_preserved': True,
    'tutorials_changed': refreshed,
    'reflections_changed': reflection_changes,
    'refresh_script_sha256': sha(HERE / 'refresh_feedback_evidence.py'),
    'limits': 'Checks program identity and source preservation; does not test learner comprehension or claim a new engine run.'
}
report['documentation_refresh'] = evidence
put(HERE / 'feedback-prose-verification.json', json.dumps(evidence, indent=2) + '\n')
put(HERE / 'verification.json', json.dumps(report, indent=2) + '\n')
print('Prose equivalence passed: seven exact programs retain the 204-check native evidence; no engine rerun.')
