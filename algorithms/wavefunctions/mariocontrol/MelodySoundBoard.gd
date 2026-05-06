extends Node3D

## Melody Sound Board - Spatial Musical Instrument
## Positions musical notes in 3D space and plays melodies by moving through them
## Similar to vowel_sound_board but for musical tones instead of phonemes

@onready var mapper = $ValueMapper3D
@onready var audio_player = $AudioStreamPlayer3D
@onready var label_note = $LabelNote

# --- Editor Selection ---
@export_enum("None", "C Major Scale", "Twinkle Twinkle", "Ode to Joy", "Mario Theme", "Pentatonic Jam", "Chromatic Run") var melody_selection: String = "C Major Scale"
@export var is_ambient_enabled: bool = true
@export var repeat_interval: float = 2.0
@export var tempo_bpm: float = 120.0  # Beats per minute

# Sound Parameters
@export var base_octave: int = 4  # Middle C octave
@export var hardness: float = 0.3  # Harmonic content (0-1)
@export var ring_time: float = 0.8  # Note sustain

# Space Configuration - Notes laid out in pitch space
# X = Chromatic position (0-11 semitones)
# Y = Octave offset (-1 to +1)
# Z = Intensity/Volume (0-1)
const SPACE_X_MIN = 0.0
const SPACE_X_MAX = 12.0  # One octave of semitones
const SPACE_Y_MIN = -1.0
const SPACE_Y_MAX = 1.0   # Octave range
const SPACE_Z_MIN = 0.0
const SPACE_Z_MAX = 1.0

# Note anchors - semitone positions in chromatic space
# Position is Vector3(semitone, octave_offset, default_intensity)
const NOTE_ANCHORS = {
	"C": Vector3(0, 0, 0.8),
	"C#": Vector3(1, 0, 0.7),
	"D": Vector3(2, 0, 0.8),
	"D#": Vector3(3, 0, 0.7),
	"E": Vector3(4, 0, 0.8),
	"F": Vector3(5, 0, 0.8),
	"F#": Vector3(6, 0, 0.7),
	"G": Vector3(7, 0, 0.8),
	"G#": Vector3(8, 0, 0.7),
	"A": Vector3(9, 0, 0.8),
	"A#": Vector3(10, 0, 0.7),
	"B": Vector3(11, 0, 0.8),
}

# Frequency table (A4 = 440Hz standard)
const A4_FREQ = 440.0
const SAMPLE_RATE = 44100

# Playback state
var is_playing_sequence: bool = false
var _beat_duration: float = 0.5

# Visual elements
var note_markers: Dictionary = {}
var melody_trail: Array[Vector3] = []

func _ready() -> void:
	_beat_duration = 60.0 / tempo_bpm

	# Configure mapper for pitch space
	mapper.output_x_min = SPACE_X_MIN
	mapper.output_x_max = SPACE_X_MAX
	mapper.output_y_min = SPACE_Y_MIN
	mapper.output_y_max = SPACE_Y_MAX
	mapper.output_z_min = SPACE_Z_MIN
	mapper.output_z_max = SPACE_Z_MAX

	mapper.label_x = "Semitone"
	mapper.label_y = "Octave"
	mapper.label_z = "Volume"

	mapper.values_changed.connect(_on_mapper_changed)

	if label_note:
		label_note.text = ""

	_spawn_note_markers()
	_start_ambient_loop()

func apply_grid_config(data: Dictionary) -> void:
	if data.has("melody"):
		is_ambient_enabled = false
		var melody = str(data["melody"]).to_lower().replace(" ", "")
		var should_repeat = str(data.get("repeat", "false")).to_lower() == "true"

		await get_tree().create_timer(0.5).timeout

		if should_repeat:
			while not is_ambient_enabled:
				await play_melody(melody)
				await get_tree().create_timer(repeat_interval).timeout
		else:
			await play_melody(melody)

	if data.has("tempo"):
		tempo_bpm = float(data["tempo"])
		_beat_duration = 60.0 / tempo_bpm

	if data.has("octave"):
		base_octave = int(data["octave"])

func _start_ambient_loop() -> void:
	await get_tree().create_timer(1.0).timeout
	while true:
		if not is_inside_tree(): return
		if not is_ambient_enabled:
			await get_tree().create_timer(1.0).timeout
			continue

		if melody_selection != "None":
			var melody_key = melody_selection.to_lower().replace(" ", "")
			await play_melody(melody_key)
			await get_tree().create_timer(repeat_interval).timeout
		else:
			await get_tree().create_timer(1.0).timeout

func play_melody(melody: String) -> void:
	if is_playing_sequence: return
	is_playing_sequence = true

	match melody:
		"cmajorscale": await _play_c_major_scale()
		"twinkletwinkle": await _play_twinkle_twinkle()
		"odetojoy": await _play_ode_to_joy()
		"mariotheme": await _play_mario_theme()
		"pentatonicjam": await _play_pentatonic_jam()
		"chromaticrun": await _play_chromatic_run()

	is_playing_sequence = false

# --- Melody Implementations ---

func _play_c_major_scale() -> void:
	var scale_notes = ["C", "D", "E", "F", "G", "A", "B", "C"]
	var octaves = [0, 0, 0, 0, 0, 0, 0, 1]

	for i in range(scale_notes.size()):
		await _play_note(scale_notes[i], octaves[i], 1.0)

	# Descend
	for i in range(scale_notes.size() - 2, -1, -1):
		await _play_note(scale_notes[i], octaves[i], 1.0)

func _play_twinkle_twinkle() -> void:
	# Twinkle Twinkle Little Star melody
	var notes = [
		["C", 0, 1], ["C", 0, 1], ["G", 0, 1], ["G", 0, 1],
		["A", 0, 1], ["A", 0, 1], ["G", 0, 2],
		["F", 0, 1], ["F", 0, 1], ["E", 0, 1], ["E", 0, 1],
		["D", 0, 1], ["D", 0, 1], ["C", 0, 2],
	]

	for n in notes:
		await _play_note(n[0], n[1], n[2])

func _play_ode_to_joy() -> void:
	# Beethoven's Ode to Joy (simplified)
	var notes = [
		["E", 0, 1], ["E", 0, 1], ["F", 0, 1], ["G", 0, 1],
		["G", 0, 1], ["F", 0, 1], ["E", 0, 1], ["D", 0, 1],
		["C", 0, 1], ["C", 0, 1], ["D", 0, 1], ["E", 0, 1],
		["E", 0, 1.5], ["D", 0, 0.5], ["D", 0, 2],
	]

	for n in notes:
		await _play_note(n[0], n[1], n[2])

func _play_mario_theme() -> void:
	# Super Mario Bros theme (opening)
	var notes = [
		["E", 0, 0.5], ["E", 0, 0.5], ["E", 0, 1],
		["C", 0, 0.5], ["E", 0, 1], ["G", 0, 2],
		["G", -1, 2],
	]

	for n in notes:
		await _play_note(n[0], n[1], n[2])

func _play_pentatonic_jam() -> void:
	# Pentatonic scale improvisation
	var penta = ["C", "D", "E", "G", "A"]

	for _i in range(16):
		var note = penta[randi() % penta.size()]
		var octave = [-1, 0, 0, 0, 1][randi() % 5]
		var dur = [0.5, 0.5, 1.0, 1.0][randi() % 4]
		await _play_note(note, octave, dur)

func _play_chromatic_run() -> void:
	# Chromatic scale run up and down
	var chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

	for note in chromatic:
		await _play_note(note, 0, 0.25)
	await _play_note("C", 1, 1.0)

	for i in range(chromatic.size() - 1, -1, -1):
		await _play_note(chromatic[i], 0, 0.25)

# --- Core Note Playing ---

func _play_note(note_name: String, octave_offset: int = 0, beat_count: float = 1.0) -> void:
	if not NOTE_ANCHORS.has(note_name):
		push_warning("Unknown note: %s" % note_name)
		return

	var anchor = NOTE_ANCHORS[note_name]
	var target_pos = Vector3(anchor.x, anchor.y + octave_offset, anchor.z)

	# Update label
	if label_note:
		var octave_str = str(base_octave + octave_offset)
		label_note.text = note_name + octave_str

	# Move mapper to note position
	_tween_mapper(target_pos, 0.05)
	await get_tree().create_timer(0.05).timeout

	# Play the tone
	_trigger_tone(note_name, octave_offset, anchor.z)
	_highlight_note_marker(note_name)

	# Hold for duration
	await get_tree().create_timer(_beat_duration * beat_count * 0.9).timeout

	# Brief silence between notes
	await get_tree().create_timer(_beat_duration * beat_count * 0.1).timeout

func _trigger_tone(note_name: String, octave_offset: int, intensity: float) -> void:
	var semitone = NOTE_ANCHORS[note_name].x
	var freq = _semitone_to_freq(semitone, base_octave + octave_offset)

	var stream = _generate_sine_bell(freq, intensity)
	audio_player.stream = stream
	audio_player.play()

func _semitone_to_freq(semitone: float, octave: int) -> float:
	# A4 = 440Hz is semitone 9 in octave 4
	var semitones_from_a4 = (octave - 4) * 12 + (semitone - 9)
	return A4_FREQ * pow(2.0, semitones_from_a4 / 12.0)

func _generate_sine_bell(freq: float, intensity: float) -> AudioStreamWAV:
	var duration = ring_time
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count

		# Exponential decay envelope
		var env = exp(-progress * (5.0 / ring_time))

		# Fundamental + harmonics based on hardness
		var sample_value = sin(2.0 * PI * freq * t) * env * 0.4
		if hardness > 0.1:
			sample_value += sin(4.0 * PI * freq * t) * env * hardness * 0.15
		if hardness > 0.3:
			sample_value += sin(6.0 * PI * freq * t) * env * hardness * 0.08

		sample_value *= intensity

		var sample_int = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

# --- Mapper Interface ---

func _on_mapper_changed(_semitone: float, octave_offset: float, intensity: float) -> void:
	# Could trigger notes based on position for interactive play
	pass

func _tween_mapper(target: Vector3, duration: float) -> void:
	var tween = create_tween()
	var start_val = mapper.get_values()

	var update_lambda = func(val: float):
		var cur_x = lerp(start_val.x, target.x, val)
		var cur_y = lerp(start_val.y, target.y, val)
		var cur_z = lerp(start_val.z, target.z, val)
		mapper.set_values(cur_x, cur_y, cur_z)

	tween.tween_method(update_lambda, 0.0, 1.0, duration)
	await tween.finished

# --- Visual Feedback ---

func _spawn_note_markers() -> void:
	var white_notes = ["C", "D", "E", "F", "G", "A", "B"]
	var black_notes = ["C#", "D#", "F#", "G#", "A#"]

	for note_name in NOTE_ANCHORS:
		var anchor = NOTE_ANCHORS[note_name]

		# Normalize to mapper space
		var norm_x = (anchor.x - SPACE_X_MIN) / (SPACE_X_MAX - SPACE_X_MIN)
		var norm_y = (anchor.y - SPACE_Y_MIN) / (SPACE_Y_MAX - SPACE_Y_MIN)
		var norm_z = 0.5

		var pos = Vector3(
			norm_x * mapper.space_size.x,
			norm_y * mapper.space_size.y,
			norm_z * mapper.space_size.z
		)

		# Create marker mesh
		var marker = MeshInstance3D.new()
		var box = BoxMesh.new()

		var is_black = note_name in black_notes
		box.size = Vector3(0.04, 0.04, 0.04) if is_black else Vector3(0.05, 0.05, 0.05)
		marker.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.2) if is_black else Color(0.9, 0.9, 0.85)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.2
		marker.material_override = mat
		marker.position = pos
		marker.name = "NoteMarker_" + note_name

		mapper.add_child(marker)
		note_markers[note_name] = marker

		# Add label
		var lbl = Label3D.new()
		lbl.text = note_name
		lbl.font_size = 18
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = pos + Vector3(0, -0.06, 0)
		lbl.scale = Vector3.ONE * 0.05
		lbl.modulate = Color(0.3, 0.3, 0.3) if is_black else Color(0.1, 0.1, 0.1)
		mapper.add_child(lbl)

func _highlight_note_marker(note_name: String) -> void:
	if not note_markers.has(note_name):
		return

	var marker = note_markers[note_name]
	var mat = marker.material_override as StandardMaterial3D
	if not mat:
		return

	# Flash the note
	var original_emission = mat.emission
	var tween = create_tween()
	tween.tween_property(mat, "emission", Color(1, 0.8, 0.3) * 2.0, 0.05)
	tween.tween_property(mat, "emission", original_emission, 0.3)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

