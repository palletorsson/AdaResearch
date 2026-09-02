# Trans_Rotation — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The second gem

Palle (2026-09-02): "what rotation does with sameness of form, that is quantum
theory." The text carries it as symmetry: the turns that bring a form home; a
square under four, a circle under all; and spin as the particle's answer to
"how do you come back when turned", with the spin-½ fact (two full turns) stated
as physics, not as anything the room measures. Probe item 5 measures the
square (quarter turn same set, eighth not).

## Exactness decisions

- **rotate_grid_cubes** runs a score (`PATTERN`): 6 rows Z, 4 flat, 6 Y, 4
  flat, 6 X-negative, 4 flat, 6 all, 8 flat; amounts 35° (rot_amount) and 25°
  (rot_amount_y). The first draft said "bands that travel"; the text now reads
  the score.
- **science_screen `#mode:wave` is not a mode.** Accepted: point, line,
  trace/draw, triangle, net/cube. The placement falls back to the plain
  projection; the text describes that. The map token should be corrected.
- **furniture_turntable**: rpm 33.333, needle_r 0.62 fixed, platter rotates
  (line 40). "Thirty-three homecomings a minute" from its own header.
- **spin** placed twice (r18 at 180, r19 at 0), both on 0.90 plinths.
- **catalyst_vent** token: emit 2.5 s, wave 3, delay 5 s, requires the catalyst
  armed ("until player has the bracelet"). **catalyst_prompter_box**:
  emergence slide, lease 45 s. The foe→friend line comes from the dropped
  Chamber_Transformation pearl's note ("a state transition rather than
  damage").
- One `pick_up_cube`; the gate wants 7 on the running score.
- The `3t` wall text: "Rotation produces space as anisotropic."

## Verified critique (2026-09-02) — APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **12 findings survived the editor, 7 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Every finding below
was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
text used to say.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] A cube to carry and a gate that wants seven on the running score, as before. Carry it past the vent.

**Problem.** The cube is never carried; walking into it collects it. And it cannot be carried past the vent in either direction: the vent stands at row 31, the cube and gate at row 36, and the exit at row 38, so the vent is already behind you, and the gate sits one cell from the cube anyway. The gate half of the sentence is right.

**Fix.** A cube and a gate that wants seven on the running score, as before. You do not carry this one. You walk into it and it is gone with a chirp, one point richer, and the gate one cell over reads the total. The rule has not changed since the first hall, and here it is the calm part of the room.

**Evidence.** Verified: pick_up_cube.gd collect path; map_data.json places catalyst_vent at row 31, pick_up_cube and pickup_gate at row 36 cols 3 and 4, catalyst_prompter_box at row 38 and the teleporter at utilities row 38.

### [wrong] It is a row of copies that slides, turns and slides again, so that the order of the operations is visible as a

**Problem.** There is no bend. The row is dead straight and the baked buffer proves it: all thirty-three origins sit at the same y and z with x advancing by a constant 0.14. What the rotation changes is the tilt of each copy, not where it is put. The argument is stronger this way; the text is looking for a shape that is not there.

**Fix.** Thirty-three small cubes in a straight line against a red bar, alternating black and white. The first eleven all lean the same way. Through the middle twelve each copy is turned fifteen degrees further than the last, a hundred and eighty in all, and the ten that follow keep the new lean. The row never bends. Every step is the same step; only the orientation it is carrying has changed, and that is what the order cost.

**Evidence.** Verified: spin.gd:79-102 and the MultiMesh buffer in spin.tscn, 33 instances at y=3, z=0.05, x from -2.4098 to 2.0702 in steps of 0.14.

### [wrong] Placed twice, facing two ways, it shows that a rotation applied to the whole result is not the same as the rot

**Problem.** Neither turn bends anything. The inner fifteen-degree steps twist the copies and leave the line straight; the 180 in the token is a yaw applied by the grid to the finished node, which swings the whole straight row end for end. The claim underneath is right and worth keeping, but the image carrying it is false.

**Fix.** Placed twice on their plinths, one of them yawed half round, and the difference is the claim: the turn inside the sequence changes what each copy is doing, and the turn applied to the finished row only changes which way the row is pointing. Same angle, two places to put it, two different objects.

**Evidence.** Same buffer evidence; the tokens are spin:180:1#plinth:0.90 and spin:0:1#plinth:0.90 at rows 18 and 19. Note that in this room the plinths are real, unlike in Trans_Introduction.

### [wrong] The screen projects what stands near it into a flat diagram, and a tilted row projected onto a plane is a prof

**Problem.** The token puts the screen in waveform mode, which switches scanning off entirely. Nothing near the screen is projected onto it, and nothing in this hall exposes _angle or current_amplitude for it to read, so the tracking target stays null. What is on the glass is a synthetic instrument: the header WAVEFORM over y = A sin(wt + phi), a sine rolling across an axis grid on the system clock, and a panel reading amplitude, frequency, angle and velocity.

**Fix.** The screen is not looking at the room. It is running as a waveform instrument, and what it draws is a sine rolling across an axis grid with an angle read out beside it. That is a rotation seen sideways: take a point going round a circle, keep one of its two numbers and plot it against time, and this is the curve you get. The diagram is a loss on purpose, and the number it threw away is the one that tells you where the point is.

**Evidence.** Verified: science_screen.gd:430-433 sets "wave" as a recognised generic mode and :453 locks it; :466-477 skips the scan when locked; :503-509 hunts for _angle or current_amplitude, which nothing in this map has; :2449-2475 draws the synthetic sine at amplitude 1.5 on Time.get_ticks_msec.

### [wrong] The crystal does not damage them. It turns their state, and a turned foe is a friend.

**Problem.** One dose walks a creature exactly one step along a five-rung arc. A foe hit once is wary, not a friend; a friend costs four hits, and only the fourth fires the pop. The vent seeds every body it emits at foe, so nothing here arrives part-way along. The one-shot version makes the room's own argument cheaper than the code does.

**Fix.** The crystal does not damage them. Each hit walks one body a single step along an arc, foe to wary to neutral to curious to friend, so a friend costs four. That is the chapter's argument done to something living: a transformation is contact, not harm, and it does not finish in one go. Folded is not less.

**Evidence.** Verified: hazard_creature_base.gd:16-18 (PERSONALITY_ARC of five), catalyst_foe.gd:658-676 ("Advance ONE step along the arc, not all the way to friend"), catalyst_vent.gd:37 (initial_state defaults to "foe" and the map token does not override it).

### [wrong] A field of cubes in rows, and the rows turn to a score: six rows tip about one axis, four stay flat, six tip a

**Problem.** Three things. The field is not an exhibit in front of you: the token ships no geometry, it reaches out to the map's own GridMultiMesh and turns the floor of the hall, collision bodies included, so the tilted bands are underfoot. The reading drops a band, the four flat rows between the third axis and the all-three band. And the cycle is forty-four rows long in a hall forty rows deep, so it does not repeat: you see it once, cut off.

**Fix.** Look down. The field of cubes in rows is the floor of this hall. The token has no geometry of its own; it reaches into the grid the room is built from and turns that. The rows turn to a score. Six tip about one axis, four stay flat, six about the next axis, four flat, six about the third, four flat, and then six that tip about all three at once, thirty-five degrees on two of the axes and twenty-five on the third. The score runs forty-four rows and the hall is forty long, so you meet it once and walk off the end of it before it can come round. The collision cubes turn with the picture, so a tilted band is tilted underfoot.

**Evidence.** Verified: RotateGridCubes.gd:36 (multimesh_path "../GridMultiMesh") and :236-254 (rotates the sibling GridCollisions bodies); GridStructureComponent.gd:82-90 names the floor multimesh GridMultiMesh and its collision parent GridCollisions under the same parent_node that GridInteractablesComponent adds artifacts to; PATTERN at :44-53 sums to 44; this map's structure is 40 rows.

### [wrong] Three turns about three axes, and the order is written into the function's name.

**Problem.** The function is called euler_rotate. Nothing in that name says up, then right, then forward. The order is in the three lines of the body, which the reader can see, and pointing at the name sends them to the one place it is not.

**Fix.** Three turns about three axes, and the order is in the body, not the name: up first, then right, then forward.

**Evidence.** The code block is printed in final.md line 6 and its function is euler_rotate; tutorial.md captions the same block "YXZ order" in prose beneath it.

### [weak] Down the hall, a tall grey seam in the air begins to breathe out bodies once the catalyst is in your hand, one

**Problem.** Two misses in one sentence. The vent is not a seam in the air: it is a four-metre translucent grey pillar that meets the floor, ringed at its base with a torus halo, with a dark orb sitting in it. "Seam" is the registry's word rather than the object's. And it is not down the hall from the hatch. The hatch is at row 38, one cell from the teleporter; the vent is at row 31, seven rows behind you by the time you have the crystal.

**Fix.** Turn round. Back up the hall a grey pillar four metres tall has been standing there all along, ringed on the floor at its foot with a dark orb sitting in it, and now that the crystal is in your hand it starts to breathe out bodies: five seconds, then one every two and a half, three of them, and then it goes quiet.

**Evidence.** Verified: catalyst_vent.gd:138-187 builds a 4 m cylinder tapering 0.30 to 0.18, a torus halo at its foot and a 0.72 m dark orb at 0.45 m; :27-30 gives the 5 s warmup after the bracelet is armed; the map token sets emit_interval_s 2.5 and wave_size 3; the row positions are as stated.

### [weak] That number is called spin, and it is the sameness of form, taken as far as it goes.

**Problem.** The number just named is two, and two is not what is called spin. Spin is the quantity that says how many turns it takes, and for the particles the sentence is reaching for it is one half. As written the room hands the visitor a wrong label on the one fact in this section it cannot show them.

**Fix.** How many turns a thing needs to come home is a number physics gives to every particle, and it calls that number spin. It is sameness of form, taken as far as it goes.

**Evidence.** Physics, not code, and the error is unambiguous: the preceding sentence establishes two full turns, and the text then names two as the spin.

### [polish] A dark sphere with no front. It is the one thing in the hall that rotation cannot change, and so it is the ref

**Problem.** True, but it leaves the better fact on the floor. The sphere is not sitting still: it is being turned, every frame, and wobbled, and you cannot tell. The room's whole claim is that rotation makes facing matter, and here is the object that is being rotated and has no facing to lose.

**Fix.** A dark sphere with no front. It is turning the whole time you stand there, slowly, and nothing about it changes, which is why it is the reference: it is the one thing in the hall a rotation cannot get hold of.

**Evidence.** Verified: dark_sphere.gd:455 (rotation_speed 0.15) and :593-595. One turn every forty-two seconds.

### [polish] Take it, and you hold the catalyst; walk away or wait out its lease and it goes back beneath the floor.

**Problem.** The two clauses belong to different states. Walking away closes the lid on a crystal you have not taken. Once it is in your hand, distance does nothing and only the forty-five second lease brings it back, which is also what quiets the vent.

**Fix.** Walk away without taking it and the lid slides shut again. Take it and it is yours for forty-five seconds; let the lease run out and the floor takes it back, and the vent goes quiet with it.

**Evidence.** Verified: catalyst_prompter_box.gd:257-270 gates the whole proximity branch on has_crystal (the crystal still parented to the box), and :340-349 shows that once taken only the lease returns it. The token sets lease_s 45.

### [polish] Next: rotation given time, and let run.

**Problem.** "And let run" hangs off nothing and the line does not parse. The next hall is Trans_RotationSpectacle, whose subject is one small angular rule repeated until it becomes architecture.

**Fix.** Next: the same turn, repeated, until it becomes architecture.

**Evidence.** A grammar fault, not a taste call. I am not asking the other rooms to drop the "Next:" form, which is this chapter's house habit.
