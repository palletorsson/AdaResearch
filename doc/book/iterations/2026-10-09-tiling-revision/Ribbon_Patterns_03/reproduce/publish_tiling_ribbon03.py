"""Publish the final Tiling lesson and update the nine-hall review route."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as base_page
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Ribbon_Patterns_03'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_03'
def page(title,body,wide=False):return base_page(title,body,wide).replace('tiling-disco-review.zip','tiling-ribbon03-review.zip')
def md(s):return markdown.markdown(s.replace('/book-images/figures/tiling/fabric-studio-museum.png','images/fabric-studio-museum.png').replace('../../../doc/book/iterations/2026-09-21-growing-dress/index.html','../../2026-09-21-growing-dress/index.html'),extensions=['fenced_code','tables','footnotes'])
def write(n,s):(O/n).write_text(s,encoding='utf8')
def sync_plan(tests,native):
 p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
 row=next(x for x in data['lessons'] if x['id']=='Ribbon_Patterns_03')
 def fmt(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
 old=fmt(row);assert raw.count(old)==1
 row.update(object='A complete reduced sampling shader on the existing studio wall and preview Skirt, with the existing source editor and controls.',
 change='UV times horizontal/vertical repeat counts, plus horizontal phase, samples the supplied texture into ALBEDO. A small Lesson child reapplies the shader whenever the host regenerates materials.',
 dependsOn=['Ribbon_Patterns_02','Pattern_Foundry','Pattern_Temple'],
 reuses='Repeated source reading, palette-to-colour, material ownership and saved copies. Supplied studio retains four-by-four mark; earlier two-by-three source is not silently imported.',
 given='Existing fabric_shader_studio.gd and Recipe.material convert palette indices to texture/uniforms and construct the actual wall/editor/preview. Three complete printed files: shader, adapter and studio scene. Museum supplies player, wardrobe and runway.',
 later='Only paint/OFFSET/REPEAT/UNDO act on the reduced preview. UV inspection, cut-out, finish and displacement remain full-studio encounters. SAVE stores supported cells/settings, not palette/shader/vertical count/meshes/LOOK. WEAR chooses current preview silhouette separately and uses original wardrobe shader. Source code and GPU readback are distinct evidence; physical headset and other renderer backends untested.',
 checks=[f"{tests['checks']} Godot assertions:21 printed and21 independent three-vertical edit, including60 GPU pixel comparisons across six renders and complete host reconstruction.",'Seven executable faults caught by assertions: absent repeat/phase, phase on wrong axis, exchanged UV components, clamp, linear filter and missed skirt. Additional source_color-removal diagnostic was not detected on Compatibility and is explicitly not claimed as a caught fault.',f"{len(native['checks'])} real museum checks: pointer source/parameters, isolated save/wear/undo/runway, live mirror World3D, three supported approaches, printed scene and edited shader. No physical headset claim."],
 transfer='Change only shader vertical multiplier2 to3. Predict2/3m vertical span on2mwall; UV(.15,.20) at4horizontal phase0 reads source[2][2]=3gold. SAVE/WEAR still rebuilds original two-vertical receiver because shader source is absent from recipe.',
 carry='Sampling operation; UV counts versus metres; saved record versus interpreter; shared recipe across differently mapped bodies.',
 next='Tiling nine-hall draft review complete. Read the sequence together before starting Change_Intro; no work on Change in this pass.',
 notes='9 October: initial three-file shader tutorial in supplied studio. Preserved reflection except three code fences converted to prose context. Corrected stale technical placement coordinates. No production script, map, registry or sequence changes. Isolated runtime replacement only, original appearance saves untouched.',
 summary='Use the existing fabric studio to write a small shader: multiply UV by repeat counts, add phase and sample the supplied texture into ALBEDO. Predict specific texels and separate repeat span from offset. Keep source editor, wall and preview skirt as the host; a supplied Lesson child reconnects the shader after edits. Change vertical repeats from two to three, then show why SAVE and WEAR cannot carry that code change: the saved recipe is interpreted by the original wardrobe shader. Return to the full studio to compare the record on a garment and procession.')
 new=raw.replace(old,fmt(row),1);parsed=json.loads(new)
 assert [x for x in data['lessons'] if x['id']!='Ribbon_Patterns_03']==[x for x in parsed['lessons'] if x['id']!='Ribbon_Patterns_03']
 assert p.read_text(encoding='utf8')==raw;p.write_text(new,encoding='utf8')
 write('plan-entry.json',json.dumps(row,ensure_ascii=False,indent=2)+'\n')
 write('plan-entry.diff',''.join(difflib.unified_diff((O/'before/plan-entry.json').read_text(encoding='utf8').splitlines(True),(O/'plan-entry.json').read_text(encoding='utf8').splitlines(True),fromfile='before/plan-entry.json',tofile='after/plan-entry.json')))
def main():
 tests=json.loads((O/'tests.json').read_text());faults=json.loads((O/'mutations.json').read_text())
 run=R/'ada_run/encounter_pilot/Ribbon_Patterns_03/source-to-skirt';native=json.loads((run/'report.json').read_text())
 assert tests['all_passed'] and faults['all_rejected'] and native['passed']
 assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
 (O/'museum').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
 for p in run.iterdir():
  if p.suffix in ['.png','.cfg'] or p.name in ['report.json','source_manifest.json','engine.log'] or p.name.endswith('-recipe.json'):shutil.copy2(p,O/'museum'/p.name)
 shutil.copy2(R/'doc/book/figures/tiling/fabric-studio-museum.png',O/'images/fabric-studio-museum.png')
 prediction=json.loads((O/'prediction.json').read_text());assert sha(M/'tutorial.md')==prediction['source_sha256']
 tracks={};diffs=[]
 for name in ['tutorial','final','technical']:
  text=(M/(name+'.md')).read_text(encoding='utf8');tracks[name]=text;write(name+'.md',text)
  write(name+'.html',page('Ribbon Patterns 03 / '+name,md(text)))
  before=(O/'before'/(name+'.md')).read_text(encoding='utf8') if name!='tutorial' else ''
  delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile=('before/' if before else 'absent/')+name+'.md',tofile='after/'+name+'.md'))
  write(name+'.diff',delta);diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(delta)}</pre>')
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl|ini)\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==3
 for n,code in blocks.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==code+'\n' and sha(O/'learner/printed'/n)==prediction['files'][n]
 assert (M/'map_data.json').read_bytes()==(O/'before/map_data.json').read_bytes()
 old=(O/'before/final.md').read_text(encoding='utf8')
 expected=re.sub(r'```glsl\n.*?\n```\n\n','',old,flags=re.S).replace('`UV` supplies an address from the mesh; multiplication repeats it, addition shifts it, and the texture wraps.','The mesh supplies a surface address; multiplication repeats it, addition shifts it, and the texture wraps.').replace('Here `discard` stops drawing a fragment.','Here the shader stops drawing selected fragments.')
 assert tracks['final']==expected
 sync_plan(tests,native)
 sources=[M/n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+[R/p for p in ['commons/artifacts/fabric_shader_studio/fabric_recipe.gd','commons/artifacts/fabric_shader_studio/fabric_shader_studio.gd','commons/artifacts/fabric_shader_studio/fabric.gdshader','commons/player/super_drag_outfit.gd','commons/maps/sequences/tiling.json']]
 write('sources.json',json.dumps([{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
 intro='<p class="meta kicker">Endless Museum / Tiling 09</p><p><a href="../Ribbon_Patterns_02/parallel.html">Previous: Ribbon Patterns 02</a> · Final hall of Tiling</p>'
 write('parallel.html',page('Ribbon Patterns 03 / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True))
 write('changes.html',page('Ribbon Patterns 03 / changes','<h1>A source reaches a skirt</h1><p>The initial tutorial supplies a complete small shader inside the existing studio. The reflection retains its encounters and questions while code fences become prose context. Technical notes now name the actual compact-map coordinates.</p>'+''.join(diffs)))
 report=f'''# A source reaches a skirt

Tiling · Ribbon Patterns 03 · 9 October 2026 · ninth of nine halls

**The address calculation is small. The receiving world is already there.**

## The closing lesson

The student writes a complete repeat-and-offset sampling shader. The supplied studio creates the source editor, wall and preview skirt, converts palette indices to a texture, and binds named shader parameters. A small Lesson child reconnects the new shader after the studio creates fresh materials. The complete shader, adapter and study scene are printed.

This keeps the lesson inside the museum. It does not rebuild a player, garment system or room. The studio's four-by-four mark is declared as the supplied source; the earlier two-by-three learner source is not silently imported. The operation is carried forward, with each source and receiver named.

The independent edit changes vertical repeats from two to three. At UV(0.15,0.20), four horizontal repeats and zero phase now read gold at source row2,column2. The wall has three copies over two metres. The source and mesh remain unchanged.

SAVE and WEAR expose a useful limit. The preview runs the edited shader, but the saved recipe contains no shader text or vertical count. The wardrobe rebuilds the original two-vertical shader. The lesson asks the student to explain that difference before proposing a schema extension.

## The two texts

The tutorial concentrates on sampling, predictions, the supplied host and the saved record. Cut-outs, material finish and displacement remain later experiments. The reflection keeps those wider encounters, the mirror, the procession and the question of what travels with a body. Its three shader excerpts are removed; the surrounding explanations remain. The ending into Change Intro is preserved.

The technical notes contained old placement coordinates from before the compact hall. They now match the map: studio(6,5), mirror(12,7), runway(23,3), laser(23,24). No production script, map, registry, artifact placement or sequence order changed.

## Evidence

- **{tests['checks']} Godot assertions passed:**21 on the printed scene and21 on the independent three-vertical shader. Six GPU renders include60 pixel comparisons against predicted source colours.
- **{len(faults['results'])} executable faults caught:** ignored repeat/offset, phase on the wrong axis, exchanged UV components, clamped texture addressing, linear filtering and a missed preview skirt.
- **{len(native['checks'])} native museum checks passed:** actual pointer actions, source/parameter changes, retained collision, isolated SAVE/WEAR/UNDO and runway application, shared mirror World3D, three supported approaches, the printed scene and edited shader in the existing studio position.

An initial test-probe type annotation was repaired before execution. The first museum probe used a separate camera, so it failed the wardrobe-viewer binding and runway activation checks. The final probe uses the museum's real camera and culling path; both checks pass. These were test-harness repairs, not lesson or production fixes. Diagnostic receipts remain available.

One extra variant removed `source_color`. The sampled pixels did not change under the tested OpenGL Compatibility backend. It is retained as a renderer diagnostic, not counted as a detected defect or evidence for other renderers. Physical headset use, Quest performance and independent learner understanding remain untested. Current runs have no lesson script errors; existing UID/registry/renderer warnings remain.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Changes](changes.html) · [Code results](tests.json) · [Fault results](mutations.json) · [Renderer diagnostic](renderer-diagnostic.json) · [Museum receipt](museum/report.json) · [Review ZIP](tiling-ribbon03-review.zip)

All nine halls now have revised draft tutorial/reflection pairs in the [Tiling route](../plan.html). The [editable plan](http://localhost:3003/tutorial-plan?map=Ribbon_Patterns_03&view=summaries) retains draft status. The next useful step is reading the complete sequence together, before moving to Change Intro.
'''
 for a,b in [('passed:**21','passed:** 21'),('and21','and 21'),('include60','include 60'),('row2,column2','row 2, column 2')]:report=report.replace(a,b)
 write('REPORT.md',report)
 pictures=[('installed-studio','The original studio: source editor, wall and preview garment.'),('installed-cutout','Full shader experiment: drawing changes, collision stays rectangular.'),('installed-runway','The saved recipe reaches performer skirts; their other materials remain.'),('student-repeat4','Exact printed shader: four horizontal and two vertical repeats.'),('student-repeat8-offset','The source editor changes a cell; eight repeats and phase0.125 use the same shader.'),('student-three-vertical','Independent edit: three vertical repeats on the same wall and skirt meshes.')]
 figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in pictures)
 write('index.html',page('Ribbon Patterns 03 / a source reaches a skirt',intro+md(report)+'<h2>Inside the museum</h2>'+figures))
 route_path=O.parent/'PLAN.md';route=route_path.read_text(encoding='utf8')
 line=next(l for l in route.splitlines() if l.startswith('| Ribbon Patterns 03 |') or l.startswith('| [Ribbon Patterns 03]'))
 route=route.replace(line,'| [Ribbon Patterns 03](Ribbon_Patterns_03/parallel.html) | Write a tiny sampling shader inside the supplied studio. Predict repeat and offset; test three vertical repeats and show what SAVE cannot carry. | Complete ninth revision; printed shader/adapter/scene, GPU sampling checks, independent edit, fault tests and native museum evidence. |')
 start=route.find('Eight Tiling lessons are complete')
 if start<0:start=route.find('All nine Tiling lessons are complete')
 assert start>=0
 route=route[:start]+'''All nine Tiling lessons are complete as revised drafts in this pass: [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html), [Tutorial Pattern](Tutorial_Pattern/index.html), [Array Patterns](Array_Patterns/index.html), [Symmetry Seventeen](Symmetry_Seventeen/index.html), [Pattern Temple](Pattern_Temple/index.html), [Ribbon Patterns 01](Ribbon_Patterns_01/index.html), [Ribbon Patterns 02](Ribbon_Patterns_02/index.html) and [Ribbon Patterns 03](Ribbon_Patterns_03/index.html). Open the [editable project plan](http://localhost:3003/tutorial-plan?map=Ribbon_Patterns_03&view=summaries). Read the complete sequence together before beginning Change Intro. Passing code and museum checks do not replace a reader or physical headset review.
'''
 route_path.write_text(route,encoding='utf8');route_html=page('Tiling / nine-hall route',md(route))
 for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-ribbon03-review.zip']:route_html=route_html.replace('href="'+n+'"','href="Ribbon_Patterns_03/'+n+'"')
 (O.parent/'plan.html').write_text(route_html.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
 write('README.md','''# Ribbon Patterns 03 review

Open index.html or parallel.html. Canonical snapshots: tutorial.md, final.md, technical.md. HTML bundles the reflection image. learner/printed contains the exact three printed files; learner/three_vertical changes one shader literal. Other folders are deliberate faulty programs or the explicitly unclaimed renderer variant. This scene depends on the existing Ada museum studio, Recipe and wardrobe code; it is not a standalone Godot project.

Run: python tools/test_tiling_ribbon03.py
Native: python tools/run_encounter_probe.py Ribbon_Patterns_03 --sequence tiling --render --no-bridges --probe tools/probes/tiling_ribbon03_room.gd --output-tag source-to-skirt --spec doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_03/spec-student.json

Native validation temporarily replaces only the studio runtime instance with the printed scene, preserving its transform. Saves go to the isolated run folder, never the player's ordinary recipe or appearance paths. The original museum camera drives wardrobe selection and runway activation. No production code or map change. Rendering is OpenGL Compatibility; headset, Quest and other backends untested. Reproduce scripts retain repository-relative assumptions.
''')
 dest=O/'reproduce';dest.mkdir(exist_ok=True)
 for n in ['tools/revise_tiling_ribbon03.py','tools/test_tiling_ribbon03.py','tools/publish_tiling_ribbon03.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_ribbon03_student.gd','tools/probes/tiling_ribbon03_room.gd','tools/probes/transformation_encounters.gd','tools/run_encounter_probe.py']:shutil.copy2(R/n,dest/Path(n).name)
 # Include the declared supplied host for review, preserving its source path.
 for p in sources:
  if p.suffix in ['.gd','.gdshader']:
   dst=O/'supplied'/p.relative_to(R);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)
 with zipfile.ZipFile(O/'tiling-ribbon03-review.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in O.rglob('*'):
   if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(O).parts:z.write(p,'Ribbon_Patterns_03/'+p.relative_to(O).as_posix())
  for n in ['PLAN.md','plan.html']:z.write(O.parent/n,n)
 print('Published',O/'index.html')
if __name__=='__main__':main()
