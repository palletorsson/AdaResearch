Every displacement is three independent displacements, one per axis, and you only feel that when the room forbids you two of them.

More than a third of this hall's floor is missing, and every missing cell is where a cube goes. What floor there is comes in islands, and the way between them is five transport cubes, each of which moves on one line only: one runs the length of the hall to the island, one runs back the other way, one runs across to the west, one runs diagonally into the last room, and one stands in a hole in a raised floor and lifts. Four of them wait until you are standing on them. The lift does not, so you have to arrive when it does. You arrive high on the east ledge, and the gate and the way out are both two steps from where you land. Everything the hall has to teach is west of them, across the missing floor, and nothing makes you go. Cross anyway, and you find that wanting to be somewhere means wanting three directions in turn, because no cube gives you two at once, until the diagonal does, and the slot it cuts is the sum of the two it replaces.

```gdscript
func components_on_axes(v: Vector3) -> Array:
    return [v.x, v.y, v.z]

func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
    return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz
```

Take a displacement apart into three numbers, and put it back together from three arrows laid tip to tail. The three are all there is, with one catch the machine will show you if you try it: forward in this engine is minus z, so the third arrow comes back pointing the other way unless you say which way forward is. Decomposition is exact. Reconstruction has to agree about the axes.

## One axis at a time

<!-- @translation_cube_demo -->

Two doors in a wireframe box, one red and one blue, each of which will only move along the axis the box currently allows. Push one sideways when it wants to go up and it resists. Complete the lift, and the slide is permitted, and then you do the whole of it again with the other. The constraint is the lesson: direction is part of the operation, not a detail added afterwards. The order belongs to the door and not to the arithmetic. The two displacements add to the same place either way, so the door has to impose a sequence to make you feel them apart.

<!-- @x_translation_cube -->

<!-- @z_translation_cube -->

The sideways cube and the depth cube, each on its own rail, each trailing four shrinking ghosts of where it just was, each printing its one coordinate to three decimals as it goes. There is a speed slider on the rack in front of them. Slow the cube down until you can read the number changing, and watch the other two digits not change at all.

<!-- @cube_scene -->

One cube, a metre on a side, hanging three metres above the widest gap in the floor. It is the chapter's plain solid, the thing everything else is measured against, and here it is out of reach, marking the crossing rather than making it.

<!-- @toruscylinder -->

Beside the maze, two motions that are not the same family. A torus turns, and a cylinder rises and falls and leaves a trail. The turning never changes where the torus is. The rising never changes which way the cylinder faces. Put side by side, the two show what this chapter keeps separate: a rotation and a translation can happen in the same place at the same time and share nothing.

<!-- @pick_up_cube -->

Six cubes, turning and bobbing: one in the north room, one up on the raised floor, four on the south floor. You do not carry them. Walk into one and it is gone with a rising chirp, and the number the gate is watching goes up by one.

<!-- @pickup_gate -->

The gate wants six on the running score. The last hall would not let you leave until you had seven, so this one is open before you reach it: the same rule, already satisfied, standing there so you can watch a condition follow you between rooms. The six cubes in this hall are the count it would have asked for on its own.

<!-- @dark_sphere -->

A dark sphere on the floor of the northern island, turning slowly on itself and breathing light. It turns and it never changes where it is, which is what makes it the thing to read every other motion against.

<!-- @mario_cube -->

Four yellow cubes, at the four places the crossings lead: the north room, the west landing, the south room, and the top of the raised floor. Walk into one and a rainbow of seven bands stands up three metres over it. The first one you reach does something more: the dark sphere shrinks to nothing in little more than a second and is gone. The thing you were reading every motion against is the first casualty of arriving.

<!-- @ -->

## The skeleton of displacement

The coordinate system is not a description of space laid on afterwards. It is the skeleton of every move. When the room gives you a cube that goes only up, you learn that up was already a separate thing inside every step you have ever taken, and that a walk is a sum of three sums. The crossing is slow because it makes you do the arithmetic with your body, one term at a time. It is passable because the arithmetic is exact. The one cube that runs diagonally is not an exception to that. It is the proof: two of the terms changing at once, and a slot in the floor that is exactly their sum.

Next: the transformation that makes direction matter.
