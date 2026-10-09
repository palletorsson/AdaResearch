"""Publish this encounter from native museum evidence, with frozen source diffs."""
from pathlib import Path
import difflib, hashlib, json, shutil
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
reports = {}
for room, prefix, images in [
    ('Point_Lines', 'lines', ['entrance-line', 'black-box-passage', 'line-length-changed']),
    ('Point_Coordinates', 'coordinates', ['held-point', 'coordinates-basin']),
]:
    run = ROOT / 'ada_run/encounter_pilot' / room
    report = json.loads((run/'report.json').read_text(encoding='utf-8-sig'))
    assert report['passed'], report['failures']
    reports[room] = report
    shutil.copy2(run/'report.json', OUT/f'{prefix}-report.json')
    shutil.copy2(run/'source_manifest.json', OUT/f'{prefix}-runtime-sources.json')
    for name in images: shutil.copy2(run/f'{name}.png', OUT/f'{name}.png')

before_point = OUT.parent/'2026-09-29-point-and-coordinates/held-point.png'
if before_point.exists(): shutil.copy2(before_point, OUT/'held-point-before.png')
sources = [
    'commons/primitives/point/point_condition.gd',
    'commons/primitives/line/line.gd',
    'commons/artifacts/line_black_box/line_black_box.gd',
    'commons/artifacts/line_black_box/line_black_box.tscn',
    'commons/maps/Point_Lines/map_data.json',
    'commons/maps/Point_Lines/final.md',
    'commons/maps/Point_Coordinates/final.md',
    'commons/maps/Point_Coordinates/technical.md',
]
manifest = {}
for relative in sources:
    path = ROOT/relative
    manifest[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
    target = OUT/'sources'/relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)
    before = OUT/'before'/relative
    if before.exists():
        diff = ''.join(difflib.unified_diff(before.read_text(encoding='utf-8-sig').splitlines(True), path.read_text(encoding='utf-8-sig').splitlines(True), fromfile='before/'+relative, tofile='after/'+relative))
        target.with_suffix(target.suffix+'.diff').write_text(diff, encoding='utf-8')
registry = ROOT/'commons/artifacts/registry/primitives.json'
manifest[registry.relative_to(ROOT).as_posix()] = hashlib.sha256(registry.read_bytes()).hexdigest()
(OUT/'source-versions.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
before_map = json.loads((OUT/'before/commons/maps/Point_Lines/map_data.json').read_text(encoding='utf-8-sig'))
after_map = json.loads((ROOT/'commons/maps/Point_Lines/map_data.json').read_text(encoding='utf-8-sig'))
assert before_map['layers']['structure'] == after_map['layers']['structure']
assert before_map['layers']['utilities'] == after_map['layers']['utilities']
assert sum(bool(v.strip()) for row in after_map['layers']['interactables'] for v in row) == 41
reading = markdown.markdown((ROOT/'commons/maps/Point_Lines/final.md').read_text(encoding='utf-8-sig'), extensions=['fenced_code','footnotes'])
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Two points / one line · Ada</title><style>
*{box-sizing:border-box}body{margin:0;background:#f3eee8;color:#27232a;font:19px/1.75 Georgia,serif}main{max-width:1260px;margin:auto;padding:50px 30px}h1{font-weight:400;font-size:clamp(40px,6vw,76px);line-height:1.08;letter-spacing:-.03em}h2{font-weight:400;font-size:32px}.intro{max-width:820px;font-size:24px}.small,nav,figcaption,footer{font:14px/1.7 system-ui,sans-serif;color:#625663}a{color:#794864;text-underline-offset:4px}nav{display:flex;gap:22px;flex-wrap:wrap}img{width:100%;display:block}figure{margin:32px 0}figcaption{margin-top:10px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}#reading{max-width:740px;margin:90px auto}#reading h1{font-size:42px}pre{overflow:auto;background:#e9e2e6;padding:18px;font-size:15px;line-height:1.6}footer{border-top:1px solid #cbbfc9;margin-top:60px;padding-top:24px}@media(max-width:720px){main{padding:25px 16px}.pair{grid-template-columns:1fr}.intro{font-size:21px}}
</style><main><p class="small">ADA RESEARCH · POINT COORDINATES → POINT LINES · 29 SEPTEMBER 2026</p><h1>Two points.<br>A line between them.</h1><p class="intro">A four-metre black room in the entrance bay you prepared. Take either end. The connection remains while its length and direction change.</p><nav><a href="#museum">Inside the museum</a><a href="#point">The smaller point</a><a href="#reading">Updated Lines text</a><a href="DECISIONS.md">Decisions and checks</a></nav>
<section id="museum"><figure><a href="entrance-line.png"><img src="entrance-line.png" alt="A pale line with two pearl handles in a dark museum room; the wall reads 1.60 metres."></a><figcaption>Native Godot museum capture. Matte walls, a slender luminous rod, two grabbable ends. The wall measures the span.</figcaption></figure><div class="pair"><figure><img src="line-length-changed.png" alt="One endpoint moved upward and outward; the line is longer and tilted."><figcaption>After moving one end with the production pickup driver: the line tilts and the readout becomes 2.03 m. Release leaves the end in place.</figcaption></figure><figure><img src="black-box-passage.png" alt="Inside the dark room looking towards the two open passages."><figcaption>The north entrance and east passage remain open. The existing two-point and barrier encounter follows beyond the room.</figcaption></figure></div></section>
<section id="point"><h2>A smaller point to hold.</h2><p>The black point in Coordinates is now 14 cm across, down from 28 cm. Its collision sphere shrinks with it; pickup, both coordinate displays and the target still respond.</p><div class="pair"><figure><img src="held-point-before.png" alt="The earlier larger black point in Coordinates."><figcaption>Before: 28 cm diameter.</figcaption></figure><figure><img src="held-point.png" alt="The smaller held black point with the coordinate frame beyond."><figcaption>Now: 14 cm diameter. The earlier white points retain their size.</figcaption></figure></div></section>
<section id="reading">READING</section><footer><p>32 native checks passed in Point Lines; 20 in Coordinates. No headset trial. <a href="lines-report.json">Line checks</a> · <a href="coordinates-report.json">Point checks</a> · <a href="source-versions.json">Source versions</a></p><p>The text above is a frozen copy. <a href="/compose/sources?map=Point_Lines&amp;doc=final">Current Lines text</a> · <a href="sources/commons/maps/Point_Lines/final.md.diff">This pass’s text diff</a></p></footer></main></html>'''
(OUT/'index.html').write_text(page.replace('READING',reading),encoding='utf-8')
print('Review published: 32 + 20 checks passed; authored structure and utilities unchanged.')
