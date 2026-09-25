# The far bank is already there

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

The cube grows from half a metre to three metres on each side, about a fixed centre. Its mesh is built one metre on a side; the script multiplies all three dimensions by the same factor, from a half to three:

```gdscript
var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
mesh_instance.scale = scale_vec
box_shape.size = scale_vec
```

The last line matters to your feet. A larger image alone would not support them: the collision box must grow too. In this artifact, the two are updated together.

The centre sits below the floor so that the upper face reaches it at full size. Growth spreads downwards as well as upwards. From the bank, you might notice only the part that arrives to meet you.

The cube remains a cube. That is useful to recognise. But its relation to your body changes: something too small and too low to cross becomes a surface that carries your walk. Which description tells you what happened?

<!-- @rc -->

The third gap has a thin orange plank. MOVE THE BANK stands at the approach. Leave its slider at the starting setting for now and watch a turn before stepping onto the plank. Across the lane, it reaches towards the sides. After a quarter-turn, its long dimension reaches along your route.

Cross while it holds that alignment. Its dimensions have not changed. Its centre has not moved. Yet a way through has appeared.

The step-and-pause rotation code assigns an angle around the upright axis:

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
```

The collision body follows the mesh's transform. Here the angle travels between zero and ninety degrees, holding for four seconds at either end. The plank is 3.6 metres long, one metre wide and 20 centimetres thick. Its upper face stays level with the floor; its ends overlap the banks when aligned.

Try following one end with your eyes. Rotation keeps the centre in place while that end travels. To say that nothing changed position would lose the very movement that makes this crossing work.

<!-- @ -->

<!-- @adjustable_landing -->

Return to MOVE THE BANK at the near bank. The far landing rests on rails. Slide BANK a little, then watch the orange plank make its usual turn.

What did you change? The plank has the same length, the same centre, the same quarter-turn. Its destination has moved.

At the starting setting, the aligned plank overlaps the landing by thirty centimetres. Move the bank beyond that overlap and a seam opens between their surfaces. The readout measures the seam. It cannot settle what your body can do with it.

![The aligned plank overlaps the landing at BANK +0.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-at-crossing.png)

![A gap opens beyond the same plank at BANK +1.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-gap.png)

*The same crossing at two bank settings: thirty centimetres of overlap, then seventy centimetres of gap. The plank holds the same quarter-turn in both views. The camera has not moved.*

Let the plank turn again. An operation that worked a moment ago keeps running exactly as before. The crossing has lost one of its agreements.

The landing uses a translation too:

```gdscript
displacement = move_toward(displacement, target_displacement, SPEED * delta)
landing.position = HOME + Vector3.BACK * displacement
```

Here `Vector3.BACK` is the local positive z direction. The slider sets a destination up to one metre farther along it; the bank travels at a quarter of a metre per second. Its mesh and collision surface belong to the same moving body. RESET brings it back. The side aisles remain available while you compare.

<!-- @ -->

Bring the landing back with RESET. The plank has kept making the same turn through both crossings. The bank was part of what made one of them work; giving it a handle lets us find out how.

The timers keep going while you think. The simulation supplies an opening and a duration. It does not know how long you need to understand what just carried you.

There is more to examine beside the route: measurements, matrices, the order of operations. For now, take the experience of crossing into the next hall, where displacement has more work to do.
