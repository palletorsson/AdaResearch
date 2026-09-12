extends Node
class_name FMPianoSynth

## FMPianoSynth (Non-Blocking Version)
## Uses background threads for FM sample generation to prevent frame stutters.
## Manages a pool of AudioStreamPlayers and a thread-safe sample cache.

@export var gain: float = 0.25  # Reduced for ambient clarity

# Cache: "freq_velocity_sustain" -> AudioStreamWAV
# Guarded by _cache_mutex
var _sample_cache: Dictionary = {}
var _cache_mutex: Mutex = Mutex.new()

var _players: Array[AudioStreamPlayer] = []
var _max_polyphony: int = 12

func _ready():
	_setup_reverb()
	
	# Create player pool
	for i in range(_max_polyphony):
		var p = AudioStreamPlayer.new()
		p.bus = "FMPianoReverb" # Route to reverb bus
		p.volume_db = linear_to_db(gain)
		add_child(p)
		_players.append(p)

func _setup_reverb():
	# Add Reverb Bus for "Air"
	var bus_name = "FMPianoReverb"
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, bus_name)
		
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.98  # Cathedral-like "Eno" Hall
		reverb.damping = 0.15  # Slight high-frequency damping for warmth
		reverb.spread = 1.0
		reverb.dry = 0.4  # Less dry for more ambient wash
		reverb.wet = 0.85  # More wet for floating quality
		
		AudioServer.add_bus_effect(idx, reverb)
		
		# Route to Master
		AudioServer.set_bus_send(idx, "Master")

func play_note(freq: float, vel: float, sustain_time: float = 1.5):
	# Quantize params to reduce cache size
	var q_freq = snapped(freq, 0.01)
	var q_vel = snapped(vel, 0.1) 
	var q_sustain = snapped(sustain_time, 0.1)
	
	var cache_key = "%s_%s_%s" % [q_freq, q_vel, q_sustain]
	if _pending_tasks.size() > 32:
		# a completed task is RELEASED only by wait_for_task_completion (a no-op wait);
		# dropping its id leaves it in the pool, and the pool crashes the engine at exit
		var still: Array[int] = []
		for tid in _pending_tasks:
			if WorkerThreadPool.is_task_completed(tid):
				WorkerThreadPool.wait_for_task_completion(tid)
			else:
				still.append(tid)
		_pending_tasks = still
	
	_cache_mutex.lock()
	var cached_stream = _sample_cache.get(cache_key)
	_cache_mutex.unlock()
	
	if cached_stream:
		_play_stream(cached_stream)
	elif not _closing:
		# Generate in background thread to prevent blocking
		var task_id: int = WorkerThreadPool.add_task(
			func(): _generate_and_cache(cache_key, q_freq, q_vel, q_sustain)
		)
		_pending_tasks.append(task_id)

## THE TASKS OUTLIVED THE NODE (2026-09-11). Every new note queues a worker-pool task that
## calls back into this node when done; nothing joined them when the node was freed, and
## a hall carrying the looper crashed Godot with a signal 11 on shutdown (the museum
## probes of WaveFunctions_AirMusic, after their reports were written). Tasks are tracked
## and joined here; a task started after closing does nothing.
## AND A TASK MUST BE WAITED TO BE RELEASED (2026-09-12): the first fix skipped tasks that
## had already completed, so their pool entries were never freed and the engine still
## crashed at exit (3221225477 in WaveFunctions_AirMusic and WaveFunctions_Synthesis_Lab,
## both carrying air_music_display_case; commons/testing/probe_wcn_shutdown.gd reproduces
## it with one synth and one note). Every tracked id is waited, completed or not.
var _pending_tasks: Array[int] = []
var _closing: bool = false

func _exit_tree() -> void:
	_closing = true
	for tid in _pending_tasks:
		WorkerThreadPool.wait_for_task_completion(tid)
	_pending_tasks.clear()

func _generate_and_cache(key: String, f: float, v: float, s: float):
	if _closing:
		return
	# HEAVY MATH HAPPENING HERE (InBackground)
	var new_stream = FMPianoGenerator.generate_note(f, v, s)
	
	# Guard: node may have been freed while thread was running
	if _closing or not is_instance_valid(self) or _cache_mutex == null:
		return
	
	_cache_mutex.lock()
	_sample_cache[key] = new_stream
	_cache_mutex.unlock()
	
	# Hand off to main thread for playback
	call_deferred("_play_stream", new_stream)

func _play_stream(stream: AudioStream):
	if not stream: return
	
	# Find free player
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	# Steal oldest (index 0)
	var p = _players[0]
	p.stop()
	p.stream = stream
	p.play()
	_players.remove_at(0)
	_players.append(p)

# Helper for Linear -> DB conversion
func linear_to_db(lin: float) -> float:
	if lin <= 0: return -80.0
	return 20.0 * log(lin) / log(10.0)
