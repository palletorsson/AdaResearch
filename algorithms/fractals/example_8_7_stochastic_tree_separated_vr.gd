# ===========================================================================
# NOC Example 8.7: Stochastic Tree with Separation Algorithm
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ GDScript, 2025
#
# Enhanced version with more branches and separation algorithm
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.7: Stochastic Tree with Separation
## Recursive tree with random variation and branch separation
## Chapter 08: Fractals

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var recursion_depth: int = 5
@export var base_angle: float = 25.0
@export var angle_variance: float = 15.0
@export var length_reduction: float = 0.67
@export var length_variance: float = 0.1
@export var separation_duration: float = 3.0
@export var separation_strength: float = 0.05
@export_range(-1.0, 1.0, 0.01) var upward_bias: float = 0.01
@export_range(0.0, 1.0, 0.01) var upward_alignment_strength: float = 0.25

var _sim_root: Node3D
var _status_label: Label3D
var branches: Array[MeshInstance3D] = []
var branch_levels: Dictionary = {}  # level -> Array[BranchData]
var initial_length: float = 1.5
var initial_thickness: float = 0.1
var separation_timer: float = 0.0
var is_separating: bool = false
var _level_order: Array[int] = []
var _current_level_idx: int = 0
var _level_timer: float = 0.0


class BranchData:
	var mesh_instance: MeshInstance3D
	var start_pos: Vector3
	var end_pos: Vector3
	var level: int
	var velocity: Vector3 = Vector3.ZERO
	var thickness: float
	var base_length: float
	var parent: BranchData = null
	var children: Array[BranchData] = []

	func _init(mesh: MeshInstance3D, start: Vector3, end: Vector3, lvl: int, thick: float, length: float) -> void:
		mesh_instance = mesh
		start_pos = start
		end_pos = end
		level = lvl
		thickness = thick
		base_length = max(length, 0.001)
		velocity = Vector3.ZERO
		parent = null

func _ready() -> void:
	randomize()
	_setup_environment()
	_grow_tree(Vector3.ZERO, Vector3.UP, initial_length, initial_thickness, recursion_depth)

	_level_order.clear()
	for level in branch_levels.keys():
		_level_order.append(level)
	_level_order.sort()
	_level_order.reverse()
	_current_level_idx = 0
	_level_timer = 0.0
	separation_timer = 0.0

	_update_status()

	if _level_order.is_empty():
		return

	_reset_level_velocities(_level_order[_current_level_idx])

	is_separating = true
	set_process(true)

func _process(delta: float) -> void:
	if not is_separating:
		return

	separation_timer += delta
	_level_timer += delta
	_apply_separation(delta)

	if _level_timer >= separation_duration:
		var current_level: int = _level_order[_current_level_idx]
		_apply_upward_alignment(current_level)
		_level_timer = 0.0
		_current_level_idx += 1
		if _current_level_idx < _level_order.size():
			_reset_level_velocities(_level_order[_current_level_idx])
		else:
			is_separating = false
			set_process(false)

	_update_status()

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_sim_root.add_child(_status_label)

	# Position at ground level
	_sim_root.position = Vector3.ZERO

func _grow_tree(start_pos: Vector3, direction: Vector3, length: float, thickness: float, depth: int, parent_data: BranchData = null) -> BranchData:
	if depth <= 0 or length < 0.01:
		return null

	var end_pos := start_pos + direction * length
	var level := recursion_depth - depth
	var branch_data := _create_branch(start_pos, end_pos, thickness, depth, level, parent_data)

	if depth > 1:
		# Add randomness to angle and length
		var angle_left := deg_to_rad(base_angle + randf_range(-angle_variance, angle_variance))
		var angle_right := deg_to_rad(base_angle + randf_range(-angle_variance, angle_variance))
		var angle_mid := deg_to_rad(randf_range(-15.0, 15.0))

		var length_left := length * (length_reduction + randf_range(-length_variance, length_variance))
		var length_right := length * (length_reduction + randf_range(-length_variance, length_variance))
		var length_mid := length * (length_reduction + randf_range(-length_variance * 0.5, length_variance * 0.5))

		# Left branch
		var left_dir := _rotate_vector(direction, Vector3.FORWARD, angle_left)
		_grow_tree(end_pos, left_dir, length_left, thickness * 0.7, depth - 1, branch_data)

		# Right branch
		var right_dir := _rotate_vector(direction, Vector3.FORWARD, -angle_right)
		_grow_tree(end_pos, right_dir, length_right, thickness * 0.7, depth - 1, branch_data)

		# Always add a third branch from level 2 onwards (depth = recursion_depth - 2)
		if depth >= recursion_depth - 1:  # This means we're at level 2
			var mid_dir := _rotate_vector(direction, Vector3.RIGHT, angle_mid)
			_grow_tree(end_pos, mid_dir, length_mid, thickness * 0.65, depth - 1, branch_data)

	return branch_data

func _update_branch_mesh(branch: MeshInstance3D, start: Vector3, end: Vector3, thickness: float) -> void:
	var dir := end - start
	var length := dir.length()
	var cylinder := branch.mesh as CylinderMesh
	if cylinder:
		cylinder.top_radius = thickness
		cylinder.bottom_radius = thickness * 1.2
		cylinder.height = max(length, 0.001)
	branch.position = (start + end) / 2.0

	if length > 0.001:
		var direction_normalized := dir.normalized()
		var basis := Basis()
		basis.y = direction_normalized
		var perp := Vector3.RIGHT
		if abs(direction_normalized.dot(Vector3.RIGHT)) > 0.9:
			perp = Vector3.FORWARD
		basis.x = perp.cross(direction_normalized).normalized()
		basis.z = basis.x.cross(direction_normalized).normalized()
		branch.basis = basis

func _create_branch(start: Vector3, end: Vector3, thickness: float, depth: int, level: int, parent_branch: BranchData = null) -> BranchData:
	var branch := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	branch.mesh = cylinder

	var branch_length: float = start.distance_to(end)
	_update_branch_mesh(branch, start, end, thickness)

	var depth_ratio := float(depth) / float(recursion_depth)
	var color := Color(0.8, 0.5, 0.7).lerp(Color(1.0, 0.7, 0.95), 1.0 - depth_ratio)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	branch.material_override = material

	_sim_root.add_child(branch)
	branches.append(branch)

	var branch_data: BranchData = BranchData.new(branch, start, end, level, thickness, branch_length)
	branch_data.parent = parent_branch
	if parent_branch:
		parent_branch.children.append(branch_data)

	if not branch_levels.has(level):
		branch_levels[level] = [] as Array[BranchData]
	branch_levels[level].append(branch_data)

	return branch_data

func _apply_separation(delta: float) -> void:
	if _current_level_idx >= _level_order.size():
		return

	var level := _level_order[_current_level_idx]
	var level_branches: Array[BranchData] = branch_levels.get(level, []) as Array[BranchData]
	if level_branches.is_empty():
		return

	for i in range(level_branches.size()):
		var branch_a: BranchData = level_branches[i]
		var force := Vector3.ZERO
		var neighbor_count := 0

		for j in range(level_branches.size()):
			if i == j:
				continue

			var branch_b: BranchData = level_branches[j]
			var distance := branch_a.end_pos.distance_to(branch_b.end_pos)

			# Apply repulsion if branches are close
			if distance < 2.0 and distance > 0.01:
				var direction := (branch_a.end_pos - branch_b.end_pos).normalized()
				var repulsion := direction * (separation_strength / distance)
				force += repulsion
				neighbor_count += 1

		if neighbor_count > 0:
			force /= neighbor_count

		if abs(upward_bias) > 0.0001:
			force += Vector3.UP * upward_bias

		branch_a.velocity += force
		branch_a.velocity *= 0.95  # Damping

		var offset := branch_a.velocity * delta
		if offset.length_squared() == 0.0:
			continue

		var previous_end: Vector3 = branch_a.end_pos
		var previous_dir: Vector3 = previous_end - branch_a.start_pos
		branch_a.end_pos += offset

		var direction_vec: Vector3 = branch_a.end_pos - branch_a.start_pos
		if direction_vec.length() > 0.0001:
			direction_vec = direction_vec.normalized() * branch_a.base_length
		else:
			direction_vec = Vector3.UP * branch_a.base_length
		branch_a.end_pos = branch_a.start_pos + direction_vec

		var tip_offset: Vector3 = branch_a.end_pos - previous_end
		var rotation: Quaternion = _compute_rotation(previous_dir, branch_a.end_pos - branch_a.start_pos)
		_update_branch_mesh(branch_a.mesh_instance, branch_a.start_pos, branch_a.end_pos, branch_a.thickness)

		if not branch_a.children.is_empty():
			var rotation_changed: bool = not rotation.is_equal_approx(Quaternion())
			if tip_offset.length_squared() > 0.0 or rotation_changed:
				_propagate_child_transform(branch_a, rotation)

func _apply_upward_alignment(level: int) -> void:
	if upward_alignment_strength <= 0.0:
		return

	var level_branches: Array[BranchData] = branch_levels.get(level, []) as Array[BranchData]
	if level_branches.is_empty():
		return

	var blend: float = clamp(upward_alignment_strength, 0.0, 1.0)
	for branch_data: BranchData in level_branches:
		var previous_dir: Vector3 = branch_data.end_pos - branch_data.start_pos
		if previous_dir.length_squared() < 0.000001:
			continue

		var noise: Vector3 = Vector3(
			randf_range(-blend, blend),
			randf_range(0.0, blend),
			randf_range(-blend, blend)
		)
		var target_up: Vector3 = (Vector3.UP + noise).normalized()
		var new_dir: Vector3 = previous_dir.normalized().lerp(target_up, blend).normalized()
		branch_data.end_pos = branch_data.start_pos + new_dir * branch_data.base_length

		var rotation: Quaternion = _compute_rotation(previous_dir, branch_data.end_pos - branch_data.start_pos)
		_update_branch_mesh(branch_data.mesh_instance, branch_data.start_pos, branch_data.end_pos, branch_data.thickness)

		if not branch_data.children.is_empty():
			var rotation_changed: bool = not rotation.is_equal_approx(Quaternion())
			if rotation_changed:
				_propagate_child_transform(branch_data, rotation)



func _compute_rotation(from_vec: Vector3, to_vec: Vector3) -> Quaternion:
	if from_vec.length_squared() < 0.000001 or to_vec.length_squared() < 0.000001:
		return Quaternion()

	var from_norm: Vector3 = from_vec.normalized()
	var to_norm: Vector3 = to_vec.normalized()
	var dot: float = clamp(from_norm.dot(to_norm), -1.0, 1.0)
	if dot > 0.9999:
		return Quaternion()

	if dot < -0.9999:
		var axis: Vector3 = from_norm.cross(Vector3.RIGHT)
		if axis.length_squared() < 0.000001:
			axis = from_norm.cross(Vector3.UP)
		axis = axis.normalized()
		return Quaternion(axis, PI)

	var axis: Vector3 = from_norm.cross(to_norm)
	if axis.length_squared() < 0.000001:
		return Quaternion()

	axis = axis.normalized()
	var angle: float = acos(dot)
	return Quaternion(axis, angle)


func _propagate_child_transform(parent_branch: BranchData, rotation: Quaternion) -> void:
	for child in parent_branch.children:
		var old_start: Vector3 = child.start_pos
		var old_end: Vector3 = child.end_pos

		child.start_pos = parent_branch.end_pos

		var relative_vector: Vector3 = old_end - old_start
		if not rotation.is_equal_approx(Quaternion()):
			relative_vector = rotation * relative_vector

		child.end_pos = child.start_pos + relative_vector
		_update_branch_mesh(child.mesh_instance, child.start_pos, child.end_pos, child.thickness)

		if child.children.is_empty():
			continue

		_propagate_child_transform(child, rotation)


func _reset_level_velocities(level: int) -> void:
	var level_branches: Array[BranchData] = branch_levels.get(level, []) as Array[BranchData]
	for branch_data: BranchData in level_branches:
		branch_data.velocity = Vector3.ZERO


func _rotate_vector(vec: Vector3, axis: Vector3, angle: float) -> Vector3:
	return Basis(axis.normalized(), angle) * vec

func _update_status() -> void:
	var status: String = "Stochastic Tree (Separated) | Branches: %d" % branches.size()
	if is_separating:
		var total_levels: int = _level_order.size()
		var current_index: int = clamp(_current_level_idx, 0, max(total_levels - 1, 0))
		var level_time: float = min(_level_timer, separation_duration)
		status += " | Level %d/%d | %.1fs" % [current_index + 1, max(total_levels, 1), level_time]
	else:
		status += " | Separation Complete"
	_status_label.text = status

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
