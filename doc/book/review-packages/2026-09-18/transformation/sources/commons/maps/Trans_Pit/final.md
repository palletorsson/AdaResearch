A wall can arrive on level ground. You can wait beside its path, or step into the space it is about to occupy.

Three rooms in a row: translating blocks, turning slabs, growing cubes. The ground stays level through the studies. There is a way around the first lanes and room to watch the others from beside them. Entering an obstacle's space is a choice you can make after seeing what it does.

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

Each block travels two metres, but the journeys take different times: about one and a third seconds, one second, just over one second. Their pauses differ too. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

From outside, a pusher changes position and keeps its dimensions. From inside, standing where it wants to be, it is a wall that arrives. Look at the space beside its path as carefully as the path itself. Here the eastern passage lets you walk around. Try a lane because you want to compare its timing, then return to the place where you can watch. The room does not need to trap you for the moving boundary to become legible.

<!-- @ -->

## Rotation, from inside

<!-- @rc -->

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

<!-- @grower_block -->

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

<!-- @ -->

## The constant

The floor supports the operations. Which body can use the openings? A translation preserves the block's dimensions. A rotation preserves distances within the slab. Here, uniform scaling preserves the cube's proportions. Those statements describe the object. Clearance also depends on your width, your pace, your viewpoint and the collision shape the program gives you. A gap that comfortably fits one body can demand another's detour.

The block can come back to its starting place. The slab can recover its earlier angle. The growing cube can return to its small size. Each return can look like the beginning again. For the body waiting beside it, a passage has opened and closed in between. Sameness depends on which part of the encounter you keep.

This is the chapter turned round: operations that carried you or made a passage can also occupy it. In this room, the way around is part of the arrangement. Choosing it is another way to read what the space permits.

The matrices did not become false when you entered the room. They became insufficient as descriptions of what the room allows.

## Make room

<!-- @transformation_airlock -->

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

<!-- @ -->
