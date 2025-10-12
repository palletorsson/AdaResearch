extends Node
class_name SceneSlideshowManager

# Scene slideshow manager - cycles through all algorithm scenes

@export var starting_slide_index: int = 0

var scene_list: Array = []
var current_scene_index: int = 0
var scene_root: Node = null

func _ready():
	print("=== Scene Slideshow Manager ===")
	print("Indexing scenes in algorithms/...")

	# Index all scenes
	index_scenes("res://algorithms/")

	print("Found ", scene_list.size(), " scenes")
	print("")
	print("Controls:")
	print("  WASD - Move")
	print("  Mouse - Look around")
	print("  Shift - Sprint")
	print("  N - Next scene")
	print("  P - Previous scene")
	print("  ESC - Toggle mouse capture")
	print("===============================")
	print("")

	if not scene_list.is_empty():
		var start_index = clamp(starting_slide_index, 0, scene_list.size() - 1)
		current_scene_index = start_index
		load_scene_at_index(current_scene_index)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # N key for next
		next_scene()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_N:
				next_scene()
			KEY_P:
				previous_scene()

func index_scenes(path: String):
	"""Recursively find all .tscn files in a directory"""
	var dir = DirAccess.open(path)
	if dir == null:
		print("Failed to open directory: ", path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = path + "/" + file_name

		if dir.current_is_dir():
			# Skip hidden directories
			if not file_name.begins_with("."):
				index_scenes(full_path)
		else:
			# Add .tscn files
			if file_name.ends_with(".tscn"):
				scene_list.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort scenes alphabetically
	scene_list.sort()

func next_scene():
	"""Load the next scene in the list"""
	if scene_list.is_empty():
		print("No scenes to load")
		return

	current_scene_index = (current_scene_index + 1) % scene_list.size()
	load_scene_at_index(current_scene_index)

func previous_scene():
	"""Load the previous scene in the list"""
	if scene_list.is_empty():
		print("No scenes to load")
		return

	current_scene_index = (current_scene_index - 1) % scene_list.size()
	if current_scene_index < 0:
		current_scene_index = scene_list.size() - 1
	load_scene_at_index(current_scene_index)

func load_scene_at_index(index: int):
	"""Load a specific scene by index"""
	if index < 0 or index >= scene_list.size():
		return

	var scene_path = scene_list[index]

	print("\n=== Loading Scene ", index + 1, "/", scene_list.size(), " ===")
	print("Path: ", scene_path)

	# Remove old scene
	if scene_root != null and is_instance_valid(scene_root):
		scene_root.queue_free()
		scene_root = null

	# Load new scene
	if not ResourceLoader.exists(scene_path):
		print("ERROR: Scene does not exist: ", scene_path)
		return

	var packed_scene = load(scene_path)
	if packed_scene == null:
		print("ERROR: Failed to load scene: ", scene_path)
		return

	scene_root = packed_scene.instantiate()
	if scene_root == null:
		print("ERROR: Failed to instantiate scene")
		return

	# Add scene to tree
	get_tree().root.add_child(scene_root)

	print("✓ Scene loaded successfully")
	print("================================")
