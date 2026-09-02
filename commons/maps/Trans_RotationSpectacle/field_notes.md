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

## Verified critique (2026-09-02) — NOT YET APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **10 findings survived the editor, 6 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Nothing below is
applied yet; the rewrite is a whole-chapter job in one scope.

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
