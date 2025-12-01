@tool
extends Node

func _ready():
	print("--- Euclidean Rhythm Verification ---")
	
	# Test cases from Toussaint's paper
	var tests = [
		{ "n": 5, "k": 2, "name": "E(2,5) - Persian/West Africa", "expected": "x.x.." }, # [10100]
		{ "n": 8, "k": 3, "name": "E(3,8) - Cuban Tresillo", "expected": "x..x..x." }, # [10010010]
		{ "n": 8, "k": 5, "name": "E(5,8) - Cinquillo", "expected": "x.xx.xx." }, # [10110110] -> Wait, paper says [x.x.x.x.]? 
		# Let's check the paper's E(5,8). It says [x.x.x.x.] = (21212). That's [10110110]? No, 2=10, 1=1. 
		# 21212 -> 10 1 10 1 10 -> x. x x. x x.  -> x.xx.xx. Correct.
		
		{ "n": 12, "k": 7, "name": "E(7,12) - West African Bell", "expected": "x.xx.x.xx.x." }, # [101101011010]
		{ "n": 16, "k": 5, "name": "E(5,16) - Bossa Nova", "expected": "x..x..x..x..x..." } # [1001001001001000]
	]
	
	for t in tests:
		var pattern = EuclideanSequencer.generate_rhythm(t.n, t.k)
		var s = EuclideanSequencer.to_string_pattern(pattern)
		print("Test: %s (n=%d, k=%d)" % [t.name, t.n, t.k])
		print("Result:   %s" % s)
		
		# Note: Rotations are common in music. The algorithm generates one standard form.
		# We might need to check if the result is a rotation of the expected if strict match fails.
		if s == t.expected:
			print("Status: MATCH")
		else:
			print("Status: MISMATCH (Checking rotations...)")
			var found = false
			for i in range(t.n):
				var rotated = EuclideanSequencer.rotate_pattern(pattern, i)
				if EuclideanSequencer.to_string_pattern(rotated) == t.expected:
					print("  Found match at rotation %d: %s" % [i, t.expected])
					found = true
					break
			if not found:
				print("  FAILED match.")
	
	print("--- End Verification ---")

