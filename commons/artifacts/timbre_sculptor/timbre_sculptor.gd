# timbre_sculptor.gd
# Timbre Sculptor — Cognitive Compression Artifact
#
# A VR rack-style panel with 8 vertical sliders controlling the amplitudes
# of the first 8 harmonics (fundamental + 7 overtones). Real-time additive
# synthesis generates the timbre as you move sliders. A waveform display
# shows the composite waveform; a spectrum display shows harmonic bars.
# Pre-set buttons morph to known timbres: sine, square, sawtooth, triangle,
# and vowel approximations (A, E, I, O, U).
#
# COGNITIVE COMPRESSION TARGET:
#   "Timbre IS harmonic recipe" becomes a single chunk. The slider heights
#   ARE the spectrum. You don't decode a Fourier transform — you build it
#   with your hands.
#
# QFEP AUDIT:
#   Additive synthesis assumes a strictly harmonic series (integer multiples
#   of the fundamental). Real acoustic instruments produce INHARMONIC partials
#   (bells, drums, piano strings have stretched harmonics). This artifact
#   teaches the harmonic model, which is powerful but incomplete. Noise
#   components (breath, bow scrape, hammer impact) are also absent here.
#   The vowel presets are idealized formant approximations, not recordings.
#
extends Node3D
class_name TimbreSculptor


# @identity
# essence: waveform(t) = sum(amplitude[n] * sin(n * fundamental * t)) — additive synthesis with audio
# desire: Sculpt timbre by adjusting harmonic sliders and hearing the result immediately in VR
# critical_parameter: fundamental_freq — sets the pitch; all harmonics are integer multiples of this
# triggers: slider movement changes harmonic amplitudes; morph_speed controls preset transitions
# emerges: the sound of mathematics — square waves, saw waves, clarinet, all from the same formula
# needs: VR sliders for 8 harmonics [has], preset buttons [has], audio output [has]
# relationships: depends on AudioStreamGenerator; contrasts with additive_wave_demo (audible vs visual synthesis); unlocks timbre-as-spectrum
# truth: Timbre is the harmonic fingerprint of a sound — the same note on different instruments differs only in overtone amplitudes.

const _P = preload("res://commons/ui/ada_palette.gd")

# ── Preloads for VR components ──
const SLIDER_V_SCENE = preload("res://commons/audio/interfaces/VRAudioControlSliderVertical.tscn")
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const SIMPLE_WAVE_SCENE = preload("res://commons/audio/interfaces/VRSimpleWaveform.tscn")
const SPECTRUM_SCENE = preload("res://commons/audio/interfaces/VRSpectrumDisplay.tscn")

# ── Number of harmonic sliders ──
const NUM_HARMONICS := 8

# ── Layout constants (meters) ──
const SLIDER_SPACING := 0.085    # Horizontal spacing between sliders
const SLIDER_START_X := -0.30    # X position of first slider
const PANEL_Y := 0.0             # Base Y
const BUTTON_SPACING := 0.075    # Spacing between preset buttons
const BUTTON_ROW_Y := -0.22     # Y offset for button row
const DISPLAY_Y := 0.16          # Y offset for displays
const DISPLAY_Z := 0.0

# ── Audio processing constants ──
const MIN_FRAMES_THRESHOLD := 256
const MAX_FRAMES_PER_FILL := 512
const AMP_SILENCE_THRESHOLD := 0.001
const MORPH_ARRIVAL_THRESHOLD := 0.005
const MASTER_GAIN := 0.5
const AUDIO_BUFFER_SEC := 0.1
const AUDIO_UNIT_SIZE := 2.0

# ── Timbre presets ──
# Each preset is an array of 8 amplitudes [h1, h2, h3, h4, h5, h6, h7, h8]
const PRESETS := {
	"SINE": [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	"SQUARE": [1.0, 0.0, 0.333, 0.0, 0.200, 0.0, 0.143, 0.0],
	"SAW": [1.0, 0.500, 0.333, 0.250, 0.200, 0.167, 0.143, 0.125],
	"TRI": [1.0, 0.0, 0.111, 0.0, 0.040, 0.0, 0.020, 0.0],
	# Vowel formant approximations (harmonic amplitudes that approximate
	# the formant peaks of each vowel at ~220 Hz fundamental)
	# These are simplified — real vowels depend on vocal tract resonances
	"A": [1.0, 0.65, 0.30, 0.55, 0.40, 0.20, 0.10, 0.05],   # "ah" — open
	"E": [1.0, 0.50, 0.60, 0.25, 0.45, 0.30, 0.15, 0.08],   # "eh" — front
	"I": [1.0, 0.30, 0.15, 0.10, 0.35, 0.50, 0.40, 0.25],   # "ee" — high front
	"O": [1.0, 0.70, 0.40, 0.15, 0.10, 0.08, 0.05, 0.03],   # "oh" — back rounded
	"U": [1.0, 0.80, 0.20, 0.08, 0.05, 0.03, 0.02, 0.01],   # "oo" — close back
}

const PRESET_ORDER := ["SINE", "SQUARE", "SAW", "TRI", "A", "E", "I", "O", "U"]

# Preset button colors
const PRESET_COLORS := {
	"SINE": Color(0.25, 0.78, 0.35),    # Green
	"SQUARE": Color(0.20, 0.55, 0.95),  # Blue
	"SAW": Color(0.95, 0.45, 0.15),     # Orange
	"TRI": Color(0.00, 0.78, 0.85),     # Cyan
	"A": Color(0.85, 0.40, 0.80),       # Purple
	"E": Color(0.90, 0.22, 0.22),       # Red
	"I": Color(0.95, 0.75, 0.10),       # Yellow
	"O": Color(0.55, 0.40, 0.75),       # Violet
	"U": Color(0.70, 0.50, 0.35),       # Brown
}

## Configuration
@export_range(50.0, 2000.0, 1.0) var fundamental_freq: float = 220.0  # A3 — good audible fundamental
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -6.0
@export_range(0.5, 20.0, 0.5) var morph_speed: float = 4.0  # How fast presets morph (higher = faster)

## Internal state
var harmonic_amplitudes: Array[float] = []  # Current amplitude for each harmonic
var target_amplitudes: Array[float] = []     # Target (from preset morph)
var is_morphing: bool = false

# Component references
var sliders: Array = []  # References to slider instances
var buttons: Dictionary = {}  # preset_name → button instance
var waveform_display: Node3D = null
var spectrum_display: Node3D = null

# Audio synthesis
var _audio_player: AudioStreamPlayer3D
var _audio_phases: Array[float] = []
var _sample_rate: float = 44100.0

# Waveform buffer for display
var _waveform_buffer: PackedFloat32Array
const WAVEFORM_BUFFER_SIZE := 512

# Panel
var _panel_mesh: MeshInstance3D
var _components: Node3D

func _ready() -> void:
	# Initialize amplitudes to sine preset
	harmonic_amplitudes.resize(NUM_HARMONICS)
	target_amplitudes.resize(NUM_HARMONICS)
	_audio_phases.resize(NUM_HARMONICS)
	_waveform_buffer.resize(WAVEFORM_BUFFER_SIZE)
	
	for i in range(NUM_HARMONICS):
		harmonic_amplitudes[i] = PRESETS["SINE"][i]
		target_amplitudes[i] = harmonic_amplitudes[i]
		_audio_phases[i] = 0.0
	
	_build_panel()
	_build_sliders()
	_build_preset_buttons()
	_build_displays()
	_setup_audio()
	_sync_sliders_to_amplitudes()

# ═══════════════════════════════════════════
#  CONSTRUCTION
# ═══════════════════════════════════════════

func _build_panel() -> void:
	_components = Node3D.new()
	_components.name = "Components"
	add_child(_components)
	
	# Background panel
	_panel_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.82, 0.60, 0.015)
	_panel_mesh.mesh = box
	_panel_mesh.material_override = _P.make_material(_P.PANEL_LIGHT, 0.05, 0.75)
	_panel_mesh.position = Vector3(0, 0, -0.008)
	_components.add_child(_panel_mesh)
	
	# Title
	var title = Label3D.new()
	title.text = "TIMBRE SCULPTOR"
	title.font_size = 28
	title.pixel_size = 0.0005
	title.modulate = _P.TEXT_PRIMARY
	title.outline_size = 0
	title.position = Vector3(0, 0.26, 0.005)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_components.add_child(title)
	
	# Subtitle
	var subtitle = Label3D.new()
	subtitle.text = "Additive Synthesis — Build timbre with harmonics"
	subtitle.font_size = 14
	subtitle.pixel_size = 0.0005
	subtitle.modulate = _P.TEXT_SECONDARY
	subtitle.outline_size = 0
	subtitle.position = Vector3(0, 0.235, 0.005)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_components.add_child(subtitle)
	
	# Section labels
	_add_section_label("HARMONICS", Vector3(SLIDER_START_X, 0.18, 0.005))
	_add_section_label("PRESETS", Vector3(-0.24, BUTTON_ROW_Y + 0.06, 0.005))

# Adds a small section header label at the given position.
func _add_section_label(text: String, pos: Vector3) -> void:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.font_size = 16
	lbl.pixel_size = 0.0005
	lbl.modulate = _P.TEXT_SECONDARY
	lbl.outline_size = 0
	lbl.position = pos
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_components.add_child(lbl)

# Creates NUM_HARMONICS vertical sliders with frequency labels.
func _build_sliders() -> void:
	sliders.resize(NUM_HARMONICS)
	for i in range(NUM_HARMONICS):
		var slider = SLIDER_V_SCENE.instantiate()
		var x_pos = SLIDER_START_X + i * SLIDER_SPACING
		slider.position = Vector3(x_pos, 0.0, 0.02)
		_components.add_child(slider)

		# Configure slider
		slider.set_range(0.0, 1.0)
		var harmonic_num = i + 1
		var label_text = "H%d" % harmonic_num
		if i == 0:
			label_text = "FUND"
		slider.set_param_name(label_text)

		# Connect slider signal
		slider.slider_moved.connect(_on_slider_changed.bind(i))

		sliders[i] = slider
		
		# Frequency label below each slider
		var freq_label = Label3D.new()
		var freq = fundamental_freq * harmonic_num
		freq_label.text = "%d Hz" % int(freq)
		freq_label.font_size = 10
		freq_label.pixel_size = 0.0005
		freq_label.modulate = _P.TEXT_SECONDARY
		freq_label.outline_size = 0
		freq_label.position = Vector3(x_pos, -0.17, 0.005)
		freq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_components.add_child(freq_label)

# Lays out the row of preset buttons with color coding and labels.
func _build_preset_buttons() -> void:
	var total_presets = PRESET_ORDER.size()
	var start_x = -float(total_presets - 1) * BUTTON_SPACING / 2.0
	
	for i in range(total_presets):
		var preset_name = PRESET_ORDER[i]
		var btn = BUTTON_SCENE.instantiate()
		var x_pos = start_x + i * BUTTON_SPACING
		btn.position = Vector3(x_pos, BUTTON_ROW_Y, 0.02)
		_components.add_child(btn)
		
		# Set button colors
		var color = PRESET_COLORS.get(preset_name, _P.ACCENT_ORANGE)
		btn.pressed_color = color
		btn.released_color = color.darkened(0.5)
		
		# Wait for the button to initialize before calling update_colors
		btn.ready.connect(func():
			btn.update_colors()
		)
		
		# Connect pressed signal
		btn.pressed.connect(_on_preset_pressed.bind(preset_name))
		
		buttons[preset_name] = btn
		
		# Label below button
		var label = Label3D.new()
		label.text = preset_name
		label.font_size = 12
		label.pixel_size = 0.0005
		label.modulate = _P.TEXT_PRIMARY
		label.outline_size = 0
		label.position = Vector3(x_pos, BUTTON_ROW_Y - 0.035, 0.005)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_components.add_child(label)

# Instantiates the waveform and spectrum display panels.
func _build_displays() -> void:
	# Waveform display (left side of display row)
	waveform_display = SIMPLE_WAVE_SCENE.instantiate()
	waveform_display.position = Vector3(-0.18, DISPLAY_Y, 0.02)
	waveform_display.scale = Vector3(0.7, 0.7, 0.7)
	_components.add_child(waveform_display)
	waveform_display.set_param_name("WAVEFORM")
	
	# Spectrum display (right side of display row)
	spectrum_display = SPECTRUM_SCENE.instantiate()
	spectrum_display.position = Vector3(0.18, DISPLAY_Y, 0.02)
	spectrum_display.scale = Vector3(0.7, 0.7, 0.7)
	_components.add_child(spectrum_display)

# ═══════════════════════════════════════════
#  AUDIO SETUP
# ═══════════════════════════════════════════

func _setup_audio() -> void:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = _sample_rate
	stream.buffer_length = AUDIO_BUFFER_SEC

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.stream = stream
	_audio_player.volume_db = volume_db
	_audio_player.unit_size = AUDIO_UNIT_SIZE
	add_child(_audio_player)
	_audio_player.play()

# ═══════════════════════════════════════════
#  INTERACTION CALLBACKS
# ═══════════════════════════════════════════

func _on_slider_changed(_value, harmonic_idx: int) -> void:
	# Read normalized value from slider
	if harmonic_idx >= 0 and harmonic_idx < sliders.size():
		var slider = sliders[harmonic_idx]
		var norm_val = slider.get_normalized_value()
		harmonic_amplitudes[harmonic_idx] = norm_val
		target_amplitudes[harmonic_idx] = norm_val
		is_morphing = false  # User interaction overrides morph

# Starts morphing amplitudes toward the given preset.
func _on_preset_pressed(preset_name: String) -> void:
	if not PRESETS.has(preset_name):
		return
	
	var preset = PRESETS[preset_name]
	for i in range(NUM_HARMONICS):
		target_amplitudes[i] = preset[i]
	is_morphing = true

# ═══════════════════════════════════════════
#  SYNC SLIDERS ↔ AMPLITUDES
# ═══════════════════════════════════════════

func _sync_sliders_to_amplitudes() -> void:
	for i in range(NUM_HARMONICS):
		if i < sliders.size():
			sliders[i].set_normalized_value(harmonic_amplitudes[i])

# ═══════════════════════════════════════════
#  PROCESS — Audio generation + morph + display
# ═══════════════════════════════════════════

func _process(delta: float) -> void:
	# Morph amplitudes toward target
	if is_morphing:
		var all_arrived = true
		for i in range(NUM_HARMONICS):
			harmonic_amplitudes[i] = lerp(harmonic_amplitudes[i], target_amplitudes[i],
				morph_speed * delta)
			if absf(harmonic_amplitudes[i] - target_amplitudes[i]) > MORPH_ARRIVAL_THRESHOLD:
				all_arrived = false
		
		if all_arrived:
			is_morphing = false
			for i in range(NUM_HARMONICS):
				harmonic_amplitudes[i] = target_amplitudes[i]
		
		# Update slider positions to reflect morph
		_sync_sliders_to_amplitudes()
	
	# Generate audio
	_generate_audio()

func _generate_audio() -> void:
	if not _audio_player or not _audio_player.playing:
		return
	
	var playback = _audio_player.get_stream_playback()
	if not playback:
		return
	
	var frames_available = playback.get_frames_available()
	if frames_available < MIN_FRAMES_THRESHOLD:
		return

	var frames_to_fill = mini(frames_available, MAX_FRAMES_PER_FILL)
	var waveform_write_idx := 0
	
	for _f in range(frames_to_fill):
		var sample: float = 0.0
		var total_amp: float = 0.0
		
		# Additive synthesis: sum of harmonics
		for h in range(NUM_HARMONICS):
			var amp = harmonic_amplitudes[h]
			if amp < AMP_SILENCE_THRESHOLD:
				continue
			
			var harmonic_freq = fundamental_freq * float(h + 1)
			_audio_phases[h] += harmonic_freq * TAU / _sample_rate
			if _audio_phases[h] > TAU:
				_audio_phases[h] -= TAU
			
			sample += amp * sin(_audio_phases[h])
			total_amp += amp
		
		# Normalize to prevent clipping when many harmonics are active
		if total_amp > 1.0:
			sample /= total_amp
		
		sample *= MASTER_GAIN
		sample = clampf(sample, -1.0, 1.0)
		
		playback.push_frame(Vector2(sample, sample))
		
		# Store in waveform buffer for display (downsample)
		if waveform_write_idx < WAVEFORM_BUFFER_SIZE:
			_waveform_buffer[waveform_write_idx] = sample
			waveform_write_idx += 1

# ═══════════════════════════════════════════
#  KEYBOARD INPUT (testing fallback)
# ═══════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# F1-F9 trigger presets
		var key_map := {
			KEY_F1: "SINE", KEY_F2: "SQUARE", KEY_F3: "SAW", KEY_F4: "TRI",
			KEY_F5: "A", KEY_F6: "E", KEY_F7: "I", KEY_F8: "O", KEY_F9: "U",
		}
		if key_map.has(event.keycode):
			_on_preset_pressed(key_map[event.keycode])

# ═══════════════════════════════════════════
#  PUBLIC API
# ═══════════════════════════════════════════

func set_preset(preset_name: String) -> void:
	"""Programmatically apply a preset with smooth morph."""
	_on_preset_pressed(preset_name)

func set_fundamental(freq: float) -> void:
	"""Change the fundamental frequency."""
	fundamental_freq = clampf(freq, 50.0, 2000.0)

func get_harmonic_amplitudes() -> Array[float]:
	"""Return current harmonic amplitudes."""
	return harmonic_amplitudes.duplicate()

func set_harmonic_amplitude(index: int, value: float) -> void:
	"""Set a single harmonic amplitude (0-indexed)."""
	if index >= 0 and index < NUM_HARMONICS:
		harmonic_amplitudes[index] = clampf(value, 0.0, 1.0)
		target_amplitudes[index] = harmonic_amplitudes[index]
		if index < sliders.size():
			sliders[index].set_normalized_value(harmonic_amplitudes[index])

func _exit_tree() -> void:
	# Stop audio playback
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
	# Disconnect slider signals
	for i in range(sliders.size()):
		var slider = sliders[i]
		if is_instance_valid(slider) and slider.slider_moved.is_connected(_on_slider_changed):
			slider.slider_moved.disconnect(_on_slider_changed)
	# Disconnect preset button signals
	for preset_name in buttons:
		var btn = buttons[preset_name]
		if is_instance_valid(btn) and btn.pressed.is_connected(_on_preset_pressed):
			btn.pressed.disconnect(_on_preset_pressed)

func apply_grid_config(config_data: Dictionary) -> void:
	pass
