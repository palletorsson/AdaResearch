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
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# ── Preloads for VR components ──
const SLIDER_V_SCENE = preload("res://commons/audio/interfaces/VRAudioControlSliderVertical.tscn")
var BUTTON_SCENE: PackedScene
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

## AXIS — HOW MUCH APPARATUS THIS ADMITS EXISTS BEHIND THE HAND. Not which timbre, not the
## harmonic amplitudes, not the presets: those are what the artifact TEACHES and they stay
## exactly as shipped at every value. What the sculptor SHOWS is whether additive synthesis
## is eight numbers floating in a room, or a machine that happens to expose eight of them.
##
## Adopted word for word — and value for value — from [[MarioSoundController]] and the seven
## promoted audio racks in this same registry (RackSineBasic, RackMoogBass, Rack303Acid,
## Rack808Drums, RackDX7Piano, RackAmbientDrone, RackMario). This is the same claim pointed
## at a different face: a panel of eight vertical sliders instead of a grabbed ball or a
## preset rack. Same word, same five moments, so a lab holding a rack and this sculptor
## cannot have one of them admitting a circuit while the other insists there is no machine.
##
##   none     the legacy lineage, byte for byte — the pale panel alone, edge on to nothing.
##            A FACE with no body: the slider heights ARE the spectrum and the sound comes
##            from wherever sound comes from.
##   plate    one dark shell standing behind the pale panel, oversailing it on every side,
##            with an edge lip and a lit strip along the foot. The instrument acquires a
##            front, and therefore a back you are not shown.
##   vacancy  the shell plus blanking covers over nine of twelve panel positions, standing
##            proud in lighter metal with a screw at each end, the left-hand column left
##            open where the eight harmonics live. What your hand can reach is the small
##            fitted subset of what the format would accept.
##   frame    no shell — two punched rack rails past the panel edges and two cross members
##            over and under it, the room visible straight through the gap behind. One unit
##            among many, rackable, made to be pulled and replaced.
##   works    no shell either — three boards on standoffs behind and beside the panel,
##            component blocks on their faces, wire runs crossing between them. The eight
##            sliders are revealed as the near ends of something soldered.
##
## STRICTLY ADDITIVE. "none" builds nothing at all and is the default, so all four existing
## placements render exactly as before. Nothing here reads or writes harmonic_amplitudes,
## the presets, the morph, the audio or the displays — the body is staged AROUND the panel
## and stops there.
@export_enum("none", "plate", "vacancy", "frame", "works") var machinery: String = "none"
const MACHINERIES: PackedStringArray = ["none", "plate", "vacancy", "frame", "works"]

## SECOND AXIS — STAGE-2 DNA, 2026-08-05. WHICH HARMONIC RECIPE THE PANEL IS FOUND HOLDING.
##
## The sound this artifact makes is invisible to a still. The eight slider POSITIONS are not:
## they ARE the spectrum drawn as a bar chart, which is the whole cognitive-compression claim
## in the header of this file ("the slider heights ARE the spectrum"). So the one thing here
## that is simultaneously audible and photographable is which named series the eight sliders
## are standing in, and that is what this axis turns.
##
## The word and its first four values are taken character for character from
## [[additive_wave_demo]].waveform (sine, square, sawtooth, triangle, clear) and agree with
## [[fourier_transform]].waveform (sine, square, impulse, triangle, sawtooth, noise) — three
## artifacts in the same sequence asking the same question of the same series must not answer
## it in three vocabularies. The spellings are the siblings', not the PRESETS keys': the
## registry says "sawtooth" and "triangle", the code's dictionary says SAW and TRI, and
## WAVEFORM_PRESET is the join.
##
## The fifth value is this artifact's alone and is why it does not simply adopt
## additive_wave_demo's list whole. Its fifth value is "clear" — every slider down, silence,
## a demo with nothing to show. This panel already has nine presets and five of them are
## vowels, which the other two artifacts do not have and cannot draw: a formant spectrum is
## not a monotone falling series but a bumpy envelope with peaks away from the fundamental,
## and standing the eight sliders in that shape is the only picture here that argues the
## harmonic model against a real voice. "clear" would have been a sixth blank tile.
##
##   sine       [1,0,0,0,0,0,0,0] — one slider up, seven on the floor. The shipped startup.
##   square     odd harmonics only, 1/n — a comb: up, down, up, down.
##   sawtooth   every harmonic at 1/n — a clean descending staircase, all eight standing.
##   triangle   odd harmonics at 1/n^2 — almost the sine, with two faint survivors.
##   formant    the "A" vowel — peaks at h2 and h4, a shape no 1/n law produces.
##
## DEFAULT PRESERVES. "sine" writes PRESETS["SINE"], which is exactly the array the four
## existing placements were already initialised with on the line this replaced. Nothing here
## touches the presets, the buttons, the morph, the audio, the displays or the machinery.
@export_enum("sine", "square", "sawtooth", "triangle", "formant") var waveform: String = "sine"
const WAVEFORMS: PackedStringArray = ["sine", "square", "sawtooth", "triangle", "formant"]
## The join between the shared registry vocabulary and this file's own PRESETS keys.
const WAVEFORM_PRESET := {
	"sine": "SINE",
	"square": "SQUARE",
	"sawtooth": "SAW",
	"triangle": "TRI",
	"formant": "A",
}

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
	BUTTON_SCENE = load("res://commons/interactables/push_button.tscn")
	# Initialize amplitudes to sine preset
	harmonic_amplitudes.resize(NUM_HARMONICS)
	target_amplitudes.resize(NUM_HARMONICS)
	_audio_phases.resize(NUM_HARMONICS)
	_waveform_buffer.resize(WAVEFORM_BUFFER_SIZE)
	
	# DNA: which named series the panel is found holding. "sine" resolves to PRESETS["SINE"],
	# the literal array this line used to name, so the default startup state is unchanged.
	var _w: String = str(waveform).strip_edges().to_lower()
	waveform = _w if WAVEFORMS.has(_w) else "sine"
	var startup: Array = PRESETS[WAVEFORM_PRESET.get(waveform, "SINE")]

	for i in range(NUM_HARMONICS):
		harmonic_amplitudes[i] = startup[i]
		target_amplitudes[i] = harmonic_amplitudes[i]
		_audio_phases[i] = 0.0

	_build_panel()
	_build_sliders()
	_build_preset_buttons()
	_build_displays()
	_setup_audio()
	_sync_sliders_to_amplitudes()

	# DNA, LAST: the machinery body is appended after every legacy child exists, so no node
	# above it changes index, position or parent. "none" builds nothing at all.
	var _m: String = str(machinery).strip_edges().to_lower()
	machinery = _m if MACHINERIES.has(_m) else "none"
	_build_machinery()

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
	
	# Title + subtitle consolidated onto one framed dark header panel (R-027)
	var header := Node3D.new()
	header.name = "HeaderBoard"
	header.position = Vector3(0, 0.2475, 0.002)
	_components.add_child(header)
	header.add_child(_plate(Vector3(0.64, 0.075, 0.02)))
	var title: MeshInstance3D = BakedText.make_label_mesh("TIMBRE SCULPTOR", _P.TEXT_ON_DARK, Vector2(0.40, 0.030), 1400, true)
	if title:
		title.position = Vector3(0, 0.014, 0.012)
		header.add_child(title)
	var subtitle: MeshInstance3D = BakedText.make_label_mesh("Additive Synthesis — Build timbre with harmonics", Color(0.70, 0.70, 0.74), Vector2(0.56, 0.020), 1400, true)
	if subtitle:
		subtitle.position = Vector3(0, -0.017, 0.012)
		header.add_child(subtitle)

	# Section labels
	_add_section_label("HARMONICS", Vector3(SLIDER_START_X, 0.18, 0.005))
	_add_section_label("PRESETS", Vector3(-0.24, BUTTON_ROW_Y + 0.06, 0.005))

# Adds a small section header tag at the given position (framed board, R-027).
func _add_section_label(text: String, pos: Vector3) -> void:
	var lbl: Node3D = BakedText.make_tag(text, Color(0.72, 0.72, 0.76), 0.02)
	if lbl:
		lbl.position = pos
		_components.add_child(lbl)

func _plate(size: Vector3) -> Node3D:
	var g := Node3D.new()
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = size + Vector3(0.05, 0.05, -0.01)
	frame.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.62, 0.60, 0.56)
	fmat.roughness = 0.7
	frame.material_override = fmat
	frame.position = Vector3(0, 0, -0.006)
	g.add_child(frame)
	var face := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	face.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.11, 0.14)
	mat.emission_enabled = true
	mat.emission = Color(0.10, 0.11, 0.14)
	mat.emission_energy_multiplier = 0.25
	face.material_override = mat
	g.add_child(face)
	return g

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
		
		# Frequency tag below each slider (framed board, R-027)
		var freq = fundamental_freq * harmonic_num
		var freq_label: Node3D = BakedText.make_tag("%d Hz" % int(freq), Color(0.72, 0.72, 0.76), 0.015)
		if freq_label:
			freq_label.position = Vector3(x_pos, -0.17, 0.008)
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
		
		# Tag below button (framed board, R-027)
		var label: Node3D = BakedText.make_tag(preset_name, _P.TEXT_ON_DARK, 0.016)
		if label:
			label.position = Vector3(x_pos, BUTTON_ROW_Y - 0.038, 0.008)
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
	# Was a no-op stub, so a map token could never reach anything on this artifact. It now
	# reads exactly one key. An absent or unknown "machinery" leaves the shipped value alone,
	# which keeps every existing placement on the legacy path.
	if config_data.has("machinery"):
		var want: String = str(config_data["machinery"]).strip_edges().to_lower()
		if MACHINERIES.has(want) and want != machinery:
			machinery = want
			_build_machinery()

	# Second axis, same contract: an absent or unknown "waveform" leaves the shipped value
	# alone. The sliders check is the guard against running before _ready has built them —
	# apply_grid_config arrives call_deferred from the grid, but a fixture or a caller that
	# reached it earlier would otherwise index an empty array.
	if config_data.has("waveform"):
		var wf: String = str(config_data["waveform"]).strip_edges().to_lower()
		if WAVEFORMS.has(wf) and wf != waveform:
			waveform = wf
			if not sliders.is_empty():
				# Morph rather than snap: this is the same path a player's button press
				# takes, so a map that names a waveform gets the panel walking to it.
				set_preset(WAVEFORM_PRESET.get(waveform, "SINE"))


# ── MACHINERY ────────────────────────────────────────────────────────────────
# One axis, five moments, shared word for word with MarioSoundController and the seven
# promoted audio racks. Everything below runs AFTER the legacy _ready() body and lives
# inside one host node parented to this root (NOT to _components), so removing that single
# node restores the shipped scene exactly. Nothing here reads or writes the harmonics, the
# presets, the morph or the audio.

const MACH_HOST := "TimbreMachinery"
## The pale panel is 0.82 x 0.60 and sits at z = -0.008; the sliders, buttons and displays
## stand in front of it at z = +0.02. The body therefore lives at negative z.
const MACH_PANEL_W := 0.82
const MACH_PANEL_H := 0.60
const MACH_BACK := 0.030    # air between the panel's back face and the body
const MACH_PLATE := 0.018   # shell thickness
const MACH_COVER := 0.010   # blanking cover thickness, standing proud of the shell
## How far the body oversails the panel on each side. Sized deliberately generous: the panel
## is opaque and the sweep's camera sits at yaw 0.62 / pitch -0.26, so a body that only just
## cleared the panel would be hidden behind it from three quarters of that view. At 0.16 the
## shell reads as a 1.14 x 0.92 mass with a clear border showing all the way round.
const MACH_MARGIN := 0.16

var _mach_host: Node3D = null


func _build_machinery() -> void:
	if _mach_host != null and is_instance_valid(_mach_host):
		remove_child(_mach_host)
		_mach_host.queue_free()
	_mach_host = null
	if machinery == "none" or not MACHINERIES.has(machinery):
		return                       # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = MACH_HOST
	add_child(host)
	_mach_host = host

	var w: float = MACH_PANEL_W + MACH_MARGIN * 2.0
	var h: float = MACH_PANEL_H + MACH_MARGIN * 2.0
	var back: float = -MACH_BACK

	match machinery:
		"plate":
			_machinery_plate(host, w, h, back)
		"vacancy":
			_machinery_plate(host, w, h, back)
			_machinery_vacancy(host, w, h, back)
		"frame":
			_machinery_frame(host, w, h)
		"works":
			_machinery_works(host, w, h, back)
		_:
			pass


## PLATE — the machine as a SURFACE. One dark shell filling the space behind the pale panel
## and standing past it on every side, a lip proud of its edge, a lit strip along the foot.
## The sculptor acquires a front, and therefore a back you are not shown.
func _machinery_plate(host: Node3D, w: float, h: float, back: float) -> void:
	var shell: StandardMaterial3D = _mach_mat(Color(0.125, 0.130, 0.150), 0.72, 0.25)
	var lip: StandardMaterial3D = _mach_mat(Color(0.075, 0.078, 0.092), 0.62, 0.45)
	_mach_box(host, Vector3(0, 0, back - MACH_PLATE * 0.5), Vector3(w, h, MACH_PLATE), shell)
	_mach_box(host, Vector3(0, 0, back - MACH_PLATE - 0.005),
		Vector3(w + 0.030, h + 0.030, 0.010), lip)
	# The only emissive surface on the body, so it owns the brightest pixels in any frame the
	# sculptor appears in — "there is a machine, and it is powered" from across a room.
	_mach_box(host, Vector3(0, -h * 0.5 + 0.030, back + 0.006),
		Vector3(w * 0.66, 0.009, 0.008), _mach_lit(Color(0.20, 0.85, 1.0)))


## VACANCY — the machine as a FORMAT. Twelve panel positions in a 4 x 3 field; the left-hand
## column stays open where the eight harmonic sliders live, and the other nine take blanking
## covers in lighter metal with a screw at each end. What your hand can reach is shown as the
## small fitted subset of what the frame would accept.
func _machinery_vacancy(host: Node3D, w: float, h: float, back: float) -> void:
	var cover: StandardMaterial3D = _mach_mat(Color(0.215, 0.225, 0.250), 0.55, 0.38)
	var screw: StandardMaterial3D = _mach_mat(Color(0.42, 0.43, 0.46), 0.35, 0.75)
	var cols: int = 4
	var rows: int = 3
	var gap: float = 0.012
	var cw: float = w / float(cols)
	var ch: float = h / float(rows)
	var cn: float = back + MACH_COVER * 0.5
	for gx in range(cols):
		for gy in range(rows):
			if gx == 0:
				continue            # the harmonic column keeps its positions open
			var u: float = -w * 0.5 + (float(gx) + 0.5) * cw
			var v: float = -h * 0.5 + (float(gy) + 0.5) * ch
			_mach_box(host, Vector3(u, v, cn), Vector3(cw - gap, ch - gap, MACH_COVER), cover)
			for sx in [-1.0, 1.0]:
				var sf: float = float(sx)
				_mach_box(host, Vector3(u + sf * maxf(cw * 0.5 - gap - 0.014, 0.006), v,
					cn + MACH_COVER * 0.5), Vector3(0.009, 0.009, 0.006), screw)


## FRAME — the machine as INSTALLED EQUIPMENT. Two punched rails past the panel edges and two
## cross members over and under it; the middle stays open, so the room shows through where a
## shell would be. One unit among many, rackable, made to be pulled and replaced.
func _machinery_frame(host: Node3D, w: float, h: float) -> void:
	var rail: StandardMaterial3D = _mach_mat(Color(0.300, 0.310, 0.340), 0.42, 0.68)
	var hole: StandardMaterial3D = _mach_mat(Color(0.045, 0.045, 0.055), 0.85, 0.10)
	var rail_w: float = 0.050
	var depth: float = 0.085
	var cn: float = -0.042
	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		var ru: float = sf * (w * 0.5 + rail_w * 0.5 + 0.008)
		_mach_box(host, Vector3(ru, 0, cn), Vector3(rail_w, h + 0.11, depth), rail)
		for k in range(8):
			var hv: float = -h * 0.5 + (float(k) + 0.5) * (h / 8.0)
			_mach_box(host, Vector3(ru, hv, cn + depth * 0.5 - 0.005),
				Vector3(0.016, 0.016, 0.010), hole)
	var span: float = w + 2.0 * (rail_w + 0.014)
	for sy in [-1.0, 1.0]:
		var sg: float = float(sy)
		_mach_box(host, Vector3(0, sg * (h * 0.5 + 0.040), cn),
			Vector3(span, 0.040, depth * 0.85), rail)


## WORKS — the machine as CIRCUITRY. Three boards on standoffs behind the panel, the outer
## two set wide enough to stand clear of its edges, component blocks on their faces and wire
## runs crossing between them. No shell at all: the eight sliders stop pretending the sound
## comes from nowhere.
func _machinery_works(host: Node3D, w: float, h: float, back: float) -> void:
	var board: StandardMaterial3D = _mach_mat(Color(0.085, 0.230, 0.155), 0.62, 0.15)
	var stand: StandardMaterial3D = _mach_mat(Color(0.380, 0.390, 0.420), 0.40, 0.72)
	var part: StandardMaterial3D = _mach_mat(Color(0.100, 0.100, 0.120), 0.70, 0.20)
	var wire: StandardMaterial3D = _mach_mat(Color(0.620, 0.360, 0.160), 0.55, 0.45)
	var bn: float = back - 0.060
	var bw: float = w * 0.29
	var bh: float = h * 0.66
	for i in range(3):
		var off: float = -0.02
		if i == 1:
			off = 0.07
		var bu: float = w * (-0.335 + 0.335 * float(i))
		var bv: float = h * off
		_mach_box(host, Vector3(bu, bv, bn), Vector3(bw, bh, 0.007), board)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var fx: float = float(sx)
				var fy: float = float(sy)
				_mach_box(host, Vector3(bu + fx * (bw * 0.5 - 0.018),
					bv + fy * (bh * 0.5 - 0.018), bn + 0.026),
					Vector3(0.013, 0.013, 0.050), stand)
		for k in range(3):
			var kv: float = bv + bh * (0.28 - 0.28 * float(k))
			_mach_box(host, Vector3(bu - bw * 0.16 + bw * 0.16 * float(k), kv, bn + 0.015),
				Vector3(bw * 0.34, h * 0.055, 0.021), part)
	for wk in range(5):
		var wv: float = -h * 0.5 + h * (0.13 + 0.185 * float(wk))
		_mach_box(host, Vector3(0, wv, bn + 0.040), Vector3(w * 0.94, 0.007, 0.007), wire)
	for px in [-1.0, 1.0]:
		var pf: float = float(px)
		_mach_box(host, Vector3(pf * (w * 0.5 + 0.016), 0, bn + 0.032),
			Vector3(0.019, h * 0.92, 0.062), stand)


# ── machinery helpers ────────────────────────────────────────────────────────

func _mach_box(host: Node3D, centre: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	host.add_child(mi)


func _mach_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mach_lit(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 2.4
	return m
