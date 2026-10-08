extends "res://commons/hazards/becoming_catalyst/catalyst_projectile.gd"
## The held sphere's mesh is copied at release. Later simplification cannot alter it.
var form: SphereMesh

func _ready() -> void:
	super()
	collision_mask |= 1 # This early form meets the architecture as well as catalyst receivers.

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = form
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.07,0.07,0.07)
	material.roughness = 0.24
	material.metallic = 0.15
	_mesh_instance.material_override = material
	add_child(_mesh_instance)

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = form.radius
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _infer_mode_id() -> String:
	return "primitives"
