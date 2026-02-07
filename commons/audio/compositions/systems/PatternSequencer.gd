# PatternSequencer.gd
# Unified pattern sequencer with support for drums, bass, chords, and arps
# Single data model for all pattern types
extends Node
class_name PatternSequencer

# ===== PATTERN DATA STRUCTURE =====

class Pattern:
	var steps: Array = []
	var length: int = 16
	var swing: float = 0.0
	var humanize: float = 0.0  # 0-20ms timing variation
	var name: String = ""
	var pattern_type: String = "generic"  # drum, bass, chord, arp
	
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
			for i in range(steps.size(), new_length):
				steps.append(_get_default_step())
		elif steps.size() > new_length:
			steps = steps.slice(0, new_length)
	
	func _get_default_step() -> Dictionary:
		return {
			"active": false,
			"velocity": 1.0,
			"pitch": 0.0,
			"probability": 1.0,
			"sound_index": 0,
			"duration": 1.0,
			"micro_timing": 0.0
		}


# ===== TRACK DATA STRUCTURE =====

class Track:
	var name: String = ""
	var pattern: Pattern = null
	var track_type: String = "drum"  # drum, bass, chord, arp
	var muted: bool = false
	var solo: bool = false
	var volume: float = 1.0
	var pan: float = 0.0
	
	# Track-specific data
	var drum_data: DrumTrackData = null
	var bass_data: BassTrackData = null
	var chord_data: ChordTrackData = null
	var arp_data: ArpTrackData = null
	
	func _init(track_name: String = "", type: String = "drum"):
		name = track_name
		track_type = type
		pattern = Pattern.new()
		pattern.pattern_type = type
		
		match type:
			"drum": drum_data = DrumTrackData.new()
			"bass": bass_data = BassTrackData.new()
			"chord": chord_data = ChordTrackData.new()
			"arp": arp_data = ArpTrackData.new()


# ===== TRACK-SPECIFIC DATA CLASSES =====

class DrumTrackData:
	var kit_name: String = "808_kit"
	var elements: Array = ["kick", "snare", "hihat", "clap"]
	var element_mutes: Dictionary = {}
	var element_volumes: Dictionary = {}


class BassTrackData:
	var root_note: int = 36  # C2
	var octave: int = 2
	var notes: Array = []    # Per-step MIDI notes
	var glides: Array = []   # Per-step glide flags
	var scale: String = "minor"
	var synth_type: String = "sub"


class ChordTrackData:
	var key: String = "C"
	var scale: String = "major"
	var chords: Array = []     # Per-step chord degrees
	var voicings: Array = []   # Per-step voicing indices
	var sustains: Array = []   # Per-step sustain flags
	var inversion: int = 0


class ArpTrackData:
	var direction: String = "up"      # up, down, up_down, down_up, random, as_played
	var rate: String = "1/8"          # 1/4, 1/8, 1/16, 1/32, triplets
	var octave_range: int = 1         # 1-4
	var gate_length: float = 0.8      # 0.1-1.0
	var velocity_curve: String = "flat"  # flat, crescendo, decrescendo, accent


# ===== MAIN SEQUENCER =====

# Multi-track storage
var tracks: Dictionary = {}           # track_name -> Track
var patterns: Dictionary = {}         # pattern_name -> Pattern (legacy compatibility)
var global_position: int = 0
var steps_per_beat: int = 4
var bpm: float = 120.0

# Signals
signal pattern_created(name: String)
signal pattern_step_triggered(pattern_name: String, step: int)
signal pattern_changed(track_name: String, step: int, data: Dictionary)
signal track_added(track_name: String, track_type: String)
signal track_removed(track_name: String)


func _ready():
	print("🎹 PATTERN SEQUENCER 🎹")
	print("Unified pattern system ready (drums, bass, chords, arps)")


# ===== TRACK MANAGEMENT =====

func create_track(name: String, track_type: String = "drum", length: int = 16) -> Track:
	"""Create a new track with specified type"""
	var track = Track.new(name, track_type)
	track.pattern.resize_pattern(length)
	track.pattern.name = name
	
	# Initialize type-specific step data
	match track_type:
		"bass":
			track.bass_data.notes.resize(length)
			track.bass_data.glides.resize(length)
			for i in range(length):
				track.bass_data.notes[i] = track.bass_data.root_note
				track.bass_data.glides[i] = false
		"chord":
			track.chord_data.chords.resize(length)
			track.chord_data.voicings.resize(length)
			track.chord_data.sustains.resize(length)
			for i in range(length):
				track.chord_data.chords[i] = "rest"
				track.chord_data.voicings[i] = 0
				track.chord_data.sustains[i] = false
	
	tracks[name] = track
	track_added.emit(name, track_type)
	print("   ✨ Track created: %s (type: %s, %d steps)" % [name, track_type, length])
	return track


func get_track(name: String) -> Track:
	"""Get a track by name"""
	return tracks.get(name, null)


func delete_track(name: String):
	"""Delete a track"""
	if tracks.has(name):
		tracks.erase(name)
		track_removed.emit(name)
		print("   🗑️ Track deleted: %s" % name)


func get_all_tracks() -> Array:
	"""Get all track names"""
	return tracks.keys()


func get_tracks_by_type(track_type: String) -> Array:
	"""Get all tracks of a specific type"""
	var result = []
	for name in tracks.keys():
		if tracks[name].track_type == track_type:
			result.append(name)
	return result


# ===== STEP VELOCITY ACCESS =====

func get_step_velocity(track_name: String, step: int) -> float:
	"""Get velocity at a specific step"""
	var track = get_track(track_name)
	if track == null:
		return 0.0
	
	var step_data = track.pattern.get_step(step)
	return step_data.get("velocity", 0.0) if step_data.get("active", false) else 0.0


func set_step_velocity(track_name: String, step: int, velocity: float):
	"""Set velocity at a specific step"""
	var track = get_track(track_name)
	if track == null:
		return
	
	var step_data = track.pattern.get_step(step)
	step_data["velocity"] = velocity
	step_data["active"] = velocity > 0.0
	track.pattern.set_step(step, step_data)
	
	pattern_changed.emit(track_name, step, step_data)


func get_pattern_for_track(track_name: String) -> Pattern:
	"""Get the pattern object for a track"""
	var track = get_track(track_name)
	if track:
		return track.pattern
	return null


# ===== DRUM-SPECIFIC METHODS =====

func set_drum_hit(track_name: String, element: String, step: int, velocity: float = 1.0):
	"""Set a drum hit for a specific element at a step"""
	var track = get_track(track_name)
	if track == null or track.track_type != "drum":
		return
	
	var step_data = track.pattern.get_step(step)
	if not step_data.has("elements"):
		step_data["elements"] = {}
	
	step_data["elements"][element] = velocity
	step_data["active"] = true
	track.pattern.set_step(step, step_data)
	
	pattern_changed.emit(track_name, step, step_data)


func get_drum_hit(track_name: String, element: String, step: int) -> float:
	"""Get drum hit velocity for element at step"""
	var track = get_track(track_name)
	if track == null or track.track_type != "drum":
		return 0.0
	
	var step_data = track.pattern.get_step(step)
	if step_data.has("elements"):
		return step_data["elements"].get(element, 0.0)
	return 0.0


func load_drum_pattern(track_name: String, patterns_dict: Dictionary, elements: Array = []):
	"""Load drum patterns from dictionary format"""
	var track = get_track(track_name)
	if track == null:
		track = create_track(track_name, "drum", 16)
	
	if elements.is_empty():
		elements = patterns_dict.keys()
	
	track.drum_data.elements = elements
	
	# Convert to step-based format
	for step in range(track.pattern.length):
		var step_data = {"active": false, "elements": {}, "velocity": 1.0}
		for element in elements:
			if patterns_dict.has(element) and step < patterns_dict[element].size():
				var vel = patterns_dict[element][step]
				if vel > 0:
					step_data["elements"][element] = vel
					step_data["active"] = true
		track.pattern.set_step(step, step_data)


func get_drum_patterns(track_name: String) -> Dictionary:
	"""Export drum patterns back to dictionary format"""
	var track = get_track(track_name)
	if track == null or track.track_type != "drum":
		return {}
	
	var result = {}
	for element in track.drum_data.elements:
		result[element] = []
		for step in range(track.pattern.length):
			result[element].append(get_drum_hit(track_name, element, step))
	
	return result


# ===== BASS-SPECIFIC METHODS =====

func set_bass_note(track_name: String, step: int, midi_note: int, velocity: float = 1.0, glide: bool = false):
	"""Set bass note at step"""
	var track = get_track(track_name)
	if track == null or track.track_type != "bass":
		return
	
	var step_data = track.pattern.get_step(step)
	step_data["active"] = velocity > 0
	step_data["velocity"] = velocity
	step_data["pitch"] = midi_note
	track.pattern.set_step(step, step_data)
	
	if step < track.bass_data.notes.size():
		track.bass_data.notes[step] = midi_note
		track.bass_data.glides[step] = glide
	
	pattern_changed.emit(track_name, step, step_data)


func get_bass_note(track_name: String, step: int) -> Dictionary:
	"""Get bass note data at step"""
	var track = get_track(track_name)
	if track == null or track.track_type != "bass":
		return {"note": 0, "velocity": 0, "glide": false}
	
	var step_data = track.pattern.get_step(step)
	var note = track.bass_data.notes[step] if step < track.bass_data.notes.size() else 36
	var glide = track.bass_data.glides[step] if step < track.bass_data.glides.size() else false
	
	return {
		"note": note,
		"velocity": step_data.get("velocity", 0.0) if step_data.get("active", false) else 0.0,
		"glide": glide
	}


func set_bass_root(track_name: String, root_note: int, octave: int = -1):
	"""Set bass track root note and optionally octave"""
	var track = get_track(track_name)
	if track == null or track.track_type != "bass":
		return
	
	track.bass_data.root_note = root_note
	if octave >= 0:
		track.bass_data.octave = octave


# ===== CHORD-SPECIFIC METHODS =====

func set_chord(track_name: String, step: int, chord_degree: String, voicing: int = 0, sustain: bool = false, velocity: float = 1.0):
	"""Set chord at step"""
	var track = get_track(track_name)
	if track == null or track.track_type != "chord":
		return
	
	var step_data = track.pattern.get_step(step)
	step_data["active"] = chord_degree != "rest" and velocity > 0
	step_data["velocity"] = velocity
	track.pattern.set_step(step, step_data)
	
	if step < track.chord_data.chords.size():
		track.chord_data.chords[step] = chord_degree
		track.chord_data.voicings[step] = voicing
		track.chord_data.sustains[step] = sustain
	
	pattern_changed.emit(track_name, step, step_data)


func get_chord(track_name: String, step: int) -> Dictionary:
	"""Get chord data at step"""
	var track = get_track(track_name)
	if track == null or track.track_type != "chord":
		return {"chord": "rest", "voicing": 0, "sustain": false, "velocity": 0.0}
	
	var step_data = track.pattern.get_step(step)
	
	return {
		"chord": track.chord_data.chords[step] if step < track.chord_data.chords.size() else "rest",
		"voicing": track.chord_data.voicings[step] if step < track.chord_data.voicings.size() else 0,
		"sustain": track.chord_data.sustains[step] if step < track.chord_data.sustains.size() else false,
		"velocity": step_data.get("velocity", 0.0) if step_data.get("active", false) else 0.0
	}


func set_chord_key(track_name: String, key: String, scale: String = ""):
	"""Set chord track key and scale"""
	var track = get_track(track_name)
	if track == null or track.track_type != "chord":
		return
	
	track.chord_data.key = key
	if not scale.is_empty():
		track.chord_data.scale = scale


# ===== ARP-SPECIFIC METHODS =====

func set_arp_settings(track_name: String, settings: Dictionary):
	"""Set arpeggiator settings"""
	var track = get_track(track_name)
	if track == null or track.track_type != "arp":
		return
	
	if settings.has("direction"):
		track.arp_data.direction = settings["direction"]
	if settings.has("rate"):
		track.arp_data.rate = settings["rate"]
	if settings.has("octave_range"):
		track.arp_data.octave_range = settings["octave_range"]
	if settings.has("gate_length"):
		track.arp_data.gate_length = settings["gate_length"]
	if settings.has("velocity_curve"):
		track.arp_data.velocity_curve = settings["velocity_curve"]


func get_arp_settings(track_name: String) -> Dictionary:
	"""Get arpeggiator settings"""
	var track = get_track(track_name)
	if track == null or track.track_type != "arp":
		return {}
	
	return {
		"direction": track.arp_data.direction,
		"rate": track.arp_data.rate,
		"octave_range": track.arp_data.octave_range,
		"gate_length": track.arp_data.gate_length,
		"velocity_curve": track.arp_data.velocity_curve
	}


# ===== LEGACY PATTERN METHODS (for compatibility) =====

func create_pattern(name: String, length: int) -> Pattern:
	"""Create a new pattern (legacy compatibility)"""
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
			"micro_timing": 0.0
		}
	
	patterns[name] = pattern
	pattern_created.emit(name)
	print("   ✨ Pattern created: %s (%d steps)" % [name, length])
	return pattern


func get_pattern(name: String) -> Pattern:
	"""Get a pattern by name (legacy compatibility)"""
	return patterns.get(name, null)


func delete_pattern(name: String):
	"""Delete a pattern (legacy compatibility)"""
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
		
		for i in range(min_count):
			var combined = ones[i] + zeros[i]
			bucket.append(combined)
		
		for i in range(min_count, ones.size()):
			bucket.append(ones[i])
		for i in range(min_count, zeros.size()):
			bucket.append(zeros[i])
	
	var flat_pattern = []
	for group in bucket:
		flat_pattern.append_array(group)
	
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


# ===== PATTERN MANIPULATION =====

func apply_swing(pattern: Pattern, amount: float):
	"""Apply swing timing to pattern"""
	pattern.swing = amount
	
	for i in range(pattern.steps.size()):
		if i % 2 == 1:  # Off-beat steps
			pattern.steps[i].micro_timing = amount * 100.0


func apply_humanize(pattern: Pattern, amount_ms: float):
	"""Apply humanization (timing and velocity variation)"""
	pattern.humanize = amount_ms
	
	for step in pattern.steps:
		if step.active:
			step.micro_timing = randf_range(-amount_ms, amount_ms)
			step.velocity = clampf(step.velocity + randf_range(-0.1, 0.1), 0.1, 1.0)


func apply_velocity_humanization(pattern: Pattern, variation: float):
	"""Add human-like velocity variation"""
	for step in pattern.steps:
		if step.active:
			var random_factor = randf_range(-variation, variation)
			step.velocity = clampf(step.velocity + random_factor, 0.1, 1.0)


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
	new_pattern.humanize = source.humanize
	
	return new_pattern


func copy_track(source_name: String, dest_name: String) -> Track:
	"""Copy a track with all its data"""
	var source = get_track(source_name)
	if not source:
		return null
	
	var dest = create_track(dest_name, source.track_type, source.pattern.length)
	dest.pattern.steps = source.pattern.steps.duplicate(true)
	dest.pattern.swing = source.pattern.swing
	dest.pattern.humanize = source.pattern.humanize
	dest.muted = source.muted
	dest.volume = source.volume
	dest.pan = source.pan
	
	# Copy type-specific data
	match source.track_type:
		"drum":
			dest.drum_data.kit_name = source.drum_data.kit_name
			dest.drum_data.elements = source.drum_data.elements.duplicate()
			dest.drum_data.element_mutes = source.drum_data.element_mutes.duplicate()
		"bass":
			dest.bass_data.root_note = source.bass_data.root_note
			dest.bass_data.octave = source.bass_data.octave
			dest.bass_data.notes = source.bass_data.notes.duplicate()
			dest.bass_data.glides = source.bass_data.glides.duplicate()
			dest.bass_data.scale = source.bass_data.scale
		"chord":
			dest.chord_data.key = source.chord_data.key
			dest.chord_data.scale = source.chord_data.scale
			dest.chord_data.chords = source.chord_data.chords.duplicate()
			dest.chord_data.voicings = source.chord_data.voicings.duplicate()
			dest.chord_data.sustains = source.chord_data.sustains.duplicate()
		"arp":
			dest.arp_data.direction = source.arp_data.direction
			dest.arp_data.rate = source.arp_data.rate
			dest.arp_data.octave_range = source.arp_data.octave_range
			dest.arp_data.gate_length = source.arp_data.gate_length
			dest.arp_data.velocity_curve = source.arp_data.velocity_curve
	
	return dest


# ===== INFO & DEBUG =====

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
			"humanize": pattern.humanize
		}
	
	return info


func get_track_info() -> Dictionary:
	"""Get information about all tracks"""
	var info = {}
	
	for name in tracks.keys():
		var track = tracks[name]
		var active_steps = 0
		for step in track.pattern.steps:
			if step.active:
				active_steps += 1
		
		info[name] = {
			"type": track.track_type,
			"length": track.pattern.length,
			"active_steps": active_steps,
			"swing": track.pattern.swing,
			"muted": track.muted,
			"solo": track.solo
		}
	
	return info


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


func list_tracks():
	"""List all tracks"""
	print("🎹 TRACK LIST 🎹")
	var info = get_track_info()
	
	for name in info.keys():
		var data = info[name]
		var status = ""
		if data.muted:
			status = " [MUTED]"
		elif data.solo:
			status = " [SOLO]"
		print("   %s (%s): %d steps (%d active) | Swing: %.2f%s" % [
			name,
			data.type,
			data.length, 
			data.active_steps, 
			data.swing,
			status
		])
