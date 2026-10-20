"""Publish NonEuclidean_Spaces' complete texts, native images and learner evidence."""
from pathlib import Path
from html import escape, unescape
from urllib.parse import urlsplit, unquote
from datetime import datetime
import hashlib, json, re, shutil, zipfile
from publish_euclid_lesson import CSS, md

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight'
STUDY = ROOT/'doc/book/studies/noneuclid-lineage'
RUN = ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces/surface-lesson-raised'
GHOST = OUT/'ghost/student'
PLAN = ROOT/'doc/book/course/storyboards/FOUNDATIONS-CRISIS-HANDOFF.md'

def read(path): return json.loads(path.read_text(encoding='utf-8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def page(title, body, wide=False):
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><main class="{'wide' if wide else ''}">
<p class="eyebrow">Endless Museum / Foundations Crisis / Non-Euclidean Spaces / 11 October 2026</p>
<nav><a href="index.html">Room & evidence</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="ghost.html">Ghost student</a></nav>{body}</main></body></html>'''

def main():
    author, museum, ghost = read(OUT/'author/results.json'), read(RUN/'report.json'), read(GHOST/'results.json')
    assert author['passed'] and museum['passed']
    learner = read(GHOST/'attempt_02_engine.json')
    learner_run = read(GHOST/'attempt_02_run.json')
    assert learner['assertion_count'] == learner['pass_count'] == len(learner['checks'])
    assert all(check['pass'] for check in learner['checks'])
    assert learner_run['exit_code'] == 0 and not learner_run['timed_out']
    learner_log = ''.join((GHOST/f'attempt_02_{stream}.log').read_text(encoding='utf-8') for stream in ['stdout','stderr'])
    assert 'SCRIPT ERROR' not in learner_log
    frozen = read(GHOST/'freeze_manifest.json')
    followup = read(GHOST/'followup_02_frozen.json')
    for path,value in frozen['input_sha256'].items(): assert sha(ROOT/path)==value
    for name,value in frozen['student_file_sha256'].items(): assert sha(GHOST/name)==value,name
    assert sha(GHOST/'probe_delayed.gd') == followup['probe_sha256'] == learner_run['script_sha256']
    assert datetime.fromisoformat(frozen['frozen_utc']) < datetime.fromisoformat(read(GHOST/'attempt_01_run.json')['started_utc'])
    assert datetime.fromisoformat(followup['frozen_utc']) < datetime.fromisoformat(learner_run['started_utc'])
    n_ghost = learner['pass_count']
    preserved = read(OUT/'preserved.json')
    preservation = {p:sha(ROOT/p)==value for p,value in preserved.items()}
    assert all(preservation.values())
    texts = {name:(ROOT/f'commons/maps/NonEuclidean_Spaces/{name}.md').read_text(encoding='utf-8') for name in ['tutorial','final']}
    for name, text in texts.items():
        assert text == (OUT/f'ghost/input/{name}.md').read_text(encoding='utf-8')
        (OUT/f'{name}.md').write_text(text,encoding='utf-8')
        (OUT/f'{name}.html').write_text(page('Surface / '+name,md(text)),encoding='utf-8')
    blocks = re.findall(r'<!-- student-code:([\w_]+\.gd) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S)
    assert len(blocks)==5
    for name, code in blocks:
        for p in [STUDY/name, OUT/'author/printed'/name, GHOST/name]:
            assert p.read_text(encoding='utf-8')==code+'\n',str(p)
    for name in ['triangle_record.gd','point_body.gd','line_skin.gd']:
        assert (STUDY/name).read_bytes()==(ROOT/'doc/book/studies/euclid-lineage'/name).read_bytes()
    for name in ['plane','sphere','above','known-triangle','degenerate']:
        shutil.copy2(RUN/f'{name}.png',OUT/f'{name}.png')
    shutil.copy2(RUN/'report.json',OUT/'museum-tests.json')
    shutil.copy2(RUN/'source_manifest.json',OUT/'museum-manifest.json')
    log=(RUN/'stdout.log').read_text(encoding='utf-8',errors='replace')
    assert 'SCRIPT ERROR' not in log
    (OUT/'museum-diagnostics.json').write_text(json.dumps([line for line in log.splitlines() if line.startswith(('ERROR:','WARNING:'))],indent=2),encoding='utf-8')
    (OUT/'study').mkdir(exist_ok=True)
    for p in STUDY.iterdir():
        if p.suffix in ['.gd','.tscn','.md']: shutil.copy2(p,OUT/'study'/p.name)
    shutil.copy2(PLAN,OUT/PLAN.name)
    (OUT/'parallel.html').write_text(page('What counts as straight / facing texts','<p>Complete tutorial left; reflection right.</p><div class="pair"><article>'+md(texts['tutorial'])+'</article><article>'+md(texts['final'])+'</article></div>',True),encoding='utf-8')
    changes='<h1>The same pairs.<br>Another path.</h1>'
    for name in ['tutorial','final']:
        changes+=f'<h2>{name}.md</h2><div class="pair"><article><h3>Before</h3>'+md((OUT/f'before/{name}.md').read_text(encoding='utf-8'))+'</article><article><h3>Now</h3>'+md(texts[name])+'</article></div>'
    (OUT/'changes.html').write_text(page('Surface / before and after',changes,True),encoding='utf-8')
    (OUT/'ghost.html').write_text(page('Surface / fresh ghost student',md((GHOST/'REPORT.md').read_text(encoding='utf-8'))+'<p><a href="ghost/student/results.json">Machine-readable results</a></p>'),encoding='utf-8')
    n_author,n_museum=len(author['checks']),len(museum['checks'])
    body=f'''<h1>What counts<br>as straight?</h1>
<p class="lead">The point, line and triangle return from Euclid. Keep the three coordinate pairs; change the surface, edge rule and direction used to measure each corner.</p>
<p class="route">Euclid / conditions → Non-Euclidean Spaces / paths and tangents → next: Russell / membership</p>
<p><a href="parallel.html">Read the facing texts</a> · <a href="surface-review.zip">Review ZIP</a></p>
<figure><img src="sphere.png" alt="Three familiar black PointBody spheres joined by pink great-circle paths on a larger pale sphere in the museum"><figcaption>Actual Godot capture. The same starting pairs now select three directions on a sphere: about 67.50°, 67.50°, 78.45°, with sum 213.46°. The cylinders approximate the arcs; the measurements use analytical tangents.</figcaption></figure>
<h2>One focused coding step</h2>
<table><tr><th>Carried from Euclid</th><th>New here</th><th>Kept as a museum comparison</th></tr><tr><td>PointBody, LineSkin and the three-point record, unchanged. Same reset and degenerate-state policy.</td><td>A spherical interpretation of each pair; great-circle samples; tangent-based angles. Two new files, three complete carried files.</td><td>The original PLANE / SPHERE / DISK bench, separate surface slider, saddle, dome and other exhibits.</td></tr></table>
<p>The runnable lesson concentrates on <strong>plane → sphere</strong>. It does not implement the disk or deform the whole museum. Switching keeps the coordinate pairs and PointBody instances while changing positions, lengths and angles. The correspondence is explicit; it is not an isometry.</p>
<figure><img src="plane.png" alt="The same three PointBody instances on the flat triangle table, with Plane Sphere and Reset controls"><figcaption>PLANE calls the previous triangle measurement. Returning to this setting restores the positions associated with the retained pairs. RESET restores the original pairs while keeping the model.</figcaption></figure>
<h2>The hand edits a record</h2>
<p>On the plane, local X/Z movement edits the pair directly. On the sphere, the hand direction is inverted through the upper-hemisphere chart, then bounded to the workspace. Release puts the point on its recorded surface position. Moving the hand too near or below the equator refuses the update and names that refusal. The sphere extends beyond the interface's chosen patch.</p>
<p>The reflection stays close to that encounter: what can be continuous between two models, what “straight” depends on, and how an interface can suggest more authority than it has. It has no code blocks. The tutorial supplies the implementation and distinguishes sampled display geometry from the analytical measurement.</p>
<h2>Runtime and learner evidence</h2>
<p><strong>{n_author}/{n_author} author assertions and {n_museum}/{n_museum} native museum checks pass.</strong> The five printed files are extracted and compared with the source. Known angles, edge endpoints, sphere membership, tangent orthogonality, model/instance continuity, transformed hand input, bounds, refusal and release are checked in Godot.</p>
<p>The fresh ghost student received the frozen texts and declared dependencies, reconstructed the lesson and passed <strong>{n_ghost}/{n_ghost} checks</strong> in its completed run. It independently predicted and tested a variation: halving the chart coordinates keeps the planar angles but reduces the spherical total to about 186.38°. Spherical arc lengths do not simply halve.</p>
<p>The first attempt passed 103 assertions but also logged XRTools singleton compile errors. A separately frozen follow-up delayed scene loading until after startup; it passed the same checks plus six dependency-health checks with no SCRIPT ERROR. No lesson code changed. Both attempts remain in the evidence. <a href="ghost.html">Read the assessment, predictions and limits</a>. The reader is an experienced coding AI; reconstruction and transfer checks are not a human-learning result.</p>
<figure><img src="known-triangle.png" alt="A right spherical triangle with a 199.47 degree measured total"><figcaption>Independent known case: the pairs (0,0), (1,0), (0,1) give 90°, 45°, 45° on the plane and approximately 90°, 54.73561°, 54.73561° on the sphere.</figcaption></figure>
<div class="note-box">Physical headset interaction, actual desktop ray targeting, walking access and Quest performance remain unverified. Existing UID/Jolt and renderer diagnostics are retained. The images use Compatibility rendering. Measurements check an implementation within a chosen model; they do not prove the geometry's theorems.</div>
<h2>Inside the existing hall</h2>
<figure><img src="above.png" alt="Overhead museum view showing the student study beside the retained triangle workbench and stepped floor"><figcaption>The first placement intersected stepped floor geometry and failed clearance. The working copy now sits at the existing floor height, with a checked supported approach. The underlying room, artifacts and spine are preserved.</figcaption></figure>
<p>Run <code>res://doc/book/studies/noneuclid-lineage/museum.tscn</code> with F6. The launcher adds this session study to the actual NonEuclidean_Spaces hall. It does not permanently register a new artifact on the ordinary museum route. <a href="study/README.md">Setup and controls</a>.</p>
<p><a href="author/results.json">Author checks</a> · <a href="museum-tests.json">Native checks</a> · <a href="ghost/student/results.json">Learner results</a> · <a href="museum-diagnostics.json">Native diagnostics</a> · <a href="verification.json">Source hashes</a> · <a href="FOUNDATIONS-CRISIS-HANDOFF.md">Editable handoff</a></p>
<p>Next: <strong>Russell_Paradox</strong>. Carry the habit of declaring a rule and checking what it permits. Choosing a geometry and satisfying an unrestricted membership demand are different questions.</p>'''
    (OUT/'index.html').write_text(page('Surface / what counts as straight',body),encoding='utf-8')
    (OUT/'README.md').write_text(f'''# Non-Euclidean Spaces review

Start with parallel.html for the complete tutorial and reflection. index.html contains actual museum images and evidence. ghost.html presents the fresh learner's assessment; original predictions, probes and logs are under ghost/student/.

{n_author} author checks, {n_museum} native checks and {n_ghost} fresh ghost-student checks pass. The first ghost run passed 103 assertions but logged dependency compile errors; its independently predicted delayed-loading harness resolved those without lesson changes. Both attempts remain. All five printed source files are verified against both author and student reconstructions. study/ contains the runnable sources and supplied museum launcher. Requires AdaResearch, XRTools and the named button scene; this is not a blank-project export.

The focused task is plane → sphere, extending the same Euclid record and reusing PointBody/LineSkin. The disk is a retained comparison, not reconstructed here. Mode switch preserves coordinate records and object identity, not metric shape. The original hall and ordinary route remain unchanged. Physical headset interaction and human learning are not established. See diagnostics and the full evidence before making broader claims.
''',encoding='utf-8')
    paths=[ROOT/f'commons/maps/NonEuclidean_Spaces/{n}.md' for n in ['tutorial','final']]+[p for p in STUDY.iterdir() if p.suffix in ['.gd','.tscn','.md']]
    paths += [PLAN,Path(__file__).resolve(),ROOT/'tools/write_noneuclid_lesson.py',ROOT/'tools/test_noneuclid_lesson.py',ROOT/'tools/probes/noneuclid_lesson_test.gd',ROOT/'tools/probes/noneuclid_lesson_museum.gd']
    (OUT/'verification.json').write_text(json.dumps({'preservation':preservation,'canonical_matches_frozen_packet':True,'all_five_listings_equal_source_author_student':True,'three_carried_files_unchanged':True,'source_sha256':{p.relative_to(ROOT).as_posix():sha(p) for p in paths},'ghost_results':'ghost/student/results.json','ghost_frozen_files_unchanged':True,'both_ghost_predictions_precede_execution':True,'author_checks':n_author,'native_checks':n_museum,'ghost_final_checks':n_ghost},indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'surface-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ['.zip','.uid','.import','.pyc'] and '__pycache__' not in p.parts: z.write(p,p.relative_to(OUT).as_posix())
        for p in paths:
            if p.is_relative_to(ROOT/'tools'): z.write(p,'reproduce/'+p.relative_to(ROOT).as_posix())
    for p in OUT.glob('*.html'):
        for target in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
            parsed=urlsplit(unescape(target))
            if parsed.scheme or parsed.netloc or not parsed.path: continue
            assert (p.parent/unquote(parsed.path)).exists(),(p.name,target)
    rendered=re.findall(r'<pre><code[^>]*>(.*?)</code></pre>',(OUT/'tutorial.html').read_text(encoding='utf-8'),re.S)
    assert [unescape(code) for code in rendered]==[code+'\n' for _,code in blocks]
    print(f'Published NonEuclidean_Spaces: {n_author} author, {n_museum} native checks, fresh learner evidence.')

if __name__=='__main__': main()
