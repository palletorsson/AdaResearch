@tool
extends EditorScript

func _run() -> void:
	print("--- Iteration 10: Final Playthrough Simulation ---")
	
	# 1. Setup Game
	var garden = load("res://algorithms/machinelearning/thegame_a/AxiomGarden.gd").new()
	var renderer = load("res://algorithms/machinelearning/thegame_a/GardenRenderer.gd").new()
	renderer.name = "GardenRenderer"
	garden.add_child(renderer)
	
	# 2. Setup Level (Target at 5 units up)
	var target = load("res://algorithms/machinelearning/thegame_a/Target.gd").new()
	target.position = Vector3(0, 5, 0)
	target.radius = 1.0
	target.add_to_group("targets") # Note: Might not work without SceneTree, but logic is there
	garden.add_child(target)
	
	# 3. Player Input (The Solution)
	# To reach 5 units up, we need a straight line or a tall tree.
	# Let's try a simple recursive growth.
	garden.lsystem = load("res://algorithms/machinelearning/thegame_a/LSystem.gd").new("F", {"F": "FF"})
	garden.generations = 3 # F -> FF -> FFFF -> FFFFFFFF (8 units)
	garden.step_length = 1.0
	
	# 4. Grow
	print("Player executes rule: F -> FF")
	garden.grow_garden()
	
	# 5. Evaluate Win Condition
	# We manually check since signals might not propagate in EditorScript
	var lines = garden.turtle.process_string(garden.lsystem.generate(3))
	var win = false
	for seg in lines:
		if seg[1].distance_to(target.position) < target.radius:
			win = true
			break
			
	if win:
		print("VICTORY! The plant reached the target.")
	else:
		print("DEFEAT. The plant did not reach the target.")
		
	assert(win == true, "Final playthrough failed.")
	print("--- The Axiom Garden is Ready ---")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

