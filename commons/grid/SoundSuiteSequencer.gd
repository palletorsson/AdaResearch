extends Node
class_name GridSoundSuiteSequencer

## Sound Suite Sequencer
## Bridges audio catalog sound generation with pattern sequencing
## Allows selection of different sound suites (trap, tech noir, liturgical)
## with individual parameter control and pattern deployment

signal beat_triggered(beat_number: int)
signal pattern_changed(pattern_name: String)
signal suite_changed(suite_name: String)
signal bpm_changed(new_bpm: float)

# Available sound suites
const SOUND_SUITES = {
	"trap_beats": {
		"kick": "808_kick",
		"snare": "trap_snare",
		"hihat_closed": "trap_hihat",
		"hihat_open": "open_hihat",
		"clap": "trap_clap",
		"rim": "808_rim",
		"tom": "trap_tom",
		"cowbell": "808_cowbell"
	},
	"tech_noir": {
		"drone": "endless_drone",
		"city": "city_ambience",
		"siren": "distant_siren",
		"static": "static_burst",
		"rain": "rain_segment",
		"mechanical": "mechanical_whir",
		"typing": "typing_segment",
		"hum": "electric_hum",
		"heartbeat": "heartbeat_segment"
	}
	# Future: liturgical, dark_game_track, etc.
}

# Current configuration
var current_suite: String = "trap_beats"
var current_pattern: Dictionary = {}
var is_playing: bool = false
var bpm: float = 120.0
var swing_amount: float = 0.0
var variation: float = 0.1

# Sound parameters for current suite
var sound_params: Dictionary = {}

# Pattern sequencing
var step_timer: Timer
var current_step: int = 0
var pattern_length: int = 16

# Audio players pool
var audio_players: Dictionary = {}
var soundbank_warning_shown: bool = false

# Beat counting
var beat_count: int = 0

func _ready():
	# Create step timer
	step_timer = Timer.new()
	add_child(step_timer)
	step_timer.timeout.connect(_on_step_timer_timeout)

	# Initialize default suite
	_initialize_suite(current_suite)

## Initialize sequencer with configuration
func initialize(config: Dictionary):
	if config.has("suite"):
		change_suite(config["suite"])

	if config.has("pattern"):
		load_pattern(config["pattern"])

	if config.has("bpm"):
		set_bpm(config["bpm"])

	if config.has("swing"):
		swing_amount = clampf(config["swing"], 0.0, 1.0)

	if config.has("variation"):
		variation = clampf(config["variation"], 0.0, 1.0)

	if config.has("sound_params"):
		sound_params = config["sound_params"]

## Change sound suite
func change_suite(suite_name: String):
	if not SOUND_SUITES.has(suite_name):
		push_warning("Unknown suite: %s" % suite_name)
		return

	var was_playing = is_playing
	if was_playing:
		stop()

	current_suite = suite_name
	_initialize_suite(suite_name)

	suite_changed.emit(suite_name)
	print("🎨 Switched to suite: %s" % suite_name)

	if was_playing:
		start()

## Initialize suite (create audio players for each sound)
func _initialize_suite(suite_name: String):
	# Clear old players
	for player in audio_players.values():
		player.queue_free()
	audio_players.clear()

	# Create players for new suite
	var suite = SOUND_SUITES[suite_name]
	for track_name in suite.keys():
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players[track_name] = player

## Load a pattern (can be from PatternSequencer or manual)
func load_pattern(pattern_data):
	if pattern_data is String:
		# Load preset pattern by name
		current_pattern = _get_preset_pattern(pattern_data)
	elif pattern_data is Dictionary:
		# Load custom pattern
		current_pattern = pattern_data

	if current_pattern.has("length"):
		pattern_length = current_pattern["length"]

	pattern_changed.emit(str(pattern_data))

## Get preset pattern (integrates with existing patterns)
func _get_preset_pattern(pattern_name: String) -> Dictionary:
	# Check if PatternSequencer exists and can generate
	var PatternSeq = load("res://commons/audio/compositions/systems/PatternSequencer.gd")
	if PatternSeq:
		var ps = PatternSeq.new()

		# Create pattern based on current suite
		if current_suite == "trap_beats":
			return _generate_trap_pattern(ps, pattern_name)
		elif current_suite == "tech_noir":
			return _generate_ambient_pattern(ps, pattern_name)

	# Fallback to built-in patterns
	return _get_builtin_pattern(pattern_name)

## Generate trap beat pattern
func _generate_trap_pattern(ps, style: String) -> Dictionary:
	var pattern = ps.create_pattern(style, 16)

	match style:
		"minimal":
			ps.generate_kick_pattern(pattern, "four_floor")
			ps.generate_snare_pattern(pattern, "two_four")
			ps.generate_hihat_pattern(pattern, "eighth")
		"hard":
			ps.generate_kick_pattern(pattern, "trap")
			ps.generate_snare_pattern(pattern, "trap")
			ps.generate_hihat_pattern(pattern, "trap_rolls")
		"drill":
			pattern.length = 32
			ps.generate_kick_pattern(pattern, "drill")
			ps.generate_snare_pattern(pattern, "trap")
			ps.generate_hihat_pattern(pattern, "trap_rolls")
		_:
			ps.generate_kick_pattern(pattern, "trap")
			ps.generate_snare_pattern(pattern, "trap")
			ps.generate_hihat_pattern(pattern, "trap_rolls")

	# Convert PatternSequencer format to our format
	return _convert_pattern_sequencer_pattern(pattern)

## Generate ambient/atmospheric pattern
func _generate_ambient_pattern(ps, style: String) -> Dictionary:
	var pattern = ps.create_pattern(style, 32)
	pattern.length = 32

	# Sparse, atmospheric triggering
	# Use euclidean rhythms for organic feel
	ps.generate_euclidean_rhythm(pattern, 3, 32)  # Very sparse

	return _convert_pattern_sequencer_pattern(pattern)

## Convert PatternSequencer pattern to our format
func _convert_pattern_sequencer_pattern(ps_pattern) -> Dictionary:
	var result = {
		"length": ps_pattern.length,
	}

	# Map PatternSequencer tracks to our suite tracks
	var suite = SOUND_SUITES[current_suite]

	for track_name in suite.keys():
		result[track_name] = []

		# Try to find matching pattern data
		var ps_track = null
		if ps_pattern.steps.has(track_name):
			ps_track = ps_pattern.steps[track_name]
		elif track_name == "kick" and ps_pattern.steps.has("kick"):
			ps_track = ps_pattern.steps["kick"]
		elif track_name == "snare" and ps_pattern.steps.has("snare"):
			ps_track = ps_pattern.steps["snare"]
		elif track_name in ["hihat_closed", "hihat"] and ps_pattern.steps.has("hihat"):
			ps_track = ps_pattern.steps["hihat"]

		# Convert to our format
		if ps_track:
			result[track_name] = ps_track.duplicate()
		else:
			# Empty pattern
			for i in range(ps_pattern.length):
				result[track_name].append(0)

	return result

## Get built-in fallback patterns
func _get_builtin_pattern(pattern_name: String) -> Dictionary:
	match pattern_name:
		"minimal_trap":
			return {
				"length": 16,
				"kick": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
				"snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
				"hihat_closed": [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]
			}
		"four_floor":
			return {
				"length": 16,
				"kick": [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
				"snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
				"hihat_closed": [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
			}
		"ambient_sparse":
			return {
				"length": 32,
				"drone": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				"city": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				"rain": [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
			}
		_:
			# Default 4-on-floor
			return {
				"length": 16,
				"kick": [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
			}

## Set parameters for a specific sound in the suite
func set_sound_params(sound_name: String, params: Dictionary):
	if not sound_params.has(sound_name):
		sound_params[sound_name] = {}

	sound_params[sound_name].merge(params, true)
	print("🎛️ Set params for %s: %s" % [sound_name, params])

## Get parameters for a specific sound
func get_sound_params(sound_name: String) -> Dictionary:
	return sound_params.get(sound_name, {})

## Start playback
func start():
	if is_playing:
		return

	is_playing = true
	current_step = 0
	beat_count = 0

	var step_duration = 60.0 / bpm / 4.0  # 16th notes
	step_timer.wait_time = step_duration
	step_timer.start()

	print("▶️ Playing suite: %s" % current_suite)

## Stop playback
func stop():
	if not is_playing:
		return

	is_playing = false
	step_timer.stop()

	print("⏹️ Stopped")

## Step timer callback
func _on_step_timer_timeout():
	_process_step(current_step)

	# Advance step
	current_step = (current_step + 1) % pattern_length

	# Emit beat every 4 steps
	if current_step % 4 == 0:
		beat_triggered.emit(beat_count)
		beat_count += 1

	# Apply swing to next step if needed
	var step_duration = 60.0 / bpm / 4.0
	var is_next_odd_step = (current_step % 2) == 1

	if is_next_odd_step and swing_amount > 0.0:
		step_timer.wait_time = step_duration * (1.0 + swing_amount * 0.3)
	else:
		step_timer.wait_time = step_duration

## Process a single step (trigger sounds)
func _process_step(step: int):
	if not has_node("/root/SoundBank"):
		if not soundbank_warning_shown:
			push_warning("SoundSuiteSequencer: SoundBank singleton not found")
			soundbank_warning_shown = true
		return

	var soundbank = get_node("/root/SoundBank")
	var suite = SOUND_SUITES[current_suite]

	# Check each track in the pattern
	for track_name in current_pattern.keys():
		if track_name == "length":
			continue

		# Check if this step triggers this track
		if step < current_pattern[track_name].size() and current_pattern[track_name][step] == 1:
			# Get the sound name from the suite
			if not suite.has(track_name):
				continue

			var sound_name = suite[track_name]

			# Apply variation (random velocity/timing)
			if randf() > variation:
				# Get sound parameters
				var params = get_sound_params(track_name).duplicate()

				# Generate sound
				var sound_key = "%s:%s" % [current_suite, sound_name]
				var stream = soundbank.get_sound(sound_key, params)

				if stream and audio_players.has(track_name):
					var player = audio_players[track_name]
					player.stream = stream
					player.play()

## Set BPM
func set_bpm(new_bpm: float):
	bpm = clampf(new_bpm, 40.0, 200.0)

	if is_playing:
		var step_duration = 60.0 / bpm / 4.0
		step_timer.wait_time = step_duration

	bpm_changed.emit(bpm)

## Set swing amount
func set_swing(amount: float):
	swing_amount = clampf(amount, 0.0, 1.0)

## Set variation amount
func set_variation(amount: float):
	variation = clampf(amount, 0.0, 1.0)

## Get available suites
func get_available_suites() -> Array:
	return SOUND_SUITES.keys()

## Get sounds in current suite
func get_suite_sounds() -> Array:
	return SOUND_SUITES[current_suite].keys()

## Mute/unmute a track
func mute_track(track_name: String, muted: bool):
	if audio_players.has(track_name):
		audio_players[track_name].volume_db = -80.0 if muted else 0.0

## Set track volume
func set_track_volume(track_name: String, volume_db: float):
	if audio_players.has(track_name):
		audio_players[track_name].volume_db = volume_db
