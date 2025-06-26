# PolymeterTrackPlayer.gd
# Demonstrates polymeters: 3 against 4 rhythmic patterns
# Creates shifting relationships as downbeats drift apart

extends Node

const SAMPLE_RATE = 44100
const BPM = 128.0
const BEAT_DURATION = 60.0 / BPM

enum TrackSound {
	DEEP_KICK,
	SHARP_SNARE,
	CRISP_HIHAT,
	ANALOG_BASS,
	LEAD_STAB,
	PERCUSSION_HIT,
	AMBIENT_PAD
}

# Audio players for layered track
var kick_player: AudioStreamPlayer
var snare_player: AudioStreamPlayer
var hihat_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var lead_player: AudioStreamPlayer
var perc_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# Polymeter system
var beat_timer: Timer
var current_beat: int = 0
var is_playing: bool = false

# Polymeter patterns - notice different lengths!
var kick_pattern_4: Array = [1, 0, 1, 0]                    # 4-beat pattern
var snare_pattern_3: Array = [0, 1, 0]                      # 3-beat pattern
var hihat_pattern_4: Array = [1, 1, 1, 1]                   # 4-beat pattern
var bass_pattern_3: Array = [1, 0, 1]                       # 3-beat pattern (polymeter!)
var lead_pattern_5: Array = [1, 0, 0, 1, 0]                 # 5-beat pattern (even more complex!)
var perc_pattern_7: Array = [1, 0, 1, 0, 1, 0, 0]           # 7-beat pattern

# Pattern positions for each polymeter
var kick_pos: int = 0
var snare_pos: int = 0
var hihat_pos: int = 0
var bass_pos: int = 0
var lead_pos: int = 0
var perc_pos: int = 0

# Sound cache
var sound_cache: Dictionary = {}

# Track settings
@export var master_volume: float = -3.0
@export var kick_volume: float = 0.0
@export var snare_volume: float = -6.0
@export var hihat_volume: float = -12.0
@export var bass_volume: float = -3.0
@export var lead_volume: float = -9.0
@export var perc_volume: float = -15.0
@export var ambient_volume: float = -18.0

@export var auto_start: bool = true

signal track_started()
signal polymeter_alignment(patterns_aligned: Array)

func _ready():
	print("🎵 POLYMETER TRACK PLAYER 🎵")
	print("Demonstrating 3 vs 4 vs 5 vs 7 beat patterns...")
	
	_setup_audio_players()
	_setup_rhythm_system()
	_generate_all_sounds()
	
	if auto_start:
		call_deferred("start_track")

func _setup_audio_players():
	"""Setup separate audio players for each polymeter element"""
	
	kick_player = AudioStreamPlayer.new()
	kick_player.name = "KickPlayer"
	kick_player.volume_db = kick_volume + master_volume
	add_child(kick_player)
	
	snare_player = AudioStreamPlayer.new()
	snare_player.name = "SnarePlayer"
	snare_player.volume_db = snare_volume + master_volume
	add_child(snare_player)
	
	hihat_player = AudioStreamPlayer.new()
	hihat_player.name = "HiHatPlayer"
	hihat_player.volume_db = hihat_volume + master_volume
	add_child(hihat_player)
	
	bass_player = AudioStreamPlayer.new()
	bass_player.name = "BassPlayer"
	bass_player.volume_db = bass_volume + master_volume
	add_child(bass_player)
	
	lead_player = AudioStreamPlayer.new()
	lead_player.name = "LeadPlayer"
	lead_player.volume_db = lead_volume + master_volume
	add_child(lead_player)
	
	perc_player = AudioStreamPlayer.new()
	perc_player.name = "PercPlayer"
	perc_player.volume_db = perc_volume + master_volume
	add_child(perc_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = ambient_volume + master_volume
	add_child(ambient_player)
	
	print("   ✅ Polymeter audio players configured")

func _setup_rhythm_system():
	"""Setup beat timer for polymeter rhythm"""
	
	beat_timer = Timer.new()
	beat_timer.name = "BeatTimer"
	beat_timer.wait_time = BEAT_DURATION
	beat_timer.one_shot = false
	beat_timer.timeout.connect(_on_beat)
	add_child(beat_timer)
	
	print("   ✅ Polymeter rhythm system ready at %d BPM" % BPM)

func _generate_all_sounds():
	"""Generate sounds optimized for polymeter demonstration"""
	print("   🔧 Generating polymeter sounds...")
	
	sound_cache[TrackSound.DEEP_KICK] = _generate_sound(TrackSound.DEEP_KICK, 0.8)
	sound_cache[TrackSound.SHARP_SNARE] = _generate_sound(TrackSound.SHARP_SNARE, 0.6)
	sound_cache[TrackSound.CRISP_HIHAT] = _generate_sound(TrackSound.CRISP_HIHAT, 0.2)
	sound_cache[TrackSound.ANALOG_BASS] = _generate_sound(TrackSound.ANALOG_BASS, 2.0)
	sound_cache[TrackSound.LEAD_STAB] = _generate_sound(TrackSound.LEAD_STAB, 0.5)
	sound_cache[TrackSound.PERCUSSION_HIT] = _generate_sound(TrackSound.PERCUSSION_HIT, 0.3)
	sound_cache[TrackSound.AMBIENT_PAD] = _generate_sound(TrackSound.AMBIENT_PAD, 8.0)
	
	print("   ✅ All polymeter sounds generated")

func start_track():
	"""Start the polymeter demonstration"""
	if is_playing:
		return
	
	print("🎵 Starting polymeter track...")
	print("   • Kick: 4-beat pattern")
	print("   • Snare: 3-beat pattern") 
	print("   • Bass: 3-beat pattern")
	print("   • Lead: 5-beat pattern")
	print("   • Percussion: 7-beat pattern")
	print("   Watch how they align and drift apart!")
	
	is_playing = true
	current_beat = 0
	
	# Reset all pattern positions
	kick_pos = 0
	snare_pos = 0
	hihat_pos = 0
	bass_pos = 0
	lead_pos = 0
	perc_pos = 0
	
	# Start ambient layer
	ambient_player.stream = sound_cache[TrackSound.AMBIENT_PAD]
	ambient_player.play()
	if ambient_player.stream is AudioStreamWAV:
		ambient_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	# Start polymeter rhythm
	beat_timer.start()
	track_started.emit()

func stop_track():
	"""Stop the polymeter track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping polymeter track...")
	is_playing = false
	beat_timer.stop()
	
	# Stop all players
	kick_player.stop()
	snare_player.stop()
	hihat_player.stop()
	bass_player.stop()
	lead_player.stop()
	perc_player.stop()
	ambient_player.stop()

func _on_beat():
	"""Handle each beat - advance all polymeters independently"""
	if not is_playing:
		return
	
	# Check which patterns are aligned on downbeat
	var aligned_patterns = []
	if kick_pos == 0: aligned_patterns.append("kick")
	if snare_pos == 0: aligned_patterns.append("snare") 
	if bass_pos == 0: aligned_patterns.append("bass")
	if lead_pos == 0: aligned_patterns.append("lead")
	if perc_pos == 0: aligned_patterns.append("perc")
	
	if aligned_patterns.size() > 1:
		print("🎯 Polymeter alignment: %s" % str(aligned_patterns))
		polymeter_alignment.emit(aligned_patterns)
	
	# Play sounds based on current pattern positions
	if kick_pattern_4[kick_pos] == 1:
		kick_player.stream = sound_cache[TrackSound.DEEP_KICK]
		kick_player.play()
	
	if snare_pattern_3[snare_pos] == 1:
		snare_player.stream = sound_cache[TrackSound.SHARP_SNARE]
		snare_player.play()
	
	if hihat_pattern_4[hihat_pos] == 1:
		hihat_player.stream = sound_cache[TrackSound.CRISP_HIHAT]
		hihat_player.play()
	
	if bass_pattern_3[bass_pos] == 1:
		bass_player.stream = sound_cache[TrackSound.ANALOG_BASS]
		bass_player.play()
	
	if lead_pattern_5[lead_pos] == 1:
		lead_player.stream = sound_cache[TrackSound.LEAD_STAB]
		lead_player.play()
	
	if perc_pattern_7[perc_pos] == 1:
		perc_player.stream = sound_cache[TrackSound.PERCUSSION_HIT]
		perc_player.play()
	
	# Advance each pattern position independently (polymeter magic!)
	kick_pos = (kick_pos + 1) % kick_pattern_4.size()
	snare_pos = (snare_pos + 1) % snare_pattern_3.size()
	hihat_pos = (hihat_pos + 1) % hihat_pattern_4.size()
	bass_pos = (bass_pos + 1) % bass_pattern_3.size()
	lead_pos = (lead_pos + 1) % lead_pattern_5.size()
	perc_pos = (perc_pos + 1) % perc_pattern_7.size()
	
	current_beat += 1

func _generate_sound(sound_type: TrackSound, duration: float) -> AudioStreamWAV:
	"""Generate polymeter-optimized sounds"""
	
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	match sound_type:
		TrackSound.DEEP_KICK:
			_generate_deep_kick(data, sample_count)
		TrackSound.SHARP_SNARE:
			_generate_sharp_snare(data, sample_count)
		TrackSound.CRISP_HIHAT:
			_generate_crisp_hihat(data, sample_count)
		TrackSound.ANALOG_BASS:
			_generate_analog_bass(data, sample_count)
		TrackSound.LEAD_STAB:
			_generate_lead_stab(data, sample_count)
		TrackSound.PERCUSSION_HIT:
			_generate_percussion_hit(data, sample_count)
		TrackSound.AMBIENT_PAD:
			_generate_ambient_pad(data, sample_count)
	
	stream.data = data
	return stream

func _generate_deep_kick(data: PackedByteArray, sample_count: int):
	"""Generate deep, punchy kick for 4-beat pattern"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 55.0 - (20.0 * pow(progress, 0.4))
		var sine = sin(2.0 * PI * freq * t)
		var click = sin(2.0 * PI * 2000.0 * t) * exp(-progress * 60.0) * 0.2
		var envelope = exp(-progress * 3.5)
		var sample = tanh((sine + click) * envelope * 1.8) * 0.8
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_sharp_snare(data: PackedByteArray, sample_count: int):
	"""Generate sharp snare for 3-beat pattern"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.8
		var tone = sin(2.0 * PI * 220.0 * t) * 0.5
		var snap = sin(2.0 * PI * 4000.0 * t) * exp(-progress * 25.0) * 0.4
		var envelope = exp(-progress * 10.0)
		var sample = (noise + tone + snap) * envelope * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_crisp_hihat(data: PackedByteArray, sample_count: int):
	"""Generate crisp hi-hat for 4-beat pattern"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 2.0
		var filter_freq = 12000.0 - (4000.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var envelope = exp(-progress * 20.0)
		var sample = filtered * envelope * 0.25
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_analog_bass(data: PackedByteArray, sample_count: int):
	"""Generate analog bass for 3-beat pattern"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 65.0 + sin(2.0 * PI * 0.5 * t) * 8.0
		var saw = 2.0 * (t * freq - floor(t * freq)) - 1.0  # Sawtooth
		var filtered = saw * (1.0 - progress * 0.7)  # Low-pass effect
		var envelope = exp(-progress * 1.5)
		var sample = tanh(filtered * envelope * 2.0) * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_lead_stab(data: PackedByteArray, sample_count: int):
	"""Generate lead stab for 5-beat pattern"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 440.0 * (1.0 + sin(2.0 * PI * 30.0 * t) * 0.1)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0.0 else -1.0
		var envelope = exp(-progress * 8.0)
		var sample = square * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_percussion_hit(data: PackedByteArray, sample_count: int):
	"""Generate percussion hit for 7-beat pattern"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 800.0 - (400.0 * progress)
		var sine = sin(2.0 * PI * freq * t)
		var noise = (randf() - 0.5) * 0.5
		var envelope = exp(-progress * 12.0)
		var sample = (sine + noise) * envelope * 0.3
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_ambient_pad(data: PackedByteArray, sample_count: int):
	"""Generate ambient pad for background"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var freq1 = 110.0
		var freq2 = 165.0  # Perfect fifth
		var freq3 = 220.0  # Octave
		var mod = sin(2.0 * PI * 0.1 * t) * 0.2 + 0.8
		
		var layer1 = sin(2.0 * PI * freq1 * t) * 0.4
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.3
		var layer3 = sin(2.0 * PI * freq3 * t) * 0.2
		var sample = (layer1 + layer2 + layer3) * mod * 0.2
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# Public API
func get_polymeter_info() -> Dictionary:
	"""Get current polymeter state"""
	return {
		"is_playing": is_playing,
		"current_beat": current_beat,
		"kick_pos": kick_pos,
		"snare_pos": snare_pos,
		"bass_pos": bass_pos,
		"lead_pos": lead_pos,
		"perc_pos": perc_pos,
		"patterns": {
			"kick_4": kick_pattern_4,
			"snare_3": snare_pattern_3,
			"bass_3": bass_pattern_3,
			"lead_5": lead_pattern_5,
			"perc_7": perc_pattern_7
		}
	}

func _input(event):
	"""Hotkey controls"""
	if event.is_action_pressed("ui_accept"):
		if is_playing:
			stop_track()
		else:
			start_track()
	elif event.is_action_pressed("ui_select"):
		var info = get_polymeter_info()
		print("🎵 POLYMETER INFO 🎵")
		print("   Beat: %d" % current_beat)
		print("   Positions: K:%d S:%d B:%d L:%d P:%d" % [kick_pos, snare_pos, bass_pos, lead_pos, perc_pos]) 
