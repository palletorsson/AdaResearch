# vector_translation_demo.gd
## Demonstrates vector translation in 3D space.
## The user controls a direction (X/Y/Z sliders) and magnitude (length slider).
## A cube is translated along the resulting vector, with an arrow showing direction
## and ghost trail instances visualizing the translation path via MultiMesh instancing.
extends Node3D

class_name VectorTranslationDemo

## Path to the magnitude slider node
@export var magnitude_slider_path: NodePath = "SliderPanel/MagnitudeSlider"
## Path to the X-direction slider node
@export var dir_x_slider_path: NodePath = "SliderPanel/DirXSlider"
## Path to the Y-direction slider node
@export var dir_y_slider_path: NodePath = "SliderPanel/DirYSlider"
## Path to the Z-direction slider node
@export var dir_z_slider_path: NodePath = "SliderPanel/DirZSlider"

## The cube being translated
@onready var cube: Node3D = $TranslationCube
@onready var arrow: Node3D = $VectorArrow
@onready var origin_marker: Node3D = $OriginMarker

## Slider references
@onready var magnitude_slider = get_node_or_null(magnitude_slider_path)
@onready var dir_x_slider = get_node_or_null(dir_x_slider_path)
@onready var dir_y_slider = get_node_or_null(dir_y_slider_path)
@onready var dir_z_slider = get_node_or_null(dir_z_slider_path)

## Vector display
@onready var vector_label: Label3D = $VectorLabel

## Maximum length the translation vector can reach
@export_range(0.1, 20.0, 0.1) var max_magnitude: float = 3.0
## Whether to show ghost trail instances along the vector path
@export var show_trail: bool = true

## Internal state
var current_vector: Vector3 = Vector3.ZERO
var trail_positions: Array[Vector3] = []
const MAX_TRAIL = 5

## MultiMesh for trail ghost rendering
var _trail_mm: MultiMesh
var _trail_mmi: MultiMeshInstance3D

signal vector_changed(new_vector: Vector3)

func _ready() -> void:
	_setup_sliders()
	_create_trail_ghosts()
	_update_visualization()
	print("VectorTranslationDemo ready")

## Connects slider signals and sets default ranges/values
func _setup_sliders() -> void:
	# Configure magnitude slider (0 to max_magnitude)
	if magnitude_slider:
		magnitude_slider.set_range(0.0, max_magnitude)
		magnitude_slider.set_param_name("LENGTH")
		magnitude_slider.slider_moved.connect(_on_magnitude_changed)

	# Configure direction sliders (-1 to 1)
	if dir_x_slider:
		dir_x_slider.set_range(-1.0, 1.0)
		dir_x_slider.set_param_name("DIR X")
		dir_x_slider.set_normalized_value(1.0)  # Default: positive X
		dir_x_slider.slider_moved.connect(_on_direction_changed)

	if dir_y_slider:
		dir_y_slider.set_range(-1.0, 1.0)
		dir_y_slider.set_param_name("DIR Y")
		dir_y_slider.set_normalized_value(0.5)  # Default: 0
		dir_y_slider.slider_moved.connect(_on_direction_changed)

	if dir_z_slider:
		dir_z_slider.set_range(-1.0, 1.0)
		dir_z_slider.set_param_name("DIR Z")
		dir_z_slider.set_normalized_value(0.5)  # Default: 0
		dir_z_slider.slider_moved.connect(_on_direction_changed)

## Creates a MultiMesh-based trail of ghost cubes along the vector path
func _create_trail_ghosts() -> void:
	if not show_trail or not cube:
		return

	# Get mesh from the cube to use as trail ghost shape
	var cube_mesh = cube.get_node_or_null("MeshInstance3D")
	if not cube_mesh or not cube_mesh.mesh:
		return

	# Set up MultiMesh for all trail ghosts
	_trail_mm = MultiMesh.new()
	_trail_mm.transform_format = MultiMesh.TRANSFORM_3D
	_trail_mm.use_colors = true
	_trail_mm.mesh = cube_mesh.mesh
	_trail_mm.instance_count = MAX_TRAIL

	# Initialize all instances as hidden (zero scale)
	for i in MAX_TRAIL:
		var xf := Transform3D()
		xf = xf.scaled(Vector3.ZERO)
		_trail_mm.set_instance_transform(i, xf)
		_trail_mm.set_instance_color(i, Color(0.0, 0.8, 1.0, 0.1 + (i * 0.05)))

	# Create the MultiMeshInstance3D node
	_trail_mmi = MultiMeshInstance3D.new()
	_trail_mmi.multimesh = _trail_mm

	# Shared transparent material using per-instance colors
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mmi.material_override = mat

	add_child(_trail_mmi)

## Called when the magnitude slider moves
func _on_magnitude_changed(_value) -> void:
	_update_visualization()

## Called when any direction slider moves
func _on_direction_changed(_value) -> void:
	_update_visualization()

## Recalculates the vector from slider values and updates all visuals
func _update_visualization() -> void:
	# Get current slider values
	var magnitude := _get_magnitude()
	var direction := _get_direction()

	# Calculate the translation vector
	if direction.length() > 0.001:
		current_vector = direction.normalized() * magnitude
	else:
		current_vector = Vector3.ZERO

	# Update cube position
	if cube:
		cube.position = current_vector

	# Update arrow visualization
	_update_arrow()

	# Update trail
	_update_trail()

	# Update label
	_update_label()

	# Emit signal
	vector_changed.emit(current_vector)

## Returns the current magnitude from the slider, mapped to [0, max_magnitude]
func _get_magnitude() -> float:
	if not magnitude_slider:
		return 0.0

	# Get normalized value and map to range
	var norm = magnitude_slider.get_normalized_value()
	return norm * max_magnitude

## Returns a direction Vector3 derived from the three direction sliders
func _get_direction() -> Vector3:
	var x := 0.0
	var y := 0.0
	var z := 0.0

	if dir_x_slider:
		x = lerp(-1.0, 1.0, dir_x_slider.get_normalized_value())
	if dir_y_slider:
		y = lerp(-1.0, 1.0, dir_y_slider.get_normalized_value())
	if dir_z_slider:
		z = lerp(-1.0, 1.0, dir_z_slider.get_normalized_value())

	return Vector3(x, y, z)

## Scales and orients the arrow to match the current vector
func _update_arrow() -> void:
	if not arrow:
		return

	var mag = current_vector.length()

	if mag < 0.01:
		arrow.visible = false
		return

	arrow.visible = true

	# Scale arrow to match vector length (arrow is ~1 unit long at scale 1)
	arrow.scale = Vector3.ONE * mag

	# Point arrow from origin toward cube
	# Arrow mesh points along +Z, look_at makes -Z point at target
	# So we look at the opposite direction
	if mag > 0.001:
		var target_dir = current_vector.normalized()
		var up = Vector3.UP
		if abs(target_dir.dot(Vector3.UP)) > 0.99:
			up = Vector3.FORWARD

		# look_at points -Z at target, but our arrow points +Z
		# So look at the negative direction
		arrow.look_at(arrow.global_position - target_dir, up)

## Updates trail ghost transforms via MultiMesh — positions along the vector path
func _update_trail() -> void:
	if not show_trail or not _trail_mm:
		return

	var mag = current_vector.length()

	for i in _trail_mm.instance_count:
		var xf := Transform3D()
		if mag < 0.1:
			# Hide by zeroing scale
			xf = xf.scaled(Vector3.ZERO)
		else:
			var t = float(i + 1) / float(_trail_mm.instance_count + 1)
			var s = 0.3 + t * 0.2
			xf.origin = current_vector * t
			xf = xf.scaled(Vector3.ONE * s)
		_trail_mm.set_instance_transform(i, xf)

## Updates the 3D label with the current vector components and magnitude
func _update_label() -> void:
	if not vector_label:
		return

	var text = "v = (%.2f, %.2f, %.2f)\n|v| = %.2f" % [
		current_vector.x,
		current_vector.y,
		current_vector.z,
		current_vector.length()
	]
	vector_label.text = text

func _exit_tree() -> void:
	# Clean up MultiMesh node
	if is_instance_valid(_trail_mmi):
		_trail_mmi.queue_free()
	# Disconnect slider signals
	if magnitude_slider and magnitude_slider.slider_moved.is_connected(_on_magnitude_changed):
		magnitude_slider.slider_moved.disconnect(_on_magnitude_changed)
	if dir_x_slider and dir_x_slider.slider_moved.is_connected(_on_direction_changed):
		dir_x_slider.slider_moved.disconnect(_on_direction_changed)
	if dir_y_slider and dir_y_slider.slider_moved.is_connected(_on_direction_changed):
		dir_y_slider.slider_moved.disconnect(_on_direction_changed)
	if dir_z_slider and dir_z_slider.slider_moved.is_connected(_on_direction_changed):
		dir_z_slider.slider_moved.disconnect(_on_direction_changed)

## Public API

## Programmatically set the vector (updates sliders to match)
func set_vector(vec: Vector3) -> void:
	var mag = vec.length()
	var dir = vec.normalized() if mag > 0.001 else Vector3.RIGHT

	if magnitude_slider:
		magnitude_slider.set_normalized_value(clamp(mag / maxf(max_magnitude, 0.0001), 0.0, 1.0))
	if dir_x_slider:
		dir_x_slider.set_normalized_value((dir.x + 1.0) / 2.0)
	if dir_y_slider:
		dir_y_slider.set_normalized_value((dir.y + 1.0) / 2.0)
	if dir_z_slider:
		dir_z_slider.set_normalized_value((dir.z + 1.0) / 2.0)

	_update_visualization()

## Get the current translation vector
func get_vector() -> Vector3:
	return current_vector

## Reset to default state
func reset() -> void:
	if magnitude_slider:
		magnitude_slider.set_normalized_value(0.0)
	if dir_x_slider:
		dir_x_slider.set_normalized_value(1.0)
	if dir_y_slider:
		dir_y_slider.set_normalized_value(0.5)
	if dir_z_slider:
		dir_z_slider.set_normalized_value(0.5)

	_update_visualization()

## Grid system integration hook
func apply_grid_config(config_data: Dictionary) -> void:
	pass
