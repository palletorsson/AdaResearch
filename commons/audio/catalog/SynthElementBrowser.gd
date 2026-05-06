# SynthElementBrowser.gd
# Deep synthesis element browser with authentic parameters
# Focus: Individual sound elements (bass, drums, fx) with full control

extends Control
class_name SynthElementBrowser

const SAMPLE_RATE = 44100.0

# ─────────────────────────────────────────────────────────────────────────────
# ELEMENT DEFINITIONS
# Each element has: category, description, parameters, generator function
# ─────────────────────────────────────────────────────────────────────────────

const SYNTH_ELEMENTS = {
	# ═══════════════════════════════════════════════════════════════════════
	# BASS SYNTHESIZERS
	# ═══════════════════════════════════════════════════════════════════════
	"tb303_bass": {
		"name": "TB-303 Acid Bass",
		"category": "bass",
		"description": "Roland TB-303 Bass Line. 18dB diode ladder filter, decay-only envelope, accent/slide. The sound of acid house.",
		"history": "Released 1982, originally for bass accompaniment. Rediscovered by Chicago house producers in 1987.",
		"parameters": {
			"waveform": {"type": "option", "options": ["sawtooth", "square"], "default": "sawtooth", "desc": "VCO waveform"},
			"cutoff": {"type": "float", "min": 60, "max": 2500, "default": 400, "unit": "Hz", "desc": "Filter cutoff frequency"},
			"resonance": {"type": "float", "min": 0, "max": 1.0, "default": 0.7, "desc": "Filter resonance (0.85+ screams)"},
			"env_mod": {"type": "float", "min": 0, "max": 1.0, "default": 0.6, "desc": "Envelope to filter amount"},
			"decay": {"type": "float", "min": 0.03, "max": 2.0, "default": 0.3, "unit": "s", "desc": "Envelope decay time"},
			"accent": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Accent intensity (boosts res + env)"},
			"slide_time": {"type": "float", "min": 0.02, "max": 0.2, "default": 0.06, "unit": "s", "desc": "Portamento time"},
			"distortion": {"type": "float", "min": 0, "max": 1.0, "default": 0.2, "desc": "Diode soft-clipping"},
			"note": {"type": "int", "min": 24, "max": 72, "default": 36, "desc": "MIDI note (36=C2)"}
		}
	},
	"minimoog_bass": {
		"name": "Minimoog Fat Bass",
		"category": "bass",
		"description": "Classic Minimoog bass: 3 oscillators, 24dB ladder filter, warm saturation. The fattest bass in synthesis history.",
		"history": "Minimoog released 1970. The bass sound heard on countless records from Parliament to Dr. Dre.",
		"parameters": {
			"osc1_wave": {"type": "option", "options": ["sawtooth", "square", "triangle"], "default": "sawtooth", "desc": "Oscillator 1 waveform"},
			"osc2_wave": {"type": "option", "options": ["sawtooth", "square", "triangle"], "default": "sawtooth", "desc": "Oscillator 2 waveform"},
			"osc3_wave": {"type": "option", "options": ["sawtooth", "square", "triangle"], "default": "square", "desc": "Oscillator 3 (sub) waveform"},
			"osc2_detune": {"type": "float", "min": -0.05, "max": 0.05, "default": 0.003, "desc": "OSC2 detune ratio"},
			"osc3_octave": {"type": "option", "options": ["-2", "-1", "0"], "default": "-1", "desc": "OSC3 octave offset"},
			"osc_mix": {"type": "float", "min": 0, "max": 1, "default": 0.7, "desc": "OSC1-2 vs OSC3 mix"},
			"cutoff": {"type": "float", "min": 50, "max": 8000, "default": 800, "unit": "Hz", "desc": "Filter cutoff"},
			"resonance": {"type": "float", "min": 0, "max": 1.0, "default": 0.3, "desc": "Filter resonance"},
			"filter_env": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Filter envelope amount"},
			"attack": {"type": "float", "min": 0.001, "max": 1.0, "default": 0.01, "unit": "s", "desc": "Amplitude attack"},
			"decay": {"type": "float", "min": 0.01, "max": 2.0, "default": 0.3, "unit": "s", "desc": "Amplitude decay"},
			"sustain": {"type": "float", "min": 0, "max": 1.0, "default": 0.7, "desc": "Amplitude sustain level"},
			"release": {"type": "float", "min": 0.01, "max": 3.0, "default": 0.5, "unit": "s", "desc": "Amplitude release"},
			"saturation": {"type": "float", "min": 0, "max": 1.0, "default": 0.3, "desc": "Tube-style saturation"},
			"drift": {"type": "float", "min": 0, "max": 0.3, "default": 0.05, "desc": "Oscillator drift (analog feel)"},
			"note": {"type": "int", "min": 24, "max": 60, "default": 36, "desc": "MIDI note"}
		}
	},
	"sub_bass": {
		"name": "Sub Bass (808 Style)",
		"category": "bass",
		"description": "Pure sub bass sine wave with slight saturation. The foundation of hip-hop and modern bass music.",
		"history": "TR-808 bass drum decay extended = the iconic 808 sub bass.",
		"parameters": {
			"frequency": {"type": "float", "min": 30, "max": 80, "default": 45, "unit": "Hz", "desc": "Base frequency"},
			"pitch_env": {"type": "float", "min": 0, "max": 1.0, "default": 0.3, "desc": "Initial pitch drop amount"},
			"pitch_decay": {"type": "float", "min": 0.01, "max": 0.1, "default": 0.03, "unit": "s", "desc": "Pitch envelope decay"},
			"decay": {"type": "float", "min": 0.2, "max": 3.0, "default": 1.0, "unit": "s", "desc": "Amplitude decay"},
			"saturation": {"type": "float", "min": 0, "max": 1.0, "default": 0.2, "desc": "Soft saturation"},
			"harmonics": {"type": "float", "min": 0, "max": 1.0, "default": 0.1, "desc": "Add upper harmonics"}
		}
	},
	
	# ═══════════════════════════════════════════════════════════════════════
	# DRUM MACHINES
	# ═══════════════════════════════════════════════════════════════════════
	"tr909_kick": {
		"name": "TR-909 Kick",
		"category": "drums",
		"description": "Roland TR-909 kick drum. Punchy analog body with click transient. The sound of techno.",
		"history": "TR-909 released 1984. Became the heartbeat of house and techno music.",
		"parameters": {
			"tune": {"type": "float", "min": 40, "max": 100, "default": 55, "unit": "Hz", "desc": "Base pitch"},
			"pitch_start": {"type": "float", "min": 100, "max": 300, "default": 150, "unit": "Hz", "desc": "Pitch envelope start"},
			"pitch_decay": {"type": "float", "min": 0.005, "max": 0.05, "default": 0.02, "unit": "s", "desc": "Pitch envelope time"},
			"attack_level": {"type": "float", "min": 0, "max": 1.0, "default": 0.3, "desc": "Click attack amount"},
			"attack_freq": {"type": "float", "min": 2000, "max": 6000, "default": 3000, "unit": "Hz", "desc": "Click frequency"},
			"decay": {"type": "float", "min": 0.1, "max": 0.5, "default": 0.25, "unit": "s", "desc": "Amplitude decay"},
			"punch": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Transient punch"}
		}
	},
	"tr808_kick": {
		"name": "TR-808 Kick",
		"category": "drums",
		"description": "Roland TR-808 kick. Deep, boomy, long decay. The foundation of hip-hop.",
		"history": "TR-808 released 1980. Initially a commercial failure, later became the most sampled drum machine.",
		"parameters": {
			"tune": {"type": "float", "min": 30, "max": 80, "default": 50, "unit": "Hz", "desc": "Base frequency"},
			"decay": {"type": "float", "min": 0.2, "max": 2.0, "default": 0.8, "unit": "s", "desc": "Long decay time"},
			"tone": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Brightness/harmonics"},
			"click": {"type": "float", "min": 0, "max": 1.0, "default": 0.1, "desc": "Attack click amount"}
		}
	},
	"tr909_snare": {
		"name": "TR-909 Snare",
		"category": "drums",
		"description": "TR-909 snare drum. Analog tone oscillators + sampled noise.",
		"history": "Hybrid analog/digital design gave it a unique punchy character.",
		"parameters": {
			"tune": {"type": "float", "min": 150, "max": 300, "default": 200, "unit": "Hz", "desc": "Body frequency"},
			"tone": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Tone vs noise balance"},
			"snappy": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Snare wire brightness"},
			"tone_decay": {"type": "float", "min": 0.03, "max": 0.2, "default": 0.08, "unit": "s", "desc": "Tone envelope decay"},
			"noise_decay": {"type": "float", "min": 0.05, "max": 0.3, "default": 0.15, "unit": "s", "desc": "Noise envelope decay"}
		}
	},
	"tr909_hihat": {
		"name": "TR-909 Hi-Hat",
		"category": "drums",
		"description": "TR-909 metallic hi-hats. 6 square wave oscillators at non-harmonic ratios.",
		"history": "The 909 hi-hat became essential for house and techno production.",
		"parameters": {
			"decay": {"type": "float", "min": 0.02, "max": 0.8, "default": 0.05, "unit": "s", "desc": "Decay (short=closed, long=open)"},
			"tone": {"type": "float", "min": 6000, "max": 16000, "default": 10000, "unit": "Hz", "desc": "High-pass cutoff"},
			"metallic": {"type": "float", "min": 0, "max": 1.0, "default": 0.7, "desc": "Metallic vs noise mix"},
			"pitch": {"type": "float", "min": 0.5, "max": 2.0, "default": 1.0, "desc": "Overall pitch multiplier"}
		}
	},
	"tr808_clap": {
		"name": "TR-808 Clap",
		"category": "drums",
		"description": "TR-808 hand clap. Multiple noise bursts with reverb tail.",
		"history": "The iconic 808 clap - actually multiple overlapping noise bursts.",
		"parameters": {
			"tone": {"type": "float", "min": 800, "max": 3000, "default": 1500, "unit": "Hz", "desc": "Bandpass center"},
			"spread": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Timing spread of hits"},
			"decay": {"type": "float", "min": 0.1, "max": 0.5, "default": 0.25, "unit": "s", "desc": "Overall decay"},
			"reverb": {"type": "float", "min": 0, "max": 1.0, "default": 0.4, "desc": "Built-in reverb amount"}
		}
	},
	
	# ═══════════════════════════════════════════════════════════════════════
	# PADS & STRINGS
	# ═══════════════════════════════════════════════════════════════════════
	"juno_pad": {
		"name": "Juno-106 Chorus Pad",
		"category": "pads",
		"description": "Roland Juno-106 pad with legendary BBD chorus. Warm, wide, lush.",
		"history": "Juno-106 released 1984. The built-in chorus became its signature sound.",
		"parameters": {
			"waveform": {"type": "option", "options": ["sawtooth", "pulse", "both"], "default": "sawtooth", "desc": "Oscillator waveform"},
			"pulse_width": {"type": "float", "min": 0.1, "max": 0.9, "default": 0.5, "desc": "Pulse width (if pulse selected)"},
			"pwm_rate": {"type": "float", "min": 0, "max": 5, "default": 0.3, "unit": "Hz", "desc": "PWM LFO rate"},
			"pwm_depth": {"type": "float", "min": 0, "max": 0.4, "default": 0.2, "desc": "PWM depth"},
			"sub_level": {"type": "float", "min": 0, "max": 1.0, "default": 0.3, "desc": "Sub oscillator level"},
			"cutoff": {"type": "float", "min": 100, "max": 8000, "default": 2000, "unit": "Hz", "desc": "Filter cutoff"},
			"resonance": {"type": "float", "min": 0, "max": 0.8, "default": 0.2, "desc": "Filter resonance"},
			"env_amount": {"type": "float", "min": 0, "max": 1.0, "default": 0.3, "desc": "Filter envelope amount"},
			"attack": {"type": "float", "min": 0.01, "max": 3.0, "default": 0.5, "unit": "s", "desc": "Amplitude attack"},
			"release": {"type": "float", "min": 0.1, "max": 5.0, "default": 1.5, "unit": "s", "desc": "Amplitude release"},
			"chorus_mode": {"type": "option", "options": ["off", "I", "II", "I+II"], "default": "I+II", "desc": "Chorus mode"},
			"chorus_depth": {"type": "float", "min": 0, "max": 1.0, "default": 0.6, "desc": "Chorus modulation depth"}
		}
	},
	"supersaw": {
		"name": "JP-8000 Supersaw",
		"category": "pads",
		"description": "7 detuned sawtooth oscillators. The sound of trance and EDM.",
		"history": "Roland JP-8000 released 1996. The Supersaw defined trance music.",
		"parameters": {
			"voices": {"type": "int", "min": 1, "max": 7, "default": 7, "desc": "Number of oscillators"},
			"detune": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Detune spread amount"},
			"mix": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Center vs side balance"},
			"cutoff": {"type": "float", "min": 500, "max": 12000, "default": 4000, "unit": "Hz", "desc": "Filter cutoff"},
			"resonance": {"type": "float", "min": 0, "max": 0.7, "default": 0.2, "desc": "Filter resonance"},
			"attack": {"type": "float", "min": 0.001, "max": 2.0, "default": 0.1, "unit": "s", "desc": "Amplitude attack"},
			"release": {"type": "float", "min": 0.1, "max": 3.0, "default": 0.8, "unit": "s", "desc": "Amplitude release"}
		}
	},
	
	# ═══════════════════════════════════════════════════════════════════════
	# LEADS
	# ═══════════════════════════════════════════════════════════════════════
	"hoover": {
		"name": "Hoover / Rave Stab",
		"category": "leads",
		"description": "The classic rave hoover sound. Detuned oscillators with portamento and filter sweep.",
		"history": "Originated from Alpha Juno 'What The' patch. Named after the vacuum cleaner sound.",
		"parameters": {
			"voices": {"type": "int", "min": 1, "max": 5, "default": 3, "desc": "Detuned voice count"},
			"detune": {"type": "float", "min": 0, "max": 0.03, "default": 0.008, "desc": "Detune spread"},
			"pwm_depth": {"type": "float", "min": 0, "max": 0.4, "default": 0.2, "desc": "Pulse width modulation"},
			"pwm_rate": {"type": "float", "min": 1, "max": 10, "default": 4, "unit": "Hz", "desc": "PWM LFO rate"},
			"portamento": {"type": "float", "min": 0, "max": 0.5, "default": 0.1, "unit": "s", "desc": "Slide time"},
			"cutoff": {"type": "float", "min": 200, "max": 4000, "default": 600, "unit": "Hz", "desc": "Base filter cutoff"},
			"filter_env": {"type": "float", "min": 0, "max": 1.0, "default": 0.7, "desc": "Filter envelope amount"},
			"resonance": {"type": "float", "min": 0, "max": 0.9, "default": 0.6, "desc": "Filter resonance"},
			"saturation": {"type": "float", "min": 0, "max": 1.0, "default": 0.4, "desc": "Output saturation"}
		}
	},
	"dx7_epiano": {
		"name": "DX7 Electric Piano",
		"category": "leads",
		"description": "Yamaha DX7 FM electric piano. The sound of the 1980s.",
		"history": "DX7 released 1983. The E.Piano 1 preset became the most used sound of the decade.",
		"parameters": {
			"mod_ratio": {"type": "float", "min": 0.5, "max": 4.0, "default": 1.0, "desc": "Modulator frequency ratio"},
			"mod_index": {"type": "float", "min": 0, "max": 10, "default": 3.5, "desc": "FM modulation depth"},
			"mod_decay": {"type": "float", "min": 2, "max": 30, "default": 15, "desc": "Modulator envelope decay rate"},
			"brightness": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Overall brightness"},
			"velocity": {"type": "float", "min": 0, "max": 1.0, "default": 0.7, "desc": "Velocity sensitivity"},
			"decay": {"type": "float", "min": 0.5, "max": 5.0, "default": 2.0, "unit": "s", "desc": "Overall decay time"}
		}
	},
	
	# ═══════════════════════════════════════════════════════════════════════
	# EFFECTS (as sound processors)
	# ═══════════════════════════════════════════════════════════════════════
	"filter_sweep": {
		"name": "Resonant Filter Sweep",
		"category": "effects",
		"description": "Classic filter sweep effect. Lowpass, highpass, or bandpass with resonance.",
		"parameters": {
			"type": {"type": "option", "options": ["lowpass", "highpass", "bandpass"], "default": "lowpass", "desc": "Filter type"},
			"cutoff_start": {"type": "float", "min": 50, "max": 10000, "default": 200, "unit": "Hz", "desc": "Sweep start frequency"},
			"cutoff_end": {"type": "float", "min": 50, "max": 10000, "default": 4000, "unit": "Hz", "desc": "Sweep end frequency"},
			"sweep_time": {"type": "float", "min": 0.1, "max": 10.0, "default": 2.0, "unit": "s", "desc": "Sweep duration"},
			"resonance": {"type": "float", "min": 0, "max": 1.0, "default": 0.7, "desc": "Filter resonance"},
			"slope": {"type": "option", "options": ["12dB", "24dB"], "default": "24dB", "desc": "Filter slope"}
		}
	},
	"bbd_chorus": {
		"name": "BBD Chorus",
		"category": "effects",
		"description": "Bucket Brigade Device chorus. Classic analog warmth and width.",
		"parameters": {
			"rate": {"type": "float", "min": 0.1, "max": 5.0, "default": 0.8, "unit": "Hz", "desc": "LFO rate"},
			"depth": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Modulation depth"},
			"mix": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Wet/dry mix"},
			"feedback": {"type": "float", "min": 0, "max": 0.8, "default": 0.2, "desc": "Feedback amount"}
		}
	},
	"distortion": {
		"name": "Distortion / Saturation",
		"category": "effects",
		"description": "Various distortion types: tube, transistor, diode, bitcrush.",
		"parameters": {
			"type": {"type": "option", "options": ["tube", "transistor", "diode", "bitcrush"], "default": "tube", "desc": "Distortion type"},
			"drive": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Drive/intensity"},
			"tone": {"type": "float", "min": 0, "max": 1.0, "default": 0.5, "desc": "Post-distortion tone"},
			"mix": {"type": "float", "min": 0, "max": 1.0, "default": 1.0, "desc": "Wet/dry mix"},
			"bits": {"type": "int", "min": 2, "max": 16, "default": 8, "desc": "Bit depth (bitcrush only)"}
		}
	}
}

# ─────────────────────────────────────────────────────────────────────────────
# UI COMPONENTS
# ─────────────────────────────────────────────────────────────────────────────

var _split_container: HSplitContainer
var _category_tree: Tree
var _detail_panel: VBoxContainer
var _param_container: VBoxContainer
var _waveform_display: Control
var _audio_player: AudioStreamPlayer

var _current_element: String = ""
var _current_params: Dictionary = {}
var _param_controls: Dictionary = {}  # param_name -> control

# Waveform visualization
var _waveform_samples: PackedFloat32Array = PackedFloat32Array()

signal element_selected(element_id: String)
signal param_changed(element_id: String, param_name: String, value)
signal preview_requested(element_id: String, params: Dictionary)


func _ready():
	_build_ui()
	_populate_categories()
	_setup_audio()


func _build_ui():
	# Main split container
	_split_container = HSplitContainer.new()
	_split_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_split_container.split_offset = 280
	add_child(_split_container)
	
	# Left panel: Category tree
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size.x = 250
	_split_container.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)
	
	var tree_label = Label.new()
	tree_label.text = "🎛️ SYNTH ELEMENTS"
	tree_label.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(tree_label)
	
	_category_tree = Tree.new()
	_category_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_tree.hide_root = true
	_category_tree.item_selected.connect(_on_element_selected)
	left_vbox.add_child(_category_tree)
	
	# Right panel: Detail view
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split_container.add_child(right_scroll)
	
	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_detail_panel)
	
	# Placeholder
	var placeholder = Label.new()
	placeholder.text = "Select an element from the left panel"
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_detail_panel.add_child(placeholder)


func _populate_categories():
	var root = _category_tree.create_item()
	
	var categories = {}
	for element_id in SYNTH_ELEMENTS:
		var element = SYNTH_ELEMENTS[element_id]
		var cat = element.category
		if not categories.has(cat):
			categories[cat] = []
		categories[cat].append(element_id)
	
	var category_icons = {
		"bass": "🎸",
		"drums": "🥁",
		"pads": "🎹",
		"leads": "🎺",
		"effects": "🔧"
	}
	
	var category_order = ["bass", "drums", "pads", "leads", "effects"]
	
	for cat in category_order:
		if not categories.has(cat):
			continue
			
		var cat_item = _category_tree.create_item(root)
		var icon = category_icons.get(cat, "📦")
		cat_item.set_text(0, "%s %s" % [icon, cat.to_upper()])
		cat_item.set_selectable(0, false)
		
		for element_id in categories[cat]:
			var element = SYNTH_ELEMENTS[element_id]
			var elem_item = _category_tree.create_item(cat_item)
			elem_item.set_text(0, element.name)
			elem_item.set_metadata(0, element_id)


func _setup_audio():
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)


func _on_element_selected():
	var selected = _category_tree.get_selected()
	if selected == null:
		return
	
	var element_id = selected.get_metadata(0)
	if element_id == null or not SYNTH_ELEMENTS.has(element_id):
		return
	
	_current_element = element_id
	_load_element(element_id)
	element_selected.emit(element_id)


func _load_element(element_id: String):
	var element = SYNTH_ELEMENTS[element_id]
	
	# Clear detail panel
	for child in _detail_panel.get_children():
		child.queue_free()
	_param_controls.clear()
	
	# Initialize current params with defaults
	_current_params = {}
	for param_name in element.parameters:
		var param = element.parameters[param_name]
		_current_params[param_name] = param.default
	
	# Header
	var header = Label.new()
	header.text = element.name
	header.add_theme_font_size_override("font_size", 24)
	_detail_panel.add_child(header)
	
	# Description
	var desc = Label.new()
	desc.text = element.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_detail_panel.add_child(desc)
	
	# History
	if element.has("history"):
		var history = Label.new()
		history.text = "📜 " + element.history
		history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		history.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		history.add_theme_font_size_override("font_size", 12)
		_detail_panel.add_child(history)
	
	_detail_panel.add_child(HSeparator.new())
	
	# Waveform display
	_waveform_display = Control.new()
	_waveform_display.custom_minimum_size = Vector2(0, 120)
	_waveform_display.draw.connect(_draw_waveform)
	_detail_panel.add_child(_waveform_display)
	
	# Preview button
	var preview_hbox = HBoxContainer.new()
	_detail_panel.add_child(preview_hbox)
	
	var preview_btn = Button.new()
	preview_btn.text = "▶️ Preview"
	preview_btn.pressed.connect(_on_preview_pressed)
	preview_hbox.add_child(preview_btn)
	
	var stop_btn = Button.new()
	stop_btn.text = "⏹️ Stop"
	stop_btn.pressed.connect(_on_stop_pressed)
	preview_hbox.add_child(stop_btn)
	
	var randomize_btn = Button.new()
	randomize_btn.text = "🎲 Randomize"
	randomize_btn.pressed.connect(_on_randomize_pressed)
	preview_hbox.add_child(randomize_btn)
	
	_detail_panel.add_child(HSeparator.new())
	
	# Parameters section
	var params_label = Label.new()
	params_label.text = "⚙️ PARAMETERS"
	params_label.add_theme_font_size_override("font_size", 16)
	_detail_panel.add_child(params_label)
	
	_param_container = VBoxContainer.new()
	_detail_panel.add_child(_param_container)
	
	# Create parameter controls
	for param_name in element.parameters:
		var param = element.parameters[param_name]
		_create_param_control(param_name, param)
	
	# Generate initial preview
	_generate_preview()


func _create_param_control(param_name: String, param: Dictionary):
	var hbox = HBoxContainer.new()
	_param_container.add_child(hbox)
	
	# Label
	var label = Label.new()
	var display_name = param.get("desc", param_name)
	label.text = display_name
	label.custom_minimum_size.x = 200
	label.tooltip_text = param_name
	hbox.add_child(label)
	
	# Control based on type
	match param.type:
		"float":
			var slider = HSlider.new()
			slider.min_value = param.min
			slider.max_value = param.max
			slider.value = param.default
			slider.step = (param.max - param.min) / 100.0
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.value_changed.connect(_on_param_changed.bind(param_name))
			hbox.add_child(slider)
			
			var value_label = Label.new()
			value_label.text = "%.2f" % param.default
			value_label.custom_minimum_size.x = 60
			hbox.add_child(value_label)
			
			if param.has("unit"):
				var unit_label = Label.new()
				unit_label.text = param.unit
				unit_label.custom_minimum_size.x = 30
				hbox.add_child(unit_label)
			
			_param_controls[param_name] = {"slider": slider, "label": value_label}
			
		"int":
			var spinbox = SpinBox.new()
			spinbox.min_value = param.min
			spinbox.max_value = param.max
			spinbox.value = param.default
			spinbox.step = 1
			spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spinbox.value_changed.connect(_on_param_changed.bind(param_name))
			hbox.add_child(spinbox)
			
			_param_controls[param_name] = {"spinbox": spinbox}
			
		"option":
			var option = OptionButton.new()
			for opt in param.options:
				option.add_item(opt)
			var default_idx = param.options.find(param.default)
			option.select(default_idx if default_idx >= 0 else 0)
			option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option.item_selected.connect(_on_option_changed.bind(param_name, param.options))
			hbox.add_child(option)
			
			_param_controls[param_name] = {"option": option}


func _on_param_changed(value: float, param_name: String):
	_current_params[param_name] = value
	
	if _param_controls.has(param_name) and _param_controls[param_name].has("label"):
		_param_controls[param_name]["label"].text = "%.2f" % value
	
	param_changed.emit(_current_element, param_name, value)
	_generate_preview()


func _on_option_changed(index: int, param_name: String, options: Array):
	_current_params[param_name] = options[index]
	param_changed.emit(_current_element, param_name, options[index])
	_generate_preview()


func _on_preview_pressed():
	var stream = _generate_sound(_current_element, _current_params)
	if stream:
		_audio_player.stream = stream
		_audio_player.play()


func _on_stop_pressed():
	_audio_player.stop()


func _on_randomize_pressed():
	if not SYNTH_ELEMENTS.has(_current_element):
		return
	
	var element = SYNTH_ELEMENTS[_current_element]
	for param_name in element.parameters:
		var param = element.parameters[param_name]
		
		match param.type:
			"float":
				var new_val = randf_range(param.min, param.max)
				_current_params[param_name] = new_val
				if _param_controls.has(param_name):
					_param_controls[param_name]["slider"].value = new_val
			"int":
				var new_val = randi_range(param.min, param.max)
				_current_params[param_name] = new_val
				if _param_controls.has(param_name):
					_param_controls[param_name]["spinbox"].value = new_val
			"option":
				var idx = randi() % param.options.size()
				_current_params[param_name] = param.options[idx]
				if _param_controls.has(param_name):
					_param_controls[param_name]["option"].select(idx)
	
	_generate_preview()


func _generate_preview():
	var stream = _generate_sound(_current_element, _current_params)
	if stream:
		_extract_waveform(stream)
		_waveform_display.queue_redraw()


func _extract_waveform(stream: AudioStreamWAV):
	_waveform_samples.clear()
	if stream == null:
		return
	
	var data = stream.data
	var step = 4 if stream.stereo else 2  # 16-bit
	
	for i in range(0, data.size(), step):
		if i + 1 < data.size():
			var sample_int = data[i] | (data[i + 1] << 8)
			if sample_int > 32767:
				sample_int -= 65536
			_waveform_samples.append(float(sample_int) / 32768.0)
	
	# Downsample for display
	var target = 512
	if _waveform_samples.size() > target:
		var step_size = _waveform_samples.size() / target
		var downsampled = PackedFloat32Array()
		for i in range(target):
			downsampled.append(_waveform_samples[int(i * step_size)])
		_waveform_samples = downsampled


func _draw_waveform():
	if _waveform_display == null:
		return
	
	var rect = _waveform_display.get_rect()
	var w = rect.size.x
	var h = rect.size.y
	var mid_y = h / 2
	
	# Background
	_waveform_display.draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.1, 0.15))
	
	# Center line
	_waveform_display.draw_line(Vector2(0, mid_y), Vector2(w, mid_y), Color(0.3, 0.3, 0.3))
	
	# Waveform
	if _waveform_samples.size() > 1:
		var points = PackedVector2Array()
		for i in range(_waveform_samples.size()):
			var x = float(i) / _waveform_samples.size() * w
			var y = mid_y - _waveform_samples[i] * mid_y * 0.9
			points.append(Vector2(x, y))
		
		_waveform_display.draw_polyline(points, Color(0.4, 0.8, 1.0), 1.5)


# ─────────────────────────────────────────────────────────────────────────────
# SOUND GENERATION
# ─────────────────────────────────────────────────────────────────────────────

func _generate_sound(element_id: String, params: Dictionary) -> AudioStreamWAV:
	match element_id:
		"tb303_bass":
			return _generate_tb303(params)
		"minimoog_bass":
			return _generate_minimoog(params)
		"sub_bass":
			return _generate_sub_bass(params)
		"tr909_kick":
			return _generate_909_kick(params)
		"tr808_kick":
			return _generate_808_kick(params)
		"tr909_snare":
			return _generate_909_snare(params)
		"tr909_hihat":
			return _generate_909_hihat(params)
		"tr808_clap":
			return _generate_808_clap(params)
		"juno_pad":
			return _generate_juno_pad(params)
		"supersaw":
			return _generate_supersaw(params)
		"hoover":
			return _generate_hoover(params)
		"dx7_epiano":
			return _generate_dx7_epiano(params)
		_:
			return _generate_test_tone()
	return null


# ═══════════════════════════════════════════════════════════════════════════
# TB-303 ACID BASS
# ═══════════════════════════════════════════════════════════════════════════

func _generate_tb303(params: Dictionary) -> AudioStreamWAV:
	var duration = 1.0
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var waveform = params.get("waveform", "sawtooth")
	var note = params.get("note", 36)
	var freq = 440.0 * pow(2.0, (note - 69) / 12.0)
	var cutoff = params.get("cutoff", 400.0)
	var resonance = params.get("resonance", 0.7)
	var env_mod = params.get("env_mod", 0.6)
	var decay = params.get("decay", 0.3)
	var accent = params.get("accent", 0.5)
	var distortion = params.get("distortion", 0.2)
	
	# Filter state (18dB 3-pole simulation)
	var f1 = 0.0
	var f2 = 0.0
	var f3 = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Oscillator
		var osc = 0.0
		var phase = fmod(freq * t, 1.0)
		if waveform == "sawtooth":
			osc = phase * 2.0 - 1.0
		else:  # square
			osc = 1.0 if phase < 0.5 else -1.0
		
		# Envelope (decay only, accent shortens decay and boosts)
		var env_decay = decay * (1.0 - accent * 0.5)
		var env = exp(-t / env_decay)
		var accent_boost = 1.0 + accent * 0.5
		
		# Filter envelope modulation
		var env_mod_actual = env_mod * (1.0 + accent * 0.4)
		var filter_freq = cutoff + env * env_mod_actual * 2000.0
		var res_actual = min(resonance + accent * 0.2, 0.98)
		
		# 3-pole lowpass filter (18dB/oct)
		var fc = clamp(filter_freq / SAMPLE_RATE, 0.001, 0.499)
		var g = tan(PI * fc)
		var k = 2.0 - 2.0 * res_actual  # Resonance coefficient
		
		# Feedback
		var feedback = f3 * res_actual * 4.0
		var input = osc - feedback
		
		# Diode soft clipping on input (303 characteristic)
		input = _diode_clip(input, distortion)
		
		# 3 cascaded 1-pole filters
		f1 += g * (input - f1)
		f2 += g * (f1 - f2)
		f3 += g * (f2 - f3)
		
		# Output with envelope and accent
		var output = f3 * env * accent_boost
		
		# Final soft clipping
		output = tanh(output * (1.0 + distortion))
		
		data[i] = output * 0.7
	
	return _float_to_wav(data)


func _diode_clip(x: float, amount: float) -> float:
	# Asymmetric soft clipping (303 diode characteristic)
	var drive = 1.0 + amount * 3.0
	x *= drive
	if x > 0:
		return (1.0 - exp(-x)) / drive
	else:
		return (-1.0 + exp(x)) / drive


# ═══════════════════════════════════════════════════════════════════════════
# MINIMOOG BASS
# ═══════════════════════════════════════════════════════════════════════════

func _generate_minimoog(params: Dictionary) -> AudioStreamWAV:
	var duration = 1.5
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var note = params.get("note", 36)
	var freq = 440.0 * pow(2.0, (note - 69) / 12.0)
	var osc2_detune = params.get("osc2_detune", 0.003)
	var osc3_octave = int(params.get("osc3_octave", "-1"))
	var osc_mix = params.get("osc_mix", 0.7)
	var cutoff = params.get("cutoff", 800.0)
	var resonance = params.get("resonance", 0.3)
	var filter_env = params.get("filter_env", 0.5)
	var attack = params.get("attack", 0.01)
	var decay_time = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 0.5)
	var saturation = params.get("saturation", 0.3)
	var drift = params.get("drift", 0.05)
	
	# Moog ladder filter state
	var moog = [0.0, 0.0, 0.0, 0.0]
	
	# Drift LFOs (slow random)
	var drift1 = randf() * TAU
	var drift2 = randf() * TAU
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Oscillator drift
		var d1 = sin(drift1 + t * 0.3) * drift * 0.01
		var d2 = sin(drift2 + t * 0.4) * drift * 0.01
		
		# Three oscillators
		var freq1 = freq * (1.0 + d1)
		var freq2 = freq * (1.0 + osc2_detune + d2)
		var freq3 = freq * pow(2.0, osc3_octave)
		
		var osc1 = _sawtooth(freq1 * t)
		var osc2 = _sawtooth(freq2 * t)
		var osc3 = _square(freq3 * t)
		
		# Mix oscillators
		var osc12 = (osc1 + osc2) * 0.5 * osc_mix
		var osc_all = osc12 + osc3 * (1.0 - osc_mix) * 0.8
		
		# ADSR envelope
		var env = _adsr(t, attack, decay_time, sustain, release, duration - 0.2)
		
		# Filter envelope
		var filter_freq = cutoff + filter_env * 2000.0 * env
		
		# Moog 24dB ladder filter
		var fc = clamp(filter_freq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = resonance * 4.0
		
		var feedback = moog[3] * k
		var x = tanh(osc_all - feedback)
		
		for j in range(4):
			moog[j] += g * (x - moog[j])
			x = moog[j]
		
		var output = moog[3] * env
		
		# Tube saturation
		output = tanh(output * (1.0 + saturation * 2.0))
		
		data[i] = output * 0.6
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# SUB BASS (808 STYLE)
# ═══════════════════════════════════════════════════════════════════════════

func _generate_sub_bass(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("decay", 1.0) + 0.1
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var base_freq = params.get("frequency", 45.0)
	var pitch_env_amount = params.get("pitch_env", 0.3)
	var pitch_decay = params.get("pitch_decay", 0.03)
	var amp_decay = params.get("decay", 1.0)
	var saturation = params.get("saturation", 0.2)
	var harmonics = params.get("harmonics", 0.1)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Pitch envelope
		var pitch_env = exp(-t / pitch_decay)
		var freq = base_freq * (1.0 + pitch_env * pitch_env_amount)
		
		# Sine wave (fundamental)
		var fundamental = sin(TAU * freq * t)
		
		# Add harmonics for presence
		var harm = sin(TAU * freq * 2.0 * t) * 0.3 + sin(TAU * freq * 3.0 * t) * 0.1
		
		var osc = fundamental + harm * harmonics
		
		# Amplitude envelope
		var env = exp(-t / amp_decay)
		
		# Saturation
		var output = tanh(osc * (1.0 + saturation * 2.0)) * env
		
		data[i] = output * 0.8
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# TR-909 KICK
# ═══════════════════════════════════════════════════════════════════════════

func _generate_909_kick(params: Dictionary) -> AudioStreamWAV:
	var duration = 0.5
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var tune = params.get("tune", 55.0)
	var pitch_start = params.get("pitch_start", 150.0)
	var pitch_decay = params.get("pitch_decay", 0.02)
	var attack_level = params.get("attack_level", 0.3)
	var attack_freq = params.get("attack_freq", 3000.0)
	var amp_decay = params.get("decay", 0.25)
	var punch = params.get("punch", 0.5)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Pitch envelope
		var pitch_env = exp(-t / pitch_decay)
		var freq = tune + (pitch_start - tune) * pitch_env
		
		# Body (sine wave)
		var body = sin(TAU * freq * t)
		
		# Click attack (high frequency burst)
		var click_env = exp(-t * 50.0)
		var click = sin(TAU * attack_freq * t) * click_env * attack_level
		
		# Amplitude envelope with punch
		var env = exp(-t / amp_decay)
		var punch_env = 1.0 + punch * exp(-t * 100.0)
		
		var output = (body + click) * env * punch_env
		
		# Soft clip
		output = tanh(output * 1.2)
		
		data[i] = output * 0.9
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# TR-808 KICK
# ═══════════════════════════════════════════════════════════════════════════

func _generate_808_kick(params: Dictionary) -> AudioStreamWAV:
	var decay_time = params.get("decay", 0.8)
	var duration = decay_time + 0.1
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var tune = params.get("tune", 50.0)
	var tone = params.get("tone", 0.5)
	var click = params.get("click", 0.1)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Pitch envelope (very fast)
		var pitch_env = exp(-t * 60.0)
		var freq = tune + pitch_env * 100.0
		
		# Body
		var body = sin(TAU * freq * t)
		
		# Add harmonics based on tone
		body += sin(TAU * freq * 2.0 * t) * tone * 0.2
		
		# Click
		var click_sig = sin(TAU * 1500.0 * t) * exp(-t * 80.0) * click
		
		# Long decay
		var env = exp(-t / decay_time)
		
		var output = (body + click_sig) * env
		
		data[i] = output * 0.9
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# TR-909 SNARE
# ═══════════════════════════════════════════════════════════════════════════

func _generate_909_snare(params: Dictionary) -> AudioStreamWAV:
	var duration = 0.4
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var tune = params.get("tune", 200.0)
	var tone_mix = params.get("tone", 0.5)
	var snappy = params.get("snappy", 0.5)
	var tone_decay = params.get("tone_decay", 0.08)
	var noise_decay = params.get("noise_decay", 0.15)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Tone (two oscillators)
		var tone1 = sin(TAU * tune * t)
		var tone2 = sin(TAU * tune * 1.7 * t)  # Non-harmonic for character
		var tone_env = exp(-t / tone_decay)
		var tone_sig = (tone1 + tone2 * 0.5) * tone_env
		
		# Noise (snare wires)
		var noise = randf_range(-1, 1)
		var noise_env = exp(-t / noise_decay) * snappy
		
		# High-pass filter the noise
		noise *= (1.0 + snappy)  # More snappy = more highs
		
		# Mix
		var output = tone_sig * tone_mix + noise * noise_env * (1.0 - tone_mix * 0.5)
		
		data[i] = output * 0.7
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# TR-909 HI-HAT
# ═══════════════════════════════════════════════════════════════════════════

func _generate_909_hihat(params: Dictionary) -> AudioStreamWAV:
	var decay_time = params.get("decay", 0.05)
	var duration = max(decay_time + 0.05, 0.1)
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var tone_cutoff = params.get("tone", 10000.0)
	var metallic = params.get("metallic", 0.7)
	var pitch_mult = params.get("pitch", 1.0)
	
	# 909 metallic frequencies (non-harmonic ratios)
	var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
	
	# Simple high-pass state
	var hp_z1 = 0.0
	var hp_alpha = 0.9  # High-pass coefficient
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Metallic oscillators (square waves)
		var metallic_sig = 0.0
		for f in freqs:
			var phase = fmod(f * pitch_mult * t, 1.0)
			metallic_sig += 1.0 if phase < 0.5 else -1.0
		metallic_sig /= freqs.size()
		
		# Noise
		var noise = randf_range(-1, 1)
		
		# Mix metallic and noise
		var sig = metallic_sig * metallic + noise * (1.0 - metallic)
		
		# High-pass filter
		var hp_out = hp_alpha * (hp_z1 + sig)
		hp_z1 = hp_out - sig
		sig = hp_out
		
		# Envelope
		var env = exp(-t / decay_time)
		
		data[i] = sig * env * 0.5
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# TR-808 CLAP
# ═══════════════════════════════════════════════════════════════════════════

func _generate_808_clap(params: Dictionary) -> AudioStreamWAV:
	var duration = 0.5
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var tone = params.get("tone", 1500.0)
	var spread = params.get("spread", 0.5)
	var decay_time = params.get("decay", 0.25)
	var reverb_amount = params.get("reverb", 0.4)
	
	# Multiple hit times (the 808 clap is multiple noise bursts)
	var hit_times = [0.0, 0.012, 0.024, 0.036]
	
	# Simple reverb buffer
	var reverb_buffer = PackedFloat32Array()
	reverb_buffer.resize(int(SAMPLE_RATE * 0.1))
	var reverb_pos = 0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Noise
		var noise = randf_range(-1, 1)
		
		# Bandpass around tone frequency (simplified)
		# Just using noise with envelope shaping
		
		# Multiple hits
		var hit_env = 0.0
		for hit_t in hit_times:
			var rel_t = t - hit_t * (1.0 + spread * 0.5)
			if rel_t >= 0:
				hit_env += exp(-rel_t * 30.0) * 0.3
		
		# Main decay
		var main_env = exp(-t / decay_time)
		
		var sig = noise * hit_env * main_env
		
		# Simple reverb
		var reverb_read_pos = (reverb_pos - int(SAMPLE_RATE * 0.03) + reverb_buffer.size()) % reverb_buffer.size()
		var reverb_sig = reverb_buffer[reverb_read_pos] * 0.5
		reverb_buffer[reverb_pos] = sig + reverb_sig * 0.3
		reverb_pos = (reverb_pos + 1) % reverb_buffer.size()
		
		var output = sig + reverb_sig * reverb_amount
		
		data[i] = output * 0.6
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# JUNO-106 PAD
# ═══════════════════════════════════════════════════════════════════════════

func _generate_juno_pad(params: Dictionary) -> AudioStreamWAV:
	var duration = 3.0
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var waveform = params.get("waveform", "sawtooth")
	var pulse_width = params.get("pulse_width", 0.5)
	var pwm_rate = params.get("pwm_rate", 0.3)
	var pwm_depth = params.get("pwm_depth", 0.2)
	var sub_level = params.get("sub_level", 0.3)
	var cutoff = params.get("cutoff", 2000.0)
	var resonance = params.get("resonance", 0.2)
	var env_amount = params.get("env_amount", 0.3)
	var attack = params.get("attack", 0.5)
	var release_time = params.get("release", 1.5)
	var chorus_mode = params.get("chorus_mode", "I+II")
	var chorus_depth = params.get("chorus_depth", 0.6)
	
	var freq = 220.0  # A3
	
	# Filter state
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	# Chorus delay lines
	var chorus_buf1 = PackedFloat32Array()
	var chorus_buf2 = PackedFloat32Array()
	chorus_buf1.resize(int(SAMPLE_RATE * 0.05))
	chorus_buf2.resize(int(SAMPLE_RATE * 0.05))
	var ch_pos = 0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# PWM
		var pw = pulse_width + sin(TAU * pwm_rate * t) * pwm_depth
		
		# Oscillator
		var osc = 0.0
		match waveform:
			"sawtooth":
				osc = _sawtooth(freq * t)
			"pulse":
				osc = _pulse(freq * t, pw)
			"both":
				osc = _sawtooth(freq * t) * 0.5 + _pulse(freq * t, pw) * 0.5
		
		# Sub oscillator (one octave down, square)
		var sub = _square(freq * 0.5 * t) * sub_level
		
		var sig = osc + sub
		
		# ADSR envelope
		var env = _adsr(t, attack, 0.5, 0.8, release_time, duration - 0.5)
		
		# Filter
		var filter_freq = cutoff + env_amount * 2000.0 * env
		var fc = clamp(filter_freq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = resonance * 4.0
		
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		var filtered = filt[3]
		
		# Juno-style chorus
		var chorused = filtered
		if chorus_mode != "off":
			var lfo1 = sin(TAU * 0.5 * t)
			var lfo2 = sin(TAU * 0.8 * t)
			
			var delay1_ms = 3.0 + lfo1 * chorus_depth * 2.0
			var delay2_ms = 4.0 + lfo2 * chorus_depth * 2.0
			
			var delay1_samples = int(delay1_ms * SAMPLE_RATE / 1000.0)
			var delay2_samples = int(delay2_ms * SAMPLE_RATE / 1000.0)
			
			var read1 = (ch_pos - delay1_samples + chorus_buf1.size()) % chorus_buf1.size()
			var read2 = (ch_pos - delay2_samples + chorus_buf2.size()) % chorus_buf2.size()
			
			chorus_buf1[ch_pos] = filtered
			chorus_buf2[ch_pos] = filtered
			ch_pos = (ch_pos + 1) % chorus_buf1.size()
			
			match chorus_mode:
				"I":
					chorused = (filtered + chorus_buf1[read1]) * 0.5
				"II":
					chorused = (filtered + chorus_buf2[read2]) * 0.5
				"I+II":
					chorused = (filtered + chorus_buf1[read1] + chorus_buf2[read2]) / 3.0
		
		data[i] = chorused * env * 0.5
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# SUPERSAW (JP-8000)
# ═══════════════════════════════════════════════════════════════════════════

func _generate_supersaw(params: Dictionary) -> AudioStreamWAV:
	var duration = 2.0
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var voices = params.get("voices", 7)
	var detune = params.get("detune", 0.5)
	var mix_balance = params.get("mix", 0.5)
	var cutoff = params.get("cutoff", 4000.0)
	var resonance = params.get("resonance", 0.2)
	var attack = params.get("attack", 0.1)
	var release_time = params.get("release", 0.8)
	
	var freq = 220.0
	
	# Detune spread for each voice
	var detune_spread = [-0.11, -0.06, -0.02, 0.0, 0.02, 0.06, 0.11]
	var voice_levels = [0.5, 0.7, 0.9, 1.0, 0.9, 0.7, 0.5]
	
	# Filter
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Generate voices
		var sig = 0.0
		var total_level = 0.0
		
		for v in range(min(voices, 7)):
			var d = 1.0 + detune_spread[v] * detune * 0.1
			var level = voice_levels[v]
			if v == 3:  # Center voice
				level *= mix_balance + 0.5
			else:
				level *= (1.0 - mix_balance) + 0.5
			
			sig += _sawtooth(freq * d * t) * level
			total_level += level
		
		sig /= total_level
		
		# Filter
		var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = resonance * 4.0
		
		var fb = filt[3] * k
		var x = sig - fb
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		# Envelope
		var env = _adsr(t, attack, 0.3, 0.8, release_time, duration - 0.3)
		
		data[i] = filt[3] * env * 0.5
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# HOOVER / RAVE STAB
# ═══════════════════════════════════════════════════════════════════════════

func _generate_hoover(params: Dictionary) -> AudioStreamWAV:
	var duration = 1.5
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var voices = params.get("voices", 3)
	var detune_amount = params.get("detune", 0.008)
	var pwm_depth = params.get("pwm_depth", 0.2)
	var pwm_rate = params.get("pwm_rate", 4.0)
	var portamento = params.get("portamento", 0.1)
	var cutoff_base = params.get("cutoff", 600.0)
	var filter_env_amt = params.get("filter_env", 0.7)
	var resonance = params.get("resonance", 0.6)
	var saturation = params.get("saturation", 0.4)
	
	var freq = 220.0
	
	# Filter state
	var filt = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# PWM
		var pw = 0.3 + sin(TAU * pwm_rate * t) * pwm_depth
		
		# Multiple detuned oscillators
		var sig = 0.0
		for v in range(voices):
			var d = 1.0 + (float(v) / voices - 0.5) * detune_amount * 2.0
			sig += _sawtooth(freq * d * t)
		sig /= voices
		
		# Add pulse wave
		sig = sig * 0.7 + _pulse(freq * t, pw) * 0.3
		
		# Filter envelope
		var filter_env = exp(-t * 3.0)
		var filter_freq = cutoff_base + filter_env * filter_env_amt * 3000.0
		
		# Resonant filter
		var fc = clamp(filter_freq / SAMPLE_RATE, 0.001, 0.45)
		var g = tan(PI * fc)
		var k = resonance * 4.0
		
		var fb = filt[3] * k
		var x = tanh(sig - fb)  # Soft clip feedback
		for j in range(4):
			filt[j] += g * (x - filt[j])
			x = filt[j]
		
		# Amplitude envelope
		var env = _adsr(t, 0.02, 0.2, 0.6, 0.5, duration - 0.3)
		
		var output = filt[3] * env
		
		# Saturation
		output = tanh(output * (1.0 + saturation * 2.0))
		
		data[i] = output * 0.6
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# DX7 ELECTRIC PIANO (FM)
# ═══════════════════════════════════════════════════════════════════════════

func _generate_dx7_epiano(params: Dictionary) -> AudioStreamWAV:
	var duration = 3.0
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var mod_ratio = params.get("mod_ratio", 1.0)
	var mod_index = params.get("mod_index", 3.5)
	var mod_decay_rate = params.get("mod_decay", 15.0)
	var brightness = params.get("brightness", 0.5)
	var velocity = params.get("velocity", 0.7)
	var decay_time = params.get("decay", 2.0)
	
	var freq = 440.0
	
	# Adjust mod index based on brightness and velocity
	var actual_mod_index = mod_index * (0.5 + brightness) * (0.5 + velocity)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Modulator envelope (fast decay for "tine" attack)
		var mod_env = exp(-t * mod_decay_rate)
		
		# Carrier envelope (longer for sustain)
		var car_env = exp(-t / decay_time) * 0.7 + 0.3 * exp(-t * 0.5)
		
		# FM synthesis
		var mod_freq = freq * mod_ratio
		var modulator = sin(TAU * mod_freq * t) * actual_mod_index * mod_env
		var carrier = sin(TAU * freq * t + modulator)
		
		# Second operator pair for richness
		var mod2 = sin(TAU * freq * 2.0 * t) * actual_mod_index * 0.3 * mod_env
		var car2 = sin(TAU * freq * t + mod2) * 0.3
		
		var output = (carrier + car2) * car_env
		
		data[i] = output * 0.5
	
	return _float_to_wav(data)


# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

func _generate_test_tone() -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * 0.5)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		data[i] = sin(TAU * 440.0 * t) * exp(-t * 3.0) * 0.5
	
	return _float_to_wav(data)


func _sawtooth(phase: float) -> float:
	return fmod(phase, 1.0) * 2.0 - 1.0


func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


func _pulse(phase: float, width: float) -> float:
	return 1.0 if fmod(phase, 1.0) < width else -1.0


func _adsr(t: float, attack: float, decay: float, sustain: float, release: float, note_off: float) -> float:
	if t < attack:
		return t / attack
	elif t < attack + decay:
		return 1.0 - (t - attack) / decay * (1.0 - sustain)
	elif t < note_off:
		return sustain
	elif t < note_off + release:
		return sustain * (1.0 - (t - note_off) / release)
	else:
		return 0.0


func _float_to_wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(SAMPLE_RATE)
	wav.stereo = false
	
	var byte_data = PackedByteArray()
	byte_data.resize(data.size() * 2)
	
	for i in range(data.size()):
		var sample = clamp(data[i], -1.0, 1.0)
		var sample_int = int(sample * 32767)
		byte_data[i * 2] = sample_int & 0xFF
		byte_data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	wav.data = byte_data
	return wav
