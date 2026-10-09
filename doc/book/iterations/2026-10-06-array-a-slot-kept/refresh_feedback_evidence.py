from pathlib import Path
import difflib
import json
import re
from build import HERE, ROOT, put, sha

native = json.loads((HERE / 'verification.json').read_text())
old = (HERE / 'before-feedback/tutorial.md').read_text(encoding='utf-8')
new = (HERE / 'tutorial.md').read_text(encoding='utf-8')
pattern = r'<!-- student-code:lesson.gd -->\s*```gdscript\n(.*?)^```'
old_blocks = re.findall(pattern, old, re.M | re.S)
new_blocks = re.findall(pattern, new, re.M | re.S)
assert len(old_blocks) == len(new_blocks) == 1
assert old_blocks == new_blocks == [(HERE / 'lesson.gd').read_text(encoding='utf-8')]
assert sha(HERE / 'verification.json') == sha(HERE / 'before-feedback/verification.json')
path = (HERE / 'tutorial.md').relative_to(ROOT).as_posix()
assert sha(HERE / 'before-feedback/tutorial.md') == native['inputs'][path]
unchanged = {p: sha(ROOT / p) == h for p, h in native['inputs'].items() if p != path}
assert all(unchanged.values())
assert sha(HERE / 'final.md') == sha(HERE / 'before-feedback/final.md') == sha(ROOT / 'commons/maps/Array/final.md')
for p, digest in native['preserved'].items():
    assert (sha(ROOT / p) if (ROOT / p).exists() else None) == digest
put(HERE / 'feedback-tutorial.diff', ''.join(difflib.unified_diff(old.splitlines(keepends=True), new.splitlines(keepends=True), fromfile='before-feedback/tutorial.md', tofile='tutorial.md')))
put(HERE / 'feedback-prose-verification.json', json.dumps({
    'passed': True, 'engine_rerun': False,
    'native_verification_sha256': sha(HERE / 'verification.json'),
    'tutorial_sha256': sha(HERE / 'tutorial.md'),
    'before_tutorial_sha256': sha(HERE / 'before-feedback/tutorial.md'),
    'printed_program_unchanged': True,
    'other_native_inputs_unchanged': unchanged,
    'final_unchanged': True,
    'scope': 'Three prose clarifications only. Prior 150 native checks, three exercise variants and six rejected faults still apply to identical executable code; no new engine run or learner claim.'
}, indent=2) + '\n')
print('Prose updated; exact printed program and all other native test inputs unchanged.')
