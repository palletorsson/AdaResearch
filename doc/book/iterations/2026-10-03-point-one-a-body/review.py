"""One lesson, matching executable source, an actual room image and its scope."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import os
import re
import xml.etree.ElementTree as ET
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
LESSON = STARTER / 'studies/point_one'
source = ROOT / 'commons/maps/Point_One/tutorial.md'
after = source.read_text(encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', after, re.S)
assert len(blocks) == 3
scripts = {name: (LESSON / (name + '.gd')).read_text(encoding='utf-8') for name in ('position', 'visible', 'solid')}
assert scripts['position'].strip() == blocks[0].strip()
assert scripts['visible'].strip() == blocks[1].strip()
assert scripts['solid'].strip() == (blocks[1].rstrip() + '\n\n' + blocks[2]).strip()
for code in scripts.values():
    assert '$' not in code and 'get_node' not in code and 'load(' not in code
assert 'MeshInstance3D' not in (STARTER / 'point_one.tscn').read_text()
api = {'Vector3': [], 'SphereMesh': ['radius', 'height'], 'MeshInstance3D': ['mesh'], 'Node3D': ['position'], 'StaticBody3D': [], 'SphereShape3D': ['radius'], 'CollisionShape3D': ['shape']}
docs = ROOT.parent / 'godot_reference_4.6/doc/classes'
for cls, members in api.items():
    reference = ET.parse(docs / (cls + '.xml')).getroot()
    assert reference.get('name') == cls
    for member in members:
        assert reference.find("members/member[@name='" + member + "']") is not None, (cls, member)
checks = json.loads((OUT / 'verification.json').read_text())
assert checks['passed']
contract = {
    'map': 'Point_One', 'status': 'written_and_desktop_tested_author_reading_pending',
    'inherits': ['Day Zero room, lights and player', 'Point Zero: Node3D, variable, :=, assignment, .new(), _ready(), add_child()'],
    'introduces': ['Vector3 used as a position', 'float radius and multiplication', 'resource versus node', 'SphereMesh and MeshInstance3D', 'StaticBody3D, CollisionShape3D and SphereShape3D'],
    'actions': ['change an unseen value', 'move and resize a visible marker', 'match and mismatch visible and collision radii', 'walk to compare contact'],
    'defers': ['full coordinate frames and axes', 'grabbing', 'distance', 'arrays and loops', 'mesh tessellation', 'material programming'],
    'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'script_sha256': {name: hashlib.sha256(code.encode()).hexdigest() for name, code in scripts.items()},
    'code_matches_printed_lesson': True, 'api_checked_in_local_godot_4_6_reference': api,
    'canonical_final_changed': False, 'physical_headset_tested': False,
    'note': 'Scope and source checks are not proof of beginner comprehension or a bulk promotion of the old numeric taxonomy.'
}
(OUT / 'lesson-contract.json').write_text(json.dumps(contract, indent=2) + '\n', encoding='utf-8')
(OUT / 'Point_One.tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='before/Point_One/tutorial.md', tofile='commons/maps/Point_One/tutorial.md')), encoding='utf-8')
(OUT / 'Point_One.tutorial.md').write_text(after, encoding='utf-8')
for name, code in scripts.items():
    (OUT / (name + '.gd')).write_text(code, encoding='utf-8')
reading = markdown.markdown(after.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../2026-10-03-ada-xr-starter/index.html#guide'), extensions=['fenced_code'])
reading = reading.replace('<h2>1. Keep a position</h2>', '<figure><a href="room.png"><img src="room.png" alt="Three Point One stations inside the Godot starter: empty space at the first, matching white spheres at the next two"></a><figcaption>Inside the shared starter. Two surfaces look alike; only the last station has a collision boundary.</figcaption></figure><h2>1. Keep a position</h2>')
full_code = ''.join('<details><summary>' + name + '.gd · complete script</summary><pre><code>' + html.escape(code) + '</code></pre><p><a download href="' + name + '.gd">Download this script</a></p></details>' for name, code in scripts.items())
def old_link(match):
    target = match.group(1)
    if '://' in target or target.startswith('#'):
        return match.group(0)
    return '](' + Path(os.path.relpath((source.parent / target).resolve(), OUT)).as_posix() + ')'
old = markdown.markdown(re.sub(r'\]\(([^)]+)\)', old_link, before), extensions=['fenced_code'])
style = '''
*{box-sizing:border-box}body{margin:0;background:#f5f1e9;color:#29282b;font:19px/1.65 Georgia,serif}main{max-width:1150px;margin:auto;padding:30px 26px 70px}header{border-bottom:1px solid #cdc6bd;padding-bottom:22px;font:14px/1.6 system-ui,sans-serif}nav{display:flex;flex-wrap:wrap;gap:12px 25px}a{color:#84445f;text-underline-offset:4px}article{max-width:760px;margin:48px auto}h1{font-size:clamp(32px,4vw,47px);font-weight:normal;line-height:1.18}h2{font-size:29px;font-weight:normal;margin-top:44px}p{margin:0 0 23px}code{font:.84em Consolas,monospace}pre{background:#e9e3db;border-left:3px solid #b87792;padding:22px;overflow-x:auto;font:15px/1.6 Consolas,monospace}pre code{font:inherit}figure{margin:34px -90px}img{width:100%;height:auto;display:block}figcaption,.small{font:14px/1.6 system-ui,sans-serif;color:#5e575b;margin-top:12px}details{margin:28px 0;border-top:1px solid #cdc6bd;padding-top:19px}summary{cursor:pointer;font:17px/1.5 system-ui,sans-serif}details>div{max-width:760px;margin:auto}.download{display:inline-block;background:#733e55;color:white;padding:10px 20px;text-decoration:none;font:16px/1.5 system-ui,sans-serif;border-radius:3px}.lineage{max-width:760px;margin:45px auto;border-top:1px solid #cdc6bd;padding-top:20px}.lineage p{margin:10px 0}a:focus-visible,summary:focus-visible{outline:3px solid #aa577b;outline-offset:4px}@media(max-width:1000px){figure{margin:30px 0}}@media(max-width:650px){main{padding:24px 17px}body{font-size:18px}pre{font-size:13px;padding:14px}}@media print{header,details,.download{display:none}body{background:white;font-size:11pt}figure{margin:20px 0}pre{white-space:pre-wrap}h2{break-after:avoid}}
'''
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point One — give the point a body</title><style>{style}</style></head><body><main><header><p>ADA / ONE TUTORIAL AT A TIME · 3 October 2026</p><nav><a href="#reading">Read Point One</a><a href="#code">Complete scripts</a><a href="#lineage">What it adds</a><a href="#comparison">Earlier lesson</a><a href="Point_One.tutorial.diff">Text diff</a></nav></header><article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the starter with Point One</a></p><p class="small">Open point_one.tscn · Run Current Scene (F6). F5 still opens Day Zero.</p></article><section class="lineage" id="lineage"><h2>What this lesson adds.</h2><p><strong>Inherit:</strong> the working room and player; readiness, a variable, creating a node and adding it.</p><p><strong>Make:</strong> a position, a visible marker and a separate collision shape. Change their values and compare what happens.</p><p><strong>Carry forward:</strong> a point whose construction the student can alter. Coordinates will add holding and reference frames.</p><p class="small">The critical text and museum remain intact. This pass revises tutorial.md and its executable companion.</p></section><section id="code">{full_code}</section><details id="comparison"><summary>The earlier tutorial</summary><div>{old}</div></details><details id="checked"><summary>{len(checks['checks'])} Point One checks passed</summary><div><p>The checks run the actual scripts, including the suggested edits, and move the supplied player through each station using Godot physics. The invisible boundary stops movement independently of the surface and light. The three scripts also create their objects without prepared mesh nodes.</p><p>Desktop collision and the screenshot were checked in Godot 4.6. Physical XR and a beginner reading trial remain to be checked.</p><p><a href="verification.json">Native checks</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="DECISIONS.md">Editorial decisions</a></p></div></details></main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'lesson_words_including_code':len(after.split()),'before_words_including_code':len(before.split()),'code_matches':True,'native_checks':len(checks['checks'])}))
