class_name IKArmDemo
extends Node3D
## IKArmDemo — Standalone showcase of TwoBoneIK3D arm inverse kinematics
##
## Two procedural arms (left + right) with animated targets tracing
## figure-8 patterns. Demonstrates the same IK solver used for VR body
## tracking, but without VR — pure algorithmic choreography.
## "The reach is not fixed but negotiated frame by frame."

# @identity
# essence: Two procedural TwoBoneIK3D arms tracing figure-8 patterns — inverse kinematics as embodiment negotiation
# desire: To show how VR arms work: skeleton, bone chain, target marker, and the solver that bends joints to reach
# critical_parameter: upper_arm_length + lower_arm_length — the reach envelope; targets beyond this sum reveal the solver limits
# triggers: Figure-8 targets push arms through full range; near-limit reaches show elbow flip; symmetric motion reveals bilateral IK
# emerges: Fluid arm motion from a two-bone chain solver — the same algorithm that connects floating VR hands to shoulders
# needs: Procedural skeleton [has], animated targets [has], joint markers [has], VR hand tracking [missing — demo only]
# relationships: Core artifact in BodyProg_Arms. Bridges body progression and spatial algorithms. Uses Skeleton3D + SkeletonIK3D.
# truth: The arm does not move — the target moves, and the arm solves for how to follow.

## ————————————————————————————————————————————————————————————————————
## Configuration
## ————————————————————————————————————————————————————————————————————

@export var arm_color: Color = Color(0.85, 0.75, 0.65)
@export var shoulder_width: float = 0.36
@export var upper_arm_length: float = 0.28
@export var lower_arm_length: float = 0.25

var _left_arm: Node3D
var _right_arm: Node3D
var _left_target: Marker3D
var _right_target: Marker3D
var _left_skeleton: Skeleton3D
var _right_skeleton: Skeleton3D
var _torso_mesh: MeshInstance3D
var _shoulder_left_marker: MeshInstance3D
var _shoulder_right_marker: MeshInstance3D
var _time: float = 0.0

const RING_SEGMENTS: int = 8
const RING_RADII: Array[float] = [0.04, 0.035, 0.03, 0.02]

func _ready() -> void:
	# Torso body — a simple capsule shape
	_build_torso()

	# Build left arm
	_left_arm = Node3D.new()
	_left_arm.name = "LeftArm"
	add_child(_left_arm)
	_left_arm.position = Vector3(-shoulder_width / 2.0, 0.6, 0.0)
	_left_skeleton = _build_arm(_left_arm, true)

	# Build right arm
	_right_arm = Node3D.new()
	_right_arm.name = "RightArm"
	add_child(_right_arm)
	_right_arm.position = Vector3(shoulder_width / 2.0, 0.6, 0.0)
	_right_skeleton = _build_arm(_right_arm, false)

	# Build animated target spheres
	_left_target = _left_arm.get_node("IKTarget")
	_right_target = _right_arm.get_node("IKTarget")

	# Add visible target spheres
	_add_target_sphere(_left_target, Color.ORANGE_RED)
	_add_target_sphere(_right_target, Color.DODGER_BLUE)

	# Shoulder joint markers
	_shoulder_left_marker = _make_joint_sphere(_left_arm.position, Color.YELLOW, 0.03)
	_shoulder_right_marker = _make_joint_sphere(_right_arm.position, Color.YELLOW, 0.03)


func _physics_process(delta: float) -> void:
	_time += delta

	# Animate targets in a figure-8 / reaching pattern
	var reach: float = upper_arm_length + lower_arm_length - 0.05

	# Left arm: figure-8 in front-left
	var lx: float = -0.15 + sin(_time * 1.2) * 0.15
	var ly: float = -0.15 + sin(_time * 0.8) * 0.2
	var lz: float = -0.2 - cos(_time * 1.2) * 0.1
	_left_target.position = Vector3(lx, ly, lz)

	# Right arm: offset figure-8 in front-right
	var rx: float = 0.15 + sin(_time * 1.2 + PI) * 0.15
	var ry: float = -0.15 + cos(_time * 0.8) * 0.2
	var rz: float = -0.2 - sin(_time * 1.2 + PI) * 0.1
	_right_target.position = Vector3(rx, ry, rz)


func _build_torso() -> void:
	# Simple cylinder torso between shoulders
	_torso_mesh = MeshInstance3D.new()
	_torso_mesh.name = "TorsoMesh"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.12
	capsule.height = 0.5
	_torso_mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arm_color.darkened(0.15)
	mat.roughness = 0.8
	_torso_mesh.material_override = mat
	_torso_mesh.position = Vector3(0, 0.4, 0)
	add_child(_torso_mesh)

	# Head sphere
	var head := MeshInstance3D.new()
	head.name = "Head"
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	head.mesh = sphere
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = arm_color
	head_mat.roughness = 0.6
	head.material_override = head_mat
	head.position = Vector3(0, 0.75, 0)
	add_child(head)


func _build_arm(parent: Node3D, is_left: bool) -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	skeleton.name = "ArmSkeleton"
	parent.add_child(skeleton)

	# Bones
	var idx_upper := skeleton.add_bone("UpperArm")
	skeleton.set_bone_rest(idx_upper, Transform3D(Basis.IDENTITY, Vector3.ZERO))

	var idx_lower := skeleton.add_bone("LowerArm")
	skeleton.set_bone_parent(idx_lower, idx_upper)
	skeleton.set_bone_rest(idx_lower, Transform3D(Basis.IDENTITY, Vector3(0, -upper_arm_length, 0)))

	var idx_hand := skeleton.add_bone("Hand")
	skeleton.set_bone_parent(idx_hand, idx_lower)
	skeleton.set_bone_rest(idx_hand, Transform3D(Basis.IDENTITY, Vector3(0, -lower_arm_length, 0)))

	# IK target
	var ik_target := Marker3D.new()
	ik_target.name = "IKTarget"
	parent.add_child(ik_target)
	ik_target.position = Vector3(0, -(upper_arm_length + lower_arm_length), 0)

	# Pole target (elbow hint)
	var pole_target := Marker3D.new()
	pole_target.name = "PoleTarget"
	parent.add_child(pole_target)
	var pole_x: float = -0.15 if is_left else 0.15
	pole_target.position = Vector3(pole_x, -upper_arm_length * 0.5, -0.3)

	# TwoBoneIK3D modifier
	var two_bone := TwoBoneIK3D.new()
	two_bone.name = "TwoBoneIK"
	two_bone.root_bone = "UpperArm"
	two_bone.tip_bone = "Hand"
	two_bone.target_node = ik_target.get_path()
	two_bone.pole_node = pole_target.get_path()
	two_bone.use_pole_node = true
	skeleton.add_child(two_bone)

	# Procedural skinned mesh
	_build_arm_mesh(skeleton, idx_upper, idx_lower, idx_hand)

	return skeleton


func _build_arm_mesh(skeleton: Skeleton3D, idx_upper: int, idx_lower: int, idx_hand: int) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var bone_indices_arr := PackedInt32Array()
	var bone_weights_arr := PackedFloat32Array()

	var hand_length: float = 0.08
	var ring_y: Array[float] = [0.0, -upper_arm_length, -(upper_arm_length + lower_arm_length), -(upper_arm_length + lower_arm_length + hand_length)]
	var ring_bone: Array[int] = [idx_upper, idx_lower, idx_hand, idx_hand]

	for ring_idx in range(ring_y.size()):
		var y: float = ring_y[ring_idx]
		var radius: float = RING_RADII[ring_idx]
		var bone_idx: int = ring_bone[ring_idx]

		for seg in range(RING_SEGMENTS):
			var angle: float = (float(seg) / float(RING_SEGMENTS)) * TAU
			vertices.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
			normals.append(Vector3(cos(angle), 0, sin(angle)).normalized())
			bone_indices_arr.append(bone_idx)
			bone_indices_arr.append(0)
			bone_indices_arr.append(0)
			bone_indices_arr.append(0)
			bone_weights_arr.append(1.0)
			bone_weights_arr.append(0.0)
			bone_weights_arr.append(0.0)
			bone_weights_arr.append(0.0)

	for ring_idx in range(ring_y.size() - 1):
		var base_curr: int = ring_idx * RING_SEGMENTS
		var base_next: int = (ring_idx + 1) * RING_SEGMENTS
		for seg in range(RING_SEGMENTS):
			var s0: int = seg
			var s1: int = (seg + 1) % RING_SEGMENTS
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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = arm_color
	mat.roughness = 0.7
	arm_mesh.surface_set_material(0, mat)

	var skin := Skin.new()
	skin.set_bind_count(skeleton.get_bone_count())
	for bone_i in range(skeleton.get_bone_count()):
		skin.set_bind_bone(bone_i, bone_i)
		skin.set_bind_pose(bone_i, skeleton.get_bone_rest(bone_i).affine_inverse())

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "ArmMesh"
	mesh_inst.mesh = arm_mesh
	mesh_inst.skin = skin
	mesh_inst.skeleton = skeleton.get_path()
	skeleton.add_child(mesh_inst)


func _add_target_sphere(target: Marker3D, color: Color) -> void:
	var sphere_mesh := MeshInstance3D.new()
	sphere_mesh.name = "TargetVisual"
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.05
	sphere_mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	sphere_mesh.material_override = mat
	target.add_child(sphere_mesh)


func _make_joint_sphere(pos: Vector3, color: Color, radius: float = 0.02) -> MeshInstance3D:
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sphere.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	sphere.material_override = mat
	sphere.position = pos
	add_child(sphere)
	return sphere


func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
