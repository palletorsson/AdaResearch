# Point Coordinates — carry a position

**Learning elements**

- Pickable
- 3D coordinate system
- Local and world position

Take the black point in the museum's coordinate hall. Its surface and boundary follow your hand. Now give the point you made in Point One that same capacity.

Continue with your existing `PointStudy` and `point.gd`. Keep the radius, centre, mesh and collision shape. Change the body's class and pickup settings, then add a position readout. Day Zero supplies the configured XR hands and Godot XR Tools library. Our script supplies the point they can hold.

## The same point, now pickable

Here is the complete resulting script. The shape construction is unchanged; the new parts are the body's type and settings, the readout, and `_process()`.

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

Run it in the prepared XR scene. Bring your hand to the point, grip, carry it, then release. Its shape is unchanged. Its relation to the hand has changed.

## What the pickup connection adds

`XRToolsPickable` is a physics body with pickup behaviour from the supplied library. It replaces `StaticBody3D`; the same mesh and collider remain its children. The configured hand selects this body and moves it. Our script does not rebuild hand tracking or the grab driver.

`freeze = true` holds the point in place initially. The kinematic freeze mode allows collision checking as a frozen body moves. `ReleaseMode.FROZEN` makes it stay where you release it. `RangedMethod.NONE` limits this example to a nearby hand.

The two collision settings match the prepared museum: `4` puts the point on layer 3, the grab layer; `196615` enables contact with layers 1, 2, 3, 17 and 18. These numbers are supplied configuration. Set them before `add_child(point)`, because the pickup library records its starting settings when the body enters the scene.

To test permission separately, add `point.enabled = false` just before `add_child(point)`. Run again. The visible point and collider remain, but the hand cannot select it. Remove that line to restore pickup.

## One point, two addresses

The readout uses the `Label3D` construction from Point Zero. It belongs to `PointStudy`, so it stays behind when the point moves. `_process()` reads the point again each frame.

`point.global_position` gives the point's position in the world's coordinate system. `to_local(world_position)` converts that position into the coordinate system of the node running this script: **PointStudy**. The two readings describe the same point from different frames.

The last line converts each vector to text. `+` joins the pieces; `\n` starts a new line. It reports the positions without calculating a distance.

If `PointStudy` has the world's origin and orientation, the readings initially agree. Move `PointStudy` two metres along world X and run again. The point still begins at LOCAL `(0, 1.12, 0)`, but WORLD now includes the study's displacement. Changing the parent changes where the point is without changing its local starting value.

Carry the point sideways, up, then forward. Watch which components change. Release it and move your empty hand: the point and its two readings stay where you left them.

## The drawn frame

The museum's pink, grey and black frame helps you see three directions. Its LOCAL card measures from that coloured frame. Our small study measures from `PointStudy`; the choice is explicit in each case. `point.position` would instead mean position relative to the point's parent.

Carry the museum point beyond an arrow's end. The drawing stops; positions continue. A coordinate system can describe more space than its diagram occupies.

Keep this `point.gd`. Lines will continue with the held point and introduce a second endpoint. Distance belongs there.


[Current point.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Coordinates/point.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)
