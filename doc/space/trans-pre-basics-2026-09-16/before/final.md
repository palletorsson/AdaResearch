The coloured court stays behind us. Its pyramids did not have to move for their arrangement to change as we walked around it. Here, stand still for a moment. Let the object make the next difference.

We have forms and a grid: enough to begin a small level. First, watch a familiar cube acquire something to do. **What changes, relative to what, and which parts follow?**

<!-- @pick_up_cube -->

The first cube holds still in the middle of the room. Look around it, then stop. It keeps its place, facing and size. The room is still processing; this cube's movement settings have been set to zero. Stillness here is something the running program maintains.

Go to the next one. Choose an edge of the room to compare it with. It rises, slows, returns. Follow one corner through a whole journey. Does it change its relation to the other corners? Where would you put the beginning of this loop?

The pickup cube's update function contains:

```gdscript
time_passed += delta
var bob_offset = sin(time_passed * bob_speed) * bob_height
global_position.y = original_y + bob_offset
```

In Point One, adding one counted calls. Here, adding `delta` accumulates the time intervals supplied to those calls. Sine turns that advancing value into a repeating offset; we will examine its wave more closely later. The last line places the cube above or below `original_y`, the height saved when this instance began. Its X and Z coordinates stay where the map put them. This is translation along Y, repeating over time.

We need both terms: a reference height and a displacement from it. In this configuration the offset ranges from −0.2 to +0.2 metres. The cube's parts travel together; the distances between its corners remain.

The cube comes back. Its timer goes on.

Beside it, the small Y-translation marker makes the direction explicit with a rail and a coordinate readout. Its shuttle pauses at the ends: the same kind of transformation can have another timing.

The third cube keeps that rising and falling, and adds a turn. Predict the route of one corner before following it. Then watch the middle. Two motions occupy the same object, and different points on it take different paths.

The rotation marker beside it rocks through an angle around a centre. Compare that back-and-forth turn with the pickup's continuing spin.

```gdscript
rotate_y(rotation_speed * delta)
```

Another angle is added each frame. `rotation_speed` is measured in radians per second; multiplying by the interval gives the angle for this update. The local upright axis runs through the cube. Its facing changes while the vertical oscillation continues. The corners keep their distances from one another while their relation to the room changes.

In Animated Cube, moving one corner exposed a crease. Here the mesh's stored corners are left alone. A transform changes how the whole construction is placed. Those are different ways to alter what we see.

At the fourth cube, something else has joined in. Watch the distance between its edges as it turns. It grows and shrinks as well.

Its scale marker keeps a reference outline still while a smaller cube changes inside it. Watch the factor on the readout: what changes together, and what holds its place?

The script computes a repeating scale factor, then uses the mesh's saved size:

```gdscript
_pulse_mesh.scale = _pulse_mesh_scale0 * s
```

Here `s` ranges from 0.7 to 1.3. All three dimensions change by the same factor, around the mesh's centre. Each size starts from the saved scale; growth does not accumulate without limit. Equal edges stay equal and the corners remain right angles. The object remains a cube while its size changes.

Which body has grown? This line scales the visible mesh. The collection detector is a separate part of the scene, and this pulse does not enlarge it. Something can look more expansive without acquiring a larger region in which it can be collected. We have met this separation between appearance and a physical rule before; transformation gives us another way to expose it.

Still; rise and fall; add turning; add swelling. These are four instances of the same artifact, with another operation admitted at each stage. Look back along them. Name one property that survives each addition and one that changes.

A few operations begin to look like an invitation. Perhaps the cube is calling you over. Perhaps you would rather stay and watch. Nothing in these operations names attraction, but they have given us a moving thing to respond to.

Ahead is a small piece of level. Wedges make a ramp up to a platform. Four collectible cubes are placed along the raised route.

Walk up. The wedge you met among the primitives is now doing work under your feet. The grid gives the pieces places; the platform holds the pickups apart. Look along them for the motions you have just followed one at a time.

These four can be collected by walking into their detection regions. Take one, or leave it moving. The four demonstrations behind you remain available to examine: their collection is disabled, although they share the same script.

After collection, that place is empty. During this visit, returning along the same ramp does not put the cube back. Its script marked it collected and removed the instance. A repeating movement and an event that changes the scene have met in one small object.

<!-- @ -->

Take the descending ramp. We have used a saved height, an axis and a scale factor to change relations we can inspect. Now carry the question from the moving object to your own body: what happens when reaching the other side depends on one of these transformations?

In the next hall, the floor is missing.
