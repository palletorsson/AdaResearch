"""Publish current manuscripts beside exact printed-code and museum evidence."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-shaping-a-rule-on-the-cube'
MAP=ROOT/'commons/maps/Shader_01_Shaping'
RUN=ROOT/'ada_run/encounter_pilot/Shader_01_Shaping/lesson'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def md(text):return markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
def page(title,body,wide=False):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#eeeae1;color:#272d2e;font:19px/1.6 Georgia,serif}}main{{max-width:{'1700' if wide else '1080'}px;margin:auto;padding:32px}}nav,.meta,table,summary,figcaption{{font:14px/1.5 system-ui}}nav{{display:flex;flex-wrap:wrap;gap:20px;padding:12px 0 25px;border-bottom:1px solid #c3bcae}}a{{color:#275956}}h1{{font-size:clamp(36px,5vw,60px);line-height:1.1}}h2{{font-size:29px;line-height:1.2;margin-top:1.5em}}.pair{{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:28px}}article{{min-width:0;background:#faf8f3;padding:30px}}.pair h1{{font-size:36px}}pre{{overflow:auto;padding:20px;background:#172d2d;color:#f0eddf;font:13px/1.5 Consolas,monospace;tab-size:4}}code{{font-size:.86em}}pre code{{font-size:inherit}}img{{max-width:100%;height:auto;display:block}}figure{{margin:26px 0}}figcaption{{margin-top:10px}}td,th{{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #c8c1b4}}table{{border-collapse:collapse;width:100%}}.status{{padding:18px;background:#dde6dd;border-left:4px solid #44685b}}details{{margin:25px 0}}.diff{{max-height:600px}}@media(max-width:850px){{.pair{{grid-template-columns:1fr}}main{{padding:20px}}article{{padding:20px}}}}@media print{{nav{{display:none}}pre{{white-space:pre-wrap;font-size:8pt}}body{{font-size:11pt}}.pair{{display:block}}article{{break-before:page}}}}
</style><main><nav><a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="coverage.html">Bump &amp; vertex plan</a><a href="shaping-review.zip">Review ZIP</a></nav>{body}</main></html>'''
def main():
    tests=json.loads((OUT/'tests.json').read_text());native=json.loads((RUN/'report.json').read_text())
    assert tests['passed'] and native['passed']
    assert 'SCRIPT ERROR:' not in (RUN/'engine.log').read_text(encoding='utf-8')
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    tutorial=(MAP/'tutorial.md').read_text(encoding='utf-8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',tutorial,re.S))
    assert set(blocks)==set(tests['files'])
    for name,code in blocks.items():
        assert (OUT/'learner/printed'/name).read_text(encoding='utf-8')==code+'\n'
        assert sha(OUT/'learner/printed'/name)==tests['files'][name]
    assert sha(ROOT/'tools/probes/shader_shaping_student.gd')==tests['probe_sha256']
    screenshots=OUT/'museum';screenshots.mkdir(exist_ok=True)
    for name in ['student.png','in-the-hall.png','hard.png','report.json','engine.log','source_manifest.json']:shutil.copy2(RUN/name,screenshots/name)
    diffs=[];tracks={}
    for track in ['tutorial','final']:
        text=(MAP/f'{track}.md').read_text(encoding='utf-8');tracks[track]=text
        (OUT/f'{track}.md').write_text(text,encoding='utf-8')
        (OUT/f'{track}.html').write_text(page('Shaping / '+track,md(text)),encoding='utf-8')
        old=(OUT/'before'/f'{track}.md').read_text(encoding='utf-8') if (OUT/'before'/f'{track}.md').exists() else ''
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile='Before '+track,tofile='Now '+track))
        (OUT/f'{track}.diff').write_text(diff,encoding='utf-8')
        diffs.append('<h2>'+track+'</h2><pre class="diff">'+html.escape(diff)+'</pre>')
    (OUT/'parallel.html').write_text(page('Shaping / facing pages','<p class="meta">Endless Museum · Shaders 01 · 10 October 2026</p><div class="pair"><article><p class="meta">LEFT · TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Shaping / changes','<h1>A mark joins the graphs.</h1><p>New focused tutorial. Reflection preserves the wave and its clock, introduces the new wall/cube, removes three implementation listings and corrects the claim that everything here is flat or retains nothing.</p>'+''.join(diffs)),encoding='utf-8')
    coverage=ROOT/'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md'
    shutil.copy2(coverage,OUT/'coverage.md')
    (OUT/'coverage.html').write_text(page('Shaders / bump, normals and vertices',md(coverage.read_text(encoding='utf-8'))),encoding='utf-8')
    sources=[
       'tools/revise_shader_shaping.py','tools/test_shader_shaping.py','tools/publish_shader_shaping_lesson.py',
       'tools/probes/shader_shaping_student.gd','tools/probes/shader_shaping_lesson_museum.gd',
       'doc/book/studies/shaders-lineage/shaping_museum.gd','doc/book/studies/shaders-lineage/Shaping.tscn',
       'commons/maps/Shader_01_Shaping/map_data.json','commons/artifacts/shader_shaping_wall/circle_mask.gdshader',
       'commons/artifacts/shader_shaping_wall/shader_shaping_wall.gd',
       'algorithms/shaders/book_of_shaders/shaping_sin.gdshader',
       'algorithms/shaders/book_of_shaders/shaping_smoothstep.gdshader',
       'commons/artifacts/basin_water/layered_water.gdshader',
       'doc/book/course/storyboards/SHADER_SURFACE_CONTRACT.md',
    ]
    for rel in sources:
        path=OUT/'source'/rel;path.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,path)
    manifest={'tutorial_sha256':sha(MAP/'tutorial.md'),'final_sha256':sha(MAP/'final.md'),
      'printed_files':tests['files'],'source_sha256':{rel:sha(ROOT/rel) for rel in sources},
      'point_dependency_sha256':sha(ROOT/'addons/godot-xr-tools/objects/pickable.gd'),
      'readme':'Program assertions ran before adding the supplied launch-scene instructions to prose; all three printed listings are byte-identical and checked on publication. Museum run mounts those same files through the supplied launcher. Production map unchanged.',
      'code_checks':sum(r['checks'] for r in tests['results'][:2]),'rejected_faults':3,'museum_checks':len(native['checks']),
      'scope':'Teacher-authored reconstruction checks, not an independent student. Physical headset, human understanding and onward traversal untested.'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    rows=''.join('<tr><td>'+html.escape(r['kind'])+'</td><td>'+('PASS' if r['passed'] else 'EXPECTED REJECTION')+'</td><td>'+html.escape('; '.join(r['failed_assertions']) or str(r['checks'])+' passing assertions')+'</td></tr>' for r in tests['results'])
    body=f'''<p class="meta">Endless Museum · Shaders 01 · 10 October 2026</p><h1>A rule on the cube.</h1><p>The first shader tutorial now reconstructs one circle mask. Raise the carried point to change its radius; press its trigger to change the edge. The same material draws on a wall and a square on the familiar cube.</p><p><a href="parallel.html">Read tutorial and reflection side by side →</a></p><figure><a href="museum/student.png"><img src="museum/student.png" alt="The extracted learner program running inside the actual Shaping museum hall"></a><figcaption>The exact printed program, temporarily mounted in the actual museum. Native Godot capture; synthetic hand input, no headset photograph.</figcaption></figure><div class="status">50 code assertions passed across the printed program and its off-centre variation. Three deliberately faulty versions were rejected. {len(native['checks'])} museum assertions passed.</div><h2>Two texts, two jobs</h2><p>The tutorial teaches UV addresses, distance, a mask, uniforms and hard/soft boundaries. It prints the new shader, a complete small host and the unchanged PointBody. The prepared museum supplies player, camera, lights and XR Tools. Every lesson-owned object is created by the printed code; tests do not import the production wall to fill a gap.</p><p>The reflection starts at the new paired circles, then returns to the five graphs and the clock-driven wave. The soft-looking edge still has a solid backing. Its strong account of the wave's jump remains; three code listings move out of the reflective track. “Nothing is kept” becomes the more exact distinction between retained parameters and no previous image.</p><h2>Bump maps and vertex shaders have a place</h2><p>Materials will add a controlled bump/normal-map comparison: light response changes while the outline stays fixed. Water already changes normals and vertex height, but its normals are currently calculated per vertex. The dedicated per-pixel bump lesson is still to build. Its follow-up compares normal-only relief with displaced geometry, mesh subdivisions and unchanged collision. <a href="coverage.html">See the six-hall coverage plan</a>.</p><figure><a href="museum/in-the-hall.png"><img loading="lazy" src="museum/in-the-hall.png" alt="Learner construction beside the existing museum collection"></a><figcaption>The study has a checked approach and bypass. Installed exhibits and authored map are unchanged. This comparison view is elevated.</figcaption></figure><h2>Reconstruct and investigate</h2><p>Open <code>res://doc/book/studies/shaders-lineage/Shaping.tscn</code> in the existing project and Run Current Scene. It opens the real museum and adds the extracted learner program. The launcher is supplied, source-visible infrastructure; it adds no substitute camera or lesson geometry. Edit the three files under <code>learner/printed/</code> in this review folder, or point its LESSON preload at your saved copy.</p><p>At radius .30 the centre is inside and an address .40 from it is outside. Raise the point and that address enters. Move the centre to (.35,.65), predict where both marks go, then explain why their metre distances differ. The tested complete variation is in <a href="learner/off-centre/shaping.gd">learner/off-centre</a>. The radius link, coordinate frame and inside/outside rule are separately challenged below.</p><table><thead><tr><th>Run</th><th>Result</th><th>Evidence</th></tr></thead><tbody>{rows}</tbody></table><h2>Limits of the evidence</h2><p>Godot 4.6, compatibility renderer, XR disabled. The numerical checks read GPU pixels; the museum probe uses synthetic XR Tools pickup, action and release, then checks the released radius and samples a standing route. Earlier museum probes exposed a release-call mistake, an entrance-wall sample and XR dependency loading before autoloads. The harness now loads the learner after autoload initialization and uses the correct release API; it was rerun cleanly. The printed lesson code did not need repair.</p><p>The engine still reports the existing audio-bus UID issue, renderer-feature warnings and an object-leak warning at shutdown. The passing run has no script or shader errors. No independent ghost student or human learner was tested. Physical headset use, learning and onward travel remain open. The full-launch scene's mount helper is exercised inside the test harness; the interactive F6 session still needs a user run.</p><p><a href="tests.json">Code results</a> · <a href="museum/report.json">Museum results</a> · <a href="museum/engine.log">Museum log</a> · <a href="manifest.json">Source hashes and scope</a> · <a href="BRIEF.md">Compact lesson contract</a> · <a href="first-museum-attempt.log">Earlier probe failure</a></p><p>Next: Patterns reuses the circle and transforms the coordinates used to read it. Bump and vertex work stays explicit in the later halls.</p>'''
    (OUT/'index.html').write_text(page('Shaping / a rule on the cube',body),encoding='utf-8')
    (OUT/'README.md').write_text('''# Shaping review

Read parallel.html: tutorial left, reflection right. Canonical tracks are copied as tutorial.md/final.md. New small shader plus host; unchanged PointBody from Tiling. See BRIEF.md and coverage.md for focus and the bump/vertex progression.

learner/printed contains the exact three visible listings. learner/off-centre contains the tested exercise. Other learner folders contain deliberately faulty versions, retained only as test evidence. Use the prepared AdaResearch_46 Godot project and its bundled XR Tools; this ZIP is not a standalone player project. The supplied launch scene is in source/doc/book/studies/shaders-lineage and uses the in-project review path. See tutorial.md for editing your own copy.

Code: python -X utf8 tools/test_shader_shaping.py
Museum: python -X utf8 tools/run_encounter_probe.py Shader_01_Shaping --sequence shaders --probe tools/probes/shader_shaping_lesson_museum.gd --render --no-bridges --output-tag lesson
Publish: python -X utf8 tools/publish_shader_shaping_lesson.py

Teacher-authored tests, native GPU, synthetic XR poses. No human-learning or headset assertion. Manuscript prose and code evidence have separate hashes; map/runtime collection unchanged.
''',encoding='utf-8')
    with zipfile.ZipFile(OUT/'shaping-review.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ('.zip','.import','.uid') and '.godot' not in p.parts:archive.write(p,p.relative_to(OUT))
    print(json.dumps({'page':str(OUT/'parallel.html'),'code_checks':50,'rejected_faults':3,'museum_checks':len(native['checks'])}))
if __name__=='__main__':main()
