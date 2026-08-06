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

# @identity
# essence: tree + separation_force(branches_at_level) + upward_alignment(blend), post-growth branch repulsion
# desire: To watch a tree argue with itself — branches push apart level by level, finding space, then aligning upward
# critical_parameter: separation_strength (0.05) — the repulsion force between same-level branches; too high and the tree explodes, too low and branches overlap
# triggers: Growth completes → separation phase activates level by level (deepest first); upward_alignment smooths the result
# emerges: Natural-looking canopy spacing from simple repulsion — branches discover their territory without planning
# needs: VR separation speed control [missing], force visualization [missing]
# relationships: Extends fractal_stochastic_tree with flocking-like separation; bridges fractals and emergence sequences
# truth: A tree's canopy is not designed — it is negotiated, branch by branch, through local repulsion toward global form.

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

# ═══════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — habit × settlement (promoted 2026-08-06)
# ═══════════════════════════════════════════════════════════════════════
#
# EVERY EXPORT THIS FILE HAD WAS A MAGNITUDE. depth, angle, variance,
# reduction, strength, duration: turn any of them and you get the same tree
# a bit bigger, a bit wider, a bit twitchier. None of them says anything.
# The two things this artifact actually argues were both hard-coded.
#
#   habit       WHERE THE CHILDREN GO AROUND THEIR PARENT. _grow_tree rotates
#               every left/right child about the WORLD axis Vector3.FORWARD and
#               every third child about the WORLD axis Vector3.RIGHT, at every
#               level, so the tree is a flat drawing with one branch leaning out
#               of it. That is one botanical habit out of several, chosen by a
#               constant and never named.
#
#               THE WORD AND ITS FOUR ANSWERS ARE branching_vine's, character
#               for character, and so is the mechanism: a roll of the branching
#               plane applied at each descent, 0 / 30 / 90 / 137.5 degrees. The
#               two artifacts are the same claim on two chassis — a recursive
#               branch rule that has to decide, at every push, whether the next
#               fork happens in its parent's plane or somewhere else — so they
#               share the table by preloading it rather than copying it, and
#               cannot drift into two vocabularies.
#
#   settlement  WHETHER YOU MEET THE TREE BEFORE OR AFTER IT ARGUES WITH ITSELF.
#               This file's whole reason to exist beside example_8_7_stochastic_
#               tree_vr is the separation phase: grown branches repel their
#               same-level neighbours, level by level, deepest first. Its own
#               truth statement is that a canopy is negotiated rather than
#               designed — and NOBODY HAS EVER SEEN THAT CLAIM, because the
#               negotiation takes separation_duration seconds per level (15 s at
#               the shipped values) and runs exactly once, unwitnessed, while the
#               player is still walking in. `grown` and `settled` are the two
#               ends of that sentence standing still, so the difference is finally
#               something you can look at instead of something you had to be
#               present for.
#
# DEFAULTS ARE THE SHIPPED TREE. habit=planar holds the roll at exactly 0.0 and
# the rotation is SKIPPED rather than applied as a zero turn, so the two axes
# handed to _rotate_vector are the literal Vector3.FORWARD and Vector3.RIGHT
# this file has always passed. settlement=live runs _ready's original tail
# unchanged: reset the deepest level's velocities, is_separating = true,
# set_process(true). rng_seed=0 keeps the shipped randomize().
@export_enum("planar", "fanned", "whorled", "spiral") var habit: String = "planar"
@export_enum("live", "settled", "grown") var settlement: String = "live"

## branching_vine's roll table, READ OUT OF ITS FILE rather than retyped, so the
## two artifacts that share this word cannot end up meaning different angles by
## it. Preloaded rather than reached through the class_name, because class_name
## lookups are not reliable headless and every frame of the evidence loop is
## rendered headless. The script is loaded, never instantiated — no hazard, no
## creature, no CharacterBody3D enters this scene.
const Habit = preload("res://commons/hazards/branching_vine/branching_vine.gd")
const SETTLEMENTS: PackedStringArray = ["live", "settled", "grown"]

## Bench knob, NOT an axis: it argues nothing. 0 is the shipped `randomize()`.
## This artifact is stochastic by name — every angle and every length carries a
## randf_range — so without a fixed seed five swept variants are five different
## trees and any difference measured between them is a fact about the RNG.
@export var rng_seed: int = 0

## Fixed timestep the `settled` pre-roll integrates at, matching the 60 Hz the
## live animation is written against (velocity is accumulated per FRAME here, not
## per second, which is why the number has to be pinned rather than inferred).
const PREROLL_HZ: float = 60.0

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
## True once _ready has grown a tree. apply_grid_config regrows only after this
## and only when a value actually changed, so a config arriving before the first
## build — or one naming nothing this artifact owns — cannot tear anything down.
var _built: bool = false


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
	# rng_seed 0 is the shipped line, untouched. A non-zero value pins every
	# randf_range in the growth AND in the upward alignment, which is the only way
	# five swept variants can be five pictures of ONE tree.
	if rng_seed != 0:
		seed(rng_seed)
	else:
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
	_start_settlement()
	_built = true


## `settlement` — whether the negotiation happens in front of you, happened
## before you arrived, or never happens at all. The `live` branch is _ready's
## original tail, line for line.
func _start_settlement() -> void:
	if _level_order.is_empty():
		return

	if settlement == "grown":
		# The rule's raw output, never argued with: example 8.6 standing inside 8.7.
		is_separating = false
		set_process(false)
		_update_status()
		return

	if settlement == "settled":
		_preroll_separation()
		_update_status()
		return

	_reset_level_velocities(_level_order[_current_level_idx])

	is_separating = true
	set_process(true)


## Run the whole separation the way _process would, at a pinned timestep, before
## the first frame is drawn. Same order (deepest level first), same per-level
## reset, same closing _apply_upward_alignment — so `settled` is where `live`
## ends up, not a different calculation that happens to look similar.
##
## The timestep has to be pinned because the live loop accumulates velocity per
## FRAME (`branch_a.velocity += force`) and only the OFFSET is multiplied by
## delta, so what the tree looks like partway through depends on the machine it
## is running on. That is the shipped behaviour and it is left alone; it is also
## the reason a still of `live` is not reproducible and a still of `settled` is.
func _preroll_separation() -> void:
	var dt: float = 1.0 / PREROLL_HZ
	var steps: int = int(round(max(separation_duration, 0.0) * PREROLL_HZ))
	for idx in range(_level_order.size()):
		_current_level_idx = idx
		_reset_level_velocities(_level_order[idx])
		for _step in range(steps):
			_apply_separation(dt)
		_apply_upward_alignment(_level_order[idx])
	_current_level_idx = _level_order.size()
	_level_timer = 0.0
	separation_timer = max(separation_duration, 0.0) * float(_level_order.size())
	is_separating = false
	set_process(false)

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

## `plane_axis` is the axis the left/right fork turns about and `mid_axis` the one
## the third branch leans out on. The shipped tree passed the WORLD constants
## Vector3.FORWARD and Vector3.RIGHT at every level, which is what these two
## default to and what habit=planar keeps them at, unrotated, all the way down.
func _grow_tree(start_pos: Vector3, direction: Vector3, length: float, thickness: float, depth: int, parent_data: BranchData = null, plane_axis: Vector3 = Vector3.FORWARD, mid_axis: Vector3 = Vector3.RIGHT) -> BranchData:
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

		# habit — roll the branching plane about this branch before forking. At
		# planar the roll is exactly 0.0 and the rotation is SKIPPED, not applied
		# as a zero turn: no float is touched and the two axes handed to
		# _rotate_vector below are the same world constants as before.
		var child_plane: Vector3 = plane_axis
		var child_mid: Vector3 = mid_axis
		var roll_rad: float = deg_to_rad(float(Habit.HABIT_ROLL.get(habit, 0.0)))
		if roll_rad != 0.0:
			var spin: Vector3 = direction.normalized()
			child_plane = plane_axis.rotated(spin, roll_rad).normalized()
			child_mid = mid_axis.rotated(spin, roll_rad).normalized()

		# Left branch
		var left_dir := _rotate_vector(direction, child_plane, angle_left)
		_grow_tree(end_pos, left_dir, length_left, thickness * 0.7, depth - 1, branch_data, child_plane, child_mid)

		# Right branch
		var right_dir := _rotate_vector(direction, child_plane, -angle_right)
		_grow_tree(end_pos, right_dir, length_right, thickness * 0.7, depth - 1, branch_data, child_plane, child_mid)

		# Always add a third branch from level 2 onwards (depth = recursion_depth - 2)
		if depth >= recursion_depth - 1:  # This means we're at level 2
			var mid_dir := _rotate_vector(direction, child_mid, angle_mid)
			_grow_tree(end_pos, mid_dir, length_mid, thickness * 0.65, depth - 1, branch_data, child_plane, child_mid)

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
	elif settlement == "grown":
		# Not "complete": at this value the negotiation never opened.
		status += " | Grown, Not Negotiated"
	else:
		status += " | Separation Complete"
	if habit != "planar":
		status += " | Habit: %s" % habit
	_status_label.text = status

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map tokens: "stochastic_tree_separated#habit:whorled",
## "stochastic_tree_separated#settlement:settled".
##
## GUARDED. This used to be `pass`, so nothing could reach the artifact at all;
## the danger in giving it a body is the opposite one — force_pad tore down every
## child and re-ran _ready on ANY call, including calls naming nothing it owns.
## So: a word the code cannot build is refused rather than accepted and silently
## rendered as the default, and the tree is regrown only when a value ACTUALLY
## changed and only after _ready has grown one.
func apply_grid_config(config: Dictionary) -> void:
	var before_habit: String = habit
	var before_settlement: String = settlement
	var before_seed: int = rng_seed

	if config.has("habit"):
		var want_habit: String = str(config["habit"]).strip_edges().to_lower()
		if Habit.HABIT_ROLL.has(want_habit):
			habit = want_habit
		elif want_habit != "":
			push_warning("stochastic_tree_separated: unknown habit '%s' — keeping '%s'"
				% [want_habit, habit])

	if config.has("settlement"):
		var want_settlement: String = str(config["settlement"]).strip_edges().to_lower()
		if SETTLEMENTS.has(want_settlement):
			settlement = want_settlement
		elif want_settlement != "":
			push_warning("stochastic_tree_separated: unknown settlement '%s' — keeping '%s'"
				% [want_settlement, settlement])

	if config.has("rng_seed"):
		rng_seed = int(config["rng_seed"])

	if not _built:
		return
	if habit == before_habit and settlement == before_settlement and rng_seed == before_seed:
		return
	_regrow()


## Free the tree and grow another. Only reached from apply_grid_config, and only
## when a value that the growth depends on has changed.
func _regrow() -> void:
	set_process(false)
	is_separating = false
	branches.clear()
	branch_levels.clear()
	_level_order.clear()
	_current_level_idx = 0
	_level_timer = 0.0
	separation_timer = 0.0
	if _sim_root != null and is_instance_valid(_sim_root):
		remove_child(_sim_root)
		_sim_root.queue_free()
	_sim_root = null
	_status_label = null
	_built = false
	_ready()
