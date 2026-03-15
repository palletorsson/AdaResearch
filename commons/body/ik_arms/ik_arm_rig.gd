class_name IKArmRig
extends Node3D
## IKArmRig — Single-arm IK rig using TwoBoneIK3D
##
## Creates a Skeleton3D with three bones (UpperArm, LowerArm, Hand),
## a TwoBoneIK3D modifier, procedural skinned mesh, and IK targets.
## Each arm extends the boundary between self and world —
## the reach is not fixed but negotiated frame by frame.

## ————————————————————————————————————————————————————————————————————
## Exports
## ————————————————————————————————————————————————————————————————————

## True for left arm, false for right.
@export var is_left: bool = false

## Base color for the procedural arm mesh.
@export var arm_color: Color = Color(0.85, 0.75, 0.65)

## Bone lengths (meters).
@export var upper_arm_length: float = 0.28
@export var lower_arm_length: float = 0.25

## Hand bone length (cosmetic, not part of IK chain solve).
var hand_length: float = 0.08

## ————————————————————————————————————————————————————————————————————
## Internal references
## ————————————————————————————————————————————————————————————————————

var _skeleton: Skeleton3D
var _two_bone_ik: TwoBoneIK3D
var _ik_target: Marker3D
var _pole_target: Marker3D
var _controller: Node3D
var _mesh_instance: MeshInstance3D

## Bone indices
var _idx_upper: int = -1
var _idx_lower: int = -1
var _idx_hand: int = -1

## Ring radii for the tapered procedural mesh (shoulder → elbow → wrist → tip)
const RING_RADII: Array[float] = [0.04, 0.035, 0.03, 0.02]
const RING_SEGMENTS: int = 8

## ————————————————————————————————————————————————————————————————————
## Lifecycle
## ————————————————————————————————————————————————————————————————————

func _ready() -> void:
	_build_skeleton()
	_build_ik_targets()
	_build_two_bone_ik()
	_build_procedural_mesh()

	var side_label: String = "Left" if is_left else "Right"
	print("[IKArmRig] %s arm rig built — bones: %.2f + %.2f + %.2f m" % [
		side_label, upper_arm_length, lower_arm_length, hand_length
	])


func _physics_process(_delta: float) -> void:
	## 1. IK target follows the XR controller
	if is_instance_valid(_controller):
		_ik_target.global_position = _controller.global_position

	## 2. Pole target (elbow hint): forward 0.3 + down 0.2 from shoulder
	var shoulder_pos: Vector3 = global_position
	var fwd: Vector3 = -global_basis.z if global_basis.z.length_squared() > 0.001 else Vector3.FORWARD
	_pole_target.global_position = shoulder_pos + fwd.normalized() * 0.3 + Vector3.DOWN * 0.2

	## 3. After TwoBoneIK3D solves, override Hand bone rotation to match controller
	##    This is a workaround for the known TwoBoneIK3D bug where the tip bone
	##    rotation is not constrained to the target's orientation.
	if is_instance_valid(_controller) and _idx_hand >= 0:
		var hand_global_xform: Transform3D = _skeleton.global_transform * _skeleton.get_bone_global_pose(_idx_hand)
		var parent_global: Transform3D = _skeleton.global_transform * _skeleton.get_bone_global_pose(_idx_lower)
		var desired_local_basis: Basis = parent_global.basis.inverse() * _controller.global_basis
		var current_pose: Transform3D = _skeleton.get_bone_pose(_idx_hand)
		current_pose.basis = desired_local_basis
		_skeleton.set_bone_pose(_idx_hand, current_pose)


## ————————————————————————————————————————————————————————————————————
## Public API
## ————————————————————————————————————————————————————————————————————

## Assign the XR controller this arm should track.
func set_controller(node: Node3D) -> void:
	_controller = node


## Update the shoulder pivot (called by PlayerBodyIK from TorsoEstimator).
func set_shoulder_position(pos: Vector3) -> void:
	global_position = pos


## Change the arm mesh color at runtime.
func set_arm_color(color: Color) -> void:
	arm_color = color
	if is_instance_valid(_mesh_instance):
		var mat := _mesh_instance.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = arm_color


## ————————————————————————————————————————————————————————————————————
## Build helpers
## ————————————————————————————————————————————————————————————————————

func _build_skeleton() -> void:
	_skeleton = Skeleton3D.new()
	_skeleton.name = "ArmSkeleton"
	add_child(_skeleton)

	## Bone 0: UpperArm — root bone, extends downward along -Y in rest pose
	_idx_upper = _skeleton.add_bone("UpperArm")
	_skeleton.set_bone_rest(_idx_upper, Transform3D(Basis.IDENTITY, Vector3.ZERO))

	## Bone 1: LowerArm — child of UpperArm
	_idx_lower = _skeleton.add_bone("LowerArm")
	_skeleton.set_bone_parent(_idx_lower, _idx_upper)
	_skeleton.set_bone_rest(_idx_lower, Transform3D(Basis.IDENTITY, Vector3(0, -upper_arm_length, 0)))

	## Bone 2: Hand — child of LowerArm
	_idx_hand = _skeleton.add_bone("Hand")
	_skeleton.set_bone_parent(_idx_hand, _idx_lower)
	_skeleton.set_bone_rest(_idx_hand, Transform3D(Basis.IDENTITY, Vector3(0, -lower_arm_length, 0)))


func _build_ik_targets() -> void:
	## IK target — tracks controller position
	_ik_target = Marker3D.new()
	_ik_target.name = "IKTarget"
	add_child(_ik_target)
	_ik_target.position = Vector3(0, -(upper_arm_length + lower_arm_length), 0)

	## Pole target — elbow hint
	_pole_target = Marker3D.new()
	_pole_target.name = "PoleTarget"
	add_child(_pole_target)
	_pole_target.position = Vector3(0, -upper_arm_length * 0.5, 0.3)


func _build_two_bone_ik() -> void:
	_two_bone_ik = TwoBoneIK3D.new()
	_two_bone_ik.name = "TwoBoneIK"
	_two_bone_ik.root_bone = "UpperArm"
	_two_bone_ik.tip_bone = "Hand"
	_two_bone_ik.target_node = _ik_target.get_path()
	_two_bone_ik.pole_node = _pole_target.get_path()
	_two_bone_ik.use_pole_node = true
	_skeleton.add_child(_two_bone_ik)


func _build_procedural_mesh() -> void:
	## Octapod-pattern procedural mesh: rings at each bone joint, tapered cylinder
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var bone_indices_arr: PackedInt32Array = PackedInt32Array()
	var bone_weights_arr: PackedFloat32Array = PackedFloat32Array()

	## Ring positions along the arm (local Y, pointing downward from shoulder)
	var ring_y_positions: Array[float] = [
		0.0,                                           # shoulder (UpperArm origin)
		-upper_arm_length,                             # elbow (LowerArm origin)
		-(upper_arm_length + lower_arm_length),        # wrist (Hand origin)
		-(upper_arm_length + lower_arm_length + hand_length) # hand tip
	]

	## Which bone owns each ring (100% weight to nearest bone)
	var ring_bone_index: Array[int] = [
		_idx_upper,  # shoulder ring → UpperArm
		_idx_lower,  # elbow ring → LowerArm
		_idx_hand,   # wrist ring → Hand
		_idx_hand    # tip ring → Hand
	]

	## Generate ring vertices
	for ring_idx in range(ring_y_positions.size()):
		var y: float = ring_y_positions[ring_idx]
		var radius: float = RING_RADII[ring_idx]
		var bone_idx: int = ring_bone_index[ring_idx]

		for seg in range(RING_SEGMENTS):
			var angle: float = (float(seg) / float(RING_SEGMENTS)) * TAU
			var x: float = cos(angle) * radius
			var z: float = sin(angle) * radius

			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(x, 0, z).normalized())

			## 4 bone indices per vertex, 4 weights per vertex (Godot skinning format)
			bone_indices_arr.append(bone_idx)
			bone_indices_arr.append(0)
			bone_indices_arr.append(0)
			bone_indices_arr.append(0)
			bone_weights_arr.append(1.0)
			bone_weights_arr.append(0.0)
			bone_weights_arr.append(0.0)
			bone_weights_arr.append(0.0)

	## Generate triangle indices between adjacent rings
	for ring_idx in range(ring_y_positions.size() - 1):
		var base_curr: int = ring_idx * RING_SEGMENTS
		var base_next: int = (ring_idx + 1) * RING_SEGMENTS
		for seg in range(RING_SEGMENTS):
			var s0: int = seg
			var s1: int = (seg + 1) % RING_SEGMENTS
			## Quad as two triangles
			indices.append(base_curr + s0)
			indices.append(base_next + s0)
			indices.append(base_next + s1)

			indices.append(base_curr + s0)
			indices.append(base_next + s1)
			indices.append(base_curr + s1)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_BONES] = bone_indices_arr
	arrays[Mesh.ARRAY_WEIGHTS] = bone_weights_arr

	var arm_mesh := ArrayMesh.new()
	arm_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	## Material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arm_color
	mat.roughness = 0.7
	arm_mesh.surface_set_material(0, mat)

	## Skin resource with bind poses
	var skin := Skin.new()
	for bone_i in range(_skeleton.get_bone_count()):
		skin.add_bind(_skeleton.get_bone_count()) # placeholder, resized below
	skin.set_bind_count(_skeleton.get_bone_count())
	for bone_i in range(_skeleton.get_bone_count()):
		skin.set_bind_bone(bone_i, bone_i)
		skin.set_bind_pose(bone_i, _skeleton.get_bone_rest(bone_i).affine_inverse())

	## MeshInstance3D
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "ArmMesh"
	_mesh_instance.mesh = arm_mesh
	_mesh_instance.skin = skin
	_mesh_instance.skeleton = _skeleton.get_path()
	_skeleton.add_child(_mesh_instance)
