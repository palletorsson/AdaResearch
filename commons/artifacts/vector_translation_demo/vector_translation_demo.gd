# vector_translation_demo.gd
# Interactive artifact demonstrating vector translation
# Slider controls vector magnitude → cube moves along that vector
extends Node3D

class_name VectorTranslationDemo

## Exported references for scene setup
@export var magnitude_slider_path: NodePath = "SliderPanel/MagnitudeSlider"
@export var dir_x_slider_path: NodePath = "SliderPanel/DirXSlider"
@export var dir_y_slider_path: NodePath = "SliderPanel/DirYSlider"
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

## Configuration
@export var max_magnitude: float = 3.0
@export var show_trail: bool = true

## Internal state
var current_vector: Vector3 = Vector3.ZERO
var trail_positions: Array[Vector3] = []
var trail_meshes: Array[MeshInstance3D] = []
const MAX_TRAIL = 5

signal vector_changed(new_vector: Vector3)

func _ready() -> void:
	_setup_sliders()
	_create_trail_ghosts()
	_update_visualization()
	print("VectorTranslationDemo ready")

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

func _create_trail_ghosts() -> void:
	if not show_trail or not cube:
		return
	
	# Create ghost cubes for trail visualization
	var cube_mesh = cube.get_node_or_null("MeshInstance3D")
	if not cube_mesh or not cube_mesh.mesh:
		return
	
	for i in range(MAX_TRAIL):
		var ghost = MeshInstance3D.new()
		ghost.mesh = cube_mesh.mesh
		
		# Create semi-transparent material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.0, 0.8, 1.0, 0.1 + (i * 0.05))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost.material_override = mat
		ghost.visible = false
		
		add_child(ghost)
		trail_meshes.append(ghost)

func _on_magnitude_changed(_value) -> void:
	_update_visualization()

func _on_direction_changed(_value) -> void:
	_update_visualization()

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

func _get_magnitude() -> float:
	if not magnitude_slider:
		return 0.0
	
	# Get normalized value and map to range
	var norm = magnitude_slider.get_normalized_value()
	return norm * max_magnitude

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

func _update_arrow() -> void:
	if not arrow:
		return
	
	var mag = current_vector.length()
	
	if mag < 0.01:
		arrow.visible = false
		return
	
	arrow.visible = true
	
	# Scale arrow to match vector length
	var base_length = 1.0  # Arrow's default length
	var scale_factor = mag / base_length
	arrow.scale = Vector3(scale_factor, scale_factor, scale_factor) * 0.15
	
	# Rotate arrow to point in vector direction
	if current_vector.length() > 0.001:
		var target_dir = current_vector.normalized()
		# Arrow points in -Z by default, so we look_at the target
		var look_target = arrow.global_position + target_dir
		arrow.look_at(look_target, Vector3.UP)
		# Rotate 90 degrees because arrow mesh points in different direction
		arrow.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_trail() -> void:
	if not show_trail:
		return
	
	var mag = current_vector.length()
	
	for i in range(trail_meshes.size()):
		var ghost = trail_meshes[i]
		if mag < 0.1:
			ghost.visible = false
			continue
		
		var t = float(i + 1) / float(trail_meshes.size() + 1)
		ghost.visible = true
		ghost.position = current_vector * t
		ghost.scale = Vector3.ONE * (0.3 + t * 0.2)

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

## Public API

func set_vector(vec: Vector3) -> void:
	"""Programmatically set the vector (updates sliders)"""
	var mag = vec.length()
	var dir = vec.normalized() if mag > 0.001 else Vector3.RIGHT
	
	if magnitude_slider:
		magnitude_slider.set_normalized_value(clamp(mag / max_magnitude, 0.0, 1.0))
	if dir_x_slider:
		dir_x_slider.set_normalized_value((dir.x + 1.0) / 2.0)
	if dir_y_slider:
		dir_y_slider.set_normalized_value((dir.y + 1.0) / 2.0)
	if dir_z_slider:
		dir_z_slider.set_normalized_value((dir.z + 1.0) / 2.0)
	
	_update_visualization()

func get_vector() -> Vector3:
	"""Get the current translation vector"""
	return current_vector

func reset() -> void:
	"""Reset to default state"""
	if magnitude_slider:
		magnitude_slider.set_normalized_value(0.0)
	if dir_x_slider:
		dir_x_slider.set_normalized_value(1.0)
	if dir_y_slider:
		dir_y_slider.set_normalized_value(0.5)
	if dir_z_slider:
		dir_z_slider.set_normalized_value(0.5)
	
	_update_visualization()
