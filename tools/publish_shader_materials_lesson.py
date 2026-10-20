"""Publish the Materials manuscript, continuation and native evidence together."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from publish_shader_shaping_lesson import page as base_page,md
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-materials-light-without-height'
MAP=ROOT/'commons/maps/Shader_11_QueerRubber'
RUN=ROOT/'ada_run/encounter_pilot/Shader_11_QueerRubber/lesson'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):return base_page(title,body,wide).replace('shaping-review.zip','materials-review.zip')

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
    assert sha(ROOT/'tools/probes/shader_materials_student.gd')==tests['probe_sha256']
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for name in ['flat.png','height.png','normal.png','in-the-hall.png','report.json','engine.log','source_manifest.json','learner_control.json']:shutil.copy2(RUN/name,museum/name)
    tracks={};diffs=[]
    for track in ['tutorial','final']:
        text=(MAP/f'{track}.md').read_text(encoding='utf-8');tracks[track]=text
        (OUT/f'{track}.md').write_text(text,encoding='utf-8')
        (OUT/f'{track}.html').write_text(page('Materials / '+track,md(text)),encoding='utf-8')
        before_path=OUT/'before'/f'{track}.md'
        before=before_path.read_text(encoding='utf-8') if before_path.exists() else ''
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='Before '+track,tofile='Now '+track))
        (OUT/f'{track}.diff').write_text(diff,encoding='utf-8');diffs.append('<h2>'+track+'</h2><pre class="diff">'+html.escape(diff)+'</pre>')
    (OUT/'parallel.html').write_text(page('Materials / facing pages','<p class="meta">Endless Museum · Shaders 03 · 10 October 2026</p><div class="pair"><article><p class="meta">LEFT · TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Materials / changes','<h1>Light without height.</h1><p>This map had no tutorial.md. The new lesson continues the tested point and receiver host from Patterns and prints all four resulting files. The reflection now enters through the furnished room and the relief comparison, then returns to the older five-body collection. Its rim, missing-texture, rotation and clock arguments remain; the code blocks are removed and outdated room-wide claims are scoped to the collection that they describe.</p>'+''.join(diffs)),encoding='utf-8')
    coverage=ROOT/'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md';shutil.copy2(coverage,OUT/'coverage.md')
    (OUT/'coverage.html').write_text(page('Shaders / surface progression',md(coverage.read_text(encoding='utf-8'))),encoding='utf-8')
    sources=['tools/revise_shader_materials.py','tools/test_shader_materials.py','tools/publish_shader_materials_lesson.py','tools/publish_shader_shaping_lesson.py','tools/probes/shader_materials_student.gd','tools/probes/shader_materials_lesson_museum.gd','doc/book/studies/shaders-lineage/materials_museum.gd','doc/book/studies/shaders-lineage/Materials.tscn','commons/maps/Shader_11_QueerRubber/map_data.json','commons/artifacts/shader_material_parlour/shader_material_parlour.gd','commons/artifacts/shader_material_parlour/rim_study.gdshader']
    chain=json.loads((OUT/'continuation.json').read_text())
    for item in chain['incoming'].values():sources.append(item['path'])
    sources.append(chain['replaced_shader']['path'])
    for rel in sources:
        p=OUT/'source'/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
    code_count=sum(r['checks'] for r in tests['results'][:2]);museum_count=len(native['checks'])
    scope='Teacher-authored reconstruction and variation, compatibility GPU, synthetic XR poses. No physical headset, independent ghost student, human-learning, onward-travel or interactive F6 claim. Launcher mount helper exercised inside the actual hall.'
    manifest={'tutorial_sha256':sha(MAP/'tutorial.md'),'final_sha256':sha(MAP/'final.md'),'printed_files':tests['files'],'source_sha256':{p:sha(ROOT/p) for p in sources},'point_dependency_sha256':sha(ROOT/'addons/godot-xr-tools/objects/pickable.gd'),'code_checks':code_count,'rejected_faults':3,'museum_checks':museum_count,'scope':scope}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    rows=''.join('<tr><td>'+html.escape(r['kind'])+'</td><td>'+('PASS' if r['passed'] else 'EXPECTED REJECTION')+'</td><td>'+html.escape('; '.join(r['failed_assertions']) or str(r['checks'])+' passing assertions')+'</td></tr>' for r in tests['results'])
    body=f'''<p class="meta">Endless Museum · Shaders 03 · 10 October 2026</p><h1>Light without height.</h1><p>The same circle acquires apparent relief. The same point controls it. The same cube and square remain solid and still.</p><p><a href="parallel.html">Read tutorial and reflection together →</a> · <a href="materials-review.zip">Download review ZIP</a></p>
<div class="status">{code_count} assertions pass across the printed program and its 4×2 variation. Three deliberate faults are rejected. {museum_count} actual-museum checks pass.</div>
<h2>Three readings of one surface</h2><p>Switch between native captures below. Camera, object placement and lamp are held; strength is 1 and roughness is 0.35. Only the shader reading changes.</p>
<div style="display:flex;gap:12px;flex-wrap:wrap;margin:20px 0" id="modes"><button type="button" data-mode="flat" aria-pressed="false">FLAT</button><button type="button" data-mode="height" aria-pressed="true">HEIGHT MAP</button><button type="button" data-mode="normal" aria-pressed="false">NORMAL MAP</button></div>
<style>button{{padding:14px 22px;background:#f8f4eb;border:1px solid #667b75;color:#243e36;cursor:pointer;font:600 14px system-ui}}button[aria-pressed=true]{{background:#304f47;color:white}}</style>
<figure><a id="capture-link" href="museum/height.png"><img id="capture" src="museum/height.png" alt="Height-map relief on the square, cube and held point inside the furnished museum room"></a><figcaption id="caption">HEIGHT MAP: four neighbouring values provide slopes. No vertex has moved.</figcaption></figure>
<script>const labels={{flat:'FLAT: the mesh normal supplies the light response.',height:'HEIGHT MAP: four neighbouring values provide slopes. No vertex has moved.',normal:'NORMAL MAP: encoded directions give a closely matching response. The geometry remains fixed.'}};document.querySelectorAll('#modes button').forEach(b=>b.addEventListener('click',()=>{{const m=b.dataset.mode;document.getElementById('capture').src='museum/'+m+'.png';document.getElementById('capture').alt=labels[m];document.getElementById('capture-link').href='museum/'+m+'.png';document.getElementById('caption').textContent=labels[m];document.querySelectorAll('#modes button').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));}}));</script>
<h2>What the student builds</h2><p>Keep the two square receivers, cube, point and local coordinate controls from Patterns. Prepare the repeated circle as a height image, then derive an encoded normal image from the same values. Compare flat shading, height-derived normals and the encoded normal map. The new coat() method exposes the existing point surface so it can wear the shared material too.</p><p>The gestures now have declared new jobs: local Y changes relief strength, local X changes roughness, and trigger cycles the three readings. The pattern stays fixed during the comparison. The complete four-file program appears once in tutorial.md; <a href="continuation.json">anchored predecessor edits and hashes</a> keep the reconstruction connected to the earlier code.</p>
<div class="pair"><figure><img src="learner/printed/height-data.png" style="width:256px" alt="Repeated circles encoded as a greyscale height field"><figcaption>Height data: values and gradual edges.</figcaption></figure><figure><img src="learner/printed/normal-data.png" style="width:256px" alt="The same circle field encoded as tangent-space normal directions"><figcaption>Normal data: directions encoded as RGB.</figcaption></figure></div>
<h2>The room remains our working environment</h2><figure><a href="museum/in-the-hall.png"><img loading="lazy" src="museum/in-the-hall.png" alt="Relief study beside the familiar furniture, sphere and cube in Materials"></a><figcaption>Native Godot view from slightly above. The learner study occupies the front-right bank of the existing parlour. The furniture, material console and older collection remain.</figcaption></figure>
<p>Open <code>res://doc/book/studies/shaders-lineage/Materials.tscn</code> in the prepared AdaResearch project and run the current scene. The supplied launcher adds this study to the actual museum. The four sibling files under this review folder's <code>learner/printed/</code> are exactly the printed source. Use them, or point the launcher's LESSON preload to your own saved copy. The museum provides its player, camera, floor and bundled XR Tools; the lesson constructs its meshes, collision, label and fixed local lamp.</p><p>This is a lesson launch scene. The production hall layout and artifact scripts were not changed by this writing pass.</p>
<h2>What the paired texts do</h2><p>The tutorial explains data, slopes, tangent-space directions and light response. It separates the apparent relief from silhouette, collision and metre-scale height. The reflection asks what each surface answers to: lamp, eye, coordinate or clock. It starts in the furnished room, then preserves the earlier material collection's more particular questions. The next room, Water, will make vertex displacement explicit.</p>
<h2>Reconstruct, vary, try to break it</h2><p>The 4×2 exercise changes only the repeat count in the map builder. Both textures rebuild from that one edit. The marks become narrower horizontally and wider vertically; at fixed gain their slopes change too. The tests read GPU pixels, check the left/up lighting directions, matching relief, zero strength, roughness, no emission, a level patch, unchanged oblique silhouette and physical backing. They also check the transformed local frame and retained data/meshes.</p>
<figure><img src="learner/four-by-two/height.png" style="width:384px" alt="Four-by-two height-map exercise under controlled lighting"><figcaption>The exact exercise, rendered with a separate fixed test lamp. Its lighting differs from the full museum.</figcaption></figure>
<table><thead><tr><th>Program</th><th>Result</th><th>Evidence</th></tr></thead><tbody>{rows}</tbody></table>
<p>The museum probe exercises synthetic XR pickup, action, movement, release and return, then samples a supported, unobstructed approach every quarter metre. No script or shader errors remain in the passing runs. Existing audio-bus UID and renderer warnings are recorded in the logs. These are teacher-authored reconstruction checks; physical-headset use, independent-student understanding and onward traversal remain untested.</p>
<p><a href="tests.json">Printed-code results</a> · <a href="museum/report.json">Museum results</a> · <a href="museum/engine.log">Museum log</a> · <a href="manifest.json">Hashes and test scope</a> · <a href="BRIEF.md">Short lesson contract</a> · <a href="changes.html">Before/after text</a> · <a href="coverage.html">Bump and vertex coverage</a></p>'''
    (OUT/'index.html').write_text(page('Materials / light without height',body),encoding='utf-8')
    (OUT/'README.md').write_text('''# Materials review

Read parallel.html (tutorial left, reflection right), or tutorial.md/final.md. index.html has the three native comparison images and evidence. BRIEF.md gives the compact lesson contract. This map had no tutorial.md before the pass; before/final.md retains its earlier reflection.

learner/printed contains exactly the four printed files. learner/four-by-two is the exercise. The other learner folders contain deliberate faults. The ZIP requires the prepared AdaResearch project and bundled XR Tools; it is not a standalone museum project. See tutorial.md for the supplied Materials.tscn launcher or your own saved copy.

Teacher-authored reconstruction tests; no independent ghost student, physical-headset or human-learning claim. The launcher's mount helper was exercised inside the actual hall; an interactive F6 session was not run. Existing production map and artifact logic preserved in this pass.

Reproduce:
- python -X utf8 tools/test_shader_materials.py
- python -X utf8 tools/run_encounter_probe.py Shader_11_QueerRubber --sequence shaders --probe tools/probes/shader_materials_lesson_museum.gd --render --no-bridges --output-tag lesson
- python -X utf8 tools/publish_shader_materials_lesson.py
''',encoding='utf-8')
    with zipfile.ZipFile(OUT/'materials-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ('.zip','.import','.uid') and '.godot' not in p.parts:z.write(p,p.relative_to(OUT))
    print(json.dumps({'code_checks':code_count,'museum_checks':museum_count,'rejected_faults':3,'page':str(OUT/'parallel.html')}))
if __name__=='__main__':main()
