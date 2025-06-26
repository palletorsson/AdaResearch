# PatternSequencer.gd
# Advanced pattern sequencer with variable lengths and algorithms
extends Node
class_name PatternSequencer

# Pattern data structure
class Pattern:
	var steps: Array = []
	var length: int = 16
	var swing: float = 0.0
	var velocity_variation: float = 0.0
	var name: String = ""
	
	func get_step(position: int) -> Dictionary:
		if steps.is_empty():
			return {"active": false}
		return steps[position % steps.size()]
	
	func set_step(position: int, data: Dictionary):
		if position >= 0 and position < steps.size():
			steps[position] = data
	
	func resize_pattern(new_length: int):
		length = new_length
		if steps.size() < new_length:
			# Extend pattern
			for i in range(steps.size(), new_length):
				steps.append({
					"active": false,
					"velocity": 1.0,
					"pitch": 0.0,
					"probability": 1.0,
					"sound_index": 0
				})
		elif steps.size() > new_length:
			# Truncate pattern
			steps = steps.slice(0, new_length)

# Multi-track patterns
var patterns: Dictionary = {}
var global_position: int = 0
var steps_per_beat: int = 4

# Pattern events
signal pattern_created(name: String)
signal pattern_step_triggered(pattern_name: String, step: int)

func _ready():
	print("🎹 PATTERN SEQUENCER 🎹")
	print("Advanced pattern generation system ready")

func create_pattern(name: String, length: int) -> Pattern:
	"""Create a new pattern"""
	var pattern = Pattern.new()
	pattern.name = name
	pattern.length = length
	pattern.steps.resize(length)
	
	for i in range(length):
		pattern.steps[i] = {
			"active": false,
			"velocity": 1.0,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 1.0,
			"micro_timing": 0.0  # Timing offset in ms
		}
	
	patterns[name] = pattern
	pattern_created.emit(name)
	print("   ✨ Pattern created: %s (%d steps)" % [name, length])
	return pattern

func get_pattern(name: String) -> Pattern:
	"""Get a pattern by name"""
	return patterns.get(name, null)

func delete_pattern(name: String):
	"""Delete a pattern"""
	if patterns.has(name):
		patterns.erase(name)
		print("   🗑️ Pattern deleted: %s" % name)

# ===== EUCLIDEAN RHYTHMS =====

func generate_euclidean_rhythm(pattern: Pattern, pulses: int, steps: int = -1):
	"""Generate Euclidean rhythms for interesting patterns"""
	if steps == -1:
		steps = pattern.length
	
	pattern.steps.clear()
	pattern.steps.resize(steps)
	
	# Euclidean algorithm
	var bucket = []
	for i in range(steps):
		if i < pulses:
			bucket.append([1])
		else:
			bucket.append([0])
	
	# Distribute evenly using Euclidean algorithm
	while bucket.size() > 1:
		var ones = []
		var zeros = []
		
		for group in bucket:
			if group[0] == 1:
				ones.append(group)
			else:
				zeros.append(group)
		
		if zeros.is_empty():
			break
		
		bucket.clear()
		var min_count = min(ones.size(), zeros.size())
		
		# Pair ones with zeros
		for i in range(min_count):
			var combined = ones[i] + zeros[i]
			bucket.append(combined)
		
		# Add remaining groups
		for i in range(min_count, ones.size()):
			bucket.append(ones[i])
		for i in range(min_count, zeros.size()):
			bucket.append(zeros[i])
	
	# Flatten to pattern
	var flat_pattern = []
	for group in bucket:
		flat_pattern.append_array(group)
	
	# Apply to pattern steps
	for i in range(min(steps, flat_pattern.size())):
		pattern.steps[i] = {
			"active": flat_pattern[i] == 1,
			"velocity": randf_range(0.8, 1.0),
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 1.0,
			"micro_timing": 0.0
		}
	
	print("   🔄 Euclidean rhythm: %d pulses in %d steps" % [pulses, steps])

# ===== ALGORITHMIC PATTERNS =====

func generate_kick_pattern(pattern: Pattern, style: String = "four_on_floor"):
	"""Generate kick drum patterns"""
	pattern.steps.clear()
	pattern.steps.resize(pattern.length)
	
	# Initialize all steps as inactive
	for i in range(pattern.length):
		pattern.steps[i] = {
			"active": false,
			"velocity": 1.0,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 1.0,
			"micro_timing": 0.0
		}
	
	match style:
		"four_on_floor":
			# Classic house/techno 4/4 pattern
			for i in range(0, pattern.length, 4):
				pattern.steps[i].active = true
				pattern.steps[i].velocity = 1.0
		
		"breakbeat":
			# Amen break inspired pattern
			var break_pattern = [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0]
			for i in range(min(pattern.length, break_pattern.size())):
				pattern.steps[i].active = break_pattern[i] == 1
				pattern.steps[i].velocity = randf_range(0.8, 1.0)
		
		"trap":
			# Trap-style kick pattern
			var trap_kicks = [0, 4, 6, 10, 14]  # Typical trap kick positions
			for pos in trap_kicks:
				if pos < pattern.length:
					pattern.steps[pos].active = true
					pattern.steps[pos].velocity = randf_range(0.9, 1.0)
		
		"dnb":
			# Drum & Bass pattern
			pattern.steps[0].active = true   # Strong kick on 1
			pattern.steps[0].velocity = 1.0
			if pattern.length >= 12:
				pattern.steps[10].active = true  # Syncopated kick
				pattern.steps[10].velocity = 0.8

func generate_hihat_pattern(pattern: Pattern, style: String = "steady"):
	"""Generate hi-hat patterns"""
	pattern.steps.clear()
	pattern.steps.resize(pattern.length)
	
	# Initialize all steps
	for i in range(pattern.length):
		pattern.steps[i] = {
			"active": false,
			"velocity": randf_range(0.6, 0.9),
			"pitch": randf_range(-2.0, 2.0),  # Slight pitch variation
			"probability": 1.0,
			"sound_index": 0,
			"duration": 0.3,
			"micro_timing": 0.0
		}
	
	match style:
		"steady":
			# Simple 8th note pattern
			for i in range(1, pattern.length, 2):
				pattern.steps[i].active = true
		
		"shuffled":
			# Shuffled 16th notes
			for i in range(1, pattern.length, 4):
				pattern.steps[i].active = true
				pattern.steps[i].micro_timing = 30.0  # Swing timing
			for i in range(3, pattern.length, 4):
				pattern.steps[i].active = true
				pattern.steps[i].velocity *= 0.7  # Quieter off-beats
		
		"trap":
			# Trap hi-hat rolls
			for i in range(pattern.length):
				if i % 4 == 2:  # Main hi-hats on off-beats
					pattern.steps[i].active = true
					pattern.steps[i].velocity = 0.8
				elif randf() < 0.3:  # Random additional hits
					pattern.steps[i].active = true
					pattern.steps[i].velocity = randf_range(0.4, 0.6)
		
		"jungle":
			# Jungle/DnB style chopped up hi-hats
			for i in range(pattern.length):
				if randf() < 0.6:
					pattern.steps[i].active = true
					pattern.steps[i].velocity = randf_range(0.3, 0.8)
					pattern.steps[i].pitch = randf_range(-5.0, 3.0)

func generate_snare_pattern(pattern: Pattern, style: String = "backbeat"):
	"""Generate snare patterns"""
	pattern.steps.clear()
	pattern.steps.resize(pattern.length)
	
	# Initialize all steps
	for i in range(pattern.length):
		pattern.steps[i] = {
			"active": false,
			"velocity": 1.0,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 1.0,
			"micro_timing": 0.0
		}
	
	match style:
		"backbeat":
			# Classic rock/pop backbeat
			pattern.steps[4].active = true   # Beat 2
			pattern.steps[12].active = true  # Beat 4
		
		"breakbeat":
			# Complex breakbeat snare placement
			var snare_hits = [4, 10, 14]
			for pos in snare_hits:
				if pos < pattern.length:
					pattern.steps[pos].active = true
					pattern.steps[pos].velocity = randf_range(0.8, 1.0)
		
		"dnb":
			# Drum & Bass snare on beat 3
			if pattern.length >= 8:
				pattern.steps[8].active = true
				pattern.steps[8].velocity = 1.0
		
		"latin":
			# Latin-inspired syncopated snares
			var latin_snares = [3, 6, 11, 14]
			for pos in latin_snares:
				if pos < pattern.length:
					pattern.steps[pos].active = true
					pattern.steps[pos].velocity = randf_range(0.7, 0.9)

# ===== MELODIC PATTERNS =====

func generate_bass_line(pattern: Pattern, key: String = "Am", style: String = "steady"):
	"""Generate bass line patterns"""
	# Define scale notes (semitones from root)
	var scales = {
		"Am": [0, 2, 3, 5, 7, 8, 10],      # A natural minor
		"Em": [0, 2, 3, 5, 7, 8, 10],      # E natural minor  
		"Dm": [0, 2, 3, 5, 7, 8, 10],      # D natural minor
		"Cm": [0, 2, 3, 5, 7, 8, 10],      # C natural minor
	}
	
	var scale = scales.get(key, scales["Am"])
	
	pattern.steps.clear()
	pattern.steps.resize(pattern.length)
	
	for i in range(pattern.length):
		pattern.steps[i] = {
			"active": false,
			"velocity": 0.8,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 2.0,
			"micro_timing": 0.0
		}
	
	match style:
		"steady":
			# Root notes on strong beats
			for i in range(0, pattern.length, 8):
				pattern.steps[i].active = true
				pattern.steps[i].pitch = 0.0  # Root note
				pattern.steps[i].velocity = 1.0
		
		"walking":
			# Walking bass line
			for i in range(0, pattern.length, 2):
				pattern.steps[i].active = true
				var scale_degree = (i / 2) % scale.size()
				pattern.steps[i].pitch = scale[scale_degree] - 12  # One octave down
				pattern.steps[i].velocity = randf_range(0.7, 0.9)
		
		"acid":
			# TB-303 style acid bass
			for i in range(pattern.length):
				if randf() < 0.6:
					pattern.steps[i].active = true
					pattern.steps[i].pitch = scale[randi() % scale.size()] - 12
					pattern.steps[i].velocity = randf_range(0.6, 1.0)
					pattern.steps[i].duration = randf_range(0.5, 2.0)

func generate_arp_pattern(pattern: Pattern, chord: Array = [0, 4, 7], style: String = "up"):
	"""Generate arpeggiated patterns"""
	pattern.steps.clear()
	pattern.steps.resize(pattern.length)
	
	for i in range(pattern.length):
		pattern.steps[i] = {
			"active": false,
			"velocity": 0.7,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 0.8,
			"micro_timing": 0.0
		}
	
	var chord_extended = chord + chord.map(func(note): return note + 12)  # Add octave
	
	match style:
		"up":
			for i in range(0, pattern.length, 2):
				var note_index = (i / 2) % chord_extended.size()
				pattern.steps[i].active = true
				pattern.steps[i].pitch = chord_extended[note_index]
		
		"down":
			chord_extended.reverse()
			for i in range(0, pattern.length, 2):
				var note_index = (i / 2) % chord_extended.size()
				pattern.steps[i].active = true
				pattern.steps[i].pitch = chord_extended[note_index]
		
		"random":
			for i in range(0, pattern.length, 2):
				if randf() < 0.8:
					pattern.steps[i].active = true
					pattern.steps[i].pitch = chord_extended[randi() % chord_extended.size()]
					pattern.steps[i].velocity = randf_range(0.5, 0.9)

# ===== PATTERN MANIPULATION =====

func apply_swing(pattern: Pattern, amount: float):
	"""Apply swing timing to pattern"""
	pattern.swing = amount
	
	for i in range(pattern.steps.size()):
		if i % 2 == 1:  # Off-beat steps
			pattern.steps[i].micro_timing = amount * 100.0  # Convert to ms

func apply_velocity_humanization(pattern: Pattern, variation: float):
	"""Add human-like velocity variation"""
	pattern.velocity_variation = variation
	
	for step in pattern.steps:
		if step.active:
			var random_factor = randf_range(-variation, variation)
			step.velocity = clamp(step.velocity + random_factor, 0.1, 1.0)

func apply_probability(pattern: Pattern, base_probability: float):
	"""Set probability for all active steps"""
	for step in pattern.steps:
		if step.active:
			step.probability = base_probability

# ===== PATTERN OPERATIONS =====

func copy_pattern(source_name: String, dest_name: String) -> Pattern:
	"""Copy a pattern"""
	var source = patterns.get(source_name)
	if not source:
		return null
	
	var new_pattern = create_pattern(dest_name, source.length)
	new_pattern.steps = source.steps.duplicate(true)
	new_pattern.swing = source.swing
	new_pattern.velocity_variation = source.velocity_variation
	
	return new_pattern

func merge_patterns(pattern1_name: String, pattern2_name: String, dest_name: String) -> Pattern:
	"""Merge two patterns together"""
	var p1 = patterns.get(pattern1_name)
	var p2 = patterns.get(pattern2_name)
	
	if not p1 or not p2:
		return null
	
	var max_length = max(p1.length, p2.length)
	var merged = create_pattern(dest_name, max_length)
	
	for i in range(max_length):
		var step1 = p1.get_step(i) if i < p1.length else {"active": false}
		var step2 = p2.get_step(i) if i < p2.length else {"active": false}
		
		merged.steps[i] = {
			"active": step1.active or step2.active,
			"velocity": max(step1.get("velocity", 0.0), step2.get("velocity", 0.0)),
			"pitch": step1.get("pitch", 0.0) if step1.active else step2.get("pitch", 0.0),
			"probability": min(step1.get("probability", 1.0), step2.get("probability", 1.0)),
			"sound_index": step1.get("sound_index", 0) if step1.active else step2.get("sound_index", 0),
			"duration": max(step1.get("duration", 1.0), step2.get("duration", 1.0)),
			"micro_timing": 0.0
		}
	
	return merged

func get_pattern_info() -> Dictionary:
	"""Get information about all patterns"""
	var info = {}
	
	for name in patterns.keys():
		var pattern = patterns[name]
		var active_steps = 0
		for step in pattern.steps:
			if step.active:
				active_steps += 1
		
		info[name] = {
			"length": pattern.length,
			"active_steps": active_steps,
			"swing": pattern.swing,
			"velocity_variation": pattern.velocity_variation
		}
	
	return info

# ===== CONSOLE COMMANDS =====

func list_patterns():
	"""List all patterns"""
	print("🎹 PATTERN LIST 🎹")
	var info = get_pattern_info()
	
	for name in info.keys():
		var data = info[name]
		print("   %s: %d steps (%d active) | Swing: %.2f" % [
			name, 
			data.length, 
			data.active_steps, 
			data.swing
		]) 