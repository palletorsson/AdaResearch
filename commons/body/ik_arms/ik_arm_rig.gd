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
## WHERE THE ELBOW IS ASKED TO GO
## ————————————————————————————————————————————————————————————————————
## 2026-08-31, Palle: "the arms elbows point inwards. It's like they need more
## space to point down, mostly."
##
## These three are a DIRECTION in torso space, not a place: outboard, down, and
## back, which is where a human elbow hangs. Only the ratio matters — the vector
## is projected onto the plane perpendicular to the shoulder-to-wrist line before
## the pole is placed, so it can never come out parallel to the chain.
##
## The old pole was `shoulder + forward*0.3 + down*0.2`, and it was wrong three
## ways at once. It had no left/right term, so it was IDENTICAL for both arms and
## could not ask an elbow to go outboard at all. It pointed FORWARD, which is in
## front of the elbow rather than behind it. And with a hand held out in front —
## the ordinary VR pose — forward is nearly ALONG the shoulder-to-wrist line, so
## the pole was degenerate: almost no component perpendicular to the chain for the
## solver to swing around, leaving the bend plane to fall out of rounding. That is
## what "points inwards" was.

## Outboard, away from the body's midline. Mirrored by is_left.
@export var elbow_out: float = 1.0
## Down. The dominant term — an elbow mostly hangs.
@export var elbow_down: float = 1.4
## Back, behind the shoulder-wrist plane, which is the other half of not
## chicken-winging.
@export var elbow_back: float = 0.55

## ————————————————————————————————————————————————————————————————————
## THE SHOULDER GIRDLE — how far the axle itself may travel
## ————————————————————————————————————————————————————————————————————
## Palle, same message: "Maybe the axle joint needs to have some movement?"
##
## Yes, and it is not a tweak — a shoulder is not where the arm is bolted to the
## body. The humerus hangs off a scapula that SLIDES across the ribs and a
## clavicle that swings, and between them the socket itself travels five to ten
## centimetres: it rises when you reach up, rolls forward when you reach across
## your chest, slides outboard when you go wide. Pin it and every one of those
## reaches has to be paid for at the elbow instead — the arm runs out of room and
## the bend has to go somewhere ugly. Which is the second half of what was wrong.
##
## Set all four to 0.0 to get the old bolted shoulder back.

## Rise, when the hand goes up (metres).
@export var girdle_lift: float = 0.07
## Roll forward, when the hand reaches out in front or across (metres).
@export var girdle_protract: float = 0.05
## Slide outboard when the hand goes wide, inboard when it crosses the midline.
@export var girdle_slide: float = 0.04
## Extra lean toward a hand that is at or beyond the arm's reach (metres).
@export var girdle_stretch: float = 0.06
## How fast the girdle catches up. Low is soft, high is rigid.
@export var girdle_speed: float = 8.0

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

## The anatomical shoulder the torso hands us, and the girdle's travel away from
## it. global_position is the sum, so the axle is _anchor + _girdle.
var _anchor: Vector3 = Vector3.ZERO
var _have_anchor: bool = false
var _girdle: Vector3 = Vector3.ZERO

## The torso's axes, fed by PlayerBodyIK. Defaults are the identity frame so a
## rig standing alone in a probe still has a sane notion of outboard.
var _torso_right: Vector3 = Vector3.RIGHT
var _torso_fwd: Vector3 = Vector3.FORWARD

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


func _physics_process(delta: float) -> void:
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

	## 2. Let the axle travel, then aim the elbow from wherever it ended up. The
	## order matters: the pole is measured off the shoulder, so moving the shoulder
	## afterwards would aim last frame's elbow.
	var wrist_now: Vector3 = _ik_target.global_position
	_drive_girdle(wrist_now, delta)
	_aim_elbow(wrist_now)

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


## Update the shoulder pivot (called by PlayerBodyIK from TorsoEstimator). This
## is the ANATOMICAL shoulder — where the girdle rests when the arm hangs. The
## axle the skeleton actually stands on is this plus _girdle, and it is written
## every frame by _drive_girdle; the sum is set here too so a rig with no
## controller still stands in the right place.
func set_shoulder_position(pos: Vector3) -> void:
	_anchor = pos
	_have_anchor = true
	global_position = pos + _girdle


## Which way the BODY faces, from TorsoEstimator. Both vectors are horizontal
## unit vectors; `outboard` for this arm is right mirrored by is_left.
func set_torso_frame(right: Vector3, forward: Vector3) -> void:
	if right.length_squared() > 0.001:
		_torso_right = right.normalized()
	if forward.length_squared() > 0.001:
		_torso_fwd = forward.normalized()


## Which way is away from the body's midline, for this arm.
func _outboard() -> Vector3:
	return _torso_right * (-1.0 if is_left else 1.0)


## THE AXLE MOVES. Four small travels, each driven by where the hand has gone,
## summed and smoothed. None of them is large — the whole budget is about 12 cm —
## but a pinned shoulder makes the elbow pay for every reach, and 12 cm at the
## shoulder is a lot of room at the elbow.
func _drive_girdle(wrist: Vector3, delta: float) -> void:
	if not _have_anchor:
		return
	var reach: float = maxf(0.01, upper_arm_length + lower_arm_length)
	var out_axis: Vector3 = _outboard()
	var to_hand: Vector3 = wrist - _anchor
	var want := Vector3.ZERO

	## up, when the hand goes up. The scapula rides the ribs — it rises freely and
	## barely drops, so this term is clamped at zero rather than allowed to sink.
	want += Vector3.UP * clampf(to_hand.dot(Vector3.UP) / reach, 0.0, 1.0) * girdle_lift
	## forward, when the hand reaches out in front or across the chest
	want += _torso_fwd * clampf(to_hand.dot(_torso_fwd) / reach, 0.0, 1.0) * girdle_protract
	## outboard when the hand goes wide; inboard, signed, when it crosses the midline
	want += out_axis * clampf(to_hand.dot(out_axis) / reach, -1.0, 1.0) * girdle_slide

	## AND THE LEAN. Past about 90% of reach a real body stops solving with the arm
	## and starts following with the shoulder. Without this the arm simply stops at
	## full extension and the elbow locks straight, which is the pose that reads as
	## a mannequin.
	var dist: float = to_hand.length()
	if dist > reach * 0.9:
		var over: float = clampf((dist - reach * 0.9) / (reach * 0.3), 0.0, 1.0)
		want += (to_hand / dist) * over * girdle_stretch

	_girdle = _girdle.lerp(want, clampf(girdle_speed * delta, 0.0, 1.0))
	global_position = _anchor + _girdle


## POINT THE ELBOW SOMEWHERE IT CAN ACTUALLY GO.
##
## The wanted direction is outboard + down + back, in torso space. That vector on
## its own is not usable as a pole: whenever it happens to lie near the
## shoulder-to-wrist line the solver has almost nothing perpendicular to swing
## around, and the bend plane becomes noise. So the axial component is REMOVED
## first — what is left is by construction perpendicular to the chain, which is
## the only kind of pole that means anything. The pole then sits half a metre off
## the middle of the chord, so it stays sane as the arm bends.
func _aim_elbow(wrist: Vector3) -> void:
	var shoulder: Vector3 = global_position
	var chord: Vector3 = wrist - shoulder
	var out_axis: Vector3 = _outboard()
	var want: Vector3 = out_axis * elbow_out + Vector3.DOWN * elbow_down + (-_torso_fwd) * elbow_back

	if chord.length_squared() > 0.000001:
		var axis: Vector3 = chord.normalized()
		want -= axis * want.dot(axis)
		## degenerate only if the wanted direction was exactly along the arm; take
		## anything perpendicular rather than handing the solver a zero vector.
		if want.length_squared() < 0.000001:
			want = axis.cross(Vector3.UP)
		if want.length_squared() < 0.000001:
			want = axis.cross(out_axis)
	if want.length_squared() < 0.000001:
		want = Vector3.DOWN

	_pole_target.global_position = shoulder + chord * 0.5 + want.normalized() * 0.5


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
