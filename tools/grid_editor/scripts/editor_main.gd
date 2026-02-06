extends Control
## Main editor controller
## Manages UI, file operations, and coordination between panels

@onready var subset_selector: OptionButton = %SubsetSelector
@onready var element_list: ItemList = %ElementList
@onready var grid_canvas: GridCanvas = %GridCanvas
@onready var properties_container: VBoxContainer = %PropertiesContainer
@onready var status_label: Label = %StatusLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var subset_loader: GridEditorSubsetLoader = %SubsetLoader
@onready var preview_root: Node3D = $VBoxContainer/HSplitContainer/HSplitContainer/RightPanel/PreviewContainer/SubViewport/PreviewRoot
@onready var preview_camera: Camera3D = $VBoxContainer/HSplitContainer/HSplitContainer/RightPanel/PreviewContainer/SubViewport/Camera3D
@onready var preview_container: SubViewportContainer = $VBoxContainer/HSplitContainer/HSplitContainer/RightPanel/PreviewContainer
@onready var preview_viewport: SubViewport = $VBoxContainer/HSplitContainer/HSplitContainer/RightPanel/PreviewContainer/SubViewport

var preview_grid: MeshInstance3D
var preview_axis: Node3D
var camera_pivot: Node3D
var camera_distance: float = 3.0
var camera_rotation: Vector2 = Vector2(-30, 45)  # pitch, yaw in degrees
var is_rotating_preview: bool = false

var current_layout_path: String = ""
var is_dirty: bool = false

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	subset_loader.subsets_loaded.connect(_on_subsets_loaded)
	grid_canvas.subset_loader = subset_loader
	
	# Apply modern styling
	_apply_modern_theme()
	
	# Setup 3D preview
	_setup_3d_preview()

func _setup_ui() -> void:
	# Will be populated when subsets load
	pass

func _apply_modern_theme() -> void:
	"""Apply modern dark theme styling"""
	# Style the subset dropdown
	_style_option_button(subset_selector)
	
	# Style element list
	_style_item_list(element_list)
	
	# Style labels
	for label in [status_label, zoom_label]:
		if label:
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

func _style_option_button(btn: OptionButton) -> void:
	if not btn:
		return
	
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
	if not list:
		return
	
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

func _connect_signals() -> void:
	subset_selector.item_selected.connect(_on_subset_selected)
	element_list.item_selected.connect(_on_element_selected)
	grid_canvas.cell_hovered.connect(_on_cell_hovered)
	grid_canvas.element_placed.connect(_on_element_placed)
	grid_canvas.element_selected.connect(_on_element_selected_canvas)
	grid_canvas.selection_cleared.connect(_on_selection_cleared)
	
	# 3D preview updates
	grid_canvas.element_placed.connect(_update_3d_preview)
	grid_canvas.element_rotated.connect(_update_3d_preview)
	grid_canvas.element_moved.connect(_update_3d_preview)
	grid_canvas.selection_cleared.connect(_update_3d_preview)

func _on_subsets_loaded() -> void:
	print("EditorMain: _on_subsets_loaded called")
	subset_selector.clear()
	var names = subset_loader.get_subset_names()
	print("EditorMain: Found %d subsets: %s" % [names.size(), str(names)])
	for id in names:
		subset_selector.add_item(names[id])
		subset_selector.set_item_metadata(subset_selector.item_count - 1, id)
	
	if subset_selector.item_count > 0:
		subset_selector.select(0)
		_on_subset_selected(0)
	else:
		push_warning("EditorMain: No subsets loaded!")

func _on_subset_selected(index: int) -> void:
	var subset_id = subset_selector.get_item_metadata(index)
	subset_loader.set_current_subset(subset_id)
	_populate_element_list()
	_update_preview_grid()
	_reset_camera_for_plane()
	status_label.text = "Subset: " + subset_loader.current_subset.get("name", "Unknown")

func _reset_camera_for_plane() -> void:
	# Set default camera angle based on orientation plane
	var plane = _get_orientation_plane()
	match plane:
		"XZ":  # Top-down view
			camera_rotation = Vector2(-45, 45)
		"YZ":  # Side view (glass rack)
			camera_rotation = Vector2(-15, 0)
		"XY":  # Front view
			camera_rotation = Vector2(-15, 0)
	_update_camera_orbit()

func _populate_element_list() -> void:
	element_list.clear()
	
	var categories = subset_loader.get_categories()
	var elements = subset_loader.current_subset.get("elements", [])
	
	# Group by category
	for category in categories:
		# Add category header
		var cat_idx = element_list.add_item("── " + category.get("name", "Unknown") + " ──")
		element_list.set_item_disabled(cat_idx, true)
		element_list.set_item_selectable(cat_idx, false)
		
		# Add elements in this category
		for element in elements:
			if element.get("category") == category.get("id"):
				var icon = element.get("icon", "?")
				var name = element.get("name", element.get("id", "?"))
				var idx = element_list.add_item(icon + " " + name)
				element_list.set_item_metadata(idx, element)

func _on_element_selected(index: int) -> void:
	var element = element_list.get_item_metadata(index)
	if element is Dictionary and not element.is_empty():
		grid_canvas.start_drag(element)
		status_label.text = "Place: " + element.get("name", "element")

func _on_cell_hovered(cell: Vector2i) -> void:
	if cell.x >= 0 and cell.y >= 0:
		status_label.text = "Cell: %d, %d" % [cell.x, cell.y]

func _on_element_placed(placement: Dictionary) -> void:
	is_dirty = true
	status_label.text = "Placed: " + placement.get("element", "element")
	_update_properties(placement)

func _on_element_selected_canvas(placement: Dictionary) -> void:
	_update_properties(placement)

func _on_selection_cleared() -> void:
	_clear_properties()

func _update_properties(placement: Dictionary) -> void:
	_clear_properties()
	
	var element = subset_loader.get_element(placement.get("element", ""))
	if element.is_empty():
		return
	
	# Element name
	var name_label = Label.new()
	name_label.text = element.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	properties_container.add_child(name_label)
	
	# Position
	var pos = placement.get("position", [0, 0])
	var pos_label = Label.new()
	pos_label.text = "Position: %d, %d" % [pos[0], pos[1]]
	properties_container.add_child(pos_label)
	
	# Rotation
	var rot_label = Label.new()
	rot_label.text = "Rotation: %d°" % placement.get("rotation", 0)
	properties_container.add_child(rot_label)
	
	# Delete button
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(func(): grid_canvas.delete_selected())
	properties_container.add_child(delete_btn)

func _clear_properties() -> void:
	for child in properties_container.get_children():
		child.queue_free()
	
	var no_sel = Label.new()
	no_sel.text = "No element selected"
	no_sel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	properties_container.add_child(no_sel)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		grid_canvas.delete_selected()
	elif event.is_action_pressed("ui_undo"):
		# TODO: Implement undo
		pass
	elif event.is_action_pressed("ui_redo"):
		# TODO: Implement redo
		pass

# File operations
func new_layout() -> void:
	grid_canvas.clear_placements()
	current_layout_path = ""
	is_dirty = false
	status_label.text = "New layout"

func save_layout(path: String = "") -> void:
	if path.is_empty():
		path = current_layout_path
	if path.is_empty():
		# TODO: Show save dialog
		return
	
	var data = {
		"version": "1.0",
		"subset": subset_loader.current_subset_id,
		"name": path.get_file().get_basename(),
		"grid_size": [grid_canvas.grid_dimensions.x, grid_canvas.grid_dimensions.y],
		"placements": grid_canvas.placements
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
		# Update selector
		for i in range(subset_selector.item_count):
			if subset_selector.get_item_metadata(i) == subset_id:
				subset_selector.select(i)
				break
		_populate_element_list()
	
	# Load layout
	grid_canvas.load_layout_data(data)
	
	current_layout_path = path
	is_dirty = false
	status_label.text = "Loaded: " + path.get_file()

func export_to_config(path: String) -> void:
	var data = grid_canvas.get_layout_data()
	var subset = subset_loader.current_subset
	
	# Generate path string
	var path_string = _generate_path_string(data.placements)
	
	# Generate schematic
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

func _generate_path_string(placements: Array) -> String:
	# TODO: Implement proper path generation with branching
	# For now, just list elements
	var parts = []
	for p in placements:
		var element = subset_loader.get_element(p.get("element", ""))
		var cmd = element.get("segment_type", element.get("id", "?"))
		parts.append(cmd)
	return ",".join(parts)

func _generate_schematic(data: Dictionary) -> Array:
	var grid_size = Vector2i(data.get("grid_size", [16, 12])[0], data.get("grid_size", [16, 12])[1])
	var schematic = []
	
	# Initialize empty grid
	for y in range(grid_size.y):
		var row = ""
		for x in range(grid_size.x):
			row += " "
		schematic.append(row)
	
	# Place elements
	for p in data.placements:
		var element = subset_loader.get_element(p.get("element", ""))
		var pos = Vector2i(p.get("position", [0, 0])[0], p.get("position", [0, 0])[1])
		var icon = element.get("icon", "?")
		
		if pos.y < schematic.size() and pos.x < schematic[pos.y].length():
			var row = schematic[pos.y]
			schematic[pos.y] = row.substr(0, pos.x) + icon + row.substr(pos.x + 1)
	
	return schematic

# ============ 3D Preview ============

func _setup_3d_preview() -> void:
	if not preview_viewport:
		return
	
	# Create camera pivot
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	preview_viewport.add_child(camera_pivot)
	
	# Reparent camera to pivot
	if preview_camera:
		preview_camera.get_parent().remove_child(preview_camera)
		camera_pivot.add_child(preview_camera)
		preview_camera.position = Vector3(0, 0, camera_distance)
		preview_camera.look_at(Vector3.ZERO)
	
	# Create grid
	_create_preview_grid()
	
	# Create axis indicator
	_create_axis_indicator()
	
	# Update camera position
	_update_camera_orbit()
	
	# Connect input - ensure container can receive mouse events
	preview_container.mouse_filter = Control.MOUSE_FILTER_STOP
	preview_container.gui_input.connect(_on_preview_input)

func _create_preview_grid() -> void:
	if not preview_viewport:
		return
	
	preview_grid = MeshInstance3D.new()
	preview_grid.name = "Grid"
	
	var im = ImmediateMesh.new()
	preview_grid.mesh = im
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.3, 0.35, 0.4, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	preview_grid.material_override = mat
	
	preview_viewport.add_child(preview_grid)
	_update_preview_grid()

func _create_axis_indicator() -> void:
	if not preview_viewport:
		return
	
	preview_axis = Node3D.new()
	preview_axis.name = "AxisIndicator"
	
	var axis_length = 0.5
	var arrow_size = 0.08
	
	# X axis (Red)
	_add_axis_arrow(preview_axis, Vector3.RIGHT, axis_length, arrow_size, Color.RED, "X")
	
	# Y axis (Green) 
	_add_axis_arrow(preview_axis, Vector3.UP, axis_length, arrow_size, Color.GREEN, "Y")
	
	# Z axis (Blue)
	_add_axis_arrow(preview_axis, Vector3.BACK, axis_length, arrow_size, Color.BLUE, "Z")
	
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
	preview_axis.add_child(origin)
	
	preview_viewport.add_child(preview_axis)

func _add_axis_arrow(parent: Node3D, direction: Vector3, length: float, arrow_size: float, color: Color, label_text: String) -> void:
	var axis_node = Node3D.new()
	
	# Shaft
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
	
	# Position shaft
	if direction == Vector3.UP:
		shaft.position = direction * length / 2
	elif direction == Vector3.RIGHT:
		shaft.rotation.z = -PI / 2
		shaft.position = direction * length / 2
	else:  # BACK (Z)
		shaft.rotation.x = PI / 2
		shaft.position = direction * length / 2
	
	axis_node.add_child(shaft)
	
	# Arrow cone
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
	
	# Label
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

func _get_orientation_plane() -> String:
	if subset_loader and not subset_loader.current_subset.is_empty():
		return subset_loader.current_subset.get("orientation", {}).get("plane", "XZ")
	return "XZ"

func _grid_to_3d(grid_x: float, grid_y: float, grid_size: float) -> Vector3:
	# Convert 2D grid coords to 3D based on orientation plane
	var plane = _get_orientation_plane()
	match plane:
		"XZ":  # Horizontal surface, Y up (top-down view)
			return Vector3(grid_x * grid_size, 0, grid_y * grid_size)
		"YZ":  # Vertical surface, X forward (side view - glass rack)
			return Vector3(0, grid_y * grid_size, grid_x * grid_size)
		"XY":  # Vertical surface, Z forward (front view - science table)
			return Vector3(grid_x * grid_size, grid_y * grid_size, 0)
		_:
			return Vector3(grid_x * grid_size, 0, grid_y * grid_size)

func _update_preview_grid() -> void:
	if not preview_grid or not preview_grid.mesh is ImmediateMesh:
		return
	
	var im = preview_grid.mesh as ImmediateMesh
	im.clear_surfaces()
	
	var grid_size = subset_loader.get_grid_size() if subset_loader else 1.0
	var grid_extent = grid_canvas.grid_dimensions if grid_canvas else Vector2i(16, 12)
	
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var line_color = Color(0.3, 0.35, 0.4, 0.6)
	var major_color = Color(0.4, 0.45, 0.5, 0.8)
	
	# Draw grid lines based on orientation
	for i in range(grid_extent.y + 1):
		var color = major_color if i % 4 == 0 else line_color
		im.surface_set_color(color)
		im.surface_add_vertex(_grid_to_3d(0, i, grid_size))
		im.surface_set_color(color)
		im.surface_add_vertex(_grid_to_3d(grid_extent.x, i, grid_size))
	
	for i in range(grid_extent.x + 1):
		var color = major_color if i % 4 == 0 else line_color
		im.surface_set_color(color)
		im.surface_add_vertex(_grid_to_3d(i, 0, grid_size))
		im.surface_set_color(color)
		im.surface_add_vertex(_grid_to_3d(i, grid_extent.y, grid_size))
	
	im.surface_end()

func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating_preview = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(1.0, camera_distance - 0.5)
			_update_camera_orbit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(20.0, camera_distance + 0.5)
			_update_camera_orbit()
	
	elif event is InputEventMouseMotion and is_rotating_preview:
		var mm = event as InputEventMouseMotion
		camera_rotation.y += mm.relative.x * 0.5
		camera_rotation.x = clamp(camera_rotation.x - mm.relative.y * 0.5, -89, 89)
		_update_camera_orbit()

func _update_camera_orbit() -> void:
	if not camera_pivot or not preview_camera:
		return
	
	# Calculate grid center for orbit target based on orientation
	var grid_size = subset_loader.get_grid_size() if subset_loader else 1.0
	var grid_extent = grid_canvas.grid_dimensions if grid_canvas else Vector2i(16, 12)
	var center = _grid_to_3d(grid_extent.x / 2.0, grid_extent.y / 2.0, grid_size)
	
	camera_pivot.position = center
	camera_pivot.rotation_degrees = Vector3(camera_rotation.x, camera_rotation.y, 0)
	preview_camera.position = Vector3(0, 0, camera_distance)
	preview_camera.look_at(camera_pivot.global_position)

func _update_3d_preview(_arg = null) -> void:
	if not preview_root:
		return
	
	# Clear existing preview
	for child in preview_root.get_children():
		child.queue_free()
	
	# Get grid scale from subset
	var grid_size = subset_loader.get_grid_size()
	
	# Rebuild from placements
	for placement in grid_canvas.placements:
		var element = subset_loader.get_element(placement.get("element", ""))
		if element.is_empty():
			continue
		
		var node_3d = _create_element_3d(element, placement, grid_size)
		if node_3d:
			preview_root.add_child(node_3d)
	
	# Fit camera to content
	_fit_camera_to_preview()

func _create_element_3d(element: Dictionary, placement: Dictionary, grid_size: float) -> Node3D:
	var node: Node3D
	
	# Position from grid coords
	var pos = placement.get("position", [0, 0])
	var elem_size = element.get("size", [1, 1])
	var rotation = placement.get("rotation", 0)
	
	# Check for procedural generation (glass_rack)
	var segment_type = element.get("segment_type", "")
	if not segment_type.is_empty() and subset_loader.current_subset_id == "glass_rack":
		node = _create_glass_segment(element, placement, grid_size)
	
	# Try to load actual scene if specified
	if not node:
		var scene_path = element.get("scene", "")
		if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			if scene:
				node = scene.instantiate()
				node.name = element.get("id", "element")
				
				# Apply scale from element definition
				var scale_arr = element.get("scene_scale", [1, 1, 1])
				node.scale = Vector3(scale_arr[0], scale_arr[1], scale_arr[2])
				
				# Apply rotation from element definition
				var rot_y = element.get("rotation_y", 0)
				node.rotation_degrees.y = rot_y
				
				# Apply placement rotation
				node.rotation_degrees.y += rotation
	
	# Fallback to placeholder if no scene
	if not node:
		node = _create_placeholder_3d(element, grid_size)
	
	# Position: grid cell to 3D based on orientation plane
	var scene_path = element.get("scene", "")
	if not scene_path.is_empty() or not segment_type.is_empty():
		# Scenes/procedural: use cell origin (pivot at origin)
		node.position = _grid_to_3d(pos[0], pos[1], grid_size)
	else:
		# Placeholders: use cell center
		var center_x = pos[0] + elem_size[0] / 2.0
		var center_y = pos[1] + elem_size[1] / 2.0
		node.position = _grid_to_3d(center_x, center_y, grid_size)
	
	# Apply placement rotation
	if rotation != 0:
		node.rotation_degrees.y += rotation
	
	return node

func _create_glass_segment(element: Dictionary, placement: Dictionary, grid_size: float) -> Node3D:
	## Creates a 3D glass tube element for the Glass Rack subset
	## 
	## Glass Rack uses YZ plane orientation:
	##   - Y axis = vertical (up/down) = grid height
	##   - Z axis = horizontal (left/right) = grid width  
	##   - X axis = depth (toward viewer) - elements stay flat
	##
	## Element sizing:
	##   - width = elem_size[0] * grid_size (maps to Z)
	##   - height = elem_size[1] * grid_size (maps to Y)
	##
	## All tubes are generated procedurally with smooth normals using SurfaceTool
	
	var segment_type = element.get("segment_type", "")
	var elem_size = element.get("size", [1, 1])
	var tube_radius = subset_loader.current_subset.get("defaults", {}).get("tube_radius", 0.015)
	
	# Calculate actual 3D dimensions from grid
	var width = elem_size[0] * grid_size   # -> Z axis
	var height = elem_size[1] * grid_size  # -> Y axis
	
	# Glass material - transparent with subtle refraction look
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
			node.position.z = width / 2  # Center in Z (horizontal for YZ plane)
		"corner":
			node = _create_glass_elbow_smooth(width, height, tube_radius, glass_mat)
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
			node = _create_glass_cap_smooth(tube_radius, glass_mat)
			node.position = Vector3(0, height, width / 2)
		"drip":
			node = _create_glass_drip_smooth(tube_radius, glass_mat)
			node.position.z = width / 2
		_:
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

func _create_glass_elbow_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	## 90° Corner/Elbow in YZ plane (2×2 grid element)
	## Enters from bottom (Y=0), exits to right (Z=width)
	## Bend radius fills the 2×2 space
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var bend_radius = min(width, height) - radius  # Fit within grid
	mesh_instance.mesh = _generate_elbow_mesh_yz(bend_radius, radius, 16, 12)
	mesh_instance.material_override = mat
	# Position at bottom-left, curve goes up then right
	node.add_child(mesh_instance)
	return node

func _generate_elbow_mesh_yz(bend_radius: float, tube_radius: float, tube_segs: int, bend_segs: int) -> ArrayMesh:
	## 90° elbow mesh in YZ plane
	## Starts at origin going +Y, curves to exit going +Z
	## Center of bend arc is at (0, 0, bend_radius)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for b in range(bend_segs + 1):
		var bend_angle = (float(b) / bend_segs) * (PI / 2)
		# Curve center traces arc: Y = r*sin(a), Z = r*(1-cos(a))
		var center = Vector3(0, bend_radius * sin(bend_angle), bend_radius * (1.0 - cos(bend_angle)))
		# Tangent is derivative of position
		var tangent = Vector3(0, cos(bend_angle), sin(bend_angle)).normalized()
		# Binormal perpendicular to YZ plane
		var binormal = Vector3(1, 0, 0)
		var normal = binormal.cross(tangent).normalized()
		
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, float(b) / bend_segs))
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
	## S-bend in YZ plane (2x2 grid element)
	## Enters from bottom-left quadrant, exits to top-right quadrant
	## The S-curve shifts from Z=0 to Z=width while going from Y=0 to Y=height
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _generate_sbend_mesh_yz(height, width, radius, 16, 24)
	mesh_instance.material_override = mat
	# No offset needed - mesh starts at origin, ends at (0, height, width)
	node.add_child(mesh_instance)
	return node

func _generate_sbend_mesh_yz(height: float, width: float, tube_radius: float, tube_segs: int, len_segs: int) -> ArrayMesh:
	## S-bend mesh in YZ plane
	## Smooth S-curve from (0, 0, 0) to (0, height, width)
	## Uses cosine interpolation for smooth acceleration/deceleration
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for l in range(len_segs + 1):
		var t = float(l) / len_segs
		# Y goes linearly from 0 to height
		var y = t * height
		# Z follows S-curve: starts slow, speeds up in middle, slows at end
		var z = width * (0.5 - 0.5 * cos(PI * t))
		var center = Vector3(0, y, z)
		
		# Calculate tangent for tube orientation
		var dy = height / len_segs
		var dz = width * 0.5 * PI * sin(PI * t) / len_segs
		var tangent = Vector3(0, dy, dz).normalized()
		var binormal = Vector3(1, 0, 0)  # Perpendicular to YZ plane
		var normal = binormal.cross(tangent).normalized()
		
		# Generate tube ring
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var ring_offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(ring_offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + ring_offset)
	
	# Generate triangle indices
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
	## U-bend in YZ plane (2×2 grid element)
	## Shape: ∪ - two openings at top, semicircle curve at bottom
	##   Entry: (Y=height, Z=tube_radius) going down
	##   Exit:  (Y=height, Z=width-tube_radius) going up
	##   Lowest: Y ≈ tube_radius
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var bend_radius = (width / 2) - radius
	mesh_instance.mesh = _generate_ubend_mesh_yz(bend_radius, height, radius, 16, 16)
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(0, height, width / 2)
	node.add_child(mesh_instance)
	return node

func _generate_ubend_mesh_yz(bend_radius: float, height: float, tube_radius: float, tube_segs: int, bend_segs: int) -> ArrayMesh:
	## U-bend mesh: 180° arc in YZ plane, shaped like ∪
	## Arc center at origin, opens upward (+Y)
	## Starts at (0, 0, -bend_radius), curves down then up to (0, 0, +bend_radius)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for b in range(bend_segs + 1):
		var bend_angle = (float(b) / bend_segs) * PI  # 0 to PI
		# Semicircle in YZ: Y goes down then up, Z goes from -r to +r
		var center = Vector3(
			0,
			-bend_radius * sin(bend_angle),  # Y: 0 -> -r -> 0 (dip down)
			-bend_radius * cos(bend_angle)   # Z: -r -> 0 -> +r
		)
		
		# Tangent along the curve
		var tangent = Vector3(
			0,
			-bend_radius * cos(bend_angle),
			bend_radius * sin(bend_angle)
		).normalized()
		
		var binormal = Vector3(1, 0, 0)
		var normal = binormal.cross(tangent).normalized()
		
		for s in range(tube_segs + 1):
			var ring_angle = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ring_angle) + binormal * sin(ring_angle)) * tube_radius
			st.set_normal(offset.normalized())
			st.set_uv(Vector2(float(s) / tube_segs, float(b) / bend_segs))
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
	# T-junction in YZ plane: vertical tube with horizontal branch
	var node = Node3D.new()
	var center_z = width / 2
	var center_y = height / 2
	
	# Vertical tube (full height)
	var vert = _create_glass_tube_smooth(height, radius, mat)
	vert.position.z = center_z
	node.add_child(vert)
	
	# Horizontal branch in Z direction
	var horiz = MeshInstance3D.new()
	horiz.mesh = _generate_tube_mesh(width / 2, radius, 16, 2)
	horiz.material_override = mat
	horiz.rotation.x = PI / 2  # Rotate to lie along Z
	horiz.position = Vector3(0, center_y, center_z)
	node.add_child(horiz)
	
	# Junction sphere
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
	# Y-splitter in YZ plane
	var node = Node3D.new()
	var center_z = width / 2
	var junction_y = height * 0.35
	
	# Bottom stem
	var stem = _create_glass_tube_smooth(junction_y, radius, mat)
	stem.position.z = center_z
	node.add_child(stem)
	
	# Two angled branches spreading in Z
	var branch_length = height * 0.55
	var spread = PI / 5  # 36°
	for side in [-1, 1]:
		var branch = MeshInstance3D.new()
		branch.mesh = _generate_tube_mesh(branch_length, radius, 16, 2)
		branch.material_override = mat
		branch.position = Vector3(0, junction_y, center_z)
		branch.rotation.x = side * spread  # Spread in YZ plane
		node.add_child(branch)
	
	# Junction sphere
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
	# Cross junction in YZ plane
	var node = Node3D.new()
	var center = Vector3(0, height / 2, width / 2)
	
	# Vertical tube
	var vert = _create_glass_tube_smooth(height, radius, mat)
	vert.position.z = center.z
	node.add_child(vert)
	
	# Horizontal tube along Z
	var horiz = MeshInstance3D.new()
	horiz.mesh = _generate_tube_mesh(width, radius, 16, 2)
	horiz.material_override = mat
	horiz.rotation.x = PI / 2  # Lie along Z
	horiz.position = center
	node.add_child(horiz)
	
	# Junction sphere
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
	# Spiral condenser in YZ plane (coils around Y axis)
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
	# Condenser in YZ plane
	var node = Node3D.new()
	
	# Inner tube (full height)
	var inner = _create_glass_tube_smooth(height, radius, mat)
	inner.position.z = width / 2
	node.add_child(inner)
	
	# Outer jacket (wider, shorter)
	var jacket = _create_glass_tube_smooth(height * 0.7, radius * 2.5, mat)
	jacket.position = Vector3(0, height * 0.15, width / 2)
	node.add_child(jacket)
	
	return node

func _create_glass_flask_smooth(width: float, height: float, radius: float, mat: Material) -> Node3D:
	# Flask in YZ plane
	var node = Node3D.new()
	
	# Bulb at bottom
	var bulb = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = width * 0.4
	sphere_mesh.height = width * 0.8
	bulb.mesh = sphere_mesh
	bulb.material_override = mat
	bulb.position = Vector3(0, width * 0.4, width / 2)
	node.add_child(bulb)
	
	# Neck going up
	var neck_height = height - width * 0.7
	var neck = _create_glass_tube_smooth(neck_height, radius, mat)
	neck.position = Vector3(0, width * 0.7, width / 2)
	node.add_child(neck)
	
	return node

func _create_glass_beaker_smooth(width: float, height: float, mat: Material) -> Node3D:
	# Beaker in YZ plane
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

func _create_glass_cap_smooth(radius: float, mat: Material) -> Node3D:
	# Cap - hemisphere pointing down
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	
	var sphere = SphereMesh.new()
	sphere.radius = radius * 1.3
	sphere.height = radius * 2.6
	sphere.is_hemisphere = true
	mesh_instance.mesh = sphere
	mesh_instance.material_override = mat
	mesh_instance.rotation.x = PI
	
	node.add_child(mesh_instance)
	return node

func _create_glass_drip_smooth(radius: float, mat: Material) -> Node3D:
	# Drip tip - tapered cone pointing down
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	
	var cone = CylinderMesh.new()
	cone.top_radius = radius
	cone.bottom_radius = radius * 0.3
	cone.height = radius * 5
	mesh_instance.mesh = cone
	mesh_instance.material_override = mat
	
	node.add_child(mesh_instance)
	return node

func _create_placeholder_3d(element: Dictionary, grid_size: float) -> Node3D:
	var node = Node3D.new()
	node.name = element.get("id", "element")
	
	var elem_size = element.get("size", [1, 1])
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	
	var mesh: Mesh
	var category = element.get("category", "")
	
	# Different shapes for different categories
	match category:
		"sources":
			mesh = CylinderMesh.new()
			mesh.top_radius = elem_size[0] * grid_size * 0.4
			mesh.bottom_radius = elem_size[0] * grid_size * 0.4
			mesh.height = 0.3
		"filters":
			mesh = BoxMesh.new()
			mesh.size = Vector3(elem_size[0] * grid_size * 0.8, 0.25, elem_size[1] * grid_size * 0.8)
		"effects":
			mesh = SphereMesh.new()
			mesh.radius = elem_size[0] * grid_size * 0.35
			mesh.height = elem_size[0] * grid_size * 0.7
		"modulators":
			mesh = PrismMesh.new()
			mesh.size = Vector3(elem_size[0] * grid_size * 0.7, 0.3, elem_size[1] * grid_size * 0.7)
		"outputs":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0
			mesh.bottom_radius = elem_size[0] * grid_size * 0.4
			mesh.height = 0.4
		_:
			mesh = BoxMesh.new()
			mesh.size = Vector3(elem_size[0] * grid_size * 0.8, 0.2, elem_size[1] * grid_size * 0.8)
	
	mesh_instance.mesh = mesh
	
	# Material with category color
	var mat = StandardMaterial3D.new()
	var cat_color = _get_category_color(element.get("category", ""))
	mat.albedo_color = cat_color
	mat.emission_enabled = true
	mat.emission = cat_color * 0.3
	mesh_instance.material_override = mat
	
	node.add_child(mesh_instance)
	
	# Add label
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
		"sources": return Color(0.3, 0.69, 0.31)      # Green
		"filters": return Color(0.13, 0.59, 0.95)     # Blue
		"effects": return Color(1.0, 0.6, 0.0)        # Orange
		"modulators": return Color(0.61, 0.15, 0.69)  # Purple
		"outputs": return Color(0.96, 0.26, 0.21)     # Red
		_: return Color(0.5, 0.5, 0.5)

func _fit_camera_to_preview() -> void:
	if not preview_camera:
		return
	
	# Calculate bounds from placements or use grid size
	var grid_size = subset_loader.get_grid_size() if subset_loader else 1.0
	var max_extent = max(grid_canvas.grid_dimensions.x, grid_canvas.grid_dimensions.y) * grid_size
	
	if not grid_canvas.placements.is_empty():
		var max_x = 0.0
		var max_z = 0.0
		for placement in grid_canvas.placements:
			var pos = placement.get("position", [0, 0])
			var element = subset_loader.get_element(placement.get("element", ""))
			var elem_size = element.get("size", [1, 1])
			max_x = max(max_x, (pos[0] + elem_size[0]) * grid_size)
			max_z = max(max_z, (pos[1] + elem_size[1]) * grid_size)
		max_extent = max(max_x, max_z)
	
	# Adjust camera distance to fit content
	camera_distance = max_extent * 1.2 + 1.0
	_update_camera_orbit()
