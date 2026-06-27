# Void Crossing — wall-hangar curation notes

*Sequence: forces. Concept (vector_forces_concept_map): the map's two artifacts live in
**General force / pad** (force_cube) and **Force field (zone)** (vector_machine, force_field_zone).*

## The argument

The map's own thesis (intent.md, and the `force_field_zone` `@identity`): **a force is not a
label on an arrow — it is a region of space with a rule, and changing the rule changes where you
can go.** "Falling isn't a property of the void, it's a property of the field over it." The wall
makes that thesis a walkable sentence read left→right, and stages it as a *growth* of one idea:
the vector gets bigger and more spatial at every station until it becomes a place you cross.

Reading order along +X (the editor re-seats each artifact to its real measured height on its base
and hides its floating Label3D, so the only text is the station plates):

1. **Force Cube** *(small — `General force / pad`)* — "a vector you hold." The vector at its most
   intimate: one push, drawn as an arrow out of a 0.4 m cube. Slim 1×1 plinth, raised **high &
   narrow** (`top_height 1.3`) and set **forward** (z 0.7) — the plinth's own rule: *what you raise
   high and narrow, you call precious.* This is the seed of everything downstream.
2. **Vector Machine** *(small — `Force field (zone)`)* — "the dial of gravity." The control surface
   where the crossing vector is chosen. Slim 1×1 plinth, a touch lower (`top_height 1.05`) and set
   back a step (z 1.25) so the eye reads cube→console as a turn from *holding* a vector to *aiming*
   one.
3. **Field Bench** *(medium — kin, `Force field (zone)`)* — "a vector at every point." Pulled in to
   fill the medium rung of the concept's own ladder: the single vector becomes a sampled field. 2×2
   plinth, mid-height/mid-depth (z 1.7).
4. **Force Field** *(large — kin, `Force field (zone)`)* — the raw field at room scale. Low broad 3×3
   `station_stage`, set **deep** (z 2.6) as the background mass — the field big enough to stand in,
   but not yet given a void to bridge.
5. **Force Field Zone** *(applied — **CENTERPIECE**, the concept's `best`)* — "a force made into a
   place." The 4 m cube where the chosen vector *is* the only physics and the void becomes a step.
   Its own low broad 4×4 stage, set **forward** (z 1.0) with its **own depth**, **framed by two
   `station_pillar` gate-posts** (x 8.5 / 13.5, forward at z 0.5) that turn the open floor into a
   bay — a threshold you cross to reach it. One unmistakable focal point.

So the ladder is the lesson: **hold a vector → aim a vector → a vector everywhere → the field at
scale → the field made into a crossable place.** small → small → medium → large → applied.

## Why each prop (chosen for meaning, not just size)

- **station_plinth, slim 1×1, high** for force_cube / vector_machine — the plinth `@identity` says
  *"size IS part of the argument… raise high and narrow, you call precious."* The two small things
  that you actually pick up and twist get the precious treatment, lifted to hand height.
- **station_plinth 2×2** for field_bench — footprint 4 → the brief's 2–4 band, a low square podium
  that reads "a patch of field," not a precious specimen.
- **station_stage 3×3 / 4×4, low** for force_field / force_field_zone — footprints 9 / 16 → the
  brief's stage band. The stage `@identity`: *"to stage a thing is to raise it a little and admit
  you are presenting it."* The two *worlds* of the map (a field, and a field-as-place) get set low
  and broad — *what you set low and broad, you call a world.*
- **station_pillar ×2** framing the centerpiece — the pillar `@identity`: *"one upright, repeated,
  makes a room out of an open floor."* They build the bay/threshold that the crossing deserves and
  give the focal point architectural weight without a wall behind it.
- **station_panel ×3 (wall, 2D-in-3D)** carry the map's truth-beats as tier headers, not generic
  labels: **"A FORCE IS A PLACE"** over the opening, **"THE FIELD GROWS"** over the bench/field,
  **"THE CROSSING — falling is the field, not the void"** over the centerpiece. The panel's job
  (its `@identity`): *"a place that presents must also explain."*

## 2D-in-3D plate labels (requirement 2)

Every artifact base carries a surface-pinned plate via its prop config — no floating text:
- plinths: `caption_text` = display name ("Force Cube — a vector you hold", "Vector Machine — the
  dial of gravity", "Field Bench — a vector at every point").
- stages: `name_plate` = display name ("Force Field", "Force Field Zone — a force made into a
  place").
- panels: `header` + `lines` carry the three truth-beats above.

## Real 3D composition (requirement 3)

Not a flat line. Depth (z out from wall) is staggered across **six** distinct values
(0.5, 0.7, 1.0, 1.25, 1.7, 2.6) and height across five (`top/step` 0.16, 0.18, 0.95, 1.05, 1.3):
- **Foreground, high:** force_cube (z 0.7, top 1.3) — the precious seed nearest the viewer.
- **Mid:** vector_machine (z 1.25) then field_bench (z 1.7) recede as the idea generalises.
- **Background mass:** force_field as a low broad slab set deep (z 2.6).
- **Focal bay, forward:** force_field_zone steps back out to z 1.0 with its own 4×4 stage, flanked
  by two forward gate-posts (z 0.5) — an alcove/threshold the player walks *into*. Reads cleanly
  left→right from the iso front, and rewards orbiting (free-cam) with a genuine forward-set
  centerpiece behind a gate, a deep background field, and high foreground podiums. No footprint
  overlaps; walkable spacing between every base; the empty mid-floor in front of the field is
  deliberate negative space (the "void" the map is about).

## Baseline (beaten)

The prior `spine_walls.json` entry was a flat line: two 1×1 plinths + one pillar + one 1×1 stage,
all at z 0.8 on one depth, with only force_cube / vector_machine / force_field_zone and **no
ladder rungs between dial and crossing** (counts 2/0/0/1). This curation: (a) completes the
concept's own small→medium→large→applied ladder by pulling two same-concept kin (field_bench,
force_field) so the field visibly *grows*; (b) sizes every base to the real footprint (slim high
podiums for the held vectors, low broad stages for the two field-worlds) instead of uniform 1×1 +
1-cell stage; (c) gives the centerpiece its own framed bay and forward depth; (d) replaces a single
blank panel with three truth-beat headers.

## Prop gaps flagged

- **Micro-pedestal for sub-1 m held objects.** force_cube is a 0.40 m cube and vector_machine is a
  small console; even a slim 1×1 plinth's 1 m foot reads a little broad under them. They get the
  slim 1×1 (correct per the brief), but a future **0.5–0.6 m-footprint micro-plinth** (or a
  `cap_inset` tuned > 0.35 so the visible column is genuinely slender) would let these precious
  small things read as precious without a 1 m foot. Flagged, not blocking.
- No vertical-circulation or lighting props are needed here; the bay is built from pillars + stages,
  which the station kit already covers.

## What to try next

- Walk it in the editor (`WallHangarEditor`, load Void_Crossing) / capture the front iso + a 3/4
  orbit to confirm the gate framing reads and the background `force_field` slab doesn't crowd the
  centerpiece; nudge `force_field` z deeper or the centerpiece forward if they merge from the front.
- Consider a fourth tiny on-wall `station_panel` naming the **far ledge target** ("aim it here"),
  echoing the map's own flagged gap (intent.md) about an unmarked crossing target — but as a wall
  plate in the hangar, not a floor sign.
- If `force_vortex` (the other `applied` exemplar of this concept) ever wants a cameo, it would sit
  as a second focal node — but one clear focal point is the stronger argument here, so it's left out.
