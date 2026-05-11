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
# Real VR hand meshes — loading the GLTF models directly. The full
# lowpoly hand scenes carry hand.gd, which depends on XRToolsUserSettings
# autoload and won't compile in headless capture. The GLBs are just the
# skinned mesh + skeleton in rest pose — exactly what we want for a still.
const LEFT_HAND_SCENE := preload("res://addons/godot-xr-tools/hands/model/Hand_Nails_low_L.gltf")
const RIGHT_HAND_SCENE := preload("res://addons/godot-xr-tools/hands/model/Hand_Nails_low_R.gltf")


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
		# For the capture: hands slightly wider apart than the detector's
		# 30 cm threshold so both are clearly framed past the orb (in real
		# VR play they'd be closer; gameplay uses 30 cm proximity).
		left_pos = Vector3(-0.20, 1.30, -0.50)
		right_pos = Vector3(0.20, 1.30, -0.50)
		orb_origin = (left_pos + right_pos) * 0.5
		orb_dir = Vector3(0, -0.55, -1).normalized()
		two_handed = true
		cone_length = 2.2
	else:
		# Right hand presenting forward + down, left hand resting at hip.
		left_pos = Vector3(-0.25, 1.05, 0.05)
		right_pos = Vector3(0.18, 1.28, -0.50)
		orb_origin = right_pos
		orb_dir = Vector3(0.05, -0.55, -1).normalized()
		two_handed = false
		cone_length = 1.9

	# Hands — instantiate the VR hand meshes. Each hand needs a basis
	# that points fingers along orb_dir and rotates the model so the two
	# hands appear as distinct units (left palm faces right hand, right
	# palm faces left hand). The LEFT model is built for the left-hand
	# controller; the RIGHT model is its mirror — so the same "fingers
	# forward, palm inward" intent maps to MIRRORED rotations.
	if mode == "two_handed":
		_pose_hand(root, LEFT_HAND_SCENE, left_pos,
			_hand_basis(orb_dir, +1.0, true))
		_pose_hand(root, RIGHT_HAND_SCENE, right_pos,
			_hand_basis(orb_dir, -1.0, false))
	else:
		# Left hand at rest at hip, right hand presenting forward.
		_pose_hand(root, LEFT_HAND_SCENE, left_pos,
			_hand_basis(Vector3.FORWARD, +1.0, true))
		_pose_hand(root, RIGHT_HAND_SCENE, right_pos,
			_hand_basis(orb_dir, 0.0, false))

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
	# Elevated 3/4 from above-right: looking down at the gesture so the
	# hands separate visually rather than aligning along one line of sight.
	var cam := Camera3D.new()
	cam.fov = 50.0
	var cam_pos := Vector3(1.30, 2.10, 0.35)
	var cam_target := Vector3(-0.05, 0.85, -1.40)
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


## Instantiate a VR hand model at pos with the given basis, and stop any
## auto-playing animations so the static pose is what we set, not a
## mid-grip frame. Prints final transform for diagnosis.
func _pose_hand(parent: Node, scene: PackedScene, pos: Vector3, basis: Basis) -> void:
	var hand: Node3D = scene.instantiate()
	hand.position = pos
	hand.transform.basis = basis
	parent.add_child(hand)
	for child in hand.get_children():
		_stop_animation_players(child)
	print("[hand] %s at %s, basis_x=%s y=%s z=%s" % [
		hand.name, pos,
		basis.x.snapped(Vector3.ONE * 0.01),
		basis.y.snapped(Vector3.ONE * 0.01),
		basis.z.snapped(Vector3.ONE * 0.01),
	])


static func _stop_animation_players(node: Node) -> void:
	if node is AnimationPlayer:
		(node as AnimationPlayer).stop()
		(node as AnimationPlayer).process_mode = Node.PROCESS_MODE_DISABLED
	for c in node.get_children():
		_stop_animation_players(c)


## Build a Basis for a VR hand pose.
##
##  point_dir — world direction along which fingers should point
##  roll      — +1.0 rotates the hand so palm faces +X axis (right hand
##              palm faces left hand for two-handed gesture); -1.0 mirrors;
##              0.0 leaves palm down (typical resting/presenting pose).
##  is_left   — true for left-hand mesh; both meshes are intrinsically
##              mirrored, so we apply an additional 180° yaw to the right
##              hand model so its natural-side palm faces the left hand.
##
## XR Tools hand model convention (verified empirically: identity basis
## leaves fingers pointing along world -Z with palm facing world +Y):
##   local +X → thumb side (left for left mesh, right for right mesh)
##   local +Y → palm-up direction
##   local -Z → fingers forward
static func _hand_basis(point_dir: Vector3, roll: float, is_left: bool) -> Basis:
	# Start from identity (fingers along -Z, palm facing +Y).
	var b := Basis.IDENTITY
	# Roll around the model's local -Z axis (fingers axis) to bring palm
	# from "up" to facing inward / sideways. +90° rolls palm to face +X,
	# -90° to face -X.
	if abs(roll) > 0.01:
		b = b.rotated(Vector3.FORWARD, deg_to_rad(90.0 * roll))
	# Mirror right hand 180° around Y so it points across to the left.
	if not is_left:
		b = b.rotated(Vector3.UP, PI)
	# Now rotate everything so model's local -Z aligns with world point_dir.
	var current_forward := -b.z
	var target_forward := point_dir.normalized()
	var rot_axis := current_forward.cross(target_forward)
	if rot_axis.length_squared() > 0.0001:
		var ang := current_forward.angle_to(target_forward)
		b = Basis(rot_axis.normalized(), ang) * b
	return b.orthonormalized()
