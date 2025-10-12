# ===========================================================================
# NOC Example 8.4: Cantor Set
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.4: Cantor Set
## Recursive division creating the Cantor set fractal
## Chapter 08: Fractals

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_depth: int = 6
@export var initial_width: float = 0.8
@export var vertical_spacing: float = 0.08

var _sim_root: Node3D
var _status_label: Label3D

func _ready() -> void:
	_setup_environment()
	_draw_cantor(Vector3(-initial_width/2, 0.3, 0), initial_width, 0)
	set_process(false)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_status_label.text = "Cantor Set | Depth: %d" % max_depth
	_sim_root.add_child(_status_label)

func _draw_cantor(start: Vector3, width: float, depth: int) -> void:
	if depth > max_depth or width < 0.01:
		return

	# Draw line segment
	_create_line(start, width, depth)

	# Recurse: divide into thirds, keep first and last third
	var new_width := width / 3.0
	var next_y := start.y - vertical_spacing

	# Left third
	_draw_cantor(Vector3(start.x, next_y, start.z), new_width, depth + 1)

	# Right third (skip middle third)
	_draw_cantor(Vector3(start.x + 2.0 * new_width, next_y, start.z), new_width, depth + 1)

func _create_line(start: Vector3, width: float, depth: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.015, 0.02)
	mesh_instance.mesh = box
	mesh_instance.position = start + Vector3(width/2, 0, 0)

	var material := StandardMaterial3D.new()
	var intensity := 1.0 - (float(depth) / float(max_depth)) * 0.4
	material.albedo_color = Color(1.0, 0.5 + intensity * 0.4, 0.9)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.6
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
