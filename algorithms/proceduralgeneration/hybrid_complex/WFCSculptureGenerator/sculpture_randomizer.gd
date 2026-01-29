## Sculpture Randomizer - Discover New Beautiful Forms
## Generates random sculptures with parameter exploration
extends Node3D

@export var generate_random : bool = false : set = _generate
@export var sculpture_type_random : bool = true
@export var param_range_min : float = 0.3
@export var param_range_max : float = 0.9

var current_sculpture : WFCSculptureGenerator = null
var generation_history : Array[Dictionary] = []
var beautiful_finds : Array[Dictionary] = []

func _generate(value):
	if value:
		generate_random_sculpture()

func _ready():
	print("🎲 Sculpture Randomizer Ready")
	print("Press Space to generate random sculptures")
	print("Press S to save current sculpture as 'beautiful'")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space
		generate_random_sculpture()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		clear_current()
	elif event.is_pressed() and event.keycode == KEY_S:
		mark_as_beautiful()

func generate_random_sculpture():
	clear_current()
	
	# Random parameters
	var params = generate_random_parameters()
	
	print("\n🎲 Generating Random Sculpture #", generation_history.size() + 1)
	print("  Type: ", WFCSculptureGenerator.SculptureType.keys()[params.type])
	print("  Hollow: %.2f" % params.hollow)
	print("  Complexity: %.2f" % params.complexity)
	print("  Organic: %.2f" % params.organic)
	print("  Seed: ", params.seed)
	
	# Create sculpture
	current_sculpture = WFCSculptureGenerator.new()
	current_sculpture.name = "RandomSculpture_" + str(generation_history.size())
	current_sculpture.sculpture_type = params.type
	current_sculpture.sculpture_size = Vector3i(15, 18, 15)
	current_sculpture.voxel_size = 0.35
	current_sculpture.hollow_intensity = params.hollow
	current_sculpture.surface_complexity = params.complexity
	current_sculpture.organic_flow = params.organic
	current_sculpture.sculpture_seed = params.seed
	
	add_child(current_sculpture)
	
	# Save to history
	generation_history.append(params)
	
	# Generate
	await current_sculpture.create_hollow_sculpture()
	print("✅ Complete!")

func generate_random_parameters() -> Dictionary:
	var params = {}
	
	# Random or specific type
	if sculpture_type_random:
		params.type = randi() % WFCSculptureGenerator.SculptureType.size()
	else:
		params.type = WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC
	
	# Parameter exploration strategies
	var strategy = randi() % 5
	
	match strategy:
		0:  # Extreme hollow
			params.hollow = randf_range(0.7, 0.95)
			params.complexity = randf_range(param_range_min, param_range_max)
			params.organic = randf_range(param_range_min, param_range_max)
		
		1:  # Extreme complexity
			params.hollow = randf_range(param_range_min, param_range_max)
			params.complexity = randf_range(0.75, 0.95)
			params.organic = randf_range(param_range_min, param_range_max)
		
		2:  # Extreme organic
			params.hollow = randf_range(param_range_min, param_range_max)
			params.complexity = randf_range(param_range_min, param_range_max)
			params.organic = randf_range(0.75, 0.95)
		
		3:  # Balanced exploration
			params.hollow = randf_range(0.4, 0.7)
			params.complexity = randf_range(0.5, 0.8)
			params.organic = randf_range(0.5, 0.8)
		
		4:  # Wide random
			params.hollow = randf_range(0.2, 0.95)
			params.complexity = randf_range(0.3, 0.95)
			params.organic = randf_range(0.2, 0.95)
	
	params.seed = randi()
	params.strategy = ["Extreme Hollow", "Extreme Complex", "Extreme Organic", "Balanced", "Wide Random"][strategy]
	
	return params

func clear_current():
	if current_sculpture:
		current_sculpture.queue_free()
		current_sculpture = null

func mark_as_beautiful():
	if current_sculpture and generation_history.size() > 0:
		var params = generation_history[generation_history.size() - 1]
		params["marked_beautiful"] = true
		params["timestamp"] = Time.get_unix_time_from_system()
		beautiful_finds.append(params)
		
		print("⭐ MARKED AS BEAUTIFUL!")
		print("   ", beautiful_finds.size(), " beautiful sculptures found")
		
		# Export beautiful ones
		export_beautiful_sculptures()
	else:
		print("⚠️  No sculpture to mark")

func export_beautiful_sculptures():
	if beautiful_finds.is_empty():
		return
	
	print("\n🌟 === BEAUTIFUL SCULPTURES === 🌟")
	for i in range(beautiful_finds.size()):
		var params = beautiful_finds[i]
		print("\n  Sculpture #", i + 1)
		print("  {")
		print('    "name": "Beautiful_', i + 1, '",')
		print('    "type": WFCSculptureGenerator.SculptureType.', WFCSculptureGenerator.SculptureType.keys()[params.type], ',')
		print('    "hollow": ', "%.2f" % params.hollow, ',')
		print('    "complexity": ', "%.2f" % params.complexity, ',')
		print('    "organic": ', "%.2f" % params.organic, ',')
		print('    "seed": ', params.seed)
		print("  },")
	print("\n🌟 === Copy these into gallery_browser.gd! === 🌟\n")

func get_beautiful_json() -> String:
	return JSON.stringify(beautiful_finds, "\t")

func print_statistics():
	if generation_history.is_empty():
		print("No sculptures generated yet")
		return
	
	print("\n📊 === GENERATION STATISTICS === 📊")
	print("Total Generated: ", generation_history.size())
	print("Marked Beautiful: ", beautiful_finds.size())
	print("Success Rate: %.1f%%" % (float(beautiful_finds.size()) / generation_history.size() * 100.0))
	
	# Type distribution
	var type_counts = {}
	for params in generation_history:
		var type_name = WFCSculptureGenerator.SculptureType.keys()[params.type]
		type_counts[type_name] = type_counts.get(type_name, 0) + 1
	
	print("\nType Distribution:")
	for type_name in type_counts:
		print("  ", type_name, ": ", type_counts[type_name])
	
	# Average beautiful parameters
	if not beautiful_finds.is_empty():
		var avg_hollow = 0.0
		var avg_complexity = 0.0
		var avg_organic = 0.0
		
		for params in beautiful_finds:
			avg_hollow += params.hollow
			avg_complexity += params.complexity
			avg_organic += params.organic
		
		avg_hollow /= beautiful_finds.size()
		avg_complexity /= beautiful_finds.size()
		avg_organic /= beautiful_finds.size()
		
		print("\nAverage Beautiful Parameters:")
		print("  Hollow: %.2f" % avg_hollow)
		print("  Complexity: %.2f" % avg_complexity)
		print("  Organic: %.2f" % avg_organic)
	
	print("📊 ============================== 📊\n")

