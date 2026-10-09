"""Publish a fresh student submission and its independently executed checks."""
from pathlib import Path
import hashlib
import html
import json
import re
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-motion-ghost-student-fresh'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    native = json.loads((OUT / 'native-checks.json').read_text(encoding='utf8'))
    museum = json.loads((OUT / 'museum/report.json').read_text(encoding='utf8'))
    submitted = json.loads((OUT / 'submission-before-run.json').read_text(encoding='utf8'))
    unchanged = all(sha(OUT / 'attempt' / name) == value for name, value in submitted.items())
    before = json.loads((OUT / 'before-execution.json').read_text(encoding='utf8'))
    canonical = {p: value for p, value in before.items() if not p.startswith('tools/')}
    source_unchanged = all(sha(ROOT / p) == value for p, value in canonical.items())
    lesson = (OUT / 'packet/lesson.md').read_text(encoding='utf8')
    helpers = (OUT / 'packet/shared-code.md').read_text(encoding='utf8')
    reference = re.findall(r'```gdscript\n(.*?)\n```', lesson, re.S)[0]
    common = re.findall(r'```gdscript\n(.*?)\n```', helpers, re.S)
    names = ['03_mass.gd', 'point_body.gd', 'free_point.gd', 'study.gd']
    parity = all((OUT / 'attempt' / n).read_text(encoding='utf8').strip() == code.strip()
                 for n, code in zip(names, [reference] + common))
    count = len(native['checks']) + len(museum['checks'])
    good = native['passed'] and museum['passed'] and unchanged and source_unchanged and parity
    observation = native['observations']
    total = f"{count}/{count}" if good else 'Checks need review'
    report = f'''# A fresh ghost student takes Motion

The revised lesson is reconstructable by a fresh AI reader. Its unchanged first submission passes **{total} native checks**: {len(native['checks'])} on code and behaviour, {len(museum['checks'])} in the actual museum. The reader copied the complete reference, made the requested mass edit, authored the two-clock comparison and chose a further 3 kg / 3 second experiment. Predictions were recorded before execution.

This was a new agent with no conversation history. It received only the revised lesson, its reflective companion and the copied prerequisite readings/helpers. It did not receive the previous student's answer, production force code or teacher checks. The AI brought existing programming and algebra knowledge, which it names in its review. This is one reconstruction test, not a human comprehension or physical-headset test.

## What it could do

| Task | Prediction | Executed result |
| --- | --- | --- |
| Reconstruct the three points | 1 / 0.5 / 0.25 m/s after the pulse | Matches on Jolt; complete printed code reproduced. |
| Change the third mass to 8 kg | 0.125 m/s | {observation['mass_eight_speed']:.6f} m/s. |
| Give 1 kg a one-second push and 2 kg a two-second push | Both finish at 1 m/s, with distances near 1.5 / 1 m | Both reach 1 m/s; retained display reads 1.508 / 1.008 m at the 60 Hz boundary. |
| Choose another mass and duration | 3 kg, 1 N, 3 seconds gives 1 m/s | {observation['transfer']['measured_speed']:.6f} m/s. |
| Press again halfway through the original pulse | Force lasts 1.5 seconds in total; velocity is retained | {observation['mid_pulse_restart_speed']:.6f} m/s for the 1 kg point. |
| Turn the study / hold the point | Force follows the study frame; held time is lost | Both verified; pickup uses real XRTools with supplied input. |

The held-point check supplies zero release velocity explicitly. It does not establish the result of an arbitrary hand throw. Distances above are the retained end readings; the independently observed positions and later screenshot occur after further coasting.

## What the reader still had to supply

**One measurement detail:** the mass-edit exercise predicts 0.125 m/s, but the printed two-decimal caption cannot show that value exactly. A useful small edit would be: “In this variation, use `%.3f` in the speed caption so you can read 0.125 m/s.”

**One origin decision:** “Keep each starting position before the run” could mean at scene creation or before every press. The reader chose scene creation and correctly retained the existing journey on another press. A useful clarification would be: “Store starting positions once in `_ready()`. Another press adds motion; restarting the study gives a fresh comparison.”

**One reasoning step:** combining two clock conditions with a once-only snapshot required a small event guard. Earlier lessons contain booleans and conditions, but the reader used prior programming knowledge to combine them. The independent exercise is demanding enough to require that transfer; a short hint or a human trial would tell us whether the step is well placed.

These are findings, not edits installed in the chapter. The canonical tutorial, reflection and authored lesson data are unchanged in this fresh test.

## Reading both texts

The student could explain why the force ends while velocity continues, then connect that result to the reflection's account of present state and incomplete history. It also identified the limit: its small code has no trail, so it cannot demonstrate the museum's trail truncation. That distinction keeps the tutorial's construction and the reflection's wider encounter from making unsupported claims for one another.

## A correction to the checker

The first run passed 42 of 43 checks. The failing check required the entire caption to remain unchanged during coasting. The student's valid solution shows live distance and speed alongside a retained end-distance pair. The checker was corrected to inspect the retained line. No student code changed. The first checker, log and result remain archived; the final run passes 43 of 43. The separate museum run passes 21 of 21.

## Read the evidence

- [Student's predictions, written before execution](attempt/predictions.md)
- [Student's first-person reading and construction account](attempt/review.md)
- [Student's interpretation after receiving measurements](attempt/after-run.md)
- [Reading packet](packet/README.md)
- [Independent comparison code](attempt/comparison.gd) and [new mass/duration code](attempt/transfer.gd)
- [Native code checks](native-checks.json) and [actual museum checks](museum/report.json)
- [First checker result](first-checker-native-checks.json)
- [Source and submission record](verification.json)
- [Current tutorial and reflection](../2026-10-08-motion-build-and-investigate/parallel.html)
'''
    (OUT / 'REPORT.md').write_text(report, encoding='utf8')
    css = '''body{margin:0;background:#eae7df;color:#202026;font:18px/1.65 Georgia,serif}main{max-width:1100px;margin:auto;padding:36px}h1{font-size:2.8rem;line-height:1.1}h2{line-height:1.3;margin-top:2em}a{color:#743b58}table{width:100%;border-collapse:collapse;font:15px/1.55 system-ui}td,th{padding:14px;text-align:left;border-bottom:1px solid #c9c4be;vertical-align:top}article{padding:26px;background:#fffdf8}img{width:100%;height:auto}pre{padding:18px;background:#252932;color:#f7f2e7;overflow:auto;font:13px/1.5 Consolas,monospace}details{padding:18px;background:#fffdf8;margin:18px 0}summary{cursor:pointer}.meta{font:14px/1.6 system-ui}@media(max-width:700px){main{padding:18px}td,th{padding:8px}}'''
    body = markdown.markdown(report, extensions=['tables', 'fenced_code'])
    body += '<h2>The submitted comparison in Endless Museum</h2><img src="museum/student.png" alt="Fresh student comparison in the Motion hall, with two moving spheres, live readings and saved end distances"><p class="meta">Native Godot render. Temporary student construction in the declared working bay. The spheres keep coasting while the end-distance readings remain available.</p>'
    for name, title in [('review.md', 'Student account before execution'), ('after-run.md', 'Student account after measurements')]:
        p = OUT / 'attempt' / name
        if p.exists():
            body += '<details><summary>' + title + '</summary>' + markdown.markdown(p.read_text(encoding='utf8'), extensions=['tables', 'fenced_code']) + '</details>'
    for name in ['comparison.gd', 'transfer.gd']:
        body += '<details><summary>' + html.escape(name) + '</summary><pre><code>' + html.escape((OUT / 'attempt' / name).read_text(encoding='utf8')) + '</code></pre></details>'
    page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Fresh ghost student — Motion</title><style>' + css + '</style><main>' + body + '</main></html>'
    (OUT / 'index.html').write_text(page, encoding='utf8')
    evidence = {'passed':good, 'native_checks':count, 'code_checks':len(native['checks']), 'museum_checks':len(museum['checks']),
                'first_submission_unchanged':unchanged, 'four_printed_files_match':parity, 'canonical_readings_unchanged':source_unchanged,
                'checker_correction':'Select retained end-distance line; permit live readings to continue. Original checker and failed run archived.',
                'limits':'AI brings prior programming/algebra knowledge; no human learner or physical headset evaluation.',
                'submission_sha256':submitted, 'canonical_sources':canonical,
                'image_sha256':sha(OUT / 'museum/student.png'),
                'teacher_probe_sha256':sha(ROOT / 'tools/probes/motion_ghost_student_fresh.gd')}
    (OUT / 'verification.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    print('Fresh ghost student:', total, 'native checks; unchanged submission:', unchanged)
    assert good


if __name__ == '__main__':
    main()
