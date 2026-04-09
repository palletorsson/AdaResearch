extends "res://commons/maps/catalog/MapCatalogDesktop3D.gd"

var _grid_editor: MapGridEditorOverlay
var _current_map_name: String = ""
var _current_map_data: Dictionary = {}
var _current_map_path: String = ""

func _ready() -> void:
	super._ready()
	_camera_mode = CameraMode.STATIC
	_grid_editor = get_node_or_null("MapGridEditorOverlay") as MapGridEditorOverlay
	if _grid_editor:
		_grid_editor.cell_painted.connect(_on_grid_painted)
		_grid_editor.artifact_placed.connect(_on_grid_artifact_placed)

func _on_map_selected(map_name: String) -> void:
	super._on_map_selected(map_name)
	_current_map_name = map_name
	_feed_grid_editor(map_name)

func _feed_grid_editor(map_name: String) -> void:
	if not _grid_editor: return
	_current_map_path = "res://commons/maps/" + map_name + "/map_data.json"
	var file := FileAccess.open(_current_map_path, FileAccess.READ)
	if not file: return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	_current_map_data = json.data
	var layers: Dictionary = _current_map_data.get("layers", {})
	var structure: Array = layers.get("structure", [])
	var utilities: Array = layers.get("utilities", [])
	var interactables: Array = layers.get("interactables", [])
	var depth: int = structure.size()
	var width: int = structure[0].size() if depth > 0 else 0
	_grid_editor.load_layers(structure, utilities, interactables, width, depth)

func _on_grid_painted(_layer_idx: int, _x: int, _z: int, _value: String) -> void:
	_save_current_map()

func _on_grid_artifact_placed(_x: int, _z: int, _value: String) -> void:
	_save_current_map()

func _save_current_map() -> void:
	if _current_map_path == "" or not _grid_editor: return
	if "layers" not in _current_map_data: _current_map_data["layers"] = {}
	_current_map_data["layers"]["structure"] = _grid_editor.structure_layer
	_current_map_data["layers"]["utilities"] = _grid_editor.utilities_layer
	_current_map_data["layers"]["interactables"] = _grid_editor.interactables_layer
	var file := FileAccess.open(_current_map_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_current_map_data, "  "))
		file.close()

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_S:
		_save_current_map()
		_set_status("Saved: " + _current_map_name)
