"""Report from actual museum captures; separates implemented test from route proposals."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Trans_Pre/counterpart'
MEL = ROOT / 'ada_run/encounter_pilot/Primitives_Melencolia/counterpart'
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
boot = json.loads((RUN / 'boot.json').read_text(encoding='utf-8'))
mel = json.loads((MEL / 'report.json').read_text(encoding='utf-8'))
assert report['passed'] and boot['passed'] and mel['passed']
for log in ['stdout.log', 'boot-engine.log']:
    text = (RUN / log).read_text(encoding='utf-8')
    assert 'SCRIPT ERROR' not in text and 'Parse Error' not in text, log
mel_log = (MEL / 'stdout.log').read_text(encoding='utf-8')
assert 'SCRIPT ERROR' not in mel_log and 'Parse Error' not in mel_log

captions = {
    'counterpart-in-the-museum': 'The optional test in the actual Transformation hall. The black point is the existing resolution catalyst; the original cube encounters remain.',
    'skull-close': 'An original faceted flying skull. Its collision body moves with it. Its appearance remains the same while its behaviour changes.',
    'line-locked': 'The warning draws the planned dash. Moving aside does not bend that line: the visitor can read the intention and dodge.',
    'interruption': 'A real form fired from the held point has interrupted the counterpart. The body remains; the visitor gains a pause in which to act.',
}
for name in ['melencolia-before', 'melencolia-burning-counterpart', 'melencolia-skull-close']:
    shutil.copy2(MEL / (name + '.png'), OUT / (name + '.png'))
for name in captions:
    shutil.copy2(RUN / (name + '.png'), OUT / (name + '.png'))

rows = [
    ('Point Coordinates', 'Acquire', 'Place the existing point in the hollow field. Empty hands together call a sphere; apart dismiss it.', 'Position, proximity and a persistent ability.', 'Already implemented in the preceding pass.'),
    ('Point Lines', 'Relate', 'A rod gives the point an extent and a direction. Keep the two-end relation visible.', 'Endpoints, displacement, length.', 'Route proposal; preserve the existing line examples.'),
    ('Point Trace', 'Leave a mark', 'Take a rod from the wall. Touch its tip into a stationary glowing point. The charged tip leaves a trace while you draw.', 'Sample the held point; keep positions in order; connect neighbours after a distance threshold.', 'Proposed. Reuse the existing drawing and record system.'),
    ('Point Grid', 'Return to your mark', 'Meet your own saved trace as a sculpture. Grid addresses organise a transformed copy while the original record remains.', 'One record, another organisation.', 'Existing Trace → Grid handoff; preserve it.'),
    ('Triangle → Polyhedra', 'Make a boundary', 'Selected positions become a face and then a body. Later, a face could become a shield and an enclosure could hold a field.', 'Connectivity and inside/outside.', 'Shield/field applications are future proposals, not extra opening lessons.'),
    ('Primitive Ignorance', 'Send a form', 'The same held sphere sheds rings and segments. Trigger sends a copy of its current form toward a visible receiver.', 'Representation, resolution and a directed emission.', 'Resolution catalyst already exists; reused by this test.'),
    ('Melencolia', 'Meet the counterpart', 'A burning skull takes the seated figure’s place in the Dürer arrangement. Its body waits; only the fire moves.', 'The composed form becomes a presence before it becomes an actor.', 'Native museum preview built; proposed replacement, original map preserved.'),
    ('Transformation', 'Read and interrupt motion', 'A counterpart announces a straight dash. Step aside or interrupt it. Later it can orbit and change scale.', 'Translation, rotation, scale and timing become encounter decisions.', 'Playable optional test built. Recommend permanent placement after the three-operation comparison.'),
    ('Arrays', 'Distribute', 'A pulse addresses a selected place or group. A counterpart can repeat itself with a readable spacing rule.', 'Index, iteration, position and multiplicity.', 'Later proposal. Introduce few copies before swarms.'),
    ('Colour', 'Change a receiver', 'Send colour to a chosen surface or cube. Make the receiver’s response visible.', 'A material property and its recipient.', 'Later proposal; a pure paint receiver is still needed. Colour need not encode fixed moral teams.'),
    ('Change → Forces → Waves', 'Redirect', 'Alter a rate, push or pull a moving form, then act on phase or amplitude. The counterpart gains the same operations.', 'Each power exposes the current sequence’s quantities.', 'Later proposal, tied to specific existing receivers.'),
    ('Chance → Growth → Many bodies', 'Work with variation', 'Introduce uncertain routes, branching effects and local interactions only after the visitor can read a single effect.', 'Prediction, variation, rule and collective behaviour.', 'Longer route proposal, not implemented by this test.'),
]

plan = '''# From a point to a power

The catalyst carries a learned operation into the next encounter. The ability belongs to the visitor; the sphere is its first form. A rod gives that ability a usable tip. Drawing is its first productive use: a movement leaves material that survives into the next room.

## Trace: a charging encounter

Keep a small stationary glowing point beside the wall-mounted rod. Touch the tip into the field, receive a brief visible response, then draw using the existing held-point sampling. This resolves an interaction constraint: the current summoned sphere requires two empty hands. Charging a held rod from that sphere would otherwise require a new one-hand transfer rule. Keep that larger change for a later pass.

Preserve the existing sampled positions, reference frame, spacing test and Trace → Grid persistence. The charging gesture controls whether drawing is enabled; it must not silently replace or clear the learner's record. The tutorial can concentrate on sampling, arrays, neighbouring entries and the distance condition. The encounter can contain a supplied charging mechanism without teaching its whole implementation there.

## First encounter

User's revised placement: the burning skull takes the seated figure's place in the Dürer arrangement in Melencolia. Its body waits; only the fire moves. The native museum preview implements this substitution while preserving the original authored tableau. This is Ada's adaptation, not a historical claim about the engraving. It is the same procedural counterpart used by the Transformation trial.

The first active encounter should follow the three transformations in Trans_Pre, in an optional clear bay. The skull that waited now moves. The visitor has already seen what a translation, a turn and a scale change do. Now those operations matter to anticipation, distance and timing, and the catalyst gives the visitor a way to defend.

The current test uses one skull and the existing resolution catalyst. Its locked dash can be dodged or interrupted. Its next powers are an orbit and a changing collision envelope, selected explicitly by the trial controls. A hit gives time and room. It does not decide that the creature must die or become friendly.

## What to assess in VR

Can the visitor recognise the warning without a spoken instruction? Does a dodge feel intentional? Is the interruption obvious? Does the second operation ask for another response? Is there room to leave the encounter? If the player merely fires continuously, first improve the consequence and timing of a hit before adding more opponents.

For a permanent encounter, the goal should be concrete: reach an opening, hold a route clear, or redirect a force into a receiver. The prototype currently tests interruption and avoidance only. A goal, rewards and the charging rod still need to be built. The Melencolia sighting and Transformation trial remain separate test scenes, not a shipped persistent encounter spanning two halls.

## Short memory

Power = learned operation carried onward. Point: acquire. Line: relation/direction. Trace: mark; keep record. Grid: return same record. Face/body: boundary. Ignorance: emit form. Melencolia: burning skull replaces figure in preview; body waits. Transformation: same form moves; defend by interruption. Arrays: distribute. Colour: receiver change. Forces: redirect. Counterpart gains same operations. Appearance ≠ hostility. Implemented now: two museum previews; no Trace or permanent spine changes.
'''
(OUT / 'PROGRESSION.md').write_text(plan, encoding='utf-8')

count = len(report['checks'])
sources = [
    ROOT / 'commons/hazards/catalyst_counterpart/flying_skull.gd',
    ROOT / 'commons/hazards/catalyst_counterpart/counterpart_trial.gd',
    ROOT / 'commons/testing/catalyst_counterpart_trial.gd',
    ROOT / 'commons/testing/catalyst_counterpart_trial.tscn',
    ROOT / 'tools/probes/catalyst_counterpart.gd',
    ROOT / 'tools/probes/catalyst_trial_boot.gd',
    ROOT / 'commons/hazards/catalyst_counterpart/tableau_preview.gd',
    ROOT / 'commons/testing/melencolia_counterpart_preview.tscn',
    ROOT / 'tools/probes/melencolia_counterpart.gd',
]
receipt = {'encounter': report, 'melencolia_preview': mel, 'entry_point': boot, 'sources': {
    p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources
}}
receipt['diagnostics'] = {'melencolia_shutdown_warning': 'The museum probe reports one resource still in use at shutdown; all assertions passed and no script/parse error was reported.' if 'resources still in use at exit' in mel_log else None}
(OUT / 'checks.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
table = ''.join('<tr>' + ''.join(f'<td>{html.escape(cell)}</td>' for cell in row) + '</tr>' for row in rows)
figures = ''.join(f'<figure><a href="{name}.png"><img src="{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name, caption in captions.items())
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A point becomes a power — Endless Museum</title>
<style>
:root{{color-scheme:light;--ink:#292827;--paper:#f3f0e8}}*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:18px/1.6 Georgia,serif}}main{{max-width:1280px;margin:auto;padding:50px 5vw}}h1{{font-size:clamp(38px,5vw,76px);line-height:1.04;font-weight:400;max-width:900px}}h2{{font-size:30px;font-weight:400;margin-top:60px}}p{{max-width:780px}}.eyebrow,nav,.status,th{{font:12px/1.5 system-ui,sans-serif;letter-spacing:.09em;text-transform:uppercase}}.lead{{font-size:25px}}a{{color:inherit;text-underline-offset:4px}}nav{{display:flex;gap:24px;flex-wrap:wrap}}.status{{padding:16px;border:1px solid #aaa;margin:30px 0}}figure{{margin:35px 0}}img{{width:100%;height:auto;display:block}}figcaption{{font:15px/1.55 system-ui,sans-serif;margin:12px 0;max-width:930px}}.route{{overflow:auto}}table{{border-collapse:collapse;width:100%;min-width:1000px;font:15px/1.55 system-ui,sans-serif}}td,th{{padding:18px 12px;text-align:left;vertical-align:top;border-bottom:1px solid #ccc}}td:first-child{{font-weight:700}}td:nth-child(3){{min-width:260px}}code{{font:14px/1.6 monospace;overflow-wrap:anywhere}}.box{{border-left:3px solid #888;padding-left:24px}}footer{{margin-top:60px;font:14px system-ui,sans-serif}}@media print{{main{{padding:0}}nav{{display:none}}figure{{break-inside:avoid}}table{{min-width:0;font-size:10px}}}}</style>
<main><div class="eyebrow">Endless Museum · 12 October 2026 · Play experiment + route proposal</div><h1>A point becomes a power.</h1>
<p class="lead">First, it lets a movement leave a trace. Later, it lets you intervene in a moving world.</p>
<nav><a href="#trace">Trace</a><a href="#trial">Flying counterpart</a><a href="#route">Spine progression</a><a href="#play">Try it</a><a href="PROGRESSION.md">Short memory + proposal</a></nav>
<div class="status">Built: Melencolia preview + Transformation trial · {count}/{count} encounter checks + {len(mel['checks'])}/{len(mel['checks'])} tableau checks passed · entry-point smoke test passed · headset playtest pending</div>
<section id="trace"><h2>The rod gives the power a tip.</h2><p>Yes: the drawing encounter can make the catalyst useful before combat. Take a rod from the wall, touch it into a small stationary glowing point, and draw a line in the air. Keep the same held-point sampling and the record that travels into Grid.</p><p>The stationary charging point matters. The current summoned sphere requires two empty hands. A rod in one hand therefore needs a charging station, or a later, explicitly designed transfer gesture. The station gives this first action a clear place.</p><p class="box"><strong>Teaching focus:</strong> keep positions in an array; sample after enough movement; loop through neighbouring entries. The charging interaction can be supplied. We do not need to teach the whole ability system to teach a trace.</p><p><strong>Status:</strong> this Trace change is proposed. The existing drawing and Grid handoff remain as they were.</p></section>
<section id="trial"><h2>In Melencolia it waits. In Transformation it moves.</h2><p>Your revised placement gives the counterpart a stronger entrance. <strong>The burning skull replaces the seated figure in the Dürer arrangement.</strong> The instruments, sphere, solid and magic square remain around it. Only its pale fire moves. This is Ada’s proposed substitution, shown in a native museum preview.</p><figure><a href="melencolia-before.png"><img src="melencolia-before.png" alt="The existing Durer arrangement before the preview substitution"></a><figcaption>Before: the current sculptural arrangement after the engraving.</figcaption></figure><figure><a href="melencolia-burning-counterpart.png"><img src="melencolia-burning-counterpart.png" alt="The burning counterpart occupies the seated figure’s place"></a><figcaption>Preview: the same skull used in the next sequence, held still among the instruments. The original authored tableau remains intact.</figcaption></figure><figure><a href="melencolia-skull-close.png"><img src="melencolia-skull-close.png" alt="Pale fire rising from the stationary skull"></a><figcaption>First sighting: fire without approach or attack. The pale flame keeps the body within the grayscale vocabulary.</figcaption></figure><p>I would begin defence <strong>after the three-operation comparison in Trans_Pre</strong>. The form you met now approaches. You have watched a body move, turn and change scale; those operations now matter to your own position. The catalyst lets you interrupt that approach and make room to pass.</p><p>The test begins at rest. Start it, and a line announces a dash. Step aside, or send a form from the held black point to interrupt it. TURN adds an orbit; SCALE changes its body and collision envelope. The trial records interruptions and contact tags. Its body survives. These are two separate previews so far; persistent travel of one entity between halls remains future work.</p>{figures}</section>
<section id="route"><h2>Carry an operation forward.</h2><p>The creature gains new operations alongside the visitor. This gives each encounter a relation to the current subject. The table distinguishes existing behaviour, this test and later proposals.</p><div class="route"><table><thead><tr><th>Hall / sequence</th><th>Use</th><th>Encounter</th><th>Subject</th><th>Status</th></tr></thead><tbody>{table}</tbody></table></div></section>
<section id="play"><h2>Try the counterpart.</h2><p>For the first sighting, open <a href="../../../../commons/testing/melencolia_counterpart_preview.tscn"><code>commons/testing/melencolia_counterpart_preview.tscn</code></a>. For the moving encounter, open <a href="../../../../commons/testing/catalyst_counterpart_trial.tscn"><code>commons/testing/catalyst_counterpart_trial.tscn</code></a>. In Godot press <strong>F6</strong>. Both open the existing museum. With an active OpenXR headset they use the existing XR rig.</p><p>In Transformation, take the black point. Use its trigger to send a form. Choose MOVE, TURN or SCALE; START / REST starts and stops the encounter. These are trial controls, not additional abilities granted by the opening field.</p><p><strong>What the checks establish:</strong> the real point can be picked up, its trigger creates a projectile, native collision reaches the counterpart, aim stays locked after a dodge, movement and scaling affect collision, rest stops attacks, and contact counts once before recovery. The Melencolia body stays still and the hidden figure leaves no invisible collider. These checks do not establish headset comfort or whether the encounter is fun.</p><p><strong>Next play decision:</strong> does interrupting it create a useful moment? A permanent encounter needs a purpose such as reaching an opening, keeping a route clear, or directing a force into a receiver. If repeated firing feels empty, improve that consequence before multiplying opponents.</p><p><a href="checks.json">Verification receipt</a> · <a href="../../../../commons/hazards/catalyst_counterpart/README.md">Implementation and test notes</a></p></section>
<footer>Native Godot captures, with controlled input poses. No generated images. The main spine, Trace sampling and lesson texts were not changed by this prototype.</footer></main></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(f'Built {OUT / "index.html"}: {count}/{count} encounter + {len(mel["checks"])}/{len(mel["checks"])} tableau checks; seven native captures.')
