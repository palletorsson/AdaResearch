extends Node3D
class_name TransformationWorkbench
## Interactive transformation learning tool using XRTools interactables
## Grabbable object shows live matrix updates, ghost position, and transformation vectors

enum Mode { TRANSLATE, ROTATE, SCALE }

@export var current_mode: Mode = Mode.TRANSLATE
@export var show_matrix: bool = true
@export var show_ghost: bool = true
@export var show_vectors: bool = true
@export var snap_rotation_to_90: bool = true

# Node references - set in _ready from scene tree
@onready var grabbable_object: RigidBody3D = $GrabbableObject
@onready var ghost_object: MeshInstance3D = $Ghost
@onready var matrix_display: Node3D = $MatrixDisplay
@onready var vector_display: Node3D = $VectorDisplay
@onready var mode_buttons: Node3D = $ModeButtons
@onready var cube_mesh: MeshInstance3D = $GrabbableObject/CubeMesh
@onready var vector_label: Label3D = $VectorDisplay/VectorLabel

# Matrix cell labels (4x4 grid of Label3D) - created at runtime
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

func _ready() -> void:
	# Create matrix labels dynamically
	create_matrix_labels()
	
	# Connect button signals
	connect_mode_buttons()
	
	# Initial state
	update_mode_visuals()
	ghost_object.visible = false
	matrix_display.visible = show_matrix
	vector_display.visible = show_vectors

func create_matrix_labels() -> void:
	# Create 4x4 grid of labels for matrix display
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

func connect_mode_buttons() -> void:
	# Connect the push button signals
	var button_t = mode_buttons.get_node_or_null("ButtonT/InteractableAreaButton")
	var button_r = mode_buttons.get_node_or_null("ButtonR/InteractableAreaButton")
	var button_s = mode_buttons.get_node_or_null("ButtonS/InteractableAreaButton")
	
	if button_t and button_t.has_signal("button_pressed"):
		button_t.button_pressed.connect(_on_mode_translate)
	if button_r and button_r.has_signal("button_pressed"):
		button_r.button_pressed.connect(_on_mode_rotate)
	if button_s and button_s.has_signal("button_pressed"):
		button_s.button_pressed.connect(_on_mode_scale)

func _on_mode_translate() -> void:
	set_mode(Mode.TRANSLATE)

func _on_mode_rotate() -> void:
	set_mode(Mode.ROTATE)

func _on_mode_scale() -> void:
	set_mode(Mode.SCALE)

func set_mode(mode: Mode) -> void:
	current_mode = mode
	update_mode_visuals()

func update_mode_visuals() -> void:
	# Update grabbable object emission color
	if cube_mesh and cube_mesh.material_override:
		cube_mesh.material_override.emission = get_mode_color()

func get_mode_color() -> Color:
	match current_mode:
		Mode.TRANSLATE: return COLOR_TRANSLATE
		Mode.ROTATE: return COLOR_ROTATE
		Mode.SCALE: return COLOR_SCALE
	return Color.WHITE

func _on_picked_up(_pickable) -> void:
	is_grabbed = true
	original_transform = grabbable_object.global_transform
	ghost_object.global_transform = original_transform
	ghost_object.visible = show_ghost

func _on_dropped(_pickable) -> void:
	is_grabbed = false
	
	# Snap rotation if enabled
	if snap_rotation_to_90 and current_mode == Mode.ROTATE:
		snap_to_90_degrees()

func snap_to_90_degrees() -> void:
	var euler = grabbable_object.rotation_degrees
	grabbable_object.rotation_degrees = Vector3(
		snappedf(euler.x, 90.0),
		snappedf(euler.y, 90.0),
		snappedf(euler.z, 90.0)
	)

func _process(_delta):
	update_matrix_display()
	update_vector_display()

func update_matrix_display() -> void:
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
			if idx >= matrix_labels.size():
				continue
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
			# Translation is in the last column
			cells = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
		Mode.ROTATE:
			# Rotation is in the 3x3 upper-left
			for row in range(3):
				for col in range(3):
					cells.append(Vector2i(row, col))
		Mode.SCALE:
			# Scale is on the diagonal
			cells = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	
	return cells

func update_vector_display() -> void:
	if not show_vectors or not vector_label:
		return
	
	match current_mode:
		Mode.TRANSLATE:
			var translation = grabbable_object.position
			vector_label.text = "T = (%.2f, %.2f, %.2f)" % [translation.x, translation.y, translation.z]
				
		Mode.ROTATE:
			var euler = grabbable_object.rotation_degrees
			vector_label.text = "R = (%.0fÂ°, %.0fÂ°, %.0fÂ°)" % [euler.x, euler.y, euler.z]
			
			# Show coordinate swap for 90Â° rotations
			if snap_rotation_to_90:
				var swap_text = get_coordinate_swap_text(euler)
				if swap_text != "":
					vector_label.text += "\n" + swap_text
				
		Mode.SCALE:
			var scale_vec = grabbable_object.scale
			vector_label.text = "S = (%.2f, %.2f, %.2f)" % [scale_vec.x, scale_vec.y, scale_vec.z]

func get_coordinate_swap_text(euler: Vector3) -> String:
	# Show coordinate swaps for 90Â° rotations
	var z_rot = int(euler.z) % 360
	if z_rot < 0:
		z_rot += 360
	
	match z_rot:
		90:
			return "(x,y) â†’ (-y,x)"
		180:
			return "(x,y) â†’ (-x,-y)"
		270:
			return "(x,y) â†’ (y,-x)"
		_:
			return ""

# Grid artifact configuration API
func apply_grid_config(config: Dictionary) -> void:
	# @onready does not assign until the node enters the tree, and config can arrive
	# before that (the museum stamps it on a detached root). Both children exist from
	# instantiate(), so resolve them by hand rather than trusting @onready to have run.
	if matrix_display == null:
		matrix_display = get_node_or_null("MatrixDisplay")
	if vector_display == null:
		vector_display = get_node_or_null("VectorDisplay")
	if config.has("mode"):
		var mode_str = str(config["mode"]).to_lower()
		match mode_str:
			"translate", "t", "0": current_mode = Mode.TRANSLATE
			"rotate", "r", "1": current_mode = Mode.ROTATE
			"scale", "s", "2": current_mode = Mode.SCALE
	
	if config.has("show_matrix"):
		show_matrix = str(config["show_matrix"]).to_lower() == "true"
	if config.has("show_ghost"):
		show_ghost = str(config["show_ghost"]).to_lower() == "true"
	if config.has("show_vectors"):
		show_vectors = str(config["show_vectors"]).to_lower() == "true"
	if config.has("snap_90"):
		snap_rotation_to_90 = str(config["snap_90"]).to_lower() == "true"

	update_mode_visuals()
	if matrix_display:
		matrix_display.visible = show_matrix
	if vector_display:
		vector_display.visible = show_vectors

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

