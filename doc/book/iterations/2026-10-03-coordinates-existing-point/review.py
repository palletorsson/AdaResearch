"""Publish the canonical Coordinates tutorial with native museum evidence."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAP = ROOT / 'commons/maps/Point_Coordinates'
RUN = ROOT / 'ada_run/encounter_pilot/Point_Coordinates_tutorial'
sources = [ROOT / p for p in (
    'commons/primitives/point/point_condition.gd',
    'algorithms/vectors/00_coordinates/CoordinateSystem3M.gd',
    'commons/primitives/point/coordinate_readout.gd')]
lesson = (MAP / 'tutorial.md').read_text(encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
for path in [MAP / 'map_data.json', MAP / 'final.md', *sources]:
    assert path.read_bytes() == (OUT / 'before' / path.name).read_bytes(), path
assert '$' not in lesson and 'get_node(' not in lesson
blocks = re.findall(r'```gdscript\n(.*?)```',lesson,re.S)
all_source = '\n'.join(p.read_text(encoding='utf-8') for p in sources)
replacement = 'held.position = CENTRE + Vector3(0, 0.5, 0)'
for block in blocks:
    assert block.strip() in all_source or block.strip() == replacement, block
assert replacement in (OUT/'verify.gd').read_text(encoding='utf-8')
for name in ('held-point.png','raised-point.png','coordinates-basin.png','two-decimals.png','three-decimals.png','engine.log','source_manifest.json'):
    shutil.copy2(RUN/name,OUT/name)
(OUT/'tutorial.md').write_text(lesson,encoding='utf-8')
(OUT/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(OUT/'Point_Coordinates.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True),lesson.splitlines(True),fromfile='Point_Coordinates/before/tutorial.md',tofile='Point_Coordinates/tutorial.md')),encoding='utf-8')
contract = {
    'map':'Point_Coordinates', 'host':'existing Endless Museum hall',
    'existing_artifacts':['point_held','CoordinateSystem3M','WORLD coordinate_readout','LOCAL coordinate_readout'],
    'reuses':['Point Zero: _process', 'Point One: Vector3, named values, surface and boundary'],
    'introduces':['supplied pickup relation','X/Y/Z components and vector addition','world and frame-local position','explicit Vector3 type annotation','coordinate display formatting'],
    'supplied':['museum player and input','XRToolsPickable hold/release','point discovery and channel routing','frame geometry and card construction'],
    'student_edits':['held.position = CENTRE + Vector3(0, 0.5, 0)','xyz formatting: %.2f to %.3f'],
    'defers':['distance and two-point relation to Point Lines','implementing pickup and input','general transformations'],
    'source_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
    'new_artifacts':[], 'physical_headset_tested':False, 'native_checks':len(report['checks']),
    'next':'Point_Lines after author reading'
}
(OUT/'lesson-contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf-8')
decisions = f'''# Coordinates — the point already in the hall

The tutorial continues from Point One using the existing held black point, basin frame and two cards in Endless Museum. It removes the instruction to instance another point or switch to a separate two-marker scene. No artifacts are added or removed. The old tutorial and implementation note are preserved in `before/`.

The learner changes the held branch's starting position in the same script read in Point One, then changes the existing card's decimal formatting. These are selected edits, not a replacement implementation. The XRToolsPickable relation is named as supplied. The lesson reads two position expressions in the running frame without requiring students to implement its group lookup, rendering or reporting connection.

The source check matters here: the held body's parent-local position is not the frame's LOCAL reading. The frame uses `to_local(pt.global_position)`, including its scale of 1.5. The black arm points towards negative Z. Card formatting changes the report, not the stored position. These distinctions prevent the simplified explanation from teaching a different system.

An independent reader checked the draft against source. {len(report['checks'])} native checks passed inside the actual museum, including the half-metre starting edit, supplied pickup/release with a synthetic holder, WORLD/LOCAL reporting, a shifted reference, and the printed formatting edit. Both cards still follow the same point. The two decimal screenshots show the same unchanged position. Images were inspected directly; they are museum renders, not a separate illustration room.

Tests substitute edited scripts in memory at the original placements. The original artifact scripts, map and critical `final.md` are byte-for-byte unchanged from this pass's baseline. Canonical `tutorial.md` and its implementation note are updated. No physical headset or beginner reading test was performed. The engine log retains the existing unresolved audio-bus UID and renderer warnings; these focused checks do not certify the whole project. HTML links and anchors are checked programmatically; browser visual inspection was not performed.

The target, Fontana comparison and other objects remain part of the museum field. Distance belongs to Point Lines, which is next after this lesson has been read.
'''
(OUT/'DECISIONS.md').write_text(decisions,encoding='utf-8')
shutil.copy2(OUT.parent/'2026-10-03-point-one-existing-points/style.css',OUT/'style.css')
def figure(name, caption):
    return f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
def pair(a, ca, b, cb):
    return '<div class="pair">'+figure(a,ca)+figure(b,cb)+'</div>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Coordinates — carry a position</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the tutorial</a><a href="#museum">Inside the hall</a><a href="#changes">Try the changes</a><a href="#decisions">Decisions and checks</a></nav><p>ADA / ENDLESS MUSEUM / 3 OCTOBER 2026</p></header>
<article><p class="step">Point Coordinates · the next tutorial</p><h1>One point.<br>Two addresses.</h1><p class="subtitle">Carry the existing black point. Read its position from the world and from the coloured frame.</p><p><a href="../2026-10-03-point-one-existing-points/index.html#reading">Previous: Point One’s surface and boundary</a></p></article>
<section id="museum" class="screen">{figure('coordinates-basin.png','The existing frame and WORLD/LOCAL cards in Endless Museum. Both cards report the held point.')}</section>
<article id="reading" class="chapter">{markdown.markdown(lesson,extensions=['fenced_code'])}<p class="quiet"><a href="tutorial.md">Tutorial source</a> · <a href="Point_Coordinates.diff">Exact text diff</a></p></article>
<section id="changes" class="screen">{pair('held-point.png','The existing point starts at a local height of 1.12 m.','raised-point.png','The printed position edit raises the same held variant by half a metre. Its station label stays in place.')}{pair('two-decimals.png','The WORLD card reports this position with two decimal places.','three-decimals.png','Only the formatting changes. The point stays at the same position; both cards show an extra decimal.')}</section>
<details id="decisions"><summary>What changed and what was checked</summary><div>{markdown.markdown(decisions)}<p><a href="verification.json">Native checks</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="verify.gd">Probe</a> · <a href="engine.log">Engine log</a> · <a href="source_manifest.json">Museum source record</a></p><p><a href="before/point_condition.gd">Original point source</a> · <a href="before/CoordinateSystem3M.gd">Original frame source</a> · <a href="before/coordinate_readout.gd">Original card source</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links=[]; self.ids=set()
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k,v in attrs if k in ('href','src'))
        self.ids.update(v for k,v in attrs if k=='id')
links=Links(); links.feed(page)
for link in links.links:
    url=urlsplit(link)
    if url.scheme: continue
    if url.path: assert (OUT/unquote(url.path)).exists(),link
    elif url.fragment: assert url.fragment in links.ids,link
summary={'native_checks':len(report['checks']),'source_excerpts_and_edits_checked':len(blocks),'links_checked':len(links.links),'lesson_words_including_code':len(lesson.split()),'map_artifacts_and_final_unchanged':True}
(OUT/'review-checks.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary))
