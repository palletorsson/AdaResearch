# incoming.gd
# Source-bound fixture ASSEMBLED from Point One's small solid-point construction.
# Assumed incoming learner state, not a recovered learner portfolio or museum file.
extends Node3D

const RADIUS := 0.14
const CENTRE := Vector3(0, 1.12, 0)

func _ready() -> void:
	var radius := RADIUS
	var centre := CENTRE
	var body := MeshInstance3D.new()
	body.name = "VisiblePoint"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	body.mesh = sphere
	body.material_override = material(Color(0.97, 0.97, 0.95))
	body.position = centre
	add_child(body)
	var solid := StaticBody3D.new()
	solid.name = "PointCollision"
	solid.position = centre
	var collider := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	collider.shape = sphere_shape
	solid.add_child(collider)
	add_child(solid)

func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.32
	return mat
