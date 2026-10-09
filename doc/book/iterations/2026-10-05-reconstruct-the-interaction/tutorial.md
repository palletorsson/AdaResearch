# Make a point the hand can carry

**Learning elements**

- Pickable body
- Shared mesh and collision dimensions
- Frozen release

Take the black point. Move your hand. Release it.
The point stays where you left it.
Reconstruct that interaction with one small body.

Point One gave you a mesh and a collider.
Here they become children of a pickable body.
The prepared XR hand supplies tracking and grabbing.
Your code supplies the object it can hold.

Use an empty `Node3D` as your station in a working copy of the prepared museum.
Place it at the exercise position, with scale `(1, 1, 1)`.
Attach `point.gd` below. It creates the point 1.12 metres above that station.
No sphere, collider or point scene needs to be added by hand.

The museum supplies the lit room and configured XR Tools player.
Use the collision and material settings shown here.
Their detailed configuration belongs to later lessons.

## Build the whole small object

```gdscript
extends Node3D

const RADIUS := 0.07
var point: XRToolsPickable

func _ready() -> void:
	point = XRToolsPickable.new()
	point.position = Vector3(0, 1.12, 0)
	point.freeze = true
	point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	point.collision_layer = 4 # Layer 3: Pickable Objects.
	point.collision_mask = 196615 # Layers 1, 2, 3, 17 and 18.

	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	var surface := MeshInstance3D.new()
	surface.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.008, 0.008, 0.012)
	material.roughness = 0.32
	surface.material_override = material
	point.add_child(surface)

	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	var collider := CollisionShape3D.new()
	collider.shape = shape
	point.add_child(collider)

	# Enter the tree last: XR Tools remembers these collision settings at ready.
	add_child(point)
```

`point` keeps a reference to the body your code creates.
`XRToolsPickable` adds the toolkit's grab behaviour to a physics body.
It does not create the sphere's surface or shape for you.

`surface.mesh = sphere` gives the visible node its geometry.
`collider.shape = shape` gives the collision node its boundary.
Both use `RADIUS`. Both belong to `point`, so both move with it.

`freeze` keeps the waiting point in place.
`ReleaseMode.FROZEN` also keeps it in place after release.
`RangedMethod.NONE` asks the hand to come close before grabbing.
The museum point restores its original frozen setting; this smaller version declares frozen release directly.

The layer values connect this body to the prepared collision setup.
`4` selects the pickable layer; `196615` is the museum's existing collision mask.
Keep those supplied values for this exercise.

The final `add_child(point)` puts the completed body into the scene tree.
Its inherited setup then remembers the configured collision settings.
The hand's existing pickup function can find and move it.
You do not need to write another tracking loop.

## Predict, try, explain

Run your working copy. Bring the hand close, grab, move, release.
The surface and boundary move together. The released body stays.

Choose another `RADIUS` and run again.
Predict the new visible radius and collision radius before grabbing.
Explain why one value changes both.

Then add `point.enabled = false` before `add_child(point)`.
Predict the difference. The sphere still exists, but refuses pickup.
Remove that line when finished.

Rebuild the object once from the short brief, without the full listing.
Name what your code creates and what the toolkit supplies.
Record where you needed help; those gaps guide the next explanation.

This construction ends at pickup and release.
The next part of Coordinates must connect this point to a named frame and readout.
Its current museum wall cards are not automatically connected to this new body.
