@tool
extends SceneTree
# The orb's lifecycle as a world actor.
#
# Focused on what the bracelet projects — the orb itself in frame, the
# bracelet treated as the offstage source. These captures concentrate
# on the orb's presence, emergence, and action.
#
# Lifecycle:
#   orb       — the form itself, floating alone (reference)
#   at_rest   — hands relaxed, no orb yet (potential)
#   humming   — hands cupping, orb formed but not yet projecting
#                ("I am holding the catalyst")
#   shooting  — orb projecting cone, creature being bathed
#                (active, doing its work)
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

	# State-specific config. Bracelet removed — captures focus on what
	# the bracelet PROJECTS (the orb), not on the bracelet itself.
	var show_hands := true
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

	# Bracelet intentionally not rendered here — captures focus on the
	# orb itself as the projected actor. The bracelet is the offstage
	# source (its own variant in the gallery shows it directly).

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
		# Apply the noise+palette shader so the orb reads as alive —
		# 3D-noise-displaced sphere mixed across the mode's palette
		# instead of one flat-emission sphere.
		VRCaptureRig.apply_orb_noise_shader(orb, "primitives", 0.06, 1.2)
		for c in orb.get_children():
			if c is OmniLight3D:
				(c as OmniLight3D).light_energy = 0.3
				(c as OmniLight3D).omni_range = 0.5

	# Settle (gives orb's _apply_pose time, creature personality, etc.).
	for _i in range(40):
		await process_frame
		# For shooting, keep dispatching update_state so the cone Area3D
		# ticks the creature into curious state. update_state rewrites
		# the orb's material every frame, so we re-enrich afterwards.
		if state == "shooting" and orb != null and orb.has_method("update_state"):
			orb.call("update_state", "primitives", orb_origin, aim_dir, cone_length, true)
			# Re-apply shader — update_state may have reset material_override.
			VRCaptureRig.apply_orb_noise_shader(orb, "primitives", 0.06, 1.2)

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


## Enrich the production orb visual for capture:
##   - Tame the OmniLight + emission so the mode color reads
##   - Add a translucent outer halo sphere for depth + presence
##   - Add a brighter inner core for centre-of-energy reading
##
## Idempotent: if the halo/core already exist (named children), they're
## reused; only their materials are updated. This lets the function be
## called inside an update_state loop without leaking nodes.
static func _enrich_orb_visual(orb: Node3D, mode_color: Color) -> void:
	var has_halo := false
	var has_core := false
	for c in orb.get_children():
		if c is OmniLight3D:
			var light := c as OmniLight3D
			light.light_energy = 0.7
			light.omni_range = 0.6
			light.light_color = mode_color
		elif c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.name == "OrbHaloCapture":
				has_halo = true
				_apply_halo_mat(mi, mode_color)
			elif mi.name == "OrbCoreCapture":
				has_core = true
				_apply_core_mat(mi, mode_color)
			else:
				# The production orb's inner sphere.
				var mat := mi.material_override as StandardMaterial3D
				if mat != null:
					mat.emission = mode_color
					mat.albedo_color = mode_color
					mat.albedo_color.a = 0.95
					mat.emission_energy_multiplier = 1.4

	if has_halo and has_core:
		return  # nothing more to add

	# Outer halo — slightly larger, much more translucent. Reads as the
	# orb's aura / field-edge.
	var halo := MeshInstance3D.new()
	halo.name = "OrbHaloCapture"
	var halo_sphere := SphereMesh.new()
	halo_sphere.radius = 0.13
	halo_sphere.height = 0.26
	halo_sphere.radial_segments = 32
	halo_sphere.rings = 16
	halo.mesh = halo_sphere
	var halo_mat := StandardMaterial3D.new()
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.albedo_color = Color(mode_color.r, mode_color.g, mode_color.b, 0.18)
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.emission_enabled = true
	halo_mat.emission = mode_color
	halo_mat.emission_energy_multiplier = 0.5
	halo_mat.cull_mode = BaseMaterial3D.CULL_BACK
	halo.material_override = halo_mat
	orb.add_child(halo)

	# Inner core — a smaller, brighter sphere right at the orb's centre.
	var core := MeshInstance3D.new()
	core.name = "OrbCoreCapture"
	var core_sphere := SphereMesh.new()
	core_sphere.radius = 0.045
	core_sphere.height = 0.09
	core_sphere.radial_segments = 24
	core_sphere.rings = 12
	core.mesh = core_sphere
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	core_mat.emission_enabled = true
	# Slightly desaturated mode color so the core reads as "bright with
	# a hint of mode" rather than the same colour as the outer shell.
	var core_emission := mode_color.lerp(Color(1, 1, 1), 0.4)
	core_mat.emission = core_emission
	core_mat.emission_energy_multiplier = 2.0
	core.material_override = core_mat
	orb.add_child(core)


static func _apply_halo_mat(halo: MeshInstance3D, mode_color: Color) -> void:
	var mat := halo.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = Color(mode_color.r, mode_color.g, mode_color.b, 0.18)
	mat.emission = mode_color


static func _apply_core_mat(core: MeshInstance3D, mode_color: Color) -> void:
	var mat := core.material_override as StandardMaterial3D
	if mat == null:
		return
	var core_emission := mode_color.lerp(Color(1, 1, 1), 0.4)
	mat.emission = core_emission
