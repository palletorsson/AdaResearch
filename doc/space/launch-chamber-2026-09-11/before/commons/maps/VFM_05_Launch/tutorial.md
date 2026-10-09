# Launch Lab

Projectile motion: one violent vector at time zero, then gravity, patiently, forever.

Launch from the catapult.

```gdscript
func launch(projectile: RigidBody3D, aim: Vector3, power: float) -> void:
    projectile.linear_velocity = aim.normalized() * power
```

Everything about the flight is decided in this one line. The rest is consequence.

Let gravity narrate.

```gdscript
func _physics_process(delta: float) -> void:
    velocity += Vector3.DOWN * 9.8 * delta
    position += velocity * delta
```

The horizontal component never changes; the vertical component loses 9.8 every second. The arc is those two facts drawn together.

Predict the arc before firing.

```gdscript
func arc_point(start: Vector3, v0: Vector3, t: float) -> Vector3:
    return start + v0 * t + 0.5 * Vector3.DOWN * 9.8 * t * t
```

The launch arc artifact draws this equation. Slide the power and watch the prediction move before anything flies.

Aim the turret.

```gdscript
func aim_at(turret: Node3D, target: Vector3) -> Vector3:
    return (target - turret.global_position).normalized()
```

Subtraction is aiming. The turret's whole intelligence is one vector difference.

Pull the slingshot.

```gdscript
func slingshot_velocity(pull: Vector3, k: float) -> Vector3:
    return -pull * k   # release opposite to the stretch
```

You store the launch vector by stretching it backwards. A preview of the springs room next door.

Race the drag lane.

```gdscript
var fast_lane_drag := 0.0
var slow_lane_drag := 0.4
```

Two identical launches, two different fluids. The drag lane shows air resistance as a handicap you can see.

Burst the firework.

```gdscript
func burst(at: Vector3, n: int) -> void:
    for i in n:
        var dir := random_unit_vector()
        spawn_spark(at, dir * burst_speed)
```

One position, many velocities. A particle system is a launch repeated in every direction at once.

> Try: at the mortar siege, hit the far target with the LOWEST power you can. There are two arcs that reach every target — find the high one.

Next: Springs — forces that depend on where you are, not just where you're going.
