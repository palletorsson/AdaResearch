extends Control

## DNA Workstation UI — browse all DNA substrates and their config variants.
## Two ItemLists: substrates on the left, configs on the right. Selecting a
## config emits `dna_changed(substrate, config_id)` which the 3D workstation
## catches and builds live in the presentation area.

signal dna_changed(substrate: String, config_id: String)

# ─── Substrate registry ────────────────────────────────────────
# Maps display name → (config file path, live-renderable flag)
const SUBSTRATES := [
	{"name": "L-system",         "key": "lsystem",       "path": "res://commons/lsystem_grammar/research_configs.json",       "live": true},
	{"name": "Trajectory",       "key": "trajectory",    "path": "res://commons/trajectory_grammar/research_configs.json",    "live": true},
	{"name": "Wallpaper pattern","key": "pattern",       "path": "res://commons/pattern_grammar/research_configs.json",       "live": true},
	{"name": "Reaction-Diffusion","key": "rd",           "path": "res://commons/rd_grammar/research_configs.json",            "live": true},
	{"name": "Primitive stack",  "key": "primitive_stack","path": "res://commons/primitive_grammar/research_configs.json",    "live": true},
	{"name": "Soft body / glass","key": "soft_body",     "path": "res://commons/soft_body/research_configs.json",             "live": true},
	{"name": "Graph grammar",    "key": "graph_grammar", "path": "res://commons/graph_grammar/research_configs.json",         "live": false},
	{"name": "Mesh grammar",     "key": "mesh_grammar",  "path": "res://commons/mesh_grammar/research_configs.json",          "live": false},
]

var _substrate_list: ItemList
var _config_list: ItemList
var _title: Label
var _current_substrate_index: int = 0
var _current_configs: Array = []


func _ready() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Title
	_title = Label.new()
	_title.text = "DNA Workstation · 10 substrates"
	_title.add_theme_font_size_override("font_size", 20)
	_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_title.position = Vector2(14, 10)
	_title.size = Vector2(780, 28)
	add_child(_title)

	# Subtitle / help
	var help := Label.new()
	help.text = "Substrate (left)  →  Config variant (right)  →  Loads in the presentation area"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	help.position = Vector2(14, 36)
	help.size = Vector2(780, 18)
	add_child(help)

	# Substrates list
	_substrate_list = ItemList.new()
	_substrate_list.position = Vector2(14, 62)
	_substrate_list.size = Vector2(240, 340)
	_substrate_list.add_theme_font_size_override("font_size", 14)
	add_child(_substrate_list)
	for s in SUBSTRATES:
		var suffix: String = "" if bool(s["live"]) else "  (config only)"
		_substrate_list.add_item(s["name"] + suffix)
	_substrate_list.item_selected.connect(_on_substrate_selected)

	# Configs list
	_config_list = ItemList.new()
	_config_list.position = Vector2(264, 62)
	_config_list.size = Vector2(520, 340)
	_config_list.add_theme_font_size_override("font_size", 13)
	add_child(_config_list)
	_config_list.item_selected.connect(_on_config_selected)

	# Select first substrate by default
	if SUBSTRATES.size() > 0:
		_substrate_list.select(0)
		_on_substrate_selected(0)


func _on_substrate_selected(idx: int) -> void:
	_current_substrate_index = idx
	_config_list.clear()
	_current_configs.clear()
	var path: String = SUBSTRATES[idx]["path"]
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		_config_list.add_item("(config file missing: %s)" % path)
		return
	var txt: String = FileAccess.get_file_as_string(path)
	var j := JSON.new()
	if j.parse(txt) != OK:
		_config_list.add_item("(invalid JSON)")
		return
	var lib = j.data
	var configs: Array = lib.get("configs", []) if lib is Dictionary else []
	_current_configs = configs
	for c in configs:
		var id: String = str(c.get("id", "?"))
		_config_list.add_item(id)


func _on_config_selected(idx: int) -> void:
	if idx < 0 or idx >= _current_configs.size(): return
	var cfg: Dictionary = _current_configs[idx]
	var substrate: String = SUBSTRATES[_current_substrate_index]["key"]
	var config_id: String = str(cfg.get("id", ""))
	_title.text = "%s · %s" % [SUBSTRATES[_current_substrate_index]["name"], config_id]
	emit_signal("dna_changed", substrate, config_id)


## Called externally to navigate by keyboard
func _on_next() -> void:
	var idx: int = _config_list.get_selected_items()[0] if _config_list.get_selected_items().size() > 0 else -1
	idx = (idx + 1) % max(_current_configs.size(), 1)
	if _current_configs.size() > 0:
		_config_list.select(idx)
		_on_config_selected(idx)


func _on_prev() -> void:
	var idx: int = _config_list.get_selected_items()[0] if _config_list.get_selected_items().size() > 0 else 0
	idx = (idx - 1 + _current_configs.size()) % max(_current_configs.size(), 1)
	if _current_configs.size() > 0:
		_config_list.select(idx)
		_on_config_selected(idx)


func _on_mode() -> void:
	var next_sub: int = (_current_substrate_index + 1) % SUBSTRATES.size()
	_substrate_list.select(next_sub)
	_on_substrate_selected(next_sub)
