"""Publish actual staging navigation results and native viewport captures."""
import html
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
run = json.loads((HERE / 'run.json').read_text(encoding='utf-8'))
names = {
    'void': ('The Void', 'Rooftop and two floors'),
    'runner': ('Museum Runner', 'Point / Line course'),
    'shadow': ('Shadow Game', 'Make a crossing'),
    'ladder': ('Biome Ladder', 'First practice stage'),
    'arena': ('Head Arena', 'Biome combat arena'),
    'museum': ('New Game', 'Endless Museum · Primitives / Point Zero'),
    'sequences': ('Sequences', 'Transformation chapter, selected in the embedded panel'),
    'maps': ('Maps', 'Advanced Laboratory / Lab Equipment Simulation, through the grid scene'),
}
results = run['results']
assert {r['route'] for r in results} == set(names), 'Publish only a complete eight-route run'
checks = sum(len(r['checks']) for r in results)
passed = sum(c['passed'] for r in results for c in r['checks'])
nav = sum(r['navigation_passed'] for r in results)
clean = sum(r['shutdown_clean'] for r in results)
cards = []
rows = []
for r in results:
    key = r['route']
    name, detail = names[key]
    status = 'Pass' if r['navigation_passed'] else 'Fail'
    rows.append(f'<tr><td><a href="#{key}">{name}</a></td><td>{detail}</td><td>{status}</td><td>{"Clean" if r["shutdown_clean"] else "Fails at shutdown"}</td></tr>')
    assertions = ''.join(f'<li>{"✓" if c["passed"] else "✕"} {html.escape(c["name"])}</li>' for c in r['checks'])
    selector = f'<a href="{key}-selector.png">View selector screenshot</a> · ' if (HERE / f'{key}-selector.png').exists() else ''
    cards.append(f'''<article id="{key}"><header><span class="tag">{status} · entry / return / reopen</span><h2>{name}</h2><p>{detail}</p></header>
      <a href="{key}-game.png"><img src="{key}-game.png" alt="Native Godot desktop view after entering {name}" loading="lazy"></a>
      <div class="body"><p>{selector}<a href="{key}.json">Assertions</a> · <a href="{key}.log">Full engine log</a></p>
      <details><summary>{len(r['checks'])} navigation assertions</summary><ul>{assertions}</ul></details></div></article>''')
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Desktop test · the real VR game menu</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#151717;color:#e8e6df;font:17px/1.6 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:52px 26px 100px}h1{font-size:clamp(32px,5vw,60px);line-height:1.1;max-width:850px}h2{font-size:25px;margin:.4em 0}p{max-width:880px}a{color:#f6b5cd}small,.muted{color:#a8b2b0}.eyebrow{letter-spacing:.13em;text-transform:uppercase;font-size:12px}.stats{display:flex;gap:20px;flex-wrap:wrap;margin:35px 0}.stat{background:#232827;padding:18px 24px;min-width:190px}.stat b{font-size:32px;display:block}.note{padding:18px 23px;border-left:4px solid #e3ad65;background:#342a20;max-width:1000px}.hero{width:100%;max-width:900px;display:block;border:1px solid #3b4341;margin:30px 0}table{width:100%;border-collapse:collapse;margin:32px 0 50px;font-size:15px}td,th{text-align:left;padding:12px;border-bottom:1px solid #394240}th{color:#9eb4ae}article{background:#202625;scroll-margin-top:24px}article header,.body{padding:22px}article img{width:100%;height:auto;display:block}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.tag{color:#b5d3bf;text-transform:uppercase;font-size:11px;letter-spacing:.08em}details{font-size:14px}summary{cursor:pointer}ul{padding-left:22px}pre{overflow:auto;background:#101313;padding:20px;font-size:13px}footer{margin-top:60px;border-top:1px solid #394240;padding-top:25px}@media(max-width:800px){.grid{grid-template-columns:1fr}table{display:block;overflow:auto}main{padding:30px 18px}}
</style><main><div class="eyebrow">Ada Research · 18 October 2026 · native Godot test</div>
<h1>The VR menu, tested with a mouse.</h1>
<p>The real staging scene opens each game destination on desktop. The test clicks the 3D menu, waits for the destination to become visible, checks its active camera, returns through the game/staging return function, and clicks The Void again.</p>
STATS
<div class="note"><strong>Navigation passes; shutdown is not clean.</strong> Every tested route reaches its destination and can return and reopen. The process then exits with Windows access violation <code>0xC0000005</code>, after material-null and resource-leak messages. A menu-only run reproduces this before entering any game; an autoload-only run exits cleanly. The cause has not been established. This report does not treat those exits as passing tests.</div>
<h2>What changed</h2><ul>
<li>Desktop mouse clicks now operate the existing 3D menu buttons and embedded panels. Button labels are clickable; the sequence panel accepts the mouse wheel.</li>
<li>Untracked VR pointers are disabled on desktop so their default rays cannot dwell-select a game.</li>
<li>Hidden panels no longer block the mouse ray.</li>
<li>The map-transition listener now accepts standalone games with no transition dictionary. This fixes the Maps → menu → Void callback errors.</li>
<li>An explicit <code>--desktop</code> launch skips XR Tools headset initialization. Pair it with Godot’s <code>--xr-mode off</code>.</li></ul>
<a href="void-menu.png"><img class="hero" src="void-menu.png" alt="Actual main menu in Godot, with desktop input enabled"></a>
<p><strong>Visual follow-up:</strong> Point Zero loads, but its initial forward view is occupied by a red-and-white striped surface in this capture. Transformation also looks very bright. The images preserve what the player actually sees; reaching a scene is not a certificate that its arrival, lighting, or gameplay is finished.</p>
<table><thead><tr><th>Entry</th><th>Destination tested</th><th>Navigation</th><th>Application exit</th></tr></thead><tbody>ROWS</tbody></table>
<div class="grid">CARDS</div>
<footer><h2>Reproduce</h2><pre>python tools/test_game_menu.py
# One route:
python tools/test_game_menu.py void
# Without rendering:
python tools/test_game_menu.py void --headless</pre>
<p>For a normal desktop session, launch the project with <code>--xr-mode off -- --desktop</code>, then click a game title.</p>
<p>The test uses the project’s actual sources and autoloads in a junction-based mirror. Only the application name changes, giving it separate <code>user://</code> saves. New Game does not clear your normal progression. Screenshots come from Godot’s rendered viewport.</p>
<p>Scope: all six direct game entries, one museum chapter selected through Sequences, and one individual map selected through Maps. Return was invoked through the real return function, not a physical controller or exit button. This does not certify every map, combat, jumping, headset input, or an Android export. Settings and Quit interactions were not part of this navigation pass.</p>
<p><a href="run.json">Complete results, including exit status</a> · <a href="menu_warm.log">Menu-only shutdown log</a> · <a href="boot.log">Autoload-only baseline</a></p></footer></main></html>'''
stats = f'<div class="stats"><div class="stat"><b>{nav}/8</b>routes navigate</div><div class="stat"><b>{passed}/{checks}</b>navigation assertions</div><div class="stat"><b>{clean}/8</b>clean process exits</div></div>'
page = page.replace('STATS', stats).replace('ROWS', ''.join(rows)).replace('CARDS', ''.join(cards))
(HERE / 'index.html').write_text(page, encoding='utf-8')
print(f'Published {nav}/8 navigation routes, {clean}/8 clean exits.')
