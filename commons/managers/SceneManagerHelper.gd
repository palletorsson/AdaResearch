# SceneManagerHelper.gd
# Helper class for easily accessing SceneManager from any node in scenes using base.tscn
# Provides convenient methods without requiring inheritance

extends RefCounted
class_name SceneManagerHelper

# Static methods for accessing SceneManager

static func get_scene_manager(from_node: Node = null) -> SceneManager:
	"""Get SceneManager from current scene"""
	var scene_root = from_node.get_tree().current_scene if from_node else Engine.get_main_loop().current_scene
	
	# Try BaseSceneAddon first
	var addon = scene_root.find_child("BaseSceneAddon", true, false)
	if addon and addon.has_method("get_scene_manager"):
		return addon.get_scene_manager()
	
	# Fallback: direct SceneManager search
	var scene_manager = scene_root.find_child("SceneManager", true, false)
	if scene_manager and scene_manager is SceneManager:
		return scene_manager as SceneManager
	
	return null

static func wait_for_scene_manager(from_node: Node) -> SceneManager:
	"""Wait for SceneManager to be available"""
	var scene_manager = get_scene_manager(from_node)
	if scene_manager:
		return scene_manager
	
	# Wait for BaseSceneAddon signal
	var scene_root = from_node.get_tree().current_scene
	var addon = scene_root.find_child("BaseSceneAddon", true, false)
	if addon and addon.has_signal("scene_manager_ready"):
		await addon.scene_manager_ready
		return get_scene_manager(from_node)
	
	# Fallback: keep checking
	while not scene_manager:
		await from_node.get_tree().process_frame
		scene_manager = get_scene_manager(from_node)
	
	return scene_manager

# Convenience methods that any node can call

static func load_map(map_name: String, spawn_point: String = "default", from_node: Node = null):
	"""Load a specific map"""
	var scene_manager = get_scene_manager(from_node)
	if scene_manager:
		scene_manager.load_map(map_name, spawn_point)

static func start_sequence(sequence_name: String, from_node: Node = null):
	"""Start a specific sequence"""
	var scene_manager = get_scene_manager(from_node)
	if scene_manager:
		scene_manager.start_sequence(sequence_name)

static func return_to_lab(completion_data: Dictionary = {}, from_node: Node = null):
	"""Return to lab hub"""
	var scene_manager = get_scene_manager(from_node)
	if scene_manager:
		scene_manager.return_to_lab(completion_data)

static func request_transition(transition_data: Dictionary, from_node: Node = null):
	"""Request a custom transition"""
	var scene_manager = get_scene_manager(from_node)
	if scene_manager:
		scene_manager.request_transition(transition_data)

static func advance_sequence(from_node: Node = null):
	"""Advance current sequence to next map"""
	var scene_manager = get_scene_manager(from_node)
	if scene_manager:
		scene_manager.request_transition({
			"type": SceneManager.TransitionType.TELEPORTER,
			"action": "next_in_sequence"
		})

# Query methods

static func is_in_sequence(from_node: Node = null) -> bool:
	"""Check if currently in a sequence"""
	var scene_manager = get_scene_manager(from_node)
	return scene_manager.is_in_sequence() if scene_manager else false

static func get_current_sequence_data(from_node: Node = null) -> Dictionary:
	"""Get current sequence data"""
	var scene_manager = get_scene_manager(from_node)
	return scene_manager.get_current_sequence_data() if scene_manager else {}

static func get_scene_type(from_node: Node = null) -> String:
	"""Get current scene type"""
	var scene_manager = get_scene_manager(from_node)
	return scene_manager.get_current_scene_type() if scene_manager else "unknown"
