extends Node3D

## Sine Oscillation — 3D VR version
## Unit circle in YZ plane with rotating point, sine wave along X axis,
## and a projection line connecting the two.

@export var angular_velocity: float = 2.0 * PI  # radians per second
@export var circle_radius: float = 0.15
@export var wave_amplitude: float = 0.15
@export var wave_x_start: float = -0.1
@export var wave_x_end: float = 0.4
@export var wave_samples: int = 200
@export var circle_segments: int = 64
@export var circle_x_offset: float = -0.2

@export var wave_color: Color = Color(0.0, 1.0, 0.0)
@export var circle_color: Color = Color(0.5, 0.5, 0.5)
@export var point_color: Color = Color(1.0, 0.0, 0.0)
@export var projection_color: Color = Color(1.0, 1.0, 0.0, 0.6)

var angle: float = 0.0

# Mesh instances
var _wave_mesh_instance: MeshInstance3D
var _circle_mesh_instance: MeshInstance3D
var _projection_mesh_instance: MeshInstance3D
var _point_mesh_instance: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	_create_circle()
	_create_wave()
	_create_projection_line()
	_create_point()
	_create_label()


func _process(delta: float) -> void:
	angle += angular_velocity * delta
	if angle > TAU:
		angle -= TAU

	_update_wave()
	_update_point()
	_update_projection_line()


func _create_label() -> void:
	_label = Label3D.new()
	_label.text = "Sine Oscillation"
	_label.font_size = 32
	_label.position = Vector3(0.15, -0.25, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1.0, 1.0, 1.0)
	add_child(_label)


func _create_circle() -> void:
	_circle_mesh_instance = MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	_circle_mesh_instance.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = circle_color
	mat.no_depth_test = false
	_circle_mesh_instance.material_override = mat

	# Draw circle ring in YZ plane at x = circle_x_offset
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(circle_segments):
		var a0 := TAU * float(i) / float(circle_segments)
		var a1 := TAU * float(i + 1) / float(circle_segments)
		var p0 := Vector3(circle_x_offset, circle_radius * sin(a0), circle_radius * cos(a0))
		var p1 := Vector3(circle_x_offset, circle_radius * sin(a1), circle_radius * cos(a1))
		mesh.surface_set_color(circle_color)
		mesh.surface_add_vertex(p0)
		mesh.surface_set_color(circle_color)
		mesh.surface_add_vertex(p1)
	mesh.surface_end()

	add_child(_circle_mesh_instance)


func _create_wave() -> void:
	_wave_mesh_instance = MeshInstance3D.new()
	_wave_mesh_instance.mesh = ImmediateMesh.new()

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = wave_color
	_wave_mesh_instance.material_override = mat

	add_child(_wave_mesh_instance)
	_update_wave()


func _update_wave() -> void:
	var mesh: ImmediateMesh = _wave_mesh_instance.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var dx := (wave_x_end - wave_x_start) / float(wave_samples)
	for i in range(wave_samples):
		var x0 := wave_x_start + dx * float(i)
		var x1 := wave_x_start + dx * float(i + 1)
		# Map x position to an angle offset from the current angle
		var phase0 := angle - (x0 - wave_x_start) / (wave_x_end - wave_x_start) * TAU * 2.0
		var phase1 := angle - (x1 - wave_x_start) / (wave_x_end - wave_x_start) * TAU * 2.0
		var y0 := wave_amplitude * sin(phase0)
		var y1 := wave_amplitude * sin(phase1)

		mesh.surface_set_color(wave_color)
		mesh.surface_add_vertex(Vector3(x0, y0, 0.0))
		mesh.surface_set_color(wave_color)
		mesh.surface_add_vertex(Vector3(x1, y1, 0.0))

	mesh.surface_end()


func _create_point() -> void:
	_point_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.01
	sphere.height = 0.02
	sphere.radial_segments = 12
	sphere.rings = 6
	_point_mesh_instance.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = point_color
	mat.emission_enabled = true
	mat.emission = point_color
	_point_mesh_instance.material_override = mat

	add_child(_point_mesh_instance)


func _update_point() -> void:
	var y := circle_radius * sin(angle)
	var z := circle_radius * cos(angle)
	_point_mesh_instance.position = Vector3(circle_x_offset, y, z)


func _create_projection_line() -> void:
	_projection_mesh_instance = MeshInstance3D.new()
	_projection_mesh_instance.mesh = ImmediateMesh.new()

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = projection_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_projection_mesh_instance.material_override = mat

	add_child(_projection_mesh_instance)


func _update_projection_line() -> void:
	var mesh: ImmediateMesh = _projection_mesh_instance.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var circle_y := circle_radius * sin(angle)
	var circle_z := circle_radius * cos(angle)
	var circle_pos := Vector3(circle_x_offset, circle_y, circle_z)

	# The wave value at x = wave_x_start corresponds to the current angle
	var wave_y := wave_amplitude * sin(angle)
	var wave_pos := Vector3(wave_x_start, wave_y, 0.0)

	mesh.surface_set_color(projection_color)
	mesh.surface_add_vertex(circle_pos)
	mesh.surface_set_color(projection_color)
	mesh.surface_add_vertex(wave_pos)

	mesh.surface_end()


func _exit_tree() -> void:
	for child in get_children():
		child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
