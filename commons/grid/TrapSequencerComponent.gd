extends Node

# TrapSequencerComponent - Automated trap beat sequencer with real-time control
# Integrates with GridSystem for map-based ambient trap soundtracks
#
# Provides:
# - Automated pattern playback
# - Real-time BPM control
# - Swing/groove adjustment
# - Pattern variation and randomization
# - Per-track volume and mute
# - Sequence transitions

class_name TrapSequencerComponent

# Signals
signal beat_triggered(beat_number: int)
signal pattern_changed(pattern_name: String)
signal bpm_changed(new_bpm: float)
signal sequencer_started()
signal sequencer_stopped()

# Configuration
var config: Dictionary = {}
var current_pattern: Dictionary = {}
var pattern_name: String = ""

# Timing
var bpm: float = 85.0  # Default trap tempo
var step_duration: float = 0.0
var current_step: int = 0
var current_bar: int = 0
var is_playing: bool = false

# Control parameters
var swing_amount: float = 0.0  # 0.0 - 1.0
var pattern_variation: float = 0.0  # 0.0 - 1.0 (randomization)
var master_volume: float = 0.0  # dB

# Track controls
var track_volumes: Dictionary = {
	"kick": 0.0,
	"snare": 0.0,
	"hihat": 0.0,
	"perc": 0.0
}

var track_mutes: Dictionary = {
	"kick": false,
	"snare": false,
	"hihat": false,
	"perc": false
}

# Audio players (pooled)
var kick_players: Array = []
var snare_players: Array = []
var hihat_players: Array = []
var perc_players: Array = []
var player_pool_size: int = 4

# Timers
var step_timer: Timer
var rng: RandomNumberGenerator

# Error tracking
var soundbank_warning_shown: bool = false

func _init():
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _ready():
	_setup_timers()
	_setup_audio_players()

func _exit_tree():
	stop()

# ===== INITIALIZATION =====

func _setup_timers():
	"""Setup step timer for sequencer"""
	step_timer = Timer.new()
	add_child(step_timer)
	step_timer.timeout.connect(_on_step_timer_timeout)

func _setup_audio_players():
	"""Setup pooled audio players for each track"""
	# Kick players
	for i in range(player_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = config.get("kick_bus", "Master")
		add_child(player)
		kick_players.append(player)

	# Snare players
	for i in range(player_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = config.get("snare_bus", "Master")
		add_child(player)
		snare_players.append(player)

	# Hi-hat players
	for i in range(player_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = config.get("hihat_bus", "Master")
		add_child(player)
		hihat_players.append(player)

	# Percussion players
	for i in range(player_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = config.get("perc_bus", "Master")
		add_child(player)
		perc_players.append(player)

# ===== CONFIGURATION =====

func initialize(sequencer_config: Dictionary):
	"""Initialize sequencer with configuration"""
	config = sequencer_config

	# Load pattern
	pattern_name = config.get("pattern", "minimal_trap")
	_load_pattern(pattern_name)

	# Set initial parameters
	bpm = config.get("bpm", 85.0)
	swing_amount = config.get("swing", 0.0)
	pattern_variation = config.get("variation", 0.0)
	master_volume = config.get("master_volume", 0.0)

	# Set track volumes
	if config.has("track_volumes"):
		for track in config["track_volumes"]:
			track_volumes[track] = config["track_volumes"][track]

	# Calculate step duration
	_update_timing()

	print("🥁 TrapSequencer initialized: %s @ %.0f BPM" % [pattern_name, bpm])

func _load_pattern(pattern_id: String):
	"""Load a pattern from configuration or presets"""
	if config.has("custom_pattern"):
		current_pattern = config["custom_pattern"]
	else:
		# Load from preset patterns
		current_pattern = _get_preset_pattern(pattern_id)

	print("✅ Loaded pattern: %s (%d steps)" % [pattern_id, current_pattern.get("steps", 16)])

func _get_preset_pattern(pattern_id: String) -> Dictionary:
	"""Get a preset pattern by ID"""
	var patterns = {
		"minimal_trap": {
			"steps": 16,
			"kick": [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0],
			"snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
			"hihat_closed": [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
			"hihat_open": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
		},
		"hard_trap": {
			"steps": 16,
			"kick": [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0],
			"snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
			"clap": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
			"hihat_closed": [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
			"hihat_open": [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1]
		},
		"triplet_trap": {
			"steps": 24,  # Triplet feel
			"kick": [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"snare": [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
			"hihat_closed": [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0]
		},
		"drill": {
			"steps": 32,
			"kick": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
			"snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"hihat_closed": [1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1],
			"808_rim": [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]
		},
		"ambient_sparse": {
			"steps": 16,
			"kick": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"hihat_closed": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"808_rim": [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
		}
	}

	return patterns.get(pattern_id, patterns["minimal_trap"])

# ===== PLAYBACK CONTROL =====

func start():
	"""Start the sequencer"""
	if is_playing:
		return

	is_playing = true
	current_step = 0
	current_bar = 0

	step_timer.start(step_duration)

	sequencer_started.emit()
	print("▶️ Sequencer started: %s @ %.0f BPM" % [pattern_name, bpm])

func stop():
	"""Stop the sequencer"""
	if not is_playing:
		return

	is_playing = false
	step_timer.stop()

	# Stop all players
	_stop_all_players()

	sequencer_stopped.emit()
	print("⏹️ Sequencer stopped")

func _stop_all_players():
	"""Stop all audio players"""
	for player in kick_players + snare_players + hihat_players + perc_players:
		if player.playing:
			player.stop()

# ===== TIMING =====

func _update_timing():
	"""Update step duration based on BPM"""
	# 16th note steps
	var beats_per_second = bpm / 60.0
	var seconds_per_beat = 1.0 / beats_per_second
	step_duration = seconds_per_beat / 4.0  # 16th notes

func _on_step_timer_timeout():
	"""Called on each step"""
	if not is_playing:
		return

	# Trigger sounds for this step
	_process_step(current_step)

	# Advance to next step
	current_step += 1
	var pattern_steps = current_pattern.get("steps", 16)

	if current_step >= pattern_steps:
		current_step = 0
		current_bar += 1

	# Emit beat signal (every 4 steps = 1 beat)
	if current_step % 4 == 0:
		beat_triggered.emit(current_step / 4)

	# Apply swing by adjusting next timer wait time
	var is_next_odd_step = (current_step % 2) == 1
	if is_next_odd_step and swing_amount > 0.0:
		# Delay odd steps for swing feel
		step_timer.wait_time = step_duration * (1.0 + swing_amount * 0.3)
	else:
		# Even steps are slightly earlier to compensate
		if swing_amount > 0.0:
			step_timer.wait_time = step_duration * (1.0 - swing_amount * 0.15)
		else:
			step_timer.wait_time = step_duration

func _process_step(step: int):
	"""Process a single step - trigger sounds"""
	# Bounds check
	var pattern_steps = current_pattern.get("steps", 16)
	if step >= pattern_steps:
		return

	# Kick
	if current_pattern.has("kick") and step < current_pattern["kick"].size() and current_pattern["kick"][step] == 1:
		if not track_mutes.get("kick", false):
			if rng.randf() > pattern_variation * 0.3:  # Variation can skip hits
				_play_sound("kick", "trap_beats.808_kick")

	# Snare
	if current_pattern.has("snare") and step < current_pattern["snare"].size() and current_pattern["snare"][step] == 1:
		if not track_mutes.get("snare", false):
			if rng.randf() > pattern_variation * 0.3:
				_play_sound("snare", "trap_beats.trap_snare")

	# Clap
	if current_pattern.has("clap") and step < current_pattern["clap"].size() and current_pattern["clap"][step] == 1:
		if not track_mutes.get("snare", false):  # Clap uses snare mute
			if rng.randf() > pattern_variation * 0.3:
				_play_sound("snare", "trap_beats.clap")

	# Closed Hi-Hat
	if current_pattern.has("hihat_closed") and step < current_pattern["hihat_closed"].size() and current_pattern["hihat_closed"][step] == 1:
		if not track_mutes.get("hihat", false):
			if rng.randf() > pattern_variation * 0.2:
				_play_sound("hihat", "trap_beats.hihat_closed")

	# Open Hi-Hat
	if current_pattern.has("hihat_open") and step < current_pattern["hihat_open"].size() and current_pattern["hihat_open"][step] == 1:
		if not track_mutes.get("hihat", false):
			if rng.randf() > pattern_variation * 0.2:
				_play_sound("hihat", "trap_beats.hihat_open")

	# 808 Rim
	if current_pattern.has("808_rim") and step < current_pattern["808_rim"].size() and current_pattern["808_rim"][step] == 1:
		if not track_mutes.get("perc", false):
			if rng.randf() > pattern_variation * 0.2:
				_play_sound("perc", "trap_beats.808_rim")

	# Cowbell
	if current_pattern.has("808_cowbell") and step < current_pattern["808_cowbell"].size() and current_pattern["808_cowbell"][step] == 1:
		if not track_mutes.get("perc", false):
			if rng.randf() > pattern_variation * 0.2:
				_play_sound("perc", "trap_beats.808_cowbell")

	# Tom
	if current_pattern.has("trap_tom") and step < current_pattern["trap_tom"].size() and current_pattern["trap_tom"][step] == 1:
		if not track_mutes.get("perc", false):
			if rng.randf() > pattern_variation * 0.2:
				_play_sound("perc", "trap_beats.trap_tom")

func _play_sound(track: String, sound_id: String):
	"""Play a sound on the specified track"""
	# Check if SoundBank exists
	if not has_node("/root/SoundBank"):
		if not soundbank_warning_shown:
			push_warning("TrapSequencer: SoundBank singleton not found. Add SoundBankSingleton as AutoLoad.")
			soundbank_warning_shown = true
		return

	# Get sound from SoundBank
	var sound_bank = get_node("/root/SoundBank")
	var sound = sound_bank.get_sound(sound_id)
	if not sound:
		push_warning("TrapSequencer: Failed to generate sound: " + sound_id)
		return

	# Get appropriate player pool
	var players = []
	match track:
		"kick": players = kick_players
		"snare": players = snare_players
		"hihat": players = hihat_players
		"perc": players = perc_players

	# Find available player
	var player = _get_available_player(players)
	if not player:
		return

	# Apply track volume + master volume
	var track_vol = track_volumes.get(track, 0.0)
	player.volume_db = master_volume + track_vol

	# Apply variation to volume
	if pattern_variation > 0.0:
		var variation_db = rng.randf_range(-pattern_variation * 6.0, pattern_variation * 3.0)
		player.volume_db += variation_db

	# Play
	player.stream = sound
	player.play()

func _get_available_player(players: Array) -> AudioStreamPlayer:
	"""Get an available player from pool"""
	for player in players:
		if not player.playing:
			return player
	# If all busy, use first one
	return players[0]

# ===== REAL-TIME CONTROL =====

func set_bpm(new_bpm: float):
	"""Change BPM in real-time"""
	bpm = clamp(new_bpm, 40.0, 200.0)
	_update_timing()

	if is_playing:
		step_timer.wait_time = step_duration

	bpm_changed.emit(bpm)

func set_swing(amount: float):
	"""Set swing amount (0.0 - 1.0)"""
	swing_amount = clamp(amount, 0.0, 1.0)

func set_variation(amount: float):
	"""Set pattern variation/randomization (0.0 - 1.0)"""
	pattern_variation = clamp(amount, 0.0, 1.0)

func set_master_volume(volume_db: float):
	"""Set master volume"""
	master_volume = clamp(volume_db, -60.0, 6.0)

func set_track_volume(track: String, volume_db: float):
	"""Set individual track volume"""
	if track in track_volumes:
		track_volumes[track] = clamp(volume_db, -60.0, 6.0)

func mute_track(track: String, muted: bool):
	"""Mute/unmute a track"""
	if track in track_mutes:
		track_mutes[track] = muted

func change_pattern(new_pattern: String):
	"""Change to a different pattern"""
	var was_playing = is_playing
	if was_playing:
		stop()

	pattern_name = new_pattern
	_load_pattern(new_pattern)

	if was_playing:
		start()

	pattern_changed.emit(new_pattern)

# ===== INFO =====

func get_info() -> Dictionary:
	"""Get current sequencer info"""
	return {
		"is_playing": is_playing,
		"pattern": pattern_name,
		"bpm": bpm,
		"swing": swing_amount,
		"variation": pattern_variation,
		"current_step": current_step,
		"current_bar": current_bar,
		"master_volume": master_volume,
		"track_volumes": track_volumes,
		"track_mutes": track_mutes
	}

func print_info():
	"""Print sequencer status"""
	var info = get_info()
	print("🥁 TRAP SEQUENCER INFO")
	print("   Pattern: %s" % info["pattern"])
	print("   BPM: %.1f" % info["bpm"])
	print("   Playing: %s" % info["is_playing"])
	print("   Step: %d | Bar: %d" % [info["current_step"], info["current_bar"]])
	print("   Swing: %.2f | Variation: %.2f" % [info["swing"], info["variation"]])
