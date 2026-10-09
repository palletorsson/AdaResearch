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
