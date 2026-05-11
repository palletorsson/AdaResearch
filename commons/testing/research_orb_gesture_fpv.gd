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
	# orb_scale / orb_emission_mult / orb_alpha are optional — used by
	# the forming-arc variants (09, 10, 11) to show the orb partway
	# through materialisation.
	var variants: Array = [
		{"id": "01_orb_only",            "show_hands": false, "two_handed": true, "roll_l": 0.0, "roll_r": 0.0,  "spacing": 0.20, "aim": Vector3(0, -0.55, -1), "label": "Just the orb — no hands"},
		{"id": "02_two_handed_cupping",  "show_hands": true,  "two_handed": true, "roll_l": +1.0, "roll_r": -1.0, "spacing": 0.20, "aim": Vector3(0, -0.55, -1), "label": "Two-handed, palms cupping inward"},
		{"id": "03_two_handed_pressing", "show_hands": true,  "two_handed": true, "roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.20, "aim": Vector3(0, -0.40, -1), "label": "Two-handed, palms down/pressing"},
		{"id": "04_two_handed_palms_down","show_hands": true, "two_handed": true, "roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.14, "aim": Vector3(0, -0.55, -1), "label": "Two-handed, palms down close"},
		{"id": "05_one_handed_present",  "show_hands": true,  "two_handed": false,"roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.0,  "aim": Vector3(0.05, -0.40, -1), "label": "One-handed, presenting forward"},
		{"id": "06_one_handed_palm_up",  "show_hands": true,  "two_handed": false,"roll_l": 0.0,  "roll_r": -2.0, "spacing": 0.0,  "aim": Vector3(0.05, -0.30, -1), "label": "One-handed, palm up offering"},
		{"id": "07_one_handed_burst",    "show_hands": true,  "two_handed": false,"roll_l": 0.0,  "roll_r": 0.0,  "spacing": 0.0,  "aim": Vector3(0.05, -0.55, -1), "label": "One-handed, burst aimed down"},
		{"id": "08_two_handed_wide",     "show_hands": true,  "two_handed": true, "roll_l": +1.0, "roll_r": -1.0, "spacing": 0.28, "aim": Vector3(0, -0.55, -1), "label": "Two-handed, wider stance"},
		# Forming arc: hands approach from far, orb materialises gradually.
		{"id": "09_two_handed_approach", "show_hands": true,  "two_handed": true, "roll_l": +0.6, "roll_r": -0.6, "spacing": 0.32, "aim": Vector3(0, -0.55, -1), "label": "Two-handed approach — hands near threshold, orb just appearing", "orb_scale": 0.35, "orb_emission_mult": 0.4, "orb_alpha": 0.45},
		{"id": "10_two_handed_forming",  "show_hands": true,  "two_handed": true, "roll_l": +0.8, "roll_r": -0.8, "spacing": 0.22, "aim": Vector3(0, -0.55, -1), "label": "Two-handed forming — gesture committing, orb materialising", "orb_scale": 0.65, "orb_emission_mult": 0.75, "orb_alpha": 0.75},
		{"id": "11_two_handed_held",     "show_hands": true,  "two_handed": true, "roll_l": +1.0, "roll_r": -1.0, "spacing": 0.14, "aim": Vector3(0, -0.55, -1), "label": "Two-handed held — hands close, orb fully alive", "orb_emission_mult": 1.3},
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
	var orb_mesh: MeshInstance3D = null
	for c in orb.get_children():
		if c is OmniLight3D:
			orb_light = c
		elif c is MeshInstance3D:
			orb_mesh = c
	if orb_light != null:
		orb_light.light_energy = 0.9
		orb_light.omni_range = 0.8

	# Forming-arc cone is also weaker — scales with orb_scale so the
	# field reach reads as "still building" alongside the orb.
	var cone_scale: float = 1.0
	if "orb_scale" in v:
		cone_scale = clamp(float(v["orb_scale"]) + 0.2, 0.3, 1.0)
	var cone_vis := VRCaptureRig.build_cone_visual(
		orb_origin, aim, cone_length * cone_scale,
		VRCaptureRig.color_for_mode("primitives"),
		0.35,
		0.05,
		0.18 * cone_scale,
		0.45 * cone_scale,
	)
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

	# Forming-arc tweaks: apply AFTER form() so we override its defaults.
	# Re-apply each frame because update_state() rewrites the visual.
	var orb_scale_override: float = float(v.get("orb_scale", -1.0))
	var orb_emission_override: float = float(v.get("orb_emission_mult", -1.0))
	var orb_alpha_override: float = float(v.get("orb_alpha", -1.0))

	for _i in range(60):
		await process_frame
		if orb.has_method("update_state"):
			orb.call("update_state", "primitives", orb_origin, aim, cone_length * cone_scale, two_handed)
		_apply_orb_overrides(orb_mesh, orb_scale_override, orb_emission_override, orb_alpha_override)
		if orb_light != null and orb_emission_override > 0.0:
			orb_light.light_energy = 0.9 * orb_emission_override

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


## Apply forming-arc overrides to the orb visual after form() has run.
## Each override is "use this value if > 0.0, otherwise leave as form set it".
func _apply_orb_overrides(mesh: MeshInstance3D, scale_override: float, emission_override: float, alpha_override: float) -> void:
	if mesh == null:
		return
	if scale_override > 0.0:
		mesh.scale = Vector3.ONE * scale_override
	var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	if emission_override > 0.0:
		mat.emission_energy_multiplier = max(0.1, 3.0 * emission_override)
	if alpha_override > 0.0:
		mat.albedo_color.a = alpha_override
