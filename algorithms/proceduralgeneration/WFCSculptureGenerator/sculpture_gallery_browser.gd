## Sculpture Gallery Browser
## Browse and explore beautiful WFC-generated sculptures
extends Node3D

## Gallery settings
@export var sculptures_per_row : int = 4
@export var spacing : float = 1.0
@export var auto_generate_on_start : bool = true
@export var sculpture_size_preview : Vector3i = Vector3i(10, 10, 10)  # Smaller for preview
@export var voxel_size : float = 0.35

## Gallery control
@export var regenerate_gallery : bool = false : set = _regenerate
@export var current_page : int = 0
@export var sculptures_per_page : int = 12

## Interactive
@export var enable_rotation : bool = false
@export var rotation_speed : float = 0.2

var sculptures_data : Array[Dictionary] = []
var current_sculptures : Array[WFCSculptureGenerator] = []

func _ready():
	if auto_generate_on_start:
		call_deferred("generate_gallery_page")

func _regenerate(value):
	if value:
		generate_gallery_page()

func _process(delta):
	if enable_rotation:
		for sculpture in current_sculptures:
			sculpture.rotation.y += rotation_speed * delta

func generate_gallery_page():
	print("🎨 Generating sculpture gallery page ", current_page, "...")
	
	# Clear existing
	clear_gallery()
	
	# Generate interesting parameter combinations
	generate_sculpture_variations()
	
	print("✅ Gallery page ", current_page, " complete with ", current_sculptures.size(), " sculptures")

func clear_gallery():
	for child in get_children():
		if child is WFCSculptureGenerator or child.has_meta("gallery_item"):
			child.queue_free()
	current_sculptures.clear()

func generate_sculpture_variations():
	var configs = get_page_configurations()
	
	for i in range(configs.size()):
		var config = configs[i]
		var row = i / sculptures_per_row
		var col = i % sculptures_per_row
		
		var pos = Vector3(
			col * spacing - (sculptures_per_row - 1) * spacing * 0.5,
			0,
			row * spacing
		)
		
		await create_sculpture_from_config(config, pos, i)

func get_page_configurations() -> Array[Dictionary]:
	var all_configs : Array[Dictionary] = []
	
	# Beautiful parameter combinations for each sculpture type
	var beautiful_presets = [
		# Page 0: Organic forms
		{
			"name": "Flowing Organic",
			"type": WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC,
			"hollow": 0.7, "complexity": 0.8, "organic": 0.9,
			"seed": 1001
		},
		{
			"name": "Dense Organic",
			"type": WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC,
			"hollow": 0.3, "complexity": 0.6, "organic": 0.8,
			"seed": 1002
		},
		{
			"name": "Porous Organic",
			"type": WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC,
			"hollow": 0.8, "complexity": 0.9, "organic": 0.7,
			"seed": 1003
		},
		{
			"name": "Smooth Organic",
			"type": WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC,
			"hollow": 0.5, "complexity": 0.4, "organic": 0.9,
			"seed": 1004
		},
		
		# Crystals
		{
			"name": "Sharp Crystal",
			"type": WFCSculptureGenerator.SculptureType.GEOMETRIC_CRYSTAL,
			"hollow": 0.4, "complexity": 0.7, "organic": 0.2,
			"seed": 2001
		},
		{
			"name": "Faceted Gem",
			"type": WFCSculptureGenerator.SculptureType.GEOMETRIC_CRYSTAL,
			"hollow": 0.3, "complexity": 0.8, "organic": 0.1,
			"seed": 2002
		},
		{
			"name": "Hollow Crystal",
			"type": WFCSculptureGenerator.SculptureType.GEOMETRIC_CRYSTAL,
			"hollow": 0.7, "complexity": 0.6, "organic": 0.3,
			"seed": 2003
		},
		{
			"name": "Geode",
			"type": WFCSculptureGenerator.SculptureType.GEOMETRIC_CRYSTAL,
			"hollow": 0.8, "complexity": 0.9, "organic": 0.2,
			"seed": 2004
		},
		
		# Biological
		{
			"name": "Coral Branch",
			"type": WFCSculptureGenerator.SculptureType.BIOLOGICAL,
			"hollow": 0.6, "complexity": 0.9, "organic": 0.9,
			"seed": 3001
		},
		{
			"name": "Sea Sponge",
			"type": WFCSculptureGenerator.SculptureType.BIOLOGICAL,
			"hollow": 0.8, "complexity": 0.8, "organic": 0.8,
			"seed": 3002
		},
		{
			"name": "Cell Structure",
			"type": WFCSculptureGenerator.SculptureType.BIOLOGICAL,
			"hollow": 0.5, "complexity": 0.7, "organic": 0.7,
			"seed": 3003
		},
		{
			"name": "Bone Form",
			"type": WFCSculptureGenerator.SculptureType.BIOLOGICAL,
			"hollow": 0.4, "complexity": 0.5, "organic": 0.6,
			"seed": 3004
		},
	]
	
	# Page 1: More types
	beautiful_presets.append_array([
		{
			"name": "Fluid Wave",
			"type": WFCSculptureGenerator.SculptureType.FLUID_DYNAMIC,
			"hollow": 0.5, "complexity": 0.7, "organic": 0.9,
			"seed": 4001
		},
		{
			"name": "Liquid Drop",
			"type": WFCSculptureGenerator.SculptureType.FLUID_DYNAMIC,
			"hollow": 0.4, "complexity": 0.6, "organic": 0.95,
			"seed": 4002
		},
		{
			"name": "Frozen Splash",
			"type": WFCSculptureGenerator.SculptureType.FLUID_DYNAMIC,
			"hollow": 0.6, "complexity": 0.8, "organic": 0.9,
			"seed": 4003
		},
		{
			"name": "Spiral Form",
			"type": WFCSculptureGenerator.SculptureType.SPIRAL_TORUS,
			"hollow": 0.5, "complexity": 0.6, "organic": 0.7,
			"seed": 5001
		},
		{
			"name": "Twisted Torus",
			"type": WFCSculptureGenerator.SculptureType.SPIRAL_TORUS,
			"hollow": 0.7, "complexity": 0.7, "organic": 0.6,
			"seed": 5002
		},
		{
			"name": "Helix",
			"type": WFCSculptureGenerator.SculptureType.SPIRAL_TORUS,
			"hollow": 0.6, "complexity": 0.5, "organic": 0.8,
			"seed": 5003
		},
		{
			"name": "Tree Branch",
			"type": WFCSculptureGenerator.SculptureType.FRACTAL_TREE,
			"hollow": 0.5, "complexity": 0.7, "organic": 0.8,
			"seed": 6001
		},
		{
			"name": "Root System",
			"type": WFCSculptureGenerator.SculptureType.FRACTAL_TREE,
			"hollow": 0.6, "complexity": 0.8, "organic": 0.7,
			"seed": 6002
		},
		{
			"name": "Sphere Cluster",
			"type": WFCSculptureGenerator.SculptureType.SPHERE_CLUSTER,
			"hollow": 0.4, "complexity": 0.6, "organic": 0.6,
			"seed": 7001
		},
		{
			"name": "Bubble Foam",
			"type": WFCSculptureGenerator.SculptureType.SPHERE_CLUSTER,
			"hollow": 0.7, "complexity": 0.8, "organic": 0.7,
			"seed": 7002
		},
		{
			"name": "Fiber Network",
			"type": WFCSculptureGenerator.SculptureType.FIBROUS_NETWORK,
			"hollow": 0.7, "complexity": 0.8, "organic": 0.7,
			"seed": 8001
		},
		{
			"name": "Web Structure",
			"type": WFCSculptureGenerator.SculptureType.FIBROUS_NETWORK,
			"hollow": 0.8, "complexity": 0.9, "organic": 0.6,
			"seed": 8002
		},
	])
	
	# Return page subset
	var start_idx = current_page * sculptures_per_page
	var end_idx = min(start_idx + sculptures_per_page, beautiful_presets.size())
	
	for i in range(start_idx, end_idx):
		all_configs.append(beautiful_presets[i])
	
	return all_configs

func create_sculpture_from_config(config: Dictionary, pos: Vector3, index: int):
	var sculpture = WFCSculptureGenerator.new()
	sculpture.name = "Sculpture_%d_%s" % [index, config["name"]]
	sculpture.position = pos
	
	# Apply configuration
	sculpture.sculpture_size = sculpture_size_preview
	sculpture.voxel_size = voxel_size
	sculpture.hollow_intensity = config.get("hollow", 0.5)
	sculpture.surface_complexity = config.get("complexity", 0.6)
	sculpture.organic_flow = config.get("organic", 0.7)
	sculpture.sculpture_seed = config.get("seed", randi())
	sculpture.sculpture_type = config.get("type", WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC)
	
	add_child(sculpture)
	current_sculptures.append(sculpture)
	
	# Add label
	var label = Label3D.new()
	label.name = "Label_" + str(index)
	label.text = config["name"]
	label.font_size = 16
	label.outline_size = 4
	label.transform.origin = pos + Vector3(0, -8, 0)
	label.set_meta("gallery_item", true)
	add_child(label)
	
	# Generate
	print("  🔨 Generating: ", config["name"])
	await sculpture.create_hollow_sculpture()
	print("  ✅ Complete: ", config["name"])

func next_page():
	current_page += 1
	if current_page > 1:  # Only 2 pages for now
		current_page = 0
	generate_gallery_page()

func previous_page():
	current_page -= 1
	if current_page < 0:
		current_page = 1
	generate_gallery_page()

func _input(event):
	if event.is_action_pressed("ui_right"):
		next_page()
	elif event.is_action_pressed("ui_left"):
		previous_page()
	elif event.is_action_pressed("ui_accept"):  # Space
		generate_gallery_page()

func save_favorite(sculpture: WFCSculptureGenerator):
	var favorite = {
		"name": sculpture.name,
		"type": sculpture.sculpture_type,
		"hollow": sculpture.hollow_intensity,
		"complexity": sculpture.surface_complexity,
		"organic": sculpture.organic_flow,
		"seed": sculpture.sculpture_seed,
		"timestamp": Time.get_unix_time_from_system()
	}
	sculptures_data.append(favorite)
	print("⭐ Saved favorite: ", favorite["name"])
	return favorite

func export_favorites_json() -> String:
	return JSON.stringify(sculptures_data, "\t")
