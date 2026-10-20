"""Publish native evidence for the optional listening-horde encounter."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-listening-horde'
RUN = ROOT / 'ada_run/encounter_pilot/SwarmIntelligence_Agent_Based_Modeling_ABM/listening-horde-final'
for name in ['assets', 'evidence']:
    (OUT/name).mkdir(parents=True, exist_ok=True)
code = json.loads((ROOT/'ada_run/listening_horde_checks.json').read_text())
native = json.loads((RUN/'report.json').read_text())
assert code['passed'] and native['passed']
for log in [ROOT/'ada_run/listening-horde-checks.log', RUN/'stdout.log']:
    assert 'SCRIPT ERROR' not in log.read_text(encoding='utf-8'), log
before = json.loads((OUT/'before/reading-hashes.json').read_text())
assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest() == digest for p,digest in before.items())
proposal = json.loads((ROOT/'doc/book/iterations/2026-10-10-swarms-fish-drones-and-hordes/scope.json').read_text())
sequence = 'commons/maps/sequences/swarmintelligence.json'
assert hashlib.sha256((ROOT/sequence).read_bytes()).hexdigest() == proposal['source_texts_sha256'][sequence]
old_plan = json.loads((OUT/'before/em_plan.json').read_text(encoding='utf-8-sig'))
new_plan = json.loads((ROOT/'commons/data/museum/em_plan.json').read_text(encoding='utf-8-sig'))
hall = 'SwarmIntelligence_Agent_Based_Modeling_ABM'
assert [p for p in old_plan['plans'] if p.get('map') != hall] == [p for p in new_plan['plans'] if p.get('map') != hall]
assert {k:v for k,v in old_plan.items() if k != 'plans'} == {k:v for k,v in new_plan.items() if k != 'plans'}
figures = [
    ('resting', 'Before the pulse. Twenty point-headed listeners wait beyond the low partition. The black PointBody is on the stand.'),
    ('investigating', 'The pulse starts an investigation. The bodies move through the opening toward a recorded location.'),
    ('a-place-kept', 'The point has moved toward the stand. The crowd still investigates the gold-ringed place of the earlier pulse.'),
    ('hall-above', 'The real ABM hall from above. Existing comparisons occupy the left room; the new listening court is reached through the east opening.')]
for name,_ in figures:
    shutil.copy2(RUN/f'{name}.png', OUT/'assets'/f'{name}.png')
for source,destination in [
    (ROOT/'ada_run/listening_horde_checks.json','code-checks.json'),
    (RUN/'report.json','museum-checks.json'),
    (RUN/'source_manifest.json','museum-sources.json'),
    (RUN/'stdout.log','museum.log'),
    (ROOT/'ada_run/listening-horde-checks.log','code.log')]:
    shutil.copy2(source, OUT/'evidence'/destination)
sources = [
    'commons/artifacts/listening_horde/horde.gd',
    'commons/artifacts/listening_horde/listening_horde.gd',
    'commons/artifacts/listening_horde/listening_horde.tscn',
    'commons/artifacts/registry/listening_horde.json',
    'commons/artifacts/particle_swarm_walk/point_body.gd',
    f'commons/maps/{hall}/map_data.json', 'commons/data/museum/em_plan.json',
    'tools/probes/listening_horde_checks.gd','tools/probes/listening_horde_museum.gd']
(OUT/'evidence/source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2)+'\n')
total = len(code['checks']) + len(native['checks'])
report = f'''# They heard you there

Endless Museum · Agent-Based Modeling · 11 October 2026

Carry the black point. Send a pulse. Walk away. Twenty bodies investigate the place where the pulse happened, then return to their resting places. The familiar point now leaves a record inside another body.

## Try it in the museum

Reload **Swarm Intelligence → Agent-Based Modeling**. Enter the new court through the east opening in the existing hall. The point waits on a pale stand, 1.18 m above the floor.

- **VR:** grip the point, then press trigger to send a pulse.
- **Desktop:** right-click to carry/drop; left-click while carrying to pulse.
- Move the point somewhere else without pulsing again. Watch the gold rings: they keep the earlier place.
- Let go. The point returns to the stand after 1.5 seconds; the crowd completes its investigation.

**o Rest → ? Investigate → < Return → o Rest**

The heads change colour as well as carrying a state glyph. The floor circles show the original resting places. Each audible pulse stores a new destination for each listener that hears it. Hearing uses an eight-metre radius; a listener outside it retains its existing state. Three seconds spent within one metre of the remembered place starts the return.

## What the encounter carries forward

The sphere uses the existing PointBody class, with its existing pickup and action signals. The bodies reuse the visual idea of the point as a head. The new operation is **recording a position when an event occurs**, then letting a state choose what to do with that record. The pulse does not supply a live connection to the player.

This is an optional transfer encounter beside the foraging tutorial. The primary tutorial already teaches an internal state; the listening crowd gives that operation another concrete setting. All fourteen canonical tutorial/final files and the seven-hall order are unchanged. The original colony, navigator, utilities and their authored placements remain.

The new side court extends the hall from 13 × 10 to 24 × 10 floor cells. A three-cell doorway connects the rooms; the low partition gives the crowd a 2.2 m opening. Procedural decorative sculptures are excluded from the encounter floor so they cannot block the experiment. The original north–south route remains open.

## A record can outlast its source

You leave the place. They keep coming to it. Their movement is exact within the rule we gave them, yet it no longer meets your present position. A stored observation can keep directing action after the world has changed. These listeners remember a coordinate; that is the limit of what their apparent attention means.

This paragraph is a possible encounter reflection, not an insertion into the agreed final text.

## What is supplied

The court has a fixed single-door waypoint, bounded steering and separation. It is a controlled kinematic crowd, not a rigid-body collision simulation or a general pathfinder. The listeners cannot damage or physically trap the player. The wall and stand have actual collision. The pulse is audible, but hearing is an explicit distance rule: wall occlusion is not simulated. The gold marker shows the latest pulse; an out-of-range listener may still retain an earlier record.

## Evidence

**{total}/{total} checks passed:** {len(code['checks'])} production-code checks and {len(native['checks'])} native museum checks, including four camera captures.

The code tests exercise the real state/movement model, finite and capped motion, hearing range, replacement of a record, passage constraints, complete return to rest, and arrival on the correct side of the wall. The actual PointBody action is tested under a translated and rotated host. Moving or releasing the sphere does not change stored destinations.

The museum run checks floor support, standing-capsule clearance from the existing room to the court, passage clearance, partition collision, point reachability, the original route and the live investigate/return cycle. All twenty listeners returned to their original resting places. The pictures are native Godot captures with the simulation running.

The first capture exposed a wrongly specified sculpture exclusion rectangle; decorative sculptures obstructed the new passage. That was corrected and the native checks rerun. The final run has no script errors. Existing unresolved UID, catalyst ViewportTexture and renderer/Jolt warnings remain in the logs; this is not a claim that the whole project is error-free.

Pickup and trigger events were supplied by the probes. Physical headset use, portal travel and Quest performance remain untested.
'''
(OUT/'REPORT.md').write_text(report, encoding='utf-8')
body = markdown.markdown(report, extensions=['extra'])
gallery = ''.join(f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in figures)
css = '''*{box-sizing:border-box}body{margin:0;background:#111b29;color:#e9e8e4;font:18px/1.65 system-ui}main{max-width:1150px;margin:42px auto;padding:0 24px 70px}h1{font-size:clamp(38px,6vw,68px);line-height:1.08;color:#f69bb2}h2{margin-top:44px}a{color:#88dddc}nav{padding:16px 24px;background:#233043;display:flex;gap:24px;flex-wrap:wrap}figure{margin:26px 0;background:#243143;padding:12px}img{width:100%;height:auto;display:block}figcaption{padding:12px 6px;font-size:15px;color:#ccd4dd}li{margin:8px 0}.hero{padding:0;background:none}'''
hero='<figure class="hero"><a href="assets/a-place-kept.png"><img src="assets/a-place-kept.png" alt="Listeners investigating the old pulse while the carried point is elsewhere"></a><figcaption>Actual museum capture: the crowd and the carried point have different destinations.</figcaption></figure>'
(OUT/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>They heard you there — Endless Museum</title><style>'+css+'</style></head><body><nav><a href="#pictures">Museum pictures</a><a href="REPORT.md">Editable report</a><a href="evidence/code-checks.json">Code checks</a><a href="evidence/museum-checks.json">Museum checks</a><a href="../2026-10-10-swarm-complete-readings/index.html">Swarm readings</a></nav><main>'+hero+body+'<section id="pictures"><h2>The encounter, inside the museum</h2>'+gallery+'</section></main></body></html>',encoding='utf-8')
print(f'Published listening-horde report: {total} passing checks; four native images; readings/order and other plan rows unchanged.')
