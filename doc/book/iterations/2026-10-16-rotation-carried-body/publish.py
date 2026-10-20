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
PREVIOUS='../2026-10-16-translation-carried-body/index.html#reading'

def page(title, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / ROTATION</b><a href="{PREVIOUS}">← Translation</a><a href="index.html#reading">Read the lesson</a><a href="files.html">Full files</a><a href="rotation-studies.zip">Download</a></header><main>{body}</main></body></html>'

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
    before=(HERE/'before/commons/maps/Trans_Rotation/tutorial.md').read_text(encoding='utf-8')
    put(HERE/'tutorial.diff',''.join(difflib.unified_diff(before.splitlines(True),tutorial.splitlines(True),fromfile='Before/Trans_Rotation/tutorial.md',tofile='After/Trans_Rotation/tutorial.md')))
    image='/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/Trans_Rotation-1.webp'
    assert (ROOT/image.removeprefix('/book-review/')).exists()
    new_lines=sum(len(re.findall(r'<!-- student-edit:'+op['id']+r' -->\s*```gdscript\n(.*?)^```',tutorial,re.M|re.S)[0].splitlines()) for op in receipt['assembly']['edits'])
    body=f'''<p class="eyebrow">16 October 2026 / Translation → Rotation</p><h1>The body continues.<br>Its frame begins to turn.</h1><p class="intro">Keep the body, the placement function and the clock. Change their relation: a pivot holds the turn; a child inherits it.</p><div class="proof"><span>{new_lines} printed code lines</span><span>4 exact edits</span><span>{receipt['native_assertions']} native assertions passed</span><span>5 deliberate faults detected</span></div><div class="inherit"><p><b>Unchanged:</b> box_body.gd · box(size, at) · _process(delta) · the travel reference · the body's dimensions.</p><p><b>New:</b> pivot · reparenting with local coordinates · angle from elapsed time · attached face mark.</p><p><a href="#reading">Read the facing pages ↓</a> · <a href="files.html#complete">Complete result</a> · <a href="verification.json">Test receipt</a> · <a href="tutorial.diff">Before / after text</a></p></div><details><summary>Should the book show the whole program?</summary><p>A first construction needs a complete small example. A continuing lesson can show the exact changes, with the file and function named and the effect explained. Here the four edits are applied to the tested Translation files; the resulting program is then run in Godot. This checks that the shorter reading has not hidden a necessary step.</p><p>Keep full listings at useful checkpoints or in an appendix. The complete, dated files and exercise variants are downloadable for offline use in the prepared museum project. A reader should be able to recover their place without rebuilding every earlier lesson. Line numbers link to this edition; named functions remain the durable directions.</p></details><details><summary>Inside the Rotation hall</summary><figure><img src="{image}" alt="Archived interior of the Rotation hall"><figcaption>Museum capture from 4 October 2026, locating the encounter. This pass changes the tutorial, not the installation.</figcaption></figure></details><div class="spread" id="reading"><section><p class="eyebrow">Left page / tutorial — the new code</p>{render(tutorial,receipt['assembly']['edits'])}</section><section class="reflection"><p class="eyebrow">Right page / unchanged final.md</p>{render(reflection)}</section></div><nav class="bottom"><a href="{PREVIOUS}">← Previous lesson: Translation</a><a href="files.html#complete">Keep the completed Rotation files →</a></nav><details><summary>What was tested</summary><p>The checker starts with Translation's exact tested files and applies the four printed edits. It compares both runnable checkpoints with the supplied full files and verifies that BoxBody, box() and _process() are unchanged. It then executes the assembled scenes in native Godot.</p><p>Checks cover spin and orbit at 30 and 120 updates per second, the fixed local offset under a moving parent, face-mark attachment, internal distances, return and continuing beyond one turn. The three exercises and a non-unit axis are tested. Five deliberate behavioural faults and eight missing or ambiguous edit anchors are rejected.</p><p>These are code checks. Physical riding, headset comfort and human learning remain separate observations. Scale is the next handoff to repair.</p><p><a href="normal-report.json">Every runtime assertion</a> · <a href="assembly-report.json">Edit reconstruction</a> · <a href="README.md">Change report</a></p></details>'''
    put(HERE/'index.html',page('Rotation — keep the body, turn its frame',body))
    files='<p class="eyebrow">Full files / edition 2026-10-16</p><h1>From a journey<br>to a turn.</h1><p>Copy a complete lesson folder into the prepared museum project. Open study.tscn or attach lesson.gd to an empty TransformStudy. Keep box_body.gd beside it. The museum supplies the environment and viewer.</p><p><a href="#incoming">Incoming Translation</a> · <a href="#turn">Turning checkpoint</a> · <a href="#complete">Completed Rotation</a> · <a href="#variants">Exercise variants</a></p>'
    for state,title in [('incoming','Translation: the exact incoming files'),('turn','Checkpoint: the body turns about its centre'),('complete','Rotation: the body and its face mark')]:
        files+=f'<article id="{state}"><h2>{title}</h2><p><a href="{state}/study.tscn" download>study.tscn</a></p>'
        for name in ['lesson.gd','box_body.gd']:
            files+=listing(state+'-'+name.replace('.','-'),name,(HERE/state/name).read_text(encoding='utf-8'),state+'/'+name)
        files+='</article>'
    files+='<article id="variants"><h2>Complete variants</h2><p>The orbit, vertical and slow folders follow the three exercises in order. axis_length is an additional normalization check. Raise the study two metres in the museum to see the vertical circle above the floor; the scripts retain the same local coordinates.</p>'
    for variant in ['orbit','vertical','slow','axis_length']:
        files+=f'<p><b>{variant}</b> · <a href="variants/{variant}/lesson.gd">lesson.gd</a> · <a href="variants/{variant}/box_body.gd">box_body.gd</a> · <a href="variants/{variant}/study.tscn">study.tscn</a></p>'
    files+='</article><h1>Before each edit</h1><p>Apply the first three edits before running the turning checkpoint. Then insert the face-mark lines and run again. Each listing below is the exact file before its named edit.</p>'
    for edit in receipt['assembly']['edits']:
        files+=listing('edit-'+edit['id'],edit['id']+' / lesson.gd',(HERE/'steps'/edit['id']/'lesson.gd').read_text(encoding='utf-8'))
    put(HERE/'files.html',page('Rotation — complete files and exact edit locations',files))
    notes=f'''# Rotation — the carried body

16 October 2026. Four printed edits ({new_lines} code lines) continue Translation's tested files. Canonical tutorial.md is updated; final.md, Translation and museum runtime remain unchanged.

Before: a separate complete script reconstructed its own mesh. After: BoxBody, box(), _process(), travel and its dimensions are retained. The new code creates a pivot, reparents the body with its local transform retained, assigns an axis-angle basis, and adds a mark using the same BoxBody constructor.

## Short brief

MAKE: body spins, then orbits when offset; mark stays attached.
BRING: exact Translation complete/lesson.gd and box_body.gd; body, clock, placement function.
GIVEN: existing museum room, light, viewer and empty study host.
BUILD: pivot; local-preserving reparent; degrees to radians; orientation from time; attached mark.
CHECK: local offset fixed; world centre moves; shape preserved; mark returns after full turn; next turn continues.
CARRY: same constructor, clock and placement function; pivot/body/mark hierarchy into Scale.
LATER: composing multiple axes, sweep meshes, rider counter-rotation, physics.

## Evidence

{receipt['native_assertions']} passing assertions in Godot 4.6. Three exercise variants and one additional axis-length case. Five deliberately faulty versions rejected by the ordinary behavioural tests; eight missing/ambiguous edit anchors rejected. Tests execute the mechanically assembled scenes, incoming Translation and both checkpoints. Physical headset use and human learning are not established by these tests.

From repository root, run `python doc/book/iterations/2026-10-16-rotation-carried-body/verify.py`, then `publish.py`. The one-time `prepare.py` is guarded against replay.

## Book and encyclopedia

First constructions get full small examples; continuing lessons get precise new code. Keep full runnable states at checkpoints and in the dated download. The book's lesson remains understandable through its explanation, predictions and named edits; the encyclopedia holds full files and exact incoming line anchors. This local edition does not claim a permanent public print URL.

Next: repair Rotation → Scale using these complete files. The existing Scale tutorial still rebuilds its boxes; do not silently claim that handoff is finished.
'''
    put(HERE/'README.md',notes)
    with zipfile.ZipFile(HERE/'rotation-studies.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['README.md','tutorial.md','edits.json','verification.json','assembly-report.json','normal-report.json']:
            z.write(HERE/name,name)
        for folder in ['incoming','turn','complete','variants']:
            for p in (HERE/folder).rglob('*'):
                if p.is_file() and p.suffix in ['.gd','.tscn']: z.write(p,p.relative_to(HERE).as_posix())
    print('Published facing pages, full files, precise edit locations and ZIP.')

if __name__=='__main__': main()

