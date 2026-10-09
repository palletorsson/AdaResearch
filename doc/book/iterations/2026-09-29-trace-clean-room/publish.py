from pathlib import Path
import difflib, html, json, shutil
import markdown

out = Path(__file__).resolve().parent
root = out.parents[3]
run = root/'ada_run/encounter_pilot/Point_Trace'
report = json.loads((run/'report.json').read_text(encoding='utf-8'))
assert report['passed'] and report['observations']['capture_complete'], report['failures']
before = json.loads((out/'before/commons/maps/Point_Trace/map_data.json').read_text(encoding='utf-8'))
after = json.loads((root/'commons/maps/Point_Trace/map_data.json').read_text(encoding='utf-8'))
assert before['layers']['structure'] == after['layers']['structure']
assert before['layers']['utilities'] == after['layers']['utilities']
tokens = [t.split(':')[0] for row in after['layers']['interactables'] for t in row if t.strip()]
assert tokens.count('draw_dot') == 3
assert not set(tokens) & {'automatic_writing_desk', 'head_trace_projection', 'draw_stick'}
for name in ['clean-hall.png','three-pens.png','plain-pen.png','wall-board.png','board-pens.png','report.json','source_manifest.json']:
    shutil.copy2(run/name,out/name)
shutil.copy2(out.parent/'2026-09-29-trace-plinth-readouts/on-the-plinths.png',out/'before-hall.png')
diffs=[]
for original in sorted((out/'before').rglob('*')):
    if not original.is_file(): continue
    rel = original.relative_to(out/'before')
    current = root/rel
    target = out/'after'/rel
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(current,target)
    diffs.extend(difflib.unified_diff(original.read_text(encoding='utf-8-sig').splitlines(True),current.read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+rel.as_posix(),tofile='after/'+rel.as_posix()))
for rel in ['commons/primitives/point/drawing_pen.gd','commons/artifacts/whiteboard/whiteboard_canvas.gd','commons/maps/Point_Trace/trace-retired-encounters.md']:
    target=out/'after'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/rel,target)
(out/'changes.diff').write_text(''.join(diffs),encoding='utf-8')
reading=markdown.markdown((root/'commons/maps/Point_Trace/final.md').read_text(encoding='utf-8'),extensions=['fenced_code','footnotes'])
body='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trace · room for drawing</title><style>
body{margin:0;background:#f4efe8;color:#28252b;font:20px/1.65 Georgia,serif}main{max-width:1200px;margin:auto;padding:48px 25px}h1{font-size:clamp(36px,5vw,64px);font-weight:400;line-height:1.05}h2{font-weight:400}img{width:100%;display:block}figure{margin:30px 0}figcaption,footer,nav{font:14px/1.6 system-ui,sans-serif;color:#625969}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}a{color:#754260}article{max-width:740px;margin:70px auto}pre{overflow:auto;background:#e8e2da;padding:20px;font-size:14px}.lead{max-width:820px}details{margin:40px 0}@media(max-width:720px){.pair{grid-template-columns:1fr}}</style><main>
<nav>ADA · POINT TRACE · 29 SEPTEMBER 2026</nav><h1>Room for drawing.</h1>
<p class="lead">Three coloured pens, three small readouts, space to approach. Plain barrels point forward when picked up. Their nibs make the marks. The whiteboard sits entirely against the wall, with its own pens and eraser on the shelf.</p>
<nav><a href="#museum">Museum</a> · <a href="#reading">Adjusted reading</a> · <a href="changes.diff">Changes</a></nav>
<section id="museum"><figure><img src="clean-hall.png" alt="The Trace hall with three pen plinths and a clear approach"><figcaption>The desk, head projection, stick and extra neutral dot have been removed from this hall.</figcaption></figure>
<div class="pair"><figure><img src="before-hall.png" alt="Earlier row of five drawing instruments"><figcaption>Before: five different instruments occupied the row.</figcaption></figure><figure><img src="three-pens.png" alt="Three smaller readouts and simple coloured pens"><figcaption>Now: red, green and blue retain their 10, 40 and 80 mm grids.</figcaption></figure></div>
<figure><img src="wall-board.png" alt="Wall-mounted whiteboard with two red marks separated by a white gap, above a shelf of plain pens"><figcaption>Actual museum capture with supplied pen gestures. Touch, lift, touch again: the gap remains blank. Marks persist on a dedicated dry-ink surface.</figcaption></figure>
<div class="pair"><figure><img src="plain-pen.png" alt="Plain coloured barrel with a dark grip and tapered nib beside its readout"><figcaption>The writing point is at the nib, 15.5 cm ahead of the pickup frame.</figcaption></figure><figure><img src="board-pens.png" alt="Four simple pen barrels and an eraser in the whiteboard shelf"><figcaption>The board retains four surface-writing resolutions and dropped-tool return.</figcaption></figure></div></section>
<p class="lead">The chapter now follows the remaining pens. Passages for the removed encounters are preserved separately, and their source scenes remain available.</p>
<footer><p>CHECK_COUNT focused native checks passed: placement, wall support at both ends, fixed pickup direction, nib-based recording, release, marker pixels, pen-lift gaps, erasing and clearing. The main hall geometry and route are unchanged. Tests use supplied hand transforms; headset comfort remains for the visitor to judge.</p><p><a href="report.json">Verification</a> · <a href="after/commons/maps/Point_Trace/trace-retired-encounters.md">Preserved passages</a> · <a href="/compose/sources?map=Point_Trace&amp;doc=final">Current chapter</a></p></footer>
<details id="reading"><summary>Read the adjusted chapter</summary><article>READING</article></details></main></html>'''
(out/'index.html').write_text(body.replace('CHECK_COUNT',str(len(report['checks']))).replace('READING',reading),encoding='utf-8')
print('Published',out/'index.html','with',len(report['checks']),'passing checks.')
