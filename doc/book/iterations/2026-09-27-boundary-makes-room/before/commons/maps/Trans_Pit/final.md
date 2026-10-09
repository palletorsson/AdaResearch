# The Moving Boundary

A wall can arrive on level ground. You can wait beside its path, or step into the space it is about to occupy.

Three rooms in a row: translating blocks, turning slabs, growing cubes. The ground stays level through the studies. There is a way around the first lanes and room to watch the others from beside them. Entering an obstacle's space is a choice you can make after seeing what it does.

Wait on the landing. Which opening is arriving, and which is about to go?

## Translation, from inside

<!-- @pusher_block -->

Three red blocks, each with an arrow on its face. Follow one through a complete journey before entering its path. It travels, stops, returns and stops again. The pause is part of the movement you need to learn.

The script keeps a fraction, `_t`, for its place along the journey: zero at the start, one at the far end. It places the block between those endpoints:

```gdscript
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

Each block travels two metres, but they take different times and their pauses differ. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

From outside, a pusher changes position and keeps its dimensions. From inside, standing where it wants to be, it is a wall that arrives. Look at the space beside its path too. Open floor along the side wall lets you walk around the lanes. Try a lane, then return to where you can watch.

<!-- @ -->

## Rotation, from inside

<!-- @rc -->

The middle room has two orange turning slabs. Watch one end while the centre stays put. Each makes a quarter-turn, waits, then reverses. Their different pauses let one begin while the other still holds its place.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The collision follows the visible angle. These upright wall profiles offer a broad face to the route, then a narrow edge. Watch the room beside one open and close. The middle route lets you keep your distance.

Its dimensions have not changed. The space it occupies has. A pivot is a fixed point, but it does not make the rest of the object stay still.

Look at the floor just beyond the slab's present edge. It is empty now. Follow the edge into it. The space this slab sweeps through is larger than the space one pose shows. Your place can become part of its turn without you taking a step.

Balls arrive from the side platforms as well. Let one cross the scene while you watch the slab. There is more than one clock here, and their movements do not wait for you to finish comparing them.

## Scale, from inside

<!-- @grower_block -->

The last room has three cubes sharing a tempo. Wait before approaching. They grow anyway. Watch them together first; the repetition makes the size change easier to read.

The previous hall's blocks made room when you came close. Here their size follows elapsed time. Walking towards them, standing still and turning away all leave the same clock running. Standing still does not hold the room still.

For this floor-anchored configuration, the size factor comes from:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

All three share the same clock rate, moving from thirty centimetres to three and a half metres on a side. Watch one complete small–large–small cycle, then choose when to approach.

![At its smallest, the green cube leaves the final door visible down the lane.](/book-review/doc/book/figures/Trans_Pit/growers-small.png)

![At full size, the same cube fills the view from the same position.](/book-review/doc/book/figures/Trans_Pit/growers-large.png)

*The same view at two moments in the cycle. At its smallest, the cube leaves the final door visible beyond it. At its largest, it fills the view. The camera has not moved.*

Watch a bottom edge. It stays on the floor. The mesh and collision box grow together, with their centres kept half a side-length above that edge. Growth takes space upwards and sideways rather than passing through the ground.

As a cube expands, its colour warms. Choose a gap and watch it narrow and widen. You can compare a passable interval with an interval that would make you wait, without calling every hesitation a failure. This instance scales all three axes equally, so the cube keeps its proportions. The gap beside it has no such guarantee. Your available space is the remainder after its growth.

<!-- @ -->

## The constant

The floor supports the operations. Which body can use the openings? A translation preserves the block's dimensions. A rotation preserves distances within the slab. Here, uniform scaling preserves the cube's proportions. Those statements describe the object. Clearance also depends on your width, your pace, your viewpoint and the collision shape the program gives you. A gap that comfortably fits one body can demand another's detour.

The block can come back to its starting place. The slab can recover its earlier angle. The growing cube can return to its small size. Each return can look like the beginning again. For the body waiting beside it, a passage has opened and closed in between. Sameness depends on which part of the encounter you keep.

This is the chapter turned round: operations that carried you or made a passage can also occupy it. In this room, the way around is part of the arrangement. Choosing it is another way to read what the space permits.

The transformations did not become false when you entered the room. They became insufficient as descriptions of what the room allows.

## Make room

<!-- @transformation_airlock -->

After the growing cubes, two armoured leaves meet inside a heavy frame. These wait for your arrival. Approach, then stop. Follow the bright strip along one leaf.

It moves sideways and up. It turns through a quarter-turn. Then it becomes smaller, drawing its armour into a recess beside the opening. The frame has stayed still. The passage has changed.

![The same door closed, partway through its turn, and fully open with the leaves reduced into their recesses.](/book-review/doc/book/iterations/2026-09-23-moving-boundary/make-room.png)

*Follow the bright meeting strip through the three views. Each leaf moves, turns and becomes smaller; the frame keeps its place. The opening appears before the whole movement is finished.*

These are the same three operations we added to the pickup cube at the beginning of the chapter. There they made a small object conspicuous. Here they make room for you.

The door keeps a fraction of its opening, from zero to one. Three overlapping intervals of that fraction drive position, angle and size:

```gdscript
var factor: float = lerpf(1.0, 0.34, operations.z)
var at := Vector3(side * lerpf(0.75, 2.15, operations.x), lerpf(1.4, 2.0, operations.x), -0.26)
var turn := Basis(Vector3.BACK, side * operations.y * PI * 0.5)
```

`side` gives the leaves opposite directions. The local Z axis points through the doorway, so these turns happen across its face. Each leaf ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.

Walk through. The door stays open while someone is near it. Once everyone leaves its clearance area, it waits three seconds and reverses. You can return from the other side and open it again.

A moving boundary has become a welcome. That welcome, too, has been written: how near you must come, how much room the frame leaves, how long the door waits. What else could these three operations make possible?

<!-- @ -->
