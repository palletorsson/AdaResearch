"""Publish the Water manuscript, continuation and native evidence together."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from publish_shader_shaping_lesson import page as base_page,md
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-water-a-surface-that-moves'
MAP=ROOT/'commons/maps/Shader_09_FBM'
RUN=ROOT/'ada_run/encounter_pilot/Shader_09_FBM/lesson'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):return base_page(title,body,wide).replace('shaping-review.zip','water-review.zip')

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
    assert sha(ROOT/'tools/probes/shader_water_student.gd')==tests['probe_sha256']
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for name in ['colour.png','height.png','normal.png','four-corners.png','in-the-hall.png','report.json','engine.log','source_manifest.json','learner_control.json']:shutil.copy2(RUN/name,museum/name)
    tracks={};diffs=[]
    for track in ['tutorial','final']:
        text=(MAP/f'{track}.md').read_text(encoding='utf-8');tracks[track]=text
        (OUT/f'{track}.md').write_text(text,encoding='utf-8')
        (OUT/f'{track}.html').write_text(page('Water / '+track,md(text)),encoding='utf-8')
        before_path=OUT/'before'/f'{track}.md'
        before=before_path.read_text(encoding='utf-8') if before_path.exists() else ''
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='Before '+track,tofile='Now '+track))
        (OUT/f'{track}.diff').write_text(diff,encoding='utf-8');diffs.append('<h2>'+track+'</h2><pre class="diff">'+html.escape(diff)+'</pre>')
    (OUT/'parallel.html').write_text(page('Water / facing pages','<p class="meta">Endless Museum · Shaders 04 · 10 October 2026</p><div class="pair"><article><p class="meta">LEFT · TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Water / changes','<h1>A surface that moves.</h1><p>This map had no tutorial.md. The new three-file program continues Water from the tested Materials point and box construction. The reflection retains its appearance/support question and the passage about domain warp, while replacing the obsolete small sine pool, full glass lid, missing controls and clock claims with the actual bathhouse. Full code belongs in the tutorial.</p>'+''.join(diffs)),encoding='utf-8')
    coverage=ROOT/'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md';shutil.copy2(coverage,OUT/'coverage.md')
    (OUT/'coverage.html').write_text(page('Shaders / surface progression',md(coverage.read_text(encoding='utf-8'))),encoding='utf-8')
    sources=['tools/revise_shader_water_lesson.py','tools/test_shader_water.py','tools/publish_shader_water_lesson.py','tools/publish_shader_shaping_lesson.py','tools/probes/shader_water_student.gd','tools/probes/shader_water_lesson_museum.gd','doc/book/studies/shaders-lineage/water_museum.gd','doc/book/studies/shaders-lineage/Water.tscn','commons/maps/Shader_09_FBM/map_data.json','commons/artifacts/basin_water/basin_water.gd','commons/artifacts/basin_water/water_study.gd','commons/artifacts/basin_water/layered_water.gdshader','algorithms/shaders/book_of_shaders/fbm_basic.gdshader','algorithms/shaders/book_of_shaders/fbm_ridged.gdshader','algorithms/shaders/book_of_shaders/fbm_turbulence.gdshader','algorithms/shaders/book_of_shaders/fbm_domain_warp.gdshader']
    chain=json.loads((OUT/'continuation.json').read_text())
    for item in chain['incoming'].values():sources.append(item['path'])
    for rel in sources:
        p=OUT/'source'/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
    code_count=sum(r['checks'] for r in tests['results'][:2]);museum_count=len(native['checks'])
    scope='Teacher-authored reconstruction and variation, compatibility GPU, synthetic XR poses. No physical headset, independent ghost student, human-learning, onward-travel or interactive F6 claim. Launcher mount helper exercised inside the actual hall.'
    manifest={'tutorial_sha256':sha(MAP/'tutorial.md'),'final_sha256':sha(MAP/'final.md'),'printed_files':tests['files'],'source_sha256':{p:sha(ROOT/p) for p in sources},'point_dependency_sha256':sha(ROOT/'addons/godot-xr-tools/objects/pickable.gd'),'code_checks':code_count,'rejected_faults':3,'museum_checks':museum_count,'scope':scope}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    rows=''.join('<tr><td>'+html.escape(r['kind'])+'</td><td>'+('PASS' if r['passed'] else 'EXPECTED REJECTION')+'</td><td>'+html.escape('; '.join(r['failed_assertions']) or str(r['checks'])+' passing assertions')+'</td></tr>' for r in tests['results'])
    body=f'''<p class="meta">Endless Museum · Shaders 04 · 10 October 2026</p><h1>A surface that moves.</h1><p>The point becomes a control for layered water. Raise it for relief; move sideways to choose phase. The cube and glass remain rigid.</p><p><a href="parallel.html">Read tutorial and reflection together →</a> · <a href="water-review.zip">Download review ZIP</a></p>
<div class="status">{code_count} assertions pass across the exact printed program and its four-corner variation. Three deliberate faults are rejected. {museum_count} actual-museum checks pass.</div>
<h2>Colour, normal, height</h2><p>These native captures hold the learner camera, lamp, relief and phase. Choose the shader reading, or compare the same HEIGHT reading with only four vertices.</p>
<div style="display:flex;gap:12px;flex-wrap:wrap;margin:20px 0" id="modes"><button type="button" data-mode="colour" aria-pressed="false">COLOUR</button><button type="button" data-mode="normal" aria-pressed="false">NORMAL</button><button type="button" data-mode="height" aria-pressed="true">HEIGHT</button><button type="button" data-mode="four-corners" aria-pressed="false">FOUR CORNERS</button></div>
<style>button{{padding:14px 22px;background:#f8f4eb;border:1px solid #667b75;color:#243e36;cursor:pointer;font:600 14px system-ui}}button[aria-pressed=true]{{background:#304f47;color:white}}</style>
<figure><a id="capture-link" href="museum/height.png"><img id="capture" src="museum/height.png" alt="The printed water study in a small tray beside the museum bathhouse"></a><figcaption id="caption">HEIGHT: the vertices move. Glass and cube stay fixed.</figcaption></figure>
<script>const labels={{colour:'COLOUR: the layered field colours a flat plane.',normal:'NORMAL: calculated directions change lighting; the plane stays flat.',height:'HEIGHT: the vertices move. Glass and cube stay fixed.','four-corners':'FOUR CORNERS: the same field and controls, but only two triangles can change shape.'}};document.querySelectorAll('#modes button').forEach(b=>b.addEventListener('click',()=>{{const m=b.dataset.mode;document.getElementById('capture').src='museum/'+m+'.png';document.getElementById('capture').alt=labels[m];document.getElementById('capture-link').href='museum/'+m+'.png';document.getElementById('caption').textContent=labels[m];document.querySelectorAll('#modes button').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));}}));</script>
<h2>What is carried forward</h2><p>PointBody is unchanged from Materials. Its coat method supplies a dark rigid surface here; its hand action cycles the three readings. The host keeps the earned box/collider construction, adding an optional material and returned reference for the glass. One horizontal plane replaces the vertical receivers. The cube remains a rigid witness, without the water shader.</p><p>Noise returns as a field evaluated on demand. A short loop doubles frequency and halves weight, then divides by the weight used. The normalized signed field bounds the displacement. The small lesson contains its full host, PointBody and water shader. <a href="continuation.json">Anchored changes</a> connect it to the tested Materials files. Nothing is recovered from the production artifact to make the student code run.</p>
<h2>How this follows bump mapping</h2><p>Materials changed per-fragment shading normals while the silhouette stayed fixed. Water reuses the slope idea at the vertices and introduces VERTEX.y. Normals now interpolate between vertices; both the resulting light response and displaced shape depend on subdivision. Pigment can retain fine detail even on two triangles. A visible height change still creates no collision.</p>
<div class="pair"><figure><img src="learner/printed/height.png" style="width:384px" alt="Dense plane displaced by the printed shader, seen at a low angle"><figcaption>2,500 vertices. Diagnostic GPU view without the tray, so the outline is visible.</figcaption></figure><figure><img src="learner/four-corners/height.png" style="width:384px" alt="The same field on a plane with four vertices"><figcaption>Four vertices, two triangles. The exact printed exercise, at the same phase and relief.</figcaption></figure></div>
<h2>The working place is the museum</h2><figure><a href="museum/in-the-hall.png"><img loading="lazy" src="museum/in-the-hall.png" alt="Small learner water tray on the dry bank beside the large bathhouse pool and bridge"></a><figcaption>The supplied learner scene mounts beside the existing 11 × 11 m basin. The original console, rigid specimens and four supporting graphs remain.</figcaption></figure>
<p>Open <code>res://doc/book/studies/shaders-lineage/Water.tscn</code> in the existing AdaResearch project and Run Current Scene. The launcher uses this review folder's <code>learner/printed/shaping.gd</code> and its two siblings; point its LESSON preload to your own saved copy to continue there. The museum supplies its player/camera/floor and XR Tools. All lesson geometry, labels, material, lamp and colliders come from the printed source.</p><p>This writing pass adds a lesson launch scene. It preserves the production hall layout, artifact logic and sequence order.</p>
<h2>What the reflection keeps</h2><p>The appearance/support question remains: the thing you walk on is not the thing you look at. The text now describes the actual narrow bridge, held phase, controls and normalized field. It distinguishes that pool from the supporting graphs' raw sums and wrapping engine clock. Domain warp remains complexity inside one frame; the later state-based hall will retain results between frames.</p>
<h2>Evidence and its limits</h2><table><thead><tr><th>Program</th><th>Result</th><th>Evidence</th></tr></thead><tbody>{rows}</tbody></table>
<p>GPU checks compare normals, silhouette, zero relief, held phase, positive/negative full turns and one/four scales. A diagnostic output checks the one-octave normalization invariant while preserving the printed field and noise functions. Physics rays distinguish the glass top from the tray floor. The deliberate omissions remove displacement, normal adjustment or normalization; each is rejected for the relevant reason.</p><p>The actual-museum checks add synthetic XR pickup, movement, action, release and restoration, plus sampled floor support and standing clearance to the study. They also check the small glass and the original full-scale bridge. No script or shader errors remain in the passing runs; the existing audio-bus UID and renderer warnings remain in the logs. These are teacher-authored reconstruction checks. Independent-student understanding, physical-headset use, manual F6 and onward traversal are not claimed.</p>
<p><a href="tests.json">Code results</a> · <a href="museum/report.json">Museum results</a> · <a href="museum/engine.log">Museum log</a> · <a href="manifest.json">Hashes and scope</a> · <a href="BRIEF.md">Short contract</a> · <a href="changes.html">Before/after text</a> · <a href="coverage.html">Shader progression</a></p><p>Next: Pink Extravaganza, a composition of operations the student can now separate.</p>'''
    (OUT/'index.html').write_text(page('Water / a surface that moves',body),encoding='utf-8')
    (OUT/'README.md').write_text('''# Water review

Read parallel.html (tutorial left, reflection right), or tutorial.md/final.md. index.html has the native mode and resolution comparison images and evidence. BRIEF.md gives the compact lesson contract. This map had no tutorial.md before the pass; before/final.md retains its earlier reflection.

learner/printed contains exactly the three printed files. learner/four-corners is the exercise. The other learner folders contain deliberate faults. The ZIP requires the prepared AdaResearch project and bundled XR Tools; it is not a standalone museum project. See tutorial.md for the supplied Water.tscn launcher or your own saved copy.

Teacher-authored reconstruction tests; no independent ghost student, physical-headset or human-learning claim. The launcher's mount helper was exercised inside the actual hall; an interactive F6 session was not run. Existing production map and artifact logic preserved in this pass.

Reproduce:
- python -X utf8 tools/test_shader_water.py
- python -X utf8 tools/run_encounter_probe.py Shader_09_FBM --sequence shaders --probe tools/probes/shader_water_lesson_museum.gd --render --no-bridges --output-tag lesson
- python -X utf8 tools/publish_shader_water_lesson.py
''',encoding='utf-8')
    with zipfile.ZipFile(OUT/'water-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ('.zip','.import','.uid') and '.godot' not in p.parts:z.write(p,p.relative_to(OUT))
    print(json.dumps({'code_checks':code_count,'museum_checks':museum_count,'rejected_faults':3,'page':str(OUT/'parallel.html')}))
if __name__=='__main__':main()
