# Trans_Translation — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Exactness decisions

- **The gate counts the GameManager score, not this hall's cubes.**
  `pickup_gate.gd` connects `score_updated` and opens when the running score
  reaches `required_pickups` (7 here). Five `pick_up_cube` are placed
  (points_value 1 each); the other two come from earlier halls. The first draft
  said "seven cubes". The text now says the gate wants seven on the score you
  carry.
- **science_screen `mode:point`** is a real mode (`_set_explicit_mode`: point,
  line, trace/draw, triangle, net/cube): it tracks a grabbed point. The text
  says carry a cube in front of it.
- **synthesis_stand `#subject:pick_up_cube#mode:hero`**: the verdict file
  `commons/data/dna_synthesis.json` rules pick_up_cube a SERIES on axis `stock`
  (wire, steel, clay, crate, foam); a hero of a series-verdict subject pins the
  top evidence variant. The text names the five stocks.
- **Axes in this hall**: transport cubes `tc:3:z`, `tc:1:y:auto`, `tc:3:y`,
  `tc:2:y`, `tc:6:y`; the two axis cubes placed are z and y. "Nothing asks you
  to go sideways" is from the utilities.
- **transform_composition_workbench**: pair 2 (rotation × uniform scale)
  commutes, per its description and probe item 6.

## Continuity

player_trace from Point_Trace (the line as positions); the void as invitation
from the blurb.

## Verified critique (2026-09-02) — NOT YET APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **12 findings survived the editor, 7 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Nothing below is
applied yet; the rewrite is a whole-chapter job in one scope.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] Cubes to carry, five of them, scattered on both sides of the void. Carrying is the smallest translation there

**Problem.** You cannot carry a pick_up_cube; walking into it deletes it. And "nothing about the cube changes" is contradicted by the cube itself, which spins at 2 rad/s and bobs 0.2 m the whole time. One of the five also stands on a void cell, so "scattered on both sides" undersells what you see.

**Fix.** Five cubes, each turning on its own axis and bobbing, four standing on floor and one hanging over the hole near the entrance. You cannot pick one up. Walk into it and it is gone with a rising chirp, and the score is one larger. The only thing translated here is you: the cube never moves at all, and the count is what your crossing leaves behind.

**Evidence.** Verified: pick_up_cube.gd:142-152 (rotate_y 2.0, bob 0.2), :218-249, :258-261; the cube at interactables row 3 col 5 sits over structure row 3 col 5, which is "0".

### [wrong] The transport cube does not cross the void; it is at one end, and then at the other, and the only thing the ma

**Problem.** This describes the one-line snippet at the top of the page, not the artifact. The transport cube crosses continuously: on body_entered it waits a second, then move_toward at 2.0 m per second, and on every frame it adds its own movement delta to the carried player's global position, waits three seconds at the far end and drives back. It is the slowest thing in the hall, and riding it is the room's central bodily fact. The thing that does jump is the teleporter at the exit, which the text never names. This is the closing paragraph, so the room lands its argument on a false observation.

**Fix.** The transport cube does cross the void, and slowly. Stand on it, wait a second, and it moves at two metres a second toward the far side, and on every frame it adds the distance it just moved to your position as well as to its own. You are not transported. You are added to, frame by frame, by a cube doing to you exactly what the first line of code did to the object.

**Evidence.** Verified in commons/scenes/mapobjects/transport_cube.gd:8-13 (move_speed 2.0, return_delay 3.0, start_delay 1.0) and :169-219 (move_toward plus carried_player.global_position += movement_delta).

### [wrong] The screen is set to track a point. Carry a cube in front of it and the screen draws where the cube goes, as c

**Problem.** The screen tracks nothing here and cannot be made to. #mode:point locks the mode and runs one scan, which latches a sibling only if its lookup name or node name contains the substring "point" and it has a freeze property. Nothing in this map matches either test, so _tracking_point stays null and the tracker paints its dot dead at the origin with the readout at plus zero. Nothing can be carried in front of it either. What the screen genuinely does goes unmentioned: it loads this map's blurb.md into the bar along the bottom.

**Fix.** The screen is set to track a point, and there is no point in this hall for it to track. It wants a neighbour with the word point in its name and a body it can hold, finds none, and draws the instrument anyway: POINT POSITION, P = (x, y), a grid, and a dot pinned at the origin reading plus zero with a trail of nothing. Along the bottom it recites this map's own blurb. A diagram of translation with the translation left out is the most honest object in the room.

**Evidence.** Verified: science_screen.gd:405-453 (_set_explicit_mode, _mode_locked), :466-477 (locked modes skip the scan and only call _connect_tracking_for_mode), :1275-1303 (the "point" plus freeze test), :1905-1910 (pos = ZERO when null), :324-372 (blurb.md into the info bar).

### [wrong] Nothing here turns and nothing grows.

**Problem.** Three things turn and one grows, and the growing one is how you cross the widest hole. Every pick_up_cube runs rotate_y at 2 rad/s. The dark sphere turns at 0.15 rad/s. And the cell in the middle of the full-width chasm at row 17 is sc:3:-0.5:1:-1, a scale cube: it swells to a 3 m cube at 1 unit per second, holds four seconds with its collider walkable, then shrinks away and starts again. The sentence carries the room's purity claim, so it has to be true, and the honest version names the crossing the text otherwise omits entirely.

**Fix.** Nothing here is reshaped by being moved, which is not the same as nothing turning: the cubes you collect spin on the spot, and the cube in the widest chasm swells to three metres, holds for four seconds while you walk across it, and shrinks away again.

**Evidence.** Verified: map_data.json utilities row 17 carries sc:3:-0.5:1:-1 and structure rows 17 and 18 are entirely void; scale_cube.gd:9-14 (max 3.0, speed 1.0, pause_at_max 4.0) and :97-125 (is_walkable at 0.95 of max); GridUtilitiesComponent sc branch reads max, min, offset_x, y_offset in that order.

### [wrong] The measurements ruled the family a series, and this plinth, told to show a hero, pins the one variant the mea

**Problem.** Both claims are false. A forced hero of a series verdict does not pin the highest-ranked variant; _build_hero takes order[order.size() - 1], the far end of the measured ladder, which the export's own comment states. For pick_up_cube that order is wire, steel, clay, crate, foam, so the plinth carries foam. And there is no number: the plaque appends a percentage only when score is above zero, and the pick_up_cube verdict has no score key at all. The plaque reads "pick_up_cube  stock=foam" and stops.

**Fix.** The measurements ruled the family a series, so there is no hero to pin. Told to show one anyway, the plinth takes the far end of the measured ladder and stands it up: foam. The plaque says pick_up_cube stock=foam and nothing else, because a series verdict carries no single number to print. Every cube in the room is the near end, wire, the shipped form nobody chose.

**Evidence.** Verified: synthesis_stand.gd:105-132 (order[-1] at :107-111, score gate at :127-131) and :26; commons/data/dna_synthesis.json verdicts.pick_up_cube has verdict "series", order wire/steel/clay/crate/foam, span and evidence, and no score key.

### [wrong] Every step you take writes another point, and the line behind you is translation and nothing else: a time-inde

**Problem.** The line is not translation and nothing else. velocity_color defaults to true and the .tscn does not override it, so the rebuild sets a per-vertex colour from speed, lerping the green trail toward amber and reaching full amber at 2.0 m per second. The recorder keeps three parallel arrays: points, times and speeds. The room's opening thesis is that a path can be kept as nothing but positions, and the room's first artifact keeps the derivative too. That is not a flaw to hide; it is the best complication in the hall, and the exemplars do exactly this.

**Fix.** Every step you take writes another point, and the line behind you is not only where you were. It is tinted by how fast you got there, green where you dawdled and amber where you ran, full amber at two metres a second. The recorder keeps three lists: positions, times, speeds. The first sentence of this room says a path can be kept as nothing but positions, and the first thing in it keeps more.

**Evidence.** Verified: player_trace.gd:28-30, :390-399 (three arrays), :466-469 (_velocity_to_color), :505-521 (per-vertex colour); velocity_color does not appear in player_trace.tscn.

### [wrong] Translation with anything is not that exception, and you will see why in the rotation halls.

**Problem.** Two translations always commute, and this is the translation hall, so the sentence throws away the room's strongest available claim and states a falsehood to do it. The workbench never tests it either: its four pairs are rotate Y with translate X, rotate Z with uniform scale, translate X with scale, and two rotations. Translation composed with translation is not on the slider, and naming that absence is more interesting than the false generalisation.

**Fix.** None of the four pairs is the one this hall is about. Two translations always commute, whatever their directions and however many, which is why nothing you do in this room has an order: take the cubes in any sequence and you reach the gate with the same count. Translation is the operation that does not care, and the rotation halls are where that stops being true.

**Evidence.** Verified: transform_composition_workbench.gd:180-216 defines exactly those four pairs.

### [weak] A dark sphere that stays still while you cross.

**Problem.** It stays in its cell, but it is not still: _process turns it on Y at 0.15 rad/s, wobbles it on X, and pulses its emission between 0.05 and 0.35. In a hall whose second paragraph is being corrected because it claims nothing turns, singling this out as the still thing puts the room's one honest control in the wrong category. The precise fact is better: it is the only object here that never changes position, and it does everything else.

**Fix.** A dark sphere that never leaves its cell while you cross. It is not still: it turns slowly, it wobbles, and its glow breathes between dim and dimmer. It is the room's control, and a strict one, because the only thing it refuses to do is the one thing everything else here does.

**Evidence.** Verified: dark_sphere.gd:455-458 and :589-609. Keeping this consistent with the corrected "nothing here turns" sentence is the point.

### [weak] <!-- @z_translation_cube -->

**Problem.** The region opened for the z cube contains nothing. Both cubes are covered in the paragraph under the y tag, so anything reading a region as its artifact's text gets an empty string for z and a doubled paragraph for y, and the visitor never learns why this is the member the family is proudest of. Its rail runs into the picture, so the same displacement is read almost entirely as a change of size, which is precisely the confusion a translation room exists to clear up.

**Fix.** Put a paragraph in the empty region: "A cube on a rail that runs away from you, sliding forty centimetres out and forty back, with four ghosts of itself shrinking behind it. Watch what your eye does. Depth is the one direction in which a pure displacement is read as a change of size, and nothing about the cube has changed at all."

**Evidence.** Verified: final.md lines 18-21 leave the z region empty; axis_translation_cube.gd:29-43 gives travel 0.4 m, cube 0.15 m and four ghosts, and z_translation_cube.tscn sets the depth course. No exemplar leaves a tag region empty.

### [weak] Walkways cross them, and transport cubes shuttle over gaps your feet cannot, rising and falling and sliding on

**Problem.** There is one walkway, not walkways: a single walkable prism at row 8 column 2, and it does not span anything, because the cells either side of it are void and the cell behind it is a wall two high. It is a ramp. The plural comes from blurb.md, which is the map's own prose rather than its code. Meanwhile the crossing the sentence should be naming, the scale cube in the full-width chasm, is absent from the whole page.

**Fix.** One ramp, five transport cubes that lift and slide on a single axis apiece, and in the widest chasm a cube that grows until you can stand on it. The whole room is displacement made into infrastructure.

**Evidence.** Verified: one wp:0:0.5 at utilities row 8 col 2 with structure row 8 reading void at cols 1 and 3 and row 9 col 2 reading "2"; five tc cells (one z, four y); the sc cell at row 17.

### [polish] It wants seven on the score you have been carrying since the first hall, and it is closed until the count gets

**Problem.** True, and it leaves out the object standing beside the gate that makes the claim checkable. The two sp cells in this map are not spawn points, whatever the map's own utility_definitions block says: sp resolves to score_cube.tscn, a cube with a Label3D showing GameManager's running score. One stands a row from the gate. The gate and the cube are reading the same integer, which is the paragraph's whole argument made visible.

**Fix.** It wants seven on the score you have been carrying since the first hall, the same number the cube beside it is displaying, and it is closed until the count gets there and open the moment it does.

**Evidence.** Verified: UtilityRegistry.gd maps "sp" to score points, score_cube.tscn; the map's own utility_definitions calls it a spawn and nothing reads that. sp sits at row 20 col 3, the gate at row 21 col 5.

### [polish] The same tetrahedron is shown twice, done in one order on the left and the other order on the right, and three

**Problem.** Three tetrahedra stand on the workbench, not two. _build_stage builds a pale untransformed ghost in the centre between the two results, with a trajectory arrow from the ghost's centroid to each, blue to the left and pink to the right. The ghost is what makes the two results legible as two answers to one question, and there is a badge over the stage that reads commutes or non-commutative as you move the slider.

**Fix.** The same tetrahedron is shown three times: pale and untransformed in the middle, then done in one order on the left and the other on the right, with an arrow from the ghost to each result. Three of the four pairs land in different places, and a badge over the stage says so.

**Evidence.** Verified: transform_composition_workbench.gd:309-313 and :350-358 (ghost), :387-398 (arrows in color_left and color_right), :54-60 (badge).
