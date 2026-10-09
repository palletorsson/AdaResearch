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
