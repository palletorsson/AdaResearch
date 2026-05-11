@tool
extends SceneTree
# Capture the calibration baseline for VR hands.
# Natural rest pose: palms down, thumbs pointing inward toward each
# other, fingers forward (the hands a player sees when extending their
# controllers naturally in front of them).
#
# Uses VRCaptureRig.natural_rest_basis() which carries the corrected
# axis mapping for the XR Tools hand model (fingers along intrinsic +X).
#
# Output:
#   user://catalyst_runs/hand_baseline/fpv.png   first-person view
#   user://catalyst_runs/hand_baseline/3q.png    external 3/4 view
#   user://catalyst_runs/hand_baseline/front.png head-on front view
#   user://catalyst_runs/hand_baseline/top.png   straight-down top view

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/hand_baseline")

	await _capture("fpv",   "fpv")
	await _capture("3q",    "3q")
	await _capture("front", "front")
	await _capture("top",   "top")
	print("[hand_baseline] complete")
	quit()


func _capture(id: String, view: String) -> void:
	var root := Node3D.new()
	root.name = "HandBaseline_%s" % id

	VRCaptureRig.build_environment(root)

	var left_pos := Vector3(-0.22, 1.30, -0.45)
	var right_pos := Vector3(0.22, 1.30, -0.45)

	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		VRCaptureRig.natural_rest_basis(true), "Default pose", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		VRCaptureRig.natural_rest_basis(false), "Default pose", false)

	var cam: Camera3D
	match view:
		"fpv":
			cam = VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.10, -0.80), 85.0)
		"3q":
			cam = VRCaptureRig.build_camera(
				Vector3(1.40, 1.60, 0.30),
				Vector3(0, 1.25, -0.60),
				50.0)
		"front":
			cam = VRCaptureRig.build_camera(
				Vector3(0, 1.30, 1.20),
				Vector3(0, 1.30, -0.45),
				48.0)
		"top":
			cam = VRCaptureRig.build_camera(
				Vector3(0, 2.40, -0.45),
				Vector3(0, 1.30, -0.45),
				50.0)
		_:
			cam = VRCaptureRig.default_elevated_camera()
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
		print("[hand_baseline] FAIL %s" % id)
		return
	img.save_png("user://catalyst_runs/hand_baseline/%s.png" % id)
	print("[hand_baseline] saved %s" % id)
