# VRMapDiscovery.gd
# Utility for discovering and listing available maps for VR grid system

extends Node
class_name VRMapDiscovery

# Map priority order (same as VRGridSystemManager)
const MAP_ORDER_PRIORITY = [
	"Tutorial_Start", "Intro_0", "Preface_0", 
	"Tutorial_Single", "Tutorial_Row", "Tutorial_Room",
	"Intro_1", "Preface_1", "Random_0", "Random_1", 
	"Random_2", "Random_3", "Random_4"
]

# Discover all available maps
static func discover_available_maps() -> Dictionary:
	"""
	Discover all available maps and return detailed information
	"""
	var result = {
		"maps": [],
		"count": 0,
		"starting_map": "",
		"priority_maps": [],
		"other_maps": []
	}
	
	var maps_dir = "res://commons/maps/"  # Updated to match actual project structure
	var dir = DirAccess.open(maps_dir)
	var found_maps: Array[String] = []
	
	if dir:
		print("VRMapDiscovery: Scanning directory: %s" % maps_dir)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				# Check if directory contains map_data.json
				var map_data_path = maps_dir + file_name + "/map_data.json"
				if ResourceLoader.exists(map_data_path):
					found_maps.append(file_name)
					print("VRMapDiscovery: Found valid map: %s" % file_name)
				else:
					print("VRMapDiscovery: Skipping '%s' - no map_data.json" % file_name)
			file_name = dir.get_next()
	else:
		print("VRMapDiscovery: ERROR - Could not open maps directory: %s" % maps_dir)
	
	found_maps.sort()
	result.maps = found_maps
	result.count = found_maps.size()
	
	# Categorize maps
	for map_name in found_maps:
		if map_name in MAP_ORDER_PRIORITY:
			result.priority_maps.append(map_name)
		else:
			result.other_maps.append(map_name)
	
	# Determine starting map
	result.starting_map = determine_starting_map_from_list(found_maps)
	
	return result

# Determine starting map from a list
static func determine_starting_map_from_list(available_maps: Array[String]) -> String:
	if available_maps.is_empty():
		return "Lab"  # Changed fallback to Lab since that's what exists
	
	# Check if Lab is available first (since it's the main hub)
	if "Lab" in available_maps:
		return "Lab"
	
	# Try priority order
	for priority_map in MAP_ORDER_PRIORITY:
		if priority_map in available_maps:
			return priority_map
	
	# Use first alphabetically
	var sorted_maps = available_maps.duplicate()
	sorted_maps.sort()
	return sorted_maps[0]

# Print discovery results
static func print_discovery_results():
	"""
	Print a formatted report of available maps
	"""
	var discovery = discover_available_maps()
	
	print("=== VR Map Discovery Results ===")
	print("Total maps found: %d" % discovery.count)
	print("Starting map: %s" % discovery.starting_map)
	print("")
	
	if discovery.priority_maps.size() > 0:
		print("Priority maps (in order):")
		for map_name in MAP_ORDER_PRIORITY:
			if map_name in discovery.priority_maps:
				var marker = "🎯" if map_name == discovery.starting_map else "  "
				print("  %s %s" % [marker, map_name])
		print("")
	
	if discovery.other_maps.size() > 0:
		print("Other available maps:")
		for map_name in discovery.other_maps:
			var marker = "🎯" if map_name == discovery.starting_map else "  "
			print("  %s %s" % [marker, map_name])
		print("")
	
	print("All maps: %s" % str(discovery.maps))
	print("================================")

# Validate a map exists
static func validate_map_exists(map_name: String) -> bool:
	var maps_dir = "res://commons/maps/" + map_name  # Updated path
	return DirAccess.dir_exists_absolute(maps_dir)

# Get map info
static func get_map_info(map_name: String) -> Dictionary:
	"""
	Get detailed information about a specific map
	"""
	var info = {
		"name": map_name,
		"exists": false,
		"has_json": false,
		"has_gd": false,
		"path": "",
		"priority_level": -1
	}
	
	var maps_dir = "res://commons/maps/" + map_name  # Updated path
	info.path = maps_dir
	info.exists = DirAccess.dir_exists_absolute(maps_dir)
	
	if info.exists:
		# Check for data files
		info.has_json = ResourceLoader.exists(maps_dir + "/map_data.json")  # Use ResourceLoader.exists
		info.has_gd = FileAccess.file_exists(maps_dir + "/struct_data.gd")
		
		# Check priority level
		var priority_index = MAP_ORDER_PRIORITY.find(map_name)
		if priority_index >= 0:
			info.priority_level = priority_index
	
	return info 