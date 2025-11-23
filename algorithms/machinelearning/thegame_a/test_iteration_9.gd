@tool
extends EditorScript

func _run():
	print("--- Iteration 9: Stochastic Test ---")
	
	var lsys = load("res://algorithms/machinelearning/thegame_a/LSystem.gd").new()
	lsys.axiom = "A"
	# A -> B or C
	lsys.rules = {"A": ["B", "C"]}
	
	var results = {}
	for i in range(100):
		var res = lsys.generate(1)
		if not results.has(res):
			results[res] = 0
		results[res] += 1
		
	print("Results distribution: " + str(results))
	assert(results.has("B") and results.has("C"), "Should produce both variations.")
	
	print("--- Iteration 9 Complete ---")
