extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WallClearanceFan

## A ceiling fan mounted too close to a wall. Its blades can rotate only because
## the wall has been cut around their swept volume.
##
## The fan turns continuous phase into architecture:
##     theta(t) = TAU * f * t
## A single blade occupies one angle, but the opening records every angle the
## blade can occupy. The absence in the wall is therefore a memory of motion.

signal state_changed(state: Dictionary)
signal phase_completed(turns: int)
signal paused_changed(is_paused: bool)

const RackTpl := preload("res://commons/audio/rack_templates/RackTemplates.gd")

@export_range(0.05, 1.5, 0.01) var frequency_hz: float = 0.32
@export_range(0.45, 1.2, 0.01) var blade_radius: float = 0.9
@export_range(0.08, 0.35, 0.01) var blade_width: float = 0.2
@export_range(0.02, 0.12, 0.005) var blade_thickness: float = 0.045
@export_range(2, 8, 1) var blade_count: int = 4
@export_range(0.2, 1.2, 0.01) var wall_distance: float = 0.53
@export_range(0.04, 0.2, 0.01) var safety_margin: float = 0.14
@export var show_swept_volume: bool = true
@export var paused: bool = false

const FAN_CENTER := Vector3(0.0, 1.84, 0.0)
const CEILING_Y: float = 2.62
const WALL_WIDTH: float = 2.7
const WALL_HEIGHT: float = 2.62
const WALL_THICKNESS: float = 0.12
const WALL_SLICES: int = 30

var _visual_root: Node3D
var _fan_root: Node3D
var _sweep_root: Node3D
var _phase_label: Label3D
var _speed_slider: Node
var _phase: float = 0.0
var _turns: int = 0
var _built: bool = false


func _ready() -> void:
	_sanitize_parameters()
	_build_visuals()
	_build_controls()
	_built = true
	_update_readout()
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	if paused or _fan_root == null:
		return
	var previous_phase: float = _phase
	_phase = fposmod(_phase + TAU * frequency_hz * delta, TAU)
	_fan_root.rotation.y = -_phase
	if _phase < previous_phase:
		_turns += 1
		phase_completed.emit(_turns)
	_update_readout()


func _sanitize_parameters() -> void:
	frequency_hz = clampf(frequency_hz, 0.05, 1.5)
	blade_radius = clampf(blade_radius, 0.45, 1.2)
	blade_width = clampf(blade_width, 0.08, 0.35)
	blade_thickness = clampf(blade_thickness, 0.02, 0.12)
	blade_count = clampi(blade_count, 2, 8)
	wall_distance = clampf(wall_distance, 0.2, 1.2)
	safety_margin = clampf(safety_margin, 0.04, 0.2)


func _build_visuals() -> void:
	if is_instance_valid(_visual_root):
		remove_child(_visual_root)
		_visual_root.queue_free()

	_visual_root = Node3D.new()
	_visual_root.name = "Visuals"
	add_child(_visual_root)

	_build_room_fragment()
	_build_swept_volume()
	_build_fan()
	_build_labels()


func _build_room_fragment() -> void:
	var wall_z: float = -wall_distance
	var wall_mat: StandardMaterial3D = _matte_mat(Color(0.73, 0.72, 0.67), 0.92, 0.0)
	var cut_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.34, 0.12), 1.2)
	var ceiling_mat: StandardMaterial3D = _matte_mat(Color(0.84, 0.83, 0.77), 0.95, 0.0)

	# The wall is assembled from narrow vertical strips. Omitting the middle of
	# each strip makes a real opening, rather than painting a dark oval on top.
	var slice_width: float = WALL_WIDTH / float(WALL_SLICES)
	var hole_half_width: float = _hole_half_width()
	var hole_half_height: float = _hole_half_height()
	for i in range(WALL_SLICES):
		var x: float = -WALL_WIDTH * 0.5 + slice_width * (float(i) + 0.5)
		var normalized_x: float = absf(x) / maxf(hole_half_width, 0.001)
		if normalized_x >= 1.0:
			_visual_root.add_child(_box(
				Vector3(x, WALL_HEIGHT * 0.5, wall_z),
				Vector3(slice_width + 0.002, WALL_HEIGHT, WALL_THICKNESS), wall_mat))
			continue

		var local_half_height: float = hole_half_height * sqrt(maxf(0.0, 1.0 - normalized_x * normalized_x))
		var opening_bottom: float = FAN_CENTER.y - local_half_height
		var opening_top: float = FAN_CENTER.y + local_half_height
		if opening_bottom > 0.0:
			_visual_root.add_child(_box(
				Vector3(x, opening_bottom * 0.5, wall_z),
				Vector3(slice_width + 0.002, opening_bottom, WALL_THICKNESS), wall_mat))
		if opening_top < WALL_HEIGHT:
			var upper_height: float = WALL_HEIGHT - opening_top
			_visual_root.add_child(_box(
				Vector3(x, opening_top + upper_height * 0.5, wall_z),
				Vector3(slice_width + 0.002, upper_height, WALL_THICKNESS), wall_mat))

	# A ceiling fragment makes the object read as a misplaced domestic fan rather
	# than a rotor on a laboratory stand.
	_visual_root.add_child(_box(
		Vector3(0.0, CEILING_Y + 0.055, 0.05),
		Vector3(WALL_WIDTH, 0.11, 1.9), ceiling_mat))

	# Outline the subtraction. The orange edge makes the wall's concession to the
	# rotating phase legible from the approach side.
	var outline_z: float = wall_z + WALL_THICKNESS * 0.5 + 0.012
	var previous: Vector3
	var outline_segments: int = 48
	for i in range(outline_segments + 1):
		var a: float = TAU * float(i) / float(outline_segments)
		var current := Vector3(
			cos(a) * hole_half_width,
			FAN_CENTER.y + sin(a) * hole_half_height,
			outline_z)
		if i > 0:
			_visual_root.add_child(_cylinder_between(previous, current, 0.012, cut_mat))
		previous = current


func _build_swept_volume() -> void:
	_sweep_root = Node3D.new()
	_sweep_root.name = "SweptVolume"
	_visual_root.add_child(_sweep_root)

	var disk_mat: StandardMaterial3D = _glass_mat(Color(0.16, 0.82, 1.0), 0.1)
	var ring_mat: StandardMaterial3D = _glow_mat(Color(0.2, 0.88, 1.0), 0.75)
	_sweep_root.add_child(_cylinder(
		FAN_CENTER + Vector3(0.0, -0.055, 0.0), _sweep_radius(), 0.012, disk_mat))
	_sweep_root.add_child(_torus(
		FAN_CENTER + Vector3(0.0, -0.061, 0.0), _sweep_radius(), 0.012, ring_mat))

	# The chord is where the horizontal sweep intersects the vertical wall.
	var chord_half: float = _raw_chord_half_width()
	var wall_front_z: float = -wall_distance + WALL_THICKNESS * 0.5 + 0.018
	_sweep_root.add_child(_cylinder_between(
		Vector3(-chord_half, FAN_CENTER.y, wall_front_z),
		Vector3(chord_half, FAN_CENTER.y, wall_front_z), 0.014, ring_mat))
	_sweep_root.visible = show_swept_volume


func _build_fan() -> void:
	var metal_mat: StandardMaterial3D = _steel_mat(Color(0.18, 0.16, 0.13))
	var hub_mat: StandardMaterial3D = _steel_mat(Color(0.28, 0.23, 0.18))
	var blade_mat: StandardMaterial3D = _matte_mat(Color(0.38, 0.17, 0.075), 0.62, 0.05)
	var lamp_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.82, 0.5), 1.4)
	var marker_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.28, 0.1), 2.0)

	# Stationary mounting hardware.
	_visual_root.add_child(_cylinder(Vector3(0.0, CEILING_Y - 0.01, 0.0), 0.16, 0.08, metal_mat))
	_visual_root.add_child(_cylinder_between(
		Vector3(0.0, CEILING_Y - 0.05, 0.0),
		FAN_CENTER + Vector3(0.0, 0.14, 0.0), 0.026, metal_mat))
	_visual_root.add_child(_cylinder(FAN_CENTER + Vector3(0.0, 0.055, 0.0), 0.17, 0.17, hub_mat))

	_fan_root = Node3D.new()
	_fan_root.name = "RotatingFan"
	_fan_root.position = FAN_CENTER
	_fan_root.rotation.y = -_phase
	_visual_root.add_child(_fan_root)

	var hub_radius: float = 0.18
	var blade_start: float = hub_radius + 0.05
	var blade_length: float = maxf(0.12, blade_radius - blade_start)
	for i in range(blade_count):
		var arm := Node3D.new()
		arm.name = "Blade_%02d" % i
		arm.rotation.y = TAU * float(i) / float(blade_count)
		_fan_root.add_child(arm)
		arm.add_child(_cylinder_between(
			Vector3(hub_radius * 0.7, 0.0, 0.0),
			Vector3(blade_start + 0.04, 0.0, 0.0), 0.016, metal_mat))
		arm.add_child(_box(
			Vector3(blade_start + blade_length * 0.5, 0.0, 0.0),
			Vector3(blade_length, blade_thickness, blade_width), blade_mat))

	# One hot tip turns rotation into a readable phase rather than anonymous blur.
	_fan_root.add_child(_sphere(Vector3(blade_radius, 0.0, 0.0), 0.04, marker_mat))
	_fan_root.add_child(_cylinder(Vector3(0.0, -0.045, 0.0), 0.13, 0.1, hub_mat))
	_fan_root.add_child(_sphere(Vector3(0.0, -0.15, 0.0), 0.105, lamp_mat))


func _build_labels() -> void:
	var front_z: float = -wall_distance + WALL_THICKNESS * 0.5 + 0.025
	var title := _billboard_label(
		"WALL-CLEARANCE FAN\nTHE HOLE REMEMBERS EVERY PHASE",
		Vector3(0.0, 2.34, front_z), 28, Color(1.0, 0.78, 0.46))
	title.outline_size = 12
	_visual_root.add_child(title)

	# Keep the live measurement on the intact lower wall. The opening and blades
	# must remain readable without a caption floating across their intersection.
	_phase_label = _billboard_label("", Vector3(0.0, 0.82, front_z), 22, Color(0.72, 0.94, 1.0))
	_phase_label.outline_size = 10
	_visual_root.add_child(_phase_label)


func _build_controls() -> void:
	var old_panel: Node = get_node_or_null("Controls")
	if old_panel:
		old_panel.queue_free()

	var panel: Node3D = RackTpl.create_panel("CLEARANCE / PHASE", [
		[{"type": "slider_h", "label": "SPEED", "default": _frequency_to_normalized()}],
		[
			{"type": "button", "label": "PAUSE"},
			{"type": "button", "label": "SWEEP"},
			{"type": "button", "label": "RESET"},
		],
	])
	panel.name = "Controls"
	panel.position = Vector3(0.0, 0.64, 1.12)
	panel.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
	add_child(panel)

	_speed_slider = panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)
	_connect_button(panel.find_child("Btn_0", true, false), _on_pause_pressed)
	_connect_button(panel.find_child("Btn_1", true, false), _on_sweep_pressed)
	_connect_button(panel.find_child("Btn_2", true, false), _on_reset_pressed)


func _connect_button(button: Node, callback: Callable) -> void:
	if button == null:
		return
	var area: Node = button.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.button_pressed.connect(callback)


func _on_speed_changed(_position: Variant = null) -> void:
	if _speed_slider == null or not _speed_slider.has_method("get_normalized_value"):
		return
	frequency_hz = lerpf(0.05, 1.5, float(_speed_slider.get_normalized_value()))
	_update_readout()
	_emit_state()


func _on_pause_pressed(_button: Variant = null) -> void:
	paused = not paused
	paused_changed.emit(paused)
	_update_readout()
	_emit_state()


func _on_sweep_pressed(_button: Variant = null) -> void:
	show_swept_volume = not show_swept_volume
	if is_instance_valid(_sweep_root):
		_sweep_root.visible = show_swept_volume
	_emit_state()


func _on_reset_pressed(_button: Variant = null) -> void:
	_phase = 0.0
	_turns = 0
	if is_instance_valid(_fan_root):
		_fan_root.rotation.y = 0.0
	_update_readout()
	_emit_state()


func _frequency_to_normalized() -> float:
	return inverse_lerp(0.05, 1.5, frequency_hz)


func _sweep_radius() -> float:
	return blade_radius + blade_width * 0.5


func _raw_chord_half_width() -> float:
	var radius: float = _sweep_radius()
	return sqrt(maxf(0.0, radius * radius - wall_distance * wall_distance))


func _hole_half_width() -> float:
	return maxf(0.12, _raw_chord_half_width() + safety_margin)


func _hole_half_height() -> float:
	return maxf(0.13, blade_thickness * 0.5 + safety_margin)


func _update_readout() -> void:
	if _phase_label == null:
		return
	var state_word: String = "PAUSED" if paused else "ROTATING"
	_phase_label.text = "%s   theta = %5.1f deg   f = %.2f Hz\nwall offset %.2f m   swept chord %.2f m" % [
		state_word,
		rad_to_deg(_phase),
		frequency_hz,
		wall_distance,
		_raw_chord_half_width() * 2.0,
	]


func _emit_state() -> void:
	state_changed.emit({
		"frequency_hz": frequency_hz,
		"phase_radians": _phase,
		"paused": paused,
		"show_swept_volume": show_swept_volume,
		"blade_radius": blade_radius,
		"wall_distance": wall_distance,
		"hole_width": _hole_half_width() * 2.0,
		"hole_height": _hole_half_height() * 2.0,
	})


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("frequency_hz"):
		frequency_hz = float(config_data["frequency_hz"])
	if config_data.has("blade_radius"):
		blade_radius = float(config_data["blade_radius"])
		rebuild = true
	if config_data.has("blade_width"):
		blade_width = float(config_data["blade_width"])
		rebuild = true
	if config_data.has("blade_count"):
		blade_count = int(config_data["blade_count"])
		rebuild = true
	if config_data.has("wall_distance"):
		wall_distance = float(config_data["wall_distance"])
		rebuild = true
	if config_data.has("safety_margin"):
		safety_margin = float(config_data["safety_margin"])
		rebuild = true
	if config_data.has("show_swept_volume"):
		show_swept_volume = bool(config_data["show_swept_volume"])
	if config_data.has("running"):
		paused = not bool(config_data["running"])
	if config_data.has("phase_degrees"):
		_phase = deg_to_rad(float(config_data["phase_degrees"]))
	if config_data.has("emissive"):
		emissive = bool(config_data["emissive"])
		rebuild = true

	_sanitize_parameters()
	if not _built:
		return
	if rebuild:
		_build_visuals()
	if is_instance_valid(_fan_root):
		_fan_root.rotation.y = -_phase
	if is_instance_valid(_sweep_root):
		_sweep_root.visible = show_swept_volume
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		_speed_slider.set_normalized_value(_frequency_to_normalized())
	_update_readout()
	_emit_state()


func get_clearance_metrics() -> Dictionary:
	return {
		"sweep_radius": _sweep_radius(),
		"wall_distance": wall_distance,
		"intrusion_depth": maxf(0.0, _sweep_radius() - wall_distance),
		"swept_chord": _raw_chord_half_width() * 2.0,
		"hole_width": _hole_half_width() * 2.0,
		"hole_height": _hole_half_height() * 2.0,
	}
