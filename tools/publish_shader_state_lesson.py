"""Package the final shader lesson with exact code and native evidence."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from publish_shader_shaping_lesson import page as base_page,md
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-state-a-field-kept'
MAP=ROOT/'commons/maps/Shader_10_ReactionDiffusion'
RUN=ROOT/'ada_run/encounter_pilot/Shader_10_ReactionDiffusion/lesson'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):return base_page(title,body,wide).replace('shaping-review.zip','state-review.zip').replace('Bump &amp; vertex plan','Sequence coverage')
def main():
    tests=json.loads((OUT/'tests.json').read_text());native=json.loads((RUN/'report.json').read_text())
    assert tests['passed'] and native['passed']
    assert not any(e in (RUN/'engine.log').read_text(encoding='utf8') for e in ['SCRIPT ERROR:','SHADER ERROR:'])
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    assert sha(MAP/'tutorial.md')==tests['source_sha256']
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',(MAP/'tutorial.md').read_text(encoding='utf8'),re.S))
    for name,code in blocks.items():
        assert (OUT/'learner/printed'/name).read_text(encoding='utf8')==code+'\n'
        assert sha(OUT/'learner/printed'/name)==tests['files'][name]
    # Retained construction must be actual continuity, not just a claim in prose.
    chain=json.loads((OUT/'continuation.json').read_text())
    incoming=(ROOT/chain['incoming']['shaping.gd']['path']).read_text(encoding='utf8')
    helper=incoming[incoming.index('func make_box'):incoming.index('func _process')].strip()
    assert helper in blocks['shaping.gd']
    assert blocks['point_body.gd']==(ROOT/chain['incoming']['point_body.gd']['path']).read_text(encoding='utf8').rstrip()
    for name in ['continuation','runner','probe']:
        p={'continuation':OUT/'continuation.json','runner':ROOT/'tools/test_shader_state.py','probe':ROOT/'tools/probes/shader_state_student.gd'}[name]
        assert sha(p)==tests[name+'_sha256']
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for name in ['student.png','other-ink.png','in-the-hall.png','wall.png','report.json','engine.log','source_manifest.json','learner_control.json']:shutil.copy2(RUN/name,museum/name)
    (OUT/'images').mkdir(exist_ok=True)
    shutil.copy2(ROOT/'doc/book/figures/shaders/what-the-rule-would-do.png',OUT/'images/what-the-rule-would-do.png')
    tracks={};diffs=[]
    for track in ['tutorial','final']:
        raw=(MAP/f'{track}.md').read_text(encoding='utf8');tracks[track]=raw.replace('/book-images/figures/shaders/what-the-rule-would-do.png','images/what-the-rule-would-do.png')
        (OUT/f'{track}.md').write_text(tracks[track],encoding='utf8')
        (OUT/f'{track}.html').write_text(page('State / '+track,md(tracks[track])),encoding='utf8')
        before=(OUT/'before'/f'{track}.md').read_text(encoding='utf-8-sig')
        delta=''.join(difflib.unified_diff(before.splitlines(True),raw.splitlines(True),fromfile='Before '+track,tofile='Now '+track))
        (OUT/f'{track}.diff').write_text(delta,encoding='utf8');diffs.append('<h2>'+track+'</h2><pre class="diff">'+html.escape(delta)+'</pre>')
    (OUT/'parallel.html').write_text(page('State / facing pages','<p class="meta">Endless Museum · Shaders 06 · 10 October 2026</p><div class="pair"><article><p class="meta">LEFT · TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf8')
    (OUT/'changes.html').write_text(page('State / changes','<h1>A past supplied.</h1><p>A new focused tutorial continues the point and cube from Pink. The field runner and numerical packing are explicit supplied support, printed in full; no production artifact fills an omitted learner step. The reflection retains the older green/frost comparison, but now starts with the functioning retained wall. It removes executable code and corrects the claim that nothing in the sequence keeps state. The historical figure remains labelled as an earlier numerical comparison. The authored hall and installed artifacts are unchanged.</p>'+''.join(diffs)),encoding='utf8')
    coverage=ROOT/'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md';shutil.copy2(coverage,OUT/'coverage.md')
    (OUT/'coverage.html').write_text(page('Shaders / coverage',md(coverage.read_text(encoding='utf8'))),encoding='utf8')
    sources=['tools/revise_shader_state_lesson.py','tools/test_shader_state.py','tools/publish_shader_state_lesson.py','tools/publish_shader_shaping_lesson.py','tools/probes/shader_state_student.gd','tools/probes/shader_state_lesson_museum.gd','tools/probes/shader_state_museum.gd','doc/book/studies/shaders-lineage/state_museum.gd','doc/book/studies/shaders-lineage/State.tscn','commons/maps/Shader_10_ReactionDiffusion/map_data.json','commons/artifacts/shader_state_chamber/chamber.gd','commons/artifacts/shader_state_chamber/field.gd','commons/artifacts/shader_state_chamber/field_step.gdshader','commons/artifacts/shader_state_chamber/field_view.gdshader','commons/interactables/push_button.tscn']
    sources.extend(d['path'] for d in chain['incoming'].values())
    for rel in sources:
        p=OUT/'source'/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
    manifest={'tutorial_sha256':sha(MAP/'tutorial.md'),'final_sha256':sha(MAP/'final.md'),'printed_files':tests['files'],'source_sha256':{p:sha(ROOT/p) for p in sources},'code_checks':sum(r['checks'] for r in tests['results'][:2]),'museum_checks':len(native['checks']),'rejected_faults':3,'scope':'Teacher-authored exact printed reconstruction and native museum mount. Synthetic XR and press receivers; no independent ghost student, physical headset, human-learning, manual F6 or onward-travel claim. Production room unchanged. Bundled reflection uses a relative image link; canonical source hash remains recorded.'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    rows=''.join('<tr><td>'+html.escape(r['kind'])+'</td><td>'+('PASS' if r['passed'] else 'EXPECTED REJECTION')+'</td><td>'+html.escape('; '.join(r['failed_assertions']) or str(r['checks'])+' passing assertions')+'</td></tr>' for r in tests['results'])
    body=f'''<p class="meta">Endless Museum · Shaders 06 · 10 October 2026</p><h1>A field kept.</h1><p>The point returns as an XY selector. Hold it and trigger to plant a mark. Release, then choose whether the field stays still or advances. The same record appears on the point, cube and square.</p><p><a href="parallel.html">Read tutorial and reflection side by side →</a> · <a href="state-review.zip">Download review ZIP</a></p>
    <div class="status">{manifest['code_checks']} code assertions passed across the printed program and F = 0.065 variation. Three deliberate faults rejected. {manifest['museum_checks']} actual-museum assertions passed.</div>
    <figure><a href="museum/student.png"><img src="museum/student.png" alt="Learner point, cube and field with nearby physical controls in the real museum"></a><figcaption>Native Godot capture. The learner study stands in front; the installed large wall has its own field. Both have completed 6,000 updates from the same seed, with different display ink.</figcaption></figure>
    <h2>The new capability</h2><p>Keep one completed state, read it, write the next separately, then exchange their roles. The update shader reads U, V and their neighbours. The display shader reads V and chooses a colour. Changing ink cannot rewrite the model; a mark can.</p><p>Five complete listings appear once in tutorial.md. Pink's PointBody and box helper remain unchanged. The GPU scheduler, 12-bit packing and named button prefab are declared support. The learner can inspect their full boundary without treating every scheduling detail as a second lesson. No production artifact is imported to construct the learner field.</p>
    <h2>Build and investigate</h2><p>Use <code>res://doc/book/studies/shaders-lineage/State.tscn</code> in the prepared project. It mounts the printed program beside the State chamber. Point its LESSON preload to your saved copy. Hold the point; X from −1 to 1 and Y from 0.5 to 2.5 address the square. Trigger plants; Z is ignored. The nearby buttons operate this study only.</p><p>Predict CLEAR → STEP. Plant, release, step and run. Hold the result and change its ink. Then change only F from .055 to .065 and compare the same seeded interior address after one update: U changes from approximately .0275 to .0325. Compare later pictures at equal update counts. The point is a selector here; the large installed wall additionally accepts direct touch.</p>
    <div class="pair"><figure><img src="learner/printed/grown.png" alt="Default F .055 field"><figcaption>F = .055 after 6,000 updates.</figcaption></figure><figure><img src="learner/feed-065/grown.png" alt="F .065 variation"><figcaption>Exact one-line exercise, F = .065, at the same count. These are diagnostic GPU displays, separate from the room captures.</figcaption></figure></div>
    <h2>The two readings</h2><p>The tutorial gives a reproducible operation and asks the learner to use it. The reflection asks what a retained trace preserves, and what it cannot tell us about its maker. The older green square and the frost remain useful counterexamples: a requested past that was never supplied, and an appearance of growth without that growth process.</p><p>The historical 256 × 256 figure is preserved as an earlier experiment. Today's field is 96 × 96. The reflection no longer claims that the dark sphere is the only thing in the sequence with a past.</p>
    <figure><a href="museum/in-the-hall.png"><img src="museum/in-the-hall.png" alt="State chamber and learner study within the existing museum"></a><figcaption>Placement keeps a checked approach beside the controls. Existing wall, sphere, cube, green panel, frost and seating remain. The small reconstruction is added by the lesson launcher.</figcaption></figure>
    <h2>Evidence and its limits</h2><table><thead><tr><th>Version</th><th>Result</th><th>Evidence</th></tr></thead><tbody>{rows}</tbody></table>
    <p>Numerical assertions compare GPU output against an independent equation at every cell, then test another step and reuse of the two buffer groups. The display is also rendered and sampled. Palette changes must preserve every state byte. The fault versions compile but fail their relevant causal checks.</p><p>Native museum checks add synthetic XR pickup, an asymmetric address in the rotated hall, release, all five press receivers, a supported clear approach and real cube collision. The learner and installed solver produce identical state at 6,000 equal steps. This establishes agreement on this renderer, not universal numerical equivalence.</p>
    <p>The first draft used a name reserved by Godot; it was corrected in the printed source. The first numerical run also exposed an exact floating-point equality in the geometry test; that assertion now uses approximate equality. Both earlier receipts are retained. Passing runs have no script or shader errors. Existing audio UID and renderer warnings remain.</p>
    <p>Teacher-authored tests on Godot 4.6 Compatibility, XR disabled. No independent ghost student, physical headset, human understanding, manual F6 session or onward travel has been tested. State lasts while the study is loaded; no save system or fluid/curved-surface simulation is implied.</p>
    <p><a href="tests.json">Code results</a> · <a href="museum/report.json">Museum results</a> · <a href="manifest.json">Source hashes</a> · <a href="continuation.json">Incoming code and changes</a> · <a href="BRIEF.md">Compact brief</a> · <a href="first-parse-attempt.log">First draft error</a> · <a href="first-numeric-check.json">First numerical receipt</a></p>
    <h2>The six-hall progression now has its ending</h2><p>Colour rule → repeated coordinates → normal/light response → moved vertices → composed material → retained field. Each has a focused printed example and native reconstruction evidence. A complete sequence reading and independent student pass remain the next useful review.</p>'''
    (OUT/'index.html').write_text(page('State / a field kept',body),encoding='utf8')
    (OUT/'README.md').write_text('''# State — a field kept

Read parallel.html or tutorial.md and final.md. Review the short BRIEF.md and sequence coverage. Five complete learner files are in learner/printed; the exact one-line exercise is in learner/feed-065. The other three learner folders deliberately contain faulty programs and are test evidence only.

This bundle belongs to the prepared AdaResearch Godot 4.6 project; it is not a standalone XR application. Supplied dependencies: its player/camera, XRTools and named push_button prefab. The full numerical scheduler and data packing are printed support. Open doc/book/studies/shaders-lineage/State.tscn in the project. Its LESSON preload chooses the saved learner program. The authored museum hall remains unchanged.

Reproduce:
- python -X utf8 tools/test_shader_state.py
- python -X utf8 tools/run_encounter_probe.py Shader_10_ReactionDiffusion --sequence shaders --probe tools/probes/shader_state_lesson_museum.gd --render --no-bridges --output-tag lesson
- python -X utf8 tools/publish_shader_state_lesson.py

Tests are teacher-authored. Read test manifests/logs for scope; do not infer independent student understanding or physical-headset validation. Source snapshots preserve project paths. The reflection's image URL is made relative in this review copy for offline reading.
''',encoding='utf8')
    with zipfile.ZipFile(OUT/'state-review.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ('.zip','.uid','.import'):archive.write(p,p.relative_to(OUT))
    print(json.dumps({'page':str(OUT/'parallel.html'),'checks':manifest['code_checks'],'museum':manifest['museum_checks']}))
if __name__=='__main__':main()
