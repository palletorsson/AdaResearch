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

@export var max_depth: int = 5
@export var initial_radius: float = 0.3
@export var show_animation: bool = true

var circles: Array[MeshInstance3D] = []
var current_depth: int = 0

# Animation
var animation_timer: float = 0.0
var animation_speed: float = 0.5  # Seconds per level

# UI
var info_label: Label3D

# Pink color palette for depth levels
var depth_colors: Array[Color] = [
	Color(1.0, 0.6, 1.0, 0.9),   # Level 0 - Bright pink
	Color(0.9, 0.5, 0.8, 0.8),   # Level 1 - Medium pink
	Color(0.8, 0.4, 0.7, 0.7),   # Level 2 - Darker pink
	Color(0.7, 0.3, 0.6, 0.6),   # Level 3 - Purple-pink
	Color(0.6, 0.2, 0.5, 0.5),   # Level 4 - Dark purple
	Color(0.5, 0.1, 0.4, 0.4),   # Level 5+ - Very dark
]

func _ready():
	# Create UI
	create_info_label()

	if show_animation:
		# Start with depth 0
		current_depth = 0
	else:
		# Draw all at once
		draw_recursive_circles(Vector3.ZERO, initial_radius, max_depth)
		current_depth = max_depth

	update_info_label()
	print("Example 8.1: Recursion (Concentric Circles) - Max depth: %d" % max_depth)

func _process(delta):
	if show_animation and current_depth < max_depth:
		animation_timer += delta
		if animation_timer >= animation_speed:
			animation_timer = 0.0
			current_depth += 1
			clear_circles()
			draw_recursive_circles(Vector3.ZERO, initial_radius, current_depth)
			update_info_label()

func create_info_label():
	"""Create info label"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

func update_info_label():
	"""Update info label"""
	if info_label:
		info_label.text = "Recursive Circles\nDepth: %d / %d" % [current_depth, max_depth]

func draw_recursive_circles(center: Vector3, radius: float, depth: int):
	"""Recursively draw concentric circles"""
	if depth < 0 or radius < 0.01:
		return

	# Draw circle at this level
	create_circle(center, radius, depth)

	# Recursive call with smaller radius
	draw_recursive_circles(center, radius * 0.5, depth - 1)

func create_circle(center: Vector3, radius: float, depth: int):
	"""Create a torus (ring) to represent a circle"""
	var circle = MeshInstance3D.new()

	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.005
	torus.outer_radius = radius + 0.005
	torus.rings = 32
	torus.ring_segments = 32

	circle.mesh = torus
	circle.position = center
	circle.rotation.x = PI / 2.0  # Rotate to horizontal

	# Color based on depth
	var color_index = depth % depth_colors.size()
	var color = depth_colors[color_index]

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.6
	material.emission_energy_multiplier = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle.material_override = material

	add_child(circle)
	circles.append(circle)

func clear_circles():
	"""Clear all circles"""
	for circle in circles:
		circle.queue_free()
	circles.clear()

func increase_depth():
	"""Increase max depth"""
	max_depth += 1
	current_depth = max_depth
	clear_circles()
	draw_recursive_circles(Vector3.ZERO, initial_radius, max_depth)
	update_info_label()
	print("Max depth increased to: %d" % max_depth)

func decrease_depth():
	"""Decrease max depth"""
	if max_depth > 1:
		max_depth -= 1
		current_depth = max_depth
		clear_circles()
		draw_recursive_circles(Vector3.ZERO, initial_radius, max_depth)
		update_info_label()
		print("Max depth decreased to: %d" % max_depth)

func reset():
	"""Reset animation"""
	current_depth = 0
	animation_timer = 0.0
	clear_circles()
	update_info_label()
	print("Reset")
