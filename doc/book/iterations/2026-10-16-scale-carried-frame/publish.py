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
PREVIOUS='../2026-10-16-rotation-carried-body/index.html#reading'

def page(title, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / SCALE</b><a href="{PREVIOUS}">← Rotation</a><a href="index.html#reading">Read the lesson</a><a href="files.html">Full files</a><a href="scale-studies.zip">Download</a></header><main>{body}</main></body></html>'

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
    before=(HERE/'before/commons/maps/Trans_Scale/tutorial.md').read_text(encoding='utf-8')
    put(HERE/'tutorial.diff',''.join(difflib.unified_diff(before.splitlines(True),tutorial.splitlines(True),fromfile='Before/Trans_Scale/tutorial.md',tofile='After/Trans_Scale/tutorial.md')))
    image='/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/Trans_Scale-1.webp'
    assert (ROOT/image.removeprefix('/book-review/')).exists()
    new_lines=sum(len(piece.splitlines()) for piece in re.findall(r'<!-- student-edit:[^>]+ -->\s*```gdscript\n(.*?)^```',tutorial,re.M|re.S))
    body=f'''<p class="eyebrow">16 October 2026 / Rotation → Scale</p><h1>The frame remains.<br>The opening grows.</h1><p class="intro">Three familiar boxes belong to one parent. A sphere stands beside it. Enlarge the parent and see what changes together.</p><div class="proof"><span>{new_lines} printed code lines</span><span>5 edits, including 2 removals</span><span>{receipt['native_assertions']} native assertions passed</span><span>4 deliberate faults detected</span></div><div class="inherit"><p><b>Carried:</b> box_body.gd · box(size, at) · the pivot declaration · local-preserving reparenting.</p><p><b>Changed:</b> a fixed threshold origin · three doorway parts · a sphere outside the group · scale factors instead of a timed angle.</p><p><a href="#reading">Read the facing pages ↓</a> · <a href="files.html#complete">Complete result</a> · <a href="verification.json">Test receipt</a> · <a href="tutorial.diff">Before / after text</a></p></div><details><summary>Inside the Scale hall</summary><figure><img src="{image}" alt="Archived interior of the Scale hall"><figcaption>Museum capture from 4 October 2026. The installed room provides the encounter; this pass changes the tutorial.</figcaption></figure></details><div class="spread" id="reading"><section><p class="eyebrow">Left page / tutorial — the changes</p>{render(tutorial,receipt['assembly']['edits'])}</section><section class="reflection"><p class="eyebrow">Right page / unchanged final.md</p>{render(reflection)}</section></div><nav class="bottom"><a href="{PREVIOUS}">← Previous lesson: Rotation</a><a href="files.html#complete">Keep the completed Scale files →</a></nav><details><summary>What was tested</summary><p>The checker applies the five printed instructions to Rotation's exact tested output, including the two deletions. The reconstructed result must match the full file and run as a scene in Godot. BoxBody, box() and the pivot declaration are checked for continuity.</p><p>The tests measure the actual transformed doorway surfaces: clear width and height, part dimensions, spacing, floor contact and the fixed sphere. They also check that stored mesh sizes and child positions remain unchanged, repeated assignment does not accumulate scale, and the scene remains still across real frames.</p><p>The three exercises and an additional depth-only case run from their own complete files. Four faults are deliberately introduced: scaling only the parts, including the sphere in the group, raising the origin, and multiplying instead of assigning the scale. All are rejected by the ordinary checks. Ten missing or ambiguous edit anchors are rejected.</p><p>The sphere's nominal radius and height are checked separately from the extents of its tessellated mesh. These are geometry and code checks; they do not establish collision, headset comfort or learner understanding.</p><p><a href="normal-report.json">Every runtime assertion</a> · <a href="assembly-report.json">Edit reconstruction</a> · <a href="README.md">Change report</a></p></details>'''
    put(HERE/'index.html',page('Scale — keep the frame, enlarge the opening',body))
    files='<p class="eyebrow">Full files / edition 2026-10-16</p><h1>From a turning body<br>to a changing opening.</h1><p>Copy the complete lesson folder into the prepared museum project. Open study.tscn or attach lesson.gd to an empty floor-level TransformStudy. Keep box_body.gd beside it. The museum supplies the environment and viewer.</p><p><a href="#incoming">Incoming Rotation</a> · <a href="#complete">Completed Scale</a> · <a href="#variants">Exercise variants</a></p>'
    for state,title in [('incoming','Rotation: the exact incoming files'),('complete','Scale: the doorway and fixed sphere')]:
        files+=f'<article id="{state}"><h2>{title}</h2><p><a href="{state}/study.tscn" download>study.tscn</a></p>'
        for name in ['lesson.gd','box_body.gd']:
            files+=listing(state+'-'+name.replace('.','-'),name,(HERE/state/name).read_text(encoding='utf-8'),state+'/'+name)
        files+='</article>'
    files+='<article id="variants"><h2>Complete variants</h2><p>uniform, width and xy are the three exercises. depth is an additional depth-only test case. Every folder includes the full script, unchanged class and study scene.</p>'
    for variant in ['uniform','width','xy','depth']:
        files+=f'<p><b>{variant}</b> · <a href="variants/{variant}/lesson.gd">lesson.gd</a> · <a href="variants/{variant}/box_body.gd">box_body.gd</a> · <a href="variants/{variant}/study.tscn">study.tscn</a></p>'
    files+='</article><h1>Before each edit</h1><p>Apply all five edits before running. These listings show the exact incoming file at each step, including the two deletions. Line numbers belong to this dated edition; follow the named declaration or function.</p>'
    for edit in receipt['assembly']['edits']:
        files+=listing('edit-'+edit['id'],edit['id']+' / lesson.gd',(HERE/'steps'/edit['id']/'lesson.gd').read_text(encoding='utf-8'))
    put(HERE/'files.html',page('Scale — complete files and exact edit locations',files))
    notes=f'''# Scale — the carried frame

16 October 2026. Canonical tutorial.md continues Rotation's tested files with five instructions: three replacement fragments ({new_lines} printed code lines) and two explicit deletions. final.md, Rotation's source and museum runtime remain unchanged.

Before: standalone program rebuilt BoxMesh construction. After: unchanged BoxBody and box() construct the doorway. Rotation's pivot declaration and local-preserving reparenting continue; the parent is fixed at the threshold. The clock and travel reference are removed. The new sphere construction is printed because the incoming file does not contain it. apply_pose now explicitly accepts Vector3 scale factors instead of a float time fraction.

## Short brief

MAKE: enlarge a three-box opening; keep a sphere outside the change.
BRING: exact Rotation scripts; BoxBody, box(), pivot and local-preserving reparenting.
GIVEN: museum room, light, viewer and empty floor-level study host.
BUILD: doorway children; fixed sphere sibling; Vector3 factors; scale assigned to parent.
CHECK: 0.45 × 0.60 → 1.80 × 2.40; width-only stays too short; local data and sphere unchanged; posts on floor.
CARRY: constructor, placement, grouped transform and independent reference into Trans_Body.
LATER: player-distance input, collision, room relocation and negative/zero scale.

## Evidence

{receipt['native_assertions']} passing assertions in Godot 4.6. Three exercise variants and one depth-only case. Four behavioural faults and ten missing/ambiguous edit anchors rejected. Tests use the assembled scene, not a repaired solution. The nominal sphere diameter and its discretized visible bounds are checked separately. Headset comfort and human learning are untested.

Run `python doc/book/iterations/2026-10-16-scale-carried-frame/verify.py` from the repository root, followed by `publish.py`. Do not rerun the guarded one-time prepare.py. The downloadable files run inside the prepared museum project; they do not supply another XR environment.

Next: repair Scale → Trans_Body against this edition. Keep BoxBody and declare how an existing visitor supplies the input. The current Trans_Body manuscript still reconstructs its mesh inline; this next handoff is not yet repaired.
'''
    put(HERE/'README.md',notes)
    with zipfile.ZipFile(HERE/'scale-studies.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['README.md','tutorial.md','edits.json','verification.json','assembly-report.json','normal-report.json']:
            z.write(HERE/name,name)
        for folder in ['incoming','complete','variants']:
            for p in (HERE/folder).rglob('*'):
                if p.is_file() and p.suffix in ['.gd','.tscn']: z.write(p,p.relative_to(HERE).as_posix())
    print('Published Scale facing pages, full files, edit locations and ZIP.')

if __name__=='__main__': main()

