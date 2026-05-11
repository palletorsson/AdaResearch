@tool
extends SceneTree
# The orb's lifecycle as a world actor — grounded in the bracelet.
#
# The bracelet is the player's persistent worn tool (always on the
# left wrist). The orb is the bracelet's MOMENTARY MANIFESTATION when
# the gesture is held — not a standalone object.
#
# Lifecycle:
#   orb       — the form itself, floating alone (reference)
#   at_rest   — bracelet worn, hands relaxed, no orb yet (potential)
#   humming   — bracelet worn, hands cupping, orb formed but not yet
#                projecting ("I am holding the catalyst")
#   shooting  — bracelet worn, orb projecting cone, creature being
#                bathed (active, doing its work)
#
# Captured FPV (from behind the player's eyes).

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
const TEST_CREATURE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/orb_lifecycle")

	await _capture("orb")
	await _capture("at_rest")
	await _capture("humming")
	await _capture("shooting")
	print("[orb_lifecycle] complete")
	quit()


func _capture(state: String) -> void:
	var root := Node3D.new()
	root.name = "OrbLifecycle_%s" % state

	VRCaptureRig.build_environment(root)

	var orb_origin := Vector3(0, 1.30, -0.55)
	var aim := Vector3(0, -0.55, -1).normalized()
	var cone_length := 2.2

	# State-specific config
	var show_hands := true
	var show_bracelet := true   # always worn — only hidden for the pure "orb" reference shot
	var show_orb := true
	var show_cone := true
	var show_creature := true
	var orb_roll := 0.0
	var hand_spacing := 0.16
	var aim_dir := aim
	var hand_pose := "Cup"

	match state:
		"orb":
			# Pure reference — just the orb form, nothing else.
			show_hands = false
			show_bracelet = false
			show_cone = false
			show_creature = false
		"at_rest":
			show_orb = false
			show_cone = false
			show_creature = false
			orb_roll = 0.0
			hand_pose = "Default pose"
			hand_spacing = 0.22
		"humming":
			show_cone = false
			show_creature = false
			orb_roll = 1.0
			hand_spacing = 0.20
			hand_pose = "Cup"
		"shooting":
			orb_roll = 1.0
			hand_spacing = 0.16
			hand_pose = "Cup"
			aim_dir = Vector3(0, -0.40, -1).normalized()

	# Hands (deferred — positions don't depend on tree state).
	var left_pos := Vector3(-hand_spacing, 1.30, -0.45)
	var right_pos := Vector3(+hand_spacing, 1.30, -0.45)
	if show_hands:
		var basis := VRCaptureRig.hand_basis(aim_dir, orb_roll, true)
		VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
			basis, hand_pose, true)
		VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
			basis, hand_pose, false)

	# Bracelet — worn on left wrist. The orb is the bracelet's projection;
	# the bracelet is the persistent worn tool. Always visible except in
	# the pure "orb" reference shot.
	if show_bracelet:
		# Position on the forearm just past the wrist. With natural rest,
		# the forearm extends from the wrist (hand position) back along
		# +Z and slightly down toward the chest centre.
		var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
		var forearm_dir := Vector3(0.3, -0.1, 0.9)
		VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir,
			VRCaptureRig.color_for_mode("primitives"))

	# Orb (instantiate now, form() AFTER tree-add — see below).
	var orb: Node3D = null
	if show_orb:
		orb = CATALYST_ORB.instantiate()
		root.add_child(orb)

	# Cone visualization aid.
	if show_cone:
		var cone := VRCaptureRig.build_cone_visual(
			orb_origin, aim_dir, cone_length,
			VRCaptureRig.color_for_mode("primitives"))
		root.add_child(cone)

	# Creature.
	if show_creature:
		var creature: Node3D = TEST_CREATURE.instantiate()
		var creature_pos: Vector3 = orb_origin + aim_dir * 1.95
		creature_pos.y = max(creature_pos.y, 0.35)
		creature.position = creature_pos
		if creature.has_method("apply_grid_config"):
			creature.call("apply_grid_config", {
				"speed": 0.0, "chase_speed": 0.0, "detection_radius": 0.0,
			})
		root.add_child(creature)

	# Camera
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.05, -0.85), 85.0)
	root.add_child(cam)

	# Replace scene FIRST — then settle, then call form() on orb.
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	await process_frame
	await process_frame

	# Now the orb is fully in tree; form() can set global_position.
	if orb != null and orb.has_method("form"):
		orb.call("form", "primitives", orb_origin, aim_dir, true)
		# Tune the orb's OmniLight so it doesn't blow out close subjects.
		for c in orb.get_children():
			if c is OmniLight3D:
				(c as OmniLight3D).light_energy = 0.9
				(c as OmniLight3D).omni_range = 0.8

	# Settle (gives orb's _apply_pose time, creature personality, etc.).
	for _i in range(40):
		await process_frame
		# For shooting, keep dispatching update_state so the cone Area3D
		# ticks the creature into curious state.
		if state == "shooting" and orb != null and orb.has_method("update_state"):
			orb.call("update_state", "primitives", orb_origin, aim_dir, cone_length, true)

	# Capture.
	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[orb_lifecycle] FAIL %s" % state)
		return
	img.save_png("user://catalyst_runs/orb_lifecycle/%s.png" % state)
	print("[orb_lifecycle] saved %s" % state)
