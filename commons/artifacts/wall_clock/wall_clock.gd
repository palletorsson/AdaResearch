extends Node3D
class_name WallClock

# @identity
# essence: a round-faced clock with a dark steel frame, twelve tick marks, and three hands (hour, minute, second in accent color) — Black Mesa / office vocabulary for "this is where time is read". Optional digital-readout mode replaces the analog face with an emissive baked-text display panel. In the lab's grammar, the wall clock is the SCHEDULER — the shared reference that lets concurrent processes synchronise.
# desire: every concurrent system wants a clock. The wall clock wants to be the architectural form of "this is the same time for all of us". It wants the player to look at it and trust that the next event will happen ON TIME — to read the face as the assertion that scheduling exists.
# critical_parameter: hour_hand_angle + minute_hand_angle + second_hand_angle — together they ARE the scheduler's state. The hands are the algorithm's read-cursor across a continuous schedule. is_digital toggles the same idea between analog (continuous angles) and digital (discrete characters) — both name the same algorithm differently.
# triggers: _ready() builds frame ring + face disc + tick marks + three hands (or digital readout) from exports; apply_grid_config rebuilds
# emerges: 12:00 reads as RESET / START. A second hand at 30 reads as MID-CYCLE. A digital "00:00:00" in red reads as ALARM / EVENT. Analog reads SMOOTH-TIME, digital reads DISCRETE-TICK — same scheduler, two modes of address.
# needs: round face disc [present]; frame ring around the face [present]; tick marks radiating from center [present]; hour + minute hands [present]; second hand in accent color [present]; optional emissive baked-text readout painted onto the face when is_digital [present]
# relationships: peer to oscilloscope (both NAME a time variable — scope's t is local-frame, clock's t is wall-time); ancestor to control_board (the board would coordinate around this clock); cousin to exit_sign (both are NAMING-IN-THE-ROOM — the sign names a place, the clock names a moment)
# truth: scheduling is the algorithm that asks "when?". The wall clock is the lab's affirmation that there IS a shared answer. It does not say what comes next — it says only that what comes next will happen at a TIME, and that time is the same time everyone reads. Synchronisation is the entire algorithm; the clock is its monument.

## A round wall clock with analog hands or digital readout.
##
## Built procedurally from DNA exports. Origin is at the CENTER of the
## clock face. The face points +Z (mountable on a -Z wall). Hands rotate
## around the Z axis, with angle measured CLOCKWISE from the 12 position.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var clock_radius: float = 0.18
@export var clock_depth: float = 0.04

@export_group("Color")
@export var face_color: Color = Color(0.94, 0.94, 0.95)
@export var frame_color: Color = Color(0.20, 0.20, 0.22)
@export var hands_color: Color = Color(0.10, 0.10, 0.10)
@export var tick_color: Color = Color(0.10, 0.10, 0.10)
@export var second_hand_color: Color = Color(0.95, 0.20, 0.20)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)
@export var digital_color: Color = Color(0.95, 0.20, 0.20)

@export_group("Hands (analog mode)")
## Degrees CLOCKWISE from the 12 position.
@export var hour_hand_angle: float = 270.0
@export var minute_hand_angle: float = 0.0
@export var second_hand_angle: float = 30.0
@export_range(4, 24) var tick_count: int = 12

@export_group("Digital mode")
@export var is_digital: bool = false
@export var digital_time_text: String = "12:00:30"

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# ── Constants ─────────────────────────────────────────────────────────

const FRAME_RING_FACTOR: float = 1.06     # outer radius = clock_radius * factor
const TICK_OUTER_FACTOR: float = 0.95
const TICK_INNER_FACTOR: float = 0.85
const TICK_THICKNESS: float = 0.005
const TICK_DEPTH: float = 0.003
const HOUR_HAND_LENGTH_FACTOR: float = 0.50
const HOUR_HAND_WIDTH: float = 0.012
const HOUR_HAND_THICKNESS: float = 0.005
const MIN_HAND_LENGTH_FACTOR: float = 0.75
const MIN_HAND_WIDTH: float = 0.010
const MIN_HAND_THICKNESS: float = 0.004
const SEC_HAND_LENGTH_FACTOR: float = 0.85
const SEC_HAND_WIDTH: float = 0.008
const SEC_HAND_THICKNESS: float = 0.0025
const HAND_FORWARD_GAP: float = 0.001
const DIGITAL_FONT_SIZE: int = 48
const DIGITAL_PIXEL_SIZE: float = 0.0045

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_clock()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_clock()


func _read_metadata_overrides() -> void:
	if has_meta("config_clock_radius"):
		clock_radius = float(str(get_meta("config_clock_radius")))
	if has_meta("config_clock_depth"):
		clock_depth = float(str(get_meta("config_clock_depth")))
	if has_meta("config_face_color"):
		face_color = _parse_color(str(get_meta("config_face_color")), face_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_hands_color"):
		hands_color = _parse_color(str(get_meta("config_hands_color")), hands_color)
	if has_meta("config_tick_color"):
		tick_color = _parse_color(str(get_meta("config_tick_color")), tick_color)
	if has_meta("config_second_hand_color"):
		second_hand_color = _parse_color(str(get_meta("config_second_hand_color")), second_hand_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_digital_color"):
		digital_color = _parse_color(str(get_meta("config_digital_color")), digital_color)
	if has_meta("config_hour_hand_angle"):
		hour_hand_angle = float(str(get_meta("config_hour_hand_angle")))
	if has_meta("config_minute_hand_angle"):
		minute_hand_angle = float(str(get_meta("config_minute_hand_angle")))
	if has_meta("config_second_hand_angle"):
		second_hand_angle = float(str(get_meta("config_second_hand_angle")))
	if has_meta("config_tick_count"):
		tick_count = int(str(get_meta("config_tick_count")))
	if has_meta("config_is_digital"):
		var dv := str(get_meta("config_is_digital")).to_lower()
		is_digital = dv in ["true", "1", "yes", "on"]
	if has_meta("config_digital_time_text"):
		digital_time_text = str(get_meta("config_digital_time_text"))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_clock() -> void:
	_built = true
	_build_face()
	_build_frame_ring()
	if is_digital:
		_build_digital_label()
	else:
		_build_tick_marks()
		_build_hour_hand()
		_build_minute_hand()
		_build_second_hand()
		_build_center_cap()


func _build_face() -> void:
	# Round face disc. Cylinder axis along Z so its flat face shows +Z.
	var face := MeshInstance3D.new()
	face.name = "Face"
	var mesh := CylinderMesh.new()
	mesh.top_radius = clock_radius
	mesh.bottom_radius = clock_radius
	mesh.height = clock_depth * 0.5
	face.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = face_color
	mat.roughness = 0.6
	mat.metallic = 0.05
	face.material_override = mat
	# Lay the cylinder along the Z axis (default along Y).
	face.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	face.position = Vector3(0.0, 0.0, -clock_depth * 0.125)
	add_child(face)


func _build_frame_ring() -> void:
	# Torus ring around the face. Default Torus axis is Y; rotate so axis = Z.
	var ring := MeshInstance3D.new()
	ring.name = "FrameRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = clock_radius
	mesh.outer_radius = clock_radius * FRAME_RING_FACTOR
	mesh.rings = 24
	mesh.ring_segments = 24
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.4
	mat.metallic = 0.7
	ring.material_override = mat
	# Rotate the torus so its central axis is +Z.
	ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	ring.position = Vector3(0.0, 0.0, 0.0)
	add_child(ring)


func _build_tick_marks() -> void:
	if tick_count <= 0:
		return
	var root := Node3D.new()
	root.name = "Ticks"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = tick_color
	mat.roughness = 0.6
	mat.metallic = 0.1

	var inner_r: float = clock_radius * TICK_INNER_FACTOR
	var outer_r: float = clock_radius * TICK_OUTER_FACTOR
	var mid_r: float = (inner_r + outer_r) * 0.5
	var bar_length: float = outer_r - inner_r

	for i in range(tick_count):
		var ang: float = TAU * float(i) / float(tick_count) - PI * 0.5  # 12 at top (-Y up in screen space if needed); here +X = 3 o'clock direction
		# We want index 0 at the 12 position (top, +Y in face plane). Standard rotation:
		# 0 → +Y, increasing index → rotate CLOCKWISE in face plane (so use sin/cos of angle below).
		# Recompute: angle_deg = i * 360/tick_count, with 0 at 12 o'clock, clockwise.
		var deg: float = float(i) * 360.0 / float(tick_count)
		var rad: float = deg_to_rad(deg)
		var cx: float = sin(rad) * mid_r
		var cy: float = cos(rad) * mid_r

		var tick := MeshInstance3D.new()
		tick.name = "Tick_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(TICK_THICKNESS, bar_length, TICK_DEPTH)
		tick.mesh = bm
		tick.material_override = mat
		tick.position = Vector3(cx, cy, HAND_FORWARD_GAP)
		# Rotate the tick around its center so its long axis points radially outward.
		# The bar's local +Y should point along (sin rad, cos rad). Angle from +Y is rad.
		tick.rotation = Vector3(0.0, 0.0, -rad)
		root.add_child(tick)


func _build_hour_hand() -> void:
	var hand_length: float = clock_radius * HOUR_HAND_LENGTH_FACTOR
	_build_hand("HourHand", hand_length, HOUR_HAND_WIDTH, HOUR_HAND_THICKNESS, hour_hand_angle, hands_color, false)


func _build_minute_hand() -> void:
	var hand_length: float = clock_radius * MIN_HAND_LENGTH_FACTOR
	_build_hand("MinuteHand", hand_length, MIN_HAND_WIDTH, MIN_HAND_THICKNESS, minute_hand_angle, hands_color, false)


func _build_second_hand() -> void:
	var hand_length: float = clock_radius * SEC_HAND_LENGTH_FACTOR
	_build_hand("SecondHand", hand_length, SEC_HAND_WIDTH, SEC_HAND_THICKNESS, second_hand_angle, second_hand_color, true)


func _build_hand(node_name: String, length: float, width: float, thick: float, angle_deg: float, hand_color: Color, emissive: bool) -> void:
	# Build a pivot at clock center; child hand box has its CENTER offset by length*0.5
	# along the pivot's local +Y, so the hand extends from center outward.
	var pivot := Node3D.new()
	pivot.name = node_name + "Pivot"
	add_child(pivot)
	# Convention: angle_deg measured CLOCKWISE from the 12 position.
	# In our face plane, 12 = +Y. Clockwise rotation around +Z is negative.
	var rad: float = deg_to_rad(angle_deg)
	pivot.rotation = Vector3(0.0, 0.0, -rad)
	pivot.position = Vector3(0.0, 0.0, HAND_FORWARD_GAP + 0.001)

	var hand := MeshInstance3D.new()
	hand.name = node_name
	var bm := BoxMesh.new()
	bm.size = Vector3(width, length, thick)
	hand.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hand_color
	mat.roughness = 0.4
	mat.metallic = 0.2
	if emissive:
		mat.emission_enabled = true
		mat.emission = hand_color
		mat.emission_energy_multiplier = 1.2
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	hand.material_override = mat
	# Offset along the pivot's local +Y so the hand's base sits at clock center.
	hand.position = Vector3(0.0, length * 0.5, 0.0)
	pivot.add_child(hand)


func _build_center_cap() -> void:
	# Small cap covering the hand pivot.
	var cap := MeshInstance3D.new()
	cap.name = "CenterCap"
	var mesh := CylinderMesh.new()
	mesh.top_radius = clock_radius * 0.045
	mesh.bottom_radius = clock_radius * 0.045
	mesh.height = clock_depth * 0.25
	cap.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	cap.material_override = mat
	cap.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	cap.position = Vector3(0.0, 0.0, clock_depth * 0.25)
	add_child(cap)


func _build_digital_label() -> void:
	# Replace analog hands/ticks with a baked-text readout painted onto the
	# face surface — unshaded=true gives it the emissive screen look.
	if digital_time_text.is_empty():
		return
	# World size: full display strip across the face (width) × a comfortable
	# single-line height. Scales with clock_radius so config overrides work.
	var w: float = clock_radius * 1.5
	var h: float = clock_radius * 0.48
	var quad: MeshInstance3D = BakedText.make_label_mesh(
			digital_time_text, digital_color, Vector2(w, h), 1400, true)
	if quad == null:
		return
	quad.name = "DigitalReadout"
	# Sit flush+tiny-proud of the face surface (same z as old Label3D).
	quad.position = Vector3(0.0, 0.0, clock_depth * 0.25 + 0.002)
	add_child(quad)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
