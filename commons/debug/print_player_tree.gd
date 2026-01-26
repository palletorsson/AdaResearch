# print_player_tree.gd - Debug tool to find invisible colliders on the player
# Add this to any scene and call print_player_scene_tree() from console or _ready()

extends Node
class_name PlayerTreeDebugger

var _timer: float = 0.0
var _print_interval: float = 10.0  # Print every 10 seconds
var _enabled: bool = true  # Set to false to disable auto-printing

func _ready():
	print("PlayerTreeDebugger: Autoload ready - will print every %.0f seconds" % _print_interval)

func _process(delta: float) -> void:
	if not _enabled:
		return

	_timer += delta
	if _timer >= _print_interval:
		_timer = 0.0
		print_player_scene_tree()
		find_forward_colliders()
		find_all_physics_bodies()
		find_map_manuals()

## Print the full scene tree under XROrigin3D, highlighting collision shapes
static func print_player_scene_tree() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		print("ERROR: No scene tree!")
		return

	var root = tree.current_scene
	if not root:
		print("ERROR: No current scene!")
		return

	# Find XROrigin3D
	var xr_origin = root.find_child("XROrigin3D", true, false)
	if not xr_origin:
		print("ERROR: Could not find XROrigin3D!")
		return

	print("\n============================================================")
	print("PLAYER SCENE TREE DEBUG - XROrigin3D and children")
	print("============================================================")

	_print_node_recursive(xr_origin, 0)

	print("============================================================\n")

static func _get_indent(depth: int) -> String:
	var result = ""
	for i in range(depth):
		result += "  "
	return result

static func _print_node_recursive(node: Node, depth: int) -> void:
	var indent = _get_indent(depth)
	var node_info = "%s[%s] %s" % [indent, node.get_class(), node.name]

	# Highlight collision shapes and areas
	if node is CollisionShape3D:
		var shape = node.shape
		var shape_type = shape.get_class() if shape else "NO SHAPE"
		var shape_size = ""
		if shape is BoxShape3D:
			shape_size = " size=%s" % str(shape.size)
		elif shape is SphereShape3D:
			shape_size = " radius=%.2f" % shape.radius
		elif shape is CapsuleShape3D:
			shape_size = " radius=%.2f height=%.2f" % [shape.radius, shape.height]
		var disabled_str = " [DISABLED]" if node.disabled else " [ENABLED!]"
		node_info += " <<< COLLISION: %s%s%s" % [shape_type, shape_size, disabled_str]

		# Print global position
		if node is Node3D:
			node_info += " @ global_pos=%s" % str(node.global_position)

	elif node is Area3D:
		node_info += " <<< AREA3D (monitoring=%s, monitorable=%s)" % [str(node.monitoring), str(node.monitorable)]

	elif node is RigidBody3D or node is CharacterBody3D or node is StaticBody3D:
		node_info += " <<< PHYSICS BODY"

	# Check visibility
	if node is Node3D and not node.visible:
		node_info += " [INVISIBLE]"

	print(node_info)

	# Recurse into children
	for child in node.get_children():
		_print_node_recursive(child, depth + 1)

## Find all collision shapes in front of the camera (forward direction)
static func find_forward_colliders() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return

	var root = tree.current_scene
	if not root:
		return

	var camera = root.find_child("XRCamera3D", true, false) as Camera3D
	if not camera:
		print("No XRCamera3D found!")
		return

	var xr_origin = root.find_child("XROrigin3D", true, false)
	if not xr_origin:
		return

	print("\n============================================================")
	print("COLLIDERS IN FRONT OF CAMERA")
	print("Camera position: %s" % str(camera.global_position))
	print("Camera forward: %s" % str(-camera.global_transform.basis.z))
	print("============================================================")

	var camera_pos = camera.global_position
	var camera_forward = -camera.global_transform.basis.z

	_find_colliders_recursive(xr_origin, camera_pos, camera_forward)

	print("============================================================\n")

static func _find_colliders_recursive(node: Node, camera_pos: Vector3, camera_forward: Vector3) -> void:
	if node is CollisionShape3D:
		var collision_pos = node.global_position
		var to_collision = (collision_pos - camera_pos).normalized()
		var dot = camera_forward.dot(to_collision)
		var distance = camera_pos.distance_to(collision_pos)

		# If dot > 0.5, it's roughly in front (within ~60 degree cone)
		if dot > 0.3 and distance < 2.0:  # Within 2 meters in front
			var shape = node.shape
			var shape_type = shape.get_class() if shape else "NO SHAPE"
			print("FOUND IN FRONT: %s" % str(node.get_path()))
			print("  Shape: %s" % shape_type)
			print("  Distance: %.2f m" % distance)
			print("  Dot product: %.2f" % dot)
			print("  Global position: %s" % str(collision_pos))
			if shape is BoxShape3D:
				print("  Box size: %s" % str(shape.size))
			elif shape is SphereShape3D:
				print("  Sphere radius: %.2f" % shape.radius)

	for child in node.get_children():
		_find_colliders_recursive(child, camera_pos, camera_forward)

## Find ALL physics bodies and areas in the entire scene (not just player)
static func find_all_physics_bodies() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return

	var root = tree.current_scene
	if not root:
		return

	print("\n============================================================")
	print("ALL PHYSICS BODIES IN SCENE (CharacterBody3D, RigidBody3D, StaticBody3D with collision)")
	print("============================================================")

	_find_physics_bodies_recursive(root)

	print("============================================================\n")

## Find ALL StaticBody3D nodes specifically (often the culprits for invisible pushers)
static func find_all_static_bodies() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return

	var root = tree.current_scene
	if not root:
		return

	print("\n============================================================")
	print("ALL STATICBODY3D IN SCENE")
	print("============================================================")

	_find_static_bodies_recursive(root)

	print("============================================================\n")

static func _find_static_bodies_recursive(node: Node) -> void:
	if node is StaticBody3D:
		var sb = node as StaticBody3D
		print("STATICBODY: %s" % str(node.get_path()))
		print("  Position: %s" % str(sb.global_position))
		print("  Collision layer: %d, mask: %d" % [sb.collision_layer, sb.collision_mask])
		_print_collision_children(node, 1)

	for child in node.get_children():
		_find_static_bodies_recursive(child)

static func _find_physics_bodies_recursive(node: Node) -> void:
	# Skip GridSystem and its children (too many floor collisions)
	if node.name == "GridSystem" or node.name == "GridCollisions":
		return

	# Look for physics bodies that could push things
	if node is CharacterBody3D:
		print("CHARACTERBODY: %s" % str(node.get_path()))
		if node is Node3D:
			print("  Position: %s" % str(node.global_position))
		_print_collision_children(node, 1)

	elif node is RigidBody3D:
		var rb = node as RigidBody3D
		if not rb.freeze:  # Only active rigid bodies
			print("RIGIDBODY (active): %s" % str(node.get_path()))
			if node is Node3D:
				print("  Position: %s" % str(node.global_position))
			_print_collision_children(node, 1)

	elif node is AnimatableBody3D:
		print("ANIMATABLEBODY: %s" % str(node.get_path()))
		if node is Node3D:
			print("  Position: %s" % str(node.global_position))
		_print_collision_children(node, 1)

	elif node is StaticBody3D:
		# Check if it has enabled collision shapes with significant size
		var has_enabled_collision = false
		for child in node.get_children():
			if child is CollisionShape3D and not child.disabled:
				has_enabled_collision = true
				break
		if has_enabled_collision:
			var sb = node as StaticBody3D
			print("STATICBODY: %s" % str(node.get_path()))
			print("  Position: %s, Layer: %d, Mask: %d" % [str(sb.global_position), sb.collision_layer, sb.collision_mask])
			_print_collision_children(node, 1)

	# Also check for Area3D with monitoring that could be interacting
	elif node is Area3D:
		var area = node as Area3D
		if area.monitoring and area.monitorable:
			# Skip if it's a small suppress area
			var dominated_by_parent = node.get_parent() != null and "Pointer" in node.get_parent().name
			if not dominated_by_parent:
				print("AREA3D (monitoring+monitorable): %s" % str(node.get_path()))
				_print_collision_children(node, 1)

	for child in node.get_children():
		_find_physics_bodies_recursive(child)

static func _print_collision_children(node: Node, depth: int) -> void:
	var indent = _get_indent(depth)
	for child in node.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			var shape_info = ""
			if shape is BoxShape3D:
				shape_info = "Box size=%s" % str(shape.size)
			elif shape is SphereShape3D:
				shape_info = "Sphere radius=%.2f" % shape.radius
			elif shape is CapsuleShape3D:
				shape_info = "Capsule radius=%.2f height=%.2f" % [shape.radius, shape.height]
			elif shape is CylinderShape3D:
				shape_info = "Cylinder radius=%.2f height=%.2f" % [shape.radius, shape.height]
			elif shape:
				shape_info = shape.get_class()
			var disabled_str = " [DISABLED]" if child.disabled else ""
			print("%sCollision: %s @ %s (path: %s)%s" % [indent, shape_info, str(child.global_position), str(child.get_path()), disabled_str])

## Find all MapManual nodes and check their viewport visibility
static func find_map_manuals() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return

	print("\n============================================================")
	print("MAP MANUAL DEBUG - Checking viewport visibility and collision state")
	print("============================================================")

	_find_map_manual_recursive(tree.root)

	print("============================================================\n")

static func _find_map_manual_recursive(node: Node) -> void:
	if node.name == "MapManual":
		print("MAPMANUAL FOUND: %s" % str(node.get_path()))
		print("  Visible: %s" % str(node.visible if node is Node3D else "N/A"))
		print("  Global position: %s" % str(node.global_position if node is Node3D else "N/A"))

		# Check for Viewport2Din3D child
		var viewport_2d = node.get_node_or_null("Viewport2Din3D")
		if viewport_2d:
			print("  Viewport2Din3D visible: %s" % str(viewport_2d.visible))
			print("  Viewport2Din3D scale: %s" % str(viewport_2d.scale if viewport_2d is Node3D else "N/A"))

			# Check StaticBody3D collision
			var static_body = viewport_2d.get_node_or_null("StaticBody3D")
			if static_body:
				print("  StaticBody3D found at: %s" % str(static_body.get_path()))
				print("  StaticBody3D position: %s" % str(static_body.global_position))
				var collision = static_body.get_node_or_null("CollisionShape3D")
				if collision:
					print("  CollisionShape3D disabled: %s" % str(collision.disabled))
					if collision.shape is BoxShape3D:
						print("  CollisionShape3D size: %s" % str(collision.shape.size))
		else:
			print("  WARNING: No Viewport2Din3D child found!")

	for child in node.get_children():
		_find_map_manual_recursive(child)
