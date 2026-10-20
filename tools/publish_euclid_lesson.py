"""Publish Euclid's complete texts, actual museum images and qualified learner evidence."""
from pathlib import Path
from urllib.parse import urlsplit, unquote
from html import escape, unescape
import hashlib
import json
import re
import shutil
import zipfile
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-euclid-the-same-triangle'
STUDY = ROOT / 'doc/book/studies/euclid-lineage'
RUN = ROOT / 'ada_run/encounter_pilot/Euclid_Parallel/euclid-lesson-readout'
PLAN = ROOT / 'doc/book/course/storyboards/FOUNDATIONS-CRISIS-HANDOFF.md'

CSS = '''
*{box-sizing:border-box}body{margin:0;background:#eeeae0;color:#25212a;font:18px/1.65 system-ui,sans-serif}
main{max-width:1180px;margin:auto;padding:34px 30px 90px}.wide{max-width:1800px}h1{font:clamp(40px,6vw,78px)/1.08 Georgia,serif;letter-spacing:-.035em}h2{font:32px/1.25 Georgia,serif;margin-top:2em}h3{line-height:1.3}
a{color:#614125;text-underline-offset:.18em}nav{display:flex;gap:20px;flex-wrap:wrap;padding:15px 0;border-bottom:1px solid #c2bba9;font-size:15px}.eyebrow{font-size:12px;letter-spacing:.14em;text-transform:uppercase}.lead{font-size:24px;max-width:930px}.route{color:#695841}
figure{margin:28px 0}img{max-width:100%;display:block}figcaption,.note{font-size:14px;color:#5f5b53}pre{background:#20232b;color:#f1f2f4;padding:20px;overflow:auto;font:14px/1.6 Consolas,monospace;tab-size:4}code{font-family:Consolas,monospace}p code,li code{overflow-wrap:anywhere;font-size:.9em}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:36px}.pair>article{min-width:0;max-height:82vh;overflow:auto;padding:12px 18px;background:#faf8f1}.pair h1{font-size:38px}table{border-collapse:collapse;width:100%;font-size:16px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #bbb3a1;padding:12px}.note-box{border-left:3px solid #a27622;background:#faf8f1;padding:20px;margin:25px 0}
@media(max-width:850px){.pair{display:block}.pair>article{max-height:none}main{padding:20px 16px}table{display:block;overflow:auto}}@media print{nav{display:none}body{background:white}.pair>article{max-height:none;overflow:visible}pre{white-space:pre-wrap;font-size:10px}img{max-height:70vh}}
'''


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def md(text):
    # Preserve the exact printed code, including carried files' indentation.
    result = markdown.markdown(text, extensions=['fenced_code', 'tables'])
    blocks = iter(re.findall(r'```(?:\w+)?\n(.*?)\n```', text, re.S))
    return re.sub(r'(<pre><code[^>]*>).*?(</code></pre>)',
                  lambda match: match[1] + escape(next(blocks)) + '\n' + match[2],
                  result, flags=re.S)


def page(title, body, wide=False):
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)} · Endless Museum</title><style>{CSS}</style></head>
<body><main class="{'wide' if wide else ''}"><p class="eyebrow">Endless Museum / Foundations Crisis / Euclid / 11 October 2026</p>
<nav><a href="index.html">Room & evidence</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="ghost.html">Ghost student</a></nav>{body}</main></body></html>'''


def main():
    author = read_json(OUT / 'author/results.json')
    museum = read_json(RUN / 'report.json')
    ghost = read_json(OUT / 'ghost/student/v3/results.json')
    assert author['passed'] and museum['passed']
    assert all(run['passed'] and not run['failures'] for run in ghost['runs'])
    assert all(ghost['initial_evidence_integrity'].values()) and all(ghost['frozen_file_integrity'].values())
    preserved = read_json(OUT / 'preserved.json')
    preservation = {name: sha(ROOT / name) == value for name, value in preserved.items()}
    assert all(preservation.values()), preservation
    texts = {name: (ROOT / f'commons/maps/Euclid_Parallel/{name}.md').read_text(encoding='utf-8')
             for name in ['tutorial', 'final']}
    for name, text in texts.items():
        assert text == (OUT / f'ghost/final-input/{name}.md').read_text(encoding='utf-8')
        assert ghost['input_sha256'][name+'.md'] == sha(ROOT / f'commons/maps/Euclid_Parallel/{name}.md')
        (OUT / f'{name}.md').write_text(text, encoding='utf-8')
        (OUT / f'{name}.html').write_text(page('Euclid / ' + name, md(text)), encoding='utf-8')
    printed = re.findall(r'<!-- student-code:([\w_]+\.gd) -->\s*```gdscript\n(.*?)\n```', texts['tutorial'], re.S)
    assert len(printed) == 4
    for name, code in printed:
        for path in [STUDY/name, OUT/'author/printed'/name, OUT/'ghost/student/v3'/name]:
            assert path.read_text(encoding='utf-8') == code + '\n', str(path)
    assert (STUDY/'point_body.gd').read_bytes() == (ROOT/'doc/book/studies/ml-gradient/point_body.gd').read_bytes()
    assert (STUDY/'line_skin.gd').read_bytes() == (ROOT/'doc/book/studies/ada-xr-starter/lessons/Point_Lines/line_skin.gd').read_bytes()
    for name in ['opening', 'above', 'scalene', 'guide-hidden', 'degenerate']:
        shutil.copy2(RUN/f'{name}.png', OUT/f'{name}.png')
    shutil.copy2(RUN/'report.json', OUT/'museum-tests.json')
    shutil.copy2(RUN/'source_manifest.json', OUT/'museum-manifest.json')
    log = (RUN/'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log
    diagnostics = [line for line in log.splitlines() if line.startswith(('ERROR:', 'WARNING:'))]
    (OUT/'museum-diagnostics.json').write_text(json.dumps(diagnostics, indent=2), encoding='utf-8')
    (OUT/'study').mkdir(exist_ok=True)
    for p in STUDY.iterdir():
        if p.suffix in ['.gd', '.tscn', '.md']: shutil.copy2(p, OUT/'study'/p.name)
    shutil.copy2(PLAN, OUT/PLAN.name)
    (OUT/'parallel.html').write_text(page('The same triangle / facing texts',
        '<p>Tutorial left; reflection right. Complete text and complete printed code.</p><div class="pair"><article>'
        + md(texts['tutorial']) + '</article><article>' + md(texts['final']) + '</article></div>', True), encoding='utf-8')
    changes = '<h1>The construction returns.</h1>'
    for name in ['tutorial', 'final']:
        changes += f'<h2>{name}.md</h2><div class="pair"><article><h3>Before</h3>'
        changes += md((OUT/f'before/{name}.md').read_text(encoding='utf-8'))
        changes += '</article><article><h3>Now</h3>' + md(texts[name]) + '</article></div>'
    (OUT/'changes.html').write_text(page('Euclid / before and after', changes, True), encoding='utf-8')
    ghost_body = '<h1>A reader makes a variation.</h1><p>This was a fresh coding agent at entry. The later presentation rerun uses that same learner; it is not another blind test.</p>'
    ghost_body += md((OUT/'ghost/student/v3/REPORT.md').read_text(encoding='utf-8'))
    ghost_body += '<p><a href="ghost/student/REPORT.md">Retained first-packet report and its three initial failures</a> · <a href="ghost/student/v3/results.json">Final revision results</a></p>'
    (OUT/'ghost.html').write_text(page('Euclid / ghost student', ghost_body), encoding='utf-8')
    n_author, n_museum = len(author['checks']), len(museum['checks'])
    n_ghost, n_transfer = [run['checks_passed'] for run in ghost['runs']]
    body = f'''<h1>The same triangle.<br>A different question.</h1>
<p class="lead">Three familiar point bodies and three line cylinders return. Move a corner, read its angle, and draw a parallel. What did this construction already assume?</p>
<p class="route">Point → line → triangle → Euclid: conditions and measurement → next: Non-Euclidean Spaces</p>
<p><a href="parallel.html">Read tutorial and reflection together</a> · <a href="euclid-review.zip">Review ZIP</a></p>
<figure><img src="scalene.png" alt="The carried point spheres on a triangular face in the actual museum, with measured unequal angles, gold parallel and two table buttons"><figcaption>Actual Godot capture of the exact printed reconstruction inside Euclid's existing hall. A = 46.03°, B = 72.33°, C = 61.64°; sum ≈ 180°. The original comparisons remain alongside it.</figcaption></figure>
<h2>What returns; what changes</h2>
<table><tr><th>Carried</th><th>New work</th><th>What travels onward</th></tr><tr><td>The small grabbable PointBody, finite cylinder line, vertex array and triangle face.</td><td>Measure interior angles from the stored positions. Construct a parallel through C using B−A. Recognise a degenerate triangle.</td><td>Three points and an explicit geometry. Distinguish a drawing, a measured result and a proof.</td></tr></table>
<p>The tutorial prints two new scripts and the two unchanged carried scripts. The museum supplies the player, lights, XRTools and named button scene. The reflection stays close to the postulates plaque, unequal gaps between parallel lines, the hand's projection and a withheld reading.</p>
<p>Move A, B or C. The hand is projected to the local X/Z table and bounded to ±1 metre. GUIDE, G or a held trigger changes only the guide's visibility. RESET or R restores the corners when all are released. No learning weights or live sphere instance are transferred from the previous sequence.</p>
<figure><img src="guide-hidden.png" alt="The same scalene triangle after hiding only its gold parallel guide"><figcaption>The drawing changes; the positions and angle values do not. The guide does not switch Euclidean geometry on or off.</figcaption></figure>
<h2>Reconstruction and transfer</h2>
<p><strong>{n_author}/{n_author} author assertions and {n_museum}/{n_museum} native museum checks pass.</strong> The author test extracts the four printed scripts. The native check mounts that exact reconstruction in an isolated run of the existing museum and checks placement, supported approach, controls and displayed states.</p>
<p>A separate fresh ghost student received only the texts and declared project dependencies, made predictions before execution, reconstructed all four files and wrote its own probes. It chose an area-preserving shear as its independent variation: the angles and lengths change while area and angle sum stay. Its first run had three failures after a one-time synthetic rigid-body move; continuous hand-pose input passed the focused follow-up without a lesson-logic change. Those failures remain in the record. The same learner's final revision rerun passes <strong>{n_ghost}/{n_ghost} host/geometry assertions and {n_transfer}/{n_transfer} shear assertions</strong>. <a href="ghost.html">Read the assessment</a>.</p>
<div class="note-box">These are software and synthetic-interaction results. Physical headset reach, actual desktop pointer targeting, human learning and Quest performance remain untested. UID and Jolt diagnostics are retained. Measurements in a chosen Euclidean model do not prove its postulates.</div>
<figure><img src="degenerate.png" alt="Three point spheres in a straight row, with no triangle face and a withheld reading"><figcaption>Coincident or nearly collinear corners withhold the triangle reading. The tolerance is an instrument policy; an extremely thin mathematical triangle can still exist.</figcaption></figure>
<h2>In the existing room</h2>
<figure><img src="above.png" alt="Elevated view of the Euclid museum hall, retaining its architecture and exhibits with the lesson table on clear floor"><figcaption>Room view from above. Initial placements intersected existing architecture or the old controls and failed checks. The final working-copy position is clear. Buttons were raised above the tabletop, turned upward and checked again; the readout now has a light outline for contrast.</figcaption></figure>
<p>Run <code>res://doc/book/studies/euclid-lineage/museum.tscn</code> with F6 in the prepared AdaResearch project. This supplied launcher adds the lesson table to Euclid's existing hall for the session. The ordinary route, map, artifact registry and old exhibits are unchanged. <a href="study/README.md">Setup and controls</a>.</p>
<p><a href="author/results.json">Author assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="ghost/student/v3/results.json">Ghost results</a> · <a href="museum-diagnostics.json">Native diagnostics</a> · <a href="verification.json">Source verification</a> · <a href="FOUNDATIONS-CRISIS-HANDOFF.md">Editable handoff</a></p>
<p>Next hall: <strong>NonEuclidean_Spaces</strong>. Carry the same triangle; define the surface and its straightest paths before comparing angles. This pass revises Euclid only.</p>'''
    (OUT/'index.html').write_text(page('Euclid / the same triangle', body), encoding='utf-8')
    (OUT/'README.md').write_text(f'''# Euclid review

Start with parallel.html: complete tutorial left, reflection right. index.html adds actual museum captures and evidence. Ghost details are in ghost.html and ghost/student/v3/REPORT.md; the retained initial assessment is ghost/student/REPORT.md.

{n_author}/{n_author} author assertions; {n_museum}/{n_museum} final native checks. Final ghost counts and qualifications are recorded separately. Do not add these counts together as a learning score. The initial ghost primary run failed three checks after one-time synthetic input; continuous-input follow-up passed with lesson logic unchanged. Later presentation reruns use the same learner.

The study folder contains all runnable student files plus the supplied museum launcher. Requires the prepared AdaResearch project with XRTools and commons/interactables/push_button.tscn; not a standalone export. Canonical texts live in commons/maps/Euclid_Parallel. Follow study/README.md to run or reconstruct.

Preserved: spine, Foundations Crisis order, map, museum plan, original plaque/triangle and carried PointBody/LineSkin. Hashes: preserved.json and verification.json. Original text: before/. The launcher adds a session working copy, not a permanently registered artifact. Physical XR and human learning remain untested; project UID/Jolt diagnostics remain in logs.
''', encoding='utf-8')
    source_files = [ROOT/f'commons/maps/Euclid_Parallel/{name}.md' for name in ['tutorial','final']]
    source_files += [p for p in STUDY.iterdir() if p.suffix in ['.gd','.tscn','.md']]
    source_files += [PLAN, Path(__file__).resolve(), ROOT/'tools/write_euclid_lesson.py', ROOT/'tools/test_euclid_lesson.py', ROOT/'tools/probes/euclid_lesson_test.gd', ROOT/'tools/probes/euclid_lesson_museum.gd']
    verification = {'canonical_equals_final_ghost_packet': True, 'four_printed_files_match_author_and_final_student': True,
                    'carried_files_unchanged': True, 'preservation': preservation,
                    'source_sha256': {p.relative_to(ROOT).as_posix():sha(p) for p in source_files},
                    'author_checks': n_author, 'native_checks': n_museum,
                    'ghost_results': 'ghost/student/v3/results.json', 'scope': 'Euclid only; qualified runtime and transfer evidence, not human learning or physical XR'}
    (OUT/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'euclid-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ['.zip','.uid','.import','.pyc'] and '__pycache__' not in p.parts:
                z.write(p,p.relative_to(OUT).as_posix())
        for p in source_files:
            if p.is_relative_to(ROOT/'tools'): z.write(p, 'reproduce/'+p.relative_to(ROOT).as_posix())
    # Every local HTML link must resolve; rendered code must match the Markdown.
    for p in OUT.glob('*.html'):
        for target in re.findall(r'(?:href|src)="([^"]+)"', p.read_text(encoding='utf-8')):
            parsed = urlsplit(unescape(target))
            if parsed.scheme or parsed.netloc or not parsed.path: continue
            assert (p.parent/unquote(parsed.path)).exists(), (p.name,target)
    rendered = re.findall(r'<pre><code[^>]*>(.*?)</code></pre>', (OUT/'tutorial.html').read_text(encoding='utf-8'), re.S)
    assert [unescape(code) for code in rendered] == [code+'\n' for _,code in printed]
    print(f'Published exact Euclid text, {n_author} author checks, {n_museum} museum checks and final ghost evidence: {OUT}')


if __name__ == '__main__':
    main()
