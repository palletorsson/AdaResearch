extends Control
## Main editor controller — 3D-only interaction
## All placement, selection, hovering is done via raycasting in the 3D viewport.
## No 2D canvas. No coordinate flipping.

@onready var subset_selector: OptionButton = %SubsetSelector
@onready var preset_selector: OptionButton = %PresetSelector
@onready var apply_preset_button: Button = %ApplyPresetButton
@onready var element_list: ItemList = %ElementList
@onready var status_label: Label = %StatusLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var subset_loader: GridEditorSubsetLoader = %SubsetLoader
@onready var properties_label: Label = %StatusLabel  # in PropertiesBar (unique in its branch)
@onready var viewport_container: SubViewportContainer = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer
@onready var sub_viewport: SubViewport = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer/SubViewport
@onready var camera: Camera3D = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer/SubViewport/Camera3D
@onready var preview_root: Node3D = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer/SubViewport/PreviewRoot
@onready var grid_mesh: MeshInstance3D = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer/SubViewport/GridMesh
@onready var hover_indicator: MeshInstance3D = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer/SubViewport/HoverIndicator
@onready var axis_indicator: Node3D = $VBoxContainer/HSplitContainer/RightArea/ViewportContainer/SubViewport/AxisIndicator
@onready var properties_bar_label: Label = $VBoxContainer/HSplitContainer/RightArea/PropertiesBar/StatusLabel

# Camera orbit
var camera_pivot: Node3D
var camera_distance: float = 3.0
var camera_rotation: Vector2 = Vector2(-30, 45)  # pitch, yaw in degrees
var is_orbiting: bool = false

# Grid state (was in grid_canvas)
var grid_dimensions: Vector2i = Vector2i(16, 12)
var orientation: String = "XZ"
var grid_plane: Plane = Plane(Vector3.UP, 0)
var grid_size: float = 1.0

# Placements (was in grid_canvas)
var placements: Array = []
var _placement_nodes: Dictionary = {}  # placement dict -> Node3D
var _placement_bodies: Dictionary = {}  # StaticBody3D -> placement dict (reverse lookup for picking)

# Interaction state
var hovered_cell: Vector2i = Vector2i(-1, -1)
var selected_placement: Dictionary = {}
var dragging_element: Dictionary = {}  # element def being placed
var drag_rotation: int = 0
var is_moving: bool = false
var move_offset: Vector2i = Vector2i.ZERO

# Ghost preview node shown while placing/moving
var _ghost_node: Node3D = null

var current_layout_path: String = ""
var is_dirty: bool = false

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	subset_loader.subsets_loaded.connect(_on_subsets_loaded)
	_apply_modern_theme()
	_setup_3d_viewport()

# ============ UI Setup ============

func _setup_ui() -> void:
	preset_selector.clear()
	preset_selector.disabled = true
	apply_preset_button.disabled = true

func _apply_modern_theme() -> void:
	_style_option_button(subset_selector)
	_style_option_button(preset_selector)
	_style_button(apply_preset_button)
	_style_item_list(element_list)
	for label in [status_label, zoom_label]:
		if label:
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

func _style_option_button(btn: OptionButton) -> void:
	if not btn: return
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.19, 0.22)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 28
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_color = Color(0.3, 0.32, 0.38)
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = Color(0.22, 0.24, 0.28)
	hover.border_color = Color(0.4, 0.5, 0.7)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.25, 0.28, 0.32)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _style_item_list(list: ItemList) -> void:
	if not list: return
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.1, 0.1, 0.12)
	panel.set_corner_radius_all(6)
	panel.border_color = Color(0.2, 0.22, 0.26)
	panel.set_border_width_all(1)
	list.add_theme_stylebox_override("panel", panel)
	list.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	list.add_theme_color_override("font_selected_color", Color(1, 1, 1))
	var selected = StyleBoxFlat.new()
	selected.bg_color = Color(0.3, 0.45, 0.65)
	selected.set_corner_radius_all(4)
	list.add_theme_stylebox_override("selected", selected)
	list.add_theme_stylebox_override("selected_focus", selected)
	var hovered = StyleBoxFlat.new()
	hovered.bg_color = Color(0.2, 0.25, 0.32)
	hovered.set_corner_radius_all(4)
	list.add_theme_stylebox_override("hovered", hovered)

func _style_button(btn: Button) -> void:
	if not btn: return
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.3, 0.42)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_color = Color(0.35, 0.45, 0.6)
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = Color(0.26, 0.36, 0.5)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.19, 0.26, 0.36)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled = style.duplicate()
	disabled.bg_color = Color(0.17, 0.19, 0.22)
	disabled.border_color = Color(0.25, 0.27, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.62))

func _connect_signals() -> void:
	subset_selector.item_selected.connect(_on_subset_selected)
	apply_preset_button.pressed.connect(_on_apply_preset_pressed)
	element_list.item_selected.connect(_on_element_list_selected)

# ============ 3D Viewport Setup ============

func _setup_3d_viewport() -> void:
	# Create camera pivot for orbiting
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	sub_viewport.add_child(camera_pivot)
	camera.get_parent().remove_child(camera)
	camera_pivot.add_child(camera)
	camera.position = Vector3(0, 0, camera_distance)
	camera.look_at(Vector3.ZERO)

	# Setup grid mesh material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.3, 0.35, 0.4, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	grid_mesh.material_override = mat

	# Setup hover indicator
	_setup_hover_indicator()

	# Setup axis indicator
	_create_axis_indicator()

	# Connect viewport input
	viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport_container.gui_input.connect(_on_viewport_input)

	_update_camera_orbit()

func _setup_hover_indicator() -> void:
	var box = BoxMesh.new()
	box.size = Vector3(grid_size, 0.01, grid_size)
	hover_indicator.mesh = box
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.3, 0.5, 0.9, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	hover_indicator.material_override = mat
	hover_indicator.visible = false

func _create_axis_indicator() -> void:
	# Clear existing children
	for child in axis_indicator.get_children():
		child.queue_free()

	var axis_length = 0.5
	var arrow_size = 0.08
	_add_axis_arrow(axis_indicator, Vector3.RIGHT, axis_length, arrow_size, Color.RED, "X")
	_add_axis_arrow(axis_indicator, Vector3.UP, axis_length, arrow_size, Color.GREEN, "Y")
	_add_axis_arrow(axis_indicator, Vector3.BACK, axis_length, arrow_size, Color.BLUE, "Z")

	# Origin sphere
	var origin = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	origin.mesh = sphere
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color.WHITE
	origin_mat.emission_enabled = true
	origin_mat.emission = Color.WHITE * 0.5
	origin.material_override = origin_mat
	axis_indicator.add_child(origin)

func _add_axis_arrow(parent: Node3D, direction: Vector3, length: float, arrow_size: float, color: Color, label_text: String) -> void:
	var axis_node = Node3D.new()
	var shaft = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.015
	cyl.height = length
	shaft.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	shaft.material_override = mat
	if direction == Vector3.UP:
		shaft.position = direction * length / 2
	elif direction == Vector3.RIGHT:
		shaft.rotation.z = -PI / 2
		shaft.position = direction * length / 2
	else:
		shaft.rotation.x = PI / 2
		shaft.position = direction * length / 2
	axis_node.add_child(shaft)

	var cone = MeshInstance3D.new()
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0
	cone_mesh.bottom_radius = arrow_size
	cone_mesh.height = arrow_size * 2
	cone.mesh = cone_mesh
	cone.material_override = mat
	if direction == Vector3.UP:
		cone.position = direction * length
	elif direction == Vector3.RIGHT:
		cone.rotation.z = -PI / 2
		cone.position = direction * length
	else:
		cone.rotation.x = PI / 2
		cone.position = direction * length
	axis_node.add_child(cone)

	var label = Label3D.new()
	label.text = label_text
	label.font_size = 48
	label.pixel_size = 0.005
	label.position = direction * (length + arrow_size * 3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_size = 8
	axis_node.add_child(label)
	parent.add_child(axis_node)

# ============ Coordinate System (NO FLIPPING) ============

func _cell_to_world(gx: int, gy: int) -> Vector3:
	match orientation:
		"XZ": return Vector3(gx * grid_size, 0, gy * grid_size)
		"YZ": return Vector3(0, gy * grid_size, gx * grid_size)
		"XY": return Vector3(gx * grid_size, gy * grid_size, 0)
		_: return Vector3(gx * grid_size, 0, gy * grid_size)

func _cell_center_world(gx: int, gy: int, elem_w: int = 1, elem_h: int = 1) -> Vector3:
	# Center of a multi-cell element for placeholder positioning
	var cx = gx + elem_w / 2.0
	var cy = gy + elem_h / 2.0
	match orientation:
		"XZ": return Vector3(cx * grid_size, 0, cy * grid_size)
		"YZ": return Vector3(0, cy * grid_size, cx * grid_size)
		"XY": return Vector3(cx * grid_size, cy * grid_size, 0)
		_: return Vector3(cx * grid_size, 0, cy * grid_size)

func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var hit = grid_plane.intersects_ray(from, dir)
	if hit == null:
		return Vector2i(-1, -1)
	match orientation:
		"XZ": return Vector2i(int(floor(hit.x / grid_size)), int(floor(hit.z / grid_size)))
		"YZ": return Vector2i(int(floor(hit.z / grid_size)), int(floor(hit.y / grid_size)))
		"XY": return Vector2i(int(floor(hit.x / grid_size)), int(floor(hit.y / grid_size)))
		_: return Vector2i(int(floor(hit.x / grid_size)), int(floor(hit.z / grid_size)))

func _update_grid_plane() -> void:
	match orientation:
		"XZ": grid_plane = Plane(Vector3.UP, 0)
		"YZ": grid_plane = Plane(Vector3.RIGHT, 0)
		"XY": grid_plane = Plane(Vector3.BACK, 0)
		_: grid_plane = Plane(Vector3.UP, 0)

func _get_orientation_plane() -> String:
	if subset_loader and not subset_loader.current_subset.is_empty():
		return subset_loader.current_subset.get("orientation", {}).get("plane", "XZ")
	return "XZ"

# ============ Grid Drawing ============

func _update_preview_grid() -> void:
	if not grid_mesh or not grid_mesh.mesh is ImmediateMesh:
		grid_mesh.mesh = ImmediateMesh.new()

	var im = grid_mesh.mesh as ImmediateMesh
	im.clear_surfaces()

	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var line_color = Color(0.3, 0.35, 0.4, 0.6)
	var major_color = Color(0.4, 0.45, 0.5, 0.8)

	# Horizontal lines
	for i in range(grid_dimensions.y + 1):
		var color = major_color if i % 4 == 0 else line_color
		im.surface_set_color(color)
		im.surface_add_vertex(_cell_to_world(0, i))
		im.surface_set_color(color)
		im.surface_add_vertex(_cell_to_world(grid_dimensions.x, i))

	# Vertical lines
	for i in range(grid_dimensions.x + 1):
		var color = major_color if i % 4 == 0 else line_color
		im.surface_set_color(color)
		im.surface_add_vertex(_cell_to_world(i, 0))
		im.surface_set_color(color)
		im.surface_add_vertex(_cell_to_world(i, grid_dimensions.y))

	im.surface_end()

# ============ Hover Indicator ============

func _update_hover_indicator(cell: Vector2i, elem_w: int = 1, elem_h: int = 1) -> void:
	if cell.x < 0 or cell.y < 0:
		hover_indicator.visible = false
		return

	hover_indicator.visible = true

	# Resize box to element footprint
	var box = hover_indicator.mesh as BoxMesh
	match orientation:
		"XZ":
			box.size = Vector3(elem_w * grid_size, 0.01, elem_h * grid_size)
		"YZ":
			box.size = Vector3(0.01, elem_h * grid_size, elem_w * grid_size)
		"XY":
			box.size = Vector3(elem_w * grid_size, elem_h * grid_size, 0.01)

	# Position at center of footprint
	hover_indicator.position = _cell_center_world(cell.x, cell.y, elem_w, elem_h)

	# Color based on validity
	var can_place = _can_place_at(cell, Vector2i(elem_w, elem_h))
	var mat = hover_indicator.material_override as StandardMaterial3D
	if can_place:
		mat.albedo_color = Color(0.3, 0.5, 0.9, 0.35)
	else:
		mat.albedo_color = Color(0.9, 0.25, 0.25, 0.35)

# ============ Camera Orbit ============

func _reset_camera_for_plane() -> void:
	match orientation:
		"XZ":
			camera_rotation = Vector2(-45, 45)
		"YZ":
			camera_rotation = Vector2(-15, 0)
		"XY":
			camera_rotation = Vector2(-15, 0)
	_fit_camera_to_grid()

func _fit_camera_to_grid() -> void:
	var max_extent = max(grid_dimensions.x, grid_dimensions.y) * grid_size
	if not placements.is_empty():
		var max_a = 0.0
		var max_b = 0.0
		for placement in placements:
			var pos = placement.get("position", [0, 0])
			var element = subset_loader.get_element(placement.get("element", ""))
			var elem_size = element.get("size", [1, 1])
			max_a = max(max_a, (pos[0] + elem_size[0]) * grid_size)
			max_b = max(max_b, (pos[1] + elem_size[1]) * grid_size)
		max_extent = max(max_a, max_b)
	camera_distance = max_extent * 1.2 + 1.0
	_update_camera_orbit()

func _update_camera_orbit() -> void:
	if not camera_pivot or not camera:
		return
	var center = _cell_center_world(0, 0, grid_dimensions.x, grid_dimensions.y)
	camera_pivot.position = center
	camera_pivot.rotation_degrees = Vector3(camera_rotation.x, camera_rotation.y, 0)
	camera.position = Vector3(0, 0, camera_distance)
	camera.look_at(camera_pivot.global_position)
	zoom_label.text = "Dist: %.1f" % camera_distance

# ============ Viewport Input ============

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key(event as InputEventKey)

func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	# Orbit camera with right-click drag
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		is_orbiting = mb.pressed
		viewport_container.accept_event()
		return

	# Zoom with scroll wheel
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera_distance = max(0.5, camera_distance - 0.5)
		_update_camera_orbit()
		viewport_container.accept_event()
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera_distance = min(30.0, camera_distance + 0.5)
		_update_camera_orbit()
		viewport_container.accept_event()
		return

	# Left-click: place / select / move
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		var cell = _screen_to_grid(mb.position)
		if not dragging_element.is_empty():
			# Place mode: place element
			_try_place_element(cell)
		elif is_moving:
			# Finish move
			_finish_move(cell)
		else:
			# Select or start move
			_try_select_or_move(cell, mb.position)
		viewport_container.accept_event()
		return

	if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		# Release during move
		if is_moving:
			var cell = _screen_to_grid(mb.position)
			_finish_move(cell)
			viewport_container.accept_event()
		return

func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if is_orbiting:
		camera_rotation.y += mm.relative.x * 0.5
		camera_rotation.x = clamp(camera_rotation.x - mm.relative.y * 0.5, -89, 89)
		_update_camera_orbit()
		return

	var cell = _screen_to_grid(mm.position)

	if cell != hovered_cell:
		hovered_cell = cell
		if cell.x >= 0 and cell.y >= 0:
			status_label.text = "Cell: %d, %d" % [cell.x, cell.y]

	# Update hover indicator and ghost
	if not dragging_element.is_empty():
		var elem_size = _get_rotated_size(dragging_element, drag_rotation)
		_update_hover_indicator(cell, elem_size.x, elem_size.y)
		_update_ghost(dragging_element, cell, drag_rotation)
	elif is_moving and not selected_placement.is_empty():
		var target = cell - move_offset
		var element = subset_loader.get_element(selected_placement.get("element", ""))
		var rotation = selected_placement.get("rotation", 0)
		var elem_size = _get_rotated_size(element, rotation)
		_update_hover_indicator(target, elem_size.x, elem_size.y)
		_update_ghost(element, target, rotation)
	else:
		_update_hover_indicator(cell)
		_clear_ghost()

func _handle_key(ke: InputEventKey) -> void:
	if not ke.pressed:
		return

	if ke.keycode == KEY_R:
		if not dragging_element.is_empty():
			drag_rotation = (drag_rotation + 90) % 360
			if hovered_cell.x >= 0:
				var elem_size = _get_rotated_size(dragging_element, drag_rotation)
				_update_hover_indicator(hovered_cell, elem_size.x, elem_size.y)
				_update_ghost(dragging_element, hovered_cell, drag_rotation)
			viewport_container.accept_event()
		elif not selected_placement.is_empty():
			_rotate_selected()
			viewport_container.accept_event()

	elif ke.keycode == KEY_DELETE or ke.keycode == KEY_BACKSPACE:
		if not selected_placement.is_empty():
			_delete_selected()
			viewport_container.accept_event()

	elif ke.keycode == KEY_ESCAPE:
		if not dragging_element.is_empty():
			_cancel_place_mode()
			viewport_container.accept_event()
		elif is_moving:
			is_moving = false
			_clear_ghost()
			hover_indicator.visible = false
			# Re-show the node that was being moved
			if _placement_nodes.has(selected_placement):
				var node = _placement_nodes[selected_placement] as Node3D
				if node: node.visible = true
			viewport_container.accept_event()

func _input(event: InputEvent) -> void:
	# Global key shortcuts
	if event is InputEventKey and event.pressed:
		var ke = event as InputEventKey
		if ke.keycode == KEY_DELETE or ke.keycode == KEY_BACKSPACE:
			if not selected_placement.is_empty():
				_delete_selected()

# ============ Element Placement ============

func _try_place_element(cell: Vector2i) -> void:
	if dragging_element.is_empty():
		return
	var elem_size = _get_rotated_size(dragging_element, drag_rotation)
	if not _can_place_at(cell, elem_size):
		return

	var placement = {
		"id": "elem_%d" % (placements.size() + 1),
		"element": dragging_element.get("id", ""),
		"position": [cell.x, cell.y],
		"rotation": drag_rotation,
		"params": {}
	}
	placements.append(placement)
	_instantiate_placement_3d(placement)

	is_dirty = true
	status_label.text = "Placed: " + dragging_element.get("name", "element")

	# Exit place mode after placing
	dragging_element = {}
	drag_rotation = 0
	_clear_ghost()
	hover_indicator.visible = false

func _cancel_place_mode() -> void:
	dragging_element = {}
	drag_rotation = 0
	_clear_ghost()
	hover_indicator.visible = false
	status_label.text = "Ready"

# ============ Element Selection & Picking ============

func _try_select_or_move(cell: Vector2i, screen_pos: Vector2) -> void:
	# First try physics raycast for picking placed elements
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var space_state = sub_viewport.world_3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + dir * 100.0)
	var result = space_state.intersect_ray(query)

	if not result.is_empty():
		var collider = result.get("collider")
		if collider is StaticBody3D and _placement_bodies.has(collider):
			var placement = _placement_bodies[collider]
			_select_placement(placement)
			# Start move
			var p_cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
			is_moving = true
			move_offset = cell - p_cell
			# Hide the original node while moving
			if _placement_nodes.has(placement):
				var node = _placement_nodes[placement] as Node3D
				if node: node.visible = false
			return

	# Also check grid-cell-based overlap as fallback
	for placement in placements:
		var p_pos = placement.get("position", [0, 0])
		var p_cell = Vector2i(p_pos[0], p_pos[1])
		var element = subset_loader.get_element(placement.get("element", ""))
		var p_rot = placement.get("rotation", 0)
		var p_size = _get_rotated_size(element, p_rot)
		if cell.x >= p_cell.x and cell.x < p_cell.x + p_size.x \
		  and cell.y >= p_cell.y and cell.y < p_cell.y + p_size.y:
			_select_placement(placement)
			is_moving = true
			move_offset = cell - p_cell
			if _placement_nodes.has(placement):
				var node = _placement_nodes[placement] as Node3D
				if node: node.visible = false
			return

	# Nothing hit — clear selection
	_clear_selection()

func _select_placement(placement: Dictionary) -> void:
	selected_placement = placement
	_update_properties_bar(placement)

	# Highlight selected node
	for p in _placement_nodes:
		var node = _placement_nodes[p] as Node3D
		if not node: continue
		# Reset all highlight
		_set_node_highlight(node, false)
	if _placement_nodes.has(placement):
		_set_node_highlight(_placement_nodes[placement] as Node3D, true)

func _clear_selection() -> void:
	if not selected_placement.is_empty():
		if _placement_nodes.has(selected_placement):
			_set_node_highlight(_placement_nodes[selected_placement] as Node3D, false)
	selected_placement = {}
	is_moving = false
	_clear_ghost()
	hover_indicator.visible = false
	properties_bar_label.text = "No selection"

func _set_node_highlight(node: Node3D, highlight: bool) -> void:
	if not node: return
	# Walk children looking for MeshInstance3D to tint
	for child in node.get_children():
		if child is MeshInstance3D:
			if highlight:
				# Store original material and apply highlight
				if not child.has_meta("orig_mat"):
					child.set_meta("orig_mat", child.material_override)
				var mat = StandardMaterial3D.new()
				if child.material_override is StandardMaterial3D:
					mat = (child.material_override as StandardMaterial3D).duplicate()
				mat.emission_enabled = true
				mat.emission = Color(1.0, 0.7, 0.2)
				mat.emission_energy_multiplier = 0.4
				child.material_override = mat
			else:
				if child.has_meta("orig_mat"):
					child.material_override = child.get_meta("orig_mat")
					child.remove_meta("orig_mat")
		elif child is Node3D:
			_set_node_highlight(child, highlight)

# ============ Element Moving ============

func _finish_move(cell: Vector2i) -> void:
	if not is_moving or selected_placement.is_empty():
		is_moving = false
		return

	var target = cell - move_offset
	var element = subset_loader.get_element(selected_placement.get("element", ""))
	var rotation = selected_placement.get("rotation", 0)
	var elem_size = _get_rotated_size(element, rotation)

	if _can_place_at_for_move(target, elem_size, selected_placement):
		selected_placement["position"] = [target.x, target.y]
		# Rebuild the 3D node at new position
		_remove_placement_node(selected_placement)
		_instantiate_placement_3d(selected_placement)
		is_dirty = true
		status_label.text = "Moved to %d, %d" % [target.x, target.y]
	else:
		# Cancel move — show original node again
		if _placement_nodes.has(selected_placement):
			var node = _placement_nodes[selected_placement] as Node3D
			if node: node.visible = true

	is_moving = false
	_clear_ghost()
	hover_indicator.visible = false
	_update_properties_bar(selected_placement)

# ============ Element Rotation & Deletion ============

func _rotate_selected() -> void:
	if selected_placement.is_empty():
		return
	selected_placement["rotation"] = (selected_placement.get("rotation", 0) + 90) % 360
	# Rebuild node
	_remove_placement_node(selected_placement)
	_instantiate_placement_3d(selected_placement)
	is_dirty = true
	_update_properties_bar(selected_placement)
	status_label.text = "Rotated to %d°" % selected_placement.get("rotation", 0)

func _delete_selected() -> void:
	if selected_placement.is_empty():
		return
	_remove_placement_node(selected_placement)
	placements.erase(selected_placement)
	selected_placement = {}
	is_dirty = true
	properties_bar_label.text = "No selection"
	status_label.text = "Element deleted"

# ============ Ghost Preview ============

func _update_ghost(element: Dictionary, cell: Vector2i, rotation: int) -> void:
	if cell.x < 0 or cell.y < 0:
		_clear_ghost()
		return

	_clear_ghost()

	var ghost_placement = {
		"element": element.get("id", ""),
		"position": [cell.x, cell.y],
		"rotation": rotation,
		"params": {}
	}
	_ghost_node = _create_element_3d(element, ghost_placement, grid_size)
	if _ghost_node:
		# Make semi-transparent
		_set_node_transparency(_ghost_node, 0.4)
		preview_root.add_child(_ghost_node)

func _clear_ghost() -> void:
	if _ghost_node and is_instance_valid(_ghost_node):
		_ghost_node.queue_free()
	_ghost_node = null

func _set_node_transparency(node: Node3D, alpha: float) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			if child.material_override is StandardMaterial3D:
				var mat = (child.material_override as StandardMaterial3D).duplicate()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = alpha
				child.material_override = mat
		elif child is Node3D:
			_set_node_transparency(child, alpha)

# ============ Placement Validation ============

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_dimensions.x and cell.y < grid_dimensions.y

func _can_place_at(cell: Vector2i, elem_size: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.x + elem_size.x > grid_dimensions.x:
		return false
	if cell.y + elem_size.y > grid_dimensions.y:
		return false
	for placement in placements:
		if _placements_overlap(cell, elem_size, placement):
			return false
	return true

func _can_place_at_for_move(cell: Vector2i, elem_size: Vector2i, exclude: Dictionary) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.x + elem_size.x > grid_dimensions.x:
		return false
	if cell.y + elem_size.y > grid_dimensions.y:
		return false
	for placement in placements:
		if placement == exclude:
			continue
		if _placements_overlap(cell, elem_size, placement):
			return false
	return true

func _placements_overlap(cell: Vector2i, elem_size: Vector2i, placement: Dictionary) -> bool:
	var p_cell = Vector2i(placement.get("position", [0, 0])[0], placement.get("position", [0, 0])[1])
	var p_size = Vector2i(1, 1)
	if subset_loader:
		var p_element = subset_loader.get_element(placement.get("element", ""))
		var p_rotation = placement.get("rotation", 0)
		p_size = _get_rotated_size(p_element, p_rotation)
	var r1 = Rect2i(cell, elem_size)
	var r2 = Rect2i(p_cell, p_size)
	return r1.intersects(r2)

func _get_rotated_size(element: Dictionary, rotation: int) -> Vector2i:
	var s = Vector2i(element.get("size", [1, 1])[0], element.get("size", [1, 1])[1])
	if rotation == 90 or rotation == 270:
		return Vector2i(s.y, s.x)
	return s

# ============ Properties Bar ============

func _update_properties_bar(placement: Dictionary) -> void:
	var element = subset_loader.get_element(placement.get("element", ""))
	var name = element.get("name", "Unknown")
	var pos = placement.get("position", [0, 0])
	var rot = placement.get("rotation", 0)
	properties_bar_label.text = "%s  |  Pos: %d, %d  |  Rot: %d°  |  [R] rotate  [Del] delete" % [name, pos[0], pos[1], rot]

# ============ Subset / Preset / Element List ============

func _on_subsets_loaded() -> void:
	subset_selector.clear()
	var names = subset_loader.get_subset_names()
	for id in names:
		subset_selector.add_item(names[id])
		subset_selector.set_item_metadata(subset_selector.item_count - 1, id)
	if subset_selector.item_count > 0:
		subset_selector.select(0)
		_on_subset_selected(0)

func _on_subset_selected(index: int) -> void:
	var subset_id = subset_selector.get_item_metadata(index)
	subset_loader.set_current_subset(subset_id)

	# Update orientation/grid from subset
	var orient = subset_loader.get_orientation()
	orientation = orient.get("plane", "XZ")
	grid_size = orient.get("grid_size", 1.0)
	_update_grid_plane()

	# Update grid dimensions from subset defaults
	var defaults = subset_loader.current_subset.get("defaults", {})
	var gs = defaults.get("grid_size", [grid_dimensions.x, grid_dimensions.y])
	if gs is Array and gs.size() >= 2:
		grid_dimensions = Vector2i(int(gs[0]), int(gs[1]))

	# Update hover indicator size for new grid_size
	_setup_hover_indicator()

	_populate_element_list()
	_populate_preset_list()
	_update_preview_grid()
	_reset_camera_for_plane()
	status_label.text = "Subset: " + subset_loader.current_subset.get("name", "Unknown")

func _populate_element_list() -> void:
	element_list.clear()
	var categories = subset_loader.get_categories()
	var elements = subset_loader.current_subset.get("elements", [])
	for category in categories:
		var cat_idx = element_list.add_item("── " + category.get("name", "Unknown") + " ──")
		element_list.set_item_disabled(cat_idx, true)
		element_list.set_item_selectable(cat_idx, false)
		for element in elements:
			if element.get("category") == category.get("id"):
				var icon = element.get("icon", "?")
				var ename = element.get("name", element.get("id", "?"))
				var idx = element_list.add_item(icon + " " + ename)
				element_list.set_item_metadata(idx, element)

func _populate_preset_list() -> void:
	preset_selector.clear()
	var presets = subset_loader.get_presets()
	if presets.is_empty():
		preset_selector.add_item("No presets")
		preset_selector.set_item_disabled(0, true)
		preset_selector.disabled = true
		apply_preset_button.disabled = true
		return
	preset_selector.disabled = false
	apply_preset_button.disabled = false
	for preset in presets:
		var preset_name = preset.get("name", preset.get("id", "Preset"))
		preset_selector.add_item(preset_name)
		preset_selector.set_item_metadata(preset_selector.item_count - 1, preset)
	preset_selector.select(0)

func _on_apply_preset_pressed() -> void:
	if preset_selector.disabled or preset_selector.item_count == 0:
		return
	var selected_index = preset_selector.selected
	if selected_index < 0:
		selected_index = 0
	var selected_preset = preset_selector.get_item_metadata(selected_index)
	if not (selected_preset is Dictionary):
		return
	_apply_preset(selected_preset)

func _apply_preset(preset: Dictionary) -> void:
	var preset_name = preset.get("name", preset.get("id", "Preset"))
	var preset_placements = preset.get("placements", [])
	var cleaned_placements: Array = []
	var skipped_count := 0

	for i in range(preset_placements.size()):
		var entry = preset_placements[i]
		if not (entry is Dictionary):
			skipped_count += 1
			continue
		var element_id = str(entry.get("element", ""))
		if element_id.is_empty() or subset_loader.get_element(element_id).is_empty():
			skipped_count += 1
			continue
		var pos = entry.get("position", [0, 0])
		if not (pos is Array) or pos.size() < 2:
			skipped_count += 1
			continue
		var rotation = int(entry.get("rotation", 0)) % 360
		if rotation < 0:
			rotation += 360
		rotation = int(round(float(rotation) / 90.0) * 90.0) % 360
		cleaned_placements.append({
			"id": "preset_%d" % (i + 1),
			"element": element_id,
			"position": [int(pos[0]), int(pos[1])],
			"rotation": rotation,
			"params": entry.get("params", {})
		})

	var preset_grid = preset.get("grid_size", [grid_dimensions.x, grid_dimensions.y])
	if preset_grid is Array and preset_grid.size() >= 2:
		grid_dimensions = Vector2i(max(1, int(preset_grid[0])), max(1, int(preset_grid[1])))

	_load_placements_data({
		"grid_size": [grid_dimensions.x, grid_dimensions.y],
		"placements": cleaned_placements
	})

	current_layout_path = ""
	is_dirty = true
	_clear_selection()
	_update_preview_grid()
	_reset_camera_for_plane()
	status_label.text = "Preset applied: %s (%d items, %d skipped)" % [preset_name, cleaned_placements.size(), skipped_count]

func _on_element_list_selected(index: int) -> void:
	var element = element_list.get_item_metadata(index)
	if element is Dictionary and not element.is_empty():
		dragging_element = element
		drag_rotation = 0
		_clear_selection()
		status_label.text = "Place: " + element.get("name", "element") + "  (click grid, R to rotate, Esc to cancel)"

# ============ Placement 3D Node Management ============

func _instantiate_placement_3d(placement: Dictionary) -> void:
	var element = subset_loader.get_element(placement.get("element", ""))
	if element.is_empty():
		return
	var node = _create_element_3d(element, placement, grid_size)
	if not node:
		return

	# Add collision for picking
	_add_picking_collision(node, element, placement)

	preview_root.add_child(node)
	_placement_nodes[placement] = node

func _remove_placement_node(placement: Dictionary) -> void:
	if _placement_nodes.has(placement):
		var node = _placement_nodes[placement] as Node3D
		if node and is_instance_valid(node):
			# Remove body references
			_remove_body_refs(node)
			node.queue_free()
		_placement_nodes.erase(placement)

func _remove_body_refs(node: Node3D) -> void:
	for child in node.get_children():
		if child is StaticBody3D:
			_placement_bodies.erase(child)
		elif child is Node3D:
			_remove_body_refs(child)

func _add_picking_collision(node: Node3D, element: Dictionary, placement: Dictionary) -> void:
	var elem_size = element.get("size", [1, 1])
	var rotation = placement.get("rotation", 0)
	var rsize = _get_rotated_size(element, rotation)
	var body = StaticBody3D.new()
	body.name = "PickBody"
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	# Size the collision box to cover the element footprint
	match orientation:
		"XZ":
			box.size = Vector3(rsize.x * grid_size, 0.2, rsize.y * grid_size)
		"YZ":
			box.size = Vector3(0.2, rsize.y * grid_size, rsize.x * grid_size)
		"XY":
			box.size = Vector3(rsize.x * grid_size, rsize.y * grid_size, 0.2)
	shape.shape = box
	body.add_child(shape)

	# Position body at center of element footprint relative to node origin
	var pos = placement.get("position", [0, 0])
	var world_origin = _cell_to_world(pos[0], pos[1])
	var world_center = _cell_center_world(pos[0], pos[1], rsize.x, rsize.y)
	body.position = world_center - world_origin

	node.add_child(body)
	_placement_bodies[body] = placement

func _rebuild_all_3d() -> void:
	# Clear all existing nodes
	for p in _placement_nodes:
		var node = _placement_nodes[p] as Node3D
		if node and is_instance_valid(node):
			_remove_body_refs(node)
			node.queue_free()
	_placement_nodes.clear()
	_placement_bodies.clear()

	# Rebuild
	for placement in placements:
		_instantiate_placement_3d(placement)

# ============ Element 3D Creation ============

func _create_element_3d(element: Dictionary, placement: Dictionary, gs: float) -> Node3D:
	var node: Node3D = null
	var pos = placement.get("position", [0, 0])
	var elem_size = element.get("size", [1, 1])
	var rotation = placement.get("rotation", 0)

	# Check for procedural glass generation
	var segment_type = str(element.get("segment_type", ""))
	if not segment_type.is_empty() and subset_loader.current_subset_id == "glass_rack":
		node = _create_glass_segment(element, placement, gs)

	# Try to load actual scene
	if not node:
		var scene_path = str(element.get("scene", ""))
		if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			if scene:
				node = scene.instantiate()
				node.name = element.get("id", "element")
				var scale_arr = element.get("scene_scale", [1, 1, 1])
				node.scale = Vector3(scale_arr[0], scale_arr[1], scale_arr[2])
				var rot_y = element.get("rotation_y", 0)
				node.rotation_degrees.y = rot_y + rotation

	# Fallback to placeholder
	if not node:
		node = _create_placeholder_3d(element, gs)

	# Position: direct cell-to-world, no flip
	var scene_path2 = str(element.get("scene", ""))
	if not scene_path2.is_empty() or not segment_type.is_empty():
		# Scenes/procedural: origin at cell corner
		node.position = _cell_to_world(pos[0], pos[1])
	else:
		# Placeholders: center in cell footprint
		node.position = _cell_center_world(pos[0], pos[1], elem_size[0], elem_size[1])

	# Apply placement rotation
	if rotation != 0:
		node.rotation_degrees.y += rotation

	return node

func _create_placeholder_3d(element: Dictionary, gs: float) -> Node3D:
	var node = Node3D.new()
	node.name = element.get("id", "element")
	var elem_size = element.get("size", [1, 1])
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh: Mesh
	var category = element.get("category", "")
	match category:
		"sources":
			mesh = CylinderMesh.new()
			mesh.top_radius = elem_size[0] * gs * 0.4
			mesh.bottom_radius = elem_size[0] * gs * 0.4
			mesh.height = 0.3
		"filters":
			mesh = BoxMesh.new()
			mesh.size = Vector3(elem_size[0] * gs * 0.8, 0.25, elem_size[1] * gs * 0.8)
		"effects":
			mesh = SphereMesh.new()
			mesh.radius = elem_size[0] * gs * 0.35
			mesh.height = elem_size[0] * gs * 0.7
		"modulators":
			mesh = PrismMesh.new()
			mesh.size = Vector3(elem_size[0] * gs * 0.7, 0.3, elem_size[1] * gs * 0.7)
		"outputs":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0
			mesh.bottom_radius = elem_size[0] * gs * 0.4
			mesh.height = 0.4
		_:
			mesh = BoxMesh.new()
			mesh.size = Vector3(elem_size[0] * gs * 0.8, 0.2, elem_size[1] * gs * 0.8)
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	var cat_color = _get_category_color(category)
	mat.albedo_color = cat_color
	mat.emission_enabled = true
	mat.emission = cat_color * 0.3
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)

	var label = Label3D.new()
	label.text = element.get("icon", "?")
	label.position = Vector3(0, 0.35, 0)
	label.pixel_size = 0.01
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.add_child(label)
	return node

func _get_category_color(category: String) -> Color:
	match category:
		"sources": return Color(0.3, 0.69, 0.31)
		"filters": return Color(0.13, 0.59, 0.95)
		"effects": return Color(1.0, 0.6, 0.0)
		"modulators": return Color(0.61, 0.15, 0.69)
		"outputs": return Color(0.96, 0.26, 0.21)
		_: return Color(0.5, 0.5, 0.5)

# ============ Glass Segment Generators ============

func _create_glass_segment(element: Dictionary, placement: Dictionary, gs: float) -> Node3D:
	var segment_type = element.get("segment_type", "")
	var elem_size = element.get("size", [1, 1])
	var tube_radius = subset_loader.current_subset.get("defaults", {}).get("tube_radius", 0.015)
	var width = elem_size[0] * gs
	var height = elem_size[1] * gs

	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.4)
	glass_mat.metallic = 0.1
	glass_mat.roughness = 0.05
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var node: Node3D = null
	match segment_type:
		"straight":
			node = _create_glass_tube_smooth(height, tube_radius, glass_mat)
			node.position.z = width / 2
		"corner":
			node = _create_glass_elbow_directed(width, height, tube_radius, glass_mat, 0)
		"corner_bl":
			node = _create_glass_elbow_directed(width, height, tube_radius, glass_mat, 90)
		"corner_br":
			node = _create_glass_elbow_directed(width, height, tube_radius, glass_mat, 0)
		"corner_tr":
			node = _create_glass_elbow_directed(width, height, tube_radius, glass_mat, 270)
		"corner_tl":
			node = _create_glass_elbow_directed(width, height, tube_radius, glass_mat, 180)
		"corner45":
			node = _create_glass_corner45_smooth(width, height, tube_radius, glass_mat)
		"wobbly":
			node = _create_glass_wobbly_smooth(width, height, tube_radius, glass_mat)
		"reducer":
			node = _create_glass_reducer_smooth(width, height, tube_radius, glass_mat)
		"sbend":
			node = _create_glass_sbend_smooth(width, height, tube_radius, glass_mat)
		"ubend":
			node = _create_glass_ubend_smooth(width, height, tube_radius, glass_mat)
		"ypipe":
			node = _create_glass_ypipe_smooth(width, height, tube_radius, glass_mat)
		"junction":
			node = _create_glass_tee_smooth(width, height, tube_radius, glass_mat)
		"cross":
			node = _create_glass_cross_smooth(width, height, tube_radius, glass_mat)
		"spiral":
			node = _create_glass_spiral_smooth(width, height, tube_radius, glass_mat)
		"condenser":
			node = _create_glass_condenser_smooth(width, height, tube_radius, glass_mat)
		"flask":
			node = _create_glass_flask_smooth(width, height, tube_radius, glass_mat)
		"beaker":
			node = _create_glass_beaker_smooth(width, height, glass_mat)
		"cap":
			node = _create_glass_cap_smooth(width, height, tube_radius, glass_mat)
		"drip":
			node = _create_glass_drip_smooth(width, height, tube_radius, glass_mat)
		_:
			push_warning("[GridEditor] Unknown segment_type '%s', falling back to tube" % segment_type)
			node = _create_glass_tube_smooth(height, tube_radius, glass_mat)
			node.position.x = width / 2

	if node:
		node.name = element.get("id", "segment")
	return node

# ============ Smooth Procedural Glass Tubes ============

func _create_glass_tube_smooth(length: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _generate_tube_mesh(length, radius, 16, 2)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_tube_mesh(length: float, radius: float, segments: int, rings: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var y = (float(r) / rings) * length
		for s in range(segments + 1):
			var angle = (float(s) / segments) * TAU
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			st.set_normal(Vector3(cos(angle), 0, sin(angle)))
			st.set_uv(Vector2(float(s) / segments, float(r) / rings))
			st.add_vertex(Vector3(x, y, z))
	for r in range(rings):
		for s in range(segments):
			var curr = r * (segments + 1) + s
			var next = curr + segments + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_elbow_directed(width: float, height: float, radius: float, mat: Material, direction: int) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var arc_radius = min(width, height) / 2.0
	var center_y = height / 2.0
	var center_z = width / 2.0
	mesh_instance.mesh = _generate_directed_elbow_yz(arc_radius, radius, center_y, center_z, direction, 16, 16)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_directed_elbow_yz(arc_radius: float, tube_radius: float, center_y: float, center_z: float, direction: int, tube_segs: int, bend_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start_angle: float
	var end_angle: float
	match direction:
		0:
			start_angle = -PI / 2.0
			end_angle = 0.0
		90:
			start_angle = -PI / 2.0
			end_angle = -PI
		180:
			start_angle = PI / 2.0
			end_angle = PI
		_:
			start_angle = PI / 2.0
			end_angle = 0.0
	var prev_normal := Vector3.ZERO
	for b in range(bend_segs + 1):
		var t = float(b) / bend_segs
		var angle = lerpf(start_angle, end_angle, t)
		var center = Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		var d_angle = end_angle - start_angle
		var tangent = Vector3(0, arc_radius * cos(angle) * d_angle, -arc_radius * sin(angle) * d_angle).normalized()
		var normal: Vector3
		var binormal: Vector3
		if prev_normal == Vector3.ZERO:
			var ref = Vector3.RIGHT
			normal = tangent.cross(ref)
			if normal.length_squared() < 0.001:
				ref = Vector3.UP
				normal = tangent.cross(ref)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001:
				normal = prev_normal
			else:
				normal = normal.normalized()
		binormal = tangent.cross(normal).normalized()
		prev_normal = normal
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + offset)
	for b in range(bend_segs):
		for s in range(tube_segs):
			var curr = b * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_sbend_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _generate_sbend_mesh_yz(height, width, radius, 16, 24)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_sbend_mesh_yz(height: float, width: float, tube_radius: float, tube_segs: int, len_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in range(len_segs + 1):
		var t = float(l) / len_segs
		var y = t * height
		var z = width * (0.5 - 0.5 * cos(PI * t))
		var center = Vector3(0, y, z)
		var dy = height / len_segs
		var dz = width * 0.5 * PI * sin(PI * t) / len_segs
		var tangent = Vector3(0, dy, dz).normalized()
		var binormal = Vector3(1, 0, 0)
		var normal = binormal.cross(tangent).normalized()
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var ring_offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(ring_offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + ring_offset)
	for l in range(len_segs):
		for s in range(tube_segs):
			var curr = l * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_ubend_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _generate_ubend_mesh_yz(width, height, radius, 16, 20)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_ubend_mesh_yz(width: float, height: float, tube_radius: float, tube_segs: int, bend_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center_z = width / 2.0
	var arc_radius = center_z - tube_radius
	var y_top = height
	var y_bottom = tube_radius
	var y_span = y_top - y_bottom
	for b in range(bend_segs + 1):
		var t = float(b) / bend_segs
		var angle = PI * t
		var z = center_z - arc_radius * cos(angle)
		var y = y_top - y_span * sin(angle)
		var center = Vector3(0, y, z)
		var tangent = Vector3(0, -y_span * cos(angle), arc_radius * sin(angle)).normalized()
		var binormal = Vector3(1, 0, 0)
		var normal = binormal.cross(tangent).normalized()
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + offset)
	for b in range(bend_segs):
		for s in range(tube_segs):
			var curr = b * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_tee_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var center_z = width / 2
	var center_y = height / 2
	var vert = _create_glass_tube_smooth(height, radius, mat)
	vert.position.z = center_z
	node.add_child(vert)
	var horiz = MeshInstance3D.new()
	horiz.mesh = _generate_tube_mesh(width / 2, radius, 16, 2)
	horiz.material_override = mat
	horiz.rotation.x = PI / 2
	horiz.position = Vector3(0, center_y, center_z)
	node.add_child(horiz)
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius * 1.5
	sphere_mesh.height = radius * 3
	sphere.mesh = sphere_mesh
	sphere.material_override = mat
	sphere.position = Vector3(0, center_y, center_z)
	node.add_child(sphere)
	return node

func _create_glass_ypipe_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var center_z = width / 2
	var junction_y = height * 0.35
	var stem = _create_glass_tube_smooth(junction_y, radius, mat)
	stem.position.z = center_z
	node.add_child(stem)
	var branch_length = height * 0.55
	var spread = PI / 5
	for side in [-1, 1]:
		var branch = MeshInstance3D.new()
		branch.mesh = _generate_tube_mesh(branch_length, radius, 16, 2)
		branch.material_override = mat
		branch.position = Vector3(0, junction_y, center_z)
		branch.rotation.x = side * spread
		node.add_child(branch)
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius * 2
	sphere_mesh.height = radius * 4
	sphere.mesh = sphere_mesh
	sphere.material_override = mat
	sphere.position = Vector3(0, junction_y, center_z)
	node.add_child(sphere)
	return node

func _create_glass_cross_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var center = Vector3(0, height / 2, width / 2)
	var vert = _create_glass_tube_smooth(height, radius, mat)
	vert.position.z = center.z
	node.add_child(vert)
	var horiz = MeshInstance3D.new()
	horiz.mesh = _generate_tube_mesh(width, radius, 16, 2)
	horiz.material_override = mat
	horiz.rotation.x = PI / 2
	horiz.position = center
	node.add_child(horiz)
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius * 1.8
	sphere_mesh.height = radius * 3.6
	sphere.mesh = sphere_mesh
	sphere.material_override = mat
	sphere.position = center
	node.add_child(sphere)
	return node

func _create_glass_spiral_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var coil_radius = width * 0.35
	mesh_instance.mesh = _generate_spiral_mesh(height, coil_radius, radius, 4, 12, 48)
	mesh_instance.material_override = mat
	mesh_instance.position.z = width / 2
	node.add_child(mesh_instance)
	return node

func _generate_spiral_mesh(height: float, coil_radius: float, tube_radius: float, turns: int, tube_segs: int, coil_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in range(coil_segs + 1):
		var t = float(c) / coil_segs
		var coil_angle = t * turns * TAU
		var y = t * height
		var center = Vector3(coil_radius * cos(coil_angle), y, coil_radius * sin(coil_angle))
		var dx = -coil_radius * sin(coil_angle) * turns * TAU / coil_segs
		var dy = height / coil_segs
		var dz = coil_radius * cos(coil_angle) * turns * TAU / coil_segs
		var tangent = Vector3(dx, dy, dz).normalized()
		var up = Vector3(0, 1, 0)
		var binormal = tangent.cross(up).normalized()
		var normal = binormal.cross(tangent).normalized()
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + offset)
	for c in range(coil_segs):
		for s in range(tube_segs):
			var curr = c * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_condenser_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var inner = _create_glass_tube_smooth(height, radius, mat)
	inner.position.z = width / 2
	node.add_child(inner)
	var jacket = _create_glass_tube_smooth(height * 0.7, radius * 2.5, mat)
	jacket.position = Vector3(0, height * 0.15, width / 2)
	node.add_child(jacket)
	return node

func _create_glass_flask_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var bulb = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = width * 0.4
	sphere_mesh.height = width * 0.8
	bulb.mesh = sphere_mesh
	bulb.material_override = mat
	bulb.position = Vector3(0, width * 0.4, width / 2)
	node.add_child(bulb)
	var neck_height = height - width * 0.7
	var neck = _create_glass_tube_smooth(neck_height, radius, mat)
	neck.position = Vector3(0, width * 0.7, width / 2)
	node.add_child(neck)
	return node

func _create_glass_beaker_smooth(width: float, height: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = width * 0.4
	cyl.bottom_radius = width * 0.35
	cyl.height = height * 0.9
	mesh_instance.mesh = cyl
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0, height * 0.45, width / 2)
	node.add_child(mesh_instance)
	return node

func _create_glass_cap_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var cap_radius = min(width, height) * 0.4
	var sphere = SphereMesh.new()
	sphere.radius = cap_radius
	sphere.height = cap_radius * 2.0
	sphere.is_hemisphere = true
	mesh_instance.mesh = sphere
	mesh_instance.material_override = mat
	mesh_instance.rotation.x = PI
	mesh_instance.position = Vector3(0, height * 0.5, width / 2.0)
	node.add_child(mesh_instance)
	return node

func _create_glass_drip_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = radius
	cone.bottom_radius = radius * 0.3
	cone.height = height * 0.8
	mesh_instance.mesh = cone
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0, height * 0.5, width / 2.0)
	node.add_child(mesh_instance)
	return node

func _create_glass_corner45_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var arc_radius = min(width, height) / 2.0
	var center_y = height / 2.0
	var center_z = width / 2.0
	mesh_instance.mesh = _generate_corner45_mesh_yz(arc_radius, radius, center_y, center_z, 16, 12)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_corner45_mesh_yz(arc_radius: float, tube_radius: float, center_y: float, center_z: float, tube_segs: int, bend_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start_angle = -PI / 2.0
	var end_angle = -PI / 4.0
	var prev_normal := Vector3.ZERO
	for b in range(bend_segs + 1):
		var t = float(b) / bend_segs
		var angle = lerpf(start_angle, end_angle, t)
		var center = Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		var d_angle = end_angle - start_angle
		var tangent = Vector3(0, arc_radius * cos(angle) * d_angle, -arc_radius * sin(angle) * d_angle).normalized()
		var normal: Vector3
		var binormal: Vector3
		if prev_normal == Vector3.ZERO:
			var ref = Vector3.RIGHT
			normal = tangent.cross(ref)
			if normal.length_squared() < 0.001:
				normal = tangent.cross(Vector3.UP)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001:
				normal = prev_normal
			else:
				normal = normal.normalized()
		binormal = tangent.cross(normal).normalized()
		prev_normal = normal
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + offset)
	for b in range(bend_segs):
		for s in range(tube_segs):
			var curr = b * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_wobbly_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var center_z = width / 2.0
	var amplitude = max(radius * 1.5, width * 0.2)
	var wave_count = max(2.0, height / max(width * 0.4, 0.001))
	mesh_instance.mesh = _generate_wobbly_mesh_yz(height, center_z, amplitude, wave_count, radius, 16, 32)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_wobbly_mesh_yz(height: float, center_z: float, amplitude: float, wave_count: float, tube_radius: float, tube_segs: int, len_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in range(len_segs + 1):
		var t = float(l) / len_segs
		var y = t * height
		var z = center_z + sin(t * TAU * wave_count) * amplitude
		var center = Vector3(0, y, z)
		var dy = height / len_segs
		var dz = cos(t * TAU * wave_count) * amplitude * TAU * wave_count / len_segs
		var tangent = Vector3(0, dy, dz).normalized()
		var binormal = Vector3(1, 0, 0)
		var normal = binormal.cross(tangent).normalized()
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var ring_offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(ring_offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + ring_offset)
	for l in range(len_segs):
		for s in range(tube_segs):
			var curr = l * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

func _create_glass_reducer_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var center_z = width / 2.0
	var top_radius = radius * 0.6
	mesh_instance.mesh = _generate_reducer_mesh_yz(height, center_z, radius, top_radius, 16, 8)
	mesh_instance.material_override = mat
	node.add_child(mesh_instance)
	return node

func _generate_reducer_mesh_yz(height: float, center_z: float, bottom_radius: float, top_radius: float, tube_segs: int, rings: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var t = float(r) / rings
		var y = t * height
		var current_radius = lerpf(bottom_radius, top_radius, t)
		for s in range(tube_segs + 1):
			var theta = (float(s) / tube_segs) * TAU
			var offset = Vector3(current_radius * cos(theta), 0, current_radius * sin(theta))
			var vert = Vector3(offset.x, y, center_z + offset.z)
			st.set_normal(Vector3(cos(theta), 0, sin(theta)))
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(vert)
	for r in range(rings):
		for s in range(tube_segs):
			var curr = r * (tube_segs + 1) + s
			var next = curr + tube_segs + 1
			st.add_index(curr)
			st.add_index(next)
			st.add_index(curr + 1)
			st.add_index(curr + 1)
			st.add_index(next)
			st.add_index(next + 1)
	st.generate_tangents()
	return st.commit()

# ============ File Operations ============

func new_layout() -> void:
	_clear_all_placements()
	current_layout_path = ""
	is_dirty = false
	_clear_selection()
	status_label.text = "New layout"

func save_layout(path: String = "") -> void:
	if path.is_empty():
		path = current_layout_path
	if path.is_empty():
		return
	var data = {
		"version": "1.0",
		"subset": subset_loader.current_subset_id,
		"name": path.get_file().get_basename(),
		"grid_size": [grid_dimensions.x, grid_dimensions.y],
		"placements": placements
	}
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	current_layout_path = path
	is_dirty = false
	status_label.text = "Saved: " + path.get_file()

func load_layout(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found: ", path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		push_error("Failed to parse: ", path)
		return
	var data = json.data

	# Set subset
	var subset_id = data.get("subset", "")
	if subset_loader.subsets.has(subset_id):
		subset_loader.set_current_subset(subset_id)
		for i in range(subset_selector.item_count):
			if subset_selector.get_item_metadata(i) == subset_id:
				subset_selector.select(i)
				break
		var orient = subset_loader.get_orientation()
		orientation = orient.get("plane", "XZ")
		grid_size = orient.get("grid_size", 1.0)
		_update_grid_plane()
		_populate_element_list()
		_populate_preset_list()

	_load_placements_data(data)
	_update_preview_grid()
	_reset_camera_for_plane()
	current_layout_path = path
	is_dirty = false
	status_label.text = "Loaded: " + path.get_file()

func _load_placements_data(data: Dictionary) -> void:
	var gs = data.get("grid_size", [grid_dimensions.x, grid_dimensions.y])
	if gs is Array and gs.size() >= 2:
		grid_dimensions = Vector2i(int(gs[0]), int(gs[1]))
	placements = data.get("placements", []).duplicate(true)
	_clear_selection()
	_rebuild_all_3d()

func _clear_all_placements() -> void:
	for p in _placement_nodes:
		var node = _placement_nodes[p] as Node3D
		if node and is_instance_valid(node):
			_remove_body_refs(node)
			node.queue_free()
	_placement_nodes.clear()
	_placement_bodies.clear()
	placements.clear()

func get_layout_data() -> Dictionary:
	return {
		"grid_size": [grid_dimensions.x, grid_dimensions.y],
		"placements": placements.duplicate(true)
	}

func export_to_config(path: String) -> void:
	var data = get_layout_data()
	var subset = subset_loader.current_subset
	var path_string = _generate_path_string(data.placements)
	var schematic = _generate_schematic(data)
	var config = {
		"name": path.get_file().get_basename(),
		"schematic": schematic,
		"path": path_string,
		"layout": {
			"segment_length": subset.get("orientation", {}).get("grid_size", 0.1),
			"tube_radius": 0.015
		}
	}
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config, "  "))
	file.close()
	status_label.text = "Exported: " + path.get_file()

func _generate_path_string(p_placements: Array) -> String:
	var parts = []
	for p in p_placements:
		var element = subset_loader.get_element(p.get("element", ""))
		var cmd = element.get("segment_type", element.get("id", "?"))
		parts.append(cmd)
	return ",".join(parts)

func _generate_schematic(data: Dictionary) -> Array:
	var gs = Vector2i(data.get("grid_size", [16, 12])[0], data.get("grid_size", [16, 12])[1])
	var schematic = []
	for y in range(gs.y):
		var row = ""
		for x in range(gs.x):
			row += " "
		schematic.append(row)
	for p in data.placements:
		var element = subset_loader.get_element(p.get("element", ""))
		var pos = Vector2i(p.get("position", [0, 0])[0], p.get("position", [0, 0])[1])
		var icon = element.get("icon", "?")
		if pos.y < schematic.size() and pos.x < schematic[pos.y].length():
			var row = schematic[pos.y]
			schematic[pos.y] = row.substr(0, pos.x) + icon + row.substr(pos.x + 1)
	return schematic
