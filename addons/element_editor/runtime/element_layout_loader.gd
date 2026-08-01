extends Node3D
class_name ElementLayoutLoader
## Runtime loader for ElementLayout resources.
## Use this in your game to load and instantiate element layouts.

## The layout resource to load
@export var layout: ElementLayout:
	set(value):
		layout = value
		if is_inside_tree():
			_reload_layout()

## Auto-load on ready
@export var auto_load: bool = true

## Subset data cache
var _subset_data: ElementSubsetData
var _element_nodes: Array[Node3D] = []
const PICKABLE_SCENE_PATH := "res://addons/godot-xr-tools/objects/pickable.tscn"


func _ready():
	_subset_data = ElementSubsetData.new()
	_subset_data.load_all()
	
	if auto_load and layout:
		_reload_layout()


func _reload_layout():
	"""Clear and reload the layout."""
	clear()
	
	if not layout:
		return
	
	for placement in layout.placements:
		var node = _instantiate_element(placement)
		if node:
			_element_nodes.append(node)


func clear():
	"""Remove all instantiated elements."""
	for node in _element_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_element_nodes.clear()


func _instantiate_element(placement: Dictionary) -> Node3D:
	"""Instantiate a single element from a placement."""
	var element_id = placement.get("id", "")
	var grid_pos: Vector3i = placement.get("grid_pos", Vector3i.ZERO)
	var rotation: int = placement.get("rotation", 0)
	
	var element = _subset_data.get_element(layout.subset_id, element_id)
	if element.is_empty():
		push_warning("[ElementLayoutLoader] Unknown element: ", element_id)
		return null
	
	var node: Node3D = null
	var scene_path = element.get("scene", "")
	var segment_type = element.get("segment_type", "")
	
	# Check for procedural glass rack elements
	if not segment_type.is_empty() and layout.subset_id == "glass_rack":
		node = _create_glass_element(element, segment_type)
	elif not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			node = scene.instantiate()
	
	if node == null:
		# Fallback placeholder
		node = _create_placeholder(element)

	node = _wrap_with_pickable_if_requested(node, element)
	
	# Position (centered for element size)
	var elem_size = element.get("size", [1, 1])
	var effective_rotation = _get_effective_grid_rotation(element, rotation)
	node.position = layout.grid_to_world(grid_pos, elem_size, effective_rotation)
	_apply_element_base_rotation(node, element)
	
	# Rotation
	if rotation != 0:
		var plane = layout.orientation_plane
		match plane:
			"XY":
				node.rotate_z(deg_to_rad(rotation * 90))
			"YZ":
				node.rotate_x(deg_to_rad(rotation * 90))
			"XZ":
				node.rotate_y(deg_to_rad(rotation * 90))
	
	# Scale
	var scene_scale = element.get("scene_scale", null)
	if scene_scale is Array and scene_scale.size() == 3:
		node.scale = Vector3(scene_scale[0], scene_scale[1], scene_scale[2])
	
	add_child(node)
	return node


func _normalize_rotation(rotation: int) -> int:
	var normalized = rotation % 4
	if normalized < 0:
		normalized += 4
	return normalized


func _get_plane_aligned_base_rotation_steps(element: Dictionary) -> int:
	var base_degrees := 0.0
	match layout.orientation_plane:
		"XY":
			base_degrees = float(element.get("rotation_z", 0.0))
		"YZ":
			base_degrees = float(element.get("rotation_x", 0.0))
		"XZ":
			base_degrees = float(element.get("rotation_y", 0.0))
	return _normalize_rotation(int(round(base_degrees / 90.0)))


func _get_effective_grid_rotation(element: Dictionary, placement_rotation: int) -> int:
	return _normalize_rotation(placement_rotation + _get_plane_aligned_base_rotation_steps(element))


func _get_element_base_rotation_degrees(element: Dictionary) -> Vector3:
	return Vector3(
		float(element.get("rotation_x", 0.0)),
		float(element.get("rotation_y", 0.0)),
		float(element.get("rotation_z", 0.0))
	)


func _apply_element_base_rotation(node: Node3D, element: Dictionary) -> void:
	var base_deg = _get_element_base_rotation_degrees(element)
	if not is_zero_approx(base_deg.x):
		node.rotate_x(deg_to_rad(base_deg.x))
	if not is_zero_approx(base_deg.y):
		node.rotate_y(deg_to_rad(base_deg.y))
	if not is_zero_approx(base_deg.z):
		node.rotate_z(deg_to_rad(base_deg.z))


func _create_glass_element(element: Dictionary, segment_type: String) -> Node3D:
	"""Create a procedural glass rack element."""
	var elem_size = element.get("size", [1, 1])
	var width = elem_size[0] * layout.grid_size
	var height = elem_size[1] * layout.grid_size
	var subset = _subset_data.get_subset(layout.subset_id)
	var tube_radius = subset.get("defaults", {}).get("tube_radius", 0.015)
	var rotation_deg = element.get("rotation", 0)
	
	return GlassMeshGenerator.create_segment(segment_type, width, height, tube_radius, null, rotation_deg)


func _create_placeholder(element: Dictionary) -> Node3D:
	"""Create a placeholder for missing scenes."""
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	var grid_size = layout.grid_size
	var size = element.get("size", [1, 1])
	
	match layout.orientation_plane:
		"XY":
			box.size = Vector3(size[0] * grid_size * 0.9, size[1] * grid_size * 0.9, 0.05)
		"YZ":
			box.size = Vector3(0.05, size[1] * grid_size * 0.9, size[0] * grid_size * 0.9)
		"XZ":
			box.size = Vector3(size[0] * grid_size * 0.9, 0.05, size[1] * grid_size * 0.9)
	
	mesh_instance.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 1, 0.5)  # Magenta = missing
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	
	return mesh_instance


func _wrap_with_pickable_if_requested(node: Node3D, element: Dictionary) -> Node3D:
	if not bool(element.get("make_pickable", false)):
		return node
	if _is_xr_pickable(node):
		return node
	if not ResourceLoader.exists(PICKABLE_SCENE_PATH):
		push_warning("[ElementLayoutLoader] Pickable scene missing: %s" % PICKABLE_SCENE_PATH)
		return node

	var pickable_scene: PackedScene = load(PICKABLE_SCENE_PATH)
	if not pickable_scene:
		return node

	var pickable_instance = pickable_scene.instantiate()
	if not (pickable_instance is Node3D):
		return node

	var pickable := pickable_instance as Node3D
	pickable.name = "%sPickable" % node.name
	pickable.add_child(node)

	if pickable is RigidBody3D:
		(pickable as RigidBody3D).freeze = true

	_ensure_pickable_collision(pickable, node)
	return pickable


func _is_xr_pickable(node: Node) -> bool:
	if node and node.has_method("is_xr_class"):
		return bool(node.call("is_xr_class", "XRToolsPickable"))
	return node is RigidBody3D and node.has_signal("picked_up") and node.has_signal("dropped")


func _ensure_pickable_collision(pickable: Node3D, mesh_owner: Node3D) -> void:
	var collision := pickable.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		pickable.add_child(collision)

	if collision.shape != null:
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(mesh_owner, meshes)

	var has_bounds := false
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO

	for mesh_instance in meshes:
		var mesh_aabb = mesh_instance.get_aabb()
		for corner in _get_aabb_corners(mesh_aabb):
			var point = pickable.to_local(mesh_instance.to_global(corner))
			if not has_bounds:
				min_v = point
				max_v = point
				has_bounds = true
			else:
				min_v.x = min(min_v.x, point.x)
				min_v.y = min(min_v.y, point.y)
				min_v.z = min(min_v.z, point.z)
				max_v.x = max(max_v.x, point.x)
				max_v.y = max(max_v.y, point.y)
				max_v.z = max(max_v.z, point.z)

	if not has_bounds:
		var fallback_shape := SphereShape3D.new()
		fallback_shape.radius = 0.08
		collision.shape = fallback_shape
		collision.position = Vector3.ZERO
		return

	var size = max_v - min_v
	var padded_size = Vector3(
		max(size.x, 0.02),
		max(size.y, 0.02),
		max(size.z, 0.02)
	) + Vector3(0.02, 0.02, 0.02)

	var box := BoxShape3D.new()
	box.size = padded_size
	collision.shape = box
	collision.position = min_v + size * 0.5


func _collect_mesh_instances(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			out.append(mesh_instance)

	for child in node.get_children():
		_collect_mesh_instances(child, out)


func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p = aabb.position
	var s = aabb.size
	return [
		p,
		p + Vector3(s.x, 0, 0),
		p + Vector3(0, s.y, 0),
		p + Vector3(0, 0, s.z),
		p + Vector3(s.x, s.y, 0),
		p + Vector3(s.x, 0, s.z),
		p + Vector3(0, s.y, s.z),
		p + s
	]


func get_elements() -> Array[Node3D]:
	"""Get all instantiated element nodes."""
	return _element_nodes


func find_element_by_id(element_id: String) -> Array[Node3D]:
	"""Find all nodes of a specific element type."""
	var result: Array[Node3D] = []
	for i in range(layout.placements.size()):
		if layout.placements[i].get("id") == element_id:
			if i < _element_nodes.size() and is_instance_valid(_element_nodes[i]):
				result.append(_element_nodes[i])
	return result
