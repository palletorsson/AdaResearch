# DarkGameTrackPlayerJSON.gd
# Enhanced version of DarkGameTrackPlayer with JSON pattern loading
# Combines original sound generation with JSON configuration

extends Node

const SAMPLE_RATE = 44100
var BPM: float = 120.0
var BEAT_DURATION: float = 60.0 / BPM

enum TrackSound {
	DARK_808_KICK,
	ACID_606_HIHAT,
	DARK_808_SUB_BASS,
	AMBIENT_DRONE,
	ACID_606_SNARE,
	GLITCH_STAB,
	DEEP_RUMBLE,
	BLADE_RUNNER_HARMONIC
}

# Audio players
var kick_player: AudioStreamPlayer
var hihat_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer
var blade_runner_player: AudioStreamPlayer

# Rhythm system
var beat_timer: Timer
var current_beat: int = 0
var is_playing: bool = false

# JSON-loadable patterns (enhanced from original arrays)
var kick_pattern: Array = []
var hihat_pattern: Array = []
var snare_pattern: Array = []
var effect_pattern: Array = []
var blade_runner_pattern: Array = []

# Pattern properties
var pattern_length: int = 8
var current_config: Dictionary = {}

# Sound cache
var sound_cache: Dictionary = {}

# Track settings (JSON configurable)
@export var config_file: String = "commons/audio/configs/dark_game_track_simple.json"
@export var auto_start: bool = true
@export var loop_track: bool = true

signal track_started()
signal beat_triggered(beat_number: int)

func _ready():
	print("🎵 DARK GAME TRACK PLAYER (JSON Enhanced) 🎵")
	print("Setting up atmospheric 808/606 track with JSON patterns...")
	
	_setup_audio_players()
	_setup_rhythm_system()
	_load_config()
	_generate_all_sounds()
	
	if auto_start:
		call_deferred("start_track")

func _load_config():
	"""Load configuration from JSON file"""
	
	if not FileAccess.file_exists(config_file):
		print("⚠️ Config file not found, using defaults: %s" % config_file)
		_set_default_patterns()
		return
	
	var file = FileAccess.open(config_file, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ Failed to parse JSON, using defaults")
		_set_default_patterns()
		return
	
	current_config = json.data
	print("✅ Loaded config: %s" % current_config.get("name", "Unknown"))
	
	# Apply configuration
	_apply_config()

func _apply_config():
	"""Apply JSON configuration to the track"""
	
	# Set BPM
	if current_config.has("bpm"):
		BPM = current_config.bpm
		BEAT_DURATION = 60.0 / BPM
		print("   🎵 BPM: %d" % BPM)
	
	# Load patterns
	if current_config.has("patterns"):
		_load_patterns_from_config()
	else:
		_set_default_patterns()
	
	# Set volumes
	if current_config.has("volumes"):
		_apply_volume_settings()

func _load_patterns_from_config():
	"""Load rhythm patterns from JSON configuration"""
	
	var patterns = current_config.patterns
	
	# Load kick pattern
	if patterns.has("kick"):
		kick_pattern = _convert_pattern_to_array(patterns.kick)
		print("   🥁 Kick pattern loaded: %d steps" % kick_pattern.size())
	
	# Load hihat pattern
	if patterns.has("hihat"):
		hihat_pattern = _convert_pattern_to_array(patterns.hihat)
		print("   🎩 HiHat pattern loaded: %d steps" % hihat_pattern.size())
	
	# Load snare pattern
	if patterns.has("snare"):
		snare_pattern = _convert_pattern_to_array(patterns.snare)
		print("   🔥 Snare pattern loaded: %d steps" % snare_pattern.size())
	
	# Load effect pattern
	if patterns.has("effect"):
		effect_pattern = _convert_pattern_to_array(patterns.effect)
		print("   ⚡ Effect pattern loaded: %d steps" % effect_pattern.size())
	
	# Load blade runner pattern
	if patterns.has("blade_runner"):
		blade_runner_pattern = _convert_pattern_to_array(patterns.blade_runner)
		print("   🏙️ Blade Runner harmonic pattern loaded: %d steps" % blade_runner_pattern.size())
	
	# Set pattern length to the longest pattern
	var max_length = 8  # Default
	if kick_pattern.size() > max_length:
		max_length = kick_pattern.size()
	if hihat_pattern.size() > max_length:
		max_length = hihat_pattern.size()
	if snare_pattern.size() > max_length:
		max_length = snare_pattern.size()
	if effect_pattern.size() > max_length:
		max_length = effect_pattern.size()
	if blade_runner_pattern.size() > max_length:
		max_length = blade_runner_pattern.size()
	
	pattern_length = max_length
	print("   🎵 Pattern length set to: %d beats" % pattern_length)

func _convert_pattern_to_array(pattern_data) -> Array:
	"""Convert JSON pattern to array format"""
	
	var result: Array = []
	
	if pattern_data is Array:
		# Handle both simple arrays [1,0,1,0] and complex step objects
		for step in pattern_data:
			if step is Dictionary:
				# Complex step: {"active": true, "velocity": 0.8}
				if step.get("active", false):
					result.append(step.get("velocity", 1.0))
				else:
					result.append(0)
			elif step is bool:
				# Boolean step: true/false
				result.append(1 if step else 0)
			else:
				# Numeric step: 1/0
				result.append(step)
	
	return result

func _set_default_patterns():
	"""Set default hardcoded patterns (original)"""
	
	kick_pattern = [1, 0, 0, 0, 1, 0, 1, 0]
	hihat_pattern = [1, 1, 1, 1, 1, 1, 1, 1]
	snare_pattern = [0, 0, 0, 0, 1, 0, 0, 0]
	effect_pattern = [0, 0, 1, 0, 0, 0, 1, 0]
	blade_runner_pattern = [1, 0, 0, 0, 0, 0, 0, 0]  # Long atmospheric hits
	pattern_length = 8
	
	print("   🎵 Using default hardcoded patterns")

func _apply_volume_settings():
	"""Apply volume settings from JSON"""
	
	var volumes = current_config.volumes
	
	if kick_player and volumes.has("kick"):
		kick_player.volume_db = volumes.kick
	
	if hihat_player and volumes.has("hihat"):
		hihat_player.volume_db = volumes.hihat
	
	if bass_player and volumes.has("bass"):
		bass_player.volume_db = volumes.bass
	
	if ambient_player and volumes.has("ambient"):
		ambient_player.volume_db = volumes.ambient
	
	if effect_player and volumes.has("effect"):
		effect_player.volume_db = volumes.effect
	
	if blade_runner_player and volumes.has("blade_runner"):
		blade_runner_player.volume_db = volumes.blade_runner

func _setup_audio_players():
	"""Setup audio players (original system)"""
	
	kick_player = AudioStreamPlayer.new()
	kick_player.name = "KickPlayer"
	add_child(kick_player)
	
	hihat_player = AudioStreamPlayer.new()
	hihat_player.name = "HiHatPlayer"
	add_child(hihat_player)
	
	bass_player = AudioStreamPlayer.new()
	bass_player.name = "BassPlayer"
	add_child(bass_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	add_child(ambient_player)
	
	effect_player = AudioStreamPlayer.new()
	effect_player.name = "EffectPlayer"
	add_child(effect_player)
	
	blade_runner_player = AudioStreamPlayer.new()
	blade_runner_player.name = "BladeRunnerPlayer"
	add_child(blade_runner_player)
	
	print("   ✅ Audio players configured")

func _setup_rhythm_system():
	"""Setup rhythm system"""
	
	beat_timer = Timer.new()
	beat_timer.name = "BeatTimer"
	beat_timer.wait_time = BEAT_DURATION
	beat_timer.one_shot = false
	beat_timer.timeout.connect(_on_beat)
	add_child(beat_timer)
	
	print("   ✅ Rhythm system ready")

func _generate_all_sounds():
	"""Generate all sounds (using original generation code)"""
	print("   🔧 Generating track sounds...")
	
	sound_cache[TrackSound.DARK_808_KICK] = _generate_808_kick_sound(1.5)
	sound_cache[TrackSound.ACID_606_HIHAT] = _generate_606_hihat_sound(0.3)
	sound_cache[TrackSound.ACID_606_SNARE] = _generate_606_snare_sound(0.8)
	sound_cache[TrackSound.GLITCH_STAB] = _generate_glitch_stab_sound(0.4)
	sound_cache[TrackSound.DARK_808_SUB_BASS] = _generate_808_sub_bass_sound(8.0)
	sound_cache[TrackSound.AMBIENT_DRONE] = _generate_ambient_drone_sound(16.0)
	sound_cache[TrackSound.DEEP_RUMBLE] = _generate_deep_rumble_sound(12.0)
	sound_cache[TrackSound.BLADE_RUNNER_HARMONIC] = _generate_blade_runner_harmonic_sound(8.0)
	
	print("   ✅ All sounds generated and cached")

# ===== SOUND GENERATION (Original methods) =====

func _generate_808_kick_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
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
	
	stream.data = data
	return stream

func _generate_606_hihat_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
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
	
	stream.data = data
	return stream

func _generate_606_snare_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
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
	
	stream.data = data
	return stream

func _generate_808_sub_bass_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
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
	
	stream.data = data
	return stream

func _generate_ambient_drone_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var freq1 = 45.0
		var freq2 = 90.0
		var freq3 = 67.5
		var mod = sin(2.0 * PI * 0.13 * t) * 0.3 + 0.7
		
		var layer1 = sin(2.0 * PI * freq1 * t) * 0.5
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.3
		var layer3 = sin(2.0 * PI * freq3 * t) * 0.2
		var detune = sin(2.0 * PI * (freq1 + 0.7) * t) * 0.1
		var sample = (layer1 + layer2 + layer3 + detune) * mod * 0.3
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	
	stream.data = data
	return stream

func _generate_glitch_stab_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 440.0 * (1.0 + sin(2.0 * PI * 50.0 * t) * 0.3)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0.2 else -1.0
		var envelope = exp(-progress * 10.0)
		
		var bit_depth = 6.0
		var crushed = floor(square * pow(2, bit_depth)) / pow(2, bit_depth)
		var sample = crushed * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	
	stream.data = data
	return stream

func _generate_deep_rumble_sound(duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
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
	
	stream.data = data
	return stream

func _generate_blade_runner_harmonic_sound(duration: float) -> AudioStreamWAV:
	"""Generate Blade Runner-style dark harmonic tones"""
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequencies for dark harmonic stack
		var fund_freq = 55.0  # Low A
		var second_freq = 82.4  # Low E
		var third_freq = 110.0  # A one octave up
		
		# Slow modulation for movement (very Blade Runner-esque)
		var slow_lfo = sin(2.0 * PI * 0.07 * t) * 0.4 + 0.6
		var slower_lfo = sin(2.0 * PI * 0.03 * t) * 0.3 + 0.7
		var micro_detune = sin(2.0 * PI * 0.23 * t) * 0.8
		
		# Rich harmonic layers with slight detuning
		var fundamental = sin(2.0 * PI * (fund_freq + micro_detune) * t) * 0.8
		var harmonic2 = sin(2.0 * PI * (fund_freq * 2.0 + micro_detune * 0.7) * t) * 0.4
		var harmonic3 = sin(2.0 * PI * (fund_freq * 3.0 - micro_detune * 0.5) * t) * 0.25
		var harmonic5 = sin(2.0 * PI * (fund_freq * 5.0 + micro_detune * 1.2) * t) * 0.15
		
		# Additional chord tones for richness
		var second_voice = sin(2.0 * PI * (second_freq + micro_detune * 0.6) * t) * 0.6
		var third_voice = sin(2.0 * PI * (third_freq - micro_detune * 0.8) * t) * 0.4
		
		# Sub-harmonic for deep presence
		var sub_harmonic = sin(2.0 * PI * (fund_freq * 0.5) * t) * 0.3
		
		# Atmospheric noise layer
		var noise = (randf() - 0.5) * 0.05 * slower_lfo
		
		# Combine all layers
		var harmonic_stack = fundamental + harmonic2 + harmonic3 + harmonic5
		var chord_layers = second_voice + third_voice + sub_harmonic
		var total_signal = (harmonic_stack + chord_layers + noise) * slow_lfo * slower_lfo
		
		# Long attack and release envelope for atmospheric feel
		var attack_time = 2.0  # 2 seconds attack
		var release_time = 3.0  # 3 seconds release
		var sustain_level = 0.8
		
		var envelope = 1.0
		if t < attack_time:
			envelope = (t / attack_time) * sustain_level
		elif t > (duration - release_time):
			var release_progress = (t - (duration - release_time)) / release_time
			envelope = sustain_level * (1.0 - release_progress)
		else:
			envelope = sustain_level
		
		# Apply gentle saturation for warmth
		var sample = tanh(total_signal * 0.7) * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF
	
	stream.data = data
	return stream

# ===== TRACK CONTROL =====

func start_track():
	if is_playing:
		return
	
	print("🎵 Starting JSON-enhanced dark game track...")
	is_playing = true
	current_beat = 0
	
	_start_ambient_layers()
	beat_timer.wait_time = BEAT_DURATION
	beat_timer.start()
	
	track_started.emit()

func stop_track():
	if not is_playing:
		return
	
	is_playing = false
	beat_timer.stop()
	
	kick_player.stop()
	hihat_player.stop()
	bass_player.stop()
	ambient_player.stop()
	effect_player.stop()
	blade_runner_player.stop()

func _start_ambient_layers():
	ambient_player.stream = sound_cache[TrackSound.AMBIENT_DRONE]
	ambient_player.play()
	
	if ambient_player.stream is AudioStreamWAV:
		ambient_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	await get_tree().create_timer(2.0).timeout
	bass_player.stream = sound_cache[TrackSound.DARK_808_SUB_BASS]
	bass_player.play()
	
	if bass_player.stream is AudioStreamWAV:
		bass_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	# Blade Runner harmonics now only trigger from patterns, not as ambient layer
	print("🎵 Ambient layers started (bass + drone only)")

func _on_beat():
	if not is_playing:
		return
	
	var pattern_pos = current_beat % pattern_length
	
	# Play patterns based on JSON or defaults
	if pattern_pos < kick_pattern.size() and kick_pattern[pattern_pos] > 0:
		kick_player.stream = sound_cache[TrackSound.DARK_808_KICK]
		kick_player.play()
	
	if pattern_pos < hihat_pattern.size() and hihat_pattern[pattern_pos] > 0:
		hihat_player.stream = sound_cache[TrackSound.ACID_606_HIHAT]
		hihat_player.play()
	
	if pattern_pos < snare_pattern.size() and snare_pattern[pattern_pos] > 0:
		effect_player.stream = sound_cache[TrackSound.ACID_606_SNARE]
		effect_player.play()
	
	if pattern_pos < effect_pattern.size() and effect_pattern[pattern_pos] > 0:
		effect_player.stream = sound_cache[TrackSound.GLITCH_STAB]
		effect_player.play()
	
	if pattern_pos < blade_runner_pattern.size() and blade_runner_pattern[pattern_pos] > 0:
		blade_runner_player.stop()  # Stop previous harmonic
		blade_runner_player.stream = sound_cache[TrackSound.BLADE_RUNNER_HARMONIC]
		blade_runner_player.play()
		print("🏙️ Blade Runner harmonic triggered at beat %d (pattern pos %d)" % [current_beat, pattern_pos])
	
	beat_triggered.emit(current_beat)
	current_beat += 1
	
	if current_beat >= (pattern_length * 4):  # 4 loops
		current_beat = 0
		if not loop_track:
			stop_track()

# ===== PUBLIC API =====

func reload_config():
	"""Reload configuration from JSON file"""
	print("🔄 Reloading configuration...")
	_load_config()

func get_pattern_info() -> Dictionary:
	"""Get current pattern information"""
	return {
		"kick_pattern": kick_pattern,
		"hihat_pattern": hihat_pattern,
		"snare_pattern": snare_pattern,
		"effect_pattern": effect_pattern,
		"blade_runner_pattern": blade_runner_pattern,
		"pattern_length": pattern_length,
		"config_file": config_file
	}

func set_bpm(new_bpm: float):
	"""Change BPM in real-time"""
	BPM = new_bpm
	BEAT_DURATION = 60.0 / BPM
	if beat_timer:
		beat_timer.wait_time = BEAT_DURATION
	print("🎵 BPM changed to: %d" % BPM)

func _input(event):
	"""Input controls"""
	if event.is_action_pressed("ui_accept"):
		if is_playing:
			stop_track()
		else:
			start_track()
	elif event.is_action_pressed("ui_select"):
		var info = get_pattern_info()
		print("🎵 PATTERN INFO 🎵")
		for key in info.keys():
			print("   %s: %s" % [key, str(info[key])])
	elif event.is_action_pressed("ui_right"):
		reload_config()
	elif event.is_action_pressed("ui_up"):
		set_bpm(BPM + 5)  # Increase BPM
	elif event.is_action_pressed("ui_down"):
		set_bpm(BPM - 5)  # Decrease BPM 
