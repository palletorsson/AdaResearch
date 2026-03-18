@tool
extends EditorScript

func _run() -> void:
	print("--- Iteration 1: L-System Logic Test ---")
	
	# Test Case 1: Algae (Lindenmayer's original)
	# A -> AB, B -> A
	var lsys = load("res://algorithms/machinelearning/thegame_a/LSystem.gd").new()
	lsys.axiom = "A"
	lsys.set_rule("A", "AB")
	lsys.set_rule("B", "A")
	
	print("Gen 0: " + lsys.generate(0)) # Expected: A
	print("Gen 1: " + lsys.generate(1)) # Expected: AB
	print("Gen 2: " + lsys.generate(2)) # Expected: ABA
	print("Gen 3: " + lsys.generate(3)) # Expected: ABAAB
	print("Gen 4: " + lsys.generate(4)) # Expected: ABAABABA
	
	assert(lsys.generate(4) == "ABAABABA", "Algae test failed!")
	print("Algae test passed.")
	
	# Test Case 2: Simple Tree
	# F -> F[+F]F[-F]
	var tree = load("res://algorithms/machinelearning/thegame_a/LSystem.gd").new()
	tree.axiom = "F"
	tree.set_rule("F", "F[+F]F[-F]")
	
	print("Tree Gen 1: " + tree.generate(1))
	assert(tree.generate(1) == "F[+F]F[-F]", "Tree test failed!")
	print("Tree test passed.")
	
	print("--- Iteration 1 Complete ---")
