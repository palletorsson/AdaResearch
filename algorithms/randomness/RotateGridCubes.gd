extends Node3D

## RotateGridCubes.gd
## Rotation pattern: Z → flat → Y → flat → X(neg) → flat → All → flat
## Also rotates collision cubes to match

@export var rot_amount: float = 35.0
@export var rot_amount_y: float = 25.0
@export var use_animation: bool = true
@export var rotation_duration: float = 1.0

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

var _cycle_length: int = 0
var _section_starts: Array[int] = []

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

func _calculate_pattern() -> void:
	_cycle_length = 0
	_section_starts.clear()
	for section in PATTERN:
		_section_starts.append(_cycle_length)
		_cycle_length += section[0]
	print("RotateGridCubes: Pattern cycle = %d rows" % _cycle_length)

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
		var rot = get_rotation_for_row(int(round(pos.z)))

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
	
	var section_type = PATTERN[section_idx][1]
	
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
			var target_rot = get_rotation_for_row(int(round(pos.z)))
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
			var row = int(round(pos.z))
			var rot = get_rotation_for_row(row)
			
			# Apply rotation to collision body
			child.rotation_degrees = Vector3(rot.x, rot.y, rot.z)
			rotated_count += 1
	
	print("RotateGridCubes: Rotated %d collision cubes" % rotated_count)

# Simple config for map parameters
func apply_grid_config(config: Dictionary) -> void:
	if config.has("rotation"):
		rot_amount = float(config["rotation"])
	if config.has("animate"):
		use_animation = str(config["animate"]).to_lower() == "true"
	if config.has("duration"):
		rotation_duration = float(config["duration"])
	
	if multimesh and multimesh.instance_count > 0:
		rotate_all_cubes()
		_rotate_collision_cubes()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
