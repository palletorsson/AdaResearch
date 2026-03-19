# ===========================================================================
# NOC Example 8.2: Recursion (Variant)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.2: Recursion (Nested Squares)
## Recursive pattern of squares within squares
## Chapter 08: Fractals
##
## Each iteration has a distinct color from a predefined palette.
## A frame surrounds the entire pattern.

# @identity
# essence: square(center, size, d) = box(size) + square(center, size * 0.5, d-1)
# desire: To be stared into — concentric squares receding in Z, each layer a different color, pulling the eye inward
# critical_parameter: size_reduction (0.5) — the ratio between parent and child determines whether the nesting feels dense or sparse
# triggers: max_depth increase → deeper nesting; z-offset per layer prevents z-fighting and creates parallax depth
# emerges: A tunnel effect from flat geometry — depth perception from color gradient and z-stacking alone
# needs: VR depth control [missing], animation toggle [missing]
# relationships: Simplest 2D recursion before Koch and Sierpinski; sibling to example_8_1 (concentric circles)
# truth: A square inside a square is not decoration — it is the first evidence that a function can call itself.

@export var max_depth: int = 6
@export var size_reduction: float = 0.5
@export var initial_size: float = 1.0
@export var show_frame: bool = true
@export var frame_thickness: float = 0.02

# Color palette for each iteration depth (0 = outermost)
var iteration_colors: Array[Color] = [
	Color(0.9, 0.2, 0.3, 0.9),   # Iteration 1: Red
	Color(0.95, 0.5, 0.1, 0.85), # Iteration 2: Orange
	Color(0.95, 0.85, 0.2, 0.8), # Iteration 3: Yellow
	Color(0.3, 0.85, 0.4, 0.75), # Iteration 4: Green
	Color(0.2, 0.6, 0.95, 0.7),  # Iteration 5: Blue
	Color(0.7, 0.3, 0.9, 0.65),  # Iteration 6: Purple
]

var _sim_root: Node3D
var _mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	# Draw the frame first (behind everything)
	if show_frame:
		_create_frame(Vector3.ZERO, initial_size)

	# Draw recursive pattern
	_draw_recursive_pattern(Vector3.ZERO, initial_size, max_depth)
	set_process(false)


func _create_frame(center: Vector3, size: float) -> void:
	# Create 4 bars forming a frame around the pattern
	var half := size * 0.5
	var bar_length := size + frame_thickness * 2

	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.2, 0.2, 0.25, 1.0)
	frame_material.metallic = 0.3
	frame_material.roughness = 0.7

	# Top bar
	_create_frame_bar(center + Vector3(0, half + frame_thickness * 0.5, 0),
					  Vector3(bar_length, frame_thickness, frame_thickness), frame_material)
	# Bottom bar
	_create_frame_bar(center + Vector3(0, -half - frame_thickness * 0.5, 0),
					  Vector3(bar_length, frame_thickness, frame_thickness), frame_material)
	# Left bar
	_create_frame_bar(center + Vector3(-half - frame_thickness * 0.5, 0, 0),
					  Vector3(frame_thickness, bar_length, frame_thickness), frame_material)
	# Right bar
	_create_frame_bar(center + Vector3(half + frame_thickness * 0.5, 0, 0),
					  Vector3(frame_thickness, bar_length, frame_thickness), frame_material)


func _create_frame_bar(pos: Vector3, bar_size: Vector3, mat: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = bar_size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	_sim_root.add_child(mesh_instance)


func _draw_recursive_pattern(center: Vector3, size: float, depth: int) -> void:
	if depth <= 0 or size < 0.01:
		return

	# Draw square at this level
	_create_square(center, size, depth)

	# Recurse with smaller squares
	var new_size := size * size_reduction
	_draw_recursive_pattern(center, new_size, depth - 1)


func _create_square(center: Vector3, size: float, depth: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, 0.005)
	mesh_instance.mesh = box
	# Offset each layer slightly in Z to prevent z-fighting
	mesh_instance.position = center + Vector3(0, 0, (max_depth - depth) * 0.003)

	var material := StandardMaterial3D.new()

	# Get color for this iteration (depth goes from max_depth down to 1)
	var iteration_index := max_depth - depth
	var color: Color
	if iteration_index < iteration_colors.size():
		color = iteration_colors[iteration_index]
	else:
		# Fallback: cycle through colors
		color = iteration_colors[iteration_index % iteration_colors.size()]

	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	material.emission_energy_multiplier = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
	_mesh_instances.append(mesh_instance)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
