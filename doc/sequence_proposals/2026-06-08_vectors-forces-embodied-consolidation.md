# Vectors & Forces — Embodied-First Consolidation

**Date:** 2026-06-08
**Status:** proposal / audit (step 1 of the consolidation plan)
**Author:** session with palle

## The steering principle

> **Feel the vector with your body.** Every principle is taught through a *playable mechanic* — a launch pad, a catapult, a whirlpool, a two-handed vector you build with your hands — not through an arrow diagram you read.

The models are already in the project and they are the good ones:

- **`force_pad`** — step on the glowing pad, it sets your velocity (forward+up). You *are* launched. F=ma you feel in the legs.
- **`human_catapult`** — stand in the basket, it throws *you*. Projectile motion, embodied.
- **`force_vortex`** — a whirlpool Area3D captures you and applies a swirling field every frame. You ride the vector field.
- **`vector_arena`** — LEFT trigger places point A at your left hand, RIGHT places B at your right; the vector appears between them. You build a·b with your arms.
- **`mortar_vector_siege`** — grab the mortar, aim (a direction vector), fire at a drone swarm. Aiming is vectors.

Everything below is sorted by **how embodied it is**, and the consolidated arc is built from the most embodied examples first.

## The three kinds of example

| Kind | Definition | Role in the arc |
|---|---|---|
| 🎮 **Embodied / playable** | the player *is* the vector — launched, thrown, swept, aiming, building with hands | **Map heroes. Build more of these.** |
| 👁 **Visual spectacle** | you watch emergent dynamics (orbits, chaos, swarms, fields) | feature as payoff / backdrop |
| 📐 **Abstract diagram** | arrows, projectors, slope/area readouts | support label, or → museum only |

The calculus/`change` content (slope, Riemann, FTC) is almost entirely 📐 — so under this steering it goes **light**: only the one idea that *can* be embodied (velocity arrow = the player's own derivative) earns a place in the arc; the rest become reference panels or museum exhibits.

## Inventory by principle

| Principle | Best embodied example (🎮) | Spectacle (👁) | Diagram (📐) | Verdict |
|---|---|---|---|---|
| Direction + magnitude | **`vector_arena`** (two-handed) | — | `VectorBasics`, `basis_vectors_rig` | hero + support |
| Addition / subtraction | **`vector_arena`** (A→B path) | `CombinedForcesDemo` | `vector_addition_demo`, `vector_subtraction_demo` | **needs a stronger toy** |
| Dot product (alignment) | — *(gap)* | `WorkEnergyDemo` | `dot_product_projector` | **BUILD embodied** |
| Cross product / torque | `gyroscope_gadget`, `paddle_wheel_gadget` | — | `TorqueDemo`, `VectorCrossProduct` | promote gadget |
| Projection / reflection | — *(gap)* | — | `vector_projection_demo`, `normal_force_demo`, `vector_reflection` | **BUILD embodied** |
| Derivative = velocity | **player velocity arrow** (run, watch it grow) | — | `slope_tangent_demo`, `derivative_pair` | embody via player motion |
| Integral / accumulation | — *(weak fit)* | — | `integral_area`, `riemann_pump`, `ftc_bridge` | → museum / reference |
| Vector field / flow | **`force_vortex`** (ride it) | `VectorFieldFlow`, `weather_vector_field`, `particle_flow_swarm` | `vector_field_grid` | hero + spectacle |
| F = ma / launch | **`force_pad`**, **`human_catapult`**, `catapult` | `firework_launcher` | `ForceMagnitudeDemo` | heroes |
| Springs (Hooke) | `spring_scale_gadget`, `mass_spring_damper` | `spring_system` | — | promote gadget |
| Friction / drag | — *(gap)* | `example_2_5_fluid_resistance_vr` | — | **BUILD a "drag lane" toy** |
| Attraction / repulsion | `mortar_vector_siege` (targets) | `chaos_attractor`, `force_fields` | `exercise_1_8_attraction` | spectacle + aim toy |
| Throwing / projectile | **`VectorThrowing`**, `throw_ball_sphere`, `vector_drone`, `gravity_gun_test_scene` | `sphere_splitting_showcase` | — | heroes |
| Destruction (impulse) | **`destructibles/*`** (throw, shatter) | voronoi/octree shatter | — | feature in arena |
| N-body / chaos | — | **`three_body_problem`**, `nbody_simulation`, `forcedirected3d` | — | spectacle finale |
| Targeting | `mortar_vector_siege`, `laser_turret` (dodge) | `TurretTargeting` | `hl_turret_vectors` | arena hazard |
| Steering | `noc_5_*` (16, watch/lead agents) | flow/seek/arrive | — | living backdrop |

Source folders: `algorithms/vectors/00_…11_`, `noc_ch01`, `shared/gadgets`, `algorithms/change/`, `algorithms/physics/`. Registries: `force_pad`, `human_catapult`, `force_vortex`, `vector_arena`, `mortar_vector_siege`, `catapult`, `steering` (16), `physics_simulation` (91), `vectors`, `vectors_demos`, `substrate_vectors`, `change` (12).

## The 6-map arc — each anchored by a playable hero

| # | Map | What the player DOES (hero) | Principle | Support (📐/👁) |
|---|---|---|---|---|
| 1 | **Build-A-Vector** | `vector_arena`: place A and B with your two hands; walk the A→B path | direction, magnitude, add/sub | VectorBasics arrows as readout |
| 2 | **Operations Playground** | crank a `gyroscope`/`paddle_wheel` (torque = cross), align a panel to score (dot), cast a shadow (projection) — **mostly NEW builds** | dot, cross, projection | dot_product_projector, TorqueDemo |
| 3 | **Velocity** | run, dash, drift — your own **velocity arrow** grows/shrinks; acceleration felt as F=ma preview | derivative = rate | slope_tangent_demo panel |
| 4 | **The Field** | step into **`force_vortex`**; ride the flow field's streamlines | vector field / flow | VectorFieldFlow spectacle, vector_field_grid |
| 5 | **Launch** | **`force_pad`** + **`human_catapult`** + springs: get thrown, feel F=ma and Hooke | F=ma, gravity, springs | ForceMagnitudeDemo |
| 6 | **Arena** | **`mortar_vector_siege`** + throwing + gravity gun + destructibles; `three_body` orbiting overhead as spectacle | systems, chaos, combat | ForcesArena, n-body backdrop |

Arc shape: *build a vector with your hands → play with what you can do to it → feel it as your own motion → get swept by a field → get launched → loose in an arena.* Every step is a toy; the diagrams are wall labels.

## Friend / Foe / Hazard — the stakes layer

Vectors/forces are the **grammar**; friend/foe/hazard are the **stakes**. This arc (spine seq 5, early) is where the player meets their *first* hazard, *first* foe, and *first* friend-making — and each is taught through the **same embodied mechanic** as the map's vector/force lesson. The project already has every piece: `becoming_catalyst` (the bracelet/tool), `catalyst_foe` + `catalyst_vent` (the unifying enemy that phase-shifts foe↔friend, with peer infection), the `h:fire/death/electric/toxic/vacuum` DangerZones, the ~60-creature hazard library, and `DeathEffect` (the restart feedback loop). The foe carries the **FOE → WARY → NEUTRAL → CURIOUS → FRIEND** personality arc — and this is the sequence where that arc *begins*.

| # | Map | Vector/force lesson | Threat / relation beat (the introduction) | Systems used |
|---|---|---|---|---|
| 1 | Build-A-Vector | build a vector | **Safe.** Meet the `becoming_catalyst` bracelet — your tool. No threat yet. | becoming_catalyst |
| 2 | Operations | dot/cross/projection | First **NEUTRAL creature** — a calm target you aim/align at. It ignores you. Aiming *is* the dot product. | a docile creature (e.g. `mushroom`, gentle `goomba_box`) |
| 3 | Velocity | derivative = velocity | First **HAZARD** — a moving `h:fire`/`h:electric` danger you out-run; velocity literally keeps you alive. First taste of `DeathEffect` + restart. | DangerZone (`h:fire`), DeathEffect |
| 4 | The Field | vector field / flow | The **`force_vortex` is the hazard** — a field that sweeps you toward danger; a field-borne swarm rides the current. Read the field or get pulled in. | force_vortex, swarm_hive |
| 5 | Launch | F=ma / springs | First **FOE** — a cube foe erupts from a `catalyst_vent`; use `force_pad`/throws to deal with it. Force as self-defense. | catalyst_foe + catalyst_vent, force_pad |
| 6 | Arena | systems / chaos / combat | Full **FOE encounter** (mortar vs drone swarm, throwing) → then the **catalyst chamber finale: befriend a foe.** Touch a FOE with the catalyst, watch it shift WARY → CURIOUS → FRIEND. The arc's emotional turn — and the game's whole relational thesis, introduced here. | mortar_vector_siege, catalyst_foe (phase-shift), becoming_catalyst |

So the threat escalation rides the force escalation: **tool → neutral target → environmental hazard → hazard field → first foe → foe swarm + first friend.** You learn to aim by aiming at a creature; you learn velocity because a hazard chases you; you learn fields because a vortex is trying to eat you; you learn projectiles by throwing at foes; and the payoff isn't a kill — it's a **conversion**: your first FOE becomes your first FRIEND via the catalyst. That single beat seeds the personality arc the rest of the spine pays off.

This mirrors the established **catalyst-chamber pattern** (last map of each sequence = a chamber with catalyst + creatures + science screen) and slots cleanly after `change`'s `Chamber_Change`, which already introduces the *sustain* affordance and "the first foe whose state shifts under sustained contact." Forces map 6 is that chamber's louder sequel.

### Particle-effect vocabulary (dress the hazards & forces)

The hazards and force fields should *look* dangerous/alive, using particle effects already in the repo. (Note: the referenced `res://scenes/particle_gallery/…` path isn't in this checkout — moved/renamed — but the equivalent effects are here and reusable.)

| Effect | Use | Source in repo |
|---|---|---|
| **Fire** | `h:fire` hazard, fire-bolt foe attacks | `commons/hazards/fireball/fireball.gd`, `algorithms/particles/particle_campfire/`, `commons/hazards/armadillo_droideka/fire_bolt.gd` |
| **Electric / plasma** | `h:electric` hazard, arc fields | `commons/hazards/plasma/plasma_critter.gd` |
| **Sparks / bursts** | launch-pad ignition, impacts, fireworks payoff | `algorithms/physicssimulation/fireworklauncher/FireworkLauncher.gd` |
| **Force-on-particles** | the field maps (4) — particles pushed by attract/repel | `algorithms/particles/example_4_6_particle_repeller_vr.gd`, `example_4_3_particle_emitter_vr.gd`, `example_4_4_multiple_emitters_vr.gd` |
| **Lifetime curves / sub-emitters** | trails, secondary bursts (a force-pad's plume, a vortex's spray) | `algorithms/particles/lifetime_curves/`, `algorithms/particles/sub_emitters/` |

The NoC Ch.4 particle set (`algorithms/particles/example_4_*`) is itself a **forces-on-particles** demo family — emitters, multiple emitters, repellers — so it doubles as both the visual dressing *and* a legitimate "forces acting on a particle system" teaching toy for maps 4–6. Worth promoting the repeller/emitter ones to placeable artifacts alongside the heroes.

## What to BUILD (more embodied examples — the priority)

These are the gaps where a principle currently has only a 📐 diagram and deserves a 🎮 toy. New artifacts, 3-file pattern, grid-placeable:

1. **Dot-Product Aligner** — aim a solar panel / sail at a moving sun; score rises as `a·b → 1`. Alignment you can feel.
2. **Torque Crank / Cross spinner** — promote `gyroscope_gadget`: push a lever off-axis, the perpendicular (cross product) spins a flywheel you can see and stop.
3. **Projection Shadow** — a light + a wall; rotate an object, its shadow length = the projection. Reflection variant = a mirror bounce game.
4. **Drag Lane** — run through air / water / honey strips; resistance scales with v (and v²). Friction felt in the legs.
5. **Launch-Pad combo course** — angled `force_pad` variants chained into a parkour (the user likes the pad game): vary the launch vector, time the jumps.
6. **Two-hand Add/Subtract** — extend `vector_arena`: place two vectors, snap them head-to-tail to see the sum; flip one for subtraction.

(Heroes for maps 1, 4, 5, 6 already exist and just need placing; map 2 and the drag/dot/projection toys are the real build work — exactly the "more interactive examples" you asked for.)

## Where everything else goes

- **Museum (`vectorforcesmuseum`)** — every promoted artifact becomes an exhibit, including the 📐 diagrams and the 👁 spectacles that don't anchor a map. Nothing is cut; the abstract demos live here as the "reference wing."
- **`physicssimulation` (91 artifacts)** — stays as the deep branch for players who want the full physics sandbox after the spine arc.
- **Calculus (`change` 📐 set)** — `integral_area`, `riemann_pump`, `ftc_bridge`, `partial_derivative_terrain` move to a reference panel / museum alcove; only `velocity_arrow` is embodied into map 3.

## Promotion work (scenes → placeable artifacts)

Most `noc_ch01/*`, throwing/destructibles, and turret examples are **full scenes**, not grid artifacts. To be droppable in maps with the placement editor (real-3D-from-above + structure paint, just built), they need the 3-file artifact pattern (`extends Node3D`, procedural `_ready()`, `apply_grid_config()`, registry entry). Batch in principle order; prioritize the ones that anchor a map.

## Spine bookkeeping

- Fold vestigial `vectors` (already "MERGED INTO FORCES") away.
- Decide `change`'s fate: either keep it as a thin F_order calculus stop (reference) **or** dissolve its embodiable idea into the forces arc (map 3) and museum the rest. Recommendation: **dissolve** — it serves the embodied-first goal and removes a scaffolded sequence.
- Update `curriculum_spine.json` + `lab_evolution` once the 6-map arc is real.

## Next concrete step

Pick one and I'll start:
- **(a)** Build the first new embodied toy — the **Dot-Product Aligner**, the **Launch-Pad combo course**, or a **hazard-dodge Drag Lane** (most fun, fills the biggest gap).
- **(b)** Build the **map-6 catalyst chamber** — the first FOE → FRIEND conversion (vent foe + `becoming_catalyst` + the WARY→CURIOUS→FRIEND shift). The emotional payoff and the introduction of the whole friend/foe/hazard layer in one map.
- **(c)** Promote the existing heroes (`force_pad`, `human_catapult`, `force_vortex`, `vector_arena`, `mortar_vector_siege`) into the 6-map layout — wiring in one hazard (`h:fire`) and one vent foe — and walk it end-to-end.
- **(d)** Stand up the museum wing first so nothing feels lost while we trim the arc.
