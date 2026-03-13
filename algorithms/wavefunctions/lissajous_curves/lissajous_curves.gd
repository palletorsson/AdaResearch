@tool
extends Node3D

# Lissajous Curve Generator
# Parametric curves formed by combining perpendicular harmonic motions
# X = A * sin(a*t + δ), Y = B * sin(b*t), Z = C * sin(c*t)

@export_group("Frequency Ratios")
@export var freq_ratio_x: float = 3.0  # a in the equation
@export var freq_ratio_y: float = 2.0  # b in the equation
@export var freq_ratio_z: float = 1.0  # c in the equation (for 3D extension)

@export_group("Amplitudes")
@export var amplitude_x: float = 1.0  # A
@export var amplitude_y: float = 1.0  # B
@export var amplitude_z: float = 0.5  # C

@export_group("Phase")
@export var phase_shift: float = 0.0  # δ (delta) in radians
@export var animate_phase: bool = true
@export var phase_speed: float = 0.5

@export_group("Visualization")
@export var num_points: int = 500
@export var line_width: float = 0.02
@export var trail_length: int = 200
@export var show_particle: bool = true
@export var particle_size: float = 0.08
@export var rainbow_gradient: bool = true

@export_group("Animation")
@export var animation_speed: float = 1.0
@export var auto_rotate: bool = false
@export var rotation_speed: float = 0.2

var time: float = 0.0
var curve_points: PackedVector3Array = []
var trail_points: Array[Vector3] = []

# Mesh for drawing the curve
var curve_mesh: ImmediateMesh
var curve_instance: MeshInstance3D
var particle_instance: MeshInstance3D

func _ready() -> void:
	_setup_visualization()
	_generate_full_curve()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_generate_full_curve()
		_update_curve_mesh()
		return

	time += delta * animation_speed

	# Animate phase shift
	if animate_phase:
		phase_shift += delta * phase_speed

	# Generate and update curve
	_generate_full_curve()
	_update_curve_mesh()

	# Update particle position
	if show_particle:
		_update_particle()

	# Auto-rotate for better viewing
	if auto_rotate:
		rotation.y += delta * rotation_speed

func _setup_visualization() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()

	# Create immediate mesh for curve
	curve_mesh = ImmediateMesh.new()
	curve_instance = MeshInstance3D.new()
	curve_instance.name = "CurveMesh"
	curve_instance.mesh = curve_mesh

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	curve_instance.material_override = mat

	add_child(curve_instance)

	# Create particle
	if show_particle:
		particle_instance = MeshInstance3D.new()
		particle_instance.name = "Particle"
		var sphere = SphereMesh.new()
		sphere.radius = particle_size
		sphere.height = particle_size * 2.0
		particle_instance.mesh = sphere

		var particle_mat = StandardMaterial3D.new()
		particle_mat.albedo_color = Color(1.0, 1.0, 0.0)
		particle_mat.emission_enabled = true
		particle_mat.emission = Color(1.0, 1.0, 0.0)
		particle_mat.emission_energy_multiplier = 2.0
		particle_mat.metallic = 0.0
		particle_mat.roughness = 1.0
		particle_instance.material_override = particle_mat

		add_child(particle_instance)

func _generate_full_curve() -> void:
	curve_points.clear()

	for i in range(num_points + 1):
		var t = float(i) / float(num_points) * TAU
		var point = _calculate_point(t)
		curve_points.append(point)

func _calculate_point(t: float) -> Vector3:
	"""Calculate Lissajous curve point at parameter t"""
	return Vector3(
		amplitude_x * sin(freq_ratio_x * t + phase_shift),
		amplitude_y * sin(freq_ratio_y * t),
		amplitude_z * sin(freq_ratio_z * t)
	)

func _update_curve_mesh() -> void:
	if not curve_mesh:
		return

	curve_mesh.clear_surfaces()

	if curve_points.size() < 2:
		return

	curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(curve_points.size()):
		var point = curve_points[i]

		# Calculate color
		var color: Color
		if rainbow_gradient:
			var hue = float(i) / float(curve_points.size())
			color = Color.from_hsv(hue, 0.8, 1.0)
		else:
			color = Color(0.3, 0.8, 1.0)

		curve_mesh.surface_set_color(color)
		curve_mesh.surface_add_vertex(point)

	curve_mesh.surface_end()

func _update_particle() -> void:
	if not particle_instance:
		return

	# Current position on curve
	var current_point = _calculate_point(time)
	particle_instance.position = current_point

	# Update trail
	trail_points.append(current_point)
	if trail_points.size() > trail_length:
		trail_points.pop_front()

func get_current_position() -> Vector3:
	"""Get current particle position"""
	return _calculate_point(time)

func get_velocity() -> Vector3:
	"""Get instantaneous velocity (derivative)"""
	var dt = 0.01
	var p1 = _calculate_point(time)
	var p2 = _calculate_point(time + dt)
	return (p2 - p1) / dt

# Preset configurations for famous Lissajous patterns
func set_preset(preset_name: String) -> void:
	match preset_name:
		"circle":
			freq_ratio_x = 1.0
			freq_ratio_y = 1.0
			freq_ratio_z = 0.0
			phase_shift = PI / 2.0
		"figure_eight":
			freq_ratio_x = 2.0
			freq_ratio_y = 1.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
		"trefoil":
			freq_ratio_x = 3.0
			freq_ratio_y = 2.0
			freq_ratio_z = 0.0
			phase_shift = 0.0
		"3d_knot":
			freq_ratio_x = 3.0
			freq_ratio_y = 2.0
			freq_ratio_z = 1.0
			phase_shift = PI / 4.0
		"pentagram":
			freq_ratio_x = 5.0
			freq_ratio_y = 4.0
			freq_ratio_z = 0.0
			phase_shift = 0.0

	_generate_full_curve()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

