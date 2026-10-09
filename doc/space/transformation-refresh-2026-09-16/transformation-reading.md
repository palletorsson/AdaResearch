# Transformation — current seven-hall reading

Drafts from the running encounters. Headset comfort and a learner walkthrough are still pending.

---

## Trans_Pre

We leave Primitives with a cube, a wedge and a grid. Now we can make a familiar game object: a Mario-style pickup cube.

Watch how its movement is built up, one addition at a time.

<!-- @pick_up_cube -->

The first cube holds still. Walk into it: even without an animation, it can be collected. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

The script chooses a height between two endpoints:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

`lerp` means **linear interpolation**: find a value between two values. Here the endpoints sit below and above the starting height. At `t = 0` the cube is at the lower end; at `t = 0.5` it is halfway; at `t = 1` it reaches the upper end. The animation runs `t` back and forth between zero and one, carrying the cube up and down at a steady speed on each leg.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its facing is **rotation**. This line adds a small turn around the upright Y axis on each update:

```gdscript
rotate_y(rotation_speed * delta)
```

The cube can rise and turn at the same time. Both movements belong to the animation you are watching.

At the fourth cube, watch the edges move apart and come together. It grows and shrinks while it rises and turns. Changing size is **scale**.

```gdscript
var size_factor: float = lerp(1.0 - pulse_scale, 1.0 + pulse_scale, t)
_apply_pulse(size_factor)
```

The same `lerp` now chooses a size factor between 0.7 and 1.3. `_apply_pulse` multiplies the saved size by that factor. Below one, the cube becomes smaller; above one, larger. All three dimensions change together, so it keeps its cube shape.

The small markers beside the examples help you recognise each operation. Look back along the four cubes: still; up and down; add turning; add growing and shrinking. Can you spot all three movements in the last one?

Ahead, wedges lead onto a platform with four collectible cubes. Here the finished animation belongs to a small level made from forms we already know.

Walk up and approach one. You can collect these by walking into them. The three moving demonstrations behind you stay in place for another look.

A few lines of code have given a plain cube the movement of a game pickup: **translation changes position, rotation changes facing, scale changes size.** We will use these three operations throughout the next halls.

<!-- @ -->


---

## Trans_Introduction

In the previous hall, a cube learned to rise, turn and swell. You could watch those movements, walk around them, leave them running.

Here the floor is missing.

Stand at the first gap. Look across, then down. The far side is already there. What would have to change for it to become somewhere you can go?

<!-- @tc -->

A cube travels between the banks. Let it make a journey without you. Its top meets the floor at each end; between them, it is a small piece of floor with nothing beside it.

Step onto it when it returns. Watch the bank you left. Now look down at the cube.

Relative to the room, you are moving. Relative to the cube, you may be standing still.

The transport script advances towards its destination:

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
```

The target lies two metres along the room's z direction. Each update allows another small distance, measured by speed times elapsed seconds. The cube keeps its size and facing.

That line moves the cube. Carrying you requires another relation in the implementation:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The displacement just made is also applied to the supported rider. In VR, `_translate_rider` moves the collision body and the tracked viewpoint together. Contact, detection and this shared movement have to agree for the moving object to become transport. A beautiful motion can still leave someone behind.

Step off at the far bank. The cube waits, then goes back. The gap has not closed. You crossed with a temporary surface under your feet.

<!-- @sc -->

At the next gap, the green cube stays in one place. Watch its upper face. It rises as the cube grows; its edges approach the banks.

Wait until the surface is level with the floor, then walk across during its pause. Look back as it shrinks. What made a floor a moment ago is withdrawing below it.

This cube changes from half a metre to three metres on each side, about a fixed centre. The visible mesh begins as a one-metre cube. The script gives all three dimensions the same factor:

```gdscript
var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
mesh_instance.scale = scale_vec
box_shape.size = scale_vec
```

The last line matters to your feet. A larger image alone would not support them: the collision box must grow too. In this artifact, the two are updated together.

The centre sits below the floor so that the upper face reaches it at full size. Growth spreads downwards as well as upwards. From the bank, you might notice only the part that arrives to meet you.

The cube remains a cube. That is useful to recognise. But its relation to your body changes: something too small and too low to cross becomes a surface that carries your walk. Which description tells you what happened?

<!-- @rc -->

The third gap has a thin orange plank. Wait through a turn before stepping onto it. Across the lane, it reaches towards the sides. After a quarter-turn, its long dimension reaches along your route.

Cross while it holds that alignment. Its dimensions have not changed. Its centre has not moved. Yet a way through has appeared.

The step-and-pause rotation code assigns an angle around the upright axis:

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
```

The collision body follows the mesh's transform. Here the angle travels between zero and ninety degrees, holding for four seconds at either end. The plank is 3.6 metres long, one metre wide and 20 centimetres thick. Its upper face stays level with the floor; its ends overlap the banks when aligned.

Try following one end with your eyes. Rotation keeps the centre in place while that end travels. To say that nothing changed position would lose the very movement that makes this crossing work.

<!-- @ -->

Three gaps; three ways of making a passage. A surface carries you, a volume grows to meet the floor, a length turns towards the other bank. Each operation needs something against which its change can be read. Here there are banks, a centre, directions, dimensions—and your arriving body.

We can now try a question about transformation: what relation makes a change possible, and what relation lets us recognise it? The fixed banks have done quiet work throughout this hall. Move them too, or change the visitor's size, and the same operations may cease to offer a crossing.

The timers keep going while you think. The simulation supplies an opening and a duration. It does not know how long you need to understand what just carried you.

There is more to examine beside the route: measurements, matrices, the order of operations. For now, take the experience of crossing into the next hall. Trans_Translation will give displacement more work to do.


---

## Trans_Translation

The far bank is familiar now. In the last hall, a moving surface carried you across. Here that small surface becomes the thread through a longer space.

Before boarding, follow the line of waiting cubes with your eyes. Some hang over the pit. Others are high above the floor. Which ones could you reach from where you stand?

<!-- @tc -->

The first carrier travels into depth. Step aboard and let the room pass. Look at the cube under your feet: it keeps its facing and size. Along this journey, only its z coordinate changes.

At the next island, the route turns sideways. The carrier moves along x. You can keep looking towards the far end of the hall while travelling across it. Direction of travel and direction of attention have separated.

Then the way goes up.

Stand on the lift and watch the lower landing descend from view. It is still where it was. The carrier changes y; the room gives that change a consequence. You arrive beside an upper platform, three metres above the ground route.

The three small axis markers near the entrance have made these directions visible one at a time. Now the same distinctions have carried your body.

The transport script calculates a destination from a starting position, a direction and a distance:

```gdscript
target_position = initial_position + (move_direction * move_distance)
```

The direction is normalised before this calculation. It says which way; the distance says how far. A displacement of three metres upwards is written with a different direction from three metres forwards. The addition is the same kind of operation.

On the upper route, another carrier travels along z. You have done this before, but there is more space below your feet. What changed in the operation? What changed in the encounter?

A sideways return carries you back across x in the opposite direction. Then the next carrier moves down and forward together, like an escalator. Its surface stays level while its path slopes: three metres down, two metres further along z. Watch the pickup approach as the lower landing comes towards you.

Each carrier's top is placed at its departure deck, with its centre half a metre below. The upper lift socket needs its own starting height: the empty cell alone cannot tell us whether a journey begins above or below. The destination must meet a landing as well. Coordinates describe the ride; their agreement with the surrounding floor makes it usable.

<!-- @pick_up_cube -->

The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

You can return along the same displacement. The pickups already taken do not return with you.

The transport does not collect them at a distance. It adds its own movement to the detected rider:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The helper moves the desktop body or the VR tracking origin with its collision body by that small displacement. It does not place the visitor at the destination. A pickup's detection area then recognises the passing body and calls `collect()`. Two small systems meet: one carries, the other notices contact. The empty place left behind belongs to their encounter.

<!-- @ -->

At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark one possible passage through seven rides. Their positions make some encounters easy and leave other parts of the arena untouched. Another arrangement could ask for another journey using exactly the same operations.

<!-- @translation_cube_demo -->

Step onto the final terrace. Two small door mechanisms wait at hand height. Their handles have the same distance to travel upwards and sideways. Try taking the diagonal.

One refuses. Its handle travels up a rail before sideways movement becomes possible. The other lets you combine those directions; a translucent door shows where you can arrive. Release a handle and take it again. The rule remains in the mechanism.

For the guided door, the code projects your displacement onto the currently permitted direction:

```gdscript
var t = (knob_pos - start).dot(phase1_dir)
knob_pos = start + phase1_dir * t
```

The full implementation also clamps the distance. Your hand can propose another path, but the handle retains only the part its current axis admits.

Up followed by sideways reaches the same position as sideways followed by up. Translation itself does not impose this order. The first mechanism does. The second gives both freedoms together. A destination can be shared by journeys with very different permissions.

<!-- @ -->

Keep the difference between travelling and facing in mind. In Trans_Rotation, the turn itself will become the question.


---

## Trans_Rotation

The transport cube carried you without needing to turn. Here, a surface stays attached to its middle. Follow one end. Where does the other end go?

<!-- @rotation_wall_crossings -->

The green blade turns around y. Its centre stays over the gap while its ends sweep towards the grid on either side. At ninety degrees it pauses. Walk across the length that has arrived in your direction of travel.

The orange blade turns around x. Look at its middle before watching the edges. It has no hinge at the bank. One end descends as the other rises, like the blade of a large paddle wheel.

The far landing is three grid cubes higher. Wait for the blade to lie between the two levels, then climb it during the pause. Look back from above. The middle did not travel up with you.

At the blue blade, z is the axis. The same long surface tips sideways. Approach the lower grid bank beside it; the higher bank is across the blade, not straight ahead through the hall. Cross when it settles into its slope.

These blades are 8.4 metres long and 2.4 metres wide. Their middle is the origin of the turn. The x and z axles sit between the two landing heights; the upper surface meets the grid at about twenty-three degrees. The grid supplies the banks. There is no additional platform hiding how the crossing meets them.

```gdscript
station.pivot.basis = Basis(
	station.axis,
	deg_to_rad(degrees * float(station.sign))
)
```

The panel sits at zero under this pivot. Turning the pivot moves both ends around their shared middle. Its collision body turns with the visible surface.

Y leaves the green blade's height unchanged. X and z change the height of points away from the axle. The banks are arranged to receive those different movements. An axis, a centre, a length and a landing participate in the passage together.

The blades hold their crossing poses for twelve seconds, then continue in the reversed direction: the raised end of each climbing blade begins to descend. A half-turn brings this rectangular surface back to the same crossing geometry. Its other face can carry you now.

<!-- @ -->

Reach the still grid beyond the blades. The next experiment holds the orientations in place so that you can walk into their differences.

<!-- @rotation_array_compare -->

Four bands each contain two columns and six rows of cubes. Begin at the row marked zero. Choose a column and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep the same spacing. The angle increases with each row. Follow an outlined edge when a surface begins to look continuous: it still belongs to one cube.

Try the same forward movement in another band. Where do you climb, where do you descend, where does a face interrupt the route? If you stop, find the row number beside you. Try approaching that row from the still aisle and inspect what your feet were meeting.

In the x band the tilts make rises and falls across your direction of travel. In the z band they make ridges running along it. The y band turns the square footprints while keeping the tops horizontal. In the fourth band each cube receives x, then y, then z. Follow an edge there: its tilt no longer belongs to one plane. The same sequence of angle values produces different ground under a forward-moving body.

The angle keeps increasing through the difficult rows, towards ninety. If you cannot walk straight through, inspect what stopped you. A jump, a different column or a different body may expose another route; a tested limit belongs to a particular way of walking.

The rule fits in two lines:

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

Every cube turns around its own fixed centre. The row supplies how much; the band supplies the axis or the combination. The combined band applies a fixed order:

```gdscript
return Basis(Vector3.BACK, radians) * Basis(Vector3.UP, radians) * Basis(Vector3.RIGHT, -radians)
```

The rightmost matrix acts first: x, then y, then z. Time is not increasing these angles while you walk. Your movement through the array brings you to the next value.

At zero, all four bands are flat. Rotation has changed how their faces meet a body and one another. The cubes themselves have not been cut, joined or replaced.

<!-- @ -->

A surface can become a climb. Repeated surfaces can become a difficulty. Neither result lives in the angle alone.

The final row reaches ninety degrees. A cube can recover an axis-aligned outline there. The route to that flat-looking end still passes through everything before it. More rotation does not promise more obstruction. Carry the row where you stopped into the last court. The floor becomes continuous again. A repeated turn is about to surround you.


<!-- @boolean_tunnel -->

Look through the first hollow cube. There are four more beyond it. Walk into the opening and follow one corner with your eye.

The first segment has no additional turn. Each following segment adds eighteen degrees: zero, eighteen, thirty-six, fifty-four, seventy-two. The numbers have returned from the array. Here they orient the walls around a passage.

```gdscript
angle_deg = i * rotation_per_segment
```

Five full-size segments occupy fifteen metres. They stand still. Your walk supplies the time in which their differences become visible. Turn back: the same sequence now unwinds towards the entrance.

The opening and the turn come from different operations. Subtracting an inner box made each cube hollow. Rotation arranged the hollow cubes. The subtraction changes what is connected inside a solid; turning a solid preserves its own topology while changing where it meets its neighbours and your body. The floor through this tunnel remains continuous.

A repeated angle can build an enclosure as readily as an obstacle. Which edge did you take for a horizon while you were inside it?

<!-- @carousel_cake -->

Step out beside the turning stacks. Find CAKE and follow one stripe on a low layer, then a stripe near the top. You can stand still now. The relations keep changing.

Each layer turns at a constant angular speed. Its place in the stack supplies the multiplier:

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

The lowest layer turns at half a radian per second. Each successive layer turns 1.2 times as fast. The first needs about twelve and a half seconds for a revolution; the eighth needs about three and a half. These are rates through time. In the tunnel, eighteen degrees was a difference between neighbours in space.

Five profiles share those eight layer heights and speeds. CAKE pinches and opens into a brim. COLUMN keeps its radius. ZIGGURAT narrows upwards. SPINDLE widens and pinches again. FLARE puts its broadest layer at the top. The stacks are smaller here so you can compare them from the same floor, without losing their different outlines.

Keep the fastest layer in view as you move between COLUMN and FLARE. It makes the same number of revolutions, yet its rim has a different distance to travel. For a point at radius `r`, the distance travelled per second is `r * angular_speed`.

A turn needed a centre and an axis. Repetition supplied many centres; order changed the ground. Now radius changes what the same angular speed asks a point to do. The next hall gives that change a name: scale.


---

## Trans_Scale

# A door, at last

<!-- @scale_me -->

In the rotation hall, a wider rim travelled farther in a revolution. Here, something waits to be taken.

A figure stands behind a tower of food. Crystal grows through her suit; broad panels lean around her body. The food has begun to flower. Porcelain plates climb above it, and smaller serving plates wind down the side. These are familiar enough to approach, strange enough to keep looking at. In the far wall, beside the figure, a little gold frame surrounds a door.

Try to put yourself through it.

You can see the opening. You can point to the space beyond. Your body will not follow. For the moment, calling it an exit describes somebody else's possibility.

There is a bottle on the highest plate. DRINK ME. Take it.

Now the plate is under your feet. The figure rises beyond you, her leaning panels large enough to seem architectural. The table has become a place to stand. Look down along the serving plates. What could be read at a glance now asks for a journey.

The bottle is gone. Everything around it has grown four times: the food, the figure, the room, the spaces between them. Your body has kept its size. The effect may feel like shrinking. The program has made that feeling by changing the other side of the comparison.

```gdscript
room.scale = Vector3.ONE * FACTOR
```

`FACTOR` is four. The food and the figure belong to `room`, so the same multiplication reaches their positions as well as their dimensions. The figure is farther from the table now. Enlarging a mesh by itself would have left her standing in the wrong relationship to it.

The arrival on the plate is another operation. Scaling the room would not put you there. The program takes the top plate's local position and asks where it has arrived in the enlarged world:

```gdscript
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

Then it moves your body to that position. A small clearance keeps your feet out of the porcelain. The scene offers a transformation; its implementation has to account for where a body can safely begin.

Follow the plates down. Their winding descent was already present when they were small. Nothing in their arrangement needed to be invented after you took the bottle. Yet the distance from one to the next now belongs to balance, gravity and the time spent falling. The program did not multiply your walking speed or the gravity with the room. Uniform scaling has left a very uneven experience.

Find the little door again. It was forty-five centimetres wide and sixty high. Now it is 1.8 metres wide and 2.4 high. Walk through.

Just beyond it stands a second gold frame, also 1.8 metres wide and 2.4 high. Pass through that one too. It stood at this size before you took the bottle. Two openings now admit the same body; only one had to change.

The opening has kept its proportions. It has not acquired another hole, or changed which wall it passes through. What changed is the relation between its dimensions and yours. There is a difference between preserving a shape and preserving what someone can do there.

The figure has not become hostile by becoming enormous. Her unfamiliar body remains with you through the change. The same is true of the food: its strangeness preceded its usefulness as a landscape. You can learn a route through something without exhausting what it is.

Outside, the museum continues at its ordinary scale. The second frame belongs to it. That boundary belongs to the code too: this room was chosen as the thing that could grow. The next hall returns the question to the body that made the comparison possible.

<!-- @ -->


---

## Trans_Body

The corridor narrows, and then it stops.

<!-- @approach_wall -->

A wall of upright slats stands across the way. There is no handle, no plate, no light that turns green. Walk at it.

The slats near you turn out of the plane, and the ones further off do not. What opens is about as wide as you are, and it is centred on you rather than on the wall. Step sideways along the face and the opening comes with you; step back and it closes.

The distance part of the rule can be written simply, for a visitor within reach:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

Two distances, multiplied. The implementation smooths this value and opens a neighbouring run of slats far enough for a body to pass. The first is how far this slat is from you along the wall; the second is how far you are from the wall. Neither is a decision. A slat has no way of knowing whether you meant to come, and no way of remembering that you did.

A door decides where you go. It was placed by someone who had already worked out where people would want to be, and it opens the same way for everyone who arrives. This wall has not worked anything out. It is still a wall: every slat is where it was, the material is the same, nothing has been consumed. Only your standing here is different, and that turns out to be enough.

Look back at it from the far side. It is shut again.

<!-- @carve_grid -->

The next throat is filled to the walls with small cubes. You can see through the gaps between them and there is nothing to see except more of them.

Press into it. The cubes your body touches stop existing.

Not pushed aside, not folded away: removed, and they do not come back. You advance a shell at a time, and behind you is a tunnel with your shoulders in it.

The test is one line, and the interesting part is a number:

```gdscript
@export var bite_m: float = 0.16
```

The lattice is solid and so are you, so the physics engine stops you at the surface and your collider never actually overlaps a cube. A lattice that deleted only what it strictly intersected would delete nothing, for ever, and would look exactly like this one. `bite_m` is the margin by which you are allowed to reach past the place you were stopped. At zero the room is a wall. At 0.16 against a 0.34 cell it clears about one shell per press.

Your movement supplies the input, but the operation on the lattice is deletion. Translation alone would leave every cube somewhere. Here the count changes. The whole behaviour also hangs on a tolerance: the difference between a body being stopped and a position allowed to reach beyond it.

The tunnel stays. Nothing here regrows, because the corridor is the only record that you came this way, and it is not a record of your route — a route is a line. It is a record of your volume.

Somebody following behind you will find the tunnel already cut. They will not be able to tell whether it was made by a person or built that way.

<!-- @approach_scale -->

Nine blocks, set closer together than a pair of shoulders. At rest the gap between neighbours is thirty-five centimetres, which is not "tight". It is shut.

Walk in anyway.

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Each block reads its own distance to the nearest body and takes a size from it. Close, it goes to about a third; far, it is whole. Each block keeps its place in the horizontal grid. Its visible mesh and collision box shrink together; their centres lower to keep the bottom face on the floor. Nothing is deleted. The gap changes because your distance has become a size.

So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you. They have grown back, and the field is shut again, and the way you came is not there any more.

In the pit one room on, another block will grow across your route. There, a clock supplies the factor. It will grow if you approach, if you wait, if you turn away. Here you can ask for room by moving closer. There you must learn a rhythm that does not read you.

<!-- @ -->

Three thresholds and not one of them has a mechanism you could point at — no trigger plate, no switch, no moment where the room decided. The wall is still a wall, the blocks still have their places, and only the lattice is permanently different, because only the lattice was allowed to keep what happened.

In every other room in this chapter you have watched a cube be moved, turned or grown. Here your approach has turned slats, removed cells and reduced blocks. Two boundaries return; one keeps the cut. Walking felt like walking, while the room was doing different kinds of work.

The next room continues changing even when you stand still.


---

## Trans_Pit

The neutrality of a transformation is easier to imagine from outside the space it acts on. Inside it, move and turn can be ways of being removed.

Three rooms in a row. Red blocks cross a corridor. Orange slabs turn between patches of fire. Further on, small green cubes swell into the space that looked available to you.

Wait on the landing. Which opening is arriving, and which is about to go?

## Translation, from inside

<!-- @pusher_block -->

Three red blocks, each with an arrow on its face. Follow one through a complete journey before entering its path. It travels, stops, returns and stops again. The pause is part of the movement you need to learn.

The pusher's script advances a fraction along a line:

```gdscript
var speed_normalized: float = push_speed / push_distance
_t += _direction * speed_normalized * delta
_t = clampf(_t, 0.0, 1.0)
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

`_t` is not a distance. Zero gives the starting point; one gives the endpoint. Dividing speed by distance converts metres per second into a fraction of the journey per second. At either end the script waits, then changes the sign of `_direction`.

Each block travels three metres, but the journeys take different times: two seconds, one and a half seconds, about one and two-thirds. Their pauses differ too. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

From outside, a pusher changes position and keeps its dimensions. From inside, standing where it wants to be, it is a wall that arrives. Look at the space beside its path as carefully as the path itself. A block can leave you room to avoid it, or leave you only the edge.

<!-- @ -->

## Rotation, from inside

<!-- @rc -->

The middle room has two orange turning slabs. Watch one end while the centre stays put. It takes two seconds to make a quarter-turn, waits, then reverses. One slab pauses for four seconds; the other for three.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The collision follows the visible angle. These are the chapter's rotation cubes with their upright wall profile, not the narrow bridge from the Introduction. Across the channel, the broad face obstructs the route. Turned edge-on, it leaves more room beside it.

Its dimensions have not changed. The space it occupies has. A pivot is a fixed point, but it does not make the rest of the object stay still.

Balls arrive from the side platforms as well. Let one cross the scene while you watch the slab. There is more than one clock here, and their movements do not wait for you to finish comparing them.

## Scale, from inside

<!-- @grower_block -->

The last room has three cubes. Wait before approaching. They grow anyway.

The previous hall's blocks made room when you came close. These read elapsed time. Walking towards them, standing still and turning away all leave the same clock running.

For this floor-anchored configuration, the size factor comes from:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

The clock advances by `delta * grow_speed * TAU`. With `grow_speed = 0.15`, a complete small–large–small cycle takes about six and two-thirds seconds. The factor runs between 0.3 and 3.5; with a one-metre base size, those are also the cube's side lengths in metres.

Watch a bottom edge. It stays on the floor. The mesh and collision box grow together, with their centres kept half a side-length above that edge. Growth takes space upwards and sideways rather than passing through the ground.

As a cube expands, its colour warms. Find the passage while it is small, then watch what happens to that passage as it fills out. This instance scales all three axes equally, so the cube keeps its proportions. The gap beside it has no such guarantee. Your available space is the remainder after its growth.

<!-- @ -->

## The constant

The same floor supports every operation, and the same body has to judge its openings. A translation preserves the block's dimensions. A rotation preserves distances within the slab. Here, uniform scaling preserves the cube's proportions. Those statements describe the object. They do not tell you whether you can still stand beside it.

This is the chapter turned round: operations that carried you or made a passage can also occupy it. The matrices did not become false when you entered the room. They became insufficient as descriptions of what the room allows.

Take that difference with you. The next rooms introduce arrays: positions that can keep their addresses while their occupants change.

