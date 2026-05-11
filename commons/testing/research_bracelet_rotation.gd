@tool
extends SceneTree
# The mode-rotation gesture: right hand reaches across to grip the
# bracelet on the left wrist, twist to select a new mode.
#
# Two-handed gesture (one hand wears, the other operates) — the
# bracelet's hinge converts the right hand's rotation into mode index.
#
# Captures the three moments of this gesture:
#   approach   — right hand reaching toward bracelet, not yet gripping
#   gripping   — right hand on the bracelet, fingers wrapped (Pinch Tight)
#   rotated    — same grip, bracelet rotated one step (next mode active)
#
# Output: user://catalyst_runs/bracelet_rotation/<state>.png

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/bracelet_rotation")

	await _capture("approach", 0, "Default pose", "primitives")
	await _capture("gripping", 1, "Pinch Tight", "primitives")
	await _capture("rotated",  1, "Pinch Tight", "transformation")
	print("[bracelet_rotation] complete")
	quit()


# state:           id for filename
# right_hand_step: 0=at side, 1=on bracelet
# right_pose:      hand pose name
# active_mode:     bracelet's currently-active mode (drives gem color)
func _capture(state: String, right_hand_step: int, right_pose: String, active_mode: String) -> void:
	var root := Node3D.new()
	root.name = "BraceletRotation_%s" % state

	VRCaptureRig.build_environment(root)

	# Left hand wears the bracelet — held forward and slightly up so the
	# player can see the gems.
	var left_pos := Vector3(-0.10, 1.32, -0.40)
	var left_basis := VRCaptureRig.hand_basis(Vector3(0.4, 0, -1), 0.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		left_basis, "Default pose", true)

	# Bracelet on left wrist with active mode color.
	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	var forearm_dir := Vector3(0.5, -0.1, 0.85)
	var bracelet_color := VRCaptureRig.color_for_mode(active_mode)
	VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir, bracelet_color)

	# Right hand — either at the player's side (approach) or on the bracelet (gripping/rotated).
	var right_pos: Vector3
	var right_basis: Basis
	if right_hand_step == 0:
		# Approach — right hand a bit forward and to the side, palm
		# turned toward the bracelet, fingers open.
		right_pos = Vector3(0.18, 1.20, -0.35)
		right_basis = VRCaptureRig.hand_basis(Vector3(-0.8, 0, -0.4), 0.0, false)
	else:
		# Gripping — right hand at the bracelet position, fingers wrap.
		# For "rotated" state we add a slight roll to suggest the twist.
		var roll_for_rotation := 0.0 if state != "rotated" else 0.5
		right_pos = wrist_pos + Vector3(0.02, 0.0, 0.0)
		right_basis = VRCaptureRig.hand_basis(Vector3(-0.7, 0, -0.5), roll_for_rotation, false)

	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		right_basis, right_pose, false)

	# FPV camera — slightly higher angle to see across both hands.
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(-0.05, 1.10, -0.65), 80.0)
	root.add_child(cam)

	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	for _i in range(40):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[bracelet_rotation] FAIL %s" % state)
		return
	img.save_png("user://catalyst_runs/bracelet_rotation/%s.png" % state)
	print("[bracelet_rotation] saved %s (mode=%s pose=%s)" % [state, active_mode, right_pose])
