@tool
extends EditorScript

func _run() -> void:
	print("--- Iteration 8: Aesthetic Test ---")
	var env = load("res://algorithms/machinelearning/thegame_a/AxiomEnvironment.gd").new()
	env._ready()
	
	print("Background Color: " + str(env.environment.background_color))
	assert(env.environment.glow_enabled == true, "Glow should be enabled.")
	
	print("--- Iteration 8 Complete ---")
