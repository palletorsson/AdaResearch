# One impact, then the world

**Learning elements**

- Impulse
- Momentum change
- One-shot state
- Collision response

Pick up the black bowling point or use ROLL. Ten pins wait down the lane. The first contact changes the next one; the score records a consequence of the bodies meeting. Recoil, the cradle, the bag and the catalyst offer other interventions around this primary encounter.

## Continue the object

Use the same point twice for the smallest collision. One is the striker; one receives it. Apply an impulse once, then let the physics engine handle their contact. This first reconstruction is a gravity-free horizontal collision, before the lane adds floor friction, rolling and pin shapes.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `10_impulse.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 10_impulse.gd

<!-- student-code:10_impulse.gd -->

```gdscript
extends "study.gd"
var point = Point.new()
var target: RigidBody3D
var used := false
var impulse := Vector3(0, 0, 3) # N·s in the study frame

func _ready() -> void:
    add_child(point)
    point.position = Vector3(0, 1.2, -1)
    target = Point.new()
    add_child(target)
    target.position = Vector3(0, 1.2, 1)
    for body in [point, target]:
        body.mass = 1.0
        body.collision_layer = 4
        body.collision_mask = 4
    caption("One impulse. Then the contact has its turn.")
    button("ROLL ONCE", Vector3(0, 1, -1.8), roll)

func roll() -> void:
    if used:
        return
    used = true
    point.apply_central_impulse(global_basis * impulse)
```

## Read what changes

Impulse has units N·s, or kg·m/s. A 3 N·s impulse changes a 1 kg body’s velocity by 3 m/s before contact. `apply_central_impulse` belongs in the one-shot action, not in every physics update. The `used` flag prevents repeated button events from adding more impacts. Collision layers and masks admit the two points to one another. They do not prescribe an elastic outcome or tell the target which way to travel. Restart the study for the next isolated trial; the museum ROLL button remains a repeatable play control.

## Try another beginning

Double the striker’s mass while keeping the impulse. Its initial speed should halve. Predict that speed separately from what the collision will do. Then compare the actual collision rather than assuming ten pins must always fall.

## Carry onward

Force was sustained; impulse happened once. In the last hall, holding a trigger sustains an acceleration request to the player body.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/VFM_08_Arena/tutorial.md).
