# SoundIdentityPanel.gd
# Visualizes a SoundIdentity with multiple views:
# - Traits (words with confidence)
# - Features (radar/bars)
# - Recipe (signal chain)
# - Explanations (click trait → see why)

extends PanelContainer
class_name SoundIdentityPanel

const SoundIdentity = preload("res://commons/audio/catalog/SoundIdentity.gd")

signal trait_clicked(trait_name: String)
signal param_clicked(param_name: String)
signal recipe_node_clicked(node_index: int)

var _identity: SoundIdentity = null

# UI elements
var _title_label: Label
var _type_label: Label
var _recipe_label: Label
var _traits_container: VBoxContainer
var _features_container: VBoxContainer
var _explanation_panel: PanelContainer
var _explanation_label: RichTextLabel

# Feature colors
const FEATURE_COLORS = {
	"brightness": Color(1.0, 0.9, 0.3),
	"warmth": Color(1.0, 0.5, 0.2),
	"thickness": Color(0.4, 0.8, 0.4),
	"aggression": Color(1.0, 0.3, 0.3),
	"space": Color(0.5, 0.4, 0.9),
	"movement": Color(0.3, 0.8, 1.0),
	"attack_speed": Color(0.9, 0.5, 0.7),
	"decay_length": Color(0.6, 0.7, 0.5),
	"width": Color(0.7, 0.6, 0.9)
}

# Trait category colors
const CATEGORY_COLORS = {
	"timbral": Color(0.9, 0.6, 0.3),
	"envelope": Color(0.3, 0.7, 0.9),
	"spatial": Color(0.6, 0.4, 0.9),
	"movement": Color(0.3, 0.9, 0.7),
	"character": Color(0.7, 0.7, 0.7)
}


func _ready():
	_setup_ui()


func _setup_ui():
	# Main style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(main_vbox)
	
	# === HEADER ===
	var header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	main_vbox.add_child(header)
	
	_title_label = Label.new()
	_title_label.text = "🔬 SOUND IDENTITY"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header.add_child(_title_label)
	
	_type_label = Label.new()
	_type_label.text = "Type: unknown"
	_type_label.add_theme_font_size_override("font_size", 13)
	_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	header.add_child(_type_label)
	
	# === RECIPE (Signal Chain) ===
	var recipe_section = _create_section("📡 Signal Chain", Color(0.5, 0.7, 0.9))
	main_vbox.add_child(recipe_section)
	
	_recipe_label = Label.new()
	_recipe_label.text = "[osc] → [filter] → [env] → [out]"
	_recipe_label.add_theme_font_size_override("font_size", 12)
	_recipe_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	_recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	recipe_section.get_child(0).add_child(_recipe_label)
	
	# === FEATURES (Bars) ===
	var features_section = _create_section("📊 Features", Color(0.6, 0.8, 0.5))
	main_vbox.add_child(features_section)
	
	_features_container = VBoxContainer.new()
	_features_container.add_theme_constant_override("separation", 4)
	features_section.get_child(0).add_child(_features_container)
	
	# === TRAITS (Words) ===
	var traits_section = _create_section("🏷️ Traits", Color(0.9, 0.6, 0.3))
	main_vbox.add_child(traits_section)
	
	_traits_container = VBoxContainer.new()
	_traits_container.add_theme_constant_override("separation", 8)
	traits_section.get_child(0).add_child(_traits_container)
	
	# === EXPLANATION (Click for details) ===
	_explanation_panel = PanelContainer.new()
	var exp_style = StyleBoxFlat.new()
	exp_style.bg_color = Color(0.1, 0.1, 0.12)
	exp_style.set_corner_radius_all(6)
	exp_style.content_margin_left = 12
	exp_style.content_margin_right = 12
	exp_style.content_margin_top = 8
	exp_style.content_margin_bottom = 8
	_explanation_panel.add_theme_stylebox_override("panel", exp_style)
	_explanation_panel.visible = false
	main_vbox.add_child(_explanation_panel)
	
	var exp_vbox = VBoxContainer.new()
	exp_vbox.add_theme_constant_override("separation", 4)
	_explanation_panel.add_child(exp_vbox)
	
	var exp_title = Label.new()
	exp_title.text = "💡 Why?"
	exp_title.add_theme_font_size_override("font_size", 14)
	exp_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	exp_vbox.add_child(exp_title)
	
	_explanation_label = RichTextLabel.new()
	_explanation_label.bbcode_enabled = true
	_explanation_label.fit_content = true
	_explanation_label.scroll_active = false
	_explanation_label.add_theme_font_size_override("normal_font_size", 12)
	exp_vbox.add_child(_explanation_label)


func _create_section(title: String, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	vbox.add_child(label)
	
	return panel


func set_identity(identity: SoundIdentity):
	_identity = identity
	_update_display()


func set_from_params(layer: String, params: Dictionary):
	_identity = SoundIdentity.from_params(layer, params)
	_update_display()


func _update_display():
	if _identity == null:
		return
	
	# Header
	_title_label.text = "🔬 %s" % _identity.name
	_type_label.text = "Type: %s | Layer: %s" % [_identity.synth_type, _identity.layer_type]
	
	# Recipe
	_recipe_label.text = _identity.get_recipe_string()
	
	# Features
	_update_features()
	
	# Traits
	_update_traits()
	
	# Hide explanation until trait clicked
	_explanation_panel.visible = false


func _update_features():
	# Clear existing
	for child in _features_container.get_children():
		child.queue_free()
	
	# Add feature bars
	var feature_order = ["brightness", "warmth", "thickness", "aggression", "space", "movement", "width", "attack_speed", "decay_length"]
	
	for feature_name in feature_order:
		if _identity.features.has(feature_name):
			var value = _identity.features[feature_name]
			var bar = _create_feature_bar(feature_name, value)
			_features_container.add_child(bar)


func _create_feature_bar(name: String, value: float) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	# Label
	var label = Label.new()
	label.text = name.replace("_", " ").capitalize()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	label.custom_minimum_size.x = 80
	row.add_child(label)
	
	# Bar container
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(120, 12)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_container)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.18)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_container.add_child(bg)
	
	# Fill
	var fill = ColorRect.new()
	fill.color = FEATURE_COLORS.get(name, Color.WHITE)
	fill.anchor_right = value
	fill.offset_right = 0
	fill.anchor_bottom = 1.0
	fill.offset_bottom = 0
	bar_container.add_child(fill)
	
	# Value label
	var val_label = Label.new()
	val_label.text = "%.0f%%" % (value * 100)
	val_label.add_theme_font_size_override("font_size", 10)
	val_label.add_theme_color_override("font_color", FEATURE_COLORS.get(name, Color.WHITE))
	val_label.custom_minimum_size.x = 35
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_label)
	
	return row


func _update_traits():
	# Clear existing
	for child in _traits_container.get_children():
		child.queue_free()
	
	# Add traits by category
	for category in _identity.traits.keys():
		var trait_list = _identity.traits[category]
		if trait_list.is_empty():
			continue
		
		# Category label
		var cat_label = Label.new()
		cat_label.text = category.capitalize()
		cat_label.add_theme_font_size_override("font_size", 11)
		cat_label.add_theme_color_override("font_color", CATEGORY_COLORS.get(category, Color.GRAY))
		_traits_container.add_child(cat_label)
		
		# Trait tags
		var flow = HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 4)
		_traits_container.add_child(flow)
		
		for trait_name in trait_list:
			var tag = _create_trait_tag(trait_name, category)
			flow.add_child(tag)


func _create_trait_tag(trait_name: String, category: String) -> Button:
	var btn = Button.new()
	btn.text = trait_name
	btn.add_theme_font_size_override("font_size", 12)
	
	var color = CATEGORY_COLORS.get(category, Color.GRAY)
	var confidence = _identity.trait_confidence.get(trait_name, 0.5)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.6)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	# Border indicates confidence
	style.set_border_width_all(int(confidence * 2))
	style.border_color = color
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.darkened(0.4)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.pressed.connect(_on_trait_clicked.bind(trait_name))
	btn.tooltip_text = "Click for explanation (%.0f%% confidence)" % (confidence * 100)
	
	return btn


func _on_trait_clicked(trait_name: String):
	trait_clicked.emit(trait_name)
	_show_explanation(trait_name)


func _show_explanation(trait_name: String):
	_explanation_panel.visible = true
	
	var explanation = _identity.get_trait_explanation(trait_name)
	var suggestions = _identity.suggest_changes_for_trait(trait_name)
	
	var bbcode = "[b]%s[/b]\n\n" % trait_name.capitalize()
	bbcode += "[color=#aaaaaa]Why this sound has this trait:[/color]\n"
	
	for line in explanation.split("\n"):
		if line.length() > 0:
			bbcode += "• %s\n" % line
	
	if not suggestions.is_empty():
		bbcode += "\n[color=#aaaaaa]To change this trait:[/color]\n"
		for param in suggestions.keys():
			bbcode += "• %s %s\n" % [suggestions[param], param]
	
	_explanation_label.text = bbcode


func clear():
	_identity = null
	_title_label.text = "🔬 SOUND IDENTITY"
	_type_label.text = "Select a sound"
	_recipe_label.text = ""
	
	for child in _features_container.get_children():
		child.queue_free()
	for child in _traits_container.get_children():
		child.queue_free()
	
	_explanation_panel.visible = false
