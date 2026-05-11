@tool
extends SceneTree
# Auto-research: figure out which rotation of the XR Tools hand mesh
# gives a "natural rest" reading. We capture 8 variants at different
# rotations so the user can pick the right baseline.
#
# Both FPV and 3/4 view per variant so we can see how each orientation
# reads from inside the headset AND from outside.
#
# Output:
#   user://catalyst_runs/hand_orientations/<id>_fpv.png
#   user://catalyst_runs/hand_orientations/<id>_3q.png

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/hand_orientations")

	# Each variant: id, label, rotation Euler degrees applied to BOTH hands
	# (in addition to mirror logic). Rotation interpreted as XYZ Euler.
	var variants: Array = [
		{"id": "00_identity",       "rot": Vector3(0, 0, 0),     "label": "Identity (no rotation)"},
		{"id": "01_yaw_180",        "rot": Vector3(0, 180, 0),   "label": "180° yaw on both"},
		{"id": "02_pitch_down_90",  "rot": Vector3(-90, 0, 0),   "label": "-90° pitch (fingers down)"},
		{"id": "03_pitch_up_90",    "rot": Vector3(90, 0, 0),    "label": "+90° pitch (fingers up)"},
		{"id": "04_palms_down",     "rot": Vector3(-45, 0, 0),   "label": "Tilted -45° (relaxed palms down)"},
		{"id": "05_palms_forward",  "rot": Vector3(0, 180, 90),  "label": "Yaw 180 + roll 90 (palms forward)"},
		{"id": "06_thumbs_up",      "rot": Vector3(0, 0, 90),    "label": "+90° roll (thumbs up)"},
		{"id": "07_thumbs_down",    "rot": Vector3(0, 0, -90),   "label": "-90° roll (thumbs down)"},
	]

	for v in variants:
		await _capture(v, true)   # FPV
		await _capture(v, false)  # 3/4 external
	print("[hand_orient] complete — %d variants × 2 views" % variants.size())
	quit()


func _capture(v: Dictionary, first_person: bool) -> void:
	var id: String = v["id"]
	var rot_deg: Vector3 = v["rot"]
	var view_suffix: String = "fpv" if first_person else "3q"

	var root := Node3D.new()
	root.name = "HandOrient_%s_%s" % [id, view_suffix]

	VRCaptureRig.build_environment(root)

	# Hands at typical chest-forward rest position.
	var left_pos := Vector3(-0.22, 1.30, -0.45)
	var right_pos := Vector3(0.22, 1.30, -0.45)

	# Build basis from Euler rotation only — no extra mirror or aim math.
	# We want to see what the RAW rotations produce.
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(rot_deg.x),
		deg_to_rad(rot_deg.y),
		deg_to_rad(rot_deg.z),
	))

	# Note: pose_hand still applies the rig's pose system, but we override
	# basis with our test Euler-only basis. Both hands get the SAME rotation
	# so we can see how the model's intrinsic mirror works.
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		basis, "Default pose", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		basis, "Default pose", false)

	# Camera
	var cam: Camera3D
	if first_person:
		cam = VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.10, -0.80), 85.0)
	else:
		cam = VRCaptureRig.build_camera(
			Vector3(1.40, 1.55, 0.20),
			Vector3(0, 1.25, -0.50),
			50.0,
		)
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
		print("[hand_orient] FAIL %s_%s" % [id, view_suffix])
		return
	img.save_png("user://catalyst_runs/hand_orientations/%s_%s.png" % [id, view_suffix])
	print("[hand_orient] saved %s_%s — %s" % [id, view_suffix, v["label"]])
