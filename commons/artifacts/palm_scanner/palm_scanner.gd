extends Node3D
class_name PalmScanner

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall-mounted (or podium-mounted) biometric palm reader — Portal 2 / Aperture vocabulary for "you are recognised here, or you are not". A dark plastic rectangular panel, an inset scan window with a faint hand outline (palm disc + four finger boxes), a small status LED in the corner, a Portal-orange accent strip across the top, and a PLACE HAND Label3D beneath the scan window. When active, the scan window and outline glow emerald; when inactive, the window goes dark and the status LED glows red.
# desire: the scanner wants to be the room's THRESHOLD — the question "are you on the list?" made architectural. A door asks you to push; a scanner asks you to PROVE. It wants palms specifically: a palm is asymmetric, irreproducible, distinctly yours. The scanner converts identity into permission.
# critical_parameter: scan_active — true reads as "the system is listening, present your hand" (emerald glow, green LED), false reads as "this entry is locked, do not bother" (dark panel, red LED). Same hardware, the entire room's posture flips.
# triggers: _ready() builds panel + scan window + hand outline + status LED + accent strip + label + optional podium stand from exports; apply_grid_config rebuilds
# emerges: scan_active=true + mounting=wall = "checkpoint at the door"; scan_active=false = "this corridor is closed"; mounting=podium = "free-standing checkpoint, mid-room", the scanner asks for the hand in open air rather than against the wall
# needs: rectangular dark panel [present]; inset scan window with emissive material [present]; hand outline (palm disc + 4 finger boxes) [present]; corner status LED with red/green state [present]; Portal-orange accent stripe [present]; PLACE HAND baked-text quad (unshaded, glows with scan colour) [present]; optional vertical podium stand [present]
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
## Seconds the hand must dwell on the plate before access is granted — the
## "scanning" beat that makes the read legible (like the gadget hand scanner).
@export var scan_dwell: float = 0.8
## Play a procedural two-tone chime when access is granted.
@export var play_chime: bool = true
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
## Forward tilt of the scan plate (degrees, around local X). Positive
## values rake the face upward so a downward palm settles naturally.
const PLATE_TILT_DEG: float = 28.0
## Pose path used by HandPoseArea — the open-hand pose that reads as
## "palm flat" while the player is scanning.
const POSE_LEFT_PATH: String  = "res://addons/godot-xr-tools/hands/poses/pose_default_left.tres"
const POSE_RIGHT_PATH: String = "res://addons/godot-xr-tools/hands/poses/pose_default_right.tres"
const HAND_POSE_AREA_SCENE: String = "res://addons/godot-xr-tools/objects/hand_pose_area.tscn"
## Rack-aesthetic materials shared with the interactables in
## res://commons/interactables — using the same palette keeps the
## scanner reading as "lab kit" rather than a one-off prop.
const RACK_METAL_PATH: String       = "res://commons/interactables/materials/rack_metal.tres"
const RACK_PANEL_PATH: String       = "res://commons/interactables/materials/rack_panel.tres"
const RACK_PANEL_DARK_PATH: String  = "res://commons/interactables/materials/rack_panel_dark.tres"
const RACK_ACCENT_PATH: String      = "res://commons/interactables/materials/rack_accent.tres"

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _scan_area: Area3D = null
var _hold_timer: Timer = null
var _status_led_mesh: MeshInstance3D = null
var _scan_window_mat: StandardMaterial3D = null
var _scanning: bool = false

# Scan state machine (mirrors the gadget hand_scanner: IDLE -> SCANNING ->
# GRANTED) so the feedback reads clearly: amber sweep while scanning, then a
# green flash + chime + open door on grant.
enum ScanState { IDLE, SCANNING, GRANTED }
var _state: int = ScanState.IDLE
var _dwell: float = 0.0
var _anim_phase: float = 0.0
var _sweep_mesh: MeshInstance3D = null
var _sweep_mat: StandardMaterial3D = null
var _audio: AudioStreamPlayer3D = null
var _prompt_label: MeshInstance3D = null   # baked-text quad — replaces Label3D
var _prompt_label_parent: Node3D = null    # Panel root; used by _update_prompt_label
var _prompt_label_pos: Vector3 = Vector3.ZERO
var _prompt_label_size: Vector2 = Vector2.ZERO

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
		# _clear_built_children() just freed the ScanArea + hold timer that
		# _ready() created — drop the dangling refs and reset detection state.
		_scan_area = null
		_hold_timer = null
		_scanning = false
		_audio = null
		_sweep_mesh = null
		_sweep_mat = null
		_state = ScanState.IDLE
		_dwell = 0.0
		_absent_time = 999.0
		_build_scanner()
		# CRITICAL: rebuild the detection volume too. Without this, a config
		# applied AFTER _ready (which is exactly how lab_loader delivers
		# scan_active / mounting — via a deferred apply_grid_config) wipes the
		# ScanArea built in _ready and never recreates it, leaving an
		# active-looking scanner that can never detect a hand. This was the
		# reason the palm scanner "did nothing" in the lab.
		if not Engine.is_editor_hint():
			_build_scan_area()
			if auto_connect_door:
				call_deferred("_auto_connect_to_door")


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
	# Detach IMMEDIATELY (remove_child), not just queue_free. queue_free
	# defers to end-of-frame, so a rebuild running in the same frame would
	# still see these dying nodes: get_node_or_null("Panel") would return the
	# old, about-to-be-freed Panel, the new ScanArea would be parented under
	# it, and it would be freed at end of frame — an active-looking scanner
	# with no detection volume. Removing first guarantees the rebuild binds
	# to the freshly-created Panel.
	for c in get_children():
		remove_child(c)
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_scanner() -> void:
	_built = true
	# Panel origin offset depends on mounting: in podium mode, lift the
	# panel up so its center sits at PODIUM_HEIGHT + panel_height/2.
	var panel_center := Vector3.ZERO
	var tilt_rad: float = 0.0
	if mounting == "podium":
		_build_podium()
		var podium_top: float = PODIUM_HEIGHT
		# Pull the plate slightly forward of the stand so the wedge angles
		# out over the player's approach instead of sitting flush atop a
		# vertical column. Lowers the centre by a touch so the rim sits at
		# ~elbow height — easier reach in VR.
		panel_center = Vector3(
			0.0,
			podium_top + panel_height * 0.40,
			panel_depth * 0.5 + 0.01)
		# Rake the plate up so a flat palm laid downward kisses the face
		# squarely instead of having to twist the wrist.
		tilt_rad = -deg_to_rad(PLATE_TILT_DEG)

	var panel_root := Node3D.new()
	panel_root.name = "Panel"
	panel_root.position = panel_center
	panel_root.rotation = Vector3(tilt_rad, 0.0, 0.0)
	add_child(panel_root)

	_build_panel_body(panel_root)
	_build_scan_window(panel_root)
	_build_hand_outline(panel_root)
	_build_status_led(panel_root)
	_build_accent_strip(panel_root)
	_build_label(panel_root)
	_build_hand_pose_area(panel_root)


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

	# Scan sweep bar — a bright line that travels down the window face while
	# scanning (the "being read" cue, like the gadget-wall hand scanner).
	var sweep := MeshInstance3D.new()
	sweep.name = "ScanSweep"
	var sweep_w: float = panel_width * SCAN_INSET_FACTOR * 0.96
	var swm := BoxMesh.new()
	swm.size = Vector3(sweep_w, 0.012, 0.004)
	sweep.mesh = swm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1, 1, 1)
	smat.emission_enabled = true
	smat.emission = Color(1, 1, 1)
	smat.emission_energy_multiplier = 3.0
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sweep.material_override = smat
	sweep.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sweep.position = Vector3(0.0, y_offset, panel_depth * 0.5 + SCAN_DEPTH + 0.004)
	sweep.visible = false
	parent.add_child(sweep)
	_sweep_mesh = sweep
	_sweep_mat = smat


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
	# Sizing: width spans ~90% of the panel, height is ~10% of panel height.
	# Matches the old Label3D footprint: target_h = panel_height * 0.10,
	# pixel_size = target_h / 96 → the visible quad was ≈ panel_width×0.10.
	var w: float = panel_width * 0.90
	var h: float = panel_height * 0.10 * 1.3   # 1.3 so descenders don't clip
	var ly: float = -panel_height * 0.35
	var lz: float = panel_depth * 0.5 + 0.006
	# Store context so _update_prompt_label can swap the mesh at runtime.
	_prompt_label_parent = parent
	_prompt_label_pos    = Vector3(0.0, ly, lz)
	_prompt_label_size   = Vector2(w, h)
	# Build the initial quad — glowing with text_color (unshaded = true so
	# the letters read as emissive, matching the scan-window aesthetic).
	var mesh: MeshInstance3D = BakedText.make_label_mesh(
			label_text, text_color, _prompt_label_size, 1400, true)
	if mesh == null:
		return
	mesh.name = "Label"
	mesh.position = _prompt_label_pos
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	_prompt_label = mesh


## Swap out the baked-text quad for new text/colour (called by the scan
## state machine in place of the old _prompt_label.text / .modulate writes).
func _update_prompt_label(new_text: String, new_color: Color) -> void:
	if _prompt_label_parent == null:
		return
	# Remove the old mesh.
	if _prompt_label != null and is_instance_valid(_prompt_label):
		_prompt_label_parent.remove_child(_prompt_label)
		_prompt_label.queue_free()
		_prompt_label = null
	if new_text.is_empty():
		return
	var mesh: MeshInstance3D = BakedText.make_label_mesh(
			new_text, new_color, _prompt_label_size, 1400, true)
	if mesh == null:
		return
	mesh.name = "Label"
	mesh.position = _prompt_label_pos
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prompt_label_parent.add_child(mesh)
	_prompt_label = mesh


func _build_podium(parent: Node3D = self) -> void:
	# Three-piece stand in the rack-interactables vocabulary:
	#   1. A wide, low base plinth (rack_metal)        — visual weight on the floor
	#   2. A slim vertical neck (rack_panel)           — the "column"
	#   3. A chamfered top yoke (rack_panel_dark)      — collar the plate sits on
	#   4. A glowing cyan rack_accent ring at the seam — matches the door rails
	var metal_mat: Material   = _try_load_material(RACK_METAL_PATH)
	var panel_mat: Material   = _try_load_material(RACK_PANEL_PATH)
	var dark_mat: Material    = _try_load_material(RACK_PANEL_DARK_PATH)
	var accent_mat: Material  = _try_load_material(RACK_ACCENT_PATH)

	# 1. Base plinth — wide, short, machined block.
	var base := MeshInstance3D.new()
	base.name = "PodiumBase"
	var base_mesh := BoxMesh.new()
	var base_w: float = PODIUM_THICKNESS * 4.0
	var base_h: float = 0.05
	base_mesh.size = Vector3(base_w, base_h, base_w * 0.9)
	base.mesh = base_mesh
	base.material_override = metal_mat
	base.position = Vector3(0.0, base_h * 0.5, 0.0)
	parent.add_child(base)

	# 2. Neck — slim column the panel sits on.
	var neck := MeshInstance3D.new()
	neck.name = "PodiumNeck"
	var neck_mesh := BoxMesh.new()
	var neck_h: float = PODIUM_HEIGHT - base_h - 0.04
	neck_mesh.size = Vector3(PODIUM_THICKNESS, neck_h, PODIUM_THICKNESS * 0.85)
	neck.mesh = neck_mesh
	neck.material_override = panel_mat
	neck.position = Vector3(0.0, base_h + neck_h * 0.5, 0.0)
	parent.add_child(neck)

	# 3. Yoke / collar — chamfered shelf the plate angles out from.
	var yoke := MeshInstance3D.new()
	yoke.name = "PodiumYoke"
	var yoke_mesh := BoxMesh.new()
	var yoke_h: float = 0.04
	var yoke_w: float = panel_width * 1.05
	var yoke_d: float = PODIUM_THICKNESS * 1.4
	yoke_mesh.size = Vector3(yoke_w, yoke_h, yoke_d)
	yoke.mesh = yoke_mesh
	yoke.material_override = dark_mat
	yoke.position = Vector3(0.0, PODIUM_HEIGHT - yoke_h * 0.5, 0.0)
	parent.add_child(yoke)

	# 4. Cyan accent line at the yoke-front — the running-light cue, same
	# emission colour as the door rails so the scanner reads as paired
	# hardware.
	var seam := MeshInstance3D.new()
	seam.name = "PodiumAccent"
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(yoke_w * 0.78, 0.006, 0.008)
	seam.mesh = seam_mesh
	seam.material_override = accent_mat
	seam.position = Vector3(
		0.0,
		PODIUM_HEIGHT - yoke_h - 0.002,
		yoke_d * 0.5 - 0.006)
	parent.add_child(seam)


func _build_hand_pose_area(parent: Node3D) -> void:
	# Adds the XR Tools HandPoseArea so the hand visually opens to "palm
	# flat" whenever it sits above the scan window — same pattern as
	# push_button, lever, knob etc. Avoids the curled-fist grab pose that
	# otherwise reads as "I'm gripping the wall".
	if Engine.is_editor_hint():
		return
	var pose_scene: PackedScene = load(HAND_POSE_AREA_SCENE) as PackedScene
	if pose_scene == null:
		return
	var area: Node = pose_scene.instantiate()
	if area == null:
		return
	area.name = "HandPoseArea"
	var pose_left = load(POSE_LEFT_PATH)
	var pose_right = load(POSE_RIGHT_PATH)
	if pose_left != null:
		area.set("left_pose", pose_left)
	if pose_right != null:
		area.set("right_pose", pose_right)
	# Cover the same volume as the scan trigger so any hand that crosses
	# the scan sphere also flattens.
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = scan_radius * 1.05
	cs.shape = sphere
	cs.position = Vector3(0.0, 0.0, panel_depth * 0.5 + scan_radius * 0.6)
	area.add_child(cs)
	parent.add_child(area)


func _try_load_material(path: String) -> Material:
	var res := load(path)
	if res is Material:
		return res
	# Fallback to a colour so the artifact still renders if the rack
	# materials ever go missing.
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.18, 0.20, 0.23)
	fallback.metallic = 0.45
	fallback.roughness = 0.4
	return fallback


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

# Build the scan trigger as a DIRECT Area3D in front of the scan
# window. This is the same proven pattern as hand_scanner / push_button:
# an Area3D whose collision_mask is the player-hand layers (18 Player
# Hands + 19 Grab Handles = 393216), no monitorable/collision layer of
# its own. A hand body or hand-area crossing the volume fires the scan.
#
# Earlier this borrowed push_button.tscn and read its inner
# InteractableAreaButton, but scaling + hiding that scene left the
# sensing volume offset from where the hand actually goes, so "place
# hand" did nothing. A direct Area3D sized to the scan window removes
# that whole fragile chain.
const HAND_LAYER_MASK := 393216  # bits 18 (Player Hands) + 19 (Grab Handles)

func _build_scan_area() -> void:
	if not scan_active:
		return
	var anchor: Node3D = get_node_or_null("Panel")
	if anchor == null:
		anchor = self

	var area := Area3D.new()
	area.name = "ScanArea"
	area.collision_layer = 0
	area.collision_mask = HAND_LAYER_MASK
	area.monitoring = true
	area.monitorable = false

	# A box volume sitting just in front of the (tilted) scan window so a
	# palm presented to the plate registers. Sized generously to the scan
	# window + scan_radius depth so the hand needn't hit an exact pixel.
	var win_w: float = panel_width * SCAN_INSET_FACTOR
	var win_h: float = panel_height * SCAN_HEIGHT_FACTOR
	var depth: float = max(scan_radius, 0.12)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(win_w * 1.4, win_h * 1.4, depth)
	cs.shape = box
	var window_face_z: float = panel_depth * 0.5 + SCAN_DEPTH + 0.001
	var window_y: float = panel_height * 0.06
	# Centre the volume out in front of the plate by half its depth so it
	# straddles the face and the approaching hand.
	cs.position = Vector3(0.0, window_y, window_face_z + depth * 0.5)
	area.add_child(cs)
	anchor.add_child(area)
	_scan_area = area

	# NOTE: detection is frame-SAMPLED in _physics_process (see _hand_present),
	# not driven by enter/exit signals. In real VR the hand collider flickers
	# in and out of the volume every few frames; counting those events kept
	# resetting the dwell so the door never opened. We keep monitoring on so
	# get_overlapping_bodies/areas() works, but read it every frame instead.

	# Auto-close timer.
	_hold_timer = Timer.new()
	_hold_timer.name = "HoldTimer"
	_hold_timer.one_shot = true
	_hold_timer.wait_time = scan_hold_seconds
	_hold_timer.timeout.connect(_on_hold_timeout)
	add_child(_hold_timer)

	# Procedural "access granted" chime.
	if play_chime and _audio == null:
		_audio = AudioStreamPlayer3D.new()
		_audio.name = "Chime"
		_audio.volume_db = -10.0
		_audio.max_distance = 10.0
		_audio.stream = _build_chime()
		add_child(_audio)


# ── Hand presence detection (frame-sampled, NOT event-counted) ────────
# Earlier versions counted Area3D enter/exit signals, but in real VR the
# hand collider flickers in and out of the volume every few frames, which
# kept resetting the dwell so access was never granted and the DOOR NEVER
# MOVED. Instead we SAMPLE presence every physics frame from three sources
# at once (controller proximity + body overlaps + area overlaps) and smooth
# brief dropouts with a short grace window — robust against layer quirks,
# tracking jitter, and hand-collider flicker.
const POLL_REACH_PAD := 0.12     # controller ~= wrist; pad the box for reach
const PRESENCE_GRACE := 0.30     # seconds of "lost" hand tolerated before reset

var _controllers: Array = []
var _ctrl_search_frames: int = 0
var _absent_time: float = 999.0  # seconds since the hand was last seen


func _physics_process(dt: float) -> void:
	if not scan_active or _scan_area == null:
		return
	# Re-discover controllers for the first ~10 s in case the player rig
	# spawns after the scanner (map load order).
	if _controllers.is_empty() and _ctrl_search_frames < 600:
		_ctrl_search_frames += 1
		if _ctrl_search_frames % 20 == 0:
			_find_controllers()

	# Sample presence from every available source, smoothed by a grace window
	# so a one-frame dropout doesn't abort an in-progress scan.
	if _hand_present():
		_absent_time = 0.0
	else:
		_absent_time += dt
	var present: bool = _absent_time < PRESENCE_GRACE

	_anim_phase += dt
	match _state:
		ScanState.IDLE:
			if present:
				_begin_scan()
		ScanState.SCANNING:
			if not present:
				_set_idle()
			else:
				_dwell += dt
				# Slide the sweep bar down the window face.
				if _sweep_mesh != null:
					var u: float = clamp(_dwell / max(0.05, scan_dwell), 0.0, 1.0)
					var travel: float = panel_height * SCAN_HEIGHT_FACTOR * 0.5
					_sweep_mesh.position.y = panel_height * 0.06 + lerp(travel, -travel, u)
				if _dwell >= scan_dwell:
					_grant_access()
		ScanState.GRANTED:
			# Pulse the granted window.
			if _scan_window_mat != null:
				_scan_window_mat.emission_energy_multiplier = 1.8 + 0.5 * sin(_anim_phase * 8.0)
			# Keep the door open while the hand stays; once it leaves, run the
			# hold-timer countdown to close it.
			if _hold_timer != null:
				if present:
					_hold_timer.stop()
				elif _hold_timer.is_stopped():
					_hold_timer.start(scan_hold_seconds)


# TRUE if a hand is in the scan volume by ANY measure: a tracked controller
# inside the box (layer-independent), or a body / area overlapping on the
# hand mask. Sampling all three each frame is what makes detection reliable.
func _hand_present() -> bool:
	if _controller_in_box():
		return true
	if _scan_area != null:
		if _scan_area.get_overlapping_bodies().size() > 0:
			return true
		if _scan_area.get_overlapping_areas().size() > 0:
			return true
	return false


func _find_controllers() -> void:
	_controllers.clear()
	var vp := get_viewport()
	if vp != null:
		_collect_controllers(vp)


func _collect_controllers(n: Node) -> void:
	if n is XRController3D:
		_controllers.append(n)
	for c in n.get_children():
		_collect_controllers(c)


func _controller_in_box() -> bool:
	var cs: CollisionShape3D = null
	for c in _scan_area.get_children():
		if c is CollisionShape3D:
			cs = c
			break
	if cs == null or not (cs.shape is BoxShape3D):
		return false
	var half: Vector3 = (cs.shape as BoxShape3D).size * 0.5 + Vector3(POLL_REACH_PAD, POLL_REACH_PAD, POLL_REACH_PAD)
	var inv := cs.global_transform.affine_inverse()
	for ctrl in _controllers:
		if not is_instance_valid(ctrl):
			continue
		var lp: Vector3 = inv * (ctrl as Node3D).global_position
		if absf(lp.x) <= half.x and absf(lp.y) <= half.y and absf(lp.z) <= half.z:
			return true
	return false


# Begin the "scanning" phase — amber wash, sweep bar visible, label reads
# SCANNING. The dwell is accumulated in _physics_process; when it reaches
# scan_dwell, _grant_access() fires.
func _begin_scan() -> void:
	_state = ScanState.SCANNING
	_dwell = 0.0
	if _sweep_mesh != null:
		_sweep_mesh.visible = true
	var amber := Color(1.0, 0.78, 0.18)
	if _scan_window_mat != null:
		_scan_window_mat.emission = amber
		_scan_window_mat.emission_energy_multiplier = 1.4
	_set_led(amber, 3.0)
	_update_prompt_label("SCANNING...", amber)


# Access granted — bright green flash, chime, haptic, door opens. Holds for
# scan_hold_seconds, then _on_hold_timeout() closes + resets to idle.
func _grant_access() -> void:
	_state = ScanState.GRANTED
	_scanning = true
	if _sweep_mesh != null:
		_sweep_mesh.visible = false
	if _scan_window_mat != null:
		_scan_window_mat.emission = scan_color * 1.8
		_scan_window_mat.emission_energy_multiplier = 2.2
	_set_led(scan_color, 4.0)
	_update_prompt_label("ACCESS GRANTED", scan_color)
	if _audio != null:
		_audio.play()
	_pulse_haptic()
	palm_scanned.emit()
	if _hold_timer != null:
		_hold_timer.stop()
		_hold_timer.start(scan_hold_seconds)


# Return to the resting "PLACE HAND" state — emerald glow, green LED.
func _set_idle() -> void:
	_state = ScanState.IDLE
	_dwell = 0.0
	_scanning = false
	if _sweep_mesh != null:
		_sweep_mesh.visible = false
	if _scan_window_mat != null:
		_scan_window_mat.emission = scan_color
		_scan_window_mat.emission_energy_multiplier = 0.9
	_set_led(scan_color, 1.5)
	_update_prompt_label(label_text, text_color)


func _set_led(c: Color, energy: float) -> void:
	if _status_led_mesh == null:
		return
	var lmat := _status_led_mesh.material_override as StandardMaterial3D
	if lmat != null:
		lmat.albedo_color = c
		lmat.emission = c
		lmat.emission_energy_multiplier = energy


func _on_hold_timeout() -> void:
	# Access window expired — close the door and reset to the resting state.
	_set_idle()
	palm_released.emit()


# Two-tone rising "access granted" chime, generated procedurally so the
# artifact needs no audio asset (mirrors the gadget-wall hand scanner).
func _build_chime() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var dur := 0.22
	var n := int(stream.mix_rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / stream.mix_rate
		var prog := float(i) / float(max(1, n - 1))
		var f := 660.0 if prog < 0.5 else 990.0
		var env := exp(-prog * 4.0) * (1.0 - prog * 0.3)
		var s := sin(TAU * f * tt) * env * 0.30
		var si := int(clamp(s, -1.0, 1.0) * 32767.0)
		data[2 * i] = si & 0xFF
		data[2 * i + 1] = (si >> 8) & 0xFF
	stream.data = data
	return stream


func _pulse_haptic() -> void:
	# Best-effort short rumble on tracked controllers (safe no-op if the rig
	# has none / handles haptics elsewhere).
	for ctrl in _controllers:
		if is_instance_valid(ctrl) and ctrl.has_method("trigger_haptic_pulse"):
			ctrl.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.08, 0.0)


# Search the scene tree for a LabDoorSensor (registered in the group
# "lab_door_sensors") and connect palm_scanned/released to its open /
# close methods. The group registration is done by lab_door_sensor.gd's
# _ready(), so this call_deferred sequence reliably finds the handler.
func _auto_connect_to_door() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var sensors: Array = tree.get_nodes_in_group("lab_door_sensors")
	# The door sensor may register its group a few frames after us (build
	# order, deferred adds, lab_loader instantiation sequence). Poll for a
	# short while before giving up so a late-built door still gets wired.
	var tries: int = 0
	while sensors.is_empty() and tries < 120:
		await tree.process_frame
		tries += 1
		sensors = tree.get_nodes_in_group("lab_door_sensors")
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
