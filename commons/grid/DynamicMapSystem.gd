# DynamicMapSystem.gd
# Dynamic map scene generation system
# Generates VR map scenes on-the-fly from data instead of using static .tscn files

extends Node
class_name DynamicMapSystem

# Path constants
const BASE_SCENE_PATH = "res://commons/scenes/base.tscn"
const GRID_SYSTEM_PATH = "res://commons/grid/GridSystemEnhanced.tscn"
const LEGACY_GRID_PATH = "res://commons/grid/multi_layer_grid.tscn"

# Cache for generated scenes
static var scene_cache: Dictionary = {}
static var generated_scenes: Dictionary = {}

# Hand pose presets for different map types
const HAND_POSES = {
	"default": {
		"left_hand_bones": {},
		"right_hand_bones": {}
	},
	"intro": {
		"left_hand_bones": {
			1: Quaternion(0.323537, -2.56581e-05, -0.0272204, 0.945824),
			2: Quaternion(-0.0904441, -0.0415175, -0.166293, 0.981042),
			3: Quaternion(-0.0466199, 0.020971, 0.0103276, 0.998639)
		},
		"right_hand_bones": {
			1: Quaternion(0.323537, 2.56581e-05, 0.0272204, 0.945824),
			2: Quaternion(-0.0904441, 0.0415175, 0.166293, 0.981042),
			3: Quaternion(-0.0466199, -0.020971, -0.0103276, 0.998639)
		}
	},
	"tutorial": {
		"left_hand_bones": {},
		"right_hand_bones": {}
	}
}

# Generate a map scene dynamically
static func generate_map_scene(map_name: String, options: Dictionary = {}) -> PackedScene:
	print("DynamicMapSystem: Generating scene for map '%s'" % map_name)
	
	# Check cache first
	var cache_key = "%s_%s" % [map_name, str(options.hash())]
	if scene_cache.has(cache_key):
		print("DynamicMapSystem: Using cached scene for '%s'" % map_name)
		return scene_cache[cache_key]
	
	# Load base scene
	var base_scene = load(BASE_SCENE_PATH) as PackedScene
	if not base_scene:
		push_error("DynamicMapSystem: Could not load base scene")
		return null
	
	# Instantiate base scene
	var scene_instance = base_scene.instantiate()
	scene_instance.name = map_name.capitalize()
	
	# Configure the grid system
	var grid_system = _setup_grid_system(scene_instance, map_name, options)
	if not grid_system:
		scene_instance.queue_free()
		return null
	
	# Apply hand poses
	_apply_hand_poses(scene_instance, map_name, options)
	
	# Apply map-specific environment settings
	_apply_environment_settings(scene_instance, map_name, options)
	
	# Create packed scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(scene_instance)
	
	if result != OK:
		push_error("DynamicMapSystem: Failed to pack scene for map '%s'" % map_name)
		scene_instance.queue_free()
		return null
	
	# Cache the scene
	scene_cache[cache_key] = packed_scene
	generated_scenes[map_name] = packed_scene
	
	# Clean up the instance
	scene_instance.queue_free()
	
	print("DynamicMapSystem: Successfully generated scene for map '%s'" % map_name)
	return packed_scene

# Setup the grid system for the map
static func _setup_grid_system(scene_instance: Node, map_name: String, options: Dictionary) -> Node:
	# Remove existing grid system if present
	var existing_grid = scene_instance.find_child("multiLayerGrid")
	if existing_grid:
		existing_grid.queue_free()
	
	# Determine which grid system to use
	var use_enhanced = options.get("use_enhanced_grid", true)
	var prefer_json = options.get("prefer_json_format", true)
	
	var grid_scene_path = GRID_SYSTEM_PATH if use_enhanced else LEGACY_GRID_PATH
	var grid_scene = load(grid_scene_path) as PackedScene
	
	if not grid_scene:
		push_error("DynamicMapSystem: Could not load grid system scene")
		return null
	
	# Instantiate grid system
	var grid_system = grid_scene.instantiate()
	
	if use_enhanced:
		# Configure enhanced grid system
		grid_system.name = "GridSystemEnhanced"
		grid_system.map_name = map_name
		grid_system.prefer_json_format = prefer_json
		
		# Apply custom settings from options
		if options.has("cube_size"):
			grid_system.cube_size = options.cube_size
		if options.has("gutter"):
			grid_system.gutter = options.gutter
		if options.has("show_grid"):
			grid_system.showgrid = options.show_grid
	else:
		# Configure legacy grid system
		grid_system.name = "multiLayerGrid"
		grid_system.map_name = map_name
		
		# Apply settings for legacy system
		if options.has("cube_size"):
			grid_system.cube_size = options.cube_size
		if options.has("gutter"):
			grid_system.gutter = options.gutter
	
	# Apply transform to match base scene
	grid_system.transform = Transform3D(
		Vector3(-1, 0, -8.74228e-08),
		Vector3(0, 1, 0), 
		Vector3(8.74228e-08, 0, -1),
		Vector3(0, 1, 0)
	)
	
	# Add to scene
	scene_instance.add_child(grid_system)
	grid_system.owner = scene_instance
	
	return grid_system

# Apply hand poses based on map type
static func _apply_hand_poses(scene_instance: Node, map_name: String, options: Dictionary) -> void:
	var pose_type = options.get("hand_pose", _determine_pose_type(map_name))
	
	if not HAND_POSES.has(pose_type) or pose_type == "default":
		return  # No custom poses to apply
	
	var pose_data = HAND_POSES[pose_type]
	
	# Apply left hand pose
	var left_skeleton = scene_instance.get_node_or_null("XROrigin3D/LeftHand/XRToolsCollisionHand/LeftHand/Hand_Nails_low_L/Armature/Skeleton3D")
	if left_skeleton and pose_data.has("left_hand_bones"):
		_apply_bone_rotations(left_skeleton, pose_data.left_hand_bones)
	
	# Apply right hand pose
	var right_skeleton = scene_instance.get_node_or_null("XROrigin3D/RightHand/XRToolsCollisionHand/RightHand/Hand_Nails_R/Armature/Skeleton3D")
	if right_skeleton and pose_data.has("right_hand_bones"):
		_apply_bone_rotations(right_skeleton, pose_data.right_hand_bones)

# Apply bone rotations to skeleton
static func _apply_bone_rotations(skeleton: Skeleton3D, bone_rotations: Dictionary) -> void:
	for bone_index in bone_rotations.keys():
		var rotation = bone_rotations[bone_index]
		if bone_index < skeleton.get_bone_count():
			skeleton.set_bone_pose_rotation(bone_index, rotation)

# Determine pose type from map name
static func _determine_pose_type(map_name: String) -> String:
	var lower_name = map_name.to_lower()
	
	if lower_name.begins_with("intro"):
		return "intro"
	elif lower_name.begins_with("tutorial") or lower_name.begins_with("preface"):
		return "tutorial"
	else:
		return "default"

# Apply environment settings based on map data
static func _apply_environment_settings(scene_instance: Node, map_name: String, options: Dictionary) -> void:
	# Check if we have JSON map data with lighting settings
	var json_path = "res://adaresearch/Common/Data/Maps/" + map_name + "/map_data.json"
	
	if JsonMapLoader.is_json_map_file(json_path):
		var loader = JsonMapLoader.load_json_map(json_path)
		if loader:
			var lighting = loader.get_lighting_settings()
			var settings = loader.get_settings()
			
			_apply_lighting_from_json(scene_instance, lighting)
			_apply_background_from_json(scene_instance, settings.get("background", {}))
	
	# Apply custom environment from options
	if options.has("environment"):
		_apply_custom_environment(scene_instance, options.environment)

# Apply lighting settings from JSON
static func _apply_lighting_from_json(scene_instance: Node, lighting: Dictionary) -> void:
	if lighting.is_empty():
		return
	
	var world_env = scene_instance.get_node_or_null("WorldEnvironment")
	var directional_light = scene_instance.get_node_or_null("DirectionalLight3D")
	
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Apply ambient lighting
		if lighting.has("ambient_color"):
			var color = lighting.ambient_color
			env.ambient_light_color = Color(color[0], color[1], color[2])
		
		if lighting.has("ambient_energy"):
			env.ambient_light_energy = lighting.ambient_energy
	
	# Apply directional light settings
	if directional_light and lighting.has("directional_light"):
		var dir_light_data = lighting.directional_light
		
		if dir_light_data.get("enabled", true):
			directional_light.visible = true
			
			if dir_light_data.has("direction"):
				var dir = dir_light_data.direction
				directional_light.look_at(Vector3(dir[0], dir[1], dir[2]))
			
			if dir_light_data.has("color"):
				var color = dir_light_data.color
				directional_light.light_color = Color(color[0], color[1], color[2])
			
			if dir_light_data.has("energy"):
				directional_light.light_energy = dir_light_data.energy
		else:
			directional_light.visible = false

# Apply background settings from JSON
static func _apply_background_from_json(scene_instance: Node, background: Dictionary) -> void:
	if background.is_empty():
		return
	
	var world_env = scene_instance.get_node_or_null("WorldEnvironment")
	if not world_env or not world_env.environment:
		return
	
	var env = world_env.environment
	
	match background.get("type", "sky"):
		"sky":
			env.background_mode = Environment.BG_SKY
			if background.has("color"):
				var color = background.color
				# Apply sky color if we have a procedural sky material
		"color":
			env.background_mode = Environment.BG_COLOR
			if background.has("color"):
				var color = background.color
				env.bg_color = Color(color[0], color[1], color[2])

# Apply custom environment settings
static func _apply_custom_environment(scene_instance: Node, env_options: Dictionary) -> void:
	var world_env = scene_instance.get_node_or_null("WorldEnvironment")
	if not world_env or not world_env.environment:
		return
	
	var env = world_env.environment
	
	# Apply any custom environment modifications
	for key in env_options.keys():
		var value = env_options[key]
		if env.has_property(key):
			env.set(key, value)



# Check if map has spawn point data
static func _has_spawn_point_data(map_name: String) -> bool:
	var json_path = "res://adaresearch/Common/Data/Maps/" + map_name + "/map_data.json"
	
	if JsonMapLoader.is_json_map_file(json_path):
		var loader = JsonMapLoader.load_json_map(json_path)
		if loader:
			var settings = loader.get_settings()
			return settings.has("spawn_points") and settings.spawn_points.size() > 0
	
	return false

# Get spawn point from map data
static func _get_spawn_point(map_name: String) -> Vector3:
	var json_path = "res://adaresearch/Common/Data/Maps/" + map_name + "/map_data.json"
	
	if JsonMapLoader.is_json_map_file(json_path):
		var loader = JsonMapLoader.load_json_map(json_path)
		if loader:
			var settings = loader.get_settings()
			if settings.has("spawn_points") and settings.spawn_points.size() > 0:
				var spawn_point = settings.spawn_points[0]
				if spawn_point.has("position"):
					var pos = spawn_point.position
					return Vector3(pos[0], pos[1], pos[2])
	
	# Default position
	return Vector3(0, 5, 8)

# Load a map scene with optional camera test mode
static func load_map_scene(map_name: String, options: Dictionary = {}) -> PackedScene:
	var force_dynamic = options.get("force_dynamic", false)
	var fallback_to_static = options.get("fallback_to_static", true)
	var camera_test_mode = options.get("camera_test_mode", false)
	
	
	if force_dynamic:
		return generate_map_scene(map_name, options)
	
	# Try to load existing static scene first
	var static_scene_path = "res://adaresearch/Common/Scenes/Maps/" + map_name + ".tscn"
	if not force_dynamic and ResourceLoader.exists(static_scene_path):
		print("DynamicMapSystem: Loading static scene for '%s'" % map_name)
		return load(static_scene_path) as PackedScene
	
	# Generate dynamically
	var generated_scene = generate_map_scene(map_name, options)
	
	if not generated_scene and fallback_to_static:
		# Try to load static scene as fallback
		if ResourceLoader.exists(static_scene_path):
			print("DynamicMapSystem: Falling back to static scene for '%s'" % map_name)
			return load(static_scene_path) as PackedScene
	
	return generated_scene

# Save a generated scene to disk (for debugging/caching)
static func save_generated_scene(map_name: String, save_path: String = "") -> bool:
	if not generated_scenes.has(map_name):
		push_error("DynamicMapSystem: No generated scene found for '%s'" % map_name)
		return false
	
	if save_path.is_empty():
		save_path = "res://adaresearch/Common/Scenes/Maps/Generated/" + map_name + "_generated.tscn"
	
	var scene = generated_scenes[map_name]
	var result = ResourceSaver.save(scene, save_path)
	
	if result == OK:
		print("DynamicMapSystem: Saved generated scene to '%s'" % save_path)
		return true
	else:
		push_error("DynamicMapSystem: Failed to save generated scene to '%s'" % save_path)
		return false

# Clear cache
static func clear_cache() -> void:
	scene_cache.clear()
	generated_scenes.clear()
	print("DynamicMapSystem: Cache cleared")

# Get cache info
static func get_cache_info() -> Dictionary:
	return {
		"cached_scenes": scene_cache.size(),
		"generated_scenes": generated_scenes.size(),
		"cache_keys": scene_cache.keys()
	}

# Preload common maps
static func preload_common_maps(map_names: Array = ["intro_0", "start", "menu"]) -> void:
	print("DynamicMapSystem: Preloading common maps...")
	
	for map_name in map_names:
		generate_map_scene(map_name)
	
	print("DynamicMapSystem: Preloaded %d maps" % map_names.size())

# Export hand poses from existing scene (utility function)
static func extract_hand_poses_from_scene(scene_path: String) -> Dictionary:
	var scene = load(scene_path) as PackedScene
	if not scene:
		return {}
	
	var instance = scene.instantiate()
	var poses = {
		"left_hand_bones": {},
		"right_hand_bones": {}
	}
	
	# Extract left hand bones
	var left_skeleton = instance.get_node_or_null("XROrigin3D/LeftHand/XRToolsCollisionHand/LeftHand/Hand_Nails_low_L/Armature/Skeleton3D")
	if left_skeleton:
		for i in range(left_skeleton.get_bone_count()):
			var rotation = left_skeleton.get_bone_pose_rotation(i)
			if rotation != Quaternion.IDENTITY:
				poses.left_hand_bones[i] = rotation
	
	# Extract right hand bones
	var right_skeleton = instance.get_node_or_null("XROrigin3D/RightHand/XRToolsCollisionHand/RightHand/Hand_Nails_R/Armature/Skeleton3D")
	if right_skeleton:
		for i in range(right_skeleton.get_bone_count()):
			var rotation = right_skeleton.get_bone_pose_rotation(i)
			if rotation != Quaternion.IDENTITY:
				poses.right_hand_bones[i] = rotation
	
	instance.queue_free()
	return poses



# Get list of all testable maps
static func get_testable_maps() -> Array[String]:
	"""Get list of all maps that can be tested"""
	var maps: Array[String] = []
	
	# Check data directory for maps with data files
	var maps_dir = "res://adaresearch/Common/Data/Maps/"
	var dir = DirAccess.open(maps_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var json_file = maps_dir + file_name + "/map_data.json"
				var gd_file = maps_dir + file_name + "/struct_data.gd"
				
				if ResourceLoader.exists(json_file) or ResourceLoader.exists(gd_file):
					maps.append(file_name)
			
			file_name = dir.get_next()
	
	# Check for static .tscn files
	var scenes_dir = "res://adaresearch/Common/Scenes/Maps/"
	dir = DirAccess.open(scenes_dir)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn") and not file_name.begins_with("base"):
				var map_name = file_name.get_basename()
				if not maps.has(map_name):
					maps.append(map_name)
			
			file_name = dir.get_next()
	
	maps.sort()
	return maps

# Validate that a map can be tested
static func validate_map_for_testing(map_name: String) -> Dictionary:
	"""Check if a map can be successfully tested"""
	var result = {
		"valid": false,
		"errors": [],
		"warnings": [],
		"format": "Unknown",
		"has_data": false
	}
	
	# Check for data files
	var json_path = "res://adaresearch/Common/Data/Maps/" + map_name + "/map_data.json"
	var gd_path = "res://adaresearch/Common/Data/Maps/" + map_name + "/struct_data.gd"
	var tscn_path = "res://adaresearch/Common/Scenes/Maps/" + map_name + ".tscn"
	
	if ResourceLoader.exists(json_path):
		result.format = "JSON"
		result.has_data = true
		
		# Validate JSON if possible
		if JsonMapLoader.is_json_map_file(json_path):
			var loader = JsonMapLoader.load_json_map(json_path)
			if loader:
				var validation = loader.validate()
				result.valid = validation.valid
				result.errors = validation.errors
				result.warnings = validation.get("warnings", [])
			else:
				result.errors.append("Failed to load JSON map data")
		else:
			result.errors.append("Invalid JSON map file")
	
	elif ResourceLoader.exists(gd_path):
		result.format = "GDScript"
		result.has_data = true
		result.valid = true  # Assume valid for GDScript files
	
	elif ResourceLoader.exists(tscn_path):
		result.format = "Static"
		result.has_data = true
		result.valid = true  # Assume valid for static scenes
	
	else:
		result.errors.append("No map data found")
	
	return result 
