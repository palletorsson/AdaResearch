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

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_depth: int = 5
@export var size_reduction: float = 0.5

var _sim_root: Node3D
var _status_label: Label3D
var _mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)
	_draw_recursive_pattern(Vector3.ZERO, 0.6, max_depth)
	set_process(false)



func _draw_recursive_pattern(center: Vector3, size: float, depth: int) -> void:
	if depth <= 0 or size < 0.02:
		return

	# Draw square at this level
	_create_square(center, size, depth)

	# Recurse with smaller squares
	var new_size := size * size_reduction
	_draw_recursive_pattern(center, new_size, depth - 1)

func _create_square(center: Vector3, size: float, depth: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, 0.01)
	mesh_instance.mesh = box
	mesh_instance.position = center

	var material := StandardMaterial3D.new()
	var intensity := 1.0 - (float(depth) / float(max_depth)) * 0.5
	material.albedo_color = Color(1.0, 0.6 + intensity * 0.4, 0.9, 0.8)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.4
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
	_mesh_instances.append(mesh_instance)
