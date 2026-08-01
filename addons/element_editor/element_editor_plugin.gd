@tool
extends EditorPlugin
## Main plugin for the 3D Element Editor.
## Provides grid-based placement of VR rack elements directly in the 3D viewport.

const ElementDock = preload("res://addons/element_editor/element_dock.gd")
const ElementGizmoPlugin = preload("res://addons/element_editor/element_gizmo_plugin.gd")
const ElementLayoutNode = preload("res://addons/element_editor/element_layout_node.gd")

var dock: Control
var gizmo_plugin: EditorNode3DGizmoPlugin
var subset_data: ElementSubsetData

# Current editing state
var current_layout: Node3D = null
var selected_element_id: String = ""
var preview_node: Node3D = null
var is_placing := false

# Grid visualization
var grid_mesh_instance: MeshInstance3D = null
var _last_viewport_camera: Camera3D = null
var _last_mouse_position: Vector2 = Vector2.ZERO
var _has_mouse_position := false


func _enter_tree():
	print("[ElementEditor] Plugin loading...")
	
	# Load subset data
	subset_data = ElementSubsetData.new()
	subset_data.load_all()
	
	# Create and add the dock
	dock = ElementDock.new()
	dock.name = "ElementDock"
	dock.plugin = self
	dock.subset_data = subset_data
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	
	# Register custom type
	add_custom_type(
		"ElementLayoutNode",
		"Node3D",
		ElementLayoutNode,
		preload("res://addons/element_editor/icons/element_layout.svg") if FileAccess.file_exists("res://addons/element_editor/icons/element_layout.svg") else null
	)
	
	# Create gizmo plugin
	gizmo_plugin = ElementGizmoPlugin.new()
	gizmo_plugin.plugin = self
	add_node_3d_gizmo_plugin(gizmo_plugin)
	
	print("[ElementEditor] Plugin loaded!")


func _exit_tree():
	# Clean up
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
	
	if gizmo_plugin:
		remove_node_3d_gizmo_plugin(gizmo_plugin)
	
	remove_custom_type("ElementLayoutNode")
	
	_clear_preview()
	_clear_grid()
	
	print("[ElementEditor] Plugin unloaded.")


func _handles(object: Object) -> bool:
	# We handle ElementLayoutNode objects
	return object is Node3D and object.get_script() == ElementLayoutNode


func _edit(object: Object):
	if object is Node3D and object.get_script() == ElementLayoutNode:
		current_layout = object
		dock.set_layout(object)
		_update_grid_visualization()
	else:
		current_layout = null
		dock.set_layout(null)
		_clear_grid()


func _make_visible(visible: bool):
	if dock:
		dock.visible = visible
	if not visible:
		_clear_preview()
		_clear_grid()


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if not current_layout:
		return AFTER_GUI_INPUT_PASS
	
	# Handle delete key even when not placing
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			var mouse_pos = viewport_camera.get_viewport().get_mouse_position()
			delete_element_at_mouse(viewport_camera, mouse_pos)
			return AFTER_GUI_INPUT_STOP
	
	# Placement mode handling
	if not is_placing or selected_element_id.is_empty():
		return AFTER_GUI_INPUT_PASS
	
	if event is InputEventMouseMotion:
		_last_viewport_camera = viewport_camera
		_last_mouse_position = event.position
		_has_mouse_position = true
		_update_preview_position(viewport_camera, event.position)
		return AFTER_GUI_INPUT_PASS
	
	if event is InputEventMouseButton:
		_last_viewport_camera = viewport_camera
		_last_mouse_position = event.position
		_has_mouse_position = true
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var grid_pos = _get_grid_position_at_mouse(viewport_camera, event.position)
			if grid_pos != null:
				_place_element(grid_pos)
				return AFTER_GUI_INPUT_STOP
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Cancel placement mode
			stop_placing()
			return AFTER_GUI_INPUT_STOP
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			stop_placing()
			return AFTER_GUI_INPUT_STOP
		if event.keycode == KEY_R:
			_rotate_preview()
			return AFTER_GUI_INPUT_STOP
	
	return AFTER_GUI_INPUT_PASS


func start_placing(element_id: String):
	"""Start placement mode for an element."""
	selected_element_id = element_id
	is_placing = true
	preview_rotation = 0
	preview_base_rotation = Vector3.ZERO
	_create_preview()
	print("[ElementEditor] Placing: ", element_id)


func stop_placing():
	"""Stop placement mode."""
	is_placing = false
	selected_element_id = ""
	_has_mouse_position = false
	preview_base_rotation = Vector3.ZERO
	_clear_preview()


func _place_element(grid_pos: Vector3i):
	"""Place the selected element at a grid position."""
	if not current_layout or selected_element_id.is_empty():
		return
	
	var layout_script = current_layout.get_script()
	if not layout_script:
		return
	
	# Use undo/redo
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Place Element")
	undo_redo.add_do_method(current_layout, "add_element", selected_element_id, grid_pos, preview_rotation)
	undo_redo.add_undo_method(current_layout, "remove_element_at", grid_pos)
	undo_redo.commit_action()


func delete_element_at_mouse(camera: Camera3D, mouse_pos: Vector2):
	"""Delete element under the mouse cursor."""
	if not current_layout:
		return
	
	var grid_pos = _get_grid_position_at_mouse(camera, mouse_pos)
	if grid_pos == null:
		return
	
	# Find element at this position
	var placement = current_layout.get_element_at(grid_pos)
	if placement.is_empty():
		# Check if clicking on any cell of a multi-cell element
		for p in current_layout.placements:
			var p_pos = p.get("grid_pos", Vector3i.ZERO)
			var p_id = p.get("id", "")
			var element = subset_data.get_element(current_layout.subset_id, p_id)
			var elem_size = element.get("size", [1, 1])
			var placement_rotation = p.get("rotation", 0)
			var effective_rotation = placement_rotation
			if current_layout.has_method("get_effective_grid_rotation"):
				effective_rotation = current_layout.get_effective_grid_rotation(element, placement_rotation)
			var cells = current_layout.get_cells_for_element(p_pos, elem_size, effective_rotation)
			if grid_pos in cells:
				placement = p
				break
	
	if placement.is_empty():
		return
	
	var element_pos = placement.get("grid_pos", Vector3i.ZERO)
	
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Delete Element")
	undo_redo.add_do_method(current_layout, "remove_element_at", element_pos)
	undo_redo.add_undo_method(current_layout, "add_element", placement.get("id"), element_pos, placement.get("rotation", 0))
	undo_redo.commit_action()


func _get_grid_position_at_mouse(camera: Camera3D, mouse_pos: Vector2):
	"""Raycast to find grid position under mouse."""
	if not current_layout:
		return null
	
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)
	
	# Get plane from layout
	var plane_normal = _get_plane_normal_world()
	var plane_origin = current_layout.global_position
	
	# Intersect ray with plane
	var plane = Plane(plane_normal, plane_origin.dot(plane_normal))
	var intersection = plane.intersects_ray(from, dir)
	
	if intersection == null:
		return null
	
	# Convert to local space then to grid
	var local_pos = current_layout.to_local(intersection)
	return _world_to_grid(local_pos)


func _world_to_grid(local_pos: Vector3) -> Vector3i:
	"""Convert local position to grid coordinates."""
	if not current_layout:
		return Vector3i.ZERO
	
	var grid_size = current_layout.grid_size if current_layout.get("grid_size") else 0.1
	var plane = current_layout.orientation_plane if current_layout.get("orientation_plane") else "XY"
	
	match plane:
		"XY":
			return Vector3i(floori(local_pos.x / grid_size), floori(local_pos.y / grid_size), 0)
		"YZ":
			return Vector3i(floori(local_pos.z / grid_size), floori(local_pos.y / grid_size), 0)
		"XZ":
			return Vector3i(floori(local_pos.x / grid_size), floori(local_pos.z / grid_size), 0)
	
	return Vector3i.ZERO


func _get_plane_normal_local() -> Vector3:
	"""Get the local-space normal for the current orientation plane."""
	if not current_layout:
		return Vector3.BACK
	
	var plane = current_layout.orientation_plane if current_layout.get("orientation_plane") else "XY"
	match plane:
		"XY": return Vector3.BACK
		"YZ": return Vector3.RIGHT
		"XZ": return Vector3.UP
	return Vector3.BACK


func _get_plane_normal_world() -> Vector3:
	"""Get the world-space normal for the current orientation plane."""
	if not current_layout:
		return Vector3.BACK
	return (current_layout.global_basis * _get_plane_normal_local()).normalized()


func _normalize_rotation(rotation: int) -> int:
	var normalized = rotation % 4
	if normalized < 0:
		normalized += 4
	return normalized


func _get_rotated_size(size: Array, rotation: int) -> Array:
	var w: int = int(size[0]) if size.size() > 0 else 1
	var h: int = int(size[1]) if size.size() > 1 else 1
	var normalized_rotation = _normalize_rotation(rotation)
	if normalized_rotation == 1 or normalized_rotation == 3:
		var tmp = w
		w = h
		h = tmp
	return [w, h]


func _get_element_base_rotation_radians(element: Dictionary) -> Vector3:
	return Vector3(
		deg_to_rad(float(element.get("rotation_x", 0.0))),
		deg_to_rad(float(element.get("rotation_y", 0.0))),
		deg_to_rad(float(element.get("rotation_z", 0.0)))
	)


func _create_preview():
	"""Create a preview mesh for the element being placed."""
	_clear_preview()
	
	if selected_element_id.is_empty() or not current_layout:
		return
	
	var subset_id = current_layout.subset_id if current_layout.get("subset_id") else ""
	var element = subset_data.get_element(subset_id, selected_element_id)
	if element.is_empty():
		return
	
	preview_node = Node3D.new()
	
	# Check if this is a procedural glass element
	var segment_type = element.get("segment_type", "")
	if not segment_type.is_empty() and subset_id == "glass_rack":
		# Create actual glass preview
		var elem_size = element.get("size", [1, 1])
		var grid_size = current_layout.grid_size if current_layout.get("grid_size") else 0.1
		var width = elem_size[0] * grid_size
		var height = elem_size[1] * grid_size
		var tube_radius = subset_data.get_subset(subset_id).get("defaults", {}).get("tube_radius", 0.015)
		var segment_rotation = int(element.get("rotation", 0))
		
		var glass_preview = GlassMeshGenerator.create_segment(segment_type, width, height, tube_radius, null, segment_rotation)
		preview_node.add_child(glass_preview)
	else:
		# Create box preview
		var mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		var world_size = subset_data.get_element_world_size(subset_id, selected_element_id)
		box.size = world_size
		mesh_instance.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 1.0, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = mat
		
		preview_node.add_child(mesh_instance)

	preview_base_rotation = _get_element_base_rotation_radians(element)
	_apply_preview_rotation()
	
	current_layout.add_child(preview_node)


var preview_rotation: int = 0
var preview_base_rotation: Vector3 = Vector3.ZERO


func _clear_preview():
	"""Remove the preview node."""
	if preview_node and is_instance_valid(preview_node):
		preview_node.queue_free()
	preview_node = null
	preview_base_rotation = Vector3.ZERO


func _update_preview_position(camera: Camera3D, mouse_pos: Vector2):
	"""Update preview position based on mouse."""
	if not preview_node or not current_layout:
		return
	
	var grid_pos = _get_grid_position_at_mouse(camera, mouse_pos)
	if grid_pos == null:
		return
	
	var grid_size = current_layout.grid_size if current_layout.get("grid_size") else 0.1
	var plane = current_layout.orientation_plane if current_layout.get("orientation_plane") else "XY"
	var subset_id = current_layout.subset_id if current_layout.get("subset_id") else ""
	
	# Get element size for proper centering
	var element = subset_data.get_element(subset_id, selected_element_id)
	var elem_size = element.get("size", [1, 1]) if not element.is_empty() else [1, 1]
	var effective_rotation = preview_rotation
	if current_layout and current_layout.has_method("get_effective_grid_rotation"):
		effective_rotation = current_layout.get_effective_grid_rotation(element, preview_rotation)
	var rotated_size = _get_rotated_size(elem_size, effective_rotation)
	var half_w = rotated_size[0] / 2.0
	var half_h = rotated_size[1] / 2.0
	
	var world_pos = Vector3.ZERO
	match plane:
		"XY":
			world_pos = Vector3(grid_pos.x + half_w, grid_pos.y + half_h, 0) * grid_size
		"YZ":
			world_pos = Vector3(0, grid_pos.y + half_h, grid_pos.x + half_w) * grid_size
		"XZ":
			world_pos = Vector3(grid_pos.x + half_w, 0, grid_pos.y + half_h) * grid_size
	
	preview_node.position = world_pos


func _apply_preview_rotation():
	if not preview_node:
		return
	preview_node.rotation = Vector3.ZERO
	if not is_zero_approx(preview_base_rotation.x):
		preview_node.rotate_x(preview_base_rotation.x)
	if not is_zero_approx(preview_base_rotation.y):
		preview_node.rotate_y(preview_base_rotation.y)
	if not is_zero_approx(preview_base_rotation.z):
		preview_node.rotate_z(preview_base_rotation.z)
	
	var plane = current_layout.orientation_plane if current_layout and current_layout.get("orientation_plane") else "XY"
	match plane:
		"XY":
			preview_node.rotate_z(preview_rotation * PI / 2.0)
		"YZ":
			preview_node.rotate_x(preview_rotation * PI / 2.0)
		"XZ":
			preview_node.rotate_y(preview_rotation * PI / 2.0)


func _rotate_preview():
	"""Rotate the preview by 90 degrees."""
	preview_rotation = (preview_rotation + 1) % 4
	_apply_preview_rotation()
	if _has_mouse_position and _last_viewport_camera:
		_update_preview_position(_last_viewport_camera, _last_mouse_position)


func _update_grid_visualization():
	"""Create/update the grid visualization for the current layout."""
	_clear_grid()
	
	if not current_layout:
		return
	
	# Grid will be drawn by gizmo plugin
	# Force redraw
	if gizmo_plugin:
		current_layout.update_gizmos()


func _clear_grid():
	"""Remove grid visualization."""
	if grid_mesh_instance and is_instance_valid(grid_mesh_instance):
		grid_mesh_instance.queue_free()
	grid_mesh_instance = null
