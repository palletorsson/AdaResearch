class_name IKArmRig
extends Node3D
## IKArmRig — Single-arm IK rig using TwoBoneIK3D
##
## Creates a Skeleton3D with three bones (UpperArm, LowerArm, Hand),
## a TwoBoneIK3D modifier, procedural skinned mesh, and IK targets.
## Each arm extends the boundary between self and world —
## the reach is not fixed but negotiated frame by frame.

## PRELOAD, NOT class_name. A headless run has no editor class cache, so a
## global class_name resolves in the editor and fails at the command line —
## which is where every gate in this project runs.
const Tartan = preload("res://commons/body/tartan.gd")

## ————————————————————————————————————————————————————————————————————
## Exports
## ————————————————————————————————————————————————————————————————————

## True for left arm, false for right.
@export var is_left: bool = false

## Tint over the tartan. White shows the cloth as woven; a colour shades it.
@export var arm_color: Color = Color(1.0, 1.0, 1.0)

## Bone lengths (meters).
@export var upper_arm_length: float = 0.28
@export var lower_arm_length: float = 0.25

## Nominal hand length. NOT drawn since 2026-08-29 and not part of the IK
## solve — the Hand bone ends the chain and carries the wrist orientation,
## and the visible hand past the wrist is xr-tools own.
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
## THE HAND'S OWN WRIST BONE, when there is one. See _find_wrist().
var _hand_skel: Skeleton3D = null
var _wrist_bone: int = -1
var _wrist_retry: int = 0

## Bone indices
var _idx_upper: int = -1
var _idx_lower: int = -1
var _idx_hand: int = -1

## Ring radii for the tapered procedural mesh: shoulder → elbow → WRIST, and it
## stops there. Palle, 2026-08-29: "3 parts might be one too many. I feel like
## the hand should be the 3rd part." There was a fourth ring at
## wrist + hand_length, which drew a third tapered tube past the wrist — so the
## arm read as upper, fore and a second small forearm where a hand should be.
## The third part is the VR hand itself, which xr-tools already draws and which
## the wrist now meets exactly.
const RING_RADII: Array[float] = [0.04, 0.035, 0.03]
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
	print("[IKArmRig] %s arm: upper %.2f + fore %.2f = %.2f m to the wrist, "
		% [side_label, upper_arm_length, lower_arm_length,
		   upper_arm_length + lower_arm_length]
		+ "then the VR hand")


func _physics_process(_delta: float) -> void:
	## 1. The IK target follows the HAND'S WRIST, falling back to the controller
	## when the hand has no skeleton. See _find_wrist.
	if is_instance_valid(_controller):
		## KEEP LOOKING UNTIL IT IS THERE. set_controller runs when PlayerBodyIK
		## enters the tree, and the hand model may be mounted after that — in the
		## probe it certainly is, and on the live rig the order is nobody's
		## guarantee. Binding once meant silently falling back to the controller
		## and looking exactly like the bug it was meant to fix. Retried about
		## twice a second until found, then never again.
		if _hand_skel == null:
			_wrist_retry += 1
			if _wrist_retry % 30 == 0:
				_find_wrist(_controller)
				if _hand_skel != null:
					print("[IKArmRig] %s sleeve ends at %s (found late)" % [
						("Left" if is_left else "Right"), _hand_skel.get_bone_name(_wrist_bone)])
		_ik_target.global_position = _wrist_xform().origin

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
		## the cuff takes the WRIST's roll, not the controller's — they differ by
		## whatever the hand model's rest applies, and using the controller twists
		## the sleeve against the hand it is supposed to meet.
		var desired_local_basis: Basis = parent_global.basis.inverse() * _wrist_xform().basis.orthonormalized()
		var current_pose: Transform3D = _skeleton.get_bone_pose(_idx_hand)
		current_pose.basis = desired_local_basis
		_skeleton.set_bone_pose(_idx_hand, current_pose)


## ————————————————————————————————————————————————————————————————————
## Public API
## ————————————————————————————————————————————————————————————————————

## Assign the XR controller this arm should track.
func set_controller(node: Node3D) -> void:
	_controller = node
	_hand_skel = null
	_wrist_bone = -1
	if node != null:
		_find_wrist(node)
	if _hand_skel != null:
		print("[IKArmRig] %s sleeve ends at %s" % [
			("Left" if is_left else "Right"), _hand_skel.get_bone_name(_wrist_bone)])


## THE CONTROLLER IS NOT THE WRIST (2026-08-29, Palle, from inside the headset:
## "there is still a mismatch, the hand has many bones — can you attach the arms
## to the last bone in the hand?").
##
## An XRController3D sits at the grip pose the runtime reports, which is inside
## the fist and rotated to the device. The visible hand is a SKINNED MODEL hung
## off it — commons/body/hands/left_hand.tscn, whose Skeleton3D carries 16 bones
## with `Wrist_L` at index 0, parent -1. Targeting the controller therefore lands
## the sleeve near the hand and never ON it, however the numbers are tuned; the
## offset is whatever that model happens to apply, and it is not ours to guess.
##
## So the arm ends where the hand BEGINS: the wrist bone's own transform. Found
## once and cached — walking the subtree every frame to ask the same question is
## how a rig gets slow for no reason.
func _find_wrist(from: Node) -> void:
	var skel := from as Skeleton3D
	if skel != null:
		for b in range(skel.get_bone_count()):
			var nm := String(skel.get_bone_name(b))
			# the hand's root: named Wrist, or whatever bone has no parent
			if nm.begins_with("Wrist") or skel.get_bone_parent(b) == -1:
				_hand_skel = skel
				_wrist_bone = b
				return
	for c in from.get_children():
		if _hand_skel == null:
			_find_wrist(c)


## Where the sleeve should end, in world space: the hand's wrist if the hand has
## one, the controller if it does not.
func _wrist_xform() -> Transform3D:
	if _hand_skel != null and is_instance_valid(_hand_skel) and _wrist_bone >= 0:
		return _hand_skel.global_transform * _hand_skel.get_bone_global_pose(_wrist_bone)
	return _controller.global_transform


## Update the shoulder pivot (called by PlayerBodyIK from TorsoEstimator).
func set_shoulder_position(pos: Vector3) -> void:
	global_position = pos


## Change the arm mesh color at runtime.
func set_arm_color(color: Color) -> void:
	arm_color = color
	if is_instance_valid(_mesh_instance):
		# retint, never replace: assigning a flat albedo here would throw the cloth
		# away the first time anything set a skin colour.
		var mat := _mesh_instance.get_surface_override_material(0) as StandardMaterial3D
		if mat == null and _mesh_instance.mesh != null:
			mat = _mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D
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

	## A REST IS NOT A POSE. add_bone() starts every bone at IDENTITY and
	## set_bone_rest() does not move it — so without this the three bones all sit
	## on the shoulder, the chain has ZERO LENGTH, and TwoBoneIK3D has nothing to
	## solve. Measured before the fix (commons/testing/probe_ik_arms.tscn): the
	## wrist sat exactly on the shoulder at all four targets, gap equal to the
	## shoulder-to-hand distance to four decimals, and it never moved. The arm has
	## been in the tree since May and has never bent.
	_skeleton.reset_bone_poses()


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
	_skeleton.add_child(_two_bone_ik)
	## THE SETTINGS ARRAY, NOT FOUR FLAT PROPERTIES. Godot 4.6 TwoBoneIK3D exposes
	## "setting_count" and then "settings/N/..."; the flat root_bone / tip_bone /
	## target_node / use_pole_node this was written against in May are not on
	## the class. They ASSIGN WITHOUT ERROR and read back null, so the modifier has
	## been standing in the tree, active, with no chain and no target — measured by
	## commons/testing/probe_ik_arms.tscn, which asked the object for its property
	## list rather than guessing again.
	##
	## Note the three-bone naming: root / MIDDLE / end, and the paths must resolve
	## FROM THE MODIFIER, so they are made relative to it rather than absolute.
	## The three bone rests are all IDENTITY basis, so the solver has no bone axis
	## to swing around unless it is allowed to derive one.
	##
	## THE KINEMATICS DO WORK — confirmed in a headset, 2026-08-29. An earlier note
	## here said the modifier never moved the bones; that was a fact about the probe,
	## which framed the arm off-camera in a 320x200 window while Skeleton3D skips its
	## update when nothing is looking. Two separate ways to measure nothing and call
	## it a broken rig, in one afternoon: read the note in probe_ik_arms.gd before
	## trusting a null reading from it.
	_two_bone_ik.set("mutable_bone_axes", true)
	_two_bone_ik.set("setting_count", 1)
	_two_bone_ik.set("settings/0/root_bone_name", "UpperArm")
	_two_bone_ik.set("settings/0/middle_bone_name", "LowerArm")
	_two_bone_ik.set("settings/0/end_bone_name", "Hand")
	_two_bone_ik.set("settings/0/target_node", _two_bone_ik.get_path_to(_ik_target))
	_two_bone_ik.set("settings/0/pole_node", _two_bone_ik.get_path_to(_pole_target))


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
		-(upper_arm_length + lower_arm_length),        # wrist (Hand origin) — the end
	]

	## Which bone owns each ring (100% weight to nearest bone)
	## The cuff still rides the HAND bone, not the forearm: where the sleeve meets
	## the real hand it should turn with the wrist, or the two part company on a
	## roll. The Hand bone stays in the skeleton — the IK chain needs an end bone
	## and it carries the wrist orientation — it is simply no longer drawn.
	var ring_bone_index: Array[int] = [
		_idx_upper,  # shoulder ring → UpperArm
		_idx_lower,  # elbow ring → LowerArm
		_idx_hand,   # wrist ring → Hand — the sleeve's cuff
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

	## THE SLEEVE IS CLOTH (2026-08-29, Palle: "arms and torso should have pink
	## Tartan pattern"). Triplanar, because this mesh is built by hand and never
	## writes ARRAY_TEX_UV — and on a limb a world-mapped check reads as cloth cut
	## from a bolt, which is what a sleeve is. arm_color survives as a tint, so
	## set_arm_color still shades the whole garment rather than being ignored.
	var mat := Tartan.material(0.42, arm_color)
	arm_mesh.surface_set_material(0, mat)

	## Skin resource with bind poses
	var skin := Skin.new()
	skin.set_bind_count(_skeleton.get_bone_count())
	for bone_i in range(_skeleton.get_bone_count()):
		skin.set_bind_bone(bone_i, bone_i)
		## THE BIND POSE IS GLOBAL, NOT LOCAL — and this is the 50 cm.
		## get_bone_rest() is the bone's rest RELATIVE TO ITS PARENT; a bind pose
		## must invert the bone's rest in SKELETON space. Using the local rest
		## binds every bone as if its parents were at the origin, so the mesh is
		## displaced by exactly the offsets it skipped: for the Hand bone that is
		## upper 0.28 + lower 0.25 = 0.53 m. Palle, 2026-08-29: "the arm wrist is
		## attached in front like 50 cm of the hands". The skeleton was solving
		## correctly the whole time; only the skin was hung wrong.
		skin.set_bind_pose(bone_i, _skeleton.get_bone_global_rest(bone_i).affine_inverse())

	## MeshInstance3D
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "ArmMesh"
	_mesh_instance.mesh = arm_mesh
	_mesh_instance.skin = skin
	_mesh_instance.skeleton = _skeleton.get_path()
	_skeleton.add_child(_mesh_instance)
