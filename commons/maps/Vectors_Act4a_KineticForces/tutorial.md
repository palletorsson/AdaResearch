# Let motion meet resistance

**Learning elements**

- Drag
- Speed-dependent resistance
- Entering a region
- Opposing velocity

Drop a point into a coloured region. Watch it slow as it falls. Begin with DRAG ONLY; leave BUOYANCY for a later comparison. Use RESET before the next drop.

## Make the small study

Keep the sphere and enable gravity. Add resistance while its centre lies between heights zero and two metres. The small study uses a height test; it does not build a liquid surface.

**The hall adds:** The hall makes three regions visible and lets you add buoyancy. The nearby ramps explore contact friction and rolling.

Save `05_drag.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 05_drag.gd

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

## Read the change

The `if` asks whether the point is inside the height range. Outside it, this script adds no resistance. Inside it, the force opposes `linear_velocity`.

Start with the minus sign in `resistance()`: it reverses the velocity’s direction. Multiplying by `velocity.length()` makes faster motion meet stronger resistance. Double the speed and the force becomes four times as large, before the limit is reached.

`coefficient` controls the strength of that resistance. Gravity continues to pull down while drag opposes the fall. DROP unfreezes the point so the engine can begin this exchange.

## Change one thing

Increase `coefficient` from 0.6 to 3.0 and restart. At the same speed the drag is five times stronger, until capped. Compare the falling speeds over the available drop; the short fall may end before either reaches a steady speed.

## Model notes

The coefficient has units kg/m in this quadratic model. `limit_length` caps drag so that this contribution alone cannot reverse velocity in one physics step. This is a force model, not a fluid simulation. Set the starting position before `add_child`, as shown: moving a frozen kinematic body afterward can introduce unintended velocity. The museum uses a separate movement rule for the player walking through a region.

## Into the next room

Drag resists motion. A spring adds a reason to move back toward an attachment.

[Reflective text](final.md).
