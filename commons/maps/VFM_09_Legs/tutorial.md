# What lets the cube stay up?

**Learning elements**

- Visible shape and collision shape
- Contact support
- Gravity
- Waking a body

Pull the rose leg from under the loaded table. Watch what loses support first, then what it meets on the way down. The fall follows the changed arrangement.

## Make the small study

Bring back the cube from Primitives. Start with one box resting on one support. Move the support sideways and let the physics engine determine what happens to the load.

**The hall adds:** The hall adds a tabletop, several supports and a load you can rearrange. Your study begins with one contact so its role is easy to see.

Save `09_support.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 09_support.gd

<!-- student-code:09_support.gd -->

```gdscript
extends "study.gd"
var leg: StaticBody3D
var load: RigidBody3D

func _ready() -> void:
    leg = StaticBody3D.new()
    leg.position = Vector3(0, 0.5, 0)
    add_child(leg)
    box_on(leg, Vector3(0.4, 1.0, 0.4))
    load = RigidBody3D.new()
    load.position = Vector3(0, 1.31, 0)
    load.mass = 2.0
    add_child(load)
    box_on(load, Vector3.ONE * 0.6)
    caption("A cube stays up because something meets it.")
    button("REMOVE SUPPORT", Vector3(0, 1, -0.8), remove_support)

func box_on(body: PhysicsBody3D, size: Vector3) -> void:
    var surface := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    surface.mesh = mesh
    body.add_child(surface)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)

func remove_support() -> void:
    leg.position.x = 1.5
    load.sleeping = false
```

## Read the change

`box_on()` gives each body a visible `BoxMesh` and a matching `BoxShape3D`. The engine uses the collision shape to detect contact.

The leg is a `StaticBody3D`. The load is a `RigidBody3D` with gravity. It begins one centimetre above the support, falls onto it and settles.

REMOVE SUPPORT changes the leg’s position. It gives no downward instruction to the cube: gravity was already acting. `sleeping = false` wakes the load if the engine had paused its settled simulation.

## Change one thing

Change the support’s movement from 1.5 m to 0.1 m and restart. Predict that enough overlap will remain to support the centred cube. Then restore the larger movement. Keep the dimensions and gravity the same.

## Return to the hall

At the full table, move the load toward one side before removing a leg. Predict which contacts matter now. Compare the collapse with the centred arrangement.

## Model notes

A mesh alone supplies no physical support. This example pairs visible dimensions with collision dimensions; the contact result depends on the latter. The walkers nearby add foot placement and control, which this small reconstruction leaves for later.

## Into the next room

Contact can hold a body still. Next, let contact pass motion from one body to another.

[Reflective text](final.md).
