# Continue with the point

**Learning elements**

- Pickable body
- Parent and child movement
- Pickup and release

Continue with the solid point from Point One. Its surface and collision shape already exist. Keep their size, material and position. We will change what your hand can do with this point.

The prepared museum supplies the XR hand and its pickup function. Your code makes the point available to that hand.

For this pilot, edit [incoming.gd](incoming.gd), attached to a `Node3D` station in a working copy with the museum's configured XR player. It collects Point One's small solid-point construction into one file. `body` refers to its visible mesh; `solid` refers to its physics body. Both are local variables inside `_ready()`. Keep these changes in that function.

## Give the existing boundary pickup behaviour

Replace this line:

```gdscript
var solid := StaticBody3D.new()
```

with:

```gdscript
var solid := XRToolsPickable.new()
```

`XRToolsPickable` is the toolkit's physics body with pickup behaviour. The existing collision shape still belongs to `solid`. You do not make another sphere or write a hand-tracking loop.

Immediately after its position assignment, add the settings below:

```gdscript
solid.position = centre
solid.freeze = true
solid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
solid.release_mode = XRToolsPickable.ReleaseMode.FROZEN
solid.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
solid.collision_layer = 4
solid.collision_mask = 196615
```

The first three added lines keep the point still while waiting and after release. Kinematic freezing lets the grab driver move it. `RangedMethod.NONE` requires the hand to come close. The last two lines use the museum's supplied collision settings: layer 3 for pickable objects, with the existing mask for their collisions.

These assignments must run before `add_child(solid)`. When the body enters the scene tree, XR Tools remembers its collision settings for release.

## Make the surface travel with the boundary

At the end of the construction, add one line after the existing `add_child(solid)`:

```gdscript
add_child(solid)
body.reparent(solid)
```

Point One placed the surface and physics body separately. `reparent` moves the existing surface under `solid` in the scene tree. Both nodes are already in the tree, so this call keeps the surface's world position. It does not jump or make a copy. When the hand moves `solid`, its surface and collider move together.

Run the working copy. Bring your hand close, grab, move and release. The sphere follows your hand and stays where you leave it.

## Check what changed

Predict what would happen without the `reparent` line. Try it, then restore it. Which part moves, and which part stays?

Choose a different value for `RADIUS`, using what Point One taught. Predict what will change. Check that the surface and boundary still agree while held. No second sphere-construction example is needed here: you are extending the same one.

Carry this changed code forward. The next part of Coordinates can use the same moving point to examine local and world positions. This pilot ends at pickup and release; it has not connected the museum's coordinate readouts to this fixture.
