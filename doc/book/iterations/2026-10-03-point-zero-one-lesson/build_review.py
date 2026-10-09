"""One-lesson reading copy, comparison and matching downloadable study."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import zipfile

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
SOURCE = ROOT / 'commons/maps/Point_Zero/tutorial.md'
STUDY = ROOT / 'doc/book/studies/point-zero'
before = (OUT / 'before-course-world.md').read_text(encoding='utf-8')
after = SOURCE.read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', after, re.S)
assert len(blocks) == 3
assert all('$' not in block and 'get_node' not in block and 'NodePath' not in block for block in blocks)
assert all('Label3D.new()' in block and 'add_child(display)' in block for block in blocks)
assert all('Label3D' not in (STUDY / name).read_text(encoding='utf-8') for name in ('base.tscn', 'hello_world.tscn'))
assert blocks[1].strip() == (STUDY / 'hello_world.gd').read_text(encoding='utf-8').strip()
assert (STUDY / 'TUTORIAL.md').read_text(encoding='utf-8') == after.replace('../../../doc/book/studies/point-zero/README.md', 'README.md')
(OUT / 'Point_Zero.tutorial.md').write_text(after, encoding='utf-8')
(OUT / 'Point_Zero.tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='before/Point_Zero/tutorial.md', tofile='commons/maps/Point_Zero/tutorial.md')), encoding='utf-8')
(OUT / 'lesson-code.json').write_text(json.dumps(dict(zip(('greeting', 'counter', 'once'), blocks)), indent=2) + '\n', encoding='utf-8')

files = [STUDY / name for name in ('project.godot', 'base.tscn', 'hello_world.tscn', 'hello_world.gd', 'README.md', 'TUTORIAL.md')]
with zipfile.ZipFile(OUT / 'point-zero-study.zip', 'w', zipfile.ZIP_DEFLATED) as package:
    for file in files:
        package.write(file, 'point-zero/' + file.name)
with zipfile.ZipFile(OUT / 'point-zero-study.zip') as package:
    assert package.testzip() is None
    for file in files:
        assert package.read('point-zero/' + file.name) == file.read_bytes()

def render(text):
    text = text.replace('../../../doc/book/studies/point-zero/README.md', 'point-zero-study.zip')
    return markdown.markdown(text, extensions=['fenced_code'])

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Point Zero — one tutorial</title><style>
*{box-sizing:border-box}body{margin:0;background:#f6f3eb;color:#282b29;font:19px/1.65 Georgia,serif}
main{max-width:1160px;margin:auto;padding:35px 24px 70px}header,article{max-width:720px;margin:0 auto}
header{font:14px/1.6 system-ui,sans-serif;border-bottom:1px solid #ccc6bc;padding-bottom:20px;margin-bottom:42px}
nav{display:flex;flex-wrap:wrap;gap:12px 24px}a{color:#794451;text-underline-offset:3px}
h1{font-weight:normal;font-size:38px;line-height:1.2}h2{font-weight:normal;font-size:27px;margin-top:36px}
p{margin:0 0 22px}pre{padding:20px;background:#eae6dd;overflow:auto;font:14px/1.55 Consolas,monospace}
code{font-family:Consolas,monospace;font-size:.88em}pre code{font:inherit}details{margin-top:48px;border-top:1px solid #ccc6bc;padding-top:20px}
summary{font:16px/1.6 system-ui,sans-serif;cursor:pointer}.comparison{display:grid;grid-template-columns:1fr 1fr;gap:35px;font-size:16px}
.comparison>div{min-width:0}.comparison h1{font-size:28px}.comparison h2{font-size:23px}
.views{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:20px}.views figure{margin:20px 0}.views img{width:100%;height:auto}.views figcaption{font:14px/1.5 system-ui,sans-serif}
a:focus-visible,summary:focus-visible{outline:3px solid #a75172;outline-offset:4px}
@media(max-width:800px){.comparison{grid-template-columns:1fr}body{font-size:18px}main{padding:24px 18px}}
@media print{header,details{display:none}body{background:white;font-size:11pt}main{padding:0}pre{white-space:pre-wrap}h2{break-after:avoid}}
</style></head><body><main><header><p>Point Zero · One tutorial at a time · 3 October 2026</p>
<nav><a href="#reading">Read</a><a href="point-zero-study.zip">Download desktop study</a><a href="course-world.html">How the studies belong to Ada</a><a href="#comparison">Before / after</a><a href="Point_Zero.tutorial.diff">Text diff</a></nav></header>
<article id="reading">''' + render(after) + '''</article>
<details id="view-study"><summary>See the camera and light experiments</summary><div class="views">
<figure><a href="camera-light-default.png"><img src="camera-light-default.png" alt="White greeting above a grey floor, viewed from the starting camera position"></a><figcaption>Starting view · camera z 4.7, light energy 1.2</figcaption></figure>
<figure><a href="camera-nearer.png"><img src="camera-nearer.png" alt="The same greeting appears larger with the camera closer"></a><figcaption>Camera nearer · z 3.0; the text object is unchanged</figcaption></figure>
<figure><a href="light-off.png"><img src="light-off.png" alt="The floor is black while the unshaded greeting stays bright"></a><figcaption>Light off · energy 0.0; the text remains bright</figcaption></figure>
</div></details>
<details id="comparison"><summary>Before / after — ''' + str(len(before.split())) + ' → ' + str(len(after.split())) + ''' words including code</summary>
<div class="comparison"><div><h2>Before</h2>''' + render(before) + '''</div><div><h2>After</h2>''' + render(after) + '''</div></div></details>
</main></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
world = (ROOT / 'doc/book/course/COURSE_WORLD.md').read_text(encoding='utf-8')
world = world.replace('../studies/ada-xr-starter/README.md', '../2026-10-03-ada-xr-starter/index.html')
world = world.replace('../iterations/2026-10-03-day-zero-light-and-material/index.html', '../2026-10-03-day-zero-light-and-material/index.html')
world = world.replace('../iterations/2026-10-03-point-one-a-body/index.html', '../2026-10-03-point-one-a-body/index.html')
world = world.replace('../iterations/2026-10-03-point-lines-two-ends/index.html', '../2026-10-03-point-lines-two-ends/index.html')
world_page = page.split('<body>')[0].replace('<title>Point Zero — one tutorial</title>', '<title>One Ada world, portable studies</title>') + '<body><main><header><nav><a href="index.html#reading">Back to Point Zero</a></nav></header><article>' + markdown.markdown(world, extensions=['tables']) + '</article></main></body></html>'
(OUT / 'course-world.html').write_text(world_page, encoding='utf-8')
(OUT / 'DECISIONS.md').write_text('''# Point Zero: one tutorial

3 October 2026. First prose pilot under the staged subject plan.

- Inherited: Day Zero's working environment, editing and running, prepared scene. The course builds within one shared Ada XR world; this small download is a portable desktop study.
- New: ready once / process repeatedly; a retained counter; calls versus seconds. A short passage opens the prepared viewing context through camera distance and light intensity.
- Supplied: room, camera and light. The learner script creates and attaches its own Label3D. It uses no node-path lookups or named scene children.
- Learner actions: change greeting, move the camera nearer and restore it, remove the directional light's contribution and restore it, change increment, move counting between callbacks.
- Return: Point One reuses readiness and develops variables through positions; Transformation uses elapsed time.

The three complete examples create the display in code and remain unchanged in this addition. The comparison baseline is the preceding camera/light lesson in before-course-world.md; earlier versions remain preserved. The introduction now distinguishes a separate desktop study from the shared Ada XR environment. The camera-position exercise is explicitly for desktop, while XR supplies a tracked view. The course-world agreement links the packaged student XR starter and records the full project's existing XR Tools configuration; physical headset checks remain pending. The study scenes contain no authored text displays. No other hall tutorial or final.md was revised. The study's TUTORIAL.md mirrors the canonical tutorial with its local README link.

This is a single lesson for the author to read before the voice is applied elsewhere. The older functional/ch01.md and its numeric taxonomy remain a separate draft; they have not been renumbered or declared aligned by this pass.

Code and lifecycle checks: native-verification.json, including execution on a bare Node3D without a scene file. Camera projection, floor darkening and persistent bright text were checked with rendered frames in view-verification.json; the PNGs show those comparisons. Source checks: verification.json. These checks do not constitute a beginner reading trial.
''', encoding='utf-8')
verification = {'map': 'Point_Zero', 'before_words_including_code': len(before.split()), 'after_words_including_code': len(after.split()), 'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'no_node_path_lookups': True, 'creates_display_in_every_example': True, 'no_scene_authored_displays': True, 'counter_matches_study': True, 'study_tutorial_matches': True, 'download_matches_study': True}
(OUT / 'verification.json').write_text(json.dumps(verification, indent=2) + '\n', encoding='utf-8')
print(json.dumps(verification, indent=2))
