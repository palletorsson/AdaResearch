# One impact, then the world

**Learning elements**

- Impulse
- Momentum change
- A one-shot action
- Collision response

Send the black bowling point down the lane. Watch the first pin it reaches and follow that pin into the next contact. Your throw starts a sequence you no longer direct.

## Make the small study

Use the same point twice: one striker and one target. Give the striker one impulse, then let their collision unfold. Start without gravity or a floor so the first question is the impact.

**The hall adds:** The hall adds ten pins, floor friction, rolling and a score. Its ROLL control can be used repeatedly; your study allows one launch before a restart.

Save `10_impulse.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 10_impulse.gd

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

## Read the change

An impulse changes momentum in one action. With a 1 kg body, the chosen 3 N·s impulse gives a velocity change of 3 m/s before contact. Doubling mass halves that initial change in velocity.

`roll()` calls `apply_central_impulse` once. The `used` flag stops another button event from adding a second impulse. This differs from the sustained force you applied during repeated physics updates.

Both points use collision layer and mask 4, so they can meet. The script never assigns a velocity to the target. Its response comes from contact with the striker.

## Change one thing

Double the striker’s mass while keeping the impulse. Predict its initial speed, then observe the collision separately. Restart each trial. A prediction about the launch speed does not yet tell you how the whole collision will end.

## Return to the hall

Back at the lane, throw slightly off-centre. Follow the first sideways deflection and the contacts it makes possible. A small change in aim can produce a different arrangement of fallen pins.

## Model notes

Impulse is measured in N·s, equivalent to kg·m/s. The collision settings and body properties determine the contact response; this code does not promise a perfectly elastic collision. The study’s points meet in mid-air, before the hall adds rolling and floor contact.

## Into the next room

An impulse happens once. In the last hall, hold a trigger to keep adding acceleration to your own movement.

[Reflective text](final.md).
