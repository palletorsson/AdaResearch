# ===========================================================================
# NOC Example 8.7: Stochastic Tree
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.7: Stochastic Tree
## Recursive tree with random variation
## Chapter 08: Fractals

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var recursion_depth: int = 5
@export var base_angle: float = 25.0
@export var angle_variance: float = 15.0
@export var length_reduction: float = 0.67
@export var length_variance: float = 0.1

var _sim_root: Node3D
var _status_label: Label3D
var branches: Array[MeshInstance3D] = []
var initial_length: float = 0.15
var initial_thickness: float = 0.01

func _ready() -> void:
	randomize()
	_setup_environment()
	_grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, recursion_depth)
	set_process(false)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_status_label.text = "Stochastic Tree | Branches: %d" % branches.size()
	_sim_root.add_child(_status_label)

	# Position at bottom
	_sim_root.position = Vector3(0, -0.3, 0)

func _grow_tree(start_pos: Vector3, direction: Vector3, length: float, thickness: float, depth: int) -> void:
	if depth <= 0 or length < 0.01:
		return

	var end_pos := start_pos + direction * length
	_create_branch(start_pos, end_pos, thickness, depth)

	if depth > 1:
		# Add randomness to angle and length
		var angle_left := deg_to_rad(base_angle + randf_range(-angle_variance, angle_variance))
		var angle_right := deg_to_rad(base_angle + randf_range(-angle_variance, angle_variance))
		var length_left := length * (length_reduction + randf_range(-length_variance, length_variance))
		var length_right := length * (length_reduction + randf_range(-length_variance, length_variance))

		# Left branch
		var left_dir := _rotate_vector(direction, Vector3.FORWARD, angle_left)
		_grow_tree(end_pos, left_dir, length_left, thickness * 0.7, depth - 1)

		# Right branch
		var right_dir := _rotate_vector(direction, Vector3.FORWARD, -angle_right)
		_grow_tree(end_pos, right_dir, length_right, thickness * 0.7, depth - 1)

		# Sometimes add a third branch
		if randf() < 0.3 and depth > 2:
			var mid_angle := deg_to_rad(randf_range(-10.0, 10.0))
			var mid_dir := _rotate_vector(direction, Vector3.RIGHT, mid_angle)
			_grow_tree(end_pos, mid_dir, length * 0.5, thickness * 0.6, depth - 2)

func _create_branch(start: Vector3, end: Vector3, thickness: float, depth: int) -> void:
	var branch := MeshInstance3D.new()
	var dir := end - start
	var length := dir.length()
	var mid := (start + end) / 2.0

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = thickness
	cylinder.bottom_radius = thickness * 1.2
	cylinder.height = length

	branch.mesh = cylinder
	branch.position = mid

	if length > 0.001:
		var up := Vector3.UP
		if abs(dir.normalized().dot(up)) > 0.99:
			up = Vector3.RIGHT
		branch.look_at(end, up)
		branch.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	var depth_ratio := float(depth) / float(recursion_depth)
	var color := Color(0.8, 0.5, 0.7).lerp(Color(1.0, 0.7, 0.95), 1.0 - depth_ratio)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	branch.material_override = material

	_sim_root.add_child(branch)
	branches.append(branch)

func _rotate_vector(vec: Vector3, axis: Vector3, angle: float) -> Vector3:
	return Basis(axis.normalized(), angle) * vec