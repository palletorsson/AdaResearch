"""Publish the real prefab overflow encounter, manuscript passage and evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-everything-worked'
OUT.mkdir(parents=True, exist_ok=True)
shutil.copy2(ROOT / 'ada_run/prefab_overflow_tests.json', OUT / 'physics-tests.json')
shutil.copy2(ROOT / 'ada_run/prefab_overflow_tests.log', OUT / 'physics-tests.log')
shutil.copy2(ROOT / 'doc/book/iterations/2026-10-07-forces-curated-progression/after/Change_Choreography/above.png', OUT / 'before.png')
manuscript = ROOT / 'commons/maps/Change_Choreography/final.md'
shutil.copy2(manuscript, OUT / 'full-final.md')
source_text = manuscript.read_text(encoding='utf-8-sig')
passage = source_text.split('<!-- @force_trial_conveyor -->', 1)[1].split('<!-- @ -->', 1)[0].strip()
footnotes = '\n\n'.join(line for line in source_text.splitlines() if line.startswith('[^overflow-'))
addition = '# Everything worked, and this happened\n\n' + passage + '\n\n' + footnotes + '\n'
(OUT / 'addition.md').write_text(addition, encoding='utf8')
readings = markdown.markdown(addition, extensions=['footnotes'])
tests = [json.loads(p.read_text(encoding='utf-8-sig')) for p in [OUT / 'physics-tests.json', OUT / 'museum/report.json']]
assert all(t['passed'] for t in tests)
assert all(c['passed'] for t in tests for c in t['checks'])
count = sum(len(t['checks']) for t in tests)
for log in [OUT / 'physics-tests.log', OUT / 'museum/engine.log']:
    assert 'SCRIPT ERROR' not in log.read_text(encoding='utf8', errors='replace')
observed = tests[1]['observations']['overflow']

def figure(path, caption):
    assert (OUT / path).is_file(), path
    return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption, quote=True)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Everything worked — prefab overflow in Endless Museum</title><style>
*{box-sizing:border-box}body{margin:0;background:#ece8df;color:#22212a;font:17px/1.65 system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:36px 24px 80px}h1{font:clamp(42px,6vw,78px)/1.05 Georgia,serif;max-width:1000px;margin:24px 0}h2{font:34px/1.2 Georgia,serif;margin-top:50px}p{max-width:820px}a{color:#863955}nav{display:flex;gap:20px;flex-wrap:wrap;margin:28px 0}figure{margin:32px 0}img{display:block;width:100%;height:auto}figcaption{color:#55535a;padding-top:10px;max-width:950px}.instructions{padding:18px 26px;background:#dfcdd5;border-left:5px solid #ae5e83}.reading{max-width:740px;margin:60px auto;font:21px/1.75 Georgia,serif}.reading h1{font-size:40px}.reading .footnote{font:14px/1.55 system-ui,sans-serif}.kicker{font-size:13px;letter-spacing:.13em;text-transform:uppercase}li{margin-bottom:10px}.evidence{background:#fff9;padding:20px 26px}code{font-size:.9em} @media print{nav{display:none}figure{break-inside:avoid}body{background:white}main{padding:0}.reading{max-width:100%}}
</style></head><body><main><p class="kicker">Endless Museum · Forces · 7 October 2026</p>
<h1>Everything worked.<br>And this happened.</h1><p>A prefab experiment in <strong>The next body arrives</strong> (<code>Change_Choreography</code>). The existing conveyor now receives chairs, wooden crates, extinguishers and the familiar black PointBody. Deliveries become obstructions, rollers and levers through their contact with the room.</p>
<nav><a href="#museum">Museum images</a><a href="#reading">New final.md passage</a><a href="#before">Before</a><a href="#checks">Evidence</a></nav>
<div class="instructions"><p><strong>Reload the museum and enter Forces → The next body arrives.</strong> Start FEED, or take the rose gate grip and press its trigger. Pull the gate with your hand; hold the trigger to accelerate the deliveries. Use the long stick or pick up a delivered object to change the pile.</p><p>The second half of the 32-object batch arrives oversized and heavier. The receiving tray rocks under the load. Pause stops new deliveries; existing bodies continue moving. RESET clears the attempt after you release held objects.</p></div>
<h2 id="museum">Just get it through</h2>'''
page += figure('museum/setup.png', 'The proposition: a delivery belt, a hand-operated gate and a rocking receiving tray. Actual museum capture.')
page += figure('museum/the-queue.png', 'The first deliveries meet the gate. A chair has openings and legs; it does not behave like another box.')
page += figure('museum/pull-and-flood.png', 'Pull and accelerate the feed. Larger prefabs enter the same apparatus; fit, leverage and mass now change the encounter.')
page += figure('museum/aftermath.png', 'The result stays available to rearrange. This pile came from Jolt contacts, gravity and two hinges, with supplied hand input during the capture.')
page += f'''<p>At the last capture, {observed['delivered']} objects had entered, {observed['beyond_gate']} had crossed the gate and {observed['spilled']} had reached the floor. These are observations from one run; the arrangement is not an animation or a promised outcome.</p>
<h2>What the artifact makes available</h2><p>The simple task makes a prediction possible. The oversized prefab exposes the difference between repeating a name and repeating a physical situation. Contact, torque, a closing spring and delivery rate then interact. A failed delivery leaves something the visitor can use.</p><p>The chapter’s existing phase-rod tutorial anchor remains in place. This encounter supports its concern with rates and adds a physical consequence. The change here is to the artifact and its reflective passage; the full tutorial has not been rewritten.</p>
<section id="reading" class="reading">{readings}</section>
<nav><a href="addition.md">Download the new passage</a><a href="full-final.md">Complete hall final.md</a><a href="final-before.md">Previous final.md</a></nav>
<h2 id="before">Before</h2>'''
page += figure('before.png', 'Earlier curated hall: phase rods and the smaller cube-conveyor comparison. The updated artifact retains the existing conveyor token and placement.')
page += f'''<h2 id="checks">What was checked</h2><div class="evidence"><p><strong>{count} assertions passed.</strong> The 24 standalone checks use actual Jolt bodies and XRTools pickup. They cover belt contact, pulling the gate without detaching its hinge, trigger flooding, spills, retaining the aftermath, picking up a chair, refusing reset while held, and waiting when the inlet is obstructed. The 20 museum checks cover production placement, a clear aisle and exit, captures and the observed event.</p><p>The supplied hand moved the gate through about 77 degrees; maximum measured hinge drift was 0.22 mm. This verifies the simulated interaction. Physical headset reach, comfort and Quest performance remain untested.</p></div>
<p>There are 32 deliveries and three other tracked bodies. Pooling is finite; ordinary spills stay. The inlet waits for space instead of spawning overlapping objects. Out-of-bounds recovery remains active below −12 m or beyond 85 m. The belt prescribes a surface velocity; chosen masses and simplified colliders define this experiment. There is no fracture, ragdoll or welding simulation.</p>
<p>The captures used the compatibility renderer. The logs retain existing unknown-UID, legacy solver-bias, empty-registry and unavailable-render-feature diagnostics; no script errors occurred.</p>
<nav><a href="physics-tests.json">Physics assertions</a><a href="museum/report.json">Museum assertions</a><a href="physics-tests.log">Physics log</a><a href="museum/engine.log">Museum log</a><a href="verification.json">Source hashes</a></nav>
<p class="kicker">Actual Godot museum images · No generated mockups</p></main></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf8')
sources = ['commons/artifacts/force_trials/prefab_overflow.gd', 'commons/artifacts/force_trials/overflow_prop.gd', 'commons/artifacts/force_trials/conveyor.tscn', 'commons/maps/Change_Choreography/final.md', 'tools/probes/prefab_overflow.gd', 'tools/probes/prefab_overflow_museum.gd']
(OUT / 'verification.json').write_text(json.dumps({'passed': True, 'checks': count, 'physics_engine': tests[0]['physics_engine'], 'sources': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}}, indent=2), encoding='utf8')
print(OUT / 'index.html', count, 'checks')
