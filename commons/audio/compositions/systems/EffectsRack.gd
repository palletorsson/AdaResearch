# EffectsRack.gd
# Master effects processors and send buses
extends Node
class_name EffectsRack

# Master effects buses
var reverb_bus: int = -1
var delay_bus: int = -1
var master_bus: int = -1

# Effect instances
var master_reverb: AudioEffectReverb
var master_delay: AudioEffectDelay
var master_compressor: AudioEffectCompressor
var master_limiter: AudioEffectLimiter
var master_eq: AudioEffectEQ10

# Effect parameters
@export var reverb_params: Dictionary = {
	"room_size": 0.8,
	"damping": 0.5,
	"spread": 0.3,
	"wet": 0.2,
	"dry": 0.8
}

@export var delay_params: Dictionary = {
	"time_ms": 375.0,      # Dotted 8th at 120 BPM
	"feedback": 0.3,
	"wet": 0.15,
	"filter_cutoff": 2000.0
}

@export var master_compressor_params: Dictionary = {
	"threshold": -6.0,
	"ratio": 3.0,
	"attack": 10.0,
	"release": 100.0,
	"makeup_gain": 3.0
}

@export var master_limiter_params: Dictionary = {
	"ceiling": -0.3,
	"threshold": -1.0,
	"release": 5.0
}

# Dynamic effects state
var active_sweeps: Array = []
var active_fades: Array = []

# Events
signal effect_applied(effect_name: String, target: String)
signal sweep_completed(sweep_id: String)

func _ready():
	print("🎚️ EFFECTS RACK 🎚️")
	print("Setting up master effects chain...")
	
	_setup_effects_buses()
	_setup_master_chain()

func _setup_effects_buses():
	"""Create send effect buses"""
	
	# Create reverb send bus
	reverb_bus = AudioServer.add_bus()
	AudioServer.set_bus_name(reverb_bus, "ReverbSend")
	AudioServer.set_bus_send(reverb_bus, "Master")
	
	# Create delay send bus
	delay_bus = AudioServer.add_bus()
	AudioServer.set_bus_name(delay_bus, "DelaySend")
	AudioServer.set_bus_send(delay_bus, "Master")
	
	_setup_send_effects()
	
	print("   ✅ Send buses created")

func _setup_send_effects():
	"""Setup effects on send buses"""
	
	# Reverb on reverb bus
	master_reverb = AudioEffectReverb.new()
	master_reverb.room_size = reverb_params.room_size
	master_reverb.damping = reverb_params.damping
	master_reverb.spread = reverb_params.spread
	master_reverb.wet = reverb_params.wet
	master_reverb.dry = reverb_params.dry
	AudioServer.add_bus_effect(reverb_bus, master_reverb, 0)
	
	# Delay on delay bus
	master_delay = AudioEffectDelay.new()
	master_delay.tap1_active = true
	master_delay.tap1_delay_ms = delay_params.time_ms
	master_delay.tap1_level_db = linear_to_db(delay_params.wet)
	master_delay.tap1_pan = 0.3
	master_delay.feedback_active = true
	master_delay.feedback_delay_ms = delay_params.time_ms * 2.0
	master_delay.feedback_level_db = linear_to_db(delay_params.feedback)
	AudioServer.add_bus_effect(delay_bus, master_delay, 0)
	
	# Add filters to delay for character
	var delay_filter = AudioEffectFilter.new()
	delay_filter.cutoff_hz = delay_params.filter_cutoff
	delay_filter.resonance = 1.2
	AudioServer.add_bus_effect(delay_bus, delay_filter, 1)

func _setup_master_chain():
	"""Setup master bus processing chain"""
	
	master_bus = AudioServer.get_bus_index("Master")
	
	# Master EQ (subtle enhancement)
	master_eq = AudioEffectEQ10.new()
	master_eq.band_gain_db[0] = 0.0   # 31Hz
	master_eq.band_gain_db[1] = 1.0   # 62Hz - slight bass boost
	master_eq.band_gain_db[2] = 0.5   # 125Hz
	master_eq.band_gain_db[3] = 0.0   # 250Hz
	master_eq.band_gain_db[4] = 0.0   # 500Hz
	master_eq.band_gain_db[5] = 0.0   # 1KHz
	master_eq.band_gain_db[6] = 0.5   # 2KHz - slight presence boost
	master_eq.band_gain_db[7] = 0.0   # 4KHz
	master_eq.band_gain_db[8] = 0.0   # 8KHz
	master_eq.band_gain_db[9] = 0.0   # 16KHz
	AudioServer.add_bus_effect(master_bus, master_eq, 0)
	
	# Master compressor for glue
	master_compressor = AudioEffectCompressor.new()
	master_compressor.threshold = master_compressor_params.threshold
	master_compressor.ratio = master_compressor_params.ratio
	master_compressor.attack_us = master_compressor_params.attack
	master_compressor.release_ms = master_compressor_params.release
	master_compressor.gain = master_compressor_params.makeup_gain
	AudioServer.add_bus_effect(master_bus, master_compressor, 1)
	
	# Master limiter for safety
	master_limiter = AudioEffectLimiter.new()
	master_limiter.ceiling_db = master_limiter_params.ceiling
	master_limiter.threshold_db = master_limiter_params.threshold
	master_limiter.soft_clip_db = -2.0
	AudioServer.add_bus_effect(master_bus, master_limiter, 2)
	
	print("   ✅ Master chain configured")

# ===== DYNAMIC EFFECTS =====

func apply_filter_sweep(layer_bus: String, start_freq: float, end_freq: float, duration: float, sweep_id: String = ""):
	"""Apply a filter sweep to a specific layer"""
	
	if sweep_id.is_empty():
		sweep_id = "sweep_%d" % Time.get_unix_time_from_system()
	
	var bus_idx = AudioServer.get_bus_index(layer_bus)
	if bus_idx == -1:
		print("   ❌ Bus not found: %s" % layer_bus)
		return
	
	# Find the filter effect (usually at index 1)
	var filter_effect = null
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectFilter:
			filter_effect = effect
			break
	
	if not filter_effect:
		print("   ❌ No filter found on bus: %s" % layer_bus)
		return
	
	# Create sweep tween
	var tween = create_tween()
	tween.tween_property(filter_effect, "cutoff_hz", end_freq, duration).from(start_freq)
	tween.tween_callback(_on_sweep_completed.bind(sweep_id))
	
	# Track active sweep
	active_sweeps.append({
		"id": sweep_id,
		"bus": layer_bus,
		"tween": tween,
		"start_time": Time.get_time_dict_from_system()
	})
	
	print("   🌊 Filter sweep: %s (%.0fHz -> %.0fHz over %.1fs)" % [layer_bus, start_freq, end_freq, duration])
	effect_applied.emit("filter_sweep", layer_bus)

func apply_volume_fade(layer_bus: String, start_volume: float, end_volume: float, duration: float, fade_id: String = ""):
	"""Apply a volume fade to a layer"""
	
	if fade_id.is_empty():
		fade_id = "fade_%d" % Time.get_unix_time_from_system()
	
	var bus_idx = AudioServer.get_bus_index(layer_bus)
	if bus_idx == -1:
		print("   ❌ Bus not found: %s" % layer_bus)
		return
	
	# Create fade tween
	var tween = create_tween()
	tween.tween_method(_set_bus_volume.bind(bus_idx), start_volume, end_volume, duration)
	tween.tween_callback(_on_fade_completed.bind(fade_id))
	
	# Track active fade
	active_fades.append({
		"id": fade_id,
		"bus": layer_bus,
		"tween": tween,
		"start_time": Time.get_time_dict_from_system()
	})
	
	print("   📉 Volume fade: %s (%.1fdB -> %.1fdB over %.1fs)" % [layer_bus, start_volume, end_volume, duration])
	effect_applied.emit("volume_fade", layer_bus)

func apply_resonance_sweep(layer_bus: String, start_resonance: float, end_resonance: float, duration: float):
	"""Apply a filter resonance sweep"""
	
	var bus_idx = AudioServer.get_bus_index(layer_bus)
	if bus_idx == -1:
		return
	
	# Find the filter effect
	var filter_effect = null
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectFilter:
			filter_effect = effect
			break
	
	if filter_effect:
		var tween = create_tween()
		tween.tween_property(filter_effect, "resonance", end_resonance, duration).from(start_resonance)
		
		print("   🔊 Resonance sweep: %s (%.1f -> %.1f)" % [layer_bus, start_resonance, end_resonance])
		effect_applied.emit("resonance_sweep", layer_bus)

func apply_delay_throw(layer_bus: String, throw_duration: float = 2.0, feedback_amount: float = 0.7):
	"""Apply a dramatic delay throw effect"""
	
	var bus_idx = AudioServer.get_bus_index(layer_bus)
	if bus_idx == -1:
		return
	
	# Temporarily increase send to delay bus
	var original_send = AudioServer.get_bus_send(bus_idx, delay_bus)
	
	# Create dramatic send increase
	var tween = create_tween()
	tween.parallel().tween_method(_set_bus_send_level.bind(bus_idx, delay_bus), 0.0, 0.8, 0.1)
	tween.parallel().tween_method(_set_delay_feedback, master_delay.feedback_level_db, linear_to_db(feedback_amount), 0.1)
	
	# Fade back down
	tween.tween_delay(throw_duration * 0.3)
	tween.parallel().tween_method(_set_bus_send_level.bind(bus_idx, delay_bus), 0.8, 0.0, throw_duration * 0.7)
	tween.parallel().tween_method(_set_delay_feedback, linear_to_db(feedback_amount), master_delay.feedback_level_db, throw_duration * 0.7)
	
	print("   💫 Delay throw: %s (%.1fs)" % [layer_bus, throw_duration])
	effect_applied.emit("delay_throw", layer_bus)

# ===== MASTER EFFECTS CONTROL =====

func set_master_reverb(room_size: float, damping: float, wet: float):
	"""Adjust master reverb parameters"""
	if master_reverb:
		master_reverb.room_size = clamp(room_size, 0.0, 1.0)
		master_reverb.damping = clamp(damping, 0.0, 1.0)
		master_reverb.wet = clamp(wet, 0.0, 1.0)
		
		reverb_params.room_size = room_size
		reverb_params.damping = damping
		reverb_params.wet = wet
		
		print("   🏢 Master reverb updated: Size=%.2f, Damp=%.2f, Wet=%.2f" % [room_size, damping, wet])

func set_master_delay_time(time_ms: float, sync_to_bpm: bool = true, bpm: float = 120.0):
	"""Set master delay time"""
	if master_delay:
		if sync_to_bpm:
			# Sync to musical divisions
			var beat_ms = 60000.0 / bpm
			var sync_times = {
				"eighth": beat_ms * 0.5,
				"dotted_eighth": beat_ms * 0.75,
				"quarter": beat_ms,
				"dotted_quarter": beat_ms * 1.5,
				"half": beat_ms * 2.0
			}
			
			# Find closest sync time
			var closest_time = sync_times["dotted_eighth"]
			var min_diff = abs(time_ms - closest_time)
			
			for division in sync_times.keys():
				var diff = abs(time_ms - sync_times[division])
				if diff < min_diff:
					min_diff = diff
					closest_time = sync_times[division]
					print("   🎵 Delay synced to %s" % division)
			
			time_ms = closest_time
		
		master_delay.tap1_delay_ms = time_ms
		master_delay.feedback_delay_ms = time_ms * 2.0
		delay_params.time_ms = time_ms
		
		print("   ⏱️ Master delay time: %.1fms" % time_ms)

func set_master_compression(threshold: float, ratio: float, attack: float, release: float):
	"""Adjust master compressor"""
	if master_compressor:
		master_compressor.threshold = threshold
		master_compressor.ratio = ratio
		master_compressor.attack_us = attack
		master_compressor.release_ms = release
		
		print("   🗜️ Master compressor: Thresh=%.1fdB, Ratio=%.1f:1" % [threshold, ratio])

# ===== SPECIAL EFFECTS =====

func apply_master_filter_sweep(start_freq: float, end_freq: float, duration: float):
	"""Apply filter sweep to entire master output"""
	
	# Add temporary filter to master bus
	var temp_filter = AudioEffectFilter.new()
	temp_filter.cutoff_hz = start_freq
	temp_filter.resonance = 2.0
	AudioServer.add_bus_effect(master_bus, temp_filter, 0)
	
	# Animate the sweep
	var tween = create_tween()
	tween.tween_property(temp_filter, "cutoff_hz", end_freq, duration)
	tween.tween_callback(_remove_master_filter.bind(temp_filter))
	
	print("   🌊 MASTER filter sweep: %.0fHz -> %.0fHz" % [start_freq, end_freq])

func apply_master_volume_duck(duck_amount: float, duck_duration: float, release_duration: float):
	"""Duck the master volume temporarily"""
	
	var original_volume = AudioServer.get_bus_volume_db(master_bus)
	var ducked_volume = original_volume - duck_amount
	
	var tween = create_tween()
	tween.tween_method(_set_bus_volume.bind(master_bus), original_volume, ducked_volume, duck_duration)
	tween.tween_method(_set_bus_volume.bind(master_bus), ducked_volume, original_volume, release_duration)
	
	print("   🦆 Master duck: -%.1fdB for %.1fs" % [duck_amount, duck_duration])

func apply_tempo_delay_ramp(start_bpm: float, end_bpm: float, duration: float):
	"""Ramp delay time to match tempo change"""
	
	if master_delay:
		var start_time = 60000.0 / start_bpm * 0.75  # Dotted eighth
		var end_time = 60000.0 / end_bpm * 0.75
		
		var tween = create_tween()
		tween.tween_property(master_delay, "tap1_delay_ms", end_time, duration).from(start_time)
		tween.tween_property(master_delay, "feedback_delay_ms", end_time * 2.0, duration).from(start_time * 2.0)
		
		print("   🎵 Delay tempo ramp: %.1f -> %.1f BPM" % [start_bpm, end_bpm])

# ===== HELPER FUNCTIONS =====

func _set_bus_volume(bus_idx: int, volume_db: float):
	"""Helper to set bus volume"""
	AudioServer.set_bus_volume_db(bus_idx, volume_db)

func _set_bus_send_level(from_bus: int, to_bus: int, level: float):
	"""Helper to set send level"""
	# Note: Godot doesn't have direct send level control
	# This would need custom implementation or workaround
	pass

func _set_delay_feedback(feedback_db: float):
	"""Helper to set delay feedback"""
	if master_delay:
		master_delay.feedback_level_db = feedback_db

func _remove_master_filter(filter: AudioEffectFilter):
	"""Remove temporary filter from master bus"""
	for i in range(AudioServer.get_bus_effect_count(master_bus)):
		var effect = AudioServer.get_bus_effect(master_bus, i)
		if effect == filter:
			AudioServer.remove_bus_effect(master_bus, i)
			break

func _on_sweep_completed(sweep_id: String):
	"""Handle sweep completion"""
	# Remove from active sweeps
	for i in range(active_sweeps.size()):
		if active_sweeps[i].id == sweep_id:
			active_sweeps.remove_at(i)
			break
	
	sweep_completed.emit(sweep_id)

func _on_fade_completed(fade_id: String):
	"""Handle fade completion"""
	# Remove from active fades
	for i in range(active_fades.size()):
		if active_fades[i].id == fade_id:
			active_fades.remove_at(i)
			break

# ===== STATUS AND CONTROL =====

func get_effects_status() -> Dictionary:
	"""Get current effects status"""
	return {
		"reverb": {
			"room_size": master_reverb.room_size if master_reverb else 0.0,
			"damping": master_reverb.damping if master_reverb else 0.0,
			"wet": master_reverb.wet if master_reverb else 0.0
		},
		"delay": {
			"time_ms": master_delay.tap1_delay_ms if master_delay else 0.0,
			"feedback": db_to_linear(master_delay.feedback_level_db) if master_delay else 0.0
		},
		"compressor": {
			"threshold": master_compressor.threshold if master_compressor else 0.0,
			"ratio": master_compressor.ratio if master_compressor else 1.0,
			"gain": master_compressor.gain if master_compressor else 0.0
		},
		"active_sweeps": active_sweeps.size(),
		"active_fades": active_fades.size()
	}

func emergency_stop_all_effects():
	"""Stop all active dynamic effects"""
	
	# Kill all active tweens
	for sweep in active_sweeps:
		if sweep.has("tween") and sweep.tween:
			sweep.tween.kill()
	
	for fade in active_fades:
		if fade.has("tween") and fade.tween:
			fade.tween.kill()
	
	active_sweeps.clear()
	active_fades.clear()
	
	print("   🛑 All effects stopped")

# ===== CONSOLE COMMANDS =====

func effects_info():
	"""Show effects rack information"""
	var status = get_effects_status()
	print("🎚️ EFFECTS RACK STATUS 🎚️")
	print("   Reverb: Size=%.2f, Damp=%.2f, Wet=%.2f" % [
		status.reverb.room_size, 
		status.reverb.damping, 
		status.reverb.wet
	])
	print("   Delay: Time=%.1fms, Feedback=%.2f" % [
		status.delay.time_ms, 
		status.delay.feedback
	])
	print("   Compressor: Thresh=%.1fdB, Ratio=%.1f:1, Gain=%.1fdB" % [
		status.compressor.threshold, 
		status.compressor.ratio, 
		status.compressor.gain
	])
	print("   Active Effects: %d sweeps, %d fades" % [
		status.active_sweeps, 
		status.active_fades
	]) 