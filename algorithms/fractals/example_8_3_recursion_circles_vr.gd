# ===========================================================================
# NOC Example 8.3: Recursion: Circles
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.3: Recursion Circles
## Recursive circles within circles
## Chapter 08: Fractals

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_depth: int = 4
@export var radius_reduction: float = 0.5

var _sim_root: Node3D
var _status_label: Label3D

func _ready() -> void:
	_setup_environment()
	_draw_circles(Vector3.ZERO, 0.4, max_depth)
	set_process(false)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_status_label.text = "Recursive Circles | Depth: %d" % max_depth
	_sim_root.add_child(_status_label)

func _draw_circles(center: Vector3, radius: float, depth: int) -> void:
	if depth <= 0 or radius < 0.01:
		return

	# Draw circle at current level
	_create_circle(center, radius, depth)

	# Recurse: create 4 smaller circles around this one
	var new_radius := radius * radius_reduction
	var offset := radius - new_radius

	_draw_circles(center + Vector3(offset, 0, 0), new_radius, depth - 1)
	_draw_circles(center + Vector3(-offset, 0, 0), new_radius, depth - 1)
	_draw_circles(center + Vector3(0, offset, 0), new_radius, depth - 1)
	_draw_circles(center + Vector3(0, -offset, 0), new_radius, depth - 1)

func _create_circle(center: Vector3, radius: float, depth: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.9
	torus.outer_radius = radius
	mesh_instance.mesh = torus
	mesh_instance.position = center

	var material := StandardMaterial3D.new()
	var hue_shift := float(depth) / float(max_depth)
	material.albedo_color = Color(1.0, 0.5 + hue_shift * 0.5, 0.8 + hue_shift * 0.2)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.5
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
