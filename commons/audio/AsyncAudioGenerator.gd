# AsyncAudioGenerator.gd
# Non-blocking audio generation using background threads
# Mirrors the approach in john_cage_tech_noir.gd

extends Node
class_name AsyncAudioGenerator

# Signals (must be emitted via call_deferred from thread)
signal generation_started(sound_id: String)
signal generation_progress(sound_id: String, progress: float)
signal generation_complete(sound_id: String, stream: AudioStream)
signal generation_failed(sound_id: String, error: String)
signal all_generations_complete()

# Threading
var _thread: Thread
var _mutex: Mutex
var _is_generating: bool = false
var _stop_requested: bool = false

# Queue
var _generation_queue: Array = []  # Array of {id, generator, params, callback_node, callback_method}
var _completed_sounds: Dictionary = {}  # sound_id -> AudioStream

# Progress tracking
var _current_sound_id: String = ""
var _total_sounds: int = 0
var _completed_count: int = 0

func _init():
	_mutex = Mutex.new()
	_thread = Thread.new()

func _ready():
	pass

func _exit_tree():
	stop_generation(true)  # Wait for thread on cleanup

# ============================================================================
# PUBLIC API
# ============================================================================

func queue_sound(sound_id: String, generator_callable: Callable, callback_node: Node = null, callback_method: String = "") -> void:
	"""Queue a sound for background generation"""
	if not _mutex:
		_mutex = Mutex.new()
	if not _thread:
		_thread = Thread.new()
	
	_mutex.lock()
	_generation_queue.append({
		"id": sound_id,
		"generator": generator_callable,
		"callback_node": callback_node,
		"callback_method": callback_method
	})
	_total_sounds = _generation_queue.size() + _completed_count
	_mutex.unlock()
	
	# Start thread if not running
	if not _is_generating:
		_start_generation()

func queue_preset_sounds(preset: Dictionary, sound_bank: Node) -> void:
	"""Queue all sounds from a preset for background generation"""
	var sounds_to_generate: Array = []
	
	# Collect continuous layer sounds
	if "continuous_layers" in preset:
		for layer in preset["continuous_layers"]:
			if "sound_id" in layer:
				sounds_to_generate.append(layer["sound_id"])
	
	# Collect random event sounds
	if "random_events" in preset:
		for event in preset["random_events"]:
			if "sound_pool" in event:
				for sound_id in event["sound_pool"]:
					if sound_id not in sounds_to_generate:
						sounds_to_generate.append(sound_id)
	
	# Queue each sound
	for sound_id in sounds_to_generate:
		var generator = func(): return sound_bank._generate_sound(sound_id)
		queue_sound(sound_id, generator, sound_bank, "_on_async_sound_ready")

func is_generating() -> bool:
	if not _mutex:
		return false
	_mutex.lock()
	var result = _is_generating
	_mutex.unlock()
	return result

func get_progress() -> float:
	if not _mutex:
		return 0.0
	_mutex.lock()
	var progress = float(_completed_count) / max(_total_sounds, 1)
	_mutex.unlock()
	return progress

func get_current_sound() -> String:
	if not _mutex:
		return ""
	_mutex.lock()
	var result = _current_sound_id
	_mutex.unlock()
	return result

func get_completed_sound(sound_id: String) -> AudioStream:
	if not _mutex:
		return null
	_mutex.lock()
	var result = _completed_sounds.get(sound_id, null)
	_mutex.unlock()
	return result

func stop_generation(wait: bool = false) -> void:
	"""Request stop. If wait=true, blocks until thread finishes (use only in _exit_tree)"""
	if not _mutex:
		return
	
	_mutex.lock()
	_stop_requested = true
	_generation_queue.clear()
	_mutex.unlock()
	
	# Only wait if explicitly requested (e.g., during cleanup)
	if wait and _thread and _thread.is_started():
		_thread.wait_to_finish()
		_mutex.lock()
		_is_generating = false
		_stop_requested = false
		_mutex.unlock()

# ============================================================================
# THREAD MANAGEMENT
# ============================================================================

func _start_generation() -> void:
	if not _mutex:
		_mutex = Mutex.new()
	if not _thread:
		_thread = Thread.new()
	
	if _thread.is_started():
		return
	
	_mutex.lock()
	_is_generating = true
	_stop_requested = false
	_completed_count = 0
	_mutex.unlock()
	
	var err = _thread.start(_thread_generate_sounds)
	if err != OK:
		push_error("AsyncAudioGenerator: Failed to start generation thread")
		_mutex.lock()
		_is_generating = false
		_mutex.unlock()

func _thread_generate_sounds() -> void:
	"""Main thread function - processes generation queue"""
	
	while true:
		# Check for stop request
		_mutex.lock()
		var should_stop = _stop_requested
		var queue_empty = _generation_queue.is_empty()
		_mutex.unlock()
		
		if should_stop or queue_empty:
			break
		
		# Get next item from queue
		_mutex.lock()
		var item = _generation_queue.pop_front()
		_current_sound_id = item["id"]
		_mutex.unlock()
		
		# Emit start signal
		_call_deferred_emit("generation_started", [item["id"]])
		
		# Generate the sound
		var stream: AudioStream = null
		var error_msg: String = ""
		
		var generator: Callable = item["generator"]
		if generator.is_valid():
			stream = generator.call()
		else:
			error_msg = "Invalid generator callable"
		
		# Store result
		_mutex.lock()
		if stream:
			_completed_sounds[item["id"]] = stream
		_completed_count += 1
		var progress = float(_completed_count) / max(_total_sounds, 1)
		_mutex.unlock()
		
		# Emit progress
		_call_deferred_emit("generation_progress", [item["id"], progress])
		
		# Emit complete or failed
		if stream:
			_call_deferred_emit("generation_complete", [item["id"], stream])
			
			# Call specific callback if provided
			var callback_node = item.get("callback_node")
			var callback_method = item.get("callback_method")
			if callback_node and is_instance_valid(callback_node) and not callback_method.is_empty():
				callback_node.call_deferred(callback_method, stream)
		else:
			_call_deferred_emit("generation_failed", [item["id"], error_msg])
		
		# Small delay to prevent CPU hogging and allow main thread to process
		OS.delay_msec(10)
	
	# Generation complete
	_mutex.lock()
	_is_generating = false
	_current_sound_id = ""
	_mutex.unlock()
	
	_call_deferred_emit("all_generations_complete", [])

func _call_deferred_emit(signal_name: String, args: Array) -> void:
	"""Helper to emit signals from thread via call_deferred"""
	# We need a way to emit signals from the thread
	# Since this is a RefCounted, we use a workaround
	match signal_name:
		"generation_started":
			generation_started.emit(args[0])
		"generation_progress":
			generation_progress.emit(args[0], args[1])
		"generation_complete":
			generation_complete.emit(args[0], args[1])
		"generation_failed":
			generation_failed.emit(args[0], args[1])
		"all_generations_complete":
			all_generations_complete.emit()


# ============================================================================
# STATIC HELPERS FOR COMMON GENERATION TASKS
# ============================================================================

static func generate_interactive_song_async(song_type: String, callback_node: Node, callback_method: String) -> AsyncAudioGenerator:
	"""Convenience method for generating interactive songs"""
	var generator = AsyncAudioGenerator.new()
	
	var gen_callable: Callable
	match song_type.to_lower():
		"pop", "pop_interactive":
			gen_callable = func(): return AudioSynthesizer.generate_pop_interactive_song()
		"ambient", "ambient_works":
			gen_callable = func(): return AudioSynthesizer.generate_ambient_works_song()
		"prog", "prog_synth", "prog_synth_70s":
			gen_callable = func(): return AudioSynthesizer.generate_prog_synth_song()
		"moroder", "moroder_disco":
			gen_callable = func(): return AudioSynthesizer.generate_moroder_disco_song({})
		"detroit", "detroit_techno":
			gen_callable = func(): return AudioSynthesizer.generate_detroit_techno_song({})
		"synthwave":
			gen_callable = func(): return AudioSynthesizer.generate_synthwave_song({})
		"rave":
			gen_callable = func(): return AudioSynthesizer.generate_rave_song({})
		_:
			push_error("AsyncAudioGenerator: Unknown song type: " + song_type)
			return null
	
	generator.queue_sound(song_type + "_song", gen_callable, callback_node, callback_method)
	return generator
