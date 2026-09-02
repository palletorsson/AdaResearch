# Trans_AxisDecomposition — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Exactness decisions

- **The tutorial's `reconstruct` flips z.** `Vector3.FORWARD` is (0,0,-1), so
  `RIGHT*cx + UP*cy + FORWARD*cz` returns (x, y, -z). Probe item 4 measured
  (2.5, -1.25, 0.75) → (2.5, -1.25, -0.75). The tutorial says "matches the
  original exactly"; the text now says decomposition is exact and
  reconstruction has to agree about the axes. The tutorial should be fixed
  (`Vector3.BACK * cz`, or say so).
- **One cube, gate 6.** One `pick_up_cube` is placed; the gate wants six on the
  running score (see Trans_Translation notes). The first draft said six cubes.
- **The room is mostly void**: rows 16–21 are all `0`; `cube_scene:0:3` and the
  axis cubes stand at y offsets over it. Transport cubes on three separate
  axes: `tc:3:z`, `tc:2:x`, `tc:4:y:auto`.
- **translation_cube_demo** default course `lift_lateral`: "up, then apart.
  Two freedoms, gated" (its own header).
- **toruscylinder**: torus rotates 0.5 rad/s, cylinder oscillates ±1.5 with a
  trail (exports).
- The `3t` text on the wall reads "Translation produces space as navigable
  extent" (map utilities r10 c3).

## Verified critique (2026-09-02) — APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **10 findings survived the editor, 7 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Every finding below
was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
text used to say.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] To get from the entrance to the gate you have to want each of the three directions separately, in the right or

**Problem.** The map puts the spawn, the gate and the teleporter within two cells of each other on the same ledge, so this describes a journey nobody makes. sp is score points in this engine, not spawn; the spawn is the s cell at x=8, z=9 on the east ledge. The teleporter sits at x=7, z=8 and the gate at x=6, z=8. You land, step across, and you are at the way out with the gate beside you. Every transport cube is west of them, and nothing obliges you to go.

**Fix.** You arrive high on the east ledge, and the gate and the way out are both two steps from where you land. Everything the hall has to teach is west of them, across the missing floor, and nothing makes you go. Cross anyway, and you find that wanting to be somewhere means wanting three directions in turn, because no cube gives you two at once.

**Evidence.** Verified against map_data.json: utilities row 8 has t at col 7 and sp at col 8, row 9 has s at col 8; interactables row 8 has pickup_gate at col 6. UtilityRegistry.gd defines s as spawn_point and sp as score points.

### [wrong] One cube to carry across the islands. The carry is three numbers changing, and on the transport cubes you will

**Problem.** You cannot carry it. Walking into the detection volume fires collect(), adds one point and frees the cube with a chirp. A visitor sent to pick this up will reach for it and watch it vanish.

**Fix.** One cube, turning and bobbing on the south floor. You do not carry it. Walk into it and it is gone with a rising chirp, and the number the gate is watching goes up by one.

**Evidence.** Same verification as the other four rooms: pick_up_cube.gd:62-63, :218-227, :258-261, and a .tscn with no body of any kind.

### [wrong] A dark sphere, still, over the void. The one thing in the maze that has no component along any axis, so that t

**Problem.** Two false claims in one short sentence. The token sits at x=2, z=5, and structure row 5 reads "1" at column 2, so it stands on solid floor, not over the void. And it is not still: it turns on Y at 0.15 rad/s with a wobble on X and pulses its emission every frame. The idea underneath is right and worth keeping, but it is invariance of position, not stillness.

**Fix.** A dark sphere on the floor of the northern island, turning slowly on itself and breathing light. It turns and it never changes where it is, which is what makes it the thing to read every other motion against.

**Evidence.** Verified: structure row 5 is ["2","1","1","1","0","0","0","0","2"], so col 2 is floor; dark_sphere.gd:455 and :589-600.

### [wrong] Cubes standing over the void, three metres up, as scaffolding and waypoints. They are the reference geometry o

**Problem.** There is one cube, not several, and it is not scaffolding. The map places a single cube_scene:0:3; at the default grain of solid the script returns from _build_all before adding anything, so the scene is its one 1 m box. It hangs three metres above a void row, out of reach, so it is not a waypoint in any usable sense. "Reference geometry" is lifted from the registry description word for word.

**Fix.** One cube, a metre on a side, hanging three metres above the widest gap in the floor. It is the chapter's plain solid, the thing everything else is measured against, and here it is out of reach, marking the crossing rather than making it.

**Evidence.** Verified: one cube_scene token at interactables row 10 col 5; structure row 10 is void across the interior; commons/primitives/cubes/cube_scene.gd:186-190 returns early on GRAIN_SOLID.

### [wrong] and doing the up before the across is a different thing from doing the across before the up, even though the d

**Problem.** Translations commute, and this chapter's own next room is built on that fact: Trans_Rotation opens "Rotation is the first operation where the order you do things in changes where you end up", and its intent.md says these two halls proved displacement order-independent. So the sentence overstates what is true of translation and spends the next hall's discovery early. It is also undemonstrable here: the demo ships course lift_lateral and the map token passes no config, so the other order is a value no visitor can reach. What the door actually shows is that the gate imposes an order the arithmetic does not.

**Fix.** The constraint is the lesson: direction is part of the operation, not a detail added afterwards. The order belongs to the door and not to the arithmetic. The two displacements add to the same place either way, so the door has to impose a sequence to make you feel them apart.

**Evidence.** Verified: translation_cube_demo.gd:45 ships course = "lift_lateral"; the map token is translation_cube_demo:180:0.5 with no config; Trans_Rotation/intent.md line 2 says in as many words that the previous two maps proved displacement order-independent.

### [wrong] A door in a box that will only move along the axis the box currently allows.

**Problem.** There are two doors, not one. _create_doors builds a red left door and a blue right door inside the wireframe container, each with its own knob and its own two-leg plan, and the demo completes only when both reach their goals. The singular hides the thing the visitor actually does twice.

**Fix.** Two doors in a wireframe box, one red and one blue, each of which will only move along the axis the box currently allows. Push one sideways when it wants to go up and it resists. Complete the lift, and the slide is permitted, and then you do the whole of it again with the other.

**Evidence.** Verified: translation_cube_demo.gd:245-263 (left red, right blue) and :325 (_check_both_complete requires both).

### [wrong] Most of this hall is void.

**Problem.** It is not most, and the true number is better. Counting the seven interior columns across sixteen rows, 56 of 112 cells are void and 56 carry floor. Exactly half. A first sentence about the room's shape should be one a visitor can check by looking.

**Fix.** Half the floor of this hall is missing.

**Evidence.** I counted the structure layer cell by cell: 4+4+3+3+3+4+6+4+4+5+7+3+3+3+0+0 = 56 void of 112 interior cells.

### [weak] the way between the islands is a vertical maze of transport cubes, each of which moves on one axis only: one g

**Problem.** "Vertical maze" is the blurb's phrase, not the map's fact, and the text then leans on "maze" three more times. There are three transport cubes and one walkway, and only one of the three is vertical. Also, two of them wait for you and the third does not: tc:4:y:auto carries auto_start, so the lift is running whether or not you are on it and you have to time your step. That is the only genuinely hard thing in the crossing and the text does not mention it.

**Fix.** the way between the islands is three transport cubes, each of which moves on one axis only: one runs in depth, one across, one up. Two of them wait until you are standing on them. The lift does not, so you have to arrive when it does.

**Evidence.** Verified: utilities carry tc:3:z, tc:2:x and tc:4:y:auto, plus one wp:90; transport_cube.gd:13 declares auto_start.

### [weak] The gate wants six on the running score. It is the same rule as the last hall: accumulated displacement become

**Problem.** True about the code and misleading about the visit. The previous hall's gate wants seven and stands right by its own teleporter, so nobody reaches this room with fewer than seven points, and a gate set to six is already open before you see it. This room places one cube worth one point, so the gate could never have been meant to bite here. Saying so is more interesting than the abstraction, which is the previous hall's sentence repeated rather than earned.

**Fix.** The gate wants six on the running score. The last hall would not let you leave until you had seven, so this one is open before you reach it: the same rule, already satisfied, standing there so you can watch a condition follow you between rooms.

**Evidence.** Verified: Trans_Translation's gate is pickup_gate:0:0#pickups:7 at row 21 with its teleporter at row 22; this map's gate is pickups:6 and holds one pick_up_cube.

### [polish] The sideways cube and the depth cube, each on its own rail with its ghosts and its label.

**Problem.** Accurate but under-delivered, and it hides the one thing you can do to them. Each cube also builds a small rack with a horizontal SPEED slider wired to travel_speed. The visitor can slow the number down. Nothing in the room tells them so.

**Fix.** The sideways cube and the depth cube, each on its own rail, each trailing four shrinking ghosts of where it just was, each printing its one coordinate to three decimals as it goes. There is a speed slider on the rack in front of them. Slow the cube down until you can read the number changing, and watch the other two digits not change at all.

**Evidence.** Verified: axis_translation_cube.gd:33 (travel_speed), :357 (a slider_h labelled SPEED), :363-370 (slider_moved sets travel_speed), :274 (Label3D prints the moving coordinate).
