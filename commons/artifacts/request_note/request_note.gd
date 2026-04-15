extends Node3D

## Request Note — floating billboard text on a cream plate.
##
## Usage in map_data.json:
##   "request_note#text:Fix the lighting here"
##   "request_note#key:bug_42"  (reads from requests.json)

var _text: String = "REQUEST"
var _label: Label3D
var _time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	# Billboard label — large, readable from distance
	_label = Label3D.new()
	_label.name = "Text"
	_label.text = _text
	_label.font_size = 48
	_label.pixel_size = 0.001
	_label.modulate = Color(0.12, 0.12, 0.12)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.width = 500
	_label.outline_size = 4
	_label.outline_modulate = Color(0.90, 0.87, 0.80, 0.8)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.transform.origin.y = 0.5
	add_child(_label)

	_base_y = transform.origin.y


func _process(delta: float) -> void:
	_time += delta
	transform.origin.y = _base_y + sin(_time * 1.5) * 0.015


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("text"):
		_text = str(config_data["text"])
	if config_data.has("key"):
		_text = _load_key(str(config_data["key"]))
	if _label:
		_label.text = _text


func _load_key(key_name: String) -> String:
	var grid_system: Node = get_tree().get_first_node_in_group("grid_system") if is_inside_tree() else null
	var map_name: String = ""
	if grid_system and "map_name" in grid_system:
		map_name = str(grid_system.map_name)
	if map_name != "":
		var path: String = "res://commons/maps/%s/requests.json" % map_name
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
					if (json.data as Dictionary).has(key_name):
						return str((json.data as Dictionary)[key_name])
	return "[%s]" % key_name
