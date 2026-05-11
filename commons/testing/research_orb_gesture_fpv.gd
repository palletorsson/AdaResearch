@tool
extends SceneTree
# Auto-research run for the orb gesture in first-person VR perspective.
# Generates a small grid of rotation/gesture variants so we can pick the
# best for the /gesture-dna gallery without going to the headset first.
#
# Output:
#   user://catalyst_runs/orb_gesture_research/<variant>.png
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/research_orb_gesture_fpv.gd
#
# Variants generated:
#   01_orb_only            — just the orb floating in space (no hands)
#   02_two_handed_cupping  — palms inward, cupping the orb
#   03_two_handed_pressing — palms forward, presenting toward field
#   04_two_handed_palms_down — palms-down rest, hands holding orb between
#   05_one_handed_present   — right hand presenting, palm forward
#   06_one_handed_palm_up   — right hand cupped, palm up
#   07_one_handed_burst     — right hand mid-burst, fingers extended
#   08_two_handed_wide      — same as cupping but wider stance (for legibility)

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/orb_gesture_research")

	# Each entry: id, params dict
	var variants: Array = [
		{"id": "01_orb_only",            "show_hands": false, "two_handed": true, "roll_l": 0.0, "roll_r": 0.0,  "spacing": 0.20, "aim": Vector3(0, -0.55, -1), "label": "Just the orb — no hands"},
		{"id": "02_two_handed_cupping",  "show_hands": true,  "two_handed": true, "roll_l": +1.0, "roll_r": -1.0, "spacing": 0.20, "aim": Vector3(0, -0.55, -1), "label": "Two-handed, palms cupping inward"},
		{"id": "03_two_handed_pressing", "show_hands": true,  "two_handed": true, "roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.20, "aim": Vector3(0, -0.40, -1), "label": "Two-handed, palms down/pressing"},
		{"id": "04_two_handed_palms_down","show_hands": true, "two_handed": true, "roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.14, "aim": Vector3(0, -0.55, -1), "label": "Two-handed, palms down close"},
		{"id": "05_one_handed_present",  "show_hands": true,  "two_handed": false,"roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.0,  "aim": Vector3(0.05, -0.40, -1), "label": "One-handed, presenting forward"},
		{"id": "06_one_handed_palm_up",  "show_hands": true,  "two_handed": false,"roll_l": 0.0,  "roll_r": -2.0, "spacing": 0.0,  "aim": Vector3(0.05, -0.30, -1), "label": "One-handed, palm up offering"},
		{"id": "07_one_handed_burst",    "show_hands": true,  "two_handed": false,"roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.0,  "aim": Vector3(0.05, -0.55, -1), "label": "One-handed, burst aimed down"},
		{"id": "08_two_handed_wide",     "show_hands": true,  "two_handed": true, "roll_l": +1.0, "roll_r": -1.0, "spacing": 0.28, "aim": Vector3(0, -0.55, -1), "label": "Two-handed, wider stance"},
	]

	for v in variants:
		await _capture(v)
	print("[orb_research] complete — %d variants" % variants.size())
	quit()


func _capture(v: Dictionary) -> void:
	var id: String = v["id"]
	var show_hands: bool = v["show_hands"]
	var two_handed: bool = v["two_handed"]
	var roll_l: float = v["roll_l"]
	var roll_r: float = v["roll_r"]
	var spacing: float = v["spacing"]
	var aim: Vector3 = (v["aim"] as Vector3).normalized()

	var root := Node3D.new()
	root.name = "OrbGestureFPV_%s" % id

	VRCaptureRig.build_environment(root)
	# No figure in FPV — the camera IS the player, the hands extending
	# into frame carry the perspective. A torso would clip the camera.

	# Hand poses — first-person, hands extended forward from chest at
	# approximately controller positions in real VR.
	var left_pos: Vector3 = Vector3(-spacing, 1.30, -0.45)
	var right_pos: Vector3 = Vector3(+spacing, 1.30, -0.45) if two_handed else Vector3(0.12, 1.30, -0.45)
	var orb_origin: Vector3 = ((left_pos + right_pos) * 0.5) if two_handed else right_pos
	var cone_length: float = 2.0

	if show_hands:
		if two_handed:
			VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
				VRCaptureRig.hand_basis(aim, roll_l, true))
			VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
				VRCaptureRig.hand_basis(aim, roll_r, false))
		else:
			# One-handed: left hand at hip (rest pose, palm down).
			VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, Vector3(-0.25, 1.00, -0.05),
				VRCaptureRig.hand_basis(Vector3.FORWARD, 0.0, true))
			VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
				VRCaptureRig.hand_basis(aim, roll_r, false))

	# Orb (production scene) + cone visual.
	var orb: Node3D = CATALYST_ORB.instantiate()
	root.add_child(orb)
	await process_frame
	var orb_light: OmniLight3D = null
	for c in orb.get_children():
		if c is OmniLight3D:
			orb_light = c
			break
	if orb_light != null:
		orb_light.light_energy = 0.9
		orb_light.omni_range = 0.8

	var cone_vis := VRCaptureRig.build_cone_visual(
		orb_origin, aim, cone_length, VRCaptureRig.color_for_mode("primitives"))
	root.add_child(cone_vis)

	# First-person camera looking down at the gesture.
	var look_target: Vector3 = orb_origin + aim * 0.8
	var cam := VRCaptureRig.first_person_camera(1.62, look_target, 85.0)
	root.add_child(cam)

	# Replace scene + settle
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	await process_frame
	await process_frame

	if orb.has_method("form"):
		orb.call("form", "primitives", orb_origin, aim, two_handed)

	for _i in range(60):
		await process_frame
		if orb.has_method("update_state"):
			orb.call("update_state", "primitives", orb_origin, aim, cone_length, two_handed)

	# Capture
	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame

	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[orb_research] FAIL viewport null (%s)" % id)
		return
	var out_path: String = "user://catalyst_runs/orb_gesture_research/%s.png" % id
	img.save_png(out_path)
	print("[orb_research] saved %s — %s" % [id, v["label"]])
