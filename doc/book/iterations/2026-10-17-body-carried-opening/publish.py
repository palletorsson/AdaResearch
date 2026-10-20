"""Read the canonical lesson; publish its changed code beside the unchanged reflection."""
import ast
import difflib
import html
import json
import re
import zipfile
from urllib.parse import urljoin
import markdown
from prepare import HERE, ROOT, PRIOR, HALL, CANONICAL, put, sha

# Reuse the established book layout without running its dated publisher.
tree=ast.parse((ROOT/'doc/book/iterations/2026-10-16-transformation-handoff/publish.py').read_text(encoding='utf-8'))
CSS=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='CSS' for t in n.targets))
CSS+='\n.spread pre{white-space:pre-wrap;overflow-wrap:anywhere}.compact{max-width:900px}.inherit{border:1px solid var(--line);padding:16px 22px;margin:24px 0;background:#faf8f3}.inherit p{margin:5px 0}.line pre{white-space:pre}\n'
PREVIOUS='../2026-10-16-scale-carried-frame/index.html#reading'

def page(title, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / BODY</b><a href="{PREVIOUS}">← Scale</a><a href="index.html#reading">Read the lesson</a><a href="files.html">Full files</a><a href="body-studies.zip">Download</a></header><main>{body}</main></body></html>'

def render(text, steps=None):
    text=re.sub(r'<details class="full-program">.*?</details>','',text,flags=re.S)
    def link(m):
        target=m[2]
        if not target.startswith(('http:', 'https:', '#')):
            target=urljoin('/book-review/commons/maps/'+HALL+'/tutorial.md',target)
        return '['+m[1]+']('+target+')'
    text=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',link,text).replace('/book-images/','/book-review/doc/book/')
    for edit in steps or []:
        marker='<!-- student-edit:'+edit['id']+' -->'
        label=f'<p class="location">lesson.gd · <a href="files.html#edit-{edit["id"]}-L{edit["incoming_line"]}">before this edit: line {edit["incoming_line"]}</a> · use the named function or statement</p>\n\n'
        text=text.replace(marker,label+marker)
        removal='<!-- student-remove:'+edit['id']+' -->'
        text=text.replace(removal,label+removal)
    return markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])

def listing(id,title,source,path=None):
    lines=''.join(f'<span class="line" id="{id}-L{i}"><a class="ln" href="#{id}-L{i}">{i}</a>{html.escape(line)}</span>' for i,line in enumerate(source.splitlines(),1))
    return '<section id="'+id+'"><h2>'+html.escape(title)+'</h2>'+(f'<p><a href="{path}" download>Download this file</a></p>' if path else '<p>Incoming file immediately before this edit. These line numbers belong to this exact state.</p>')+'<pre><code>'+lines+'</code></pre></section>'

def main():
    receipt=json.loads((HERE/'verification.json').read_text(encoding='utf-8'))
    assert receipt['passed']
    for path,digest in receipt['inputs'].items(): assert sha(ROOT/path)==digest,path
    tutorial=CANONICAL.read_text(encoding='utf-8')
    reflection=(ROOT/'commons/maps'/HALL/'final.md').read_text(encoding='utf-8')
    before=(HERE/'before/commons/maps/Trans_Body/tutorial.md').read_text(encoding='utf-8')
    put(HERE/'tutorial.diff',''.join(difflib.unified_diff(before.splitlines(True),tutorial.splitlines(True),fromfile='Before/Trans_Body/tutorial.md',tofile='After/Trans_Body/tutorial.md')))
    image='/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/Trans_Body-1.webp'
    assert (ROOT/image.removeprefix('/book-review/')).exists()
    pieces=re.findall(r'<!-- student-edit:[^>]+ -->\s*```gdscript\n(.*?)^```',tutorial,re.M|re.S)
    new_lines=sum(len(p.splitlines()) for p in pieces)
    substantive_lines=sum(len([line for line in p.splitlines() if line.strip()]) for p in pieces)
    body=f'''<p class="eyebrow">17 October 2026 / Scale → Body</p>
<h1>The opening stays.<br>Your approach changes it.</h1>
<p class="intro">Keep the three boxes, their parent and the black sphere. Let the distance from your viewpoint choose the doorway’s size.</p>
<div class="proof"><span>3 insertions</span><span>{substantive_lines} new code lines</span><span>{receipt['native_assertions']} Godot assertions passed</span><span>5 deliberate faults caught</span></div>
<div class="inherit"><p><b>Carried:</b> BoxBody · box() · apply_pose() · the entire doorway and fixed sphere.</p><p><b>New:</b> active viewpoint → horizontal distance → bounded fraction → scale factor.</p><p><a href="#reading">Read the facing pages ↓</a> · <a href="files.html#complete">Full files</a> · <a href="verification.json">Test receipt</a> · <a href="tutorial.diff">Before / after</a></p></div>
<details><summary>Inside the Body hall</summary><figure><img src="{image}" alt="Interior of the Body hall from the existing museum route"><figcaption>Archived museum capture, 4 October 2026. The installed artifacts supply the encounter. This pass changes the tutorial; it does not rebuild the room.</figcaption></figure></details>
<div class="spread" id="reading"><section><p class="eyebrow">Left page / tutorial — new code</p>{render(tutorial,receipt['assembly']['edits'])}</section><section class="reflection"><p class="eyebrow">Right page / unchanged final.md</p>{render(reflection)}</section></div>
<nav class="bottom"><a href="{PREVIOUS}">← Previous lesson: Scale</a><a href="files.html#complete">Keep the complete Body files →</a></nav>
<details><summary>What changed and what passed</summary><p>The previous tutorial discarded the doorway and rebuilt a cube. This continuation inserts declarations, two range assertions and two functions into the exact tested Scale script. All previous lines remain. The active camera is an explicit supplied reference; no hidden scene path or extra player is required.</p><p>The checker applies the printed fragments mechanically and compares the result with the published files before running it. It also runs the incoming Scale scene. Native checks measure the opening, unchanged sphere, stored geometry, floor contact and repeated responses.</p><p>Tests use actual Camera3D and XRCamera3D nodes, translated and yawed parents, live frames, missing and replaced cameras. XR tracking is disabled; positions are supplied by the test. This establishes the camera connection under these conditions, not physical headset behaviour.</p><p>Three exercises run from their exact edits: extend reach, change width only, reverse the response. Five faults mix local and world coordinates, retain height in the distance, remove the far clamp, accumulate scale, or scale the wrong object. Ordinary checks reject all five. Six missing or ambiguous insertion anchors are rejected.</p><p>There is no lesson collision or claim that a human has understood the text. Spectator camera mode would change the input. The installed exhibits’ multiple visitors, collision, smoothing and retained cuts remain outside this small study.</p><p><a href="normal-report.json">Every assertion</a> · <a href="assembly-report.json">Reconstruction</a> · <a href="README.md">Change report</a></p></details>'''
    put(HERE/'index.html',page('Body — let approach choose the size',body))
    files='''<p class="eyebrow">Complete files / edition 2026-10-17</p><h1>Keep the frame.<br>Add a relation.</h1><p>Copy a complete folder into the prepared Endless Museum project. Instance study.tscn in the same viewport as the walking or XR camera, on a clear floor with unit scale and no tilt. Keep box_body.gd beside lesson.gd. The scene contains the study only; the museum supplies its viewer and environment.</p><p><a href="#incoming">Incoming Scale</a> · <a href="#complete">Completed Body</a> · <a href="#variants">Exercise variants</a> · <a href="body-studies.zip">Download all</a></p>'''
    for state,title in [('incoming','Scale: the exact starting files'),('complete','Body: the same frame, driven by approach')]:
        files+=f'<article id="{state}"><h2>{title}</h2><p><a href="{state}/study.tscn" download>study.tscn</a></p>'
        for name in ['lesson.gd','box_body.gd']:
            files+=listing(state+'-'+name.replace('.','-'),name,(HERE/state/name).read_text(encoding='utf-8'),state+'/'+name)
        files+='</article>'
    files+='<article id="variants"><h2>Complete exercise variants</h2><p>Each folder is a separate exercise from the completed base. reach moves the far limit to six metres; width changes only X; reverse reverses the interpolation endpoints. Every folder includes the unchanged constructor and scene.</p>'
    for variant in ['reach','width','reverse']:
        files+=f'<p><b>{variant}</b> · <a href="variants/{variant}/lesson.gd">lesson.gd</a> · <a href="variants/{variant}/box_body.gd">box_body.gd</a> · <a href="variants/{variant}/study.tscn">study.tscn</a></p>'
    files+='</article><h1>Before each insertion</h1><p>Apply all three insertions before running. Line numbers belong to this edition; the named declaration or function is the durable location.</p>'
    for edit in receipt['assembly']['edits']:
        files+=listing('edit-'+edit['id'],edit['id']+' / lesson.gd',(HERE/'steps'/edit['id']/'lesson.gd').read_text(encoding='utf-8'))
    put(HERE/'files.html',page('Body — full files and exact edit locations',files))
    notes=f'''# Body — the carried opening

17 October 2026. Canonical Trans_Body/tutorial.md now continues the tested Scale edition. Three insertions, {substantive_lines} nonblank new code lines ({new_lines} including spacing). BoxBody, box(), apply_pose(), the complete doorway construction and sphere remain. Only two assertions enter the previous _ready body. Reflection and museum runtime remain unchanged.

## Short brief

MAKE: existing opening grows with approach, returns on retreat.
BRING: exact Scale output; BoxBody, parent/children, apply_pose(Vector3), fixed sphere.
GIVEN: Endless Museum; active walking/XR camera in same viewport; floor-level unscaled host, no tilt.
ADD: camera reference each frame; world separation projected onto XZ; bounded range; interpolated uniform factor.
CHECK: far4 → factor1; near1 → factor4; midpoint2.5 → factor2.5; height/direction irrelevant; fixed witness; no accumulation.
CARRY: unchanged frame + distance-to-factor response into Trans_Pit.
LATER: body collider, multiple visitors, smoothing, timed progress, permanent cuts.

## Before / after

Before: standalone cube rebuilt mesh construction, looked up groups that do not cover every XR rig, removed the frame and sphere. After: all Scale code retained; active camera deliberately provides viewpoint input. Camera origin and collision body are explicitly different. The frame grows on approach; the hall's separate block field shrinks parts to make space between them. These operations share the input relation, not the same geometry.

## Evidence

{receipt['native_assertions']} Godot 4.6 native assertions pass. Three exercise variants, five detected behavioural faults and six bad insertion anchors. The tests run the assembled printed edits, the actual preceding Scale scene, live frames, actual desktop and XR camera classes with test positions, different parent frames, no camera, late camera and freed/replaced camera. Native scene execution is not evidence of human learning, physical XR tracking or collision safety.

Run `python doc/book/iterations/2026-10-17-body-carried-opening/verify.py`, then `publish.py`. Do not rerun guarded prepare.py. These are files for the prepared museum project, not a replacement environment.

## Source context

- commons/scenes/endless_museum.gd: walking Camera3D is made current; VR has an XRCamera3D.
- commons/artifacts/approach_scale/approach_scale.gd: installed artifact explicitly distinguishes em_walker/player_body visitors from XR descendants; it measures horizontal distance and updates collision too.
- Godot 4.6 Viewport.get_camera_3d: active camera in this viewport, or null.

Next repair: Body → Trans_Pit. Continue these files; declare the change from a visual frame to a solid, combined and timed opening. Do not silently rebuild BoxBody or certify the untouched Pit lesson.
'''
    put(HERE/'README.md',notes)
    with zipfile.ZipFile(HERE/'body-studies.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['README.md','tutorial.md','edits.json','verification.json','assembly-report.json','normal-report.json']:
            z.write(HERE/name,name)
        for folder in ['incoming','complete','variants']:
            for p in (HERE/folder).rglob('*'):
                if p.is_file() and p.suffix in ['.gd','.tscn']: z.write(p,p.relative_to(HERE).as_posix())
    print('Published Body facing pages, full files and ZIP:',substantive_lines,'new code lines.')

if __name__=='__main__': main()

