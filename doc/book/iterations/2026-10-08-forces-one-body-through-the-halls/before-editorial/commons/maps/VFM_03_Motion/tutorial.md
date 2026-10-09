# When the push ends

**Learning elements**

- Force
- Mass
- Physics updates
- Retained velocity

Three equally sized black points wait in separate lanes. Their masses are 1, 2 and 4 kilograms. Press PUSH 1 s. The push ends; the points keep travelling. The new readouts place their speeds beside the expected velocity change.

## Continue the object

Use three instances of the same PointBody. They differ in mass, not visible size. The new free_point.gd subclass allows physical release and removes inherited gravity and damping for this controlled comparison. A single button applies one newton for one second.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `03_mass.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 03_mass.gd

<!-- student-code:03_mass.gd -->

```gdscript
extends "study.gd"
var points: Array[RigidBody3D] = []
var force := Vector3(0, 0, 1) # newtons in the study frame
var remaining := 0.0
var reading: Label3D

func _ready() -> void:
    for i in range(3):
        var point = Point.new()
        add_child(point)
        point.position = Vector3(i - 1, 1.2, 0)
        point.mass = pow(2.0, i)
        points.append(point)
    reading = caption("")
    button("PUSH 1 s", Vector3(0, 1, -0.8), push)

func push() -> void:
    remaining = 1.0

func _physics_process(delta: float) -> void:
    var interval := minf(remaining, delta)
    for point in points:
        if interval > 0 and not point.is_picked_up():
            point.apply_central_force(global_basis * force * interval / delta)
    remaining = maxf(0, remaining - delta)
    reading.text = "1 / 2 / 4 kg\n%.2f / %.2f / %.2f m/s" % [
        points[0].linear_velocity.length(), points[1].linear_velocity.length(),
        points[2].linear_velocity.length()]
```

## Read what changes

`apply_central_force` asks the physics engine to change motion; it does not assign position. Godot integrates the force each physics step and accounts for mass. We scale only the final partial step by `interval / delta` so the pulse lasts exactly one second. We do not multiply a continuing force by delta a second time. After the pulse, no code erases velocity. The expected changes are 1, 0.5 and 0.25 m/s before contacts or another intervention. Another press adds to the current state; restart the study for a matched trial.

## Try another beginning

Change the third mass to 8 kg. The same pulse should add 0.125 m/s. Predict the result, then compare it with the readout. Keep your hands off during this measurement; a grab or collision is another influence.

## Carry onward

A force can end while its consequence continues. The field will choose the next acceleration from the point’s current address.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/VFM_03_Motion/tutorial.md).
