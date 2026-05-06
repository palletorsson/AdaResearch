class_name SequencerPresets
extends RefCounted

## Sequencer Presets - Pattern Templates
##
## Pre-defined rhythm patterns for the ArraySequencer.
## Each pattern is a 2D array: pattern[track][step] = bool

## Pattern preset definitions
## Format: { "name": { tracks: int, steps: int, data: Array[Array[bool]] } }
const PATTERNS: Dictionary = {
	"four_on_floor": {
		"name": "Four on the Floor",
		"description": "Classic house/disco kick pattern",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, true, false, true, false, true, false],  # Kick on every beat
			[false, false, false, false, true, false, false, false],  # Snare on 3
			[true, true, true, true, true, true, true, true],  # Hi-hat on every step
			[false, false, false, false, false, false, false, false]   # Empty track
		]
	},
	"backbeat": {
		"name": "Backbeat",
		"description": "Rock/pop snare on 2 and 4",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, false, false, true, false, false, false],  # Kick on 1, 3
			[false, false, true, false, false, false, true, false],  # Snare on 2, 4
			[true, false, true, false, true, false, true, false],    # Hi-hat
			[false, false, false, false, false, false, false, false]
		]
	},
	"trap_basic": {
		"name": "Trap Basic",
		"description": "Simple trap beat with rolling hi-hats",
		"tracks": 4,
		"steps": 16,
		"data": [
			[true, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false],
			[false, false, false, false, true, false, false, false, false, false, false, false, true, false, false, false],
			[true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true],
			[false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true]
		]
	},
	"breakbeat": {
		"name": "Breakbeat",
		"description": "Syncopated break pattern",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, false, true, false, false, true, false],   # Syncopated kick
			[false, false, true, false, false, true, false, false],  # Off-beat snare
			[true, false, true, false, true, false, true, false],    # Hi-hat
			[false, false, false, false, false, false, false, true]  # Accent
		]
	},
	"minimal": {
		"name": "Minimal",
		"description": "Sparse, minimal techno",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, false, false, false, false, false, false],
			[false, false, false, false, true, false, false, false],
			[false, false, true, false, false, false, true, false],
			[false, false, false, false, false, false, false, false]
		]
	},
	"euclidean_5_8": {
		"name": "Euclidean 5/8",
		"description": "5 hits distributed over 8 steps",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, true, true, false, true, false, true],  # Euclidean(5,8)
			[false, true, false, false, true, false, true, false], # Complement
			[true, true, true, true, true, true, true, true],
			[false, false, false, false, false, false, false, false]
		]
	},
	"euclidean_3_8": {
		"name": "Euclidean 3/8",
		"description": "3 hits distributed over 8 steps (tresillo)",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, false, true, false, false, true, false],  # Euclidean(3,8) - tresillo
			[false, false, true, false, false, true, false, false],
			[true, false, true, false, true, false, true, false],
			[false, false, false, false, false, false, false, true]
		]
	},
	"ambient": {
		"name": "Ambient",
		"description": "Sparse ambient texture",
		"tracks": 4,
		"steps": 8,
		"data": [
			[true, false, false, false, false, false, false, false],
			[false, false, false, false, false, false, false, false],
			[false, false, false, true, false, false, false, false],
			[false, false, false, false, false, false, true, false]
		]
	},
	"empty": {
		"name": "Empty",
		"description": "Blank canvas",
		"tracks": 4,
		"steps": 8,
		"data": [
			[false, false, false, false, false, false, false, false],
			[false, false, false, false, false, false, false, false],
			[false, false, false, false, false, false, false, false],
			[false, false, false, false, false, false, false, false]
		]
	}
}


## Get pattern data by name
static func get_pattern(name: String) -> Dictionary:
	if name in PATTERNS:
		return PATTERNS[name]
	return {}


## Get all pattern names
static func get_pattern_names() -> Array[String]:
	var names: Array[String] = []
	for key in PATTERNS.keys():
		names.append(key)
	return names


## Apply pattern to sequencer
static func apply_pattern(sequencer: ArraySequencer, pattern_name: String) -> bool:
	var pattern = get_pattern(pattern_name)
	if pattern.is_empty():
		return false

	var data = pattern.get("data", [])
	for track in range(data.size()):
		if track >= sequencer.num_tracks:
			break
		var track_data = data[track]
		for step in range(track_data.size()):
			if step >= sequencer.num_steps:
				break
			sequencer.set_cell(track, step, track_data[step])

	return true


## Generate Euclidean rhythm
## Distributes 'hits' evenly across 'steps' using Bjorklund's algorithm
static func generate_euclidean(hits: int, steps: int) -> Array[bool]:
	if hits >= steps:
		var result: Array[bool] = []
		result.resize(steps)
		result.fill(true)
		return result

	if hits <= 0:
		var result: Array[bool] = []
		result.resize(steps)
		result.fill(false)
		return result

	# Bjorklund's algorithm
	var pattern: Array[Array] = []
	for i in range(hits):
		pattern.append([true])
	for i in range(steps - hits):
		pattern.append([false])

	while true:
		var ones: Array[Array] = []
		var zeros: Array[Array] = []

		for p in pattern:
			if p[0]:
				ones.append(p)
			else:
				zeros.append(p)

		if zeros.size() <= 1:
			break

		pattern.clear()
		var min_size = mini(ones.size(), zeros.size())
		for i in range(min_size):
			var combined = ones[i].duplicate()
			combined.append_array(zeros[i])
			pattern.append(combined)

		# Add remaining
		for i in range(min_size, ones.size()):
			pattern.append(ones[i])
		for i in range(min_size, zeros.size()):
			pattern.append(zeros[i])

	# Flatten to result
	var result: Array[bool] = []
	for p in pattern:
		for v in p:
			result.append(v)

	return result


## Generate random pattern with given density (0.0 - 1.0)
static func generate_random(steps: int, density: float) -> Array[bool]:
	var result: Array[bool] = []
	for i in range(steps):
		result.append(randf() < density)
	return result


## Mirror a pattern horizontally
static func mirror_pattern(pattern: Array[bool]) -> Array[bool]:
	var result: Array[bool] = pattern.duplicate()
	result.reverse()
	return result


## Shift pattern by offset
static func shift_pattern(pattern: Array[bool], offset: int) -> Array[bool]:
	var size = pattern.size()
	if size == 0:
		return pattern

	offset = offset % size
	if offset < 0:
		offset += size

	var result: Array[bool] = []
	for i in range(size):
		result.append(pattern[(i - offset + size) % size])
	return result
