extends Node3D

## Grid Snapper - Snaps the XR Origin to a grid
## Useful for aligning the player in grid-based environments

@export_group("References")
@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")

@export_group("Grid Settings")
@export var grid_size: Vector3 = Vector3(1.0, 0.0, 1.0) # Y=0 means no vertical snapping by default
@export var snap_enabled: bool = true
@export var smooth_snap: bool = true
@export var snap_speed: float = 5.0
@export var snap_threshold: float = 0.5 # Distance to grid point to activate snap (0.5 = always snap to nearest)

@export_group("Visualization")
@export var show_grid_points: bool = true
@export var grid_points_range: int = 2 # How many points to show in each direction
@export var point_color: Color = Color(0.0, 1.0, 1.0, 0.5)
@export var point_size: float = 0.05

var _xr_origin: Node3D
var _debug_mesh: MultiMeshInstance3D

func _ready() -> void:
	# Find XR Origin
	_xr_origin = get_node_or_null(xr_origin_path)
	if not _xr_origin:
		_xr_origin = _find_xr_origin()
	
	if not _xr_origin:
		push_warning("GridSnapper: XROrigin3D not found at path: %s" % xr_origin_path)
	else:
		print("GridSnapper: Controlling %s" % _xr_origin.name)
		
	if show_grid_points:
		_setup_visualization()

func _process(delta: float) -> void:
	if show_grid_points:
		_update_visualization()
		
	if not snap_enabled or not _xr_origin:
		return
		
	var current_pos = _xr_origin.global_position
	var target_pos = _calculate_snapped_position(current_pos)
	
	# Only snap if we are close enough (if threshold < 0.5 grid size)
	# But simpler is just to always snap to nearest
	
	if smooth_snap:
		# Lerp for smooth magnetic effect
		_xr_origin.global_position = current_pos.lerp(target_pos, delta * snap_speed)
	else:
		_xr_origin.global_position = target_pos

func _calculate_snapped_position(pos: Vector3) -> Vector3:
	var snapped = pos
	
	if grid_size.x > 0:
		snapped.x = round(pos.x / grid_size.x) * grid_size.x
		
	if grid_size.y > 0:
		snapped.y = round(pos.y / grid_size.y) * grid_size.y
		
	if grid_size.z > 0:
		snapped.z = round(pos.z / grid_size.z) * grid_size.z
		
	return snapped

func _setup_visualization() -> void:
	_debug_mesh = MultiMeshInstance3D.new()
	_debug_mesh.name = "GridPoints"
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.mesh.size = Vector3(point_size, point_size, point_size)
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = point_color
	multimesh.mesh.material = material
	
	# Calculate instance count
	var range_width = grid_points_range * 2 + 1
	var count = range_width * range_width # X * Z plane
	if grid_size.y > 0:
		count *= range_width # 3D grid
		
	multimesh.instance_count = count
	_debug_mesh.multimesh = multimesh
	add_child(_debug_mesh)

func _update_visualization() -> void:
	if not _xr_origin or not _debug_mesh:
		return
		
	var center_pos = _xr_origin.global_position
	var snapped_center = _calculate_snapped_position(center_pos)
	
	var idx = 0
	var range_val = grid_points_range
	
	for x in range(-range_val, range_val + 1):
		for z in range(-range_val, range_val + 1):
			var offset = Vector3(x * grid_size.x, 0, z * grid_size.z)
			
			if grid_size.y > 0:
				for y in range(-range_val, range_val + 1):
					offset.y = y * grid_size.y
					var pos = snapped_center + offset
					var t = Transform3D(Basis(), pos)
					_debug_mesh.multimesh.set_instance_transform(idx, t)
					idx += 1
			else:
				# 2D grid on current Y level (or snapped Y if we were snapping Y)
				# Keep points at player's foot level or snapped center Y?
				# Let's keep them at snapped_center.y
				var pos = snapped_center + offset
				var t = Transform3D(Basis(), pos)
				_debug_mesh.multimesh.set_instance_transform(idx, t)
				idx += 1

func _find_xr_origin() -> Node3D:
	"""Try to find XROrigin3D in the scene tree"""
	var root = get_tree().root
	if root:
		for child in root.get_children():
			var found = _search_for_xr_origin(child)
			if found:
				return found
	return null

func _search_for_xr_origin(node: Node) -> Node3D:
	"""Recursively search for XROrigin3D"""
	if node.name == "XROrigin3D" or node.is_class("XROrigin3D"):
		return node as Node3D
	for child in node.get_children():
		var found = _search_for_xr_origin(child)
		if found:
			return found
	return null

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

