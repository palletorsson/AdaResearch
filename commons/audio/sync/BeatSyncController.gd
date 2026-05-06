# BeatSyncController.gd
# Provides precise beat synchronization for audio playback
# Based on Godot audio sync documentation

extends Node
class_name BeatSyncController

## Emitted on each beat (quarter note)
signal beat(beat_number: int)
## Emitted on each bar (4 beats by default)
signal bar(bar_number: int)
## Emitted on each 16th note for hi-hat patterns
signal sixteenth(sixteenth_number: int)

@export var bpm: float = 120.0
@export var beats_per_bar: int = 4
@export var auto_start: bool = false

var _player: AudioStreamPlayer
var _player_3d: AudioStreamPlayer3D
var _time_begin: float = 0.0
var _time_delay: float = 0.0
var _last_beat: int = -1
var _last_bar: int = -1
var _last_sixteenth: int = -1
var _is_playing: bool = false
var _use_hardware_clock: bool = false

# Beat timing
var beat_duration: float:
	get: return 60.0 / bpm
var bar_duration: float:
	get: return beat_duration * beats_per_bar
var sixteenth_duration: float:
	get: return beat_duration / 4.0


func _ready():
	if auto_start:
		call_deferred("_find_and_start")


func _find_and_start():
	# Try to find an audio player in parent
	_player = get_parent().get_node_or_null("AudioStreamPlayer")
	if _player:
		start_sync(_player)


## Start syncing with an AudioStreamPlayer
func start_sync(player: AudioStreamPlayer, use_hardware_clock: bool = false):
	_player = player
	_player_3d = null
	_use_hardware_clock = use_hardware_clock
	_start_internal()


## Start syncing with an AudioStreamPlayer3D
func start_sync_3d(player: AudioStreamPlayer3D, use_hardware_clock: bool = false):
	_player_3d = player
	_player = null
	_use_hardware_clock = use_hardware_clock
	_start_internal()


func _start_internal():
	_time_begin = Time.get_ticks_usec()
	_time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_last_beat = -1
	_last_bar = -1
	_last_sixteenth = -1
	_is_playing = true
	set_process(true)


## Stop syncing
func stop_sync():
	_is_playing = false
	set_process(false)


## Get precise current time in seconds
func get_music_time() -> float:
	if not _is_playing:
		return 0.0
	
	if _use_hardware_clock:
		# Hardware clock method - better for long playback
		var pos = 0.0
		if _player:
			pos = _player.get_playback_position()
		elif _player_3d:
			pos = _player_3d.get_playback_position()
		return pos + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	else:
		# System clock method - better for short/precise sync
		var time = (Time.get_ticks_usec() - _time_begin) / 1000000.0
		time -= _time_delay
		return max(0.0, time)


## Get current beat number (0-indexed)
func get_current_beat() -> int:
	return int(get_music_time() / beat_duration)


## Get current bar number (0-indexed)
func get_current_bar() -> int:
	return int(get_music_time() / bar_duration)


## Get current 16th note number (0-indexed)
func get_current_sixteenth() -> int:
	return int(get_music_time() / sixteenth_duration)


## Get position within current beat (0.0 to 1.0)
func get_beat_progress() -> float:
	return fmod(get_music_time(), beat_duration) / beat_duration


## Get position within current bar (0.0 to 1.0)
func get_bar_progress() -> float:
	return fmod(get_music_time(), bar_duration) / bar_duration


## Check if we're on a specific beat within the bar (1-4 for standard 4/4)
func is_on_beat(beat_in_bar: int) -> bool:
	var current_beat_in_bar = (get_current_beat() % beats_per_bar) + 1
	return current_beat_in_bar == beat_in_bar


## Get time until next beat in seconds
func time_to_next_beat() -> float:
	var progress = get_beat_progress()
	return beat_duration * (1.0 - progress)


func _process(_delta):
	if not _is_playing:
		return
	
	var current_beat = get_current_beat()
	var current_bar = get_current_bar()
	var current_sixteenth = get_current_sixteenth()
	
	# Emit beat signal
	if current_beat != _last_beat:
		_last_beat = current_beat
		beat.emit(current_beat)
	
	# Emit bar signal
	if current_bar != _last_bar:
		_last_bar = current_bar
		bar.emit(current_bar)
	
	# Emit sixteenth signal
	if current_sixteenth != _last_sixteenth:
		_last_sixteenth = current_sixteenth
		sixteenth.emit(current_sixteenth)


## Utility: Convert beat number to time in seconds
func beat_to_time(beat_num: int) -> float:
	return beat_num * beat_duration


## Utility: Convert time to beat number
func time_to_beat(time: float) -> int:
	return int(time / beat_duration)


## Utility: Quantize time to nearest beat
func quantize_to_beat(time: float) -> float:
	return round(time / beat_duration) * beat_duration


## Utility: Quantize time to nearest 16th
func quantize_to_sixteenth(time: float) -> float:
	return round(time / sixteenth_duration) * sixteenth_duration
