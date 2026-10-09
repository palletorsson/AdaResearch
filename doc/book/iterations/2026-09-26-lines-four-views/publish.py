from pathlib import Path
import json, shutil, difflib, hashlib, html, re
import markdown

r = Path.cwd()
o = Path(__file__).resolve().parent
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

checks = []
for room, target in [('Point_One', 'point'), ('Point_Lines', 'lines')]:
    source = r/'ada_run/encounter_pilot'/f'{room}_four_views'
    dest = o/target
    dest.mkdir(exist_ok=True)
    report = read(source/'report.json')
    assert report['passed'], report['failures']
    checks += report['checks']
    for path in source.glob('*.png'): shutil.copy2(path, dest/path.name)
    for name in ['report.json', 'source_manifest.json', 'stdout.log']:
        shutil.copy2(source/name, dest/name)
shutil.copy2(r/'doc/book/iterations/2026-09-26-point-one-basin/basin.png',o/'previous-basin.png')
shutil.copy2(r/'doc/book/captures/primitives/primitives-book.md',o/'primitives-book.md')

changed = []
for before in (o/'before').rglob('*'):
    if not before.is_file(): continue
    rel = before.relative_to(o/'before')
    current = r/rel
    if current.read_bytes() == before.read_bytes(): continue
    changed.append(rel.as_posix())
    dest = o/'after'/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(current,dest)
    diff = o/'diffs'/(rel.as_posix()+'.diff')
    diff.parent.mkdir(parents=True,exist_ok=True)
    diff.write_text(''.join(difflib.unified_diff(before.read_text(encoding='utf-8').splitlines(True),current.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile='after/'+rel.as_posix())),encoding='utf-8')
for p in (r/'commons/artifacts/line_relations_gallery').glob('*'):
    if p.suffix not in ['.gd','.tscn']:continue
    rel=p.relative_to(r);changed.append(rel.as_posix())
    dest=o/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
(o/'sources.json').write_text(json.dumps({p:sha(r/p) for p in changed},indent=2)+'\n',encoding='utf-8')
(o/'verification.json').write_text(json.dumps({'passed':True,'native_checks':len(checks),'checks':checks,'scope':'Native museum, supplied grabber, physical rays/capsule paths. Headset comfort and learner acceptance remain unverified.'},indent=2)+'\n',encoding='utf-8')

manuscript=(r/'commons/maps/Point_Lines/final.md').read_text(encoding='utf-8')
old=(o/'before/commons/maps/Point_Lines/final.md').read_text(encoding='utf-8')
reading=markdown.markdown(manuscript,extensions=['fenced_code','footnotes','tables'])
diff=difflib.HtmlDiff(wrapcolumn=75).make_table(old.splitlines(),manuscript.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2)
parked=read(o/'parked-placements.json')
decisions=f'''# L-shaped basin and four views of a line

The user's correction replaces the rectangular coordinate pool with two one-cell-wide arms following the X/Z axes. Eleven basin cells, 1 m deep; origin and horizontal axes at deck height. Existing basin seating lowers by one metre, so the placement offset is +1 m. The uncut quadrant remains floor. Automatic dream-body statues are excluded in these two halls so they do not stand across the axes or line paths.

Point Lines preserves the first nine rows, including the black walk and trace, then opens into a 27 × 37 hall. Its four sightlines compare plus/X, parallels/measures, vertical/horizon and grid/depth. Twenty line bodies use the production XRToolsPickable class, with Dynamic World and Pickable Objects layers (mask 6), and stay where released. They are arrangement models; their bodies do not obstruct the walking capsule. The real hall wall does obstruct it.

The common segment's five skins change the visible body without changing its endpoints. The light skin is an emissive mesh, not a laser ray. Existing laser_measure supplies the actual ray-based instrument. Fixed wall drawings do not live-project the moved bodies. The gallery's wall coordinates are authored for this room; it is not claimed as a portable wall-layout generator.

The new primary encounter enters canonical Point_Lines/final.md, curation roles and the full Primitives capture. Original references remain. {len(parked)} repeated rear placements have been parked, with exact tokens and cells recorded and their source artifacts intact. Selected earlier works and the four-camera workshop remain on the side/exit route. Earlier notes asserting all 52 placements or only five primary tokens are historical.

The 27 m gallery deliberately exceeds the old generic 19 m hall-width guideline to give four views enough width. The existing generator accepts it; only this map's derived row uses the width exemption when refreshed here. Other hall plan rows are unchanged.

{len(checks)} native checks passed across the two halls: floor-level origin, both basin arms, pickup and release, line spans/pickup layers, all four walking paths, entry into the gallery and obstruction at the real wall. Screenshots are from the actual museum. No script/shader errors were reported; existing unrelated cabinet/material/UID warnings remain in the logs. Headset handling and learner acceptance remain open. No commit.
'''
(o/'DECISIONS.md').write_text(decisions,encoding='utf-8')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point and line · Four views</title><style>
body{margin:0;background:#eeeae0;color:#252824;font:18px/1.7 Georgia,serif}main{max-width:1320px;margin:auto;padding:48px 28px}h1{font-weight:400;font-size:clamp(34px,5vw,62px);line-height:1.15}h2{font-weight:400;line-height:1.3;margin-top:2em}p{max-width:790px}nav,small,figcaption,summary{font:14px/1.6 system-ui,sans-serif}nav a{margin-right:22px}a{color:#22564e}figure{margin:30px 0}img{width:100%;height:auto}figcaption{margin-top:6px;color:#585c56}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}.reading{max-width:760px;margin:70px auto}.reading p{margin:1.15em 0}.reading h1{font-size:38px}.reading h2{font-size:27px}pre{overflow:auto;background:#e2e1d7;padding:18px;font-size:14px}code{font-size:.86em}.table-scroll{overflow:auto}table.diff{font:12px/1.5 monospace;width:100%;border-collapse:collapse}.diff_header{background:#dfdbcf}.diff_add{background:#d4e9d6}.diff_sub{background:#f0d5cf}.diff_chg{background:#ece2b2}td{vertical-align:top}details{margin:30px 0}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:26px 18px}}
</style><main><small>PRIMITIVES · 26 SEPTEMBER 2026</small><h1>An idea needs a body.</h1><p>The coordinate basin follows its axes. Beyond <em>Walk this line</em>, the hall opens into four paths of looking and rearranging. A line becomes something the eye can follow and the hand can hold. At the wall, those two kinds of following part company.</p><nav><a href="#basin">The L-shaped basin</a><a href="#gallery">Four views</a><a href="#reading">Read the revised chapter</a><a href="#changes">Text changes</a></nav>
<section id="basin"><h2>Point One · the L at floor level</h2><figure><img src="point/l-basin.png" alt="Floor-level coordinate axes following the two arms of a glass-covered L-shaped pool"><figcaption>The origin and horizontal axes are at floor level. The glass covers two narrow basin arms; the quadrant between them remains ordinary floor.</figcaption></figure><details><summary>Previous rectangular pool</summary><img src="previous-basin.png" alt="The previous rectangular basin"><p>The previous version sank the origin below deck. This replaces it.</p></details></section>
<section id="gallery"><h2>Point Lines · four views after the walk</h2><figure><img src="lines/four-views.png" alt="Four open sightlines through arrangements of sticks, planks, uprights and grids"><figcaption>Actual museum view. Twenty line bodies can be picked up and left in another arrangement. The four-camera workshop remains beyond them.</figcaption></figure><div class="pair"><figure><img src="lines/plus-and-cross.png" alt="Plus and cross made from movable sticks"><figcaption>Two lines, another view: plus and X.</figcaption></figure><figure><img src="lines/parallel-and-grid.png" alt="Parallel planks and line arrangements in depth"><figcaption>Parallel bodies, vertical beams, a horizon and a grid.</figcaption></figure></div><figure><img src="lines/follow-to-wall.png" alt="FOLLOW THIS LINE on the floor leading into a solid wall and continuing upward"><figcaption>The floor mark reaches the wall and climbs its face. The wall still stops the walking body.</figcaption></figure></section>
<section class="reading" id="reading">'''+reading+'''</section><section id="changes"><h2>What changed in the manuscript</h2><p>The opening connection, measurement, walk and trace remain. The new passage follows the four views, gives the line's “conceptual skin” a concrete meaning, and returns to the journey at the wall.</p><details><summary>Compare original and current text</summary><div class="table-scroll">'''+diff+'''</div></details><p><a href="primitives-book.md">Full Primitives capture</a> · <a href="DECISIONS.md">Decisions and limits</a> · <a href="parked-placements.json">Parked duplicate placements</a> · <a href="verification.json">Native checks</a></p><p>'''+str(len(checks))+''' native desktop checks passed. Headset comfort and hand feel remain to be tried in VR.</p></section></main></html>'''
(o/'index.html').write_text(page,encoding='utf-8')
print('Published',len(checks),'native checks;',len(changed),'changed/new sources;',len(parked),'parked placements.')
