# TrackConfigLoader.gd
# JSON configuration loader for Enhanced Track System
extends RefCounted
class_name TrackConfigLoader

static func load_track_config(file_path: String) -> Dictionary:
	"""Load a complete track configuration from JSON"""
	
	if not FileAccess.file_exists(file_path):
		print("❌ Config file not found: %s" % file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ Failed to parse JSON: %s" % file_path)
		return {}
	
	var config = json.data
	print("✅ Loaded track config: %s" % config.get("metadata", {}).get("name", "Unnamed"))
	
	return config

static func apply_config_to_track(track: EnhancedTrackSystem, config: Dictionary):
	"""Apply a JSON configuration to an Enhanced Track System"""
	
	if config.is_empty():
		print("❌ Empty configuration")
		return
	
	print("🎛️ Applying track configuration...")
	
	# Apply metadata
	_apply_metadata(track, config.get("metadata", {}))
	
	# Apply layer configurations
	_apply_layer_configs(track, config.get("layers", {}))
	
	# Apply pattern definitions
	_apply_patterns(track, config.get("patterns", {}))
	
	# Apply effects settings
	_apply_effects(track, config.get("effects", {}))
	
	# Apply section definitions
	_apply_sections(track, config.get("sections", {}))
	
	# Apply automation
	_apply_automation(track, config.get("automation", {}))
	
	print("✅ Configuration applied successfully")

static func _apply_metadata(track: EnhancedTrackSystem, metadata: Dictionary):
	"""Apply metadata settings"""
	
	if metadata.has("bpm"):
		track.set_bpm(metadata.bpm)
		print("   🎵 BPM set to: %d" % metadata.bpm)
	
	if metadata.has("master_volume"):
		if track.effects_rack:
			var master_bus = AudioServer.get_bus_index("Master")
			AudioServer.set_bus_volume_db(master_bus, metadata.master_volume)
		print("   🔊 Master volume: %.1fdB" % metadata.master_volume)

static func _apply_layer_configs(track: EnhancedTrackSystem, layers_config: Dictionary):
	"""Apply layer configurations"""
	
	for category in layers_config.keys():
		var category_config = layers_config[category]
		
		for layer_name in category_config.keys():
			var layer_config = category_config[layer_name]
			var layer = track.get_layer(category, layer_name)
			
			if not layer:
				continue
			
			# Basic layer settings
			if layer_config.has("enabled"):
				track.set_layer_enabled(category, layer_name, layer_config.enabled)
			
			if layer_config.has("volume"):
				track.set_layer_volume(category, layer_name, layer_config.volume)
			
			if layer_config.has("solo"):
				track.set_layer_solo(category, layer_name, layer_config.solo)
			
			if layer_config.has("pan"):
				layer.set_pan_position(layer_config.pan)
			
			# Effects settings
			if layer_config.has("effects"):
				_apply_layer_effects(layer, layer_config.effects)
			
			# LFO settings
			if layer_config.has("lfo"):
				_apply_layer_lfo(layer, layer_config.lfo)
			
			# Pattern assignment
			if layer_config.has("pattern"):
				_assign_pattern_to_layer(track, layer, layer_config.pattern)
			
			print("   🎛️ Configured layer: %s/%s" % [category, layer_name])

static func _apply_layer_effects(layer: TrackLayer, effects_config: Dictionary):
	"""Apply effects configuration to a layer"""
	
	if effects_config.has("filter"):
		var filter_config = effects_config.filter
		if filter_config.has("cutoff"):
			layer.set_filter_cutoff(filter_config.cutoff)
		if filter_config.has("resonance"):
			layer.set_filter_resonance(filter_config.resonance)
	
	if effects_config.has("compressor"):
		var comp_config = effects_config.compressor
		layer.set_compression(
			comp_config.get("threshold", -12.0),
			comp_config.get("ratio", 4.0),
			comp_config.get("attack", 10.0),
			comp_config.get("release", 100.0)
		)
	
	if effects_config.has("delay"):
		var delay_config = effects_config.delay
		layer.set_delay_time(
			delay_config.get("time", 375.0),
			delay_config.get("feedback", -18.0)
		)

static func _apply_layer_lfo(layer: TrackLayer, lfo_config: Dictionary):
	"""Apply LFO configuration to a layer"""
	
	if lfo_config.has("target") and lfo_config.has("rate") and lfo_config.has("depth"):
		layer.setup_lfo(
			lfo_config.target,
			lfo_config.rate,
			lfo_config.depth
		)

static func _assign_pattern_to_layer(track: EnhancedTrackSystem, layer: TrackLayer, pattern_name: String):
	"""Assign a pattern to a layer"""
	
	var pattern = track.sequencer.get_pattern(pattern_name)
	if pattern:
		layer.pattern = pattern.steps
		layer.pattern_length = pattern.length

static func _apply_patterns(track: EnhancedTrackSystem, patterns_config: Dictionary):
	"""Apply pattern definitions"""
	
	for pattern_name in patterns_config.keys():
		var pattern_config = patterns_config[pattern_name]
		var pattern = track.sequencer.create_pattern(pattern_name, pattern_config.get("length", 16))
		
		# Apply pattern type and generation
		if pattern_config.has("type"):
			_generate_pattern_by_type(track.sequencer, pattern, pattern_config)
		
		# Apply manual step data
		if pattern_config.has("steps"):
			_apply_manual_pattern_steps(pattern, pattern_config.steps)
		
		# Apply pattern modifiers
		if pattern_config.has("swing"):
			track.sequencer.apply_swing(pattern, pattern_config.swing)
		
		if pattern_config.has("humanization"):
			track.sequencer.apply_velocity_humanization(pattern, pattern_config.humanization)
		
		if pattern_config.has("probability"):
			track.sequencer.apply_probability(pattern, pattern_config.probability)
		
		print("   🎹 Created pattern: %s (%d steps)" % [pattern_name, pattern.length])

static func _generate_pattern_by_type(sequencer: PatternSequencer, pattern: PatternSequencer.Pattern, config: Dictionary):
	"""Generate pattern based on type configuration"""
	
	match config.type:
		"kick":
			sequencer.generate_kick_pattern(pattern, config.get("style", "four_on_floor"))
		
		"hihat":
			sequencer.generate_hihat_pattern(pattern, config.get("style", "steady"))
		
		"snare":
			sequencer.generate_snare_pattern(pattern, config.get("style", "backbeat"))
		
		"bass":
			sequencer.generate_bass_line(pattern, config.get("key", "Am"), config.get("style", "steady"))
		
		"arp":
			var chord = config.get("chord", [0, 4, 7])
			sequencer.generate_arp_pattern(pattern, chord, config.get("style", "up"))
		
		"euclidean":
			var pulses = config.get("pulses", 4)
			var steps = config.get("steps", pattern.length)
			sequencer.generate_euclidean_rhythm(pattern, pulses, steps)

static func _apply_manual_pattern_steps(pattern: PatternSequencer.Pattern, steps_data: Array):
	"""Apply manually defined pattern steps"""
	
	for i in range(min(steps_data.size(), pattern.steps.size())):
		var step_data = steps_data[i]
		if step_data is Dictionary:
			pattern.steps[i] = {
				"active": step_data.get("active", false),
				"velocity": step_data.get("velocity", 1.0),
				"pitch": step_data.get("pitch", 0.0),
				"probability": step_data.get("probability", 1.0),
				"sound_index": step_data.get("sound_index", 0),
				"duration": step_data.get("duration", 1.0),
				"micro_timing": step_data.get("micro_timing", 0.0)
			}
		elif step_data is bool:
			pattern.steps[i].active = step_data

static func _apply_effects(track: EnhancedTrackSystem, effects_config: Dictionary):
	"""Apply effects rack configuration"""
	
	if not track.effects_rack:
		return
	
	if effects_config.has("reverb"):
		var reverb_config = effects_config.reverb
		track.effects_rack.set_master_reverb(
			reverb_config.get("room_size", 0.8),
			reverb_config.get("damping", 0.5),
			reverb_config.get("wet", 0.2)
		)
	
	if effects_config.has("delay"):
		var delay_config = effects_config.delay
		track.effects_rack.set_master_delay_time(
			delay_config.get("time", 375.0),
			delay_config.get("sync_to_bpm", true),
			track.bpm
		)
	
	if effects_config.has("compressor"):
		var comp_config = effects_config.compressor
		track.effects_rack.set_master_compression(
			comp_config.get("threshold", -6.0),
			comp_config.get("ratio", 3.0),
			comp_config.get("attack", 10.0),
			comp_config.get("release", 100.0)
		)

static func _apply_sections(track: EnhancedTrackSystem, sections_config: Dictionary):
	"""Apply section definitions"""
	
	if track is EnhancedDarkTrack:
		for section_name in sections_config.keys():
			var section_config = sections_config[section_name]
			if section_config.has("length_bars"):
				track.pattern_bars[section_name] = section_config.length_bars

static func _apply_automation(track: EnhancedTrackSystem, automation_config: Dictionary):
	"""Apply automation settings"""
	
	# Filter sweeps
	if automation_config.has("filter_sweeps"):
		for sweep_config in automation_config.filter_sweeps:
			_schedule_filter_sweep(track, sweep_config)
	
	# Volume fades
	if automation_config.has("volume_fades"):
		for fade_config in automation_config.volume_fades:
			_schedule_volume_fade(track, fade_config)

static func _schedule_filter_sweep(track: EnhancedTrackSystem, sweep_config: Dictionary):
	"""Schedule a filter sweep"""
	
	var timer = Timer.new()
	timer.wait_time = sweep_config.get("delay", 0.0)
	timer.one_shot = true
	timer.timeout.connect(func():
		if track.effects_rack:
			track.effects_rack.apply_filter_sweep(
				sweep_config.get("target", "Layer_bass_sub"),
				sweep_config.get("start_freq", 200.0),
				sweep_config.get("end_freq", 2000.0),
				sweep_config.get("duration", 2.0)
			)
		timer.queue_free()
	)
	track.add_child(timer)
	timer.start()

static func _schedule_volume_fade(track: EnhancedTrackSystem, fade_config: Dictionary):
	"""Schedule a volume fade"""
	
	var timer = Timer.new()
	timer.wait_time = fade_config.get("delay", 0.0)
	timer.one_shot = true
	timer.timeout.connect(func():
		if track.effects_rack:
			track.effects_rack.apply_volume_fade(
				fade_config.get("target", "Layer_drums_kick"),
				fade_config.get("start_volume", 0.0),
				fade_config.get("end_volume", -20.0),
				fade_config.get("duration", 2.0)
			)
		timer.queue_free()
	)
	track.add_child(timer)
	timer.start()

# ===== SAVE CONFIGURATION =====

static func save_track_config(track: EnhancedTrackSystem, file_path: String, config_name: String = "Exported Track"):
	"""Save current track configuration to JSON"""
	
	var config = _extract_track_config(track, config_name)
	
	var json_string = JSON.stringify(config, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	
	print("✅ Track configuration saved: %s" % file_path)

static func _extract_track_config(track: EnhancedTrackSystem, config_name: String) -> Dictionary:
	"""Extract current track configuration to dictionary"""
	
	var config = {
		"metadata": {
			"name": config_name,
			"version": "1.0",
			"bpm": track.bpm,
			"created": Time.get_datetime_string_from_system()
		},
		"layers": {},
		"patterns": {},
		"effects": {},
		"sections": {},
		"automation": {}
	}
	
	# Extract layer configurations
	for category in track.layers.keys():
		config.layers[category] = {}
		for layer_name in track.layers[category].keys():
			var layer = track.layers[category][layer_name]
			if layer:
				config.layers[category][layer_name] = {
					"enabled": layer.enabled,
					"volume": layer.layer_volume,
					"solo": layer.solo,
					"pan": layer.pan,
					"effects": {
						"filter": {
							"cutoff": 1000.0,  # Default values - could extract from actual effects
							"resonance": 1.0
						}
					},
					"lfo": {
						"target": layer.lfo_target,
						"rate": layer.lfo_rate,
						"depth": layer.lfo_depth
					}
				}
	
	# Extract pattern configurations
	for pattern_name in track.sequencer.patterns.keys():
		var pattern = track.sequencer.patterns[pattern_name]
		config.patterns[pattern_name] = {
			"length": pattern.length,
			"swing": pattern.swing,
			"velocity_variation": pattern.velocity_variation,
			"steps": []
		}
		
		for step in pattern.steps:
			config.patterns[pattern_name].steps.append({
				"active": step.active,
				"velocity": step.velocity,
				"pitch": step.pitch,
				"probability": step.probability
			})
	
	return config 