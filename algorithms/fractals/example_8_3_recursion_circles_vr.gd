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
const MAT_POP_PLASTIC := preload("res://algorithms/shaders/queer_materials/mat_pop_plastic.tres")

@export var max_depth: int = 4
@export var radius_reduction: float = 0.5
@export var rotation_speed: float = 0.3
@export var rotation_per_depth: float = 0.5
@export var pause_duration: float = 10.0

var _sim_root: Node3D
var _status_label: Label3D
var _circles: Array = []
var _is_paused: bool = false
var _pause_timer: float = 0.0

func _ready() -> void:
	_setup_environment()
	_draw_circles(Vector3.ZERO, 2.0, max_depth)
	set_process(true)

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

	# Use the pop plastic shader material
	mesh_instance.material_override = MAT_POP_PLASTIC

	_sim_root.add_child(mesh_instance)

	# Store circle data for rotation
	_circles.append({
		"node": mesh_instance,
		"depth": depth,
		"center": center,
		"rotation": 0.0  # Track total rotation
	})

func _process(delta: float) -> void:
	# Handle pause timer
	if _is_paused:
		_pause_timer += delta
		if _pause_timer >= pause_duration:
			_is_paused = false
			_pause_timer = 0.0
		return

	# Rotate each circle based on its depth
	for circle_data in _circles:
		var node = circle_data["node"]
		var depth = circle_data["depth"]

		# Different rotation speeds per depth level
		var speed_multiplier = rotation_speed * (1.0 + depth * rotation_per_depth)
		var rotation_amount = delta * speed_multiplier

		node.rotate_z(rotation_amount)
		circle_data["rotation"] += rotation_amount

		# Check if this circle completed a full rotation (2π radians)
		if circle_data["rotation"] >= TAU:  # TAU = 2π
			circle_data["rotation"] = fmod(circle_data["rotation"], TAU)

			# Pause animation when first circle completes rotation
			if depth == max_depth:  # Check the outermost/first created circle
				_is_paused = true
				_pause_timer = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

