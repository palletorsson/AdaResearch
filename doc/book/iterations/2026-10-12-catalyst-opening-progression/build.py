"""Build a review of the connected opening from native Godot test evidence."""
from pathlib import Path
import hashlib
import html
import json
import os
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
EVIDENCE = ROOT / "ada_run/encounter_pilot/Catalyst_Opening_Progression"
receipt = json.loads((EVIDENCE / "report.json").read_text(encoding="utf-8"))
assert receipt["passed"], receipt["failures"]
sources = [
    "commons/hazards/catalyst_counterpart/opening_progression.gd",
    "commons/hazards/catalyst_counterpart/progression_point.gd",
    "commons/hazards/catalyst_counterpart/practice_receiver.gd",
    "commons/hazards/catalyst_counterpart/proving_ground.gd",
    "commons/hazards/catalyst_counterpart/charged_rod.gd",
    "commons/hazards/catalyst_counterpart/trial_trace.gd",
    "commons/hazards/catalyst_counterpart/flying_skull.gd",
    "commons/hazards/becoming_catalyst/first_catalyst_ability.gd",
    "commons/artifacts/drag_point_target/first_catalyst_field.gd",
    "commons/artifacts/ignorance_gallery/resolution_catalyst.gd",
    "commons/testing/catalyst_counterpart_trial.gd",
    "commons/testing/catalyst_opening_progression.tscn",
    "commons/testing/catalyst_opening_progression_plan.json",
    "commons/maps/Catalyst_Opening_Progression/map_data.json",
    "tools/probes/catalyst_opening_progression.gd",
]
receipt["source_sha256"] = {s: hashlib.sha256((ROOT / s).read_bytes()).hexdigest() for s in sources}
(HERE / "checks.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
count = len(receipt["checks"])
shots = [
    ("01-the-first-point", "01 / Carry → acquire", "Take the point into the hollow field", "The opening uses the existing PointBody and acquisition field. First pickup does not simplify the surface or fire. Only this point grants the local hand ability."),
    ("02-form-between-hands", "02 / Acquire → form", "Bring empty hands together", "A black sphere appears between the small hand glows. Separating the hands dismisses its form; the ability remains. This capture uses supplied hand poses, without rendered hands."),
    ("03-charge-and-draw", "03 / Form → trace", "Give the light a tip", "Take the existing pen from its wall mount. Hold its tip in the light, draw and release. The charged tip and distance filter feed the real Trace recorder. The pictured gesture was supplied by the test."),
    ("04-kept-line-waiting-head", "04 / Trace → kept record", "Something you made goes ahead", "The next plinth displays your recorded intervals. The source positions stay intact. The burning head waits in Ada's Dürer arrangement; it has not begun attacking."),
    ("05-form-and-quiet-target", "05 / Resolution → emission", "The same point becomes a catalyst", "The original point waits ahead when released. Holding it at this station reduces its surface to 1 ring and 4 segments. The trigger then sends a copy of that form. Hit the quiet ring target before BEGIN becomes effective."),
    ("06-operation-1", "06 / Translation", "The waiting head starts to move", "BEGIN brings the same head from the tableau. A warning line fixes its destination before it moves. Step aside or send a form. One interruption ends this round."),
    ("06-operation-2", "07 / Added rotation", "Press BEGIN for another operation", "The head now orbits during recovery. The visitor retains the same catalyst and the familiar trigger. Its added motion changes the timing of an already learned action."),
    ("06-operation-3", "08 / Added scale", "The boundary changes with the body", "The head grows and contracts. Its collision radius follows the visible size. This is an explicit authored progression, not autonomous learning."),
    ("07-three-operations-a-passage", "09 / Defence → passage", "A way opens; the head remains", "Three interrupted rounds open the physical gate. Walking through completes this opening. The next proposed step is Arrays: one form distributes an effect. That continuation is not implemented yet."),
]
cards = []
for name, tag, title, caption in shots:
    shutil.copy2(EVIDENCE / f"{name}.png", HERE / f"{name}.png")
    cards.append(f'<article id="{name}"><a href="{name}.png"><img src="{name}.png" alt="{html.escape(title)} — native Godot museum capture" loading="lazy"></a><div><p class="tag">{tag}</p><h2>{title}</h2><p>{caption}</p></div></article>')

def relative(path):
    return Path(os.path.relpath(ROOT / path, HERE)).as_posix()

scene = relative("commons/testing/catalyst_opening_progression.tscn")
readme = relative("commons/maps/Catalyst_Opening_Progression/README.md")
checklist = "".join(f'<li>✓ {html.escape(c["name"])}</li>' for c in receipt["checks"])
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Catalyst · A beginning that carries forward</title><style>
:root{{color-scheme:light;--paper:#f4f1e9;--ink:#252924;--line:#cfcec2}}*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}}main{{max-width:1320px;margin:auto;padding:45px 32px}}header{{max-width:950px}}.tag{{font:12px/1.4 monospace;letter-spacing:.12em;text-transform:uppercase}}h1{{font:clamp(42px,6vw,76px)/1.05 Georgia,serif;margin:20px 0}}h2{{font:28px/1.2 Georgia,serif;margin:10px 0 16px}}a{{color:inherit;text-underline-offset:4px}}.lead{{font-size:22px}}.route{{border-block:1px solid var(--line);padding:20px 0;margin:32px 0;font-weight:600}}.launch{{padding:26px;background:#e1e6d9;margin-bottom:32px;border:1px solid #c8cebf}}.cards{{display:grid;grid-template-columns:1fr 1fr;gap:26px}}article{{background:#faf9f4;border:1px solid var(--line)}}article img{{width:100%;aspect-ratio:1.6;display:block;object-fit:cover}}article>div{{padding:24px}}article p{{margin:0 0 10px}}article:first-child{{grid-column:1/-1}}article:first-child img{{max-height:650px;object-fit:contain;background:#141820}}.notes{{max-width:960px;margin-top:38px}}table{{width:100%;border-collapse:collapse;margin:24px 0}}td,th{{text-align:left;border-bottom:1px solid var(--line);padding:12px;vertical-align:top}}details{{margin-top:28px;border-top:1px solid var(--line);padding-top:18px}}summary{{font-weight:600;cursor:pointer}}details ul{{columns:2;list-style:none;padding:0;font-size:14px}}details li{{break-inside:avoid;margin-bottom:9px}}code{{font-size:14px;overflow-wrap:anywhere}}footer{{font-size:14px;margin-top:38px;color:#606557}}@media(max-width:750px){{main{{padding:25px 18px}}.cards{{grid-template-columns:1fr}}details ul{{columns:1}}}}
</style><main><header><p class="tag">Endless Museum / playable opening / 12 October 2026</p><h1>An ability that<br>travels with you.</h1><p class="lead">The test now begins with acquiring the power, then carries it through making a line, keeping it, sending a form and defending a passage.</p><p>Four connected rooms rehearse selected moments from Primitives through Transformation. One physical point and one counterpart remain the same objects throughout.</p></header>
<p class="route">Acquire → form → draw → keep → simplify → emit → move / turn / scale → pass</p>
<section class="launch"><h2>Play the beginning</h2><p>Open <a href="{scene}"><code>catalyst_opening_progression.tscn</code></a> in Godot and press <strong>F6</strong> with OpenXR available. Use the museum's existing hands and grip controls. Follow the plinths and wall instructions.</p><p><strong>BEGIN</strong> starts each encounter after the practice receiver answers. <strong>REST / RESUME</strong> pauses an active round; <strong>RESET WALK / RESET TRIAL</strong> returns to acquisition. A held object stays in your hand; released tools return to their mounts.</p><p><strong>{count}/{count} engine checks passed.</strong> <a href="{readme}">Full controls and implementation notes</a> · <a href="checks.json">Evidence receipt</a>.</p></section>
<section class="cards">{''.join(cards)}</section>
<section class="notes"><h2>What now connects</h2><table><thead><tr><th>Before</th><th>Now</th></tr></thead><tbody><tr><td>Power supplied at entry.</td><td>The first sphere grants a local hand ability. Empty-hand formation is performed before the pen can charge.</td></tr><tr><td>A separate weapon waits in the arena.</td><td>The first PointBody remains the same instance, gaining resolution and emission permissions.</td></tr><tr><td>One hit opens the gate.</td><td>A quiet target introduces emission; three successive operations lead to the passage.</td></tr><tr><td>Operations can be selected freely.</td><td>This walk introduces them in order. The direct-entry arena still offers free testing.</td></tr></tbody></table>
<h2>The next decisions belong to play</h2><p>Does forming the point make the ability feel yours? Does the kept drawing connect the rooms? Is the quiet target enough preparation for an approaching body? Does meeting the head at rest change what defending against it feels like?</p><p>This is a compressed rehearsal outside the main teaching spine. It does not replace Lines, Triangle, Polyhedra or the other lessons. Arrays and subsequent sequences remain the proposed continuation. Contact counts a training touch; there is no health loss or automatic conversion to a friend.</p><p>Local unlocks and the trial drawing reset within this scene. Checks verify that the persistent ability save and museum TraceData stay unchanged, and that the normal hand ability resumes when the trial closes.</p>
<details><summary>Inspect all {count} engine checks</summary><ul>{checklist}</ul></details></section>
<footer>All nine images were captured inside the running Godot museum. The probe uses actual pickup, trace and projectile code with supplied poses. Headset grip, reach, aiming, performance and enjoyment still need a human playtest.</footer></main></html>'''
(HERE / "index.html").write_text(page, encoding="utf-8")
print(f"Built {HERE / 'index.html'} — {count} checks, {len(shots)} captures")
