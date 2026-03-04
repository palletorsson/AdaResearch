# control_board.gd
# Black Mesa-style mission control console — procedural meshes with
# interactive VR buttons, sliders, dials and animated CRT screens.
# Layout on XY plane (X = horizontal, Y = vertical, Z = depth toward viewer).
# Matches grid-editor control_board subset orientation.
extends Node3D
class_name ControlBoard

const SLIDER_H = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

# ── Palette ──────────────────────────────────────────────────────────
const COL_PANEL     := Color(0.08, 0.08, 0.10)
const COL_BEZEL     := Color(0.12, 0.12, 0.14)
const COL_SCREEN_BG := Color(0.01, 0.04, 0.01)
const COL_SCREEN_FG := Color(0.15, 0.85, 0.15)
const COL_LED_GREEN := Color(0.1, 1.0, 0.2)
const COL_LED_RED   := Color(1.0, 0.15, 0.1)
const COL_LED_AMBER := Color(1.0, 0.7, 0.1)
const COL_METAL     := Color(0.35, 0.35, 0.38)
const COL_KNOB      := Color(0.25, 0.25, 0.28)
const COL_SPEAKER   := Color(0.18, 0.15, 0.12)

# ── Config ───────────────────────────────────────────────────────────
# All measurements in the XY plane, matching grid-editor cells (0.1m each)
@export var panel_width: float = 2.4   # X extent
@export var panel_height: float = 1.4  # Y extent
@export var panel_depth: float = 0.06  # Z thickness of back plate

# ── State ────────────────────────────────────────────────────────────
var _crt_screens: Array[MeshInstance3D] = []
var _led_indicators: Array[Dictionary] = []
var _vu_needles: Array[MeshInstance3D] = []
var _faders: Array[Node] = []
var _time: float = 0.0

func _ready() -> void:
	_build_back_plate()
	_build_monitors()
	_build_meters()
	_build_fader_bank()
	_build_button_array()
	_build_switch_row()
	_build_knob_cluster()
	_build_speaker()
	_build_led_strip()
	print("[ControlBoard] Built on XY plane — %d CRTs, %d LEDs, %d faders" % [
		_crt_screens.size(), _led_indicators.size(), _faders.size()])

func _process(delta: float) -> void:
	_time += delta
	_animate_screens(delta)
	_animate_vu_meters(delta)
	_animate_leds(delta)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("panel_width"):
		panel_width = float(config_data["panel_width"])
	if config_data.has("panel_height"):
		panel_height = float(config_data["panel_height"])

# ══════════════════════════════════════════════════════════════════════
#  Coordinate helpers — all placement in XY, depth in -Z
# ══════════════════════════════════════════════════════════════════════
# Panel origin is center-bottom. X right, Y up, -Z toward viewer.
# Grid-editor cell (gx, gy) maps to:
#   X = (gx - grid_w/2) * 0.1
#   Y = (grid_h - gy) * 0.1   (grid Y=0 is top row, Godot Y up)

func _xy(x: float, y: float, z: float = 0.0) -> Vector3:
	return Vector3(x, y, z)  # positive z = forward (in front of panel)

# ══════════════════════════════════════════════════════════════════════
#  BACK PLATE — flat XY panel, everything mounts on its front face
# ══════════════════════════════════════════════════════════════════════

func _build_back_plate() -> void:
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(panel_width, panel_height, panel_depth)
	plate.mesh = mesh
	plate.material_override = _mat(COL_PANEL, 0.3, 0.7)
	plate.position = _xy(0, panel_height * 0.5, -panel_depth * 0.5)
	add_child(plate)

	# Side trim rails
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.03, panel_height, panel_depth + 0.02)
		rail.mesh = rm
		rail.material_override = _mat(COL_BEZEL, 0.5, 0.5)
		rail.position = _xy(side * panel_width * 0.5, panel_height * 0.5, -panel_depth * 0.5)
		add_child(rail)

# ══════════════════════════════════════════════════════════════════════
#  MONITORS — CRT screens, top section of panel
# ══════════════════════════════════════════════════════════════════════

func _build_monitors() -> void:
	# Large CRT left — grid ~(1,0) to (6,4)
	_add_crt(_xy(-0.55, 1.15, 0.02), Vector3(0.50, 0.38, 0.08))
	# Large CRT centre — grid ~(7,0) to (12,4)
	_add_crt(_xy(0.10, 1.15, 0.02), Vector3(0.50, 0.38, 0.08))
	# Small CRT right — waveform scope
	_add_crt(_xy(0.70, 1.12, 0.02), Vector3(0.30, 0.25, 0.06))

func _add_crt(pos: Vector3, size: Vector3) -> void:
	# Housing bezel
	var housing := MeshInstance3D.new()
	var hmesh := BoxMesh.new()
	hmesh.size = Vector3(size.x + 0.04, size.y + 0.04, size.z)
	housing.mesh = hmesh
	housing.material_override = _mat(COL_BEZEL, 0.3, 0.8)
	housing.position = pos
	add_child(housing)

	# Screen face — sits on front of housing
	var screen := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = Vector3(size.x - 0.02, size.y - 0.02, 0.005)
	screen.mesh = smesh
	var smat := StandardMaterial3D.new()
	smat.albedo_color = COL_SCREEN_BG
	smat.emission_enabled = true
	smat.emission = COL_SCREEN_FG * 0.3
	smat.emission_energy_multiplier = 0.8
	smat.roughness = 0.2
	screen.material_override = smat
	screen.position = pos + Vector3(0, 0, size.z * 0.5 + 0.003)
	add_child(screen)
	_crt_screens.append(screen)

# ══════════════════════════════════════════════════════════════════════
#  METERS — VU meters, upper-middle band
# ══════════════════════════════════════════════════════════════════════

func _build_meters() -> void:
	for i in 2:
		var x_pos: float = -0.85 + i * 0.22
		_add_vu_meter(_xy(x_pos, 0.82, 0.02))

func _add_vu_meter(pos: Vector3) -> void:
	var face := MeshInstance3D.new()
	var fmesh := BoxMesh.new()
	fmesh.size = Vector3(0.18, 0.10, 0.02)
	face.mesh = fmesh
	face.material_override = _mat(Color(0.9, 0.88, 0.82), 0.0, 0.9)
	face.position = pos
	add_child(face)

	var needle := MeshInstance3D.new()
	var nmesh := BoxMesh.new()
	nmesh.size = Vector3(0.002, 0.06, 0.002)
	needle.mesh = nmesh
	needle.material_override = _mat(Color(0.1, 0.1, 0.1), 0.0, 0.3)
	needle.position = pos + Vector3(0, -0.02, 0.012)
	add_child(needle)
	_vu_needles.append(needle)

# ══════════════════════════════════════════════════════════════════════
#  FADER BANK — 6 vertical sliders, middle band
# ══════════════════════════════════════════════════════════════════════

func _build_fader_bank() -> void:
	for i in 6:
		var slider := SLIDER_H.instantiate()
		slider.name = "Fader%d" % i
		slider.position = _xy(-0.35 + i * 0.1, 0.55, 0.03)
		slider.rotation_degrees.z = 90  # vertical
		slider.scale = Vector3(0.6, 0.6, 0.6)
		add_child(slider)
		slider.set_param_name("CH%d" % (i + 1))
		slider.slider_moved.connect(_on_fader_moved.bind(i))
		_faders.append(slider)

func _on_fader_moved(_pos: Variant, index: int) -> void:
	if index < _faders.size() and _faders[index].has_method("get_normalized_value"):
		var val: float = _faders[index].get_normalized_value()
		if index < _vu_needles.size():
			_vu_needles[index].rotation_degrees.z = lerp(-40.0, 40.0, val)

# ══════════════════════════════════════════════════════════════════════
#  BUTTON ARRAY — colored push buttons, right side
# ══════════════════════════════════════════════════════════════════════

func _build_button_array() -> void:
	var base := _xy(0.55, 0.55, 0.03)
	var button_defs := [
		["ALARM", Color(0.9, 0.15, 0.1)],
		["ACK", Color(0.1, 0.8, 0.2)],
		["TEST", Color(0.2, 0.4, 0.9)],
		["RESET", Color(0.9, 0.7, 0.1)],
		["LOCK", Color(0.6, 0.6, 0.6)],
		["AUX", Color(0.7, 0.3, 0.8)],
	]
	for i in button_defs.size():
		var row: int = i / 3
		var col: int = i % 3
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "Btn_%s" % button_defs[i][0]
		btn.position = base + Vector3(col * 0.08, -row * 0.08, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		btn.pressed_color = button_defs[i][1]
		btn.released_color = button_defs[i][1].darkened(0.5)
		add_child(btn)
		_add_label(btn, button_defs[i][0])
		var area := btn.get_node_or_null("InteractableAreaButton")
		if area:
			var idx := i
			area.button_pressed.connect(func(_b): _on_board_button(idx))

func _on_board_button(index: int) -> void:
	if index < _led_indicators.size():
		var led: Dictionary = _led_indicators[index]
		led["state"] = not led["state"]
		_set_led_color(led)
	print("[ControlBoard] Button %d pressed" % index)

# ══════════════════════════════════════════════════════════════════════
#  SWITCH ROW — toggle switches, lower-left
# ══════════════════════════════════════════════════════════════════════

func _build_switch_row() -> void:
	var base := _xy(-0.90, 0.30, 0.02)
	for i in 8:
		# Switch base plate
		var sw_base := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 0.025, 0.015)
		sw_base.mesh = bm
		sw_base.material_override = _mat(COL_METAL, 0.7, 0.3)
		sw_base.position = base + Vector3(i * 0.055, 0, 0)
		add_child(sw_base)

		# Toggle lever
		var lever := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.003
		lm.bottom_radius = 0.004
		lm.height = 0.03
		lever.mesh = lm
		lever.material_override = _mat(COL_METAL, 0.8, 0.2)
		var up := (i % 2 == 0)
		var tip_y: float = 0.015 if up else -0.005
		lever.position = sw_base.position + Vector3(0, tip_y, 0.01)
		lever.rotation_degrees.x = 15.0 if up else -15.0
		add_child(lever)

# ══════════════════════════════════════════════════════════════════════
#  KNOB CLUSTER — rotary dials, right side
# ══════════════════════════════════════════════════════════════════════

func _build_knob_cluster() -> void:
	var base := _xy(0.80, 0.82, 0.02)
	var labels := ["FREQ", "GAIN", "BIAS", "TRIM"]
	for i in labels.size():
		var row: int = i / 2
		var col: int = i % 2
		var pos := base + Vector3(col * 0.12, -row * 0.12, 0)
		_add_knob(pos, labels[i], 0.03)

func _add_knob(pos: Vector3, label_text: String, radius: float) -> void:
	var knob := MeshInstance3D.new()
	var km := CylinderMesh.new()
	km.top_radius = radius
	km.bottom_radius = radius * 1.1
	km.height = 0.015
	km.radial_segments = 16
	knob.mesh = km
	knob.material_override = _mat(COL_KNOB, 0.5, 0.4)
	knob.position = pos
	knob.rotation_degrees.x = -90  # Cylinder faces +Z (toward viewer)
	add_child(knob)

	# Pointer line on face
	var ptr := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.002, radius * 0.8, 0.002)
	ptr.mesh = pm
	ptr.material_override = _mat(Color.WHITE, 0.0, 0.5)
	ptr.position = pos + Vector3(0, 0, 0.009)
	ptr.rotation_degrees.z = randf_range(-120, 120)
	add_child(ptr)

	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.pixel_size = 0.0006
	lbl.font_size = 8
	lbl.modulate = Color(0.7, 0.7, 0.7)
	lbl.position = pos + Vector3(0, -0.04, 0.01)
	add_child(lbl)

# ══════════════════════════════════════════════════════════════════════
#  SPEAKER — right side, upper area
# ══════════════════════════════════════════════════════════════════════

func _build_speaker() -> void:
	var housing := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.25, 0.25, 0.08)
	housing.mesh = hm
	housing.material_override = _mat(COL_SPEAKER, 0.2, 0.8)
	housing.position = _xy(0.90, 0.30, 0.02)
	add_child(housing)

	# Speaker cone — faces -Z
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.09
	cm.height = 0.03
	cm.radial_segments = 24
	cone.mesh = cm
	cone.material_override = _mat(Color(0.15, 0.15, 0.15), 0.1, 0.6)
	cone.position = housing.position + Vector3(0, 0, 0.04)
	cone.rotation_degrees.x = -90  # Face forward (+Z)
	add_child(cone)

	# Grille
	var grille := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.22, 0.22, 0.005)
	grille.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.2, 0.2, 0.2, 0.4)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.metallic = 0.6
	gmat.roughness = 0.3
	grille.material_override = gmat
	grille.position = housing.position + Vector3(0, 0, 0.045)
	add_child(grille)

# ══════════════════════════════════════════════════════════════════════
#  LED STRIP — bottom band
# ══════════════════════════════════════════════════════════════════════

func _build_led_strip() -> void:
	var base := _xy(-0.50, 0.10, 0.02)
	var led_colors := [
		COL_LED_GREEN, COL_LED_GREEN, COL_LED_RED,
		COL_LED_AMBER, COL_LED_GREEN, COL_LED_RED,
		COL_LED_GREEN, COL_LED_AMBER,
	]
	for i in led_colors.size():
		var led := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.008
		lm.height = 0.016
		led.mesh = lm
		var on_color: Color = led_colors[i]
		var off_color: Color = on_color.darkened(0.7)
		var initially_on: bool = (i % 3 != 2)

		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = on_color if initially_on else off_color
		mat.emission_energy_multiplier = 2.0 if initially_on else 0.3
		mat.albedo_color = on_color.darkened(0.3)
		mat.roughness = 0.3
		led.material_override = mat

		led.position = base + Vector3(i * 0.04, 0, 0)
		add_child(led)

		_led_indicators.append({
			"mesh": led,
			"color_on": on_color,
			"color_off": off_color,
			"state": initially_on,
		})

# ══════════════════════════════════════════════════════════════════════
#  ANIMATION
# ══════════════════════════════════════════════════════════════════════

func _animate_screens(_delta: float) -> void:
	for screen in _crt_screens:
		if not is_instance_valid(screen):
			continue
		var mat: StandardMaterial3D = screen.material_override
		if mat:
			var flicker: float = 0.7 + sin(_time * 30.0) * 0.05 + sin(_time * 7.3) * 0.1
			mat.emission = COL_SCREEN_FG * flicker * 0.4
			mat.emission_energy_multiplier = 0.6 + sin(_time * 2.1) * 0.2

func _animate_vu_meters(_delta: float) -> void:
	for i in _vu_needles.size():
		if not is_instance_valid(_vu_needles[i]):
			continue
		var signal_val: float = abs(sin(_time * (2.0 + i * 0.7))) * 0.6 + sin(_time * 13.0) * 0.15
		signal_val = clampf(signal_val, 0.0, 1.0)
		_vu_needles[i].rotation_degrees.z = lerp(-35.0, 35.0, signal_val)

func _animate_leds(_delta: float) -> void:
	for i in _led_indicators.size():
		var led: Dictionary = _led_indicators[i]
		if i % 3 == 0 and fmod(_time + i * 0.7, 2.0) < 0.1:
			led["state"] = not led["state"]
			_set_led_color(led)

func _set_led_color(led: Dictionary) -> void:
	var mesh: MeshInstance3D = led["mesh"]
	if not is_instance_valid(mesh):
		return
	var mat: StandardMaterial3D = mesh.material_override
	if mat:
		var on: bool = led["state"]
		mat.emission = led["color_on"] if on else led["color_off"]
		mat.emission_energy_multiplier = 2.0 if on else 0.3

# ══════════════════════════════════════════════════════════════════════
#  UTILITIES
# ══════════════════════════════════════════════════════════════════════

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _add_label(parent: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	parent.add_child(lbl)
