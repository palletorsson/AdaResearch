# Curation — VectorAdvanced (Vector Advanced: Torque, Dynamics & Throwing)

> *"Curation is an argument made with placement."* (curation_station @identity)

## The argument the wall makes

The map is **four islands where vectors stop being observed and start being *done*** — torque, dynamics, attraction/steering, throwing. Its own docs name the throughline twice: the critical essay's "theory becomes embodied skill" and the truth both `summary.md` and `critical.md` single out — **"An orbit is a perpetual fall that always misses the ground."** The map is the place where, in QFEP terms, the state vector S begins to *evolve under rules* (acceleration, orbit, release).

The **baseline** stated this at its thinnest: eight 1×1 plinths in one dead-flat row at `z=0.8, top_height=1.2`, two wordless panels, a `proximity_spawner` hazard parked on a display plinth as if it were an exhibit, and the bouncing island's own collision tool (`vector_projection_reflection_xl`, named explicitly in `summary.md`) left out entirely. A shelf with no centre, no depth, no ladder, no labels.

This wall keeps the **left→right processional** the map already is, but turns the four islands into **four legible bays, each a verb the body performs**:

> **TURN → FALL & SETTLE → PULL → THROW**

It restores the missing projection/reflection exhibit (the tool the bouncing island actually uses), drops the two hazard tokens (`proximity_spawner`, `catalyst_target` are danger-zone utilities, not curated artifacts), gives **every** artifact a 2D-in-3D name plate, and builds a real small→medium→large composition with one raised focal heart and genuine front-to-back depth.

## Reading order (left → right = the walk)

| x | Bay (verb) | Artifact | Tier | Depth z | Prop (why) |
|---|-----------|----------|------|---------|-----------|
| 1.5 | — opener | `VectorFieldFlow` | medium | 2.3 (back) | **station_stage 4×2** — "instructions written in space"; a field is a *ground you read*, set back as the bay's backdrop so the body walks up to it |
| 4.0 | **TURN** | `VectorTorque` | small | 0.7 (fwd) | slim 1×1 plinth @1.2 — "leverage made mathematical"; brought forward, eye height |
| 6.0 | **TURN** | `torque_demo` | small | 1.5 (mid) | slim 1×1 plinth @1.05 — the right-hand-rule restatement, set behind its sibling so the pair reads as a depth-pair, not a line |
| 9.5 | **FALL & SETTLE** | `exercise_1_3` 3D Bouncing Ball | small | 0.6 (fwd) | slim 1×1 plinth @1.1 — "a clock that runs down" |
| 11.5 | **FALL & SETTLE** | `example_1_9` Random Acceleration | small | 1.4 (mid) | slim 1×1 plinth @1.25 — velocity is accumulated acceleration; lifted + set back |
| 13.5 | **FALL & SETTLE** | `exercise_1_5` Accelerate and Decelerate | small | 0.7 (fwd) | slim 1×1 plinth @1.15 — "smooth arrival is a feedback loop" |
| **19.0** | **PULL — the heart** | **`exercise_1_8` Attraction and Orbit** | **small → FOCAL** | **1.6 (own alcove)** | **slim 1×1 plinth raised to 1.35 m, three-colour bar on** — the QFEP centerpiece. Raised high-and-narrow because the plinth's soul says "what you raise high and narrow, you call precious," pulled into its own forward alcove, crowned by the "perpetual fall" panel |
| 21.0 | **PULL — body scale** | `vector_projection_reflection_xl` | large | 2.6 (back) | **station_stage 4×2** — the walk-inside (~5×5 m) plane you *stand on*; goes low + broad + far back as the bay's deep mass, the collision tool the bouncing island reuses |
| 27.5 | **THROW — culmination** | `VectorThrowing` | medium | 2.0 (back) | **station_stage 4×2** — its @identity: "Culmination of VectorAdvanced"; a 3.3 m floor piece, so it goes low + broad as the terminal climax, not on a podium |

**Pillars** at x = -1, 8, 15.5, 24, 30 cut the long run into the four bays (the pillar soul: "one upright, repeated, makes a room out of an open floor"). **Panels** (5) carry the map's *own* lines as wall labels — the entry spine ("Vectors, made to act — turn / fall / pull / throw"), one truth-beat per bay, and the focal's "perpetual fall" crown raised to 2.25 m so it sits over the centerpiece.

## The focal point

**`exercise_1_8_solution_attraction_magnitude_vr` ("Attraction and Orbit") at x=19, on a slim 1×1 plinth raised to 1.35 m, in its own forward alcove (z=1.6), crowned by the "An orbit is a perpetual fall that always misses the ground" panel.**

It is the focal point because it is the truth both `summary.md` and `critical.md` elevate above the others, and the one artifact that *demonstrates* the map's QFEP thesis rather than restating it: complex structure (a stable orbit) emerging from one simple rule (inverse-square pull) with no global coordinator — and the learner deforms it live by grabbing the attractor. Everything left of it is the body learning the rules (turn, fall, settle); everything right of it is the body spending them at scale (decompose by standing on the plane; throw and lose control). Its registry `spatial_needs.platform` already asks for `"pedestal"` — the raised plinth honours that request. Raised + isolated + crowned is the whole plinth argument: *this one, here, by itself, precious.*

## Why these props (meaning, not just size)

- **`station_stage` 4×2 (low, broad) for the three big floor pieces** — `VectorFieldFlow` (3.1 m measured), `vector_projection_reflection_xl` (room-scale, `player_position: inside`), and `VectorThrowing` (4×2 environment, 3.3 m). The stage soul: "raise it a little and admit you are presenting it… low enough to step onto." A field you read, a plane you stand on, and a throwing range are *worlds you enter*, not objects on podiums — so each gets a broad deck and goes to the back as its bay's deep mass.
- **`station_plinth` slim 1×1, sized per meaning** — the six small NOC/torque artifacts each get a tall-narrow podium (`cap_inset` 0.3) at staggered heights 1.05–1.35. The plinth soul: "size IS part of the argument." The focal goes highest (1.35) and isolated; the supporting small beats sit lower and weave forward/back so a bay never reads as a flat shelf.
- **`station_pillar` as dividers** — five uprights turn one ~31 m run into four walk-through rooms, so TURN / FALL / PULL / THROW read as a procession, not a list.
- **`station_panel` as labels (2D-in-3D)** — every plinth carries the artifact's display name as a surface-pinned plate (`caption_text`), and the five wall panels surface the map's *own* truth-beats (the editor hides the artifacts' floating Label3D, so these plates are the only text). The map already wrote these lines; the wall pins them.

## Prop gaps flagged

1. **Sub-1 m artifacts on an oversized foot (the real micro-pedestal gap).** Two artifacts are genuinely sub-1 m by measured AABB, yet the smallest honest base is still a 1×1 plinth whose foot-plate over-claims their ground:
   - `exercise_1_5_solution_accelerate_and_decelerate_vr` — aabb **0.39 × 0.10 m, 0.59 m tall**. A flat little ribbon on a 1 m foot.
   - `exercise_1_8_solution_attraction_magnitude_vr` (the **focal**) — aabb **0.81 × 0.29 m, 0.57 m tall**. The orbit reads small against the plinth cap.
   Both still use the slim 1×1 per the brief, but they want a future **micro-pedestal prop** (~0.4–0.6 m cap, narrow column) so the base stops dwarfing the object. The focal especially would gain from a taller, slimmer column that lifts the orbit to true eye height without a wide tray.
2. **No floor-line / processional-stripe prop.** The four bays would read as one journey from the entry if a faint floor line linked them; the editor's `station_*` kit has no floor-stripe piece yet (same gap noted in the Act 1 wall). Candidate: a thin tiling `station_*` floor-line, or a utilities-layer marker in `map_data.json`.
3. **Artifact-internal gaps (from @identity), not wall-fixable but worth a caption upgrade later:** `torque_demo` wants a wrench/door metaphor + angular-momentum readout; the attraction orbit wants a trail showing orbit history; `VectorThrowing` wants a trajectory-prediction overlay before release. If those land, the bay panels can quote them.

## Sieve pass

- **Q1 — does it thicken the cognitive water?** Yes. The baseline gave eight flat handles and two hazards mistaken for exhibits. This gives four named verbs you walk through, a small→medium→large spread, one focal heart the eye and the argument converge on, depth that rewards orbiting, and the restored projection plane that the bouncing island's collision actually needs. New handles to *think* "vectors as actions," not just objects to look at.
- **Q2 — what is foreclosed?** The wall now strongly asserts the TURN→FALL→PULL→THROW reading and crowns one focal truth. A learner who wanted to read the four islands as co-equal, or to find a different climax (e.g. the throw, which is the literal "culmination"), is gently overruled by the bays, the heights, and the panels. Acceptable for a sub-sequence finale whose job is to consolidate — but it is a real foreclosure, and the throw's demotion to "terminal mass" rather than "focal" is a genuine editorial call, not a free lunch.
- **Q3 — what lives in the dark spot?** The embodied beats — grabbing the attractor and watching the orbit deform, standing on the projection plane, throwing and losing control — are left to the artifacts, not spelled out by the plates. That is generative habitat (room to play and discover), not a sterilising seal. The plates name; the bodies still do the proving.

## What I'd try next

1. **Build the micro-pedestal prop** (gap #1) and re-seat `exercise_1_5` and the focal `exercise_1_8` on it; lift the focal's column without widening its tray.
2. **Capture the composed wall** (`capture_multi_angle.gd --mode=map --target=VectorAdvanced`) and check that (a) the room-scale `vector_projection_reflection_xl` at z=2.6 doesn't overrun the `VectorThrowing` stage, and (b) the focal's 2.25 m panel clears the raised orbit — drop to 2.15 m if they meet.
3. **Add a processional floor line** linking the four bays (gap #2) so the journey reads from the entry.
4. **An exit back-reference panel** past the THROW bay ("you have used the tools with your hands; next, the forces half") to tie the teleporter to the forces sub-sequence the map hands off to.
