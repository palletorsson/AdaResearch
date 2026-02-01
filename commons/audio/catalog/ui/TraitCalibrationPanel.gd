# TraitCalibrationPanel.gd
# UI for adjusting trait detection thresholds
# Allows real-time calibration of "how bright is bright?"

extends PanelContainer
class_name TraitCalibrationPanel

signal threshold_changed(trait_name: String, key: String, value: float)
signal calibration_saved()

const WORD_MAP_PATH = "res://commons/audio/parameters/word_synthesis_map.json"

var _sliders: Dictionary = {}  # trait_name → {min: Slider, max: Slider}
var _current_rules: Dictionary = {}
var _test_identity: SoundIdentity = null

# UI elements
var _traits_container: VBoxContainer
var _preview_label: RichTextLabel
var _save_btn: Button


func _ready():
	_setup_ui()
	_load_current_rules()
	_populate_sliders()


func _setup_ui():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "🎚️ TRAIT THRESHOLDS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	_save_btn = Button.new()
	_save_btn.text = "💾 Save"
	_save_btn.pressed.connect(_save_to_json)
	header.add_child(_save_btn)
	
	var reset_btn = Button.new()
	reset_btn.text = "↺ Reset"
	reset_btn.pressed.connect(_reset_to_defaults)
	header.add_child(reset_btn)
	
	# Description
	var desc = Label.new()
	desc.text = "Adjust thresholds for trait detection. Lower min = easier to trigger."
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	main_vbox.add_child(desc)
	
	# Scroll container for traits
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 300
	main_vbox.add_child(scroll)
	
	_traits_container = VBoxContainer.new()
	_traits_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_traits_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_traits_container)
	
	# Preview area
	var preview_panel = PanelContainer.new()
	var preview_style = StyleBoxFlat.new()
	preview_style.bg_color = Color(0.06, 0.06, 0.08)
	preview_style.set_corner_radius_all(4)
	preview_style.content_margin_left = 8
	preview_style.content_margin_right = 8
	preview_style.content_margin_top = 6
	preview_style.content_margin_bottom = 6
	preview_panel.add_theme_stylebox_override("panel", preview_style)
	main_vbox.add_child(preview_panel)
	
	_preview_label = RichTextLabel.new()
	_preview_label.bbcode_enabled = true
	_preview_label.fit_content = true
	_preview_label.scroll_active = false
	_preview_label.text = "[color=#666666]Select a sound to preview trait detection[/color]"
	preview_panel.add_child(_preview_label)


func _load_current_rules():
	"""Load current trait rules from JSON"""
	if FileAccess.file_exists(WORD_MAP_PATH):
		var file = FileAccess.open(WORD_MAP_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		
		if error == OK:
			_current_rules = json.data.get("trait_rules", {})


func _populate_sliders():
	"""Create sliders for each trait threshold"""
	# Clear existing
	for child in _traits_container.get_children():
		child.queue_free()
	_sliders.clear()
	
	# Group traits by category
	var categories = {}
	for trait_name in _current_rules.keys():
		var rule = _current_rules[trait_name]
		var category = rule.get("category", "other")
		if not categories.has(category):
			categories[category] = []
		categories[category].append(trait_name)
	
	# Create UI for each category
	for category in ["timbral", "envelope", "spatial", "movement", "character"]:
		if not categories.has(category):
			continue
		
		# Category header
		var cat_label = Label.new()
		cat_label.text = category.capitalize()
		cat_label.add_theme_font_size_override("font_size", 14)
		cat_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		_traits_container.add_child(cat_label)
		
		# Traits in this category
		for trait_name in categories[category]:
			var rule = _current_rules[trait_name]
			var row = _create_trait_row(trait_name, rule)
			_traits_container.add_child(row)


func _create_trait_row(trait_name: String, rule: Dictionary) -> Control:
	"""Create a row with sliders for a trait"""
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	# Trait name
	var name_label = Label.new()
	name_label.text = trait_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	name_label.custom_minimum_size.x = 80
	row.add_child(name_label)
	
	_sliders[trait_name] = {}
	
	# Feature-based rules have min or max
	if rule.has("feature"):
		if rule.has("min"):
			var min_slider = _create_threshold_slider(trait_name, "min", rule["min"])
			row.add_child(min_slider)
			_sliders[trait_name]["min"] = min_slider.get_child(1)  # The HSlider
		
		if rule.has("max"):
			var max_slider = _create_threshold_slider(trait_name, "max", rule["max"])
			row.add_child(max_slider)
			_sliders[trait_name]["max"] = max_slider.get_child(1)
	
	# Param-based rules
	if rule.has("param") and rule.has("min") and not rule.has("feature"):
		var min_slider = _create_threshold_slider(trait_name, "min", rule["min"], 0.0, 1.0)
		row.add_child(min_slider)
		_sliders[trait_name]["min"] = min_slider.get_child(1)
	
	if rule.has("param") and rule.has("max") and not rule.has("feature"):
		var max_slider = _create_threshold_slider(trait_name, "max", rule["max"], 0.0, 1.0)
		row.add_child(max_slider)
		_sliders[trait_name]["max"] = max_slider.get_child(1)
	
	return row


func _create_threshold_slider(trait_name: String, key: String, value: float, min_val: float = 0.0, max_val: float = 1.0) -> Control:
	"""Create a labeled slider for a threshold"""
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	
	# Label
	var label = Label.new()
	label.text = key + ":"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	label.custom_minimum_size.x = 30
	container.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = value
	slider.step = 0.05
	slider.custom_minimum_size.x = 80
	slider.value_changed.connect(_on_threshold_changed.bind(trait_name, key))
	container.add_child(slider)
	
	# Value display
	var val_label = Label.new()
	val_label.text = "%.2f" % value
	val_label.add_theme_font_size_override("font_size", 10)
	val_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	val_label.custom_minimum_size.x = 35
	container.add_child(val_label)
	
	slider.value_changed.connect(func(v): val_label.text = "%.2f" % v)
	
	return container


func _on_threshold_changed(value: float, trait_name: String, key: String):
	"""Handle threshold slider change"""
	if _current_rules.has(trait_name):
		_current_rules[trait_name][key] = value
	
	threshold_changed.emit(trait_name, key, value)
	_update_preview()


func set_test_sound(identity: SoundIdentity):
	"""Set a sound to preview trait detection"""
	_test_identity = identity
	_update_preview()


func _update_preview():
	"""Update preview showing which traits would be detected"""
	if _test_identity == null:
		_preview_label.text = "[color=#666666]No sound selected for preview[/color]"
		return
	
	# Re-derive traits with current rules
	# Note: This modifies _trait_rules in memory (not saved yet)
	SoundIdentity._trait_rules = _current_rules
	SoundIdentity._trait_rules_loaded = true
	
	# Create fresh identity to test
	var test = SoundIdentity.from_params(_test_identity.name, _test_identity.params)
	
	var text = "[b]Preview:[/b] "
	var all_traits = test.get_all_traits()
	if all_traits.is_empty():
		text += "[color=#666666](no traits detected)[/color]"
	else:
		var trait_strs = []
		for t in all_traits:
			var conf = test.trait_confidence.get(t, 0.5)
			var color = "aaffaa" if conf > 0.7 else "ffff88" if conf > 0.5 else "ffaa88"
			trait_strs.append("[color=#%s]%s (%.0f%%)[/color]" % [color, t, conf * 100])
		text += ", ".join(trait_strs)
	
	_preview_label.text = text


func _save_to_json():
	"""Save current thresholds back to JSON"""
	if not FileAccess.file_exists(WORD_MAP_PATH):
		push_error("TraitCalibrationPanel: Cannot save - JSON file not found")
		return
	
	# Read current file
	var file = FileAccess.open(WORD_MAP_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("TraitCalibrationPanel: Cannot parse JSON")
		return
	
	# Update trait_rules
	var data = json.data
	data["trait_rules"] = _current_rules
	
	# Write back
	file = FileAccess.open(WORD_MAP_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	
	# Force reload
	SoundIdentity._trait_rules_loaded = false
	
	print("TraitCalibrationPanel: Saved %d trait rules to JSON" % _current_rules.size())
	calibration_saved.emit()


func _reset_to_defaults():
	"""Reset to default thresholds"""
	var defaults = {
		"bright": 0.65, "dark": 0.35,
		"warm": 0.55, "cold": 0.3,
		"thick": 0.55, "thin": 0.3,
		"aggressive": 0.55, "soft": 0.3,
		"spacious": 0.55, "dry": 0.2,
		"wide": 0.6, "narrow": 0.3,
		"evolving": 0.4, "static": 0.15,
		"punchy": 0.85, "plucky": 0.8, "swelling": 0.3
	}
	
	for trait_name in defaults.keys():
		if _current_rules.has(trait_name):
			var rule = _current_rules[trait_name]
			if rule.has("min"):
				rule["min"] = defaults[trait_name]
				if _sliders.has(trait_name) and _sliders[trait_name].has("min"):
					_sliders[trait_name]["min"].value = defaults[trait_name]
			elif rule.has("max"):
				rule["max"] = defaults[trait_name]
				if _sliders.has(trait_name) and _sliders[trait_name].has("max"):
					_sliders[trait_name]["max"].value = defaults[trait_name]
	
	_update_preview()
