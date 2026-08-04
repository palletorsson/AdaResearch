# @identity
# essence: choreographed permutation — rows of grid cubes rotated in axis-banded segments
# desire: read the grid as a score: 6 rows Z, 4 flat, 6 Y, 4 flat, 6 X-negative, 4 flat, 6 all, 8 flat
# critical_parameter: PATTERN — the ordered list of (row_count, axis) bands that defines the cycle length
# triggers: _ready() computes section starts and binds to the GridMultiMesh; tween animations apply rotation per section
# emerges: a moving stripe of axis-aligned tilts that sweeps through the grid revealing structural anisotropy
# needs: pattern editor [now `score`, five band lists]; per-axis amount sliders [missing]; cycle pause control [missing]
# relationships: cousin of RotateScaleCubes (combined transforms); contrast to BlueNoise which redistributes positions, this redistributes orientations
# truth: The grid is a stack of choices. Which axis turns where, in which order, IS the music — randomness lives in the score, not the dance.

extends Node3D
class_name RotateGridCubes

## RotateGridCubes.gd
## Rotation pattern: Z → flat → Y → flat → X(neg) → flat → All → flat
## Also rotates collision cubes to match

@export var rot_amount: float = 35.0
@export var rot_amount_y: float = 25.0
@export var use_animation: bool = true
@export var rotation_duration: float = 1.0

# --- STAGE-2 DNA (promoted 2026-08-03) ---------------------------------------
# The degrees were already exposed and they are the least interesting thing here.
# What this artifact ARGUES is the SCORE: which rows turn, in what phrasing, and
# in which direction that phrasing is read across the lattice. Both were const.
#
#   score  the ordered band list. "bands" is the shipped PATTERN const, byte for
#          byte, so it is the default.
#   grain  which coordinate the band index reads. "rows" is the
#          int(round(pos.z)) this file has always used, so it is the default.
@export_enum("bands", "alternate", "cascade", "solid", "sparse") var score: String = "bands"
@export_enum("rows", "columns", "diagonal", "rings") var grain: String = "rows"

@export_group("MultiMesh")
@export var multimesh_path: NodePath = "../GridMultiMesh"

var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var initial_transforms: Array[Transform3D] = []

# Pattern definition: [rotation_rows, flat_rows, axis] 
# axis: 0=Z, 1=Y, 2=X(negative), 3=All
const PATTERN = [
	[6, "z"],   # 6 rows Z rotation
	[4, "flat"],  # 4 rows flat
	[6, "y"],   # 6 rows Y rotation
	[4, "flat"],  # 4 rows flat
	[6, "x_neg"], # 6 rows X rotation (negative)
	[4, "flat"],  # 4 rows flat
	[6, "all"],  # 6 rows All axes
	[8, "flat"],  # 8 rows flat
]

# The other four scores. Same grammar as PATTERN — [row_count, axis] bands — so
# every one of them runs through the same _calculate_pattern / get_rotation_for_row
# machinery and nothing below this line needed a special case.
#   alternate  every other index tilts: the transformation as a high-frequency
#              weave, no phrasing at all
#   cascade    one index per axis, walking Z→Y→X→all: a continuous shear rather
#              than a repetition
#   solid      no flat rows anywhere: the null hypothesis, applied uniformly
#   sparse     one tilt every eight: rotation as a rare event, a stitch
const SCORE_ALTERNATE = [[1, "all"], [1, "flat"]]
const SCORE_CASCADE = [[1, "z"], [1, "y"], [1, "x_neg"], [1, "all"]]
const SCORE_SOLID = [[1, "all"]]
const SCORE_SPARSE = [[1, "all"], [7, "flat"]]

const SCORE_NAMES = ["bands", "alternate", "cascade", "solid", "sparse"]
const GRAIN_NAMES = ["rows", "columns", "diagonal", "rings"]

var _cycle_length: int = 0
var _section_starts: Array[int] = []
var _pattern: Array = PATTERN

func _ready() -> void:
	# Calculate cycle length and section starts
	_calculate_pattern()
	
	# Find MultiMesh
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("RotateGridCubes: Found MultiMesh with %d instances" % multimesh.instance_count)

			# Store initial transforms
			for i in range(multimesh.instance_count):
				initial_transforms.append(multimesh.get_instance_transform(i))

			rotate_all_cubes()
			
			# Rotate collision cubes after a short delay
			call_deferred("_rotate_collision_cubes")

func _score_pattern() -> Array:
	match score:
		"alternate":
			return SCORE_ALTERNATE
		"cascade":
			return SCORE_CASCADE
		"solid":
			return SCORE_SOLID
		"sparse":
			return SCORE_SPARSE
		"bands", _:
			return PATTERN


## Which coordinate the band index reads. "rows" is int(round(pos.z)), the only
## thing this file ever did, so the default is unchanged for every placement.
func _index_for(pos: Vector3) -> int:
	match grain:
		"columns":
			return int(round(pos.x))
		"diagonal":
			return int(round(pos.x + pos.z))
		"rings":
			return int(round(sqrt(pos.x * pos.x + pos.z * pos.z)))
		"rows", _:
			return int(round(pos.z))


func _calculate_pattern() -> void:
	_pattern = _score_pattern()
	_cycle_length = 0
	_section_starts.clear()
	for section in _pattern:
		_section_starts.append(_cycle_length)
		_cycle_length += section[0]
	print("RotateGridCubes: score '%s' cycle = %d rows, grain '%s'" % [score, _cycle_length, grain])

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func rotate_all_cubes() -> void:
	if not multimesh:
		return

	print("RotateGridCubes: Applying Z→flat→Y→flat→X(-)→flat→All→flat pattern")

	if use_animation:
		animate_rotation()
	else:
		apply_rotation()

func apply_rotation() -> void:
	for i in range(multimesh.instance_count):
		var transform = initial_transforms[i] if i < initial_transforms.size() else multimesh.get_instance_transform(i)
		var pos = transform.origin
		var rot = get_rotation_for_row(_index_for(pos))

		var rot_basis = Basis()
		rot_basis = rot_basis.rotated(Vector3.BACK, deg_to_rad(rot.z))
		rot_basis = rot_basis.rotated(Vector3.RIGHT, deg_to_rad(rot.x))
		rot_basis = rot_basis.rotated(Vector3.UP, deg_to_rad(rot.y))

		transform.basis = rot_basis
		multimesh.set_instance_transform(i, transform)

func get_rotation_for_row(row: int) -> Vector3:
	## Pattern (44 rows total cycle):
	## 0-5:   Z rotation 25°
	## 6-9:   flat
	## 10-15: Y rotation 25°
	## 16-19: flat
	## 20-25: X rotation -25°
	## 26-29: flat
	## 30-35: All axes 25°
	## 36-43: flat
	
	# Normalize row to positive
	if row < 0:
		row = -row
	
	# Get position in cycle
	var cycle_pos = row % _cycle_length
	
	# Find which section we're in
	var section_idx = 0
	for i in range(_section_starts.size()):
		if i + 1 < _section_starts.size():
			if cycle_pos >= _section_starts[i] and cycle_pos < _section_starts[i + 1]:
				section_idx = i
				break
		else:
			section_idx = i
	
	var section_type = _pattern[section_idx][1]
	
	match section_type:
		"z":
			return Vector3(0, 0, rot_amount)
		"y":
			return Vector3(0, rot_amount_y, 0)  # Y uses 25°
		"x_neg":
			return Vector3(-rot_amount, 0, 0)  # Negative X
		"all":
			return Vector3(-rot_amount, rot_amount_y, rot_amount)  # X negative, Y uses 25°
		"flat", _:
			return Vector3.ZERO

func animate_rotation() -> void:
	var tween = create_tween()
	
	tween.tween_method(func(progress: float):
		for i in range(multimesh.instance_count):
			var transform = initial_transforms[i] if i < initial_transforms.size() else Transform3D()
			var pos = transform.origin
			var target_rot = get_rotation_for_row(_index_for(pos))
			var current_rot = target_rot * progress

			var rot_basis = Basis()
			rot_basis = rot_basis.rotated(Vector3.BACK, deg_to_rad(current_rot.z))
			rot_basis = rot_basis.rotated(Vector3.RIGHT, deg_to_rad(current_rot.x))
			rot_basis = rot_basis.rotated(Vector3.UP, deg_to_rad(current_rot.y))

			transform.basis = rot_basis
			multimesh.set_instance_transform(i, transform)
	, 0.0, 1.0, rotation_duration)

	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func _rotate_collision_cubes() -> void:
	# Find GridCollisions node
	var collision_parent = get_parent().get_node_or_null("GridCollisions")
	if not collision_parent:
		print("RotateGridCubes: No GridCollisions found")
		return
	
	var rotated_count = 0
	for child in collision_parent.get_children():
		if child is StaticBody3D:
			var pos = child.position
			var row: int = _index_for(pos)
			var rot = get_rotation_for_row(row)
			
			# Apply rotation to collision body
			child.rotation_degrees = Vector3(rot.x, rot.y, rot.z)
			rotated_count += 1
	
	print("RotateGridCubes: Rotated %d collision cubes" % rotated_count)

# Simple config for map parameters.
#
# GUARDED (2026-08-03). This used to re-apply on every call whether or not any
# value had changed, which re-fired the tween for placements that pass no keys
# at all. Now it only re-applies when a value actually moved, and only once
# _ready has found a host grid — so a shipped map that sets nothing gets exactly
# the picture _ready built.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false

	if config.has("rotation"):
		var deg: float = float(config["rotation"])
		if not is_equal_approx(deg, rot_amount):
			rot_amount = deg
			changed = true
	if config.has("animate"):
		var anim: bool = str(config["animate"]).to_lower() == "true"
		if anim != use_animation:
			use_animation = anim
			changed = true
	# The sweep sets exports by their own name, so accept that spelling too.
	if config.has("use_animation"):
		var anim2: bool = str(config["use_animation"]).to_lower() != "false"
		if anim2 != use_animation:
			use_animation = anim2
			changed = true
	if config.has("duration"):
		var dur: float = float(config["duration"])
		if not is_equal_approx(dur, rotation_duration):
			rotation_duration = dur
			changed = true
	if config.has("score"):
		var s: String = str(config["score"])
		if s != score and SCORE_NAMES.has(s):
			score = s
			_calculate_pattern()
			changed = true
	if config.has("grain"):
		var g: String = str(config["grain"])
		if g != grain and GRAIN_NAMES.has(g):
			grain = g
			changed = true

	if not changed:
		return
	if multimesh and multimesh.instance_count > 0:
		rotate_all_cubes()
		_rotate_collision_cubes()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
