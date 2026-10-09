# Point Coordinates — carry a position

**Learning elements**

- Pickable
- 3D coordinate system
- Local and world position

Take the black sphere at the entrance. Its label stays behind. The point follows your hand.

Point One separated a position, a surface and a physical boundary. Here we learn what makes that body grabbable, then read its position in local and global coordinates.

Work with the existing sphere and coordinate frame in the Endless Museum. The player and XR controls are already configured. The excerpts below come from the artifact's scripts; make the small edits in your working copy.

## What makes it grabbable?

Open `commons/primitives/point/interactive_point_origin.gd`. Near the top is:

```gdscript
extends XRToolsPickable
```

`extends` gives this script the behaviour of an existing class. `XRToolsPickable` is a physics body with pickup behaviour. Our point keeps that behaviour and adds its own appearance and feedback.

The sphere's mesh makes it visible. Its collision shape gives it a physical boundary. The pickable behaviour lets the prepared grab system take hold of the body. A mesh or collider alone does not supply that interaction.

Take the sphere, move it and release it. The mesh and collider belong to the held body, so they move together. The station's label belongs elsewhere and stays behind.

Release ends the connection to the hand. This point's scene starts with `freeze = true`, and the pickable's release mode restores that original setting. It stays where you leave it; letting go does not necessarily mean falling. In `interactive_point_origin.gd`, `_on_picked_up()` sets `_is_held = true`; `_on_dropped()` sets it to `false` and hides the point's own position label and guide. The body remains in the room. The supplied grab system moves the body; these handlers respond to the beginning and end of that hold.

Open `commons/primitives/point/point_condition.gd`. In the `held` branch, find `held.position = CENTRE`. Immediately below it, add:

```gdscript
held.set("enabled", false)
```

`held` refers to the existing pickable instance. `set()` changes a named property; `false` switches its pickup permission off. Restart your working copy and try taking the sphere. Its surface and collision shape remain, but the XR grab system refuses the pickup.

Remove the added line and restart. The sphere can be held again. You changed its availability to the hand without rebuilding its shape.

## Local to what?

In the same branch, the original assignment is:

```gdscript
held.position = CENTRE
```

`CENTRE` is `Vector3(0, 1.12, 0)`. A node's `position` is local to its parent. Here that parent is the point's station: the sphere starts at X = 0, Y = 1.12, Z = 0 in the station's frame.

Replace the assignment with:

```gdscript
held.position = CENTRE + Vector3(0, 0.5, 0)
```

The corresponding components add together. Only Y changes, from `1.12` to `1.62`. Predict where the sphere will appear, then restart. It begins higher along the station's Y direction; the label stays put.

Restore `held.position = CENTRE`.

## One point, two addresses

Carry the sphere towards the coloured frame in the basin. Pink marks X, grey marks Y and black marks the Z axis. Move along one direction, then another, watching the LOCAL card. The black arm points towards −Z: moving from the origin along it decreases local Z.

Compare LOCAL with WORLD while holding the sphere still. The same point can have different coordinates because the readings use different frames.

Open `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd`. These two lines occur at separate places in `_process()`:

```gdscript
var world_p: Vector3 = pt.global_position
```

```gdscript
var lp: Vector3 = to_local(pt.global_position)
```

`pt` refers to the sphere we are holding. `global_position` gives its position in the scene's world frame. The first line keeps that value in `world_p`.

The second line converts that world position into the coordinate frame running this script: the coloured frame. `lp` holds the result. `: Vector3` states that each variable contains three components.

The conversion accounts for the frame's position, orientation and scale. Here the frame has a scale of `1.5`, so one local unit spans 1.5 world units. Converting between these frames involves more than choosing another zero.

The sphere's parent and the coloured frame are different nodes. Reading `pt.position` would give coordinates relative to its parent. `to_local(pt.global_position)` deliberately asks for coordinates relative to the coloured frame, wherever the sphere is parented.

Point Zero introduced `_process()`. Here it keeps reading while the grab system moves the body. Holding and reporting are separate jobs connected by the same point.

## Beyond the drawn frame

Carry the sphere beyond an arrow's end. The drawing stops, but its coordinate system still describes positions beyond it. Watch the guides and readings continue to follow your hand.

Choose another starting position in the station. Predict which component will change, try it, then carry the sphere to the frame. Release it and move your empty hand: which object stops following? Explain what WORLD and LOCAL each measure from. You can now change where a body begins, control whether it can be grabbed, and name the frame used to read its position.

In Point Lines, we will keep two positions and examine what joins them. Distance calculation begins there.
