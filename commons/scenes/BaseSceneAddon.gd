# base_scene_addon.gd
# Addon script for base.tscn that adds SceneManager without breaking XRToolsSceneBase
# Attach this as a child node script, not to the root

extends Node
class_name BaseSceneAddon

# SceneManager instance - available to all scenes using base.tscn
var scene_manager: SceneManager
var base_scene_root: Node

# Signals that other nodes can connect to
signal scene_manager_ready(scene_manager: SceneManager)

func _ready():
	print("BaseSceneAddon: Initializing SceneManager for base.tscn")
	
	# Get the root of base scene (the XRToolsSceneBase)
	base_scene_root = get_parent()
	
	# Defer scene manager creation to avoid timing issues
	call_deferred("_setup_scene_manager")

func _setup_scene_manager():
	"""Create and configure the SceneManager"""
	# Make sure we're still valid and in the tree
	if not is_inside_tree() or not base_scene_root:
		print("BaseSceneAddon: Not in tree or no base root, skipping setup")
		return
	
	scene_manager = SceneManager.new()
	scene_manager.name = "SceneManager"
	
	# Use call_deferred to add child safely
	base_scene_root.call_deferred("add_child", scene_manager)
	
	# Wait for the child to be added, then continue setup
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Set staging reference
	var staging = _find_vr_staging()
	if staging:
		scene_manager.set_staging_reference(staging)
		print("BaseSceneAddon: SceneManager connected to VR staging")
	
	# Auto-connect to scene systems after a brief delay
	call_deferred("_auto_connect_scene_manager")
	
	# Emit signal for other nodes
	scene_manager_ready.emit(scene_manager)
	
	print("BaseSceneAddon: SceneManager available for scene: %s" % base_scene_root.name)

func _auto_connect_scene_manager():
	"""Automatically connect SceneManager to available systems"""
	if not scene_manager:
		print("BaseSceneAddon: No SceneManager to auto-connect")
		return
	
	# Wait for scene to fully load
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for safety
	
	print("BaseSceneAddon: Auto-connecting SceneManager to scene systems")
	
	# Safely call auto-connect
	if scene_manager.has_method("auto_connect_to_scene"):
		scene_manager.auto_connect_to_scene()
	else:
		print("BaseSceneAddon: SceneManager has no auto_connect_to_scene method")
	
	print("BaseSceneAddon: SceneManager auto-connection complete")

func _find_vr_staging() -> Node:
	"""Find VR staging in the tree"""
	var potential_stagings = [
		get_node_or_null("/root/VRStaging"),
		get_node_or_null("/root/AdaVRStaging")
	]
	
	for staging in potential_stagings:
		if staging:
			return staging
	
	# Check if current scene root is staging
	var tree_root = get_tree().current_scene
	if tree_root and ("staging" in tree_root.name.to_lower() or "vr" in tree_root.name.to_lower()):
		return tree_root
	
	return null

# Public API - static-like access for other nodes in the scene
func get_scene_manager() -> SceneManager:
	"""Get the SceneManager instance"""
	return scene_manager

# Helper function for other nodes to find the SceneManager
static func find_scene_manager_in_scene(scene_root: Node = null) -> SceneManager:
	"""Find SceneManager in current scene"""
	if not scene_root:
		scene_root = Engine.get_main_loop().current_scene
	
	# Try to find BaseSceneAddon first
	var addon = scene_root.find_child("BaseSceneAddon", true, false)
	if addon and addon.has_method("get_scene_manager"):
		return addon.get_scene_manager()
	
	# Fallback: directly find SceneManager
	var scene_manager = scene_root.find_child("SceneManager", true, false)
	if scene_manager and scene_manager is SceneManager:
		return scene_manager as SceneManager
	
	return null
