"""Freeze this pass and render its local research blog; never runs the museum."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
def read(p): return p.read_text(encoding='utf-8')
def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8', newline='\n')
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def md(s): return markdown.markdown(s, extensions=['footnotes', 'fenced_code', 'tables'])

# Update one room's current encounter record, preserving every other entry.
index = ROOT / 'commons/data/museum_core_encounters.json'
saved = OUT / 'before/commons/data/museum_core_encounters.json'
if not saved.exists():
    saved.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(index, saved)
data = json.loads(read(index))
entry = data['rooms']['Point_Triangle_Context']
entry.update(reason='Close a boundary, add a face, then distinguish viewpoint, corner position and fill visibility through one shared drawing at two scales. Keep the fan overspill as a further investigation.',
    text_sha256=digest(ROOT/'commons/maps/Point_Triangle_Context/final.md'),
    map_sha256=digest(ROOT/'commons/maps/Point_Triangle_Context/map_data.json'),
    learner_verified=False,
    local_review='http://localhost:3003/book-review/doc/book/iterations/2026-10-01-lines-triangle-research/index.html')
write(index,json.dumps(data,ensure_ascii=False,indent=2)+'\n')

baseline=json.loads(read(OUT/'baseline.json'))
files=list(baseline['files'])+['commons/data/museum_core_encounters.json']
changes=[]
for rel in files:
    src=ROOT/rel
    dst=OUT/'after'/rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src,dst)
    before=OUT/'before'/rel
    if before.read_bytes()!=src.read_bytes():
        diff=''.join(difflib.unified_diff(read(before).splitlines(True),read(src).splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
        name=rel.replace('/','__')+'.diff'
        write(OUT/'diffs'/name,diff)
        changes.append((rel,name))
write(OUT/'after.json',json.dumps({'baseline_commit':baseline['commit'],'scope':'Working-copy sources; not a standalone museum export','files':{r:digest(ROOT/r) for r in files}},indent=2)+'\n')

CSS='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f1e9;color:#202622;font:18px/1.7 Georgia,serif}a{color:#365d51;text-underline-offset:4px}nav{font:14px/1.6 system-ui;background:#e6e5db;padding:18px 5vw;display:flex;gap:24px;flex-wrap:wrap}header{padding:70px 7vw 36px;max-width:1250px;margin:auto}h1{font-weight:400;font-size:clamp(42px,6vw,78px);line-height:1.07;letter-spacing:-.035em;margin:20px 0}h2{font-size:34px;font-weight:400;line-height:1.25;margin-top:60px}h3{font:600 19px/1.4 system-ui}.kicker,.label{font:12px/1.5 system-ui;letter-spacing:.14em;text-transform:uppercase}.intro{font-size:23px;max-width:850px}.prose{max-width:790px;margin:0 auto;padding:0 24px}.wide{max-width:1600px;margin:35px auto;padding:0 3vw}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:0 0 22px}img{width:100%;height:auto;display:block;background:#ccd1ce}figcaption{font:14px/1.6 system-ui;padding-top:10px;color:#48524c}blockquote{border-left:3px solid #96a493;padding-left:24px;font-size:23px;margin:30px 0}pre{overflow:auto;padding:22px;background:#e6e5db;font:14px/1.6 monospace}code{font-size:.85em}table{border-collapse:collapse;width:100%;font:14px/1.6 system-ui}td,th{padding:12px 10px;border-bottom:1px solid #bdc7bd;text-align:left;vertical-align:top}.note{background:#e6e9df;padding:24px;margin:32px 0;font:16px/1.7 system-ui}.footnote{font-size:15px}.footnote hr{margin-top:50px}details{padding:18px 0;border-bottom:1px solid #b9c4b9}summary{cursor:pointer;font-family:system-ui}footer{padding:50px 24px;font:13px/1.6 system-ui;text-align:center}article img{margin:28px 0}#reading,#making{scroll-margin-top:20px}.diff{width:100%;font-size:12px}.diff td{padding:4px;white-space:pre-wrap;overflow-wrap:anywhere}.diff_header{background:#e5e5dc}.diff_add{background:#d5e7d5}.diff_sub{background:#f0d9d2}.diff_chg{background:#efdfb5}@media(max-width:850px){.pair{grid-template-columns:1fr}header{padding:40px 24px 20px}.intro{font-size:21px}.wide{padding:0 18px}}@media print{nav{display:none}body{background:white;font-size:12pt}.wide{padding:0}.pair{break-inside:avoid}h2{break-after:avoid}header{padding-top:0}}'''
write(OUT/'style.css',CSS)
NAV='<nav><a href="index.html">Research journal</a><a href="reading.html#reading">Revised chapter</a><a href="making.html#making">Tutorial</a><a href="changes.html">Text &amp; source changes</a><a href="index.html#record">Evidence / replay</a></nav>'
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+CSS+'</style></head><body>'+NAV+body+'<footer>Ada Research · 1 October 2026 · Native Godot museum captures · Working-copy research record</footer></body></html>'
def figure(path,caption):
    return f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{html.escape(caption,quote=True)}"></a><figcaption>{caption}</figcaption></figure>'
def pair(*figures):return '<div class="wide pair">'+''.join(figure(*f) for f in figures)+'</div>'
def prose(text):return '<section class="prose">'+md(text)+'</section>'

body='''<header><div class="kicker">Research journal 01 / Point Lines → Triangle</div><h1>When a face<br>becomes a line.</h1><p class="intro">A step to the side can make a surface disappear. So can moving a corner. They ask different things of us when we want the surface back.</p><p>We used two existing halls to test a way of working: observe one difference, intervene, return—and let the room change the question.</p></header>'''
body+=prose('''## Start where something already happens

The [QFEP handoff](https://docs.google.com/document/d/1o3TwRif8JGcsFj2jd0vWMumzRFeGNf_B7AMYd4e0BwM/edit) becomes useful here as a working discipline. Pick a concrete uncertainty, preserve the starting state, change one condition, then ask what the result allows us to do next. The existing [operational inquiry notes](/book-review/doc/book/OPERATIONAL_INQUIRY.md) already give this a place in the project.

In Point Lines, a suspended line can coincide with a ceiling edge. We began with that encounter. No new exhibit was needed. The first question was simply: **what movement separates them?**''')
body+=pair(('lines-final/line-aligned.png','Point Lines: the supplied eye position aligns the suspended line with the ceiling edge.'),('lines-final/line-side-step.png','The same geometry after a 65 cm sideways camera movement. The detached line separates from the edge.'))
body+=prose('''## The viewing place belongs to the arrangement

At an eye height of 1.65 metres, the two projected lines coincide. A sideways move separates them. Lowering the eye to 1.30 metres also separates them—but moving about 73 centimetres along the viewing strip restores their alignment at that lower height.

**Observed:** these particular camera poses produce separation and recovery. **Interpretation:** the work includes a place from which it can be seen. That place can be negotiated; it is not exhausted by one marked eye height. These images do not establish how easily different visitors find it in a headset.

We also tried making the line's cross-section one quarter as thick. I found the difference harder to read at this capture scale. The original thickness stays. A useful research result can be a reason to keep an existing decision.''')
body+=pair(('lines-final/line-lower-eye.png','Lower eye; the line separates again.'),('lines-final/line-lower-recovered.png','Same lower eye height, another place on the strip; alignment recovered.'))
body+=prose('''The measurement needed revision too. Distances between corresponding endpoints can grow even when both segments lie on the same projected line. We changed the comparison to perpendicular distance from the suspended segment to the projected ceiling edge. The recovered alignment is within one pixel. The initial measure remains in the record so the correction is visible.

## Give Triangle a first encounter

The Triangle hall offered several investigations at once: closure, filling, shared edges, a troublesome fan, symbols and multiple geometric studies. The strongest first route was already inside that collection.

We kept eight placements from seventeen and widened three internal passages. The entrance puzzle now faces the approach. The small drawing and its central twin remain one drawing at two scales. The construction plate connects the room to the book. The folded strip, quad studies and pink triangle remain available for returns. Nine other placements are parked with their exact tokens and positions; their sources and the earlier room are preserved.

This is a curatorial proposal about attention. It needs a visitor's response before we can call it easier to understand.''')
body+=pair(('triangle-before/triangle-two-scales.png','Before: the drawing shares attention with the earlier collection.'),('triangle-after/triangle-two-scales-matched.png','After: the same camera position and lens, with the drawing given more room.'))
body+=prose('''## One appearance, three different changes

The revised chapter follows a short investigation. Close three edges. Add a face. Then visit the same drawing at two scales.

Leave its corners alone and walk to its side: its breadth disappears from view. Return to the small tool and bring its upper corner down onto the baseline: the large copy now has no area. Walking round cannot restore that area. Move the corner away, and a face opens again.

The existing fill button offers a third change. It hides both faces while keeping the corners and edges. Here, asking *what disappeared?* becomes more useful than naming the shape again.''')
body+=pair(('triangle-after/triangle-front.png','An unchanged face viewed from the front.'),('triangle-after/triangle-edge.png','The same stored corners viewed from the side. Its area remains positive.'))
body+=pair(('triangle-after/triangle-collapsed.png','The upper corner has been picked up and released onto the baseline. Three addresses remain; area is zero.'),('triangle-after/triangle-unfilled.png','The fill is switched off. The triangular boundary remains, ready for the same face to return.'))
body+=prose('''## The proposed sentence had to survive the artifact

“Bring the upper corner onto the baseline” sounds straightforward. The supplied corners initially did not obey the same snapping rule as a visitor's released point. We changed the starter to use that rule, then exercised the production pickup and drop methods with a supplied hand position. The collinear result now survives release.

Reviewing the pictures found another problem. The museum seated the drawing station after its world-space starter was built, leaving the large triangle partly under the floor. An area-only check passed, because translation does not change area. The artifact now carries the drawing with its relocated support. A new check verifies the actual corner positions before and after reset.

There is also a small **RESTORE TRIANGLE** button. It replaces the current drawing only when the pen and all corners are released. A carried trace still arrives open; it is not automatically discarded. Recovery makes the comparison repeatable without asking someone to redraw the starting figure each time.''')
body+='<div class="wide">'+figure('triangle-after/triangle-maker.png','The small drawing, the existing controls, the new restore button and the shared large twin in the actual museum.')+'</div>'
body+=prose('''## What reaches the writing

The chapter is shorter: 1,582 to 1,043 words including its retained footnotes. The fan's overspill remains a further investigation, with its detailed construction beside the chapter. The first passage now has a distinction the visitor can follow:

> From one view, these two events can look alike. In one, the face waits for another viewpoint. In the other, we must change what we made.

The critical possibility comes from keeping those different conditions available. A name can remain stable while the image, geometry, or permission to pass through it changes. The room need not finish that thought for the visitor.

[Read the revised chapter](reading.html#reading) · [Open the tutorial](making.html#making) · [Compare the exact changes](changes.html)

## A repeatable working rhythm

For the next hall, use one question small enough to try in the room. Keep a baseline image and its camera. Change one condition. If the result is unclear, inspect the measuring setup as well as the exhibit. Repair the encounter before making the prose explain away its failure. Then decide what to keep, park or pursue.

The immediate human trial is small: approach the puzzle without an explanation, then try the three changes at the twin. Can you distinguish moving yourself, moving a corner and hiding a face? Can you recover the starting triangle? Watch where the hand or attention stalls. Those observations should guide the next pass.

The approach produced a clearer proposal, two concrete artifact repairs and a more specific passage of writing. It has not yet demonstrated learning, bodily ease, or a general theory of inquiry.''')
body+='<section class="prose" id="record"><h2>Evidence and what remains open</h2>'
body+=md('''All photographs above are rendered inside the native Godot museum. They are not grid plans or generated illustrations. Materials, room lighting and the desktop HUD are retained; the large off-white face appears blue under this lighting.

The final native pass records **12 Point Lines checks and 25 Triangle checks**, including camera bookkeeping, actual pickup/drop behavior, the reset guard and three capsule collision sweeps. A fresh-process Triangle replay compares corner positions, areas and route results. These are bounded software observations, not a physical headset session or a learner evaluation.

The capsule is 1.65 m high and 0.5 m wide on collision mask 1. Its three specified routes are clear. This does not certify every route, floor support, controller reach, Quest performance or the whole museum. Point Lines still reports an exit-frame safe-fallback warning, also present in the initial capture; that exit needs a separate passage check. Existing UID, audio and renderer warnings remain in the logs.

The first Triangle entrance camera was inside a wall. Early route checks mixed local and world coordinates. Neither is presented as evidence of a blocked visitor entrance. A later trial passed its area checks but showed the misplaced starter; its images are retained as the reason the checks changed.
''')
body+='''<details><summary>Open trial records</summary><ul>
<li><a href="QUESTION.md">Initial questions and scope changes</a></li>
<li><a href="baseline.json">Working-copy baseline hashes</a> / <a href="after.json">Revised source hashes</a></li>
<li><a href="lines-final/report.json">Final Line measurements</a> / <a href="lines-final/line-quarter-thickness.png">Discarded thickness trial</a></li>
<li><a href="triangle-before/report.json">Triangle baseline</a> / <a href="triangle-after/report.json">Triangle final report</a></li>
<li><a href="triangle-trial-one/report.json">First route apparatus failure</a></li>
<li><a href="triangle-trial-two/triangle-collapsed.png">The misplaced starter</a> / <a href="triangle-trial-two/report.json">The insufficient area check</a></li>
<li><a href="parked-placements.json">Nine parked placements</a></li>
<li><a href="replay-verification.json">Fresh-process replay comparison</a></li>
<li><a href="probe.gd">Executable trial</a> / <a href="triangle-after/stdout.log">Native log</a></li>
</ul></details>'''
body+=md('''### Replay in this checkout

```powershell
python tools/run_encounter_probe.py Point_Lines --sequence primitives --render --probe doc/book/iterations/2026-10-01-lines-triangle-research/probe.gd
python tools/run_encounter_probe.py Point_Triangle_Context --sequence primitives --render --probe doc/book/iterations/2026-10-01-lines-triangle-research/probe.gd
```

The runner isolates museum output in `ada_run/encounter_pilot/`. Each saved trial includes its control, plan, overrides, source manifest and engine version. Replay needs the project and its dependencies; this review folder is not a standalone museum build. Background animations need not produce identical pixels.
''')+'</section>'
write(OUT/'index.html',page('When a face becomes a line — Ada Research',body))

for source,target,anchor in [('final.md','reading.html','reading'),('tutorial.md','making.html','making')]:
    text=read(ROOT/'commons/maps/Point_Triangle_Context'/source)
    # Companion relative links must resolve from the source map, not this dated page.
    rendered=md(text)
    def links(m):
        value=m.group(1)
        if not re.match(r'^(?:[a-z]+:|/|#)',value):
            from posixpath import normpath
            value='/book-review/'+normpath('commons/maps/Point_Triangle_Context/'+value)
        return 'href="'+value+'"'
    rendered=re.sub(r'href="([^"]+)"',links,rendered)
    write(OUT/target,page('Triangle — '+anchor,'<header><div class="kicker">Current canonical '+source+'</div></header><article class="prose" id="'+anchor+'">'+rendered+'</article>'))

before=read(OUT/'before/commons/maps/Point_Triangle_Context/final.md')
after=read(ROOT/'commons/maps/Point_Triangle_Context/final.md')
comparison=difflib.HtmlDiff(wrapcolumn=65).make_table(before.splitlines(),after.splitlines(),'Before this pilot','Promoted to final.md',context=True,numlines=2)
changebody='<header><div class="kicker">Working-copy comparison</div><h1>What changed.</h1><p>Text, artifacts and the arrangement are recorded separately. The earlier state remains recoverable.</p></header><section class="prose"><ul>'
for rel,name in changes:changebody+=f'<li><a href="diffs/{name}">{html.escape(rel)}</a></li>'
changebody+='</ul></section><div class="wide">'+comparison+'</div>'
write(OUT/'changes.html',page('Triangle — exact changes',changebody))
print('Published',len(changes),'changed source files and four local pages')
