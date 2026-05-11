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
# Approach: no XR rig in headless; instead we instantiate the CatalystOrb
# directly and drive form()/update_state() with the hand positions we
# want to depict. A small "head" sphere + simple hand boxes + a single
# creature (in CURIOUS state) make the spatial relationship legible.

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
# Use catalyst_foe — its personality-stage colour signature (grey/red/tan/yellow/green)
# is the cleanest still-image evidence of state change.
const TEST_CREATURE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")


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

	# Floor
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6.0, 6.0)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.88, 0.85, 0.72)
	floor_mat.roughness = 0.7
	floor.material_override = floor_mat
	root.add_child(floor)

	# Environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.50, 0.48)
	env.ambient_light_color = Color(0.85, 0.85, 0.90)
	env.ambient_light_energy = 0.55
	env_node.environment = env
	root.add_child(env_node)

	# Lights
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.96, 0.86)
	key.light_energy = 1.0
	key.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.78, 0.86, 1.0)
	fill.light_energy = 0.45
	fill.rotation = Vector3(deg_to_rad(-25), deg_to_rad(-130), 0)
	root.add_child(fill)

	# Player figure (head + torso hints; the figure orientation looks
	# forward = -Z so the gesture pushes away from the camera-left).
	var head_mesh := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.105
	head_sphere.height = 0.21
	head_mesh.mesh = head_sphere
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.85, 0.75, 0.68)
	skin_mat.roughness = 0.7
	head_mesh.material_override = skin_mat
	head_mesh.position = Vector3(0, 1.62, 0)
	root.add_child(head_mesh)

	var torso := MeshInstance3D.new()
	var torso_mesh := CylinderMesh.new()
	torso_mesh.top_radius = 0.16
	torso_mesh.bottom_radius = 0.20
	torso_mesh.height = 0.65
	torso.mesh = torso_mesh
	var torso_mat := StandardMaterial3D.new()
	torso_mat.albedo_color = Color(0.30, 0.32, 0.36)
	torso_mat.roughness = 0.8
	torso.material_override = torso_mat
	torso.position = Vector3(0, 1.20, 0)
	root.add_child(torso)

	# Hands + orb origin/direction per mode
	var head_pos := Vector3(0, 1.62, 0)
	var left_pos: Vector3
	var right_pos: Vector3
	var orb_origin: Vector3
	var orb_dir: Vector3
	var two_handed: bool
	var cone_length: float

	if mode == "two_handed":
		# Palms together, extended out from chest, aimed down at a floor creature.
		# (In VR the player naturally tilts palms toward what they want to dose.)
		left_pos = Vector3(-0.14, 1.30, -0.50)
		right_pos = Vector3(0.14, 1.30, -0.50)
		orb_origin = (left_pos + right_pos) * 0.5
		orb_dir = Vector3(0, -0.55, -1).normalized()
		two_handed = true
		cone_length = 2.2
	else:
		# Right hand presenting forward + down, left hand at hip
		left_pos = Vector3(-0.25, 1.05, 0.05)
		right_pos = Vector3(0.18, 1.28, -0.50)
		orb_origin = right_pos
		orb_dir = Vector3(0.05, -0.55, -1).normalized()
		two_handed = false
		cone_length = 1.9

	_add_hand(root, left_pos, skin_mat, mode == "one_handed" and false, true)
	_add_hand(root, right_pos, skin_mat, true, false)

	# Orb (instantiated directly; no detector)
	var orb: Node3D = CATALYST_ORB.instantiate()
	root.add_child(orb)
	# Dim the orb's OmniLight for capture — the real VR light is right
	# for headset rendering but blows out close subjects in headless RGB.
	await process_frame
	var orb_light: OmniLight3D = orb.get_node_or_null("OmniLight3D") as OmniLight3D
	if orb_light == null:
		# OmniLight is built procedurally; find it
		for c in orb.get_children():
			if c is OmniLight3D:
				orb_light = c
				break
	if orb_light != null:
		orb_light.light_energy = 0.9
		orb_light.omni_range = 0.8

	# Cone visualization aid — a soft translucent cylinder mesh showing the
	# field's reach. Added only for the capture; production VR uses just the
	# orb sphere + OmniLight. If this iteration validates the visual, we
	# might bring a particle-stream version into the production orb.
	var cone_vis := MeshInstance3D.new()
	var cone_mesh := CylinderMesh.new()
	cone_mesh.height = cone_length
	cone_mesh.top_radius = 0.35
	cone_mesh.bottom_radius = 0.05
	cone_vis.mesh = cone_mesh
	var cone_mat := StandardMaterial3D.new()
	var mode_color := Color(0.40, 0.95, 0.60)  # primitives
	cone_mat.albedo_color = Color(mode_color.r, mode_color.g, mode_color.b, 0.18)
	cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_mat.emission_enabled = true
	cone_mat.emission = mode_color
	cone_mat.emission_energy_multiplier = 0.45
	cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone_vis.material_override = cone_mat
	# Aim the cylinder along orb_dir (cylinder's Y is along height).
	var up_dir := orb_dir.normalized()
	var cone_basis := Basis()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	cone_basis = Basis(rx, up_dir, rz)
	cone_vis.transform.basis = cone_basis
	cone_vis.position = orb_origin + orb_dir * (cone_length * 0.5)
	root.add_child(cone_vis)

	# Creature in the cone — catalyst_foe whose stage colour is legible.
	# Place it far enough down the cone that the orb's OmniLight doesn't
	# blow out the personality-state hue.
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

	# Camera — 3/4 elevated view, slightly to player's right, framing
	# head + both hands + orb + creature. Using look_at_from_position
	# avoids the tree-state race that look_at(target) hits on the first
	# capture (before current_scene is set).
	var cam := Camera3D.new()
	cam.fov = 52.0
	var cam_pos := Vector3(1.55, 1.85, 0.45)
	var cam_target := Vector3(-0.05, 0.80, -1.50)
	cam.transform = Transform3D().looking_at(
		cam_target - cam_pos,
		Vector3.UP,
	)
	cam.position = cam_pos
	root.add_child(cam)

	# Replace any existing scene
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	# Let _ready fire on orb + creature (builds geometry).
	await process_frame
	await process_frame

	# Drive orb into formed state.
	if orb.has_method("form"):
		orb.call("form", "primitives", orb_origin, orb_dir, two_handed)

	# Set creature personality after _ready so visuals are applied.
	if creature.has_method("set_personality"):
		creature.call("set_personality", "curious")

	# Settle for several frames so the orb's light + the creature's
	# curious-state colour shift apply, and the cone Area3D ticks.
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


func _add_hand(parent: Node, pos: Vector3, skin_mat: StandardMaterial3D, _palm_forward: bool, _is_left: bool) -> void:
	var hand_root := Node3D.new()
	hand_root.position = pos
	parent.add_child(hand_root)
	# Palm (small flattened box)
	var palm := MeshInstance3D.new()
	var palm_mesh := BoxMesh.new()
	palm_mesh.size = Vector3(0.085, 0.025, 0.105)
	palm.mesh = palm_mesh
	palm.material_override = skin_mat
	hand_root.add_child(palm)
	# Forearm hint (cylinder pointing back toward shoulder area)
	var forearm := MeshInstance3D.new()
	var fa_mesh := CylinderMesh.new()
	fa_mesh.top_radius = 0.028
	fa_mesh.bottom_radius = 0.032
	fa_mesh.height = 0.22
	forearm.mesh = fa_mesh
	forearm.material_override = skin_mat
	# Aim back toward torso position (0, 1.20, 0)
	var to_torso: Vector3 = Vector3(0, 1.20, 0) - pos
	forearm.position = to_torso * 0.5
	if to_torso.length_squared() > 0.001:
		var fa_basis := Basis()
		var y := to_torso.normalized()
		var ref := Vector3.UP if abs(y.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var x := y.cross(ref).normalized()
		var z := x.cross(y).normalized()
		fa_basis = Basis(x, y, z)
		forearm.transform.basis = fa_basis
