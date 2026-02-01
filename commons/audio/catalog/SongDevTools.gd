# SongDevTools.gd
# Enhanced song development environment with:
# - Hot parameter tweaking
# - Section looping
# - Layer solo/mute
# - A/B snapshots
# - Visual feedback (oscilloscope/spectrum)
# - Parameter randomization

extends Control

const SongTimeline = preload("res://commons/audio/catalog/ui/SongTimeline.gd")
const WordSynthDisplay = preload("res://commons/audio/catalog/ui/WordSynthDisplay.gd")
const WordSynthBridge = preload("res://commons/audio/catalog/WordSynthBridge.gd")
# AudioSynthesizer is available via class_name - no preload needed

# Word→Synth bridge for semantic parameter control
var _word_bridge: WordSynthBridge

# Audio
var _player: AudioStreamPlayer
var _current_song: String = ""
var _is_playing: bool = false
var _current_stream: AudioStreamInteractive = null
var _playback_time: float = 0.0  # Manual time tracking (AudioStreamInteractive doesn't report position)

# Looping
var _loop_enabled: bool = false
var _loop_start: float = 0.0
var _loop_end: float = 0.0

# UI Components
var _title_label: Label
var _status_label: Label
var _song_buttons: Dictionary = {}
var _play_btn: Button
var _stop_btn: Button
var _loop_btn: Button
var _section_dropdown: OptionButton

# Timeline
var _timeline: SongTimeline
var _timeline_container: PanelContainer

# Dev Tools Panel
var _dev_panel: PanelContainer
var _layer_controls: VBoxContainer

# Word Display
var _word_display: WordSynthDisplay
var _layer_solos: Dictionary = {}  # layer_name -> {solo: CheckBox, mute: CheckBox, volume: HSlider}

# Parameter Panel
var _param_panel: PanelContainer
var _param_sliders: Dictionary = {}  # param_name -> HSlider
var _snapshot_a: Dictionary = {}
var _snapshot_b: Dictionary = {}
var _current_snapshot: String = "A"

# Visualizer
var _visualizer: Control
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _oscilloscope_buffer: PackedFloat32Array

# Live parameters (these affect playback in real-time)
var live_params: Dictionary = {
	"master_volume": 0.0,
	"bass_filter_cutoff": 800.0,
	"bass_filter_resonance": 0.5,
	"bass_volume": 0.0,
	"pad_filter_cutoff": 2000.0,
	"pad_detune": 10.0,
	"pad_volume": 0.0,
	"lead_filter_cutoff": 3000.0,
	"lead_vibrato_depth": 0.2,
	"lead_volume": 0.0,
	"drums_volume": 0.0,
	"reverb_mix": 0.3,
	"delay_mix": 0.2,
	"delay_time": 0.375,
}

# Parameter ranges for randomization
var param_ranges: Dictionary = {
	"master_volume": {"min": -20.0, "max": 6.0, "default": 0.0},
	"bass_filter_cutoff": {"min": 100.0, "max": 2000.0, "default": 800.0},
	"bass_filter_resonance": {"min": 0.1, "max": 0.9, "default": 0.5},
	"bass_volume": {"min": -12.0, "max": 6.0, "default": 0.0},
	"pad_filter_cutoff": {"min": 200.0, "max": 8000.0, "default": 2000.0},
	"pad_detune": {"min": 0.0, "max": 30.0, "default": 10.0},
	"pad_volume": {"min": -12.0, "max": 6.0, "default": 0.0},
	"lead_filter_cutoff": {"min": 500.0, "max": 8000.0, "default": 3000.0},
	"lead_vibrato_depth": {"min": 0.0, "max": 0.5, "default": 0.2},
	"lead_volume": {"min": -12.0, "max": 6.0, "default": 0.0},
	"drums_volume": {"min": -12.0, "max": 6.0, "default": 0.0},
	"reverb_mix": {"min": 0.0, "max": 1.0, "default": 0.3},
	"delay_mix": {"min": 0.0, "max": 1.0, "default": 0.2},
	"delay_time": {"min": 0.1, "max": 1.0, "default": 0.375},
}

signal parameters_changed(params: Dictionary)


func _ready():
	if not Engine.is_editor_hint():
		get_tree().root.title = "AdaResearch Song Dev Tools"
	_word_bridge = WordSynthBridge.new()
	_setup_audio()
	_setup_ui()
	_setup_spectrum_analyzer()
	_snapshot_a = live_params.duplicate(true)
	_snapshot_b = live_params.duplicate(true)
	print("Song Dev Tools ready!")


func _setup_audio():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.finished.connect(_on_song_finished)
	add_child(_player)
	
	# Add realtime effects to Master bus
	_setup_realtime_effects()


func _setup_realtime_effects():
	"""Add controllable effects to Master bus"""
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		return
	
	# Check if effects already exist
	var has_reverb = false
	var has_delay = false
	
	for i in range(AudioServer.get_bus_effect_count(master_idx)):
		var effect = AudioServer.get_bus_effect(master_idx, i)
		if effect is AudioEffectReverb:
			has_reverb = true
		elif effect is AudioEffectDelay:
			has_delay = true
	
	# Add missing effects
	if not has_reverb:
		var reverb = AudioEffectReverb.new()
		reverb.wet = live_params.get("reverb_mix", 0.3)
		reverb.room_size = 0.6
		reverb.damping = 0.5
		AudioServer.add_bus_effect(master_idx, reverb)
	
	if not has_delay:
		var delay = AudioEffectDelay.new()
		delay.tap1_active = true
		delay.tap1_delay_ms = live_params.get("delay_time", 0.375) * 1000
		delay.tap1_level_db = -6.0
		delay.dry = 1.0 - live_params.get("delay_mix", 0.2)
		delay.feedback_active = true
		delay.feedback_delay_ms = delay.tap1_delay_ms
		delay.feedback_level_db = -12.0
		AudioServer.add_bus_effect(master_idx, delay)


func _setup_spectrum_analyzer():
	# Add spectrum analyzer to master bus
	var bus_idx = AudioServer.get_bus_index("Master")
	
	# Check if analyzer already exists
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum = AudioServer.get_bus_effect_instance(bus_idx, i)
			return
	
	# Add new analyzer
	var analyzer = AudioEffectSpectrumAnalyzer.new()
	analyzer.buffer_length = 0.1
	analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	AudioServer.add_bus_effect(bus_idx, analyzer)
	_spectrum = AudioServer.get_bus_effect_instance(bus_idx, AudioServer.get_bus_effect_count(bus_idx) - 1)


func _setup_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Main horizontal split
	var hsplit = HSplitContainer.new()
	hsplit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hsplit.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 16)
	add_child(hsplit)
	
	# Left panel - song list and timeline
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 2.0
	left_panel.add_theme_constant_override("separation", 12)
	hsplit.add_child(left_panel)
	
	# Title
	_title_label = Label.new()
	_title_label.text = "🛠️ SONG DEV TOOLS"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	left_panel.add_child(_title_label)
	
	# Song buttons (compact)
	var songs_scroll = ScrollContainer.new()
	songs_scroll.custom_minimum_size.y = 200
	songs_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_panel.add_child(songs_scroll)
	
	var songs_grid = GridContainer.new()
	songs_grid.columns = 2
	songs_grid.add_theme_constant_override("h_separation", 8)
	songs_grid.add_theme_constant_override("v_separation", 8)
	songs_scroll.add_child(songs_grid)
	
	var songs = [
		["prog_synth_70s", "🎸 70s Prog"],
		["pop_generative", "🎤 Pop"],
		["ambient_works", "🌊 Ambient"],
		["moroder_disco", "🪩 Disco"],
		["detroit_techno", "🔩 Techno"],
		["synthwave", "🌃 Synthwave"],
		["rave", "⚡ Rave"],
		["french_touch", "🇫🇷 French Touch"],
		["supersaw_trance", "🔊 Supersaw"],
		["lofi_house", "📼 Lo-Fi House"],
		["reese_jungle", "🌴 Jungle"],
		["ambient_techno", "🌌 Ambient"],
		["blade_runner", "🌃 Blade Runner"]
	]
	
	for song in songs:
		var btn = Button.new()
		btn.text = song[1]
		btn.pressed.connect(_on_song_selected.bind(song[0]))
		_style_button_compact(btn, Color(0.2, 0.4, 0.5))
		_song_buttons[song[0]] = btn
		songs_grid.add_child(btn)
	
	# Transport controls
	var transport = HBoxContainer.new()
	transport.add_theme_constant_override("separation", 8)
	left_panel.add_child(transport)
	
	_play_btn = Button.new()
	_play_btn.text = "▶"
	_play_btn.disabled = true
	_play_btn.pressed.connect(_toggle_pause)
	_style_button_compact(_play_btn, Color(0.2, 0.5, 0.3))
	transport.add_child(_play_btn)
	
	_stop_btn = Button.new()
	_stop_btn.text = "⏹"
	_stop_btn.disabled = true
	_stop_btn.pressed.connect(_stop_song)
	_style_button_compact(_stop_btn, Color(0.5, 0.2, 0.2))
	transport.add_child(_stop_btn)
	
	_loop_btn = Button.new()
	_loop_btn.text = "🔁 Loop"
	_loop_btn.toggle_mode = true
	_loop_btn.toggled.connect(_on_loop_toggled)
	_style_button_compact(_loop_btn, Color(0.4, 0.3, 0.5))
	transport.add_child(_loop_btn)
	
	# Section dropdown
	_section_dropdown = OptionButton.new()
	_section_dropdown.custom_minimum_size.x = 100
	_section_dropdown.add_item("Section", 0)
	_section_dropdown.disabled = true
	_section_dropdown.item_selected.connect(_on_section_selected)
	transport.add_child(_section_dropdown)
	
	_status_label = Label.new()
	_status_label.text = "Select a song..."
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transport.add_child(_status_label)
	
	# Visualizer
	_visualizer = _create_visualizer()
	left_panel.add_child(_visualizer)
	
	# Timeline
	_timeline_container = PanelContainer.new()
	var tl_style = StyleBoxFlat.new()
	tl_style.bg_color = Color(0.08, 0.08, 0.1)
	tl_style.set_corner_radius_all(6)
	_timeline_container.add_theme_stylebox_override("panel", tl_style)
	_timeline_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_timeline_container.custom_minimum_size.y = 250
	left_panel.add_child(_timeline_container)
	
	_timeline = SongTimeline.new()
	_timeline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_timeline.seek_requested.connect(_on_timeline_seek)
	_timeline.section_clicked.connect(_on_section_clicked)
	_timeline_container.add_child(_timeline)
	
	# Right panel - parameters
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.0
	right_panel.add_theme_constant_override("separation", 12)
	hsplit.add_child(right_panel)
	
	# Parameter panel
	_param_panel = _create_param_panel()
	right_panel.add_child(_param_panel)
	
	# Layer controls
	_dev_panel = _create_layer_panel()
	right_panel.add_child(_dev_panel)
	
	# Word display
	var word_panel = PanelContainer.new()
	var wp_style = StyleBoxFlat.new()
	wp_style.bg_color = Color(0.08, 0.08, 0.1)
	wp_style.set_corner_radius_all(6)
	wp_style.content_margin_left = 12
	wp_style.content_margin_right = 12
	wp_style.content_margin_top = 8
	wp_style.content_margin_bottom = 8
	word_panel.add_theme_stylebox_override("panel", wp_style)
	word_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(word_panel)
	
	_word_display = WordSynthDisplay.new()
	_word_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_word_display.word_clicked.connect(_on_word_clicked)
	_word_display.layer_preview_requested.connect(_on_layer_preview)
	_word_display.layer_selected.connect(_on_layer_selected)
	_word_display.add_word_requested.connect(show_word_picker)
	word_panel.add_child(_word_display)


func _create_visualizer() -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.03)
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	style.border_color = Color(0.15, 0.15, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(0, 120)
	
	var viz = Control.new()
	viz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viz.draw.connect(_on_visualizer_draw.bind(viz))
	panel.add_child(viz)
	
	return panel


func _create_param_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)
	
	# Header with A/B buttons
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "⚙️ PARAMETERS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var snap_a_btn = Button.new()
	snap_a_btn.text = "A"
	snap_a_btn.toggle_mode = true
	snap_a_btn.button_pressed = true
	snap_a_btn.pressed.connect(_load_snapshot.bind("A"))
	_style_button_compact(snap_a_btn, Color(0.5, 0.3, 0.3))
	header.add_child(snap_a_btn)
	
	var snap_b_btn = Button.new()
	snap_b_btn.text = "B"
	snap_b_btn.toggle_mode = true
	snap_b_btn.pressed.connect(_load_snapshot.bind("B"))
	_style_button_compact(snap_b_btn, Color(0.3, 0.3, 0.5))
	header.add_child(snap_b_btn)
	
	var save_btn = Button.new()
	save_btn.text = "💾"
	save_btn.pressed.connect(_save_current_snapshot)
	_style_button_compact(save_btn, Color(0.3, 0.4, 0.3))
	header.add_child(save_btn)
	
	var rand_btn = Button.new()
	rand_btn.text = "🎲"
	rand_btn.pressed.connect(_randomize_all)
	_style_button_compact(rand_btn, Color(0.4, 0.3, 0.5))
	header.add_child(rand_btn)
	
	var reset_btn = Button.new()
	reset_btn.text = "↺"
	reset_btn.pressed.connect(_reset_all)
	_style_button_compact(reset_btn, Color(0.4, 0.4, 0.4))
	header.add_child(reset_btn)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Parameter sliders grouped by category
	var categories = {
		"🔊 Master": ["master_volume"],
		"🎸 Bass": ["bass_filter_cutoff", "bass_filter_resonance", "bass_volume"],
		"🌊 Pad": ["pad_filter_cutoff", "pad_detune", "pad_volume"],
		"🎹 Lead": ["lead_filter_cutoff", "lead_vibrato_depth", "lead_volume"],
		"🥁 Drums": ["drums_volume"],
		"🌀 FX": ["reverb_mix", "delay_mix", "delay_time"],
	}
	
	for cat_name in categories.keys():
		var cat_label = Label.new()
		cat_label.text = cat_name
		cat_label.add_theme_font_size_override("font_size", 14)
		cat_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox.add_child(cat_label)
		
		for param_name in categories[cat_name]:
			var row = _create_param_row(param_name)
			vbox.add_child(row)
	
	return panel


func _create_param_row(param_name: String) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	
	# Param name (shortened)
	var short_name = param_name.replace("_", " ").replace("filter ", "").replace("volume", "vol")
	var label = Label.new()
	label.text = short_name.substr(0, 12)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	
	# Slider
	var range_info = param_ranges.get(param_name, {"min": 0.0, "max": 1.0, "default": 0.5})
	var slider = HSlider.new()
	slider.min_value = range_info["min"]
	slider.max_value = range_info["max"]
	slider.value = live_params.get(param_name, range_info["default"])
	slider.step = (range_info["max"] - range_info["min"]) / 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_param_changed.bind(param_name))
	hbox.add_child(slider)
	_param_sliders[param_name] = slider
	
	# Value label
	var val_label = Label.new()
	val_label.text = "%.1f" % slider.value
	val_label.add_theme_font_size_override("font_size", 11)
	val_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	val_label.custom_minimum_size.x = 45
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val_label)
	slider.value_changed.connect(func(v): val_label.text = "%.1f" % v)
	
	# Random button for this param
	var rand_btn = Button.new()
	rand_btn.text = "🎲"
	rand_btn.add_theme_font_size_override("font_size", 10)
	rand_btn.custom_minimum_size = Vector2(24, 24)
	rand_btn.pressed.connect(_randomize_param.bind(param_name))
	hbox.add_child(rand_btn)
	
	return hbox


func _create_layer_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = 180
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🎚️ LAYERS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 0.5))
	vbox.add_child(title)
	
	_layer_controls = VBoxContainer.new()
	_layer_controls.add_theme_constant_override("separation", 2)
	vbox.add_child(_layer_controls)
	
	# Will be populated when song loads
	_populate_layer_controls(["Bass", "Pad", "Lead", "Drums", "FX"])
	
	return panel


func _populate_layer_controls(layer_names: Array):
	# Clear existing
	for child in _layer_controls.get_children():
		child.queue_free()
	_layer_solos.clear()
	
	for layer_name in layer_names:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_layer_controls.add_child(row)
		
		# Solo button
		var solo = CheckBox.new()
		solo.text = "S"
		solo.add_theme_font_size_override("font_size", 11)
		solo.toggled.connect(_on_layer_solo.bind(layer_name))
		row.add_child(solo)
		
		# Mute button
		var mute = CheckBox.new()
		mute.text = "M"
		mute.add_theme_font_size_override("font_size", 11)
		mute.toggled.connect(_on_layer_mute.bind(layer_name))
		row.add_child(mute)
		
		# Layer name
		var label = Label.new()
		label.text = layer_name
		label.add_theme_font_size_override("font_size", 13)
		label.custom_minimum_size.x = 50
		row.add_child(label)
		
		# Volume slider
		var vol = HSlider.new()
		vol.min_value = -24.0
		vol.max_value = 6.0
		vol.value = 0.0
		vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vol.value_changed.connect(_on_layer_volume.bind(layer_name))
		row.add_child(vol)
		
		_layer_solos[layer_name] = {"solo": solo, "mute": mute, "volume": vol}


func _style_button_compact(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)


# === SONG PLAYBACK ===

func _on_song_selected(song_id: String):
	_stop_song()
	_current_song = song_id
	_status_label.text = "Generating " + song_id + "..."
	
	for btn in _song_buttons.values():
		btn.disabled = true
	
	call_deferred("_generate_and_play", song_id)


func _generate_and_play(song_id: String):
	var stream: AudioStream = null
	
	# AudioSynthesizer has class_name - call static methods directly
	match song_id:
		"prog_synth_70s":
			stream = AudioSynthesizer.generate_prog_synth_song({})
		"pop_generative":
			stream = AudioSynthesizer.generate_pop_interactive_song({})
		"ambient_works":
			stream = AudioSynthesizer.generate_ambient_works_song({})
		"moroder_disco":
			stream = AudioSynthesizer.generate_moroder_disco_song({})
		"detroit_techno":
			stream = AudioSynthesizer.generate_detroit_techno_song({})
		"synthwave":
			stream = AudioSynthesizer.generate_synthwave_song({})
		"rave":
			stream = AudioSynthesizer.generate_rave_song({})
		"french_touch":
			stream = AudioSynthesizer.generate_french_touch_song({})
		"supersaw_trance":
			stream = AudioSynthesizer.generate_supersaw_trance_song({})
		"lofi_house":
			stream = AudioSynthesizer.generate_lofi_house_song({})
		"reese_jungle":
			stream = AudioSynthesizer.generate_reese_jungle_song({})
		"ambient_techno":
			stream = AudioSynthesizer.generate_ambient_techno_song({})
		"blade_runner":
			stream = AudioSynthesizer.generate_blade_runner_song({})
	
	if stream == null:
		_status_label.text = "Generation failed - check console for errors"
		_enable_buttons()
		return
	
	_current_stream = stream as AudioStreamInteractive
	_player.stream = stream
	_player.play()
	_is_playing = true
	_playback_time = 0.0
	
	_status_label.text = "Playing: " + song_id
	_play_btn.disabled = false
	_play_btn.text = "⏸"
	_stop_btn.disabled = false
	_enable_buttons()
	
	# Load timeline metadata
	_load_timeline_for_song(song_id, stream)


func _toggle_pause():
	if _player.stream_paused:
		_player.stream_paused = false
		_play_btn.text = "⏸"
		_timeline.set_playing(true)
	else:
		_player.stream_paused = true
		_play_btn.text = "▶"
		_timeline.set_playing(false)


func _stop_song():
	_player.stop()
	_player.stream_paused = false
	_is_playing = false
	_playback_time = 0.0
	_play_btn.text = "▶"
	_play_btn.disabled = true
	_stop_btn.disabled = true
	_timeline.set_current_time(0.0)
	_timeline.set_playing(false)


func _on_song_finished():
	if _loop_enabled:
		_playback_time = _loop_start
		_player.play()
	else:
		_is_playing = false
		_playback_time = 0.0
		_play_btn.disabled = true
		_stop_btn.disabled = true


func _enable_buttons():
	for btn in _song_buttons.values():
		btn.disabled = false


# === LOOP ===

func _on_loop_toggled(pressed: bool):
	_loop_enabled = pressed
	_loop_btn.text = "🔁 Loop" if not pressed else "🔁 ON"


func _on_section_selected(index: int):
	if index == 0 or _timeline._sections.is_empty():
		return
	
	var section_idx = index - 1  # Account for "Section" placeholder
	if section_idx >= 0 and section_idx < _timeline._sections.size():
		var section = _timeline._sections[section_idx]
		
		# Set playback time manually (AudioStreamInteractive seek doesn't work reliably)
		_playback_time = section["start"]
		_timeline.set_current_time(_playback_time)
		
		# For AudioStreamInteractive, we need to switch clips, not seek
		if _current_stream and section.has("index"):
			# Switch to the correct clip
			var playback = _player.get_stream_playback()
			if playback and playback.has_method("switch_to_clip"):
				playback.switch_to_clip(section["index"])
		
		if not _player.playing:
			_player.play()
		_is_playing = true
		_play_btn.text = "⏸"
		
		_timeline.set_current_time(section["start"])
		_last_section_name = section["name"]  # Prevent auto-update from changing dropdown
		_skip_section_update_until = Time.get_ticks_msec() / 1000.0 + 1.0  # Skip for 1 second
		
		# Update word display for this section
		_update_words_for_section(section["name"])
		
		# Auto-enable loop for this section
		_loop_start = section["start"]
		_loop_end = section["end"]
		_loop_enabled = true
		_loop_btn.button_pressed = true
		_loop_btn.text = "🔁 " + section["name"]


func _on_section_clicked(section_name: String):
	# Jump to section and set loop points
	for i in range(_timeline._sections.size()):
		var section = _timeline._sections[i]
		if section["name"] == section_name:
			_loop_start = section["start"]
			_loop_end = section["end"]
			_loop_enabled = true
			_loop_btn.button_pressed = true
			_loop_btn.text = "🔁 " + section_name
			_last_section_name = section_name
			_skip_section_update_until = Time.get_ticks_msec() / 1000.0 + 1.0
			
			# Set playback time manually
			_playback_time = _loop_start
			_timeline.set_current_time(_playback_time)
			
			# Switch clip for AudioStreamInteractive
			if _current_stream and section.has("index"):
				var playback = _player.get_stream_playback()
				if playback and playback.has_method("switch_to_clip"):
					playback.switch_to_clip(section["index"])
			
			if not _player.playing:
				_player.play()
			_is_playing = true
			_play_btn.text = "⏸"
			
			_section_dropdown.selected = i + 1
			_update_words_for_section(section_name)
			break


func _on_timeline_seek(time: float):
	# Set playback time manually
	_playback_time = time
	_timeline.set_current_time(_playback_time)
	
	# Find which section this time falls into and switch clip
	if _current_stream:
		for section in _timeline._sections:
			if time >= section["start"] and time < section["end"] and section.has("index"):
				var playback = _player.get_stream_playback()
				if playback and playback.has_method("switch_to_clip"):
					playback.switch_to_clip(section["index"])
				break
	
	if _player.stream and not _player.playing:
		_player.play()
		_is_playing = true
		_play_btn.text = "⏸"


# === PARAMETERS ===

func _on_param_changed(value: float, param_name: String):
	live_params[param_name] = value
	_apply_live_params()
	parameters_changed.emit(live_params)
	
	# Show feedback
	_status_label.text = "⚙️ %s = %.2f" % [param_name.replace("_", " "), value]


func _apply_live_params():
	# Apply to audio buses/effects
	var master_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, live_params["master_volume"])
	
	# TODO: Connect these to actual synth parameters when AudioSynthesizer supports it
	# For now, this demonstrates the UI - full integration requires synth modifications


func _save_current_snapshot():
	if _current_snapshot == "A":
		_snapshot_a = live_params.duplicate(true)
	else:
		_snapshot_b = live_params.duplicate(true)
	_status_label.text = "Saved to snapshot " + _current_snapshot


func _load_snapshot(which: String):
	_current_snapshot = which
	var snapshot = _snapshot_a if which == "A" else _snapshot_b
	
	for param_name in snapshot.keys():
		live_params[param_name] = snapshot[param_name]
		if _param_sliders.has(param_name):
			_param_sliders[param_name].value = snapshot[param_name]
	
	_apply_live_params()
	_status_label.text = "Loaded snapshot " + which


func _randomize_param(param_name: String):
	var range_info = param_ranges.get(param_name, {"min": 0.0, "max": 1.0})
	var new_val = randf_range(range_info["min"], range_info["max"])
	live_params[param_name] = new_val
	if _param_sliders.has(param_name):
		_param_sliders[param_name].value = new_val
	_apply_live_params()


func _randomize_all():
	for param_name in live_params.keys():
		_randomize_param(param_name)
	_status_label.text = "Randomized all parameters"


func _reset_all():
	for param_name in param_ranges.keys():
		var default_val = param_ranges[param_name]["default"]
		live_params[param_name] = default_val
		if _param_sliders.has(param_name):
			_param_sliders[param_name].value = default_val
	_apply_live_params()
	_status_label.text = "Reset to defaults"


# === LAYERS ===

func _on_layer_solo(pressed: bool, layer_name: String):
	# TODO: Implement actual solo via bus routing
	pass


func _on_layer_mute(pressed: bool, layer_name: String):
	# TODO: Implement actual mute via bus routing
	pass


func _on_layer_volume(value: float, layer_name: String):
	# TODO: Apply to layer-specific bus
	pass


func _on_word_clicked(layer: String, word: String):
	# Get word params and apply them via the bridge
	var layer_words = _word_display._layer_words.get(layer, [])
	
	# Use bridge to translate words → live_params
	var new_params = _word_bridge.apply_words_to_params(layer, layer_words, live_params)
	
	# Apply changes
	for key in new_params.keys():
		if live_params.has(key):
			live_params[key] = new_params[key]
			if _param_sliders.has(key):
				_param_sliders[key].value = new_params[key]
	
	_apply_live_params()
	parameters_changed.emit(live_params)
	
	# Show status with opposites
	var opposites = _word_bridge.get_opposites(word)
	var opp_text = " (try: %s)" % ", ".join(opposites) if not opposites.is_empty() else ""
	_status_label.text = "🏷️ %s: %s%s" % [layer, word, opp_text]
	print("Word applied: %s → %s, updated params: %s" % [layer, word, new_params])


func _on_layer_selected(layer: String):
	# Apply all words for this layer
	var layer_words = _word_display._layer_words.get(layer, [])
	var new_params = _word_bridge.words_to_live_params(layer, layer_words)
	
	for key in new_params.keys():
		if live_params.has(key):
			live_params[key] = new_params[key]
			if _param_sliders.has(key):
				_param_sliders[key].value = new_params[key]
	
	_apply_live_params()
	_status_label.text = "📋 %s: applied %d words" % [layer, layer_words.size()]


func _on_layer_preview(layer: String, params: Dictionary):
	_status_label.text = "▶ Previewing %s..." % layer
	var preview = _generate_layer_preview(layer, params)
	if preview:
		var was_playing = _player.playing
		var saved_pos = _playback_time
		_player.stop()
		_player.stream = preview
		_player.play()
		await get_tree().create_timer(2.0).timeout
		if _current_stream:
			_player.stream = _current_stream
			if was_playing:
				_player.play()
				_playback_time = saved_pos
		_status_label.text = "Playing: " + _current_song_id if _current_song_id else "Ready"


func _generate_layer_preview(layer: String, params: Dictionary) -> AudioStream:
	var sample_rate = 44100
	var duration = 2.0
	var samples = int(sample_rate * duration)
	var data = PackedFloat32Array()
	data.resize(samples)
	
	var base_freq = 261.63
	var attack = params.get("env.attack", params.get("attack", 0.01))
	var decay = params.get("env.decay", params.get("decay", 0.2))
	var sustain = params.get("env.sustain", params.get("sustain", 0.7))
	var voices = int(params.get("osc.voices", params.get("voices", 1)))
	var detune = params.get("osc.detune", params.get("detune", 0.0))
	
	match layer.to_lower():
		"bass", "reese bass", "juno bass", "filter bass", "trance bass":
			base_freq = 65.41
		"pad", "ambient pad", "juno pad", "supersaw pad", "string pad":
			base_freq = 130.81
		"lead", "supersaw lead", "duck lead", "vangelis keys":
			base_freq = 523.25
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var env = 1.0
		if t < attack: env = t / attack
		elif t < attack + decay: env = 1.0 - (1.0 - sustain) * ((t - attack) / decay)
		elif t > duration - 0.3: env = sustain * (duration - t) / 0.3
		else: env = sustain
		
		var osc = 0.0
		for v in range(max(1, voices)):
			var vd = (float(v) / max(1, voices - 1) - 0.5) * detune * 0.01 if voices > 1 else 0.0
			var freq = base_freq * (1.0 + vd)
			if "pad" in layer.to_lower() or "ambient" in layer.to_lower():
				osc += sin(2.0 * PI * freq * t)
			else:
				osc += fmod(t * freq, 1.0) * 2.0 - 1.0
		osc /= max(1, voices)
		data[i] = clampf(osc * env * 0.5, -1.0, 1.0)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	var bytes = PackedByteArray()
	for s in data:
		var val = int(clamp(s, -1.0, 1.0) * 32767)
		bytes.append(val & 0xFF)
		bytes.append((val >> 8) & 0xFF)
	stream.data = bytes
	return stream


func _load_song_words(song_id: String):
	"""Load word descriptors for each layer based on song type"""
	_word_display.clear_all()
	
	# Define words for each song's layers
	var song_words = {
		"prog_synth_70s": {
			"Bass": {
				"words": ["warm", "thick", "analog", "punchy"],
				"params": {"filter_cutoff": 800, "resonance": 0.4, "glide": 50}
			},
			"Pad": {
				"words": ["warm", "wide", "swelling", "analog"],
				"params": {"voices": 7, "detune": 10, "attack": 2.0}
			},
			"Lead": {
				"words": ["bright", "aggressive", "sustained", "analog"],
				"params": {"portamento": 80, "vibrato": 5.0, "filter_cutoff": 3000}
			},
			"Drums": {
				"words": ["punchy", "crisp", "analog"],
				"params": {"pattern": "motorik", "tempo": 110}
			}
		},
		"ambient_works": {
			"Keys": {
				"words": ["warm", "soft", "dreamy", "analog"],
				"params": {"type": "FM piano", "saturation": "tape"}
			},
			"Pad": {
				"words": ["dreamy", "wide", "evolving", "soft"],
				"params": {"voices": 5, "chorus": 0.4, "attack": 1.5}
			},
			"Bass": {
				"words": ["aggressive", "wobbling", "analog"],
				"params": {"type": "303", "resonance": 0.8, "accent": true}
			},
			"Drums": {
				"words": ["crisp", "punchy"],
				"params": {"type": "breakbeat", "lo-fi": true}
			}
		},
		"moroder_disco": {
			"Sequencer": {
				"words": ["pulsing", "analog", "warm", "evolving"],
				"params": {"rate": "16th", "filter_mod": true}
			},
			"Bass": {
				"words": ["thick", "punchy", "warm"],
				"params": {"type": "Moog", "octave_jumps": true}
			},
			"Strings": {
				"words": ["wide", "warm", "sustained"],
				"params": {"type": "string_machine", "chorus": 0.5}
			},
			"Drums": {
				"words": ["punchy", "crisp"],
				"params": {"type": "disco", "hats": "16th"}
			}
		},
		"detroit_techno": {
			"Pad": {
				"words": ["cold", "digital", "wide", "evolving"],
				"params": {"type": "digital", "attack": 0.5}
			},
			"Bass": {
				"words": ["thick", "punchy", "cold"],
				"params": {"type": "sub", "style": "808"}
			},
			"Stabs": {
				"words": ["cold", "percussive", "digital"],
				"params": {"decay": 0.1, "filter": "gated"}
			},
			"Drums": {
				"words": ["punchy", "crisp", "cold"],
				"params": {"type": "909", "style": "machine funk"}
			}
		},
		"synthwave": {
			"Arpeggio": {
				"words": ["bright", "shimmering", "wide", "pulsing"],
				"params": {"type": "Juno", "chorus": 0.4, "rate": "16th"}
			},
			"Bass": {
				"words": ["thick", "warm", "punchy"],
				"params": {"type": "saw", "sidechain": true}
			},
			"Lead": {
				"words": ["bright", "warm", "sustained", "wide"],
				"params": {"detune": 15, "vibrato": 0.3, "delay": 0.35}
			},
			"Drums": {
				"words": ["punchy", "crisp", "spacious"],
				"params": {"type": "LinnDrum", "gated_reverb": true}
			}
		},
		"rave": {
			"Bass": {
				"words": ["aggressive", "thick", "analog"],
				"params": {"type": "hoover", "pwm": true, "massive": true}
			},
			"Stabs": {
				"words": ["aggressive", "percussive", "bright"],
				"params": {"type": "Mentasm", "chord": true}
			},
			"Drums": {
				"words": ["aggressive", "punchy", "crisp"],
				"params": {"type": "breakbeat", "tempo": 140}
			}
		},
		"french_touch": {
			"Filter Bass": {
				"words": ["warm", "sidechained", "disco", "punchy"],
				"params": {"type": "filter_sweep", "sidechain": true}
			},
			"Duck Lead": {
				"words": ["resonant", "quacky", "bright", "percussive"],
				"params": {"filter": "bandpass", "resonance": 0.8, "envelope": "short"}
			},
			"Chiff": {
				"words": ["plucky", "double-hit", "wavetable", "bright"],
				"params": {"type": "wavetable", "attack": "inverse"}
			},
			"Vocoder Pad": {
				"words": ["warm", "wide", "robotic", "soft"],
				"params": {"voices": 4, "formant": true}
			},
			"Drums": {
				"words": ["punchy", "disco", "four-on-floor"],
				"params": {"type": "disco", "tempo": 120}
			}
		},
		"supersaw_trance": {
			"Supersaw Pad": {
				"words": ["massive", "wide", "detuned", "uplifting"],
				"params": {"voices": 8, "detune": 0.06, "stereo": "wide"}
			},
			"Supersaw Lead": {
				"words": ["bright", "soaring", "sustained", "wide"],
				"params": {"octave": "+1", "detune": 0.03}
			},
			"Trance Bass": {
				"words": ["sub", "punchy", "sidechained"],
				"params": {"type": "sub", "sidechain": true}
			},
			"Arp": {
				"words": ["pulsing", "bright", "rhythmic", "shimmering"],
				"params": {"rate": "16th", "pattern": "chord"}
			},
			"Drums": {
				"words": ["punchy", "driving", "crisp"],
				"params": {"type": "trance", "tempo": 138}
			}
		},
		"lofi_house": {
			"Juno Bass": {
				"words": ["warm", "plucky", "analog", "filtered"],
				"params": {"type": "DCO", "waveform": "saw+square", "pwm": true, "filter_env": "pluck"}
			},
			"Juno Pad": {
				"words": ["warm", "wide", "chorus", "dreamy"],
				"params": {"type": "DCO", "chorus": "juno", "detune": 0.005}
			},
			"Stab": {
				"words": ["percussive", "filtered", "soft"],
				"params": {"decay": 0.08, "filter": "lowpass"}
			},
			"Vocal Chop": {
				"words": ["breathy", "pitched", "warm"],
				"params": {"formant": true, "pitch": "root"}
			},
			"Drums": {
				"words": ["dusty", "warm", "lofi", "groovy"],
				"params": {"type": "lofi", "saturation": "tape", "tempo": 118}
			}
		},
		"reese_jungle": {
			"Reese Bass": {
				"words": ["wobbling", "detuned", "thick", "dark"],
				"params": {"detune": 0.07, "sub": true, "filter_lfo": 0.25}
			},
			"Amen Break": {
				"words": ["chopped", "aggressive", "fast", "complex"],
				"params": {"type": "amen", "tempo": 170}
			},
			"Stab": {
				"words": ["bitcrushed", "bright", "percussive"],
				"params": {"bitdepth": 12, "chord": true}
			},
			"Pad": {
				"words": ["atmospheric", "soft", "wide"],
				"params": {"reverb": "large"}
			}
		},
		"ambient_techno": {
			"Ambient Pad": {
				"words": ["evolving", "wide", "slow", "immersive"],
				"params": {"attack": 5.0, "oscillators": 4, "octaves": [-1, 0, 1, 2]}
			},
			"Texture": {
				"words": ["granular", "evolving", "subtle", "mysterious"],
				"params": {"lfo_rate": 0.07, "noise": "subtle"}
			},
			"Minimal Kick": {
				"words": ["soft", "deep", "sidechain"],
				"params": {"type": "minimal", "decay": 0.15}
			},
			"Arp": {
				"words": ["slow", "meditative", "sparse"],
				"params": {"rate": "8th", "decay": 3.0}
			}
		},
		"blade_runner": {
			"Vangelis Keys": {
				"words": ["resonant", "plucky", "expressive", "cinematic"],
				"params": {"filter_cutoff": 91, "resonance": 88, "velocity": 83}
			},
			"String Pad": {
				"words": ["lush", "wide", "evolving", "warm"],
				"params": {"detune": 0.002, "attack": 0.3}
			},
			"Bass Pulse": {
				"words": ["deep", "pulsing", "slow", "dark"],
				"params": {"pulse_rate": 0.5, "octave": -2}
			},
			"Lead": {
				"words": ["soaring", "vibrato", "expressive", "bright"],
				"params": {"vibrato_rate": 5.0, "vibrato_depth": 0.01}
			}
		},
		"pop_generative": {
			"Bass": {
				"words": ["warm", "punchy", "soft"],
				"params": {"type": "synth", "pattern": "root"}
			},
			"Keys": {
				"words": ["warm", "soft", "plucky"],
				"params": {"type": "electric piano"}
			},
			"Pad": {
				"words": ["soft", "wide", "warm"],
				"params": {"supporting": true}
			},
			"Lead": {
				"words": ["bright", "present", "sustained"],
				"params": {"type": "melodic hook"}
			},
			"Drums": {
				"words": ["punchy", "crisp"],
				"params": {"type": "pop kit"}
			}
		}
	}
	
	var layers = song_words.get(song_id, {})
	for layer_name in layers.keys():
		var data = layers[layer_name]
		_word_display.set_layer_words(layer_name, data["words"], data["params"])


var _current_song_id: String = ""

func _update_words_for_section(section_name: String):
	"""Update word display based on current section - sections modify layer emphasis"""
	_word_display.clear_all()
	
	# Section-specific word profiles (which layers are active + their words)
	var section_profiles = {
		"Intro": {
			"Pad": ["soft", "wide", "evolving"],
			"Arpeggio": ["shimmering", "pulsing"],
			"Drums": ["soft", "sparse"]
		},
		"Verse": {
			"Bass": ["warm", "punchy"],
			"Pad": ["wide", "sustained"],
			"Drums": ["crisp", "steady"],
			"Keys": ["soft", "plucky"]
		},
		"Build": {
			"Bass": ["thick", "swelling"],
			"Pad": ["wide", "evolving", "swelling"],
			"Drums": ["punchy", "building"],
			"Arpeggio": ["pulsing", "bright"]
		},
		"Chorus": {
			"Bass": ["thick", "punchy", "aggressive"],
			"Lead": ["bright", "present", "sustained"],
			"Pad": ["wide", "warm"],
			"Drums": ["punchy", "crisp", "driving"]
		},
		"Solo": {
			"Lead": ["bright", "aggressive", "sustained", "expressive"],
			"Bass": ["thick", "punchy"],
			"Drums": ["driving", "punchy"]
		},
		"Breakdown": {
			"Pad": ["wide", "dreamy", "evolving"],
			"Keys": ["soft", "warm"],
			"Drums": ["sparse", "soft"]
		},
		"Drop": {
			"Bass": ["aggressive", "thick", "punchy"],
			"Lead": ["bright", "aggressive"],
			"Drums": ["punchy", "crisp", "driving"],
			"Stabs": ["aggressive", "percussive"]
		},
		"Outro": {
			"Pad": ["soft", "wide", "fading"],
			"Keys": ["soft", "warm"],
			"Drums": ["soft", "sparse"]
		},
		"Main": {
			"Bass": ["thick", "punchy", "warm"],
			"Lead": ["bright", "present", "sustained"],
			"Pad": ["wide", "warm"],
			"Drums": ["punchy", "crisp", "driving"],
			"Arpeggio": ["pulsing", "bright"]
		}
	}
	
	# Get profile for this section (or default)
	var profile = section_profiles.get(section_name, {})
	if profile.is_empty():
		# Fallback: reload full song words
		_load_song_words(_current_song_id)
		return
	
	# Display section-specific layers and words
	for layer_name in profile.keys():
		var words = profile[layer_name]
		_word_display.set_layer_words(layer_name, words, {})


# === VISUALIZER ===

func _on_visualizer_draw(viz: Control):
	var rect = viz.get_rect()
	var w = rect.size.x
	var h = rect.size.y
	var mid_y = h / 2.0
	
	# Draw center line
	viz.draw_line(Vector2(0, mid_y), Vector2(w, mid_y), Color(0.15, 0.15, 0.2), 1.0)
	
	if _spectrum == null:
		return
	
	# Spectrum analyzer (bottom half)
	var freq_count = 64
	var bar_width = w / float(freq_count)
	
	for i in range(freq_count):
		var freq_low = 20.0 * pow(2.0, i * 10.0 / freq_count)
		var freq_high = 20.0 * pow(2.0, (i + 1) * 10.0 / freq_count)
		var magnitude = _spectrum.get_magnitude_for_frequency_range(freq_low, freq_high)
		var mag_db = linear_to_db(magnitude.length())
		var normalized = clamp((mag_db + 60.0) / 60.0, 0.0, 1.0)
		
		var bar_height = normalized * (h * 0.45)
		var bar_x = i * bar_width
		
		var color = Color.from_hsv(0.55 - normalized * 0.3, 0.7, 0.5 + normalized * 0.5)
		viz.draw_rect(Rect2(bar_x, h - bar_height, bar_width - 1, bar_height), color)


var _last_section_name: String = ""
var _skip_section_update_until: float = 0.0  # Skip auto-update until this time (seconds)

func _process(delta):
	if _is_playing and _player.playing:
		# Manual time tracking (AudioStreamInteractive doesn't report position correctly)
		_playback_time += delta
		_timeline.set_current_time(_playback_time)
		
		# Check loop
		if _loop_enabled and _playback_time >= _loop_end:
			_playback_time = _loop_start
			# Switch to correct clip for the loop start
			if _current_stream:
				for section in _timeline._sections:
					if _loop_start >= section["start"] and _loop_start < section["end"] and section.has("index"):
						var playback = _player.get_stream_playback()
						if playback and playback.has_method("switch_to_clip"):
							playback.switch_to_clip(section["index"])
						break
		
		# Update visualizer
		if _visualizer:
			_visualizer.get_child(0).queue_redraw()
		
		# Update section dropdown to match current position
		_update_section_dropdown(_playback_time)
		
		# Apply realtime effects
		_apply_realtime_effects()


func _update_section_dropdown(pos: float):
	"""Keep section dropdown and words in sync with playhead"""
	# Skip auto-update briefly after manual section selection (seek hasn't caught up)
	if Time.get_ticks_msec() / 1000.0 < _skip_section_update_until:
		return
	
	for i in range(_timeline._sections.size()):
		var section = _timeline._sections[i]
		if pos >= section["start"] and pos < section["end"]:
			if section["name"] != _last_section_name:
				_last_section_name = section["name"]
				_section_dropdown.selected = i + 1  # +1 for "Section" placeholder
				_update_words_for_section(section["name"])  # Update words for new section
			return


func _apply_realtime_effects():
	"""Apply live_params to audio buses for real-time changes"""
	# Master volume
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, live_params["master_volume"])
	
	# Find or create effect buses for real-time control
	# For now, update any existing effects
	for i in range(AudioServer.get_bus_effect_count(master_idx)):
		var effect = AudioServer.get_bus_effect(master_idx, i)
		if effect is AudioEffectReverb:
			effect.wet = live_params.get("reverb_mix", 0.3)
		elif effect is AudioEffectDelay:
			effect.dry = 1.0 - live_params.get("delay_mix", 0.2)
			effect.tap1_delay_ms = live_params.get("delay_time", 0.375) * 1000


func _load_timeline_for_song(song_id: String, stream: AudioStream):
	_current_song_id = song_id  # Track for section word updates
	# Reuse logic from SongPreviewDesktop
	var metadata = {
		"name": song_id,
		"sections": [],
		"total_duration": 0.0
	}
	
	if stream is AudioStreamInteractive:
		var interactive = stream as AudioStreamInteractive
		var time_offset = 0.0
		
		for i in range(interactive.clip_count):
			var clip_name = interactive.get_clip_name(i)
			var clip_stream = interactive.get_clip_stream(i)
			var duration = 8.0
			if clip_stream:
				duration = clip_stream.get_length()
			
			metadata["sections"].append({
				"name": clip_name if clip_name else "Section %d" % (i + 1),
				"start": time_offset,
				"end": time_offset + duration,
				"index": i,
				"layers": []
			})
			time_offset += duration
		
		metadata["total_duration"] = time_offset
	else:
		metadata["total_duration"] = stream.get_length() if stream else 60.0
		metadata["sections"] = [{"name": "Full Track", "start": 0.0, "end": metadata["total_duration"], "layers": []}]
	
	_timeline.load_song_metadata(metadata)
	
	# Load word descriptors for the song
	_load_song_words(song_id)
	
	# Populate section dropdown
	_section_dropdown.clear()
	_section_dropdown.add_item("Section", 0)
	for section in metadata["sections"]:
		_section_dropdown.add_item(section["name"])
	_section_dropdown.disabled = false
	_section_dropdown.selected = 0


# === WORD PICKER ===

var _word_picker_popup: PopupPanel = null
var _word_picker_layer: String = ""

func show_word_picker(layer: String, position: Vector2 = Vector2.ZERO):
	"""Show popup to browse and add words for a layer"""
	_word_picker_layer = layer
	
	if _word_picker_popup == null:
		_word_picker_popup = _create_word_picker_popup()
		add_child(_word_picker_popup)
	
	_populate_word_picker(layer)
	
	if position == Vector2.ZERO:
		position = get_viewport_rect().size / 2.0 - Vector2(_word_picker_popup.size) / 2.0
	_word_picker_popup.position = position
	_word_picker_popup.popup()


func _create_word_picker_popup() -> PopupPanel:
	var popup = PopupPanel.new()
	popup.size = Vector2(400, 500)
	
	var panel = VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	panel.add_theme_constant_override("separation", 8)
	popup.add_child(panel)
	
	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "🏷️ ADD WORD"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)
	
	# Category tabs
	var tabs = TabContainer.new()
	tabs.name = "Categories"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(tabs)
	
	# Create tab for each category
	for category in ["timbral", "envelope", "spatial", "movement", "experimental"]:
		var scroll = ScrollContainer.new()
		scroll.name = category.capitalize()
		tabs.add_child(scroll)
		
		var flow = HFlowContainer.new()
		flow.name = "Words"
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		scroll.add_child(flow)
	
	# Current words display
	var current_label = Label.new()
	current_label.name = "CurrentLabel"
	current_label.text = "Current: "
	current_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(current_label)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): popup.hide())
	panel.add_child(close_btn)
	
	return popup


func _populate_word_picker(layer: String):
	if _word_picker_popup == null:
		return
	
	var tabs = _word_picker_popup.find_child("Categories", true, false) as TabContainer
	if tabs == null:
		return
	
	var current_words = _word_display._layer_words.get(layer, [])
	
	# Update title
	var title = _word_picker_popup.find_child("Title", true, false) as Label
	if title:
		title.text = "🏷️ ADD WORD TO: %s" % layer
	
	# Update current words label
	var current_label = _word_picker_popup.find_child("CurrentLabel", true, false) as Label
	if current_label:
		current_label.text = "Current: %s" % ", ".join(current_words) if not current_words.is_empty() else "Current: (none)"
	
	# Populate each category
	for i in range(tabs.get_tab_count()):
		var category = tabs.get_tab_title(i).to_lower()
		var scroll = tabs.get_child(i) as ScrollContainer
		var flow = scroll.find_child("Words", true, false) as HFlowContainer
		if flow == null:
			continue
		
		# Clear existing
		for child in flow.get_children():
			child.queue_free()
		
		# Add word buttons
		var words = _word_bridge.get_all_words_in_category(category)
		for word in words:
			var btn = Button.new()
			btn.text = word
			btn.toggle_mode = true
			btn.button_pressed = word in current_words
			btn.add_theme_font_size_override("font_size", 12)
			
			# Color based on whether it's active
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.3, 0.4, 0.5) if word in current_words else Color(0.2, 0.2, 0.25)
			style.set_corner_radius_all(4)
			style.content_margin_left = 8
			style.content_margin_right = 8
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			btn.add_theme_stylebox_override("normal", style)
			
			btn.toggled.connect(_on_word_picker_toggled.bind(layer, word))
			
			# Tooltip with description
			var params = _word_bridge.get_word_params(word)
			var opposites = _word_bridge.get_opposites(word)
			btn.tooltip_text = "Opposites: %s" % ", ".join(opposites) if not opposites.is_empty() else ""
			
			flow.add_child(btn)


func _on_word_picker_toggled(pressed: bool, layer: String, word: String):
	var current_words = _word_display._layer_words.get(layer, []).duplicate()
	
	if pressed and word not in current_words:
		# Add word, remove any opposites
		var opposites = _word_bridge.get_opposites(word)
		current_words = current_words.filter(func(w): return w not in opposites)
		current_words.append(word)
	elif not pressed and word in current_words:
		# Remove word
		current_words.erase(word)
	
	# Update display
	var params = _word_display._layer_params.get(layer, {})
	_word_display.set_layer_words(layer, current_words, params)
	
	# Apply via bridge
	var new_params = _word_bridge.apply_words_to_params(layer, current_words, live_params)
	for key in new_params.keys():
		if live_params.has(key):
			live_params[key] = new_params[key]
			if _param_sliders.has(key):
				_param_sliders[key].value = new_params[key]
	
	_apply_live_params()
	parameters_changed.emit(live_params)
	
	# Refresh picker display
	_populate_word_picker(layer)
	
	_status_label.text = "🏷️ %s: %s" % [layer, ", ".join(current_words)]
