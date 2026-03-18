@tool
extends EditorScript

func _run() -> void:
	print("--- Iteration 4: Integration Test ---")
	
	# Simulate the Main Scene
	var garden = load("res://algorithms/machinelearning/thegame_a/AxiomGarden.gd").new()
	
	# Mock UI
	var ui = Control.new()
	ui.name = "UI"
	var panel = Panel.new()
	panel.name = "Panel"
	var input = LineEdit.new()
	input.name = "RuleInput"
	input.text = "F=F[+F]F[-F]" # Default rule
	var btn = Button.new()
	btn.name = "GrowButton"
	
	panel.add_child(input)
	panel.add_child(btn)
	ui.add_child(panel)
	garden.add_child(ui)
	
	# Mock Renderer (needs to be in tree for _ready)
	var renderer = load("res://algorithms/machinelearning/thegame_a/GardenRenderer.gd").new()
	renderer.name = "GardenRenderer"
	garden.add_child(renderer)
	
	# Run _ready manually since we aren't adding garden to the main tree
	garden._ready()
	
	# Verify initial state
	print("Initial render complete.")
	assert(garden.renderer.multi_mesh_instance.multimesh.instance_count > 0, "Nothing rendered!")
	
	# Test Interaction
	input.text = "F=FF" # Change rule to simple line
	garden._on_grow_pressed()
	
	print("Updated render complete.")
	# With F=FF and 4 gens, we expect F -> FF -> FFFF -> FFFFFFFF -> 16 Fs.
	# 16 segments.
	var count = garden.renderer.multi_mesh_instance.multimesh.instance_count
	print("Instance count: " + str(count))
	assert(count == 16, "Expected 16 segments, got " + str(count))
	
	print("--- Iteration 4 Complete ---")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

