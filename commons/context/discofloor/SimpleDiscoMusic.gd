extends AudioStreamPlayer
class_name SimpleDiscoMusic

# Enhanced Disco Music Generator - AUTHENTIC DISCO VIBES! 🕺✨
# Creates disco-inspired beats with classic disco elements:
# - 4-on-the-floor kick pattern
# - Funky syncopated bass lines  
# - Lush string sections
# - Piano/chord stabs
# - Classic disco groove

@export var bpm: float = 120.0
@export var volume: float = 0.6
@export var disco_enabled: bool = true
@export var disco_style: String = "classic"  # classic, funk, eurobeat

# Audio generation
var audio_generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var time_position: float = 0.0

# AUTHENTIC DISCO PATTERNS! 🎵
# Classic 4-on-the-floor disco kick (every beat)
var kick_pattern: Array[bool] = [true, true, true, true]

# Disco hi-hat pattern (8th notes with emphasis on off-beats) - REMOVED METRONOME SOUND
var hihat_pattern: Array[float] = [0.0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, 0.1]  # Much more subtle, less frequent

# FUNKY DISCO BASS LINE! (2-bar pattern with syncopation)
var bass_pattern: Array[Dictionary] = [
	{"note": 0, "accent": 1.0},    # Root - strong
	{"note": -1, "accent": 0.0},   # Rest
	{"note": 0, "accent": 0.6},    # Root - medium  
	{"note": 3, "accent": 0.8},    # Third - strong
	{"note": -1, "accent": 0.0},   # Rest
	{"note": 5, "accent": 0.7},    # Fifth - strong
	{"note": 3, "accent": 0.5},    # Third - light
	{"note": 0, "accent": 0.9},    # Root - very strong
]

# DISCO STRING CHORDS! (lush and sustained)
var string_chords: Array[Array] = [
	[0, 4, 7, 11],      # CMaj7
	[5, 9, 0, 4],       # FMaj7  
	[7, 11, 2, 5],      # G7
	[0, 4, 7, 11],      # CMaj7
]

# PIANO STAB PATTERN! (classic disco piano hits)
var piano_pattern: Array[float] = [0.0, 0.8, 0.0, 0.0, 0.0, 0.9, 0.0, 0.7]  # Syncopated stabs

# Musical scales and harmony
var disco_scale: Array[int] = [0, 2, 4, 5, 7, 9, 11]  # Major scale
var chord_progression: Array[int] = [0, 5, 7, 0]  # I-vi-V-I (classic disco)

# Enhanced synthesis parameters
var base_frequency: float = 65.4  # C2 (disco bass range)
var sample_rate: float = 44100.0
var beat_duration: float
var beat_counter: int = 0
var bar_counter: int = 0

# Audio processing
var low_pass_filter: float = 1.0
var groove_swing: float = 0.1  # Disco groove timing

# EXTREME LO-FI PROCESSING! 🌊📼
var lofi_enabled: bool = true
var bit_crush_factor: float = 6.0  # Reduced from 8.0 - less aggressive crushing
var sample_rate_crush: float = 12000.0  # Increased from 8000.0 - less harsh
var tape_saturation: float = 0.6  # Reduced from 0.8 - gentler saturation
var vinyl_crackle_intensity: float = 0.2  # Reduced from 0.3 - less crackle
var underwater_depth: float = 0.8  # Reduced from 0.9 - less extreme
var pitch_wobble_amount: float = 0.015  # Reduced from 0.02 - less wobble
var reverb_decay: float = 0.8  # Reduced from 0.85 - less reverb buildup
var lo_pass_frequency: float = 1200.0  # Increased from 800.0 - less muffled

# Lo-fi state variables
var crackle_state: float = 0.0
var wobble_phase: float = 0.0
var reverb_buffer: Array[float] = []
var reverb_index: int = 0

func _ready():
	print("🌊 Initializing EXTREME LO-FI DROWNED Disco - Underwater vibes! 📼✨")
	setup_audio_generation()
	setup_lofi_processing()
	calculate_timing()
	if disco_enabled:
		start_disco_music()

func setup_audio_generation():
	"""Setup audio stream generator for real-time disco synthesis"""
	audio_generator = AudioStreamGenerator.new()
	audio_generator.buffer_length = 0.05  # Smaller buffer for better timing
	
	sample_rate = AudioServer.get_mix_rate()
	
	stream = audio_generator
	volume_db = linear_to_db(volume)
	
	play()
	playback = get_stream_playback()

func setup_lofi_processing():
	"""Setup lo-fi processing buffers and effects"""
	# Initialize reverb buffer for underwater effect (0.5 second delay)
	var reverb_size = int(sample_rate * 0.5)
	reverb_buffer.resize(reverb_size)
	for i in range(reverb_size):
		reverb_buffer[i] = 0.0
	
	print("🌊 Lo-fi underwater processing initialized!")
	print("📼 Bit depth: ", int(bit_crush_factor), " bits")
	print("🎵 Sample rate crush: ", sample_rate_crush, " Hz")
	print("💧 Underwater depth: ", int(underwater_depth * 100), "%")

func calculate_timing():
	"""Calculate disco timing with groove"""
	beat_duration = 60.0 / bpm
	print("🎵 Disco groove at: ", bpm, " BPM (", beat_duration, "s per beat)")

func start_disco_music():
	"""Start the disco party! 🎉"""
	print("🎶 Starting authentic disco groove! Let's boogie! 🕺")
	var timer = Timer.new()
	timer.wait_time = beat_duration / 8  # Higher resolution for groove
	timer.timeout.connect(_on_beat_timer)
	timer.autostart = true
	add_child(timer)

func _on_beat_timer():
	"""Generate groovy disco audio"""
	if not disco_enabled or not playback:
		return
	
	var frames_to_fill = playback.get_frames_available()
	if frames_to_fill > 0:
		var audio_frames = generate_disco_audio(frames_to_fill)
		playback.push_buffer(audio_frames)

func generate_disco_audio(frame_count: int) -> PackedVector2Array:
	"""Generate AUTHENTIC disco audio with all the classic elements! 🎵"""
	var frames = PackedVector2Array()
	frames.resize(frame_count)
	
	for i in range(frame_count):
		var sample_time = time_position + i / sample_rate
		var beat_position = fmod(sample_time / beat_duration, 4.0)
		var eighth_position = fmod(sample_time / (beat_duration * 0.5), 8.0)
		var bar_position = fmod(sample_time / (beat_duration * 4.0), 4.0)
		
		# Generate all disco elements
		var kick_sample = generate_disco_kick(beat_position)
		var hihat_sample = generate_disco_hihat(eighth_position)
		var bass_sample = generate_disco_bass(sample_time)
		var strings_sample = generate_disco_strings(sample_time, bar_position)
		var piano_sample = generate_disco_piano(eighth_position, sample_time)
		
		# MIX WITH DISCO BALANCE! 🎚️
		var left_mix = (
			kick_sample * 0.8 +        # Strong kick
			hihat_sample * 0.4 +       # Crisp hi-hat
			bass_sample * 0.7 +        # Funky bass
			strings_sample * 0.5 +     # Lush strings
			piano_sample * 0.6         # Piano stabs
		)
		
		var right_mix = (
			kick_sample * 0.8 +        # Strong kick
			hihat_sample * 0.4 +       # Crisp hi-hat  
			bass_sample * 0.7 +        # Funky bass
			strings_sample * 0.5 +     # Lush strings
			piano_sample * 0.6         # Piano stabs
		)
		
		# Apply disco filtering (classic disco has warm, filtered sound)
		left_mix = apply_disco_filter(left_mix)
		right_mix = apply_disco_filter(right_mix)
		
		# Gentle compression (disco glue)
		left_mix = compress_disco(left_mix)
		right_mix = compress_disco(right_mix)
		
		# EXTREME LO-FI PROCESSING! 🌊📼
		if lofi_enabled:
			left_mix = apply_extreme_lofi(left_mix, i)
			right_mix = apply_extreme_lofi(right_mix, i)
		
		frames[i] = Vector2(left_mix, right_mix)
	
	time_position += frame_count / sample_rate
	return frames

func generate_disco_kick(beat_position: float) -> float:
	"""Generate classic 4-on-the-floor disco kick! 🥁"""
	var beat_index = int(beat_position)
	if not kick_pattern[beat_index]:
		return 0.0
	
	var beat_phase = beat_position - beat_index
	
	# Classic disco kick envelope (punchy but full)
	var envelope = exp(-beat_phase * 5.0) * (1.0 - exp(-beat_phase * 50.0))
	
	# Two-part kick: low thump + higher click
	var low_freq = 55.0 * (1.0 - beat_phase * 0.3)  # Pitch bend down
	var click_freq = 2000.0 * exp(-beat_phase * 15.0)  # High frequency click
	
	var low_thump = sin(time_position * low_freq * 2.0 * PI) * envelope
	var click = sin(time_position * click_freq * 2.0 * PI) * envelope * 0.3
	
	return (low_thump + click) * 0.7

func generate_disco_hihat(eighth_position: float) -> float:
	"""Generate classic disco hi-hat pattern! 🎩"""
	var eighth_index = int(eighth_position) % hihat_pattern.size()
	var accent = hihat_pattern[eighth_index]
	
	if accent == 0.0:
		return 0.0
	
	var eighth_phase = eighth_position - int(eighth_position)
	
	# Quick hi-hat envelope
	var envelope = exp(-eighth_phase * 25.0) * accent
	
	# Filtered noise for realistic hi-hat
	var noise = (randf() - 0.5) * 2.0
	var filtered = noise * envelope * 0.3
	
	return filtered

func generate_disco_bass(sample_time: float) -> float:
	"""Generate FUNKY disco bass line! 🎸"""
	var pattern_time = fmod(sample_time / beat_duration, bass_pattern.size())
	var bass_index = int(pattern_time)
	var bass_phase = pattern_time - bass_index
	
	var bass_note = bass_pattern[bass_index]
	if bass_note.note == -1:  # Rest
		return 0.0
	
	var accent = bass_note.accent
	var note_interval = bass_note.note
	
	# Calculate bass frequency  
	var bass_freq = base_frequency * pow(2.0, note_interval / 12.0)
	
	# Disco bass envelope (punchy attack, sustain for groove)
	var attack = min(bass_phase * 20.0, 1.0)
	var sustain = 0.7 + 0.3 * exp(-bass_phase * 2.0)
	var envelope = attack * sustain * accent
	
	# Classic disco bass sound (square wave + slight distortion)
	var fundamental = sin(sample_time * bass_freq * 2.0 * PI)
	var harmonic = sin(sample_time * bass_freq * 4.0 * PI) * 0.3
	var bass_sound = (fundamental + harmonic) * envelope * 0.6
	
	# Add subtle distortion for funk
	bass_sound = sign(bass_sound) * pow(abs(bass_sound), 0.8)
	
	return bass_sound

func generate_disco_strings(sample_time: float, bar_position: float) -> float:
	"""Generate lush disco string section! 🎻✨"""
	var chord_index = int(bar_position) % string_chords.size()
	var chord = string_chords[chord_index]
	
	var strings_mix = 0.0
	
	# Generate each note in the chord
	for note_offset in chord:
		var string_freq = base_frequency * 4.0 * pow(2.0, note_offset / 12.0)  # Higher octave
		
		# Lush string envelope (slow attack, long sustain)
		var phase = fmod(sample_time / (beat_duration * 4.0), 1.0)
		var envelope = min(phase * 3.0, 1.0) * 0.8  # Slow attack
		
		# String sound (sawtooth + filtering for warmth)
		var sawtooth = 2.0 * fmod(sample_time * string_freq, 1.0) - 1.0
		var filtered_string = sawtooth * envelope * 0.15
		
		strings_mix += filtered_string
	
	# Apply string section filtering (warm, lush)
	return strings_mix * 0.7

func generate_disco_piano(eighth_position: float, sample_time: float) -> float:
	"""Generate classic disco piano stabs! 🎹✨"""
	var piano_index = int(eighth_position) % piano_pattern.size()
	var stab_intensity = piano_pattern[piano_index]
	
	if stab_intensity == 0.0:
		return 0.0
	
	var eighth_phase = eighth_position - int(eighth_position)
	
	# Piano stab envelope (quick attack, medium decay)
	var envelope = exp(-eighth_phase * 8.0) * stab_intensity
	
	# Piano chord (simulate multiple notes)
	var piano_mix = 0.0
	var piano_chord = [0, 4, 7]  # Major triad
	
	for note in piano_chord:
		var piano_freq = base_frequency * 8.0 * pow(2.0, note / 12.0)  # High octave
		var piano_note = sin(sample_time * piano_freq * 2.0 * PI) * envelope * 0.2
		piano_mix += piano_note
	
	return piano_mix

func apply_disco_filter(sample: float) -> float:
	"""Apply classic disco filtering (warm, slightly muffled top end)"""
	# Simple low-pass filtering for disco warmth
	low_pass_filter = low_pass_filter * 0.98 + sample * 0.02
	return low_pass_filter * 0.7 + sample * 0.3

func compress_disco(sample: float) -> float:
	"""Apply gentle compression for disco glue"""
	var threshold = 0.7
	if abs(sample) > threshold:
		var excess = abs(sample) - threshold
		var compressed_excess = excess * 0.3  # 3:1 compression ratio
		sample = sign(sample) * (threshold + compressed_excess)
	
	return clamp(sample, -0.95, 0.95)

# Enhanced public API
func set_disco_style(style: String):
	"""Change disco style: classic, funk, eurobeat"""
	disco_style = style
	match style:
		"classic":
			bpm = 120.0
			groove_swing = 0.1
		"funk":
			bpm = 110.0  
			groove_swing = 0.15
		"eurobeat":
			bpm = 130.0
			groove_swing = 0.05
	
	calculate_timing()
	print("🕺 Disco style: ", style.to_upper(), " at ", bpm, " BPM!")

func set_tempo(new_bpm: float):
	"""Change the disco tempo with style"""
	bpm = clamp(new_bpm, 90.0, 150.0)
	calculate_timing()
	print("🎵 Disco tempo boosted to: ", bpm, " BPM! Let's dance! 💃")

func set_volume(new_volume: float):
	"""Set disco volume with style"""
	volume = clamp(new_volume, 0.0, 1.0)
	volume_db = linear_to_db(volume)
	var emoji = "🔊" if volume > 0.7 else "🔉" if volume > 0.3 else "🔈"
	print(emoji, " Disco volume: ", int(volume * 100), "% - ", get_volume_description())

func get_volume_description() -> String:
	"""Get funky volume description"""
	if volume > 0.8: return "PARTY TIME! 🎉"
	elif volume > 0.6: return "Getting groovy! 🕺"
	elif volume > 0.4: return "Smooth vibes ✨"
	elif volume > 0.2: return "Chill disco 😌"
	else: return "Whisper quiet 🤫"

func toggle_music():
	"""Toggle disco with style!"""
	disco_enabled = !disco_enabled
	if disco_enabled:
		print("🎵 DISCO IS BACK! Let's boogie! 🕺✨")
		volume_db = linear_to_db(volume)
	else:
		print("🛑 Disco paused... but the groove lives on! 💫")
		volume_db = -80.0

# Educational mode (restored for compatibility)
func set_educational_mode(enabled: bool):
	"""Set educational mode with gentler sounds"""
	if enabled:
		set_volume(0.3)  # Quieter for classroom
		set_disco_style("classic")  # Gentle classic style
		print("🎓 Educational mode: ON (quieter disco)")
	else:
		set_volume(0.6)  # Party volume
		print("🕺 Party mode: ON (louder disco)")

func restart_music():
	"""Restart disco music from beginning"""
	time_position = 0.0
	print("🔄 Disco music restarted - back to the beat!")

func get_disco_info() -> Dictionary:
	"""Get comprehensive disco info"""
	return {
		"bpm": bpm,
		"style": disco_style,
		"volume": volume,
		"groove_swing": groove_swing,
		"beat_duration": beat_duration,
		"current_beat": get_current_beat(),
		"disco_enabled": disco_enabled,
		"party_level": get_party_level()
	}

func get_party_level() -> String:
	"""Assess the current party level"""
	if not disco_enabled: return "No party 😴"
	elif bpm > 130: return "WILD PARTY! 🎉"
	elif bpm > 120: return "Great vibes! 🕺"
	elif bpm > 110: return "Smooth groove ✨"
	else: return "Chill disco 😌"

func print_disco_info():
	"""Print disco info with style!"""
	print("🕺 === DISCO MUSIC STATUS === ✨")
	print("🎵 Style: ", disco_style.to_upper())
	print("⚡ BPM: ", bpm, " (", get_party_level(), ")")
	print("🔊 Volume: ", int(volume * 100), "% (", get_volume_description(), ")")
	print("🎪 Disco enabled: ", "YES! 🎉" if disco_enabled else "Paused 🛑")
	print("🕺 === KEEP ON DANCING! === ✨")

func get_current_beat() -> int:
	"""Get current beat in the 4/4 pattern"""
	return int(time_position / beat_duration) % 4 + 1  # 1-4 for disco feel

func apply_extreme_lofi(sample: float, frame_index: int) -> float:
	"""Apply EXTREME lo-fi drowning effects! 🌊📼💧"""
	
	# 1. TAPE PITCH WOBBLE (old tape deck instability)
	wobble_phase += 0.0001  # Slow wobble
	var pitch_mod = 1.0 + sin(wobble_phase) * pitch_wobble_amount
	# Simulate pitch change by slightly modulating the sample
	sample *= pitch_mod
	
	# 2. SMOOTH BIT CRUSHING (destroy clarity without harsh artifacts)
	var bit_reduction = pow(2.0, bit_crush_factor)
	var crushed = round(sample * bit_reduction) / bit_reduction
	# Smooth blend instead of harsh switching to prevent sparkling
	sample = sample * 0.3 + crushed * 0.7  # Much gentler bit crushing
	
	# Add smoothing filter to prevent aliasing artifacts
	sample = (sample + low_pass_filter * 0.2) / 1.2
	
	# 3. SMOOTH SAMPLE RATE CRUSHING (make it sound ancient without artifacts)
	var crush_ratio = sample_rate / sample_rate_crush
	var crush_index = int(frame_index / crush_ratio) * crush_ratio
	var crush_phase = fmod(frame_index, crush_ratio) / crush_ratio
	# Use smooth interpolation instead of harsh sample-and-hold
	sample = sample * (0.7 + crush_phase * 0.3)  # Gentle fade instead of hard stepping
	
	# 4. HEAVY TAPE SATURATION (warm analog distortion)
	var saturated = tanh(sample * (1.0 + tape_saturation * 3.0))
	sample = sample * (1.0 - tape_saturation) + saturated * tape_saturation
	
	# 5. VINYL CRACKLE & SURFACE NOISE
	crackle_state = crackle_state * 0.99 + (randf() - 0.5) * 0.01
	var crackle = crackle_state * vinyl_crackle_intensity
	var surface_noise = (randf() - 0.5) * 0.02 * vinyl_crackle_intensity
	sample += crackle + surface_noise
	
	# 6. EXTREME LOW-PASS FILTERING (underwater muffling)
	var cutoff_normalized = lo_pass_frequency / (sample_rate * 0.5)
	cutoff_normalized = clamp(cutoff_normalized, 0.01, 0.99)
	low_pass_filter = low_pass_filter * (1.0 - cutoff_normalized) + sample * cutoff_normalized
	sample = low_pass_filter
	
	# 7. UNDERWATER REVERB (drowning effect)
	if reverb_buffer.size() > 0:
		var reverb_sample = reverb_buffer[reverb_index]
		reverb_buffer[reverb_index] = sample + reverb_sample * reverb_decay
		sample = sample * (1.0 - underwater_depth) + reverb_sample * underwater_depth
		
		reverb_index = (reverb_index + 1) % reverb_buffer.size()
	
	# 8. FINAL UNDERWATER DAMPENING (complete submersion effect)
	sample *= 0.7  # Overall volume reduction for underwater feel
	sample = sample * (1.0 - underwater_depth * 0.5)  # Further muffling
	
	# 9. GENTLE COMPRESSION (glue it all together)
	var threshold = 0.4
	if abs(sample) > threshold:
		var excess = abs(sample) - threshold
		sample = sign(sample) * (threshold + excess * 0.2)  # Heavy compression
	
	return clamp(sample, -0.8, 0.8)  # Prevent clipping but keep some headroom

# Enhanced lo-fi controls
func set_lofi_intensity(intensity: float):
	"""Set lo-fi intensity (0.0 = clean, 1.0 = extremely drowned)"""
	intensity = clamp(intensity, 0.0, 1.0)
	
	underwater_depth = intensity * 0.95
	tape_saturation = intensity * 0.9
	vinyl_crackle_intensity = intensity * 0.4
	bit_crush_factor = 4.0 + intensity * 8.0  # 4-12 bits
	sample_rate_crush = 22050.0 - intensity * 14050.0  # 22kHz down to 8kHz
	lo_pass_frequency = 2000.0 - intensity * 1200.0  # 2kHz down to 800Hz
	
	print("🌊 Lo-fi intensity: ", int(intensity * 100), "% drowned")
	print("📼 Tape saturation: ", int(tape_saturation * 100), "%")
	print("💧 Underwater depth: ", int(underwater_depth * 100), "%")

func toggle_lofi():
	"""Toggle lo-fi processing on/off"""
	lofi_enabled = !lofi_enabled
	if lofi_enabled:
		print("🌊 DROWNED DISCO MODE: ON! Welcome to the underwater party! 💧📼")
	else:
		print("✨ CLEAN DISCO MODE: ON! Crystal clear vibes! 🕺")

func set_underwater_style():
	"""Preset for maximum underwater drowning effect"""
	set_lofi_intensity(1.0)
	lo_pass_frequency = 600.0  # Very muffled
	reverb_decay = 0.92  # Long underwater echo
	underwater_depth = 0.95  # Almost completely submerged
	print("🌊💧 MAXIMUM UNDERWATER DROWNING ACTIVATED! Glub glub... 🐟")
