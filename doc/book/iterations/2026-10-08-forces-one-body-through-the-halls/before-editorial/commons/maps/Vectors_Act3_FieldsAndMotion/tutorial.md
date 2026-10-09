# Ask the field where you are

**Learning elements**

- Position-dependent acceleration
- Sampling
- Force and acceleration
- Receiving a vector

The vortex begins with one point, so its path can be followed through the arrows. ONE / MANY restores the circulating cargo. The same field meets more receivers; their contacts add another source of change.

## Continue the object

Keep the moving point and its velocity. Replace the fixed force with a function of position. The function returns acceleration: an inward part and a sideways part. Multiply by mass before handing it to the rigid body.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `04_field.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 04_field.gd

<!-- student-code:04_field.gd -->

```gdscript
extends "study.gd"
var point = Point.new()
var reading: Label3D

func _ready() -> void:
    add_child(point)
    point.position = Vector3(2, 1.2, 0)
    point.linear_velocity = global_basis * Vector3(0, 0, 1.8)
    reading = caption("")

func sample(p: Vector3) -> Vector3:
    var flat := Vector3(p.x, 0, p.z)
    if flat.length() < 0.05:
        return Vector3.ZERO
    var tangent := Vector3(-flat.z, 0, flat.x).normalized()
    return -flat * 0.65 + tangent * 2.8 # m/s²

func _physics_process(_delta: float) -> void:
    var acceleration := global_basis * sample(point.position)
    if not point.is_picked_up():
        point.apply_central_force(point.mass * acceleration)
    reading.text = "at %s m\nacceleration %s m/s²" % [point.position, acceleration]
```

## Read what changes

`sample()` works in the station’s local X–Z frame. Its result is transformed into world direction by `global_basis`. The tangent is perpendicular to the radius; near the centre the function deliberately returns zero. `mass * acceleration` makes the commanded acceleration independent of mass. The engine still handles contacts. This small reconstruction removes the museum vortex’s additional damping to isolate the field term. The retained VectorFieldFlow comparison shows another choice: assign the sample as velocity instead of accumulating its effect as acceleration. Those are different receivers.

## Try another beginning

Set the point’s mass to 4 kg. With the same start and no contact, the path should stay the same because the requested force grows with mass. Then set the tangential coefficient to zero; predict the loss of the sideways contribution.

## Carry onward

The next force will read velocity rather than position. Carry the distinction between sampling a value and deciding how a body receives it.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/Vectors_Act3_FieldsAndMotion/tutorial.md).
