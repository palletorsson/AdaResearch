extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const GRID_RANGE := 4
const GRID_SPACING := 0.9
const FIELD_VERTICAL_OSCILLATION := 0.3
const FIELD_VERTICAL_FREQUENCY := 0.75
const PARTICLE_FOLLOW := 0.35
const PARTICLE_DAMPING := 0.985
const PARTICLE_VERTICAL_LIMIT := 0.35

var field_vectors: Array[Node3D] = []  # kept for compatibility but unused with MultiMesh
var particle: Node3D
var particle_velocity: Vector3 = Vector3.ZERO
var particle_position: Vector3 = Vector3.ZERO
var info_label: Label3D
var elapsed := 0.0

# MultiMesh for field arrows — replaces 81 line scenes with 2 draw calls
var _field_shaft_mm_instance: MultiMeshInstance3D
var _field_head_mm_instance: MultiMeshInstance3D
var _field_origins: PackedVector3Array = PackedVector3Array()
var _field_count: int = 0

func _ready() -> void:
	super._ready()
	# Match the compact exhibition presentation used by other advanced vector scenes.
	scale = Vector3(0.5, 0.5, 0.5)
	create_axes(4.5)
	_create_field_vectors()
	particle = _create_particle_marker()
	reposition_particle(Vector3.ZERO)
	info_label = create_info_panel(
		"Vector Field Flow",
		Vector3(-3.5, 2.5, 0.0),
		Vector2(2.4, 1.0),
		"F(p) = swirl - radial",
		"Particle follows field vectors"
	)

func _process(delta: float) -> void:
	elapsed += delta
	_update_field_vectors()
	_update_particle(delta)
	_update_info()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reposition_particle(Vector3.ZERO)
			restart_particle()
		if event.keycode == KEY_SPACE:
			particle_velocity = Vector3.ZERO

func _create_field_vectors() -> void:
	# Compute grid origins
	_field_origins.clear()
	for x in range(-GRID_RANGE, GRID_RANGE + 1):
		for z in range(-GRID_RANGE, GRID_RANGE + 1):
			_field_origins.append(Vector3(x * GRID_SPACING, 0.0, z * GRID_SPACING))
	_field_count = _field_origins.size()

	# Arrow shafts — unit cylinder scaled per instance
	var shaft_cyl := CylinderMesh.new()
	shaft_cyl.top_radius = 0.006
	shaft_cyl.bottom_radius = 0.006
	shaft_cyl.height = 1.0
	shaft_cyl.radial_segments = 8
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.3, 0.8, 1.0, 1.0)
	shaft_mat.emission_enabled = true
	shaft_mat.emission = Color(0.3, 0.8, 1.0) * 0.5
	shaft_cyl.material = shaft_mat

	var shaft_mm := MultiMesh.new()
	shaft_mm.transform_format = MultiMesh.TRANSFORM_3D
	shaft_mm.instance_count = _field_count
	shaft_mm.mesh = shaft_cyl

	_field_shaft_mm_instance = MultiMeshInstance3D.new()
	_field_shaft_mm_instance.name = "FieldShaftMM"
	_field_shaft_mm_instance.multimesh = shaft_mm
	add_child(_field_shaft_mm_instance)

	# Arrow heads — small cone
	var head_cone := CylinderMesh.new()
	head_cone.top_radius = 0.0
	head_cone.bottom_radius = 0.025
	head_cone.height = 0.12
	head_cone.radial_segments = 12
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.3, 0.8, 1.0, 1.0)
	head_mat.emission_enabled = true
	head_mat.emission = Color(0.3, 0.8, 1.0) * 0.5
	head_cone.material = head_mat

	var head_mm := MultiMesh.new()
	head_mm.transform_format = MultiMesh.TRANSFORM_3D
	head_mm.instance_count = _field_count
	head_mm.mesh = head_cone

	_field_head_mm_instance = MultiMeshInstance3D.new()
	_field_head_mm_instance.name = "FieldHeadMM"
	_field_head_mm_instance.multimesh = head_mm
	add_child(_field_head_mm_instance)

func _update_field_vectors() -> void:
	if not _field_shaft_mm_instance or not _field_head_mm_instance:
		return
	var shaft_mm := _field_shaft_mm_instance.multimesh
	var head_mm := _field_head_mm_instance.multimesh
	var sc := SCENE_SCALE

	for i in _field_count:
		var origin := _field_origins[i]
		var value := _field_value(origin)
		var mag := value.length()

		# Origin in local space (scene is scaled by SCENE_SCALE in _ready)
		var base := origin * sc

		if mag < 0.001:
			# Hide this instance
			var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -999, 0))
			shaft_mm.set_instance_transform(i, hidden)
			head_mm.set_instance_transform(i, hidden)
			continue

		var dir := value / mag
		var arrow_len := mag * sc  # Scale arrow length to scene scale
		# Build basis: Y axis along direction, height = arrow_len
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.99:
			up = Vector3.RIGHT
		var right := dir.cross(up).normalized()
		up = right.cross(dir).normalized()

		# Shaft: centered at origin + half arrow length along direction
		var shaft_basis := Basis(right, dir * arrow_len, up)
		var shaft_pos := base + dir * (arrow_len * 0.5)
		shaft_mm.set_instance_transform(i, Transform3D(shaft_basis, shaft_pos))

		# Head: at tip of arrow
		var head_basis := Basis(right, dir, up)  # Unit scale, just oriented
		var head_pos := base + dir * arrow_len
		head_mm.set_instance_transform(i, Transform3D(head_basis, head_pos))

func _field_value(position: Vector3) -> Vector3:
	var swirl = Vector3(
		-position.z,
		FIELD_VERTICAL_OSCILLATION * sin(elapsed * FIELD_VERTICAL_FREQUENCY),
		position.x
	)
	var radial = position * 0.1
	return (swirl - radial).limit_length(2.5)

func _create_particle_marker() -> Node3D:
	var marker = Node3D.new()
	marker.name = "Particle"
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	sphere.radial_segments = 24
	sphere.rings = 16
	mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.4, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.2, 1.0) * 0.5
	mesh.material_override = mat
	marker.add_child(mesh)
	add_child(marker)
	return marker

func _update_particle(delta: float) -> void:
	var sample = _field_value(particle_position)
	# Keep vertical motion compact and readable in VR.
	sample.y *= 0.5
	particle_velocity = particle_velocity.lerp(sample, PARTICLE_FOLLOW)
	particle_velocity *= PARTICLE_DAMPING
	particle_position += particle_velocity * delta
	if absf(particle_position.y) > PARTICLE_VERTICAL_LIMIT:
		particle_position.y = clampf(
			particle_position.y,
			-PARTICLE_VERTICAL_LIMIT,
			PARTICLE_VERTICAL_LIMIT
		)
		particle_velocity.y *= -0.25
	reposition_particle(particle_position)

func reposition_particle(position: Vector3) -> void:
	particle_position = position
	if particle:
		particle.position = particle_position

func restart_particle() -> void:
	particle_velocity = Vector3.ZERO

func _update_info() -> void:
	var field_here = _field_value(particle_position)
	var builder := []
	builder.append("Position = (%.2f, %.2f, %.2f)" % [particle_position.x, particle_position.y, particle_position.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [particle_velocity.x, particle_velocity.y, particle_velocity.z])
	builder.append("Field(position) = (%.2f, %.2f, %.2f)" % [field_here.x, field_here.y, field_here.z])
	info_label.text = "\n".join(builder)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
