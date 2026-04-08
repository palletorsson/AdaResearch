@tool
extends EditorScript

func _run() -> void:
	print("--- Iteration 6: Withering Test ---")
	
	var garden = load("res://algorithms/machinelearning/thegame_a/AxiomGarden.gd").new()
	garden.max_segments = 10
	
	# Mock Renderer
	var renderer = load("res://algorithms/machinelearning/thegame_a/GardenRenderer.gd").new()
	renderer.name = "GardenRenderer"
	garden.add_child(renderer)
	
	# 1. Safe Growth
	# F -> F (1 segment)
	garden.lsystem = load("res://algorithms/machinelearning/thegame_a/LSystem.gd").new("F", {"F": "F"})
	garden.generations = 1
	garden.grow_garden()
	
	print("Safe growth count: " + str(garden.renderer.multi_mesh_instance.multimesh.instance_count))
	assert(garden.renderer.multi_mesh_instance.multimesh.instance_count == 1, "Should have grown.")
	
	# 2. Withered Growth
	# F -> F... (Explosion)
	# Actually, let's just force a long string manually to test the check logic
	# But we can't easily inject the string into grow_garden without modifying LSystem or mocking.
	# Let's just set generations high for a branching rule.
	garden.lsystem = load("res://algorithms/machinelearning/thegame_a/LSystem.gd").new("F", {"F": "FF"})
	garden.generations = 5 # 1 -> 2 -> 4 -> 8 -> 16 -> 32 segments. 32 > 10.
	garden.grow_garden()
	
	print("Withered growth count: " + str(garden.renderer.multi_mesh_instance.multimesh.instance_count))
	assert(garden.renderer.multi_mesh_instance.multimesh.instance_count == 0, "Should have withered (0 instances).")
	
	print("--- Iteration 6 Complete ---")



