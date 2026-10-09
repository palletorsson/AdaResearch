We leave Melencolia with forms: the cube, the wedge, a barrier, a pyramid, an arrangement. We have also walked a grid. There is already enough here to make a small level.

Now watch what happens when we give a cube something to do.

<!-- @pick_up_cube -->

The first cube holds still in the middle of the room. Look around it. Its appearance changes as you move, but it keeps its place, facing and size in the room.

Go to the next one. It rises, slows, returns. Wait for the bottom of its movement, then follow it upwards. Where would you put the beginning of this loop?

The pickup cube's update function contains:

```gdscript
time_passed += delta
var bob_offset = sin(time_passed * bob_speed) * bob_height
global_position.y = original_y + bob_offset
```

Each frame adds elapsed time to `time_passed`. Sine makes a repeating offset from that advancing value; the last line places the cube above or below its starting height. Its x and z coordinates stay where the map put them. This is translation along y, repeating over time.

The cube comes back. Its timer goes on.

Beside it, the small Y-translation marker makes the direction explicit with a rail and a coordinate readout. Its shuttle pauses at the ends: the same kind of transformation can have another timing.

The third cube keeps that rising and falling, and adds a turn. Try watching a corner while following the rise. Then let your attention stay with the turn. Two motions occupy the same object.

The rotation marker beside it rocks through an angle around a centre. Compare that back-and-forth turn with the pickup's continuing spin.

```gdscript
rotate_y(rotation_speed * delta)
```

Another angle is added each frame. The upright axis runs through the cube, so its facing changes while the vertical oscillation continues. One line has changed the rhythm you were watching.

At the fourth cube, something else has joined in. Watch the distance between its edges as it turns. It grows and shrinks as well.

Its scale marker keeps a reference outline still while a smaller cube changes inside it. Watch the factor on the readout: what changes together, and what holds its place?

The script computes a repeating scale factor, then uses the mesh's saved size:

```gdscript
_pulse_mesh.scale = _pulse_mesh_scale0 * s
```

Here `s` ranges from 0.7 to 1.3. All three dimensions change together, around the mesh's centre. Each size starts from the saved scale; growth does not accumulate without limit. The object remains a cube.

Still; rise and fall; add turning; add swelling. We have built up the behaviour of one familiar object. A few operations begin to look like an invitation. Perhaps it is calling you over. Perhaps you would rather stay and watch.

Ahead is a small piece of level. Wedges make a ramp up to a platform. Five cubes move on top.

Walk up. The wedge you met among the primitives is now doing work under your feet. The grid gives the pieces places; the platform holds the five pickups apart. Look along them for the motions you have just followed one at a time.

These five can be collected by walking into them. Take one, or leave it moving. The four demonstrations behind you remain available to examine.

The animation repeats, but an encounter can change the scene: after collection, that place is empty. Returning along the same ramp does not put the cube back. Position alone could not describe what happened here.

<!-- @ -->

Take the descending ramp. We now have forms, places, movement and a small action within them. In the next hall, a moving form will become part of the way across.
