@tool
extends SceneTree
# Captures two stills of the orb gesture for the auto-research-DNA pass.
#
# Output:
#   user://catalyst_runs/orb_gesture/two_handed.png
#   user://catalyst_runs/orb_gesture/one_handed.png
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/capture_orb_gesture.gd
#
# This script is now a thin wrapper over commons/testing/vr_capture_rig.gd.
# That module carries the reusable VR-mocking pieces (player figure,
# hand posing, cone-visual aid, camera defaults). See also
# doc/VR_CAPTURE_PATTERN.md.

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
const TEST_CREATURE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
# Preload the rig so we don't depend on class_name resolution
# (which can fail when this script is run in isolation with --script).
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/orb_gesture")

	await _capture("two_handed")
	await _capture("one_handed")
	print("[orb_gesture] complete")
	quit()


func _capture(mode: String) -> void:
	var root := Node3D.new()
	root.name = "OrbGestureCapture_%s" % mode

	# Environment + player figure (head + torso) via the rig.
	VRCaptureRig.build_environment(root)
	VRCaptureRig.build_player_figure(root)

	# Hand poses + orb origin/direction per mode.
	var left_pos: Vector3
	var right_pos: Vector3
	var orb_origin: Vector3
	var orb_dir: Vector3
	var two_handed: bool
	var cone_length: float

	if mode == "two_handed":
		# Hands slightly wider than the detector's 30 cm proximity for
		# capture-framing visibility (real play uses tighter spacing).
		left_pos = Vector3(-0.20, 1.30, -0.50)
		right_pos = Vector3(0.20, 1.30, -0.50)
		orb_origin = (left_pos + right_pos) * 0.5
		orb_dir = Vector3(0, -0.55, -1).normalized()
		two_handed = true
		cone_length = 2.2
	else:
		left_pos = Vector3(-0.25, 1.05, 0.05)   # at hip, resting
		right_pos = Vector3(0.18, 1.28, -0.50)  # presenting
		orb_origin = right_pos
		orb_dir = Vector3(0.05, -0.55, -1).normalized()
		two_handed = false
		cone_length = 1.9

	# Hands — mirrored bases for left vs right, named poses applied via
	# the XR Tools AnimationPlayer in the rig.
	if two_handed:
		VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
			VRCaptureRig.hand_basis(orb_dir, +1.0, true), "Cup", true)
		VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
			VRCaptureRig.hand_basis(orb_dir, -1.0, false), "Cup", false)
	else:
		VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
			VRCaptureRig.hand_basis(Vector3.FORWARD, +1.0, true), "Default pose", true)
		VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
			VRCaptureRig.hand_basis(orb_dir, 0.0, false), "Straight", false)

	# Orb (production scene) + cone visual (capture-only aid).
	var orb: Node3D = CATALYST_ORB.instantiate()
	root.add_child(orb)
	await process_frame
	var orb_light: OmniLight3D = null
	for c in orb.get_children():
		if c is OmniLight3D:
			orb_light = c
			break
	if orb_light != null:
		# Dim the production light for capture so close subjects don't
		# blow out (in VR rendering the light is right; in headless RGB
		# the camera clips at slightly different exposure).
		orb_light.light_energy = 0.9
		orb_light.omni_range = 0.8

	var cone_vis := VRCaptureRig.build_cone_visual(
		orb_origin,
		orb_dir,
		cone_length,
		VRCaptureRig.color_for_mode("primitives"),
	)
	root.add_child(cone_vis)

	# Creature in the cone — catalyst_foe's stage colour is legible.
	var creature: Node3D = TEST_CREATURE.instantiate()
	var creature_pos: Vector3 = orb_origin + orb_dir * 1.95
	creature_pos.y = max(creature_pos.y, 0.35)
	creature.position = creature_pos
	if creature.has_method("apply_grid_config"):
		creature.call("apply_grid_config", {
			"speed": 0.0,
			"chase_speed": 0.0,
			"detection_radius": 0.0,
		})
	root.add_child(creature)

	# Elevated 3/4 camera (so both hands separate visually in two-handed).
	var cam := VRCaptureRig.default_elevated_camera()
	root.add_child(cam)

	# Replace any existing scene.
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	# Let _ready fire on orb + creature.
	await process_frame
	await process_frame

	if orb.has_method("form"):
		orb.call("form", "primitives", orb_origin, orb_dir, two_handed)
	if creature.has_method("set_personality"):
		creature.call("set_personality", "curious")

	# Settle — gives the orb light, creature visual, and any procedural
	# geometry time to apply.
	for _i in range(120):
		await process_frame
		if orb.has_method("update_state"):
			orb.call("update_state", "primitives", orb_origin, orb_dir, cone_length, two_handed)

	# Capture
	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[orb_gesture] FAIL viewport null (%s)" % mode)
		return
	var out_path: String = "user://catalyst_runs/orb_gesture/%s.png" % mode
	img.save_png(out_path)
	print("[orb_gesture] saved %s" % mode)
