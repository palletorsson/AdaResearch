# DarkGameTrackPlayer.gd
# Pure dark 808/606 game track - no interactions, just music
# Creates atmospheric background music for your VR game

extends Node

const SAMPLE_RATE = 44100
const BPM = 120.0
const BEAT_DURATION = 60.0 / BPM  # 0.5 seconds per beat at 120 BPM

enum TrackSound {
	DARK_808_KICK,
	ACID_606_HIHAT,
	DARK_808_SUB_BASS,
	AMBIENT_DRONE,
	ACID_606_SNARE,
	GLITCH_STAB,
	DEEP_RUMBLE
}

# Audio players for layered track
var kick_player: AudioStreamPlayer
var hihat_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer

# Rhythm system
var beat_timer: Timer
var current_beat: int = 0
var is_playing: bool = false

# Track patterns (1 = play, 0 = silence)
var kick_pattern: Array = [1, 0, 0, 0, 1, 0, 1, 0]        # Heavy 808 kicks
var hihat_pattern: Array = [1, 1, 1, 1, 1, 1, 1, 1]       # Steady hi-hats
var snare_pattern: Array = [0, 0, 0, 0, 1, 0, 0, 0]       # Snare on 5
var effect_pattern: Array = [0, 0, 1, 0, 0, 0, 1, 0]      # Glitch effects

# Sound cache
var sound_cache: Dictionary = {}

# Track settings
@export var master_volume: float = -6.0
@export var bass_volume: float = 0.0     # Loud bass
@export var kick_volume: float = -3.0    # Medium kicks
@export var hihat_volume: float = -9.0   # Quiet hi-hats
@export var ambient_volume: float = -15.0 # Very quiet ambient
@export var effect_volume: float = -12.0  # Quiet effects

@export var auto_start: bool = true
@export var loop_track: bool = true

signal track_started()
signal beat_triggered(beat_number: int)

func _ready():
	print("🎵 DARK GAME TRACK PLAYER 🎵")
	print("Setting up atmospheric 808/606 track...")
	
	_setup_audio_players()
	_setup_rhythm_system()
	_generate_all_sounds()
	
	if auto_start:
		call_deferred("start_track")

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
	
	print("   ✅ Audio players configured")

func _setup_rhythm_system():
	"""Setup beat timer for rhythm"""
	
	beat_timer = Timer.new()
	beat_timer.name = "BeatTimer"
	beat_timer.wait_time = BEAT_DURATION
	beat_timer.one_shot = false
	beat_timer.timeout.connect(_on_beat)
	add_child(beat_timer)
	
	print("   ✅ Rhythm system ready at %d BPM" % BPM)

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
	
	print("   ✅ All sounds generated and cached")

# ===== TRACK CONTROL =====

func start_track():
	"""Start playing the dark game track"""
	if is_playing:
		return
	
	print("🎵 Starting dark game track...")
	
	is_playing = true
	current_beat = 0
	
	# Start ambient layers first
	_start_ambient_layers()
	
	# Start rhythm
	beat_timer.start()
	
	track_started.emit()
	print("   🎵 Track playing at %d BPM" % BPM)

func stop_track():
	"""Stop the track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping track...")
	
	is_playing = false
	beat_timer.stop()
	
	# Stop all players
	kick_player.stop()
	hihat_player.stop()
	bass_player.stop()
	ambient_player.stop()
	effect_player.stop()

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

func _on_beat():
	"""Handle each beat of the track"""
	if not is_playing:
		return
	
	var pattern_pos = current_beat % 8  # 8-beat patterns
	
	# Kick pattern (deep 808 kicks)
	if kick_pattern[pattern_pos] == 1:
		kick_player.stream = sound_cache[TrackSound.DARK_808_KICK]
		kick_player.play()
	
	# Hi-hat pattern (crisp 606 hi-hats)
	if hihat_pattern[pattern_pos] == 1:
		hihat_player.stream = sound_cache[TrackSound.ACID_606_HIHAT]
		hihat_player.play()
	
	# Snare pattern (606 snares)
	if snare_pattern[pattern_pos] == 1:
		effect_player.stream = sound_cache[TrackSound.ACID_606_SNARE]
		effect_player.play()
	
	# Effect pattern (glitch stabs)
	if effect_pattern[pattern_pos] == 1:
		effect_player.stream = sound_cache[TrackSound.GLITCH_STAB]
		effect_player.play()
	
	# Emit beat signal for external sync
	beat_triggered.emit(current_beat)
	
	current_beat += 1
	
	# Reset pattern after 32 beats (4 x 8-beat patterns)
	if current_beat >= 32:
		current_beat = 0
		if not loop_track:
			stop_track()

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

# ===== PUBLIC API =====

func set_bpm(new_bpm: float):
	"""Change the track BPM"""
	beat_timer.wait_time = 60.0 / new_bpm
	print("🎵 BPM changed to %d" % new_bpm)

func set_master_volume(volume_db: float):
	"""Set overall track volume"""
	master_volume = volume_db
	kick_player.volume_db = kick_volume + master_volume
	hihat_player.volume_db = hihat_volume + master_volume
	bass_player.volume_db = bass_volume + master_volume
	ambient_player.volume_db = ambient_volume + master_volume
	effect_player.volume_db = effect_volume + master_volume

func customize_pattern(element: String, pattern: Array):
	"""Customize rhythm patterns"""
	match element:
		"kick":
			kick_pattern = pattern
		"hihat":
			hihat_pattern = pattern
		"snare":
			snare_pattern = pattern
		"effect":
			effect_pattern = pattern
	
	print("🎵 Updated %s pattern: %s" % [element, str(pattern)])

func get_track_info() -> Dictionary:
	"""Get current track information"""
	return {
		"is_playing": is_playing,
		"current_beat": current_beat,
		"bpm": BPM,
		"master_volume": master_volume,
		"kick_pattern": kick_pattern,
		"hihat_pattern": hihat_pattern,
		"snare_pattern": snare_pattern,
		"effect_pattern": effect_pattern
	}

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
	print("🎵 TRACK INFO 🎵")
	for key in track_info.keys():
		print("   %s: %s" % [key, str(track_info[key])])

# ===== INPUT CONTROLS =====

func _input(event):
	"""Hotkey controls for the track"""
	if event.is_action_pressed("ui_accept"):      # Space = Start/Stop
		if is_playing:
			stop_track()
		else:
			start_track()
	elif event.is_action_pressed("ui_select"):   # Enter = Info
		info()
	elif event.is_action_pressed("ui_up"):       # Up = Volume up
		set_master_volume(master_volume + 3.0)
		print("🔊 Volume: %.1f dB" % master_volume)
	elif event.is_action_pressed("ui_down"):     # Down = Volume down
		set_master_volume(master_volume - 3.0)
		print("🔉 Volume: %.1f dB" % master_volume)
