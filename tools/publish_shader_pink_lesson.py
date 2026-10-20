"""Publish Pink's exact reconstruction, reflection and native museum evidence."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from publish_shader_shaping_lesson import page as base_page,md
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-pink-three-amounts'
MAP=ROOT/'commons/maps/Shader_12_PinkExtravaganza'
RUN=ROOT/'ada_run/encounter_pilot/Shader_12_PinkExtravaganza/lesson'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):return base_page(title,body,wide).replace('shaping-review.zip','pink-review.zip')
def main():
    tests=json.loads((OUT/'tests.json').read_text());native=json.loads((RUN/'report.json').read_text())
    assert tests['passed'] and native['passed']
    assert not any(e in (RUN/'engine.log').read_text(encoding='utf-8') for e in ['SCRIPT ERROR:','SHADER ERROR:'])
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    assert sha(MAP/'tutorial.md')==tests['source_sha256']
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',(MAP/'tutorial.md').read_text(encoding='utf-8'),re.S))
    for name,code in blocks.items():
        assert (OUT/'learner/printed'/name).read_text(encoding='utf-8')==code+'\n'
        assert sha(OUT/'learner/printed'/name)==tests['files'][name]
    assert sha(OUT/'continuation.json')==tests['continuation_sha256']
    assert sha(ROOT/'tools/probes/shader_pink_student.gd')==tests['probe_sha256']
    assert sha(ROOT/'tools/test_shader_pink.py')==tests['runner_sha256']
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for name in ['composed.png','base.png','in-the-hall.png','studio.png','report.json','engine.log','source_manifest.json','learner_control.json']:
        shutil.copy2(RUN/name,museum/name)
    tracks={};diffs=[]
    for track in ['tutorial','final']:
        text=(MAP/f'{track}.md').read_text(encoding='utf-8-sig');tracks[track]=text
        (OUT/f'{track}.md').write_text(text,encoding='utf-8')
        (OUT/f'{track}.html').write_text(page('Pink / '+track,md(text)),encoding='utf-8')
        before=(OUT/'before'/f'{track}.md').read_text(encoding='utf-8-sig')
        delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='Before '+track,tofile='Now '+track))
        (OUT/f'{track}.diff').write_text(delta,encoding='utf-8')
        diffs.append('<h2>'+track+'</h2><pre class="diff">'+html.escape(delta)+'</pre>')
    (OUT/'parallel.html').write_text(page('Pink / facing pages','<p class="meta">Endless Museum · Shaders 05 · 10 October 2026</p><div class="pair"><article><p class="meta">LEFT · TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Pink / changes','<h1>Separate the amounts. Compose the room.</h1><p>The proposed-focus page becomes a complete three-file lesson, carrying the tested Water point and box construction. The old supplied plural-body edit remains as an explicitly separate optional return. The reflection begins with the controlled stage and changing surround, keeps the original collection and plural-body discussion, removes executable code, and corrects the inference that an emissive surface necessarily illuminates its neighbours. Production artifacts and map are unchanged.</p>'+''.join(diffs)),encoding='utf-8')
    coverage=ROOT/'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md';shutil.copy2(coverage,OUT/'coverage.md')
    (OUT/'coverage.html').write_text(page('Shaders / surface progression',md(coverage.read_text(encoding='utf-8'))),encoding='utf-8')
    sources=['tools/revise_shader_pink_lesson.py','tools/test_shader_pink.py','tools/publish_shader_pink_lesson.py','tools/publish_shader_shaping_lesson.py','tools/probes/shader_pink_student.gd','tools/probes/shader_pink_lesson_museum.gd','tools/probes/shader_pink_museum.gd','doc/book/studies/shaders-lineage/pink_museum.gd','doc/book/studies/shaders-lineage/Pink.tscn','commons/maps/Shader_12_PinkExtravaganza/map_data.json','commons/artifacts/shader_composition_stage/shader_composition_stage.gd','commons/artifacts/shader_composition_stage/recipe.gdshader','algorithms/shaders/book_of_shaders/shader_12_pinkextravaganza.gd']
    incoming=json.loads((OUT/'continuation.json').read_text())['incoming']
    sources.extend(d['path'] for d in incoming.values())
    for rel in sources:
        path=OUT/'source'/rel;path.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,path)
    manifest={'tutorial_sha256':sha(MAP/'tutorial.md'),'final_sha256':sha(MAP/'final.md'),'printed_files':tests['files'],'source_sha256':{p:sha(ROOT/p) for p in sources},'point_dependency_sha256':sha(ROOT/'addons/godot-xr-tools/objects/pickable.gd'),'code_checks':sum(r['checks'] for r in tests['results'][:2]),'rejected_faults':3,'museum_checks':len(native['checks']),'scope':'Teacher-authored exact reconstruction and actual-hall mount. No independent student, physical headset, human learning, manual F6 or onward-travel claim. Production map/artifacts unchanged; optional plural-body edit not included in these checks.'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    rows=''.join('<tr><td>'+html.escape(r['kind'])+'</td><td>'+('PASS' if r['passed'] else 'EXPECTED REJECTION')+'</td><td>'+html.escape('; '.join(r['failed_assertions']) or str(r['checks'])+' passing assertions')+'</td></tr>' for r in tests['results'])
    body=f'''<p class="meta">Endless Museum · Shaders 05 · 10 October 2026</p><h1>Three amounts.</h1><p>The same point and cube now share a composition: repeated circles, a view-dependent rim and emission. Move the point along local X, Y or Z to change one amount. Trigger compares the base material with the composition; release holds the choice.</p><p><a href="parallel.html">Read tutorial and reflection side by side →</a> · <a href="pink-review.zip">Download the review ZIP</a></p>
    <div class="status">{manifest['code_checks']} code checks passed across the printed program and 4×2 variation. Three deliberate faults rejected. {manifest['museum_checks']} actual-museum checks passed.</div>
    <p><button onclick="show('composed')">COMPOSED</button> <button onclick="show('base')">BASE</button></p>
    <figure><a id="full" href="museum/composed.png"><img id="view" src="museum/composed.png" alt="Printed learner point and cube in the actual Pink composition bay"></a><figcaption id="caption">The learner point and cube are in the foreground. Behind them: the existing sphere, cube and sofa, with suspended chairs and water overhead.</figcaption></figure>
    <h2>What this adds to the sequence</h2><p>Patterns returns as a UV circle mask. Materials' normals now meet the viewing direction to produce a rim. Emission, encountered in the Water room, becomes an explicit controllable output. The shader reads normals but does not perturb them, and displaces no vertices. The existing point class and box/collider helper come from the tested Water program through <a href="continuation.json">anchored edits</a>.</p>
    <p>The small program creates its own cube, plinth, point, lamp and label. It imports no production artifact to complete those objects. Its only inherited library dependency is the prepared project's XR Tools. All three files appear once in tutorial.md. Sofa projection and scene construction stay in the wider museum encounter.</p>
    <h2>Two texts, different work</h2><p>The tutorial asks for a prediction, a parameter comparison, the 4×2 variation and a composition the learner can explain. The reflection asks what changes when the room changes around the same recipe. It retains the original collection's material/default/clock questions and the plural-body passage, while distinguishing a visibly emissive surface from a lamp that illuminates its surroundings. Pink alone cannot establish the body's meaning.</p>
    <div class="pair"><figure><img src="museum/in-the-hall.png" alt="Study within the theatrical Pink room"><figcaption>The supplied launcher mounts at the existing stage's front-right side. Museum camera and player remain supplied.</figcaption></figure><figure><img src="museum/studio.png" alt="Same hall and learner study after changing the setting"><figcaption>SETTING removes the suspended surroundings. The primary bodies and stage lamps remain.</figcaption></figure></div>
    <h2>Build and investigate</h2><p>Open <code>res://doc/book/studies/shaders-lineage/Pink.tscn</code> in AdaResearch and Run Current Scene. Its LESSON points to this review's <code>learner/printed/shaping.gd</code>; point that preload at your saved copy to continue independently. The code arrives as a small reconstruction beside the already existing exhibits.</p>
    <p>At local point position (0.65, 1.2, 1.2), the amounts are (1, 0.6, 0.3). Move one metre left to remove dots, 0.6 m down to remove rim, or 0.3 m away to remove glow. Keep the other coordinates fixed. BASE supplies three zeros temporarily; the readout retains the chosen amounts. Repeat layout and mesh UV distortion remain distinct.</p>
    <div class="pair"><figure><img src="learner/printed/dots.png" style="width:300px" alt="Three by three circle mask from printed shader"><figcaption>Printed 3×3 UV mask, in the diagnostic viewport.</figcaption></figure><figure><img src="learner/four-by-two/dots.png" style="width:300px" alt="Four by two variation of the same mask"><figcaption>Exact one-line 4×2 exercise. Geometry remains fixed.</figcaption></figure></div>
    <h2>Evidence</h2><table><thead><tr><th>Version</th><th>Result</th><th>Checks</th></tr></thead><tbody>{rows}</tbody></table>
    <p>GPU assertions separate pigment, rim and emission, hold the image across time, and compare silhouette. A dark diagnostic viewport tests self-brightness and an adjacent grey receiver; a positive illumination control verifies that the neighbour sample actually sees the body. Native museum checks add synthetic XR pickup/action/release, a quarter-metre sampled approach and retained production objects/lights.</p>
    <p>The first diagnostic used a contrast threshold too high for the deliberately dark ground. The corrected measurable threshold passes the actual signal while rejecting the missing-emission version. A first launcher run exposed mixed indentation; the supplied launcher was corrected and rerun. These were test/launcher fixes; the printed learner program stayed unchanged. Earlier attempts are retained in this package.</p>
    <p>Godot 4.6 Compatibility, XR disabled. Passing runs have no script or shader errors; the existing audio-bus UID and renderer warnings remain. These are teacher-authored tests, not an independent ghost student or evidence of human understanding. Physical headset use, interactive F6 and onward travel remain untested. The optional plural-body edit has supplied geometry and is outside this reconstruction's result.</p>
    <p><a href="tests.json">Code results</a> · <a href="museum/report.json">Museum results</a> · <a href="museum/engine.log">Museum log</a> · <a href="manifest.json">Source hashes</a> · <a href="BRIEF.md">Short brief</a> · <a href="changes.html">Text changes</a></p><p>Next: Reaction–Diffusion — a field that keeps what happened to it.</p>
    <script>function show(name){{document.getElementById('view').src='museum/'+name+'.png';document.getElementById('full').href='museum/'+name+'.png';document.getElementById('caption').textContent=name==='base'?'BASE removes the three additions on the learner bodies. It preserves the chosen amounts, ground, roughness, geometry and lamps.':'COMPOSED restores the three chosen amounts on the learner point and cube. The existing collection stays unchanged.';}}</script>'''
    (OUT/'index.html').write_text(page('Pink / three amounts',body),encoding='utf-8')
    (OUT/'README.md').write_text('''# Pink — three amounts

Read parallel.html, tutorial.md and final.md. The tutorial carries Water's PointBody and cube/box construction into a UV mask + view rim + emission recipe. Anchored predecessor edits: continuation.json. Complete learner files are in learner/printed; the exact REPEATS=Vector2(4,2) exercise is in learner/four-by-two. Three deliberately faulty versions are separately labelled and must fail.

This is a review bundle for the existing AdaResearch Godot 4.6 project, not a standalone project or XR toolkit distribution. Use doc/book/studies/shaders-lineage/Pink.tscn in that project. Source snapshots preserve paths under source/. All printed dependencies beyond Godot/XR Tools are included with the learner files. Source-bound tests are in tests.json, museum/report.json and manifest.json.

Production map/artifacts unchanged. No independent learner/headset/human-learning/manual-F6/onward-travel claim. Optional plural-body edit is a separate supplied-geometry exercise, retained but not tested here. Prior water lesson and current water toys remain separate work. Next: Reaction–Diffusion.
''',encoding='utf-8')
    archive=OUT/'pink-review.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for path in sorted(OUT.rglob('*')):
            if path.is_file() and path!=archive and path.suffix not in ['.uid','.import']:
                z.write(path,path.relative_to(OUT))
    with zipfile.ZipFile(archive) as z:assert z.testzip() is None;count=len(z.namelist())
    print(f'Published {count} review files; {manifest["code_checks"]} code and {manifest["museum_checks"]} museum checks.')
if __name__=='__main__':main()
