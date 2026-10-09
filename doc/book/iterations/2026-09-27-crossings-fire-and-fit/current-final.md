# The far bank is already there

In the previous hall, a cube learned to rise, turn and swell. You could watch those movements, walk around them, leave them running.

Here the floor is missing. Fire glows at the bottom of the basins. If you fall into the fire, you die. The museum returns you to a save point, and you can try the crossing again.

Stand at the first gap. Look across, then down. The far side is already there. What would have to change for it to become somewhere you can go?

<!-- @tc -->

A cube travels between the banks. Let it make a journey without you. Its top meets the floor at each end; between them, it is a small piece of floor with nothing beside it.

Step onto it when it returns. Watch the bank you left. Now look down at the cube.

Relative to the room, you are moving. Relative to the cube, you may be standing still.

The transport script moves the cube towards `target_position`, its destination:

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
```

The destination is two metres farther along the room's z direction. `move_speed * delta` gives the distance the cube can travel during this update: its speed multiplied by the elapsed time. The cube keeps its size and facing.

To carry you, the script also applies each small displacement to the rider it has detected on top:

```gdscript
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

`movement_delta` is the difference between the cube's new position and its previous one. `_translate_rider` adds that difference to your position too. In VR, it moves both the body used to test contact and the viewpoint through which you see the room. The bank recedes while the surface beneath you stays close.

Step off at the far bank. The cube waits, then goes back. The gap has not closed. You crossed with a temporary surface under your feet.

<!-- @sc -->

At the next gap, a green cube grows about a fixed centre below the floor. Watch its upper face rise and its edges approach the banks.

Wait until the surface is level with the floor, then walk across during its pause. Look back as it shrinks. What made a floor a moment ago is withdrawing below it.

The cube grows from half a metre to three metres on each side. Its visible shape, the mesh, is built one metre on a side. The script multiplies all three dimensions by the same factor, `safe_scale`, from a half to three:

```gdscript
var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
mesh_instance.scale = scale_vec
box_shape.size = scale_vec
```

The last line enlarges the collision box, the shape the program uses to test contact with the cube. The visible surface and the surface that supports your feet grow together.

The centre sits below the floor so that the upper face reaches it at full size. Growth spreads downwards as well as upwards. From the bank, you might notice only the part that arrives to meet you.

The cube keeps its proportions throughout. It is recognisably the same shape when it is too small to carry your walk and when it reaches both banks. Your way across appears and disappears within that sameness.

<!-- @rc -->

The third gap has a thin orange plank. A control marked MOVE THE BANK stands at the approach. Leave its slider at the starting setting for now and watch a turn before stepping onto the plank. At first the plank lies across your route, its ends pointing to either side. A quarter-turn brings those ends towards the banks.

Cross while it holds that alignment. The same length of plank now reaches the places you need it to reach, with its centre still in the middle of the gap.

The step-and-pause rotation code assigns an angle around the upright axis:

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
```

The visible plank and its collision body turn together, between zero and ninety degrees, with a four-second pause at each end. The plank is three metres long, one metre wide and 20 centimetres thick. Its upper face stays level with the floor; its ends meet the banks when aligned.

From the bank, follow one end with your eyes as it turns away again. The centre stays in place while the end sweeps a curve around it, carrying the edge of your crossing out of reach.

<!-- @ -->

<!-- @adjustable_landing -->

Return to MOVE THE BANK at the near bank. The far landing rests on rails. Slide BANK a little, then watch the orange plank make its usual turn.

The plank has the same length, the same centre, the same quarter-turn. You have moved the place it needs to reach.

At the starting setting, the aligned plank meets the landing edge to edge. Move the bank and a gap opens between their surfaces. The readout measures how far apart they have become.

![The aligned plank meets the landing at BANK +0.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-edges-meet.png)

![A gap opens beyond the same plank at BANK +1.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-full-gap.png)

*The same crossing at two bank settings: meeting edges, then a one-metre gap. The plank holds the same quarter-turn in both views. The camera has not moved.*

Let the plank turn again. An operation that worked a moment ago keeps running exactly as before. The crossing has lost one of its agreements.

The landing uses a translation too:

```gdscript
displacement = move_toward(displacement, target_displacement, SPEED * delta)
landing.position = HOME + Vector3.BACK * displacement
```

The slider sets `target_displacement`, how far the landing should move from `HOME`. `Vector3.BACK` points along the rails, the local positive z direction. The bank can travel one metre, taking its visible surface and its support with it. The side aisles let you return to the control while the gap stays open.

<!-- @ -->

Bring the landing back with RESET. The plank has kept making the same turn through both crossings. The bank was part of what made one of them work; giving it a handle lets us find out how.

The travelling cube asks you to board and stay with it. The growing cube asks you to wait until it reaches the banks, then cross before it shrinks. The turning plank gives you a pause in which to cross. A place to stand can also be a moment you have to meet.

The timers keep going while you think. The simulation supplies an opening and a duration. It does not know how long you need to understand what just carried you.

There is more to examine beside the route: measurements, matrices, the order of operations. For now, take the experience of crossing into the next hall, where displacement has more work to do.
