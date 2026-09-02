Every displacement is three independent displacements, one per axis, and you only feel that when the room forbids you two of them.

Most of this hall is void. What floor there is comes in islands, and the way between the islands is a vertical maze of transport cubes, each of which moves on one axis only: one goes forward, one goes sideways, one goes up. To get from the entrance to the gate you have to want each of the three directions separately, in the right order, because no cube gives you two at once. The sentence written on the wall says what the room is for: translation produces space as navigable extent. Before you move, space is a set of coordinates with no consequences. Moving is the test of the theory.

```gdscript
func components_on_axes(v: Vector3) -> Array:
    return [v.x, v.y, v.z]

func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
    return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz
```

Take a displacement apart into three numbers, and put it back together from three arrows laid tip to tail. The three are all there is, with one catch the machine will show you if you try it: forward in this engine is minus z, so the third arrow comes back pointing the other way unless you say which way forward is. Decomposition is exact. Reconstruction has to agree about the axes.

## One axis at a time

<!-- @translation_cube_demo -->

A door in a box that will only move along the axis the box currently allows. Push it sideways when it wants to go up and it resists. Complete the lift, and then the sideways slide is permitted. The constraint is the lesson: direction is part of the operation, not a detail added afterwards, and doing the up before the across is a different thing from doing the across before the up, even though the door ends in the same place.

<!-- @x_translation_cube -->

<!-- @z_translation_cube -->

The sideways cube and the depth cube, each on its own rail with its ghosts and its label. Depth is the hard one. Forward and back are the axis your eyes read worst, and so it is isolated here, next to the easy one, so that you can tell them apart before the maze asks you to.

<!-- @cube_scene -->

Cubes standing over the void, three metres up, as scaffolding and waypoints. They are the reference geometry of the whole chapter, the plain solid that everything else is measured against, and here they mark where the next island is when the floor beneath you is nothing.

<!-- @toruscylinder -->

Beside the maze, two motions that are not the same family. A torus turns, and a cylinder rises and falls and leaves a trail. The turning never changes where the torus is. The rising never changes which way the cylinder faces. Put side by side, the two show what this chapter keeps separate: a rotation and a translation can happen in the same place at the same time and share nothing.

<!-- @pick_up_cube -->

One cube to carry across the islands. The carry is three numbers changing, and on the transport cubes you will feel them change one at a time.

<!-- @pickup_gate -->

The gate wants six on the running score. It is the same rule as the last hall: accumulated displacement becomes a condition, and the condition follows you between rooms.

<!-- @dark_sphere -->

A dark sphere, still, over the void. The one thing in the maze that has no component along any axis, so that the components of everything else can be read.

<!-- @ -->

## The skeleton of displacement

The coordinate system is not a description of space laid on afterwards. It is the skeleton of every move. When the room gives you a cube that goes only up, you learn that up was already a separate thing inside every step you have ever taken, and that a walk is a sum of three sums. The maze is hard because it makes you do the arithmetic with your body, one term at a time. It is passable because the arithmetic is exact.

Next: the transformation that makes direction matter.
