extends Node3D
class_name RotationGimbal

## Gimbal lock demonstrator — 3 nested rotation rings (X=red, Y=green, Z=blue)
## with VR sliders for each Euler angle. When Y approaches +/-90 deg, X and Z
## rings align and "GIMBAL LOCK!" flashes. Inner box shows the final orientation.
## Teaches why quaternions matter.

# --- Configuration ---

@export var ring_radius_outer: float = 0.28
@export var ring_radius_mid: float = 0.22
@export var ring_radius_inner: float = 0.16
@export var ring_tube_radius: float = 0.008
@export var gimbal_lock_threshold: float = 5.0  # degrees from 90

# --- Euler angles (degrees) ---

var angle_x: float = 0.0
var angle_y: float = 0.0
var angle_z: float = 0.0

# --- Colors ---

var color_x: Color = Color(1.0, 0.3, 0.3)       # Red
var color_y: Color = Color(0.3, 1.0, 0.4)        # Green
var color_z: Color = Color(0.35, 0.55, 1.0)      # Blue
var color_box: Color = Color(0.9, 0.85, 0.7)     # Warm white
var color_lock: Color = Color(1.0, 0.2, 0.1)     # Alert red

# --- Node references ---

var _gimbal_root: Node3D
var _x_ring_pivot: Node3D
var _y_ring_pivot: Node3D
var _z_ring_pivot: Node3D
var _x_ring: MeshInstance3D
var _y_ring: MeshInstance3D
var _z_ring: MeshInstance3D
var _inner_box: MeshInstance3D
var _box_axes_mesh: MeshInstance3D
var _title_label: Label3D
var _matrix_label: Label3D
var _angles_label: Label3D
var _lock_label: Label3D
var _info_label: Label3D
var _control_panel: Node3D

# Sliders
var _x_slider: Node
var _y_slider: Node
var _z_slider: Node

# Gimbal lock flash
var _lock_flash_time: float = 0.0
var _is_locked: bool = false



func _ready() -> void:
	_build_gimbal()
	_build_inner_box()
	_build_labels()
	_build_vr_controls()
	_update_gimbal()


# ------------------------------------------------------------------
# Gimbal rings — 3 nested torus rings with axis indicator lines
# ------------------------------------------------------------------

func _build_gimbal() -> void:
	_gimbal_root = Node3D.new()
	_gimbal_root.name = "GimbalRoot"
	_gimbal_root.position = Vector3(0, 0.35, 0)
	add_child(_gimbal_root)

	# Outermost: X-axis ring (red) — pitch
	_x_ring_pivot = Node3D.new()
	_x_ring_pivot.name = "XRingPivot"
	_gimbal_root.add_child(_x_ring_pivot)

	_x_ring = _create_ring(ring_radius_outer, ring_tube_radius, color_x, "XRing")
	_x_ring_pivot.add_child(_x_ring)
	_add_axis_tick(_x_ring_pivot, ring_radius_outer, color_x, Vector3.RIGHT)

	# Middle: Y-axis ring (green) — yaw
	_y_ring_pivot = Node3D.new()
	_y_ring_pivot.name = "YRingPivot"
	_x_ring_pivot.add_child(_y_ring_pivot)

	_y_ring = _create_ring(ring_radius_mid, ring_tube_radius, color_y, "YRing")
	_y_ring.rotation_degrees.z = 90.0  # Rotate so torus aligns with Y rotation
	_y_ring_pivot.add_child(_y_ring)
	_add_axis_tick(_y_ring_pivot, ring_radius_mid, color_y, Vector3.UP)

	# Innermost: Z-axis ring (blue) — roll
	_z_ring_pivot = Node3D.new()
	_z_ring_pivot.name = "ZRingPivot"
	_y_ring_pivot.add_child(_z_ring_pivot)

	_z_ring = _create_ring(ring_radius_inner, ring_tube_radius, color_z, "ZRing")
	_z_ring.rotation_degrees.x = 90.0  # Rotate so torus aligns with Z rotation
	_z_ring_pivot.add_child(_z_ring)
	_add_axis_tick(_z_ring_pivot, ring_radius_inner, color_z, Vector3.BACK)


func _create_ring(radius: float, tube_radius: float, color: Color, ring_name: String) -> MeshInstance3D:
	var ring = MeshInstance3D.new()
	ring.name = ring_name
	var torus = TorusMesh.new()
	torus.inner_radius = radius - tube_radius
	torus.outer_radius = radius + tube_radius
	torus.rings = 32
	torus.ring_segments = 24
	ring.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.85)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.4
	mat.roughness = 0.4
	ring.material_override = mat

	return ring


func _add_axis_tick(pivot: Node3D, radius: float, color: Color, direction: Vector3) -> void:
	# Small line segments at the ring's cardinal points to show axis orientation
	var tick_mesh = MeshInstance3D.new()
	tick_mesh.name = "AxisTick"
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var tick_len = 0.03
	# Two opposing ticks along the axis direction
	for sign_val in [-1.0, 1.0]:
		var base = direction * radius * sign_val
		var tip = direction * (radius + tick_len) * sign_val
		im.surface_set_color(color)
		im.surface_add_vertex(base)
		im.surface_set_color(color)
		im.surface_add_vertex(tip)

	im.surface_end()
	tick_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	tick_mesh.material_override = mat
	pivot.add_child(tick_mesh)


# ------------------------------------------------------------------
# Inner box — shows final combined orientation
# ------------------------------------------------------------------

func _build_inner_box() -> void:
	_inner_box = MeshInstance3D.new()
	_inner_box.name = "InnerBox"
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.06, 0.10)
	_inner_box.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_box
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.85, 0.7)
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.2
	mat.roughness = 0.6
	_inner_box.material_override = mat

	# Box goes inside the innermost ring
	_z_ring_pivot.add_child(_inner_box)

	# Tiny colored face markers so you can track orientation
	_build_box_face_markers()


func _build_box_face_markers() -> void:
	# Small colored quads on +X, +Y, +Z faces of the box
	var faces = [
		{"normal": Vector3.RIGHT, "color": color_x, "size": Vector2(0.04, 0.035), "offset": Vector3(0.041, 0, 0)},
		{"normal": Vector3.UP, "color": color_y, "size": Vector2(0.05, 0.06), "offset": Vector3(0, 0.031, 0)},
		{"normal": Vector3.BACK, "color": color_z, "size": Vector2(0.05, 0.035), "offset": Vector3(0, 0, -0.051)},
	]

	for face in faces:
		var marker = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = face["size"]
		marker.mesh = quad
		marker.position = face["offset"]

		# Orient the quad to face outward
		var normal: Vector3 = face["normal"]
		if normal == Vector3.RIGHT:
			marker.rotation_degrees.y = 90
		elif normal == Vector3.UP:
			marker.rotation_degrees.x = -90
		elif normal == Vector3.BACK:
			marker.rotation_degrees.y = 180

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(face["color"], 0.7)
		mat.emission_enabled = true
		mat.emission = face["color"]
		mat.emission_energy_multiplier = 0.8
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = mat
		_inner_box.add_child(marker)

	# Box axes — small ImmediateMesh arrows on the box
	_box_axes_mesh = MeshInstance3D.new()
	_box_axes_mesh.name = "BoxAxes"
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var axis_len = 0.12
	var axes = [
		{"dir": Vector3(axis_len, 0, 0), "color": color_x},
		{"dir": Vector3(0, axis_len, 0), "color": color_y},
		{"dir": Vector3(0, 0, axis_len), "color": color_z},
	]
	for axis in axes:
		im.surface_set_color(axis["color"])
		im.surface_add_vertex(Vector3.ZERO)
		im.surface_set_color(axis["color"])
		im.surface_add_vertex(axis["dir"])

	im.surface_end()
	_box_axes_mesh.mesh = im

	var axes_mat = StandardMaterial3D.new()
	axes_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	axes_mat.vertex_color_use_as_albedo = true
	_box_axes_mesh.material_override = axes_mat
	_inner_box.add_child(_box_axes_mesh)


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _build_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "GIMBAL LOCK"
	_title_label.font_size = 28
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, 0.72, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 5
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	# Subtitle
	var subtitle = Label3D.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "Why Euler angles lose a degree of freedom"
	subtitle.font_size = 14
	subtitle.pixel_size = 0.001
	subtitle.position = Vector3(0, 0.68, 0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.75, 0.85, 0.9)
	subtitle.outline_size = 3
	subtitle.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(subtitle)

	# Euler angles readout
	_angles_label = Label3D.new()
	_angles_label.name = "AnglesLabel"
	_angles_label.font_size = 18
	_angles_label.pixel_size = 0.001
	_angles_label.position = Vector3(-0.42, 0.45, 0)
	_angles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_angles_label.modulate = Color(0.85, 0.85, 0.9)
	_angles_label.outline_size = 3
	_angles_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_angles_label)

	# Rotation matrix display
	_matrix_label = Label3D.new()
	_matrix_label.name = "MatrixLabel"
	_matrix_label.font_size = 14
	_matrix_label.pixel_size = 0.001
	_matrix_label.position = Vector3(0.38, 0.45, 0)
	_matrix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_matrix_label.modulate = Color(0.75, 0.8, 0.9)
	_matrix_label.outline_size = 2
	_matrix_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_matrix_label)

	# GIMBAL LOCK warning label
	_lock_label = Label3D.new()
	_lock_label.name = "LockWarning"
	_lock_label.text = "GIMBAL LOCK!"
	_lock_label.font_size = 36
	_lock_label.pixel_size = 0.001
	_lock_label.position = Vector3(0, 0.05, 0)
	_lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_label.modulate = Color(color_lock, 0.0)  # Start invisible
	_lock_label.outline_size = 6
	_lock_label.outline_modulate = Color(0, 0, 0, 0.8)
	_lock_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_lock_label)

	# Info label explaining gimbal lock
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.text = "Set Y to 90\u00b0 \u2014 X and Z axes merge!"
	_info_label.font_size = 12
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, -0.01, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.6, 0.65, 0.75, 0.8)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_info_label)

	# Legend
	var legend = Label3D.new()
	legend.name = "LegendLabel"
	legend.text = "X (pitch) = Red | Y (yaw) = Green | Z (roll) = Blue"
	legend.font_size = 11
	legend.pixel_size = 0.001
	legend.position = Vector3(0, -0.05, 0)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.modulate = Color(0.55, 0.55, 0.6, 0.7)
	legend.outline_size = 2
	legend.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(legend)


# ------------------------------------------------------------------
# VR Controls — 3 angle sliders + reset button
# ------------------------------------------------------------------

func _build_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_parameter_panel(
		3, ["X", "Y", "Z"],
		[angle_x / 360.0, angle_y / 360.0, angle_z / 360.0]
	)
	_control_panel.position = Vector3(0, -0.12, 0.35)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_x_slider = _control_panel.get_node_or_null("Param_0")
	_y_slider = _control_panel.get_node_or_null("Param_1")
	_z_slider = _control_panel.get_node_or_null("Param_2")

	if _x_slider and _x_slider.has_signal("slider_moved"):
		_x_slider.slider_moved.connect(_on_x_slider)
	if _y_slider and _y_slider.has_signal("slider_moved"):
		_y_slider.slider_moved.connect(_on_y_slider)
	if _z_slider and _z_slider.has_signal("slider_moved"):
		_z_slider.slider_moved.connect(_on_z_slider)

	var reset_btn: Node = _control_panel.get_node_or_null("ResetButton")
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_angles())


func _sync_slider(slider: Node, normalized: float) -> void:
	if slider and slider.has_method("set_normalized_value"):
		slider.set_normalized_value(clampf(normalized, 0.0, 1.0))


func _sync_all_sliders() -> void:
	_sync_slider(_x_slider, angle_x / 360.0)
	_sync_slider(_y_slider, angle_y / 360.0)
	_sync_slider(_z_slider, angle_z / 360.0)


# --- Slider callbacks ---

func _on_x_slider(_pos) -> void:
	if _x_slider and _x_slider.has_method("get_normalized_value"):
		angle_x = _x_slider.get_normalized_value() * 360.0
		_update_gimbal()

func _on_y_slider(_pos) -> void:
	if _y_slider and _y_slider.has_method("get_normalized_value"):
		angle_y = _y_slider.get_normalized_value() * 360.0
		_update_gimbal()

func _on_z_slider(_pos) -> void:
	if _z_slider and _z_slider.has_method("get_normalized_value"):
		angle_z = _z_slider.get_normalized_value() * 360.0
		_update_gimbal()


func _reset_angles() -> void:
	angle_x = 0.0
	angle_y = 0.0
	angle_z = 0.0
	_sync_all_sliders()
	_update_gimbal()


# ------------------------------------------------------------------
# Gimbal update — apply Euler angles to the nested ring pivots
# ------------------------------------------------------------------

func _update_gimbal() -> void:
	# Euler rotation order: X (outer) -> Y (middle) -> Z (inner)
	_x_ring_pivot.rotation_degrees = Vector3(angle_x, 0, 0)
	_y_ring_pivot.rotation_degrees = Vector3(0, angle_y, 0)
	_z_ring_pivot.rotation_degrees = Vector3(0, 0, angle_z)

	# Check for gimbal lock: Y near +/-90 degrees
	var y_mod = fmod(angle_y, 360.0)
	if y_mod < 0:
		y_mod += 360.0
	var dist_to_90 = minf(absf(y_mod - 90.0), absf(y_mod - 270.0))
	_is_locked = dist_to_90 < gimbal_lock_threshold

	_update_angles_label()
	_update_matrix_label()
	_update_lock_warning()


func _update_angles_label() -> void:
	if not _angles_label:
		return
	_angles_label.text = "Euler Angles:\n  X (pitch): %.1f\u00b0\n  Y (yaw):   %.1f\u00b0\n  Z (roll):  %.1f\u00b0" % [
		angle_x, angle_y, angle_z
	]


func _update_matrix_label() -> void:
	if not _matrix_label:
		return

	# Build the combined rotation matrix R = Rx * Ry * Rz
	var rx = deg_to_rad(angle_x)
	var ry = deg_to_rad(angle_y)
	var rz = deg_to_rad(angle_z)

	var cx = cos(rx)
	var sx = sin(rx)
	var cy = cos(ry)
	var sy = sin(ry)
	var cz = cos(rz)
	var sz = sin(rz)

	# Combined rotation matrix: Rx * Ry * Rz
	var m00 = cy * cz
	var m01 = -cy * sz
	var m02 = sy
	var m10 = sx * sy * cz + cx * sz
	var m11 = -sx * sy * sz + cx * cz
	var m12 = -sx * cy
	var m20 = -cx * sy * cz + sx * sz
	var m21 = cx * sy * sz + sx * cz
	var m22 = cx * cy

	_matrix_label.text = "R = Rx\u00b7Ry\u00b7Rz\n|%5.2f %5.2f %5.2f|\n|%5.2f %5.2f %5.2f|\n|%5.2f %5.2f %5.2f|" % [
		m00, m01, m02,
		m10, m11, m12,
		m20, m21, m22,
	]


func _update_lock_warning() -> void:
	if not _lock_label:
		return
	if _is_locked:
		_lock_label.modulate = Color(color_lock, 1.0)
		_info_label.text = "X and Z rotate the SAME axis! 1 DOF lost."
		_info_label.modulate = Color(color_lock, 0.9)
	else:
		_lock_label.modulate = Color(color_lock, 0.0)
		_info_label.text = "Set Y to 90\u00b0 \u2014 X and Z axes merge!"
		_info_label.modulate = Color(0.6, 0.65, 0.75, 0.8)


# ------------------------------------------------------------------
# Process — gimbal lock flash animation
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if _is_locked:
		_lock_flash_time += delta * 4.0
		var alpha = 0.6 + 0.4 * sin(_lock_flash_time)
		_lock_label.modulate = Color(color_lock, alpha)

		# Pulse the ring emission when locked
		var pulse = 0.8 + 0.6 * sin(_lock_flash_time * 1.5)
		if _x_ring.material_override:
			_x_ring.material_override.emission_energy_multiplier = pulse
		if _z_ring.material_override:
			_z_ring.material_override.emission_energy_multiplier = pulse
	else:
		_lock_flash_time = 0.0
		if _x_ring.material_override:
			_x_ring.material_override.emission_energy_multiplier = 0.6
		if _z_ring.material_override:
			_z_ring.material_override.emission_energy_multiplier = 0.6


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

## Accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("angle_x"):
		angle_x = float(config_data["angle_x"])
	if config_data.has("angle_y"):
		angle_y = float(config_data["angle_y"])
	if config_data.has("angle_z"):
		angle_z = float(config_data["angle_z"])
	if config_data.has("gimbal_lock_threshold"):
		gimbal_lock_threshold = float(config_data["gimbal_lock_threshold"])
	_sync_all_sliders()
	_update_gimbal()
