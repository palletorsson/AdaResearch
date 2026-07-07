# A Bridge Made of a Vector

The floor stops. The far ledge waits. The bridge is a force field — a volume of space where one vector overrides gravity.

A force zone is a box that edits physics for whatever enters:

```gdscript
# force_field_zone.gd — an Area3D with one exported vector
@export var field_force := Vector3(0, 9.8, 0)   # straight up: cancels gravity

var bodies_inside: Array[RigidBody3D] = []

func _on_body_entered(b: Node3D) -> void:
    if b is RigidBody3D:
        bodies_inside.append(b)

func _physics_process(_d: float) -> void:
    for b in bodies_inside:
        b.apply_central_force(field_force * b.mass)
```

`force * mass` is the important subtlety: to give every body the same *acceleration* (like gravity does), scale the force by each body's mass — F = ma read right-to-left. Skip the scaling and heavy cubes sag while light ones rocket, which is its own good lesson to leave a slider on.

Cancel gravity exactly and objects float; overshoot and they climb. The crossing wants a slight overshoot plus a push:

```gdscript
field_force = Vector3(2.0, 10.6, 0)   # a little more than g up, a little forward
```

Throw the cube in and read its arc — inside the zone the cube behaves as if the world were tilted; at the exit boundary, ordinary gravity resumes mid-flight and the arc bends back down. The zone's edge is drawn in the air by every trajectory that crosses it.

Your own body obeys the same field if the player's controller applies zone forces to the character:

```gdscript
velocity += field_force * delta      # inside the zone, in the player's mover
```

Step off the ledge into the field. The fall does not come. What holds you is not a platform — it is a *decision about acceleration*, three floats you dialed a moment ago.

Try: set the upward component to exactly 9.8 and the forward component to zero, then jump in with some running speed. You coast in a straight line — Newton's first law, experienced from inside: no net force, no change, the void crossed on pure inertia.
