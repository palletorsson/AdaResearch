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
const SynthConfigRegistry = preload("res://commons/audio/catalog/SynthConfigRegistry.gd")
const SoundIdentity = preload("res://commons/audio/catalog/SoundIdentity.gd")
const SoundIdentityPanel = preload("res://commons/audio/catalog/ui/SoundIdentityPanel.gd")
const SoundDetailPanel = preload("res://commons/audio/catalog/ui/SoundDetailPanel.gd")
const MidiPianoRoll = preload("res://commons/audio/catalog/ui/MidiPianoRoll.gd")
const AIAssistantPanel = preload("res://commons/audio/catalog/ui/AIAssistantPanel.gd")
# AudioSynthesizer is available via class_name - no preload needed
const PATTERN_OVERRIDES_PATH = "user://song_pattern_overrides.json"
const GLOBAL_SECTION_KEY = "__global__"

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
var _export_wav_btn: Button
var _export_midi_btn: Button
var _section_dropdown: OptionButton
var _reference_mix_toggle: CheckBox
var _reference_mix_mode: bool = true

# Timeline
var _timeline: SongTimeline
var _timeline_container: PanelContainer

# Dev Tools Panel
var _dev_panel: PanelContainer
var _layer_controls: VBoxContainer

# Word Display
var _word_display: WordSynthDisplay
var _layer_solos: Dictionary = {}  # layer_name -> {solo: CheckBox, mute: CheckBox, volume: HSlider}

# Tab navigation
var _main_tabs: TabContainer
var _overview_tab: Control
var _sound_editor_tab: Control
var _archive_tab: Control
var _midi_editor_tab: MidiPianoRoll
var _ai_panel = null  # AIAssistantPanel
var _sound_detail_panel: SoundDetailPanel
var _editor_back_btn: Button
var _editor_sound_name: Label
var _current_editor_layer: String = ""

# Archive UI
var _archive_list: ItemList
var _archive_details: RichTextLabel
var _archive_load_btn: Button
var _archive_compare_btn: Button
var _archive_index: Dictionary = {}

# Config Inspector (live JSON view)
var _config_inspector: PanelContainer
var _config_text: RichTextLabel
var _config_edit_btn: Button
var _config_path_label: Label
var _current_config: Dictionary = {}
var _current_config_path: String = ""
var _current_section_name: String = ""
var _current_song_words: Dictionary = {}  # layer_name -> {words: [...], params: {...}}
var _pattern_overrides: Dictionary = {}  # generator_song_id -> {sections:{section->{layer->data}}}

# Subset selector (grid editor subsets)
var _subset_dropdown: OptionButton
var _loaded_subsets: Dictionary = {}  # id -> parsed JSON
var _current_subset_id: String = ""

signal subset_changed(subset_id: String, subset_data: Dictionary)

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

# Track analyzer
var _scorecard: TrackScorecard

# Live parameters (these affect playback in real-time)
var live_params: Dictionary = {
	"master_volume": 0.0,
	"bass_filter_cutoff": 20000.0,
	"bass_filter_resonance": 0.1,
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
	"bass_filter_cutoff": {"min": 100.0, "max": 20000.0, "default": 20000.0},
	"bass_filter_resonance": {"min": 0.1, "max": 0.9, "default": 0.1},
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
	_load_pattern_overrides()
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
	_set_dev_effects_enabled(not _reference_mix_mode)


func _setup_realtime_effects():
	"""Add controllable effects to Master bus"""
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		return
	
	# Clear existing effects (we'll add our own in known order)
	while AudioServer.get_bus_effect_count(master_idx) > 0:
		AudioServer.remove_bus_effect(master_idx, 0)
	
	# Add effects in specific order for consistent indexing
	# 0: Filter (lowpass)
	var filter = AudioEffectFilter.new()
	filter.cutoff_hz = live_params.get("bass_filter_cutoff", 800.0)
	filter.resonance = live_params.get("bass_filter_resonance", 0.5)
	filter.db = AudioEffectFilter.FILTER_12DB
	AudioServer.add_bus_effect(master_idx, filter)
	
	# 1: Highpass filter (for pad brightness control)
	var highpass = AudioEffectHighPassFilter.new()
	highpass.cutoff_hz = 20.0  # Start fully open
	highpass.resonance = 0.5
	AudioServer.add_bus_effect(master_idx, highpass)
	
	# 2: Distortion
	var distortion = AudioEffectDistortion.new()
	distortion.mode = AudioEffectDistortion.MODE_ATAN  # Soft saturation
	distortion.drive = 0.0
	distortion.keep_hf_hz = 8000
	AudioServer.add_bus_effect(master_idx, distortion)
	
	# 3: Chorus (for pad detune/width simulation)
	var chorus = AudioEffectChorus.new()
	chorus.voice_count = 2
	chorus.set("voice/1/delay_ms", 15.0)
	chorus.set("voice/1/rate_hz", 0.8)
	chorus.set("voice/1/depth_ms", live_params.get("pad_detune", 10.0) * 0.5)
	chorus.set("voice/1/level_db", 0.0)
	chorus.set("voice/2/delay_ms", 20.0)
	chorus.set("voice/2/rate_hz", 0.9)
	chorus.set("voice/2/depth_ms", live_params.get("pad_detune", 10.0) * 0.4)
	chorus.set("voice/2/level_db", 0.0)
	chorus.dry = 0.8
	chorus.wet = 0.2
	AudioServer.add_bus_effect(master_idx, chorus)
	
	# 4: Delay
	var delay = AudioEffectDelay.new()
	delay.tap1_active = true
	delay.tap1_delay_ms = live_params.get("delay_time", 0.375) * 1000
	delay.tap1_level_db = -6.0
	delay.dry = 1.0 - live_params.get("delay_mix", 0.2)
	delay.feedback_active = true
	delay.feedback_delay_ms = delay.tap1_delay_ms
	delay.feedback_level_db = -12.0
	AudioServer.add_bus_effect(master_idx, delay)
	
	# 5: Reverb
	var reverb = AudioEffectReverb.new()
	reverb.wet = live_params.get("reverb_mix", 0.3)
	reverb.room_size = 0.6
	reverb.damping = 0.5
	AudioServer.add_bus_effect(master_idx, reverb)
	
	# 6: Limiter (safety)
	var limiter = AudioEffectLimiter.new()
	limiter.ceiling_db = -0.5
	limiter.threshold_db = -6.0
	AudioServer.add_bus_effect(master_idx, limiter)


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
	# Modern dark background with subtle gradient feel
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Main TabContainer with modern styling
	_main_tabs = TabContainer.new()
	_main_tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_tabs.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	_main_tabs.tab_changed.connect(_on_tab_changed)
	_style_tab_container(_main_tabs)
	add_child(_main_tabs)
	
	# === OVERVIEW TAB ===
	_overview_tab = Control.new()
	_overview_tab.name = "🎵 Overview"
	_main_tabs.add_child(_overview_tab)
	
	# Main horizontal split (inside overview tab)
	var hsplit = HSplitContainer.new()
	hsplit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hsplit.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 8)
	_overview_tab.add_child(hsplit)
	
	# Left panel - song list and timeline
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 2.0
	left_panel.add_theme_constant_override("separation", 16)
	hsplit.add_child(left_panel)
	
	# Modern header with title
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	left_panel.add_child(header)
	
	_title_label = Label.new()
	_title_label.text = "SONG DEV TOOLS"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	header.add_child(_title_label)
	
	# Subset dropdown in header (modern pill style)
	_subset_dropdown = OptionButton.new()
	_subset_dropdown.custom_minimum_size = Vector2(200, 36)
	_style_dropdown_modern(_subset_dropdown)
	_subset_dropdown.item_selected.connect(_on_subset_selected)
	header.add_child(_subset_dropdown)
	
	# Load subsets after dropdown is styled and ready
	call_deferred("_load_subsets")
	
	# Song buttons in a modern card
	var songs_panel = PanelContainer.new()
	songs_panel.custom_minimum_size.y = 180
	songs_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_style_panel_modern(songs_panel, Color(0.09, 0.09, 0.12))
	left_panel.add_child(songs_panel)
	
	var songs_scroll = ScrollContainer.new()
	songs_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	songs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	songs_panel.add_child(songs_scroll)
	
	var songs_grid = GridContainer.new()
	songs_grid.columns = 3
	songs_grid.add_theme_constant_override("h_separation", 10)
	songs_grid.add_theme_constant_override("v_separation", 10)
	songs_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	songs_scroll.add_child(songs_grid)
	
	# Load all songs from the songs folder
	var songs = _load_songs_from_folder()
	
	for song in songs:
		var btn = Button.new()
		btn.text = song[1]
		btn.pressed.connect(_on_song_selected.bind(song[0]))
		_style_button_modern(btn, _get_song_button_color(song[0]))
		btn.custom_minimum_size.x = 140
		_song_buttons[song[0]] = btn
		songs_grid.add_child(btn)
	
	if songs.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No songs found.\nAdd JSON configs to songs/ folder."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		songs_grid.add_child(empty_label)
	
	# Transport controls in modern bar
	var transport_panel = PanelContainer.new()
	var transport_style = StyleBoxFlat.new()
	transport_style.bg_color = Color(0.12, 0.12, 0.15)
	transport_style.set_corner_radius_all(10)
	transport_style.content_margin_left = 12
	transport_style.content_margin_right = 12
	transport_style.content_margin_top = 8
	transport_style.content_margin_bottom = 8
	transport_panel.add_theme_stylebox_override("panel", transport_style)
	left_panel.add_child(transport_panel)
	
	var transport = HBoxContainer.new()
	transport.add_theme_constant_override("separation", 12)
	transport_panel.add_child(transport)
	
	_play_btn = Button.new()
	_play_btn.text = "▶"
	_play_btn.disabled = true
	_play_btn.custom_minimum_size = Vector2(44, 36)
	_play_btn.pressed.connect(_toggle_pause)
	_style_button_modern(_play_btn, Color(0.2, 0.55, 0.35))
	transport.add_child(_play_btn)
	
	_stop_btn = Button.new()
	_stop_btn.text = "⏹"
	_stop_btn.disabled = true
	_stop_btn.custom_minimum_size = Vector2(44, 36)
	_stop_btn.pressed.connect(_stop_song)
	_style_button_modern(_stop_btn, Color(0.55, 0.25, 0.25))
	transport.add_child(_stop_btn)
	
	_loop_btn = Button.new()
	_loop_btn.text = "🔁 Loop"
	_loop_btn.toggle_mode = true
	_loop_btn.toggled.connect(_on_loop_toggled)
	_style_button_modern(_loop_btn, Color(0.35, 0.3, 0.5))
	transport.add_child(_loop_btn)
	
	# Analyze button
	var analyze_btn = Button.new()
	analyze_btn.text = "📊 Analyze"
	analyze_btn.disabled = false
	analyze_btn.pressed.connect(_analyze_current_track)
	_style_button_modern(analyze_btn, Color(0.25, 0.35, 0.45))
	transport.add_child(analyze_btn)
	
	# Export WAV button
	_export_wav_btn = Button.new()
	_export_wav_btn.text = "💾 WAV"
	_export_wav_btn.disabled = true
	_export_wav_btn.custom_minimum_size = Vector2(70, 36)
	_export_wav_btn.pressed.connect(_export_wav)
	_style_button_modern(_export_wav_btn, Color(0.3, 0.45, 0.35))
	transport.add_child(_export_wav_btn)
	
	# Export MIDI button
	_export_midi_btn = Button.new()
	_export_midi_btn.text = "🎹 MIDI"
	_export_midi_btn.disabled = true
	_export_midi_btn.custom_minimum_size = Vector2(70, 36)
	_export_midi_btn.pressed.connect(_export_midi)
	_style_button_modern(_export_midi_btn, Color(0.35, 0.3, 0.45))
	transport.add_child(_export_midi_btn)
	
	# Section dropdown (modern)
	_section_dropdown = OptionButton.new()
	_section_dropdown.custom_minimum_size = Vector2(130, 36)
	_section_dropdown.add_item("Section", 0)
	_section_dropdown.disabled = true
	_section_dropdown.item_selected.connect(_on_section_selected)
	_style_dropdown_modern(_section_dropdown)
	transport.add_child(_section_dropdown)
	
	_reference_mix_toggle = CheckBox.new()
	_reference_mix_toggle.text = "Preview Ref"
	_reference_mix_toggle.button_pressed = _reference_mix_mode
	_reference_mix_toggle.add_theme_font_size_override("font_size", 12)
	_reference_mix_toggle.add_theme_color_override("font_color", Color(0.7, 0.9, 0.85))
	_reference_mix_toggle.toggled.connect(_on_reference_mix_toggled)
	transport.add_child(_reference_mix_toggle)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transport.add_child(spacer)
	
	_status_label = Label.new()
	_status_label.text = "Select a song..."
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.55, 0.57, 0.65))
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
	
	# Track Scorecard (collapsible)
	var scorecard_header = HBoxContainer.new()
	scorecard_header.add_theme_constant_override("separation", 8)
	left_panel.add_child(scorecard_header)
	
	var scorecard_toggle = Button.new()
	scorecard_toggle.text = "📊 Track Analysis"
	scorecard_toggle.toggle_mode = true
	scorecard_toggle.button_pressed = false
	scorecard_toggle.toggled.connect(func(pressed): _scorecard.visible = pressed)
	_style_button_compact(scorecard_toggle, Color(0.3, 0.4, 0.5))
	scorecard_header.add_child(scorecard_toggle)
	
	_scorecard = TrackScorecard.new()
	_scorecard.visible = false
	_scorecard.custom_minimum_size.y = 350
	left_panel.add_child(_scorecard)
	
	# Config Inspector (live JSON view)
	_setup_config_inspector(left_panel)
	
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
	
	# === SOUND EDITOR TAB ===
	_setup_sound_editor_tab()
	
	# === ARCHIVE TAB ===
	_setup_archive_tab()
	
	# === MIDI EDITOR TAB ===
	_midi_editor_tab = MidiPianoRoll.new()
	_midi_editor_tab.name = "🎹 MIDI Editor"
	_main_tabs.add_child(_midi_editor_tab)
	
	# === AI ASSISTANT TAB ===
	_ai_panel = AIAssistantPanel.new()
	_ai_panel.name = "🤖 AI Assistant"
	_ai_panel.midi_editor = _midi_editor_tab
	_ai_panel.song_dev_tools = self
	_main_tabs.add_child(_ai_panel)


func _setup_sound_editor_tab():
	"""Create the Sound Editor tab with full editing capabilities"""
	_sound_editor_tab = VBoxContainer.new()
	_sound_editor_tab.name = "🎛️ Sound Editor"
	_sound_editor_tab.add_theme_constant_override("separation", 8)
	_main_tabs.add_child(_sound_editor_tab)
	
	# Header with back button and sound name
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_sound_editor_tab.add_child(header)
	
	_editor_back_btn = Button.new()
	_editor_back_btn.text = "← Back to Overview"
	_editor_back_btn.pressed.connect(_on_editor_back_pressed)
	_style_button_compact(_editor_back_btn, Color(0.3, 0.35, 0.4))
	header.add_child(_editor_back_btn)
	
	_editor_sound_name = Label.new()
	_editor_sound_name.text = "Select a sound to edit"
	_editor_sound_name.add_theme_font_size_override("font_size", 24)
	_editor_sound_name.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	_editor_sound_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_editor_sound_name)
	
	# Hint label when no sound selected
	var hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "Click on a layer name in the Overview tab to edit its sound"
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sound_editor_tab.add_child(hint_label)
	
	# Sound Detail Panel (hidden until a sound is selected)
	_sound_detail_panel = SoundDetailPanel.new()
	_sound_detail_panel.name = "DetailPanel"
	_sound_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sound_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sound_detail_panel.visible = false
	_sound_detail_panel.param_changed.connect(_on_detail_param_changed)
	_sound_detail_panel.word_added.connect(_on_detail_word_added)
	_sound_detail_panel.word_removed.connect(_on_detail_word_removed)
	_sound_detail_panel.preview_requested.connect(_on_detail_preview)
	_sound_detail_panel.pattern_changed.connect(_on_detail_pattern_changed)
	_sound_detail_panel.close_requested.connect(_on_editor_back_pressed)
	_sound_editor_tab.add_child(_sound_detail_panel)


func _on_tab_changed(tab_index: int):
	"""Handle tab switching"""
	# Refresh archive list when switching to archive tab
	if tab_index == 2:  # Archive tab
		_refresh_archive_list()


func _setup_archive_tab():
	"""Create the Archive Songs tab for accessing old song versions"""
	_archive_tab = HSplitContainer.new()
	_archive_tab.name = "📦 Archive"
	_main_tabs.add_child(_archive_tab)
	
	# Left panel - archive list
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 1.0
	left_panel.add_theme_constant_override("separation", 8)
	_archive_tab.add_child(left_panel)
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	left_panel.add_child(header)
	
	var title = Label.new()
	title.text = "📦 ARCHIVED SONGS"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 Refresh"
	refresh_btn.pressed.connect(_refresh_archive_list)
	_style_button_compact(refresh_btn, Color(0.3, 0.4, 0.5))
	header.add_child(refresh_btn)
	
	# Archive list
	var list_panel = PanelContainer.new()
	var list_style = StyleBoxFlat.new()
	list_style.bg_color = Color(0.06, 0.06, 0.08)
	list_style.set_corner_radius_all(6)
	list_panel.add_theme_stylebox_override("panel", list_style)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(list_panel)
	
	_archive_list = ItemList.new()
	_archive_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_archive_list.item_selected.connect(_on_archive_item_selected)
	_archive_list.add_theme_font_size_override("font_size", 14)
	list_panel.add_child(_archive_list)
	
	# Action buttons
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	left_panel.add_child(actions)
	
	_archive_load_btn = Button.new()
	_archive_load_btn.text = "📂 Load Archived"
	_archive_load_btn.disabled = true
	_archive_load_btn.pressed.connect(_on_archive_load_pressed)
	_style_button_compact(_archive_load_btn, Color(0.3, 0.5, 0.4))
	actions.add_child(_archive_load_btn)
	
	_archive_compare_btn = Button.new()
	_archive_compare_btn.text = "⚖️ Compare to Current"
	_archive_compare_btn.disabled = true
	_archive_compare_btn.pressed.connect(_on_archive_compare_pressed)
	_style_button_compact(_archive_compare_btn, Color(0.4, 0.4, 0.5))
	actions.add_child(_archive_compare_btn)
	
	# Right panel - archive details
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.5
	right_panel.add_theme_constant_override("separation", 8)
	_archive_tab.add_child(right_panel)
	
	var details_title = Label.new()
	details_title.text = "📋 ARCHIVE DETAILS"
	details_title.add_theme_font_size_override("font_size", 18)
	details_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	right_panel.add_child(details_title)
	
	var details_panel = PanelContainer.new()
	var details_style = StyleBoxFlat.new()
	details_style.bg_color = Color(0.06, 0.06, 0.08)
	details_style.set_corner_radius_all(6)
	details_style.content_margin_left = 12
	details_style.content_margin_right = 12
	details_style.content_margin_top = 12
	details_style.content_margin_bottom = 12
	details_panel.add_theme_stylebox_override("panel", details_style)
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(details_panel)
	
	_archive_details = RichTextLabel.new()
	_archive_details.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_archive_details.bbcode_enabled = true
	_archive_details.text = "[color=#888888]Select an archived song to view details...[/color]"
	_archive_details.add_theme_font_size_override("normal_font_size", 13)
	details_panel.add_child(_archive_details)
	
	# Load archive index
	_load_archive_index()


func _setup_config_inspector(parent: Control):
	"""Create the live JSON config inspector panel"""
	# Header with toggle and edit button
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	parent.add_child(header)
	
	var toggle_btn = Button.new()
	toggle_btn.text = "📋 Config Inspector"
	toggle_btn.toggle_mode = true
	toggle_btn.button_pressed = true  # Visible by default
	_style_button_compact(toggle_btn, Color(0.4, 0.5, 0.3))
	header.add_child(toggle_btn)
	
	_config_edit_btn = Button.new()
	_config_edit_btn.text = "✏️ Edit JSON"
	_config_edit_btn.disabled = true
	_config_edit_btn.pressed.connect(_on_config_edit_pressed)
	_style_button_compact(_config_edit_btn, Color(0.5, 0.4, 0.3))
	header.add_child(_config_edit_btn)
	
	_config_path_label = Label.new()
	_config_path_label.text = ""
	_config_path_label.add_theme_font_size_override("font_size", 11)
	_config_path_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_config_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_config_path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_config_path_label)
	
	# Config panel
	_config_inspector = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09)
	style.border_color = Color(0.2, 0.25, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_config_inspector.add_theme_stylebox_override("panel", style)
	_config_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_config_inspector.custom_minimum_size.y = 200
	parent.add_child(_config_inspector)
	
	# Toggle visibility
	toggle_btn.toggled.connect(func(pressed): _config_inspector.visible = pressed)
	
	# Scroll container for config text
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_config_inspector.add_child(scroll)
	
	# RichTextLabel for selectable, formatted JSON
	_config_text = RichTextLabel.new()
	_config_text.bbcode_enabled = true
	_config_text.fit_content = true
	_config_text.selection_enabled = true  # Make text selectable!
	_config_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_config_text.add_theme_font_size_override("normal_font_size", 12)
	_config_text.add_theme_font_size_override("mono_font_size", 12)
	_config_text.text = "[color=#666666]Select a song to view its config...[/color]"
	scroll.add_child(_config_text)


func _on_config_edit_pressed():
	"""Open the config JSON file in the system editor"""
	if _current_config_path.is_empty():
		return
	
	# Convert res:// path to absolute path
	var abs_path = ProjectSettings.globalize_path(_current_config_path)
	
	# Open in default system editor
	if OS.get_name() == "Windows":
		OS.shell_open(abs_path)
	elif OS.get_name() == "macOS":
		OS.execute("open", [abs_path])
	else:
		OS.execute("xdg-open", [abs_path])
	
	_status_label.text = "📝 Opened: " + _current_config_path.get_file()


func _load_config_for_song(song_id: String):
	"""Load and display the JSON config for the current song"""
	var config_path = "res://commons/audio/parameters/songs/%s.json" % song_id
	_current_config_path = config_path
	
	if not FileAccess.file_exists(config_path):
		_config_text.text = "[color=#ff6666]No config file found: %s[/color]" % config_path
		_config_edit_btn.disabled = true
		_config_path_label.text = ""
		_current_config = {}
		return
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		_config_text.text = "[color=#ff6666]Failed to open config file[/color]"
		_config_edit_btn.disabled = true
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		_config_text.text = "[color=#ff6666]JSON parse error: %s[/color]" % json.get_error_message()
		_config_edit_btn.disabled = true
		return
	
	_current_config = json.data
	_config_edit_btn.disabled = false
	_config_path_label.text = config_path.get_file()
	
	# Format and display the config
	_update_config_display()


func _update_config_display():
	"""Update the config display, highlighting the current section"""
	if _current_config.is_empty():
		return
	
	var formatted = _format_config_as_bbcode(_current_config, _current_section_name)
	_config_text.text = formatted


func _format_config_as_bbcode(config: Dictionary, highlight_section: String = "", indent: int = 0) -> String:
	"""Format config dictionary as BBCode with syntax highlighting"""
	var lines = []
	var prefix = "  ".repeat(indent)
	
	for key in config.keys():
		var value = config[key]
		var key_color = "#88aaff"  # Blue for keys
		
		# Highlight current section
		var is_current_section = false
		if key == "sections" or (highlight_section != "" and key.to_lower() == highlight_section.to_lower()):
			is_current_section = true
			key_color = "#ffcc00"  # Yellow for current section
		
		if value is Dictionary:
			# Check if this is the highlighted section
			var section_marker = ""
			if is_current_section or (indent == 2 and key.to_lower() == highlight_section.to_lower()):
				section_marker = " [color=#00ff88]◀ NOW[/color]"
			lines.append("%s[color=%s]\"%s\"[/color]:%s {" % [prefix, key_color, key, section_marker])
			lines.append(_format_config_as_bbcode(value, highlight_section, indent + 1))
			lines.append("%s}" % prefix)
		elif value is Array:
			if value.size() <= 8 and not (value.size() > 0 and value[0] is Dictionary):
				# Short array - inline
				var items = []
				for item in value:
					if item is String:
						items.append("[color=#98c379]\"%s\"[/color]" % item)
					else:
						items.append("[color=#d19a66]%s[/color]" % str(item))
				lines.append("%s[color=%s]\"%s\"[/color]: [%s]" % [prefix, key_color, key, ", ".join(items)])
			else:
				# Long array - multiline
				lines.append("%s[color=%s]\"%s\"[/color]: [" % [prefix, key_color, key])
				for item in value:
					if item is Dictionary:
						lines.append(_format_config_as_bbcode(item, highlight_section, indent + 1))
					elif item is String:
						lines.append("%s  [color=#98c379]\"%s\"[/color]," % [prefix, item])
					else:
						lines.append("%s  [color=#d19a66]%s[/color]," % [prefix, str(item)])
				lines.append("%s]" % prefix)
		elif value is String:
			lines.append("%s[color=%s]\"%s\"[/color]: [color=#98c379]\"%s\"[/color]" % [prefix, key_color, key, value])
		elif value is bool:
			var bool_color = "#56b6c2" if value else "#e06c75"
			lines.append("%s[color=%s]\"%s\"[/color]: [color=%s]%s[/color]" % [prefix, key_color, key, bool_color, str(value).to_lower()])
		else:
			lines.append("%s[color=%s]\"%s\"[/color]: [color=#d19a66]%s[/color]" % [prefix, key_color, key, str(value)])
	
	return "\n".join(lines)


func _on_section_changed(section_name: String):
	"""Called when the current section changes during playback"""
	_current_section_name = section_name
	_update_config_display()
	_sync_open_sound_editor_section()


func _load_pattern_overrides():
	"""Load persistent pattern overrides from user storage."""
	_pattern_overrides.clear()
	if not FileAccess.file_exists(PATTERN_OVERRIDES_PATH):
		return
	
	var file = FileAccess.open(PATTERN_OVERRIDES_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open pattern override store: %s" % PATTERN_OVERRIDES_PATH)
		return
	
	var json = JSON.new()
	var parse_error = json.parse(file.get_as_text())
	file.close()
	
	if parse_error != OK:
		push_warning("Pattern override JSON parse error: %s" % json.get_error_message())
		return
	
	if json.data is Dictionary:
		_pattern_overrides = json.data


func _save_pattern_overrides():
	"""Persist pattern overrides to user storage."""
	var global_path = ProjectSettings.globalize_path(PATTERN_OVERRIDES_PATH)
	var base_dir = global_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(base_dir)
	
	var file = FileAccess.open(PATTERN_OVERRIDES_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write pattern override store: %s" % PATTERN_OVERRIDES_PATH)
		return
	
	file.store_string(JSON.stringify(_pattern_overrides, "\t"))
	file.close()


func _resolve_pattern_song_id(song_id: String) -> String:
	"""Resolve display/song aliases to SoundbankGenerator pattern ids."""
	var pattern_map = {
		"detroit_sb": "detroit_techno",
		"synthwave_sb": "synthwave",
		"burial_sb": "burial",
		"boc_sb": "boards_of_canada",
		"rave_sb": "rave",
		"kraftwerk_sb": "kraftwerk",
		"madonna_sb": "madonna_80s",
		"gypsy_sb": "gypsy_woman_house",
		"dub_house_sb": "dub_house",
		"moroder_disco_sb": "moroder_disco",
		"midnight_metroplex": "detroit_techno",
		"i_feel_love": "moroder_disco",
		"computer_love": "kraftwerk",
		"dark_wave_cathedral": "dark_wave",
	}
	return pattern_map.get(song_id, song_id)


func _get_song_pattern_overrides(song_id: String) -> Dictionary:
	var resolved_song_id = _resolve_pattern_song_id(song_id)
	var song_entry = _pattern_overrides.get(resolved_song_id, {})
	if not (song_entry is Dictionary):
		return {}
	var sections = song_entry.get("sections", {})
	return sections if sections is Dictionary else {}


func _store_pattern_override(song_id: String, section_name: String, layer: String, pattern_data: Dictionary):
	if song_id.is_empty() or layer.is_empty() or pattern_data.is_empty():
		return
	
	var resolved_song_id = _resolve_pattern_song_id(song_id)
	var song_entry = _pattern_overrides.get(resolved_song_id, {})
	if not (song_entry is Dictionary):
		song_entry = {}
	
	var sections = song_entry.get("sections", {})
	if not (sections is Dictionary):
		sections = {}
	
	var section_key = section_name if not section_name.is_empty() else GLOBAL_SECTION_KEY
	if not sections.has(section_key):
		sections[section_key] = {}
	if not sections.has(GLOBAL_SECTION_KEY):
		sections[GLOBAL_SECTION_KEY] = {}
	
	sections[section_key][layer] = pattern_data.duplicate(true)
	sections[GLOBAL_SECTION_KEY][layer] = pattern_data.duplicate(true)
	
	song_entry["sections"] = sections
	song_entry["updated_at"] = Time.get_datetime_string_from_system()
	_pattern_overrides[resolved_song_id] = song_entry
	_save_pattern_overrides()


func _apply_pattern_override_to_generator(song_id: String, layer: String, pattern_data: Dictionary):
	"""Apply one edited pattern to runtime generator dictionaries."""
	if song_id.is_empty() or pattern_data.is_empty():
		return
	
	var SG = load("res://commons/audio/generators/SoundbankGenerator.gd")
	if SG == null:
		return
	
	var resolved_song_id = _resolve_pattern_song_id(song_id)
	if not SG.PATTERNS.has(resolved_song_id):
		SG.PATTERNS[resolved_song_id] = {}
	
	var layer_lower = layer.to_lower()
	
	# Bass/lead melodic pattern payload
	if pattern_data.has("pattern"):
		var pattern_array = pattern_data.get("pattern", [])
		if pattern_array is Array:
			SG.PATTERNS[resolved_song_id][layer] = pattern_array.duplicate()
			
			if ("bass" in layer_lower or "sub" in layer_lower or "hoover" in layer_lower) and SG.BASS_PATTERNS.has(resolved_song_id):
				SG.BASS_PATTERNS[resolved_song_id]["pattern"] = pattern_array.duplicate()
				if pattern_data.has("notes"):
					SG.BASS_PATTERNS[resolved_song_id]["notes"] = pattern_data["notes"].duplicate()
				if pattern_data.has("glides"):
					SG.BASS_PATTERNS[resolved_song_id]["glides"] = pattern_data["glides"].duplicate()
		return
	
	# Multi-lane pattern payload (typically drums)
	for key in pattern_data.keys():
		if pattern_data[key] is Array:
			SG.PATTERNS[resolved_song_id][key] = pattern_data[key].duplicate()


func _apply_song_pattern_overrides_to_generator(song_id: String):
	"""Apply persistent global overrides before generating/previewing songs."""
	var sections = _get_song_pattern_overrides(song_id)
	if sections.is_empty():
		return
	
	var global_layers = sections.get(GLOBAL_SECTION_KEY, {})
	if not (global_layers is Dictionary):
		return
	
	for layer in global_layers.keys():
		var layer_data = global_layers[layer]
		if layer_data is Dictionary:
			_apply_pattern_override_to_generator(song_id, str(layer), layer_data)
		elif layer_data is Array:
			_apply_pattern_override_to_generator(song_id, str(layer), {"pattern": layer_data})


func _sync_open_sound_editor_section():
	if _current_editor_layer.is_empty():
		return
	if _sound_detail_panel == null or not _sound_detail_panel.visible:
		return
	
	var song_overrides = _get_song_pattern_overrides(_current_song_id)
	_sound_detail_panel.set_pattern_overrides(song_overrides)
	_sound_detail_panel.set_section(_current_section_name)


func _load_archive_index():
	"""Load the archive index JSON file"""
	var path = "res://commons/audio/parameters/songs/archive/ARCHIVE_INDEX.json"
	if not FileAccess.file_exists(path):
		print("Archive index not found at: ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Failed to open archive index")
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		print("Failed to parse archive index: ", json.get_error_message())
		return
	
	_archive_index = json.data
	print("Loaded archive index with %d entries" % _archive_index.get("archives", []).size())


func _refresh_archive_list():
	"""Refresh the archive list from the index"""
	_archive_list.clear()
	_load_archive_index()
	
	var archives = _archive_index.get("archives", [])
	
	# Group by song
	var by_song: Dictionary = {}
	for entry in archives:
		var song = entry.get("song", "unknown")
		if not by_song.has(song):
			by_song[song] = []
		by_song[song].append(entry)
	
	# Add items grouped by song
	for song in by_song.keys():
		var versions = by_song[song]
		for entry in versions:
			var version = entry.get("version", 0)
			var date = entry.get("date", "unknown")
			var emotion = entry.get("emotion", "")
			
			var display_text = "%s v%d (%s)" % [song, version, date]
			if not emotion.is_empty():
				display_text += " - %s" % emotion
			
			var idx = _archive_list.add_item(display_text)
			_archive_list.set_item_metadata(idx, entry)
			
			# Color based on song type
			var color = _get_song_color(song)
			_archive_list.set_item_custom_fg_color(idx, color)
	
	if _archive_list.item_count == 0:
		_archive_list.add_item("No archived songs found")
		_archive_list.set_item_disabled(0, true)
	
	_status_label.text = "📦 Loaded %d archived versions" % archives.size()


func _get_song_color(song_id: String) -> Color:
	"""Get a distinct color for each song type (for archive list)"""
	match song_id:
		"ambient_works", "ambient_techno": return Color(0.4, 0.7, 0.9)
		"detroit_techno", "detroit_sb": return Color(0.7, 0.5, 0.9)
		"moroder_disco", "french_touch": return Color(0.9, 0.6, 0.4)
		"pop_generative", "pop_v2", "pop_madonna": return Color(0.9, 0.4, 0.6)
		"prog_synth_70s", "prog_synth_v2", "prog_odyssey": return Color(0.5, 0.8, 0.5)
		"rave", "reese_jungle": return Color(0.9, 0.3, 0.3)
		"synthwave", "blade_runner", "synthwave_sb": return Color(0.6, 0.4, 0.9)
		"burial_sb": return Color(0.4, 0.4, 0.5)
		"boc_sb": return Color(0.6, 0.5, 0.3)
		"rave_sb": return Color(0.9, 0.2, 0.2)
		"kraftwerk_sb": return Color(0.3, 0.6, 0.9)
		"madonna_sb": return Color(0.95, 0.5, 0.7)
		"gypsy_sb": return Color(0.4, 0.8, 0.6)
		"dub_house_sb": return Color(0.45, 0.65, 0.7)
		"boards_of_canada", "boards_of_canada_v2": return Color(0.6, 0.75, 0.6)
		"burial", "burial_v2": return Color(0.4, 0.4, 0.6)
		"kraftwerk", "kraftwerk_v2": return Color(0.8, 0.5, 0.5)
		"supersaw_trance": return Color(0.3, 0.6, 0.9)
		"lofi_house": return Color(0.7, 0.6, 0.5)
		"chromatic_story": return Color(0.5, 0.7, 0.85)
		_: return Color(0.3, 0.45, 0.55)


func _get_song_button_color(song_id: String) -> Color:
	"""Get button color for overview - modern muted tones"""
	var base = _get_song_color(song_id)
	# Desaturate slightly and darken for modern flat look
	return base.darkened(0.4).lerp(Color(0.15, 0.15, 0.18), 0.3)


func _load_songs_from_folder() -> Array:
	"""Load all songs from songs folder (archive is for version history, not hiding)"""
	var songs = []
	var songs_path = "res://commons/audio/parameters/songs"
	
	# Display name mappings
	var display_names = {
		"acid_house": "🧪 Acid House",
		"acid_techno_303": "🔊 Acid Techno 303",
		"ambient_works": "🌊 Ambient Works",
		"ambient_techno": "🌌 Ambient Techno",
		"blade_runner": "🌃 Blade Runner",
		"boards_of_canada": "📼 BoC",
		"boards_of_canada_v2": "📼 BoC V2",
		"burial": "🌧️ Burial",
		"burial_v2": "🌧️ Burial V2",
		"detroit_techno": "🔩 Hard Detroit",
		"detroit_sb": "🔩 Detroit (Soundbank)",
		"midnight_metroplex": "🌃 Midnight Metroplex",
		"synthwave_sb": "🌆 Synthwave (Soundbank)",
		"burial_sb": "🌧️ Burial (Soundbank)",
		"boc_sb": "📼 BoC (Soundbank)",
		"rave_sb": "⚡ Rave (Soundbank)",
		"kraftwerk_sb": "🤖 Kraftwerk (Soundbank)",
		"madonna_sb": "💃 Madonna 80s (Soundbank)",
		"gypsy_sb": "🎹 Gypsy Woman (Soundbank)",
		"dub_house_sb": "Dub House (Soundbank)",
		"french_touch": "🇫🇷 French Touch",
		"gypsy_woman_house": "💃 Gypsy Woman",
		"kraftwerk": "🤖 Kraftwerk",
		"kraftwerk_v2": "🤖 Kraftwerk V2",
		"lofi_house": "📼 Lo-Fi House",
		"moroder_disco": "🪩 Moroder Disco",
		"pop_generative": "🎤 Pop",
		"pop_madonna": "👸 Madonna 80s",
		"pop_v2": "🎤 Pop V2",
		"prog_synth_70s": "🎸 70s Prog",
		"prog_synth_v2": "🎸 Prog V2",
		"prog_odyssey": "🚀 Prog Odyssey",
		"ada_theme": "🎤 Ada Theme",
		"aphex_twin": "💛 Digital Amber (Aphex)",
		"aphex_twin_digital_amber": "💛 Digital Amber",
		"rave": "⚡ Rave",
		"reese_jungle": "🌴 Jungle",
		"k_bass": "🇰🇷 K-Bass",
		"supersaw_trance": "🔊 Supersaw",
		"synthwave": "🌃 Synthwave",
		"chromatic_story": "🎹 Chromatic Story"
	}
	
	# Read songs folder
	var dir = DirAccess.open(songs_path)
	if dir == null:
		print("Failed to open songs directory")
		return songs
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Skip directories and non-JSON files
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var song_id = file_name.replace(".json", "")
			var display_name = display_names.get(song_id, "🎵 " + song_id.replace("_", " ").capitalize())
			songs.append([song_id, display_name])
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort alphabetically
	songs.sort_custom(func(a, b): return a[1] < b[1])
	
	print("Loaded %d songs from folder" % songs.size())
	return songs


func _on_archive_item_selected(index: int):
	"""Display details for selected archive entry"""
	var entry = _archive_list.get_item_metadata(index)
	if entry == null or entry is not Dictionary:
		return
	
	_archive_load_btn.disabled = false
	_archive_compare_btn.disabled = false
	
	# Build details text
	var text = ""
	
	# Song name and version
	var song = entry.get("song", "unknown")
	var version = entry.get("version", 0)
	text += "[b][color=#88ccff]%s[/color][/b] — Version %d\n" % [song.replace("_", " ").capitalize(), version]
	text += "[color=#666666]━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n"
	
	# Date and filename
	text += "[color=#aaaaaa]📅 Date:[/color] %s\n" % entry.get("date", "unknown")
	text += "[color=#aaaaaa]📄 File:[/color] %s\n\n" % entry.get("filename", "unknown")
	
	# Description
	var desc = entry.get("description", "")
	if not desc.is_empty():
		text += "[color=#aaaaaa]📝 Description:[/color]\n%s\n\n" % desc
	
	# Quick stats
	var bpm = entry.get("bpm", 0)
	var key = entry.get("key", "")
	var emotion = entry.get("emotion", "")
	
	if bpm > 0 or not key.is_empty() or not emotion.is_empty():
		text += "[color=#aaaaaa]🎵 Quick Stats:[/color]\n"
		if bpm > 0:
			text += "  • BPM: [color=#ffcc88]%d[/color]\n" % bpm
		if not key.is_empty():
			text += "  • Key: [color=#88ffcc]%s[/color]\n" % key
		if not emotion.is_empty():
			text += "  • Emotion: [color=#ff88cc]%s[/color]\n" % emotion.replace("_", " ")
		text += "\n"
	
	# Changes
	var changes = entry.get("changes", [])
	if not changes.is_empty():
		text += "[color=#aaaaaa]🔄 Changes in this version:[/color]\n"
		for change in changes:
			text += "  • %s\n" % change
		text += "\n"
	
	_archive_details.text = text


func _on_archive_load_pressed():
	"""Load the selected archived song config"""
	var selected = _archive_list.get_selected_items()
	if selected.is_empty():
		return
	
	var entry = _archive_list.get_item_metadata(selected[0])
	if entry == null:
		return
	
	var filename = entry.get("filename", "")
	var path = "res://commons/audio/parameters/songs/archive/%s" % filename
	
	if not FileAccess.file_exists(path):
		_status_label.text = "❌ Archive file not found: %s" % filename
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_label.text = "❌ Failed to open archive file"
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		_status_label.text = "❌ Failed to parse archive: %s" % json.get_error_message()
		return
	
	var config = json.data
	
	# Display the config in a popup or detail view
	_show_archived_config(entry.get("song", "unknown"), config)
	
	_status_label.text = "📂 Loaded archived: %s v%d" % [entry.get("song", ""), entry.get("version", 0)]


func _show_archived_config(song_id: String, config: Dictionary):
	"""Display the archived config details"""
	var popup = PopupPanel.new()
	popup.size = Vector2(600, 700)
	popup.title = "Archived Config: %s" % song_id
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	popup.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "📦 %s (Archived)" % song_id.replace("_", " ").capitalize()
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	vbox.add_child(title)
	
	# Display config as formatted text
	var text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var formatted = _format_config_for_display(config)
	text.text = formatted
	vbox.add_child(text)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): popup.queue_free())
	_style_button_compact(close_btn, Color(0.4, 0.3, 0.3))
	vbox.add_child(close_btn)
	
	add_child(popup)
	popup.position = get_viewport_rect().size / 2.0 - Vector2(popup.size) / 2.0
	popup.popup()


func _format_config_for_display(config: Dictionary, indent: int = 0) -> String:
	"""Format a config dictionary as BBCode for display"""
	var text = ""
	var prefix = "  ".repeat(indent)
	
	for key in config.keys():
		var value = config[key]
		
		# Skip archive metadata in display
		if key == "_archive_metadata":
			continue
		
		if value is Dictionary:
			text += "%s[color=#88ccff]%s:[/color]\n" % [prefix, key]
			text += _format_config_for_display(value, indent + 1)
		elif value is Array:
			text += "%s[color=#88ccff]%s:[/color] [" % [prefix, key]
			var items = []
			for item in value:
				if item is Dictionary:
					items.append("{...}")
				else:
					items.append(str(item))
			text += ", ".join(items) + "]\n"
		else:
			var color = "#aaffaa" if value is int or value is float else "#ffcc88" if value is String else "#cccccc"
			text += "%s[color=#88ccff]%s:[/color] [color=%s]%s[/color]\n" % [prefix, key, color, str(value)]
	
	return text


func _on_archive_compare_pressed():
	"""Compare selected archive with current song config"""
	var selected = _archive_list.get_selected_items()
	if selected.is_empty():
		return
	
	var entry = _archive_list.get_item_metadata(selected[0])
	if entry == null:
		return
	
	var song_id = entry.get("song", "")
	
	# Load archived config
	var filename = entry.get("filename", "")
	var archive_path = "res://commons/audio/parameters/songs/archive/%s" % filename
	
	if not FileAccess.file_exists(archive_path):
		_status_label.text = "❌ Archive file not found"
		return
	
	var archive_file = FileAccess.open(archive_path, FileAccess.READ)
	var json = JSON.new()
	json.parse(archive_file.get_as_text())
	archive_file.close()
	var archived_config = json.data
	
	# Load current config
	var current_path = "res://commons/audio/parameters/songs/%s.json" % song_id
	if not FileAccess.file_exists(current_path):
		_status_label.text = "❌ Current config not found: %s" % song_id
		return
	
	var current_file = FileAccess.open(current_path, FileAccess.READ)
	json.parse(current_file.get_as_text())
	current_file.close()
	var current_config = json.data
	
	# Show comparison
	_show_config_comparison(song_id, archived_config, current_config, entry.get("version", 0))
	
	_status_label.text = "⚖️ Comparing %s v%d to current" % [song_id, entry.get("version", 0)]


func _show_config_comparison(song_id: String, archived: Dictionary, current: Dictionary, version: int):
	"""Show side-by-side comparison of archived vs current config"""
	var popup = PopupPanel.new()
	popup.size = Vector2(900, 700)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 12)
	main_vbox.add_theme_constant_override("separation", 8)
	popup.add_child(main_vbox)
	
	# Title
	var title = Label.new()
	title.text = "⚖️ %s — v%d vs Current" % [song_id.replace("_", " ").capitalize(), version]
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	main_vbox.add_child(title)
	
	# Split view
	var hsplit = HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(hsplit)
	
	# Archived side
	var archived_panel = VBoxContainer.new()
	archived_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.add_child(archived_panel)
	
	var archived_label = Label.new()
	archived_label.text = "📦 Archived (v%d)" % version
	archived_label.add_theme_font_size_override("font_size", 16)
	archived_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	archived_panel.add_child(archived_label)
	
	var archived_scroll = ScrollContainer.new()
	archived_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	archived_panel.add_child(archived_scroll)
	
	var archived_text = RichTextLabel.new()
	archived_text.bbcode_enabled = true
	archived_text.fit_content = true
	archived_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archived_text.text = _format_config_for_display(archived)
	archived_scroll.add_child(archived_text)
	
	# Current side
	var current_panel = VBoxContainer.new()
	current_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.add_child(current_panel)
	
	var current_label = Label.new()
	current_label.text = "📄 Current"
	current_label.add_theme_font_size_override("font_size", 16)
	current_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.5))
	current_panel.add_child(current_label)
	
	var current_scroll = ScrollContainer.new()
	current_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	current_panel.add_child(current_scroll)
	
	var current_text = RichTextLabel.new()
	current_text.bbcode_enabled = true
	current_text.fit_content = true
	current_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_text.text = _format_config_for_display(current)
	current_scroll.add_child(current_text)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): popup.queue_free())
	_style_button_compact(close_btn, Color(0.4, 0.3, 0.3))
	main_vbox.add_child(close_btn)
	
	add_child(popup)
	popup.position = get_viewport_rect().size / 2.0 - Vector2(popup.size) / 2.0
	popup.popup()


func _on_editor_back_pressed():
	"""Return to Overview tab"""
	_main_tabs.current_tab = 0


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
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var focus = style.duplicate()
	focus.bg_color = color.lightened(0.1)
	focus.border_color = Color(0.4, 0.6, 1.0, 0.5)
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", focus)


func _style_button_modern(btn: Button, color: Color):
	"""Modern flat button with subtle glow on hover"""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.12)
	hover.shadow_size = 4
	hover.shadow_color = Color(color.r, color.g, color.b, 0.3)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	pressed.shadow_size = 1
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))


func _style_dropdown_modern(dropdown: OptionButton):
	"""Modern styled dropdown/select"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.16, 0.2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 30  # Room for arrow
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_color = Color(0.25, 0.27, 0.35)
	style.set_border_width_all(1)
	dropdown.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.18, 0.19, 0.24)
	hover.border_color = Color(0.4, 0.5, 0.7)
	dropdown.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.2, 0.22, 0.28)
	pressed.border_color = Color(0.5, 0.6, 0.8)
	dropdown.add_theme_stylebox_override("pressed", pressed)
	
	var focus = style.duplicate()
	focus.border_color = Color(0.4, 0.6, 1.0)
	focus.set_border_width_all(2)
	dropdown.add_theme_stylebox_override("focus", focus)
	
	dropdown.add_theme_font_size_override("font_size", 14)
	dropdown.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	dropdown.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	dropdown.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	dropdown.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	
	# Arrow color
	dropdown.add_theme_color_override("arrow_color", Color(0.6, 0.65, 0.75))


func _style_dropdown_popup(dropdown: OptionButton):
	"""Style the dropdown popup menu"""
	var popup = dropdown.get_popup()
	if popup == null:
		return
	
	popup.transparent_bg = false
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.12, 0.13, 0.16)
	popup_style.set_corner_radius_all(8)
	popup_style.border_color = Color(0.25, 0.27, 0.35)
	popup_style.set_border_width_all(1)
	popup_style.shadow_color = Color(0, 0, 0, 0.4)
	popup_style.shadow_size = 8
	popup.add_theme_stylebox_override("panel", popup_style)
	
	popup.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	popup.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	popup.add_theme_color_override("font_accelerator_color", Color(0.5, 0.5, 0.6))
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.25, 0.35, 0.55)
	hover_style.set_corner_radius_all(4)
	popup.add_theme_stylebox_override("hover", hover_style)
	
	popup.add_theme_constant_override("v_separation", 6)
	popup.add_theme_constant_override("h_separation", 8)


func _style_tab_container(tabs: TabContainer):
	"""Modern tab container styling"""
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.13)
	panel_style.set_corner_radius_all(8)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	tabs.add_theme_stylebox_override("panel", panel_style)
	
	tabs.add_theme_font_size_override("font_size", 14)
	tabs.add_theme_color_override("font_selected_color", Color(0.95, 0.95, 0.98))
	tabs.add_theme_color_override("font_unselected_color", Color(0.5, 0.52, 0.58))
	tabs.add_theme_color_override("font_hovered_color", Color(0.75, 0.77, 0.82))


func _style_panel_modern(panel: PanelContainer, bg_color: Color = Color(0.1, 0.1, 0.13)):
	"""Modern panel with subtle border"""
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(10)
	style.border_color = Color(0.18, 0.19, 0.24)
	style.set_border_width_all(1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)


# === SONG PLAYBACK ===

func _on_song_selected(song_id: String):
	_stop_song()
	_current_song = song_id
	_current_editor_layer = ""
	_status_label.text = "Generating " + song_id + "..."
	
	# Load config for inspector
	_load_config_for_song(song_id)
	
	for btn in _song_buttons.values():
		btn.disabled = true
	
	call_deferred("_generate_and_play", song_id)


func _set_dev_effects_enabled(enabled: bool) -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		return
	
	# The first six effects are the DevTools color chain.
	var effect_count = AudioServer.get_bus_effect_count(master_idx)
	var controlled_count = mini(6, effect_count)
	for i in range(controlled_count):
		AudioServer.set_bus_effect_enabled(master_idx, i, enabled)


func _on_reference_mix_toggled(pressed: bool) -> void:
	_reference_mix_mode = pressed
	_set_dev_effects_enabled(not _reference_mix_mode)
	_apply_live_params()
	if _reference_mix_mode:
		_status_label.text = "Mode: Preview Reference"
	else:
		_status_label.text = "Mode: Dev Tools"


func _generate_preview_reference_stream(song_id: String) -> AudioStream:
	match song_id:
		"chromatic_story":
			return SoundbankGenerator.generate_song("chromatic_story", {"bpm": 100})
		"nineties_rnb":
			return SoundbankGenerator.generate_song("nineties_rnb", {"bpm": 92})
		"computer_love":
			return SoundbankGenerator.generate_song("kraftwerk", {"bpm": 129})
		"aphex_twin", "aphex_twin_digital_amber":
			return SoundbankGenerator.generate_song("aphex_twin", {"bpm": 108})
		"ada_theme":
			return SoundbankGenerator.generate_song("ada_theme", {"bpm": 100})
		"prog_synth_70s":
			return AudioSynthesizer.generate_prog_synth_song({})
		"prog_odyssey":
			return AudioSynthesizer.generate_prog_odyssey_song({})
		"kpop_prog":
			return AudioSynthesizer.generate_kpop_prog_song({})
		"pop_generative":
			return AudioSynthesizer.generate_pop_interactive_song({})
		"ambient_works":
			return AudioSynthesizer.generate_ambient_works_song({})
		"i_feel_love", "moroder_disco":
			return SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})
		"detroit_techno":
			return AudioSynthesizer.generate_detroit_techno_song({})
		"midnight_metroplex":
			return SoundbankGenerator.generate_song("detroit_techno", {})
		"synthwave":
			return AudioSynthesizer.generate_synthwave_song({})
		"rave":
			return AudioSynthesizer.generate_rave_song({})
		"replicants_dawn":
			return SoundbankGenerator.generate_hybrid_song("replicants_dawn", {})
		"foggy_frequencies":
			return SoundbankGenerator.generate_hybrid_song("foggy_frequencies", {})
		"chicago_dusseldorf":
			return SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", {})
		"dub_house_sb", "dub_house":
			return SoundbankGenerator.generate_song("dub_house", {"bpm": 122})
		"k_bass":
			return SoundbankGenerator.generate_song("k_bass", {"bpm": 170})
		"dark_wave_cathedral":
			return SoundbankGenerator.generate_song("dark_wave", {"bpm": 118})
		_:
			return null


func _build_generation_params(song_id: String) -> Dictionary:
	var params: Dictionary = {}
	
	if not _current_config.is_empty():
		var config_params = _current_config.get("parameters", {})
		if config_params is Dictionary:
			for param_name in config_params.keys():
				var param_info = config_params[param_name]
				if param_info is Dictionary:
					if param_info.has("value"):
						params[param_name] = param_info["value"]
					elif param_info.has("default"):
						params[param_name] = param_info["default"]
		
		var arrangement = _current_config.get("arrangement", null)
		if arrangement is Dictionary:
			params["arrangement"] = arrangement
			params["carry_layers"] = bool(arrangement.get("carry_layers", true))
			
			var variation_hint = str(arrangement.get("variation", "")).to_lower()
			if arrangement.has("enable_motif_variation"):
				params["enable_motif_variation"] = bool(arrangement["enable_motif_variation"])
			elif arrangement.has("motif_variation"):
				params["enable_motif_variation"] = bool(arrangement["motif_variation"])
			elif not variation_hint.is_empty():
				params["enable_motif_variation"] = not (variation_hint in ["none", "off", "false", "minimal"])
			
			if arrangement.has("motif_variation_amount"):
				params["motif_variation_amount"] = float(arrangement["motif_variation_amount"])
			elif variation_hint == "minimal":
				params["motif_variation_amount"] = 0.2
			elif variation_hint == "medium":
				params["motif_variation_amount"] = 0.45
			elif variation_hint == "high":
				params["motif_variation_amount"] = 0.75
		
		var chord_progressions = _current_config.get("chord_progressions", null)
		if chord_progressions != null:
			params["chord_progressions"] = chord_progressions
			if chord_progressions is Array and chord_progressions.size() > 0 and chord_progressions[0] is Dictionary:
				params["progression_name"] = chord_progressions[0].get("name", "")
		
		var rhythm = _current_config.get("rhythm", null)
		if rhythm is Dictionary:
			if rhythm.has("humanize_ms"):
				params["humanize_ms"] = float(rhythm["humanize_ms"])
			if rhythm.has("swing_pct"):
				params["swing_pct"] = float(rhythm["swing_pct"])
	
	if not params.has("carry_layers"):
		params["carry_layers"] = true
	if not params.has("enable_motif_variation"):
		params["enable_motif_variation"] = false
	if not params.has("motif_variation_amount"):
		params["motif_variation_amount"] = 0.25
	
	params["song_id"] = song_id
	return params


func _generate_and_play(song_id: String):
	_apply_song_pattern_overrides_to_generator(song_id)
	
	var stream: AudioStream = null
	if _reference_mix_mode:
		stream = _generate_preview_reference_stream(song_id)
	var generation_params = _build_generation_params(song_id)
	
	# Soundbank previews (explicit *_sb IDs)
	if stream == null and song_id.ends_with("_sb"):
		var soundbank_map = {
			"detroit_sb": "detroit_techno",
			"synthwave_sb": "synthwave",
			"burial_sb": "burial",
			"boc_sb": "boards_of_canada",
			"rave_sb": "rave",
			"kraftwerk_sb": "kraftwerk",
			"madonna_sb": "madonna_80s",
			"gypsy_sb": "gypsy_woman_house",
			"dub_house_sb": "dub_house",
			"moroder_disco_sb": "moroder_disco",
		}
		var bank_id = soundbank_map.get(song_id, "")
		if bank_id != "":
			stream = SoundbankGenerator.generate_song(bank_id, generation_params)
		else:
			stream = null
	elif stream == null:
		# AudioSynthesizer has class_name - call static methods directly
		match song_id:
			"acid_house":
				stream = AudioSynthesizer.generate_acid_house_song(generation_params)
			"acid_techno_303":
				stream = AudioSynthesizer.generate_acid_house_song(generation_params)
			"prog_synth_70s":
				stream = AudioSynthesizer.generate_prog_synth_song(generation_params)
			"prog_odyssey":
				stream = AudioSynthesizer.generate_prog_odyssey_song(generation_params)
			"kpop_prog_remix":
				stream = AudioSynthesizer.generate_kpop_prog_song(generation_params)
			"pop_generative":
				stream = AudioSynthesizer.generate_pop_interactive_song(generation_params)
			"ambient_works":
				stream = AudioSynthesizer.generate_ambient_works_song(generation_params)
			"moroder_disco":
				stream = AudioSynthesizer.generate_moroder_disco_song(generation_params)
			"detroit_techno":
				stream = AudioSynthesizer.generate_detroit_techno_song(generation_params)
			"midnight_metroplex":
				stream = SoundbankGenerator.generate_song("detroit_techno", generation_params)
			"synthwave":
				stream = AudioSynthesizer.generate_synthwave_song(generation_params)
			"rave":
				stream = AudioSynthesizer.generate_rave_song(generation_params)
			"french_touch":
				stream = AudioSynthesizer.generate_french_touch_song(generation_params)
			"supersaw_trance":
				stream = AudioSynthesizer.generate_supersaw_trance_song(generation_params)
			"lofi_house":
				stream = AudioSynthesizer.generate_lofi_house_song(generation_params)
			"reese_jungle":
				stream = AudioSynthesizer.generate_reese_jungle_song(generation_params)
			"ambient_techno":
				stream = AudioSynthesizer.generate_ambient_techno_song(generation_params)
			"blade_runner":
				stream = AudioSynthesizer.generate_blade_runner_song(generation_params)
			"boards_of_canada":
				stream = AudioSynthesizer.generate_boards_of_canada_song(generation_params)
			"burial":
				stream = AudioSynthesizer.generate_burial_song(generation_params)
			"kraftwerk":
				stream = AudioSynthesizer.generate_kraftwerk_song(generation_params)
			"boards_of_canada_v2":
				stream = AudioSynthesizer.generate_boards_of_canada_v2_song(generation_params)
			"burial_v2":
				stream = AudioSynthesizer.generate_burial_v2_song(generation_params)
			"kraftwerk_v2":
				stream = AudioSynthesizer.generate_kraftwerk_v2_song(generation_params)
			"prog_synth_v2":
				stream = AudioSynthesizer.generate_prog_synth_v2_song(generation_params)
			"pop_v2":
				stream = AudioSynthesizer.generate_pop_v2_song(generation_params)
			"pop_madonna":
				stream = AudioSynthesizer.generate_pop_madonna_song(generation_params)
			"gypsy_woman_house":
				stream = AudioSynthesizer.generate_gypsy_woman_house_song(generation_params)
			# === SOUND BANK-ONLY SONGS ===
			"aphex_twin", "aphex_twin_digital_amber":
				stream = SoundbankGenerator.generate_song("aphex_twin", generation_params)
			"ada_theme":
				stream = SoundbankGenerator.generate_song("ada_theme", generation_params)
			"chromatic_story":
				stream = SoundbankGenerator.generate_song("chromatic_story", generation_params)
			"nineties_rnb":
				stream = SoundbankGenerator.generate_song("nineties_rnb", generation_params)
			"k_bass":
				stream = SoundbankGenerator.generate_song("k_bass", generation_params)
			"vangelis_cs80":
				stream = SoundbankGenerator.generate_song("vangelis_cs80", generation_params)
			"dark_wave_cathedral":
				stream = SoundbankGenerator.generate_song("dark_wave", generation_params)
			# === HYBRID SONGS ===
			"chicago_dusseldorf":
				stream = SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", generation_params)
			"replicants_dawn":
				stream = SoundbankGenerator.generate_hybrid_song("replicants_dawn", generation_params)
			"foggy_frequencies":
				stream = SoundbankGenerator.generate_hybrid_song("foggy_frequencies", generation_params)
			_:
				# No generator - show config breakdown only (no audio)
				_status_label.text = "?? %s (config only - no audio)" % song_id
				_current_song_id = song_id
				_load_song_words(song_id)
				_enable_buttons()
				return
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
	_export_wav_btn.disabled = false
	_export_midi_btn.disabled = false
	_enable_buttons()
	
	# Load timeline metadata
	_load_timeline_for_song(song_id, stream)
	
	# Populate MIDI editor tab if capture is available
	if _midi_editor_tab:
		var midi_capture = AudioSynthesizer.capture_midi_for_song(song_id)
		if midi_capture:
			_midi_editor_tab.load_from_capture(midi_capture)


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
	_export_wav_btn.disabled = true
	_export_midi_btn.disabled = true
	_timeline.set_current_time(0.0)
	_timeline.set_playing(false)


func _analyze_current_track():
	"""Analyze the current track and display results in the scorecard"""
	if _current_stream == null:
		_status_label.text = "No track loaded - select a song first"
		return
	
	_status_label.text = "Analyzing track..."
	
	# Extract audio samples from the current stream
	var audio_data = PackedFloat32Array()
	
	if _current_stream is AudioStreamInteractive:
		var clip_count = _current_stream.clip_count
		if clip_count > 0:
			# Get first clip's stream
			var first_clip = _current_stream.get_clip_stream(0)
			if first_clip is AudioStreamWAV:
				audio_data = _extract_samples_from_wav(first_clip)
	
	if audio_data.is_empty():
		_status_label.text = "Could not extract audio for analysis"
		return
	
	# Run analysis
	var bpm = _estimate_bpm_from_song(_current_song_id)
	_scorecard.analyze(audio_data, bpm)
	
	# Show scorecard and update status
	_scorecard.visible = true
	var results = _scorecard.get_results()
	var overall = results.get("overall_score", 0.0) * 10.0
	_status_label.text = "Analysis: %.1f/10 | λ=%.2f" % [overall, results.get("estimated_lambda", 0.5)]


func _extract_samples_from_wav(wav: AudioStreamWAV) -> PackedFloat32Array:
	"""Extract float samples from AudioStreamWAV"""
	var result = PackedFloat32Array()
	var data = wav.data
	
	if data.is_empty():
		return result
	
	var format = wav.format
	
	match format:
		AudioStreamWAV.FORMAT_8_BITS:
			result.resize(data.size())
			for i in range(data.size()):
				result[i] = (float(data[i]) - 128.0) / 128.0
		AudioStreamWAV.FORMAT_16_BITS:
			var sample_count = data.size() / 2
			result.resize(sample_count)
			for i in range(sample_count):
				var low = data[i * 2]
				var high = data[i * 2 + 1]
				var value = low | (high << 8)
				if value >= 32768:
					value -= 65536
				result[i] = float(value) / 32768.0
		AudioStreamWAV.FORMAT_IMA_ADPCM:
			pass  # Complex, skip
	
	return result


func _estimate_bpm_from_song(song_id: String) -> float:
	"""Estimate BPM based on song style"""
	match song_id:
		"boards_of_canada", "boards_of_canada_v2":
			return 95.0
		"burial", "burial_v2":
			return 130.0
		"kraftwerk", "kraftwerk_v2":
			return 110.0
		"detroit_techno", "detroit_sb":
			return 128.0
		"rave":
			return 145.0
		"reese_jungle":
			return 170.0
		"french_touch":
			return 122.0
		"supersaw_trance":
			return 140.0
		"ambient_works", "ambient_techno":
			return 100.0
		"moroder_disco":
			return 115.0
		"synthwave", "blade_runner":
			return 100.0
		"lofi_house":
			return 115.0
		"prog_synth_70s":
			return 100.0
		"prog_synth_v2":
			return 105.0
		"prog_odyssey":
			return 100.0
		"pop_v2":
			return 118.0
		"pop_madonna":
			return 118.0
		_:
			return 120.0


# === EXPORT ===

func _export_wav():
	"""Export current song to WAV file"""
	if _current_stream == null:
		_status_label.text = "No song to export!"
		return
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = _current_song + "_" + timestamp + ".wav"
	var export_path = "user://exports/"
	
	# Ensure export directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_path))
	
	var full_path = export_path + filename
	
	_status_label.text = "Exporting WAV..."
	_export_wav_btn.disabled = true
	
	# Use SongExporter if available
	if ResourceLoader.exists("res://commons/audio/generators/SongExporter.gd"):
		var SongExporter = load("res://commons/audio/generators/SongExporter.gd")
		var result = SongExporter.export_interactive_to_wav(_current_stream, full_path)
		if result == OK:
			var global_path = ProjectSettings.globalize_path(full_path)
			_status_label.text = "Exported: " + global_path
			print("WAV exported to: ", global_path)
		else:
			_status_label.text = "WAV export failed!"
	else:
		# Fallback: export the stream directly if it's a WAV
		if _player.stream is AudioStreamWAV:
			var wav: AudioStreamWAV = _player.stream
			var err = wav.save_to_wav(full_path)
			if err == OK:
				var global_path = ProjectSettings.globalize_path(full_path)
				_status_label.text = "Exported: " + global_path
			else:
				_status_label.text = "WAV export failed!"
		else:
			_status_label.text = "Cannot export this stream type"
	
	_export_wav_btn.disabled = false


func _export_midi():
	"""Export current song patterns to MIDI file"""
	if _current_song.is_empty():
		_status_label.text = "No song to export!"
		return
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = _current_song + "_" + timestamp + ".mid"
	var export_path = "user://exports/"
	
	# Ensure export directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_path))
	
	var full_path = export_path + filename
	
	_status_label.text = "Exporting MIDI..."
	_export_midi_btn.disabled = true
	
	# Use MidiExporter
	if ResourceLoader.exists("res://commons/audio/generators/MidiExporter.gd"):
		var MidiExporter = load("res://commons/audio/generators/MidiExporter.gd")
		
		# Get BPM for this song
		var bpm = _estimate_bpm_from_song(_current_song)
		
		# Map song IDs to pattern IDs (some songs use different patterns or generators)
		var pattern_map = {
			# Songs that use soundbank patterns directly
			"midnight_metroplex": "detroit_techno",
			"i_feel_love": "moroder_disco",
			"computer_love": "kraftwerk",
			"aphex_twin_digital_amber": "boards_of_canada",
			"ada_theme": "chromatic_story",
			# Songs that use AudioSynthesizer — use MIDI capture path
			"prog_odyssey": "",
			"prog_synth_70s": "",
			"kraftwerk": "",
			"pop_generative": "",
			"ambient_works": "",
		}
		
		var pattern_id = pattern_map.get(_current_song, _current_song)
		
		# Check if this song has exportable patterns
		if pattern_id.is_empty():
			# AudioSynthesizer song — use MIDI capture
			var capture = AudioSynthesizer.capture_midi_for_song(_current_song)
			if capture != null:
				var capture_result = MidiExporter.export_from_capture(capture, full_path)
				if capture_result:
					var global_path_c = ProjectSettings.globalize_path(full_path)
					_status_label.text = "MIDI exported: " + global_path_c
					print("MIDI (capture) exported to: ", global_path_c)
				else:
					_status_label.text = "MIDI capture export failed for " + _current_song
			else:
				_status_label.text = "No MIDI capture available for " + _current_song
			_export_midi_btn.disabled = false
			return
		
		var result = MidiExporter.export_patterns(pattern_id, full_path, bpm)
		if result:
			var global_path = ProjectSettings.globalize_path(full_path)
			_status_label.text = "MIDI exported: " + global_path
			print("MIDI exported to: ", global_path)
		else:
			_status_label.text = "No patterns found for '" + pattern_id + "'"
	else:
		_status_label.text = "MidiExporter not found!"
	
	_export_midi_btn.disabled = false


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
		
		# Update word display and config inspector for this section
		_update_words_for_section(section["name"])
		_on_section_changed(section["name"])
		
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
			_on_section_changed(section_name)
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

func _on_layer_solo(_pressed: bool, layer_name: String):
	# TODO: Implement actual solo via bus routing
	pass


func _on_layer_mute(_pressed: bool, layer_name: String):
	# TODO: Implement actual mute via bus routing
	pass


func _on_layer_volume(_value: float, layer_name: String):
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
	# Show sound breakdown panel
	show_sound_breakdown(layer)
	
	# Also apply words
	var layer_words = _word_display._layer_words.get(layer, [])
	var new_params = _word_bridge.words_to_live_params(layer, layer_words)
	
	for key in new_params.keys():
		if live_params.has(key):
			live_params[key] = new_params[key]
			if _param_sliders.has(key):
				_param_sliders[key].value = new_params[key]
	
	_apply_live_params()
	_status_label.text = "🔬 %s breakdown" % layer


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


func _resolve_param(value) -> float:
	"""Resolve param value that might be a dict with range/value to a float"""
	if value is Dictionary:
		if value.has("value"):
			return float(value["value"])
		elif value.has("range"):
			var r = value["range"]
			var tendency = value.get("tendency", "middle")
			match tendency:
				"low": return r[0] + (r[1] - r[0]) * 0.25
				"high": return r[0] + (r[1] - r[0]) * 0.75
				_: return (r[0] + r[1]) / 2.0
		return 0.0
	return float(value) if value != null else 0.0


func _generate_layer_preview(layer: String, params: Dictionary) -> AudioStream:
	var sample_rate = 44100
	var duration = 2.0
	var samples = int(sample_rate * duration)
	var data = PackedFloat32Array()
	data.resize(samples)
	
	var base_freq = 261.63
	var attack = _resolve_param(params.get("env.attack", params.get("attack", 0.01)))
	var decay = _resolve_param(params.get("env.decay", params.get("decay", 0.2)))
	var sustain = _resolve_param(params.get("env.sustain", params.get("sustain", 0.7)))
	var voices = int(_resolve_param(params.get("osc.voices", params.get("voices", 1))))
	var detune = _resolve_param(params.get("osc.detune", params.get("detune", 0.0)))
	
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
		"prog_odyssey": {
			"Pad": {
				"words": ["warm", "wide", "swelling", "analog", "cathedral"],
				"params": {"voices": 7, "detune": 10, "attack": 2.0}
			},
			"Bass": {
				"words": ["warm", "thick", "analog", "punchy", "deep"],
				"params": {"filter_cutoff": 800, "resonance": 0.4, "glide": 50}
			},
			"Sequence": {
				"words": ["pulsing", "motorik", "hypnotic", "mechanical"],
				"params": {"pattern": "16th_arp", "filter_sweep": true}
			},
			"Lead": {
				"words": ["bright", "aggressive", "screaming", "portamento"],
				"params": {"portamento": 80, "vibrato": 5.0, "filter_cutoff": 3000}
			},
			"Drums": {
				"words": ["driving", "mechanical", "punchy", "motorik"],
				"params": {"pattern": "motorik", "tempo": 130}
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
		"dub_house_sb": {
			"Dub Stab": {
				"words": ["warm", "dark", "plucky", "distant"],
				"params": {"filter_cutoff": 1200, "decay": 0.18, "delay": 0.12}
			},
			"Sub Bass": {
				"words": ["warm", "soft", "pulsing"],
				"params": {"type": "sub", "style": "sustained"}
			},
			"Pad": {
				"words": ["warm", "wide", "sustained", "distant"],
				"params": {"attack": 1.2, "release": 1.5}
			},
			"Siren Drone": {
				"words": ["ominous", "swelling", "distant", "cinematic"],
				"params": {"sweep": "slow", "attack": 4.0, "release": 6.0}
			},
			"Drums": {
				"words": ["punchy", "soft", "warm"],
				"params": {"type": "909", "swing": 8}
			}
		},
		"reese_jungle": {
			"Reese Bass": {
				"words": ["wobbling", "detuned", "thick", "dark", "modulated", "growling"],
				"params": {"detune": 0.07, "sub": true, "filter_lfo": 0.5, "pitch_wobble": 0.003, "drive_swell": true}
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
			},
			"Derbyshire FX": {
				"words": ["metallic", "wobbly", "alien", "tape", "radiophonic", "zappy"],
				"params": {"ring_mod_carrier": 150, "ring_mod_depth": 0.8, "wobble_lfo": 3.0, "wobble_depth_cents": 80, "tape_sweep": true, "noise_burst_hz": 2000}
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
		},
		"boards_of_canada": {
			"Warbly Pad": {
				"words": ["warm", "analog", "unstable", "evolving", "lo-fi"],
				"params": {"type": "tape-degraded poly", "osc.drift": 0.12, "fx.distortion": 0.2}
			},
			"Melodic Sequence": {
				"words": ["warm", "dark", "plucky", "lo-fi"],
				"params": {"type": "detuned mono", "osc.drift": 0.08}
			},
			"Bass": {
				"words": ["warm", "soft", "thick"],
				"params": {"type": "warm sub", "filter.cutoff": 400}
			},
			"Texture Layer": {
				"words": ["lo-fi", "noisy", "evolving"],
				"params": {"type": "granular/tape noise", "fx.bitcrush.depth": 10}
			},
			"Drums": {
				"words": ["lo-fi", "warm", "soft"],
				"params": {"type": "lo-fi breakbeat", "tempo": 100}
			}
		},
		"burial": {
			"Sub Bass": {
				"words": ["thick", "dark", "punchy"],
				"params": {"type": "UK garage sub", "filter.cutoff": 120}
			},
			"Atmosphere Pad": {
				"words": ["spacious", "dark", "wide", "evolving"],
				"params": {"type": "dark reverb wash", "fx.reverb.decay": 6.0}
			},
			"Pitched Vocal": {
				"words": ["soft", "distant", "dreamy", "lo-fi"],
				"params": {"type": "timestretched R&B sample", "pitch_shift": -5}
			},
			"Crackle Layer": {
				"words": ["noisy", "lo-fi", "static"],
				"params": {"type": "vinyl noise"}
			},
			"Garage Stab": {
				"words": ["plucky", "soft", "spacious"],
				"params": {"type": "organ stab"}
			},
			"Drums": {
				"words": ["soft", "spacious"],
				"params": {"type": "2-step garage", "tempo": 130}
			}
		},
		"kraftwerk": {
			"Minimoog Bass": {
				"words": ["warm", "analog", "punchy", "clean"],
				"params": {"type": "Minimoog Model D", "filter.type": "ladder"}
			},
			"Sequencer Line": {
				"words": ["cold", "digital", "mechanical", "static"],
				"params": {"type": "ARP 2600 sequence", "osc.drift": 0.0}
			},
			"Vocoder Pad": {
				"words": ["wide", "cold", "digital"],
				"params": {"type": "Sennheiser VSM201 vocoder"}
			},
			"Lead Melody": {
				"words": ["warm", "analog", "sustained"],
				"params": {"type": "Minimoog lead", "mod.lfo.depth": 0.008}
			},
			"Electric Percussion": {
				"words": ["punchy", "percussive", "clean"],
				"params": {"type": "Syndrum / custom electronic"}
			},
			"Drums": {
				"words": ["punchy", "clean", "mechanical"],
				"params": {"type": "TR-808 / custom", "tempo": 110}
			}
		},
		# V2 Enhanced Versions
		"boards_of_canada_v2": {
			"Warbly Pad": {
				"words": ["warm", "analog", "unstable", "nostalgic", "tape-degraded"],
				"params": {"detune_cents": 15, "lfo_rate": 0.15, "voices": 4}
			},
			"Melody": {
				"words": ["childlike", "simple", "detuned", "dotted-delay"],
				"params": {"delay_type": "dotted_8th", "drift": 0.012}
			},
			"Warm Bass": {
				"words": ["deep", "soft", "filtered", "warm"],
				"params": {"filter_cutoff": 400, "saturation": "tape"}
			},
			"Lo-Fi Drums": {
				"words": ["crunchy", "humanized", "hip-hop", "bit-crushed"],
				"params": {"bitcrush": 10, "timing_humanize": 10}
			},
			"Texture": {
				"words": ["VHS", "tape-hiss", "crackle", "nostalgic"],
				"params": {"noise_type": "cassette"}
			}
		},
		"burial_v2": {
			"Atmosphere": {
				"words": ["dark", "cavernous", "evolving", "urban"],
				"params": {"reverb_decay": 6.0, "phaser": true}
			},
			"Sub Bass": {
				"words": ["underground", "earthy", "warm", "heavy"],
				"params": {"freq": 40, "saturation": 1.4}
			},
			"Garage Stab": {
				"words": ["organ", "reverbed", "offbeat", "soulful"],
				"params": {"harmonics": 3, "decay": 0.3}
			},
			"2-Step Drums": {
				"words": ["shuffled", "loose", "humanized", "fuzzy"],
				"params": {"timing_slop": 15, "quantize": false}
			},
			"Pitched Vocal": {
				"words": ["ghostly", "timestretched", "distant", "R&B"],
				"params": {"pitch_shift": -5, "timestretched": true}
			},
			"Crackle": {
				"words": ["vinyl", "rain", "static", "South London"],
				"params": {"density": 0.004}
			}
		},
		"kraftwerk_v2": {
			"Sequence": {
				"words": ["precise", "mechanical", "hypnotic", "stable"],
				"params": {"drift": 0.0, "filter_cutoff": 2000}
			},
			"Moog Bass": {
				"words": ["clean", "dual-saw", "ladder-filtered", "punchy"],
				"params": {"detune_cents": 2, "filter_cutoff": 600}
			},
			"Vocoder Pad": {
				"words": ["robotic", "formant", "chorus", "wide"],
				"params": {"bands": 16, "filter": 3000}
			},
			"Moog Lead": {
				"words": ["bright", "vibrato", "expressive", "Florian"],
				"params": {"vibrato_rate": 5, "vibrato_depth": 0.008}
			},
			"Motorik Drums": {
				"words": ["driving", "8th-hat", "mechanical", "Autobahn"],
				"params": {"pattern": "motorik", "tempo": 110}
			},
			"Car Sounds": {
				"words": ["engine", "highway", "road-noise", "cinematic"],
				"params": {"type": "Autobahn ambience"}
			}
		},
		"prog_synth_v2": {
			"Mellotron Pad": {
				"words": ["warm", "analog", "string-machine", "choir-like", "drifting"],
				"params": {"detune_cents": 10, "attack": 2.0, "chorus": 0.3, "drift": 5}
			},
			"Motif Bell": {
				"words": ["crystalline", "recurring", "identity", "5th-interval", "recognizable"],
				"params": {"interval": "P5", "recurrence": "every_8_bars", "decay": 1.2}
			},
			"Moog Bass V2": {
				"words": ["fat", "warm", "sub", "filtered", "analog-drift"],
				"params": {"osc": "dual_saw+sub", "filter": "ladder_800Hz", "drift_cents": 8}
			},
			"Arp Sequence": {
				"words": ["pulsing", "PWM", "resonant", "ascending", "hypnotic"],
				"params": {"wave": "square_pwm", "pattern": "1-5-8-5", "filter_sweep": true}
			},
			"Prog Lead": {
				"words": ["bright", "vibrato", "portamento", "screaming", "ELP-style"],
				"params": {"filter": 3500, "vibrato_hz": 5, "glide": true}
			},
			"Motorik V2": {
				"words": ["driving", "tight", "humanized", "8th-hats", "Neu!-style"],
				"params": {"pattern": "motorik", "humanize_ms": 5, "tempo": 105}
			}
		},
		"pop_v2": {
			"Pluck Motif": {
				"words": ["digital", "clean", "rhythmic", "identity", "chillwave"],
				"params": {"wave": "sine+harmonics", "decay": 6.0, "pattern": "syncopated"}
			},
			"Shimmer Arp": {
				"words": ["sparkle", "high", "detuned", "ethereal", "air"],
				"params": {"octave": "+2", "detune": 0.003, "decay": 8.0}
			},
			"Sub 808": {
				"words": ["deep", "sub", "pitched", "modern", "clean"],
				"params": {"freq_range": "30-60Hz", "pitch_env": true, "saturation": 1.2}
			},
			"Sidechain Pad": {
				"words": ["pumping", "warm", "ducking", "atmospheric", "soft-saw"],
				"params": {"sidechain": "4th-note", "attack": 0.1, "filter": "lowpass"}
			},
			"Vocal Chop": {
				"words": ["formant", "rhythmic", "pitched", "ah-vowel", "percussive"],
				"params": {"formants": [800, 1200, 2500], "decay": 8.0}
			},
			"Synth Lead": {
				"words": ["supersaw-lite", "bright", "melodic", "hook", "3-voice"],
				"params": {"voices": 3, "detune": 0.01, "filter": "mid-bright"}
			},
			"Snap Beat": {
				"words": ["minimal", "finger-snap", "clean", "modern", "sparse"],
				"params": {"kick": "4th", "snap": "backbeat", "hats": "8th"}
			},
			"Full Beat": {
				"words": ["driving", "layered-clap", "16th-hats", "punchy", "chorus-energy"],
				"params": {"kick": "4th+extra", "clap": "layered", "hats": "16th"}
			}
		},
		"pop_madonna": {
			"Gated Drums": {
				"words": ["80s", "gated-reverb", "punchy", "snappy", "dance"],
				"params": {"kick": "4-on-floor", "snare": "gated_reverb_150ms", "hats": "8th_bright"}
			},
			"Octave Bass": {
				"words": ["jumping", "synth", "saw", "filtered", "bouncy"],
				"params": {"pattern": "low-low-HIGH-low", "wave": "detuned_saw", "filter_env": true}
			},
			"Juno Pad": {
				"words": ["lush", "PWM", "bright", "chorus", "shimmery"],
				"params": {"wave": "pwm_square", "chorus": 0.4, "filter": "bright"}
			},
			"Synth Stab": {
				"words": ["brass", "DX7", "bright", "attack", "chord-hit"],
				"params": {"harmonics": 4, "decay": 12.0, "character": "brassy"}
			},
			"Hook Melody": {
				"words": ["catchy", "singable", "bright", "memorable", "lead"],
				"params": {"wave": "sine+saw", "range": "octave_up", "vibrato": false}
			},
			"String Hits": {
				"words": ["orchestral", "stab", "downbeat", "dramatic", "80s"],
				"params": {"attack": 0.02, "release": 0.4, "harmonics": "rich"}
			}
		}
	}
	
	var layers = song_words.get(song_id, {})
	_current_song_words = layers
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
				_on_section_changed(section["name"])  # Update config inspector
			return


func _apply_realtime_effects():
	"""Apply live_params to audio buses for real-time changes"""
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		return
	
	# Master volume
	AudioServer.set_bus_volume_db(master_idx, live_params["master_volume"])
	
	# Effects are in known order (set up in _setup_realtime_effects):
	# 0: Lowpass Filter, 1: Highpass Filter, 2: Distortion, 3: Chorus, 4: Delay, 5: Reverb, 6: Limiter
	
	var effect_count = AudioServer.get_bus_effect_count(master_idx)
	
	# 0: Lowpass Filter (bass_filter_cutoff, bass_filter_resonance)
	if effect_count > 0:
		var filter = AudioServer.get_bus_effect(master_idx, 0)
		if filter is AudioEffectFilter:
			# Map bass cutoff (100-2000) to filter (200-8000)
			var cutoff = live_params.get("bass_filter_cutoff", 800.0)
			filter.cutoff_hz = clampf(cutoff * 2.0, 200, 16000)
			filter.resonance = live_params.get("bass_filter_resonance", 0.5)
	
	# 1: Highpass Filter (pad_filter_cutoff inverted - higher = brighter = less bass)
	if effect_count > 1:
		var highpass = AudioServer.get_bus_effect(master_idx, 1)
		if highpass is AudioEffectHighPassFilter:
			# Map pad cutoff: low value = dark (highpass at 20), high value = bright (highpass higher)
			var pad_cutoff = live_params.get("pad_filter_cutoff", 2000.0)
			# Invert: low pad_cutoff → low highpass (more bass), high pad_cutoff → still low highpass
			# Actually, let's use it to thin out low end when pad is "bright"
			highpass.cutoff_hz = 20.0 + (8000 - pad_cutoff) * 0.01  # Subtle effect
	
	# 2: Distortion (drive based on "aggression" - derive from filter settings)
	if effect_count > 2:
		var distortion = AudioServer.get_bus_effect(master_idx, 2)
		if distortion is AudioEffectDistortion:
			# Use resonance as proxy for drive (high resonance = more edge)
			var resonance = live_params.get("bass_filter_resonance", 0.5)
			distortion.drive = resonance * 0.3  # Subtle
	
	# 3: Chorus (pad_detune → depth)
	if effect_count > 3:
		var chorus = AudioServer.get_bus_effect(master_idx, 3)
		if chorus is AudioEffectChorus:
			var detune = live_params.get("pad_detune", 10.0)
			chorus.set("voice/1/depth_ms", detune * 0.3)
			chorus.set("voice/2/depth_ms", detune * 0.25)
			chorus.wet = clampf(detune / 30.0, 0.0, 0.5) * 0.4  # More detune = more wet
	
	# 4: Delay
	if effect_count > 4:
		var delay = AudioServer.get_bus_effect(master_idx, 4)
		if delay is AudioEffectDelay:
			var delay_mix = live_params.get("delay_mix", 0.2)
			var delay_time = live_params.get("delay_time", 0.375)
			delay.dry = 1.0 - delay_mix
			delay.tap1_delay_ms = delay_time * 1000
			delay.tap1_level_db = -6.0 + (delay_mix * 6.0)  # Louder when more wet
			delay.feedback_delay_ms = delay_time * 1000
	
	# 5: Reverb
	if effect_count > 5:
		var reverb = AudioServer.get_bus_effect(master_idx, 5)
		if reverb is AudioEffectReverb:
			reverb.wet = live_params.get("reverb_mix", 0.3)
			# Room size based on pad volume (louder pad = bigger room feel)
			var pad_vol = live_params.get("pad_volume", 0.0)
			reverb.room_size = clampf(0.5 + pad_vol * 0.02, 0.3, 0.9)
	
	# Individual "volume" params - simulate via EQ-ish approach using filter bypass
	# For proper per-layer control we'd need separate buses, but we can fake it:
	# bass_volume → affects low frequencies
	# lead_volume → affects high frequencies  
	# drums_volume → affects transients (no good way without separate bus)
	
	# Simulate bass volume via filter cutoff modulation
	var bass_vol = live_params.get("bass_volume", 0.0)
	if effect_count > 0 and bass_vol < -6:
		var filter = AudioServer.get_bus_effect(master_idx, 0)
		if filter is AudioEffectFilter:
			# Lower bass volume = lower cutoff
			filter.cutoff_hz *= pow(10, bass_vol / 40.0)
	
	# Lead vibrato → modulate chorus rate slightly
	var vibrato = live_params.get("lead_vibrato_depth", 0.2)
	if effect_count > 3:
		var chorus = AudioServer.get_bus_effect(master_idx, 3)
		if chorus is AudioEffectChorus:
			var rate = 0.5 + vibrato * 4.0  # 0.5 to 2.5 Hz
			chorus.set("voice/1/rate_hz", rate)
			chorus.set("voice/2/rate_hz", rate * 1.1)  # Slight offset for richness


func _load_timeline_for_song(song_id: String, stream: AudioStream):
	_current_song_id = song_id  # Track for section word updates
	_sound_detail_panel.set_pattern_overrides(_get_song_pattern_overrides(song_id))
	
	var metadata = {"name": song_id, "sections": [], "total_duration": 0.0}
	
	if stream is AudioStreamInteractive:
		var interactive = stream as AudioStreamInteractive
		var time_offset = 0.0
		var song_layers = _get_layers_for_song(song_id)
		
		for i in range(interactive.clip_count):
			var clip_name = interactive.get_clip_name(i)
			var clip_stream = interactive.get_clip_stream(i)
			var duration = 8.0
			if clip_stream:
				duration = clip_stream.get_length()
			
			var section_layers = song_layers.get(clip_name.to_lower(), song_layers.get("default", []))
			
			metadata["sections"].append({
				"name": clip_name if clip_name else "Section %d" % (i + 1),
				"start": time_offset,
				"end": time_offset + duration,
				"index": i,
				"layers": section_layers
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
	_style_dropdown_popup(_section_dropdown)


func _get_layers_for_song(song_id: String) -> Dictionary:
	"""Return detailed layer/parameter info per section for each song type"""
	match song_id:
		"aphex_twin", "aphex_twin_digital_amber":
			return {
				"intro": [
					{"name": "Tape Texture", "type": "noise", "params": "hiss | warmth | memory"},
					{"name": "Warm Pad", "type": "pad", "params": "detuned ±8 cents | SAW85"},
				],
				"build": [
					{"name": "Warm Pad", "type": "pad", "params": "evolving | LFO drift"},
					{"name": "Sub Bass", "type": "bass", "params": "sine | pulse"},
					{"name": "Hi-Hat", "type": "drums", "params": "sparse | humanized"},
					{"name": "Sequence", "type": "seq", "params": "bell-like | detuned"},
				],
				"main": [
					{"name": "Kick", "type": "drums", "params": "pillow 808 | warm"},
					{"name": "Snare", "type": "drums", "params": "lo-fi break | ghosts"},
					{"name": "Hi-Hat", "type": "drums", "params": "intricate | velocity"},
					{"name": "Acid Bass", "type": "bass", "params": "303 squelch"},
					{"name": "Warm Pad", "type": "pad", "params": "nostalgic"},
					{"name": "Lead", "type": "lead", "params": "detuned fifth | RDJ"},
				],
				"breakdown": [
					{"name": "Piano", "type": "keys", "params": "prepared | intimate"},
					{"name": "Granular Pad", "type": "pad", "params": "crystalline"},
					{"name": "Vocal", "type": "vocal", "params": "ghostly | human traces"},
				],
				"outro": [
					{"name": "Warm Pad", "type": "pad", "params": "filter closing"},
					{"name": "Tape Texture", "type": "noise", "params": "fade to silence"},
				],
				"default": [{"name": "Digital Amber", "type": "mix", "params": "108 BPM | F#m"}]
			}
		"chicago_dusseldorf":
			return {
				"intro": [
					{"name": "House Piano", "type": "keys", "params": "jazz voicings | warm"},
					{"name": "House Organ", "type": "keys", "params": "sustained | sweep"},
				],
				"verse": [
					{"name": "House Kick", "type": "drums", "params": "4-on-floor"},
					{"name": "Chicago Bass", "type": "bass", "params": "offbeat | bouncy"},
					{"name": "House Piano", "type": "keys", "params": "offbeat stabs"},
				],
				"robotic": [
					{"name": "Motorik Kick", "type": "drums", "params": "machine"},
					{"name": "Kraftwerk Seq", "type": "seq", "params": "precise"},
					{"name": "Vocoder", "type": "vocal", "params": "Trans Europa"},
				],
				"default": [{"name": "Chi→Düss", "type": "mix", "params": "122 BPM"}]
			}
		"ada_theme":
			return {
				"intro": [{"name": "Warm Pad", "type": "pad", "params": "supportive | space for vocal"}],
				"verse": [
					{"name": "Pad", "type": "pad", "params": "bed"},
					{"name": "Bass", "type": "bass", "params": "sine | root notes"},
					{"name": "Drums", "type": "drums", "params": "minimal"},
				],
				"chorus": [
					{"name": "Pad", "type": "pad", "params": "fuller"},
					{"name": "Arp", "type": "seq", "params": "twinkling"},
				],
				"default": [{"name": "Ada Theme", "type": "mix", "params": "100 BPM | warm"}]
			}
		"dub_house_sb":
			return {
				"intro": [
					{"name": "Pad", "type": "pad", "params": "warm | slow attack"},
					{"name": "Siren Drone", "type": "pad", "params": "cinematic | slow sweep"},
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat | low intensity"},
				],
				"build": [
					{"name": "Kick", "type": "drums", "params": "deep 4-on-floor"},
					{"name": "Sub Bass", "type": "bass", "params": "round | sustained"},
					{"name": "Pad", "type": "pad", "params": "wide | distant"},
					{"name": "Siren Drone", "type": "pad", "params": "long sweep | distant"},
				],
				"main": [
					{"name": "Kick", "type": "drums", "params": "deep"},
					{"name": "Snare", "type": "drums", "params": "short | airy"},
					{"name": "Clap", "type": "drums", "params": "roomy"},
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat swing"},
					{"name": "Dub Stab", "type": "keys", "params": "filtered | delay tails"},
					{"name": "Sub Bass", "type": "bass", "params": "sub-forward"},
					{"name": "Pad", "type": "pad", "params": "warm bed"},
				],
				"breakdown": [
					{"name": "Dub Stab", "type": "keys", "params": "space and decay"},
					{"name": "Pad", "type": "pad", "params": "long release"},
					{"name": "Siren Drone", "type": "pad", "params": "slow rise | cinematic"},
				],
				"drop": [
					{"name": "Kick", "type": "drums", "params": "deep"},
					{"name": "Snare", "type": "drums", "params": "short"},
					{"name": "Clap", "type": "drums", "params": "roomy"},
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat"},
					{"name": "Dub Stab", "type": "keys", "params": "tape-delay"},
					{"name": "Sub Bass", "type": "bass", "params": "pulse"},
				],
				"outro": [
					{"name": "Hi-Hat", "type": "drums", "params": "offbeat"},
					{"name": "Pad", "type": "pad", "params": "fade"},
					{"name": "Siren Drone", "type": "pad", "params": "distant | tail"},
				],
				"default": [{"name": "Dub House", "type": "mix", "params": "122 BPM | minor/dorian"}]
			}
		_:
			return {"default": [{"name": "Audio", "type": "mix", "params": ""}]}


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


# === SOUND DETAIL PANEL (Tab-based) ===

func show_sound_breakdown(layer: String):
	"""Switch to Sound Editor tab and load the selected sound"""
	_current_editor_layer = layer
	_sound_detail_panel.set_pattern_overrides(_get_song_pattern_overrides(_current_song_id))
	
	# Get config and words
	var config = SynthConfigRegistry.get_layer_config(_current_song_id, layer)
	if config.is_empty():
		config = _word_display._layer_params.get(layer, {})
	
	var words = _word_display._layer_words.get(layer, [])
	
	# Update editor tab header
	_editor_sound_name.text = "🎛️ %s" % layer
	
	# Hide hint, show detail panel
	var hint = _sound_editor_tab.get_node_or_null("HintLabel")
	if hint:
		hint.visible = false
	_sound_detail_panel.visible = true
	
	# Load into detail panel with current section context
	_sound_detail_panel.load_sound(_current_song_id, layer, words, config, _current_section_name)
	
	# Switch to Sound Editor tab
	_main_tabs.current_tab = 1
	
	_status_label.text = "🎛️ Editing: %s" % layer


func _on_detail_param_changed(layer: String, param: String, value: float):
	"""Handle param change from detail panel - apply to live params"""
	# Map detail panel param to live_params
	var mapping = {
		"filter.cutoff": "bass_filter_cutoff" if "bass" in layer.to_lower() else "pad_filter_cutoff" if "pad" in layer.to_lower() else "lead_filter_cutoff",
		"filter.resonance": "bass_filter_resonance",
		"osc.detune": "pad_detune",
		"mod.vibrato_depth": "lead_vibrato_depth",
		"fx.reverb_mix": "reverb_mix",
		"fx.delay_mix": "delay_mix",
	}
	
	if mapping.has(param):
		var live_param = mapping[param]
		live_params[live_param] = value
		if _param_sliders.has(live_param):
			_param_sliders[live_param].value = value
		_apply_live_params()
	
	_status_label.text = "⚙️ %s.%s = %.3f" % [layer, param, value]


func _on_detail_word_added(layer: String, word: String):
	"""Handle word added from detail panel"""
	var words = _word_display._layer_words.get(layer, []).duplicate()
	if word not in words:
		words.append(word)
	var params = _word_display._layer_params.get(layer, {})
	_word_display.set_layer_words(layer, words, params)
	
	# Apply word to live params
	_on_word_clicked(layer, word)
	_status_label.text = "🏷️ Added '%s' to %s" % [word, layer]


func _on_detail_word_removed(layer: String, word: String):
	"""Handle word removed from detail panel"""
	var words = _word_display._layer_words.get(layer, []).duplicate()
	words.erase(word)
	var params = _word_display._layer_params.get(layer, {})
	_word_display.set_layer_words(layer, words, params)
	_status_label.text = "🏷️ Removed '%s' from %s" % [word, layer]


func _on_detail_preview(layer: String):
	"""Preview just this layer from detail panel"""
	var params = _word_display._layer_params.get(layer, {})
	_on_layer_preview(layer, params)


func _on_detail_pattern_changed(layer: String, pattern_data: Dictionary):
	"""Handle pattern change from detail panel and persist it."""
	_apply_pattern_override_to_generator(_current_song_id, layer, pattern_data)
	_store_pattern_override(_current_song_id, _current_section_name, layer, pattern_data)
	_sound_detail_panel.set_pattern_overrides(_get_song_pattern_overrides(_current_song_id))
	
	var scope = _current_section_name if not _current_section_name.is_empty() else "global"
	_status_label.text = "Pattern saved for %s (%s)" % [layer, scope]


# === LEGACY IDENTITY PANEL (Read-only breakdown) ===

var _identity_popup: PopupPanel = null
var _identity_panel: SoundIdentityPanel = null

func show_identity_breakdown(layer: String):
	"""Show read-only SoundIdentity breakdown (features + traits)"""
	if _identity_popup == null:
		_identity_popup = PopupPanel.new()
		_identity_popup.size = Vector2(420, 600)
		
		_identity_panel = SoundIdentityPanel.new()
		_identity_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_identity_panel.trait_clicked.connect(_on_identity_trait_clicked)
		_identity_popup.add_child(_identity_panel)
		
		add_child(_identity_popup)
	
	var config = SynthConfigRegistry.get_layer_config(_current_song_id, layer)
	if config.is_empty():
		config = _word_display._layer_params.get(layer, {})
	
	_identity_panel.set_from_params(layer, config)
	_identity_popup.position = get_viewport_rect().size / 2.0 - Vector2(_identity_popup.size) / 2.0
	_identity_popup.popup()


func _on_identity_trait_clicked(trait_name: String):
	"""Handle trait click from identity panel"""
	_status_label.text = "🏷️ Trait: %s" % trait_name


# === SUBSET SELECTOR ===

func _load_subsets():
	"""Load all subsets from the grid_editor/subsets folder"""
	_loaded_subsets.clear()
	_subset_dropdown.clear()
	
	var subsets_path = "res://tools/grid_editor/subsets"
	var dir = DirAccess.open(subsets_path)
	if dir == null:
		print("Could not open subsets folder: ", subsets_path)
		_subset_dropdown.add_item("(no subsets)", 0)
		return
	
	var idx = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var subset = _load_subset_file(subsets_path + "/" + file_name)
			if subset and subset.has("id"):
				_loaded_subsets[subset.id] = subset
				var display_name = subset.get("name", subset.id)
				_subset_dropdown.add_item(display_name, idx)
				_subset_dropdown.set_item_metadata(idx, subset.id)
				idx += 1
				print("Loaded subset: ", subset.id, " - ", display_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	if _loaded_subsets.is_empty():
		_subset_dropdown.add_item("(no subsets found)", 0)
	else:
		# Select first subset by default
		_subset_dropdown.selected = 0
		var first_id = _subset_dropdown.get_item_metadata(0)
		_set_current_subset(first_id)
	
	# Style the popup after items are added
	_style_dropdown_popup(_subset_dropdown)


func _load_subset_file(path: String) -> Dictionary:
	"""Load a single subset JSON file"""
	if not FileAccess.file_exists(path):
		push_error("Subset file not found: ", path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open subset: ", path)
		return {}
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Failed to parse subset: ", path, " - ", json.get_error_message())
		return {}
	
	return json.data


func _on_subset_selected(index: int):
	"""Handle subset dropdown selection"""
	var subset_id = _subset_dropdown.get_item_metadata(index)
	if subset_id and subset_id is String:
		_set_current_subset(subset_id)


func _set_current_subset(subset_id: String):
	"""Set the current active subset"""
	if not _loaded_subsets.has(subset_id):
		return
	
	_current_subset_id = subset_id
	var subset_data = _loaded_subsets[subset_id]
	
	_status_label.text = "📦 Subset: %s" % subset_data.get("name", subset_id)
	print("Selected subset: ", subset_id)
	
	# Emit signal for other components to react
	subset_changed.emit(subset_id, subset_data)


func get_current_subset() -> Dictionary:
	"""Get the currently selected subset data"""
	return _loaded_subsets.get(_current_subset_id, {})


func get_current_subset_id() -> String:
	"""Get the currently selected subset ID"""
	return _current_subset_id


func get_subset(subset_id: String) -> Dictionary:
	"""Get a specific subset by ID"""
	return _loaded_subsets.get(subset_id, {})
