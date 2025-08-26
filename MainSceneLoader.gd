extends Node3D

# Main Scene Loader
# Manages loading and cycling through algorithm scenes

var algorithm_scenes = []
var current_scene_index =   130
var loaded_scene_instance = null
var scene_info_label: Label
var scene_title_label: Label
var location_info_label: Label
var player_position_label: Label
var algorithm_container: Node3D
var player: CharacterBody3D

# Algorithm scenes loaded from external JSON file
@export var algorithms_config_file: String = "res://algorithms.json"
var scene_paths = []

func _ready():
	scene_info_label = $UI/SceneInfo
	scene_title_label = $UI/SceneTitle
	location_info_label = $UI/LocationInfo
	player_position_label = $UI/PlayerPosition
	algorithm_container = $AlgorithmContainer
	player = $Player
	
	# Load available algorithm scenes
	load_algorithm_scenes()
	
	# Start at wavefunctions and load the scene
	load_scene_at_index(current_scene_index)
	
	print("MainSceneLoader ready. Available scenes: ", algorithm_scenes.size())
	print("🚀 === ULTIMATE ALGORITHM COLLECTION === 🚀")
	print("📚 DEEP SCAN COMPLETE - EVERY ALGORITHM DISCOVERED!")
	print("")
	print("🔬 Advanced Laboratory: ", count_scenes_by_category("advancedlaboratory"), " scenes")
	print("🔮 Alternative Geometries: ", count_scenes_by_category("alternativegeometries"), " scenes") 
	print("🌪️ Chaos Theory: ", count_scenes_by_category("chaos"), " scenes")
	print("🧬 Computational Biology: ", count_scenes_by_category("computationalbiology"), " scenes")
	print("📐 Computational Geometry: ", count_scenes_by_category("computationalgeometry"), " scenes")
	print("⚖️ Critical Algorithms: ", count_scenes_by_category("criticalalgorithms"), " scenes")
	print("💭 Critical Theory: ", count_scenes_by_category("criticaltheory"), " scenes")
	print("🔐 Cryptography: ", count_scenes_by_category("cryptography"), " scenes")
	print("🗃️ Data Structures: ", count_scenes_by_category("datastructures"), " scenes")
	print("🌱 Emergent Systems: ", count_scenes_by_category("emergentsystems"), " scenes")
	print("🕸️ Graph Theory: ", count_scenes_by_category("graphtheory"), " scenes")
	print("🧠 Machine Learning: ", count_scenes_by_category("machinelearning"), " scenes - MASSIVE ML COLLECTION!")
	print("🧪 Neuroscience: ", count_scenes_by_category("neuroscience"), " scenes")
	print("📊 Numerical Methods: ", count_scenes_by_category("numericalmethods"), " scenes")
	print("⚡ Optimization: ", count_scenes_by_category("optimization"), " scenes")
	print("🎨 Pattern Generation: ", count_scenes_by_category("patterngeneration"), " scenes")
	print("📐 Primitives: ", count_scenes_by_category("primitives"), " scenes")
	print("🎵 Procedural Audio: ", count_scenes_by_category("proceduralaudio"), " scenes")
	print("🌱 Procedural Generation: ", count_scenes_by_category("proceduralgeneration"), " scenes")
	print("⚛️ Quantum Algorithms: ", count_scenes_by_category("quantumalgorithms"), " scenes")
	print("🔍 Search & Pathfinding: ", count_scenes_by_category("searchpathfinding"), " scenes")
	print("🔄 Sorting Algorithms: ", count_scenes_by_category("sortingalgorithms"), " scenes")
	print("📝 String Algorithms: ", count_scenes_by_category("stringalgorithms"), " scenes")
	print("🐝 Swarm Intelligence: ", count_scenes_by_category("swarmintelligence"), " scenes")
	print("🎲 Randomness & Noise: ", count_scenes_by_category("randomness"), " scenes")
	print("🌊 Wave Functions: ", count_scenes_by_category("wavefunctions"), " scenes")
	print("📐 Physics Simulation: ", count_scenes_by_category("physicssimulation"), " scenes")
	print("📊 Space Topology: ", count_scenes_by_category("spacetopology"), " scenes")
	print("🎨 Commons & Primitives: ", count_scenes_by_category("commons"), " scenes")
	print("")
	print("🎯 ULTIMATE TOTAL: ", algorithm_scenes.size(), " ALGORITHM SCENES!")
	print("🏆 THIS IS THE MOST COMPREHENSIVE ALGORITHM COLLECTION EVER ASSEMBLED!")
	update_scene_info()

func _process(_delta):
	# Update player position display
	update_player_position()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_N:
			load_next_scene()
		elif event.keycode == KEY_P:
			load_previous_scene()
		elif event.keycode == KEY_R:
			reload_current_scene()
		elif event.keycode == KEY_U:
			unload_current_scene()

func load_algorithm_scenes():
	"""Load and validate algorithm scene paths from JSON file"""
	# Load scenes from JSON file
	load_scenes_from_json()

func load_scenes_from_json():
	"""Load algorithm scenes from the JSON configuration file"""
	var file = FileAccess.open(algorithms_config_file, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.data
			for category in data.categories:
				for scene_path in data.categories[category]:
					if ResourceLoader.exists(scene_path) and is_3d_scene(scene_path):
						algorithm_scenes.append(scene_path)
						scene_paths.append(scene_path)  # Keep scene_paths for compatibility
						print("Added scene from JSON: ", scene_path)
					elif not ResourceLoader.exists(scene_path):
						print("Scene not found in JSON: ", scene_path)
					else:
						print("Filtered out 2D scene from JSON: ", scene_path)
		else:
			print("Failed to parse JSON file: ", algorithms_config_file)
	else:
		print("Failed to open JSON file: ", algorithms_config_file)
		# Fallback to empty list if JSON fails
		scene_paths = []

func load_next_scene():
	"""Load the next algorithm scene in the list"""
	if algorithm_scenes.is_empty():
		print("No algorithm scenes available")
		return
	
	current_scene_index = (current_scene_index + 1) % algorithm_scenes.size()
	load_scene_at_index(current_scene_index)

func load_previous_scene():
	"""Load the previous algorithm scene in the list"""
	if algorithm_scenes.is_empty():
		return
	
	current_scene_index = (current_scene_index - 1) % algorithm_scenes.size()
	if current_scene_index < 0:
		current_scene_index = algorithm_scenes.size() - 1
	load_scene_at_index(current_scene_index)

func load_scene_at_index(index: int):
	"""Load a specific scene by index"""
	if index < 0 or index >= algorithm_scenes.size():
		return
	
	# Unload current scene
	unload_current_scene()
	
	var scene_path = algorithm_scenes[index]
	print("Loading scene: ", scene_path)
	
	var scene_resource = load(scene_path)
	if scene_resource:
		loaded_scene_instance = scene_resource.instantiate()
		if loaded_scene_instance:
			algorithm_container.add_child(loaded_scene_instance)
			
			# Position the algorithm scene slightly away from the player
			# Check if the loaded instance is a Node3D before setting position
			if loaded_scene_instance is Node3D:
				loaded_scene_instance.position = Vector3(0, 0, -5)
				print("Positioned scene at: ", loaded_scene_instance.position)
			else:
				print("Warning: Loaded scene is not a Node3D, cannot set position")
			
			print("Successfully loaded: ", scene_path)
			update_scene_info()
		else:
			print("Failed to instantiate scene: ", scene_path)
			loaded_scene_instance = null
	else:
		print("Failed to load scene resource: ", scene_path)

func unload_current_scene():
	"""Unload the currently loaded algorithm scene"""
	if loaded_scene_instance:
		if is_instance_valid(loaded_scene_instance):
			loaded_scene_instance.queue_free()
		loaded_scene_instance = null
		print("Unloaded current scene")
		update_scene_info()

func reload_current_scene():
	"""Reload the current scene"""
	if current_scene_index >= 0:
		load_scene_at_index(current_scene_index)

func update_scene_info():
	"""Update the UI to show current scene information"""
	var info_text = "Press 'N' for next scene, 'P' for previous, 'R' to reload, 'U' to unload\n"
	info_text += "WASD to move, Mouse to look around, ESC to toggle mouse\n"
	
	if current_scene_index >= 0 and current_scene_index < algorithm_scenes.size():
		var scene_name = algorithm_scenes[current_scene_index].get_file().get_basename()
		info_text += "Current: " + scene_name + " (" + str(current_scene_index + 1) + "/" + str(algorithm_scenes.size()) + ")"
	else:
		info_text += "Current: Main Scene (No algorithm loaded)"
	
	if scene_info_label:
		scene_info_label.text = info_text
	
	# Update scene title and location
	update_scene_title_and_location()

func get_current_scene_name() -> String:
	"""Get the name of the currently loaded scene"""
	if current_scene_index >= 0 and current_scene_index < algorithm_scenes.size():
		return algorithm_scenes[current_scene_index].get_file().get_basename()
	return "Main Scene"



func update_scene_title_and_location():
	"""Update the scene title and location display in the UI"""
	if current_scene_index >= 0 and current_scene_index < algorithm_scenes.size():
		var scene_path = algorithm_scenes[current_scene_index]
		var scene_name = scene_path.get_file().get_basename()
		var scene_category = get_scene_category(scene_path)
		var display_name = format_scene_name(scene_name)
		
		# Update title
		if scene_title_label:
			scene_title_label.text = display_name
		
		# Update location info
		if location_info_label:
			var location_text = "Category: " + scene_category + "\n"
			location_text += "Scene: " + str(current_scene_index + 1) + "/" + str(algorithm_scenes.size()) + "\n"
			location_text += "Path: " + scene_path.get_base_dir().get_file()
			location_info_label.text = location_text
	else:
		# Default main scene info
		if scene_title_label:
			scene_title_label.text = "Main Environment"
		if location_info_label:
			location_info_label.text = "Location: Main Scene\nCategory: Base Environment\nScene: Home"

func get_scene_category(scene_path: String) -> String:
	"""Extract the category from the scene path"""
	var path_parts = scene_path.split("/")
	if path_parts.size() >= 3:
		var category = path_parts[2] # algorithms/[category]/...
		return format_category_name(category)
	return "Unknown"

func format_category_name(category: String) -> String:
	"""Format category names to be more readable"""
	var formatted = category.replace("_", " ").replace("-", " ")
	var words = formatted.split(" ")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize() + " "
	return result.strip_edges()

func format_scene_name(scene_name: String) -> String:
	"""Format scene names to be more readable"""
	var formatted = scene_name.replace("_", " ").replace("-", " ")
	var words = formatted.split(" ")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize() + " "
	return result.strip_edges()

func update_player_position():
	"""Update the player position display"""
	if player and player_position_label:
		var pos = player.global_position
		var pos_text = "Player Position:\n"
		pos_text += "X: " + str(round(pos.x * 10) / 10) + "\n"
		pos_text += "Y: " + str(round(pos.y * 10) / 10) + "\n"  
		pos_text += "Z: " + str(round(pos.z * 10) / 10)
		
		# Add distance to algorithm scene if one is loaded
		if loaded_scene_instance and loaded_scene_instance is Node3D:
			var scene_pos = loaded_scene_instance.global_position
			var distance = pos.distance_to(scene_pos)
			pos_text += "\nDistance to Scene: " + str(round(distance * 10) / 10) + "m"
		
		player_position_label.text = pos_text

func is_3d_scene(scene_path: String) -> bool:
	"""Check if a scene is 3D by filtering out known 2D scene patterns"""
	var path_lower = scene_path.to_lower()
	
	# Filter out 2D scene patterns
	var exclusion_patterns = [
		"2d",
		"flowchart", 
		"algorithm_flowchart",
		"tartan_grid_2d",
		"paint_dripping_2d",
		"cellular_automata_2d",
		"boids_2d",
		"pollock2d",
		"pickup_cube_placer"  # Specifically excluded scene
	]
	
	for pattern in exclusion_patterns:
		if pattern in path_lower:
			return false
	
	# Additional specific exclusions
	if "2d_in_3d" in path_lower and not "turing_pattern" in path_lower:
		return false
	
	return true

func count_scenes_by_category(category: String) -> int:
	"""Count how many scenes belong to a specific category"""
	var count = 0
	var category_lower = category.to_lower()
	
	for scene_path in algorithm_scenes:
		if category_lower in scene_path.to_lower():
			count += 1
	
	return count
