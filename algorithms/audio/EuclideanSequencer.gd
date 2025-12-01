class_name EuclideanSequencer
extends RefCounted

# Implementation of Bjorklund's algorithm for Euclidean Rhythms
# Based on: "The Euclidean Algorithm Generates Traditional Musical Rhythms" by Godfried Toussaint

# Generates a Euclidean rhythm pattern
# steps (n): The total number of time intervals (steps) in the pattern
# pulses (k): The number of pulses (beats/onsets) to distribute evenly
# Returns: An Array of bools where true represents a pulse and false represents silence
static func generate_rhythm(steps: int, pulses: int) -> Array[bool]:
	if pulses >= steps:
		var result: Array[bool] = []
		for i in range(steps):
			result.append(true)
		return result
		
	if pulses <= 0:
		var result: Array[bool] = []
		for i in range(steps):
			result.append(false)
		return result

	# Initialize the sequences
	# We start with 'pulses' number of [1] sequences and 'steps - pulses' number of [0] sequences
	var sequences: Array[Array] = [] # Array of Arrays of bools
	var remainder: Array[Array] = []
	
	for i in range(pulses):
		sequences.append([true])
		
	for i in range(steps - pulses):
		remainder.append([false])
		
	# Repeatedly distribute the remainder sequences into the main sequences
	while remainder.size() > 0:
		if sequences.size() == 0:
			break
			
		# We want to move items from remainder to sequences
		# If remainder is larger than sequences, we can only distribute 'sequences.size()' items
		# The rest stay in remainder for the next pass? 
		# No, Bjorklund's algorithm is slightly different.
		
		# Let's follow the paper's example: E(5, 13) -> 5 pulses, 13 steps. 8 zeros.
		# [1] [1] [1] [1] [1] | [0] [0] [0] [0] [0] [0] [0] [0]
		# We distribute zeros to ones:
		# [10] [10] [10] [10] [10] | [0] [0] [0]
		# Now we have 5 sequences of [10] and 3 sequences of [0].
		# We distribute the 3 [0]s to the [10]s:
		# [100] [100] [100] | [10] [10]
		# Now we have 3 sequences of [100] and 2 sequences of [10].
		# We distribute the 2 [10]s to the [100]s:
		# [10010] [10010] | [100]
		# We stop when remainder has 0 or 1 item? Paper says "process stops when the remainder consists of only one sequence".
		
		var num_to_distribute = min(sequences.size(), remainder.size())
		
		# We are moving 'num_to_distribute' items from remainder and appending them to the first 'num_to_distribute' items of sequences.
		# The items remaining in 'remainder' (if any) become the NEW remainder.
		# But wait, if sequences.size() < remainder.size(), the un-appended remainder items stay as remainder.
		# But if sequences.size() > remainder.size(), the sequences that DIDN'T get an appendage become the NEW remainder.
		
		# Correct logic based on "distribute the remainder evenly":
		# We are essentially doing a GCD-like reduction.
		
		# Let's implement it iteratively:
		# 1. We have 'count' sequences (initially pulses) and 'rem' sequences (initially steps-pulses).
		# 2. We want to distribute 'rem' into 'count'.
		
		var new_sequences: Array[Array] = []
		var new_remainder: Array[Array] = []
		
		if remainder.size() <= sequences.size():
			# Case A: We have fewer (or equal) remainder items than sequences.
			# We append each remainder item to a sequence item.
			# The sequences that got appended to become the new 'sequences'.
			# The sequences that did NOT get appended to become the new 'remainder'.
			
			for i in range(remainder.size()):
				var seq = sequences[i]
				seq.append_array(remainder[i])
				new_sequences.append(seq)
				
			# The rest of sequences become the new remainder
			for i in range(remainder.size(), sequences.size()):
				new_remainder.append(sequences[i])
				
			sequences = new_sequences
			remainder = new_remainder
			
		else:
			# Case B: We have MORE remainder items than sequences.
			# We append one remainder item to each sequence item.
			# The LEFT OVER remainder items stay as the remainder.
			
			for i in range(sequences.size()):
				var seq = sequences[i]
				seq.append_array(remainder[i])
				
			# The rest of remainder stays as remainder
			# We don't change 'sequences' variable, just modify contents in place basically
			# But we need to slice remainder
			var left_over = remainder.slice(sequences.size())
			remainder = left_over
			
		# Stopping condition: 
		# The algorithm stops when we can't distribute anymore? 
		# In Case A, we created a new remainder.
		# In Case B, we reduced the remainder.
		# If remainder becomes empty, we are done.
		# If remainder has 1 item, we are done (it's just appended at the end).
		if remainder.size() <= 1:
			break
			
	# Final concatenation
	var result: Array[bool] = []
	for seq in sequences:
		result.append_array(seq)
	for seq in remainder:
		result.append_array(seq)
		
	return result

# Helper to convert bool array to string for debug/visualization
# e.g. "x.x.x.x."
static func to_string_pattern(pattern: Array[bool]) -> String:
	var s = ""
	for p in pattern:
		s += "x" if p else "."
	return s

# Helper: Rotate a pattern by 'shift' steps
static func rotate_pattern(pattern: Array[bool], shift: int) -> Array[bool]:
	if pattern.is_empty():
		return []
	var p = pattern.duplicate()
	var s = shift % p.size()
	# Rotate right (positive shift)
	for i in range(s):
		var last = p.pop_back()
		p.push_front(last)
	return p

