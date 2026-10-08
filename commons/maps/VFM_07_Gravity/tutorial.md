# Let both points answer

**Learning elements**

- Mutual attraction
- Equal and opposite forces
- Adding pair forces
- Initial conditions
- Softening at close range

Begin with PAIR. Follow both spheres: each turns toward a source that is itself moving. Neither one is fixed. Save PAIR / FIVE until you have watched the pair.

## Make the small study

Return to two physical points. Give them opposite starting velocities. Calculate the attraction between them once, apply it to one body, and apply its negative to the other.

**The hall adds:** The hall can add three more spheres and make the visitor another source. Your first reconstruction keeps the pair isolated, with collisions and ordinary downward gravity off.

Save `08_attraction.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 08_attraction.gd

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

## Read the change

Subtract the two world positions to get a displacement from a to b. The force follows that displacement. Both masses multiply its strength.

The denominator makes attraction weaker with separation. Read `softening` as a chosen length that changes the calculation when the points get close. It keeps the force finite even when their positions coincide.

The two calls apply `force` and `-force`. The engine then uses each body’s mass to find its acceleration. Both velocities change, so the next update begins with two new source positions.

## Change one thing

Double only `a.mass` and keep the starting velocities. Predict both responses: the shared force doubles; a’s acceleration stays the same because its mass also doubled; b’s acceleration doubles. Restart to compare.

## Return to the hall

Choose PAIR / FIVE in the hall, then enter the field. Your presence adds another attraction. Track one sphere and notice when a new encounter makes its earlier path a poor guide to what happens next.

## Model notes

This softened attraction is an authored model. Far from the softening length it approaches an inverse-square force. It does not guarantee a circular orbit. Equal and opposite forces preserve the isolated pair’s total momentum within numerical tolerance; the simulation does not conserve energy exactly. Once the visitor joins, the spheres alone are no longer an isolated system.

## Into the next room

These points attract while passing through each other. Bring back collision to ask what lets one body support another.

[Reflective text](final.md).
