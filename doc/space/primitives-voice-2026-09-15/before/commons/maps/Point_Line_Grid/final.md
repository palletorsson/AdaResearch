How far can you move while the record continues to report the same place?

The last room let a dot keep positions and a whiteboard keep ink. Both met grids along the way. A little loop could disappear into one stored position; the same rule could help you return to a corner. Carry that change of purpose here. The grid is about to take up more space, and the point it follows will be somewhere in your own movement.

There may already be a line here that you did not draw in this room. Keep it in view. We will come back to how it arrived.

## A grid in the hand

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Move it a little, then a little more. Watch the line that follows its small marker. Can your hand move while that line refuses another place? Now read the ground table: spacing, retained positions in metres and lattice indices. Move slowly along one direction until two successive retained positions are neighbours. How far apart are the numbers? Release, then compare the marker with the last retained position.

This artifact uses a **0.05 m grid: five centimetres**. Keep that spacing in mind. The walking recorder will apply a related rule on a much larger lattice.

At five-centimetre spacing, successive coordinates along one axis can read `0.10`, `0.15`, `0.20` metres while the corresponding lattice indices read `2`, `3`, `4`. The index names a position in units of the grid spacing. The metre value gives the retained position in world units. They are two ways to read the same stored sample.

The table is a history of retained positions, not a raw-versus-rounded comparison. Follow the small drawing marker: the tool samples that point and aligns the same marker to the lattice on release. The retained table stays visible so you can compare the released marker with its last recorded position. Use this table for the experiment; the tiny floating label is a separate position display.

Try two nearby hand positions whose samples round to the same lattice point. Then cross the boundary that admits a different point. At what spacing would the difference you intended become readable?

<!-- @ -->

## Put the grid under your feet

<!-- @player_trace -->

Walk a small loop beside the recorder, then a wider diagonal. Look behind you for the two paths. Compare their turns before trying to explain the gap between them. Pause, retrace part of your route, and watch what another crossing adds.

In the headset, keep your feet planted and lean a little to one side. Look again. Has something travelled? Then stand upright and take a step. The paths may respond to both. Keep the difference between those actions in mind.

One path is a finer sampled reference. The other records positions rounded onto this placement's **one-metre lattice**. Both are records made by the machine; the fainter line is not an unsampled copy of your movement.

Before rounding anything, the recorder must choose a position to follow. In VR it takes horizontal coordinates from the headset camera and height from the rig origin. In desktop use it follows the museum's walking body, whose origin is at its feet. Neither source supplies a list of footsteps.

These two assignments bring physical movement inside the VR play area into the record:

```gdscript
position_sample.x = camera.global_position.x
position_sample.z = camera.global_position.z
```

The rig origin alone can remain still while you walk around it. Following only that origin used to leave this kind of movement out. Following the headset admits the step, and also the lean. Repairing an omission gives us another question about what the new reading means.

The recorder translates this chosen position into its own frame, then rounds local X and Z. It retains the chosen height with a small display offset, so the vertical coordinate is not rounded by this lattice. The result is an ordered path, with consecutive duplicate positions suppressed.

The spatial operation in this recorder is:

```gdscript
local_point.x = roundf(local_point.x / seam_grid) * seam_grid
local_point.z = roundf(local_point.z / seam_grid) * seam_grid
```

Divide by the spacing, round to an integer, multiply back. Several input positions become the same lattice position. Starting at a lattice node with one-metre spacing, half a metre along an axis reaches the boundary between neighbouring rounding regions. Near such a boundary, a small movement can change the recorded address abruptly.

Find one of those changes by walking. Then find a smaller loop that stays within a single rounding region. A large difference in your experience can become a small difference in the record; a small step across a boundary can become a whole metre in the record's coordinates.

You can work with that disproportion. Move back and forth across an edge and give the change a rhythm. Then move within one region while keeping its address steady. The first task uses the discontinuity; the second uses the interval it leaves open. Neither needs the grid to become a complete account of your movement.

<!-- @grid_lines -->

Return to the ruled grid. If you released a drawing dot or stick in Trace, look for a bend you made there. It may be much larger now. Follow it with your eyes before reading the instrument. What has travelled from the other room?

The release sends a copy of the dot's retained positions to a store shared across rooms in this running game. The grid receives that list. It does not receive the hand, the pen's colour, or a record of what the gesture meant. A whiteboard stroke takes another route: its painted image is not sent here. Nor is this replay the walking path currently growing behind you.

If the panel says there is no released trace, that absence is useful information. Make a short line with a dot in Trace and let go. There must be at least two retained points. Return and look again; the grid should have something of that line to display.

Find a pink line and its green companion. Pink carries the source shape after recentering and enlargement. Green rounds that displayed shape again. The instrument gives the latest source count and length, the display multiplier, and the new snapping interval. Its coordinate rows still belong to the source world. Why do those numbers fail to describe where the pink line stands now?

The display begins by finding the midpoint of the source's bounding box. Each position is moved relative to that centre and multiplied:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

A small trace is enlarged five times. If that would make its longest bounding-box dimension exceed five metres, the multiplier is reduced to fit. The source positions stay in the store; the mesh receives transformed ones. The same coordinates can support another appearance without being rewritten.

Green is made after this enlargement. Here each metre of display space is divided into six snapping intervals: about 16.7 centimetres. This rule rounds all three displayed axes. It is separate from the walking recorder's one-metre horizontal lattice and the hand tool's five-centimetre world lattice. A grid can look like the room's shared rule while several different grids are at work.

The instrument's source rows turn a page every two seconds. It shows the latest release and summarises the last ten; older replay lines can remain visible. The page has moved on before we finished reading it. We can wait for its return, choose one coordinate to follow, or go back to the original dot's retained table. Choosing a reading takes time too.

Look through the glass at the ruled field. Its five-by-five cells continue across the lowered basin. The museum's glass supports the visitor above it; the drawn lines supply no collision surface. An address, a visible line and something that can hold your weight have been made by different parts of the program.

Try imagining this enlarged trace as a route for another body. A bend that barely moved your wrist could ask for a detour at this scale. It can become useful as a score for movement precisely because it is no longer a faithful measure of the original gesture. What would you keep fixed so another person could interpret the score with you?

<!-- @ -->

## A path, not a census

Return to a part of the room you have already crossed. Does the line retain the new journey, or merely announce that this place has been visited before?

The current recorder keeps lists of positions, sample times and speeds. Its capacity is **1024 accepted points**, and it removes the oldest entries when that capacity is exceeded. It is not a permanent dictionary with one entry per visited cell. A position can recur later in the ordered path.

Revisiting, pausing and remaining within one coarse position are different events. The record can distinguish only what its sample trigger and retained fields allow. In particular, a stationary pause does not continually add more position samples. Default fading is off, so merely waiting does not erase an older point either.

Applying the same rounding rule again to an already rounded position leaves it in place. This property is called *idempotence*. It says something precise about repeating the operation. It does not say the first application lost nothing.

The segments between accepted positions can be diagonal. The recorder connects what it kept; it does not reconstruct every step of a walk by choosing one axis at a time. Look for where a straight connection crosses ground you did not actually traverse.

<!-- @ -->

## Whose grid, and for what?

<!-- @floating_sphere_field -->

The floating field offers movement you can watch while your own path is being recorded. A room can contain much more motion than one instrument follows. Being in the room is not the same as being in the dataset.

<!-- @room_grammar -->

A plan generated by rules asks a related question at the scale of walls and doors. An address is useful for composing a room, but the address alone does not say whether a visitor can reach what has been placed there. A second account of bodies, access and purpose is needed.

<!-- @simulation_grid -->

Step into the small five-by-five plan beside the main gallery. Count a row, then a column. There are twenty-five square cells, each one metre across. The numbers name the cells from zero to four; the boundary lines separate areas you can stand in.

Walk across a row, then cut diagonally. The squares offer places for a later construction, but their edges need not become walls for your body. Keep this little floor in mind: cubes can stand on it, wedges can become ramps, and a few placed forms can begin to make a level. First we still need to ask how a boundary becomes a face.

<!-- @ -->

A grid can make positions comparable under shared units and a shared frame. The same choices decide which differences that comparison can express. That does not make every use of a grid surveillance, nor every lost difference harmful. It makes the choice answerable to a task and to the people whose movement supplies the record.

Choose a purpose for your path other than reaching an endpoint: a pause beside something interesting, a detour to accompany someone, a small loop made for its own pleasure. Repeat it so that the coarse path looks as similar as you can make it. Explain which difference matters to your purpose and which additional record would let it count.

You can also keep the coarse record and decline to make it a complete account of you. The fit and the misfit can remain visible together.

The next room adds a third point. A path has been able to return to where it began; now we will ask what a closed boundary needs before it becomes a face.
