"""Publish the Point One reading copy from canonical text and museum checks."""
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
MAP = ROOT / 'commons/maps/Point_One'
RUN = ROOT / 'ada_run/encounter_pilot/Point_One_tutorial'
SOURCE = ROOT / 'commons/primitives/point/point_condition.gd'
lesson = (MAP / 'tutorial.md').read_text(encoding='utf-8')
source = SOURCE.read_text(encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
for name in ('map_data.json', 'final.md'):
    assert (MAP / name).read_bytes() == (OUT / 'before' / name).read_bytes()
assert SOURCE.read_bytes() == (OUT / 'before/point_condition.gd').read_bytes()
blocks = re.findall(r'```gdscript\n(.*?)```', lesson, re.S)
source_lines = [line.strip() for line in source.splitlines()]
for block in blocks:
    cursor = 0
    for line in block.splitlines():
        if line.strip():
            cursor = source_lines.index(line.strip(), cursor) + 1
assert '$' not in lesson and 'get_node(' not in lesson
for old, new in [('const CENTRE := Vector3(0, 1.12, 0)', 'const CENTRE := Vector3(0, 1.7, 0)'), ('const RADIUS := 0.14', 'const RADIUS := 0.3'), ('sphere_shape.radius = radius', 'sphere_shape.radius = radius * 2.0')]:
    assert source.count(old) == 1
    harness = (OUT / 'verify.gd').read_text(encoding='utf-8')
    assert old in harness and new in harness
for name in ('corridor.png', 'absence.png', 'surface.png', 'solid.png', 'raised.png', 'grown.png', 'sun-off.png', 'engine.log', 'source_manifest.json'):
    shutil.copy2(RUN / name, OUT / name)
(OUT / 'verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
(OUT / 'tutorial.md').write_text(lesson, encoding='utf-8')
(OUT / 'Point_One.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), lesson.splitlines(True), fromfile='Point_One/before/tutorial.md', tofile='Point_One/tutorial.md')), encoding='utf-8')
contract = {
    'map': 'Point_One', 'host': 'existing Endless Museum corridor',
    'source': str(SOURCE.relative_to(ROOT)),
    'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'existing_artifacts': ['point_absent','point_visible','point_solid','point_pedestal','point_sun_switch'],
    'reuses': ['Day Zero: edit, save, restart the museum', 'Point Zero: source reading, assignment and _ready'],
    'introduces': ['named values: const, var and inferred type', 'Vector3 as a position', 'a mesh resource and the node displaying it', 'a separate physics body and collision shape'],
    'supplied': ['condition selection', 'labels, material and subdivision', 'large pedestal configuration', 'museum player and light rig'],
    'student_edits': ['small point height 1.12 to 1.7', 'shared small radius 0.14 to 0.3', 'collision radius multiplied by two'],
    'defers': ['grabbing and reference frames to Coordinates', 'distance to Lines', 'shape subdivision and materials'],
    'new_artifacts': [], 'next': 'Point_Coordinates after author reading',
    'physical_headset_tested': False, 'native_checks': len(report['checks'])
}
(OUT / 'lesson-contract.json').write_text(json.dumps(contract, indent=2) + '\n', encoding='utf-8')
decisions = f'''# Point One — use the points already in the corridor

Palle asked to continue with the next hall and reiterated that its artifacts already exist. The canonical tutorial now follows the shared `commons/primitives/point/point_condition.gd` used by `point_absent`, `point_visible`, `point_solid` and `point_pedestal`. No artifacts, scenes or alternate teaching room were added. The old starter remains a separate study, not the default route.

The first lesson is the difference between a position, a visible surface and a physical boundary. Its source uses `const CENTRE`, so the text explains a constant accurately rather than inventing a different variable in a duplicate script. `var` is introduced through the existing resource and node references. Station selection is named as supplied; the learner edits the relevant values without first implementing all the branches.

The small visible and solid variants share `CENTRE` and `RADIUS`. The pedestal overrides those values. The collision assignment serves both solid and pedestal: doubling it changes both boundaries, and the tutorial says so. The student's own collision body contributes to the stopping distance. The light switch is an encounter at the end; programming its rig is deferred. Coordinates retains grabbing and reference frames.

The excerpts identify source already present. The larger collision excerpt explicitly omits naming and collision-layer assignments for reading; students are told to make only specified edits. The critical `final.md`, museum map and source script are byte-for-byte unchanged from this pass's baseline. `technical.md` and the existing course handover now point to this lesson.

An independent source reader checked the draft against the script and placement chain. {len(report['checks'])} native checks passed using the real museum and its CharacterBody3D. The player crossed absence and visible mesh, met the solid, and stopped earlier after invisible boundary growth. Height, shared radius and pedestal exceptions were checked. The existing button event removed the sun without removing collision. The test substituted edited scripts in memory at original placements; it retained their renderer masks because anonymous test scripts have no source path for the light's normal discovery. Nothing was saved into production artifacts.

The images are native views inside the museum. Physical headset use and beginner comprehension remain untested. The engine log also contains the existing unresolved audio-bus UID `uid://rwex60pqapc` and material warnings; passing these focused checks does not certify the whole project. Review links and anchors are checked programmatically; browser visual inspection was not performed.

Next: read this one lesson, then follow the existing held point into Point Coordinates.
'''
(OUT / 'DECISIONS.md').write_text(decisions, encoding='utf-8')
shutil.copy2(OUT.parent / '2026-10-03-point-zero-in-the-museum/style.css', OUT / 'style.css')
def figure(name, caption):
    return f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
def pair(a, ca, b, cb):
    return '<div class="pair">' + figure(a,ca) + figure(b,cb) + '</div>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point One — the existing points</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the tutorial</a><a href="#museum">Inside the hall</a><a href="#changes">Try the changes</a><a href="#decisions">Decisions and checks</a></nav><p>ADA / ENDLESS MUSEUM / 3 OCTOBER 2026</p></header>
<article><p class="step">Point One · the next tutorial</p><h1>A position.<br>A surface. A boundary.</h1><p class="subtitle">The points are already in the corridor. Read their construction, then change what they permit.</p><p><a href="../2026-10-03-point-zero-in-the-museum/index.html#reading">Previous: Point Zero’s running counter</a></p></article>
<section id="museum" class="screen">{figure('corridor.png', 'Point One’s existing corridor in Endless Museum. Native Godot rendering.')}{pair('absence.png','The first station creates a label and no sphere.','surface.png','The next station adds a visible surface, with no collision body.')}</section>
<article id="reading" class="chapter">{markdown.markdown(lesson,extensions=['fenced_code'])}<p class="quiet"><a href="tutorial.md">Tutorial source</a> · <a href="Point_One.diff">Exact text diff</a></p></article>
<section id="changes" class="screen">{pair('solid.png','The original small solid sphere: radius 0.14 m.','grown.png','Changing RADIUS to 0.3 grows this sphere and its matching boundary. The large pedestal sphere retains its own radius.')}{pair('surface.png','The original visible point uses a centre height of 1.12 m.','raised.png','CENTRE at 1.7 m moves the surface; its label stays put.')}{figure('sun-off.png','The existing switch removes the directional sun. Fill remains, and the solid sphere’s collision is unchanged.')}</section>
<details id="decisions"><summary>What changed and what was checked</summary><div>{markdown.markdown(decisions)}<p><a href="verification.json">Native checks</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="before/point_condition.gd">Original artifact source</a> · <a href="verify.gd">Probe</a> · <a href="engine.log">Engine log</a> · <a href="source_manifest.json">Museum source record</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links=[]; self.ids=set()
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k,v in attrs if k in ('href','src'))
        self.ids.update(v for k,v in attrs if k == 'id')
links=Links(); links.feed(page)
for link in links.links:
    url=urlsplit(link)
    if url.scheme: continue
    if url.path: assert (OUT/unquote(url.path)).exists(), link
    elif url.fragment: assert url.fragment in links.ids, link
summary={'native_checks':len(report['checks']), 'source_excerpts_match':len(blocks), 'local_links_checked':len(links.links), 'map_artifact_and_final_unchanged':True, 'added_artifacts':0, 'lesson_words_including_code':len(lesson.split())}
(OUT/'review-checks.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary))
