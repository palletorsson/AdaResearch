class_name PopMusicTheory

# PopMusicTheory.gd
# Helper for frequencies, scales, and chord progressions

const A4_FREQ = 440.0
const NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# Frequencies
static func get_freq(note_name: String) -> float:
	# Parse "C4", "F#3"
	if note_name.length() < 2: return 440.0
	
	var key = note_name.substr(0, note_name.length()-1)
	var octave = int(note_name.substr(note_name.length()-1))
	
	var note_idx = NOTES.find(key)
	if note_idx == -1: return 440.0
	
	# MIDI Note Number: C4 is 60. A4 is 69.
	# C4 index is 0. 
	# A4 is index 9.
	# Formula: f = 440 * 2^((n - 69) / 12)
	
	var semitone_from_c0 = note_idx + (octave + 1) * 12
	# MIDI note 0 is C-1.
	# C4 is note 60. 
	# semitone_from_c0 for C4: 0 + (4+1)*12 = 60. Correct.
	
	var n = semitone_from_c0
	return 440.0 * pow(2.0, (n - 69.0) / 12.0)

# Scales
static func get_major_scale_notes(root: String) -> Array[String]:
	var root_key = root.substr(0, root.length()-1)
	var root_idx = NOTES.find(root_key)
	var start_octave = int(root.substr(root.length()-1))
	
	# Major Scale Intervals: W W H W W W H (2 2 1 2 2 2 1)
	var intervals = [0, 2, 4, 5, 7, 9, 11]
	
	var scale: Array[String] = []
	for interval in intervals:
		var idx = root_idx + interval
		var oct_shift = floor(idx / 12.0)
		var note_name = NOTES[idx % 12]
		var octave = start_octave + oct_shift
		scale.append(note_name + str(int(octave)))
		
	return scale # Returns 7 notes [I, ii, iii, IV, V, vi, vii]

static func get_minor_scale_notes(root: String) -> Array[String]:
	var root_key = root.substr(0, root.length()-1)
	var root_idx = NOTES.find(root_key)
	var start_octave = int(root.substr(root.length()-1))
	
	# Natural Minor Scale Intervals: W H W W H W W (2 1 2 2 1 2 2)
	var intervals = [0, 2, 3, 5, 7, 8, 10]
	
	var scale: Array[String] = []
	for interval in intervals:
		var idx = root_idx + interval
		var oct_shift = floor(idx / 12.0)
		var note_name = NOTES[idx % 12]
		var octave = start_octave + oct_shift
		scale.append(note_name + str(int(octave)))
		
	return scale

# Chord Progressions
const PROG_POP_4 = [0, 4, 5, 3] # I, V, vi, IV
const PROG_DOO_WOP = [0, 5, 3, 4] # I, vi, IV, V
const PROG_EMOTIONAL = [5, 3, 0, 4] # vi, IV, I, V

static func get_chord_frequencies(scale: Array[String], degree_idx: int) -> Array[float]:
	# Triad: Root, 3rd, 5th
	# Degree_idx is 0-based index in scale (0 = I, 1 = ii, etc.)
	
	var root_note = scale[degree_idx]
	var third_note = scale[(degree_idx + 2) % 7]
	var fifth_note = scale[(degree_idx + 4) % 7]
	
	# Correction for octaves wrapping around scale
	# If degree + 2 >= 7, we are wrapping to next octave relative to root? 
	# The scale array is absolute.
	# We need to construct chords diatonically.
	# Simple way: just create a 2-octave scale array temporarily
	
	if degree_idx + 4 >= scale.size():
		# This logic is tricky with strings.
		# Let's trust the Caller to provide frequencies? No.
		pass
		
	var freqs: Array[float] = []
	freqs.append(get_freq(root_note))
	
	# Need to handle the octave jump for upper structures
	# If the 3rd or 5th is lower in pitch index than root, bump octave.
	# Actually, assuming input scale is sorted C4...B4.
	# But key of F: F G A A# C D E. C is higher than F.
	# Key of B: B C# D#... C# is higher than B? No, C#5 vs B4.
	
	# Let's re-calculate frequencies on the fly from the scale indices logic
	# Just returning root, third, fifth from the scale list usually works if strict diatonic.
	# But we might need to bump octave if index wraps.
	
	var n1 = scale[degree_idx]
	var n2 = scale[(degree_idx + 2) % 7]
	var n3 = scale[(degree_idx + 4) % 7]
	
	var f1 = get_freq(n1)
	var f2 = get_freq(n2)
	var f3 = get_freq(n3)
	
	# If f2 < f1, bump f2 octave
	if f2 < f1: f2 *= 2.0
	# If f3 < f1, bump f3 octave
	if f3 < f1: f3 *= 2.0
	
	return [f1, f2, f3]
