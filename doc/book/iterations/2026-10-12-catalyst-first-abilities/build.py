"""Publish local evidence for the isolated first-abilities playtest."""
from pathlib import Path
import hashlib
import html
import json
import os
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
EVIDENCE = ROOT / "ada_run/encounter_pilot/Catalyst_First_Abilities"
receipt = json.loads((EVIDENCE / "report.json").read_text(encoding="utf-8"))
assert receipt["passed"], receipt["failures"]
count = len(receipt["checks"])
sources = [
    "commons/hazards/catalyst_counterpart/proving_ground.gd",
    "commons/hazards/catalyst_counterpart/charged_rod.gd",
    "commons/hazards/catalyst_counterpart/trial_trace.gd",
    "commons/hazards/catalyst_counterpart/flying_skull.gd",
    "commons/testing/catalyst_first_abilities.tscn",
    "commons/testing/catalyst_counterpart_trial.gd",
    "commons/testing/catalyst_first_abilities_plan.json",
    "commons/maps/Catalyst_First_Abilities/map_data.json",
    "tools/probes/catalyst_first_abilities.gd",
]
receipt["source_sha256"] = {s: hashlib.sha256((ROOT / s).read_bytes()).hexdigest() for s in sources}
(HERE / "checks.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
shots = [
    ("01-charge-and-draw", "Charge the rod", "Take the rod from the wall. Hold its tip inside the sphere's light for a quarter of a second. The tip starts to glow."),
    ("01b-a-line-in-the-air", "A movement becomes a line", "Move the charged rod while holding it. The existing Trace recorder keeps separated hand positions. Release the rod to keep the drawing."),
    ("02-line-kept-head-waiting", "Meet the head at rest", "The original Dürer apparatus is here. A burning head waits in the seated figure's place. This is Ada's proposed substitution in the test map."),
    ("02b-your-kept-line", "Your line arrives before you", "The next plinth shows a fitted copy of your own recorded intervals. It keeps the source positions intact. The pictured line was made by supplied test-hand poses through the real recorder."),
    ("03-head-and-locked-line", "The still head begins to move", "Take the black sphere and press BEGIN. The same head flies into the arena. Its line warns of a charge, then stays fixed: step aside or use the held sphere's trigger to interrupt it."),
    ("04-the-way-opens", "An interruption makes room", "A real catalyst projectile opens the gate on contact with the head. The head remains, resting. Walking through completes this encounter."),
]
figures = []
for name, title, caption in shots:
    shutil.copy2(EVIDENCE / f"{name}.png", HERE / f"{name}.png")
    figures.append(f'<article id="{name}"><a href="{name}.png"><img src="{name}.png" alt="{html.escape(title)} — native Godot museum capture" loading="lazy"></a><div><h2>{title}</h2><p>{caption}</p></div></article>')
scene_link = Path(os.path.relpath(ROOT / sources[4], HERE)).as_posix()
readme_link = Path(os.path.relpath(ROOT / "commons/maps/Catalyst_First_Abilities/technical.md", HERE)).as_posix()
checks = "".join(f'<li>✓ {html.escape(c["name"])}</li>' for c in receipt["checks"])
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Catalyst · First Abilities</title><style>
:root{{color-scheme:light;--ink:#20231f;--paper:#f3f0e8;--line:#d2d1c5}}*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}}main{{max-width:1320px;margin:auto;padding:45px 32px}}header{{max-width:880px;margin-bottom:35px}}.eyebrow{{font:12px/1.4 monospace;letter-spacing:.16em;text-transform:uppercase}}h1{{font:clamp(42px,6vw,76px)/1.03 Georgia,serif;margin:18px 0}}h2{{font:27px/1.2 Georgia,serif;margin:0 0 14px}}a{{color:inherit;text-underline-offset:4px}}.lead{{font-size:22px}}.route{{border-block:1px solid var(--line);padding:18px 0;margin:28px 0;font-weight:600}}.launch{{padding:24px;background:#e2e5da;border:1px solid #c5cabb;margin-bottom:32px}}.cards{{display:grid;grid-template-columns:1fr 1fr;gap:26px}}article{{border:1px solid var(--line);background:#faf9f4}}article img{{width:100%;display:block;aspect-ratio:1.6;object-fit:cover}}article>div{{padding:24px}}article p{{margin:0}}.review{{margin-top:42px;max-width:900px}}code{{font-size:14px;overflow-wrap:anywhere}}details{{margin-top:25px;border-top:1px solid var(--line);padding-top:20px}}summary{{cursor:pointer;font-weight:600}}details ul{{columns:2;font-size:14px;list-style:none;padding:0}}details li{{break-inside:avoid;margin-bottom:9px}}footer{{margin-top:40px;font-size:14px;color:#62665b}}@media(max-width:750px){{main{{padding:26px 18px}}.cards{{grid-template-columns:1fr}}details ul{{columns:1}}}}
</style><main><header><p class="eyebrow">Endless Museum / isolated test map / 12 October 2026</p><h1>Make a mark.<br>Make room to pass.</h1><p class="lead">The first connected catalyst encounter: a power becomes useful for drawing, keeping something, and defending a passage.</p><p>Three rooms inside the existing museum shell, using the actual pen, recorder, sphere and counterpart. This is a playable prototype outside the teaching spine.</p></header>
<p class="route">Charge → draw → keep → meet → defend → pass</p>
<section class="launch"><h2>Try it in VR</h2><p>Open <a href="{scene_link}"><code>catalyst_first_abilities.tscn</code></a> in Godot and press <strong>F6</strong> with OpenXR available. The scene uses the museum's existing XR rig. The test begins with the first ability supplied.</p><p>Take the rod from the wall, charge its tip, draw and release. Walk to the next room. Take the black sphere at the arena and press BEGIN. Aim with the hand holding it; trigger sends a form. RESET TRIAL is available at the entrance and arena. Released tools return to their mounts.</p><p><strong>{count}/{count} automated checks passed.</strong> Headset reach, timing, aiming and enjoyment remain for the human playtest. <a href="{readme_link}">Implementation and launch notes</a>.</p></section>
<section class="cards">{''.join(figures)}</section>
<section class="review"><h2>What this version lets us judge</h2><p>Does charging feel like gaining an ability? Does finding your own line in the next room give the power continuity? Does the waiting head feel different when it starts to move? Is opening a passage enough reason to fire?</p><p>Contact currently records a touch, without health damage or forced movement. One interruption ends the attack and opens the passage. The head survives; becoming a companion is still a design proposal. This test does not yet represent all 25 sequences.</p><p>The drawing is local to this trial. The main Trace → Grid record, curriculum order and book texts are unchanged. Reset clears this trial's drawing, charge, projectiles, counters and gate state.</p>
<details><summary>Read the {count} engine checks</summary><ul>{checks}</ul><a href="checks.json">Receipt with source hashes</a></details></section>
<footer>All six images are native captures inside the running Godot museum. Automated inputs exercise the actual XRTools pickup and projectile paths; these captures are not headset evidence.</footer></main></html>'''
(HERE / "index.html").write_text(page, encoding="utf-8")
print(f"Built {HERE / 'index.html'} — {count} checks, {len(shots)} museum photographs")
