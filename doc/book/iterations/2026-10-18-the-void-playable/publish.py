"""Publish the tested Void prototype and its native in-scene screenshots."""
from pathlib import Path
import html
import json
import re
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
physics = json.loads((OUT/'checks.json').read_text())
package = json.loads((OUT/'package-checks.json').read_text())
menu = json.loads((OUT/'menu-checks.json').read_text())
receipt = json.loads((OUT/'receipt.json').read_text())
assert physics['passed'] and package['passed'] and menu['passed'] and receipt['passed']
sources = ['game.gd', 'jump.gd', 'walker.gd', 'architecture.gd', 'layout.json', 'void.tscn', 'README.md']
for source in sources:
    shutil.copy2(ROOT/'commons/void'/source, OUT/(source+'.txt'))

def figure(name, title, caption):
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{html.escape(title)}" loading="lazy"></a><figcaption><b>{title}.</b> {caption}</figcaption></figure>'

gallery = figure('roof', 'The roof', 'The same architectural frame now has a player body, jump input and a saved starting point.')
gallery += '<div class="pair">' + figure('descent', 'Inside shaft A', 'Two timber ledges break the six-metre storey into smaller descents. Move in the air to choose the next landing.')
gallery += figure('floor-one', 'Floor 01', 'A safe landing saves this floor. Falling again brings you back here, beside the shaft.') + '</div>'
gallery += figure('floor-two', 'Floor 02', 'The second floor is the end of this test. Left Y returns to the roof for another attempt.')
source_links = ''.join(f'<li><a href="{s}.txt">{s}</a></li>' for s in sources)
body = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The Void — playable descent</title><style>
:root{{color-scheme:dark;--paper:#e9e6dd;--pink:#e6a1b9}}*{{box-sizing:border-box}}body{{margin:0;background:#182128;color:var(--paper);font:18px/1.6 system-ui,sans-serif}}main{{max-width:1240px;margin:auto;padding:48px 28px 90px}}a{{color:var(--pink);text-underline-offset:4px}}.kicker{{font-size:13px;letter-spacing:.14em;text-transform:uppercase;color:#aebdc7}}h1{{font-size:clamp(40px,6vw,78px);line-height:1.05;margin:22px 0}}h2{{font-size:29px;line-height:1.3;margin:45px 0 18px}}.lede{{font-size:24px;max-width:860px}}.route{{display:flex;gap:10px;flex-wrap:wrap;margin:28px 0}}.route span{{padding:10px 18px;background:#2d3b43;border-bottom:2px solid var(--pink)}}.launch{{border:1px solid #65737a;padding:24px;margin:32px 0;background:#222d34}}.launch strong{{font-size:23px}}table{{width:100%;border-collapse:collapse;text-align:left}}td,th{{padding:12px;border-bottom:1px solid #415059}}th{{color:var(--pink);font-weight:600}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}figure{{margin:32px 0}}figure img{{display:block;width:100%;height:auto;background:#26343e}}figcaption{{font-size:15px;color:#c1ccd1;padding-top:12px}}.pair figure{{margin:0}}.note{{font-size:16px;max-width:900px;color:#b8c5cb}}details{{margin:24px 0;padding:18px;border:1px solid #415059}}summary{{cursor:pointer}}code{{font-size:.88em;background:#2a3840;padding:2px 5px;overflow-wrap:anywhere}}li{{margin:7px 0}}footer{{border-top:1px solid #415059;padding-top:24px;margin-top:45px;color:#acbac3;font-size:14px}}@media(max-width:760px){{.pair{{grid-template-columns:1fr}}main{{padding:25px 18px}}.lede{{font-size:20px}}td,th{{font-size:15px;padding:9px}}}}@media print{{body{{background:white;color:black}}main{{padding:0}}a{{color:black}}.pair{{display:block}}figure{{break-inside:avoid}}}}
</style><main>
<div class="kicker">Endless Museum / The Void / 18 October 2026</div>
<h1>A playable descent.</h1>
<p class="lede">Start on the roof. Find a landing in either open shaft. Reach the two floors below. If you die, return to the last floor you reached safely.</p>
<div class="route"><span>Roof · starting checkpoint</span><span>↓ Floor 01 · save on landing</span><span>↓ Floor 02 · descent complete</span></div>
<div class="launch"><strong>Run the project → Main menu → The Void</strong><p>This uses the existing VR staging system. For a desktop test, open <code>commons/void/void.tscn</code> in Godot and press F6. For standalone Quest, export and install the current project through the usual setup.</p></div>
<h2>Controls</h2><table><thead><tr><th>Action</th><th>VR</th><th>Desktop</th></tr></thead><tbody>
<tr><td>Move</td><td>Left stick</td><td>WASD / arrows</td></tr><tr><td>Turn / look</td><td>Head + right stick, 30° snap</td><td>Mouse</td></tr><tr><td>Jump</td><td>Right A or right trigger</td><td>Space</td></tr><tr><td>Retry saved floor</td><td>Right B</td><td>R</td></tr><tr><td>Start again on roof</td><td>Left Y</td><td>T</td></tr><tr><td>Main menu</td><td>Left X</td><td>M</td></tr></tbody></table>
<p class="note">One press makes one jump; holding the button does not jump again on landing. On desktop, Escape releases the mouse; click to capture it again.</p>
<h2>Find the next landing</h2><p>Shaft A has two staggered timber ledges per storey. Shaft B has a wider suspended platform. Both descend to the same main floor. The short drops are survivable; a direct six-metre drop is fatal.</p>
<p>A main floor becomes your checkpoint after a safe landing. Temporary ledges do not save progress, and falling past a floor does not count. Death gives a short fade, places you on the saved floor and clears your falling velocity. Progress lasts for this visit.</p>
{gallery}
<h2>What changed</h2><p>The roof, two shafts, columns and exposed service lines retain the architectural layout. The prototype adds walking, jumping, solid roof rails, landing detection, floor checkpoints and recovery. Floor signs carry the controls. The original <a href="../2026-10-18-the-void-layout/index.html">architectural study</a> remains available.</p>
<h2>What has been tested</h2><ul><li><a href="checks.json">{len(physics['checks'])}/{len(physics['checks'])} native physics checks</a>: real Jolt collisions, both descent routes, fatal impacts, saved floors, rail collision, snap turn, jump/retry buttons and headset-offset preservation.</li><li><a href="package-checks.json">{len(package['checks'])}/{len(package['checks'])} exported-package checks</a>: the same scene works without the documentation folder. Windows PCK using Android export exclusions; this is not an APK test.</li><li><a href="menu-checks.json">{len(menu['checks'])}/{len(menu['checks'])} menu integration checks</a>: the actual menu button routes to this scene, the scene initializes in the project, and global hand/rescue tools are restored on exit.</li></ul>
<p><strong>Still to test in the headset:</strong> the felt depth, landing visibility, comfort during descent, and Quest performance. The automated VR checks use synthetic tracking and controller input with the real XRTools player body. The images above are native Godot views from inside the playable scene, not headset captures.</p>
<details><summary>Implementation and test limits</summary><p>The game inherits XRToolsSceneBase and uses XRTools movement/body code. It suspends the global stuck detector while falling is intentional. Local checkpoints do not alter the museum’s saved progression.</p><p>The existing main menu emits null-material cleanup errors. These reproduce in a <a href="menu-baseline.log">menu-only baseline</a> without loading The Void; the <a href="menu.log">integration log</a> records them too. Void physics, packaging and capture logs have no engine errors.</p><p>Run <code>python tools/test_void_game.py --package --capture --menu</code>. <a href="receipt.json">Source receipt</a> · <a href="physics.log">physics log</a> · <a href="package.log">package log</a> · <a href="menu-receipt.json">menu baseline comparison</a>.</p></details>
<details><summary>Full runtime files</summary><ul>{source_links}</ul></details>
<footer>First playable architecture test. One roof, two floors, two descent routes. The next design decisions should follow a headset playthrough.</footer></main></html>'''
(OUT/'index.html').write_text(body,encoding='utf-8')
for link in re.findall(r'(?:href|src)="([^"]+)"',body):
    if not link.startswith(('http', '#')):
        assert (OUT/link).exists(), link
print(f'Published: {len(physics["checks"])} physics, {len(package["checks"])} package, {len(menu["checks"])} menu checks; local links verified.')
