# WordSynthDisplay.gd
# Displays word descriptors for each sound layer
# Shows the semantic tags that describe current synthesis settings

extends Control
class_name WordSynthDisplay

signal word_clicked(layer: String, word: String)
signal word_change_requested(layer: String, old_word: String, new_word: String)
signal layer_preview_requested(layer: String, params: Dictionary)
signal layer_selected(layer: String)

const WORD_MAP_PATH = "res://commons/audio/parameters/word_synthesis_map.json"

var _word_map: Dictionary = {}
var _layer_words: Dictionary = {}  # layer_name -> [words]
var _layer_params: Dictionary = {}  # layer_name -> {param: value}

var _container: VBoxContainer
var _layer_displays: Dictionary = {}  # layer_name -> Control
var _selected_layer: String = ""
var _param_panel: PanelContainer = null

# Colors for word categories
const COLORS = {
	"timbral": Color(0.9, 0.6, 0.3),
	"envelope": Color(0.3, 0.7, 0.9),
	"spatial": Color(0.6, 0.9, 0.5),
	"movement": Color(0.9, 0.4, 0.7),
	"experimental": Color(0.7, 0.3, 0.9)
}


func _ready():
	_load_word_map()
	_setup_ui()


func _load_word_map():
	if FileAccess.file_exists(WORD_MAP_PATH):
		var file = FileAccess.open(WORD_MAP_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		
		if error == OK:
			_word_map = json.data
			print("WordSynthDisplay: Loaded word map with %d timbral words" % _word_map.get("timbral_words", {}).size())
		else:
			push_warning("WordSynthDisplay: Failed to parse word map")
	else:
		push_warning("WordSynthDisplay: Word map not found at %s" % WORD_MAP_PATH)


func _setup_ui():
	_container = VBoxContainer.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.add_theme_constant_override("separation", 8)
	add_child(_container)
	
	# Header
	var header = Label.new()
	header.text = "🏷️ SOUND WORDS"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_container.add_child(header)


func set_layer_words(layer_name: String, words: Array, params: Dictionary = {}):
	"""Set the descriptive words for a layer"""
	_layer_words[layer_name] = words
	_layer_params[layer_name] = params
	_rebuild_layer_display(layer_name)


func clear_layer(layer_name: String):
	_layer_words.erase(layer_name)
	_layer_params.erase(layer_name)
	if _layer_displays.has(layer_name):
		_layer_displays[layer_name].queue_free()
		_layer_displays.erase(layer_name)


func clear_all():
	_layer_words.clear()
	_layer_params.clear()
	for display in _layer_displays.values():
		display.queue_free()
	_layer_displays.clear()


func _rebuild_layer_display(layer_name: String):
	# Remove existing display
	if _layer_displays.has(layer_name):
		_layer_displays[layer_name].queue_free()
	
	var words = _layer_words.get(layer_name, [])
	if words.is_empty():
		return
	
	# Create layer panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Header row: icon + name + preview button
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	
	# Layer name button (clickable to select/show config)
	var icon = _get_layer_icon(layer_name)
	var name_btn = Button.new()
	name_btn.text = "%s %s" % [icon, layer_name]
	name_btn.flat = true
	name_btn.add_theme_font_size_override("font_size", 14)
	name_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	name_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	name_btn.pressed.connect(_on_layer_name_clicked.bind(layer_name))
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_btn)
	
	# Preview button (plays just this layer)
	var preview_btn = Button.new()
	preview_btn.text = "▶"
	preview_btn.tooltip_text = "Preview %s" % layer_name
	preview_btn.custom_minimum_size = Vector2(28, 24)
	preview_btn.pressed.connect(_on_layer_preview.bind(layer_name))
	header.add_child(preview_btn)
	
	# Word tags (clickable)
	var word_flow = HFlowContainer.new()
	word_flow.add_theme_constant_override("h_separation", 6)
	word_flow.add_theme_constant_override("v_separation", 4)
	vbox.add_child(word_flow)
	
	for word in words:
		var tag = _create_word_tag(layer_name, word)
		word_flow.add_child(tag)
	
	# Param summary (collapsed by default, expands on layer click)
	var params = _layer_params.get(layer_name, {})
	var param_container = VBoxContainer.new()
	param_container.name = "params"
	param_container.visible = (_selected_layer == layer_name)
	vbox.add_child(param_container)
	
	if not params.is_empty():
		# Detailed param list
		for key in params.keys():
			var val = params[key]
			var param_row = HBoxContainer.new()
			param_row.add_theme_constant_override("separation", 8)
			
			var key_label = Label.new()
			key_label.text = key + ":"
			key_label.add_theme_font_size_override("font_size", 11)
			key_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			key_label.custom_minimum_size.x = 100
			param_row.add_child(key_label)
			
			var val_label = Label.new()
			if val is float:
				val_label.text = "%.3f" % val
			else:
				val_label.text = str(val)
			val_label.add_theme_font_size_override("font_size", 11)
			val_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
			param_row.add_child(val_label)
			
			param_container.add_child(param_row)
	
	_container.add_child(panel)
	_layer_displays[layer_name] = panel


func _create_word_tag(layer_name: String, word: String) -> Control:
	var btn = Button.new()
	btn.text = word
	btn.flat = false
	btn.add_theme_font_size_override("font_size", 12)
	
	var color = _get_word_color(word)
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5)
	style.set_corner_radius_all(3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.darkened(0.3)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.pressed.connect(_on_word_clicked.bind(layer_name, word))
	btn.tooltip_text = _get_word_tooltip(word)
	
	return btn


func _get_word_color(word: String) -> Color:
	# Check which category the word belongs to
	if _word_map.get("timbral_words", {}).has(word):
		return COLORS["timbral"]
	elif _word_map.get("envelope_words", {}).has(word):
		return COLORS["envelope"]
	elif _word_map.get("spatial_words", {}).has(word):
		return COLORS["spatial"]
	elif _word_map.get("movement_words", {}).has(word):
		return COLORS["movement"]
	elif _word_map.get("experimental_words", {}).has(word):
		return COLORS["experimental"]
	return Color(0.5, 0.5, 0.55)


const ALL_WORD_CATEGORIES = ["timbral_words", "envelope_words", "spatial_words", "movement_words", "experimental_words"]


func _get_word_tooltip(word: String) -> String:
	# Find word in map and return description + opposites
	for category in ALL_WORD_CATEGORIES:
		if _word_map.get(category, {}).has(word):
			var data = _word_map[category][word]
			var tip = data.get("description", "")
			var opposites = data.get("opposites", [])
			if not opposites.is_empty():
				tip += "\nOpposites: " + ", ".join(opposites)
			return tip
	return ""


func _get_layer_icon(layer_name: String) -> String:
	match layer_name.to_lower():
		"bass": return "🎸"
		"pad": return "🌊"
		"lead": return "🎹"
		"keys": return "🎹"
		"drums": return "🥁"
		"seq", "sequencer": return "⏱️"
		"fx", "effects": return "🌀"
		_: return "🔊"


func _on_word_clicked(layer_name: String, word: String):
	word_clicked.emit(layer_name, word)
	
	# Show available alternatives (opposites)
	var opposites = _get_opposites(word)
	if not opposites.is_empty():
		print("WordSynthDisplay: '%s' clicked. Opposites: %s" % [word, opposites])


func _on_layer_name_clicked(layer_name: String):
	"""Toggle param display for this layer"""
	if _selected_layer == layer_name:
		_selected_layer = ""  # Collapse
	else:
		_selected_layer = layer_name  # Expand
	
	# Update visibility of all param containers
	for lname in _layer_displays.keys():
		var panel = _layer_displays[lname]
		var param_container = panel.find_child("params", true, false)
		if param_container:
			param_container.visible = (_selected_layer == lname)
	
	layer_selected.emit(layer_name)


func _on_layer_preview(layer_name: String):
	"""Request preview of just this layer"""
	var params = _layer_params.get(layer_name, {})
	var words = _layer_words.get(layer_name, [])
	
	# Collect all word params
	var all_params = params.duplicate()
	for word in words:
		var word_params = get_word_params(word)
		for key in word_params.keys():
			if not all_params.has(key):
				all_params[key] = word_params[key]
	
	print("WordSynthDisplay: Preview '%s' with params: %s" % [layer_name, all_params])
	layer_preview_requested.emit(layer_name, all_params)


func get_layer_params(layer_name: String) -> Dictionary:
	"""Get combined params for a layer (explicit + from words)"""
	var params = _layer_params.get(layer_name, {}).duplicate()
	var words = _layer_words.get(layer_name, [])
	
	for word in words:
		var word_params = get_word_params(word)
		for key in word_params.keys():
			if not params.has(key):
				params[key] = word_params[key]
	
	return params


func _get_opposites(word: String) -> Array:
	for category in ALL_WORD_CATEGORIES:
		if _word_map.get(category, {}).has(word):
			return _word_map[category][word].get("opposites", [])
	return []


# Get params for a word
func get_word_params(word: String) -> Dictionary:
	for category in ALL_WORD_CATEGORIES:
		if _word_map.get(category, {}).has(word):
			return _word_map[category][word].get("params", {})
	return {}


# Translate a word change to param changes
func translate_word_change(old_word: String, new_word: String) -> Dictionary:
	"""Returns param changes needed to go from old_word to new_word"""
	var old_params = get_word_params(old_word)
	var new_params = get_word_params(new_word)
	
	var changes = {}
	for param in new_params.keys():
		var new_val = new_params[param]
		if new_val is Dictionary:
			# Has range - pick tendency or middle
			if new_val.has("value"):
				changes[param] = new_val["value"]
			elif new_val.has("range"):
				var r = new_val["range"]
				var tendency = new_val.get("tendency", "middle")
				match tendency:
					"low": changes[param] = r[0] + (r[1] - r[0]) * 0.25
					"high": changes[param] = r[0] + (r[1] - r[0]) * 0.75
					_: changes[param] = (r[0] + r[1]) / 2.0
		else:
			changes[param] = new_val
	
	return changes


# Load preset words for a layer type
func load_layer_preset(layer_name: String, preset_type: String):
	var templates = _word_map.get("layer_templates", {})
	if templates.has(preset_type):
		var template = templates[preset_type]
		set_layer_words(layer_name, template.get("typical_words", []))
