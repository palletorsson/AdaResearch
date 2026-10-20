"""A review of the saved floor and native verification, with real screenshots."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"doc/book/iterations/2026-10-20-carousels-and-scale"
counts={}
for name in ["tests","rotation-regression"]:
    result=json.loads((OUT/name/"checks.json").read_text())
    assert result["passed"]
    counts[name]=len(result["checks"])
editor=json.loads((OUT/"editor-checks.json").read_text())
assert editor["passed"]
figures=[
("carousel-floor","A room of rotating layers","Five original profiles, an all-together turn and alternating directions. The clear centre connects the two arrivals to the Scale bridge."),
("seven-carousels","Inside floor 17","The tower floor stays 42 × 18 m. The enlarged carousels are 5.7–7 m across and 3.4–5.4 m tall, with the shafts retained."),
("scale-chamber-small","Before taking the bottle","A 4 × 4 m room on a fixed 20 × 22 m foundation. The tall frame reserves the space the room will need."),
("scale-chamber-large","After taking the bottle","The same viewpoint. Only the original Room grows fourfold: 16 × 16 m and 12.8 m high. The foundation, return path and reference frame stay the same."),
("scale-before-inside","Enter the original encounter","The original bottle, crystal figure, food tower and tiny gold doorway."),
("scale-on-the-plate","Stand on the food tower","The visitor keeps their size. Taking the bottle places their feet on the highest porcelain plate."),
("scale-after-inside","The familiar objects become architecture","Walk down all thirteen serving plates, around the front and east side of the figure, and out through the enlarged doorway."),
("editor","Arrange it in the editor","Editor view before the carousel size increase. Seven separate carousel placements; the room, bridge and foundation move together as one assembly. Whole floor frames the exterior chamber too."),
]
gallery="\n".join(f'<figure id="{key}"><img src="images/{key}.png" alt="{title}" loading="lazy"><figcaption><strong>{title}.</strong> {caption}</figcaption></figure>' for key,title,caption in figures)
html=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Seven carousels and Drink Me · The Void</title>
<style>
*{{box-sizing:border-box}}body{{margin:0;background:#17161d;color:#efe7e8;font:18px/1.65 system-ui,sans-serif}}
main{{max-width:1250px;margin:auto;padding:50px 30px}}header{{max-width:850px;margin-bottom:48px}}
h1{{font-size:clamp(36px,5vw,66px);line-height:1.06;letter-spacing:-.04em}}small{{color:#d1a5d5;letter-spacing:.1em}}
a{{color:#ecc5ef}}nav{{display:flex;gap:12px;flex-wrap:wrap;margin:28px 0}}nav a{{padding:10px 16px;border:1px solid #77637e;border-radius:6px;text-decoration:none}}
figure{{margin:40px 0 60px}}img{{display:block;width:100%;height:auto;border-radius:8px}}figcaption{{max-width:940px;color:#cfc4d0;margin-top:12px}}strong{{color:#fff}}
.checks{{background:#24212c;padding:24px;border-left:3px solid #a1d2b0;max-width:950px}}li{{margin:7px 0}}
</style><main><header><small>THE VOID · FLOOR 17 · 20 OCTOBER 2026</small>
<h1>Seven carousels.<br>A room that outgrows the tower.</h1>
<p>Descend from Rotation into seven spinning configurations, then cross the bridge to the original <em>Drink Me</em> encounter. Its tall exterior foundation gives the fourfold room space beside the tower.</p>
<nav><a href="http://localhost:3003/voxel-editor?mode=void&amp;floor=17">Arrange floor 17</a>
<a href="http://localhost:3003/lab-editor?mode=void&amp;floor=17">Open lab editor</a>
<a href="#scale-chamber-small">Compare the two sizes</a><a href="#verification">Verification</a></nav>
<p>Restart The Void to load the shared saved layout. Desktop and VR use the same placements. The web editor shows static native models; the carousels spin and the bottle works in Godot.</p></header>
{gallery}
<section id="verification" class="checks"><strong>Verified in the real Godot runtime</strong>
<ul><li>{counts["tests"]} checks on this floor, using the actual desktop body and synthetic XR tracking with the museum player rig.</li>
<li>{counts["rotation-regression"]} checks from the earlier Rotation regression run, including the wheel descent and downward Boolean passage onto this floor.</li>
<li>{len(editor["checks"])} checks from the earlier editor/model/API run: all nine models, copy/move/turn, shared save validation and Desktop backup.</li>
<li>Actual bottle pickup, unchanged body size, the thirteen-plate descent, both doorways, exterior return route and restart.</li>
<li>The tall chamber remains owned by floor 17; the surrounding tower still uses its normal floor and fall rules.</li></ul>
<p>Physical headset comfort and performance have not been tested. Screenshots above are native Godot captures; the last is the browser editor. The earlier Rotation layout and the tutorial/final texts were retained. Concurrent Point Trace edits were preserved.</p>
<p><a href="tests/checks.json">Floor tests</a> · <a href="rotation-regression/checks.json">Rotation tests</a> · <a href="editor-checks.json">Editor checks</a> · <a href="placed-floor.json">Saved placement snapshot</a></p></section>
</main></html>'''
(OUT/"index.html").write_text(html,encoding="utf8")
if (OUT/"enlargement-receipt.json").exists():
    html=html.replace('</section>', '<p>Enlargement update: 62 desktop/synthetic-XR floor checks passed. The rendered capture completed its route checks but logged a roof-grid texture import error; the editor recheck was unavailable because localhost:3003 was stopped.</p></section>')
    (OUT/"index.html").write_text(html,encoding="utf8")
print("Report saved:",OUT/"index.html")
