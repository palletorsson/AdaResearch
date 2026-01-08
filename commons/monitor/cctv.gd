extends Node3D
class_name CCTVMonitor

## CCTV Monitor - Displays a target scene in a SubViewport
## Can be configured via grid system with scene path, rotation, y-offset, and scale

@export_group("Target Scene")
@export var target_scene_path: String = "res://commons/primitives/origin/origin.tscn"  # Default scene to display
@export var camera_distance: float = 2.0
@export var camera_fov: float = 70.0

@export_group("Monitor Transform")
@export var monitor_rotation_y: float = 0.0  # Rotation in degrees
@export var monitor_y_offset: float = 0.0    # Y position offset
@export var monitor_scale: float = 1.0       # Uniform scale

@export_group("Viewport Settings")
@export var viewport_width: int = 512
@export var viewport_height: int = 512
@export var viewport_update_mode: SubViewport.UpdateMode = SubViewport.UPDATE_ALWAYS

# Internal references
var _subviewport: SubViewport
var _camera: Camera3D
var _sprite: Sprite3D
var _monitor_frame: MeshInstance3D
var _target_scene_instance: Node3D

func _ready() -> void:
	# Find child nodes
	_subviewport = get_node_or_null("SubViewport")
	_camera = get_node_or_null("SubViewport/Camera3D")
	_sprite = get_node_or_null("Sprite3D")
	_monitor_frame = get_node_or_null("MonitorFrame")
	
	if not _subviewport:
		push_error("CCTVMonitor: SubViewport not found!")
		return
	
	if not _camera:
		push_error("CCTVMonitor: Camera3D not found in SubViewport!")
		return
	
	# Configure viewport
	_configure_viewport()
	
	# Apply monitor transforms
	_apply_monitor_transforms()
	
	# Load and display target scene if path is set
	if not target_scene_path.is_empty():
		call_deferred("_load_and_display_scene")

func configure(scene_path: String, rot_y: float = 0.0, y_trans: float = 0.0, scale: float = 1.0) -> void:
	"""Configure the CCTV monitor from grid system"""
	target_scene_path = scene_path
	monitor_rotation_y = rot_y
	monitor_y_offset = y_trans
	monitor_scale = scale
	
	# Apply transforms
	_apply_monitor_transforms()
	
	# Load scene
	if is_inside_tree():
		call_deferred("_load_and_display_scene")
	
	print("CCTVMonitor: Configured - scene='%s', rot=%f, y=%f, scale=%f" % [scene_path, rot_y, y_trans, scale])

func _configure_viewport() -> void:
	"""Set up the SubViewport with proper settings"""
	if not _subviewport:
		return
	
	_subviewport.size = Vector2i(viewport_width, viewport_height)
	_subviewport.render_target_update_mode = viewport_update_mode
	_subviewport.transparent_bg = false
	
	# Configure camera
	if _camera:
		_camera.fov = camera_fov
		_camera.position = Vector3(0, 0, camera_distance)
		_camera.look_at(Vector3.ZERO, Vector3.UP)
	
	print("CCTVMonitor: Viewport configured - size=%dx%d" % [viewport_width, viewport_height])

func _apply_monitor_transforms() -> void:
	"""Apply rotation, y-offset, and scale to the entire monitor"""
	rotation_degrees.y = monitor_rotation_y
	position.y = monitor_y_offset
	scale = Vector3.ONE * monitor_scale

func _load_and_display_scene() -> void:
	"""Load the target scene and display it in the viewport"""
	if target_scene_path.is_empty():
		push_warning("CCTVMonitor: No target scene path set")
		return
	
	if not _subviewport:
		push_error("CCTVMonitor: SubViewport not available")
		return
	
	# Clear any existing target scene
	if _target_scene_instance:
		_target_scene_instance.queue_free()
		_target_scene_instance = null
	
	# Load the target scene
	if not FileAccess.file_exists(target_scene_path):
		push_error("CCTVMonitor: Target scene file not found: %s" % target_scene_path)
		_show_no_signal()
		return
	
	var scene = load(target_scene_path)
	if not scene:
		push_error("CCTVMonitor: Failed to load scene: %s" % target_scene_path)
		_show_no_signal()
		return
	
	# Instantiate the scene
	_target_scene_instance = scene.instantiate()
	if not _target_scene_instance:
		push_error("CCTVMonitor: Failed to instantiate scene: %s" % target_scene_path)
		_show_no_signal()
		return
	
	# Add to viewport
	_subviewport.add_child(_target_scene_instance)
	
	# Position camera to frame the scene
	call_deferred("_frame_target_scene")
	
	print("CCTVMonitor: Loaded and displaying scene: %s" % target_scene_path)

func _frame_target_scene() -> void:
	"""Automatically position camera to frame the target scene"""
	if not _target_scene_instance or not _camera:
		return
	
	# Try to calculate bounding box of the scene
	var aabb = _calculate_scene_aabb(_target_scene_instance)
	
	if aabb.size.length() > 0.001:
		# Position camera to look at center of AABB
		var center = aabb.get_center()
		var size = aabb.size.length()
		
		# Adjust camera distance based on scene size
		var adjusted_distance = max(camera_distance, size * 1.5)
		_camera.position = center + Vector3(0, size * 0.3, adjusted_distance)
		_camera.look_at(center, Vector3.UP)
		
		print("CCTVMonitor: Camera framed - center=%s, distance=%f" % [center, adjusted_distance])
	else:
		# Fallback to default positioning
		_camera.position = Vector3(0, 0.5, camera_distance)
		_camera.look_at(Vector3.ZERO, Vector3.UP)
		print("CCTVMonitor: Using default camera position")

func _calculate_scene_aabb(node: Node) -> AABB:
	"""Calculate the axis-aligned bounding box for all visual nodes in the scene"""
	var combined_aabb = AABB()
	var first = true
	
	_collect_aabb_recursive(node, combined_aabb, first)
	
	return combined_aabb

func _collect_aabb_recursive(node: Node, combined_aabb: AABB, first: bool) -> void:
	"""Recursively collect AABBs from all MeshInstance3D nodes"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh:
			var local_aabb = mesh_instance.mesh.get_aabb()
			var global_aabb = local_aabb
			
			# Transform AABB to global coordinates
			if mesh_instance.global_transform:
				global_aabb = mesh_instance.global_transform * local_aabb
			
			if first:
				combined_aabb = global_aabb
				first = false
			else:
				combined_aabb = combined_aabb.merge(global_aabb)
	
	# Recurse through children
	for child in node.get_children():
		_collect_aabb_recursive(child, combined_aabb, first)

func _show_no_signal() -> void:
	"""Display a 'NO SIGNAL' message when scene loading fails"""
	if not _sprite:
		return
	
	# Create a simple "NO SIGNAL" texture
	var img = Image.create(viewport_width, viewport_height, false, Image.FORMAT_RGB8)
	img.fill(Color(0.1, 0.1, 0.15))  # Dark blue background
	
	var texture = ImageTexture.create_from_image(img)
	_sprite.texture = texture
	
	print("CCTVMonitor: Displaying NO SIGNAL")

func set_camera_distance(distance: float) -> void:
	"""Adjust camera distance from target"""
	camera_distance = distance
	if _camera:
		_camera.position.z = distance
		if _target_scene_instance:
			call_deferred("_frame_target_scene")

func get_target_scene_instance() -> Node3D:
	"""Get reference to the instantiated target scene"""
	return _target_scene_instance
