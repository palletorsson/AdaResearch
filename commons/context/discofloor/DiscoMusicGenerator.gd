extends AudioStreamPlayer
class_name DiscoMusicGenerator

# Original Disco Music Generator
# Creates disco-inspired beats and melodies without using copyrighted material
# Perfect for the Array Disco Learning Game!

@export var bpm: float = 120.0
@export var volume: float = 0.7
@export var disco_enabled: bool = true

# Audio generation
var audio_generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var beat_count: int = 0
var time_position: float = 0.0

# Signals for beat synchronization
signal beat_pulse(beat_number: int)
signal disco_flourish_triggered()

# Disco elements
var kick_pattern: Array[bool] = [true, false, true, false]  # 4/4 beat
var hihat_pattern: Array[bool] = [false, true, false, true]
var bass_pattern: Array[int] = [0, 0, 3, 0, 0, 0, 3, 0]  # Bass line intervals

# Musical scales for disco melodies (in semitones from root)
var disco_scale: Array[int] = [0, 2, 4, 5, 7, 9, 11]  # Major scale
var funk_chords: Array[Array] = [
	[0, 4, 7],      # Major triad
	[5, 9, 0],      # IV chord
	[7, 11, 2],     # V chord
	[2, 5, 9]       # vi chord
]

# Synthesis parameters
var base_frequency: float = 110.0  # A2
var sample_rate: float = 44100.0  # Will be updated from AudioServer
var beat_duration: float

func _ready():
	print("🎵 Initializing Original Disco Music Generator 🕺")
	setup_audio_generation()
	calculate_timing()
	if disco_enabled:
		start_disco_music()

func setup_audio_generation():
	"""Setup audio stream generator for real-time synthesis"""
	audio_generator = AudioStreamGenerator.new()
	audio_generator.buffer_length = 0.1  # 100ms buffer
	
	# Get the actual sample rate from AudioServer (read-only property)
	sample_rate = AudioServer.get_mix_rate()
	
	stream = audio_generator
	volume_db = linear_to_db(volume)
	
	# Get playback stream
	play()
	playback = get_stream_playback()

func calculate_timing():
	"""Calculate beat timing from BPM"""
	beat_duration = 60.0 / bpm
	print("🎵 Disco tempo: ", bpm, " BPM (", beat_duration, "s per beat)")

func start_disco_music():
	"""Start generating disco music"""
	print("🎶 Starting original disco groove!")
	var timer = Timer.new()
	timer.wait_time = beat_duration / 4  # 16th note resolution
	timer.timeout.connect(_on_beat_timer)
	timer.autostart = true
	add_child(timer)

func _on_beat_timer():
	"""Generate audio for each beat subdivision"""
	if not disco_enabled or not playback:
		return
	
	var frames_to_fill = playback.get_frames_available()
	if frames_to_fill > 0:
		var audio_frames = generate_disco_audio(frames_to_fill)
		playback.push_buffer(audio_frames)

func generate_disco_audio(frame_count: int) -> PackedVector2Array:
	"""Generate original disco audio frames"""
	var frames = PackedVector2Array()
	frames.resize(frame_count)  # Each Vector2 is one stereo frame
	
	var samples_per_beat = sample_rate * beat_duration
	
	for i in range(frame_count):
		var sample_time = time_position + i / sample_rate
		var beat_position = fmod(sample_time / beat_duration, 4.0)
		var beat_index = int(beat_position)
		var beat_phase = beat_position - beat_index
		
		# Generate disco elements
		var kick_sample = generate_kick(beat_index, beat_phase)
		var hihat_sample = generate_hihat(beat_index, beat_phase)
		var bass_sample = generate_bass(sample_time)
		var melody_sample = generate_melody(sample_time)
		
		# Mix all elements
		var left_sample = kick_sample + hihat_sample + bass_sample * 0.6 + melody_sample * 0.4
		var right_sample = kick_sample + hihat_sample + bass_sample * 0.6 + melody_sample * 0.4
		
		# Apply gentle limiting
		left_sample = clamp(left_sample, -1.0, 1.0)
		right_sample = clamp(right_sample, -1.0, 1.0)
		
		# Store as Vector2 (left, right)
		frames[i] = Vector2(left_sample, right_sample)
	
	time_position += frame_count / sample_rate
	return frames

func generate_kick(beat_index: int, beat_phase: float) -> float:
	"""Generate kick drum on disco beats"""
	if not kick_pattern[beat_index]:
		return 0.0
	
	# Exponential decay envelope
	var envelope = exp(-beat_phase * 8.0)
	
	# Low frequency sine wave with pitch bend
	var freq = 60.0 * (1.0 - beat_phase * 0.5)  # Pitch drops
	var kick = sin(time_position * freq * 2.0 * PI) * envelope * 0.5
	
	return kick

func generate_hihat(beat_index: int, beat_phase: float) -> float:
	"""Generate hi-hat on off-beats"""
	if not hihat_pattern[beat_index]:
		return 0.0
	
	# Quick decay envelope
	var envelope = exp(-beat_phase * 20.0)
	
	# High frequency noise-like sound
	var noise = (randf() - 0.5) * 2.0
	var filtered_noise = noise * envelope * 0.2
	
	return filtered_noise

func generate_bass(sample_time: float) -> float:
	"""Generate disco bass line"""
	var measure_time = fmod(sample_time / beat_duration, 8.0)
	var bass_index = int(measure_time)
	var bass_phase = measure_time - bass_index
	
	if bass_index >= bass_pattern.size():
		return 0.0
	
	var bass_interval = bass_pattern[bass_index]
	if bass_interval == 0:
		return 0.0
	
	# Bass frequency
	var bass_freq = base_frequency * pow(2.0, bass_interval / 12.0)
	
	# Bass envelope (punchy attack, quick decay)
	var envelope = exp(-bass_phase * 3.0) * 0.8 + 0.2
	
	# Square wave for funky bass
	var bass = sign(sin(sample_time * bass_freq * 2.0 * PI)) * envelope * 0.3
	
	return bass

func generate_melody(sample_time: float) -> float:
	"""Generate disco melody line"""
	var melody_time = fmod(sample_time / beat_duration, 16.0)  # 4-bar phrase
	var note_duration = 0.5  # Half-beat notes
	var note_index = int(melody_time / note_duration)
	var note_phase = fmod(melody_time, note_duration) / note_duration
	
	# Simple disco melody pattern
	var melody_pattern = [0, 2, 4, 2, 0, 4, 2, 0, 2, 4, 6, 4, 2, 0, 2, 4]
	
	if note_index >= melody_pattern.size():
		return 0.0
	
	var scale_degree = melody_pattern[note_index]
	if scale_degree >= disco_scale.size():
		return 0.0
	
	var note_interval = disco_scale[scale_degree]
	var melody_freq = base_frequency * 2.0 * pow(2.0, note_interval / 12.0)  # One octave up
	
	# Envelope for melody notes
	var attack = min(note_phase * 10.0, 1.0)
	var decay = exp(-(note_phase - 0.1) * 2.0) if note_phase > 0.1 else 1.0
	var envelope = attack * decay
	
	# Sawtooth wave for bright disco lead
	var sawtooth = 2.0 * fmod(sample_time * melody_freq, 1.0) - 1.0
	var melody = sawtooth * envelope * 0.25
	
	return melody

# Public API for disco game integration
func set_disco_tempo(new_bpm: float):
	"""Change the disco tempo"""
	bpm = clamp(new_bpm, 80.0, 140.0)
	calculate_timing()
	print("🎵 Tempo changed to: ", bpm, " BPM")

func trigger_disco_break():
	"""Trigger a disco break/bridge section"""
	print("🕺 DISCO BREAK! 💃")
	# Could modify patterns here for breaks

func add_disco_flourish():
	"""Add a musical flourish for special moments"""
	print("✨ Disco flourish! ✨")
	disco_flourish_triggered.emit()

func toggle_disco_music():
	"""Toggle disco music on/off"""
	disco_enabled = !disco_enabled
	if disco_enabled:
		print("🎵 Disco music: ON")
		volume_db = linear_to_db(volume)
	else:
		print("🎵 Disco music: OFF")
		volume_db = -80.0  # Mute

func set_disco_volume(new_volume: float):
	"""Set disco music volume (0.0 to 1.0)"""
	volume = clamp(new_volume, 0.0, 1.0)
	volume_db = linear_to_db(volume)
	print("🔊 Disco volume: ", int(volume * 100), "%")

# Integration with Array Disco Game
func sync_with_array_pattern(pattern_name: String):
	"""Sync music with array learning patterns"""
	match pattern_name:
		"CORNER_BLINK":
			set_disco_tempo(100.0)  # Slower for learning
		"SNAKE_PATTERN":
			set_disco_tempo(130.0)  # Faster for dynamic pattern
		"DISCO_CELEBRATION":
			set_disco_tempo(125.0)  # Perfect disco tempo
			add_disco_flourish()
		_:
			set_disco_tempo(120.0)  # Default tempo

func create_beat_sync_signal():
	"""Emit beat pulse signal for synchronization with visuals"""
	var current_beat = get_current_beat()
	beat_pulse.emit(current_beat)

func get_current_beat() -> int:
	"""Get current beat number for synchronization"""
	return int(time_position / beat_duration) % 4

# Disco music info for debugging
func print_disco_info():
	"""Print current disco music information"""
	print("=== DISCO MUSIC INFO ===")
	print("BPM: ", bpm)
	print("Volume: ", int(volume * 100), "%")
	print("Beat duration: ", beat_duration, "s")
	print("Current beat: ", get_current_beat())
	print("Disco enabled: ", disco_enabled)
	print("Sample rate: ", sample_rate)
	print("========================")

# Advanced features for educational integration
func set_educational_mode(enabled: bool):
	"""Set educational mode with gentler sounds"""
	if enabled:
		# Softer volumes for classroom use
		volume = 0.4
		set_disco_volume(volume)
		print("🎓 Educational mode: ON (quieter)")
	else:
		volume = 0.7
		set_disco_volume(volume)
		print("🕺 Party mode: ON (louder)")

func sync_with_lesson_phase(lesson_phase: String):
	"""Sync music with specific lesson phases"""
	match lesson_phase:
		"introduction":
			set_disco_tempo(90.0)   # Very slow for introduction
		"learning":
			set_disco_tempo(110.0)  # Medium for active learning
		"practice":
			set_disco_tempo(120.0)  # Normal for practice
		"celebration":
			set_disco_tempo(130.0)  # Fast for celebration
			add_disco_flourish()
		_:
			set_disco_tempo(120.0)

func create_custom_pattern(kick: Array[bool], hihat: Array[bool], bass: Array[int]):
	"""Allow custom rhythm patterns for advanced users"""
	if kick.size() == 4:
		kick_pattern = kick
	if hihat.size() == 4:
		hihat_pattern = hihat
	if bass.size() == 8:
		bass_pattern = bass
	print("🎵 Custom disco pattern applied!")

func get_musical_info() -> Dictionary:
	"""Get current musical information for debugging/display"""
	return {
		"bpm": bpm,
		"volume": volume,
		"beat_duration": beat_duration,
		"current_beat": get_current_beat(),
		"sample_rate": sample_rate,
		"disco_enabled": disco_enabled,
		"kick_pattern": kick_pattern,
		"hihat_pattern": hihat_pattern,
		"bass_pattern": bass_pattern
	}
