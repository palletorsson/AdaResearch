# Sequence Scenarios — hazard × theme event × catalyst × friend/foe

> 2026-07-11. One small scenario per spine sequence: what the world's misalignment is (static
> hazard), the moment the capability unlocks (theme event), which catalyst mode it is, and what
> the foe becomes (friend power). Grounded in soft_stages.json (verbs, enemies.kind,
> hazards.unlock_types are quoted from data, not invented).
>
> **Status flags** — the discipline that keeps this from becoming design fiction:
> **REAL** = playable today · **NEXT** = one content/wiring pass away (systems exist) ·
> **LATER** = needs new code. A scenario may not enter soft_stages until its map exists.

## The grammar (one sentence)

The world is misaligned before the critters are: **static hazard** poses the sequence's problem
in space; the **theme event** is the player enacting the sequence's truth (that's when the
capability lands — not at the boundary); the **catalyst mode** is the truth as a verb; the
**friend power** is the truth given back as a lasting ability — usually the answer to a hazard
met earlier. Chamber placement rule: *the chamber follows the event, not the boundary* —
teach → theme event (unlock) → chamber (arena) → reflection → exit.

## Act I — the world is the opponent (1–8, minus 7)

**1 · primitives** — goo / verbs: observe, grab, snap. The Lab_Death gallery, rescued into the
sequence as a safe "dumb ways to die" museum: each of the six DangerZone types behind a short,
survivable crossing (death flow is forgiving: teleport-to-spawn + 3s immunity). Theme event:
lifting the first catalyst off the pedestal — the primal grab IS primitives. Foes appear only
at the end (Chamber_Primitives, vents REAL). First conversion → **shield**. *(NEXT: wire
Lab_Death into primitives.json; chamber loop already REAL.)*

**2 · transformation** — transport / miura_crawler. The fire pit. Trans_Pit is the limit case:
fire you cannot un-burn — irreversible change. Theme event: crossing it — `unlock_event:
map_completed:Trans_Pit` **(REAL, shipped today)**. The miura_crawler is met here as the first
creature; TRANSPORT friends shove path blocks. Power: **porter**. *(NEXT: Chamber_Transformation
placed after Trans_Pit in the sequence JSON, with a vent.)*

**3 · symmetry** — no mode (honest gap). Hazard: electric fences laid out under a wallpaper
group; the crossing is the one cell where the symmetry breaks. Finding the asymmetry is the
theme event (variant B `notify_theme_event` from a floor trigger). No foes — creatures appear
only as mirrored pairs behind glass. *(NEXT for hazard placement; the symmetry-break trigger is
a small artifact.)*

**4 · array_tutorial** — mode `array` (DESIGN-ONLY as projectile) / gridagent / verbs:
snap_place, reorder. Hazard: an electric floor firing row-by-row in array order — you read the
index pattern to time the run. Theme event: `snap_place` — placing the missing element completes
the array and bridges the gap. Note: `array` may never need to be a projectile — its verb is
placement, and the catalyst already has placement modes. Mode ≠ gun. *(NEXT: timed rows need a
duty-cycle on DangerZone — small; see change.)*

**5 · color** — chromatic / kaleidocycle_enemy / verbs: paint, shoot_color. Hazard: toxic pools
where only cells matching the shown hue are safe — reading color as information. Theme event:
first `paint` act recolors a pool crossable. Foe: the kaleidocycle (REAL creature). CHROMA
friends grant **neutralizer** — a friend standing in a zone mutes it: the power is this
sequence's own hazard, answered. *(LATER: hue-keyed DangerZone variant.)*

**6 · change** — mode `change` (DESIGN-ONLY) / verbs: trace, sustain. Hazard: fire that
breathes — zones with an on/off duty cycle. The crossing is pure timing: change is only visible
to those who wait and `trace`. Theme event: a full crossing during the off-phase (`sustain`).
*(NEXT: add `duty:on_s:off_s` config to DangerZone — one small additive param, unlocks
sequences 4 and 6 both.)*

**8 · formfinding** — no mode (honest gap). Hazard: vacuum flanking a catenary bridge — the
hanging-chain path is the only survivable form. Walking the form the forces found IS
formfinding. No foes; the sequence stays contemplative. *(NEXT: h:vacuum placement, bridge
geometry exists in structure layer.)*

## Act II — the critters arrive, the catalyst answers (7, 9–19)

**7 · forces** — forces mode / SWARM kind / kresling_spire, force_field, goomba_box,
shell_roller, spring_hopper (all named in data). The first real vent battle. And the first
**f: force field** placement — the dual hazard that pushes you off the ledge OR launches you
across, depending on approach: the static prefiguration of the foe→friend flip, met one
sequence before the flip matters. Theme event: first `force_shield` deflect. Power: **launcher**
(friends cluster underfoot → jump boost). *(NEXT: bind the f: scene — registry entry exists
empty; vents are one token per map.)*

**9 · wavefunctions** — waveform / waterbomb_enemy. Hazard: electric zones pulsing as a standing
wave — the nodes are still, and standing at a node is understanding. Theme event:
`tune_frequency` to flatten a barrier's amplitude to zero. WAVE friends slow-pulse foes; power:
**calmer**. *(LATER: phase-linked zone group — needs a small conductor node.)*

**10 · randomness** — chaos / SWARM / octapod_crawler, plasma_critter. Hazard: a fire minefield
re-rolled on every entry — you can't memorize it, only reason about density (expectation, not
map). Theme event: `entropy_trigger` — the first deliberate dice roll. Power: **decoy** (foes
chase the chaotic friend). *(NEXT: re-roll-on-load is a map loader seed param.)*

**11 · noise** — no mode / SWARM kind / verb: sculpt_terrain. Hazard: toxic marsh distributed by
a noise field — safe islands follow the gradient; you learn to read coherent randomness.
Theme event: `sculpt_terrain` raising a causeway — the crossing tool is the sequence's own verb.
No new mode is honest here: your existing friends are the tools. *(NEXT: noise-sampled h:toxic
placement is a generator one-liner.)*

**12 · cellularautomata** — cellular / DRAINFRIEND / armadillo_droideka. Hazard: an electric
floor running Life — still-lifes are safe islands, gliders sweep the corridor on the tick.
Theme event: `seed_life` — seeding a still-life to make your own island. DRAINFRIEND is the
counter-current: caught foes drag a friend back one step — the second law, embodied. Power:
**replicator** (conversions yield two). *(LATER: CA-driven zone grid — the showpiece hazard.)*

**13 · fractals** — fractal / origami_droideka; fractal_hydra REAL. Hazard: the floor is a
Sierpinski carpet over death-void — the walkable set IS the fractal, and every zoom level walks
the same. Theme event: `iterate` — recursing the floor one level deeper to reach the exit.
FRACTAL friends split-convert (second-nearest foe advances too). Power: **splitter**. *(NEXT:
Sierpinski structure layer is generator output; gen tools exist.)*

**14 · lsystems** — branching / scissor_stalker. Hazard: toxic ground everywhere; the only safe
path is along branches you grow. Theme event: `write_rule` — the grammar that grows the bridge.
The crossing is authored, not found. Power: **bridger** — friends grow walkable tendrils: the
power is the sequence's mechanic, made permanent. *(NEXT: grown-branch walkability via
path_passable group — path_block system exists.)*

**15 · proceduralgeneration** — no mode / DRAINFRIEND / sphere_droideka. Hazard: the minefield
is regenerated from a visible seed each visit — you learn the generator, not the layout. The
bricoleur golem (design) rebuilds itself from the environment: conversion doesn't stick until
you starve its inputs. *(LATER.)*

**16 · softbodies** — no mode / TRANSPORT kind / waterbomb_hopper. Hazard: a deformable floor
over vacuum — your own weight is the hazard; lambda tuning (`tune_lambda`) stiffens the crossing.
*(LATER: needs soft-floor physics tie-in.)*

**17 · isosurfaces** — mode `isosurface` (DESIGN-ONLY) / verbs: observe, grab, snap. The
sequence h:radiation was born for: a scalar dose field with falloff, and the survivable path is
the isoline. Walking the isosurface of an invisible field — the concept, as a crossing. Theme
event: tracing one full isoline. *(NEXT: h:radiation finally gets its first placement + its
missing visual; field falloff = per-cell dps notation that already exists.)*

**18 · boolean_surfaces** — mode `csg` (DESIGN-ONLY). Hazard: two overlapping danger volumes;
the safe tunnel is their CSG difference. Union, intersection, difference — walked, not clicked.
*(NEXT: pure placement of overlapping h: boxes.)*

**19 · swarmintelligence** — swarm mode / SWARM kind. The full vent war: multiple vents, waves,
your flock against theirs. Theme event: `embody_flock` — first time your friends outnumber the
foes on the field. Power: **escort** (shield-wall). *(REAL loop in test ring; NEXT: spine
chamber with 2+ vents.)*

## Act III — the template inverts (20–24)

**20 · machinelearning** — no mode / DRAINFRIEND / verbs: train, evolve. The hazard learns YOU:
zones migrate toward your habitual routes between visits (gradient descent on your paths).
Crossing means being unpredictable — the anti-habit room. Friends are training data: the
gradient_hunter (design) converts only when it can no longer predict you. *(LATER.)*

**21 · graphtheory** — no mode / TRANSPORT kind / verbs: connect_nodes, traverse_graph. Hazard:
only edges are walkable over void; some edges are missing. PORTER/TRANSPORT friends carry
path blocks to complete the graph — the Act I power, graduated into topology. *(NEXT: edge maps
are structure-layer content.)*

**22 · foundationscrisis** — no mode / DRAINFRIEND / verbs: hold_paradox, walk_impossible.
**The template breaks, deliberately.** The paradox_stalker cannot be converted — the arc loops
at curious→foe. There is an h:death moat whose crossing is provably impossible under the room's
rules; the exit is accepting that, and stepping outside the system (the first time removing the
bracelet is the verb). The catalyst's failure here is the pedagogy — 24 identical hero arcs
would be a lie about incompleteness. *(LATER, and worth it.)*

**23 · qfeplaboratory** — no mode / verbs: tune_phi, tune_delta_e. The reunion chamber: every
hazard type from the spine reappears once, and every friend kind you ever converted is already
there, each answering the hazard its sequence taught (bridger over the fire, neutralizer in the
toxic pool, calmer at the electric wave). You tune the full formula while your whole history
walks beside you. *(NEXT once powers have effects — this room is the payoff.)*

**24 · postfoundationscrisis** — no mode / verb: apply_limits. The final act: **giving powers
back**. Each power can be voluntarily released at an altar; each release quiets one hazard
permanently. You end as you began — unarmed — but the world is aligned now. Limits chosen, not
imposed. *(LATER; the save format already supports removal.)*

## Is the grammar right? (sieve pass)

**Q1 — thicken?** Yes: each sequence gets a playable thesis, and hazard/event/mode/power are
four askable questions any collaborator can answer per sequence. The verbs were already in
soft_stages — this reads structure out, more than it invents.

**Q2 — what is foreclosed?** Two risks. (a) *Formula*: 24 identical four-beat arcs would
flatten the grammar into a scoreboard — so the template must break where content demands it
(22 breaks it, 24 inverts it, 3/8/11 stay contemplative with no combat). (b) *Combat framing*:
QFEP is transformation, not conquest — Act I has no enemies at all, the f: field is a hazard
that becomes a gift, and the final act is disarmament. If a scenario only works as a
tower-defense wave, it's wrong.

**Q3 — dark spot?** This document itself. Scenario text is exactly the kind of promise that
produced `array`/`change`/`isosurface`/`csg` — modes named in data with no code behind them.
Hence the status flags, and the rule: a scenario may not enter soft_stages until its map
exists. The flags are the seal-breaker.

## Cheapest unlocking moves (from the LATERs)

1. **DangerZone duty cycle** (`duty:on_s:off_s`) — one additive param unlocks scenarios 4 + 6.
2. **Bind f: force_field scene** — unlocks 7's dual hazard (registry row already exists, empty).
3. **h:radiation visual + first placement** — unlocks 17 and retires a PARTIAL.
4. **Re-roll-on-load seed** — unlocks 10.
5. Chamber-after-event integration in sequence JSONs — unlocks the arc everywhere at once.
