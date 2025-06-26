# TrackLayer.gd
# Individual track layer with built-in effects and modulation
extends AudioStreamPlayer
class_name TrackLayer

# Layer properties
@export var layer_name: String = ""
@export var enabled: bool = true
@export var solo: bool = false
@export var muted_by_solo: bool = false
@export var pattern: Array = []
@export var pattern_length: int = 16

# Mix controls
@export var layer_volume: float = 0.0
@export var pan: float = 0.0
@export var send_reverb: float = 0.0
@export var send_delay: float = 0.0

# Built-in effects
var compressor: AudioEffectCompressor
var filter: AudioEffectFilter
var delay: AudioEffectDelay
var distortion: AudioEffectDistortion
var panner: AudioEffectPanner

# LFO for modulation
@export var lfo_rate: float = 0.5
@export var lfo_depth: float = 0.0
@export var lfo_target: String = "filter_cutoff"
var lfo_phase: float = 0.0

# Pattern and sound data
var sound_cache: Dictionary = {}
var current_pattern_position: int = 0
var layer_bus_index: int = -1

# Events
signal audio_played()
signal pattern_step(step: int)

func _ready():
	_setup_effects_chain()
	_initialize_pattern()
	_cache_sounds()

func _setup_effects_chain():
	"""Create dedicated bus and effects chain for this layer"""
	
	# Create dedicated audio bus
	layer_bus_index = AudioServer.add_bus()
	var bus_name = "Layer_%s" % layer_name
	AudioServer.set_bus_name(layer_bus_index, bus_name)
	bus = bus_name
	
	# Route to master
	AudioServer.set_bus_send(layer_bus_index, "Master")
	
	# Add effects in order
	_add_compressor(layer_bus_index)
	_add_filter(layer_bus_index)
	_add_panner(layer_bus_index)
	_add_delay(layer_bus_index)
	
	print("   🔧 Effects chain setup for layer: %s" % layer_name)

func _add_compressor(bus_idx: int):
	"""Add compressor to the effects chain"""
	compressor = AudioEffectCompressor.new()
	compressor.threshold = -12.0
	compressor.ratio = 4.0
	compressor.attack_us = 10.0
	compressor.release_ms = 100.0
	compressor.gain = 0.0
	AudioServer.add_bus_effect(bus_idx, compressor, 0)

func _add_filter(bus_idx: int):
	"""Add filter to the effects chain"""
	filter = AudioEffectFilter.new()
	filter.cutoff_hz = 2000.0
	filter.resonance = 1.0
	filter.gain = 1.0
	AudioServer.add_bus_effect(bus_idx, filter, 1)

func _add_panner(bus_idx: int):
	"""Add panner for stereo positioning"""
	panner = AudioEffectPanner.new()
	panner.pan = pan
	AudioServer.add_bus_effect(bus_idx, panner, 2)

func _add_delay(bus_idx: int):
	"""Add delay effect"""
	delay = AudioEffectDelay.new()
	delay.tap1_active = true
	delay.tap1_delay_ms = 375.0  # Dotted 8th at 120 BPM
	delay.tap1_level_db = -12.0
	delay.tap1_pan = 0.2
	delay.feedback_active = true
	delay.feedback_delay_ms = 750.0  # Dotted quarter
	delay.feedback_level_db = -18.0
	AudioServer.add_bus_effect(bus_idx, delay, 3)

func _initialize_pattern():
	"""Initialize default pattern"""
	pattern.clear()
	pattern.resize(pattern_length)
	
	for i in range(pattern_length):
		pattern[i] = {
			"active": false,
			"velocity": 1.0,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 1.0
		}

func _cache_sounds():
	"""Pre-generate and cache sounds for this layer"""
	# This will be implemented per layer type
	# Each layer will override this to generate appropriate sounds
	pass

func _process(delta):
	"""Process LFO modulation"""
	if lfo_depth > 0.0:
		_process_lfo(delta)
	
	# Update volume based on layer settings
	_update_volume()

func _process_lfo(delta):
	"""Process LFO modulation"""
	lfo_phase += delta * lfo_rate * TAU
	var lfo_value = sin(lfo_phase) * lfo_depth
	
	match lfo_target:
		"filter_cutoff":
			if filter:
				var base_cutoff = 1000.0
				filter.cutoff_hz = base_cutoff + lfo_value * 1000.0
		"volume":
			# LFO affects layer volume
			var modulated_volume = layer_volume + lfo_value * 6.0
			AudioServer.set_bus_volume_db(layer_bus_index, modulated_volume)
		"pan":
			if panner:
				panner.pan = pan + lfo_value * 0.5
		"delay_feedback":
			if delay:
				delay.feedback_level_db = -18.0 + lfo_value * 12.0
		"filter_resonance":
			if filter:
				filter.resonance = 1.0 + lfo_value * 3.0

func _update_volume():
	"""Update volume based on solo/mute state"""
	var final_volume = layer_volume
	
	# Apply muting
	if muted_by_solo or not enabled:
		final_volume = -80.0  # Effectively muted
	
	AudioServer.set_bus_volume_db(layer_bus_index, final_volume)

func process_beat(global_beat: int):
	"""Process a beat for this layer"""
	if not enabled or muted_by_solo:
		return
	
	var pattern_pos = global_beat % pattern_length
	var step = pattern[pattern_pos]
	
	if step.active and randf() <= step.probability:
		_play_step(step, pattern_pos)
	
	current_pattern_position = pattern_pos
	pattern_step.emit(pattern_pos)

func _play_step(step: Dictionary, position: int):
	"""Play a pattern step"""
	# Get sound based on step configuration
	var sound_key = "default"
	if step.has("sound_index"):
		sound_key = str(step.sound_index)
	
	if sound_cache.has(sound_key):
		stream = sound_cache[sound_key]
		
		# Apply pitch modulation
		if step.pitch != 0.0:
			pitch_scale = pow(2.0, step.pitch / 12.0)  # Semitone conversion
		else:
			pitch_scale = 1.0
		
		play()
		audio_played.emit()

# ===== PATTERN CONTROL =====

func set_step(position: int, active: bool, velocity: float = 1.0, pitch: float = 0.0, probability: float = 1.0):
	"""Set a pattern step"""
	if position >= 0 and position < pattern_length:
		pattern[position] = {
			"active": active,
			"velocity": velocity,
			"pitch": pitch,
			"probability": probability,
			"sound_index": 0,
			"duration": 1.0
		}

func clear_pattern():
	"""Clear all pattern steps"""
	for i in range(pattern_length):
		pattern[i].active = false

func randomize_pattern(density: float = 0.3):
	"""Create a random pattern"""
	for i in range(pattern_length):
		pattern[i].active = randf() < density
		pattern[i].velocity = randf_range(0.7, 1.0)
		pattern[i].probability = randf_range(0.8, 1.0)

func create_euclidean_pattern(pulses: int, steps: int = -1):
	"""Generate Euclidean rhythm pattern"""
	if steps == -1:
		steps = pattern_length
	
	# Euclidean algorithm implementation
	var pattern_array = []
	var bucket = []
	
	# Initialize buckets
	for i in range(steps):
		if i < pulses:
			bucket.append([1])
		else:
			bucket.append([0])
	
	# Distribute pulses evenly
	while bucket.size() > 1:
		var last_group = bucket[-1]
		if last_group[0] == 0:
			bucket.pop_back()
			var idx = 0
			while idx < bucket.size() and bucket[idx][-1] == 1:
				bucket[idx].append(last_group[0])
				idx += 1
				if idx < bucket.size():
					last_group = bucket.pop_back()
		else:
			break
	
	# Flatten to pattern
	for group in bucket:
		pattern_array.append_array(group)
	
	# Apply to pattern
	for i in range(min(pattern_length, pattern_array.size())):
		pattern[i].active = pattern_array[i] == 1

# ===== EFFECT CONTROL =====

func set_filter_cutoff(cutoff_hz: float):
	"""Set filter cutoff frequency"""
	if filter:
		filter.cutoff_hz = cutoff_hz

func set_filter_resonance(resonance: float):
	"""Set filter resonance"""
	if filter:
		filter.resonance = resonance

func set_compression(threshold: float, ratio: float, attack: float, release: float):
	"""Configure compressor"""
	if compressor:
		compressor.threshold = threshold
		compressor.ratio = ratio
		compressor.attack_us = attack
		compressor.release_ms = release

func set_delay_time(time_ms: float, feedback_db: float = -18.0):
	"""Configure delay"""
	if delay:
		delay.tap1_delay_ms = time_ms
		delay.feedback_delay_ms = time_ms * 2.0
		delay.feedback_level_db = feedback_db

func set_pan_position(pan_value: float):
	"""Set stereo pan position (-1.0 to 1.0)"""
	pan = clamp(pan_value, -1.0, 1.0)
	if panner:
		panner.pan = pan

# ===== LFO CONTROL =====

func setup_lfo(target: String, rate: float, depth: float):
	"""Configure LFO modulation"""
	lfo_target = target
	lfo_rate = rate
	lfo_depth = depth
	lfo_phase = 0.0
	print("   🌊 LFO setup: %s -> %s (Rate: %.2f, Depth: %.2f)" % [layer_name, target, rate, depth])

func modulate_filter_sweep(start_freq: float, end_freq: float, duration: float):
	"""Create a filter sweep effect"""
	if filter:
		var tween = create_tween()
		tween.tween_property(filter, "cutoff_hz", end_freq, duration).from(start_freq)

# ===== SEND EFFECTS =====

func set_reverb_send(amount: float):
	"""Set reverb send amount"""
	send_reverb = clamp(amount, 0.0, 1.0)
	# This would connect to the effects rack reverb bus
	# Implementation depends on your effects rack setup

func set_delay_send(amount: float):
	"""Set delay send amount"""
	send_delay = clamp(amount, 0.0, 1.0)
	# This would connect to the effects rack delay bus

# ===== CLEANUP =====

func stop():
	"""Stop playback and clean up"""
	if playing:
		super.stop()

func _exit_tree():
	"""Cleanup when removed"""
	if layer_bus_index >= 0:
		# Note: In a real implementation, you'd want to be careful about removing buses
		# as other systems might be using them
		pass 