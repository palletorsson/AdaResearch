extends Node3D
class_name ProgressionDriver

## Interactive VR control panel to advance through sequences, befriend hazards,
## and reset progression on all three managers. Slider selects sequence,
## buttons trigger force_advance_to or reset_progression.

# --- Preloads ---
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

# --- Configuration ---
@export var panel_width: float = 0.9
@export var panel_height: float = 0.65

# --- Colors ---
const COL_BG := Color(0.05, 0.05, 0.08)
const COL_FRAME := Color(0.2, 0.25, 0.4)
const COL_TITLE := Color(0.85, 0.9, 1.0)
const COL_VALUE := Color(0.7, 0.8, 0.95)
const COL_STATUS := Color(0.4, 0.9, 0.5)
const COL_LABEL := Color(0.55, 0.6, 0.7)

# --- Internal ---
var _sequence_order: Array[String] = []  # Sorted by order field
var _all_hazard_types: Array[String] = []
var _stages_data: Dictionary = {}

var _selected_sequence: String = ""
var _sequence_slider: Node
var _sequence_label: Label3D
var _status_label: Label3D
var _control_panel: Node3D

const STAGES_PATH := "res://commons/maps/soft_stages.json"

# Signal tracking for cleanup
var _signal_connections: Array = []


func _ready() -> void:
	_load_stages_data()
	_build_panel()
	_build_header()
	_build_sequence_section()
	_build_action_buttons()
	_build_befriend_section()
	_build_status_label()


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

func _load_stages_data() -> void:
	if not FileAccess.file_exists(STAGES_PATH):
		push_warning("ProgressionDriver: Cannot find %s" % STAGES_PATH)
		return

	var file := FileAccess.open(STAGES_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("ProgressionDriver: Failed to parse %s" % STAGES_PATH)
		return

	var data: Dictionary = json.data
	_stages_data = data.get("stages", {})

	# Sort sequences by order
	var ordered: Array = []
	for seq_id in _stages_data.keys():
		ordered.append({"id": seq_id, "order": _stages_data[seq_id].get("order", 0)})
	ordered.sort_custom(func(a, b): return a["order"] < b["order"])
	for entry in ordered:
		_sequence_order.append(entry["id"])

	# Collect all unique hazard types across stages
	for seq_id in _stages_data.keys():
		var hazards: Dictionary = _stages_data[seq_id].get("hazards", {})
		for t in hazards.get("unlock_types", []):
			if not _all_hazard_types.has(t):
				_all_hazard_types.append(t)

	if _sequence_order.size() > 0:
		_selected_sequence = _sequence_order[0]


# ---------------------------------------------------------------------------
# Panel construction
# ---------------------------------------------------------------------------

func _build_panel() -> void:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(panel_width, panel_height)
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_BG
	mat.roughness = 0.85
	mat.metallic = 0.1
	mi.material_override = mat
	add_child(mi)

	# Frame
	_add_frame_edge(Vector3(0, panel_height / 2.0, 0.001), Vector3(panel_width + 0.02, 0.015, 0.002))
	_add_frame_edge(Vector3(0, -panel_height / 2.0, 0.001), Vector3(panel_width + 0.02, 0.015, 0.002))
	_add_frame_edge(Vector3(-panel_width / 2.0, 0, 0.001), Vector3(0.015, panel_height + 0.02, 0.002))
	_add_frame_edge(Vector3(panel_width / 2.0, 0, 0.001), Vector3(0.015, panel_height + 0.02, 0.002))


func _add_frame_edge(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_FRAME
	mat.emission_enabled = true
	mat.emission = COL_FRAME * 0.4
	mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
	add_child(mi)


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

func _build_header() -> void:
	_make_label("PROGRESSION DRIVER", 32, COL_TITLE,
		Vector3(-panel_width / 2.0 + 0.04, panel_height / 2.0 - 0.035, 0.003),
		HORIZONTAL_ALIGNMENT_LEFT)


# ---------------------------------------------------------------------------
# Sequence selection (slider + label)
# ---------------------------------------------------------------------------

func _build_sequence_section() -> void:
	var section_y := panel_height / 2.0 - 0.10

	# Section divider
	_add_section_divider(section_y + 0.02)

	_make_label("SEQUENCE", 16, COL_LABEL,
		Vector3(-panel_width / 2.0 + 0.04, section_y, 0.003), HORIZONTAL_ALIGNMENT_LEFT)

	# Slider — placed as child of a control node for positioning
	_control_panel = Node3D.new()
	_control_panel.position = Vector3(0, section_y - 0.04, 0.01)
	add_child(_control_panel)

	_sequence_slider = SLIDER_HORIZONTAL.instantiate()
	_sequence_slider.position = Vector3(0, 0, 0)
	_sequence_slider.scale = Vector3(1.2, 1.2, 1.2)
	var slider_label = _sequence_slider.get_node_or_null("Frame/LabelName")
	if slider_label:
		slider_label.text = "STAGE"
	_control_panel.add_child(_sequence_slider)
	_sequence_slider.slider_moved.connect(_on_sequence_slider_moved)
	_signal_connections.append([_sequence_slider, &"slider_moved", _on_sequence_slider_moved])

	# Current sequence label below slider
	_sequence_label = _make_label("→ — (0/%d)" % _sequence_order.size(), 20, COL_VALUE,
		Vector3(-panel_width / 2.0 + 0.04, section_y - 0.09, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


func _on_sequence_slider_moved(_pos) -> void:
	if not _sequence_slider or _sequence_order.size() == 0:
		return
	var norm: float = _sequence_slider.get_normalized_value()
	var idx := int(round(norm * float(_sequence_order.size() - 1)))
	idx = clampi(idx, 0, _sequence_order.size() - 1)
	_selected_sequence = _sequence_order[idx]
	_update_sequence_label()


func _update_sequence_label() -> void:
	var idx := _sequence_order.find(_selected_sequence)
	var order: int = int(_stages_data.get(_selected_sequence, {}).get("order", 0))
	_sequence_label.text = "→ %s (%d/%d)" % [_selected_sequence, order, _sequence_order.size()]


# ---------------------------------------------------------------------------
# Action buttons — ADVANCE, RESET, UNLOCK ALL
# ---------------------------------------------------------------------------

func _build_action_buttons() -> void:
	var btn_y := panel_height / 2.0 - 0.24

	_add_section_divider(btn_y + 0.02)

	var x_positions := [-0.25, 0.0, 0.25]
	var labels := ["ADVANCE", "RESET", "UNLOCK ALL"]
	var callbacks := [_on_advance, _on_reset, _on_unlock_all]

	for i in range(3):
		var btn := PUSH_BUTTON.instantiate()
		btn.position = Vector3(x_positions[i], btn_y - 0.02, 0.015)
		add_child(btn)
		_add_button_label(btn, labels[i])
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(callbacks[i])
			_signal_connections.append([area, &"button_pressed", callbacks[i]])


func _on_advance(_b) -> void:
	if _selected_sequence.is_empty():
		_set_status("No sequence selected")
		return

	var eco = get_node_or_null("/root/EcosystemManager")
	var haz = get_node_or_null("/root/HazardManager")
	var cap = get_node_or_null("/root/CatalystCapabilityManager")

	if eco:
		eco.force_advance_to(_selected_sequence)
	if haz:
		haz.force_advance_to(_selected_sequence)
	if cap:
		cap.force_advance_to(_selected_sequence)

	var order: int = int(_stages_data.get(_selected_sequence, {}).get("order", 0))
	_set_status("Advanced to '%s' (order %d)" % [_selected_sequence, order])


func _on_reset(_b) -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	var haz = get_node_or_null("/root/HazardManager")
	var cap = get_node_or_null("/root/CatalystCapabilityManager")

	if eco:
		eco.reset_progression()
	if haz:
		haz.reset_progression()
	if cap:
		cap.reset_progression()

	if _sequence_slider and _sequence_slider.has_method("set_normalized_value"):
		_sequence_slider.set_normalized_value(0.0)
	_selected_sequence = _sequence_order[0] if _sequence_order.size() > 0 else ""
	_update_sequence_label()
	_set_status("All progression reset")


func _on_unlock_all(_b) -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	var haz = get_node_or_null("/root/HazardManager")
	var cap = get_node_or_null("/root/CatalystCapabilityManager")

	var last_seq := _sequence_order[-1] if _sequence_order.size() > 0 else ""
	if eco and not last_seq.is_empty():
		eco.force_advance_to(last_seq)
	if haz and not last_seq.is_empty():
		haz.force_advance_to(last_seq)
	if cap:
		cap.unlock_all_capabilities()

	if _sequence_slider and _sequence_slider.has_method("set_normalized_value"):
		_sequence_slider.set_normalized_value(1.0)
	_selected_sequence = last_seq
	_update_sequence_label()
	_set_status("All capabilities unlocked")


# ---------------------------------------------------------------------------
# Befriend buttons — dynamic grid from soft_stages.json hazard types
# ---------------------------------------------------------------------------

func _build_befriend_section() -> void:
	var section_y := panel_height / 2.0 - 0.34

	_add_section_divider(section_y + 0.02)

	_make_label("BEFRIEND HAZARD", 16, COL_LABEL,
		Vector3(-panel_width / 2.0 + 0.04, section_y, 0.003), HORIZONTAL_ALIGNMENT_LEFT)

	if _all_hazard_types.size() == 0:
		_make_label("(no hazard types found)", 14, COL_LABEL,
			Vector3(-panel_width / 2.0 + 0.04, section_y - 0.03, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
		return

	var cols := 4
	var x_start := -panel_width / 2.0 + 0.12
	var x_step := 0.20
	var y_start := section_y - 0.05
	var y_step := 0.055

	for i in range(_all_hazard_types.size()):
		var col := i % cols
		var row := i / cols
		var hazard_type := _all_hazard_types[i]

		var btn := PUSH_BUTTON.instantiate()
		btn.position = Vector3(x_start + col * x_step, y_start - row * y_step, 0.015)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		add_child(btn)

		# Short label — first part of name, max 10 chars
		var short := _short_name(hazard_type)
		_add_button_label(btn, short)

		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			var type_ref := hazard_type  # Capture for closure
			var cb := func(_b): _on_befriend(type_ref)
			area.button_pressed.connect(cb)
			_signal_connections.append([area, &"button_pressed", cb])


func _on_befriend(hazard_type: String) -> void:
	var haz = get_node_or_null("/root/HazardManager")
	if haz:
		haz.befriend_hazard(hazard_type)
		_set_status("Befriended: %s" % hazard_type)
	else:
		_set_status("HazardManager not loaded")


# ---------------------------------------------------------------------------
# Status label
# ---------------------------------------------------------------------------

func _build_status_label() -> void:
	var status_y := -panel_height / 2.0 + 0.035
	_add_section_divider(status_y + 0.025)
	_status_label = _make_label("Ready", 18, COL_STATUS,
		Vector3(-panel_width / 2.0 + 0.04, status_y, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


func _set_status(text: String) -> void:
	_status_label.text = text


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_label(text: String, size: int, color: Color, pos: Vector3, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = size
	lbl.pixel_size = 0.001
	lbl.outline_size = max(2, size / 8)
	lbl.position = pos
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.modulate = color
	add_child(lbl)
	return lbl


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)


func _add_section_divider(y: float) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(panel_width - 0.04, 0.003, 0.001)
	mi.mesh = box
	mi.position = Vector3(0, y, 0.001)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.14, 0.2)
	mi.material_override = mat
	add_child(mi)


func _short_name(hazard_type: String) -> String:
	# "miura_crawler" → "miura", "kaleidocycle_enemy" → "kaleido"
	var parts := hazard_type.split("_")
	if parts.size() > 0:
		var n := parts[0]
		return n.substr(0, 10) if n.length() > 10 else n
	return hazard_type


func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()

## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("start_sequence"):
		var seq: String = config_data["start_sequence"]
		if _sequence_order.has(seq):
			_selected_sequence = seq
			_update_sequence_label()
			var idx := _sequence_order.find(seq)
			var norm := float(idx) / float(max(1, _sequence_order.size() - 1))
			if _sequence_slider and _sequence_slider.has_method("set_normalized_value"):
				_sequence_slider.set_normalized_value(norm)
	if config_data.has("auto_advance") and config_data["auto_advance"]:
		call_deferred("_on_advance", true)
