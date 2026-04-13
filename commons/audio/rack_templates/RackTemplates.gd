extends Node3D
class_name RackTemplates

## Reusable rack module templates — standardized building blocks
## that combine interactive elements into Dieter Rams-styled modules.
##
## Each template creates a complete module with:
## - Cream panel background
## - Properly spaced controls (real interactable scenes)
## - Labels and value displays
## - Rams aesthetic (copper accents, dark controls, cream panels)
##
## Usage:
##   var module = RackTemplates.create_fader_bank(4, ["FREQ", "AMP", "DEC", "REL"])
##   add_child(module)

const CREAM := Color(0.90, 0.87, 0.80)
const DARK := Color(0.12, 0.12, 0.12)
const COPPER := Color(0.75, 0.38, 0.13)
const WARM_DARK := Color(0.25, 0.23, 0.20)
const HP := 0.018  # meters per HP unit


## ─── FADER_BANK: N vertical sliders side by side ─────────────────────

static func create_fader_bank(count: int, labels: Array = [], params: Array = []) -> Node3D:
	var module := Node3D.new()
	module.name = "FaderBank_%d" % count

	var gap := 0.06
	var total_w := count * gap + 0.04
	var panel_h := 0.28

	# Cream panel
	_add_panel(module, total_w, panel_h)

	# Title
	_add_title(module, "FADER BANK", total_w, panel_h)

	# Sliders
	var start_x := -(count - 1) * gap / 2.0
	for i in count:
		var x := start_x + i * gap
		var slider: Node = load("res://commons/interactables/slider_smooth.tscn").instantiate()
		slider.name = "Fader_%d" % i
		slider.transform.origin = Vector3(x, 0, 0.01)
		slider.scale = Vector3.ONE * 0.8
		module.add_child(slider)

		# Label
		var label_text: String = labels[i] if i < labels.size() else "CH%d" % (i + 1)
		_add_label(module, label_text, Vector3(x, -panel_h / 2.0 + 0.02, 0.01))

		# Set parameter name
		if slider.has_method("set_param_name"):
			slider.set_param_name(label_text)

	return module


## ─── KNOB_PANEL: N rotary knobs in a row ─────────────────────────────

static func create_knob_panel(count: int, labels: Array = []) -> Node3D:
	var module := Node3D.new()
	module.name = "KnobPanel_%d" % count

	var gap := 0.07
	var total_w := count * gap + 0.04
	var panel_h := 0.14

	_add_panel(module, total_w, panel_h)
	_add_title(module, "KNOBS", total_w, panel_h)

	var start_x := -(count - 1) * gap / 2.0
	for i in count:
		var x := start_x + i * gap
		var knob: Node = load("res://commons/interactables/dial_smooth.tscn").instantiate()
		knob.name = "Knob_%d" % i
		knob.transform.origin = Vector3(x, -0.01, 0.01)
		knob.scale = Vector3.ONE * 0.85
		module.add_child(knob)

		var label_text: String = labels[i] if i < labels.size() else "K%d" % (i + 1)
		_add_label(module, label_text, Vector3(x, -panel_h / 2.0 + 0.015, 0.01))

		if knob.has_method("set_param_name"):
			knob.set_param_name(label_text)

	return module


## ─── PARAMETER_PANEL: N horizontal sliders stacked (most common) ─────

static func create_parameter_panel(count: int, labels: Array = [], defaults: Array = []) -> Node3D:
	var module := Node3D.new()
	module.name = "ParamPanel_%d" % count

	var gap := 0.055
	var total_w := 0.28
	var panel_h := count * gap + 0.04

	_add_panel(module, total_w, panel_h)
	_add_title(module, "PARAMETERS", total_w, panel_h)

	var start_y := (count - 1) * gap / 2.0
	for i in count:
		var y := start_y - i * gap
		var slider: Node = load("res://commons/interactables/slider_horizontal.tscn").instantiate()
		slider.name = "Param_%d" % i
		slider.transform.origin = Vector3(0.02, y, 0.01)
		slider.scale = Vector3.ONE * 0.7
		module.add_child(slider)

		var label_text: String = labels[i] if i < labels.size() else "P%d" % (i + 1)
		_add_label(module, label_text, Vector3(-total_w / 2.0 + 0.03, y, 0.01), 16, HORIZONTAL_ALIGNMENT_LEFT)

		if slider.has_method("set_param_name"):
			slider.set_param_name(label_text)
		if i < defaults.size() and slider.has_method("set_normalized_value"):
			slider.set_normalized_value(defaults[i])

	# Reset button at bottom
	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	if btn_scene:
		var btn: Node = btn_scene.instantiate()
		btn.name = "ResetButton"
		btn.transform.origin = Vector3(0, -panel_h / 2.0 + 0.025, 0.01)
		btn.scale = Vector3.ONE * 0.6
		module.add_child(btn)
		_add_label(module, "RESET", Vector3(0, -panel_h / 2.0 + 0.008, 0.01), 14)

	return module


## ─── BUTTON_GRID: Array of buttons ───────────────────────────────────

static func create_button_grid(cols: int, rows: int, labels: Array = [], colors: Array = []) -> Node3D:
	var module := Node3D.new()
	module.name = "ButtonGrid_%dx%d" % [cols, rows]

	var gap_x := 0.06
	var gap_y := 0.06
	var total_w := cols * gap_x + 0.04
	var panel_h := rows * gap_y + 0.04

	_add_panel(module, total_w, panel_h)
	_add_title(module, "CONTROLS", total_w, panel_h)

	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	if not btn_scene:
		return module

	var idx := 0
	var start_x := -(cols - 1) * gap_x / 2.0
	var start_y := (rows - 1) * gap_y / 2.0
	for r in rows:
		for c in cols:
			var x := start_x + c * gap_x
			var y := start_y - r * gap_y
			var btn: Node = btn_scene.instantiate()
			btn.name = "Btn_%d" % idx
			btn.transform.origin = Vector3(x, y, 0.01)
			btn.scale = Vector3.ONE * 0.7
			module.add_child(btn)

			var label_text: String = labels[idx] if idx < labels.size() else "%d" % (idx + 1)
			_add_label(module, label_text, Vector3(x, y - 0.025, 0.01), 12)

			idx += 1

	return module


## ─── MIXER_STRIP: Fader + pan knob + mute button ─────────────────────

static func create_mixer_strip(label: String = "CH") -> Node3D:
	var module := Node3D.new()
	module.name = "MixerStrip_%s" % label

	var total_w := 0.08
	var panel_h := 0.34

	_add_panel(module, total_w, panel_h)
	_add_title(module, label, total_w, panel_h)

	# Fader (vertical)
	var slider: Node = load("res://commons/interactables/slider_smooth.tscn").instantiate()
	slider.name = "Fader"
	slider.transform.origin = Vector3(0, 0.04, 0.01)
	slider.scale = Vector3.ONE * 0.65
	module.add_child(slider)
	if slider.has_method("set_param_name"):
		slider.set_param_name("VOL")

	# Pan knob
	var knob: Node = load("res://commons/interactables/dial_smooth.tscn").instantiate()
	knob.name = "Pan"
	knob.transform.origin = Vector3(0, -0.06, 0.01)
	knob.scale = Vector3.ONE * 0.5
	module.add_child(knob)
	if knob.has_method("set_param_name"):
		knob.set_param_name("PAN")

	# Mute button
	var btn_scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	if btn_scene:
		var btn: Node = btn_scene.instantiate()
		btn.name = "Mute"
		btn.transform.origin = Vector3(0, -0.12, 0.01)
		btn.scale = Vector3.ONE * 0.5
		module.add_child(btn)
		_add_label(module, "MUTE", Vector3(0, -0.145, 0.01), 12)

	return module


## ─── MONITOR_FADERS: Display on top, faders below ────────────────────

static func create_monitor_faders(fader_count: int, labels: Array = [], mode: String = "scope") -> Node3D:
	var module := Node3D.new()
	module.name = "MonitorFaders_%d" % fader_count

	var gap := 0.06
	var total_w: float = max(fader_count * gap + 0.04, 0.20)
	var panel_h := 0.34

	_add_panel(module, total_w, panel_h)
	_add_title(module, "MONITOR", total_w, panel_h)

	# Monitor display on top
	var RackPassive: GDScript = load("res://commons/interactables/RackPassiveElements.gd")
	if RackPassive:
		var monitor_container := Node3D.new()
		monitor_container.transform.origin = Vector3(0, 0.06, 0.01)
		module.add_child(monitor_container)
		RackPassive.build_monitor_grid(monitor_container, 1, mode)

	# Faders below
	var start_x := -(fader_count - 1) * gap / 2.0
	for i in fader_count:
		var x := start_x + i * gap
		var slider: Node = load("res://commons/interactables/slider_smooth.tscn").instantiate()
		slider.name = "Fader_%d" % i
		slider.transform.origin = Vector3(x, -0.06, 0.01)
		slider.scale = Vector3.ONE * 0.55
		module.add_child(slider)

		var label_text: String = labels[i] if i < labels.size() else "F%d" % (i + 1)
		_add_label(module, label_text, Vector3(x, -panel_h / 2.0 + 0.02, 0.01), 12)

	return module


## ─── HELPERS ─────────────────────────────────────────────────────────

static func _add_panel(parent: Node3D, w: float, h: float) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var box := BoxMesh.new()
	box.size = Vector3(w, h, 0.008)
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = CREAM
	mat.roughness = 0.8
	panel.material_override = mat
	parent.add_child(panel)

	# Dark border frame
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(w + 0.004, h + 0.004, 0.004)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = WARM_DARK
	frame.material_override = fmat
	frame.transform.origin.z = -0.003
	parent.add_child(frame)


static func _add_title(parent: Node3D, text: String, panel_w: float, panel_h: float) -> void:
	var lbl := Label3D.new()
	lbl.name = "Title"
	lbl.text = text
	lbl.font_size = 18
	lbl.pixel_size = 0.0004
	lbl.modulate = Color(0.15, 0.15, 0.15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, panel_h / 2.0 - 0.012, 0.005)
	parent.add_child(lbl)


static func _add_label(parent: Node3D, text: String, pos: Vector3, size: int = 14, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = size
	lbl.pixel_size = 0.0004
	lbl.modulate = Color(0.15, 0.15, 0.15)
	lbl.horizontal_alignment = align
	lbl.transform.origin = pos
	parent.add_child(lbl)
