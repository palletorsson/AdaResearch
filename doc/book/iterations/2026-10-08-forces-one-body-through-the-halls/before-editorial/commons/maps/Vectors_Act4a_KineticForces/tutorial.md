# Let motion meet resistance

**Learning elements**

- Quadratic drag
- Region membership
- Opposing velocity
- A bounded physics step

Drop the same point into the three large coloured regions. Begin with DRAG ONLY. The nearby BUOYANCY button adds an upward contribution after the first comparison. RESET and DROP give each trial a shared beginning. The basin ramps nearby ask a separate question about contact friction and rolling.

## Continue the object

Rebuild one falling point and one region. Keep the familiar sphere; enable ordinary gravity and apply resistance only while its centre is between zero and two metres in this small study. The museum extends that membership test across three visible volumes.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `05_drag.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 05_drag.gd

<!-- student-code:05_drag.gd -->

```gdscript
extends "study.gd"
var point = Point.new()
var coefficient := 0.6 # kg/m, chosen for this quadratic model
var released := false

func _ready() -> void:
    point.position = Vector3(0, 3, 0)
    add_child(point)
    point.freeze = true
    point.gravity_scale = 1.0
    caption("DROP · one point, one resistance coefficient")
    button("DROP", Vector3(0, 1, -0.8), drop)

func drop() -> void:
    point.freeze = false
    point.sleeping = false
    released = true

func resistance(velocity: Vector3, mass_kg: float, delta: float) -> Vector3:
    var force := -coefficient * velocity.length() * velocity
    return force.limit_length(mass_kg * velocity.length() / delta)

func _physics_process(delta: float) -> void:
    if not released or point.is_picked_up():
        return
    if point.position.y >= 0 and point.position.y <= 2.0:
        point.apply_central_force(resistance(point.linear_velocity, point.mass, delta))
```

## Read what changes

The minus sign opposes velocity. `velocity.length() * velocity` makes force magnitude proportional to speed squared. With this convention the coefficient has units kg/m. Doubling speed makes four times the drag before the numerical cap. `limit_length` prevents this drag contribution alone from reversing velocity during a large step. Gravity still acts separately. No fluid solver is hidden here, and the player’s walking adapter uses a different resistance mapping. Put the starting position on the point before adding it to the scene: a frozen kinematic teleport can otherwise manufacture velocity.

## Try another beginning

Increase coefficient from 0.6 to 3.0 and restart. At the same downward speed the opposing force is five times larger until capped; the falling body should settle to a lower speed. Keep buoyancy out of this first comparison.

## Carry onward

Resistance opposes an existing movement. A spring adds a different demand: return toward a rest length.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/Vectors_Act4a_KineticForces/tutorial.md).
