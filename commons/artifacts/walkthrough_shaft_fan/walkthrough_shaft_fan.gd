extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WalkthroughShaftFan

## A slow industrial fan spanning a walkable ventilation shaft.
##
## The visitor crosses along the Z axis. The fan rotates in the XY plane, so the
## passage is not a permanent hole: it opens only when the gap between two blades
## reaches the lower walking lane. Moving collision shapes make phase bodily.
##
## Companion to wall_clearance_fan:
##   - there, architecture yields to every phase;
##   - here, the visitor yields to phase and crosses when the interval arrives.

signal state_changed(state: Dictionary)
signal crossing_window_opened(window_seconds: float)
signal crossing_window_closed()
signal revolution_completed(turns: int)

const RackTpl := preload("res://commons/audio/rack_templates/RackTemplates.gd")

@export_range(0.005, 0.08, 0.001) var rotation_hz: float = 0.018
@export_range(4, 10, 1) var blade_count: int = 7
@export_range(1.2, 2.0, 0.05) var blade_radius: float = 1.78
@export_range(0.18, 0.42, 0.01) var blade_width: float = 0.28
@export_range(0.05, 0.18, 0.01) var blade_depth: float = 0.12
@export_range(0.2, 0.5, 0.01) var hub_radius: float = 0.34
@export_range(10.0, 22.0, 0.5) var safe_angle_degrees: float = 17.0
@export_enum("clockwise:-1", "counter_clockwise:1") var rotation_direction: int = -1
@export var paused: bool = false
@export var collision_enabled: bool = true
@export var show_phase_ring: bool = true

const SHAFT_CENTER := Vector3(0.0, 2.2, 0.0)
const SHAFT_RADIUS: float = 2.12
const SHAFT_DEPTH: float = 4.4
const SHAFT_THICKNESS: float = 0.22
const SHAFT_SEGMENTS: int = 32
const WALKWAY_WIDTH: float = 2.25
const CONTROL_MIN_HZ: float = 0.005
const CONTROL_MAX_HZ: float = 0.08

var _visual_root: Node3D
var _rotor: AnimatableBody3D
var _phase_ring: Node3D
var _speed_slider: Node
var _status_labels: Array[Label3D] = []
var _status_lights: Array[MeshInstance3D] = []
var _blade_colliders: Array[CollisionShape3D] = []
var _phase: float = 0.0
var _turns: int = 0
var _safe_now: bool = false
var _built: bool = false


func _ready() -> void:
	_sanitize_parameters()
	_build_visuals()
	_build_controls()
	_built = true
	_update_gate_state(true)
	set_physics_process(not Engine.is_editor_hint())


func _physics_process(delta: float) -> void:
	if _rotor == null:
		return
	if not paused:
		var previous_phase: float = _phase
		_phase = fposmod(_phase + TAU * rotation_hz * delta, TAU)
		_rotor.rotation.z = _signed_phase()
		if _phase < previous_phase:
			_turns += 1
			revolution_completed.emit(_turns)
	_update_gate_state(false)


func _sanitize_parameters() -> void:
	rotation_hz = clampf(rotation_hz, CONTROL_MIN_HZ, CONTROL_MAX_HZ)
	blade_count = clampi(blade_count, 4, 10)
	blade_radius = clampf(blade_radius, 1.2, 2.0)
	blade_width = clampf(blade_width, 0.18, 0.42)
	blade_depth = clampf(blade_depth, 0.05, 0.18)
	hub_radius = clampf(hub_radius, 0.2, 0.5)
	safe_angle_degrees = clampf(safe_angle_degrees, 10.0, 22.0)
	rotation_direction = -1 if rotation_direction < 0 else 1


func _build_visuals() -> void:
	if is_instance_valid(_visual_root):
		remove_child(_visual_root)
		_visual_root.queue_free()

	_status_labels.clear()
	_status_lights.clear()
	_blade_colliders.clear()
	_rotor = null
	_phase_ring = null

	_visual_root = Node3D.new()
	_visual_root.name = "WalkthroughShaft"
	add_child(_visual_root)
	_build_shaft()
	_build_rotor()
	_build_phase_instruments()


func _build_shaft() -> void:
	var shell_mat: StandardMaterial3D = _matte_mat(Color(0.12, 0.15, 0.14), 0.72, 0.45)
	var inner_mat: StandardMaterial3D = _matte_mat(Color(0.19, 0.23, 0.21), 0.88, 0.2)
	var floor_mat: StandardMaterial3D = _matte_mat(Color(0.13, 0.14, 0.14), 0.86, 0.25)
	var edge_mat: StandardMaterial3D = _glow_mat(Color(0.24, 1.0, 0.38), 1.1)
	var wait_mat: StandardMaterial3D = _glow_mat(Color(1.0, 0.55, 0.08), 0.9)

	# A faceted circular liner. The bottom arc is omitted and replaced by a flat,
	# collidable walkway, preserving a normal human floor inside a cylindrical duct.
	var arc_length: float = TAU * SHAFT_RADIUS / float(SHAFT_SEGMENTS) * 1.08
	for i in range(SHAFT_SEGMENTS):
		var angle: float = TAU * float(i) / float(SHAFT_SEGMENTS)
		var radial := Vector3(cos(angle), sin(angle), 0.0)
		var center: Vector3 = SHAFT_CENTER + radial * (SHAFT_RADIUS + SHAFT_THICKNESS * 0.5)
		if center.y < 0.18:
			continue
		_add_solid_box(
			_visual_root,
			"ShaftSegment_%02d" % i,
			center,
			Vector3(arc_length, SHAFT_THICKNESS, SHAFT_DEPTH),
			angle - PI * 0.5,
			shell_mat)

	_add_solid_box(
		_visual_root,
		"Walkway",
		Vector3(0.0, -0.09, 0.0),
		Vector3(WALKWAY_WIDTH, 0.18, SHAFT_DEPTH + 1.2),
		0.0,
		floor_mat)

	# Two threshold lines tell the body where waiting ends and commitment begins.
	for z in [-0.72, 0.72]:
		_visual_root.add_child(_box(
			Vector3(0.0, 0.012, z),
			Vector3(WALKWAY_WIDTH, 0.024, 0.08), wait_mat))

	# Green depth behind the fan, borrowed from the reference image but kept thin
	# enough that the far exit remains visible through it.
	var glow_disk: MeshInstance3D = _axial_cylinder(
		SHAFT_RADIUS * 0.96, 0.018, _glass_mat(Color(0.18, 1.0, 0.28), 0.13))
	glow_disk.position = SHAFT_CENTER + Vector3(0.0, 0.0, -SHAFT_DEPTH * 0.48)
	_visual_root.add_child(glow_disk)

	for z in [-SHAFT_DEPTH * 0.5 - 0.025, SHAFT_DEPTH * 0.5 + 0.025]:
		var rim: MeshInstance3D = _torus(
			SHAFT_CENTER + Vector3(0.0, 0.0, z),
			SHAFT_RADIUS + 0.01, 0.045, edge_mat)
		rim.rotation.x = PI * 0.5
		_visual_root.add_child(rim)

	# A few ribs establish that the rotor belongs to a working shaft, not a loose
	# wheel. They sit behind the blade plane and do not narrow the timed passage.
	for angle in [-2.45, -0.69, 0.69, 2.45]:
		var outer := SHAFT_CENTER + Vector3(
			cos(angle) * (SHAFT_RADIUS - 0.15),
			sin(angle) * (SHAFT_RADIUS - 0.15),
			-0.16)
		var inner := SHAFT_CENTER + Vector3(
			cos(angle) * (hub_radius + 0.08),
			sin(angle) * (hub_radius + 0.08),
			-0.16)
		_visual_root.add_child(_cylinder_between(inner, outer, 0.045, inner_mat))


func _build_rotor() -> void:
	var hub_mat: StandardMaterial3D = _steel_mat(Color(0.12, 0.13, 0.13))
	var blade_mat: StandardMaterial3D = _matte_mat(Color(0.08, 0.09, 0.085), 0.72, 0.5)
	var blade_edge_mat: StandardMaterial3D = _glow_mat(Color(0.22, 0.9, 0.32), 0.24)

	_rotor = AnimatableBody3D.new()
	_rotor.name = "SolidRotor"
	_rotor.position = SHAFT_CENTER
	_rotor.rotation.z = _signed_phase()
	_rotor.collision_layer = 1
	_rotor.collision_mask = 1
	_rotor.sync_to_physics = true
	_visual_root.add_child(_rotor)

	var hub_mesh: MeshInstance3D = _axial_cylinder(hub_radius, blade_depth * 1.8, hub_mat)
	_rotor.add_child(hub_mesh)
	var hub_collision := CollisionShape3D.new()
	var hub_shape := CylinderShape3D.new()
	hub_shape.radius = hub_radius
	hub_shape.height = blade_depth * 1.8
	hub_collision.shape = hub_shape
	hub_collision.rotation.x = PI * 0.5
	hub_collision.disabled = not collision_enabled
	_rotor.add_child(hub_collision)
	_blade_colliders.append(hub_collision)

	var blade_start: float = hub_radius + 0.07
	var blade_length: float = maxf(0.4, blade_radius - blade_start)
	for i in range(blade_count):
		var angle: float = TAU * float(i) / float(blade_count)
		var radial := Vector3(cos(angle), sin(angle), 0.0)
		var tangent := Vector3(-sin(angle), cos(angle), 0.0)
		var blade_center: float = blade_start + blade_length * 0.5
		var blade := _box(
			radial * blade_center,
			Vector3(blade_length, blade_width, blade_depth), blade_mat)
		blade.name = "BladeMesh_%02d" % i
		blade.rotation.z = angle
		_rotor.add_child(blade)

		# A thin luminous trailing edge keeps individual blades legible at speed.
		var edge := _box(
			radial * blade_center - tangent * (blade_width * 0.46) + Vector3(0.0, 0.0, blade_depth * 0.52),
			Vector3(blade_length, 0.018, 0.012), blade_edge_mat)
		edge.rotation.z = angle
		_rotor.add_child(edge)

		var blade_collision := CollisionShape3D.new()
		var blade_shape := BoxShape3D.new()
		blade_shape.size = Vector3(blade_length, blade_width, blade_depth)
		blade_collision.shape = blade_shape
		blade_collision.position = radial * blade_center
		blade_collision.rotation.z = angle
		blade_collision.disabled = not collision_enabled
		_rotor.add_child(blade_collision)
		_blade_colliders.append(blade_collision)


func _build_phase_instruments() -> void:
	var phase_mat: StandardMaterial3D = _glow_mat(Color(0.25, 0.9, 1.0), 0.7)
	_phase_ring = Node3D.new()
	_phase_ring.name = "PhaseRing"
	_visual_root.add_child(_phase_ring)
	var ring: MeshInstance3D = _torus(
		SHAFT_CENTER + Vector3(0.0, 0.0, 0.18),
		blade_radius + 0.08, 0.018, phase_mat)
	ring.rotation.x = PI * 0.5
	_phase_ring.add_child(ring)
	_phase_ring.visible = show_phase_ring

	# The moving dot names instantaneous phase while the solid blades make it felt.
	var marker_root := Node3D.new()
	marker_root.position = SHAFT_CENTER + Vector3(0.0, 0.0, 0.2)
	marker_root.rotation.z = _signed_phase()
	marker_root.set_meta("follows_phase", true)
	_visual_root.add_child(marker_root)
	marker_root.add_child(_sphere(Vector3(blade_radius + 0.08, 0.0, 0.0), 0.055, phase_mat))

	var title := _billboard_label(
		"WALK-THROUGH ROTATION\nTHE OPENING ARRIVES IN TIME",
		Vector3(0.0, 4.62, 2.05), 34, Color(0.7, 1.0, 0.72))
	title.outline_size = 14
	_visual_root.add_child(title)

	for z in [-1.55, 1.55]:
		var status := _billboard_label("", Vector3(0.0, 3.72, z), 32, Color.WHITE)
		status.outline_size = 13
		_visual_root.add_child(status)
		_status_labels.append(status)
		for x in [-0.72, 0.72]:
			var light := _sphere(Vector3(x, 3.72, z), 0.085, _signal_material(Color(1.0, 0.36, 0.08)))
			_visual_root.add_child(light)
			_status_lights.append(light)


func _build_controls() -> void:
	var old_panel: Node = get_node_or_null("Controls")
	if old_panel:
		old_panel.queue_free()
	var panel: Node3D = RackTpl.create_panel("SHAFT CONTROL", [
		[{"type": "slider_h", "label": "SPEED", "default": _frequency_to_normalized()}],
		[
			{"type": "button", "label": "STOP"},
			{"type": "button", "label": "RESET"},
		],
	])
	panel.name = "Controls"
	panel.position = Vector3(1.42, 0.82, 2.48)
	panel.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	add_child(panel)

	_speed_slider = panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)
	_connect_button(panel.find_child("Btn_0", true, false), _on_stop_pressed)
	_connect_button(panel.find_child("Btn_1", true, false), _on_reset_pressed)


func _connect_button(button: Node, callback: Callable) -> void:
	if button == null:
		return
	var area: Node = button.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.button_pressed.connect(callback)


func _on_speed_changed(_position: Variant = null) -> void:
	if _speed_slider == null or not _speed_slider.has_method("get_normalized_value"):
		return
	rotation_hz = lerpf(
		CONTROL_MIN_HZ, CONTROL_MAX_HZ,
		float(_speed_slider.get_normalized_value()))
	_update_gate_state(true)
	_emit_state()


func _on_stop_pressed(_button: Variant = null) -> void:
	paused = not paused
	_update_gate_state(true)
	_emit_state()


func _on_reset_pressed(_button: Variant = null) -> void:
	_phase = 0.0
	_turns = 0
	if is_instance_valid(_rotor):
		_rotor.rotation.z = _signed_phase()
	_update_gate_state(true)
	_emit_state()


func _signed_phase() -> float:
	return _phase * float(rotation_direction)


func _nearest_blade_angle_to_lane() -> float:
	var lane_angle: float = -PI * 0.5
	var nearest: float = PI
	for i in range(blade_count):
		var blade_angle: float = _signed_phase() + TAU * float(i) / float(blade_count)
		nearest = minf(nearest, absf(wrapf(blade_angle - lane_angle, -PI, PI)))
	return nearest


func _is_crossing_window_open() -> bool:
	return _nearest_blade_angle_to_lane() > deg_to_rad(safe_angle_degrees)


func _window_seconds() -> float:
	var sector_degrees: float = 360.0 / float(blade_count)
	var open_degrees: float = maxf(0.0, sector_degrees - safe_angle_degrees * 2.0)
	return open_degrees / maxf(rotation_hz * 360.0, 0.001)


func _update_gate_state(force: bool) -> void:
	if is_instance_valid(_visual_root):
		for child in _visual_root.get_children():
			if child is Node3D and child.has_meta("follows_phase"):
				(child as Node3D).rotation.z = _signed_phase()

	var safe: bool = _is_crossing_window_open()
	if not force and safe != _safe_now:
		if safe:
			crossing_window_opened.emit(_window_seconds())
		else:
			crossing_window_closed.emit()
	_safe_now = safe

	var color: Color
	var headline: String
	if paused:
		color = Color(0.35, 0.85, 1.0)
		headline = "STOPPED"
	elif safe:
		color = Color(0.28, 1.0, 0.38)
		headline = "CROSS"
	else:
		color = Color(1.0, 0.32, 0.08)
		headline = "WAIT"

	var clearance_deg: float = rad_to_deg(_nearest_blade_angle_to_lane())
	var period: float = 1.0 / maxf(rotation_hz, 0.001)
	var text: String = "%s\nphase %5.1f deg   nearest blade %4.1f deg\nperiod %.1f s   open window %.1f s" % [
		headline,
		rad_to_deg(_signed_phase()),
		clearance_deg,
		period,
		_window_seconds(),
	]
	for label in _status_labels:
		if is_instance_valid(label):
			label.text = text
			label.modulate = color
	for light in _status_lights:
		_set_signal_color(light, color)


func _signal_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8 if emissive else 0.3
	material.roughness = 0.3
	return material


func _set_signal_color(light: MeshInstance3D, color: Color) -> void:
	if light == null:
		return
	var material: StandardMaterial3D = light.material_override as StandardMaterial3D
	if material == null:
		return
	material.albedo_color = color
	material.emission = color


func _frequency_to_normalized() -> float:
	return inverse_lerp(CONTROL_MIN_HZ, CONTROL_MAX_HZ, rotation_hz)


func _axial_cylinder(radius: float, depth: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.rotation.x = PI * 0.5
	return instance


func _add_solid_box(
		parent: Node3D,
		body_name: String,
		center: Vector3,
		size: Vector3,
		rotation_z: float,
		material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = body_name
	body.position = center
	body.rotation.z = rotation_z
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_child(_box(Vector3.ZERO, size, material))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _set_blade_collision(enabled: bool) -> void:
	for collision in _blade_colliders:
		if is_instance_valid(collision):
			collision.set_deferred("disabled", not enabled)


func _emit_state() -> void:
	state_changed.emit({
		"rotation_hz": rotation_hz,
		"period_seconds": 1.0 / maxf(rotation_hz, 0.001),
		"phase_radians": _signed_phase(),
		"blade_count": blade_count,
		"crossing_window_open": _safe_now,
		"crossing_window_seconds": _window_seconds(),
		"paused": paused,
		"collision_enabled": collision_enabled,
	})


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("rotation_hz"):
		rotation_hz = float(config_data["rotation_hz"])
	if config_data.has("blade_count"):
		blade_count = int(config_data["blade_count"])
		rebuild = true
	if config_data.has("blade_radius"):
		blade_radius = float(config_data["blade_radius"])
		rebuild = true
	if config_data.has("blade_width"):
		blade_width = float(config_data["blade_width"])
		rebuild = true
	if config_data.has("hub_radius"):
		hub_radius = float(config_data["hub_radius"])
		rebuild = true
	if config_data.has("safe_angle_degrees"):
		safe_angle_degrees = float(config_data["safe_angle_degrees"])
	if config_data.has("rotation_direction"):
		rotation_direction = int(config_data["rotation_direction"])
	if config_data.has("running"):
		paused = not bool(config_data["running"])
	if config_data.has("collision_enabled"):
		collision_enabled = bool(config_data["collision_enabled"])
	if config_data.has("show_phase_ring"):
		show_phase_ring = bool(config_data["show_phase_ring"])
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
	if is_instance_valid(_rotor):
		_rotor.rotation.z = _signed_phase()
	if is_instance_valid(_phase_ring):
		_phase_ring.visible = show_phase_ring
	_set_blade_collision(collision_enabled)
	if _speed_slider and _speed_slider.has_method("set_normalized_value"):
		_speed_slider.set_normalized_value(_frequency_to_normalized())
	_update_gate_state(true)
	_emit_state()


func get_phase_state() -> Dictionary:
	return {
		"phase_degrees": rad_to_deg(_signed_phase()),
		"nearest_blade_degrees": rad_to_deg(_nearest_blade_angle_to_lane()),
		"crossing_window_open": _safe_now,
		"window_seconds": _window_seconds(),
		"period_seconds": 1.0 / maxf(rotation_hz, 0.001),
	}
