"""Publish a compact reading and pinned complete files after successful reconstruction."""
import difflib
import html
import json
import re
import zipfile
from urllib.parse import urljoin
import markdown
from prepare import HERE, ROOT, HALLS, put, sha
from verify import apply

CSS = '''
:root{--paper:#f4f0e8;--ink:#272621;--accent:#7a3e58;--line:#d2cbbb}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.7 system-ui,sans-serif}a{color:var(--accent);text-underline-offset:3px}header{padding:18px 4vw;border-bottom:1px solid var(--line);display:flex;gap:25px;flex-wrap:wrap;align-items:center}header b{font-size:12px;letter-spacing:.17em;margin-right:auto}main{max-width:1480px;margin:auto;padding:42px 4vw}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.2}h1{font-size:clamp(36px,4vw,62px);max-width:900px}h2{font-size:30px;margin-top:36px}h3{font-size:23px}p,li{max-width:880px}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.15em;text-transform:uppercase;color:var(--accent)}.intro{font-size:20px;max-width:830px}.proof{display:flex;flex-wrap:wrap;gap:10px;margin:24px 0}.proof span{padding:7px 12px;background:#e3e8dc;font-size:14px;border-radius:4px}.route{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin:34px 0}.route article{border:1px solid var(--line);padding:22px;background:#faf8f3}.route h2{margin:8px 0 16px;font-size:26px}.route p{font-size:16px}.spread{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:56px;margin-top:35px}.spread>section{min-width:0}.spread>section+section{border-left:1px solid var(--line);padding-left:36px}.spread h1{font-size:35px}.spread h2{font-size:27px}.spread p,.spread li{font-size:16px}.spread pre{font-size:12px}.reflection p{font-family:Georgia,serif;font-size:19px;line-height:1.8}pre{background:#e9e4d9;padding:18px;overflow:auto;border-left:3px solid #a27e8d;font:14px/1.7 Consolas,monospace;tab-size:4}code{font-family:Consolas,monospace;font-size:.9em}pre code{font:inherit}.location{font-size:12px!important;color:#66665d;border-bottom:1px solid var(--line);padding-bottom:5px}img{width:100%;display:block}figure{margin:0}figcaption{font-size:12px;padding:8px 0;color:#69665e}table{border-collapse:collapse;width:100%;margin:25px 0;font-size:15px}th,td{text-align:left;padding:14px;border-bottom:1px solid var(--line);vertical-align:top}.line{display:block;scroll-margin-top:25px}.line:target{background:#f7d69c}.ln{display:inline-block;width:3em;color:#776c65;text-decoration:none;user-select:none}details{margin:24px 0}summary{cursor:pointer}nav.bottom{margin-top:50px;border-top:1px solid var(--line);padding:20px 0;display:flex;justify-content:space-between;gap:30px}.read{max-width:850px}.note{border-left:3px solid var(--accent);padding-left:18px}.full-program{display:none}
@media(max-width:1000px){.spread,.route{display:block}.route article{margin-bottom:16px}.spread>section+section{border-left:0;padding-left:0;border-top:1px solid var(--line);margin-top:35px;padding-top:25px}.spread pre{font-size:13px}}@media print{header,nav,details,.location,.proof{display:none}body{background:white;font-size:10pt}main{padding:0}.spread{gap:24px}.spread>section+section{padding-left:20px}.spread p,.spread li{font-size:10pt}.spread .reflection p{font-size:11pt}pre,.spread pre{white-space:pre-wrap;overflow:visible;font-size:8pt;break-inside:avoid}.route article{break-inside:avoid}a{color:inherit}h1{font-size:25pt}}
'''

def page(title, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / LEARNING TO CONTINUE</b><a href="index.html">Handoff</a><a href="Trans_Pre.html#reading">Pre</a><a href="Trans_Introduction.html#reading">Introduction</a><a href="files.html">Full files</a><a href="transformation-handoff.zip">Download</a></header><main>{body}</main></body></html>'

def render(text, hall, steps=None):
    text = re.sub(r'<details class="full-program">.*?</details>', '', text, flags=re.S)
    def link(m):
        target = m[2]
        if not target.startswith(('http:', 'https:', '#')):
            target = urljoin('/book-review/commons/maps/' + hall + '/tutorial.md', target)
        return '[' + m[1] + '](' + target + ')'
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, text)
    text = text.replace('/book-images/', '/book-review/doc/book/')
    for step in steps or []:
        id = step['id']
        line = step['incoming_line']
        location = f'<p class="location">{html.escape(step["file"])} · ' + (f'<a href="files.html#edit-{id}-L{line}">before this edit: line {line}</a>' if line else 'new code') + ' · locate by the named function or statement</p>\n\n'
        text = text.replace('<!-- student-edit:' + id + ' -->', location + '<!-- student-edit:' + id + ' -->')
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])

def listing(id, title, source, link=None):
    lines = ''.join(f'<span class="line" id="{id}-L{i}"><a class="ln" href="#{id}-L{i}">{i}</a>{html.escape(line)}</span>' for i,line in enumerate(source.splitlines(), 1))
    return f'<section id="{id}"><h2>{html.escape(title)}</h2>' + (f'<p><a href="{link}" download>Download this file</a></p>' if link else '<p>Incoming file immediately before this edit. Line numbers apply to this pinned state.</p>') + '<pre><code>' + lines + '</code></pre></section>'

def main():
    evidence = json.loads((HERE / 'verification.json').read_text(encoding='utf-8'))
    assert evidence['passed']
    for path,digest in evidence['inputs'].items():
        assert sha(ROOT / path) == digest, path
    steps = evidence['assembly']['edits']
    rows = [
        ('Primitives / Melencolia', 'Two CubeBody instances and a pickable PointBody; an arrangement built in _ready().', 'Save it. Explicitly switch from the bottom-origin face-list cube to a centred BoxMesh visual.', 'A familiar shape, class construction, local placement and the existing host.'),
        ('Trans_Pre', 'The saved arrangement script and Point Zero’s clock.', 'Create BoxBody once. Add timed position, rotation and uniform scale, then a collection area.', 'box_body.gd, elapsed seconds and a collectible snapshot for Arrays.'),
        ('Trans_Introduction', 'The exact completed Pre files.', 'Keep BoxBody unchanged. Remove collection. Place nine models and separate apply_pose() from time.', 'A reusable visual class, placement function, held pose and interpolation.')
    ]
    cards = ''.join(f'<article><p class="eyebrow">{i:02d} / {r[0]}</p><h2>{["Keep the arrangement", "Give one body a clock", "Compare what it can do"][i-1]}</h2><p>{r[2]}</p><p><b>Carry:</b> {r[3]}</p>' + (f'<a href="{HALLS[i-2]}.html#reading">Read the new pages →</a>' if i>1 else '<a href="files.html#Primitives_Melencolia">See the incoming code →</a>') + '</article>' for i,r in enumerate(rows,1))
    table = '<table><thead><tr><th>Hall</th><th>Bring</th><th>Change</th><th>Carry</th></tr></thead><tbody>' + ''.join('<tr>' + ''.join('<td>' + html.escape(cell) + '</td>' for cell in r) + '</tr>' for r in rows) + '</tbody></table>'
    body = f'''<p class="eyebrow">16 October 2026 · a tested handoff</p><h1>Change the behaviour.<br>Keep the construction.</h1><p class="intro">Primitives → Pre → Introduction. The book prints the edits. The encyclopedia keeps every complete file. A reconstruction test connects the two.</p><div class="proof"><span>{evidence['assertions']} native assertions passed</span><span>8 exercise variants</span><span>4 broken behaviours detected</span><span>16 bad edit anchors rejected</span></div><div class="route">{cards}</div><h2>What now carries across</h2>{table}<h2>Short instructions, complete context</h2><div class="note"><p><b>Open lesson.gd. In _process(delta), keep elapsed += delta. Replace the lines beneath it with:</b></p><pre><code>    if animate:
        pose = pingpong(2.0 * elapsed / period, 1.0)
    apply_pose(pose)</code></pre><p>The file and named statement locate the change. A line link opens the exact incoming version. The complete resulting file is one click away.</p></div><h2>What the test proves</h2><p>Starting from Melencolia’s actual script, the test extracts eleven printed edits from the current tutorial.md files. It assembles the movement checkpoint, the complete pickup and the three-model comparison. Each result must exactly match its full downloadable file. The native tests execute those assembled files and the real prior arrangement, using the project’s XR Tools.</p><p>Checks cover independent meshes, the changed local origin, timing at 30 and 120 updates per second, held poses, the moved bank and actual physics overlap with synthetic museum-player bodies. Missing and ambiguous edit anchors are rejected; broken behaviours must fail their intended check.</p><p>These checks do not establish human learning or headset behaviour. Museum code and final.md are preserved. The next unresolved handoff is Introduction → Translation.</p><p><a href="verification.json">Test receipt</a> · <a href="normal-report.json">Every assertion</a> · <a href="assembly-report.json">Every edit</a> · <a href="README.md">Change report</a></p>'''
    put(HERE / 'index.html', page('Primitives into Transformation', body))
    for i,hall in enumerate(HALLS):
        tutorial = (ROOT / 'commons/maps' / hall / 'tutorial.md').read_text(encoding='utf-8')
        final = (ROOT / 'commons/maps' / hall / 'final.md').read_text(encoding='utf-8')
        put(HERE / hall / 'final.md', final)
        image = '/book-review/doc/book/iterations/2026-10-04-museum-tutorial-storyboards/images/' + hall + '-1.webp'
        nav = '<nav class="bottom"><a href="index.html">← Handoff overview</a>' + ('<a href="Trans_Introduction.html#reading">Next: Introduction →</a>' if i==0 else '<a href="files.html#Trans_Introduction">Complete resulting files →</a>') + '</nav>'
        relevant = [s for s in steps if (s['stage']=='comparison') == (hall=='Trans_Introduction')]
        body = f'<p class="eyebrow">{hall} / tutorial on the left · reflection on the right</p><h1>{["A familiar shape gains behaviour", "The same construction, another purpose"][i]}</h1><details><summary>Inside this museum hall</summary><figure><img src="{image}" alt="Archived interior of {hall}"><figcaption>Museum capture from 4 October 2026. Context for the encounter; not a new installation or test screenshot.</figcaption></figure></details><div class="spread" id="reading"><section><p class="eyebrow">Make / current tutorial.md</p>{render(tutorial,hall,relevant)}</section><section class="reflection"><p class="eyebrow">Reflect / unchanged final.md</p>{render(final,hall)}</section></div>{nav}'
        put(HERE / (hall + '.html'), page(hall + ' — facing pages', body))
        put(HERE / hall / 'study.tscn', '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="lesson.gd" id="Lesson"]\n\n[node name="TransformStudy" type="Node3D"]\nscript = ExtResource("Lesson")\n')
        diff = ''.join(difflib.unified_diff((HERE / 'before' / hall / 'tutorial.md').read_text(encoding='utf-8').splitlines(True),tutorial.splitlines(True),fromfile='Before/'+hall,tofile='After/'+hall))
        put(HERE / hall / 'tutorial.diff',diff)

    listings = '<p class="eyebrow">Pinned files / edition 2026-10-16</p><h1>Every complete state</h1><p>The listings are complete. Each lesson folder can be copied into the prepared museum project. Instantiate study.tscn in the hall, or attach lesson.gd to its empty TransformStudy host. The museum supplies the environment and player. These files do not include another world or XR installation.</p>'
    for state in ['Primitives_Melencolia', *HALLS]:
        listings += '<article id="' + state + '"><h2>' + state + '</h2>'
        for name in ['lesson.gd', 'box_body.gd'] if state in HALLS else ['lesson.gd','cube_body.gd','point_body.gd','face_body.gd','line_skin.gd']:
            listings += listing(state + '-' + name.replace('.', '-'), name, (HERE / state / name).read_text(encoding='utf-8'), state + '/' + name)
        listings += '</article>'
    operations=json.loads((HERE / 'edits.json').read_text())['operations']
    files={'lesson.gd':(HERE / 'Primitives_Melencolia/lesson.gd').read_text(encoding='utf-8')}
    listings += '<h1>Before each edit</h1><p>These intermediate snapshots locate edits. An unfinished step may refer to a function introduced in the following step; run at the named movement and complete-lesson checkpoints.</p>'
    for op in operations:
        source = files.get(op['file'],'')
        if source:
            listings += listing('edit-' + op['id'], op['id'] + ' / ' + op['file'], source)
        hall = 'Trans_Introduction' if op['stage']=='comparison' else 'Trans_Pre'
        text=(ROOT / 'commons/maps' / hall / 'tutorial.md').read_text(encoding='utf-8')
        new=re.findall(r'<!-- student-edit:'+re.escape(op['marker'])+r' -->\s*(?:<!-- student-code:[^>]+ -->\s*)?```gdscript\n(.*?)^```',text,re.M|re.S)[0]
        apply(files,op,new)
    put(HERE / 'files.html',page('Complete files and edit locations',listings))
    report='''# Primitives → Pre → Introduction

16 October 2026. This edition updates tutorial.md in Trans_Pre and Trans_Introduction and corrects the forward promises in Cube and Melencolia. The earlier arrangements remain saved. No museum runtime or final.md edits.

- Primitives: the face-list CubeBody remains available. The next branch deliberately uses a centred BoxMesh rather than silently promising the identical class.
- Pre: BoxBody is a six-line visual class. A copy of Melencolia’s host becomes the moving cube; collection follows as a separate tested checkpoint.
- Introduction: carries box_body.gd byte-for-byte. Exact edits add independent models, a placement function and apply_pose; collection is removed. Period means a complete return cycle in both lessons.
- Book: prints complete new functions or exact changed lines. File + function/unique statement are authoritative; line numbers link to a pinned incoming state. Full programs remain online, outside the print reading.

Run `python doc/book/iterations/2026-10-16-transformation-handoff/verify.py` from the AdaResearch repository. The test reads the current canonical printed edits, rejects missing/ambiguous anchors, compares assembled outputs to full files, then runs those outputs in native Godot. prepare.py is an editorial one-shot, not a build command.

Evidence: 68 native assertions; eight variants; four deliberately broken behaviours detected; sixteen bad anchors rejected. Real XR Tools used for the prior arrangement. Synthetic player bodies used for pickup tests. No headset or human-learning result is claimed.

## Download

Copy a lesson folder into the existing prepared Endless Museum project. Use its study.tscn as a child of the hall, at floor level with unit scale and zero rotation. Or attach lesson.gd to the existing empty study host. Keep the named helper beside it. The studies use the museum’s supplied camera, light and player; the ZIP is not a separate XR installation.

## Next pass

Introduction → Translation remains open. Reuse this edition’s BoxBody and placement function; print the route values and changed update only; reconstruct the next state from these exact files. Keep the saved Pre collectible for the later Arrays branch. Do not change the museum runtime or final.md to make tutorial tests pass.
'''
    put(HERE / 'README.md',report)
    with zipfile.ZipFile(HERE / 'transformation-handoff.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['README.md','verification.json','normal-report.json','assembly-report.json','edits.json']:
            z.write(HERE / name,name)
        for state in ['Primitives_Melencolia', *HALLS]:
            for p in (HERE / state).iterdir():
                if p.suffix in ['.gd','.tscn','.md']:
                    z.write(p,p.relative_to(HERE).as_posix())
    print('Published compact facing pages, numbered complete files, incoming edit snapshots and study ZIP.')

if __name__ == '__main__':
    main()
