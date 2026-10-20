"""Publish an architectural proposal with native Godot views and measured diagrams."""
from pathlib import Path
import html
import json
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
spec = json.loads((ROOT / "commons/void/layout.json").read_text(encoding="utf-8"))
checks = json.loads((OUT / "checks.json").read_text(encoding="utf-8"))
receipt = json.loads((OUT / "receipt.json").read_text(encoding="utf-8"))
assert checks["passed"] and receipt["exit_code"] == 0 and not receipt["engine_errors"]
count = len(checks["checks"])

def svg_start(title, width, height):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img"><title>{title}</title>',
            '<style>text{font-family:Arial,sans-serif;fill:#e9e5dc;font-size:16px}.small{font-size:12px;fill:#aeb6ba}</style>',
            f'<rect width="{width}" height="{height}" fill="#1e252b"/>']

def rect(parts, x, y, w, h, fill, extra=""):
    parts.append(f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" fill="{fill}" {extra}/>')

def text(parts, x, y, value, extra=""):
    parts.append(f'<text x="{x:g}" y="{y:g}" {extra}>{html.escape(value)}</text>')

# Plan in metres at 20 px/m. All architectural dimensions come from layout.json.
parts = svg_start("The Void — floor plan", 900, 570)
scale = 20
px = lambda x: 100 + (x + spec["width"] / 2) * scale
pz = lambda z: 95 + (z + spec["depth"] / 2) * scale
rect(parts, 100, 95, spec["width"] * scale, spec["depth"] * scale, "#b8b3a9")
for shaft in spec["shafts"]:
    rect(parts, px(shaft["x"]-spec["shaft_width"]/2), pz(-spec["shaft_depth"]/2), spec["shaft_width"]*scale, spec["shaft_depth"]*scale, "#1e252b", 'stroke="#d77894" stroke-width="2"')
    text(parts, px(shaft["x"]), pz(0)-8, "SHAFT " + shaft["name"], 'text-anchor="middle"')
    text(parts, px(shaft["x"]), pz(0)+16, "5 × 6 m", 'text-anchor="middle" class="small"')
for x in spec["column_x"]:
    for z in spec["column_z"]:
        rect(parts, px(x)-9, pz(z)-9, 18, 18, "#333d44")
for x in spec["service_x"]:
    rect(parts, px(x)-4, pz(spec["service_z"])-5, 8, 10, "#6c9cae")
    rect(parts, px(x)+5, pz(spec["service_z"])-5, 4, 10, "#d77894")
parts.append(f'<path d="M{px(-6.5)} {pz(-4.2)} V{pz(7)} M{px(6.5)} {pz(-4.2)} V{pz(7)}" fill="none" stroke="#678795" stroke-width="3" stroke-dasharray="7 5"/>')
text(parts, 400, 65, "30 m", 'text-anchor="middle"')
text(parts, 45, 280, "18 m")
text(parts, 400, 260, "OPEN WORK FLOOR", 'text-anchor="middle" style="fill:#263138;font-size:16px"')
text(parts, 400, 285, "Walls and artifacts can vary.", 'text-anchor="middle" style="fill:#38454c;font-size:13px"')
parts.append('<path d="M750 180 H680 M750 340 H640" fill="none" stroke="#aeb6ba"/>')
text(parts, 758, 175, "COLUMN", 'class="small"')
text(parts, 758, 193, "0.9 × 0.9 m", 'class="small"')
text(parts, 758, 335, "SERVICE", 'class="small"')
text(parts, 758, 353, "BRANCH", 'class="small"')
text(parts, 100, 505, "Two permanent voids. Many possible arrangements between them.")
text(parts, 100, 532, "Plan of the frame; temporary landings omitted. Dashed lines: overhead service branches.", 'class="small"')
parts.append('</svg>')
(OUT / "floor-plan.svg").write_text("\n".join(parts), encoding="utf-8")

# Section: rear columns and proposed ledges projected for spatial understanding.
parts = svg_start("The Void — vertical section and proposed landings", 900, 550)
sx = lambda x: 110 + (x + 15) * 20
sy = lambda y: 105 - y * 22
for x in spec["column_x"]:
    rect(parts, sx(x)-9, sy(2), 18, 17*22, "#38424b")
for x in spec["service_x"]:
    rect(parts, sx(x), sy(1), 4, 15*22, "#6c9cae")
for index, y in enumerate(spec["levels"]):
    cursor = -15
    for shaft in spec["shafts"]:
        left = shaft["x"] - 2.5
        rect(parts, sx(cursor), sy(y), (left-cursor)*20, spec["slab_thickness"]*22, "#b8b3a9")
        cursor = shaft["x"]+2.5
    rect(parts, sx(cursor), sy(y), (15-cursor)*20, spec["slab_thickness"]*22, "#b8b3a9")
    text(parts, 745, sy(y)+5, ["ROOF  /  0 m", "MAP 01  /  −6 m", "MAP 02  /  −12 m"][index], 'class="small"')
    if index < 2:
        rect(parts, sx(-9.3), sy(y-2), 36, 5, "#caa367")
        rect(parts, sx(-12.5), sy(y-4), 36, 5, "#caa367")
        rect(parts, sx(8.3), sy(y-3), 68, 5, "#d77894")
        parts.append(f'<path d="M{sx(-7.5)} {sy(y)-3} L{sx(-8.4)} {sy(y-2)-7} L{sx(-11.6)} {sy(y-4)-7} L{sx(-13)} {sy(y-6)-3}" fill="none" stroke="#caa367" stroke-width="2" stroke-dasharray="5 5"/>')
text(parts, sx(-10), 35, "A  /  STAGGERED", 'text-anchor="middle"')
text(parts, sx(10), 35, "B  /  SUSPENDED", 'text-anchor="middle"')
text(parts, 110, 475, "The frame continues down. The route changes.")
text(parts, 110, 502, "Projected section; landing positions are proposals, not tested jump trajectories.", 'class="small"')
parts.append('</svg>')
(OUT / "section.svg").write_text("\n".join(parts), encoding="utf-8")

files = receipt["source_files"] + ["tools/test_void_layout.py"]
links = []
for relative in files:
    dest = OUT / "sources" / (relative + ".txt")
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / relative, dest)
    links.append(f'<li><a href="sources/{relative}.txt">{relative}</a></li>')

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Void — architectural layout</title><style>
:root{color-scheme:dark;--bg:#171d22;--ink:#e9e5dc;--muted:#aeb6ba;--pink:#e5a3b9}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.65 system-ui,sans-serif}main{max-width:1230px;padding:40px 28px 90px;margin:auto}nav{display:flex;flex-wrap:wrap;gap:24px;font-size:14px;margin-bottom:55px}a{color:var(--pink)}.kicker{font-size:12px;letter-spacing:.16em;text-transform:uppercase;color:var(--muted)}h1{font-size:clamp(46px,7vw,88px);line-height:1.04;letter-spacing:-.045em;font-weight:500;max-width:900px;margin:20px 0 25px}.lead{font-size:23px;max-width:850px;color:#c5cdd0}h2{font-weight:500;font-size:32px;line-height:1.2;margin:60px 0 18px}h3{font-weight:500;font-size:23px;line-height:1.3}p{max-width:860px}img{width:100%;display:block;border:1px solid #39424a}figure{margin:28px 0}figcaption,.small{font-size:14px;line-height:1.6;color:var(--muted)}figcaption{margin-top:10px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:26px}.pair p{color:#c2c8ca}.pair figure{margin:0}.note{padding:22px 26px;border-left:3px solid var(--pink);background:#242c33;margin:28px 0}.diagram{background:#1e252b}table{border-collapse:collapse;width:100%;margin:25px 0}td,th{text-align:left;vertical-align:top;padding:14px 16px;border-bottom:1px solid #3c464d}th{color:var(--muted);font-size:13px;text-transform:uppercase;letter-spacing:.05em}td:first-child{width:25%}code{font-size:14px;overflow-wrap:anywhere}.files{font-size:14px}section{scroll-margin-top:24px}@media(max-width:740px){main{padding:24px 18px}.pair{grid-template-columns:1fr}.lead{font-size:20px}td,th{padding:10px 8px}.files{padding-left:18px}}
</style></head><body><main>
<nav><a href="#layout">The frame</a><a href="#descent">The descent</a><a href="#floor">Inside a floor</a><a href="#next">What to test</a><a href="#files">Model &amp; evidence</a></nav>
<div class="kicker">Endless Museum / The Void / 18 October 2026 / architecture study</div>
<h1>There is a floor<br>below you.</h1>
<p class="lead">A skyscraper under construction. You arrive on its roof. Each map occupies a floor; finding a way down becomes part of the encounter.</p>
<figure><a href="overview.png"><img src="overview.png" alt="Native Godot model showing three concrete floor slabs, two continuous shafts, eight aligned columns, and temporary platforms"></a><figcaption>Actual Godot model: rooftop and two floors from a proposed taller tower. This is an architectural study. Player movement and death have not been implemented here.</figcaption></figure>
<section id="layout"><h2>A recognisable frame, open to change.</h2><p>The columns, floor edges and service risers help you understand where you are. Within that frame, a map can be sparse, partitioned, crowded with experiments or altered by the player. The shafts stay in the same positions as you descend.</p>
<figure class="diagram"><img src="floor-plan.svg" alt="Measured plan: a 30 by 18 metre floor with two 5 by 6 metre shafts at opposite ends"></figure>
<div class="pair"><article><h3>Keep the frame.</h3><p>Floor slabs, two continuous shaft openings, eight aligned columns and vertical pipe and cable routes. Twelve empty attachment points show where artifacts could meet the columns across these three levels.</p></article><article><h3>Change the encounter.</h3><p>Temporary landings, bridges, platforms, partitions, light and artifact placement. These are separate model elements. Neither shaft is permanently assigned as the entrance or exit.</p></article></div>
<div class="note"><strong>Working dimensions:</strong> 30 × 18 m per floor; 6 m between floors; 0.36 m slab thickness; 5 × 6 m shaft openings; 0.9 m square columns. These are game-space proposals, not structural engineering specifications. Reach, scale and travel time still need player testing.</div></section>
<section id="descent"><h2>Look down before committing.</h2><div class="pair"><figure><a href="roof.png"><img loading="lazy" src="roof.png" alt="The rooftop, exposed reinforcing rods and the first open shaft"></a><figcaption>The roof introduces the construction frame and the open edge.</figcaption></figure><figure><a href="shaft.png"><img loading="lazy" src="shaft.png" alt="Looking down shaft A, past staggered timber platforms toward the floor below"></a><figcaption>An overlook into shaft A. Platforms occupy part of the opening; the view continues past them.</figcaption></figure></div>
<figure class="diagram"><img loading="lazy" src="section.svg" alt="Section diagram comparing staggered ledges in shaft A with suspended landings in shaft B"></figure>
<p>Shaft A proposes smaller staged descents. Shaft B proposes a wider suspended landing. Their contrasting arrangements give us something concrete to compare. The first playable test must establish whether their distances are reachable and whether the choice is interesting.</p>
<p><strong>Keep a view beyond the next landing.</strong> A platform that fills the shaft would hide the next floor and turn the descent into a sequence of enclosed steps. The opening should let you anticipate somewhere you have not reached.</p></section>
<section id="floor"><h2>The building can carry the experiments.</h2><figure><a href="floor.png"><img loading="lazy" src="floor.png" alt="Eye-level view inside floor one: large columns, service pipes, open shaft and suspended platform"></a><figcaption>Floor 01, at eye height. Pipes and cable trays branch beneath the slab. Their function is currently architectural; no power or fluid simulation is connected.</figcaption></figure>
<div class="pair"><article><h3>A floor remains a place to stay.</h3><p>The descent supplies a reason to investigate the room. It should also leave space to stop, touch an artifact and read. A student should be able to examine an experiment without a timer forcing the next jump.</p></article><figure><a href="partition.png"><img loading="lazy" src="partition.png" alt="The same floor with a removable partition added"></a><figcaption>The same frame with one optional wall. The wall can be toggled in the model.</figcaption></figure></div>
<table><thead><tr><th>Returning object</th><th>Possible role here — later work</th></tr></thead><tbody><tr><td>Sphere / point</td><td>Drop it into the shaft to investigate the space below. Later, carry it to an artifact or use it as a catalyst.</td></tr><tr><td>Stick / line</td><td>A rail, beam or adjustable bridge: its length and orientation could change what is reachable.</td></tr><tr><td>Cube / body</td><td>A movable step, load or counterweight. The same object returns with another use.</td></tr></tbody></table><p class="small">These object behaviours are proposals. No artifacts have been transplanted or rewritten in this architectural pass.</p></section>
<section id="next"><h2>What this changes in the museum.</h2><p>The existing museum streams halls along +Z and has a fixed-height fall rescue. A vertical version needs floor identity and landing-based checkpoints. Simply lowering each existing hall would leave the old rescue and streaming rules working against the descent.</p>
<table><thead><tr><th>Keep</th><th>Develop for The Void</th></tr></thead><tbody><tr><td>Map identity and spine order</td><td>Associate each map with a floor. Fit its selected artifacts into the frame; do not shrink whole existing halls indiscriminately.</td></tr><tr><td>Existing artifact scenes</td><td>Give each placement a floor, position and attachment role. Preserve the artifact's own interaction logic.</td></tr><tr><td>Player rigs and interactions</td><td>Test first-person descending and recovery. Jump tuning and VR comfort require separate play tests.</td></tr><tr><td>Bounded streaming</td><td>Keep continuous shaft and landing collision around the player. Load nearby floor content without leaving a hole in the architecture.</td></tr></tbody></table>
<div class="note"><strong>First playable question:</strong> can I see a landing, judge a risk and choose how to reach it?<br>Test one complete descent before adding many floors. A missed jump should return the player quickly to the last stable floor. The death rule must allow intended descents and distinguish them from uncontrolled falls.</div>
<p>The next design decision is the balance between a cautious route and a faster, more demanding one. It should be learned from movement through this space. The diagrams alone cannot tell us whether the game is fun.</p></section>
<section id="files"><h2>Model and evidence.</h2><p><strong>CHECK_COUNT / CHECK_COUNT checks passed.</strong> Godot confirmed the slab collisions, continuous openings, aligned columns, optional-wall collision and saved views. The test runs exact copies of the model source in a small isolated project. No player, jump, death, headset or vertical-streaming test is claimed.</p>
<p>To inspect it in Godot, open <code>commons/void/layout_viewer.tscn</code> and use <strong>F6</strong>. Keys <strong>1–5</strong> change views; <strong>P</strong> adds or removes the sample wall. This viewer is not a VR staging scene.</p>
<p><a href="checks.json">Geometry checks</a> · <a href="receipt.json">Run receipt</a> · <a href="engine.log">Godot log</a> · <a href="plan.png">Native overhead view</a></p><ul class="files">FILE_LINKS</ul>
<p class="small">Basis: Palle's brief and supplied “Design the Void Game” PDF. Dimensions, material choices and temporary landings are new proposals. The main museum, its map order, tutorials and existing game modes are unchanged.</p></section>
</main></body></html>'''
page = page.replace("CHECK_COUNT", str(count)).replace("FILE_LINKS", "".join(links))
(OUT / "index.html").write_text(page, encoding="utf-8")
print(OUT / "index.html")
