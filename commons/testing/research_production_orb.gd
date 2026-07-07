@tool
extends SceneTree
# Production validation: instantiate the live CatalystOrb (not the
# capture-side procedural form) and verify that form() dispatches to
# the per-mode held-matter forms for swarm / forces / branching.
#
# If the rendered images match the held_matter captures, the production
# dispatch is wired correctly and the headset will show the same forms
# the gallery has been previewing.
#
# Output: user://catalyst_runs/production_orb/<mode>.png

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

const MODES_TO_TEST := ["swarm", "forces", "branching", "primitives"]


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/production_orb")

	for mode in MODES_TO_TEST:
		await _capture(mode)
	print("[production_orb] complete")
	quit()


func _capture(mode_id: String) -> void:
	var root := Node3D.new()
	root.name = "ProductionOrb_%s" % mode_id

	VRCaptureRig.build_environment(root)

	var orb_origin := Vector3(0, 1.30, -0.55)
	var aim_dir := Vector3(0, -0.55, -1).normalized()
	var mode_color := VRCaptureRig.color_for_mode(mode_id)

	# Hands cupping — same gesture as the held_matter captures so we
	# can directly compare production vs gallery.
	var hand_spacing := 0.20
	var left_pos := Vector3(-hand_spacing, 1.30, -0.45)
	var right_pos := Vector3(+hand_spacing, 1.30, -0.45)
	var basis := VRCaptureRig.hand_basis(aim_dir, 1.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		basis, "Cup", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		basis, "Cup", false)

	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	var forearm_dir := Vector3(0.3, -0.1, 0.9)
	VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir, mode_color)

	# PRODUCTION orb — instantiate the live scene.
	var orb: Node3D = CATALYST_ORB.instantiate()
	root.add_child(orb)

	# Camera
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.05, -0.85), 85.0)
	root.add_child(cam)

	# Add to tree so _ready() runs and procedural build happens.
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	await process_frame
	await process_frame

	# Now call form() — this is the production dispatch under test.
	if orb.has_method("form"):
		orb.call("form", mode_id, orb_origin, aim_dir, true)

	# Let the orb settle and the noise shader animate a few frames.
	for _i in range(40):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[production_orb] FAIL %s" % mode_id)
		return
	img.save_png("user://catalyst_runs/production_orb/%s.png" % mode_id)
	print("[production_orb] saved %s" % mode_id)
