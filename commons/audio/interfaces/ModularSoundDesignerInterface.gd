# ModularSoundDesignerInterface.gd
# Modular interface with working parameter controls and master bus visualization
# Uses Ada UI Design System for consistent styling
#
# Apply ada_theme.tres to the root Control (or parent scene) for automatic
# Button/Slider/Label theming. This script only sets colors that the theme
# can't reach (dynamic StyleBoxes created at runtime).

extends Control
class_name ModularSoundDesignerInterface

# ── Palette shorthand (no autoload needed) ──
const _P = preload("res://commons/ui/ada_palette.gd")

# ── Core UI References ──
var sound_type_option: OptionButton
var preview_button: Button
var stop_button: Button
var realtime_toggle: CheckBox
var parameters_container: VBoxContainer

# ── Audio ──
var audio_player: AudioStreamPlayer
var current_sound_type: AudioSynthesizer.SoundType = AudioSynthesizer.SoundType.BASIC_SINE_WAVE

# ── Real-time update system ──
var realtime_enabled: bool = true
var update_timer: Timer
var needs_audio_update: bool = false

# ── Parameter tracking ──
var parameter_controls = {}
var value_labels = {}

# ── Audio Visualization ──
var audio_visualization: Node
var master_bus_index: int

# ── Sound data (loaded from JSON) ──
var sound_parameters = {}
var sound_names = {}
var sound_type_mapping = {}
var ordered_sound_types = []

# ═══════════════════════════════════════════
#  INIT
# ═══════════════════════════════════════════

func _ready():
	_load_sound_parameters_from_folder()
	_setup_audio_system()
	_initialize_interface()
	_setup_master_bus_visualization()
	_connect_signals()

func _setup_audio_system():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	update_timer = Timer.new()
	update_timer.wait_time = 0.1
	update_timer.timeout.connect(_on_realtime_update)
	add_child(update_timer)
	update_timer.start()

# ═══════════════════════════════════════════
#  INTERFACE LAYOUT
# ═══════════════════════════════════════════

func _initialize_interface():
	# ── Main vertical stack ──
	var main = VBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("separation", 12)
	add_child(main)

	# ── Top bar ──
	var top_bar = _build_top_bar()
	main.add_child(top_bar)

	# ── Separator ──
	main.add_child(HSeparator.new())

	# ── Content split: params | visualization ──
	var splitter = HSplitContainer.new()
	splitter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(splitter)

	# Left: scrollable parameter list
	var params_scroll = ScrollContainer.new()
	params_scroll.custom_minimum_size = Vector2(420, 300)
	params_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splitter.add_child(params_scroll)

	parameters_container = VBoxContainer.new()
	parameters_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	params_scroll.add_child(parameters_container)

	# Right: audio visualization
	var viz = _build_visualization_panel()
	splitter.add_child(viz)

	_populate_sound_types()
	create_parameter_controls()

func _build_top_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)

	var lbl = Label.new()
	lbl.text = "Sound:"
	bar.add_child(lbl)

	sound_type_option = OptionButton.new()
	sound_type_option.custom_minimum_size = Vector2(220, 0)
	bar.add_child(sound_type_option)

	preview_button = Button.new()
	preview_button.text = "▶  Preview"
	bar.add_child(preview_button)

	stop_button = Button.new()
	stop_button.text = "■  Stop"
	bar.add_child(stop_button)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	realtime_toggle = CheckBox.new()
	realtime_toggle.text = "Real-time"
	realtime_toggle.button_pressed = true
	bar.add_child(realtime_toggle)

	return bar

func _build_visualization_panel() -> VBoxContainer:
	var viz = VBoxContainer.new()
	viz.custom_minimum_size = Vector2(400, 300)
	viz.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title = Label.new()
	title.text = "Master Bus"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _P.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", _P.TEXT_SECONDARY)
	viz.add_child(title)

	var panel = Panel.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viz.add_child(panel)

	# Dark background for oscilloscope-style display
	var dark_style = StyleBoxFlat.new()
	dark_style.bg_color = _P.SCREEN_BG
	dark_style.corner_radius_top_left = _P.CORNER_RADIUS
	dark_style.corner_radius_top_right = _P.CORNER_RADIUS
	dark_style.corner_radius_bottom_left = _P.CORNER_RADIUS
	dark_style.corner_radius_bottom_right = _P.CORNER_RADIUS
	panel.add_theme_stylebox_override("panel", dark_style)

	audio_visualization = preload("res://commons/audio/components/AudioVisualizationComponent.gd").new()
	panel.add_child(audio_visualization)

	return viz

# ═══════════════════════════════════════════
#  PARAMETER CONTROLS
# ═══════════════════════════════════════════

func create_parameter_controls():
	if not parameters_container:
		return

	for child in parameters_container.get_children():
		child.queue_free()
	parameter_controls.clear()
	value_labels.clear()

	var sound_key = get_sound_key_from_type(current_sound_type)
	var params = sound_parameters.get(sound_key, {})
	if params.is_empty():
		return

	# Title
	var title = Label.new()
	title.text = sound_names.get(sound_key, sound_key.capitalize())
	title.add_theme_font_size_override("font_size", _P.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", _P.TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parameters_container.add_child(title)

	# 3-column grid
	var columns_box = HBoxContainer.new()
	columns_box.add_theme_constant_override("separation", 12)
	columns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameters_container.add_child(columns_box)

	var cols: Array[VBoxContainer] = []
	for i in 3:
		var col = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 6)
		columns_box.add_child(col)
		cols.append(col)

	await get_tree().process_frame

	var keys = params.keys()
	for i in keys.size():
		var pname = keys[i]
		_create_param_card(cols[i % 3], pname, params[pname])

func _create_param_card(column: VBoxContainer, param_name: String, config: Dictionary):
	"""A single parameter: label + value readout + slider or dropdown."""
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = _P.PANEL_LIGHT
	card_style.corner_radius_top_left = _P.CORNER_RADIUS
	card_style.corner_radius_top_right = _P.CORNER_RADIUS
	card_style.corner_radius_bottom_left = _P.CORNER_RADIUS
	card_style.corner_radius_bottom_right = _P.CORNER_RADIUS
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)
	column.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Parameter name
	var lbl = Label.new()
	lbl.text = param_name.capitalize().replace("_", " ")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", _P.FONT_SIZE_SMALL)
	lbl.add_theme_color_override("font_color", _P.TEXT_SECONDARY)
	vbox.add_child(lbl)

	# Value readout
	var val_lbl = Label.new()
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", _P.FONT_SIZE_LABEL)
	val_lbl.add_theme_color_override("font_color", _P.ACCENT_ORANGE)
	vbox.add_child(val_lbl)
	value_labels[param_name] = val_lbl

	# Control
	if config.has("options"):
		_add_option_control(vbox, param_name, config)
	else:
		_add_slider_control(vbox, param_name, config)

func _add_slider_control(container: VBoxContainer, param_name: String, config: Dictionary):
	var slider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("value", 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(140, 20)
	# Theme handles the slider styling (ada_theme.tres)
	slider.value_changed.connect(func(v): _on_slider_changed(param_name, v))
	container.add_child(slider)
	parameter_controls[param_name] = slider
	update_value_label(param_name, slider.value)

func _add_option_control(container: VBoxContainer, param_name: String, config: Dictionary):
	var opt = OptionButton.new()
	var options = config.get("options", [])
	var current = config.get("value", "")
	opt.custom_minimum_size = Vector2(140, 0)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for o in options:
		opt.add_item(o)
	for i in opt.get_item_count():
		if opt.get_item_text(i) == current:
			opt.selected = i
			break
	opt.item_selected.connect(func(idx): _on_option_changed(param_name, idx))
	container.add_child(opt)
	parameter_controls[param_name] = opt
	update_value_label(param_name, current)

# ═══════════════════════════════════════════
#  SIGNALS
# ═══════════════════════════════════════════

func _connect_signals():
	if sound_type_option:
		sound_type_option.item_selected.connect(_on_sound_type_changed)
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	if realtime_toggle:
		realtime_toggle.toggled.connect(_on_realtime_toggled)

func _on_slider_changed(param_name: String, value: float):
	var sound_key = get_sound_key_from_type(current_sound_type)
	if sound_parameters.has(sound_key) and sound_parameters[sound_key].has(param_name):
		if sound_parameters[sound_key][param_name] is Dictionary:
			sound_parameters[sound_key][param_name]["value"] = value
	update_value_label(param_name, value)
	if realtime_enabled:
		update_audio_immediately()

func _on_option_changed(param_name: String, index: int):
	var opt = parameter_controls[param_name] as OptionButton
	var value = opt.get_item_text(index)
	var sound_key = get_sound_key_from_type(current_sound_type)
	if sound_parameters.has(sound_key) and sound_parameters[sound_key].has(param_name):
		if sound_parameters[sound_key][param_name] is Dictionary:
			sound_parameters[sound_key][param_name]["value"] = value
	update_value_label(param_name, value)
	if realtime_enabled:
		update_audio_immediately()

func _on_sound_type_changed(index: int):
	if index >= 0 and index < ordered_sound_types.size():
		current_sound_type = ordered_sound_types[index]
		create_parameter_controls()

func _on_preview_pressed():
	update_audio_immediately()

func _on_stop_pressed():
	if audio_player and audio_player.playing:
		audio_player.stop()

func _on_realtime_toggled(enabled: bool):
	realtime_enabled = enabled
	if enabled:
		update_audio_immediately()
	elif audio_player and audio_player.playing:
		audio_player.stop()

func _on_realtime_update():
	if needs_audio_update and realtime_enabled:
		needs_audio_update = false
		update_audio_immediately()

# ═══════════════════════════════════════════
#  AUDIO
# ═══════════════════════════════════════════

func update_audio_immediately():
	if not audio_player:
		return
	if audio_player.playing:
		audio_player.stop()

	var sound_key = get_sound_key_from_type(current_sound_type)
	var params = get_current_parameter_values(sound_key)
	var stream = CustomSoundGenerator.generate_custom_sound(current_sound_type, params)
	if stream:
		audio_player.stream = stream
		audio_player.play()

func get_current_parameter_values(sound_key: String) -> Dictionary:
	var params = {}
	if not sound_parameters.has(sound_key):
		return params
	for pname in sound_parameters[sound_key].keys():
		var cfg = sound_parameters[sound_key][pname]
		if cfg is Dictionary and cfg.has("value"):
			params[pname] = cfg["value"]
		else:
			params[pname] = 0.0
	return params

func _setup_master_bus_visualization():
	master_bus_index = AudioServer.get_bus_index("Master")
	if audio_visualization and audio_visualization.has_method("setup_master_bus_monitoring"):
		audio_visualization.setup_master_bus_monitoring(master_bus_index)

# ═══════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════

func update_value_label(param_name: String, value):
	if value_labels.has(param_name):
		value_labels[param_name].text = str(value) if value is String else "%.3f" % value

func get_sound_key_from_type(sound_type: AudioSynthesizer.SoundType) -> String:
	if sound_type_mapping.has(sound_type):
		return sound_type_mapping[sound_type]
	if sound_parameters.size() > 0:
		return sound_parameters.keys()[0]
	return "basic_sine_wave"

func _populate_sound_types():
	ordered_sound_types = AudioSynthesizer.get_all_sound_types()
	sound_type_option.clear()
	for st in ordered_sound_types:
		var key = get_sound_key_from_type(st)
		if key != "" and sound_names.has(key):
			sound_type_option.add_item(sound_names[key])
		else:
			sound_type_option.add_item(AudioSynthesizer.get_sound_type_name(st))

# ═══════════════════════════════════════════
#  DATA LOADING
# ═══════════════════════════════════════════

func _load_sound_parameters_from_folder():
	sound_parameters.clear()
	sound_names.clear()
	sound_type_mapping.clear()

	sound_parameters = EnhancedParameterLoader.load_all_parameters()

	if sound_parameters.size() == 0:
		_load_fallback_parameters()
		return

	for sound_key in sound_parameters.keys():
		_create_display_name(sound_key)

	_create_sound_type_mappings()

func _create_display_name(sound_key: String):
	var display = sound_key.capitalize().replace("_", " ")
	var emoji_map = {
		"kick": "🥁", "808": "🥁", "drum": "🥁",
		"hihat": "🔥", "hat": "🔥", "bass": "🎵", "sub": "🎵",
		"drone": "🌌", "ambient": "🌌", "laser": "🔫",
		"pickup": "🪙", "mario": "🪙", "explosion": "💥",
		"jump": "🟢", "sine": "〰️", "basic": "〰️",
		"disco": "🕺", "cosmic": "🛸", "moog": "🎹",
	}
	for kw in emoji_map.keys():
		if sound_key.to_lower().contains(kw):
			display = emoji_map[kw] + " " + display
			break
	sound_names[sound_key] = display

func _create_sound_type_mappings():
	sound_type_mapping.clear()
	for sound_key in sound_parameters.keys():
		var enum_name = sound_key.to_upper()
		if AudioSynthesizer.SoundType.has(enum_name):
			sound_type_mapping[AudioSynthesizer.SoundType[enum_name]] = sound_key
	if sound_type_mapping.is_empty():
		sound_type_mapping[AudioSynthesizer.SoundType.BASIC_SINE_WAVE] = "basic_sine_wave"

func _load_fallback_parameters():
	sound_parameters = {
		"basic_sine_wave": {
			"duration": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
			"frequency": {"value": 440.0, "min": 20.0, "max": 2000.0, "step": 1.0},
			"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		}
	}
	sound_names = {"basic_sine_wave": "〰️ Basic Sine Wave"}
	sound_type_mapping = {AudioSynthesizer.SoundType.BASIC_SINE_WAVE: "basic_sine_wave"}
