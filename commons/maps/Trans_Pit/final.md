# The Moving Boundary

A wall can arrive on level ground. You can wait beside its path, or step into the space it is about to occupy.

Three rooms in a row: translating blocks, turning slabs, growing cubes. There is a way around the first lanes and room to watch the others from beside them. The ground stays level. An opening can disappear while you stand still.

The neutrality of a transformation is only available from outside the space it acts on. Everything the chapter did to objects, this hall does to you.

## Translation, from inside

<!-- @pusher_block -->

Three blocks, each with an arrow on its face. Follow one through a complete journey before entering its path. It travels, stops, returns and stops again. The pause is part of the movement you need to learn.

The script keeps a fraction, `_t`, for its place along the journey: zero at the start, one at the far end. It places the block between those endpoints:

```gdscript
var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
_body.global_position = target_pos
```

Each block travels two metres, but they take different times and their pauses differ. Two advance along Z; the third goes the other way. An opening that works for the first does not give you the timing of the next.

The block keeps its dimensions. From outside, a pusher is the mildest thing in the chapter: position changes and nothing else does. Standing where it wants to be, you meet a wall that arrives. The displacement that carried you in an earlier hall can also occupy your place. Beside these lanes, open floor lets you walk around.

<!-- @ -->

## Rotation, from inside

<!-- @rc -->

The middle room has two turning slabs. Watch one end while the centre stays put. Each makes a quarter-turn, waits, then reverses. Their different pauses let one begin while the other still holds its place.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

The collision follows the visible angle. These upright wall profiles offer a broad face to the route, then a narrow edge. Their dimensions stay the same as the clearance beside them changes. The middle route lets you keep your distance.

A rotation has a pivot, and from outside you would say the slab goes nowhere, it only turns. From inside you learn the other half of the fact: a turn changes what the same slab occupies. Nothing about the slab changed, and the gap did.

Look at the floor just beyond a slab's present edge. It is empty now. Follow the edge into it. The space this slab sweeps through is larger than the space one pose shows. Your place can become part of its turn without you taking a step.

Balls arrive from the side platforms as well. There is more than one clock here, and their movements do not wait for you to finish comparing them.

## Scale, from inside

<!-- @grower_block -->

The last room has three cubes sharing a tempo. Wait before approaching. They grow anyway.

The previous hall's blocks made room when you came close. Here their size follows elapsed time. Walking towards them, standing still and turning away all leave the same clock running.

For this floor-anchored configuration, the size factor comes from:

```gdscript
var t: float = (1.0 - cos(_time)) * 0.5
var current_scale: float = lerpf(min_scale, max_scale, t)
```

Cosine carries `t` from zero to one and back; `lerpf` places the size between its two limits. All three cubes move from thirty centimetres to three and a half metres on a side, then return together.

![At its smallest, the cube leaves the final door visible down the lane.](/book-review/doc/book/figures/Trans_Pit/growers-small.png)

![At full size, the same cube fills the view from the same position.](/book-review/doc/book/figures/Trans_Pit/growers-large.png)

*The same view at two moments in the cycle. At its smallest, the cube leaves the final door visible beyond it. At its largest, it fills the view. The camera has not moved.*

Watch a bottom edge. It stays on the floor. The mesh and collision box grow together, with their centres kept half a side-length above that edge. Growth takes space upwards and sideways rather than passing through the ground.

As a cube expands, the gap beside it narrows, then widens again. All three axes scale equally, so the cube keeps its proportions. The gap has no such guarantee. Your available space is the remainder after its growth.

<!-- @ -->

## What returns

The block returns to its starting place, the slab to its earlier angle, the cube to its small size. You may still be waiting, or already be on the other side. An object can recover its pose while your encounter with it continues.

The matrices in the first hall were true: translation preserved everything but position, rotation everything but direction, scale everything but size. They were true of the blocks and the slabs. You were not in the matrix. You were in the room, and from inside the room every one of those preservations arrives as a body coming toward you.

Which body can use the opening? Width, pace and the collision shape assigned to you all matter. A gap may admit you before you are ready to cross. There is room here to wait, watch or take the way around.

## Make room

<!-- @transformation_airlock -->

After the growing cubes, two armoured leaves meet inside a heavy frame. These wait for your arrival. Approach, then stop. Follow the bright strip along one leaf.

It moves sideways and up. It turns through a quarter-turn. Then it becomes smaller, drawing its armour into a recess beside the opening. The frame has stayed still. The passage has changed.

![The same door closed, partway through its turn, and fully open with the leaves reduced into their recesses.](/book-review/doc/book/iterations/2026-09-23-moving-boundary/make-room.png)

*Follow the bright meeting strip through the three views. Each leaf moves, turns and becomes smaller; the frame keeps its place. The opening appears before the whole movement is finished.*

The door keeps a fraction of its opening, from zero to one. Three overlapping intervals of that fraction drive position, angle and size:

```gdscript
var factor: float = lerpf(1.0, 0.34, operations.z)
var at := Vector3(side * lerpf(0.75, 2.15, operations.x), lerpf(1.4, 2.0, operations.x), -0.26)
var turn := Basis(Vector3.BACK, side * operations.y * PI * 0.5)
```

`side` gives the leaves opposite directions. The local Z axis points through the doorway, so these turns happen across its face. Each leaf ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.

Walk through. The door stays open while someone is near it. Once everyone leaves its clearance area, it waits three seconds and reverses. You can return from the other side and open it again. Its welcome has a reach, a width and a waiting time, each chosen in advance.

These are the same three operations we added to the pickup cube at the beginning of the sequence. There they made a small object conspicuous. Here they make room for you.

That is the end of the chapter, and it is the chapter turned round. Three ways of closing a gap, seen from the gap.

<!-- @ -->
