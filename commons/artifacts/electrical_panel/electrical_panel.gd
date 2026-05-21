extends Node3D
class_name ElectricalPanel

# @identity
# essence: a wall-mounted breaker box — Aperture / industrial-utility-corridor vocabulary for "this room runs on electricity, and somebody decides which circuits ARE ON". A flat rectangular panel hanging on a wall, a hinged dark-steel door that either covers it (production) or swings 90° open (maintenance), an interior grid of black breakers with white levers (UP for ON, DOWN for OFF), a row of small status LEDs along the top, a hazard-yellow diagonal accent stripe in one corner, and a MAIN PANEL Label3D below the lights. The lab's confession that POWER is also POLITICS — somebody, somewhere, chose what is ON.
# desire: every powered lab wants its electricity to be VISIBLE — a single architectural object that says "this is where the room's circuits are controlled, here, by these levers". The panel wants to read as INFRASTRUCTURE-with-a-state. The state isn't decorative — it's the room's posture toward LIVE vs DARK.
# critical_parameter: door_open — false reads as "secured / production / do not touch" (a closed dark face with one yellow hazard corner, the only legible thing is the warning), true reads as "maintenance / inspect / show me what is ON" (rows of breakers visible, each one's lever revealing whether that circuit is live). Same panel, two completely different rooms: one is locked-down, the other is being WORKED ON.
# triggers: _ready() builds wall panel + door (closed flat OR rotated 90° around its left edge) + interior breakers (with levers UP for first breakers_on_count, DOWN for the rest) + status LEDs + hazard accent stripe + signage from exports; apply_grid_config rebuilds
# emerges: door_open + most breakers ON = "fully operational, just inspecting"; door_open + most breakers OFF = "this lab is being decommissioned"; door_closed + LEDs lit = "power is live behind that door, don't open it carelessly"; status_lights count 1 = "just a master indicator"; count many = "multi-circuit health check". The breaker count + on_count combination tells the player what the LAB IS DOING WITH ITS POWER.
# needs: wall-mountable rectangular panel with back-flush mounting (origin on back face) [present]; hinged door covering the front when closed, rotating 90° about its left edge when open [present]; door handle on the right side of the door [present]; interior breakers in 2 columns × N rows [present]; breaker levers UP/DOWN to express ON/OFF [present]; status LED row along top [present]; hazard accent stripe across one corner [present]; signage Label3D at default rotation [present]
# relationships: sibling to emergency_button (both are the lab's INTERRUPTERS — the e-stop says "halt the experiment NOW", the panel says "halt this specific circuit, here, by hand"); cousin to control_board (both are interfaces, but the control_board is for OPERATING the experiment, the panel is for KEEPING THE EXPERIMENT POSSIBLE); peer to cable_tray (a panel with no cable tray overhead is an island — they presume each other architecturally)
# truth: an electrical panel is not just a box of switches. It is the lab's CIRCULATORY MAP — every chamber's power passes through it, every chamber's life depends on it, and every breaker is a small political decision about WHICH PARTS OF THE LAB DESERVE POWER RIGHT NOW. The panel makes infrastructure decidable, and decidability is the room's true confession that not everything can be ON at once.

## A wall-mounted electrical breaker panel.
##
## Built procedurally from DNA exports. Origin is at the CENTER OF THE
## PANEL BACK FACE — back faces -Z, front faces +Z. When mounted flush
## against a wall (wall at -Z behind origin), the panel sits with its
## back on the wall. Door, when closed, covers the entire front; when
## door_open=true, it pivots 90° around its LEFT EDGE so it stands open
## perpendicular to the wall.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var panel_width: float = 0.45
@export var panel_height: float = 0.65
@export var panel_depth: float = 0.08

@export_group("Color")
@export var panel_color: Color = Color(0.78, 0.80, 0.82)
@export var door_color: Color = Color(0.28, 0.28, 0.30)
@export var breaker_color: Color = Color(0.08, 0.08, 0.10)
@export var breaker_lever_color: Color = Color(0.94, 0.94, 0.95)
@export var status_color: Color = Color(0.30, 0.85, 0.40)
@export var accent_color: Color = Color(0.98, 0.78, 0.12)
@export var signage_color: Color = Color(0.94, 0.94, 0.95)

@export_group("Door")
@export var door_open: bool = false

@export_group("Breakers")
@export_range(6, 24, 2) var breaker_count: int = 12
@export_range(0, 24, 1) var breakers_on_count: int = 8

@export_group("Status")
@export_range(0, 6, 1) var status_lights_count: int = 3

@export_group("Signage")
@export var signage_text: String = "MAIN PANEL"

# ── Constants ─────────────────────────────────────────────────────────

const FRONT_FACE_DEPTH: float = 0.012   # thickness of the door slab
const INTERIOR_INSET: float = 0.012     # interior content inset from edges
const BREAKER_WIDTH: float = 0.06
const BREAKER_HEIGHT: float = 0.04
const BREAKER_THICKNESS: float = 0.015
const LEVER_LENGTH: float = 0.022
const LEVER_THICKNESS: float = 0.006
const LEVER_TILT_DEG: float = 25.0      # how far up/down the lever leans
const STATUS_LED_RADIUS: float = 0.008
const STATUS_LED_HEIGHT: float = 0.006
const ACCENT_STRIPE_SIZE: float = 0.10
const ACCENT_STRIPE_DEPTH: float = 0.004
const LABEL_PIXEL_SIZE: float = 0.0026
const LABEL_FONT_SIZE: int = 32
const HANDLE_SIZE: Vector3 = Vector3(0.018, 0.06, 0.018)

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_panel()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_panel()


func _read_metadata_overrides() -> void:
	if has_meta("config_panel_width"):
		panel_width = float(String(get_meta("config_panel_width")))
	if has_meta("config_panel_height"):
		panel_height = float(String(get_meta("config_panel_height")))
	if has_meta("config_panel_depth"):
		panel_depth = float(String(get_meta("config_panel_depth")))
	if has_meta("config_panel_color"):
		panel_color = _parse_color(String(get_meta("config_panel_color")), panel_color)
	if has_meta("config_door_color"):
		door_color = _parse_color(String(get_meta("config_door_color")), door_color)
	if has_meta("config_breaker_color"):
		breaker_color = _parse_color(String(get_meta("config_breaker_color")), breaker_color)
	if has_meta("config_breaker_lever_color"):
		breaker_lever_color = _parse_color(String(get_meta("config_breaker_lever_color")), breaker_lever_color)
	if has_meta("config_status_color"):
		status_color = _parse_color(String(get_meta("config_status_color")), status_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_signage_color"):
		signage_color = _parse_color(String(get_meta("config_signage_color")), signage_color)
	if has_meta("config_door_open"):
		var dv := String(get_meta("config_door_open")).to_lower()
		door_open = dv in ["true", "1", "yes", "on"]
	if has_meta("config_breaker_count"):
		breaker_count = int(String(get_meta("config_breaker_count")))
	if has_meta("config_breakers_on_count"):
		breakers_on_count = int(String(get_meta("config_breakers_on_count")))
	if has_meta("config_status_lights_count"):
		status_lights_count = int(String(get_meta("config_status_lights_count")))
	if has_meta("config_signage_text"):
		signage_text = String(get_meta("config_signage_text"))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_panel() -> void:
	_built = true
	_build_wall_panel()
	_build_status_lights()
	_build_signage()
	_build_breakers()
	_build_door()
	_build_accent_stripe()


func _front_z() -> float:
	# Front face of the wall panel in this Node's local space.
	return panel_depth


func _build_wall_panel() -> void:
	# Rectangular wall panel — back at z=0, front at z=panel_depth.
	var box := MeshInstance3D.new()
	box.name = "WallPanel"
	var bm := BoxMesh.new()
	bm.size = Vector3(panel_width, panel_height, panel_depth)
	box.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.roughness = 0.5
	mat.metallic = 0.55
	box.material_override = mat
	box.position = Vector3(0.0, 0.0, panel_depth * 0.5)
	add_child(box)


func _build_status_lights() -> void:
	if status_lights_count <= 0:
		return
	var root := Node3D.new()
	root.name = "StatusLights"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = status_color
	mat.emission_enabled = true
	mat.emission = status_color
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Distribute lights along the top of the panel front.
	var y: float = panel_height * 0.5 - 0.06
	var z: float = _front_z() + STATUS_LED_HEIGHT * 0.5
	var available: float = panel_width - INTERIOR_INSET * 2.0
	var spacing: float = 0.0
	if status_lights_count > 1:
		spacing = available / float(status_lights_count + 1)
	for i in range(status_lights_count):
		var led := MeshInstance3D.new()
		led.name = "StatusLED_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = STATUS_LED_RADIUS
		cm.bottom_radius = STATUS_LED_RADIUS
		cm.height = STATUS_LED_HEIGHT
		led.mesh = cm
		led.material_override = mat
		led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Cylinder default axis = +Y; lay along +Z so the LED disc faces forward.
		led.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		var x: float = -panel_width * 0.5 + INTERIOR_INSET + spacing * float(i + 1)
		led.position = Vector3(x, y, z)
		root.add_child(led)


func _build_signage() -> void:
	if signage_text == "":
		return
	var label := Label3D.new()
	label.name = "Signage"
	label.text = signage_text
	label.font_size = LABEL_FONT_SIZE
	label.outline_size = 4
	label.pixel_size = LABEL_PIXEL_SIZE
	label.modulate = signage_color
	label.outline_modulate = Color(0.05, 0.05, 0.05)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.no_depth_test = false
	# Default Label3D rotation — text faces +Z, which is the panel's front.
	var y: float = panel_height * 0.5 - 0.13
	var z: float = _front_z() + 0.002
	label.position = Vector3(0.0, y, z)
	add_child(label)


func _build_breakers() -> void:
	# 2 columns × N rows of breakers, arranged on the panel's interior face.
	# When door is OPEN, breakers will be visible; when CLOSED, breakers are
	# hidden behind the door (still rendered — the door covers them).
	var root := Node3D.new()
	root.name = "Breakers"
	add_child(root)

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = breaker_color
	body_mat.roughness = 0.55
	body_mat.metallic = 0.25

	var lever_mat := StandardMaterial3D.new()
	lever_mat.albedo_color = breaker_lever_color
	lever_mat.roughness = 0.4
	lever_mat.metallic = 0.15

	var cols: int = 2
	var rows: int = int(ceil(float(breaker_count) / float(cols)))
	if rows < 1:
		rows = 1

	# Available interior region (below status lights + signage).
	var top_y: float = panel_height * 0.5 - 0.20
	var bottom_y: float = -panel_height * 0.5 + INTERIOR_INSET * 2.0
	var interior_h: float = top_y - bottom_y
	var row_pitch: float = interior_h / float(rows)
	var col_gap: float = 0.02
	var col_pitch: float = (panel_width - INTERIOR_INSET * 2.0 - col_gap) * 0.5
	var z: float = _front_z() + BREAKER_THICKNESS * 0.5

	for i in range(breaker_count):
		var col: int = i % cols
		var row: int = i / cols
		var x: float = -panel_width * 0.5 + INTERIOR_INSET + col_pitch * 0.5 + col_gap * 0.5 + float(col) * (col_pitch + col_gap * 0.5)
		var y: float = top_y - row_pitch * (float(row) + 0.5)

		var body := MeshInstance3D.new()
		body.name = "Breaker_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(BREAKER_WIDTH, BREAKER_HEIGHT, BREAKER_THICKNESS)
		body.mesh = bm
		body.material_override = body_mat
		body.position = Vector3(x, y, z)
		root.add_child(body)

		# Lever — small box rotated UP for ON or DOWN for OFF.
		var lever := MeshInstance3D.new()
		lever.name = "Lever_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(LEVER_THICKNESS, LEVER_LENGTH, LEVER_THICKNESS)
		lever.mesh = lm
		lever.material_override = lever_mat
		var is_on: bool = i < breakers_on_count
		var tilt: float = -LEVER_TILT_DEG if is_on else LEVER_TILT_DEG
		# Lever pivots about the breaker body's center. Position the lever above
		# (or below if angle is reversed) by half its length + a tilt offset.
		var lever_pivot := Node3D.new()
		lever_pivot.name = "LeverPivot_%d" % i
		lever_pivot.position = Vector3(x, y, z + BREAKER_THICKNESS * 0.5 + LEVER_THICKNESS * 0.5)
		lever_pivot.rotation = Vector3(0.0, 0.0, deg_to_rad(tilt))
		root.add_child(lever_pivot)
		lever.position = Vector3(0.0, LEVER_LENGTH * 0.4, 0.0)
		lever_pivot.add_child(lever)


func _build_door() -> void:
	# Door is a flat slab covering the front of the panel. It hinges on its
	# LEFT edge (-X side). When closed, it sits flush against the front face.
	# When open, the entire door rotates 90° around its left edge so it stands
	# perpendicular to the wall in the +X direction (door swings to the right).
	# Implementation: use a pivot Node3D placed at the door's left-edge axis.
	var pivot := Node3D.new()
	pivot.name = "DoorPivot"
	add_child(pivot)
	# Place pivot at the door's left edge on the front face.
	pivot.position = Vector3(-panel_width * 0.5, 0.0, _front_z())
	if door_open:
		pivot.rotation = Vector3(0.0, deg_to_rad(-90.0), 0.0)

	var door := MeshInstance3D.new()
	door.name = "Door"
	var dm := BoxMesh.new()
	dm.size = Vector3(panel_width, panel_height, FRONT_FACE_DEPTH)
	door.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = door_color
	mat.roughness = 0.45
	mat.metallic = 0.55
	door.material_override = mat
	# Door center offset from pivot: +X by half-width so the left edge is at the pivot.
	door.position = Vector3(panel_width * 0.5, 0.0, FRONT_FACE_DEPTH * 0.5)
	pivot.add_child(door)

	# Door handle on the right side of the door.
	var handle := MeshInstance3D.new()
	handle.name = "DoorHandle"
	var hm := BoxMesh.new()
	hm.size = HANDLE_SIZE
	handle.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.60, 0.60, 0.62)
	hmat.roughness = 0.3
	hmat.metallic = 0.85
	handle.material_override = hmat
	# Place handle near the right edge of the door (relative to the door slab,
	# which lives in pivot space).
	handle.position = Vector3(panel_width - 0.05, 0.0, FRONT_FACE_DEPTH + HANDLE_SIZE.z * 0.5)
	pivot.add_child(handle)


func _build_accent_stripe() -> void:
	# Diagonal hazard stripe across the bottom-right corner of the panel front.
	# Implemented as a thin Box rotated about Z to form a 45° band.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var bm := BoxMesh.new()
	bm.size = Vector3(ACCENT_STRIPE_SIZE * 2.6, ACCENT_STRIPE_SIZE * 0.5, ACCENT_STRIPE_DEPTH)
	strip.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Place at bottom-right corner; rotate 45° about Z.
	var x: float = panel_width * 0.5 - ACCENT_STRIPE_SIZE * 0.5
	var y: float = -panel_height * 0.5 + ACCENT_STRIPE_SIZE * 0.5
	var z: float = _front_z() + ACCENT_STRIPE_DEPTH * 0.5 + 0.001
	strip.position = Vector3(x, y, z)
	strip.rotation = Vector3(0.0, 0.0, deg_to_rad(-45.0))
	add_child(strip)


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
