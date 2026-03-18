# ===========================================================================
# NOC Example 8.4: Cantor Pagoda (Walkable Architecture)
# Based on: Daniel Shiffman's Cantor Set (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# A walkable architectural interpretation of the Cantor set as a pagoda structure
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.4: Cantor Pagoda
## Recursive Cantor set reimagined as walkable pagoda architecture
## Chapter 08: Fractals

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_depth: int = 5
@export var base_width: float = 8.0  # Large enough to walk through
@export var base_depth: float = 8.0  # Depth of the structure
@export var block_height: float = 1.0  # Height of each level
@export var block_thickness: float = 1.5  # Thickness of blocks (walkable)
@export var vertical_offset: float = 0.0  # Additional vertical spacing between levels

var _sim_root: Node3D
var _status_label: Label3D
var _blocks: Array = []

func _ready() -> void:
	_setup_environment()
	_build_pagoda()
	set_process(false)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 32
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, (max_depth + 1) * (block_height + vertical_offset) + 1.0, 0)
	_status_label.text = "Cantor Pagoda | Depth: %d" % max_depth
	_sim_root.add_child(_status_label)

func _build_pagoda() -> void:
	"""Build the pagoda from bottom to top (inverted - largest at top)"""
	for level in range(max_depth + 1):
		var y_position = level * (block_height + vertical_offset)
		# Invert the depth so max_depth is at bottom, 0 is at top
		var inverted_depth = max_depth - level
		_draw_cantor_level(inverted_depth, y_position)

func _draw_cantor_level(depth: int, y_pos: float) -> void:
	"""Draw a single level of the Cantor pagoda"""
	if depth > max_depth:
		return

	# Calculate segments for this depth
	var segments = _get_cantor_segments(depth)

	# Draw each segment as a 3D block
	for segment in segments:
		_create_block(segment["start"], segment["width"], y_pos, depth)

func _get_cantor_segments(depth: int) -> Array:
	"""Calculate Cantor set segments for a given depth"""
	var segments = []

	if depth == 0:
		# Base level - single full block
		segments.append({
			"start": -base_width / 2.0,
			"width": base_width
		})
	else:
		# Recursively build segments
		var previous_segments = _get_cantor_segments(depth - 1)
		for prev_segment in previous_segments:
			var segment_width = prev_segment["width"] / 3.0

			# Left third
			segments.append({
				"start": prev_segment["start"],
				"width": segment_width
			})

			# Right third (skip middle)
			segments.append({
				"start": prev_segment["start"] + 2.0 * segment_width,
				"width": segment_width
			})

	return segments

func _create_block(x_start: float, width: float, y_pos: float, depth: int) -> void:
	"""Create a walkable block with collision"""
	# Create StaticBody3D for collision
	var static_body = StaticBody3D.new()
	static_body.position = Vector3(x_start + width / 2.0, y_pos + block_height / 2.0, 0)

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, block_height, block_thickness)
	mesh_instance.mesh = box

	# Create material with depth-based coloring (brighter)
	var material = StandardMaterial3D.new()
	# Invert depth_factor so higher blocks (larger) are brighter
	var depth_factor = 1.0 - (float(depth) / float(max_depth))

	# Gradient from medium purple at bottom to very bright pink at top
	var base_color = Color(0.5, 0.2, 0.5, 1.0)  # Medium purple (brighter)
	var top_color = Color(1.0, 0.7, 1.0, 1.0)   # Very bright pink
	material.albedo_color = base_color.lerp(top_color, depth_factor)

	# Add stronger emission for visual appeal
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.8
	material.emission_energy_multiplier = 1.5
	material.metallic = 0.2
	material.roughness = 0.7

	mesh_instance.material_override = material
	static_body.add_child(mesh_instance)

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, block_height, block_thickness)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)

	_sim_root.add_child(static_body)
	_blocks.append(static_body)

func get_block_count() -> int:
	"""Return total number of blocks"""
	return _blocks.size()

func get_level_info(level: int) -> Dictionary:
	"""Get information about a specific level"""
	if level > max_depth:
		return {}

	var segments = _get_cantor_segments(level)
	return {
		"level": level,
		"block_count": segments.size(),
		"total_width": base_width / pow(3, level),
		"y_position": level * (block_height + vertical_offset)
	}

func reset_pagoda() -> void:
	"""Clear and rebuild the pagoda"""
	for block in _blocks:
		block.queue_free()
	_blocks.clear()
	_build_pagoda()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
