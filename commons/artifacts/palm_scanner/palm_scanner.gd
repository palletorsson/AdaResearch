extends Node3D
class_name PalmScanner

# @identity
# essence: a wall-mounted (or podium-mounted) biometric palm reader — Portal 2 / Aperture vocabulary for "you are recognised here, or you are not". A dark plastic rectangular panel, an inset scan window with a faint hand outline (palm disc + four finger boxes), a small status LED in the corner, a Portal-orange accent strip across the top, and a PLACE HAND Label3D beneath the scan window. When active, the scan window and outline glow emerald; when inactive, the window goes dark and the status LED glows red.
# desire: the scanner wants to be the room's THRESHOLD — the question "are you on the list?" made architectural. A door asks you to push; a scanner asks you to PROVE. It wants palms specifically: a palm is asymmetric, irreproducible, distinctly yours. The scanner converts identity into permission.
# critical_parameter: scan_active — true reads as "the system is listening, present your hand" (emerald glow, green LED), false reads as "this entry is locked, do not bother" (dark panel, red LED). Same hardware, the entire room's posture flips.
# triggers: _ready() builds panel + scan window + hand outline + status LED + accent strip + label + optional podium stand from exports; apply_grid_config rebuilds
# emerges: scan_active=true + mounting=wall = "checkpoint at the door"; scan_active=false = "this corridor is closed"; mounting=podium = "free-standing checkpoint, mid-room", the scanner asks for the hand in open air rather than against the wall
# needs: rectangular dark panel [present]; inset scan window with emissive material [present]; hand outline (palm disc + 4 finger boxes) [present]; corner status LED with red/green state [present]; Portal-orange accent stripe [present]; PLACE HAND Label3D [present]; optional vertical podium stand [present]
# relationships: sibling to sliding_door (the scanner is the QUESTION the door asks before it opens — together they form the threshold ritual); cousin to emergency_button (both are interactive surfaces, one says STOP one says PROVE); peer to exit_sign (both are signage with intent, but exit_sign says "go here" while palm_scanner says "earn this")
# truth: a palm scanner is not just a sensor. It is the lab's declaration that BODIES are credentials. The hand is not merely flesh in this frame — it is a key, a barcode, a signature. The scanner reduces the human to the readable.

## A wall-mounted (or podium) biometric palm scanner.
##
## Built procedurally from DNA. Origin is at the center of the panel face
## (or at the floor in podium mode, with the panel centered above). The
## panel faces +Z. Toggle `scan_active` to flip emerald-glow on / red LED.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var panel_width: float = 0.18
@export var panel_height: float = 0.24
@export var panel_depth: float = 0.05

@export_group("Color")
@export var panel_color: Color = Color(0.12, 0.12, 0.14)
@export var scan_color: Color = Color(0.25, 0.92, 0.45)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)
@export var text_color: Color = Color(0.95, 0.96, 0.98)

@export_group("State")
@export var scan_active: bool = true

@export_group("Signage")
@export var label_text: String = "PLACE HAND"

@export_group("Mounting")
## "wall" — panel mounted directly at origin.
## "podium" — panel sits on a 1.0m vertical stand rising from origin.
@export var mounting: String = "wall"

@export_group("Interaction")
## Sphere radius in front of the scan window that detects a hand.
## XR controllers + XRToolsHand instances entering this volume fire
## the palm_scanned signal.
@export var scan_radius: float = 0.18
## How long (seconds) the door stays open after a successful scan
## before the scanner emits palm_released and closes it again.
@export var scan_hold_seconds: float = 5.0
## When TRUE the scanner locates a LabDoorSensor via the
## "lab_door_sensors" group and wires palm_scanned → its open path
## and palm_released → its close path automatically.
@export var auto_connect_door: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const SCAN_INSET_FACTOR: float = 0.70   # scan window is 70% of panel width
const SCAN_HEIGHT_FACTOR: float = 0.55  # scan window is 55% of panel height
const SCAN_DEPTH: float = 0.008
const ACCENT_STRIP_HEIGHT: float = 0.010
const ACCENT_STRIP_DEPTH: float = 0.004
const STATUS_LED_RADIUS: float = 0.008
const STATUS_LED_LENGTH: float = 0.006
const PALM_DISC_RADIUS_FACTOR: float = 0.18  # relative to panel_width
const FINGER_WIDTH_FACTOR: float = 0.045
const FINGER_HEIGHT_FACTOR: float = 0.16
const PODIUM_HEIGHT: float = 1.00
const PODIUM_THICKNESS: float = 0.06

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _scan_area: Area3D = null
var _hold_timer: Timer = null
var _status_led_mesh: MeshInstance3D = null
var _scan_window_mat: StandardMaterial3D = null
var _scanning: bool = false

# ── Signals ───────────────────────────────────────────────────────────

## Fired when a VR hand / controller enters the scan area for the first
## time (only refires after a release). Subscribers should drive door
## opening, lock unlocking, etc.
signal palm_scanned
## Fired when the scan_hold_seconds timer expires after a successful
## scan. Subscribers should close the door, re-lock, etc.
signal palm_released

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_scanner()
	if Engine.is_editor_hint():
		return
	_build_scan_area()
	if auto_connect_door:
		call_deferred("_auto_connect_to_door")


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_scanner()


func _read_metadata_overrides() -> void:
	if has_meta("config_panel_width"):
		panel_width = float(str(get_meta("config_panel_width")))
	if has_meta("config_panel_height"):
		panel_height = float(str(get_meta("config_panel_height")))
	if has_meta("config_panel_depth"):
		panel_depth = float(str(get_meta("config_panel_depth")))
	if has_meta("config_panel_color"):
		panel_color = _parse_color(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_scan_color"):
		scan_color = _parse_color(str(get_meta("config_scan_color")), scan_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_scan_active"):
		var v := str(get_meta("config_scan_active")).to_lower()
		scan_active = v in ["true", "1", "yes", "on"]
	if has_meta("config_label_text"):
		label_text = str(get_meta("config_label_text"))
	if has_meta("config_mounting"):
		mounting = str(get_meta("config_mounting")).to_lower()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_scanner() -> void:
	_built = true
	# Panel origin offset depends on mounting: in podium mode, lift the
	# panel up so its center sits at PODIUM_HEIGHT + panel_height/2.
	var panel_center := Vector3.ZERO
	if mounting == "podium":
		_build_podium()
		var podium_top: float = PODIUM_HEIGHT
		panel_center = Vector3(0.0, podium_top + panel_height * 0.5, 0.0)

	var panel_root := Node3D.new()
	panel_root.name = "Panel"
	panel_root.position = panel_center
	add_child(panel_root)

	_build_panel_body(panel_root)
	_build_scan_window(panel_root)
	_build_hand_outline(panel_root)
	_build_status_led(panel_root)
	_build_accent_strip(panel_root)
	_build_label(panel_root)


func _build_panel_body(parent: Node3D) -> void:
	var body := MeshInstance3D.new()
	body.name = "PanelBody"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(panel_width, panel_height, panel_depth)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.roughness = 0.45
	mat.metallic = 0.25
	body.material_override = mat
	body.position = Vector3.ZERO
	parent.add_child(body)


func _build_scan_window(parent: Node3D) -> void:
	var win := MeshInstance3D.new()
	win.name = "ScanWindow"
	var w: float = panel_width * SCAN_INSET_FACTOR
	var h: float = panel_height * SCAN_HEIGHT_FACTOR
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, SCAN_DEPTH)
	win.mesh = mesh
	var mat := StandardMaterial3D.new()
	if scan_active:
		# Emerald glow when active.
		mat.albedo_color = scan_color
		mat.emission_enabled = true
		mat.emission = scan_color
		mat.emission_energy_multiplier = 1.8
	else:
		# Dark, dormant.
		var dim: Color = Color(scan_color.r * 0.15, scan_color.g * 0.15, scan_color.b * 0.15)
		mat.albedo_color = dim
		mat.emission_enabled = false
	mat.roughness = 0.25
	mat.metallic = 0.0
	win.material_override = mat
	win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cache the material so the interaction code can flash it brighter
	# during an active scan and dim it back to resting.
	_scan_window_mat = mat
	# Slight downward bias so label below has space; window sits centered
	# vertically with a small lift.
	var y_offset: float = panel_height * 0.06
	# Push very slightly forward of the panel face.
	win.position = Vector3(0.0, y_offset, panel_depth * 0.5 + SCAN_DEPTH * 0.5)
	parent.add_child(win)


func _build_hand_outline(parent: Node3D) -> void:
	# A faint raised palm-disc + 4 short finger boxes, in a slightly brighter
	# variant of scan_color (so they read as outline, not bulb).
	var root := Node3D.new()
	root.name = "HandOutline"
	parent.add_child(root)

	var outline_color: Color = scan_color
	if not scan_active:
		outline_color = Color(scan_color.r * 0.35, scan_color.g * 0.35, scan_color.b * 0.35)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = outline_color
	mat.emission_enabled = scan_active
	mat.emission = outline_color
	mat.emission_energy_multiplier = 1.4 if scan_active else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var window_y: float = panel_height * 0.06
	var window_face_z: float = panel_depth * 0.5 + SCAN_DEPTH + 0.0008

	# Palm disc — lower portion of the window.
	var palm_radius: float = panel_width * PALM_DISC_RADIUS_FACTOR
	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var pm := CylinderMesh.new()
	pm.top_radius = palm_radius
	pm.bottom_radius = palm_radius
	pm.height = 0.004
	palm.mesh = pm
	palm.material_override = mat
	palm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cylinder default axis = Y, lay it flat against the panel (face +Z).
	palm.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# Sit palm slightly below the window center.
	palm.position = Vector3(0.0, window_y - panel_height * 0.06, window_face_z)
	root.add_child(palm)

	# 4 finger boxes above the palm — pinky / ring / middle / index.
	var finger_w: float = panel_width * FINGER_WIDTH_FACTOR
	var finger_h: float = panel_height * FINGER_HEIGHT_FACTOR
	var finger_d: float = 0.004
	var span: float = palm_radius * 1.6   # the 4 fingers fan across this span
	var palm_top_y: float = window_y - panel_height * 0.06 + 0.001
	for i in range(4):
		var f := MeshInstance3D.new()
		f.name = "Finger_%d" % i
		var fm := BoxMesh.new()
		# Middle two fingers slightly taller, outer two slightly shorter.
		var h_factor: float = 1.0
		match i:
			0: h_factor = 0.82  # pinky
			1: h_factor = 1.0   # ring
			2: h_factor = 1.05  # middle (tallest)
			3: h_factor = 0.92  # index
		fm.size = Vector3(finger_w, finger_h * h_factor, finger_d)
		f.mesh = fm
		f.material_override = mat
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var t: float = float(i) / 3.0  # 0..1 across the 4 fingers
		var fx: float = -span * 0.5 + span * t
		var fy: float = palm_top_y + finger_h * h_factor * 0.5 + 0.002
		f.position = Vector3(fx, fy, window_face_z)
		root.add_child(f)


func _build_status_led(parent: Node3D) -> void:
	# Small emissive cylinder in the corner — red when inactive, green when active.
	var led := MeshInstance3D.new()
	led.name = "StatusLED"
	var lm := CylinderMesh.new()
	lm.top_radius = STATUS_LED_RADIUS
	lm.bottom_radius = STATUS_LED_RADIUS
	lm.height = STATUS_LED_LENGTH
	led.mesh = lm
	var mat := StandardMaterial3D.new()
	var color: Color = Color(0.95, 0.18, 0.12)  # red default (inactive)
	if scan_active:
		color = Color(0.20, 0.95, 0.30)  # green
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	led.material_override = mat
	led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cache for interaction (flash brighter during scan).
	_status_led_mesh = led
	# Lay along +Z so it pokes out of the front face.
	led.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# Upper-right corner of the panel.
	var lx: float = panel_width * 0.5 - 0.022
	var ly: float = panel_height * 0.5 - 0.022
	var lz: float = panel_depth * 0.5 + STATUS_LED_LENGTH * 0.5
	led.position = Vector3(lx, ly, lz)
	parent.add_child(led)


func _build_accent_strip(parent: Node3D) -> void:
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(panel_width * 0.92, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Top of panel face.
	var y: float = panel_height * 0.5 - ACCENT_STRIP_HEIGHT * 0.5 - 0.006
	var z: float = panel_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5
	strip.position = Vector3(0.0, y, z)
	parent.add_child(strip)


func _build_label(parent: Node3D) -> void:
	if label_text == "":
		return
	var label := Label3D.new()
	label.name = "Label"
	label.text = label_text
	# Sizing — target height ~12% of panel_height.
	var target_h: float = panel_height * 0.10
	label.pixel_size = target_h / 96.0
	label.font_size = 96
	label.outline_size = 2
	label.modulate = text_color
	label.outline_modulate = Color(0.02, 0.02, 0.02)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.no_depth_test = false
	# Label3D faces -Z by default; rotate so it reads from +Z.
	# Position below the scan window.
	var ly: float = -panel_height * 0.35
	var lz: float = panel_depth * 0.5 + 0.006
	label.position = Vector3(0.0, ly, lz)
	parent.add_child(label)


func _build_podium(parent: Node3D = self) -> void:
	# Vertical box stand rising from origin to PODIUM_HEIGHT.
	var stand := MeshInstance3D.new()
	stand.name = "PodiumStand"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(PODIUM_THICKNESS, PODIUM_HEIGHT, PODIUM_THICKNESS)
	stand.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(panel_color.r * 1.1, panel_color.g * 1.1, panel_color.b * 1.1)
	mat.roughness = 0.4
	mat.metallic = 0.55
	stand.material_override = mat
	stand.position = Vector3(0.0, PODIUM_HEIGHT * 0.5, 0.0)
	parent.add_child(stand)


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


# ── Interaction ───────────────────────────────────────────────────────

# Build the scan-trigger Area3D in front of the scan window. The XR
# Tools hands + controllers each carry physics bodies; entering this
# sphere fires palm_scanned.
func _build_scan_area() -> void:
	if not scan_active:
		return
	var anchor: Node3D = get_node_or_null("Panel")
	if anchor == null:
		anchor = self
	_scan_area = Area3D.new()
	_scan_area.name = "ScanArea"
	# Layer 0 = the scanner doesn't COLLIDE with anything;
	# Mask covers any of the layers XR Tools hands / controllers occupy.
	# Use a permissive mask so it picks up controller bodies (typically
	# layer 16 with XR Tools, but vary by project).
	_scan_area.collision_layer = 0
	_scan_area.collision_mask = 0xFFFFFFFF
	_scan_area.monitoring = true
	_scan_area.monitorable = false

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = scan_radius
	cs.shape = sphere
	# Sit slightly proud of the scan window face (+Z) so the centre
	# of the volume is where a player's palm naturally hovers.
	cs.position = Vector3(0.0, 0.0, panel_depth * 0.5 + scan_radius * 0.5)
	_scan_area.add_child(cs)

	_scan_area.body_entered.connect(_on_scan_body_entered)
	_scan_area.area_entered.connect(_on_scan_area_entered)
	anchor.add_child(_scan_area)

	# Auto-close timer.
	_hold_timer = Timer.new()
	_hold_timer.name = "HoldTimer"
	_hold_timer.one_shot = true
	_hold_timer.wait_time = scan_hold_seconds
	_hold_timer.timeout.connect(_on_hold_timeout)
	add_child(_hold_timer)


# A body entered the volume — usually an XRController3D or a paired
# collision hand. Treat any of them as a successful scan.
func _on_scan_body_entered(_body: Node3D) -> void:
	_trigger_scan()


# Some XR Tools setups expose the hand as Area3D rather than a body
# (e.g. the FunctionPickup proximity area). Treat both equally.
func _on_scan_area_entered(_area: Area3D) -> void:
	_trigger_scan()


func _trigger_scan() -> void:
	if _scanning:
		return
	_scanning = true
	# Flash the scan window brighter and bias the LED green.
	if _scan_window_mat != null:
		_scan_window_mat.emission = scan_color * 1.6
		_scan_window_mat.emission_energy_multiplier = 1.4
	if _status_led_mesh != null:
		var lmat := _status_led_mesh.material_override as StandardMaterial3D
		if lmat != null:
			lmat.albedo_color = scan_color
			lmat.emission = scan_color
			lmat.emission_energy_multiplier = 3.0
	palm_scanned.emit()
	if _hold_timer != null:
		_hold_timer.stop()
		_hold_timer.start(scan_hold_seconds)


func _on_hold_timeout() -> void:
	_scanning = false
	# Return to resting state — emerald glow at default energy.
	if _scan_window_mat != null:
		_scan_window_mat.emission = scan_color
		_scan_window_mat.emission_energy_multiplier = 0.9
	if _status_led_mesh != null:
		var lmat := _status_led_mesh.material_override as StandardMaterial3D
		if lmat != null:
			lmat.albedo_color = scan_color
			lmat.emission = scan_color
			lmat.emission_energy_multiplier = 1.5
	palm_released.emit()


# Search the scene tree for a LabDoorSensor (registered in the group
# "lab_door_sensors") and connect palm_scanned/released to its open /
# close methods. The group registration is done by lab_door_sensor.gd's
# _ready(), so this call_deferred sequence reliably finds the handler.
func _auto_connect_to_door() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var sensors: Array = tree.get_nodes_in_group("lab_door_sensors")
	if sensors.is_empty():
		return
	# Pick the closest one (single-lab maps will have exactly one).
	var nearest: Node = sensors[0]
	if sensors.size() > 1:
		var best_d: float = INF
		for s in sensors:
			if s is Node3D and self is Node3D:
				var d: float = s.global_position.distance_to(global_position)
				if d < best_d:
					best_d = d
					nearest = s
	if nearest.has_method("_open_door") and not palm_scanned.is_connected(nearest._open_door):
		palm_scanned.connect(nearest._open_door)
	if nearest.has_method("_close_door") and not palm_released.is_connected(nearest._close_door):
		palm_released.connect(nearest._close_door)
