extends Node3D
## DOES THE ARM ACTUALLY REACH THE HAND?
##
## 2026-08-29, Palle: "the vr body; rebuild it in stages, first make the arm be
## attached to the vr hand arms extended inverse kinematics."
##
## commons/body/ik_arms/ already holds an IKArmRig (TwoBoneIK3D, three bones, a
## procedural skinned mesh) and a PlayerBodyIK that composes a torso from a
## headset and two controllers. It was written in May and compiles on 4.6. What
## nobody has measured is whether it SOLVES — so this stands a fake rig, moves a
## hand to four places, and reads back where the wrist ended up.
##
## A PROBE READS THE MODEL, NOT THE VIEW (the standing lesson). The arm's mesh is
## skinned, so looking at a MeshInstance3D's transform says nothing; the answer is
## in the Skeleton3D's global bone poses. And Node3D.basis CARRIES SCALE, so the
## bone chain is measured by POSITION and reported to 4 decimals rather than
## eyeballed.
##
##   godot --headless --path . --xr-mode off \
##       --script res://commons/testing/probe_ik_arms.gd
##
## Exit 0 = every target reached inside tolerance. Exit 1 = it does not solve.

const TOL := 0.06     # metres. TwoBoneIK cannot reach past upper+lower, so a
                      # target beyond the arm is scored against the arm's limit.

var _origin: XROrigin3D
var _cam: XRCamera3D
var _left: Node3D
var _right: Node3D
var _body: Node
var _step := 0
var _fails: Array = []
var _rows: Array = []

## the four places a hand is put, in XROrigin-local metres
const TARGETS := [
	Vector3(-0.30, 1.10, -0.35),   # resting, close in
	Vector3(-0.55, 1.40, -0.45),   # out and up
	Vector3(-0.20, 0.70, -0.25),   # low, near the hip
	Vector3(-0.75, 1.30, -0.10),   # wide, near the arm's limit
]


func _ready() -> void:
	# a rig the same SHAPE as base.tscn's: XROrigin3D with an XRCamera3D and two
	# controllers named LeftHand / RightHand, because that is what
	# PlayerBodyIK._find_hand looks for.
	_origin = XROrigin3D.new()
	_origin.name = "XROrigin3D"
	add_child(_origin)

	_cam = XRCamera3D.new()
	_cam.name = "XRCamera3D"
	_origin.add_child(_cam)
	_cam.position = Vector3(0.0, 1.65, 0.0)

	_left = XRController3D.new()
	_left.name = "LeftHand"
	_origin.add_child(_left)
	_left.position = TARGETS[0]

	_right = XRController3D.new()
	_right.name = "RightHand"
	_origin.add_child(_right)
	_right.position = Vector3(0.30, 1.10, -0.35)

	var scene: PackedScene = load("res://commons/body/ik_arms/player_body_ik.tscn")
	if scene == null:
		print("[ik-probe] FAIL: player_body_ik.tscn will not load")
		get_tree().quit(1)
		return
	_body = scene.instantiate()
	_body.name = "PlayerBodyIK"
	_origin.add_child(_body)
	print("[ik-probe] rig standing: origin + camera + two controllers + PlayerBodyIK")


func _physics_process(_delta: float) -> void:
	# a settle before the first reading: the rig builds its skeleton in _ready and
	# TwoBoneIK3D solves in the physics step, so reading on frame 0 measures an
	# unbuilt arm and calls it broken.
	_step += 1
	if _step < 12:
		return
	var idx: int = (_step - 12) / 8
	if idx >= TARGETS.size():
		_report()
		return
	if (_step - 12) % 8 == 0:
		_left.position = TARGETS[idx]
	if (_step - 12) % 8 == 7:
		_measure(idx)


func _measure(idx: int) -> void:
	var arm: Node = _body.get_node_or_null("LeftArmRig")
	if arm == null:
		_fails.append("no LeftArmRig under PlayerBodyIK")
		return
	var skel: Skeleton3D = _find_skeleton(arm)
	if skel == null:
		_fails.append("target %d: the arm rig built no Skeleton3D" % idx)
		return
	# the wrist is the LAST bone of the chain the IK drives; its global origin is
	# what "the arm reaches the hand" actually means.
	var n: int = skel.get_bone_count()
	if n < 3:
		_fails.append("target %d: skeleton has %d bones, expected 3" % [idx, n])
		return
	# IS IT THE RIG OR IS IT HEADLESS? A SkeletonModifier3D runs inside the
	# skeleton's own update, and --headless changes which code runs (the standing
	# lesson). Before calling the arm broken, ask three questions that separate
	# "the wiring is dead", "the modifier is off" and "the modifier never ran".
	if idx == 0:
		var tgt: Node3D = _find_named(arm, "IKTarget")
		var mod: Node = _find_modifier(arm)
		print("  [diagnosis] ik target follows controller : %s" % (
			("YES  target=%s controller=%s" % [str(tgt.global_position), str(_left.global_position)])
			if tgt != null else "NO TARGET NODE FOUND"))
		if mod != null:
			var tn: Variant = mod.get("target_node")
			var resolved: Node = mod.get_node_or_null(tn) if tn != null else null
			print("  [diagnosis] modifier target resolves     : %s  (path %s)" % [
				("YES -> %s at %s" % [resolved.name, str((resolved as Node3D).global_position)])
					if resolved is Node3D else "NO — the NodePath does not resolve from the modifier",
				str(tn)])
			print("  [diagnosis] modifier influence           : %s" % str(mod.get("influence")))
			print("  [diagnosis] root/tip bone                : %s -> %s" % [
				str(mod.get("root_bone")), str(mod.get("tip_bone"))])
			print("  [diagnosis] skeleton callback mode       : %s" % str(skel.modifier_callback_mode_process))
			# ASK THE OBJECT WHAT IT HAS. Guessing property names is how the rig got
			# here: four assignments that compile and read back null.
			print("  [diagnosis] settings read back         : count=%s root=%s(%s) mid=%s(%s) end=%s(%s)" % [
				str(mod.get("setting_count")),
				str(mod.get("settings/0/root_bone_name")), str(mod.get("settings/0/root_bone")),
				str(mod.get("settings/0/middle_bone_name")), str(mod.get("settings/0/middle_bone")),
				str(mod.get("settings/0/end_bone_name")), str(mod.get("settings/0/end_bone"))])
			var tpath: Variant = mod.get("settings/0/target_node")
			var tnode: Node = mod.get_node_or_null(tpath) if tpath != null else null
			print("  [diagnosis] settings target resolves    : %s  (path %s)" % [
				("YES -> %s" % str((tnode as Node3D).global_position)) if tnode is Node3D else "NO",
				str(tpath)])
			var names: Array = []
			for pr in mod.get_property_list():
				var nm := String(pr.get("name", ""))
				if nm.begins_with("_") or nm == "script":
					continue
				if nm.find("/") < 0 and nm != "setting_count":
					continue
				names.append("%s:%s" % [nm, type_string(int(pr.get("type", 0)))])
			print("  [diagnosis] TwoBoneIK3D really exposes   : %s" % ", ".join(names))
		print("  [diagnosis] modifier                     : %s" % (
			("%s active=%s" % [mod.get_class(), str(mod.get("active"))]) if mod != null else "NONE"))
		# does the skeleton update AT ALL headless? poke a bone and read it back.
		var probe_pose: Transform3D = skel.get_bone_pose(1)
		var before: Vector3 = (skel.global_transform * skel.get_bone_global_pose(2)).origin
		probe_pose.basis = probe_pose.basis.rotated(Vector3.RIGHT, 0.7)
		skel.set_bone_pose(1, probe_pose)
		skel.force_update_all_bone_transforms()
		var after: Vector3 = (skel.global_transform * skel.get_bone_global_pose(2)).origin
		print("  [diagnosis] skeleton responds to a poke   : %s (moved %.4f m)" % [
			("YES" if before.distance_to(after) > 0.001 else "NO — the skeleton itself is frozen"),
			before.distance_to(after)])
		# PUT IT BACK. The poke bends bone 1 by 0.7 rad, and leaving it bent makes
		# every later reading a measurement of the probe rather than of the arm —
		# the first run of this fix reported a wrist frozen at y 0.9288 for all
		# four targets, which was this rotation and not the rig.
		skel.set_bone_pose(1, skel.get_bone_rest(1))
		skel.force_update_all_bone_transforms()
	# READ AFTER THE SOLVE, NOT BEFORE IT. The modifier runs inside the skeleton's
	# own update (callback mode 1 = physics), so a bone pose read straight out of
	# _physics_process can be the pose from before this frame's solve. Forcing the
	# update first is the difference between measuring the arm and measuring the
	# order the two happened in.
	skel.force_update_all_bone_transforms()
	var wrist: Vector3 = (skel.global_transform * skel.get_bone_global_pose(n - 1)).origin
	var hand: Vector3 = _left.global_position
	var d: float = wrist.distance_to(hand)
	var reach: float = float(arm.get("upper_arm_length")) + float(arm.get("lower_arm_length"))
	var shoulder: Vector3 = (skel.global_transform * skel.get_bone_global_pose(0)).origin
	var want: float = shoulder.distance_to(hand)
	var beyond: bool = want > reach
	var ok: bool = d <= TOL or (beyond and absf(want - reach - d) <= TOL)
	_rows.append({"target": idx, "hand": hand, "wrist": wrist, "gap_m": d,
		"shoulder_to_hand": want, "arm_reach": reach, "beyond_reach": beyond, "ok": ok})
	if not ok:
		_fails.append("target %d: wrist %.4f m from the hand (reach %.2f, wanted %.2f)"
			% [idx, d, reach, want])


func _find_named(n: Node, want: String) -> Node3D:
	if n.name == want and n is Node3D:
		return n as Node3D
	for c in n.get_children():
		var r := _find_named(c, want)
		if r != null:
			return r
	return null


func _find_modifier(n: Node) -> Node:
	if n.get_class().findn("IK") >= 0 and n is SkeletonModifier3D:
		return n
	for c in n.get_children():
		var r := _find_modifier(c)
		if r != null:
			return r
	return null


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var s := _find_skeleton(c)
		if s != null:
			return s
	return null


func _report() -> void:
	print("\n[ik-probe] does the arm reach the hand?\n")
	print("  %-7s %-26s %-26s %8s %8s %7s" % ["target", "hand (world)", "wrist (world)", "gap m", "want m", "reach"])
	for r in _rows:
		print("  %-7d %-26s %-26s %8.4f %8.3f %7.2f  %s" % [
			int(r["target"]), str(r["hand"]), str(r["wrist"]),
			float(r["gap_m"]), float(r["shoulder_to_hand"]), float(r["arm_reach"]),
			("ok" if bool(r["ok"]) else ("BEYOND REACH" if bool(r["beyond_reach"]) else "MISS"))])
	if _fails.is_empty():
		print("\n[ik-probe] PASS — the arm tracks the controller at all %d targets" % _rows.size())
		get_tree().quit(0)
	else:
		print("\n[ik-probe] FAIL — %d problem(s):" % _fails.size())
		for f in _fails:
			print("   - %s" % f)
		get_tree().quit(1)
