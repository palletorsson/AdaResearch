# Trans_Introduction — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The arc, found

Palle's ruling (2026-09-02): transformation's red thread is that each move
*creates space in a different way*. The blurbs already said it, one clause per
map: translation produces space as extent, rotation produces space as
anisotropic, scale produces space as relation; the intro is three ways to close
a gap, the pit the same three from inside. The chapter follows Melencolia and
opens with "the primitives finally move".

## Exactness decisions

- **Shear keeps area.** The first draft said "shear it and almost nothing
  survives"; `probe_transformation_tutorials.gd` item 1 measured a shear keeping
  the triangle's area exactly. The text now says only the area holds.
- **The three lane cubes are utilities**, not interactables: `tc` transport
  cube ("carries players across voids"), `rc` rotation cube ("rotates to create
  walkable ramps"), `sc` scale cube ("scales to fill gaps with presence"), per
  `UtilityRegistry.gd`. Cyan/orange/green from the blurb.
- **scale_me does not rescale the world around you.** `scale_me.gd` finds a
  node named DarkSphere in the scene and tweens its scale ×100 over 5 s, and
  sets the player's position to y = 5 with x, z multiplied by 20; auto-revert
  after 20 s. The registry's "rescales the world around the player" is prose.
  The text says what happens. (Flag: the x,z ×20 on the player is a teleport
  far from the hall in the museum; worth a look.)
- **invariants_demo** is placed with `pose:rotate` (arrives showing the
  rotated face) and has TRANSLATE/ROTATE/SCALE/SHEAR/RESET/PROJECT buttons, so
  "put it through a move" is true.
- **head_crab** `#detection:14` reaches `detect_m` (head_crab.gd:395); it
  chases (chase_speed 0.95).
- **rotation_gimbal** locks within 5° of 90° on the middle ring
  (gimbal_lock_threshold).
- **balance_puzzle** piece_count 8.
- "Alice had a bottle for this": the bottle and the cake, not a pill.

## Probe

`commons/testing/probe_transformation_tutorials.gd` (PROBE OK): srt vs trs
land differently; a*b applies b first; t·invert(t) = identity; the invariants
table; a square returns under a quarter turn, not an eighth; Rx·Ry ≠ Ry·Rx;
rotation commutes with uniform scale and not with non-uniform; volume ×8.

## Open

- The `sp` utility ("score points", `score_cube.tscn`) has no script on disk
  under that name; whether it adds to the score or only shows it is unread.

## Verified critique (2026-09-02) — APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **16 findings survived the editor, 8 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Every finding below
was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
text used to say.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] A cube that can be carried. Translation reduced to a portable primitive, and the sequence's small change: the

**Problem.** pick_up_cube has no pickable, no rigid body and no grab of any kind. It is a Node3D with an Area3D called DetectionArea; body_entered fires collect(), which adds one point to GameManager, plays a rising chirp and queue_frees the cube 0.1 s later. The script says so in its own header: "This artifact is collected by walking into it." The sentence sends the visitor to grab the one object in the hall that vanishes on contact.

**Fix.** A black cube in orange wireframe, turning and bobbing on its own axis. You cannot carry it. Walk into it and it is gone with a rising chirp and one point on the score, so the translation the room counts here is yours and not the cube's.

**Evidence.** Verified in commons/scenes/mapobjects/pick_up_cube.gd (collect at :218, add_points :227, queue_free :249, body_entered :258) and pick_up_cube.tscn, whose only nodes are DetectionArea (Area3D, mask 524288) and CubeBaseMesh. The registry's "grab-and-carry cube" is the wrong prose. This same error is repeated in five rooms.

### [wrong] The orange cube turns a floor into a ramp: the gap is bridged by facing differently, not by moving.

**Problem.** No ramp. The token is rc:90:y:4:-0.6, which the grid reads as ninety degrees about Vector3.UP with a four second pause, and rotation_cube.gd applies it as mesh_instance.rotation_degrees = rotation_axis * current_angle on a box of 2.2 by 2.2 by 1.0. A quarter turn about the upright yaws the slab like a door. Nothing tilts. "Rotates to create walkable surfaces" is the script's own header comment, not its behaviour.

**Fix.** The orange cube is a slab that turns a quarter circle about the upright, holds for four seconds and turns back. It does not tilt and it does not grow. The gap is bridged by facing differently, not by moving.

**Evidence.** Verified: GridUtilitiesComponent.gd rc branch maps axis "y" to Vector3.UP and parameter 4 to pause, parameter -0.6 to y_offset; rotation_cube.gd:57 builds BoxMesh(2.2, 2.2, 1.0) and :122 rotates on the chosen axis only.

### [wrong] The turn is inserted in the middle of the process, and because of that the second slide goes a different way.

**Problem.** Two errors. All three phases do current_transform.origin.x += translation_step, and rotated_local multiplies the basis from the right, so it never touches the origin. The baked buffer proves it: thirty-three instances, y constant at 3, z constant at 0.05, x advancing by 0.14 from -2.4098 to 2.0702. The row is dead straight and the second slide goes exactly the same way. And there is no plinth: the token is spin:0:1, and the grid stands a plinth only when the token carries #plinth:H, which three other tokens in this map do and this one does not.

**Fix.** The turn is inserted in the middle of the process, and it changes the copies without changing where they go. The row stays straight, because every phase adds the same step along the same axis and only the basis is turned. Twelve copies tumble fifteen degrees each, and the last ten stand upside down and still in line.

**Evidence.** Verified in algorithms/transformation/spin/spin.gd:81, :89-90, :98 and the MultiMesh buffer in spin.tscn; plinth gating at GridInteractablesComponent.gd:1338 (config_data.has("plinth")); token at Trans_Introduction/map_data.json row 17.

### [wrong] Eight pieces to stack until the pile stops moving. Every drop is a translation and a small rotation, but the p

**Problem.** The puzzle never tests the centre of mass. The win condition is a height line at 0.4 m and then every piece under a linear velocity of 0.05 for 1.5 continuous seconds. Centre of mass is computed once, inside _transform_to_walker, after you have already won, only to place the walker. Below the line the stability timer is reset every frame, so "stops moving" is not sufficient either. And the paragraph omits what actually happens: the eight blocks gather and walk away as a creature.

**Fix.** Eight pieces, and a line at forty centimetres. Stack them past it and hold every piece still for a second and a half, and the pile stops being a pile: the eight blocks gather and walk away as a creature. Every drop is a translation and a small rotation, and the test is not the moves. The test is whether the stack is still standing when you take your hands off it.

**Evidence.** Verified in commons/primitives/balance/balance_puzzle.gd:48 (height_threshold 0.4), :51 (stability_time 1.5), :54 (velocity 0.05), :57 (piece_count 8), :323-357 (_update_stability_check), :378 (_transform_to_walker, centre computed after the trigger).

### [wrong] Shear it and the sides and the angles go red and only the area holds.

**Problem.** The base side holds too. SHEAR does x += 0.4 * (y - base_y) with base_y read from vertex 0, and in all three figures the demo can build, vertices 0 and 1 sit at the same y, so the base has zero shift at both ends and its length is unchanged. The tag comparison uses an absolute tolerance of 0.01, so it renders green. On the equilateral default: base 0.30 unchanged, the other two sides 0.30 to 0.264 and 0.363, all three angles moved, area unchanged. "Only the area holds" is the one claim on that panel a visitor can disprove by reading it.

**Fix.** Shear it and all three angles go red, two of the sides go with them, and the base and the area hold.

**Evidence.** Verified in algorithms/transforms/invariants/invariants_demo.gd:394-399 (shear), :100-112 (all three vertex sets have verts 0 and 1 at equal y), :477-479 (_invariant_color, tolerance 0.01). I recomputed the side lengths by hand.

### [wrong] Do, and the dark sphere in this hall grows a hundred times over five seconds while you are lifted and carried

**Problem.** Wrong on every number, and wrong about what happens to you. The critic who filed this read the .gd defaults; the scene the map instantiates overrides all of them. scale_me.tscn sets scale_amount = 10.0, scale_up_time = 2.0, scale_down_time = 2.0 and scale_duration = 1000.0. So the sphere grows ten times over two seconds, and the revert timer is a thousand seconds, which nobody walking this hall will see. You are not carried either: at the instant of the grab, before the tween is created, the script writes the origin's global position once, to (x times scale_amount/5, 5, z times scale_amount/5), which here is a doubling of x and z and a height of five metres. On the way back the code comments "Don't move player when scaling down" and tweens only the world node.

**Fix.** A sphere you can take hold of. Do, and the dark sphere across the hall swells ten times over two seconds. You are not carried with it. In the instant you close your hand, before anything has started to grow, your distance from the room's corner is doubled and your height set to five metres, so you arrive at the new view before the sphere does. It does not come back while you are here, and neither do you. Alice had a bottle for this.

**Evidence.** Verified: algorithms/primitives/scaleme/scale_me.tscn:8-11 overrides the four exports; scale_me.gd:118-126 writes the position in one step before the tween at :129-132; :174-181 deliberately leaves the player. The registry maps the token scale_me to that .tscn. I corrected the critic's numbers, which came from the script defaults rather than the placed scene.

### [wrong] Three lanes leave this hall, one per move, and each is a cube.

**Problem.** One lane, three pits. The structure layer cuts three three-by-three pits into the centre columns at rows 6 to 8, 11 to 13 and 16 to 18, and puts a different cube at each: tc at row 5, sc at row 12, rc at row 17. Rows 9 and 15 seal the two side corridors with height-2 walls, so nothing leaves the hall down them.

**Fix.** One lane runs the length of this hall and three pits are cut into it, and there is a different cube at each one.

**Evidence.** Verified against Trans_Introduction/map_data.json structure rows 6-8, 11-13, 16-18 (cols 4-6 void) and rows 9 and 15 (cols 0-3 and 7-10 all "2"), with the tc, sc and rc utility cells where the critic says.

### [wrong] A small black crab on four jointed legs, looking for you from a distance, and following.

**Problem.** It does not only follow. can_bite is true, the token sets detection to fourteen metres, and inside 1.9 m it commits to a dash at 4.2 m per second and bites for thirty-four of your hundred health, eighteen on a walk-up contact. Damage routes through GameManager.apply_health_damage, which red-flashes and puts you back at the spawn point. This is the only thing in the hall that can undo your walk and the text does not mention it, so the visitor learns it by being bitten.

**Fix.** A small black crab on four jointed legs, which finds you at fourteen metres and comes. Inside two metres it dashes. The bite takes a third of your health and puts you back at the door, so the one thing in this hall that moves itself is also the only one that can undo your walk.

**Evidence.** Verified in commons/hazards/head_crab/head_crab.gd:97-101 (can_bite, contact 18, lunge 34, lunge_range 1.9, lunge_speed 4.2), :251 (LEG_COUNT 4); token head_crab:180#detection:14; GameManager.gd:44 (max 100) and :370-387 (hurt then return to spawn).

### [weak] Turn the middle ring toward ninety degrees and the outer and inner rings come into line, and at that moment on

**Problem.** You cannot turn the ring. The rig is driven by a three-slider pad labelled X, Y and Z with a reset button; the rings are torus meshes on nested pivots and nothing on them is grabbable. Everything else in the sentence is exact: outer is X, middle is Y, inner is Z, and the alarm arms within five degrees of ninety.

**Fix.** Push the Y slider on the pad toward ninety degrees and the outer and inner rings come into line, and at that moment one of your three freedoms is gone: gimbal lock.

**Evidence.** Verified in commons/artifacts/rotation_gimbal/rotation_gimbal.gd:161-191 (outer X pitch, middle Y yaw, inner Z roll), :463-488 (create_parameter_panel with labels X, Y, Z plus ResetButton), :17 (gimbal_lock_threshold 5.0).

### [weak] ## What each refuses

**Problem.** Three of the six artifacts under this heading refuse nothing. invariants_demo and the three axis cubes are about invariance; spin, transform_composition and rotation_gimbal are about composition order and about what three-angle bookkeeping costs. The room's thesis is invariance, and the section that ought to deliver it is diluted by the section that should follow it.

**Fix.** Close the run after the three axis cubes with a bare closing comment, and open a second heading at spin: "## Order". Then spin, transform_composition and rotation_gimbal argue one case together, and "What each refuses" is left holding only what refuses something.

**Evidence.** One-line insertion, no prose rewritten. The exemplars keep headings tight to their runs: Melencolia's four sections each cover what they name, and Gravity's "## Three" covers exactly the three-body pieces.

### [weak] ## One matrix

**Problem.** The heading stops describing its contents after two artifacts. It covers homogeneous_coordinates and matrix_4x4_viewer, then runs on through balance_puzzle, scale_me, pick_up_cube, head_crab and dark_sphere, none of which is about a matrix. From that point the room stops arguing and starts listing what is left, which is the one thing none of the three exemplars does.

**Fix.** Keep "## One matrix" for homogeneous_coordinates and matrix_4x4_viewer, close the run after the viewer with a bare closing comment, and open a second heading at balance_puzzle: "## Moves with something at stake". Those are the ones where a transformation costs you something, which is a claim, and it sets up the closing.

**Evidence.** Confirmed against final.md lines 54-84: seven artifact regions under one heading. Also a one-line insertion.

### [weak] Shear keeps only the area, which is why it is not one of the three lanes.

**Problem.** The causal clause is not a reason, and the fact repeats the error upstream: shear keeps the base as well as the area. The room also has a real tension here and ducks it. The opening says there are exactly three ways a thing can move, and the first panel the visitor presses has a fourth button on it.

**Fix.** Shear keeps the area and the side it stands on, and gives up the rest. It is the fourth button on the first panel in the hall, and the chapter does not give it a lane, which is a choice the panel quietly argues with.

**Evidence.** Verified: invariants_demo.gd:325-341 builds TRANSLATE, ROTATE, SCALE, SHEAR, PROJECT, RESET; the shear arithmetic is at :394-399.

### [weak] A dark sphere that does almost nothing. It changes so little that the changes around it become readable, which

**Problem.** It contradicts the room twelve lines earlier, where the same sphere grows ten times under the pill. It is also the registry's sentence reworded, and it undersells the code: a slow yaw at 0.15 rad/s, a sine wobble on X, and an emission pulse between 0.05 and 0.35 every frame. The hall has a better claim available for free, because this is the object the grab sphere acts on.

**Fix.** This is the sphere the grab handle goes looking for. It turns slowly and its purple emission breathes, and otherwise it is only ever acted upon, which is what makes a tenfold change in it legible.

**Evidence.** Verified: dark_sphere.gd:455-458 and :589-609; scale_me.gd:67 searches the scene for a node named DarkSphere, and dark_sphere.tscn's root carries that name. In this map the sphere is placed at row 7 and the pill at row 12, so the search finds it.

### [polish] Three cubes, each allowed one axis. One slides sideways, one lifts, one goes into the depth, and each leaves g

**Problem.** The paragraph sits after the third comment, so the x and y regions open onto nothing and only z carries wall text. The three cubes are also in three different parts of the hall, at rows 5, 7 and 12, so a visitor meets them one at a time and never sees the trio the paragraph describes. The label prints one coordinate, not three.

**Fix.** Give each region its own line. Under x: "Three cubes stand apart in this hall, each allowed one axis. This one slides sideways, on a rail, with four fading ghosts behind it and its one coordinate counting on a label." Under y: "This one lifts. The same operation, and the one that reads least like it." Under z: "This one goes into the depth, where the same displacement reads almost entirely as getting bigger. Translation, taken apart, is three of these, and the room after next will forbid you two of them at a time to prove it."

**Evidence.** Verified: the cubes are at map rows 5, 7 and 12; axis_translation_cube.gd:274 prints the moving axis only, and the default account "ghost" builds a rail, two markers and four fading ghosts. No exemplar leaves a tag region empty.

### [polish] Each of the three moves has a different answer, and that answer is its name.

**Problem.** It contradicts the thesis one sentence after stating it. Translation is named for what it changes, not for what it keeps, and so are the other two. The room already has the clean version further down, "the signature is what it cannot touch", so this line is a muddier duplicate standing in the load-bearing position.

**Fix.** Each of the three moves has a different answer, and each is named for the one thing it gives up.

**Evidence.** Internal to final.md lines 1 and 3. One clause changed.

### [polish] Next: translation on its own, and a floor made of it.

**Problem.** The image is wrong. The next hall's floor is not made of translation; it has holes cut in it that translation crosses, which is that room's own first line.

**Fix.** The next hall is translation on its own, and its floor has holes in it.

**Evidence.** Trans_Translation/final.md:3 opens "This hall has holes in its floor." One line changed.
