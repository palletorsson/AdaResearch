"""Publish a source-grounded inventory. This script edits only this report folder."""
from pathlib import Path
import hashlib
import html
import json
import re

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
BASE = "commons/hazards/becoming_catalyst/"
FOE = "commons/hazards/catalyst_foe/catalyst_foe.gd"
BINDING = "commons/hazards/catalyst_sequence_binding.gd"
MANAGER = "commons/managers/CatalystCapabilityManager.gd"

rows = [
    ("primitives", "Primitives", "A bouncing luminous sphere shrinks over its lifetime; each bounce can dispatch a catalyst hit.", "Shield", "A nearby primitives friend orbits the player and can absorb an incoming hit; its absorb cooldown is 10 seconds.", "The early resolution sphere is another PointBody continuation. Holding reduces its rings/segments; firing copies the current mesh. It is not yet the full mode controller."),
    ("transformation", "Transformation", "A direct hit temporarily halves the target's scale and restores it. Shared reaction receivers instead own their configured response.", "Porter", "A friend can push a peer away and park as a temporary walkable platform at a detected gap.", "The shot implements shrink/recovery, not the full translate/rotate/scale curriculum. Raw body scaling needs receiver-specific physics review."),
    ("chromatic", "Colour", "Paints nearby rendered grid instances within 1.5 m; also randomly shrinks, rotates and offsets them and emits small cubes.", "Neutralizer", "A chromatic friend inside a compatible DangerZone suppresses its periodic damage. Instant-kill zones are excluded.", "Current shot is a compound effect. Colour-only addressed painting is a proposed focused adapter; appearance changes are not proof of saved edits or matching collision changes."),
    ("forces", "Forces", "An arcing shot slows nearby unfrozen rigid bodies and temporarily increases their damping for three seconds.", "Launcher", "At least two forces friends within 1.2 m provide an upward boost through the player adapter.", "The shot is a calming field. General attract/capture/launch is not implemented by this mode. The separate two flight points need integration."),
    ("waveform", "Waves", "An oscillating projectile draws paired helical trails and delivers the common catalyst hit.", "Calmer", "A waveform friend periodically slows nearby non-friend creatures; the previous speed is restored.", "The helix is the projectile's trajectory/appearance. It does not establish a simulated wave field across every receiver."),
    ("chaos", "Randomness", "A crackling projectile receives random impulses; impact chooses shake, repel, tint or spin where the receiver supports it.", "Decoy", "Chasing foes can target a chaos-lineage friend instead of the player.", "Randomised motion is not evidence of a deterministic chaotic system. Keep the algorithm's actual scope visible."),
    ("cellular", "Cellular automata", "A slow cube displays nine evolving cells in a 3 by 3 arrangement and delivers the common catalyst hit.", "Replicator", "A cellular friend advances an additional nearby creature by one relationship step when converting a peer.", "The cells use a cyclic one-dimensional elementary rule displayed as 3 by 3. The friend currently advances two targets; it does not create two new friends."),
    ("fractal", "Fractals", "A projectile splits into three smaller projectiles, with recursion bounded to depth two.", "Splitter", "A fractal friend can clone instead of reverting during the drag-back event; its peer contact can advance a second target.", "Do not generalise the clone response to every damage event. The split has a bound and specific triggers."),
    ("branching", "L-systems", "A seed branches in flight. Eligible impacts or terminal branches can grow a temporary DNA-based tree.", "Bridger", "A branching friend can grow a temporary walkable strip across a nearby eligible danger zone.", "The tree is probabilistic and removed after 30 seconds. It is distinct from the friend's bridge; instant-kill zones are excluded."),
    ("swarm", "Swarm", "Eight simulated boids separate, align, cohere and seek nearby catalyst targets or creatures.", "Escort", "Swarm friends form positions around the player and shove nearby foes away.", "Target selection currently follows configured groups. A surrounding formation is not proof of an impenetrable shield."),
]

tools = [
    ("voxel_editor", "Add/remove grid blocks", "Grid construction and bounded brush operations."),
    ("wedge_placer", "Place/remove wedges", "A preview and directional placement create walkable prisms."),
    ("artifact_edit", "Place and rearrange artifacts", "Catalogue placement plus laser selection, move, rotate and snap."),
    ("lab_edit", "Arrange lab equipment", "Reuses artifact manipulation with surface alignment for props."),
    ("biome_brush", "Paint biome density", "Select elements and brush size; changes the biome's paint layers."),
    ("modifier", "Apply reversible modifier operations", "Colourise, randomise colours, normalise and undo a modifier stack."),
    ("utility_edit", "Edit room utilities", "Add, move, rotate or remove utility tokens."),
]

source_paths = [BASE + "becoming_catalyst.gd", BASE + "catalyst_projectile.gd", BINDING, FOE,
    MANAGER, "commons/managers/FriendPowerGuard.gd", "commons/hazards/hazard_creature_base.gd",
    "commons/hazards/DangerZone.gd", "commons/hazards/catalyst_foe/bridger_tendril.gd",
    BASE + "catalyst_orb.gd", BASE + "orb_gesture_detector.gd", BASE + "orb_test_rig.gd",
    "commons/artifacts/ignorance_gallery/resolution_catalyst.gd",
    "commons/artifacts/ignorance_gallery/form_projectile.gd", "commons/grid/GridBiomeComponent.gd",
    "algorithms/color/gridcolorizer/gridcolorizer.gd", "algorithms/color/gridcolorizer/address_lesson.gd",
    "commons/maps/Color_Grid_Pallet/map_data.json", "commons/maps/OrbTestChamber/map_data.json",
    "commons/maps/sequences/catalyst_test.json", "commons/maps/sequences/catalyst_lab.json",
    "commons/maps/CatalystLab_02_Pair_Primitives/map_data.json", "commons/maps/CatalystLab_05_Mismatch/map_data.json"]
source_paths += [BASE + f"modes/{r[0]}_projectile.gd" for r in rows]
source_paths += [BASE + f"modes/mode_{r[0]}.gd" for r in rows]

inventory = {
    "date": "2026-10-12", "title": "The catalyst and its counterpart",
    "status": "Source inventory and proposed design direction. No runtime changes or new Godot/headset tests in this pass.",
    "core": "Carry PointBody into an instrument. Distinguish source, gesture, emitted form, receiver response and lasting consequence. Threat belongs to a situated behaviour; an altered body is not intrinsically an enemy.",
    "projectile_modes": [dict(zip(["id", "sequence_label", "shot", "companion_power", "companion_effect", "limits"], r),
        sources=[BASE + f"modes/{r[0]}_projectile.gd", BASE + "catalyst_projectile.gd", FOE, BINDING]) for r in rows],
    "editor_tools": [dict(zip(["id", "action", "scope"], r)) for r in tools],
    "field": {"status": "Prototype installed in OrbTestChamber via orb_test_rig; not established as the production controller throughout the museum.",
        "two_hands": "Close palms held away from the head form a sustained orb; reach changes the influence length.",
        "one_hand": "Presenting one hand produces a brief field burst with a per-hand cooldown.",
        "receiver": "Creatures accumulate exposure and advance through the existing relationship states. An Area3D cylinder approximates the described cone.",
        "limit": "Different held visuals currently share the personality-dose receiver behaviour; they are not ten independently implemented field powers."},
    "arenas": {"catalyst_test": "10 mode arenas", "catalyst_lab": "8 binding/interaction arenas", "first_existing_pair": "CatalystLab_02_Pair_Primitives", "mismatch_study": "CatalystLab_05_Mismatch", "scope": "Test sequences, outside the main curriculum spine."},
    "important_findings": [
        "The full catalyst has 10 projectile definitions and 7 editor-tool definitions; off is an inactive state.",
        "Projectile mode, foe kind and companion power share a 10-entry binding table. One mode is not implemented for every curriculum sequence.",
        "Ordinary catalyst foes advance foe → wary → neutral → curious → friend. The first hit received while foe locks the later power lineage; a pre-warmed creature can retain its seeded lineage.",
        "The silhouette body is an exception: a shot makes it a statue rather than following the normal friend arc.",
        "A recorded companion-power grant differs from a currently active effect: several effects require live nearby friends, a suitable receiver or a specific event.",
        "The capability manager writes progress to disk; the catalyst's own mode-save method remains a no-op. Continuous handoff/reload behaviour needs explicit verification before making a general persistence claim.",
        "Shared artifact reaction receivers can substitute a common temporary colour response for specialised projectile behaviour. Biome mutation routing is explicitly opt-in.",
        "The actual Colour Grid lesson has addressed instance-colour editing and rule reapplication. No dedicated catalyst adapter was found in its lesson script; the broad chromatic shot currently edits structure instances through another path.",
        "Several README and July audit claims are stale, including the roster, companion grants and manager persistence. Current sources were used here."],
    "proposal": {"status": "Proposal only; not installed", "seed_arena": "CatalystLab_02_Pair_Primitives",
        "question": "Can the player stop a harmful action while leaving a strange body free to continue existing?",
        "encounter": "A counterpart repeatedly sends a visible pulse across a passage. Use the familiar sphere to interrupt or redirect the pulse, or place a shelter. Success is enough space/time to pass or protect a chosen sculpture; friendship can be an additional outcome.",
        "shared_form": "Give the source in the hand and the counterpart a recognisable shared material and family of motion. Signal an imminent action through preparation, direction and timing.",
        "outcomes": ["A shot interrupts or redirects a threatening event.", "The same power can protect a route or affect a surface.", "The counterpart can remain strange when neutral or allied.", "Withdrawal/coexistence is possible without compulsory conversion."],
        "colour_followup": "Adapt an impact into the actual Colour Grid cell address; change only that cell's stored colour, keep transforms/collision fixed, let the existing rule reapplication overwrite the exception as taught.",
        "first_checks": ["One emitted event causes one receiver response.", "A visual variant alone does not change allegiance or damage.", "The player can succeed without making every counterpart a friend.", "A missed shot has a legible, bounded consequence.", "Colour-only mode changes the addressed colour and leaves transforms/colliders untouched.", "A held study object owns its trigger; the absorbed catalyst does not fire a second time."]},
    "theory": {"source": "Julia Kristeva, Powers of Horror, opening chapter, printed p. 4.",
        "url": "https://courses.lsa.umich.edu/jptw/wp-content/uploads/sites/23/2017/08/Kristeva-PowersofHorror.pdf",
        "reading": "Abjection concerns disturbance of the boundaries supporting identity and order; it is not a diagnostic label for an unusual body. Ada's choice to separate hostile action from morphological difference is our design interpretation, not a game prescription supplied by Kristeva.",
        "tension": "A compulsory shoot-to-friend loop can still make otherness acceptable only after it serves the player. Retain room for difference, refusal, distance and temporary alliance."},
    "sources": [{"path": p, "sha256": hashlib.sha256((ROOT / p).read_bytes()).hexdigest()} for p in source_paths]
}
(OUT / "inventory.json").write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

E = html.escape
def source_link(path, label="Source"):
    return f'<a href="../../../../{E(path)}">{E(label)}</a>'
def bullets(items):
    return '<ul>' + ''.join(f'<li>{E(s)}</li>' for s in items) + '</ul>'

mode_rows = ''.join(f'<tr><th scope="row">{E(r[1])}<small>{E(r[0])}</small></th><td>{E(r[2])}</td><td><strong>{E(r[3])}</strong><br>{E(r[4])}</td><td>{E(r[5])}<br>{source_link(BASE + "modes/" + r[0] + "_projectile.gd", "Projectile source")}</td></tr>' for r in rows)
tool_rows = ''.join(f'<tr><th scope="row">{E(r[0])}</th><td>{E(r[1])}</td><td>{E(r[2])}</td></tr>' for r in tools)
sources = ''.join(f'<li>{source_link(s["path"], s["path"])}</li>' for s in inventory['sources'])
doc = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The catalyst and its counterpart · Ada</title><style>
:root{color-scheme:light;--paper:#f4f1e9;--ink:#202224;--line:#cdc8bd;--accent:#275e69}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}main{max-width:1380px;margin:auto;padding:48px 34px 90px}header{max-width:920px;margin-bottom:34px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.15em;color:var(--accent)}h1{font:clamp(38px,5vw,66px)/1.06 Georgia,serif;max-width:800px;margin:18px 0}h2{font:32px/1.2 Georgia,serif;margin:50px 0 16px}h3{font:23px Georgia,serif}p{max-width:850px}a{color:var(--accent);text-underline-offset:3px}nav{display:flex;flex-wrap:wrap;gap:12px 23px;border-block:1px solid var(--line);padding:16px 0}.status{font-size:14px;color:#575752;max-width:900px}.table-wrap{overflow:auto}table{width:100%;border-collapse:collapse;font-size:15px}th,td{text-align:left;vertical-align:top;padding:16px 14px;border-bottom:1px solid var(--line)}thead{background:#e3e4df}th small{display:block;font-weight:400;color:#62655f;font-size:12px}td a{font-size:13px}#powers th{width:13%}#powers td{width:29%}li{margin:9px 0;max-width:940px}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.card{padding:22px;border:1px solid var(--line);background:#faf8f3}.card p{font-size:15px}.proposal{border-left:4px solid var(--accent);padding:10px 25px;background:#e9efeb;max-width:1000px}.proposal h3{margin-top:12px}.source-list{font-size:13px;overflow-wrap:anywhere}details{margin-top:30px}footer{border-top:1px solid var(--line);margin-top:60px;padding-top:20px;font-size:13px}@media(max-width:800px){main{padding:24px 18px}.cards{grid-template-columns:1fr}table{min-width:960px}}@media print{main{padding:0}nav{display:none}table{font-size:10px}th,td{padding:7px}h2{break-after:avoid}tr,.card{break-inside:avoid}}
</style></head><body><main><header><div class="eyebrow">Endless Museum / 12 October 2026 / source inventory</div><h1>The catalyst and its counterpart</h1><p>The sphere is the material held between the hands. A gesture gives it a direction; an operation gives it an effect; a receiver decides what that effect can change.</p><p class="status">STATUS</p></header><nav><a href="#powers">10 powers and their companions</a><a href="#field">The held orb</a><a href="#editors">7 editing tools</a><a href="#arena">The first arena</a><a href="#colour">Colour Grid</a><a href="inventory.json">Editable inventory</a></nav>
<section id="powers"><h2>What the code already contains</h2><p>These are source-verified behaviours. Availability depends on unlocks, configuration and receiver. A projectile's appearance, its direct effect and a companion's later power are separate parts of the system.</p><div class="table-wrap"><table><thead><tr><th>Mode</th><th>What the shot does</th><th>What a companion can do</th><th>Boundary to keep visible</th></tr></thead><tbody>MODES</tbody></table></div></section>
<section id="field"><h2>The reference already has a relative in Ada</h2><p>Your image places luminous matter between two hands. Ada has a corresponding gesture prototype: two hands sustain a field; one hand presents a short burst. It is currently bootstrapped by the OrbTestChamber test fixture.</p><div class="cards"><article class="card"><h3>Hold</h3><p>Two palms close together, away from the head, form the orb. Reach changes its influence length.</p></article><article class="card"><h3>Project</h3><p>One hand presents a brief field burst and then cools. The existing projectile controller supplies a separate aimed-shot action.</p></article><article class="card"><h3>Affect</h3><p>Nearby compatible creatures accumulate exposure. Current field modes share this relationship-state effect despite differing visuals.</p></article></div><p>FIELDLINK</p></section>
<section id="editors"><h2>The catalyst also edits the museum</h2><p>These seven authoring modes already share the controller. They should not automatically become seven required lessons or seven player rewards.</p><div class="table-wrap"><table><thead><tr><th>Tool</th><th>Action</th><th>Scope</th></tr></thead><tbody>TOOLS</tbody></table></div><p class="status">Editor save actions can write map data through existing save services. This inventory did not invoke them.</p></section>
<section><h2>What the inventory changes in our understanding</h2>FINDINGS</section>
<section id="arena"><h2>Start with the counterpart arena</h2><p>There are ten mode-test arenas and eight binding/interaction arenas outside the main spine. The existing Primitives pair is a useful starting point. The mismatch arena already asks which source determines a creature's eventual lineage.</p><p>ARENALINKS</p><div class="proposal"><div class="eyebrow">Proposed next encounter / not implemented</div><h3>Keep a passage open</h3><p>A counterpart sends a visible pulse across a passage. The player can interrupt or redirect that pulse, or make a shelter. The objective is to gain enough room and time to pass, or protect a chosen sculpture. The same strange body can remain present afterwards.</p><p>Keep the held sphere and counterpart visibly related. Indicate danger through the preparation, direction and timing of an action. Friendship can be another outcome; it need not be the admission price for a body to remain in the room.</p><p>A skull-like mask could carry this behaviour, but changing the skin alone would leave the underlying reward structure untouched. Start by making one action legible and enjoyable.</p></div><h3>Ways shooting can matter</h3>INCENTIVES<h3>What a first test should establish</h3>CHECKS</section>
<section id="colour"><h2>Let one shot leave one colour</h2><p>The native chromatic shot already changes nearby grid cubes, but it also changes their transforms and emits smaller cubes. The Colour Grid address lesson already provides the more focused operation: select an actual cell, edit its stored colour, then reapply a rule.</p><p>The proposed connection is an impact-to-address adapter into that lesson. Keep geometry and collision fixed. Show which cell changed, retain its colour in the lesson's live state, and let the existing rule reapplication overwrite the exception. Cross-hall or disk persistence would be an additional, explicit decision.</p><p>COLOURLINK</p></section>
<section><h2>What is threatening?</h2><p>Kristeva's account of abjection concerns disturbances of the boundaries supporting identity and order. It does not give us a test for which body deserves to be attacked. Ada can use this as a question about the player's learned response to a form. <a href="https://courses.lsa.umich.edu/jptw/wp-content/uploads/sites/23/2017/08/Kristeva-PowersofHorror.pdf">Powers of Horror, opening chapter, p. 4</a>.</p><p>Our design interpretation: an altered body can remain desirable, uncanny or unknown. A particular action can still injure, trap or overwhelm. Its relation to the player can change without making it visually normal.</p><p>The current shoot-to-friend mechanic needs a second reading: the first hit can assign a lineage and repeated hits make the creature useful. That can be enjoyable and still leave a question about compulsory assimilation. Include a meaningful outcome where the counterpart retains its difference and the player has room to continue.</p></section>
<details><summary>Source files and evidence scope</summary><p>All listed source paths exist. Their SHA-256 fingerprints are recorded in inventory.json. Existing tests were inspected, not rerun. This pass does not certify current headset reach, performance, arena feel or cross-hall persistence.</p><ul class="source-list">SOURCES</ul></details><footer>Only this review folder was created. Museum scripts, maps, tutorial.md and final.md were not edited. The inventory is a dated reading of current source; the arena and Colour Grid adapter remain proposals.</footer></main></body></html>'''
for key, value in {
    "STATUS": E(inventory['status']), "MODES": mode_rows, "TOOLS": tool_rows,
    "FIELDLINK": source_link(BASE + "orb_gesture_detector.gd", "Gesture source") + " · " + source_link(BASE + "catalyst_orb.gd", "Orb receiver source"),
    "FINDINGS": bullets(inventory['important_findings']),
    "ARENALINKS": source_link("commons/maps/CatalystLab_02_Pair_Primitives/map_data.json", "Existing Primitives pair") + " · " + source_link("commons/maps/CatalystLab_05_Mismatch/map_data.json", "Existing mismatch arena"),
    "INCENTIVES": bullets(["Interrupt an imminent impact: aim, timing and defence.", "Redirect a moving body or pulse toward a useful receiver: angle, trajectory and consequence.", "Protect a sculpture or temporary shelter: an objective beyond the player's health.", "Recolour an addressed surface or leave a spatial mark: visible authorship.", "Create a temporary crossing or recruit a companion: access and cooperation."]),
    "CHECKS": bullets(inventory['proposal']['first_checks']),
    "COLOURLINK": source_link("algorithms/color/gridcolorizer/address_lesson.gd", "Current addressed colour operation"),
    "SOURCES": sources,
}.items():
    doc = doc.replace(key, value)
(OUT / "index.html").write_text(doc, encoding="utf-8")

# Verify the published inventory against the actual registries and source files.
main_source = (ROOT / (BASE + "becoming_catalyst.gd")).read_text(encoding="utf-8-sig")
defs = main_source.split("const MODE_DEFS:", 1)[1].split("\n]", 1)[0]
mode_ids = re.findall(r'\{"id":\s*"([^"]+)"', defs)
assert set(mode_ids) == {r[0] for r in rows} | {r[0] for r in tools}
assert len(rows) == 10 and len(tools) == 7
for source in inventory['sources']:
    assert hashlib.sha256((ROOT / source['path']).read_bytes()).hexdigest() == source['sha256']
for seq, count in [('catalyst_test', 10), ('catalyst_lab', 8)]:
    data = json.loads((ROOT / f'commons/maps/sequences/{seq}.json').read_text(encoding='utf-8-sig'))['sequences'][seq]
    assert len(data['maps']) == count
    assert all((ROOT / f'commons/maps/{m}/map_data.json').is_file() for m in data['maps'])
for match in re.finditer(r'href="(\.\./\.\./\.\./\.\./[^"#]+)"', doc):
    assert (OUT / html.unescape(match.group(1))).resolve().is_file()
checks = {"status": "pass", "scope": "Publication, exact roster, arena counts, source links and source fingerprints only", "projectile_modes": 10, "editor_tools": 7, "mode_arenas": 10, "binding_arenas": 8, "source_files": len(source_paths), "godot_run": False, "headset_test": False, "runtime_files_modified": False}
(OUT / "checks.json").write_text(json.dumps(checks, indent=2) + "\n", encoding="utf-8")
print(json.dumps(checks))
