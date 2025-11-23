@tool
extends EditorScript

func _run():
	print("--- Iteration 3: Renderer Test ---")
	
	# We can't easily visual test in headless mode, but we can check if it crashes
	var renderer = load("res://algorithms/machinelearning/thegame_a/GardenRenderer.gd").new()
	renderer._ready()
	
	# Mock data from Turtle
	var lines = [
		PackedVector3Array([Vector3(0,0,0), Vector3(0,1,0)]),
		PackedVector3Array([Vector3(0,1,0), Vector3(1,2,0)])
	]
	
	renderer.render(lines)
	
	print("Rendered " + str(lines.size()) + " instances.")
	print("MultiMesh instance count: " + str(renderer.multi_mesh_instance.multimesh.instance_count))
	
	assert(renderer.multi_mesh_instance.multimesh.instance_count == 2, "Renderer instance count mismatch!")
	print("--- Iteration 3 Complete ---")
