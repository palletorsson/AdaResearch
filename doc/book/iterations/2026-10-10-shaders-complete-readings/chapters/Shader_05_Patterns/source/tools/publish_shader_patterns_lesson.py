"""Publish Patterns manuscripts, exact continuation and native museum evidence."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from publish_shader_shaping_lesson import page as base_page,md
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-patterns-the-same-circle'
MAP=ROOT/'commons/maps/Shader_05_Patterns'
RUN=ROOT/'ada_run/encounter_pilot/Shader_05_Patterns/lesson'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):return base_page(title,body,wide).replace('shaping-review.zip','patterns-review.zip')
def main():
    tests=json.loads((OUT/'tests.json').read_text());native=json.loads((RUN/'report.json').read_text())
    assert tests['passed'] and native['passed']
    assert not any(e in (RUN/'engine.log').read_text(encoding='utf-8') for e in ['SCRIPT ERROR:','SHADER ERROR:'])
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    tutorial=(MAP/'tutorial.md').read_text(encoding='utf-8')
    assert sha(MAP/'tutorial.md')==tests['source_sha256']
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',tutorial,re.S))
    for name,code in blocks.items():
        assert (OUT/'learner/printed'/name).read_text(encoding='utf-8')==code+'\n'
        assert sha(OUT/'learner/printed'/name)==tests['files'][name]
    assert sha(OUT/'continuation.json')==tests['continuation_sha256']
    assert sha(ROOT/'tools/probes/shader_patterns_student.gd')==tests['probe_sha256']
    marker='<!-- uncertainty:p4-record -->'
    previous=(OUT/'before/tutorial.md').read_text(encoding='utf-8')
    assert tutorial[tutorial.index(marker):]==previous[previous.index(marker):]
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for name in ['student.png','half-shift.png','in-the-hall.png','report.json','engine.log','source_manifest.json','learner_control.json']:shutil.copy2(RUN/name,museum/name)
    tracks={};diffs=[]
    for track in ['tutorial','final']:
        text=(MAP/f'{track}.md').read_text(encoding='utf-8');tracks[track]=text
        (OUT/f'{track}.md').write_text(text,encoding='utf-8')
        (OUT/f'{track}.html').write_text(page('Patterns / '+track,md(text)),encoding='utf-8')
        before=(OUT/'before'/f'{track}.md').read_text(encoding='utf-8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='Before '+track,tofile='Now '+track))
        (OUT/f'{track}.diff').write_text(diff,encoding='utf-8');diffs.append('<h2>'+track+'</h2><pre class="diff">'+html.escape(diff)+'</pre>')
    (OUT/'parallel.html').write_text(page('Patterns / facing pages','<p class="meta">Endless Museum · Shaders 02 · 10 October 2026</p><div class="pair"><article><p class="meta">LEFT · TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Patterns / changes','<h1>The same circle continues.</h1><p>The required tutorial gains the complete tested Shaping continuation. The flower is an optional encounter; the saved-record appendix remains byte-for-byte unchanged. Reflection follows the new passage, corrects the drawn border, mesh-seam and noise-family claims, removes inline code blocks, and leads into the furnished Materials hall.</p>'+''.join(diffs)),encoding='utf-8')
    coverage=ROOT/'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md';shutil.copy2(coverage,OUT/'coverage.md')
    (OUT/'coverage.html').write_text(page('Shaders / surface progression',md(coverage.read_text(encoding='utf-8'))),encoding='utf-8')
    sources=['tools/revise_shader_patterns.py','tools/test_shader_patterns.py','tools/publish_shader_patterns_lesson.py','tools/publish_shader_shaping_lesson.py','tools/probes/shader_patterns_student.gd','tools/probes/shader_patterns_lesson_museum.gd','doc/book/studies/shaders-lineage/patterns_museum.gd','doc/book/studies/shaders-lineage/Patterns.tscn','commons/maps/Shader_05_Patterns/map_data.json','commons/artifacts/shader_pattern_passage/shader_pattern_passage.gd','commons/artifacts/shader_pattern_passage/repeated_mask.gdshader','algorithms/shaders/book_of_shaders/patterns_tile.gdshader','algorithms/shaders/book_of_shaders/patterns_wang.gdshader','algorithms/shaders/book_of_shaders/patterns_truchet.gdshader','algorithms/shaders/book_of_shaders/patterns_noise.gdshader','algorithms/shaders/book_of_shaders/patterns_voronoi.gdshader']
    chain=json.loads((OUT/'continuation.json').read_text())
    for item in chain['incoming'].values():sources.append(item['path'])
    for rel in sources:
        p=OUT/'source'/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
    code_count=sum(r['checks'] for r in tests['results'][:2]);museum_count=len(native['checks'])
    manifest={'tutorial_sha256':sha(MAP/'tutorial.md'),'final_sha256':sha(MAP/'final.md'),'printed_files':tests['files'],'source_sha256':{p:sha(ROOT/p) for p in sources},'point_dependency_sha256':sha(ROOT/'addons/godot-xr-tools/objects/pickable.gd'),'code_checks':code_count,'rejected_faults':3,'museum_checks':museum_count,'optional_saved_record':'Unchanged; not tested in this pass.','scope':'Teacher-authored reconstruction and variation; compatibility GPU; synthetic XR poses, not physical headset/human learning/onward travel. Launcher mount helper exercised inside actual hall; interactive F6 session not run.'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    rows=''.join('<tr><td>'+html.escape(r['kind'])+'</td><td>'+('PASS' if r['passed'] else 'EXPECTED REJECTION')+'</td><td>'+html.escape('; '.join(r['failed_assertions']) or str(r['checks'])+' passing assertions')+'</td></tr>' for r in tests['results'])
    body=f'''<p class="meta">Endless Museum · Shaders 02 · 10 October 2026</p><h1>The same circle, another address.</h1><p>The point, cube and shared material continue from Shaping. Multiply and fold the coordinates before reading the circle. Move the point sideways: the image moves while the receivers stay still.</p><p><a href="parallel.html">Read tutorial and reflection side by side →</a> · <a href="patterns-review.zip">Download review ZIP</a></p>
<figure><a href="museum/student.png"><img src="museum/student.png" alt="Nine repeated circles on the learner wall and cube inside the actual patterned museum passage"></a><figcaption>Native Godot capture of the exact printed continuation. The starting radius, shift and hard edge have been restored through the simulated hand interaction.</figcaption></figure>
<div class="status">{code_count} assertions passed across the printed continuation and the four-by-two variation. Three deliberate faults were rejected. {museum_count} actual-museum assertions passed.</div>
<h2>One new operation</h2><p>The new shader folds a scaled and shifted UV coordinate with fract() before the earned distance/edge rule reads it. Local Y still changes radius. Local X now changes shift; trigger still switches the edge. One full tile of shift returns the image even though the point stays in a new place. Positive lookup movement moves the marks in the opposite direction.</p><p>The lesson prints the complete small result once, with the unchanged PointBody. <a href="continuation.json">Anchored changes and source hashes</a> verify that it is mechanically assembled from the tested Shaping files. No separate solution or production artifact supplies missing construction. The four-by-two experiment uses the same local circles in rectangular cells, producing tall ellipses.</p>
<figure><a href="learner/four-by-two/repeated.png"><img style="width:384px;image-rendering:auto" src="learner/four-by-two/repeated.png" alt="GPU result of four repeats across and two down, producing tall ellipses"></a><figcaption>The exact exercise edit, captured from the GPU. The radius remains 0.30.</figcaption></figure>
<h2>The wider museum</h2><p>The chair's room-versus-attached projection, Truchet arcs, staggered rows and other specimens remain supporting encounters. The tutorial distinguishes repeats per UV square from the installation's repeats per metre. The previous flower source edit remains optional. Its saved-record appendix is preserved unchanged and was not retested in this pass.</p><p>The reflection connects the loom's physical crossings to the surface rule. It retains the Truchet and painted-Wang-seam passages while correcting three source claims: the small tile shader draws a faint border; a single mesh does not guarantee seamless UVs; the rack's different noise modes cannot all be explained by square-lattice interpolation. The next room now correctly appears as a furnished material study.</p>
<figure><a href="museum/in-the-hall.png"><img loading="lazy" src="museum/in-the-hall.png" alt="Learner study behind the existing patterned chair in the real museum"></a><figcaption>Elevated context view. The learner study sits in the back-right bank. The installed chair and authored room are retained. A route from the central aisle to the control and beside the study was sampled every quarter metre.</figcaption></figure>
<h2>Run and investigate</h2><p>In the existing AdaResearch project, open <code>res://doc/book/studies/shaders-lineage/Patterns.tscn</code> and Run Current Scene. The supplied launcher uses a separate lesson control file so a saved travel request cannot redirect this entry. It mounts <code>learner/printed/shaping.gd</code> from this review folder in the actual Patterns hall. The three sibling files are the ones printed in tutorial.md. Change its LESSON preload to point at your own copy.</p><p>At starting height, move the point half a metre sideways, then a full metre from its start. Predict the direction and return before looking. Keep the mesh; change the repeat counts. Explain why wall and cube carry the same count but different metre sizes. The text also asks for another positive count pair and a fractional count; those open student investigations are not claimed as tested learning.</p>
<table><thead><tr><th>Program</th><th>Result</th><th>Evidence</th></tr></thead><tbody>{rows}</tbody></table>
<h2>What the tests establish</h2><p>Godot 4.6, compatibility renderer. Tests read rendered pixels for counts, aspect, coverage, phase direction, positive/negative periods and soft edges. They check the transformed local frame, inherited radius action, unchanged meshes/collision and UV attachment. The actual-hall probe adds synthetic XR pickup, action, release and a return through the same grip to restore the comparison.</p><p>No script or shader errors in the passing runs. The existing audio-bus UID and renderer-feature warnings remain in the museum log. This is a teacher-authored reconstruction check, not an independent ghost student or human-learning result. Headset use and onward traversal are untested. The supplied launcher's mount helper is exercised; a manual F6 session remains to try.</p>
<p><a href="tests.json">Code results</a> · <a href="museum/report.json">Museum results</a> · <a href="museum/engine.log">Museum log</a> · <a href="manifest.json">Source hashes and scope</a> · <a href="BRIEF.md">Short lesson contract</a> · <a href="changes.html">Before/after text</a></p>
<p>Next: Materials. Surface orientation, roughness and the explicit bump/normal-map comparison will change how light reads the familiar objects. Vertex displacement follows in Water. <a href="coverage.html">See the coverage plan</a>.</p>'''
    (OUT/'index.html').write_text(page('Patterns / the same circle',body),encoding='utf-8')
    (OUT/'README.md').write_text('''# Patterns review

Read parallel.html (tutorial left, reflection right), or tutorial.md/final.md. index.html gives native images, changes, results and limits. BRIEF.md is the compact contract. continuation.json pins the three Shaping predecessors and applies unique anchored edits; test_shader_patterns.py verifies equality with the printed result before running it.

learner/printed is the exact primary program. learner/four-by-two is the tested variation. Other learner folders are deliberately faulty controls. The prepared AdaResearch Godot project and bundled XR Tools are required; this ZIP is not a standalone player project. The launcher is source/doc/book/studies/shaders-lineage/Patterns.tscn and uses the in-project review path. See tutorial.md for using your own saved copy.

The optional saved-record appendix is unchanged, not covered by this pass's tests. Teacher-authored checks; no independent ghost student, headset, human-learning or onward-travel claim.

Reproduce in the repository:
- python -X utf8 tools/test_shader_patterns.py
- python -X utf8 tools/run_encounter_probe.py Shader_05_Patterns --sequence shaders --probe tools/probes/shader_patterns_lesson_museum.gd --render --no-bridges --output-tag lesson
- python -X utf8 tools/publish_shader_patterns_lesson.py
''',encoding='utf-8')
    with zipfile.ZipFile(OUT/'patterns-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ('.zip','.import','.uid') and '.godot' not in p.parts:z.write(p,p.relative_to(OUT))
    print(json.dumps({'code_checks':code_count,'museum_checks':museum_count,'rejected_faults':3,'page':str(OUT/'parallel.html')}))
if __name__=='__main__':main()
