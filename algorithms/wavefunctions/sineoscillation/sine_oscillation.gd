extends Node3D

## Sine Oscillation — Expressive 3D VR Visualization
## Unit circle with rotating point, sine + cosine waves along X axis,
## projection lines, phase trail, and interactive VR controls.
## Core math concept: how circular motion projects to sinusoidal waves.

signal cycle_complete(cycles: int)
signal phase_changed(phase: float)

enum WaveType { SINE, COSINE, BOTH }

@export var wave_type: WaveType = WaveType.BOTH
@export var angular_velocity: float = 1.5  # radians per second
@export var amplitude: float = 0.15
@export var frequency: float = 2.0  # wave cycles visible
@export var speed: float = 1.0  # animation speed multiplier

@export var sine_color: Color = Color(0.2, 0.9, 0.3)
@export var cosine_color: Color = Color(0.3, 0.5, 1.0)
@export var circle_color: Color = Color(0.6, 0.6, 0.6)
@export var point_color: Color = Color(1.0, 0.2, 0.2)
@export var projection_color: Color = Color(1.0, 1.0, 0.3, 0.7)

# Layout constants
const CIRCLE_X := -0.25
const WAVE_X_START := -0.05
const WAVE_X_END := 0.55
const WAVE_SAMPLES := 200
const CIRCLE_SEGMENTS := 64
const TRAIL_LENGTH := 40

# State
var _angle: float = 0.0
var _total_cycles: int = 0
var _prev_angle: float = 0.0
var _trail_points: Array[float] = []  # recent angle values for trail

# ImmediateMesh surfaces
var _circle_mesh_inst: MeshInstance3D
var _circle_mesh: ImmediateMesh
var _sine_mesh_inst: MeshInstance3D
var _sine_mesh: ImmediateMesh
var _cosine_mesh_inst: MeshInstance3D
var _cosine_mesh: ImmediateMesh
var _projection_mesh_inst: MeshInstance3D
var _projection_mesh: ImmediateMesh
var _trail_mesh_inst: MeshInstance3D
var _trail_mesh: ImmediateMesh
var _axis_mesh_inst: MeshInstance3D
var _axis_mesh: ImmediateMesh

# Circle point + wave point spheres
var _circle_point: MeshInstance3D
var _sine_point: MeshInstance3D
var _cosine_point: MeshInstance3D

# Radius arm line
var _radius_mesh_inst: MeshInstance3D
var _radius_mesh: ImmediateMesh

# UI
var _info_label: Label3D
var _metrics_label: Label3D
var _phase_label: Label3D

# Controllers
var _speed_controller: ParameterController3D
var _amplitude_controller: ParameterController3D
var _frequency_controller: ParameterController3D


func _ready() -> void:
	_setup_axes()
	_setup_circle()
	_setup_waves()
	_setup_projection()
	_setup_trail()
	_setup_radius_arm()
	_setup_points()
	_create_ui()
	_create_controllers()
	_draw_circle()
	_draw_axes()


func _process(delta: float) -> void:
	_prev_angle = _angle
	_angle += angular_velocity * speed * delta

	# Cycle detection
	if _angle >= TAU:
		_angle -= TAU
		_total_cycles += 1
		cycle_complete.emit(_total_cycles)

	# Trail update
	_trail_points.append(_angle)
	if _trail_points.size() > TRAIL_LENGTH:
		_trail_points.remove_at(0)

	phase_changed.emit(_angle)

	_draw_waves()
	_draw_projection()
	_draw_trail()
	_draw_radius_arm()
	_update_points()
	_update_labels()


# ---------------------------------------------------------------------------
# Axis lines (X and Y reference)
# ---------------------------------------------------------------------------

func _setup_axes() -> void:
	_axis_mesh = ImmediateMesh.new()
	_axis_mesh_inst = MeshInstance3D.new()
	_axis_mesh_inst.mesh = _axis_mesh
	_axis_mesh_inst.material_override = _make_unshaded_mat()
	add_child(_axis_mesh_inst)

func _draw_axes() -> void:
	_axis_mesh.clear_surfaces()
	_axis_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var axis_col := Color(0.3, 0.3, 0.3, 0.5)

	# Horizontal axis along wave
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(WAVE_X_START, 0, 0))
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(WAVE_X_END, 0, 0))

	# Vertical axis at circle
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(CIRCLE_X, -amplitude * 1.3, 0))
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(CIRCLE_X, amplitude * 1.3, 0))

	# Vertical axis at wave start
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(WAVE_X_START, -amplitude * 1.3, 0))
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(WAVE_X_START, amplitude * 1.3, 0))

	# Horizontal zero line through circle
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(CIRCLE_X - amplitude * 1.3, 0, 0))
	_axis_mesh.surface_set_color(axis_col)
	_axis_mesh.surface_add_vertex(Vector3(CIRCLE_X + amplitude * 1.3, 0, 0))

	_axis_mesh.surface_end()


# ---------------------------------------------------------------------------
# Unit circle
# ---------------------------------------------------------------------------

func _setup_circle() -> void:
	_circle_mesh = ImmediateMesh.new()
	_circle_mesh_inst = MeshInstance3D.new()
	_circle_mesh_inst.mesh = _circle_mesh
	var mat := _make_unshaded_mat()
	mat.emission_enabled = true
	mat.emission = circle_color * 0.5
	_circle_mesh_inst.material_override = mat
	add_child(_circle_mesh_inst)

func _draw_circle() -> void:
	_circle_mesh.clear_surfaces()
	_circle_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for i in range(CIRCLE_SEGMENTS):
		var a0 := TAU * float(i) / float(CIRCLE_SEGMENTS)
		var a1 := TAU * float(i + 1) / float(CIRCLE_SEGMENTS)
		var y0 := amplitude * sin(a0)
		var z0 := amplitude * cos(a0)
		var y1 := amplitude * sin(a1)
		var z1 := amplitude * cos(a1)
		_circle_mesh.surface_set_color(circle_color)
		_circle_mesh.surface_add_vertex(Vector3(CIRCLE_X, y0, z0))
		_circle_mesh.surface_set_color(circle_color)
		_circle_mesh.surface_add_vertex(Vector3(CIRCLE_X, y1, z1))

	_circle_mesh.surface_end()


# ---------------------------------------------------------------------------
# Sine and Cosine waves (ImmediateMesh)
# ---------------------------------------------------------------------------

func _setup_waves() -> void:
	_sine_mesh = ImmediateMesh.new()
	_sine_mesh_inst = MeshInstance3D.new()
	_sine_mesh_inst.mesh = _sine_mesh
	var sin_mat := _make_unshaded_mat()
	sin_mat.emission_enabled = true
	sin_mat.emission = sine_color * 0.4
	_sine_mesh_inst.material_override = sin_mat
	add_child(_sine_mesh_inst)

	_cosine_mesh = ImmediateMesh.new()
	_cosine_mesh_inst = MeshInstance3D.new()
	_cosine_mesh_inst.mesh = _cosine_mesh
	var cos_mat := _make_unshaded_mat()
	cos_mat.emission_enabled = true
	cos_mat.emission = cosine_color * 0.4
	_cosine_mesh_inst.material_override = cos_mat
	add_child(_cosine_mesh_inst)

func _draw_waves() -> void:
	var show_sine := wave_type == WaveType.SINE or wave_type == WaveType.BOTH
	var show_cosine := wave_type == WaveType.COSINE or wave_type == WaveType.BOTH

	# Sine wave
	_sine_mesh.clear_surfaces()
	if show_sine:
		_sine_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		var dx := (WAVE_X_END - WAVE_X_START) / float(WAVE_SAMPLES)
		for i in range(WAVE_SAMPLES):
			var x0 := WAVE_X_START + dx * float(i)
			var x1 := WAVE_X_START + dx * float(i + 1)
			var t0 := (x0 - WAVE_X_START) / (WAVE_X_END - WAVE_X_START)
			var t1 := (x1 - WAVE_X_START) / (WAVE_X_END - WAVE_X_START)
			var phase0 := _angle - t0 * TAU * frequency
			var phase1 := _angle - t1 * TAU * frequency
			var y0 := amplitude * sin(phase0)
			var y1 := amplitude * sin(phase1)

			# Color intensity fades along wave length
			var fade0 := 1.0 - t0 * 0.4
			var fade1 := 1.0 - t1 * 0.4
			_sine_mesh.surface_set_color(sine_color * fade0)
			_sine_mesh.surface_add_vertex(Vector3(x0, y0, 0))
			_sine_mesh.surface_set_color(sine_color * fade1)
			_sine_mesh.surface_add_vertex(Vector3(x1, y1, 0))
		_sine_mesh.surface_end()

	# Cosine wave
	_cosine_mesh.clear_surfaces()
	if show_cosine:
		_cosine_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		var dx := (WAVE_X_END - WAVE_X_START) / float(WAVE_SAMPLES)
		for i in range(WAVE_SAMPLES):
			var x0 := WAVE_X_START + dx * float(i)
			var x1 := WAVE_X_START + dx * float(i + 1)
			var t0 := (x0 - WAVE_X_START) / (WAVE_X_END - WAVE_X_START)
			var t1 := (x1 - WAVE_X_START) / (WAVE_X_END - WAVE_X_START)
			var phase0 := _angle - t0 * TAU * frequency
			var phase1 := _angle - t1 * TAU * frequency
			var y0 := amplitude * cos(phase0)
			var y1 := amplitude * cos(phase1)

			var fade0 := 1.0 - t0 * 0.4
			var fade1 := 1.0 - t1 * 0.4
			_cosine_mesh.surface_set_color(cosine_color * fade0)
			_cosine_mesh.surface_add_vertex(Vector3(x0, y0, 0))
			_cosine_mesh.surface_set_color(cosine_color * fade1)
			_cosine_mesh.surface_add_vertex(Vector3(x1, y1, 0))
		_cosine_mesh.surface_end()


# ---------------------------------------------------------------------------
# Projection lines (circle point → wave start)
# ---------------------------------------------------------------------------

func _setup_projection() -> void:
	_projection_mesh = ImmediateMesh.new()
	_projection_mesh_inst = MeshInstance3D.new()
	_projection_mesh_inst.mesh = _projection_mesh
	var mat := _make_unshaded_mat()
	mat.emission_enabled = true
	mat.emission = projection_color * 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_projection_mesh_inst.material_override = mat
	add_child(_projection_mesh_inst)

func _draw_projection() -> void:
	_projection_mesh.clear_surfaces()
	_projection_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var show_sine := wave_type == WaveType.SINE or wave_type == WaveType.BOTH
	var show_cosine := wave_type == WaveType.COSINE or wave_type == WaveType.BOTH

	var circle_y := amplitude * sin(_angle)
	var circle_z := amplitude * cos(_angle)
	var circle_pos := Vector3(CIRCLE_X, circle_y, circle_z)

	if show_sine:
		# Horizontal projection line from circle point to sine wave start
		var sine_y := amplitude * sin(_angle)
		var sine_pos := Vector3(WAVE_X_START, sine_y, 0)
		_projection_mesh.surface_set_color(projection_color)
		_projection_mesh.surface_add_vertex(circle_pos)
		_projection_mesh.surface_set_color(projection_color)
		_projection_mesh.surface_add_vertex(sine_pos)

		# Horizontal guide from circle to Y axis
		_projection_mesh.surface_set_color(Color(sine_color.r, sine_color.g, sine_color.b, 0.3))
		_projection_mesh.surface_add_vertex(Vector3(CIRCLE_X, circle_y, 0))
		_projection_mesh.surface_set_color(Color(sine_color.r, sine_color.g, sine_color.b, 0.3))
		_projection_mesh.surface_add_vertex(sine_pos)

	if show_cosine:
		# Cosine = cos(angle) — corresponds to Z component on unit circle
		var cos_y := amplitude * cos(_angle)
		var cos_pos := Vector3(WAVE_X_START, cos_y, 0)
		_projection_mesh.surface_set_color(Color(cosine_color.r, cosine_color.g, cosine_color.b, 0.5))
		_projection_mesh.surface_add_vertex(Vector3(CIRCLE_X, cos_y, circle_z))
		_projection_mesh.surface_set_color(Color(cosine_color.r, cosine_color.g, cosine_color.b, 0.5))
		_projection_mesh.surface_add_vertex(cos_pos)

	_projection_mesh.surface_end()


# ---------------------------------------------------------------------------
# Phase trail on unit circle (fading arc behind the point)
# ---------------------------------------------------------------------------

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_mesh_inst = MeshInstance3D.new()
	_trail_mesh_inst.mesh = _trail_mesh
	var mat := _make_unshaded_mat()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh_inst.material_override = mat
	add_child(_trail_mesh_inst)

func _draw_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var count := _trail_points.size()
	for i in range(count - 1):
		var t := float(i) / float(count)
		var alpha := t * 0.8  # Fade from transparent to opaque
		var col := Color(point_color.r, point_color.g, point_color.b, alpha)

		var a0 := _trail_points[i]
		var a1 := _trail_points[i + 1]
		var p0 := Vector3(CIRCLE_X, amplitude * sin(a0), amplitude * cos(a0))
		var p1 := Vector3(CIRCLE_X, amplitude * sin(a1), amplitude * cos(a1))

		_trail_mesh.surface_set_color(col)
		_trail_mesh.surface_add_vertex(p0)
		_trail_mesh.surface_set_color(col)
		_trail_mesh.surface_add_vertex(p1)

	_trail_mesh.surface_end()


# ---------------------------------------------------------------------------
# Radius arm (center of circle → rotating point)
# ---------------------------------------------------------------------------

func _setup_radius_arm() -> void:
	_radius_mesh = ImmediateMesh.new()
	_radius_mesh_inst = MeshInstance3D.new()
	_radius_mesh_inst.mesh = _radius_mesh
	var mat := _make_unshaded_mat()
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.9) * 0.3
	_radius_mesh_inst.material_override = mat
	add_child(_radius_mesh_inst)

func _draw_radius_arm() -> void:
	_radius_mesh.clear_surfaces()
	_radius_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var center := Vector3(CIRCLE_X, 0, 0)
	var tip := Vector3(CIRCLE_X, amplitude * sin(_angle), amplitude * cos(_angle))
	var arm_color := Color(0.9, 0.9, 0.9, 0.7)

	_radius_mesh.surface_set_color(arm_color)
	_radius_mesh.surface_add_vertex(center)
	_radius_mesh.surface_set_color(arm_color)
	_radius_mesh.surface_add_vertex(tip)

	_radius_mesh.surface_end()


# ---------------------------------------------------------------------------
# Marker spheres (circle point, sine point, cosine point)
# ---------------------------------------------------------------------------

func _setup_points() -> void:
	_circle_point = _make_sphere(0.012, point_color)
	add_child(_circle_point)

	_sine_point = _make_sphere(0.01, sine_color)
	add_child(_sine_point)

	_cosine_point = _make_sphere(0.01, cosine_color)
	add_child(_cosine_point)

func _update_points() -> void:
	# Circle point
	_circle_point.position = Vector3(CIRCLE_X, amplitude * sin(_angle), amplitude * cos(_angle))

	var show_sine := wave_type == WaveType.SINE or wave_type == WaveType.BOTH
	var show_cosine := wave_type == WaveType.COSINE or wave_type == WaveType.BOTH

	# Sine point at wave start
	_sine_point.visible = show_sine
	if show_sine:
		_sine_point.position = Vector3(WAVE_X_START, amplitude * sin(_angle), 0)

	# Cosine point at wave start
	_cosine_point.visible = show_cosine
	if show_cosine:
		_cosine_point.position = Vector3(WAVE_X_START, amplitude * cos(_angle), 0)


# ---------------------------------------------------------------------------
# UI Labels
# ---------------------------------------------------------------------------

func _create_ui() -> void:
	_info_label = Label3D.new()
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.font_size = 28
	_info_label.outline_size = 4
	_info_label.modulate = Color(1.0, 0.95, 1.0)
	_info_label.position = Vector3(0.15, 0.35, 0)
	add_child(_info_label)

	_metrics_label = Label3D.new()
	_metrics_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_metrics_label.font_size = 20
	_metrics_label.outline_size = 3
	_metrics_label.modulate = Color(0.85, 0.9, 1.0)
	_metrics_label.position = Vector3(0.15, 0.28, 0)
	add_child(_metrics_label)

	_phase_label = Label3D.new()
	_phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_phase_label.font_size = 18
	_phase_label.outline_size = 3
	_phase_label.modulate = Color(0.9, 0.85, 1.0)
	_phase_label.position = Vector3(CIRCLE_X, -amplitude - 0.06, 0)
	add_child(_phase_label)

func _update_labels() -> void:
	if _info_label:
		var type_str := "Sine" if wave_type == WaveType.SINE else ("Cosine" if wave_type == WaveType.COSINE else "Sine + Cosine")
		_info_label.text = "Sine Oscillation | %s" % type_str

	if _metrics_label:
		var wavelength := (WAVE_X_END - WAVE_X_START) / frequency
		var period := TAU / (angular_velocity * speed) if angular_velocity * speed > 0 else INF
		_metrics_label.text = "A: %.2f | f: %.1f | T: %.2fs | lambda: %.3f | Cycles: %d" % [
			amplitude, frequency, period, wavelength, _total_cycles
		]

	if _phase_label:
		var deg := rad_to_deg(_angle)
		_phase_label.text = "Phase: %.0f deg (%.2f rad)" % [deg, _angle]
		_phase_label.position = Vector3(CIRCLE_X, -amplitude - 0.06, 0)


# ---------------------------------------------------------------------------
# VR Controllers (ParameterController3D)
# ---------------------------------------------------------------------------

func _create_controllers() -> void:
	_speed_controller = ParameterController3D.new()
	_speed_controller.parameter_name = "Speed"
	_speed_controller.min_value = 0.0
	_speed_controller.max_value = 5.0
	_speed_controller.default_value = speed
	_speed_controller.step_size = 0.1
	_speed_controller.position = Vector3(-0.1, -0.35, 0)
	_speed_controller.value_changed.connect(_on_speed_changed)
	add_child(_speed_controller)

	_amplitude_controller = ParameterController3D.new()
	_amplitude_controller.parameter_name = "Amplitude"
	_amplitude_controller.min_value = 0.02
	_amplitude_controller.max_value = 0.35
	_amplitude_controller.default_value = amplitude
	_amplitude_controller.step_size = 0.01
	_amplitude_controller.position = Vector3(0.15, -0.35, 0)
	_amplitude_controller.value_changed.connect(_on_amplitude_changed)
	add_child(_amplitude_controller)

	_frequency_controller = ParameterController3D.new()
	_frequency_controller.parameter_name = "Frequency"
	_frequency_controller.min_value = 0.5
	_frequency_controller.max_value = 5.0
	_frequency_controller.default_value = frequency
	_frequency_controller.step_size = 0.5
	_frequency_controller.position = Vector3(0.4, -0.35, 0)
	_frequency_controller.value_changed.connect(_on_frequency_changed)
	add_child(_frequency_controller)

func _on_speed_changed(value: float) -> void:
	speed = value

func _on_amplitude_changed(value: float) -> void:
	amplitude = value
	_draw_circle()
	_draw_axes()

func _on_frequency_changed(value: float) -> void:
	frequency = value


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_unshaded_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	return mat

func _make_sphere(radius: float, color: Color) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	inst.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.2
	inst.material_override = mat
	return inst


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func reset() -> void:
	_angle = 0.0
	_total_cycles = 0
	_trail_points.clear()
	speed = 1.0
	amplitude = 0.15
	frequency = 2.0
	_draw_circle()
	_draw_axes()
	_sync_controllers()

func replay_animation() -> void:
	_angle = 0.0
	_total_cycles = 0
	_trail_points.clear()

func _sync_controllers() -> void:
	if _speed_controller:
		_speed_controller.set_value(speed)
	if _amplitude_controller:
		_amplitude_controller.set_value(amplitude)
	if _frequency_controller:
		_frequency_controller.set_value(frequency)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("wave_type"):
		var wt: String = str(config.wave_type).to_lower()
		match wt:
			"sine": wave_type = WaveType.SINE
			"cosine": wave_type = WaveType.COSINE
			"both": wave_type = WaveType.BOTH
	if config.has("amplitude"):
		amplitude = clampf(float(config.amplitude), 0.02, 0.35)
	if config.has("frequency"):
		frequency = clampf(float(config.frequency), 0.5, 5.0)
	if config.has("speed"):
		speed = clampf(float(config.speed), 0.0, 5.0)
	if config.has("angular_velocity"):
		angular_velocity = clampf(float(config.angular_velocity), 0.1, 10.0)
	if config.has("sine_color"):
		sine_color = Color(config.sine_color)
	if config.has("cosine_color"):
		cosine_color = Color(config.cosine_color)

	_draw_circle()
	_draw_axes()
	_sync_controllers()
