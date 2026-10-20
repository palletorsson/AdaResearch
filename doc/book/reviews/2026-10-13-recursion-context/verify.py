"""Re-extract the printed files; run existing Godot probes in this review folder."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RES = 'res://' + HERE.relative_to(ROOT).as_posix() + '/'
GODOT = Path(r'C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe')
records = json.loads((HERE / 'before.json').read_text(encoding='utf-8'))
diffs = []
for record in records:
    path = ROOT / record['path']
    before = (HERE / 'before' / path.parent.name / path.name).read_text(encoding='utf-8')
    after = path.read_text(encoding='utf-8')
    assert re.findall(r'```.*?```', before, re.S) == re.findall(r'```.*?```', after, re.S), path
    assert re.findall(r'<!--.*?-->', before, re.S) == re.findall(r'<!--.*?-->', after, re.S), path
    record['after_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
    record['code_and_markers_unchanged'] = True
    diffs.extend(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile=record['path']+' (before)', tofile=record['path']+' (after)'))
(HERE / 'changes.diff').write_text(''.join(diffs), encoding='utf-8')
(HERE / 'text-checks.json').write_text(json.dumps(records, indent=2), encoding='utf-8')

for hall in ['Fractal_Recursion', 'Fractal_RecursiveTrees', 'LSystems_Grammar_Lab']:
    text = (ROOT / 'commons/maps' / hall / 'tutorial.md').read_text(encoding='utf-8')
    blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', text, re.S)
    for name, code in blocks:
        dest = HERE / ('grammar/printed' if hall.startswith('LSystems') else 'fractal/' + hall) / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(code + '\n', encoding='utf-8')
        if hall.startswith('LSystems'):
            dest = HERE / 'grammar/variation' / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            if name == 'sentence.gd':
                assert 'const CURVE := {"F": "F+F-F-F+F"}' in code
                code = code.replace('const CURVE := {"F": "F+F-F-F+F"}', 'const CURVE := {"F": "F+F"}')
            dest.write_text(code + '\n', encoding='utf-8')

fractal = (ROOT / 'tools/probes/fractal_lesson_student.gd').read_text(encoding='utf-8')
fractal = fractal.replace('res://ada_run/fractal_lesson_student/', RES + 'fractal/')
fractal = fractal.replace('res://ada_run/fractal_lesson_student_tests.json', RES + 'fractal/checks.json')
needle = '\t\ttrial.free()'
assert fractal.count(needle) == 1
fractal = fractal.replace(needle, '\t\tif count == 1:\n\t\t\tcheck("New call trace returns two distinct 0.49 metre child nodes", trial.first_forks[0] != trial.first_forks[1] and is_equal_approx(trial.first_forks[0].get_meta("length"), 0.49) and is_equal_approx(trial.first_forks[1].get_meta("length"), 0.49))\n' + needle)

grammar = (ROOT / 'tools/probes/grammar_sentence_lesson.gd').read_text(encoding='utf-8')
grammar = grammar.replace('res://doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading/', RES + 'grammar/')
needle = '\tvar model=study.model'
assert grammar.count(needle) == 1
grammar = grammar.replace(needle, needle + '\n\tvar first: Dictionary = model.rewrite("F", study.CANTOR)\n\tvar second: Dictionary = model.rewrite(first.text, study.CANTOR)\n\tcheck("New paper trace produces F then FfF then FfFfffFfF", first.text == "FfF" and second.text == "FfFfffFfF")\n\tvar second_ends: Array = model.read(second.text, 90)\n\tvar wanted := [0,1,2,3,6,7,8,9]\n\tvar trace_ok := second_ends.size() == wanted.size()\n\tfor i in wanted.size(): trace_ok = trace_ok and second_ends[i].is_equal_approx(Vector3.UP * wanted[i])\n\tcheck("New trace draws four intervals across nine unit advances", trace_ok)')

results = []
for name, source in [('fractal', fractal), ('grammar', grammar)]:
    probe = HERE / name / 'probe.gd'
    probe.write_text(source, encoding='utf-8')
    log = HERE / name / 'engine.log'
    with (HERE / name / 'stdout.log').open('w', encoding='utf-8') as output:
        process = subprocess.run([str(GODOT), '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(log), '--script', RES + name + '/probe.gd'], cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
    errors = [line for line in log.read_text(encoding='utf-8', errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
    assert process.returncode == 0 and not errors, (name, process.returncode, errors)
    result = json.loads((HERE / name / 'checks.json').read_text(encoding='utf-8'))
    assert result['passed'], result['failures']
    results.append({'probe': name, 'checks': len(result['checks']), 'passed': True})
print(json.dumps(results), flush=True)
