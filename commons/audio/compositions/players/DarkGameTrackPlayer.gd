# DarkGameTrackPlayer.gd
# Advanced dark 808/606 game track with rhythm theory implementation
# Demonstrates complex patterns, syncopation, and structured composition
# Uses 64-step patterns with sophisticated rhythmic concepts

extends Node

const SAMPLE_RATE = 44100
var BPM = 360.0  # High-energy BPM from JSON config
var BEAT_DURATION = 60.0 / BPM
var STEP_DURATION = BEAT_DURATION / 4.0  # 16th note steps for precision

enum TrackSound {
	DARK_808_KICK,
	ACID_606_HIHAT,
	DARK_808_SUB_BASS,
	AMBIENT_DRONE,
	ACID_606_SNARE,
	GLITCH_STAB,
	DEEP_RUMBLE,
	BLADE_RUNNER_HIT  # New atmospheric element
}

# Audio players for layered track
var kick_player: AudioStreamPlayer
var hihat_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer
var snare_player: AudioStreamPlayer
var blade_runner_player: AudioStreamPlayer

# Advanced rhythm system
var step_timer: Timer  # 16th note precision
var bar_timer: Timer   # Track bar structure
var current_step: int = 0
var current_bar: int = 0
var phrase_position: int = 0  # Position within larger phrase structure
var is_playing: bool = false

# 64-step complex patterns from JSON (demonstrates advanced rhythm concepts)
var kick_pattern: Array = [0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1]
var hihat_pattern: Array = [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0]
var snare_pattern: Array = [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0]
var effect_pattern: Array = [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var blade_runner_pattern: Array = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# Rhythm analysis (based on rhythm theory)
var pattern_length: int = 64
var strong_beats: Array = []    # Beat 1 of each bar
var back_beats: Array = []      # Beats 2 and 4 (snare territory)
var weak_beats: Array = []      # Off-beats and syncopated positions
var ghost_positions: Array = [] # Quiet texture positions

# Sound cache
var sound_cache: Dictionary = {}

# Track settings (from JSON config)
@export var master_volume: float = -6.0
@export var kick_volume: float = 0.0      # Strong kicks for spine beat
@export var hihat_volume: float = 0.0     # Active hi-hats for groove
@export var bass_volume: float = 0.0      # Sub bass foundation  
@export var snare_volume: float = -3.0    # Snares on backbeats
@export var ambient_volume: float = -9.0  # Atmospheric layer
@export var effect_volume: float = -12.0  # Glitch stabs
@export var blade_runner_volume: float = -1.0  # Cinematic hits

# Rhythm configuration
@export var swing_amount: float = 0.08    # Subtle swing for groove
@export var ghost_note_volume: float = -15.0  # Very quiet ghost notes
@export var accent_boost: float = 6.0     # Boost for accented hits

@export var auto_start: bool = true
@export var loop_track: bool = true

signal track_started()
signal beat_triggered(beat_number: int)

func _ready():
	print("🎵 ADVANCED DARK GAME TRACK PLAYER 🎵")
	print("Setting up complex 64-step rhythmic patterns...")
	print("BPM: %.0f | Pattern Length: %d steps" % [BPM, pattern_length])
	
	_analyze_rhythm_patterns()
	_setup_audio_players()
	_setup_rhythm_system()
	_generate_all_sounds()
	
	# Auto-load JSON configuration if available
	call_deferred("_auto_load_config")
	
	if auto_start:
		call_deferred("start_track")

func _auto_load_config():
	"""Try to auto-load JSON configuration"""
	var config_path = "res://commons/audio/configs/dark_game_track_simple.json"
	if FileAccess.file_exists(config_path):
		print("🔧 Auto-loading configuration...")
		load_from_json(config_path)
	else:
		print("ℹ️ No auto-config found, using default patterns")

func _analyze_rhythm_patterns():
	"""Analyze patterns using rhythm theory concepts"""
	print("   🔍 Analyzing rhythm patterns...")
	
	# Identify strong beats (downbeats) - every 16th step (beat 1 of each bar)
	for i in range(0, pattern_length, 16):
		strong_beats.append(i)
	
	# Identify backbeats (beats 2 and 4) - steps 4, 12, 20, 28, etc.
	for i in range(4, pattern_length, 8):
		back_beats.append(i)
		if i + 8 < pattern_length:
			back_beats.append(i + 8)
	
	# Identify weak beats (offbeats and syncopated positions)
	for i in range(pattern_length):
		if i % 4 != 0:  # Not on main beats
			weak_beats.append(i)
	
	# Identify ghost note positions (between strong hits in hi-hat pattern)
	for i in range(pattern_length):
		if hihat_pattern[i] == 1 and kick_pattern[i] == 0 and snare_pattern[i] == 0:
			ghost_positions.append(i)
	
	print("   • Strong beats: %d positions" % strong_beats.size())
	print("   • Back beats: %d positions" % back_beats.size()) 
	print("   • Weak beats: %d positions" % weak_beats.size())
	print("   • Ghost positions: %d positions" % ghost_positions.size())

func _setup_audio_players():
	"""Setup separate audio players for each track element"""
	
	# Kick drum player (punchy bass)
	kick_player = AudioStreamPlayer.new()
	kick_player.name = "KickPlayer"
	kick_player.volume_db = kick_volume
	add_child(kick_player)
	
	# Hi-hat player (crisp highs)
	hihat_player = AudioStreamPlayer.new()
	hihat_player.name = "HiHatPlayer"
	hihat_player.volume_db = hihat_volume
	add_child(hihat_player)
	
	# Bass player (deep sub)
	bass_player = AudioStreamPlayer.new()
	bass_player.name = "BassPlayer"
	bass_player.volume_db = bass_volume
	add_child(bass_player)
	
	# Ambient player (atmospheric background)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = ambient_volume
	add_child(ambient_player)
	
	# Effect player (glitches and stabs)
	effect_player = AudioStreamPlayer.new()
	effect_player.name = "EffectPlayer"
	effect_player.volume_db = effect_volume
	add_child(effect_player)
	
	# Snare player (separate for better control)
	snare_player = AudioStreamPlayer.new()
	snare_player.name = "SnarePlayer"
	snare_player.volume_db = snare_volume
	add_child(snare_player)
	
	# Blade Runner player (cinematic atmospheric hits)
	blade_runner_player = AudioStreamPlayer.new()
	blade_runner_player.name = "BladeRunnerPlayer"
	blade_runner_player.volume_db = blade_runner_volume
	add_child(blade_runner_player)
	
	print("   ✅ Advanced audio players configured")

func _setup_rhythm_system():
	"""Setup advanced rhythm system with 16th note precision"""
	
	# 16th note step timer for complex patterns
	step_timer = Timer.new()
	step_timer.name = "StepTimer"
	step_timer.wait_time = STEP_DURATION
	step_timer.one_shot = false
	step_timer.timeout.connect(_on_step)
	add_child(step_timer)
	
	# Bar timer for structure tracking
	bar_timer = Timer.new()
	bar_timer.name = "BarTimer"
	bar_timer.wait_time = BEAT_DURATION * 4.0  # 4 beats per bar
	bar_timer.one_shot = false
	bar_timer.timeout.connect(_on_bar)
	add_child(bar_timer)
	
	print("   ✅ Advanced rhythm system ready at %.0f BPM" % BPM)
	print("   🎵 16th note precision with %.1f%% swing" % (swing_amount * 100))

func _generate_all_sounds():
	"""Pre-generate all sounds for the track"""
	print("   🔧 Generating track sounds...")
	
	# Generate individual drum sounds
	sound_cache[TrackSound.DARK_808_KICK] = _generate_sound(TrackSound.DARK_808_KICK, 1.5)
	sound_cache[TrackSound.ACID_606_HIHAT] = _generate_sound(TrackSound.ACID_606_HIHAT, 0.3)
	sound_cache[TrackSound.ACID_606_SNARE] = _generate_sound(TrackSound.ACID_606_SNARE, 0.8)
	sound_cache[TrackSound.GLITCH_STAB] = _generate_sound(TrackSound.GLITCH_STAB, 0.4)
	
	# Generate longer sustained sounds
	sound_cache[TrackSound.DARK_808_SUB_BASS] = _generate_sound(TrackSound.DARK_808_SUB_BASS, 8.0)
	sound_cache[TrackSound.AMBIENT_DRONE] = _generate_sound(TrackSound.AMBIENT_DRONE, 16.0)
	sound_cache[TrackSound.DEEP_RUMBLE] = _generate_sound(TrackSound.DEEP_RUMBLE, 12.0)
	sound_cache[TrackSound.BLADE_RUNNER_HIT] = _generate_sound(TrackSound.BLADE_RUNNER_HIT, 4.0)
	
	print("   ✅ All advanced sounds generated and cached")

# ===== TRACK CONTROL =====

func start_track():
	"""Start playing the advanced dark game track"""
	if is_playing:
		return
	
	print("🎵 Starting advanced dark game track...")
	print("   • 64-step complex patterns")
	print("   • Sophisticated syncopation")
	print("   • Ghost notes and rhythm theory")
	print("   • %.0f BPM high-energy groove" % BPM)
	
	is_playing = true
	current_step = 0
	current_bar = 0
	phrase_position = 0
	
	# Start ambient layers first
	_start_ambient_layers()
	
	# Start advanced rhythm system
	step_timer.start()
	bar_timer.start()
	
	track_started.emit()
	print("   🎵 Advanced track playing at %.0f BPM" % BPM)

func stop_track():
	"""Stop the advanced track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping advanced track...")
	
	is_playing = false
	step_timer.stop()
	bar_timer.stop()
	
	# Stop all players
	kick_player.stop()
	hihat_player.stop()
	bass_player.stop()
	ambient_player.stop()
	effect_player.stop()
	snare_player.stop()
	blade_runner_player.stop()

func _start_ambient_layers():
	"""Start the continuous ambient layers"""
	
	# Deep ambient drone (very quiet background)
	ambient_player.stream = sound_cache[TrackSound.AMBIENT_DRONE]
	ambient_player.play()
	
	# Enable looping for ambient
	if ambient_player.stream is AudioStreamWAV:
		ambient_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	# Deep bass layer (looping sub bass)
	await get_tree().create_timer(2.0).timeout  # Delay bass entry
	bass_player.stream = sound_cache[TrackSound.DARK_808_SUB_BASS]
	bass_player.play()
	
	if bass_player.stream is AudioStreamWAV:
		bass_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

func _on_step():
	"""Handle each 16th note step of the advanced track"""
	if not is_playing:
		return
	
	var pattern_pos = current_step % pattern_length
	var is_strong_beat = pattern_pos in strong_beats
	var is_back_beat = pattern_pos in back_beats
	var is_weak_beat = pattern_pos in weak_beats
	var is_ghost_position = pattern_pos in ghost_positions
	
	# Apply swing to odd 16th notes
	var swing_delay = 0.0
	if pattern_pos % 2 == 1:  # Odd positions (the "e" and "a")
		swing_delay = STEP_DURATION * swing_amount
		if swing_delay > 0:
			await get_tree().create_timer(swing_delay).timeout
	
	# Kick pattern (complex syncopated 808 kicks)
	if kick_pattern[pattern_pos] == 1:
		kick_player.stream = sound_cache[TrackSound.DARK_808_KICK]
		# Boost volume for strong beats
		if is_strong_beat:
			kick_player.volume_db = kick_volume + master_volume + accent_boost
		else:
			kick_player.volume_db = kick_volume + master_volume
		kick_player.play()
	
	# Hi-hat pattern (groove and ghost notes)
	if hihat_pattern[pattern_pos] == 1:
		hihat_player.stream = sound_cache[TrackSound.ACID_606_HIHAT]
		# Ghost notes are much quieter
		if is_ghost_position:
			hihat_player.volume_db = ghost_note_volume + master_volume
		else:
			hihat_player.volume_db = hihat_volume + master_volume
		hihat_player.play()
	
	# Snare pattern (backbeats and variations)
	if snare_pattern[pattern_pos] == 1:
		snare_player.stream = sound_cache[TrackSound.ACID_606_SNARE]
		# Accent snares on backbeats
		if is_back_beat:
			snare_player.volume_db = snare_volume + master_volume + accent_boost
		else:
			snare_player.volume_db = snare_volume + master_volume
		snare_player.play()
	
	# Effect pattern (glitch stabs on weak beats)
	if effect_pattern[pattern_pos] == 1:
		effect_player.stream = sound_cache[TrackSound.GLITCH_STAB]
		effect_player.play()
	
	# Blade Runner atmospheric hits (very sparse, cinematic)
	if blade_runner_pattern[pattern_pos] == 1:
		blade_runner_player.stream = sound_cache[TrackSound.BLADE_RUNNER_HIT]
		blade_runner_player.play()
		print("   ⚡ Blade Runner hit at step %d" % current_step)
	
	# Emit step signal for external sync
	beat_triggered.emit(current_step)
	
	current_step += 1
	
	# Reset pattern after 64 steps
	if current_step >= pattern_length:
		current_step = 0
		phrase_position += 1
		print("   🔄 64-step phrase completed (%d)" % phrase_position)
		if not loop_track:
			stop_track()

func _on_bar():
	"""Handle bar transitions for structure tracking"""
	if not is_playing:
		return
	
	current_bar += 1
	var bar_in_phrase = current_bar % 4
	
	# Log structural information
	if bar_in_phrase == 1:
		print("   📊 Bar %d: Phrase start" % current_bar)
	else:
		print("   📊 Bar %d" % current_bar)

# ===== SOUND GENERATION (from working test) =====

func _generate_sound(sound_type: TrackSound, duration: float) -> AudioStreamWAV:
	"""Generate a track sound using proven working methods"""
	
	var sample_count = int(SAMPLE_RATE * duration)
	
	# Create audio stream
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	# Generate audio data
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Generate based on sound type
	match sound_type:
		TrackSound.DARK_808_KICK:
			_generate_808_kick(data, sample_count)
		TrackSound.ACID_606_HIHAT:
			_generate_606_hihat(data, sample_count)
		TrackSound.ACID_606_SNARE:
			_generate_606_snare(data, sample_count)
		TrackSound.DARK_808_SUB_BASS:
			_generate_808_sub_bass(data, sample_count)
		TrackSound.AMBIENT_DRONE:
			_generate_ambient_drone(data, sample_count)
		TrackSound.GLITCH_STAB:
			_generate_glitch_stab(data, sample_count)
		TrackSound.DEEP_RUMBLE:
			_generate_deep_rumble(data, sample_count)
		TrackSound.BLADE_RUNNER_HIT:
			_generate_blade_runner_hit(data, sample_count)
	
	stream.data = data
	return stream

func _generate_808_kick(data: PackedByteArray, sample_count: int):
	"""Generate 808 kick (proven working)"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 60.0 - (25.0 * pow(progress, 0.3))
		var sine = sin(2.0 * PI * freq * t)
		var click = sin(2.0 * PI * 1200.0 * t) * exp(-progress * 80.0) * 0.3
		var envelope = exp(-progress * 4.0)
		var sample = tanh((sine + click) * envelope * 1.5) * 0.7
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_606_hihat(data: PackedByteArray, sample_count: int):
	"""Generate 606 hi-hat (proven working)"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 2.0
		var filter_freq = 8000.0 - (3000.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var envelope = exp(-progress * 15.0)
		var ring = sin(2.0 * PI * 12000.0 * t) * envelope * 0.2
		var sample = (filtered + ring) * envelope * 0.3
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_606_snare(data: PackedByteArray, sample_count: int):
	"""Generate 606 snare"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.5
		var tone = sin(2.0 * PI * 200.0 * t) * 0.4
		var envelope = exp(-progress * 8.0)
		var snap = sin(2.0 * PI * 3000.0 * t) * exp(-progress * 20.0) * 0.3
		var sample = (noise + tone + snap) * envelope * 0.5
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_808_sub_bass(data: PackedByteArray, sample_count: int):
	"""Generate 808 sub bass (proven working)"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 35.0 + sin(2.0 * PI * 0.3 * t) * 5.0
		var sub = sin(2.0 * PI * freq * t)
		var harmonic2 = sin(2.0 * PI * freq * 2.0 * t) * 0.1
		var harmonic3 = sin(2.0 * PI * freq * 3.0 * t) * 0.05
		var envelope = (1.0 - exp(-progress * 8.0)) * exp(-progress * 0.5)
		var sample = (sub + harmonic2 + harmonic3) * envelope * 0.5
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_ambient_drone(data: PackedByteArray, sample_count: int):
	"""Generate ambient drone (proven working)"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var freq1 = 45.0   # Fundamental
		var freq2 = 90.0   # Octave
		var freq3 = 67.5   # Perfect fifth
		var mod = sin(2.0 * PI * 0.13 * t) * 0.3 + 0.7
		
		var layer1 = sin(2.0 * PI * freq1 * t) * 0.5
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.3
		var layer3 = sin(2.0 * PI * freq3 * t) * 0.2
		var detune = sin(2.0 * PI * (freq1 + 0.7) * t) * 0.1
		var sample = (layer1 + layer2 + layer3 + detune) * mod * 0.3
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_glitch_stab(data: PackedByteArray, sample_count: int):
	"""Generate glitch stab"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 440.0 * (1.0 + sin(2.0 * PI * 50.0 * t) * 0.3)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0.2 else -1.0
		var envelope = exp(-progress * 10.0)
		
		# Bit crushing
		var bit_depth = 6.0
		var crushed = floor(square * pow(2, bit_depth)) / pow(2, bit_depth)
		var sample = crushed * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_deep_rumble(data: PackedByteArray, sample_count: int):
	"""Generate deep rumble"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var freq = 25.0 + sin(2.0 * PI * 0.1 * t) * 3.0
		var fundamental = sin(2.0 * PI * freq * t)
		var sub_harmonic = sin(2.0 * PI * freq * 0.5 * t) * 0.3
		var envelope = sin(2.0 * PI * 0.4 * t) * 0.5 + 0.5
		var sample = (fundamental + sub_harmonic) * envelope * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_blade_runner_hit(data: PackedByteArray, sample_count: int):
	"""Generate cinematic Blade Runner atmospheric hit"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Complex harmonic structure for cinematic feel
		var freq = 110.0 - (20.0 * progress)
		var fundamental = sin(2.0 * PI * freq * t)
		var fifth = sin(2.0 * PI * freq * 1.5 * t) * 0.6
		var octave = sin(2.0 * PI * freq * 2.0 * t) * 0.3
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.4
		
		# Atmospheric modulation
		var lfo = sin(2.0 * PI * 0.5 * t) * 0.3 + 0.7
		var reverb_sim = sin(2.0 * PI * freq * 8.0 * t) * exp(-progress * 3.0) * 0.1
		
		# Long cinematic envelope
		var envelope = exp(-progress * 0.8) * (1.0 - exp(-progress * 15.0))
		var sample = (fundamental + fifth + octave + sub + reverb_sim) * envelope * lfo * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# ===== PUBLIC API =====

func set_bpm(new_bpm: float):
	"""Change the track BPM and update timing"""
	BPM = new_bpm
	BEAT_DURATION = 60.0 / BPM
	STEP_DURATION = BEAT_DURATION / 4.0
	
	if step_timer:
		step_timer.wait_time = STEP_DURATION
	if bar_timer:
		bar_timer.wait_time = BEAT_DURATION * 4.0
	
	print("🎵 BPM changed to %.0f" % new_bpm)

func set_master_volume(volume_db: float):
	"""Set overall track volume"""
	master_volume = volume_db
	kick_player.volume_db = kick_volume + master_volume
	hihat_player.volume_db = hihat_volume + master_volume
	bass_player.volume_db = bass_volume + master_volume
	ambient_player.volume_db = ambient_volume + master_volume
	effect_player.volume_db = effect_volume + master_volume
	snare_player.volume_db = snare_volume + master_volume
	blade_runner_player.volume_db = blade_runner_volume + master_volume

func customize_pattern(element: String, pattern: Array):
	"""Customize rhythm patterns (must be 64 steps)"""
	if pattern.size() != pattern_length:
		print("⚠️ Pattern must be %d steps long" % pattern_length)
		return
	
	match element:
		"kick":
			kick_pattern = pattern
		"hihat":
			hihat_pattern = pattern
		"snare":
			snare_pattern = pattern
		"effect":
			effect_pattern = pattern
		"blade_runner":
			blade_runner_pattern = pattern
	
	# Re-analyze patterns after change
	_analyze_rhythm_patterns()
	print("🎵 Updated %s pattern (%d steps)" % [element, pattern.size()])

func get_track_info() -> Dictionary:
	"""Get current advanced track information"""
	return {
		"is_playing": is_playing,
		"current_step": current_step,
		"current_bar": current_bar,
		"phrase_position": phrase_position,
		"bpm": BPM,
		"pattern_length": pattern_length,
		"swing_amount": swing_amount,
		"master_volume": master_volume,
		"strong_beats_count": strong_beats.size(),
		"weak_beats_count": weak_beats.size(),
		"ghost_positions_count": ghost_positions.size(),
		"patterns": {
			"kick": kick_pattern,
			"hihat": hihat_pattern,
			"snare": snare_pattern,
			"effect": effect_pattern,
			"blade_runner": blade_runner_pattern
		}
	}

func set_swing(amount: float):
	"""Set swing amount (0.0 to 0.5)"""
	swing_amount = clamp(amount, 0.0, 0.5)
	print("🎵 Swing set to %.1f%%" % (swing_amount * 100))

func analyze_syncopation():
	"""Analyze and report syncopation in current patterns"""
	print("🎵 SYNCOPATION ANALYSIS 🎵")
	
	var kick_on_weak = 0
	var snare_on_weak = 0
	var total_hits = 0
	
	for i in range(pattern_length):
		if kick_pattern[i] == 1:
			total_hits += 1
			if i in weak_beats:
				kick_on_weak += 1
		if snare_pattern[i] == 1:
			if i in weak_beats:
				snare_on_weak += 1
	
	print("   • Kick hits on weak beats: %d/%d" % [kick_on_weak, total_hits])
	print("   • Snare hits on weak beats: %d" % snare_on_weak)
	print("   • Syncopation level: %.1f%%" % ((kick_on_weak + snare_on_weak) / float(total_hits) * 100))

func load_from_json(json_path: String):
	"""Load patterns from JSON file"""
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("⚠️ Could not load JSON file: %s" % json_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("⚠️ JSON parse error")
		return
	
	var data = json.data
	
	# Load BPM
	if "bpm" in data:
		set_bpm(data.bpm)
	
	# Load patterns
	if "patterns" in data:
		var patterns = data.patterns
		if "kick" in patterns:
			customize_pattern("kick", patterns.kick)
		if "hihat" in patterns:
			customize_pattern("hihat", patterns.hihat)
		if "snare" in patterns:
			customize_pattern("snare", patterns.snare)
		if "effect" in patterns:
			customize_pattern("effect", patterns.effect)
		if "blade_runner" in patterns:
			customize_pattern("blade_runner", patterns.blade_runner)
	
	# Load volumes (full implementation)
	if "volumes" in data:
		var volumes = data.volumes
		if "kick" in volumes:
			kick_volume = volumes.kick
			kick_player.volume_db = kick_volume + master_volume
		if "hihat" in volumes:
			hihat_volume = volumes.hihat
			hihat_player.volume_db = hihat_volume + master_volume
		if "bass" in volumes:
			bass_volume = volumes.bass
			bass_player.volume_db = bass_volume + master_volume
		if "ambient" in volumes:
			ambient_volume = volumes.ambient
			ambient_player.volume_db = ambient_volume + master_volume
		if "effect" in volumes:
			effect_volume = volumes.effect
			effect_player.volume_db = effect_volume + master_volume
		if "blade_runner" in volumes:
			blade_runner_volume = volumes.blade_runner
			blade_runner_player.volume_db = blade_runner_volume + master_volume
		
		print("   🔊 Applied volume settings from JSON")
	
	# Load track name if available
	if "name" in data:
		print("   📛 Track: %s" % data.name)
	
	print("✅ Loaded complete configuration from %s" % json_path)
	analyze_syncopation()  # Analyze the newly loaded patterns

func show_json_utilization():
	"""Show how JSON features are being utilized"""
	print("🎵 JSON FEATURE UTILIZATION 🎵")
	
	# Pattern utilization
	print("   📊 PATTERNS (64 steps each):")
	print("      • Kick: %d hits" % kick_pattern.count(1))
	print("      • Hi-hat: %d hits" % hihat_pattern.count(1))
	print("      • Snare: %d hits" % snare_pattern.count(1))
	print("      • Effect: %d hits" % effect_pattern.count(1))
	print("      • Blade Runner: %d hits" % blade_runner_pattern.count(1))
	
	# Volume utilization
	print("   🔊 VOLUME SETTINGS:")
	print("      • Kick: %.1f dB" % kick_volume)
	print("      • Hi-hat: %.1f dB" % hihat_volume)
	print("      • Bass: %.1f dB" % bass_volume)
	print("      • Ambient: %.1f dB" % ambient_volume)
	print("      • Effect: %.1f dB" % effect_volume)
	print("      • Blade Runner: %.1f dB" % blade_runner_volume)
	
	# BPM utilization
	print("   ⚡ TEMPO: %.0f BPM" % BPM)
	
	# Advanced features being applied
	print("   🎛️ ADVANCED FEATURES ACTIVE:")
	print("      • Swing groove: %.1f%%" % (swing_amount * 100))
	print("      • Ghost note system: %.1f dB" % ghost_note_volume)
	print("      • Accent system: +%.1f dB boost" % accent_boost)
	print("      • Pattern analysis: ✅")
	print("      • Syncopation detection: ✅")

# ===== CONSOLE COMMANDS =====

func play():
	"""Console command: start track"""
	start_track()

func pause():
	"""Console command: stop track"""
	stop_track()

func info():
	"""Console command: show track info"""
	var track_info = get_track_info()
	print("🎵 ADVANCED TRACK INFO 🎵")
	print("   Status: %s" % ("Playing" if track_info.is_playing else "Stopped"))
	print("   Step: %d/%d" % [track_info.current_step, track_info.pattern_length])
	print("   Bar: %d" % track_info.current_bar)
	print("   Phrase: %d" % track_info.phrase_position)
	print("   BPM: %.0f" % track_info.bpm)
	print("   Swing: %.1f%%" % (track_info.swing_amount * 100))
	print("   Strong beats: %d" % track_info.strong_beats_count)
	print("   Weak beats: %d" % track_info.weak_beats_count)
	print("   Ghost positions: %d" % track_info.ghost_positions_count)

func json_info():
	"""Console command: show JSON utilization"""
	show_json_utilization()

func synco():
	"""Console command: analyze syncopation"""
	analyze_syncopation()

# ===== INPUT CONTROLS =====

func _input(event):
	"""Advanced hotkey controls for the track"""
	if event.is_action_pressed("ui_accept"):      # Space = Start/Stop
		if is_playing:
			stop_track()
		else:
			start_track()
	elif event.is_action_pressed("ui_select"):   # Enter = Info
		info()
	elif event.is_action_pressed("ui_up"):       # Up = Volume up
		set_master_volume(master_volume + 3.0)
		print("🔊 Master Volume: %.1f dB" % master_volume)
	elif event.is_action_pressed("ui_down"):     # Down = Volume down
		set_master_volume(master_volume - 3.0)
		print("🔉 Master Volume: %.1f dB" % master_volume)
	elif event.is_action_pressed("ui_right"):    # Right = More swing
		set_swing(swing_amount + 0.05)
	elif event.is_action_pressed("ui_left"):     # Left = Less swing
		set_swing(swing_amount - 0.05)
	
	# Handle keyboard input for additional commands
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_J: # J = JSON info
				json_info()
			KEY_S: # S = Syncopation analysis
				synco()
			KEY_R: # R = Reload JSON
				load_from_json("res://commons/audio/configs/dark_game_track_simple.json")
			KEY_1: # 1-5 = Toggle individual elements
				kick_volume = 0.0 if kick_volume < -20.0 else -999.0
				kick_player.volume_db = kick_volume + master_volume
				print("🥁 Kick: %s" % ("ON" if kick_volume > -20.0 else "OFF"))
			KEY_2:
				hihat_volume = 0.0 if hihat_volume < -20.0 else -999.0
				hihat_player.volume_db = hihat_volume + master_volume
				print("🎩 Hi-hat: %s" % ("ON" if hihat_volume > -20.0 else "OFF"))
			KEY_3:
				snare_volume = -3.0 if snare_volume < -20.0 else -999.0
				snare_player.volume_db = snare_volume + master_volume
				print("🥁 Snare: %s" % ("ON" if snare_volume > -20.0 else "OFF"))
			KEY_4:
				effect_volume = -12.0 if effect_volume < -20.0 else -999.0
				effect_player.volume_db = effect_volume + master_volume
				print("⚡ Effects: %s" % ("ON" if effect_volume > -20.0 else "OFF"))
			KEY_5:
				blade_runner_volume = -1.0 if blade_runner_volume < -20.0 else -999.0
				blade_runner_player.volume_db = blade_runner_volume + master_volume
				print("🎬 Blade Runner: %s" % ("ON" if blade_runner_volume > -20.0 else "OFF"))
