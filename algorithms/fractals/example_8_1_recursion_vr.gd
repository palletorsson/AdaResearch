# ===========================================================================
# NOC Example 8.1: Recursion
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.1: Basic Recursion - Concentric Circles
## Demonstrates recursive drawing with decreasing size
## Chapter 08: Fractals
##
## Each depth level has a distinct color. A frame surrounds the pattern.

@export var max_depth: int = 6
@export var initial_radius: float = 0.4
@export var show_animation: bool = false
@export var show_frame: bool = true
@export var frame_thickness: float = 0.02

var circles: Array[MeshInstance3D] = []
var current_depth: int = 0

# Animation
var animation_timer: float = 0.0
var animation_speed: float = 0.5  # Seconds per level

# Color palette for depth levels (rainbow progression)
var depth_colors: Array[Color] = [
	Color(0.9, 0.2, 0.3, 0.95),   # Level 0 - Red
	Color(0.95, 0.5, 0.1, 0.9),   # Level 1 - Orange
	Color(0.95, 0.85, 0.2, 0.85), # Level 2 - Yellow
	Color(0.3, 0.85, 0.4, 0.8),   # Level 3 - Green
	Color(0.2, 0.5, 0.95, 0.75),  # Level 4 - Blue
	Color(0.7, 0.3, 0.9, 0.7),    # Level 5 - Purple
]

func _ready() -> void:
	# Create frame background
	if show_frame:
		_create_frame()

	if show_animation:
		# Start with depth 0
		current_depth = 0
	else:
		# Draw all at once
		draw_recursive_circles(Vector3.ZERO, initial_radius, max_depth)
		current_depth = max_depth

func _process(delta: float) -> void:
	if show_animation and current_depth < max_depth:
		animation_timer += delta
		if animation_timer >= animation_speed:
			animation_timer = 0.0
			current_depth += 1
			clear_circles()
			draw_recursive_circles(Vector3.ZERO, initial_radius, current_depth)


func _create_frame() -> void:
	# Create a square frame around the circles
	var frame_size := initial_radius * 2.2
	var half := frame_size * 0.5
	var bar_length := frame_size + frame_thickness * 2

	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.15, 0.15, 0.2, 1.0)
	frame_material.metallic = 0.4
	frame_material.roughness = 0.6

	# Create 4 bars forming a square frame (in XY plane)
	# Top bar
	_create_frame_bar(Vector3(0, half + frame_thickness * 0.5, 0),
					  Vector3(bar_length, frame_thickness, frame_thickness), frame_material)
	# Bottom bar
	_create_frame_bar(Vector3(0, -half - frame_thickness * 0.5, 0),
					  Vector3(bar_length, frame_thickness, frame_thickness), frame_material)
	# Left bar
	_create_frame_bar(Vector3(-half - frame_thickness * 0.5, 0, 0),
					  Vector3(frame_thickness, bar_length, frame_thickness), frame_material)
	# Right bar
	_create_frame_bar(Vector3(half + frame_thickness * 0.5, 0, 0),
					  Vector3(frame_thickness, bar_length, frame_thickness), frame_material)

	# Create background panel (slightly behind)
	var bg_mesh := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(frame_size, frame_size, 0.005)
	bg_mesh.mesh = bg_box
	bg_mesh.position = Vector3(0, 0, -0.01)

	var bg_material := StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.05, 0.05, 0.08, 1.0)
	bg_mesh.material_override = bg_material
	add_child(bg_mesh)


func _create_frame_bar(pos: Vector3, bar_size: Vector3, mat: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = bar_size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	add_child(mesh_instance)


func draw_recursive_circles(center: Vector3, radius: float, depth: int) -> void:
	"""Recursively draw concentric circles"""
	if depth < 0 or radius < 0.01:
		return

	# Draw circle at this level
	create_circle(center, radius, depth)

	# Recursive call with smaller radius
	draw_recursive_circles(center, radius * 0.5, depth - 1)


func create_circle(center: Vector3, radius: float, depth: int) -> void:
	"""Create a torus (ring) to represent a circle"""
	var circle = MeshInstance3D.new()

	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.008
	torus.outer_radius = radius + 0.008
	torus.rings = 32
	torus.ring_segments = 32

	circle.mesh = torus
	circle.position = center
	circle.rotation.x = PI / 2.0  # Rotate to face forward (XY plane)

	# Color based on depth (iteration index from outermost)
	var iteration_index = max_depth - depth
	var color: Color
	if iteration_index < depth_colors.size():
		color = depth_colors[iteration_index]
	else:
		color = depth_colors[iteration_index % depth_colors.size()]

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	material.emission_energy_multiplier = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle.material_override = material

	add_child(circle)
	circles.append(circle)


func clear_circles() -> void:
	"""Clear all circles"""
	for circle in circles:
		circle.queue_free()
	circles.clear()


func increase_depth() -> void:
	"""Increase max depth"""
	max_depth += 1
	current_depth = max_depth
	clear_circles()
	draw_recursive_circles(Vector3.ZERO, initial_radius, max_depth)


func decrease_depth() -> void:
	"""Decrease max depth"""
	if max_depth > 1:
		max_depth -= 1
		current_depth = max_depth
		clear_circles()
		draw_recursive_circles(Vector3.ZERO, initial_radius, max_depth)


func reset() -> void:
	"""Reset animation"""
	current_depth = 0
	animation_timer = 0.0
	clear_circles()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
