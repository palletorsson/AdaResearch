# SoundDetailPanel.gd
# Full sound editing panel with tabs: Sound (params), Pattern (sequencer), FX
# Click a sound in catalog to open

extends PanelContainer
class_name SoundDetailPanel

const WordSynthBridge = preload("res://commons/audio/catalog/WordSynthBridge.gd")
const SynthConfigRegistry = preload("res://commons/audio/catalog/SynthConfigRegistry.gd")
const SoundIdentity = preload("res://commons/audio/catalog/SoundIdentity.gd")
const SoundDescriptions = preload("res://commons/audio/catalog/SoundDescriptions.gd")

# Unified pattern editors (new architecture)
const DrumPatternEditor = preload("res://commons/audio/catalog/ui/DrumPatternEditor.gd")
const BassPatternEditor = preload("res://commons/audio/catalog/ui/BassPatternEditor.gd")
const ChordPatternEditor = preload("res://commons/audio/catalog/ui/ChordPatternEditor.gd")
const ArpPatternEditor = preload("res://commons/audio/catalog/ui/ArpPatternEditor.gd")
const LeadPatternEditor = preload("res://commons/audio/catalog/ui/LeadPatternEditor.gd")

# Legacy editors (deprecated - kept for backwards compatibility)
const DrumSequencer = preload("res://commons/audio/catalog/ui/DrumSequencer.gd")
const BassTimeline = preload("res://commons/audio/catalog/ui/BassTimeline.gd")
const ChordTimeline = preload("res://commons/audio/catalog/ui/ChordTimeline.gd")
const ArpeggioEditor = preload("res://commons/audio/catalog/ui/ArpeggioEditor.gd")

# Use unified editors by default
var _use_unified_editors: bool = true

signal param_changed(layer: String, param: String, value: float)
signal word_added(layer: String, word: String)
signal word_removed(layer: String, word: String)
signal preview_requested(layer: String)
signal suggestion_applied(layer: String, changes: Dictionary)
signal pattern_changed(layer: String, pattern_data: Dictionary)
signal close_requested()

var _word_bridge: WordSynthBridge
var _current_layer: String = ""
var _current_song: String = ""
var _current_section: String = ""
var _current_params: Dictionary = {}
var _current_words: Array = []
var _original_params: Dictionary = {}
var _current_pattern: Dictionary = {}
var _pattern_overrides_by_section: Dictionary = {}
var _last_pattern_preview_ms: int = -100000
var _pending_preview_context: Dictionary = {}

# UI Components
var _header_label: Label
var _type_label: Label
var _synth_description: Label
var _preview_btn: Button
var _tab_container: TabContainer

# Sound Tab
var _sound_tab: Control
var _sliders_container: VBoxContainer
var _words_container: HFlowContainer
var _suggestions_container: VBoxContainer
var _evaluation_container: VBoxContainer

# Pattern Tab
var _pattern_tab: Control
var _pattern_editor: Control  # Will be DrumSequencer, BassTimeline, ChordTimeline, or ArpeggioEditor
var _pattern_type_label: Label
var _pattern_toolbar: HBoxContainer
var _pattern_preset_dropdown: OptionButton
var _pattern_apply_preset_btn: Button
var _active_pattern_family: String = "generic"

# FX Tab  
var _fx_tab: Control
var _fx_sliders: Dictionary = {}

# Slider references
var _param_sliders: Dictionary = {}  # param_name -> {slider, value_label, min, max}

# Param definitions with proper ranges by layer type
const PARAM_DEFINITIONS = {
	"bass": {
		"osc.voices": {"min": 1, "max": 4, "default": 1, "label": "Voices"},
		"osc.detune": {"min": 0.0, "max": 0.1, "default": 0.02, "label": "Detune"},
		"osc.drift": {"min": 0.0, "max": 0.2, "default": 0.0, "label": "Drift"},
		"filter.cutoff": {"min": 50, "max": 2000, "default": 400, "label": "Filter Cutoff"},
		"filter.resonance": {"min": 0.0, "max": 1.0, "default": 0.3, "label": "Resonance"},
		"env.attack": {"min": 0.001, "max": 0.5, "default": 0.01, "label": "Attack"},
		"env.decay": {"min": 0.01, "max": 1.0, "default": 0.2, "label": "Decay"},
		"env.sustain": {"min": 0.0, "max": 1.0, "default": 0.8, "label": "Sustain"},
		"env.release": {"min": 0.01, "max": 2.0, "default": 0.3, "label": "Release"},
		"fx.saturation": {"min": 0.0, "max": 1.0, "default": 0.0, "label": "Saturation"},
		"fx.sub_level": {"min": 0.0, "max": 1.0, "default": 0.5, "label": "Sub Level"},
	},
	"pad": {
		"osc.voices": {"min": 1, "max": 8, "default": 5, "label": "Voices"},
		"osc.detune": {"min": 0.0, "max": 0.15, "default": 0.05, "label": "Detune"},
		"osc.drift": {"min": 0.0, "max": 0.3, "default": 0.02, "label": "Drift"},
		"filter.cutoff": {"min": 200, "max": 8000, "default": 2000, "label": "Filter Cutoff"},
		"filter.resonance": {"min": 0.0, "max": 0.8, "default": 0.2, "label": "Resonance"},
		"env.attack": {"min": 0.1, "max": 5.0, "default": 1.0, "label": "Attack"},
		"env.decay": {"min": 0.1, "max": 3.0, "default": 0.5, "label": "Decay"},
		"env.sustain": {"min": 0.2, "max": 1.0, "default": 0.7, "label": "Sustain"},
		"env.release": {"min": 0.1, "max": 5.0, "default": 1.5, "label": "Release"},
		"fx.chorus_depth": {"min": 0.0, "max": 1.0, "default": 0.4, "label": "Chorus"},
		"fx.reverb_mix": {"min": 0.0, "max": 1.0, "default": 0.3, "label": "Reverb"},
		"mod.lfo_rate": {"min": 0.01, "max": 2.0, "default": 0.3, "label": "LFO Rate"},
		"mod.lfo_depth": {"min": 0.0, "max": 0.5, "default": 0.1, "label": "LFO Depth"},
	},
	"lead": {
		"osc.voices": {"min": 1, "max": 8, "default": 3, "label": "Voices"},
		"osc.detune": {"min": 0.0, "max": 0.08, "default": 0.015, "label": "Detune"},
		"osc.drift": {"min": 0.0, "max": 0.15, "default": 0.01, "label": "Drift"},
		"filter.cutoff": {"min": 500, "max": 12000, "default": 3000, "label": "Filter Cutoff"},
		"filter.resonance": {"min": 0.0, "max": 0.9, "default": 0.3, "label": "Resonance"},
		"env.attack": {"min": 0.001, "max": 1.0, "default": 0.02, "label": "Attack"},
		"env.decay": {"min": 0.05, "max": 1.5, "default": 0.3, "label": "Decay"},
		"env.sustain": {"min": 0.0, "max": 1.0, "default": 0.6, "label": "Sustain"},
		"env.release": {"min": 0.05, "max": 2.0, "default": 0.4, "label": "Release"},
		"mod.vibrato_rate": {"min": 3.0, "max": 8.0, "default": 5.0, "label": "Vibrato Rate"},
		"mod.vibrato_depth": {"min": 0.0, "max": 0.02, "default": 0.005, "label": "Vibrato Depth"},
		"fx.delay_mix": {"min": 0.0, "max": 0.6, "default": 0.2, "label": "Delay"},
	},
	"drums": {
		"kick.attack": {"min": 0.001, "max": 0.05, "default": 0.01, "label": "Kick Attack"},
		"kick.pitch": {"min": 40, "max": 80, "default": 55, "label": "Kick Pitch"},
		"kick.decay": {"min": 0.1, "max": 0.8, "default": 0.35, "label": "Kick Decay"},
		"snare.tone": {"min": 0.0, "max": 1.0, "default": 0.5, "label": "Snare Tone"},
		"snare.noise": {"min": 0.0, "max": 1.0, "default": 0.6, "label": "Snare Noise"},
		"hat.decay": {"min": 0.02, "max": 0.3, "default": 0.08, "label": "HiHat Decay"},
		"hat.filter": {"min": 4000, "max": 16000, "default": 8000, "label": "HiHat Tone"},
		"fx.compression": {"min": 0.0, "max": 1.0, "default": 0.3, "label": "Compression"},
		"fx.saturation": {"min": 0.0, "max": 0.8, "default": 0.1, "label": "Saturation"},
	},
	"arp": {
		"osc.voices": {"min": 1, "max": 4, "default": 2, "label": "Voices"},
		"osc.detune": {"min": 0.0, "max": 0.06, "default": 0.01, "label": "Detune"},
		"filter.cutoff": {"min": 400, "max": 8000, "default": 2500, "label": "Filter"},
		"filter.env_amount": {"min": 0.0, "max": 1.0, "default": 0.3, "label": "Filter Env"},
		"env.attack": {"min": 0.001, "max": 0.1, "default": 0.01, "label": "Attack"},
		"env.decay": {"min": 0.05, "max": 0.8, "default": 0.2, "label": "Decay"},
		"env.sustain": {"min": 0.0, "max": 0.5, "default": 0.0, "label": "Sustain"},
		"fx.chorus_mix": {"min": 0.0, "max": 0.6, "default": 0.2, "label": "Chorus"},
		"fx.delay_mix": {"min": 0.0, "max": 0.5, "default": 0.25, "label": "Delay"},
	},
}

# Word categories
const WORD_CATEGORIES = {
	"timbral": Color(0.9, 0.6, 0.3),
	"envelope": Color(0.3, 0.7, 0.9),
	"spatial": Color(0.6, 0.9, 0.5),
	"movement": Color(0.9, 0.4, 0.7),
}

# Sound type detection for pattern editors
const DRUM_SOUNDS = ["kick", "snare", "clap", "hihat", "rimshot", "shaker", 
					 "tambourine", "perc", "cr5000_kick", "cr5000_snare", 
					 "cr5000_hihat", "fingersnap"]
const BASS_SOUNDS = ["bass", "sub", "hoover"]
const LEAD_SOUNDS = ["lead", "melody", "hook", "solo", "pluck"]
const CHORD_SOUNDS = ["pad", "keys", "rhodes", "strings", "piano", "organ", "stab"]
const ARP_SOUNDS = ["arp", "sequence", "sequencer", "jupiter_arp"]
const GLOBAL_SECTION_KEY = "__global__"
const DEFAULT_PATTERN_STEPS = 16
const PATTERN_PREVIEW_COOLDOWN_MS = 120
const PATTERN_PRESET_OPTIONS = {
	"drums": ["Four on Floor", "Broken Beat", "Half Time", "Sparse"],
	"bass": ["Root Pulse", "Offbeat Bounce", "Syncopated", "Sparse Sub"],
	"lead": ["Hook Phrase", "Staccato Run", "Call and Response", "Long Tone"],
	"chord": ["Pop 1-5-6-4", "Minor Flow", "Slow Pads", "Sparse Stabs"],
	"arp": ["Up 1/8", "Down 1/16", "Up-Down Trance", "Random Texture"],
}


func _ready():
	_word_bridge = WordSynthBridge.new()
	_setup_ui()


func _setup_ui():
	# Panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08)
	style.set_corner_radius_all(8)
	style.border_color = Color(0.2, 0.4, 0.6)
	style.set_border_width_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)
	
	# === HEADER ===
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	main_vbox.add_child(header)
	
	_header_label = Label.new()
	_header_label.text = "ðŸŽ›ï¸ SOUND EDITOR"
	_header_label.add_theme_font_size_override("font_size", 22)
	_header_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_header_label)
	
	_preview_btn = Button.new()
	_preview_btn.text = "â–¶ Preview"
	_preview_btn.pressed.connect(_on_preview_pressed)
	_style_button(_preview_btn, Color(0.2, 0.5, 0.3))
	header.add_child(_preview_btn)
	
	# Type label
	_type_label = Label.new()
	_type_label.text = "Select a sound to edit"
	_type_label.add_theme_font_size_override("font_size", 13)
	_type_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	main_vbox.add_child(_type_label)
	
	# Synthesis description (one-sentence explanation)
	_synth_description = Label.new()
	_synth_description.text = ""
	_synth_description.add_theme_font_size_override("font_size", 12)
	_synth_description.add_theme_color_override("font_color", Color(0.6, 0.7, 0.65))
	_synth_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_synth_description.custom_minimum_size.y = 30
	main_vbox.add_child(_synth_description)
	
	# === TAB CONTAINER ===
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_tab_container(_tab_container)
	main_vbox.add_child(_tab_container)
	
	# Create tabs
	_setup_sound_tab()
	_setup_pattern_tab()
	_setup_fx_tab()


func _style_tab_container(tabs: TabContainer):
	# Modern tab styling
	tabs.add_theme_constant_override("side_margin", 0)
	
	var tab_style = StyleBoxFlat.new()
	tab_style.bg_color = Color(0.12, 0.12, 0.15)
	tab_style.set_corner_radius_all(4)
	tab_style.corner_radius_bottom_left = 0
	tab_style.corner_radius_bottom_right = 0
	
	var tab_selected = tab_style.duplicate()
	tab_selected.bg_color = Color(0.18, 0.18, 0.22)
	tab_selected.border_color = Color(0.4, 0.6, 0.8)
	tab_selected.border_width_top = 2


func _setup_sound_tab():
	_sound_tab = VBoxContainer.new()
	_sound_tab.name = "ðŸŽ›ï¸ Sound"
	_sound_tab.add_theme_constant_override("separation", 12)
	_tab_container.add_child(_sound_tab)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sound_tab.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	
	# === WORDS SECTION ===
	content.add_child(_create_section_header("ðŸ·ï¸ WORDS", Color(0.9, 0.7, 0.4)))
	
	_words_container = HFlowContainer.new()
	_words_container.add_theme_constant_override("h_separation", 8)
	_words_container.add_theme_constant_override("v_separation", 6)
	content.add_child(_words_container)
	
	# Add word button
	var add_word_btn = Button.new()
	add_word_btn.text = "+ Add Word"
	add_word_btn.pressed.connect(_on_add_word_pressed)
	_style_button(add_word_btn, Color(0.3, 0.4, 0.5))
	content.add_child(add_word_btn)
	
	# === SLIDERS SECTION ===
	content.add_child(_create_section_header("âš™ï¸ PARAMETERS", Color(0.4, 0.7, 0.9)))
	
	_sliders_container = VBoxContainer.new()
	_sliders_container.add_theme_constant_override("separation", 8)
	content.add_child(_sliders_container)
	
	# === SUGGESTIONS SECTION ===
	content.add_child(_create_section_header("ðŸ’¡ SUGGESTIONS", Color(0.9, 0.8, 0.4)))
	
	_suggestions_container = VBoxContainer.new()
	_suggestions_container.add_theme_constant_override("separation", 4)
	content.add_child(_suggestions_container)
	
	# === EVALUATION SECTION ===
	content.add_child(_create_section_header("ðŸ“Š EVALUATION", Color(0.6, 0.9, 0.7)))
	
	_evaluation_container = VBoxContainer.new()
	_evaluation_container.add_theme_constant_override("separation", 4)
	content.add_child(_evaluation_container)
	
	# === ACTION BUTTONS ===
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	content.add_child(action_row)
	
	var reset_btn = Button.new()
	reset_btn.text = "â†º Reset"
	reset_btn.pressed.connect(_on_reset_pressed)
	_style_button(reset_btn, Color(0.4, 0.3, 0.3))
	action_row.add_child(reset_btn)
	
	var random_btn = Button.new()
	random_btn.text = "ðŸŽ² Randomize"
	random_btn.pressed.connect(_on_randomize_pressed)
	_style_button(random_btn, Color(0.5, 0.3, 0.5))
	action_row.add_child(random_btn)
	
	var copy_btn = Button.new()
	copy_btn.text = "ðŸ“‹ Copy Config"
	copy_btn.pressed.connect(_on_copy_config_pressed)
	_style_button(copy_btn, Color(0.3, 0.4, 0.4))
	action_row.add_child(copy_btn)


func _setup_pattern_tab():
	_pattern_tab = VBoxContainer.new()
	_pattern_tab.name = "ðŸŽµ Pattern"
	_pattern_tab.add_theme_constant_override("separation", 8)
	_tab_container.add_child(_pattern_tab)
	
	# Pattern type label
	_pattern_type_label = Label.new()
	_pattern_type_label.text = "Select a sound to edit its pattern"
	_pattern_type_label.add_theme_font_size_override("font_size", 14)
	_pattern_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_pattern_tab.add_child(_pattern_type_label)

	_pattern_toolbar = HBoxContainer.new()
	_pattern_toolbar.add_theme_constant_override("separation", 8)
	_pattern_tab.add_child(_pattern_toolbar)

	var preset_label = Label.new()
	preset_label.text = "Preset:"
	preset_label.add_theme_font_size_override("font_size", 12)
	preset_label.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
	_pattern_toolbar.add_child(preset_label)

	_pattern_preset_dropdown = OptionButton.new()
	_pattern_preset_dropdown.custom_minimum_size.x = 180
	_pattern_preset_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pattern_toolbar.add_child(_pattern_preset_dropdown)

	_pattern_apply_preset_btn = Button.new()
	_pattern_apply_preset_btn.text = "Apply Preset"
	_pattern_apply_preset_btn.pressed.connect(Callable(self, "_on_pattern_apply_preset_pressed"))
	_style_button(_pattern_apply_preset_btn, Color(0.35, 0.4, 0.56))
	_pattern_toolbar.add_child(_pattern_apply_preset_btn)
	call_deferred("_refresh_pattern_preset_options", "")
	
	# Pattern editor placeholder (will be replaced with appropriate editor)
	var placeholder = Label.new()
	placeholder.name = "PatternPlaceholder"
	placeholder.text = "Pattern editor will appear here based on sound type"
	placeholder.add_theme_font_size_override("font_size", 12)
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pattern_tab.add_child(placeholder)


func _setup_fx_tab():
	_fx_tab = VBoxContainer.new()
	_fx_tab.name = "âœ¨ FX"
	_fx_tab.add_theme_constant_override("separation", 12)
	_tab_container.add_child(_fx_tab)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_fx_tab.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	
	# FX sections
	content.add_child(_create_section_header("ðŸŒ€ REVERB", Color(0.5, 0.7, 0.9)))
	content.add_child(_create_fx_slider("reverb_mix", "Mix", 0.0, 1.0, 0.3))
	content.add_child(_create_fx_slider("reverb_size", "Size", 0.0, 1.0, 0.5))
	content.add_child(_create_fx_slider("reverb_damping", "Damping", 0.0, 1.0, 0.5))
	
	content.add_child(_create_section_header("â±ï¸ DELAY", Color(0.7, 0.6, 0.5)))
	content.add_child(_create_fx_slider("delay_mix", "Mix", 0.0, 1.0, 0.2))
	content.add_child(_create_fx_slider("delay_time", "Time", 0.05, 1.0, 0.375))
	content.add_child(_create_fx_slider("delay_feedback", "Feedback", 0.0, 0.9, 0.3))
	
	content.add_child(_create_section_header("ðŸ“¢ DISTORTION", Color(0.9, 0.5, 0.4)))
	content.add_child(_create_fx_slider("distortion_drive", "Drive", 0.0, 1.0, 0.0))
	content.add_child(_create_fx_slider("distortion_mix", "Mix", 0.0, 1.0, 0.5))
	
	content.add_child(_create_section_header("ðŸŽšï¸ FILTER", Color(0.6, 0.8, 0.5)))
	content.add_child(_create_fx_slider("filter_cutoff", "Cutoff", 20, 20000, 8000))
	content.add_child(_create_fx_slider("filter_resonance", "Resonance", 0.0, 1.0, 0.1))


func _create_fx_slider(param_name: String, label_text: String, min_val: float, max_val: float, default_val: float) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	label.custom_minimum_size.x = 80
	row.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default_val
	slider.step = (max_val - min_val) / 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_fx_slider_changed.bind(param_name))
	row.add_child(slider)
	
	var val_label = Label.new()
	val_label.text = _format_value(default_val, min_val, max_val)
	val_label.add_theme_font_size_override("font_size", 11)
	val_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	val_label.custom_minimum_size.x = 50
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_label)
	
	_fx_sliders[param_name] = {
		"slider": slider,
		"label": val_label,
		"min": min_val,
		"max": max_val
	}
	
	slider.value_changed.connect(func(v): val_label.text = _format_value(v, min_val, max_val))
	
	return row


func _on_fx_slider_changed(value: float, param_name: String):
	# Emit FX param change
	param_changed.emit(_current_layer, "fx." + param_name, value)


func _create_section_header(title: String, color: Color) -> Label:
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	return label


func _style_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)


# === PUBLIC API ===

func load_sound(song_id: String, layer: String, words: Array = [], params: Dictionary = {}, section: String = ""):
	"""Load a sound for editing"""
	_current_song = song_id
	_current_layer = layer
	_current_section = section
	_current_words = words.duplicate()
	
	# Get params from registry or use provided
	var config = SynthConfigRegistry.get_layer_config(song_id, layer)
	if config.is_empty():
		config = params
	_current_params = config.duplicate(true)
	_original_params = config.duplicate(true)
	
	# Update header
	_header_label.text = "ðŸŽ›ï¸ %s" % layer
	_refresh_context_label()
	
	# Synthesis description
	_synth_description.text = "âš¡ " + SoundDescriptions.get_description(layer, song_id)
	
	# Rebuild UI
	_rebuild_words()
	_rebuild_sliders()
	_rebuild_suggestions()
	_rebuild_evaluation()
	
	# Setup pattern editor
	_setup_pattern_editor_for_layer(layer)
	
	# Load pattern data if available
	_load_pattern_for_layer(song_id, layer)


func set_section(section_name: String):
	"""Update section context without changing selected layer."""
	_current_section = section_name
	_refresh_context_label()
	if not _current_song.is_empty() and not _current_layer.is_empty():
		_load_pattern_for_layer(_current_song, _current_layer)


func set_pattern_overrides(overrides_by_section: Dictionary):
	"""Set section-aware pattern overrides: section -> layer -> pattern data."""
	_pattern_overrides_by_section = overrides_by_section.duplicate(true)
	if not _current_song.is_empty() and not _current_layer.is_empty():
		_load_pattern_for_layer(_current_song, _current_layer)


func _refresh_context_label():
	var synth_type = SoundDescriptions.get_short_type(_current_layer)
	_type_label.text = "Song: %s | Type: %s" % [_current_song, synth_type]
	if not _current_section.is_empty():
		_type_label.text += " | Section: %s" % _current_section


func _setup_pattern_editor_for_layer(layer: String):
	"""Create the appropriate pattern editor based on layer type"""
	# Remove existing pattern editor
	if _pattern_editor != null:
		_pattern_editor.queue_free()
		_pattern_editor = null
	
	# Remove placeholder if exists
	var placeholder = _pattern_tab.get_node_or_null("PatternPlaceholder")
	if placeholder:
		placeholder.queue_free()
	
	var layer_lower = layer.to_lower()

	_active_pattern_family = _get_pattern_layer_family(layer_lower)
	_refresh_pattern_preset_options(layer)
	
	# Determine editor type and create appropriate editor
	if _active_pattern_family == "drums":
		_pattern_type_label.text = "Drum Sequencer: %s" % layer
		if _use_unified_editors:
			_pattern_editor = DrumPatternEditor.new()
			_pattern_editor.pattern_changed.connect(_on_unified_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_pattern_preview)
		else:
			_pattern_editor = DrumSequencer.new()
			_pattern_editor.pattern_changed.connect(_on_drum_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_pattern_preview)
	elif _active_pattern_family == "bass":
		_pattern_type_label.text = "Bass Timeline: %s" % layer
		if _use_unified_editors:
			_pattern_editor = BassPatternEditor.new()
			_pattern_editor.pattern_changed.connect(_on_unified_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_bass_preview)
		else:
			_pattern_editor = BassTimeline.new()
			_pattern_editor.pattern_changed.connect(_on_bass_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_bass_preview)
	elif _active_pattern_family == "lead":
		_pattern_type_label.text = "Lead Melody Editor: %s" % layer
		if _use_unified_editors:
			_pattern_editor = LeadPatternEditor.new()
			_pattern_editor.pattern_changed.connect(_on_unified_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_bass_preview)
		else:
			_pattern_editor = BassTimeline.new()
			_pattern_editor.pattern_changed.connect(_on_bass_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_bass_preview)
	elif _active_pattern_family == "chord":
		_pattern_type_label.text = "Pad/Chord Progression: %s" % layer
		if _use_unified_editors:
			_pattern_editor = ChordPatternEditor.new()
			_pattern_editor.pattern_changed.connect(_on_unified_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_chord_preview)
		else:
			_pattern_editor = ChordTimeline.new()
			_pattern_editor.pattern_changed.connect(_on_chord_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_chord_preview)
	elif _active_pattern_family == "arp":
		_pattern_type_label.text = "Arpeggio Motion: %s" % layer
		if _use_unified_editors:
			_pattern_editor = ArpPatternEditor.new()
			_pattern_editor.pattern_changed.connect(_on_unified_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_arp_preview)
		else:
			_pattern_editor = ArpeggioEditor.new()
			_pattern_editor.pattern_changed.connect(_on_arp_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_arp_preview)
	else:
		_pattern_type_label.text = "Pattern Editor: %s" % layer
		if _use_unified_editors:
			_pattern_editor = DrumPatternEditor.new()
			_pattern_editor.pattern_changed.connect(_on_unified_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_pattern_preview)
		else:
			_pattern_editor = DrumSequencer.new()
			_pattern_editor.pattern_changed.connect(_on_drum_pattern_changed)
			_pattern_editor.preview_requested.connect(_on_pattern_preview)
	
	if _pattern_editor:
		_pattern_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_pattern_tab.add_child(_pattern_editor)


func _get_pattern_layer_family(layer: String) -> String:
	if _is_drum_layer(layer):
		return "drums"
	if _is_bass_layer(layer):
		return "bass"
	if _is_lead_layer(layer):
		return "lead"
	if _is_chord_layer(layer):
		return "chord"
	if _is_arp_layer(layer):
		return "arp"
	return "generic"


func _is_drum_layer(layer: String) -> bool:
	for drum in DRUM_SOUNDS:
		if drum in layer:
			return true
	return false


func _is_bass_layer(layer: String) -> bool:
	for bass in BASS_SOUNDS:
		if bass in layer:
			return true
	return false


func _is_chord_layer(layer: String) -> bool:
	for chord in CHORD_SOUNDS:
		if chord in layer:
			return true
	return false


func _is_lead_layer(layer: String) -> bool:
	for lead in LEAD_SOUNDS:
		if lead in layer:
			return true
	return false


func _is_arp_layer(layer: String) -> bool:
	for arp in ARP_SOUNDS:
		if arp in layer:
			return true
	return false


func _load_pattern_for_layer(song_id: String, layer: String):
	"""Load pattern data from SoundbankGenerator.PATTERNS"""
	# Try to access SoundbankGenerator patterns
	var patterns = {}
	if ClassDB.class_exists("SoundbankGenerator"):
		var sg = ClassDB.instantiate("SoundbankGenerator")
		if sg and sg.has_method("get_patterns"):
			patterns = sg.get_patterns(song_id)
	
	# Fallback: try loading from the constant
	if patterns.is_empty():
		# Load patterns directly
		var SoundbankGenerator = load("res://commons/audio/generators/SoundbankGenerator.gd")
		if SoundbankGenerator:
			var pattern_song_id = _resolve_pattern_song_id(song_id)
			patterns = SoundbankGenerator.PATTERNS.get(pattern_song_id, {})

	_current_pattern = patterns
	var layer_override = _get_layer_pattern_override(layer)

	# Load into the appropriate editor
	# Handle unified editors
	if _use_unified_editors:
		if _pattern_editor is DrumPatternEditor:
			if not layer_override.is_empty():
				var override_drum_patterns = {}
				if layer_override.has("pattern") and layer_override["pattern"] is Array:
					override_drum_patterns[layer] = layer_override["pattern"]
				else:
					for key in layer_override.keys():
						if layer_override[key] is Array:
							override_drum_patterns[key] = layer_override[key]
				if not override_drum_patterns.is_empty():
					_pattern_editor.load_patterns(override_drum_patterns)
					return
			
			var drum_patterns = _extract_drum_patterns(patterns, layer)
			if drum_patterns.is_empty():
				drum_patterns = _build_drum_preset_data("Four on Floor")
			_pattern_editor.load_patterns(drum_patterns)
		
		elif _pattern_editor is LeadPatternEditor:
			if not layer_override.is_empty() and layer_override.has("pattern"):
				_pattern_editor.load_pattern(
					layer_override.get("pattern", []),
					layer_override.get("notes", []),
					layer_override.get("glides", [])
				)
				return
			var lead_pattern = _find_pattern_array(patterns, layer, LEAD_SOUNDS)
			var lead_data = _build_melodic_preset_data("lead", "Hook Phrase")
			if not lead_pattern.is_empty():
				lead_data["pattern"] = lead_pattern
			_pattern_editor.load_pattern(
				lead_data.get("pattern", []),
				lead_data.get("notes", []),
				lead_data.get("glides", [])
			)
		
		elif _pattern_editor is BassPatternEditor:
			if not layer_override.is_empty() and layer_override.has("pattern"):
				_pattern_editor.load_pattern(
					layer_override.get("pattern", []),
					layer_override.get("notes", []),
					layer_override.get("glides", [])
				)
				return
			
			var bass_cfg = {}
			var SoundbankGenerator = load("res://commons/audio/generators/SoundbankGenerator.gd")
			if SoundbankGenerator:
				var pattern_song_id = _resolve_pattern_song_id(song_id)
				bass_cfg = SoundbankGenerator.BASS_PATTERNS.get(pattern_song_id, {})
			
			var bass_data = _build_melodic_preset_data("bass", "Root Pulse")
			var fallback_bass_pattern = _find_pattern_array(patterns, layer, BASS_SOUNDS)
			if bass_cfg.has("pattern"):
				bass_data["pattern"] = bass_cfg["pattern"]
				bass_data["notes"] = bass_cfg.get("notes", [])
				bass_data["glides"] = bass_cfg.get("glides", [])
			elif not fallback_bass_pattern.is_empty():
				bass_data["pattern"] = fallback_bass_pattern
			_pattern_editor.load_pattern(
				bass_data.get("pattern", []),
				bass_data.get("notes", []),
				bass_data.get("glides", [])
			)
		
		elif _pattern_editor is ChordPatternEditor:
			if not layer_override.is_empty() and layer_override.has("pattern"):
				var override_pattern = layer_override.get("pattern", [])
				var override_chords = layer_override.get("chords", [])
				if override_chords.is_empty():
					override_chords = _build_chord_steps_from_pattern(override_pattern)
				_pattern_editor.load_pattern(
					override_pattern,
					override_chords,
					layer_override.get("voicings", []),
					layer_override.get("sustains", [])
				)
				return
			var chord_pattern = _find_pattern_array(patterns, layer, CHORD_SOUNDS)
			if chord_pattern.is_empty():
				var default_chord = _build_chord_preset_data("Pop 1-5-6-4")
				_pattern_editor.load_pattern(
					default_chord.get("pattern", []),
					default_chord.get("chords", []),
					default_chord.get("voicings", []),
					default_chord.get("sustains", [])
				)
			else:
				var generated_chords = _build_chord_steps_from_pattern(chord_pattern)
				var generated_voicings = _build_constant_int_steps(0)
				var generated_sustains = _build_false_steps()
				_pattern_editor.load_pattern(chord_pattern, generated_chords, generated_voicings, generated_sustains)
		
		elif _pattern_editor is ArpPatternEditor:
			if not layer_override.is_empty():
				_pattern_editor.load_settings(layer_override)
				return
			var settings = _build_arp_preset_data("Up 1/8")
			_pattern_editor.load_settings(settings)
		return
	
	# Legacy editors (backwards compatibility)
	if _pattern_editor is DrumSequencer:
		if not layer_override.is_empty():
			var override_drum_patterns = {}
			if layer_override.has("pattern") and layer_override["pattern"] is Array:
				override_drum_patterns[layer] = layer_override["pattern"]
			else:
				for key in layer_override.keys():
					if layer_override[key] is Array:
						override_drum_patterns[key] = layer_override[key]
			if not override_drum_patterns.is_empty():
				_pattern_editor.load_patterns(override_drum_patterns)
				return
		
		var drum_patterns = _extract_drum_patterns(patterns, layer)
		if drum_patterns.is_empty():
			drum_patterns = _build_drum_preset_data("Four on Floor")
		_pattern_editor.load_patterns(drum_patterns)
	
	elif _pattern_editor is BassTimeline:
		if not layer_override.is_empty() and layer_override.has("pattern"):
			_pattern_editor.load_pattern(layer_override.get("pattern", []))
			return
		
		# Load bass pattern
		var bass_cfg = {}
		var SoundbankGenerator = load("res://commons/audio/generators/SoundbankGenerator.gd")
		if SoundbankGenerator:
			var pattern_song_id = _resolve_pattern_song_id(song_id)
			bass_cfg = SoundbankGenerator.BASS_PATTERNS.get(pattern_song_id, {})
		
		if bass_cfg.has("pattern"):
			_pattern_editor.load_pattern(bass_cfg["pattern"])
		else:
			_pattern_editor.load_pattern(_build_melodic_preset_data("bass", "Root Pulse").get("pattern", []))
	
	elif _pattern_editor is ChordTimeline:
		if not layer_override.is_empty() and layer_override.has("pattern"):
			_pattern_editor.load_pattern(layer_override.get("pattern", []))
			return
		
		var chord_pattern = _find_pattern_array(patterns, layer, CHORD_SOUNDS)
		if chord_pattern.is_empty():
			_pattern_editor.load_pattern(_build_chord_preset_data("Pop 1-5-6-4").get("pattern", []))
		else:
			_pattern_editor.load_pattern(chord_pattern)

	elif _pattern_editor is ArpeggioEditor:
		if not layer_override.is_empty():
			_pattern_editor.load_settings(layer_override)
			return
		
		# Load arp settings
		var settings = {
			"pattern": "up",
			"rate": "1/8",
			"octave_range": 1,
			"gate_length": 0.8,
		}
		_pattern_editor.load_settings(settings)


func _refresh_pattern_preset_options(layer: String):
	if _pattern_preset_dropdown == null:
		return
	
	var family = _active_pattern_family
	if not layer.is_empty():
		family = _get_pattern_layer_family(layer.to_lower())
	_active_pattern_family = family
	
	_pattern_preset_dropdown.clear()
	var presets: Array = _get_pattern_presets_for_family(family)
	if presets.is_empty():
		_pattern_preset_dropdown.add_item("No presets")
		_pattern_preset_dropdown.disabled = true
		if _pattern_apply_preset_btn:
			_pattern_apply_preset_btn.disabled = true
		return
	
	_pattern_preset_dropdown.disabled = false
	for preset_name in presets:
		_pattern_preset_dropdown.add_item(str(preset_name))
	_pattern_preset_dropdown.selected = 0
	if _pattern_apply_preset_btn:
		_pattern_apply_preset_btn.disabled = false


func _get_pattern_presets_for_family(family: String) -> Array:
	var raw_presets: Variant = PATTERN_PRESET_OPTIONS.get(family, [])
	if raw_presets is Array:
		return raw_presets
	return []


func _on_pattern_apply_preset_pressed():
	if _pattern_editor == null or _pattern_preset_dropdown == null:
		return
	var item_count: int = _pattern_preset_dropdown.get_item_count()
	if _pattern_preset_dropdown.disabled or item_count <= 0:
		return
	
	var selected_idx: int = _pattern_preset_dropdown.selected
	if selected_idx < 0 or selected_idx >= item_count:
		return
	
	var preset_name: String = _pattern_preset_dropdown.get_item_text(selected_idx)
	if preset_name == "No presets":
		return
	
	_apply_pattern_preset_to_editor(_active_pattern_family, preset_name)
	_emit_current_pattern_from_editor()


func _apply_pattern_preset_to_editor(family: String, preset_name: String):
	if family == "drums":
		var drum_data = _build_drum_preset_data(preset_name)
		if _pattern_editor is DrumPatternEditor or _pattern_editor is DrumSequencer:
			_pattern_editor.load_patterns(drum_data)
		return
	
	if family == "bass" or family == "lead":
		var melodic_data = _build_melodic_preset_data(family, preset_name)
		if _pattern_editor is BassPatternEditor or _pattern_editor is LeadPatternEditor:
			_pattern_editor.load_pattern(
				melodic_data.get("pattern", []),
				melodic_data.get("notes", []),
				melodic_data.get("glides", [])
			)
		elif _pattern_editor is BassTimeline:
			_pattern_editor.load_pattern(melodic_data.get("pattern", []))
		return
	
	if family == "chord":
		var chord_data = _build_chord_preset_data(preset_name)
		if _pattern_editor is ChordPatternEditor:
			_pattern_editor.load_pattern(
				chord_data.get("pattern", []),
				chord_data.get("chords", []),
				chord_data.get("voicings", []),
				chord_data.get("sustains", [])
			)
		elif _pattern_editor is ChordTimeline:
			_pattern_editor.load_pattern(chord_data.get("pattern", []))
		return
	
	if family == "arp":
		var arp_data = _build_arp_preset_data(preset_name)
		if _pattern_editor is ArpPatternEditor:
			_pattern_editor.load_settings(arp_data)
		elif _pattern_editor is ArpeggioEditor:
			_pattern_editor.load_settings({
				"pattern": arp_data.get("direction", "up"),
				"rate": arp_data.get("rate", "1/8"),
				"octave_range": arp_data.get("octave_range", 1),
				"gate_length": arp_data.get("gate_length", 0.8),
			})


func _emit_current_pattern_from_editor():
	if _pattern_editor and _pattern_editor.has_method("get_pattern_data"):
		var raw_data: Variant = _pattern_editor.get_pattern_data()
		if raw_data is Dictionary:
			var pattern_data: Dictionary = raw_data
			_current_pattern = pattern_data
			pattern_changed.emit(_current_layer, pattern_data)


func _build_steps_from_indices(indices: Array, value: float = 1.0) -> Array:
	var steps = []
	for i in range(DEFAULT_PATTERN_STEPS):
		steps.append(0.0)
	for raw_step in indices:
		var step = int(raw_step)
		if step >= 0 and step < DEFAULT_PATTERN_STEPS:
			steps[step] = value
	return steps


func _build_false_steps() -> Array:
	var values = []
	for i in range(DEFAULT_PATTERN_STEPS):
		values.append(false)
	return values


func _build_constant_int_steps(value: int) -> Array:
	var values = []
	for i in range(DEFAULT_PATTERN_STEPS):
		values.append(value)
	return values


func _build_constant_note_steps(note: int) -> Array:
	var values = []
	for i in range(DEFAULT_PATTERN_STEPS):
		values.append(note)
	return values


func _build_note_steps_from_pattern(pattern: Array, note_pool: Array, fallback_note: int) -> Array:
	var notes = _build_constant_note_steps(fallback_note)
	if note_pool.is_empty():
		return notes
	
	var note_idx = 0
	var max_steps: int = mini(DEFAULT_PATTERN_STEPS, pattern.size())
	for step in range(max_steps):
		if float(pattern[step]) > 0.0:
			notes[step] = int(note_pool[note_idx % note_pool.size()])
			note_idx += 1
	return notes


func _extract_drum_patterns(patterns: Dictionary, layer: String) -> Dictionary:
	var drum_patterns = {}
	for key in patterns.keys():
		var key_name = str(key)
		if patterns[key] is Array and _is_drum_layer(key_name.to_lower()):
			drum_patterns[key_name] = patterns[key]
	
	if patterns.has(layer) and patterns[layer] is Array:
		drum_patterns[layer] = patterns[layer]
	
	if drum_patterns.is_empty():
		var layer_pattern = _find_pattern_array(patterns, layer, DRUM_SOUNDS)
		if not layer_pattern.is_empty():
			drum_patterns[layer] = layer_pattern
	
	return drum_patterns


func _find_pattern_array(patterns: Dictionary, layer: String, aliases: Array) -> Array:
	if patterns.has(layer) and patterns[layer] is Array:
		return patterns[layer]
	
	var layer_lower = layer.to_lower()
	for key in patterns.keys():
		var key_name = str(key)
		if key_name.to_lower() == layer_lower and patterns[key] is Array:
			return patterns[key]
	
	for alias in aliases:
		var alias_name = str(alias)
		if patterns.has(alias_name) and patterns[alias_name] is Array:
			return patterns[alias_name]
	
	for key in patterns.keys():
		var key_name = str(key).to_lower()
		if not (patterns[key] is Array):
			continue
		for alias in aliases:
			var alias_name = str(alias).to_lower()
			if alias_name in key_name:
				return patterns[key]
	
	return []


func _build_drum_preset_data(preset_name: String) -> Dictionary:
	var kick_indices = [0, 4, 8, 12]
	var snare_indices = [4, 12]
	var hihat_indices = [2, 6, 10, 14]
	var clap_indices = [4, 12]
	
	match preset_name:
		"Broken Beat":
			kick_indices = [0, 6, 9, 14]
			snare_indices = [4, 12]
			hihat_indices = [1, 3, 5, 7, 9, 11, 13, 15]
			clap_indices = [12]
		"Half Time":
			kick_indices = [0, 7, 10]
			snare_indices = [8]
			hihat_indices = [2, 6, 10, 14]
			clap_indices = [8]
		"Sparse":
			kick_indices = [0, 12]
			snare_indices = [8]
			hihat_indices = [4, 14]
			clap_indices = []
	
	return {
		"kick": _build_steps_from_indices(kick_indices),
		"snare": _build_steps_from_indices(snare_indices),
		"hihat": _build_steps_from_indices(hihat_indices),
		"clap": _build_steps_from_indices(clap_indices),
	}


func _build_melodic_preset_data(family: String, preset_name: String) -> Dictionary:
	var is_bass = (family == "bass")
	var base_note = 36 if is_bass else 60
	var pattern = _build_steps_from_indices([0, 4, 8, 12])
	var note_pool = [base_note]
	
	if is_bass:
		match preset_name:
			"Offbeat Bounce":
				pattern = _build_steps_from_indices([2, 6, 10, 14])
				note_pool = [36, 36, 38, 36]
			"Syncopated":
				pattern = _build_steps_from_indices([0, 3, 6, 10, 14])
				note_pool = [36, 38, 41, 38, 36]
			"Sparse Sub":
				pattern = _build_steps_from_indices([0, 10])
				note_pool = [35, 38]
			_:
				pattern = _build_steps_from_indices([0, 4, 8, 12])
				note_pool = [36, 36, 38, 36]
	else:
		match preset_name:
			"Staccato Run":
				pattern = _build_steps_from_indices([0, 2, 4, 6, 8, 10, 12, 14])
				note_pool = [60, 62, 64, 67, 69, 67, 64, 62]
			"Call and Response":
				pattern = _build_steps_from_indices([0, 1, 2, 8, 9, 10, 14])
				note_pool = [64, 67, 69, 60, 62, 64, 67]
			"Long Tone":
				pattern = _build_steps_from_indices([0])
				note_pool = [67]
			_:
				pattern = _build_steps_from_indices([0, 2, 3, 6, 8, 11, 14])
				note_pool = [64, 67, 69, 67, 65, 64, 62]
	
	var notes = _build_note_steps_from_pattern(pattern, note_pool, base_note)
	var glides = _build_false_steps()
	return {
		"pattern": pattern,
		"notes": notes,
		"glides": glides,
	}


func _build_chord_preset_data(preset_name: String) -> Dictionary:
	var pattern = _build_steps_from_indices([0, 4, 8, 12])
	var progression = ["I", "V", "vi", "IV"]
	
	match preset_name:
		"Minor Flow":
			pattern = _build_steps_from_indices([0, 4, 8, 12])
			progression = ["vi", "IV", "I", "V"]
		"Slow Pads":
			pattern = _build_steps_from_indices([0, 8])
			progression = ["I", "vi"]
		"Sparse Stabs":
			pattern = _build_steps_from_indices([2, 6, 10, 14])
			progression = ["I", "IV", "V", "vi"]
	
	return {
		"pattern": pattern,
		"chords": _build_chord_steps_from_pattern(pattern, progression),
		"voicings": _build_constant_int_steps(0),
		"sustains": _build_false_steps(),
	}


func _build_chord_steps_from_pattern(pattern: Array, progression: Array = []) -> Array:
	var chord_steps = []
	for i in range(DEFAULT_PATTERN_STEPS):
		chord_steps.append("rest")
	
	var prog: Array = progression
	if prog.is_empty():
		prog = ["I", "V", "vi", "IV"]
	
	var chord_idx = 0
	var max_steps: int = mini(DEFAULT_PATTERN_STEPS, pattern.size())
	for step in range(max_steps):
		if float(pattern[step]) > 0.0:
			chord_steps[step] = prog[chord_idx % prog.size()]
			chord_idx += 1
	
	return chord_steps


func _build_arp_preset_data(preset_name: String) -> Dictionary:
	var settings = {
		"direction": "up",
		"rate": "1/8",
		"octave_range": 1,
		"gate_length": 0.8,
		"swing": 0.0,
		"velocity_curve": "flat",
	}
	
	match preset_name:
		"Down 1/16":
			settings["direction"] = "down"
			settings["rate"] = "1/16"
			settings["gate_length"] = 0.65
		"Up-Down Trance":
			settings["direction"] = "up_down"
			settings["rate"] = "1/16"
			settings["octave_range"] = 2
			settings["gate_length"] = 0.75
		"Random Texture":
			settings["direction"] = "random"
			settings["rate"] = "1/8T"
			settings["octave_range"] = 3
			settings["gate_length"] = 0.55
			settings["swing"] = 8.0
			settings["velocity_curve"] = "crescendo"
	
	return settings


func _resolve_pattern_song_id(song_id: String) -> String:
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


func _get_layer_pattern_override(layer: String) -> Dictionary:
	if _pattern_overrides_by_section.is_empty():
		return {}
	
	var section_key = _current_section if not _current_section.is_empty() else GLOBAL_SECTION_KEY
	var section_override = _find_layer_override(section_key, layer)
	if not section_override.is_empty():
		return section_override
	
	return _find_layer_override(GLOBAL_SECTION_KEY, layer)


func _find_layer_override(section_key: String, layer: String) -> Dictionary:
	var section_data = _pattern_overrides_by_section.get(section_key, {})
	if not (section_data is Dictionary):
		return {}
	
	if section_data.has(layer):
		var raw = section_data[layer]
		if raw is Dictionary:
			return raw.duplicate(true)
		if raw is Array:
			return {"pattern": raw.duplicate()}
	
	var layer_lower = layer.to_lower()
	for key in section_data.keys():
		if str(key).to_lower() == layer_lower:
			var raw = section_data[key]
			if raw is Dictionary:
				return raw.duplicate(true)
			if raw is Array:
				return {"pattern": raw.duplicate()}
	
	return {}


func _on_unified_pattern_changed(pattern_data: Dictionary):
	"""Unified handler for all new pattern editors"""
	_current_pattern = pattern_data
	pattern_changed.emit(_current_layer, pattern_data)


func _on_drum_pattern_changed(pattern_data: Dictionary):
	_current_pattern = pattern_data
	pattern_changed.emit(_current_layer, pattern_data)


func _on_bass_pattern_changed(pattern: Array, notes: Array):
	var data = {"pattern": pattern, "notes": notes}
	pattern_changed.emit(_current_layer, data)


func _on_chord_pattern_changed(pattern: Array, chords: Array):
	var data = {"pattern": pattern, "chords": chords}
	pattern_changed.emit(_current_layer, data)


func _on_arp_pattern_changed(settings: Dictionary):
	pattern_changed.emit(_current_layer, settings)


func _on_pattern_preview(element: String):
	_pending_preview_context = {
		"step_preview": true,
		"preview_source": "pattern_row"
	}
	_emit_preview_request(element)


func _on_bass_preview(note: int):
	_pending_preview_context = {
		"step_preview": true,
		"preview_source": "bass_step",
		"preview_note": note
	}
	_emit_preview_request(_current_layer)


func _on_chord_preview(chord: Variant):
	var pattern_data: Dictionary = get_current_pattern()
	_pending_preview_context = {
		"step_preview": true,
		"preview_source": "chord_step",
		"chord_degree": str(chord),
		"key": str(pattern_data.get("key", "C")),
		"scale": str(pattern_data.get("scale", "major"))
	}
	_emit_preview_request(_current_layer)


func _on_arp_preview(note: Variant = null):
	_pending_preview_context = {
		"step_preview": true,
		"preview_source": "arp_step"
	}
	if note is int or note is float:
		_pending_preview_context["preview_note"] = int(note)
	_emit_preview_request(_current_layer)


func _emit_preview_request(request_layer: String, force: bool = false):
	var layer_name: String = request_layer if not request_layer.is_empty() else _current_layer
	if layer_name.is_empty():
		return
	if not force:
		var now_ms: int = Time.get_ticks_msec()
		if (now_ms - _last_pattern_preview_ms) < PATTERN_PREVIEW_COOLDOWN_MS:
			return
		_last_pattern_preview_ms = now_ms
	preview_requested.emit(layer_name)


func _detect_layer_type(layer: String) -> String:
	"""Detect layer type from name for param definitions"""
	var family = _get_pattern_layer_family(layer.to_lower())
	if family == "bass":
		return "bass"
	if family == "lead":
		return "lead"
	if family == "drums":
		return "drums"
	if family == "arp":
		return "arp"
	return "pad"


# === REBUILD UI ===

func _rebuild_words():
	# Clear
	for child in _words_container.get_children():
		child.queue_free()
	
	# Add word tags
	for word in _current_words:
		var tag = _create_word_tag(word)
		_words_container.add_child(tag)
	
	# Add opposite suggestions
	var all_opposites = []
	for word in _current_words:
		for opp in _word_bridge.get_opposites(word):
			if opp not in _current_words and opp not in all_opposites:
				all_opposites.append(opp)
	
	if not all_opposites.is_empty():
		var spacer = Control.new()
		spacer.custom_minimum_size.x = 8
		_words_container.add_child(spacer)
		
		var divider = Label.new()
		divider.text = "| try:"
		divider.add_theme_font_size_override("font_size", 11)
		divider.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		_words_container.add_child(divider)
		
		for opp in all_opposites.slice(0, 4):  # Max 4 suggestions
			var tag = _create_suggestion_word_tag(opp)
			_words_container.add_child(tag)


func _create_word_tag(word: String) -> Button:
	var btn = Button.new()
	btn.text = word + " âœ•"
	btn.add_theme_font_size_override("font_size", 13)
	
	var category = _word_bridge.get_word_category(word)
	var color = WORD_CATEGORIES.get(category, Color(0.5, 0.5, 0.5))
	
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.4)
	style.set_corner_radius_all(4)
	style.border_color = color
	style.set_border_width_all(1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.pressed.connect(_on_word_tag_clicked.bind(word))
	btn.tooltip_text = "Click to remove '%s'" % word
	
	return btn


func _create_suggestion_word_tag(word: String) -> Button:
	var btn = Button.new()
	btn.text = "+ " + word
	btn.add_theme_font_size_override("font_size", 11)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18)
	style.set_corner_radius_all(4)
	style.border_color = Color(0.3, 0.3, 0.35)
	style.set_border_width_all(1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.25, 0.25, 0.3)
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.pressed.connect(_on_suggestion_word_clicked.bind(word))
	btn.tooltip_text = "Add '%s'" % word
	
	return btn


func _rebuild_sliders():
	# Clear
	for child in _sliders_container.get_children():
		child.queue_free()
	_param_sliders.clear()
	
	# Get param definitions for this layer type
	var layer_type = _detect_layer_type(_current_layer)
	var definitions = PARAM_DEFINITIONS.get(layer_type, PARAM_DEFINITIONS["pad"])
	
	# Group params
	var groups = {
		"Oscillator": [],
		"Filter": [],
		"Envelope": [],
		"Modulation": [],
		"Effects": [],
		"Drums": [],
		"Other": []
	}
	
	for param_key in definitions.keys():
		var group = "Other"
		if param_key.begins_with("osc."): group = "Oscillator"
		elif param_key.begins_with("filter."): group = "Filter"
		elif param_key.begins_with("env."): group = "Envelope"
		elif param_key.begins_with("mod."): group = "Modulation"
		elif param_key.begins_with("fx."): group = "Effects"
		elif param_key.begins_with("kick.") or param_key.begins_with("snare.") or param_key.begins_with("hat."):
			group = "Drums"
		groups[group].append(param_key)
	
	# Build grouped sliders
	for group_name in ["Oscillator", "Filter", "Envelope", "Modulation", "Effects", "Drums", "Other"]:
		var group_params = groups[group_name]
		if group_params.is_empty():
			continue
		
		# Group header
		var group_label = Label.new()
		group_label.text = group_name
		group_label.add_theme_font_size_override("font_size", 12)
		group_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		_sliders_container.add_child(group_label)
		
		# Sliders
		for param_key in group_params:
			var def = definitions[param_key]
			var current_val = _get_nested_param(param_key, def["default"])
			var row = _create_slider_row(param_key, def["label"], current_val, def["min"], def["max"])
			_sliders_container.add_child(row)


func _create_slider_row(param_key: String, label_text: String, value: float, min_val: float, max_val: float) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	label.custom_minimum_size.x = 90
	row.add_child(label)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = value
	slider.step = (max_val - min_val) / 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_changed.bind(param_key))
	row.add_child(slider)
	
	# Value label
	var val_label = Label.new()
	val_label.text = _format_value(value, min_val, max_val)
	val_label.add_theme_font_size_override("font_size", 11)
	val_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	val_label.custom_minimum_size.x = 50
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_label)
	
	# Store reference
	_param_sliders[param_key] = {
		"slider": slider,
		"label": val_label,
		"min": min_val,
		"max": max_val
	}
	
	# Update label when slider changes
	slider.value_changed.connect(func(v): val_label.text = _format_value(v, min_val, max_val))
	
	return row


func _format_value(value: float, min_val: float, max_val: float) -> String:
	# Choose format based on range
	var range_size = max_val - min_val
	if range_size > 100:
		return "%.0f" % value
	elif range_size > 1:
		return "%.2f" % value
	else:
		return "%.3f" % value


func _rebuild_suggestions():
	# Clear
	for child in _suggestions_container.get_children():
		child.queue_free()
	
	# Generate suggestions based on current words and params
	var suggestions = _generate_suggestions()
	
	if suggestions.is_empty():
		var none_label = Label.new()
		none_label.text = "No suggestions - sound looks balanced!"
		none_label.add_theme_font_size_override("font_size", 11)
		none_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.4))
		_suggestions_container.add_child(none_label)
		return
	
	for suggestion in suggestions:
		var row = _create_suggestion_row(suggestion)
		_suggestions_container.add_child(row)


func _generate_suggestions() -> Array:
	var suggestions = []
	
	# Check for word-param mismatches
	for word in _current_words:
		var word_params = _word_bridge.get_word_params(word)
		for param_key in word_params.keys():
			var expected = word_params[param_key]
			var current = _get_nested_param(param_key, null)
			if current != null and expected is Dictionary:
				if expected.has("range"):
					var r = expected["range"]
					if current < r[0] or current > r[1]:
						suggestions.append({
							"text": "'%s' suggests %s in range [%.2f-%.2f] but it's %.2f" % [word, param_key, r[0], r[1], current],
							"action": "adjust",
							"param": param_key,
							"target": (r[0] + r[1]) / 2.0
						})
	
	# Check for contradicting words
	for i in range(_current_words.size()):
		for j in range(i + 1, _current_words.size()):
			var word1 = _current_words[i]
			var word2 = _current_words[j]
			if word2 in _word_bridge.get_opposites(word1):
				suggestions.append({
					"text": "'%s' and '%s' are opposites - consider removing one" % [word1, word2],
					"action": "conflict",
					"words": [word1, word2]
				})
	
	# Suggest missing words based on params
	var detected_traits = _detect_traits_from_params()
	for detected_word in detected_traits:
		if detected_word not in _current_words:
			var any_opposite_present = false
			for opp in _word_bridge.get_opposites(detected_word):
				if opp in _current_words:
					any_opposite_present = true
					break
			if not any_opposite_present:
				suggestions.append({
					"text": "Params suggest '%s' - add it?" % detected_word,
					"action": "add_word",
					"word": detected_word
				})
	
	return suggestions.slice(0, 5)  # Max 5 suggestions


func _detect_traits_from_params() -> Array:
	"""Detect words that match current param values"""
	var traits = []
	var identity = SoundIdentity.from_params(_current_layer, _current_params)
	
	for category in identity.traits.keys():
		for trait_word in identity.traits[category]:
			traits.append(trait_word)
	
	return traits


func _create_suggestion_row(suggestion: Dictionary) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	# Icon
	var icon = Label.new()
	match suggestion["action"]:
		"adjust": icon.text = "âš™ï¸"
		"conflict": icon.text = "âš ï¸"
		"add_word": icon.text = "ðŸ’¡"
		_: icon.text = "â€¢"
	icon.add_theme_font_size_override("font_size", 12)
	row.add_child(icon)
	
	# Text
	var text = Label.new()
	text.text = suggestion["text"]
	text.add_theme_font_size_override("font_size", 11)
	text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(text)
	
	# Apply button
	var apply_btn = Button.new()
	apply_btn.text = "Apply"
	apply_btn.add_theme_font_size_override("font_size", 10)
	apply_btn.pressed.connect(_on_suggestion_apply.bind(suggestion))
	row.add_child(apply_btn)
	
	return row


func _rebuild_evaluation():
	# Clear
	for child in _evaluation_container.get_children():
		child.queue_free()
	
	# Generate identity and show features
	var identity = SoundIdentity.from_params(_current_layer, _current_params)
	
	for feature_name in identity.features.keys():
		var value = identity.features[feature_name]
		var bar = _create_eval_bar(feature_name, value)
		_evaluation_container.add_child(bar)


func _create_eval_bar(name: String, value: float) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	var label = Label.new()
	label.text = name.replace("_", " ").capitalize()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	label.custom_minimum_size.x = 80
	row.add_child(label)
	
	# Bar
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.12, 0.12, 0.15)
	bar_bg.custom_minimum_size = Vector2(100, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_bg)
	
	var bar_fill = ColorRect.new()
	bar_fill.color = Color.from_hsv(0.3 + value * 0.4, 0.6, 0.7)
	bar_fill.custom_minimum_size = Vector2(value * 100, 8)
	bar_bg.add_child(bar_fill)
	
	var val_label = Label.new()
	val_label.text = "%.0f%%" % (value * 100)
	val_label.add_theme_font_size_override("font_size", 10)
	val_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	val_label.custom_minimum_size.x = 35
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_label)
	
	return row


# === HELPERS ===

func _get_nested_param(param_key: String, default_val):
	"""Get param value from nested dict using dot notation"""
	var parts = param_key.split(".")
	var current = _current_params
	
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return default_val
	
	if current is Dictionary:
		if current.has("value"):
			return current["value"]
		elif current.has("range"):
			return (current["range"][0] + current["range"][1]) / 2.0
	
	return current if current != null else default_val


func _set_nested_param(param_key: String, value):
	"""Set param value in nested dict using dot notation"""
	var parts = param_key.split(".")
	var current = _current_params
	
	for i in range(parts.size() - 1):
		var part = parts[i]
		if not current.has(part):
			current[part] = {}
		current = current[part]
	
	current[parts[-1]] = value


# === CALLBACKS ===

func _on_slider_changed(value: float, param_key: String):
	_set_nested_param(param_key, value)
	param_changed.emit(_current_layer, param_key, value)
	
	# Rebuild suggestions (might have changed)
	call_deferred("_rebuild_suggestions")
	call_deferred("_rebuild_evaluation")


func _on_word_tag_clicked(word: String):
	# Remove word
	_current_words.erase(word)
	word_removed.emit(_current_layer, word)
	_rebuild_words()
	_rebuild_suggestions()


func _on_suggestion_word_clicked(word: String):
	# Add word, remove opposites
	var opposites = _word_bridge.get_opposites(word)
	for opp in opposites:
		if opp in _current_words:
			_current_words.erase(opp)
			word_removed.emit(_current_layer, opp)
	
	_current_words.append(word)
	word_added.emit(_current_layer, word)
	
	# Apply word's params
	var word_params = _word_bridge.get_word_params(word)
	for param_key in word_params.keys():
		var target = word_params[param_key]
		if target is Dictionary and target.has("range"):
			target = (target["range"][0] + target["range"][1]) / 2.0
		
		_set_nested_param(param_key, target)
		
		# Update slider if exists
		if _param_sliders.has(param_key):
			var slider_data = _param_sliders[param_key]
			slider_data["slider"].value = target
		
		param_changed.emit(_current_layer, param_key, target)
	
	_rebuild_words()
	_rebuild_suggestions()
	_rebuild_evaluation()


func _on_suggestion_apply(suggestion: Dictionary):
	match suggestion["action"]:
		"adjust":
			var param_key = suggestion["param"]
			var target = suggestion["target"]
			_set_nested_param(param_key, target)
			if _param_sliders.has(param_key):
				_param_sliders[param_key]["slider"].value = target
			param_changed.emit(_current_layer, param_key, target)
		
		"add_word":
			_on_suggestion_word_clicked(suggestion["word"])
		
		"conflict":
			pass  # User must choose which to remove
	
	suggestion_applied.emit(_current_layer, suggestion)
	_rebuild_suggestions()
	_rebuild_evaluation()


func _on_add_word_pressed():
	# TODO: Show word picker popup
	print("SoundDetailPanel: Add word requested for %s" % _current_layer)


func _on_preview_pressed():
	_pending_preview_context = _build_manual_preview_context()
	_emit_preview_request(_current_layer, true)


func consume_preview_context() -> Dictionary:
	var context: Dictionary = _pending_preview_context.duplicate(true)
	_pending_preview_context.clear()
	return context


func _build_manual_preview_context() -> Dictionary:
	var context: Dictionary = {
		"step_preview": false,
		"preview_source": "manual"
	}
	var pattern_data: Dictionary = get_current_pattern()
	if pattern_data.is_empty():
		return context
	
	if pattern_data.has("pattern") and pattern_data["pattern"] is Array:
		context["pattern"] = pattern_data["pattern"].duplicate()
	if pattern_data.has("notes") and pattern_data["notes"] is Array:
		context["notes"] = pattern_data["notes"].duplicate()
	if pattern_data.has("chords") and pattern_data["chords"] is Array:
		context["chords"] = pattern_data["chords"].duplicate()
	if pattern_data.has("key"):
		context["key"] = pattern_data["key"]
	if pattern_data.has("scale"):
		context["scale"] = pattern_data["scale"]
	if pattern_data.has("direction"):
		context["direction"] = pattern_data["direction"]
	if pattern_data.has("rate"):
		context["rate"] = pattern_data["rate"]
	
	return context


func _on_reset_pressed():
	_current_params = _original_params.duplicate(true)
	_rebuild_sliders()
	_rebuild_suggestions()
	_rebuild_evaluation()


func _on_randomize_pressed():
	var layer_type = _detect_layer_type(_current_layer)
	var definitions = PARAM_DEFINITIONS.get(layer_type, PARAM_DEFINITIONS["pad"])
	
	for param_key in definitions.keys():
		var def = definitions[param_key]
		var new_val = randf_range(def["min"], def["max"])
		_set_nested_param(param_key, new_val)
		
		if _param_sliders.has(param_key):
			_param_sliders[param_key]["slider"].value = new_val
		
		param_changed.emit(_current_layer, param_key, new_val)
	
	_rebuild_suggestions()
	_rebuild_evaluation()


func _on_copy_config_pressed():
	# Copy current config to clipboard
	var config_text = JSON.stringify(_current_params, "\t")
	DisplayServer.clipboard_set(config_text)
	print("SoundDetailPanel: Config copied to clipboard")


func get_current_pattern() -> Dictionary:
	"""Return current pattern data for saving"""
	# Try to get from unified editor first
	if _pattern_editor and _pattern_editor.has_method("get_pattern_data"):
		return _pattern_editor.get_pattern_data()
	return _current_pattern


func set_use_unified_editors(enabled: bool):
	"""Switch between unified and legacy pattern editors"""
	_use_unified_editors = enabled
	# Re-setup current editor if one exists
	if not _current_layer.is_empty():
		_setup_pattern_editor_for_layer(_current_layer)
		_load_pattern_for_layer(_current_song, _current_layer)


func is_using_unified_editors() -> bool:
	"""Check if using unified pattern editors"""
	return _use_unified_editors


func get_pattern_editor():
	"""Return the current pattern editor instance"""
	return _pattern_editor
