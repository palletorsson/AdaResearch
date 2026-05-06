extends Control

## 2D UI for the VR Artifact Workstation
## Rendered onto a 3D panel via viewport_2d_in_3d

signal artifact_changed(lookup_name: String)

var _all_artifacts: Array = []
var _current_list: Array = []
var _current_index: int = 0
var _sort_mode: int = 1  # Start in SEQUENCE mode
var _groups: Array[String] = []
var _group_index: int = 0
var _current_group: String = "primitives"
var _group_map: Dictionary = {}  # group_name -> Array of artifacts

# Spine sequence order (curriculum progression)
const SPINE_ORDER: Array[String] = [
	"primitives", "transformation", "color", "forces", "array_tutorial",
	"wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
	"lsystems", "proceduralgeneration", "softbodies", "swarmintelligence",
	"machinelearning", "foundationscrisis", "qfeplaboratory",
	"postfoundationscrisis", "graphtheory"
]

const SORT_NAMES := ["ALL", "SEQUENCE", "TYPE"]

var _name_label: Label
var _pos_label: Label
var _group_label: Label
var _info_label: Label
var _mode_button: Button
var _badge_container: Node

func _ready() -> void:
	_name_label = get_node_or_null("VBox/NameLabel") as Label
	_pos_label = get_node_or_null("VBox/PosLabel") as Label
	_group_label = get_node_or_null("VBox/GroupRow/GroupLabel") as Label
	_info_label = get_node_or_null("VBox/InfoLabel") as Label
	_mode_button = get_node_or_null("VBox/ButtonRow/ModeButton") as Button
	_badge_container = get_node_or_null("VBox/BadgeScroll/BadgeFlow")

	var prev_btn = get_node_or_null("VBox/ButtonRow/PrevButton")
	var next_btn = get_node_or_null("VBox/ButtonRow/NextButton")
	var mode_btn = get_node_or_null("VBox/ButtonRow/ModeButton")
	var gprev_btn = get_node_or_null("VBox/GroupRow/GrpPrevButton")
	var gnext_btn = get_node_or_null("VBox/GroupRow/GrpNextButton")

	if prev_btn: prev_btn.pressed.connect(_on_prev)
	if next_btn: next_btn.pressed.connect(_on_next)
	if mode_btn: mode_btn.pressed.connect(_on_mode)
	if gprev_btn: gprev_btn.pressed.connect(_on_group_prev)
	if gnext_btn: gnext_btn.pressed.connect(_on_group_next)

	_load_data()
	_build_badges()

	if _current_list.size() > 0:
		_update_ui()
		artifact_changed.emit(str(_current_list[0].get("lookup_name", "")))

func _load_data() -> void:
	_all_artifacts = ArtifactCatalogDataProvider.get_all_artifacts()
	_all_artifacts.sort_custom(func(a, b): return str(a.get("lookup_name", "")) < str(b.get("lookup_name", "")))

	# Pre-build group map for sequences
	_group_map.clear()
	for art in _all_artifacts:
		var seqs = art.get("map_sequences", [])
		if seqs is Array:
			for s in seqs:
				if s not in _group_map:
					_group_map[s] = []
				_group_map[s].append(art)
		elif seqs is String and seqs != "":
			if seqs not in _group_map:
				_group_map[seqs] = []
			_group_map[seqs].append(art)

	# Default: sequence mode, starting with primitives
	_sort_mode = 1
	_groups = SPINE_ORDER.duplicate()
	# Add non-spine sequences at the end
	for g in _group_map.keys():
		if g not in _groups:
			_groups.append(g)
	_group_index = 0  # primitives
	_current_group = _groups[0]
	_current_list = _group_map.get(_current_group, [])
	_current_index = 0

func _build_badges() -> void:
	if not _badge_container:
		return
	# Clear existing
	for child in _badge_container.get_children():
		child.queue_free()

	for i in range(SPINE_ORDER.size()):
		var seq_name: String = SPINE_ORDER[i]
		var count: int = _group_map.get(seq_name, []).size()
		var btn := Button.new()
		btn.text = "%s (%d)" % [seq_name.substr(0, 8), count]
		btn.custom_minimum_size = Vector2(0, 24)
		btn.tooltip_text = seq_name
		btn.pressed.connect(_on_badge_pressed.bind(seq_name))
		_badge_container.add_child(btn)

func _on_badge_pressed(seq_name: String) -> void:
	_sort_mode = 1
	var idx := _groups.find(seq_name)
	if idx >= 0:
		_group_index = idx
	_current_group = seq_name
	_current_list = _group_map.get(seq_name, [])
	_current_index = 0
	_emit_and_update()

func _apply_sort() -> void:
	match _sort_mode:
		0:
			_current_list = _all_artifacts.duplicate()
			_current_group = "all"
		1:
			_groups = SPINE_ORDER.duplicate()
			for g in _group_map.keys():
				if g not in _groups:
					_groups.append(g)
			if _group_index >= _groups.size():
				_group_index = 0
			_current_group = _groups[_group_index]
			_current_list = _group_map.get(_current_group, [])
		2:
			_build_type_groups()
	_current_index = 0
	_update_ui()

func _build_type_groups() -> void:
	var tmap: Dictionary = {}
	for art in _all_artifacts:
		var t: String = str(art.get("artifact_type", "unknown"))
		if t not in tmap:
			tmap[t] = []
		tmap[t].append(art)
	_groups.clear()
	for g in tmap.keys():
		_groups.append(g)
	_groups.sort()
	if _group_index >= _groups.size():
		_group_index = 0
	_current_group = _groups[_group_index] if _groups.size() > 0 else ""
	_current_list = tmap.get(_current_group, [])

func _on_prev() -> void:
	if _current_list.size() == 0: return
	_current_index = (_current_index - 1 + _current_list.size()) % _current_list.size()
	_emit_and_update()

func _on_next() -> void:
	if _current_list.size() == 0: return
	_current_index = (_current_index + 1) % _current_list.size()
	_emit_and_update()

func _on_mode() -> void:
	_sort_mode = (_sort_mode + 1) % 3
	_group_index = 0
	_apply_sort()
	_emit_and_update()

func _on_group_prev() -> void:
	if _groups.size() <= 1: return
	_group_index = (_group_index - 1 + _groups.size()) % _groups.size()
	_current_group = _groups[_group_index]
	_current_list = _group_map.get(_current_group, _all_artifacts) if _sort_mode == 1 else []
	if _sort_mode == 2:
		_build_type_groups()
		_current_list = _group_map.get(_current_group, [])
	_current_index = 0
	_emit_and_update()

func _on_group_next() -> void:
	if _groups.size() <= 1: return
	_group_index = (_group_index + 1) % _groups.size()
	_current_group = _groups[_group_index]
	_current_list = _group_map.get(_current_group, _all_artifacts) if _sort_mode == 1 else []
	if _sort_mode == 2:
		_build_type_groups()
		_current_list = _group_map.get(_current_group, [])
	_current_index = 0
	_emit_and_update()

func _emit_and_update() -> void:
	_update_ui()
	if _current_index < _current_list.size():
		var lookup: String = str(_current_list[_current_index].get("lookup_name", ""))
		artifact_changed.emit(lookup)

func _update_ui() -> void:
	if not _name_label:
		return

	if _current_list.size() == 0:
		_name_label.text = "No artifacts"
		if _pos_label: _pos_label.text = ""
		if _group_label: _group_label.text = ""
		if _info_label: _info_label.text = ""
		return

	var art: Dictionary = _current_list[_current_index] if _current_index < _current_list.size() else {}
	var lookup: String = str(art.get("lookup_name", "?"))
	var name_str: String = str(art.get("name", lookup))

	_name_label.text = name_str
	if _pos_label: _pos_label.text = "%d / %d" % [_current_index + 1, _current_list.size()]
	if _mode_button: _mode_button.text = SORT_NAMES[_sort_mode]

	if _group_label:
		if _sort_mode == 0:
			_group_label.text = "all %d artifacts" % _all_artifacts.size()
		else:
			_group_label.text = "%s  (%d/%d)" % [_current_group, _group_index + 1, _groups.size()]

	if _info_label:
		var seqs = art.get("map_sequences", [])
		var seq_str: String = ", ".join(seqs) if seqs is Array else str(seqs)
		var desc: String = str(art.get("description", ""))
		if desc.length() > 100:
			desc = desc.substr(0, 97) + "..."
		_info_label.text = "%s | %s\n%s" % [lookup, seq_str, desc]

	# Highlight active badge
	if _badge_container and _sort_mode == 1:
		for i in range(_badge_container.get_child_count()):
			var btn: Button = _badge_container.get_child(i) as Button
			if btn:
				btn.modulate = Color(1, 0.85, 0.3) if SPINE_ORDER[i] == _current_group else Color(1, 1, 1)
