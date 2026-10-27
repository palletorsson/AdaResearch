extends RigidBody3D
## Freestanding prefab terminal. Compound feet and a low centre of mass provide
## stability, without locking rotation or freezing the board while it is in use.
const SCREEN_CENTRE := Vector3(0, 2.5, 0.115)
var placed := false

func _ready() -> void:
	name = "PrefabBoardStand"
	mass = 50.0
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.28, 0)
	linear_damp = 1.2
	angular_damp = 2.5
	continuous_cd = true
	var rubber := PhysicsMaterial.new()
	rubber.friction = 0.7
	rubber.bounce = 0
	physics_material_override = rubber
	var enamel := _material("d6d4c9", 0.15)
	var graphite := _material("303633", 0.45)
	var sole := _material("202622", 0)
	_part(Vector3(4.16, 4.16, 0.18), Vector3(0, 2.5, 0), enamel)
	for x in [-1.65, 1.65]:
		_part(Vector3(0.16, 0.54, 0.16), Vector3(x, 0.29, 0), graphite)
		_part(Vector3(0.32, 0.12, 1.9), Vector3(x, 0.08, 0), enamel)
		for z in [-0.77, 0.77]:
			_part(Vector3(0.30, 0.04, 0.32), Vector3(x, 0.02, z), sole)
	_part(Vector3(3.3, 0.10, 0.16), Vector3(0, 0.18, 0), graphite)
	_part(Vector3(0.24, 0.025, 0.012), Vector3(-1.82, 0.46, 0.097), _material("d76332", 0), false)
	set_deployed(false)

func _material(hex: String, metal: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.metallic = metal
	mat.roughness = 0.68
	return mat

func _part(size: Vector3, at: Vector3, material: Material, solid := true) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	add_child(mesh)
	if solid:
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		shape.position = at
		add_child(shape)

func set_deployed(value: bool) -> void:
	visible = value
	freeze = not value
	collision_layer = 1 if value else 0
	collision_mask = (7 | (1 << 17) | (1 << 19)) if value else 0
	if not value:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

## Require all foot corners to rest on the same slab. Reject occupied space,
## including overhead geometry; never create a hidden platform over a shaft.
func supported_pose(eye: Node3D, floor_y: float) -> Variant:
	var forward := -eye.global_basis.z
	forward.y = 0
	if forward.length_squared() < 0.01: forward = Vector3.FORWARD
	forward = forward.normalized()
	var basis_y := Basis(Vector3.UP, atan2(-forward.x, -forward.z))
	var space := get_world_3d().direct_space_state
	for distance in [3.8, 3.0, 4.8]:
		for side in [0.0, -2.5, 2.5]:
			var centre: Vector3 = eye.global_position + forward * distance + basis_y.x * side
			centre.y = floor_y + 0.02
			var supported := true
			for x in [-1.81, -1.49, 1.49, 1.81]:
				for z in [-0.95, 0.95]:
					var sample: Vector3 = centre + basis_y * Vector3(x, 0, z)
					var ray := PhysicsRayQueryParameters3D.create(sample + Vector3.UP * 0.3, sample - Vector3.UP * 0.15, 1, [get_rid()])
					var hit := space.intersect_ray(ray)
					if hit.is_empty() or hit.normal.y < 0.98 or absf(hit.position.y - floor_y) > 0.04:
						supported = false
			if not supported: continue
			var query := PhysicsShapeQueryParameters3D.new()
			var volume := BoxShape3D.new()
			volume.size = Vector3(4.20, 4.62, 1.94)
			query.shape = volume
			query.transform = Transform3D(basis_y, centre + Vector3.UP * 2.34)
			query.collision_mask = 7
			query.exclude = [get_rid()]
			if space.intersect_shape(query, 1).is_empty():
				return Transform3D(basis_y, centre)
	return null

func relocate(pose: Transform3D) -> void:
	freeze = true
	global_transform = pose
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	placed = true
	set_deployed(true)
	sleeping = false
