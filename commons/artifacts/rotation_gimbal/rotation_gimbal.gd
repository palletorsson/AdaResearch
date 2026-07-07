extends Node3D
class_name RotationGimbal

## Gimbal lock demonstrator — 3 nested rotation rings (X=red, Y=green, Z=blue)
## with VR sliders for each Euler angle. When Y approaches +/-90 deg, X and Z
## rings align and "GIMBAL LOCK!" flashes. Inner box shows the final orientation.
## Teaches why quaternions matter.

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

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
var _control_panel: Node3D

# --- Integrated 2D-in-3D boards (baked text on surfaces) ---
var _readout_board: Node3D       # Euler angles + rotation matrix, one panel
var _readout_anchor: Node3D      # fixed transform holding the readout board
var _lock_board: Node3D          # "GIMBAL LOCK!" flash board
var _lock_mat: StandardMaterial3D  # cached material of the lock board face (for flash)
var _info_board: Node3D          # status/info line under the rings
var _info_anchor: Node3D         # fixed transform holding the info board

# Cache guards — rebuild a board only when its text actually changes
var _readout_cache: String = ""
var _info_cache: String = ""

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
	_add_axis_tag(_x_ring_pivot, ring_radius_outer, color_x, Vector3.RIGHT, "X  PITCH")

	# Middle: Y-axis ring (green) — yaw
	_y_ring_pivot = Node3D.new()
	_y_ring_pivot.name = "YRingPivot"
	_x_ring_pivot.add_child(_y_ring_pivot)

	_y_ring = _create_ring(ring_radius_mid, ring_tube_radius, color_y, "YRing")
	_y_ring.rotation_degrees.z = 90.0  # Rotate so torus aligns with Y rotation
	_y_ring_pivot.add_child(_y_ring)
	_add_axis_tick(_y_ring_pivot, ring_radius_mid, color_y, Vector3.UP)
	_add_axis_tag(_y_ring_pivot, ring_radius_mid, color_y, Vector3.UP, "Y  YAW")

	# Innermost: Z-axis ring (blue) — roll
	_z_ring_pivot = Node3D.new()
	_z_ring_pivot.name = "ZRingPivot"
	_y_ring_pivot.add_child(_z_ring_pivot)

	_z_ring = _create_ring(ring_radius_inner, ring_tube_radius, color_z, "ZRing")
	_z_ring.rotation_degrees.x = 90.0  # Rotate so torus aligns with Z rotation
	_z_ring_pivot.add_child(_z_ring)
	_add_axis_tick(_z_ring_pivot, ring_radius_inner, color_z, Vector3.BACK)
	_add_axis_tag(_z_ring_pivot, ring_radius_inner, color_z, Vector3.BACK, "Z  ROLL")


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


func _add_axis_tag(pivot: Node3D, radius: float, color: Color, direction: Vector3, text: String) -> void:
	# A small integrated 2D-in-3D board naming the ring's axis. Pushed well OUT
	# past the ring (radius + tick + clearance) so it never collides with the
	# torus or with the neighbouring ring's tag. Billboarded to stay readable.
	var tag: Node3D = BakedText.make_tag(
		text, color.lightened(0.35), 0.055,
		Color(0.06, 0.07, 0.09), true, color)
	if tag == null:
		return
	tag.name = "AxisTag"
	# Clearance beyond the outermost tick tip; scaled a touch by ring size so the
	# three tags fan outward rather than stacking at one distance.
	var clearance := 0.075
	tag.position = direction * (radius + clearance)
	pivot.add_child(tag)


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
	# \u2500\u2500 Title header board \u2014 title + subtitle + legend on ONE opaque plate \u2500\u2500
	# One printed panel above the rig instead of three stacked floating labels.
	var header_lines := [
		"GIMBAL LOCK",
		"Why Euler angles lose a degree of freedom",
		"",
		"X pitch = red   Y yaw = green   Z roll = blue",
	]
	var header := BakedText.make_text_block(
		header_lines, Color(0.90, 0.92, 0.98), 0.052, 0.72, 0.020, true)
	header.name = "HeaderBoard"
	# A dark backing plate so the text reads as a display, not floating glyphs.
	add_child(_make_backing_plate("HeaderPlate", Vector3(0, 0.66, -0.006),
		Vector2(0.82, 0.30), Color(0.05, 0.06, 0.08)))
	header.position = Vector3(0, 0.66, 0)
	add_child(header)

	# \u2500\u2500 Readout board \u2014 Euler angles + rotation matrix on ONE panel \u2500\u2500
	# Fixed anchor to the left of the rig; the board is rebuilt (cache-guarded)
	# only when the numbers change. Left of centre so it clears the rings.
	_readout_anchor = Node3D.new()
	_readout_anchor.name = "ReadoutAnchor"
	_readout_anchor.position = Vector3(-0.62, 0.40, 0.02)
	add_child(_readout_anchor)
	# Static backing plate for the readout \u2014 persists across board rebuilds.
	_readout_anchor.add_child(_make_backing_plate("ReadoutPlate", Vector3(0, 0, -0.006),
		Vector2(0.44, 0.44), Color(0.04, 0.05, 0.07)))

	# \u2500\u2500 Lock warning board \u2014 the flashing "GIMBAL LOCK!" alert \u2500\u2500
	# make_tag gives an opaque board; we grab its face material to pulse alpha.
	_lock_board = BakedText.make_tag(
		"GIMBAL  LOCK", Color(1.0, 0.85, 0.80), 0.10,
		Color(0.14, 0.02, 0.02), false, color_lock)
	if _lock_board:
		_lock_board.name = "LockBoard"
		_lock_board.position = Vector3(0, 0.05, 0)
		add_child(_lock_board)
		# Cache the dark glass face material (emission disabled) so _process can
		# pulse its alpha. The frame face also has emission off, so take the
		# first non-emissive StandardMaterial3D found — either reads as the plate.
		for child in _lock_board.get_children():
			if child is MeshInstance3D:
				var mm = child.material_override
				if mm is StandardMaterial3D and not mm.emission_enabled:
					_lock_mat = mm
					# Enable alpha so the _process flash can fade the face.
					_lock_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					break
		_set_lock_visible(false)

	# \u2500\u2500 Info / status board \u2014 one line under the rig, rebuilt on state change \u2500\u2500
	_info_anchor = Node3D.new()
	_info_anchor.name = "InfoAnchor"
	_info_anchor.position = Vector3(0, -0.02, 0.0)
	add_child(_info_anchor)


func _make_backing_plate(node_name: String, pos: Vector3, size: Vector2, col: Color) -> MeshInstance3D:
	# A flat dark plate behind a text board so the readout reads as a lit display
	# panel rather than glyphs floating in space.
	var plate := MeshInstance3D.new()
	plate.name = node_name
	var qm := QuadMesh.new()
	qm.size = size
	plate.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.5
	mat.metallic = 0.15
	plate.material_override = mat
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plate.position = pos
	return plate


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

	_update_readout_board()
	_update_lock_warning()
	_update_info_board()


func _update_readout_board() -> void:
	# Euler angles AND the combined rotation matrix on ONE make_text_block panel.
	# Cache-guarded: rebuild the baked-text quads only when the string changes.
	if not _readout_anchor:
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

	var m00 = cy * cz
	var m01 = -cy * sz
	var m02 = sy
	var m10 = sx * sy * cz + cx * sz
	var m11 = -sx * sy * sz + cx * cz
	var m12 = -sx * cy
	var m20 = -cx * sy * cz + sx * sz
	var m21 = cx * sy * sz + sx * cz
	var m22 = cx * cy

	var lines := [
		"EULER ANGLES",
		"X pitch  %7.1f" % angle_x,
		"Y yaw    %7.1f" % angle_y,
		"Z roll   %7.1f" % angle_z,
		"",
		"R = Rx . Ry . Rz",
		"%5.2f  %5.2f  %5.2f" % [m00, m01, m02],
		"%5.2f  %5.2f  %5.2f" % [m10, m11, m12],
		"%5.2f  %5.2f  %5.2f" % [m20, m21, m22],
	]
	var key := "\n".join(lines)
	if key == _readout_cache:
		return
	_readout_cache = key

	if _readout_board and is_instance_valid(_readout_board):
		_readout_board.queue_free()
	_readout_board = BakedText.make_text_block(
		lines, Color(0.82, 0.88, 0.98), 0.036, 0.42, 0.010, true)
	_readout_board.name = "ReadoutBoard"
	_readout_anchor.add_child(_readout_board)


func _update_lock_warning() -> void:
	# Toggle the lock board's base visibility; _process pulses its alpha while locked.
	_set_lock_visible(_is_locked)


func _update_info_board() -> void:
	# One status line under the rig, rebuilt only when the message changes.
	if not _info_anchor:
		return
	var msg: String
	var col: Color
	if _is_locked:
		msg = "X and Z rotate the SAME axis  -  1 DOF lost"
		col = Color(1.0, 0.55, 0.45)
	else:
		msg = "Set Y to 90 deg  -  X and Z axes merge"
		col = Color(0.62, 0.68, 0.80)
	var key := "%s|%s" % [msg, col]
	if key == _info_cache:
		return
	_info_cache = key

	if _info_board and is_instance_valid(_info_board):
		_info_board.queue_free()
	_info_board = BakedText.make_tag(msg, col, 0.05, Color(0.05, 0.06, 0.09), false, col)
	if _info_board:
		_info_board.name = "InfoBoard"
		_info_anchor.add_child(_info_board)


func _set_lock_visible(on: bool) -> void:
	if _lock_board:
		_lock_board.visible = on
	if _lock_mat:
		_lock_mat.albedo_color.a = 1.0 if on else 0.0


# ------------------------------------------------------------------
# Process — gimbal lock flash animation
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if _is_locked:
		_lock_flash_time += delta * 4.0
		# Flash the lock board by pulsing its face alpha.
		if _lock_mat:
			_lock_mat.albedo_color.a = 0.6 + 0.4 * sin(_lock_flash_time)

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
