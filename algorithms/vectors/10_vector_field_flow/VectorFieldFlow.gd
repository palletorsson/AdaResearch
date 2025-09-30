extends "res://algorithms/vectors/shared/vector_scene_base.gd"

const GRID_RANGE := 4
const GRID_SPACING := 0.9

var field_vectors: Array[Node3D] = []
var particle: Node3D
var particle_velocity: Vector3 = Vector3.ZERO
var particle_position: Vector3 = Vector3.ZERO
var info_label: Label3D
var elapsed := 0.0

func _ready():
	super._ready()
	create_axes(4.5)
	_create_field_vectors()
	particle = _create_particle_marker()
	reposition_particle(Vector3.ZERO)
	info_label = create_info_panel("Vector Field Flow", Vector3(-3.5, 2.5, 0.0))

func _process(delta):
	elapsed += delta
	_update_field_vectors()
	_update_particle(delta)
	_update_info()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reposition_particle(Vector3.ZERO)
			restart_particle()
		if event.keycode == KEY_SPACE:
			particle_velocity = Vector3.ZERO

func _create_field_vectors():
	for x in range(-GRID_RANGE, GRID_RANGE + 1):
		for z in range(-GRID_RANGE, GRID_RANGE + 1):
			var origin = Vector3(x * GRID_SPACING, 0.0, z * GRID_SPACING)
			var arrow = spawn_vector(origin, Vector3.ZERO, Color(0.3, 0.8, 1.0, 1.0), "Field", false)
			field_vectors.append(arrow)

func _update_field_vectors():
	for arrow in field_vectors:
		var world_origin = arrow.global_position
		var value = _field_value(world_origin)
		update_vector(arrow, value)

func _field_value(position: Vector3) -> Vector3:
	var swirl = Vector3(-position.z, 0.6 * sin(elapsed), position.x)
	var radial = position * 0.1
	return (swirl - radial).limit_length(2.5)

func _create_particle_marker() -> Node3D:
	var marker = Node3D.new()
	marker.name = "Particle"
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
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

func _update_particle(delta: float):
	var sample = _field_value(particle_position)
	particle_velocity = particle_velocity.lerp(sample, 0.5)
	particle_position += particle_velocity * delta
	reposition_particle(particle_position)

func reposition_particle(position: Vector3):
	particle_position = position
	if particle:
		particle.global_position = particle_position

func restart_particle():
	particle_velocity = Vector3.ZERO

func _update_info():
	var field_here = _field_value(particle_position)
	var builder := []
	builder.append("Position = (%.2f, %.2f, %.2f)" % [particle_position.x, particle_position.y, particle_position.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [particle_velocity.x, particle_velocity.y, particle_velocity.z])
	builder.append("Field(position) = (%.2f, %.2f, %.2f)" % [field_here.x, field_here.y, field_here.z])
	info_label.text = "\n".join(builder)



