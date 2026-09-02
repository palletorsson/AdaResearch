Translation changes nothing about a thing except where it is. That is why a void can be crossed by it, and why a path can be kept as nothing but a list of positions.

This hall has holes in its floor. One ramp, five transport cubes that lift and slide on a single axis apiece, and in the widest chasm a cube that grows until you can stand on it. The whole room is displacement made into infrastructure. Nothing here is reshaped by being moved, which is not the same as nothing turning: the cubes you collect spin on the spot, and the cube in the chasm swells to three metres, holds for four seconds while you walk across it, and shrinks away again.

```gdscript
func move_to(node: Node3D, target: Vector3) -> void:
    node.global_position = target
```

One assignment, and the object is elsewhere. Everything it was, it still is.

## Over the void

<!-- @player_trace -->

Your own path, drawn. Every step you take writes another point, and the line behind you is not only where you were. It is tinted by how fast you got there, green where you dawdled and amber where you ran, full amber at two metres a second. The recorder keeps three lists: positions, times, speeds. The first sentence of this room says a path can be kept as nothing but positions, and the first thing in it keeps more.

<!-- @z_translation_cube -->

A cube on a rail that runs away from you, sliding forty centimetres out and forty back, with four ghosts of itself shrinking behind it. Watch what your eye does. Depth is the one direction in which a pure displacement is read as a change of size, and nothing about the cube has changed at all.

<!-- @y_translation_cube -->

This one lifts, on its own rail, with its own ghosts. Those are the two directions this hall uses to get you across: the transport cubes go up, and they go forward. Nothing in the room asks you to go sideways.

<!-- @pick_up_cube -->

Five cubes, each turning on its own axis and bobbing, four standing on floor and one hanging over the hole near the entrance. You cannot pick one up. Walk into it and it is gone with a rising chirp, and the score is one larger. The only thing translated here is you: the cube never moves at all, and the count is what your crossing leaves behind.

<!-- @pickup_gate -->

The gate at the end counts. It wants seven on the score you have been carrying since the first hall, the same number the cube beside it is displaying, and it is closed until the count gets there and open the moment it does. Nothing about the gate is clever, and that is the point: enough crossings changed a number, and the number changed a wall.

<!-- @synthesis_stand -->

The cube you have been walking into has a family: wire, steel, clay, crate and foam, five stocks of the same object. The measurements ruled the family a series, so there is no hero to pin. Told to show one anyway, the plinth takes the far end of the measured ladder and stands it up: foam. The plaque says pick_up_cube stock=foam and nothing else, because a series verdict carries no single number to print. Every cube in the room is the near end, wire, the shipped form nobody chose.

<!-- @science_screen -->

The screen is set to track a point, and there is no point in this hall for it to track. It wants a neighbour with the word point in its name and a body it can hold, finds none, and draws the instrument anyway: POINT POSITION, P = (x, y), a grid, and a dot pinned at the origin reading plus zero with a trail of nothing. Along the bottom it recites this map's own blurb. A diagram of translation with the translation left out is the most honest object in the room.

<!-- @transform_composition_workbench -->

A workbench with a slider that picks one of four pairs of moves. The same tetrahedron is shown three times: pale and untransformed in the middle, then done in one order on the left and the other on the right, with an arrow from the ghost to each result. Three of the four pairs land in different places, and a badge over the stage says so. None of the four is the pair this hall is about. Two translations always commute, whatever their directions and however many, which is why nothing you do in this room has an order: take the cubes in any sequence and you reach the gate with the same count. Translation is the operation that does not care, and the rotation halls are where that stops being true.

<!-- @dark_sphere -->

A dark sphere that never leaves its cell while you cross. It is not still: it turns slowly, it wobbles, and its glow breathes between dim and dimmer. It is the room's control, and a strict one, because the only thing it refuses to do is the one thing everything else here does.

<!-- @ -->

## Here becomes there

The gaps in this floor are not obstacles. They are invitations, because translation is the operation that does not care what lies between two positions. And the transport cube does cross the void, slowly. Stand on it, wait a second, and it moves at two metres a second toward the far side, and on every frame it adds the distance it just moved to your position as well as to its own. You are not transported. You are added to, frame by frame, by a cube doing to you exactly what the first line of code did to the object.

That is translation's promise, and it is the only transformation in the chapter whose promise covers you.

The next hall takes the same operation apart into three, in a room that forbids you two of them at a time.
