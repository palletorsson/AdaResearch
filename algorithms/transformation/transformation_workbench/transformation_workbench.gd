extends Node3D
class_name TransformationWorkbench
## Interactive transformation learning tool
## Grabbable object that shows live matrix updates, ghost position, and transformation vectors

enum Mode { TRANSLATE, ROTATE, SCALE }

@export var current_mode: Mode = Mode.TRANSLATE
@export var show_matrix: bool = true
@export var show_ghost: bool = true
@export var show_vectors: bool = true
@export var snap_rotation_to_90: bool = true

# References
var grabbable_object: Node3D
var ghost_object: MeshInstance3D
var matrix_display: Node3D
var vector_display: Node3D
var mode_buttons: Node3D

# Matrix cell labels (4x4 grid of Label3D)
var matrix_labels: Array[Label3D] = []

# Original transform when grabbed
var original_transform: Transform3D
var is_grabbed: bool = false

# Colors
const COLOR_TRANSLATE = Color(0.2, 0.8, 0.2)  # Green
const COLOR_ROTATE = Color(0.8, 0.2, 0.2)     # Red  
const COLOR_SCALE = Color(0.2, 0.2, 0.8)      # Blue
const COLOR_INACTIVE = Color(0.3, 0.3, 0.3)   # Gray
const COLOR_HIGHLIGHT = Color(1.0, 0.9, 0.2)  # Yellow

func _ready():
	create_grabbable_object()
	create_ghost()
	create_matrix_display()
	create_vector_display()
	create_mode_buttons()
	update_mode_visuals()

func create_grabbable_object():
	# The main object to manipulate
	grabbable_object = Node3D.new()
	grabbable_object.name = "GrabbableObject"
	add_child(grabbable_object)
	
	# Visual mesh - a distinctive cube with edges
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	mesh_instance.mesh = box
	
	# Grid shader material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.9)
	mat.emission_enabled = true
	mat.emission = get_mode_color()
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat
	grabbable_object.add_child(mesh_instance)
	
	# Add XRToolsPickable for VR grabbing
	var pickable_script = load("res://addons/godot-xr-tools/objects/pickable.gd")
	if pickable_script:
		grabbable_object.set_script(pickable_script)
		grabbable_object.set("enabled", true)
		
		# Connect signals
		if grabbable_object.has_signal("picked_up"):
			grabbable_object.picked_up.connect(_on_picked_up)
		if grabbable_object.has_signal("dropped"):
			grabbable_object.dropped.connect(_on_dropped)
	
	# Collision shape for picking
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.35, 0.35, 0.35)
	collision.shape = shape
	grabbable_object.add_child(collision)
	
	# Axes indicator on the object
	create_local_axes(grabbable_object)

func create_local_axes(parent: Node3D):
	# Show XYZ axes on the object
	var axes = Node3D.new()
	axes.name = "LocalAxes"
	parent.add_child(axes)
	
	var axis_length = 0.25
	var axis_thickness = 0.01
	
	# X axis - Red
	var x_axis = create_axis_mesh(Vector3(axis_length, axis_thickness, axis_thickness), Color.RED)
	x_axis.position = Vector3(axis_length / 2, 0, 0)
	axes.add_child(x_axis)
	
	# Y axis - Green
	var y_axis = create_axis_mesh(Vector3(axis_thickness, axis_length, axis_thickness), Color.GREEN)
	y_axis.position = Vector3(0, axis_length / 2, 0)
	axes.add_child(y_axis)
	
	# Z axis - Blue
	var z_axis = create_axis_mesh(Vector3(axis_thickness, axis_thickness, axis_length), Color.BLUE)
	z_axis.position = Vector3(0, 0, axis_length / 2)
	axes.add_child(z_axis)

func create_axis_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	mesh_instance.material_override = mat
	
	return mesh_instance

func create_ghost():
	# Wireframe ghost showing original position
	ghost_object = MeshInstance3D.new()
	ghost_object.name = "Ghost"
	add_child(ghost_object)
	
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	ghost_object.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_object.material_override = mat
	
	ghost_object.visible = show_ghost

func create_matrix_display():
	# 4x4 matrix display floating nearby
	matrix_display = Node3D.new()
	matrix_display.name = "MatrixDisplay"
	matrix_display.position = Vector3(0.6, 0.3, 0)
	add_child(matrix_display)
	
	# Background panel
	var bg = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	bg.mesh = quad
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.05, 0.05, 0.1, 0.8)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bg.material_override = bg_mat
	bg.position.z = 0.01
	matrix_display.add_child(bg)
	
	# Title
	var title = Label3D.new()
	title.text = "Transform Matrix"
	title.font_size = 32
	title.position = Vector3(0, 0.28, 0)
	title.pixel_size = 0.001
	matrix_display.add_child(title)
	
	# Create 4x4 grid of labels
	var cell_size = 0.1
	var start_x = -0.15
	var start_y = 0.15
	
	for row in range(4):
		for col in range(4):
			var label = Label3D.new()
			label.name = "Cell_%d_%d" % [row, col]
			label.font_size = 24
			label.pixel_size = 0.001
			label.position = Vector3(
				start_x + col * cell_size,
				start_y - row * cell_size,
				0
			)
			label.modulate = COLOR_INACTIVE
			matrix_display.add_child(label)
			matrix_labels.append(label)
	
	matrix_display.visible = show_matrix

func create_vector_display():
	# Arrow showing translation vector or rotation axis
	vector_display = Node3D.new()
	vector_display.name = "VectorDisplay"
	add_child(vector_display)
	
	# Translation arrow (will be updated dynamically)
	var arrow = MeshInstance3D.new()
	arrow.name = "Arrow"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = 0.1
	arrow.mesh = cylinder
	
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = COLOR_TRANSLATE
	arrow_mat.emission_enabled = true
	arrow_mat.emission = COLOR_TRANSLATE
	arrow.material_override = arrow_mat
	vector_display.add_child(arrow)
	
	# Vector label
	var vec_label = Label3D.new()
	vec_label.name = "VectorLabel"
	vec_label.font_size = 28
	vec_label.pixel_size = 0.001
	vec_label.position = Vector3(0.1, 0.1, 0)
	vector_display.add_child(vec_label)
	
	vector_display.visible = show_vectors

func create_mode_buttons():
	# Three buttons to switch modes
	mode_buttons = Node3D.new()
	mode_buttons.name = "ModeButtons"
	mode_buttons.position = Vector3(-0.5, 0.2, 0)
	add_child(mode_buttons)
	
	var button_names = ["T", "R", "S"]
	var button_colors = [COLOR_TRANSLATE, COLOR_ROTATE, COLOR_SCALE]
	
	for i in range(3):
		var button = create_mode_button(button_names[i], button_colors[i], i)
		button.position = Vector3(0, -i * 0.12, 0)
		mode_buttons.add_child(button)

func create_mode_button(label_text: String, color: Color, mode_index: int) -> Node3D:
	var button = Node3D.new()
	button.name = "Button_" + label_text
	
	# Button mesh
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.03)
	mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3 if mode_index != current_mode else 1.0
	mesh.material_override = mat
	mesh.name = "Mesh"
	button.add_child(mesh)
	
	# Label
	var label = Label3D.new()
	label.text = label_text
	label.font_size = 48
	label.pixel_size = 0.001
	label.position.z = 0.02
	button.add_child(label)
	
	# Collision for interaction
	var area = Area3D.new()
	area.name = "Area"
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.1, 0.1, 0.05)
	collision.shape = shape
	area.add_child(collision)
	button.add_child(area)
	
	# Store mode index
	area.set_meta("mode_index", mode_index)
	area.body_entered.connect(_on_button_touched.bind(mode_index))
	
	return button

func _on_button_touched(body: Node3D, mode_index: int):
	if body.is_in_group("hand") or body.name.contains("Hand"):
		set_mode(mode_index)

func set_mode(mode_index: int):
	current_mode = mode_index as Mode
	update_mode_visuals()

func update_mode_visuals():
	# Update button highlights
	for i in range(mode_buttons.get_child_count()):
		var button = mode_buttons.get_child(i)
		var mesh = button.get_node_or_null("Mesh")
		if mesh and mesh.material_override:
			mesh.material_override.emission_energy_multiplier = 1.0 if i == current_mode else 0.3
	
	# Update grabbable object color
	var obj_mesh = grabbable_object.get_node_or_null("Mesh")
	if obj_mesh and obj_mesh.material_override:
		obj_mesh.material_override.emission = get_mode_color()
	
	# Update vector display color
	var arrow = vector_display.get_node_or_null("Arrow")
	if arrow and arrow.material_override:
		arrow.material_override.albedo_color = get_mode_color()
		arrow.material_override.emission = get_mode_color()

func get_mode_color() -> Color:
	match current_mode:
		Mode.TRANSLATE: return COLOR_TRANSLATE
		Mode.ROTATE: return COLOR_ROTATE
		Mode.SCALE: return COLOR_SCALE
	return Color.WHITE

func _on_picked_up(pickable):
	is_grabbed = true
	original_transform = grabbable_object.global_transform
	ghost_object.global_transform = original_transform
	ghost_object.visible = show_ghost

func _on_dropped(pickable):
	is_grabbed = false

func _process(_delta):
	update_matrix_display()
	update_vector_display()
	
	# Snap rotation to 90° if enabled
	if snap_rotation_to_90 and not is_grabbed and current_mode == Mode.ROTATE:
		snap_to_90_degrees()

func snap_to_90_degrees():
	var euler = grabbable_object.rotation_degrees
	grabbable_object.rotation_degrees = Vector3(
		snappedf(euler.x, 90.0),
		snappedf(euler.y, 90.0),
		snappedf(euler.z, 90.0)
	)

func update_matrix_display():
	if not show_matrix or matrix_labels.is_empty():
		return
	
	var t = grabbable_object.transform
	var basis = t.basis
	var origin = t.origin
	
	# Build 4x4 matrix values
	var matrix_values = [
		[basis.x.x, basis.y.x, basis.z.x, origin.x],
		[basis.x.y, basis.y.y, basis.z.y, origin.y],
		[basis.x.z, basis.y.z, basis.z.z, origin.z],
		[0.0, 0.0, 0.0, 1.0]
	]
	
	# Determine which cells to highlight based on mode
	var highlight_cells = get_highlight_cells()
	
	for row in range(4):
		for col in range(4):
			var idx = row * 4 + col
			var label = matrix_labels[idx]
			var value = matrix_values[row][col]
			
			# Format the number
			if abs(value) < 0.001:
				label.text = "0"
			elif abs(value - 1.0) < 0.001:
				label.text = "1"
			elif abs(value + 1.0) < 0.001:
				label.text = "-1"
			else:
				label.text = "%.2f" % value
			
			# Highlight relevant cells
			var cell_key = Vector2i(row, col)
			if cell_key in highlight_cells:
				label.modulate = COLOR_HIGHLIGHT
			else:
				label.modulate = COLOR_INACTIVE

func get_highlight_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	match current_mode:
		Mode.TRANSLATE:
			# Translation is in the last column (indices 3, 7, 11)
			cells = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
		Mode.ROTATE:
			# Rotation is in the 3x3 upper-left (indices 0-2 in first 3 rows)
			for row in range(3):
				for col in range(3):
					cells.append(Vector2i(row, col))
		Mode.SCALE:
			# Scale is on the diagonal (indices 0, 5, 10)
			cells = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	
	return cells

func update_vector_display():
	if not show_vectors:
		return
	
	var vec_label = vector_display.get_node_or_null("VectorLabel")
	var arrow = vector_display.get_node_or_null("Arrow")
	
	match current_mode:
		Mode.TRANSLATE:
			var translation = grabbable_object.position
			if vec_label:
				vec_label.text = "T = (%.2f, %.2f, %.2f)" % [translation.x, translation.y, translation.z]
			
			# Update arrow to show translation vector
			if arrow and translation.length() > 0.01:
				arrow.visible = true
				var length = translation.length()
				arrow.scale = Vector3(1, length * 5, 1)
				arrow.position = translation / 2
				arrow.look_at(translation, Vector3.UP)
				arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
			elif arrow:
				arrow.visible = false
				
		Mode.ROTATE:
			var euler = grabbable_object.rotation_degrees
			if vec_label:
				vec_label.text = "R = (%.0f°, %.0f°, %.0f°)" % [euler.x, euler.y, euler.z]
			
			# Show rotation as coordinate swap for 90° rotations
			if snap_rotation_to_90:
				var swap_text = get_coordinate_swap_text(euler)
				if swap_text != "" and vec_label:
					vec_label.text += "\n" + swap_text
			
			if arrow:
				arrow.visible = false
				
		Mode.SCALE:
			var scale_vec = grabbable_object.scale
			if vec_label:
				vec_label.text = "S = (%.2f, %.2f, %.2f)" % [scale_vec.x, scale_vec.y, scale_vec.z]
			
			if arrow:
				arrow.visible = false

func get_coordinate_swap_text(euler: Vector3) -> String:
	# Show coordinate swaps for 90° rotations (without trig!)
	var x_rot = int(euler.x) % 360
	var y_rot = int(euler.y) % 360
	var z_rot = int(euler.z) % 360
	
	# Simplified: show swap for Z rotation (most common)
	match z_rot:
		90, -270:
			return "(x,y) → (-y,x)"
		180, -180:
			return "(x,y) → (-x,-y)"
		270, -90:
			return "(x,y) → (y,-x)"
		_:
			return ""
