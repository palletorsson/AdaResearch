extends Node3D
class_name ServerRack

# @identity
# essence: a 19-inch vertical compute rack — Aperture/Black Mesa lab vocabulary for "the lab has CPU". Rectangular dark-steel frame on small feet, interior subdivided into U slots, a configurable count of server faces with rows of emerald LEDs, a single Portal-orange accent strip near the top, and a door that opens to reveal the interior or closes to a solid panel.
# desire: the rack wants to be the room's HEARTBEAT — quiet, modular, blinking. Servers are the lab's metabolism: data in, data out, heat radiating sideways. A chamber with a server rack is a chamber that is THINKING about something, somewhere else, all the time.
# critical_parameter: door_open — false reads as "production / live / do not touch" (solid front, only the accent strip leaks), true reads as "decommissioned / lab-bench / show me the guts" (LEDs and slots exposed). Same hardware, two completely different room postures.
# triggers: _ready() builds frame + feet + slot markers + servers + LEDs + door from exports; apply_grid_config rebuilds
# emerges: closed door + bright LEDs hidden = "discreet infrastructure"; open door + many LEDs = "active compute, lab-as-server-room"; few servers + open = "decommissioned, ghost of"; sparse U-slots filled = "test bench, work in progress"
# needs: rectangular frame [present]; 4 small feet [present]; interior U-slot markers [present]; vertically distributed server faces with LED arrays [present]; switchable solid door / open exposure [present]; accent strip [present]
# relationships: sibling to control_board (one operates, the other COMPUTES — they are the lab's two hands); cousin to large_table (the rack stands FLOOR-mounted where the table stands hip-mounted — both are surfaces, the rack is the vertical one); peer to cable_tray (a rack with no cable tray overhead is a rack that has been UNPLUGGED — they want each other)
# truth: a server rack is not just a box of computers. It is the lab's confession that THINKING is not always inside heads. The rack is the room's outsourced consciousness — and the LEDs are how that consciousness REPORTS BACK.

## A 19-inch vertical compute rack.
##
## Built procedurally from DNA. Origin is at the bottom center of the rack
## footprint, the rack faces +Z (the door is on the +Z face, the LEDs face
## the player). The rack stands on 4 small feet.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Rack height in U (1U ≈ 0.044m). 24U is a common compact data-rack.
@export_range(8, 42, 1) var rack_height_u: int = 24
@export var rack_width: float = 0.55
@export var rack_depth: float = 0.6

@export_group("Servers")
@export_range(1, 12, 1) var server_count: int = 6
## LEDs per server face.
@export_range(1, 16, 1) var led_density: int = 4

@export_group("Color")
@export var led_color: Color = Color(0.20, 0.95, 0.45)
@export var frame_color: Color = Color(0.18, 0.18, 0.22)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Door")
## false = solid front panel covers the interior; true = interior exposed.
@export var door_open: bool = false

# ── Constants ─────────────────────────────────────────────────────────

const U_HEIGHT: float = 0.044            # 1U ≈ 44mm
const FRAME_THICKNESS: float = 0.025
const FOOT_HEIGHT: float = 0.04
const FOOT_THICKNESS: float = 0.05
const SLOT_MARKER_HEIGHT: float = 0.003
const SERVER_FACE_DEPTH: float = 0.012
const LED_RADIUS: float = 0.008
const LED_LENGTH: float = 0.006
const ACCENT_STRIP_HEIGHT: float = 0.014
const ACCENT_STRIP_DEPTH: float = 0.006

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_rack()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_rack()


func _read_metadata_overrides() -> void:
	if has_meta("config_rack_height_u"):
		rack_height_u = int(str(get_meta("config_rack_height_u")))
	if has_meta("config_rack_width"):
		rack_width = float(str(get_meta("config_rack_width")))
	if has_meta("config_rack_depth"):
		rack_depth = float(str(get_meta("config_rack_depth")))
	if has_meta("config_server_count"):
		server_count = int(str(get_meta("config_server_count")))
	if has_meta("config_led_density"):
		led_density = int(str(get_meta("config_led_density")))
	if has_meta("config_led_color"):
		led_color = _parse_color(str(get_meta("config_led_color")), led_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_door_open"):
		var v := str(get_meta("config_door_open")).to_lower()
		door_open = v in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_rack() -> void:
	_built = true
	_build_feet()
	_build_frame()
	_build_slot_markers()
	_build_servers()
	if not door_open:
		_build_door()
	_build_accent_strip()


func _rack_total_height() -> float:
	return FOOT_HEIGHT + U_HEIGHT * float(rack_height_u)


func _interior_bottom_y() -> float:
	return FOOT_HEIGHT


func _interior_top_y() -> float:
	return _rack_total_height()


func _build_feet() -> void:
	var feet := Node3D.new()
	feet.name = "Feet"
	add_child(feet)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.4
	mat.metallic = 0.7

	var x_inset := FOOT_THICKNESS * 0.5 + 0.01
	var z_inset := FOOT_THICKNESS * 0.5 + 0.01
	var corners := [
		Vector3(rack_width * 0.5 - x_inset, 0.0, rack_depth * 0.5 - z_inset),
		Vector3(-rack_width * 0.5 + x_inset, 0.0, rack_depth * 0.5 - z_inset),
		Vector3(rack_width * 0.5 - x_inset, 0.0, -rack_depth * 0.5 + z_inset),
		Vector3(-rack_width * 0.5 + x_inset, 0.0, -rack_depth * 0.5 + z_inset),
	]
	for i in range(corners.size()):
		var foot := MeshInstance3D.new()
		foot.name = "Foot_%d" % i
		var m := BoxMesh.new()
		m.size = Vector3(FOOT_THICKNESS, FOOT_HEIGHT, FOOT_THICKNESS)
		foot.mesh = m
		foot.material_override = mat
		var c: Vector3 = corners[i]
		foot.position = Vector3(c.x, FOOT_HEIGHT * 0.5, c.z)
		feet.add_child(foot)


func _build_frame() -> void:
	# 4 vertical corner posts + a top cap. Sides (-X / +X) are panels.
	var frame := Node3D.new()
	frame.name = "Frame"
	add_child(frame)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.4
	mat.metallic = 0.65

	var interior_height := _rack_total_height() - FOOT_HEIGHT
	var center_y := FOOT_HEIGHT + interior_height * 0.5

	# Left side panel (-X)
	var left := MeshInstance3D.new()
	left.name = "LeftSide"
	var lm := BoxMesh.new()
	lm.size = Vector3(FRAME_THICKNESS, interior_height, rack_depth)
	left.mesh = lm
	left.material_override = mat
	left.position = Vector3(-rack_width * 0.5 + FRAME_THICKNESS * 0.5, center_y, 0.0)
	frame.add_child(left)

	# Right side panel (+X)
	var right := MeshInstance3D.new()
	right.name = "RightSide"
	var rm := BoxMesh.new()
	rm.size = Vector3(FRAME_THICKNESS, interior_height, rack_depth)
	right.mesh = rm
	right.material_override = mat
	right.position = Vector3(rack_width * 0.5 - FRAME_THICKNESS * 0.5, center_y, 0.0)
	frame.add_child(right)

	# Back panel (-Z)
	var back := MeshInstance3D.new()
	back.name = "Back"
	var bm := BoxMesh.new()
	bm.size = Vector3(rack_width - FRAME_THICKNESS * 2.0, interior_height, FRAME_THICKNESS)
	back.mesh = bm
	back.material_override = mat
	back.position = Vector3(0.0, center_y, -rack_depth * 0.5 + FRAME_THICKNESS * 0.5)
	frame.add_child(back)

	# Top cap
	var top := MeshInstance3D.new()
	top.name = "Top"
	var tm := BoxMesh.new()
	tm.size = Vector3(rack_width, FRAME_THICKNESS, rack_depth)
	top.mesh = tm
	top.material_override = mat
	top.position = Vector3(0.0, _rack_total_height() - FRAME_THICKNESS * 0.5, 0.0)
	frame.add_child(top)

	# Bottom cap
	var bottom := MeshInstance3D.new()
	bottom.name = "Bottom"
	var btm := BoxMesh.new()
	btm.size = Vector3(rack_width, FRAME_THICKNESS, rack_depth)
	bottom.mesh = btm
	bottom.material_override = mat
	bottom.position = Vector3(0.0, FOOT_HEIGHT + FRAME_THICKNESS * 0.5, 0.0)
	frame.add_child(bottom)


func _build_slot_markers() -> void:
	# Thin horizontal stripes inside the rack — one per U slot. Only build a
	# subset (every 2U) to keep the geometry count reasonable but still read
	# as "this is a U-slot rack".
	var markers := Node3D.new()
	markers.name = "SlotMarkers"
	add_child(markers)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.32, 0.36)
	mat.roughness = 0.5
	mat.metallic = 0.4

	var interior_width := rack_width - FRAME_THICKNESS * 2.0 - 0.01
	var bottom_y := _interior_bottom_y() + FRAME_THICKNESS
	# Stride: place a marker every 2U, leave first/last U free for the caps.
	var stride := 2
	var u := stride
	while u < rack_height_u:
		var m := MeshInstance3D.new()
		m.name = "SlotMarker_%dU" % u
		var bm := BoxMesh.new()
		bm.size = Vector3(interior_width, SLOT_MARKER_HEIGHT, 0.01)
		m.mesh = bm
		m.material_override = mat
		var y := bottom_y + U_HEIGHT * float(u)
		m.position = Vector3(0.0, y, rack_depth * 0.5 - 0.025)
		markers.add_child(m)
		u += stride


func _build_servers() -> void:
	# server_count servers vertically distributed across the rack interior.
	# Each server is a BoxMesh face with led_density emissive cylinders.
	var servers := Node3D.new()
	servers.name = "Servers"
	add_child(servers)

	var server_face_mat := StandardMaterial3D.new()
	server_face_mat.albedo_color = Color(0.12, 0.12, 0.14)
	server_face_mat.roughness = 0.55
	server_face_mat.metallic = 0.35

	var led_mat := StandardMaterial3D.new()
	led_mat.albedo_color = led_color
	led_mat.emission_enabled = true
	led_mat.emission = led_color
	led_mat.emission_energy_multiplier = 2.2
	led_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var bottom_y := _interior_bottom_y() + FRAME_THICKNESS + 0.02
	var top_y := _interior_top_y() - FRAME_THICKNESS - 0.02
	var available: float = max(0.0, top_y - bottom_y)
	if server_count <= 0:
		return
	# Server slot pitch — divides the interior into server_count equal bands.
	var pitch := available / float(server_count)
	var server_face_height := pitch * 0.6
	if server_face_height < U_HEIGHT * 1.2:
		server_face_height = U_HEIGHT * 1.2

	var server_face_width := rack_width - FRAME_THICKNESS * 2.0 - 0.02
	# Place server faces just inside the front of the rack (+Z side).
	var face_z := rack_depth * 0.5 - FRAME_THICKNESS - SERVER_FACE_DEPTH * 0.5 - 0.005

	for i in range(server_count):
		var server := Node3D.new()
		server.name = "Server_%d" % i
		servers.add_child(server)

		var face := MeshInstance3D.new()
		face.name = "Face"
		var fm := BoxMesh.new()
		fm.size = Vector3(server_face_width, server_face_height, SERVER_FACE_DEPTH)
		face.mesh = fm
		face.material_override = server_face_mat
		var y := bottom_y + pitch * (float(i) + 0.5)
		face.position = Vector3(0.0, y, face_z)
		server.add_child(face)

		# LEDs along the right side of the server face — tiny emissive cylinders.
		var led_row_x_start := server_face_width * 0.25
		var led_spacing := 0.0
		if led_density > 1:
			led_spacing = (server_face_width * 0.4) / float(led_density - 1)
		for j in range(led_density):
			var led := MeshInstance3D.new()
			led.name = "LED_%d" % j
			var lm := CylinderMesh.new()
			lm.top_radius = LED_RADIUS
			lm.bottom_radius = LED_RADIUS
			lm.height = LED_LENGTH
			led.mesh = lm
			led.material_override = led_mat
			led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Lay LED cylinder along +Z so it pokes out of the face.
			led.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
			var lx := led_row_x_start + led_spacing * float(j)
			# Stagger vertically slightly so it doesn't read as a perfect column.
			var ly := y - server_face_height * 0.15
			var lz := face_z + SERVER_FACE_DEPTH * 0.5 + LED_LENGTH * 0.5
			led.position = Vector3(lx, ly, lz)
			server.add_child(led)


func _build_door() -> void:
	# Solid front panel covering the interior when door_open=false.
	var door := MeshInstance3D.new()
	door.name = "Door"
	var mesh := BoxMesh.new()
	var door_w := rack_width - FRAME_THICKNESS * 2.0
	var door_h := _rack_total_height() - FOOT_HEIGHT - FRAME_THICKNESS * 2.0
	mesh.size = Vector3(door_w, door_h, FRAME_THICKNESS)
	door.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(frame_color.r * 1.15, frame_color.g * 1.15, frame_color.b * 1.18)
	mat.roughness = 0.45
	mat.metallic = 0.5
	door.material_override = mat
	var center_y := FOOT_HEIGHT + FRAME_THICKNESS + door_h * 0.5
	door.position = Vector3(0.0, center_y, rack_depth * 0.5 - FRAME_THICKNESS * 0.5)
	add_child(door)

	# Small handle on the right side of the door.
	var handle := MeshInstance3D.new()
	handle.name = "DoorHandle"
	var hm := BoxMesh.new()
	hm.size = Vector3(0.04, 0.06, 0.02)
	handle.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.6, 0.6, 0.62)
	hmat.roughness = 0.3
	hmat.metallic = 0.85
	handle.material_override = hmat
	handle.position = Vector3(door_w * 0.4, center_y, rack_depth * 0.5 + 0.012)
	add_child(handle)


func _build_accent_strip() -> void:
	# Single accent strip near the top of the front face.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(rack_width * 0.85, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just under the top cap.
	var y := _rack_total_height() - FRAME_THICKNESS - 0.04
	strip.position = Vector3(0.0, y, rack_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5)
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
