# When the push ends

**Learning elements**

- Force
- Mass
- Physics updates
- Continued velocity

Press PUSH 1 s. Three equally sized black points start moving. Their masses are 1, 2 and 4 kilograms. Watch after the second has passed: the push ends, but the points keep going.

## Make the small study

Use three instances of the familiar point. Give each the same force for the same time and vary only mass. The supplied `free_point.gd` lets them move freely, with gravity and damping set to zero.

**The hall adds:** The hall supplies lanes, reset controls and measured speeds beside the expected change. Your study shows the three speeds in one caption.

Save `03_mass.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 03_mass.gd

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

## Read the change

`apply_central_force` supplies a push to the rigid body. Godot updates its velocity and position. A greater mass receives a smaller acceleration from the same force.

The loop visits all three points during each physics update. While `remaining` is positive, it applies the force. Once the time runs out, it stops applying it. Nothing sets velocity back to zero.

One newton acting for one second changes these bodies’ speeds by 1, 0.5 and 0.25 m/s, starting from rest and before contact. Pressing again acts on the motion they already have.

## Change one thing

Change the third mass to 8 kg. Predict a speed change of 0.125 m/s from the same pulse. Restart to compare from rest, and keep your hands off while measuring.

## Return to the hall

After one pulse has ended, press again before the points hit anything. Predict another equal change in velocity. Then interrupt a trial by catching a point. The button command stayed the same; your intervention changed the starting state for what followed.

## Model notes

`global_basis` turns the study’s force direction into world axes. Godot already accounts for the physics time step when applying force. `interval / delta` only shortens the last step if less than a full step remains in the one-second pulse.

## Into the next room

A push can end while its consequence continues. Next, choose the push from where the point is now.

[Reflective text](final.md).
