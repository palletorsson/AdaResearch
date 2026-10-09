# What lets the cube stay up?

**Learning elements**

- Collision shapes
- Contact support
- Gravity
- Waking a sleeping body

The removable-leg table carries a load. Pull the rose leg and the contacts change. Nothing needs to command the falling path. Nearby walkers remind us that reaching a foot toward a floor and receiving physical support are different operations.

## Continue the object

Bring back the cube from Primitives. This small first reconstruction uses one box resting on one support. The mesh and collider share dimensions. REMOVE SUPPORT moves the supporting body sideways and wakes the load. Let the physics engine supply the result before building the full table.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `09_support.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 09_support.gd

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

## Read what changes

`BoxMesh` makes a surface visible; `BoxShape3D` makes its boundary available to physics. The support is static; the load is a rigid body with ordinary gravity. The starting gap is one centimetre. Contact catches the falling cube and can keep it still. Moving the support supplies no downward command to the load. `sleeping = false` ensures a body that had settled resumes simulation. The full table introduces load position and several contact patches; this first example proves the prerequisite, contact support, without teaching a gait controller.

## Try another beginning

Move the support only 0.1 m instead of 1.5 m and restart. Enough overlap should remain to hold the centred cube. Then use the larger displacement and compare. Keep body dimensions and gravity fixed.

## Carry onward

A contact can maintain rest or change motion during an impact. The bowling point returns for the second case.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/VFM_09_Legs/tutorial.md).
