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
tree=ast.parse((PRIOR/'publish.py').read_text(encoding='utf-8'))
CSS=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='CSS' for t in n.targets))
CSS+='\n.spread pre{white-space:pre-wrap;overflow-wrap:anywhere}.compact{max-width:900px}.inherit{border:1px solid var(--line);padding:16px 22px;margin:24px 0;background:#faf8f3}.inherit p{margin:5px 0}.line pre{white-space:pre}\n'
PREVIOUS='../2026-10-16-transformation-handoff/Trans_Introduction.html#reading'

def page(title, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / TRANSLATION</b><a href="{PREVIOUS}">← Introduction</a><a href="index.html#reading">Read the lesson</a><a href="files.html">Full files</a><a href="translation-studies.zip">Download</a></header><main>{body}</main></body></html>'

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
    before=(HERE/'before/commons/maps/Trans_Translation/tutorial.md').read_text(encoding='utf-8')
    put(HERE/'tutorial.diff',''.join(difflib.unified_diff(before.splitlines(True),tutorial.splitlines(True),fromfile='Before/Trans_Translation/tutorial.md',tofile='After/Trans_Translation/tutorial.md')))
    image='/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/Trans_Translation-1.webp'
    assert (ROOT/image.removeprefix('/book-review/')).exists()
    new_lines=sum(len(re.findall(r'<!-- student-edit:'+op['id']+r' -->\s*```gdscript\n(.*?)^```',tutorial,re.M|re.S)[0].splitlines()) for op in receipt['assembly']['edits'])
    body=f'''<p class="eyebrow">16 October 2026 / Introduction → Translation</p><h1>The body continues.<br>The journey changes.</h1><p class="intro">Keep the visual class and placement function. Give the travelling body a destination, then choose how it gets there.</p><div class="proof"><span>{new_lines} printed code lines</span><span>5 exact edits</span><span>{receipt['native_assertions']} native assertions passed</span><span>4 deliberate faults detected</span></div><div class="inherit"><p><b>Unchanged:</b> box_body.gd · box(size, at) · the travel reference · elapsed seconds · the bounded apply_pose interface.</p><p><b>New:</b> start and finish · one-way duration · vector interpolation · a condition choosing the two legs.</p><p><a href="#reading">Read the facing pages ↓</a> · <a href="files.html#complete">Complete result</a> · <a href="verification.json">Test receipt</a> · <a href="tutorial.diff">Before / after text</a></p></div><details><summary>Inside the Translation hall</summary><figure><img src="{image}" alt="Archived interior of the Translation hall"><figcaption>Museum capture from 4 October 2026, locating the encounter. No new museum installation is claimed.</figcaption></figure></details><div class="spread" id="reading"><section><p class="eyebrow">Left page / tutorial — the new code</p>{render(tutorial,receipt['assembly']['edits'])}</section><section class="reflection"><p class="eyebrow">Right page / unchanged final.md</p>{render(reflection)}</section></div><nav class="bottom"><a href="{PREVIOUS}">← Previous lesson: Introduction</a><a href="files.html#complete">Keep the completed Translation files →</a></nav><details><summary>What was tested</summary><p>The checker starts with Introduction’s previously tested files and applies the five edits printed in tutorial.md. It verifies both runnable checkpoints, exact agreement with the full files, and the unchanged visual class and placement function. Native Godot runs the supplied scene files, including a real _process callback.</p><p>Checks cover predicted positions at 30 and 120 updates per second, local and world frames, no change to the mesh or orientation, clamped arrival, continuity at the corner and independent instances. Three exercises and one zero-length edge case are tested. Four deliberately broken behaviours and ten bad edit anchors are rejected.</p><p>This is a visual study. Installed rider transport, physical headset use and human learning are separate checks. Rotation is the next continuation to repair.</p><p><a href="normal-report.json">Every runtime check</a> · <a href="assembly-report.json">Edit reconstruction</a> · <a href="README.md">Change report</a></p></details>'''
    put(HERE/'index.html',page('Translation — keep the body, change the journey',body))
    files='<p class="eyebrow">Full files / edition 2026-10-16</p><h1>From the comparison<br>to one journey.</h1><p>Copy the complete lesson folder into the prepared museum project. Use study.tscn or attach lesson.gd to the empty TransformStudy host. Keep box_body.gd beside it. The museum supplies the environment and player.</p><p><a href="#incoming">Incoming Introduction</a> · <a href="#direct">Direct checkpoint</a> · <a href="#complete">Completed Translation</a> · <a href="#variants">Exercise variants</a></p>'
    for state,title in [('incoming','Introduction: the exact incoming files'),('direct','Checkpoint: a direct journey'),('complete','Translation: direct or bent route')]:
        files+=f'<article id="{state}"><h2>{title}</h2><p><a href="{state}/study.tscn" download>study.tscn</a></p>'
        for name in ['lesson.gd','box_body.gd']:
            files+=listing(state+'-'+name.replace('.','-'),name,(HERE/state/name).read_text(encoding='utf-8'),state+'/'+name)
        files+='</article>'
    files+='<article id="variants"><h2>Complete variants</h2><p>These folders contain both files and their study scene. The zero-length route is an additional test case.</p>'
    for variant in ['corner','diagonal','slow','zero']:
        files+=f'<p><b>{variant}</b> · <a href="variants/{variant}/lesson.gd">lesson.gd</a> · <a href="variants/{variant}/box_body.gd">box_body.gd</a> · <a href="variants/{variant}/study.tscn">study.tscn</a></p>'
    files+='</article><h1>Before each edit</h1><p>Run after the direct-route checkpoint, then again after the corner-route edit. Intermediate edits may still refer to names replaced in the following step.</p>'
    for edit in receipt['assembly']['edits']:
        files+=listing('edit-'+edit['id'],edit['id']+' / lesson.gd',(HERE/'steps'/edit['id']/'lesson.gd').read_text(encoding='utf-8'))
    put(HERE/'files.html',page('Translation — complete files and exact edit locations',files))
    notes=f'''# Translation — the carried body

16 October 2026. Canonical tutorial.md now continues the tested Introduction output. final.md, Introduction’s canonical lesson and museum runtime are preserved.

## Before → after

- Reconstructed a new inline MeshInstance/BoxMesh → carries box_body.gd and box(size, at) byte-for-byte.
- Changed the body’s reference name → keeps travel, the reference already used in Introduction.
- Reprinted a complete program as the main reading → five located edits ({new_lines} lines), with complete versioned files online.
- A finished script tested alone → exact incoming state + printed edits produce both the direct checkpoint and the completed lesson, then run in native Godot.
- Hall labels promised waypoint indexing/guards → learning choices now match vector interpolation and a two-branch route. Longer lists remain a later extension.

## Brief for the next writer

MAKE: one level visual follows direct or bent route, then stops.
BRING: Introduction lesson.gd + box_body.gd; preserve box(), travel, clock and bounded pose interface.
GIVEN: existing museum room, viewer and empty study host; installed riding stays supplied.
BUILD: endpoints, duration, one visual, fraction from time, vector interpolation, two-leg condition.
CHECK: midpoint differs; endpoint agrees; mesh/basis unchanged; duration scales both legs; corner has no jump.
CARRY: complete/lesson.gd + unchanged complete/box_body.gd into Rotation.
LATER: rider transport, general waypoint indexing, distance-weighted speed, curved paths.

## Evidence

{receipt['native_assertions']} native assertions; three exercise variants and one zero-length edge case. Four faults detected: frame-based clock, missing clamp, incorrect second fraction, unintended turn. Ten missing/ambiguous edit anchors rejected. Tests run the actual assembled scene files and the incoming Introduction study, with no repair in the harness. No human-learning or headset claim.

Run from repository root: `python doc/book/iterations/2026-10-16-translation-carried-body/verify.py`. Then `publish.py` refreshes this edition only if all pinned inputs match. Do not rerun the one-time prepare.py. The archive supplies lesson folders for the existing museum, not another XR installation.

Next: Translation → Rotation. Keep BoxBody; decide the parent used by the inherited placement function before adding a pivot. Do not silently claim that the current Rotation chapter already uses these files.
'''
    put(HERE/'README.md',notes)
    with zipfile.ZipFile(HERE/'translation-studies.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['README.md','tutorial.md','edits.json','verification.json','assembly-report.json','normal-report.json']:
            z.write(HERE/name,name)
        for folder in ['incoming','direct','complete','variants']:
            for p in (HERE/folder).rglob('*'):
                if p.is_file() and p.suffix in ['.gd','.tscn']: z.write(p,p.relative_to(HERE).as_posix())
    print('Published facing pages, complete files, incoming edit links and ZIP.')

if __name__=='__main__': main()
