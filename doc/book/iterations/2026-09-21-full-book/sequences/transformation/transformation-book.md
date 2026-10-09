# transformation: the chapters

## Trans Pre

*Trans_Pre*

We leave Primitives with a cube, a wedge and a grid. Now we can make a familiar game object: a Mario-style pickup cube.

Watch how its movement is built up, one addition at a time.


The first cube holds still. Pause before approaching and watch a corner: nothing shifts. Then walk into it: even without an animation, it can be collected. Keep its shape in mind as you go to the next one.

This cube moves up and down. Follow it through a complete rise and fall. Its position changes while its size and facing stay the same. Moving an object from one position to another is **translation**. Here that movement follows the vertical Y direction.

The script chooses a height between two endpoints:

```gdscript
global_position.y = lerp(original_y - bob_height, original_y + bob_height, t)
```

`lerp` means **linear interpolation**: find a value between two values. Here the endpoints sit below and above the starting height. At `t = 0` the cube is at the lower end; at `t = 0.5` it is halfway; at `t = 1` it reaches the upper end. The animation runs `t` back and forth between zero and one, carrying the cube up and down at a steady speed on each leg.

The third cube keeps moving up and down. What has been added?

Follow a corner. The cube turns as well. Changing its orientation — which way it faces — is **rotation**. This line adds a small turn around the upright Y axis on each update:

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

The small markers beside the examples help you recognise each operation. Look back along the four stations. The still cube has gone if you collected it; the three moving examples remain. Recall the sequence: still; up and down; add turning; add growing and shrinking. Can you spot all three movements in the last one?

Ahead, wedges lead onto a platform with four collectible cubes. Here the finished animation belongs to a small level made from forms we already know.

Walk up and approach one. You can collect these by walking into them. The three moving demonstrations behind you stay in place for another look.

A few lines of code have given a plain cube the movement of a game pickup: **translation changes position, rotation changes orientation, scale changes size.** We will use these three operations throughout the next halls.

---

## Trans Introduction

*Trans_Introduction*

In the previous hall, a cube learned to rise, turn and swell. You could watch those movements, walk around them, leave them running.

Here the floor is missing.

Stand at the first gap. Look across, then down. The far side is already there. What would have to change for it to become somewhere you can go?


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


The third gap has a thin orange plank. Wait through a turn before stepping onto it. Across the lane, it reaches towards the sides. After a quarter-turn, its long dimension reaches along your route.

Cross while it holds that alignment. Its dimensions have not changed. Its centre has not moved. Yet a way through has appeared.

The step-and-pause rotation code assigns an angle around the upright axis:

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
```

The collision body follows the mesh's transform. Here the angle travels between zero and ninety degrees, holding for four seconds at either end. The plank is 3.6 metres long, one metre wide and 20 centimetres thick. Its upper face stays level with the floor; its ends overlap the banks when aligned.

Try following one end with your eyes. Rotation keeps the centre in place while that end travels. To say that nothing changed position would lose the very movement that makes this crossing work.


Three gaps; three ways of making a passage. A surface carries you, a volume grows to meet the floor, a length turns towards the other bank. Each operation needs something against which its change can be read. Here there are banks, a centre, directions, dimensions—and your arriving body.


Before leaving, take the side aisle to the small control marked MOVE THE BANK. The far landing rests on rails. Slide BANK a little, then watch the orange plank make its usual turn.

What did you change? The plank has the same length, the same centre, the same quarter-turn. Its destination has moved.

At the starting setting, the aligned plank overlaps the landing by thirty centimetres. Move the bank beyond that overlap and a seam opens between their surfaces. The readout measures the seam. It cannot settle what your body can do with it.

Let the plank turn again. An operation that worked a moment ago keeps running exactly as before. The crossing has lost one of its agreements.

The landing uses a translation too:

```gdscript
displacement = move_toward(displacement, target_displacement, SPEED * delta)
landing.position = HOME + Vector3.BACK * displacement
```

Here `Vector3.BACK` is the local positive z direction. The slider sets a destination up to one metre farther along it; the bank travels at a quarter of a metre per second. Its mesh and collision surface belong to the same moving body. RESET brings it back. The side aisles remain available while you compare.


What relation makes a change possible, and what relation lets us recognise it? The banks were doing quiet work before we gave one a handle. We had treated them as the background to the experiment. Now part of that background can answer back.

The timers keep going while you think. The simulation supplies an opening and a duration. It does not know how long you need to understand what just carried you.

There is more to examine beside the route: measurements, matrices, the order of operations. For now, take the experience of crossing into the next hall. Trans_Translation will give displacement more work to do.

---

## Trans Translation

*Trans_Translation*

The far bank is familiar now. In the last hall, a moving surface carried you across. Here that small surface becomes the thread through a longer space.

Before boarding, follow the line of waiting cubes with your eyes. Some hang over the pit. Others are high above the floor. Which ones could you reach from where you stand?


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


The small pickups have been waiting along these journeys. They rise and fall without turning. Their small vertical loop continues as the carrier brings you into contact with them, and each collected cube disappears with a sound.

You can return along the same displacement. The pickups already taken do not return with you.

The transport does not collect them at a distance. It adds its own movement to the detected rider:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

The helper moves the desktop body or the VR tracking origin with its collision body by that small displacement. It does not place the visitor at the destination. A pickup's detection area then recognises the passing body and calls `collect()`. Two small systems meet: one carries, the other notices contact. The empty place left behind belongs to their encounter.


At the last crossing, the waiting cubes run diagonally over the pit. Watch an edge of the carrier as you travel. It does not turn.

This direction changes x and z together. The destination lies eight metres across and eight metres further into the hall. Both coordinates change during the same journey. We have combined directions without adding rotation.

Thirteen pickups mark one possible passage through seven rides. Their positions make some encounters easy and leave other parts of the arena untouched. Another arrangement could ask for another journey using exactly the same operations.


Step onto the final terrace. Two small door mechanisms wait at hand height. Their handles have the same distance to travel upwards and sideways. Try taking the diagonal.

One refuses. Its handle travels up a rail before sideways movement becomes possible. The other lets you combine those directions; a translucent door shows where you can arrive. Release a handle and take it again. The rule remains in the mechanism.

For the guided door, the code projects your displacement onto the currently permitted direction:

```gdscript
var t = (knob_pos - start).dot(phase1_dir)
knob_pos = start + phase1_dir * t
```

The full implementation also clamps the distance. Your hand can propose another path, but the handle retains only the part its current axis admits.

Up followed by sideways reaches the same position as sideways followed by up. Translation itself does not impose this order. The first mechanism does. The second gives both freedoms together. A destination can be shared by journeys with very different permissions.


The torus beside the course already turns while its cylinder rises and falls. It offers a glimpse of the next question. Our carriers have kept their facing throughout; this neighbouring object combines the operations. Keep the difference between travelling and facing in mind. In Trans_Rotation, the turn itself will become the question.

---

## Trans Rotation

*Trans_Rotation*

The transport cube carried you without needing to turn. Here, a surface stays attached to its middle. Follow one end. Where does the other end go?


The green blade turns around y. Its centre stays over the gap while its ends sweep towards the grid. At ninety degrees it pauses. Walk across the length that has arrived in your direction of travel.

The orange blade turns around x. Look at its middle. It has no hinge at the bank. One end descends as the other rises, like a large paddle wheel.

The far landing is three grid cubes higher. During the pause, the blade makes a slope you can climb. But a slope that keeps turning does not keep offering itself as a floor. Through vertical, your feet lose their agreement with it.

Step onto the small level platform beside the orange blade's lower end. Stay there as the turn begins.

You rise, move forward, and arrive beside the higher grid. The blade's centre has stayed where it was. Your head has stayed upright. Which part turned, and which part was kept from turning?

The platform follows an arc while its surface stays level. Its sideways mounting lets the blade pass through vertical without sweeping through your body. Keeping a standing surface under you is another rule in this mechanism. Rotation does not supply it for free.

For the orange ride, the position calculation can be written:

```gdscript
var radial := Vector3(0, -1.5, -3.5)
var orbit := Basis(Vector3.RIGHT, PI * progress) * radial
var endpoint := Vector3(0, 1.5, 0) + orbit
```

`progress` runs from zero to one: half a revolution. The point goes from the lower near bank to the higher far bank; its x coordinate stays fixed. The platform adds its sideways mounting offset and shares each small displacement with a supported rider. Stepping off or jumping releases that support.

At the blue blade, z is the axis. Board from the left. This platform carries you sideways along x and up. Look down the hall while it moves. Rotation around z has no displacement along z to give you. The passage asks you to face another bank.

Both rides pause for twelve seconds, then take twelve for the half-turn. After the high pause they retrace the upper arc. Staying aboard brings you back above the basin. The grid wedges and still aisles offer other returns.

The blades remain 8.4 metres long and 2.4 wide. A centre, an axis and a length describe their turn. A standing surface, a body and a receiving bank make it a passage.


Beyond the blades, the orientations stay still. Your movement will bring you into their differences.


Four bands each contain two columns and six rows of cubes. Begin at zero. Choose a column and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep the same spacing; the angle increases with each row. Follow an outlined edge when surfaces seem continuous. It still belongs to one cube.

Try another band. Where do you climb, descend, stop? Find the row beside you, then inspect it from the still aisle.

X makes rises and falls across your route. Z makes ridges along it. Y turns square footprints while keeping their tops horizontal. The fourth band combines x, then y, then z. At intermediate rows, its edges leave the planes of the grid.

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

The row supplies the angle; the band supplies the axis or combination. For XYZ:

```gdscript
return Basis(Vector3.BACK, radians) * Basis(Vector3.UP, radians) * Basis(Vector3.RIGHT, -radians)
```

The rightmost matrix acts first: x, then y, then z. In the previous hall, the same upward and sideways displacements could exchange order and still reach the same destination. Turns about different axes need not finish in the same orientation when their order is reversed. This band fixes its order in the code.

These angles are assigned by position, not accumulated while you wait.

The cubes have not been cut or joined. Their internal distances survive the turn; the connections available to your walk need not.

Watch the cyan bodies begin: each is 0.44 metres wide. Pink bodies follow from the same places, now 1.20 metres wide. Their height, speed, gravity and forward instruction stay the same. Rings keep the first endpoints. Readouts record distance, stopping and sideways displacement. REPLAY begins both passes again.

You might expect wider to mean worse. Watch z before deciding. Here the narrow body catches on a ridge; the wider one can slide sideways and continue. Its changed route matters as much as its arrival.

The capsules neither jump nor choose a detour. The collision solver supplies their slides. You can walk through them without pushing them, and try your own movement. A stopped trial belongs to this body and these rules. It has not exhausted the space.


The final row reaches ninety degrees. A cube can recover an axis-aligned outline there. The way to that flat-looking end still passes through everything before it. More rotation does not promise more obstruction.

Compare the first and last orientations. A plain cube turned ninety degrees about an axis through the centres of two opposite faces occupies the same shape. Yet a corner has changed places. A mark on one face would make the return a difference you could follow.

The array holds these orientations still. The blades let you encounter the journey between them. A shape can return without giving back the time it took, or undoing where it carried you. What would you need to keep in order to notice that something happened?[^Trans_Rotation--turning-studies]

Walk on into the last court. Let the repeated turns surround you.


Look through the first hollow cube. Four more stand beyond it. Walk inside and follow a corner with your eye.

Each segment adds eighteen degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

Five segments occupy fifteen metres. They stand still; your walk unfolds their differences. Turn back and the sequence unwinds.

Subtracting an inner box made each cube hollow. The turns arrange those openings around a continuous floor.

Which edge did you take for a horizon?


Step out beside the turning stacks. Follow a stripe on a low layer, then near the top. Stand still. Their relations keep changing.

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

The lowest layer turns at half a radian per second; each successive layer turns 1.2 times as fast. In the tunnel, eighteen degrees separated neighbours. Here a rate changes the angle through time.

Eight layers make each of the five profiles: a brim, a column, a taper, a pinched spindle, a flare. They share heights and speeds. Walk between them and compare the room each leaves around itself.

Your body has supplied a measure throughout this hall: what could carry it, obstruct it, surround it. The next hall changes the size of the surroundings while your body stays the same. What will fit then?

[^Trans_Rotation--turning-studies]: The [rotating-drum and axial-sweep studies](http://localhost:3003/research/possible-bodies/transformation-zoetrope.html) extend this question. Twelve fixed poses travel on a turning carrier; beside them, one body turns about its own axis. A centred cube sweeps a cylindrical volume, while the specified triangular profile sweeps a cone. The optional contours record the outer boundary of that full turn; they do not make it solid. These experiments are available in the research preview and test scene, awaiting placement in the museum. Their felt continuity still needs a headset encounter.

---

## Trans Scale

*Trans_Scale*

# A door, at last


In the rotation hall, you tried the openings against the size of your body. Here, something waits to be taken.

A figure stands behind a tower of food. Crystal grows through her suit; broad panels lean around her body. The food has begun to flower. Porcelain plates climb above it, and smaller serving plates wind down the side. These are familiar enough to approach, strange enough to keep looking at. In the far wall, beside the figure, a little gold frame surrounds a door.

Try to put yourself through it.

You can see the opening. You can point to the space beyond. Your body will not follow. For the moment, calling it an exit describes somebody else's possibility.

There is a bottle on the highest plate. DRINK ME. Take it.

A cut. Now the plate is under your feet. The figure rises beyond you, her leaning panels large enough to seem architectural. The table has become a place to stand. Look down along the serving plates. What could be read at a glance now asks for a journey.

The bottle is gone. You have not watched the room swell through the sizes between. Everything around it is suddenly four times as large: the food, the figure, the room, the spaces between them. Your body has kept its size. The effect may feel like shrinking. The program has made that feeling by changing the other side of the comparison.

```gdscript
room.scale = Vector3.ONE * FACTOR
```

`FACTOR` is four. The food and the figure belong to `room`, so the same multiplication reaches their positions as well as their dimensions. The figure is farther from the table now. Enlarging a mesh by itself would have left her standing in the wrong relationship to it.

The arrival on the plate is another operation. Scaling the room would not put you there. The program takes the top plate's local position and asks where it has arrived in the enlarged world:

```gdscript
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

Then it moves your body to that position. The multiplication and the relocation arrive together as an encounter, but they do different work. One changes the room; the other chooses where you meet it again. A small clearance keeps your feet out of the porcelain.

Follow the plates down. Their winding descent was already present when they were small. Nothing in their arrangement needed to be invented after you took the bottle. Yet the distance from one to the next now belongs to balance, gravity and the time spent falling. The program did not multiply your walking speed or the gravity with the room. Uniform scaling has left a very uneven experience.

Find the little door again. It was forty-five centimetres wide and sixty high. Now it is 1.8 metres wide and 2.4 high. Walk through.

Just beyond it stands a second gold frame, also 1.8 metres wide and 2.4 high. Pass through that one too. It stood at this size before you took the bottle.

The little doorway has kept its proportions. There is a difference between preserving a shape and preserving what someone can do there.

The figure has not become hostile by becoming enormous. Her unfamiliar body remains with you through the change. The same is true of the food: its strangeness preceded its usefulness as a landscape. You can learn a route through something without exhausting what it is.

Beyond the two frames, turn toward the museum's own exit. The little door has brought you out of the furnished room; there is still a short walk to the next hall. The museum continues at its ordinary scale. The second frame belongs to it. That boundary belongs to the code too: this room was chosen as the thing that could grow. The next hall returns the question to the body that made the comparison possible.

---

## Trans Body

*Trans_Body*

The corridor narrows, and then it stops.


A wall of upright slats stands across the way. There is no handle, no plate, no light that turns green. Walk at it.

The slats near you turn out of the plane, and the ones further off do not. The opening centres on where you stand rather than on the wall. Step sideways along the face and the opening comes with you; step back and it closes.

The distance part of the rule can be written simply, for a visitor within reach:

```gdscript
var t: float = absf(slat_x - visitor_x) / aperture_m
var d: float = absf(visitor_z) / reach_m
var openness: float = (1.0 - t) * (1.0 - d)
```

Two distances, multiplied. The implementation smooths this value and opens a neighbouring run of slats far enough for a body to pass. The first is how far this slat is from you along the wall; the second is how far you are from the wall. The slat does not know whether you meant to come. Its mechanism holds which side you approached from while it swings, then settles back. Even this small response needs a little state.

A door gives you a place to approach. This wall lets the place of approach move with you. Someone has still chosen how close counts as close, how wide the opening should become, and which collision bodies it will notice. The invitation has dimensions. The slats remain attached to their hinges, the material is the same, nothing has been consumed. Your position changes what that arrangement allows.

Look back while you are still close: a slat may stay open for you. Continue into the space beyond its reach and wait for it to close. Crossing the plane and leaving the wall's attention are different distances.


The next throat holds a low block of small cubes, about 1.3 metres high. You can look over it. The lattice reaches across the way, but it does not enclose your head.

Press into it. The cubes your body touches stop existing.

They are removed. You advance a shell at a time, leaving an open-topped cut through the block. For a standing visitor this is closer to a trench than a tunnel. Your view was above it before your legs had a way through.

The test is one line, and the interesting part is a number:

```gdscript
@export var bite_m: float = 0.16
```

The lattice is solid and so are you, so the physics engine stops you at the surface and your collider never actually overlaps a cube. A lattice that deleted only what it strictly intersected would delete nothing, for ever, and would look exactly like this one. `bite_m` is the margin by which you are allowed to reach past the place you were stopped. At zero the room is a wall. At 0.16 against a 0.34 cell it clears about one shell per press.

Your movement supplies the input, but the operation on the lattice is deletion. Translation alone would leave every cube somewhere. Here the count changes. The whole behaviour also hangs on a tolerance: the difference between a body being stopped and a position allowed to reach beyond it.

The cut stays while this room remains loaded. Look at its stepped sides. It records where the lattice met the collision shape used for your body, expanded by that small margin. The cubes can only retain the contact at their own resolution. Some of you passed above the entire record.

Somebody following behind you will find the cut already made. Will their body fit the passage yours left?


Nine blocks, set closer together than a pair of shoulders. At rest the gap between neighbours is thirty-five centimetres, which is not "tight". It is shut.

Walk in anyway.

```gdscript
var t: float = clampf(sqrt(_dist2[i]) / reach_m, 0.0, 1.0)
t = t * t * (3.0 - 2.0 * t)
return lerpf(min_scale, 1.0, t)
```

Each block reads its own distance to the nearest body and takes a size from it. Close, it goes to about a third; far, it is whole. Each block keeps its place in the horizontal grid. Its visible mesh and collision box shrink together; their centres lower to keep the bottom face on the floor. Nothing is deleted. The gap changes because your distance has become a size.

So the gap you walk through was not made by clearing anything. It was made by measuring.

Look behind you near the last row. Some blocks may still be small: you have passed them, but they still measure you. Walk on towards the far end of the room. Once you are outside their reach, the field fills out again. The caption asks you to step clear; it cannot declare that you already have.

In the next room, another block will grow across your route. There, a clock supplies the factor. It will grow if you approach, if you wait, if you turn away. Here you can ask for room by moving closer. There you must learn a rhythm that does not read you.


Three thresholds, and no button asked for your request. The input was already arriving with your body. The wall is still a wall, the blocks still have their places, and the lattice alone retains a visible cut while the room stays loaded.

In every other room in this chapter you have watched a cube be moved, turned or grown. Here your approach has turned slats, removed cells and reduced blocks. Two boundaries return; one keeps the cut. Walking felt like walking, while the room was doing different kinds of work.

What the room offers depends on the body its code can recognise. The next room continues changing even when you stand still.

---

## Trans Pit

*Trans_Pit*

A wall can arrive on level ground. You can wait beside its path, or step into the space it is about to occupy.

Three rooms in a row: translating blocks, turning slabs, growing cubes. The ground stays level through the studies. There is a way around the first lanes and room to watch the others from beside them. Entering an obstacle's space is a choice you can make after seeing what it does.

Wait on the landing. Which opening is arriving, and which is about to go?

## Translation, from inside


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

Each block travels two metres, but the journeys take different times: about one and a third seconds, one second, just over one second. Their pauses differ too. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

From outside, a pusher changes position and keeps its dimensions. From inside, standing where it wants to be, it is a wall that arrives. Look at the space beside its path as carefully as the path itself. Here the eastern passage lets you walk around. Try a lane because you want to compare its timing, then return to the place where you can watch. The room does not need to trap you for the moving boundary to become legible.


## Rotation, from inside


The middle room has two orange turning slabs. Watch one end while the centre stays put. It takes two seconds to make a quarter-turn, waits, then reverses. One slab pauses for four seconds; the other for three.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The collision follows the visible angle. These are the chapter's rotation cubes with their upright wall profile, not the narrow bridge from the Introduction. Across its strip of floor, the broad face occupies more width. Turned edge-on, it leaves more room beside it. The open middle route also lets you keep your distance; these are studies you can enter, not locks on the exit.

Its dimensions have not changed. The space it occupies has. A pivot is a fixed point, but it does not make the rest of the object stay still.

Look at the floor just beyond the slab's present edge. It is empty now. Follow the edge into it. The space this slab sweeps through is larger than the space one pose shows. Your place can become part of its turn without you taking a step.

Balls arrive from the side platforms as well. Let one cross the scene while you watch the slab. There is more than one clock here, and their movements do not wait for you to finish comparing them.

## Scale, from inside


The last room has three cubes sharing a tempo. Wait before approaching. They grow anyway. Watch them together first; the repetition makes the size change easier to read.

The previous hall's blocks made room when you came close. These read elapsed time. Walking towards them, standing still and turning away all leave the same clock running.

For this floor-anchored configuration, the size factor comes from:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

The clock advances by `delta * grow_speed * TAU`. With `grow_speed = 0.15`, a complete small–large–small cycle takes about six and two-thirds seconds. All three use that rate. The factor runs between 0.3 and 3.5; with a one-metre base size, those are also the cube's side lengths in metres.

Watch a bottom edge. It stays on the floor. The mesh and collision box grow together, with their centres kept half a side-length above that edge. Growth takes space upwards and sideways rather than passing through the ground.

As a cube expands, its colour warms. Choose a gap and watch it narrow and widen. You can compare a passable interval with an interval that would make you wait, without calling every hesitation a failure. This instance scales all three axes equally, so the cube keeps its proportions. The gap beside it has no such guarantee. Your available space is the remainder after its growth.


## The constant

The floor supports the operations. Which body can use the openings? A translation preserves the block's dimensions. A rotation preserves distances within the slab. Here, uniform scaling preserves the cube's proportions. Those statements describe the object. Clearance also depends on your width, your pace, your viewpoint and the collision shape the program gives you. A gap that comfortably fits one body can demand another's detour.

The block can come back to its starting place. The slab can recover its earlier angle. The growing cube can return to its small size. Each return can look like the beginning again. For the body waiting beside it, a passage has opened and closed in between. Sameness depends on which part of the encounter you keep.

This is the chapter turned round: operations that carried you or made a passage can also occupy it. In this room, the way around is part of the arrangement. Choosing it is another way to read what the space permits.

The matrices did not become false when you entered the room. They became insufficient as descriptions of what the room allows.

## Make room


After the growing cubes, two armoured leaves meet inside a heavy frame. Approach, then stop. Follow the bright strip along one leaf.

It moves sideways and up. It turns through a quarter-turn. Then it becomes smaller, drawing its armour into a recess beside the opening. The frame has stayed still. The passage has changed.

These are the same three operations we added to the pickup cube at the beginning of the chapter. There they made a small object conspicuous. Here they make room for you.

The door keeps a fraction of its opening, from zero to one. Three overlapping intervals of that fraction drive position, angle and size:

```gdscript
var factor: float = lerpf(1.0, 0.34, operations.z)
var at := Vector3(side * lerpf(0.75, 2.15, operations.x), lerpf(1.4, 2.0, operations.x), -0.26)
var turn := Basis(Vector3.BACK, side * operations.y * PI * 0.5)
```

`side` gives the leaves opposite directions. The local Z axis points through the doorway, so these turns happen across its face. Each leaf ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.

Walk through. The door stays open while someone is near it. Once everyone leaves its clearance area, it waits three seconds and reverses. You can return from the other side and open it again. No pickup count decides whether you may enter.

A moving boundary has become a welcome. That welcome, too, has been written: how near you must come, how much room the frame leaves, how long the door waits. What else could these three operations make possible?

---
