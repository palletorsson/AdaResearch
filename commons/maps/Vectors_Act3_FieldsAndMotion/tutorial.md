# Ask the field where you are

**Learning elements**

- A field of vectors
- Sampling by position
- Acceleration and force
- Local and world directions

Follow one point through the vortex arrows. At each place it meets a different direction. Watch it turn before switching ONE / MANY to bring back the circulating cargo.

## Make the small study

Keep the moving point. Replace the fixed push with `sample()`, a function that reads its position and returns an acceleration. Combine an inward pull with a sideways turn.

**The hall adds:** The hall adds visible arrows, damping and several bodies that can collide. Your study isolates the acceleration rule, with a caption showing position and acceleration.

Save `04_field.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 04_field.gd

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

## Read the change

`flat` is the point’s position in the study’s horizontal X–Z plane. Multiplying it by a negative number gives an inward vector toward the centre.

`Vector3(-flat.z, 0, flat.x)` turns that vector sideways by a quarter-turn. Normalizing gives it unit length; multiplying by 2.8 sets the sideways acceleration. Add this to the inward part to make the swirl.

Each physics update samples again at the point’s new position. `global_basis` turns the local result into world axes. Then `point.mass * acceleration` supplies the force needed for that acceleration. The point keeps its existing velocity as this new contribution acts.

## Change one thing

Change the point’s mass to 4 kg. With the same start and no contact, predict the same path: the requested force grows with mass. Restart, then set the sideways coefficient from 2.8 to zero. Watch what remains of the motion.

## Return to the hall

Return to the hall and choose MANY. Follow one body until it meets another. The field still samples position; contact has now changed the velocity with which the body reaches its next position.

## Model notes

The rule returns zero within 0.05 m of the centre, where this sideways direction is undefined. The caption’s position is local and its acceleration is in world axes. This study omits the museum vortex’s damping. The nearby flow display makes a separate choice: using a vector as velocity directly gives different motion from using it as acceleration.

## Into the next room

This force reads position. The next one reads how fast, and in which direction, the point is moving.

[Reflective text](final.md).
