@tool
extends SceneTree
# Catalyst-mode polymorphism: capture the bracelet + orb (humming state)
# in each of the 10 catalyst modes so the gallery shows the full palette.
#
# Each capture:
#   - Bracelet on left wrist, active gem in the mode's hue
#   - Orb between cupped hands, tinted to the mode
#   - FPV camera
#
# Output: user://catalyst_runs/catalyst_modes/<mode_id>.png

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

const MODE_IDS := [
	"primitives",
	"transformation",
	"chromatic",
	"forces",
	"waveform",
	"chaos",
	"fractal",
	"cellular",
	"branching",
	"swarm",
]


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/catalyst_modes")

	for mode in MODE_IDS:
		await _capture(mode)
	print("[catalyst_modes] complete — %d modes" % MODE_IDS.size())
	quit()


func _capture(mode_id: String) -> void:
	var root := Node3D.new()
	root.name = "CatalystMode_%s" % mode_id

	VRCaptureRig.build_environment(root)

	var orb_origin := Vector3(0, 1.30, -0.55)
	var aim_dir := Vector3(0, -0.55, -1).normalized()
	var mode_color := VRCaptureRig.color_for_mode(mode_id)

	# Hands cupping the orb (humming state)
	var hand_spacing := 0.20
	var left_pos := Vector3(-hand_spacing, 1.30, -0.45)
	var right_pos := Vector3(+hand_spacing, 1.30, -0.45)
	var basis := VRCaptureRig.hand_basis(aim_dir, 1.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		basis, "Cup", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		basis, "Cup", false)

	# Bracelet on left wrist with this mode's color on the active gem
	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	var forearm_dir := Vector3(0.3, -0.1, 0.9)
	VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir, mode_color)

	# Orb (instantiated; form() called after tree-add)
	var orb: Node3D = CATALYST_ORB.instantiate()
	root.add_child(orb)

	# Camera
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.05, -0.85), 85.0)
	root.add_child(cam)

	# Add to tree
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	await process_frame
	await process_frame

	# Now form the orb with this mode
	if orb.has_method("form"):
		orb.call("form", mode_id, orb_origin, aim_dir, true)
		# Apply the noise+palette shader — same shader, mode-specific palette.
		# Each mode's three-stop palette gives the orb its characteristic
		# colour story (greens for primitives, fire for chaos, etc.).
		VRCaptureRig.apply_orb_noise_shader(orb, mode_id, 0.06, 1.2)
		for c in orb.get_children():
			if c is OmniLight3D:
				(c as OmniLight3D).light_energy = 0.3
				(c as OmniLight3D).omni_range = 0.5
				(c as OmniLight3D).light_color = mode_color

	for _i in range(30):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[catalyst_modes] FAIL %s" % mode_id)
		return
	img.save_png("user://catalyst_runs/catalyst_modes/%s.png" % mode_id)
	print("[catalyst_modes] saved %s — color %s" % [mode_id, mode_color])
