# Point Coordinates — carry a position

**Learning elements**

- Pickup behaviour
- Local and world position
- A position read each frame

On the floor below Point One, the small black point can travel with your hand. Its light comes on while held and goes out on release. The WORLD and LOCAL cards keep reporting its position. Carrying, lighting and reporting are separate connections.

Continue with the `PointStudy` and `point.gd` you made in [Point One](../Point_One/tutorial.md). Keep its radius, centre, surface and collision shape. We will change who can move that same body, then report where it is. The tower's smaller black finish and carried light remain reference features; this study adds pickup and coordinates to your existing sphere.

Use the prepared Day Zero XR scene and its configured hands. Keep `PointStudy` at scale `(1, 1, 1)`.

## Change the body; keep its construction

In `point.gd`, replace the declaration `var point: StaticBody3D` with:

```gdscript
var point: XRToolsPickable
var readout: Label3D
```

In `_ready()`, replace only `point = StaticBody3D.new()` with:

```gdscript
    point = XRToolsPickable.new()
```

Immediately after the existing `point.position = CENTRE`, add:

```gdscript
    point.freeze = true
    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    point.collision_layer = 4
    point.collision_mask = 196615
```

Keep the mesh, collider and `add_child(point)` below these settings unchanged. `XRToolsPickable` supplies pickup behaviour; the configured hands select and move it. We reuse that connection rather than build hand tracking here.

`freeze` holds the point initially. Kinematic freeze mode permits collision checking when it moves. `FROZEN` keeps it where you release it; `NONE` limits grabbing to a nearby hand. Layer `4` is grab layer 3; mask `196615` includes layers 1, 2, 3, 17 and 18. These are the prepared project's settings. They precede `add_child(point)` because the library records initial settings on entering the scene.

Run it. Grip, carry and release the point. Its shape remains the one you made in Point One.

To test pickup permission, add `point.enabled = false` just before `add_child(point)`. Predict the result, then run. The surface and collider remain, but the hand cannot select the point. Remove that line.

## Read the same point from two references

At the end of `_ready()`, after `add_child(point)`, add:

```gdscript
    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)
```

Then add this function outside `_ready()`:

```gdscript
func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)
```

This reuses Point Zero's label and per-frame reading pattern. The label belongs to `PointStudy`, so it stays behind when the point moves. `+` joins text; `\n` starts another line.

`global_position` reads the world address. `to_local()` converts it into **PointStudy's** reference frame, including its position, rotation and scale. It does not move the point.

With `PointStudy` at world origin, no rotation and unit scale, the readings agree. Move it two metres along world X and run again. LOCAL still begins at `(0, 1.12, 0)`; WORLD includes the displacement. Restore the study's position.

Carry the point sideways, up and forward. Release it, then move your empty hand. The readings follow the point, not the hand.

## Return to the tower

The tower's LOCAL card measures from its coloured frame, not our `PointStudy`. WORLD still measures from the roof's origin. Its cards format two decimal places; our `str()` readout does not impose that format. Rounding a report does not round the stored position.

Carry the tower point beyond an arrow's end. The drawing stops; positions continue.

Keep this `point.gd`, with pickup enabled. [Point Lines](../Point_Lines/tutorial.md) will reuse its body construction for two endpoints and measure their relation.

[Complete point.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Coordinates/point.gd) · [Working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Course verification](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)

<details class="complete-script">
<summary>Complete script for comparison</summary>

<!-- student-code:point.gd -->
```gdscript
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

var point: XRToolsPickable
var readout: Label3D

func _ready() -> void:
    point = XRToolsPickable.new()
    point.position = CENTRE
    point.freeze = true
    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    point.collision_layer = 4
    point.collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    point.add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    point.add_child(boundary)

    add_child(point)

    readout = Label3D.new()
    readout.position = Vector3(0, 1.6, 0)
    readout.font_size = 36
    readout.pixel_size = 0.005
    add_child(readout)

func _process(_delta: float) -> void:
    var world_position := point.global_position
    var local_position := to_local(world_position)
    readout.text = "LOCAL " + str(local_position) + "\nWORLD " + str(world_position)
```

</details>
