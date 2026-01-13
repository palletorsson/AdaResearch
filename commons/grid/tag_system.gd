extends Node
class_name TagSystem

## Tag-Based Event System
## Allows puzzles and other triggers to execute actions on tagged entities
## without direct coupling

## Dictionary mapping tags to arrays of nodes
## Format: { "tag_name": [node1, node2, ...] }
static var _tagged_nodes: Dictionary = {}

## Register a node with a specific tag
static func register_tagged_node(tag: String, node: Node) -> void:
	if tag == "" or tag == null:
		push_warning("TagSystem: Attempted to register node with empty tag")
		return
	
	if not is_instance_valid(node):
		push_warning("TagSystem: Attempted to register invalid node with tag '%s'" % tag)
		return
	
	if not _tagged_nodes.has(tag):
		_tagged_nodes[tag] = []
	
	_tagged_nodes[tag].append(node)
	print("TagSystem: Registered node '%s' with tag '%s'" % [node.name, tag])
	
	# Connect to node's tree_exiting signal to auto-unregister
	if not node.tree_exiting.is_connected(_on_node_freed.bind(tag, node)):
		node.tree_exiting.connect(_on_node_freed.bind(tag, node))

## Unregister a node from a specific tag
static func unregister_tagged_node(tag: String, node: Node) -> void:
	if not _tagged_nodes.has(tag):
		return
	
	var nodes_array: Array = _tagged_nodes[tag]
	var idx = nodes_array.find(node)
	if idx >= 0:
		nodes_array.remove_at(idx)
		print("TagSystem: Unregistered node '%s' from tag '%s'" % [node.name, tag])
	
	# Clean up empty tag arrays
	if nodes_array.is_empty():
		_tagged_nodes.erase(tag)

## Automatically called when a registered node is freed
static func _on_node_freed(tag: String, node: Node) -> void:
	unregister_tagged_node(tag, node)

## Trigger an action on all nodes with a specific tag
static func trigger_tag_action(tag: String, action: String) -> void:
	if not _tagged_nodes.has(tag):
		push_warning("TagSystem: Triggered action '%s' on tag '%s' but no nodes found" % [action, tag])
		return
	
	var nodes_array: Array = _tagged_nodes[tag].duplicate()  # Duplicate to avoid modification during iteration
	var success_count: int = 0
	
	print("TagSystem: Triggering action '%s' on %d nodes with tag '%s'" % [action, nodes_array.size(), tag])
	
	for node in nodes_array:
		if not is_instance_valid(node):
			continue
		
		if _execute_action(node, action):
			success_count += 1
	
	print("TagSystem: Action '%s' executed on %d/%d nodes" % [action, success_count, nodes_array.size()])

## Execute a specific action on a node
static func _execute_action(node: Node, action: String) -> bool:
	match action.to_lower():
		"remove":
			print("  - '%s': queue_free()" % node.name)
			node.queue_free()
			return true
		
		"reveal":
			if "visible" in node:
				node.visible = true
				node.show()
				# Re-enable collision shapes
				_set_collision_enabled(node, true)
				print("  - '%s': visible = true (collisions enabled)" % node.name)
				return true
			else:
				push_warning("  - '%s': No 'visible' property (action: reveal)" % node.name)
				return false
		
		"hide":
			if "visible" in node:
				node.visible = false
				node.hide()
				# Disable collision shapes to prevent invisible collisions
				_set_collision_enabled(node, false)
				print("  - '%s': visible = false (collisions disabled)" % node.name)
				return true
			else:
				push_warning("  - '%s': No 'visible' property (action: hide)" % node.name)
				return false
		
		"freeze":
			if node is RigidBody3D:
				node.freeze = true
				print("  - '%s': freeze = true" % node.name)
				return true
			else:
				push_warning("  - '%s': Not a RigidBody3D (action: freeze)" % node.name)
				return false
		
		"unfreeze":
			if node is RigidBody3D:
				node.freeze = false
				print("  - '%s': freeze = false" % node.name)
				return true
			else:
				push_warning("  - '%s': Not a RigidBody3D (action: unfreeze)" % node.name)
				return false
		
		"enable_physics":
			if node is RigidBody3D:
				node.freeze = false
				node.visible = true
				node.show()
				print("  - '%s': physics enabled (unfreeze + reveal)" % node.name)
				return true
			else:
				push_warning("  - '%s': Not a RigidBody3D (action: enable_physics)" % node.name)
				return false
		
		"disable_physics":
			if node is RigidBody3D:
				node.freeze = true
				print("  - '%s': physics disabled (freeze)" % node.name)
				return true
			else:
				push_warning("  - '%s': Not a RigidBody3D (action: disable_physics)" % node.name)
				return false
				
		"shrink_and_remove":
			print("  - '%s': scaling down and removing" % node.name)
			if "scale" in node:
				var tween = node.create_tween()
				tween.tween_property(node, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tween.tween_callback(node.queue_free)
				return true
			else:
				push_warning("  - '%s': No 'scale' property (action: shrink_and_remove)" % node.name)
				return false
		
		_:
			push_warning("  - '%s': Unknown action '%s'" % [node.name, action])
			return false

## Get all nodes with a specific tag (for debugging/querying)
static func get_nodes_with_tag(tag: String) -> Array:
	if _tagged_nodes.has(tag):
		return _tagged_nodes[tag].duplicate()
	return []

## Clear all tag registrations (useful for scene changes)
static func clear_all_tags() -> void:
	print("TagSystem: Clearing all tag registrations")
	_tagged_nodes.clear()

## Debug: Print all registered tags and their node counts
static func debug_print_tags() -> void:
	print("TagSystem: Debug - Registered tags:")
	for tag in _tagged_nodes.keys():
		var nodes = _tagged_nodes[tag]
		print("  - '%s': %d nodes" % [tag, nodes.size()])
		for node in nodes:
			if is_instance_valid(node):
				print("    - %s" % node.name)
			else:
				print("    - [INVALID]")

## Helper: Enable/disable collision shapes recursively
static func _set_collision_enabled(node: Node, enabled: bool) -> void:
	# Handle CollisionShape3D
	if node is CollisionShape3D:
		node.disabled = not enabled
	
	# Handle CollisionShape2D
	if node is CollisionShape2D:
		node.disabled = not enabled
	
	# Handle CollisionPolygon3D
	if node is CollisionPolygon3D:
		node.disabled = not enabled
	
	# Handle CollisionPolygon2D
	if node is CollisionPolygon2D:
		node.disabled = not enabled
	
	# Recurse through children
	for child in node.get_children():
		_set_collision_enabled(child, enabled)
