# Works that do not fit the Void tower: a survey (2026-11-09)

Palle asked: *"When we converted the artifacts from the endless museum, some of them were too big to fit the void tower,
so they stand a bit strange in the tower. Can we conduct a survey of how many of the artifacts are overflowing and think
about what we can do about it?"*

## How it was measured

The survey measured each work in the built tower: 212 floors and 1,801 works, with each work's placement, scale,
facing and config applied.
- **The box:** each work is measured by its drawn meshes. Parts that are turned at an angle are measured from their vertices, so a round carousel is not read as a square.
- **Not counted:**
  - a film's picture, which is rendered in a separate world
  - edge overlays
  - multimesh instances that are hidden or shrunk to nothing
  - soft-body cloth, whose vertices live in the physics world
- **Ground under it:** a 5 × 5 grid of rays checks each work's footprint for floor under it. The rays ignore the work's own bodies.
- **Tools:**
  - `tools/probes/void_size_survey.gd` measures.
  - `tools/void_size_survey.py run|report` runs it in six chunks, two at a time. Four games at once, or one game that has visited about 80 floors, runs out of memory.
  - `tools/void_fit_pass.py` writes the move proposals.
- **Raw data:** `ada_run/void-size-survey/` (`report.json`, `report.md`, `fit_pass.json`, `fit_pass.md`).

**What counts as overflow:**
- The work leaves the building past the 42 × 18 m slab edge by more than 0.3 m, with no landing or balcony under that part.
- Or it rises through the slab of the floor above. A floor's headroom is the gap up to the floor above minus the slab.
- Or it goes more than 0.3 m down through its own slab outside a shaft. Four works go down through a shaft, which is how the tower is built to work, so they are not counted.

**Displaced:** no part of the work stands over any floor or landing. It is drawn away from the floor it is placed on.

**Counted apart:** 33 deliberate exterior extensions, such as Drink Me and the playground wings.

## The count

| | works | overflowing | displaced | do not fit |
|---|---|---|---|---|
| museum transfer (`f1_`..`f6_` ids) | 1,121 | 273 | 120 | **393 (35 %)** |
| museum restore (`museum-` ids) | 175 | 4 | 1 | 5 (3 %) |
| made in the tower | 505 | 18 | 2 | 20 (4 %) |
| **all** | **1,801** | **295** | **123** | **418 (23 %)** |

So the problem is the museum transfer: about a third of the works that came over in the per-sequence transfer batches
do not fit where they stand. The restore of 19 October placed each work in the free slot farthest from its neighbours
without measuring it (its own comment: "staging positions only"), and the transfers kept each work's museum-hall size.

**How the overflow breaks down:**
- **Past the edge, 229 works:**
  - under 1 m: 37
  - 1–3 m: 90
  - 3–6 m: 71
  - more than 6 m: 31
- **Through the ceiling, 61 works:**
  - under 1 m: 26
  - 1–3 m: 18
  - more than 3 m: 17
- **Down through the floor outside a shaft, 86 works:**
  - under 1 m: 39
  - 1–3 m: 26
  - more than 3 m: 21

**By sequence (works, overflowing, displaced), worst first:**
- machine learning 25 / 20 / 2
- shaders 27 / 14 / 4
- procedural generation 23 / 12 / 3
- isosurfaces 48 / 22 / 4
- soft bodies 62 / 18 / 14
- swarm intelligence 35 / 12 / 6
- forces 80 / 26 / 11
- fractals 65 / 17 / 12
- boolean surfaces 42 / 13 / 5
- L-systems 49 / 16 / 4
- post-foundations crisis 45 / 8 / 9
- noise 38 / 9 / 5
- array 25 / 4 / 3
- tiling 114 / 21 / 9
- wave functions 150 / 18 / 21

**Nearly clean:** primitives (351 works, 10), transformation (159, 7), colour (69, 9) and cellular automata (48, 3).
These are the floors that were curated in the tower.

**Also found, not counted as overflow:**
- 167 works stand over a shaft opening.
- 47 float more than 0.3 m above the slab with placement height 0.
- 90 have no measurable mesh.

## What can be done, by kind

1. **Move: 255 works have a free spot on their own floor.** That is 141 overflowing works plus 114 of the displaced ones. Remedy class across all overflowing works: 210 would fit if moved, 60 need a taller floor, 25 need shrinking or an exterior.
   - `tools/void_fit_pass.py` found each spot: on the slab, off the shafts, round no column, clear of every other work.
   - Distance moved:
     - under 1 m: 4
     - 1–3 m: 101
     - 3–6 m: 88
     - more than 6 m: 62
   - 46 need a quarter turn.
   - These are proposals only. The search knows sizes, not meaning: the order Palle gave the works (`/api/spine-roles`) and the route are not in it.
2. **No room on their own floor: 34 works.** They are smaller than the floor, but the floor is full.
   - Examples: the wind room on Fields (16 × 14 m), the shader passage and pattern garden on Shader_05, three swarm walks, the maze, the tension membrane.
   - Options:
     - another floor of the same sequence
     - the timeline's environment track
     - one of the "candidate" works on that floor goes
3. **Too tall: 60 works.** Their footprint fits but not the 5.6 m of headroom.
   - 36 of them are only 6–8 m tall, about one storey too much.
   - Options:
     - Make a floor that gathers several tall works double height. `tools/insert_void_floor.py` has the levels logic; setting the storey of an existing floor is a small addition.
     - Stand the work under a shaft of the floor above, so it rises through the opening. The tower already does this.
     - Shrink a work that is not at body scale.
   - About 10 are tens of metres tall: the diamonds (48 m), the Gyroid (20 m), the cypress (20 m) and the tube tree (23 m).
4. **Down through the floor: 86 works.** These are mostly pits, basins and wall works sunk into a museum hall floor.
   - Options:
     - Raise them with the placement height.
     - Use the floor's `basin` record, which already cuts a pit into a slab, as on Random_Remove.
     - Move them over a shaft so the descent reads as meant.
5. **Spaces bigger than a floor: 25 works.** Atria, wombs, landscapes, the 40 m evolved-creatures field, the 48 m portal landscape.
   - These are rooms, not objects. Shrinking them breaks what they are, because the body is the measure.
   - Options:
     - a floor of their own, like Drink Me
     - an exterior extension: the playground wings and Drink Me are the precedent
     - their own size settings: `box_size`, `cells`, `clearing_radius` exist on several
   - Per-placement `scale` only for works that are looked at, not walked.
6. **Code faults, not size: about 10 works.**
   - A few works are drawn far from their floor, which points to a mesh at world coordinates. Examples: `joint_learn_walk` at about 1,080 m, ElphabaDress hundreds of metres up, `env_one`'s atmosphere particles at 274 m.
   - Each needs a look at its code.

## Keeping it fixed

- Rerun `python tools/void_size_survey.py run` and then `report` after a curation pass. It takes about 25 minutes, two games at a time.
- The measured boxes could be kept beside the placements, so that the floor editor draws a work's real footprint and the timeline's "add from catalogue" places by size.
- The restore and transfer tools placed by distance from neighbours. A size-aware placement would have avoided most of this.

## First passes: machine learning and shaders (2026-11-09, same day)

Palle: *"start with the moves on machine learning and shaders, but we need to learn the strategies and what works ...
we can build a catalog of strategies that make it easier to fit the work ... In the end it is about conveying an
idea."*

**Mechanisms built:**
- `config.fit` on a placement: `strip` (floor / walls / ceiling, found by shape), `strip_parts`, `keep_parts` and `set`. `set` takes the work's own exported counts and is applied before the work builds. A part that wears a shader is never stripped by shape.
- `void_slab_extension`: a side slab up to 10 m out, on tangled beams down to the floor below.
- `tools/void_fit.py apply|survey|record` and the pass files in `doc/fit-passes/`.

The strategies, with what each pass taught, are in `commons/void/fit_strategies.json`.

**Result:**
- Machine learning: 22 → 3 that don't fit. The three are code cases: two drop something hundreds of metres; one is 0.3 m through a ceiling.
- Shaders: 18 → 0.
- Across 41 works and 4 side slabs:

| strategy | worked | partly |
|---|---|---|
| move | 27 | 1 |
| strip floor | 11 | |
| raise | 9 | 2 |
| turn | 8 | |
| scale | 7 | 2 |
| strip walls | 6 | |
| reduce repeats | 4 | |
| side slab | 6 works on 4 slabs | |

**What was learned:**
- **Machine learning:** the works were built for museum stages. They sat below their origin, and their bodies fell. *Raise* plus *strip floor* fixed most of them.
- **Shaders:** the rooms are the shader. Floor and walls wear it, so stripping did little. They fit by *side slab* and *move*. The playground setup Palle asked for is the real answer: a surface to carry the shader, without a room around it.
- **Order matters:** strip, raise and scale first; then re-measure; then the fit pass. Sizes change, so moves come last.

## The passes since (2026-11-09, same day)

Each sequence was fitted the same way: a pass of strip, raise, scale and turn; a re-measure; the fit pass for moves and
side slabs; then repeat until nothing is left. The cases are in `commons/void/fit_strategies.json`, the pass files in
`doc/fit-passes/`.

Counts are from the recorded cases. "Left" is the run the pass was recorded on; the physics cases come and go from run
to run.

| sequences | not fitting before | fitted | removed | left |
|---|---|---|---|---|
| machine learning | 21 | 18 | 1 | 2: `neural_networks_vr` drops something about 494 m; `transformers_vr` is 0.3 m through a ceiling |
| shaders | 18 | 18 | 0 | 0; the six floors' shader galleries are in the working tree only, waiting for the playground system's commit |
| isosurfaces + soft bodies | 58 | 58 | 0 | 0; `rounded_softbody_test` blows up on some runs |
| procedural generation + swarm | 28 | 26 | 0 | 2: `caverandomwalk` (physics fliers, a taller-floor case) and `rhizomatic_maze_space` (0.8 m through a ceiling) |
| forces + fractals | 55 | 46 | 9 (museum wayfinding) | 0; the ball dropper's balls fall under the slab on some runs |
| L-systems + boolean surfaces | 40 | 40 | 0 | 0; 4 side slabs; no work in another, no column through a work |

**What the L-systems and boolean pass taught:**
- **The survey judges each work alone.** Two works standing in each other, or a tower column through a work, both read
  "fits". After the first pass there were 22 such pairs on these 11 floors, most from works scaled where they stood: a
  scale keeps the box's centre, and the smaller box can land across a column row.
  - `python tools/void_fit.py overlaps <pass.json>` lists them.
  - `python tools/void_fit_pass.py --overlaps` moves them: the one round a column, otherwise the smaller of the pair.
  - Run both after every pass.
- **The columns stand on two rows, z = ±7.** On each row they are at most 10 m apart (x = ±5, ±14, ±20).
  - A work wider than 10 m can never cross a row. Inside the building it must stay within z ±6.5.
  - Anything deeper goes on a side slab, where the deck plus the edge strip gives 11.5 m.
  - Boolean_Works holds two walk-in bays. The cone ("One cut, three rooms", now 0.68) stands in the open middle. The
    Kapoor bay stands on a 10 m south slab, turned so its console faces the floor.
- **Two faults in the fit pass, both fixed.** Both now read the deck from the slab's placement (`slab_decks`,
  `slab_grounds` in `tools/void_size_survey.py`):
  - It read a side slab's measured box as deck. The box also holds the tangled beams, whose feet spread 1 m past the deck.
  - It kept its margin on a north slab's inner edge, which left a 27 cm strip of no ground just inside the edge.
- **Tall works scaled down to fit, not to keep their meaning.** Four L-system works were cut to a quarter or a third of
  their height: the Modulor cypress, the tube tree, the city and the 3D Hilbert curve. If their height is the point, they
  are candidates for a shaft or a taller floor.

## The overlap pass over the five earlier pairs (2026-11-09, same day)

The first five pairs were fitted before the overlap check existed. A fresh survey of their 68 floors found **121
overlaps: 99 were a tower column through a work, 22 were two works standing in each other.** Four passes
(`doc/fit-passes/2026-11-09-overlaps-a..d.json`) cleared all but two cases, and kept two works on purpose.

| remedy | works | what |
|---|---|---|
| move (fit pass `--overlaps`) | 42 | small works a metre or two off a column row |
| slab deepened, work wholly past the column row | 16 | 12 slabs went to 8-10 m; e.g. the force plays, the composition stage, the flow crowd, the ant walk |
| into the open middle (14 x 13 m between the shafts) or an end bay | 7 | the maze, the swarm walks (turned, 0.93-0.95), the firework burst (0.8), the sculpting volume; the fuzzy doorway and the fish school in the east bays |
| scaled into the strip between a shaft and a column row | 3 | the pattern tunnel (0.95), the RD gallery (0.6 -> 0.49), the shapes console (0.72 -> 0.66, its gallery 1.1 m south) |
| own size setting | 2 | the mower's lawn (14 -> 12.4 m), the boid flock (bounds 10.5 m, and a new `boid_boundary_force`) |
| code fix | 2 | the gyroid console's probe rail, the flock's boundary steer |
| kept, with a note in `config.fit` | 2 | the rhizome body (24 x 25 m, walked inside, at its smallest walkable size), the gyroid console (its probe crosses the gyroid by design) |
| slab removed | 2 | empty once their walks moved to the middle |

**Left:**
- `caverandomwalk`: its fliers vary per run, a code case.
- Two of the Unit's drones (`unit-steer`, `unit-rhythm`, another session's uncommitted placements) stand in the boid
  flock's volume.

**What it taught:**
- **The columns stand on two rows, z = ±7.** A work fitted at the slab's edge ended up across a row. The rule now: a
  slab work's inner edge sits at |z| ≥ 7.45.
- **A box is not a body.** Two flags were markers, not size:
  - a VR brush resting 15 m from its 2 m sculpting volume
  - a probe drawn through the work it tests

  Read a work's parts before moving the whole work.
- **A fix that makes a work build can make it overflow.** The gyroid console failed to parse until earlier today.
  Once it built, it stood 2 m past the edge with a 12 m rail. Measure again after any parse fix.
