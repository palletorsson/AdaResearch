extends Node3D

# Singing Board - Extension of VowelSoundBoard for Melodic Singing
# Uses the existing vowel_synth for real-time formant synthesis
# Adds pitch control, vibrato, and melody sequencing

@onready var mapper = $ValueMapper3D
@onready var synth = $VowelSynth3D
@onready var label_word = $LabelWord

# --- Editor Selection ---
@export_enum("None", "Scale", "Ode To Joy", "Twinkle", "La La La", "Ada Melody", "I Feel Love", "Custom") var melody_selection: String = "Scale"
@export var base_pitch: float = 220.0  # A3
@export var tempo_bpm: float = 120.0
@export var vibrato_enabled: bool = true
@export var vibrato_rate: float = 5.5  # Hz
@export var vibrato_depth: float = 0.015  # Semitones as ratio
@export var is_looping: bool = true

# Field Constraints (from VowelSoundBoard)
const F1_MIN = 200.0
const F1_MAX = 900.0
const DELTA_MIN = 200.0
const DELTA_MAX = 2200.0

# Vowel Anchors (F1, Delta)
const ANCHORS = {
	"i": Vector2(240, 2160),
	"e": Vector2(390, 1910),
	"a": Vector2(850, 760),
	"o": Vector2(360, 280),
	"u": Vector2(250, 345),
	"r": Vector2(450, 750),
}

# Playback State
var is_singing: bool = false
var _vibrato_phase: float = 0.0

# Pre-defined Melodies
# Format: [{"pitch": semitones_from_base, "duration": beats, "vowel": "a", "consonant": ""}]
const MELODIES = {
	"scale": [
		{"pitch": 0, "duration": 1, "vowel": "a"},
		{"pitch": 2, "duration": 1, "vowel": "a"},
		{"pitch": 4, "duration": 1, "vowel": "a"},
		{"pitch": 5, "duration": 1, "vowel": "a"},
		{"pitch": 7, "duration": 1, "vowel": "a"},
		{"pitch": 9, "duration": 1, "vowel": "a"},
		{"pitch": 11, "duration": 1, "vowel": "a"},
		{"pitch": 12, "duration": 2, "vowel": "a"},
	],
	"ode_to_joy": [
		{"pitch": 4, "duration": 1, "vowel": "a"},
		{"pitch": 4, "duration": 1, "vowel": "a"},
		{"pitch": 5, "duration": 1, "vowel": "a"},
		{"pitch": 7, "duration": 1, "vowel": "a"},
		{"pitch": 7, "duration": 1, "vowel": "a"},
		{"pitch": 5, "duration": 1, "vowel": "a"},
		{"pitch": 4, "duration": 1, "vowel": "a"},
		{"pitch": 2, "duration": 1, "vowel": "e"},
		{"pitch": 0, "duration": 1, "vowel": "o"},
		{"pitch": 0, "duration": 1, "vowel": "o"},
		{"pitch": 2, "duration": 1, "vowel": "o"},
		{"pitch": 4, "duration": 1, "vowel": "a"},
		{"pitch": 4, "duration": 1.5, "vowel": "a"},
		{"pitch": 2, "duration": 0.5, "vowel": "a"},
		{"pitch": 2, "duration": 2, "vowel": "a"},
	],
	"twinkle": [
		{"pitch": 0, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 0, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 7, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 7, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 9, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 9, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 7, "duration": 2, "vowel": "a"},
		{"pitch": 5, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 5, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 4, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 4, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 2, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 2, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 0, "duration": 2, "vowel": "a"},
	],
	"la_la_la": [
		{"pitch": 0, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 2, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 4, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 5, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 7, "duration": 1, "vowel": "a", "consonant": "l"},
		{"pitch": 7, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 5, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 4, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 2, "duration": 0.5, "vowel": "a", "consonant": "l"},
		{"pitch": 0, "duration": 2, "vowel": "a"},
	],
	"ada_melody": [
		# "A" on A
		{"pitch": 0, "duration": 0.75, "vowel": "a"},
		# "da" going up
		{"pitch": 2, "duration": 0.25, "vowel": "a", "consonant": "d"},
		{"pitch": 4, "duration": 1, "vowel": "a"},
		# Rest
		{"pitch": 0, "duration": 0.5, "vowel": "a", "intensity": 0},
		# "Re" 
		{"pitch": 5, "duration": 0.5, "vowel": "e", "consonant": "r"},
		# "search"
		{"pitch": 7, "duration": 1.5, "vowel": "e"},
		{"pitch": 5, "duration": 0.5, "vowel": "r"},
	],
	"i_feel_love": [
		# Donna Summer / Giorgio Moroder - hypnotic disco vocal
		# "I..."
		{"pitch": 0, "duration": 1.5, "vowel": "i"},
		# Rest
		{"pitch": 0, "duration": 0.5, "vowel": "a", "intensity": 0},
		# "feel..."
		{"pitch": 0, "duration": 0.5, "vowel": "i", "consonant": "f"},
		{"pitch": -2, "duration": 1.0, "vowel": "e"},
		# Rest
		{"pitch": 0, "duration": 0.5, "vowel": "a", "intensity": 0},
		# "love..."
		{"pitch": -4, "duration": 0.5, "vowel": "u", "consonant": "l"},
		{"pitch": -5, "duration": 1.5, "vowel": "u"},
		# Rest before repeat
		{"pitch": 0, "duration": 1.0, "vowel": "a", "intensity": 0},
		# Second phrase - slightly varied
		# "I..."
		{"pitch": 0, "duration": 1.0, "vowel": "i"},
		# "feel..."
		{"pitch": 0, "duration": 0.5, "vowel": "i", "consonant": "f"},
		{"pitch": -2, "duration": 0.5, "vowel": "e"},
		{"pitch": -3, "duration": 0.5, "vowel": "e"},
		# "love..."
		{"pitch": -5, "duration": 0.5, "vowel": "u", "consonant": "l"},
		{"pitch": -4, "duration": 2.0, "vowel": "u"},
	],
}

func _ready():
	# Configure Mapper Range
	mapper.output_x_min = DELTA_MIN
	mapper.output_x_max = DELTA_MAX
	mapper.output_y_min = F1_MIN
	mapper.output_y_max = F1_MAX
	mapper.output_z_min = 0.0
	mapper.output_z_max = 1.0
	
	mapper.values_changed.connect(_on_mapper_changed)
	label_word.text = "♪"
	
	# Start melody loop
	_start_melody_loop()


func _process(delta: float):
	# Apply vibrato to pitch
	if vibrato_enabled and is_singing:
		_vibrato_phase += delta * vibrato_rate * TAU
		var vibrato_mod = sin(_vibrato_phase) * vibrato_depth
		# Vibrato modulates the current pitch
		# (Applied in _sing_note instead for cleaner control)


func _start_melody_loop():
	await get_tree().create_timer(1.0).timeout
	while true:
		if not is_inside_tree(): return
		
		if melody_selection != "None":
			var melody_key = melody_selection.to_lower().replace(" ", "_")
			if MELODIES.has(melody_key):
				await sing_melody(MELODIES[melody_key])
			
			if is_looping:
				await get_tree().create_timer(1.0).timeout
			else:
				await get_tree().create_timer(3.0).timeout
		else:
			await get_tree().create_timer(1.0).timeout


func sing_melody(melody: Array):
	"""Sing a melody sequence"""
	is_singing = true
	var beat_duration = 60.0 / tempo_bpm
	
	for note in melody:
		var pitch_semitones = note.get("pitch", 0)
		var duration_beats = note.get("duration", 1)
		var vowel = note.get("vowel", "a")
		var consonant = note.get("consonant", "")
		var intensity = note.get("intensity", 1.0)
		
		var note_duration = duration_beats * beat_duration
		var freq = base_pitch * pow(2.0, pitch_semitones / 12.0)
		
		label_word.text = consonant + vowel
		
		await _sing_note(freq, vowel, consonant, note_duration, intensity)
	
	# End
	_tween_mapper(ANCHORS["a"], 0.0, 0.1)
	await get_tree().create_timer(0.2).timeout
	synth.stop()
	is_singing = false


func _sing_note(freq: float, vowel: String, consonant: String, duration: float, intensity: float = 1.0):
	"""Sing a single note with optional consonant onset"""
	
	# Set pitch
	synth.pulse_hz = freq
	
	# Handle consonant onset
	if consonant != "":
		match consonant.to_lower():
			"l":
				synth.trigger_nasal("l", 50)
				await get_tree().create_timer(0.03).timeout
			"m":
				synth.trigger_nasal("m", 80)
				await get_tree().create_timer(0.05).timeout
			"n":
				synth.trigger_nasal("n", 60)
				await get_tree().create_timer(0.04).timeout
			"d":
				synth.trigger_plosive("d")
				await get_tree().create_timer(0.05).timeout
			"b":
				synth.trigger_plosive("b")
				await get_tree().create_timer(0.05).timeout
			"r":
				# R is a vowel-like approximant
				_tween_mapper(ANCHORS["r"], intensity * 0.5, 0.03)
				await get_tree().create_timer(0.03).timeout
			"s":
				synth.trigger_fricative("s", 80)
				await get_tree().create_timer(0.05).timeout
			"f":
				synth.trigger_fricative("f", 60)
				await get_tree().create_timer(0.04).timeout
			"h":
				synth.trigger_fricative("h", 40)
				await get_tree().create_timer(0.03).timeout
	
	# Skip if rest
	if intensity <= 0:
		await get_tree().create_timer(duration).timeout
		return
	
	# Get vowel anchor
	var vowel_anchor = ANCHORS.get(vowel, ANCHORS["a"])
	
	# Attack
	_tween_mapper(vowel_anchor, intensity, 0.05)
	
	# Sustain with vibrato
	var sustain_time = duration - 0.1  # Leave room for release
	if sustain_time > 0:
		if vibrato_enabled:
			await _sustain_with_vibrato(freq, sustain_time)
		else:
			await get_tree().create_timer(sustain_time).timeout
	
	# Quick release for legato
	_tween_mapper(vowel_anchor, intensity * 0.3, 0.05)


func _sustain_with_vibrato(base_freq: float, duration: float):
	"""Sustain a note with pitch vibrato"""
	var elapsed = 0.0
	var step = 0.016  # ~60fps
	
	while elapsed < duration:
		var vib = sin(_vibrato_phase) * vibrato_depth
		synth.pulse_hz = base_freq * (1.0 + vib)
		_vibrato_phase += step * vibrato_rate * TAU
		
		await get_tree().create_timer(step).timeout
		elapsed += step


# --- Core Functions (from VowelSoundBoard) ---

func _on_mapper_changed(delta_val: float, f1_val: float, intensity_val: float):
	synth.f1 = f1_val
	synth.delta = delta_val
	synth.target_intensity = intensity_val
	synth.is_speaking = (intensity_val > 0.01)


func _set_mapper_pos(target_field: Vector2, target_intensity: float):
	mapper.set_values(target_field.y, target_field.x, target_intensity)


func _tween_mapper(target_field: Vector2, target_intensity: float, duration: float):
	var tween = create_tween()
	var start_val = mapper.get_values()
	var update_lambda = func(val: float):
		var cur_delta = lerp(start_val.x, target_field.y, val)
		var cur_f1 = lerp(start_val.y, target_field.x, val)
		var cur_int = lerp(start_val.z, target_intensity, val)
		mapper.set_values(cur_delta, cur_f1, cur_int)
	tween.tween_method(update_lambda, 0.0, 1.0, duration)
	await tween.finished


# --- Custom Melody API ---

func sing_custom(notes: Array):
	"""
	Sing a custom melody.
	Format: [{"pitch": semitones, "duration": beats, "vowel": "a", "consonant": "l"}, ...]
	"""
	await sing_melody(notes)


func sing_text(text: String, pitches: Array = []):
	"""
	Attempt to sing text with given pitches.
	If no pitches provided, uses a simple ascending pattern.
	"""
	var syllables = _text_to_syllables(text)
	var melody = []
	
	for i in range(syllables.size()):
		var syl = syllables[i]
		var pitch = pitches[i] if i < pitches.size() else (i * 2) % 12
		melody.append({
			"pitch": pitch,
			"duration": 0.5,
			"vowel": syl.get("vowel", "a"),
			"consonant": syl.get("consonant", "")
		})
	
	await sing_melody(melody)


func _text_to_syllables(text: String) -> Array:
	"""Simple text to syllable parser"""
	var syllables = []
	var vowels_list = ["a", "e", "i", "o", "u"]
	var current_consonant = ""
	
	for c in text.to_lower():
		if c in vowels_list:
			syllables.append({
				"consonant": current_consonant,
				"vowel": c
			})
			current_consonant = ""
		elif c.is_valid_identifier():
			current_consonant = c
	
	return syllables
