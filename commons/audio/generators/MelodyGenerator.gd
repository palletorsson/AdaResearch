class_name MelodyGenerator
extends RefCounted
## Genre-specific melody and pattern generation
## Each genre has distinct melodic DNA - intervals, rhythms, character

# === MELODY PROFILES ===
# Each profile defines the melodic character of a genre

const PROFILES = {
	"madonna_80s": {
		"intervals": [0, 2, 3, 5, 7],  # Major pentatonic feel
		"rhythm": [1, 0, 1, 1, 0, 1, 1, 0],  # Syncopated pop
		"range_octaves": 1.0,
		"step_bias": 0.7,  # Prefer stepwise motion
		"repeat_bias": 0.3,  # Some note repetition
		"character": "hooky"
	},
	"prog_70s": {
		"intervals": [0, 2, 4, 5, 7, 9, 11],  # Full scale, modal
		"rhythm": [1, 1, 1, 0, 1, 1, 0, 1],  # Flowing
		"range_octaves": 1.5,
		"step_bias": 0.4,  # More leaps
		"repeat_bias": 0.1,  # Less repetition
		"character": "adventurous"
	},
	"burial": {
		"intervals": [0, 3, 5, 7, 10],  # Minor pentatonic, sparse
		"rhythm": [1, 0, 0, 1, 0, 0, 1, 0],  # Very sparse
		"range_octaves": 0.5,
		"step_bias": 0.5,
		"repeat_bias": 0.6,  # Lots of repetition (hypnotic)
		"character": "atmospheric"
	},
	"boards_of_canada": {
		"intervals": [0, 2, 4, 7, 9],  # Major pentatonic, childlike
		"rhythm": [1, 0, 1, 0, 1, 0, 0, 1],  # Simple, nostalgic
		"range_octaves": 0.8,
		"step_bias": 0.6,
		"repeat_bias": 0.4,
		"character": "nostalgic"
	},
	"kraftwerk": {
		"intervals": [0, 0, 7, 0, 0, 0, 5, 0],  # Sequence, not melody
		"rhythm": [1, 1, 1, 1, 1, 1, 1, 1],  # Mechanical 8ths or 16ths
		"range_octaves": 1.0,
		"step_bias": 0.2,  # Jumps (octaves, 5ths)
		"repeat_bias": 0.8,  # Very repetitive
		"character": "robotic"
	},
	"modern_pop": {
		"intervals": [0, 2, 4, 5, 7],  # Simple major
		"rhythm": [1, 0, 0, 1, 0, 1, 0, 0],  # Sparse, space
		"range_octaves": 0.7,
		"step_bias": 0.6,
		"repeat_bias": 0.5,
		"character": "minimal"
	},
	"synthwave": {
		"intervals": [0, 2, 3, 5, 7, 10],  # Minor with drama
		"rhythm": [1, 0, 1, 0, 1, 1, 0, 1],  # Arpeggio-like
		"range_octaves": 1.2,
		"step_bias": 0.5,
		"repeat_bias": 0.3,
		"character": "cinematic"
	},
	"french_touch": {
		"intervals": [0, 4, 7, 11],  # Disco/funk, major 7th
		"rhythm": [0, 1, 0, 1, 0, 1, 1, 0],  # Offbeat, funky
		"range_octaves": 0.8,
		"step_bias": 0.3,  # Chord tones, arpeggios
		"repeat_bias": 0.4,
		"character": "groovy"
	},
	"detroit_techno": {
		"intervals": [0, 3, 5, 7, 10],  # Minor, sparse
		"rhythm": [1, 0, 0, 0, 1, 0, 0, 1],  # Minimal
		"range_octaves": 1.0,
		"step_bias": 0.4,
		"repeat_bias": 0.5,
		"character": "hypnotic"
	},
	"acid_house": {
		"intervals": [0, 3, 5, 6, 7, 10],  # Minor blues + b5 (303 acid)
		"rhythm": [1, 1, 0, 1, 1, 0, 1, 0],  # Rolling 16ths
		"range_octaves": 1.5,
		"step_bias": 0.3,  # Wild leaps (resonant filter sweeps)
		"repeat_bias": 0.4,
		"character": "squelchy"
	},
	"acid_techno_303": {
		"intervals": [0, 1, 3, 5, 7, 10],  # Minor + chromatic b2
		"rhythm": [1, 1, 1, 0, 1, 1, 0, 1],  # Relentless
		"range_octaves": 2.0,
		"step_bias": 0.2,  # Big leaps, accent-driven
		"repeat_bias": 0.3,
		"character": "aggressive"
	},
	"ambient_techno": {
		"intervals": [0, 2, 5, 7, 9],  # Dorian feel (warm minor)
		"rhythm": [1, 0, 0, 0, 0, 1, 0, 0],  # Very sparse
		"range_octaves": 0.5,
		"step_bias": 0.7,  # Gentle movement
		"repeat_bias": 0.6,
		"character": "drifting"
	},
	"ambient_works": {
		"intervals": [0, 2, 3, 7, 9],  # Pentatonic minor + 2nd
		"rhythm": [1, 0, 0, 1, 0, 0, 0, 1],  # Irregular, human
		"range_octaves": 0.7,
		"step_bias": 0.6,
		"repeat_bias": 0.5,
		"character": "dreamy"
	},
	"rave": {
		"intervals": [0, 0, 7, 12],  # Octaves and 5ths (hoover stabs)
		"rhythm": [1, 0, 1, 0, 1, 1, 0, 1],  # Driving
		"range_octaves": 1.5,
		"step_bias": 0.2,  # Big jumps
		"repeat_bias": 0.5,
		"character": "euphoric"
	},
	"k_bass": {
		"intervals": [0, 3, 5, 7],  # Minimal minor (sub-focused)
		"rhythm": [1, 0, 0, 0, 1, 0, 0, 0],  # Sub pulses
		"range_octaves": 0.5,
		"step_bias": 0.5,
		"repeat_bias": 0.7,  # Very repetitive (hypnotic pressure)
		"character": "heavy"
	},
	"reese_jungle": {
		"intervals": [0, 3, 5, 7, 10],  # Minor pentatonic
		"rhythm": [1, 0, 1, 1, 0, 1, 0, 1],  # Breakbeat syncopation
		"range_octaves": 1.0,
		"step_bias": 0.3,  # Jumps (bass stabs)
		"repeat_bias": 0.4,
		"character": "rolling"
	},
	"supersaw_trance": {
		"intervals": [0, 2, 3, 5, 7, 8, 10],  # Full natural minor
		"rhythm": [1, 0, 1, 0, 1, 0, 1, 0],  # Steady 8ths
		"range_octaves": 1.2,
		"step_bias": 0.6,  # Singable, stepwise
		"repeat_bias": 0.2,  # Flowing, not stuck
		"character": "anthemic"
	},
	"midnight_metroplex": {
		"intervals": [0, 2, 3, 5, 7, 9, 10],  # Dorian (jazz minor)
		"rhythm": [1, 0, 0, 1, 0, 1, 0, 0],  # Syncopated jazz
		"range_octaves": 1.0,
		"step_bias": 0.4,
		"repeat_bias": 0.4,
		"character": "noir"
	},
	"lofi_house": {
		"intervals": [0, 3, 5, 7, 10],  # Minor pentatonic
		"rhythm": [0, 1, 0, 1, 0, 0, 1, 0],  # Offbeat, dusty
		"range_octaves": 0.7,
		"step_bias": 0.5,
		"repeat_bias": 0.5,
		"character": "dusty"
	},
	"dark_wave_cathedral": {
		"intervals": [0, 1, 3, 5, 7, 8, 10],  # Phrygian (dark, gothic)
		"rhythm": [1, 0, 0, 1, 0, 0, 1, 0],  # Sparse, reverberant
		"range_octaves": 1.0,
		"step_bias": 0.5,
		"repeat_bias": 0.4,
		"character": "gothic"
	}
}


## Generate a melody pattern for a genre
## Returns array of semitone offsets from root
static func generate_melody(genre: String, length: int = 8, seed_value: int = -1) -> Array:
	if seed_value >= 0:
		seed(seed_value)
	else:
		randomize()
	
	var profile = PROFILES.get(genre, null)
	if profile == null:
		push_warning("MelodyGenerator: No profile for '%s' — using modern_pop fallback. Add a profile to PROFILES." % genre)
		profile = PROFILES["modern_pop"]
	var intervals = profile.intervals
	var step_bias = profile.step_bias
	var repeat_bias = profile.repeat_bias
	var range_semitones = int(profile.range_octaves * 12)
	
	var melody = []
	var current_note = 0  # Start on root
	
	for i in range(length):
		# Decide: repeat, step, or leap?
		var r = randf()
		
		if r < repeat_bias and i > 0:
			# Repeat previous note
			melody.append(melody[i - 1])
		elif r < repeat_bias + step_bias:
			# Stepwise motion (move to adjacent interval)
			var direction = 1 if randf() > 0.5 else -1
			var current_idx = intervals.find(current_note % 12)
			if current_idx == -1:
				current_idx = 0
			var new_idx = clampi(current_idx + direction, 0, intervals.size() - 1)
			current_note = intervals[new_idx]
			# Keep in range
			while current_note > range_semitones:
				current_note -= 12
			while current_note < -range_semitones:
				current_note += 12
			melody.append(current_note)
		else:
			# Leap to any interval
			current_note = intervals[randi() % intervals.size()]
			# Random octave within range
			if randf() > 0.7 and range_semitones >= 12:
				current_note += 12 * (randi() % 2)
			melody.append(current_note)
	
	return melody


## Generate a rhythm pattern (1 = note, 0 = rest)
static func generate_rhythm(genre: String, length: int = 16, seed_value: int = -1) -> Array:
	if seed_value >= 0:
		seed(seed_value)
	else:
		randomize()
	
	var profile = PROFILES.get(genre, PROFILES["modern_pop"])
	var base_rhythm = profile.rhythm
	
	# Extend or truncate base rhythm to desired length
	var rhythm = []
	for i in range(length):
		var base_val = base_rhythm[i % base_rhythm.size()]
		# Add some variation
		if randf() < 0.15:
			base_val = 1 - base_val  # Flip occasionally
		rhythm.append(base_val)
	
	return rhythm


## Generate a complete phrase (melody + rhythm combined)
static func generate_phrase(genre: String, steps: int = 8, seed_value: int = -1) -> Dictionary:
	var melody = generate_melody(genre, steps, seed_value)
	var rhythm = generate_rhythm(genre, steps, seed_value + 1 if seed_value >= 0 else -1)
	
	# Combine: if rhythm is 0, use -100 as "rest" marker
	var phrase = []
	for i in range(steps):
		if rhythm[i] == 1:
			phrase.append(melody[i % melody.size()])
		else:
			phrase.append(-100)  # Rest marker
	
	return {
		"notes": phrase,
		"melody": melody,
		"rhythm": rhythm,
		"genre": genre
	}


## Get a pre-defined hook for a genre (more controlled than random)
static func get_signature_hook(genre: String) -> Array:
	match genre:
		"madonna_80s":
			# Catchy, stepwise with resolution
			return [0, 2, 4, 2, 0, 0, 5, 4]
		"prog_70s":
			# Modal, uses 4ths and 5ths
			return [0, 5, 7, 5, 0, 4, 7, 12]
		"burial":
			# Sparse, minor, atmospheric
			return [0, -100, 7, -100, 5, -100, 3, 0]
		"boards_of_canada":
			# Childlike pentatonic
			return [0, 4, 7, 4, 0, -3, 0, 4]
		"kraftwerk":
			# Robotic sequence (not really melody)
			return [0, 0, 12, 0, 7, 0, 12, 0]
		"modern_pop":
			# Sparse, rhythmic
			return [0, -100, 4, -100, 7, 4, -100, 0]
		"synthwave":
			# Cinematic minor
			return [0, 3, 7, 12, 7, 3, 0, -2]
		"french_touch":
			# Funky, chord-based
			return [-100, 4, -100, 7, -100, 11, 7, -100]
		"detroit_techno":
			# Minimal, hypnotic
			return [0, -100, -100, 5, -100, -100, 7, -100]
		_:
			return [0, 2, 4, 2, 0, -1, 0, 2]


## Get characteristic arpeggio pattern for genre
static func get_arp_pattern(genre: String) -> Array:
	match genre:
		"madonna_80s":
			return [0, 4, 7, 12, 7, 4, 0, 4]  # Major triad up/down
		"prog_70s":
			return [0, 7, 12, 7, 0, 5, 12, 5]  # 5ths and octaves
		"burial":
			return [0, 7, 0, 7, 0, 7, 0, 5]  # Minimal 5ths
		"boards_of_canada":
			return [0, 4, 7, 4, 9, 4, 7, 4]  # Pentatonic
		"kraftwerk":
			return [0, 12, 0, 12, 7, 12, 0, 12]  # Octave + 5th
		"modern_pop":
			return [0, 7, 12, 16, 12, 7, 0, 7]  # Wide, sparse feel
		"synthwave":
			return [0, 3, 7, 12, 15, 12, 7, 3]  # Minor arp
		"french_touch":
			return [0, 4, 7, 11, 7, 4, 0, -1]  # Maj7 arp
		"detroit_techno":
			return [0, 0, 7, 7, 0, 0, 5, 5]  # Stab pattern
		_:
			return [0, 4, 7, 12, 7, 4, 0, 4]


## Get bass pattern style for genre
static func get_bass_pattern(genre: String) -> Dictionary:
	match genre:
		"madonna_80s":
			return {
				"style": "octave_jump",  # Low-low-HIGH-low
				"pattern": [0, 0, 12, 0, 0, 0, 12, 0],
				"rhythm": [1, 0, 1, 0, 1, 0, 1, 0]
			}
		"prog_70s":
			return {
				"style": "walking",
				"pattern": [0, 2, 4, 5, 7, 5, 4, 2],
				"rhythm": [1, 1, 1, 1, 1, 1, 1, 1]
			}
		"burial":
			return {
				"style": "sub_pulse",
				"pattern": [0, 0, 0, 0, 0, 0, 0, 0],  # Just root
				"rhythm": [1, 0, 0, 0, 1, 0, 0, 0]
			}
		"boards_of_canada":
			return {
				"style": "warm_sub",
				"pattern": [0, 0, 0, 5, 0, 0, 0, 7],
				"rhythm": [1, 0, 0, 1, 1, 0, 0, 1]
			}
		"kraftwerk":
			return {
				"style": "sequence",
				"pattern": [0, 0, 0, 0, 5, 5, 7, 7],
				"rhythm": [1, 1, 1, 1, 1, 1, 1, 1]
			}
		"modern_pop":
			return {
				"style": "808_sub",
				"pattern": [0, 0, 0, 0, 0, 0, 0, 0],
				"rhythm": [1, 0, 0, 0, 1, 0, 1, 0]
			}
		"synthwave":
			return {
				"style": "driving",
				"pattern": [0, 0, 7, 0, 0, 0, 5, 0],
				"rhythm": [1, 0, 1, 0, 1, 0, 1, 0]
			}
		"french_touch":
			return {
				"style": "disco",
				"pattern": [0, 12, 0, 12, 0, 12, 7, 12],
				"rhythm": [1, 1, 1, 1, 1, 1, 1, 1]
			}
		"detroit_techno":
			return {
				"style": "minimal",
				"pattern": [0, 0, 0, 0, 0, 0, 0, 0],
				"rhythm": [1, 0, 0, 1, 0, 0, 1, 0]
			}
		_:
			return {
				"style": "root",
				"pattern": [0, 0, 0, 0, 0, 0, 0, 0],
				"rhythm": [1, 0, 1, 0, 1, 0, 1, 0]
			}
