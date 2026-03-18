@tool
extends EditorScript

func _run() -> void:
	print("--- Iteration 2: Turtle Graphics Test ---")
	
	var turtle = load("res://algorithms/machinelearning/thegame_a/Turtle.gd").new()
	
	# Test 1: Simple Branch
	# F[+F][-F]
	# Should produce 3 segments
	var instructions = "F[+F][-F]"
	var lines = turtle.process_string(instructions)
	
	print("Instructions: " + instructions)
	print("Segments generated: " + str(lines.size()))
	
	if lines.size() == 3:
		print("Segment count correct.")
	else:
		push_error("Expected 3 segments, got " + str(lines.size()))
		
	# Check continuity
	# Segment 0: (0,0,0) -> (0,1,0) (assuming UP)
	var seg0 = lines[0]
	print("Seg 0: " + str(seg0[0]) + " -> " + str(seg0[1]))
	
	assert(lines.size() == 3, "Turtle test failed!")
	print("--- Iteration 2 Complete ---")
