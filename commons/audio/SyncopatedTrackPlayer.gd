# SyncopatedTrackPlayer.gd
# Demonstrates heavy syncopation and ghost notes
# Focus on weak beats, offbeats, and rhythmic tension

extends Node

const SAMPLE_RATE = 44100
const BPM = 110.0  # Slower BPM to feel the syncopation better
const BEAT_DURATION = 60.0 / BPM
const SIXTEENTH_DURATION = BEAT_DURATION / 4.0

enum TrackSound {
	SPINE_KICK,
	SPINE_SNARE,
	SPINE_HIHAT,
	GHOST_SNARE,
	ACCENT_KICK,
	SYNCO_PERC,
	OFFBEAT_STAB,
	WEAK_TOM
}

# Audio players for different rhythmic roles
var spine_player: AudioStreamPlayer      # Main "spine beat" 
var ghost_player: AudioStreamPlayer      # Ghost notes (quiet)
var accent_player: AudioStreamPlayer     # Accent hits (loud)
var synco_player: AudioStreamPlayer      # Syncopated elements
var offbeat_player: AudioStreamPlayer    # Offbeat elements

# Syncopation system
var sixteenth_timer: Timer  # 16th note precision for syncopation
var current_sixteenth: int = 0
var is_playing: bool = false

# Syncopated patterns (16 sixteenth notes = 4 beats)
# 1=strong, 2=medium, 3=ghost, 0=silence
var spine_kick_pattern: Array = [3, 0, 0, 0, 3, 0, 2, 0, 3, 0, 0, 0, 3, 0, 1, 0]    # Syncopated kicks
var spine_snare_pattern: Array = [0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0]   # Backbeats
var ghost_snare_pattern: Array = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]   # Ghost snares on offbeats
var accent_pattern: Array = [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0]        # Accent hits
var synco_perc_pattern: Array = [0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]    # Syncopated percussion
var offbeat_stab_pattern: Array = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]  # Offbeat stabs

# Sound cache
var sound_cache: Dictionary = {}

# Track settings
@export var master_volume: float = 0.0
@export var spine_volume: float = 0.0
@export var ghost_volume: float = 0.0    # Very quiet ghost notes
@export var accent_volume: float = 0.0     # Loud accents
@export var synco_volume: float = 0.0     # Medium syncopation
@export var offbeat_volume: float = 0.0  # Quiet offbeats

@export var auto_start: bool = true
@export var swing_amount: float = 0.15     # 16th note swing

signal track_started()
signal syncopation_hit(pattern_name: String, intensity: int)

func _ready():
	print("🎵 SYNCOPATED TRACK PLAYER 🎵")
	print("Demonstrating syncopation, ghost notes, and weak beats...")
	
	_setup_audio_players()
	_setup_rhythm_system()
	_generate_all_sounds()
	
	if auto_start:
		call_deferred("start_track")

func _setup_audio_players():
	"""Setup players for different syncopation roles"""
	
	# Spine beat player (main rhythm)
	spine_player = AudioStreamPlayer.new()
	spine_player.name = "SpinePlayer"
	spine_player.volume_db = spine_volume + master_volume
	add_child(spine_player)
	
	# Ghost notes player (quiet fills)
	ghost_player = AudioStreamPlayer.new()
	ghost_player.name = "GhostPlayer"
	ghost_player.volume_db = ghost_volume + master_volume
	add_child(ghost_player)
	
	# Accent player (strong hits)
	accent_player = AudioStreamPlayer.new()
	accent_player.name = "AccentPlayer"
	accent_player.volume_db = accent_volume + master_volume
	add_child(accent_player)
	
	# Syncopation player (rhythmic tension)
	synco_player = AudioStreamPlayer.new()
	synco_player.name = "SyncoPlayer"
	synco_player.volume_db = synco_volume + master_volume
	add_child(synco_player)
	
	# Offbeat player (between main beats)
	offbeat_player = AudioStreamPlayer.new()
	offbeat_player.name = "OffbeatPlayer"
	offbeat_player.volume_db = offbeat_volume + master_volume
	add_child(offbeat_player)
	
	print("   ✅ Syncopation audio players configured")

func _setup_rhythm_system():
	"""Setup 16th note timer for syncopation precision"""
	
	sixteenth_timer = Timer.new()
	sixteenth_timer.name = "SixteenthTimer"
	sixteenth_timer.wait_time = SIXTEENTH_DURATION
	sixteenth_timer.one_shot = false
	sixteenth_timer.timeout.connect(_on_sixteenth)
	add_child(sixteenth_timer)
	
	print("   ✅ Syncopation rhythm system ready at %d BPM" % BPM)
	print("   🎵 16th note precision with %.1f%% swing" % (swing_amount * 100))

func _generate_all_sounds():
	"""Generate sounds optimized for syncopation demonstration"""
	print("   🔧 Generating syncopation sounds...")
	
	sound_cache[TrackSound.SPINE_KICK] = _generate_sound(TrackSound.SPINE_KICK, 0.6)
	sound_cache[TrackSound.SPINE_SNARE] = _generate_sound(TrackSound.SPINE_SNARE, 0.5)
	sound_cache[TrackSound.SPINE_HIHAT] = _generate_sound(TrackSound.SPINE_HIHAT, 0.15)
	sound_cache[TrackSound.GHOST_SNARE] = _generate_sound(TrackSound.GHOST_SNARE, 0.3)
	sound_cache[TrackSound.ACCENT_KICK] = _generate_sound(TrackSound.ACCENT_KICK, 0.8)
	sound_cache[TrackSound.SYNCO_PERC] = _generate_sound(TrackSound.SYNCO_PERC, 0.4)
	sound_cache[TrackSound.OFFBEAT_STAB] = _generate_sound(TrackSound.OFFBEAT_STAB, 0.3)
	sound_cache[TrackSound.WEAK_TOM] = _generate_sound(TrackSound.WEAK_TOM, 0.5)
	
	print("   ✅ All syncopation sounds generated")

func start_track():
	"""Start the syncopated track"""
	if is_playing:
		return
	
	print("🎵 Starting syncopated track...")
	print("   • Focus on the 'e's and 'a's (weak 16th notes)")
	print("   • Ghost snares create rhythmic texture")
	print("   • Accents create surprise and tension")
	print("   • %.1f%% swing adds groove" % (swing_amount * 100))
	
	is_playing = true
	current_sixteenth = 0
	
	# Start syncopated rhythm
	sixteenth_timer.start()
	track_started.emit()

func stop_track():
	"""Stop the syncopated track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping syncopated track...")
	is_playing = false
	sixteenth_timer.stop()
	
	# Stop all players
	spine_player.stop()
	ghost_player.stop()
	accent_player.stop()
	synco_player.stop()
	offbeat_player.stop()

func _on_sixteenth():
	"""Handle each 16th note for maximum syncopation precision"""
	if not is_playing:
		return
	
	var pattern_pos = current_sixteenth % 16
	
	# Apply swing to odd 16th notes (the "e" and "a")
	if pattern_pos % 2 == 1:  # Odd positions get delayed for swing
		await get_tree().create_timer(SIXTEENTH_DURATION * swing_amount).timeout
	
	# Spine beat elements (main rhythm foundation)
	var kick_intensity = spine_kick_pattern[pattern_pos]
	if kick_intensity > 0:
		spine_player.stream = sound_cache[TrackSound.SPINE_KICK]
		spine_player.volume_db = spine_volume + master_volume - (3 - kick_intensity) * 6  # Quieter for lower intensity
		spine_player.play()
		syncopation_hit.emit("spine_kick", kick_intensity)
	
	var snare_intensity = spine_snare_pattern[pattern_pos]
	if snare_intensity > 0:
		spine_player.stream = sound_cache[TrackSound.SPINE_SNARE]
		spine_player.volume_db = spine_volume + master_volume - (3 - snare_intensity) * 6
		spine_player.play()
		syncopation_hit.emit("spine_snare", snare_intensity)
	
	# Ghost notes (quiet rhythmic texture)
	var ghost_intensity = ghost_snare_pattern[pattern_pos]
	if ghost_intensity > 0:
		ghost_player.stream = sound_cache[TrackSound.GHOST_SNARE]
		ghost_player.play()
		syncopation_hit.emit("ghost_snare", ghost_intensity)
	
	# Accent hits (surprise and tension)
	var accent_intensity = accent_pattern[pattern_pos]
	if accent_intensity > 0:
		accent_player.stream = sound_cache[TrackSound.ACCENT_KICK]
		accent_player.volume_db = accent_volume + master_volume - (3 - accent_intensity) * 4
		accent_player.play()
		syncopation_hit.emit("accent", accent_intensity)
	
	# Syncopated percussion (rhythmic complexity)
	var synco_intensity = synco_perc_pattern[pattern_pos]
	if synco_intensity > 0:
		synco_player.stream = sound_cache[TrackSound.SYNCO_PERC]
		synco_player.play()
		syncopation_hit.emit("synco_perc", synco_intensity)
	
	# Offbeat stabs (between main beats)
	var offbeat_intensity = offbeat_stab_pattern[pattern_pos]
	if offbeat_intensity > 0:
		offbeat_player.stream = sound_cache[TrackSound.OFFBEAT_STAB]
		offbeat_player.volume_db = offbeat_volume + master_volume - (3 - offbeat_intensity) * 3
		offbeat_player.play()
		syncopation_hit.emit("offbeat_stab", offbeat_intensity)
	
	current_sixteenth += 1
	
	# Print beat positions for educational purposes
	if pattern_pos == 0:
		print("🎵 Beat positions: 1-e-and-a-2-e-and-a-3-e-and-a-4-e-and-a")
	if pattern_pos % 4 == 0:
		var beat_num = (pattern_pos / 4) + 1
		print("   %d" % beat_num)

func _generate_sound(sound_type: TrackSound, duration: float) -> AudioStreamWAV:
	"""Generate syncopation-optimized sounds"""
	
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	match sound_type:
		TrackSound.SPINE_KICK:
			_generate_spine_kick(data, sample_count)
		TrackSound.SPINE_SNARE:
			_generate_spine_snare(data, sample_count)
		TrackSound.SPINE_HIHAT:
			_generate_spine_hihat(data, sample_count)
		TrackSound.GHOST_SNARE:
			_generate_ghost_snare(data, sample_count)
		TrackSound.ACCENT_KICK:
			_generate_accent_kick(data, sample_count)
		TrackSound.SYNCO_PERC:
			_generate_synco_perc(data, sample_count)
		TrackSound.OFFBEAT_STAB:
			_generate_offbeat_stab(data, sample_count)
		TrackSound.WEAK_TOM:
			_generate_weak_tom(data, sample_count)
	
	stream.data = data
	return stream

func _generate_spine_kick(data: PackedByteArray, sample_count: int):
	"""Generate main kick for spine beat"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 70.0 - (30.0 * pow(progress, 0.3))
		var sine = sin(2.0 * PI * freq * t)
		var click = sin(2.0 * PI * 1800.0 * t) * exp(-progress * 50.0) * 0.15
		var envelope = exp(-progress * 4.0)
		var sample = tanh((sine + click) * envelope * 1.2) * 0.7
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_spine_snare(data: PackedByteArray, sample_count: int):
	"""Generate main snare for spine beat"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.6
		var tone = sin(2.0 * PI * 250.0 * t) * 0.4
		var snap = sin(2.0 * PI * 3500.0 * t) * exp(-progress * 30.0) * 0.3
		var envelope = exp(-progress * 8.0)
		var sample = (noise + tone + snap) * envelope * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_spine_hihat(data: PackedByteArray, sample_count: int):
	"""Generate hi-hat for spine beat"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.8
		var filter_freq = 10000.0 - (3000.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var envelope = exp(-progress * 18.0)
		var sample = filtered * envelope * 0.2
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_ghost_snare(data: PackedByteArray, sample_count: int):
	"""Generate quiet ghost snare for texture"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 0.8  # Much quieter
		var tone = sin(2.0 * PI * 200.0 * t) * 0.2
		var envelope = exp(-progress * 12.0)
		var sample = (noise + tone) * envelope * 0.3  # Very subtle
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_accent_kick(data: PackedByteArray, sample_count: int):
	"""Generate loud accent kick for surprise"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 80.0 - (35.0 * pow(progress, 0.2))
		var sine = sin(2.0 * PI * freq * t)
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.3  # Sub harmonic
		var click = sin(2.0 * PI * 2200.0 * t) * exp(-progress * 40.0) * 0.2
		var envelope = exp(-progress * 3.0)
		var sample = tanh((sine + sub + click) * envelope * 2.0) * 0.9  # Louder
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_synco_perc(data: PackedByteArray, sample_count: int):
	"""Generate syncopated percussion"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 600.0 - (200.0 * progress)
		var triangle = (2.0 / PI) * asin(sin(2.0 * PI * freq * t))  # Triangle wave
		var noise = (randf() - 0.5) * 0.3
		var envelope = exp(-progress * 8.0)
		var sample = (triangle + noise) * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_offbeat_stab(data: PackedByteArray, sample_count: int):
	"""Generate offbeat stab"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 330.0 * (1.0 + sin(2.0 * PI * 40.0 * t) * 0.2)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0.1 else -1.0
		var envelope = exp(-progress * 12.0)
		var sample = square * envelope * 0.35
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_weak_tom(data: PackedByteArray, sample_count: int):
	"""Generate weak tom for fills"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 150.0 - (50.0 * progress)
		var sine = sin(2.0 * PI * freq * t)
		var noise = (randf() - 0.5) * 0.4
		var envelope = exp(-progress * 6.0)
		var sample = (sine + noise) * envelope * 0.5
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# Public API
func set_swing(amount: float):
	"""Adjust swing amount (0.0 to 0.5)"""
	swing_amount = clamp(amount, 0.0, 0.5)
	print("🎵 Swing set to %.1f%%" % (swing_amount * 100))

func get_syncopation_info() -> Dictionary:
	"""Get current syncopation state"""
	return {
		"is_playing": is_playing,
		"current_sixteenth": current_sixteenth,
		"pattern_position": current_sixteenth % 16,
		"swing_amount": swing_amount,
		"patterns": {
			"spine_kick": spine_kick_pattern,
			"spine_snare": spine_snare_pattern,
			"ghost_snare": ghost_snare_pattern,
			"accent": accent_pattern,
			"synco_perc": synco_perc_pattern,
			"offbeat_stab": offbeat_stab_pattern
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
		var info = get_syncopation_info()
		print("🎵 SYNCOPATION INFO 🎵")
		print("   16th: %d, Position: %d" % [current_sixteenth, info.pattern_position])
		print("   Swing: %.1f%%" % (swing_amount * 100))
	elif event.is_action_pressed("ui_right"):
		set_swing(swing_amount + 0.05)
	elif event.is_action_pressed("ui_left"):
		set_swing(swing_amount - 0.05) 
