# control_board_element_factory.gd
# Stateless factory that produces 3D Node3D subtrees for each Control Board
# element type. Each builder returns a Node3D whose origin is at center,
# sized to fit within (w * cell_size) x (h * cell_size) meters, facing +Z.
#
# Children use standardized names for animation:
#   "Screen"      — CRT emissive face
#   "Needle"      — VU/gauge needle (rotate Z)
#   "SweepLine"   — radar sweep arm (rotate Z)
#   "StatusLabel"  — cycling text
#   "Bulb"        — LED sphere
#   "Interactable" — the .tscn instance (button/slider/dial)
#   "LED_0"..."LED_7" — LED bar segments
extends RefCounted
class_name ControlBoardElementFactory

const PUSH_BUTTON  = preload("res://commons/interactables/push_button.tscn")
const SLIDER_H     = preload("res://commons/interactables/slider_horizontal.tscn")

# ── Palette (from control_board.gd) ─────────────────────────────────
const COL_BEZEL     := Color(0.12, 0.12, 0.14)
const COL_SCREEN_BG := Color(0.01, 0.04, 0.01)
const COL_SCREEN_FG := Color(0.15, 0.85, 0.15)
const COL_LED_GREEN := Color(0.1, 1.0, 0.2)
const COL_LED_RED   := Color(1.0, 0.15, 0.1)
const COL_LED_AMBER := Color(1.0, 0.7, 0.1)
const COL_METAL     := Color(0.35, 0.35, 0.38)
const COL_KNOB      := Color(0.25, 0.25, 0.28)
const COL_SPEAKER   := Color(0.18, 0.15, 0.12)

const PAD := 0.003  # Padding from cell edges

# ── Element type classification ──────────────────────────────────────
const INTERACTIVE := [
	"btn_red", "btn_green", "btn_blue", "btn_yellow", "btn_square",
	"emergency_stop", "toggle_switch", "rocker_switch", "key_switch",
	"knob_large", "knob_small", "dial_selector",
	"fader_v", "fader_h", "lever",
]
const ANIMATED := [
	"crt_large", "crt_small", "waveform_display", "radar_display",
	"status_panel", "vu_meter", "gauge_round", "led_bar_v",
	"led_green", "led_red", "led_amber", "warning_light",
]

# ═════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═════════════════════════════════════════════════════════════════════

static func build_element_3d(element_id: String, cell_size: float) -> Node3D:
	var CBS = load("res://commons/artifacts/grid_editor_board/control_board_subset.gd")
	var el: Dictionary = CBS.get_element(element_id)
	if el.is_empty():
		return null
	var w: int = int(el["w"])
	var h: int = int(el["h"])
	var sx: float = w * cell_size
	var sy: float = h * cell_size

	match element_id:
		# Monitors
		"crt_large", "crt_small":
			return _build_crt(sx, sy, COL_SCREEN_FG)
		"waveform_display":
			return _build_crt(sx, sy, Color(0.1, 0.4, 0.9))
		"radar_display":
			return _build_radar(sx, sy)
		"status_panel":
			return _build_status_panel(sx, sy)
		# Meters
		"vu_meter":
			return _build_vu_meter(sx, sy)
		"gauge_round":
			return _build_gauge_round(sx, sy)
		"led_bar_v":
			return _build_led_bar_v(sx, sy)
		# Buttons
		"btn_red":
			return _build_push_button(sx, sy, Color(0.9, 0.15, 0.1))
		"btn_green":
			return _build_push_button(sx, sy, Color(0.1, 0.8, 0.2))
		"btn_blue":
			return _build_push_button(sx, sy, Color(0.2, 0.4, 0.9))
		"btn_yellow":
			return _build_push_button(sx, sy, Color(0.9, 0.7, 0.1))
		"btn_square":
			return _build_push_button(sx, sy, Color(0.6, 0.6, 0.6))
		"emergency_stop":
			return _build_emergency_stop(sx, sy)
		# Switches
		"toggle_switch":
			return _build_toggle_switch(sx, sy, false)
		"rocker_switch":
			return _build_toggle_switch(sx, sy, true)  # wider variant
		"key_switch":
			return _build_key_switch(sx, sy)
		# Dials
		"knob_large":
			return _build_knob(sx, sy)
		"knob_small":
			return _build_knob(sx, sy)
		"dial_selector":
			return _build_dial_selector(sx, sy)
		# Sliders
		"fader_v":
			return _build_fader_v(sx, sy)
		"fader_h":
			return _build_fader_h(sx, sy)
		"lever":
			return _build_lever(sx, sy)
		# Speakers
		"speaker_large", "speaker_small":
			return _build_speaker(sx, sy)
		"microphone":
			return _build_microphone(sx, sy)
		"headphone_jack":
			return _build_headphone_jack(sx, sy)
		# Panels
		"nameplate":
			return _build_nameplate(sx, sy)
		"blank_panel":
			return _build_blank_panel(sx, sy)
		"patch_bay":
			return _build_patch_bay(sx, sy)
		# Lights
		"led_green":
			return _build_led(sx, sy, COL_LED_GREEN)
		"led_red":
			return _build_led(sx, sy, COL_LED_RED)
		"led_amber":
			return _build_led(sx, sy, COL_LED_AMBER)
		"warning_light":
			return _build_warning_light(sx, sy)
	return null

static func get_element_type(element_id: String) -> String:
	if element_id in INTERACTIVE:
		return "interactive"
	if element_id in ANIMATED:
		return "animated"
	return "decorative"

# ═════════════════════════════════════════════════════════════════════
# MONITORS
# ═════════════════════════════════════════════════════════════════════

static func _build_crt(sx: float, sy: float, screen_color: Color) -> Node3D:
	var root := Node3D.new()
	# Housing bezel
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	var hm := BoxMesh.new()
	hm.size = Vector3(sx - PAD * 2, sy - PAD * 2, sx * 0.15)
	housing.mesh = hm
	housing.material_override = _mat(COL_BEZEL, 0.3, 0.8)
	root.add_child(housing)
	# Screen face
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var sm := BoxMesh.new()
	sm.size = Vector3(sx - PAD * 2 - 0.02, sy - PAD * 2 - 0.02, 0.004)
	screen.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = COL_SCREEN_BG
	smat.emission_enabled = true
	smat.emission = screen_color * 0.3
	smat.emission_energy_multiplier = 0.8
	smat.roughness = 0.2
	screen.material_override = smat
	screen.position.z = sx * 0.075 + 0.003
	root.add_child(screen)
	return root

static func _build_radar(sx: float, sy: float) -> Node3D:
	var root := _build_crt(sx, sy, COL_SCREEN_FG)
	# Circular overlay
	var r: float = minf(sx, sy) * 0.35
	var disc := MeshInstance3D.new()
	disc.name = "Overlay"
	var dm := CylinderMesh.new()
	dm.top_radius = r
	dm.bottom_radius = r
	dm.height = 0.002
	dm.radial_segments = 24
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.0, 0.3, 0.0, 0.2)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = dmat
	disc.rotation_degrees.x = -90
	disc.position.z = sx * 0.075 + 0.006
	root.add_child(disc)
	# Sweep line
	var sweep := MeshInstance3D.new()
	sweep.name = "SweepLine"
	var swm := BoxMesh.new()
	swm.size = Vector3(0.002, r, 0.002)
	sweep.mesh = swm
	var sw_mat := StandardMaterial3D.new()
	sw_mat.albedo_color = COL_SCREEN_FG
	sw_mat.emission_enabled = true
	sw_mat.emission = COL_SCREEN_FG
	sw_mat.emission_energy_multiplier = 2.0
	sw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sweep.material_override = sw_mat
	sweep.position = Vector3(0, r * 0.5, sx * 0.075 + 0.008)
	root.add_child(sweep)
	return root

static func _build_status_panel(sx: float, sy: float) -> Node3D:
	var root := _build_crt(sx, sy, Color(0.1, 0.6, 0.1))
	var lbl := Label3D.new()
	lbl.name = "StatusLabel"
	lbl.text = "SYS OK\nTEMP 22C\nPRESS 1.0\nPWR NOMINAL"
	lbl.pixel_size = 0.0004
	lbl.font_size = 5
	lbl.modulate = Color(0.15, 0.85, 0.15)
	lbl.position.z = sx * 0.075 + 0.008
	root.add_child(lbl)
	return root

# ═════════════════════════════════════════════════════════════════════
# METERS
# ═════════════════════════════════════════════════════════════════════

static func _build_vu_meter(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Face
	var face := MeshInstance3D.new()
	face.name = "Face"
	var fm := BoxMesh.new()
	fm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.015)
	face.mesh = fm
	face.material_override = _mat(Color(0.9, 0.88, 0.82), 0.0, 0.9)
	root.add_child(face)
	# Needle
	var needle := MeshInstance3D.new()
	needle.name = "Needle"
	var nm := BoxMesh.new()
	nm.size = Vector3(0.002, sy * 0.55, 0.002)
	needle.mesh = nm
	needle.material_override = _mat(Color(0.1, 0.1, 0.1), 0.0, 0.3)
	needle.position = Vector3(0, -sy * 0.1, 0.009)
	root.add_child(needle)
	# Scale markings (thin arc)
	var mark_mat := _mat(Color(0.3, 0.3, 0.3), 0.0, 0.5)
	for i in 7:
		var angle_deg: float = -40.0 + i * 13.3
		var tick := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.001, 0.008, 0.001)
		tick.mesh = tm
		tick.material_override = mark_mat
		var angle_rad: float = deg_to_rad(angle_deg)
		var r: float = sy * 0.4
		tick.position = Vector3(sin(angle_rad) * r, -sy * 0.1 + cos(angle_rad) * r, 0.009)
		tick.rotation_degrees.z = -angle_deg
		root.add_child(tick)
	return root

static func _build_gauge_round(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	var r: float = minf(sx, sy) * 0.42
	# Face disc
	var face := MeshInstance3D.new()
	face.name = "Face"
	var fm := CylinderMesh.new()
	fm.top_radius = r
	fm.bottom_radius = r
	fm.height = 0.012
	fm.radial_segments = 24
	face.mesh = fm
	face.material_override = _mat(Color(0.88, 0.85, 0.8), 0.0, 0.9)
	face.rotation_degrees.x = -90
	root.add_child(face)
	# Bezel ring
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = r - 0.003
	rm.outer_radius = r + 0.003
	rm.ring_segments = 24
	ring.mesh = rm
	ring.material_override = _mat(COL_METAL, 0.7, 0.3)
	ring.rotation_degrees.x = -90
	ring.position.z = 0.002
	root.add_child(ring)
	# Needle
	var needle := MeshInstance3D.new()
	needle.name = "Needle"
	var nm := BoxMesh.new()
	nm.size = Vector3(0.002, r * 0.8, 0.002)
	needle.mesh = nm
	needle.material_override = _mat(Color(0.8, 0.1, 0.1), 0.0, 0.3)
	needle.position = Vector3(0, r * 0.2, 0.008)
	root.add_child(needle)
	return root

static func _build_led_bar_v(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	var count: int = 8
	var spacing: float = (sy - PAD * 2) / count
	var led_r: float = minf(sx * 0.3, spacing * 0.35)
	# Back plate
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.008)
	plate.mesh = pm
	plate.material_override = _mat(Color(0.05, 0.05, 0.05), 0.0, 0.9)
	root.add_child(plate)
	# LEDs from bottom (green) to top (red)
	for i in count:
		var led := MeshInstance3D.new()
		led.name = "LED_%d" % i
		var lm := SphereMesh.new()
		lm.radius = led_r
		lm.height = led_r * 2
		led.mesh = lm
		var t: float = float(i) / (count - 1)
		var color: Color = COL_LED_GREEN.lerp(COL_LED_RED, t)
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3  # Off by default
		mat.albedo_color = color.darkened(0.6)
		mat.roughness = 0.3
		led.material_override = mat
		var y_pos: float = -sy * 0.5 + PAD + spacing * 0.5 + i * spacing
		led.position = Vector3(0, y_pos, 0.008)
		root.add_child(led)
	return root

# ═════════════════════════════════════════════════════════════════════
# BUTTONS
# ═════════════════════════════════════════════════════════════════════

static func _build_push_button(sx: float, sy: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var btn := PUSH_BUTTON.instantiate()
	btn.name = "Interactable"
	var s: float = minf(sx, sy) / 0.065  # push_button is ~0.065m
	btn.scale = Vector3(s * 0.8, s * 0.8, s * 0.8)
	btn.pressed_color = color
	btn.released_color = color.darkened(0.4)
	btn.position.z = 0.01
	root.add_child(btn)
	return root

static func _build_emergency_stop(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Yellow/black housing
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	var hm := BoxMesh.new()
	hm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.025)
	housing.mesh = hm
	housing.material_override = _mat(Color(0.8, 0.7, 0.0), 0.3, 0.6)
	root.add_child(housing)
	# Large red button
	var btn := PUSH_BUTTON.instantiate()
	btn.name = "Interactable"
	btn.scale = Vector3(1.4, 1.4, 1.4)
	btn.pressed_color = Color(0.95, 0.1, 0.05)
	btn.released_color = Color(0.6, 0.05, 0.02)
	btn.position.z = 0.02
	root.add_child(btn)
	# "STOP" label
	var lbl := Label3D.new()
	lbl.text = "STOP"
	lbl.pixel_size = 0.0005
	lbl.font_size = 6
	lbl.modulate = Color(0.1, 0.1, 0.1)
	lbl.position = Vector3(0, -sy * 0.35, 0.014)
	root.add_child(lbl)
	return root

# ═════════════════════════════════════════════════════════════════════
# SWITCHES
# ═════════════════════════════════════════════════════════════════════

static func _build_toggle_switch(sx: float, sy: float, is_rocker: bool) -> Node3D:
	var root := Node3D.new()
	# Base plate
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var base_w: float = sx * 0.6 if not is_rocker else sx * 0.8
	bm.size = Vector3(base_w, sy * 0.3, 0.012)
	base.mesh = bm
	base.material_override = _mat(COL_METAL, 0.7, 0.3)
	base.position.z = 0.003
	root.add_child(base)
	# Toggle lever
	if is_rocker:
		var lever := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(base_w * 0.7, 0.005, 0.025)
		lever.mesh = lm
		lever.material_override = _mat(COL_METAL, 0.8, 0.2)
		var up := randf() > 0.5
		lever.position = Vector3(0, 0, 0.015)
		lever.rotation_degrees.x = 20.0 if up else -20.0
		root.add_child(lever)
	else:
		var lever := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.003
		lm.bottom_radius = 0.004
		lm.height = sy * 0.4
		lever.mesh = lm
		lever.material_override = _mat(COL_METAL, 0.8, 0.2)
		var up := randf() > 0.5
		lever.position = Vector3(0, sy * 0.1 if up else -sy * 0.05, 0.012)
		lever.rotation_degrees.x = 15.0 if up else -15.0
		root.add_child(lever)
	return root

static func _build_key_switch(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Base plate
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.7, sy * 0.35, 0.015)
	base.mesh = bm
	base.material_override = _mat(COL_METAL, 0.7, 0.3)
	base.position.z = 0.004
	root.add_child(base)
	# Keyhole ring
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = sx * 0.2
	rm.bottom_radius = sx * 0.2
	rm.height = 0.004
	rm.radial_segments = 16
	ring.mesh = rm
	ring.material_override = _mat(COL_METAL.darkened(0.2), 0.8, 0.2)
	ring.rotation_degrees.x = -90
	ring.position.z = 0.013
	root.add_child(ring)
	# Keyhole slit
	var slit := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.003, sx * 0.15, 0.005)
	slit.mesh = sm
	slit.material_override = _mat(Color(0.02, 0.02, 0.02), 0.0, 0.9)
	slit.position.z = 0.014
	root.add_child(slit)
	return root

# ═════════════════════════════════════════════════════════════════════
# DIALS
# ═════════════════════════════════════════════════════════════════════

static func _build_knob(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	var r: float = minf(sx, sy) * 0.35
	# Knob body
	var knob := MeshInstance3D.new()
	knob.name = "Knob"
	var km := CylinderMesh.new()
	km.top_radius = r
	km.bottom_radius = r * 1.1
	km.height = 0.012
	km.radial_segments = 16
	knob.mesh = km
	knob.material_override = _mat(COL_KNOB, 0.5, 0.4)
	knob.rotation_degrees.x = -90
	knob.position.z = 0.006
	root.add_child(knob)
	# Pointer line
	var ptr := MeshInstance3D.new()
	ptr.name = "Pointer"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.002, r * 0.8, 0.002)
	ptr.mesh = pm
	ptr.material_override = _mat(Color.WHITE, 0.0, 0.5)
	ptr.position = Vector3(0, r * 0.2, 0.013)
	ptr.rotation_degrees.z = randf_range(-120, 120)
	root.add_child(ptr)
	return root

static func _build_dial_selector(sx: float, sy: float) -> Node3D:
	var root := _build_knob(sx, sy)
	# Add detent marks around the circumference
	var r: float = minf(sx, sy) * 0.42
	var mark_mat := _mat(Color(0.7, 0.7, 0.7), 0.0, 0.5)
	for i in 6:
		var angle: float = deg_to_rad(-150.0 + i * 60.0)
		var tick := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.001, 0.006, 0.001)
		tick.mesh = tm
		tick.material_override = mark_mat
		tick.position = Vector3(sin(angle) * r, cos(angle) * r, 0.004)
		tick.rotation_degrees.z = -(- 150.0 + i * 60.0)
		root.add_child(tick)
	return root

# ═════════════════════════════════════════════════════════════════════
# SLIDERS
# ═════════════════════════════════════════════════════════════════════

static func _build_fader_v(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Track groove
	var track := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(sx * 0.15, sy - PAD * 4, 0.008)
	track.mesh = tm
	track.material_override = _mat(Color(0.05, 0.05, 0.05), 0.0, 0.9)
	track.position.z = 0.002
	root.add_child(track)
	# Slider handle (instantiate real interactable)
	var slider := SLIDER_H.instantiate()
	slider.name = "Interactable"
	slider.rotation_degrees.z = 90  # Vertical
	slider.scale = Vector3(0.5, 0.5, 0.5)
	slider.position.z = 0.01
	root.add_child(slider)
	return root

static func _build_fader_h(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Track groove
	var track := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(sx - PAD * 4, sy * 0.2, 0.008)
	track.mesh = tm
	track.material_override = _mat(Color(0.05, 0.05, 0.05), 0.0, 0.9)
	track.position.z = 0.002
	root.add_child(track)
	# Slider handle
	var slider := SLIDER_H.instantiate()
	slider.name = "Interactable"
	slider.scale = Vector3(0.6, 0.6, 0.6)
	slider.position.z = 0.01
	root.add_child(slider)
	return root

static func _build_lever(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Base housing
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx - PAD * 2, sy * 0.3, 0.02)
	base.mesh = bm
	base.material_override = _mat(COL_METAL, 0.6, 0.4)
	base.position = Vector3(0, -sy * 0.25, 0.005)
	root.add_child(base)
	# Lever arm (CylinderMesh)
	var arm := MeshInstance3D.new()
	arm.name = "Interactable"
	var am := CylinderMesh.new()
	am.top_radius = 0.008
	am.bottom_radius = 0.006
	am.height = sy * 0.7
	arm.mesh = am
	arm.material_override = _mat(COL_METAL, 0.8, 0.2)
	arm.position = Vector3(0, 0, 0.02)
	arm.rotation_degrees.x = randf_range(-15, 15)
	root.add_child(arm)
	# Ball grip on top
	var grip := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.012
	gm.height = 0.024
	grip.mesh = gm
	grip.material_override = _mat(Color(0.15, 0.15, 0.15), 0.3, 0.4)
	grip.position = Vector3(0, sy * 0.3, 0.02)
	root.add_child(grip)
	return root

# ═════════════════════════════════════════════════════════════════════
# SPEAKERS
# ═════════════════════════════════════════════════════════════════════

static func _build_speaker(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Housing
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	var hm := BoxMesh.new()
	hm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.06)
	housing.mesh = hm
	housing.material_override = _mat(COL_SPEAKER, 0.2, 0.8)
	root.add_child(housing)
	# Cone
	var r_cone: float = minf(sx, sy) * 0.3
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_cone * 0.4
	cm.bottom_radius = r_cone
	cm.height = 0.025
	cm.radial_segments = 24
	cone.mesh = cm
	cone.material_override = _mat(Color(0.15, 0.15, 0.15), 0.1, 0.6)
	cone.rotation_degrees.x = -90
	cone.position.z = 0.035
	root.add_child(cone)
	# Grille
	var grille := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(sx - PAD * 2 - 0.01, sy - PAD * 2 - 0.01, 0.004)
	grille.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.2, 0.2, 0.2, 0.4)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.metallic = 0.6
	gmat.roughness = 0.3
	grille.material_override = gmat
	grille.position.z = 0.035
	root.add_child(grille)
	return root

static func _build_microphone(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Stem
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = sx * 0.1
	sm.bottom_radius = sx * 0.12
	sm.height = sy * 0.5
	sm.radial_segments = 8
	stem.mesh = sm
	stem.material_override = _mat(Color(0.15, 0.15, 0.15), 0.6, 0.3)
	stem.position = Vector3(0, -sy * 0.1, 0.01)
	root.add_child(stem)
	# Head
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = sx * 0.25
	hm.height = sx * 0.5
	head.mesh = hm
	head.material_override = _mat(COL_METAL, 0.5, 0.4)
	head.position = Vector3(0, sy * 0.2, 0.01)
	root.add_child(head)
	# Base mount
	var mount := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = sx * 0.2
	mm.bottom_radius = sx * 0.25
	mm.height = 0.008
	mm.radial_segments = 12
	mount.mesh = mm
	mount.material_override = _mat(COL_METAL, 0.7, 0.3)
	mount.rotation_degrees.x = -90
	mount.position = Vector3(0, -sy * 0.35, 0.008)
	root.add_child(mount)
	return root

static func _build_headphone_jack(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	var r: float = minf(sx, sy) * 0.25
	# Socket ring
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = r
	rm.bottom_radius = r
	rm.height = 0.006
	rm.radial_segments = 12
	ring.mesh = rm
	ring.material_override = _mat(COL_METAL, 0.8, 0.2)
	ring.rotation_degrees.x = -90
	ring.position.z = 0.005
	root.add_child(ring)
	# Hole
	var hole := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = r * 0.5
	hm.bottom_radius = r * 0.5
	hm.height = 0.008
	hm.radial_segments = 8
	hole.mesh = hm
	hole.material_override = _mat(Color(0.02, 0.02, 0.02), 0.0, 0.9)
	hole.rotation_degrees.x = -90
	hole.position.z = 0.004
	root.add_child(hole)
	return root

# ═════════════════════════════════════════════════════════════════════
# PANELS
# ═════════════════════════════════════════════════════════════════════

static func _build_nameplate(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Plate
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.004)
	plate.mesh = pm
	plate.material_override = _mat(Color(0.5, 0.45, 0.35), 0.6, 0.4)
	plate.position.z = 0.002
	root.add_child(plate)
	# Text
	var lbl := Label3D.new()
	lbl.text = "PANEL"
	lbl.pixel_size = 0.0004
	lbl.font_size = 5
	lbl.modulate = Color(0.15, 0.15, 0.15)
	lbl.position.z = 0.005
	root.add_child(lbl)
	return root

static func _build_blank_panel(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.008)
	panel.mesh = pm
	panel.material_override = _mat(COL_BEZEL, 0.3, 0.7)
	panel.position.z = 0.002
	root.add_child(panel)
	# Thin bezel frame
	var frame_mat := _mat(COL_METAL.darkened(0.2), 0.5, 0.5)
	var fw := 0.003
	for data in [
		[Vector3(sx - PAD * 2, fw, 0.01), Vector3(0, (sy - PAD * 2) * 0.5, 0.004)],
		[Vector3(sx - PAD * 2, fw, 0.01), Vector3(0, -(sy - PAD * 2) * 0.5, 0.004)],
		[Vector3(fw, sy - PAD * 2, 0.01), Vector3(-(sx - PAD * 2) * 0.5, 0, 0.004)],
		[Vector3(fw, sy - PAD * 2, 0.01), Vector3((sx - PAD * 2) * 0.5, 0, 0.004)],
	]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = data[0]
		bar.mesh = bm
		bar.material_override = frame_mat
		bar.position = data[1]
		root.add_child(bar)
	return root

static func _build_patch_bay(sx: float, sy: float) -> Node3D:
	var root := _build_blank_panel(sx, sy)
	# Grid of small socket holes
	var cols: int = maxi(int(sx / 0.025), 2)
	var rows: int = maxi(int(sy / 0.025), 2)
	var hole_r: float = 0.004
	var hole_mat := _mat(Color(0.02, 0.02, 0.02), 0.0, 0.9)
	for row in rows:
		for col in cols:
			var hole := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = hole_r
			hm.bottom_radius = hole_r
			hm.height = 0.005
			hm.radial_segments = 8
			hole.mesh = hm
			hole.material_override = hole_mat
			hole.rotation_degrees.x = -90
			var x_off: float = -sx * 0.35 + (col + 0.5) * (sx * 0.7 / cols)
			var y_off: float = -sy * 0.3 + (row + 0.5) * (sy * 0.6 / rows)
			hole.position = Vector3(x_off, y_off, 0.008)
			root.add_child(hole)
	return root

# ═════════════════════════════════════════════════════════════════════
# LIGHTS
# ═════════════════════════════════════════════════════════════════════

static func _build_led(sx: float, sy: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var r: float = minf(sx, sy) * 0.3
	var led := MeshInstance3D.new()
	led.name = "Bulb"
	var lm := SphereMesh.new()
	lm.radius = r
	lm.height = r * 2
	led.mesh = lm
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.albedo_color = color.darkened(0.3)
	mat.roughness = 0.3
	led.material_override = mat
	led.position.z = 0.006
	root.add_child(led)
	return root

static func _build_warning_light(sx: float, sy: float) -> Node3D:
	var root := Node3D.new()
	# Cage housing
	var cage := MeshInstance3D.new()
	cage.name = "Housing"
	var cm := BoxMesh.new()
	cm.size = Vector3(sx - PAD * 2, sy - PAD * 2, 0.03)
	cage.mesh = cm
	var cage_mat := StandardMaterial3D.new()
	cage_mat.albedo_color = Color(0.2, 0.2, 0.2, 0.5)
	cage_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cage_mat.metallic = 0.5
	cage_mat.roughness = 0.4
	cage.material_override = cage_mat
	cage.position.z = 0.01
	root.add_child(cage)
	# Bulb
	var r: float = minf(sx, sy) * 0.3
	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	var bm := SphereMesh.new()
	bm.radius = r
	bm.height = r * 2
	bulb.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = COL_LED_RED
	mat.emission_energy_multiplier = 2.5
	mat.albedo_color = COL_LED_RED.darkened(0.2)
	mat.roughness = 0.2
	bulb.material_override = mat
	bulb.position.z = 0.012
	root.add_child(bulb)
	return root

# ═════════════════════════════════════════════════════════════════════
# UTILITIES
# ═════════════════════════════════════════════════════════════════════

static func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m
