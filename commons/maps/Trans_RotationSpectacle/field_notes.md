# Trans_RotationSpectacle — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The tunnel

Palle (2026-09-02): "I want the tunnel in the scene now, to the side, in the
wall." Moved from r4 c11 to r4 c12 (the east edge) through
`/api/maps/cell-edit`, which refused nothing. `booleanTunnel.gd`: 18 segments,
spacing 3.0, rotation_per_segment 10° about z (the corridor axis), accrual
default `ramp`; the run is 17 × 3 = 51 m along z from the placement, in a hall
54 rows deep, so it ends about a metre short of the far end. Placed at
y −1.05. Whether "in the wall" means embedded in the museum wall beyond the
map edge is a hall ruling.

## Exactness decisions

- **carousel_cake**: 8 layers, `layer_speed = base × 1.2^i` (line 208/268), so
  the top turns 1.2^7 = 3.58× the base (probe item 8). "A fifth faster than
  the layer below" is the multiplier.
- **baggage_grammar**: lap 12 s, customs_scale 0.55 (scaled down and
  restored), per exports and header.
- **two_cakes**: R·T ≠ T·R, "candles at two addresses", from its header.
- **righttriangle** default proportion isoceles, reading uniform.
- **boolean cubes**: the tunnel's `cube_scene` preload is from
  `algorithms/primitives/booleans/`, hence "hollowed cubes".

## Verified critique (2026-09-02) — APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **10 findings survived the editor, 6 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Every finding below
was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
text used to say.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] Eight objects at even angles round a circle, hung from one frame. Turn the frame and the whole ring sweeps. St

**Problem.** Nothing in this hall is built that way. The code block is lifted out of tutorial.md and describes a ring of eight boxes parented to a frame, which does not exist here. carousel_cake draws eight stacked cylinders as instances of one MultiMesh and writes each instance's rotation individually, with sibling colliders each given their own rotation.y. booleanTunnel bakes an absolute transform into each cube and never rotates a parent. baggage_grammar writes position, rotation and scale straight onto one node. No frame turns and nothing inherits a turn, and the sentence claims to name the room's whole machinery.

**Fix.** Replace the block with the two rules that are running: tunnel_angle(i) returns i * rotation_per_segment, ten degrees added per segment; layer_speed(i) returns base_rotation_speed * pow(1.2, i), a fifth multiplied per layer. Then: "Two rules and one counter. The corridor adds ten degrees for every segment you pass; the cake multiplies its speed by a fifth for every layer you look up. That is the whole machinery of this hall: an index, and something that reads it."

**Evidence.** Verified: carousel_cake.gd:206-220 and :268-271; booleanTunnel.gd:184, :218 and :233-235 (tunnel_rotation_x and _z both zero and unset by the map); baggage_grammar.gd:47-50. The exemplars simplify code freely, but each shows a mechanism that is actually running.

### [wrong] The dark sphere, still, as it has been in every hall. The spectacle needs a witness that does not spin.

**Problem.** The dark sphere spins. rotation_speed is 0.15 rad/s and _process turns it every frame, with a sine wobble on X and an emission pulse on top. The map token is bare dark_sphere with no config, so every default holds. In a room whose subject is rotation, the one sentence that stakes a claim on something not rotating is the one the code contradicts, and forty-two seconds a turn is exactly the kind of slow rotation this room ought to want.

**Fix.** The dark sphere, which is not still either. It turns once in about forty seconds, slowly enough that you have to look away and back to catch it doing anything. In this hall even the witness is spinning, and the only thing that is not is the triangle.

**Evidence.** Verified: dark_sphere.gd:455, :594-595, :599-600; map_data.json interactables row 3 col 6 carries a bare dark_sphere token.

### [wrong] A cube to carry through the procession, so that something in the hall moves because you moved it.

**Problem.** You cannot carry it and you cannot meet it during the procession. Walking into it deletes it. It is also placed at row 45 of 54, three rows past the two cakes and three rows before the exit teleporter, so it stands at the end of the walk, not along it. The true fact is better: it turns at 2 rad/s, a full turn every three seconds, which makes it faster than the carousel's top layer.

**Fix.** A cube near the end, bobbing and turning once every three seconds on its own axis, which makes it the fastest thing turning in this hall: quicker than the carousel's top layer, and the only turn here you can end. Walk into it and it is gone.

**Evidence.** Verified: pick_up_cube.gd:76 (rotation_speed 2.0), :147, :218-249, :258-261; map_data.json places two_cakes at row 42, pick_up_cube at row 45, the teleporter at utilities row 48 and carousel_cake at row 51.

### [wrong] Both are the same ten degrees, and the difference between a building and a performance is only whether the rep

**Problem.** The room lands its argument on a number that is false of half the argument. Ten degrees is the tunnel's rule and only the tunnel's. The cake's rule is a base of 0.5 rad/s multiplied by 1.2 per layer. There is no ten anywhere in the carousel, and the two rules are not even the same operation: one adds an angle, one multiplies a rate. The second half of this sentence is the best writing in the room and the first half is the only thing standing between it and being true.

**Fix.** One is added and one is multiplied: ten degrees per segment down the corridor, a fifth per layer up the cake. The difference between a building and a performance is only whether the repetition has finished.

**Evidence.** Verified: booleanTunnel.gd:18 (rotation_per_segment 10.0) and :184; carousel_cake.gd:54-55 (base_rotation_speed 0.5, rotation_speed_multiplier 1.2) and :208.

### [wrong] Eighteen times ten is a half turn, and over fifty-one metres it is a twist you walk through with your whole bo

**Problem.** Off by one, in exactly the place a rule that accrues should be exact. The first cube is at zero, so eighteen cubes carry seventeen increments: angle_deg = i * rotation_per_segment for i from 0 to 17, which is a hundred and seventy degrees. And nothing about your body leans. The rotation is about Z, the axis you walk along, and the map floor under you is flat; the phrase is carried over almost intact from the registry blurb.

**Fix.** Ten degrees is nothing. Seventeen of them is a hundred and seventy, and the corridor spends fifty-one metres rolling that far about the line you walk along. The ground stays flat. Everything round it does not.

**Evidence.** Verified: booleanTunnel.gd:16 (num_segments 18), :18, :184 (i * 10 for i in 0..17) and :218 (rotation about Vector3(0,0,1)). Note for the author: the critic's supporting claim that the pivot compensation holds every cube centre at x=0 is backwards, since the compensation moves the centre to hold the bottom pivot. The fix above does not rest on it.

### [wrong] This one teaches that speed and direction compound.

**Problem.** Direction never compounds anywhere in this hall. Every carousel layer takes base_rotation_speed times 1.2 to the power i, all positive, so all eight turn the same way. Every tunnel segment adds a positive ten degrees. The suitcase turns the same way at every corner. Nothing counter-rotates. The claim comes from intent.md and from the blurb's "different speeds, different directions", and it is the sentence that sets the room's promise.

**Fix.** The last hall taught that order matters. This one teaches that a speed compounds.

**Evidence.** Verified: carousel_cake.gd:55 and :208 (multiplier 1.2, positive, no sign flip); booleanTunnel.gd:184; Trans_RotationSpectacle/intent.md line 2.

### [weak] Rotation is the transformation that happens in time: the same small angular rule, repeated, accrues into a twi

**Problem.** The opener is not what the room delivers, and it argues against the room's own closing paragraph. The tunnel is fifty-one metres of static geometry with no time in it at all, and the closing says so plainly: a rule repeated in space gave you a twisted tunnel, a rule repeated in time gives you a cake that never settles. The room's one claim is the space/time split, and the opener collapses it.

**Fix.** One angular rule, repeated, is a building if you repeat it in space and a spectacle if you repeat it in time.

**Evidence.** Verified: booleanTunnel bakes its transforms once at build and has no _process; carousel_cake advances _rotation_angle every frame. The room's own last paragraph states the distinction the opener denies.

### [weak] At the end, the carousel itself: eight circular layers stacked into a cake, and every layer obeys one rule, tu

**Problem.** The room's climax arrives with no size on it. The stack is 5.65 m tall and the top layer is 10 m across in a hall 13 m wide, so the brim overhangs almost the full width and stands three times a visitor's height. And the eight layers are not eight equal tiers: three are 5 cm plates at your ankles, then a 3 m column, then four widening slabs. Nor is "the bottom layer turns slowly" a number: it is one turn every twelve and a half seconds against the top layer's three and a half.

**Fix.** At the end, the carousel itself, and it is bigger than it sounds: three thin plates at your ankles, a three-metre column above them, then four slabs widening to a brim ten metres across, six metres up, spanning most of the hall. Eight layers, one rule, each turning a fifth faster than the one below. The bottom takes twelve seconds to come round. The top takes three and a half.

**Evidence.** Verified: carousel_cake.gd:15-16 (radii 4, 3.5, 3, 1.6, 3, 3.5, 4, 5 and heights 0.05, 0.05, 0.05, 3.0, 1.0, 0.5, 0.5, 0.5, summing to 5.65) and :54-55; placed at y+0.35. Every exemplar hands the visitor the scale of a thing at the moment they meet it.

### [polish] Along the east wall, a corridor built from eighteen hollowed cubes, three metres apart, and every one of them

**Problem.** Two small things. "Three metres apart" is the spacing value, but each cube is itself exactly three metres deep, so they abut into one continuous tube with no gaps at all, which is not what "apart" pictures. And "turned ten degrees more" never says about which axis, so a reader builds a corridor that bends. It does not: the turn is about the direction of travel, so the tube stays straight and rolls.

**Fix.** Along the east wall, a corridor of eighteen hollowed cubes set end to end, each three metres deep, each rolled ten degrees further about the corridor's own axis than the one before.

**Evidence.** Verified: booleanTunnel.gd:17 (spacing 3.0) and :218 (rotated about Vector3(0,0,1)); booleanHollowCube.tscn's outer CSGBox3D is size Vector3(4, 4, 3).

### [polish] ## Still things first

**Problem.** Once the dark sphere is described honestly, the heading covers one object out of two. The right triangle is genuinely static, with no _process at all; the sphere turns and pulses. The heading should name what the two share, which is that they are the references.

**Fix.** ## What you can trust

**Evidence.** Consequential on the kept dark_sphere fix. Verified: righttriangle.gd has no _process; dark_sphere.gd:589-600 does.

## The rethink (2026-09-05): the hole is the way

Palle, after the three galleries: *"Do you understand the syntax and the
principal of these maps? It is all about how transformation creates empty
space. So the holes are the pathway up down to the side as a result of
translation rotation and scale."* And when the first draft answered with walls
that open and a cube that fills a pit: *"I mean not fill hole that is another
question I mean just structure 0."* The ruling is in
`commons/data/red_thread_rulings.json`; the rebuild is commit 0298271bd; the
generator that made it (traces, banks and cell-sharing checked) is the session's
`rethink2.py`. **Every `0` cell is the trace of one ride, and the ride is the
only way through it.** A crossing hole is ringed by walls; a spectacle hole (a
rolling cube, a growing cube) keeps floor round it. Mario cubes stand where the
holes lead.

**What the holes are now, down the procession.** Band A, rows 11-13: planks
`rc:90:y:4:-0.6` (2,12), `rc:90:x:4:-0.6` (6,12), `rc:180:y:3:-0.6` (10,12),
walls between. Band B, rows 16-18, floor round the holes:
`rc:continuous:y:40:-0.6` (2,17), `rc:continuous:x:30` (6,17),
`rc:continuous:z:30` (10,17). Band C, rows 21-23: `tc:4:z#rot:90`, `#rot:-90`,
`#rot:360` from row 20 at x2, 6, 10. Band D, rows 26-28: `tc:4:z#rot:180#scale:1.2`
from (2,25) in a 3-wide slot and `tc:4:z#scale:1.3` from (6,25) in a 1-wide one.
The diagonal `tc:4.24:1,0,1` from (1,30) through (2,31), (3,32) into (4,33);
the screw `tc:2:y:auto#rot:360` on floor at (10,31); `sc:3:0.5:1:0` at (8,34),
the LEFT column of its hole (x8-10, rows 33-35). Band E, rows 38-40:
`rc:continuous:y:10:-0.6` (2,39), `rc:45:y:4:-0.6` (6,39), `br:z:3` at (10,38).
Twelve Mario cubes. The tunnel at (12,4), the cakes at (8,42) and the carousel
are where they were. This is a door hall: its artifacts come from the plan,
re-derived and re-baked on 2026-09-05.

**Templates learned, and what each cost.**

- **The ferry distance is the void's depth plus one.** The cube ends EMBEDDED
  in the far bank, flush with it (Trans_Introduction's `tc:4:z:auto` over rows
  6-8). A ride that stops in the last void cell strands the rider a metre
  short, which is what once stranded Palle between two chapters.
- **A ride in a void cell stands half a metre down.** `GridCommon.surface_world_y(0)`
  is 0, so the cube's top is at 0.5 against a floor top of 1.0. A hole in a
  plateau's front is entered by dropping in, and `tc:1.5:y:auto` rises flush to
  the plateau top at 2.0. Plateaus exist only in the embedded-grid halls
  (Translation, AxisDecomposition, Rotation); the museum's door halls read
  height 2 as wall.
- **A straight ride needs a 1-wide slot; a turning one (`#rot`) needs 3**,
  because a 1 m cube at 45 degrees is 1.41 m across and would pass through the
  walls.
- **The plank is a 2.2 m cube at y -0.6** at the centre of a 3x3 hole: its top
  at 0.5, its corners 1.55 out at 45 degrees (touching the banks) and 1.1 at
  rest (a 0.4 m gap). Crossing is a step over the gap and a half-metre step up
  at the far bank, the template's own terms; `rc:90` pauses closed at both
  ends and is open mid-sweep, `rc:45` pauses open. A continuous `rc` is a
  StaticBody turned by script, no platform velocity: a rider is not carried,
  so rolling cubes are spectacle and a turntable is crossed on foot.
- **The scale cube goes at the LEFT column of its 3x3 hole** (`sc:3:0.5:1:0`,
  offset_x 1 puts the centre in the middle). The galleries commit had it at
  the centre column, overhanging the bank by a metre.
- **The pathfinder read `int(distance)` and only the words x, y, z.** `tc:1.5`,
  `tc:4.24:1,0,1` and `tc:2.24:0,-1,2` were dropped in silence and their far
  sides reported unreachable. `tools/map_pathfinder.py` now reads floats,
  signed axes and vectors, and a plank or turntable joins its banks two cells
  out; a cube rolling about x or z joins nothing.
- **The Mario cube took the first node named DarkSphere in the whole tree**,
  which in the museum could be another hall's; it now takes the nearest
  (`commons/artifacts/mario_cube/mario_cube.gd`). In this hall that is the
  room's own sphere, so the first crossing removes the room's control, and the
  wall text says so.
- **Rides are utilities, artifacts are placements.** The museum reads a hall's
  structure and utilities live, but a door hall's artifacts come from
  `ada_run/em_plan.json`: the five transformation rows were re-derived from
  the maps and re-baked on 2026-09-05. A full `em_map_halls.py --apply` would
  have re-derived 23 rows other sessions were editing, so the patch was partial
  and says so in the plan's `_map_halls` stamp.

**Open.** Nobody has walked the rebuilt hall in VR. The `t` at (3,48) still
stands on floor.

**Learned after the bake (2026-09-05, later).** The museum seals every body's
cells in its walk map, a walk-into trigger included, and refuses a seal that
would cut the route ("sealing would sever the walk route"), then SLIDES the
body - into a wall cell, if that is the nearest cell whose seal cuts nothing.
Trans_Scale's right hall is one loop (row 8, the x8 and x12 columns, rows
12-13) with a branch to the sideways slot; a loop tolerates one sealed cell and
a landing pocket none, so two of its three Mario cubes were slid into walls.
They now stand at (12,8), the loop's one cut, and (11,17), off the loop. And
the Mario cube measured seventeen cells because its hidden rainbow (seven arcs,
three metres up) was built at `_ready`: the museum's extent counts every
MeshInstance3D, hidden or not. It is built at the moment of the crossing now,
so the cube seals its one cell; the registry's measured footprint (17) is stale
by the same amount. The Spectacle's twelve stood exactly where placed, because
its rows are thirteen wide.
