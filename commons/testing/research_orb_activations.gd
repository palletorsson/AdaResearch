@tool
extends SceneTree
# Activations: what the orb DOES when it shoots, per catalyst mode.
#
# Each mode has a distinct verb. The shape + palette tell you WHICH
# mode the bracelet is in. The activation tells you what that mode
# CHANGES in the world.
#
# Captured moments:
#   primitives    — color conversion (creature tints toward palette)
#   chromatic     — paint splash (mode-coloured particles around creature)
#   forces        — push (creature offset back from rest position)
#   transformation — rotation (creature spun around Y axis)
#   waveform      — oscillation (creature displaced on a sine curve)
#   chaos         — randomisation (creature jittered + recoloured)
#   fractal       — split (a smaller orb fragment beside the main)
#   cellular      — grid spread (small cubes radiating around impact)
#   branching     — tendrils (thin rods extending from impact point)
#   swarm         — multiplication (several small orbs orbiting main)

const CATALYST_ORB := preload("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
const TEST_CREATURE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

const ACTIVATIONS := [
	"primitives",
	"chromatic",
	"forces",
	"transformation",
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
		dir.make_dir_recursive("catalyst_runs/orb_activations")

	for mode in ACTIVATIONS:
		await _capture(mode)
	print("[orb_activations] complete — %d activations" % ACTIVATIONS.size())
	quit()


func _capture(mode: String) -> void:
	var root := Node3D.new()
	root.name = "OrbActivation_%s" % mode

	VRCaptureRig.build_environment(root)

	var orb_origin := Vector3(0, 1.30, -0.55)
	var aim_dir := Vector3(0, -0.40, -1).normalized()
	var cone_length := 2.0
	var mode_color := VRCaptureRig.color_for_mode(mode)

	# Hands cupping
	var hand_spacing := 0.16
	var left_pos := Vector3(-hand_spacing, 1.30, -0.45)
	var right_pos := Vector3(+hand_spacing, 1.30, -0.45)
	var basis := VRCaptureRig.hand_basis(aim_dir, 1.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		basis, "Cup", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		basis, "Cup", false)

	# Orb (deferred form)
	var orb: Node3D = CATALYST_ORB.instantiate()
	root.add_child(orb)

	# Cone visual aid
	var cone := VRCaptureRig.build_cone_visual(
		orb_origin, aim_dir, cone_length, mode_color)
	root.add_child(cone)

	# Base creature position (impact target)
	var creature_pos: Vector3 = orb_origin + aim_dir * 1.85
	creature_pos.y = max(creature_pos.y, 0.35)

	# Activation-specific scene additions
	var creature: Node3D = _add_creature_for_activation(root, creature_pos, mode, mode_color)
	_add_activation_decoration(root, creature_pos, mode, mode_color, orb_origin)

	# FPV camera
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.05, -0.85), 85.0)
	root.add_child(cam)

	# Replace scene
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	await process_frame
	await process_frame

	# Form the orb with this mode + apply noise shader
	if orb.has_method("form"):
		orb.call("form", mode, orb_origin, aim_dir, true)
		VRCaptureRig.apply_orb_noise_shader(orb, mode, 0.06, 1.2)
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
		print("[orb_activations] FAIL %s" % mode)
		return
	img.save_png("user://catalyst_runs/orb_activations/%s.png" % mode)
	print("[orb_activations] saved %s" % mode)


# Create + position the creature with mode-specific tweaks (rotation,
# offset, recolor, etc.)
func _add_creature_for_activation(root: Node3D, base_pos: Vector3, mode: String, mode_color: Color) -> Node3D:
	var creature: Node3D = TEST_CREATURE.instantiate()
	var pos := base_pos
	var rot := Vector3.ZERO

	match mode:
		"forces":
			# Pushed back from base position
			pos += Vector3(0, 0.1, -0.6)
		"transformation":
			# Rotated 30° around Y
			rot = Vector3(0, deg_to_rad(30), 0)
		"waveform":
			# Displaced on a sine arc — shifted up + slightly side
			pos += Vector3(0.15, 0.25, 0)
			rot = Vector3(0, 0, deg_to_rad(15))
		"chaos":
			# Jittered + tilted
			pos += Vector3(0.10, 0.05, -0.10)
			rot = Vector3(deg_to_rad(20), deg_to_rad(45), deg_to_rad(10))

	creature.position = pos
	creature.rotation = rot
	if creature.has_method("apply_grid_config"):
		creature.call("apply_grid_config", {
			"speed": 0.0, "chase_speed": 0.0, "detection_radius": 0.0,
		})
	root.add_child(creature)
	return creature


# Add per-mode decoration around the creature/impact: particles, splits,
# tendrils, swarm orbs, etc.
func _add_activation_decoration(root: Node3D, impact_pos: Vector3, mode: String, mode_color: Color, orb_origin: Vector3) -> void:
	match mode:
		"chromatic":
			# Paint splash: small spheres of mode color spreading around impact
			_spawn_paint_splash(root, impact_pos, mode_color, 12)
		"fractal":
			# Split fragment: smaller orb beside main
			_spawn_split_fragment(root, orb_origin, mode_color)
		"cellular":
			# Grid spread: small cubes in a 3x3 pattern around impact
			_spawn_grid_cells(root, impact_pos, mode_color)
		"branching":
			# Tendrils: thin cylinders extending outward from impact
			_spawn_tendrils(root, impact_pos, mode_color)
		"swarm":
			# Small orbs orbiting the main orb
			_spawn_swarm(root, orb_origin, mode_color)


func _spawn_paint_splash(root: Node3D, center: Vector3, color: Color, count: int) -> void:
	for i in range(count):
		var s := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = randf_range(0.025, 0.06)
		sphere.height = sphere.radius * 2.0
		s.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.8
		s.material_override = mat
		var offset := Vector3(
			randf_range(-0.4, 0.4),
			randf_range(-0.2, 0.4),
			randf_range(-0.3, 0.3),
		)
		s.position = center + offset
		root.add_child(s)


func _spawn_split_fragment(root: Node3D, orb_origin: Vector3, color: Color) -> void:
	# Smaller orb beside main orb
	var frag := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.09
	frag.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color * 1.1
	frag.material_override = mat
	frag.position = orb_origin + Vector3(0.18, 0.05, 0.05)
	root.add_child(frag)
	# Plus a tinier one
	var tiny := MeshInstance3D.new()
	var ts := SphereMesh.new()
	ts.radius = 0.025
	ts.height = 0.05
	tiny.mesh = ts
	tiny.material_override = mat
	tiny.position = orb_origin + Vector3(0.25, -0.05, 0.1)
	root.add_child(tiny)


func _spawn_grid_cells(root: Node3D, center: Vector3, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue
			var cube := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.10, 0.10, 0.10)
			cube.mesh = box
			cube.material_override = mat
			cube.position = center + Vector3(x * 0.18, y * 0.18, 0)
			root.add_child(cube)


func _spawn_tendrils(root: Node3D, center: Vector3, color: Color) -> void:
	# Several thin cylinders branching outward from impact
	var directions: Array[Vector3] = [
		Vector3( 0.3,  0.4, 0.0),
		Vector3(-0.3,  0.3, 0.1),
		Vector3( 0.1,  0.6, -0.1),
		Vector3(-0.2, -0.3, 0.0),
		Vector3( 0.4, -0.2, 0.2),
	]
	for d in directions:
		var tendril := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.012
		cyl.bottom_radius = 0.025
		cyl.height = d.length() * 1.4
		tendril.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5
		tendril.material_override = mat
		# Orient tendril along d
		var up_dir := d.normalized()
		var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var rx := up_dir.cross(ref_v).normalized()
		var rz := rx.cross(up_dir).normalized()
		tendril.transform.basis = Basis(rx, up_dir, rz)
		tendril.position = center + d * 0.5
		root.add_child(tendril)


func _spawn_swarm(root: Node3D, center: Vector3, color: Color) -> void:
	# Small orbs orbiting the main orb
	var positions: Array[Vector3] = [
		Vector3( 0.18,  0.08,  0.05),
		Vector3(-0.15,  0.10, -0.08),
		Vector3( 0.08, -0.12,  0.12),
		Vector3(-0.18, -0.08, -0.05),
		Vector3( 0.05,  0.15, -0.10),
		Vector3(-0.05, -0.15,  0.10),
	]
	for p in positions:
		var s := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		s.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color * 1.1
		s.material_override = mat
		s.position = center + p
		root.add_child(s)
