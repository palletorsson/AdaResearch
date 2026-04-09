extends Control

## 2D UI for the VR Artifact Workstation
## Rendered onto a 3D panel via viewport_2d_in_3d

signal artifact_changed(lookup_name: String)

var _all_artifacts: Array = []
var _current_list: Array = []
var _current_index: int = 0
var _sort_mode: int = 0
var _groups: Array[String] = []
var _group_index: int = 0
var _current_group: String = "all"

const SORT_NAMES := ["ALL", "SEQUENCE", "TYPE"]

@onready var _name_label: Label = $VBox/NameLabel
@onready var _pos_label: Label = $VBox/PosLabel
@onready var _group_label: Label = $VBox/GroupLabel
@onready var _info_label: Label = $VBox/InfoLabel
@onready var _mode_button: Button = $VBox/ButtonRow/ModeButton

func _ready() -> void:
	_load_data()
	$VBox/ButtonRow/PrevButton.pressed.connect(_on_prev)
	$VBox/ButtonRow/NextButton.pressed.connect(_on_next)
	$VBox/ButtonRow/ModeButton.pressed.connect(_on_mode)
	$VBox/GroupRow/GrpPrevButton.pressed.connect(_on_group_prev)
	$VBox/GroupRow/GrpNextButton.pressed.connect(_on_group_next)
	if _current_list.size() > 0:
		_update_ui()
		emit_signal("artifact_changed", str(_current_list[0].get("lookup_name", "")))

func _load_data() -> void:
	_all_artifacts = ArtifactCatalogDataProvider.get_all_artifacts()
	_all_artifacts.sort_custom(func(a, b): return str(a.get("lookup_name", "")) < str(b.get("lookup_name", "")))
	_apply_sort()

func _apply_sort() -> void:
	match _sort_mode:
		0:
			_current_list = _all_artifacts.duplicate()
			_groups = ["all"]
			_current_group = "all"
		1:
			_build_groups("map_sequences")
		2:
			_build_groups("artifact_type")
	_current_index = 0
	_update_ui()

func _build_groups(field: String) -> void:
	var gmap: Dictionary = {}
	for art in _all_artifacts:
		var val = art.get(field, "")
		var names: Array = []
		if val is Array:
			names = val
		elif val is String and val != "":
			names = [val]
		else:
			names = ["ungrouped"]
		for g in names:
			if g not in gmap:
				gmap[g] = []
			gmap[g].append(art)
	_groups.clear()
	for g in gmap.keys():
		_groups.append(g)
	_groups.sort()
	if _group_index >= _groups.size():
		_group_index = 0
	_current_group = _groups[_group_index] if _groups.size() > 0 else ""
	_current_list = gmap.get(_current_group, [])
	_current_index = 0

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
	_rebuild_group_list()
	_emit_and_update()

func _on_group_next() -> void:
	if _groups.size() <= 1: return
	_group_index = (_group_index + 1) % _groups.size()
	_current_group = _groups[_group_index]
	_rebuild_group_list()
	_emit_and_update()

func _rebuild_group_list() -> void:
	if _sort_mode == 0:
		_current_list = _all_artifacts.duplicate()
	else:
		var field := "map_sequences" if _sort_mode == 1 else "artifact_type"
		_current_list = _all_artifacts.filter(func(art):
			var val = art.get(field, "")
			if val is Array: return _current_group in val
			return str(val) == _current_group
		)
	_current_index = 0

func _emit_and_update() -> void:
	_update_ui()
	if _current_index < _current_list.size():
		var lookup: String = str(_current_list[_current_index].get("lookup_name", ""))
		emit_signal("artifact_changed", lookup)

func _update_ui() -> void:
	if _current_list.size() == 0:
		_name_label.text = "No artifacts"
		_pos_label.text = ""
		_group_label.text = ""
		_info_label.text = ""
		return

	var art: Dictionary = _current_list[_current_index] if _current_index < _current_list.size() else {}
	var lookup: String = str(art.get("lookup_name", "?"))
	var name_str: String = str(art.get("name", lookup))

	_name_label.text = name_str
	_pos_label.text = "%d / %d" % [_current_index + 1, _current_list.size()]
	_mode_button.text = SORT_NAMES[_sort_mode]

	if _sort_mode == 0:
		_group_label.text = "all artifacts"
	else:
		_group_label.text = "%s  (%d/%d)" % [_current_group, _group_index + 1, _groups.size()]

	var seqs = art.get("map_sequences", [])
	var seq_str: String = ", ".join(seqs) if seqs is Array else str(seqs)
	var desc: String = str(art.get("description", ""))
	if desc.length() > 120:
		desc = desc.substr(0, 117) + "..."
	_info_label.text = "%s\n%s\n%s" % [lookup, seq_str, desc]
