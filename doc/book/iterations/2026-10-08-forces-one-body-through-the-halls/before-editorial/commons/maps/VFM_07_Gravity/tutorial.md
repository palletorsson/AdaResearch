# Let both points answer

**Learning elements**

- Pair forces
- Equal and opposite contributions
- Superposition
- Softening
- Initial conditions

Begin with PAIR. Two spheres move under their mutual attraction; the visitor is not a source in this comparison. PAIR / FIVE restores five sources and admits you as another one. The added body changes the sum of the relations, not the law of each pair.

## Continue the object

Return to two instances of the same physical point. Give them opposite initial velocities, then calculate one force from the displacement between them. Apply it to one body and its negative to the other. Contacts and uniform gravity are off for this isolated pair.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `08_attraction.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 08_attraction.gd

<!-- student-code:08_attraction.gd -->

```gdscript
extends "study.gd"
var a = Point.new()
var b = Point.new()
var strength := 4.0 # m³ / (kg s²), an authored model value
var softening := 1.2 # metres

func _ready() -> void:
    add_child(a)
    add_child(b)
    a.position = Vector3(-1.5, 1.2, 0)
    b.position = Vector3(1.5, 1.2, 0)
    a.linear_velocity = global_basis * Vector3(0, 0, 0.6)
    b.linear_velocity = -a.linear_velocity
    for point in [a, b]:
        point.mass = 2.0
        point.collision_layer = 0
        point.collision_mask = 0
    caption("Two sources. Neither is fixed.")

func pair_force(displacement: Vector3) -> Vector3:
    var denominator := pow(displacement.length_squared() + softening * softening, 1.5)
    return displacement * strength * a.mass * b.mass / denominator

func _physics_process(_delta: float) -> void:
    var force := pair_force(b.global_position - a.global_position)
    a.apply_central_force(force)
    b.apply_central_force(-force)
```

## Read what changes

The source positions are world positions, so the force is already in world axes. Both masses enter its strength; the engine divides by each receiving mass during integration. Adding softening squared keeps the force finite at close range; it changes the near-field model. This is not a guaranteed circular orbit or an exact energy-conserving integrator. Equal and opposite forces preserve total momentum within numerical tolerance while the pair remains isolated. The museum’s five-source mode adds a visitor/controller boundary, so the displayed point subsystem is no longer isolated.

## Try another beginning

Double only a.mass while keeping the initial velocities. The shared force doubles. The acceleration of a stays the same, while b’s acceleration doubles. Predict both responses before running. Set both positions equal to check that softening returns a finite zero vector.

## Carry onward

Two bodies can interact while passing through one another. Support adds a different relation: a surface that prevents penetration.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/VFM_07_Gravity/tutorial.md).
