# Trans_Pit — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Exactness decisions

- **The grower breathes.** `grower_block.gd`: `_time += delta * grow_speed *
  TAU; scale = lerp(min_scale, max_scale, t)`, a cycle, with `hot` colouring
  from small (safe) to big (danger). Tokens: min 0.3, max 3.5, speed 0.3
  cycles/s ≈ one breath per 3.3 s. The tutorial's `GrowerBlock` climbs once to
  max and stops; the first draft followed the tutorial. The text now says the
  blocks breathe and that the tutorial's grower differs.
- **pusher_block**: tokens axis z, distance 3, speeds 1.5 / 2 / 1.8, pauses
  1.5 / 1 / 1.2; `push_axis`, `push_distance`, `push_speed`, `pause_time`
  read in apply_grid_config. Probe item 9: the triangle wave stays in [0, 3].
- **Revolving walls** are the `rc` rotation-cube utility (`rc:90:y:4:-0.6`,
  `rc:90:y:3:-0.6`): "rotates to create walkable ramps/surfaces". The text
  says a quarter turn about a vertical axis, four cells and three.
- **Fire**: `h:fire` utilities; DeathEffect handles the reload (CLAUDE.md:
  35 dmg per 0.3 s tick).
- Structure heights: 5 walls, 3 floor, lower cells around the hazards.

## Verified critique (2026-09-02) — APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **8 findings survived the editor, 5 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Every finding below
was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
text used to say.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] The last room has three blocks that breathe. Each swells from a third of a metre to three and a half across an

**Problem.** The grower blocks do not breathe. "min" and "max" are not in CONFIG_PARAM_NAMES, so the token's #min:0.3 and #max:3.5 fall into the shorthand branch: each stores config_data[key] = true and sets a small yaw. grower_block.gd then does min_scale = float(true) = 1.0 and max_scale = float(true) = 1.0, so lerpf(min_scale, max_scale, t) is the constant 1.0. Three fixed one-metre cubes standing in a row. The hot term is then zero over zero, so the colour ramp two sentences later never runs either, and line 12's "the blocks in the room breathe" falls with it.

**Fix.** Either repair the map, which is one line (add "min" and "max" to CONFIG_PARAM_NAMES) and makes the existing sentence nearly true, correcting only "a third of a metre" to "three tenths of a metre". If the map is not repaired, the honest sentence is: "The last room has three cubes in a row, a metre each, and they do not move. Scale is the one transformation this hall never performs on you, and you will walk past it without noticing, which is the whole of what scale does."

**Evidence.** Verified end to end: GridInteractablesComponent.gd's CONFIG_PARAM_NAMES contains neither "min" nor "max"; the shorthand branch at :1668-1702 sets config_data[tutorial_id] = true; grower_block.gd:91-94 reads them with float(), :42 lerps between them and :53 divides by their difference. The map tokens are grower_block#min:0.3#max:3.5#speed:0.3.

### [wrong] The middle room has revolving walls: two of them, a quarter turn at a time about a vertical axis, one four cel

**Problem.** The 4 and the 3 are not lengths. The rc token is angle:axis:pause:y_offset, so rc:90:y:4:-0.6 means a ninety degree step with a four second pause and a 0.6 m drop. Both slabs are identical, 2.2 by 2.2 by 1.0, and with that offset only about half a metre of each stands above the floor. These are knee-high turning slabs, not walls. "Fire around the edges" is also wrong-shaped: nine of the arena's twenty-one fire cells are a solid block in the middle, and each slab turns in a three-cell channel between the middle fire and a side one. The quarter turn itself takes two seconds at 45 degrees per second.

**Fix.** The middle room has two turning slabs, orange and wireframed, each a little over two metres across and knee high. They stand in the two clear channels between three blocks of fire. Each takes two seconds to make a quarter turn about a vertical axis and then stops: one waits four seconds before the next quarter, the other three.

**Evidence.** Verified: GridUtilitiesComponent.gd rc branch reads angle, axis, pause, y_offset; rotation_cube.gd:16 (45 deg/s) and :57 (BoxMesh 2.2 x 2.2 x 1.0); Trans_Pit map has rc:90:y:4:-0.6 at col 4 and rc:90:y:3:-0.6 at col 10, with h:fire at cols 1, 2, 6, 7, 8, 12, 13 across rows 11 to 13.

### [wrong] Three stone blocks in the first corridor, each shuttling along the depth of the room, three metres out and thr

**Problem.** Three separate errors. "Stone": the block is given an emissive red albedo and a bright orange prism arrow on its leading face, which is the one thing that tells you what is about to happen and the text never mentions it. "Along the depth": _end_pos is computed in _ready from the export defaults, and apply_grid_config arrives afterwards through call_deferred, so axis:z never reaches the path. All three slide along +X, across the corridor's width, and each passes directly over a fire pit two cells along. "Three different pauses": pause is not a recognised config name, so it collapses to 1.0 for all three, as does distance, which makes each stroke take about half a second.

**Fix.** Three red blocks in the first corridor, each with an arrow on its face saying where it will go. Each crosses three metres of the corridor in about half a second, straight over a fire pit, waits a second, and comes back. They differ only in how fast.

**Evidence.** Verified: pusher_block.gd:38-41 bakes _end_pos in _ready, :87 sets the red emissive material, :99-106 builds the arrow, :116-128 is the apply_grid_config that arrives too late; GridInteractablesComponent.gd:1801 calls it deferred while :1294 adds the child. Neither "distance" nor "pause" is in CONFIG_PARAM_NAMES. The three pushers at (3,3), (3,7) and (5,7) each cross a fire cell at (3,5), (3,9) and (5,9).

### [wrong] From inside you learn the other half of the fact: a point at the end of a turning wall moves fastest of all, a

**Problem.** Nothing arrives anywhere. The slab's furthest point is half the horizontal diagonal of a 2.2 by 1.0 box, about 1.21 m from the pivot. The nearest fire cell begins 1.5 m away and the room's own edge is over five metres off, so the sweep stays inside its channel and cannot touch you at the edge. The true fact is better than the invented one and is pure geometry.

**Fix.** From inside you learn the other half of the fact: a turn changes what the same slab occupies. Side on it nearly closes the channel. End on it leaves a metre either side. Nothing about the slab changed, and the gap did.

**Evidence.** Verified: rotation_cube.gd:57 gives the box dimensions, from which the half-diagonal is 1.208 m; the slab at col 4 sits in a three-cell channel between fire at col 2 and fire at col 6.

### [wrong] A wall rotates, and you are swept.

**Problem.** This is the room's spine, and its middle third is not the shipped mechanism. The pusher and grower are AnimatableBody3D, which the solver carries bodies with. The turning slab is a StaticBody3D whose transform is copied from the mesh each frame, which blocks but does not carry, and at half a metre proud of the floor it is a step, not a wall. Rotation in this hall does not remove you; it changes the shape of the opening you have to use.

**Fix.** A slab turns, and the way through is somewhere else.

**Evidence.** Verified: pusher_block.gd:68 and grower_block.gd:60 both build AnimatableBody3D; rotation_cube.gd:85 builds a StaticBody3D and :101 copies the mesh transform onto it each frame.

### [weak] What the hall proves is that a transformation's neutrality is a fact about the outside view.

**Problem.** This is the opening sentence again, in the last section, doing the work of a lid rather than an arrival. The sentence before it sets up the turn and the two after it are the real close and are strong. This one sits between them and takes the air out of both.

**Fix.** Cut it. Run "Fire is the same fire under all three rooms, and the reload is the same reload." straight into "The matrices in the first hall were true:".

**Evidence.** Internal to final.md lines 1 and 36, which state the same proposition. One deletion, nothing rewritten. This is the low-churn way to fix the room's opener-restates-closer problem without touching the opener.

### [weak] That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the

**Problem.** Good image, no door. Trans_Pit is the last map of the transformation sequence and the teleporter is right there at the far end, set to next_in_sequence; the visitor is standing next to the way out. All three exemplars end by naming what is through it, including Melencolia, which is also a chapter end.

**Fix.** Keep both sentences and add: "The teleporter is at the far end, past the last block. The next chapter is colour, which moves nothing at all."

**Evidence.** Verified: Trans_Pit/map_data.json places t at row 23 col 7 with action next_in_sequence, and curriculum_spine.json orders transformation at 2 and color at 3.

### [weak] There are fire pits either side of the lane.

**Problem.** Vague, and false of the lane it most matters for. Each block's stroke passes directly over one fire pit rather than between two. The corridor also holds five holes at height 1 with no fire on them at all, which a visitor falls into just as readily, so "fire pits" undercounts the ways down.

**Fix.** The pit is two cells along the block's line, and the block crosses it. Not every hole in this corridor burns, and the ones that do not are the same distance down.

**Evidence.** Verified: structure height-1 cells at (3,5), (3,9), (4,3), (4,7), (4,8), (5,9), (6,6), (6,8), against h:fire only at (3,5), (3,9), (5,3), (5,9). Five height-1 holes carry no fire.

## Open after the rewrite

- **The grower blocks are inert and the text now says so.** Their tokens carry
  `#min:0.3#max:3.5#speed:0.3`, but `min` and `max` are not in
  `CONFIG_PARAM_NAMES`, so the grid's shorthand branch stores them as `true`
  and the block keeps its defaults. The one-line repair is to add both keys to
  that list, which changes how every map in the corpus parses those words, so
  it is a ruling and not a text fix. Make it and the swelling sentence becomes
  true again, with "a third of a metre" corrected to three tenths.
