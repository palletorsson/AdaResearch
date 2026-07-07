@tool
extends SceneTree
# Activations: what the orb DOES when it shoots, per catalyst mode.
#
# Each mode has a distinct verb. The shape + palette tell you WHICH
# mode the bracelet is in. The activation tells you what that mode
# CHANGES in the world.
#
# Verbs aligned with production projectile scripts (see sieve pass
# 2026-05-11T19-25-26_activation-verbs.md for the contract).
#
# Captured moments:
#   primitives    — bounce-and-tint (orb bounces, creature tints toward palette)
#   chromatic     — paint (mode-coloured cubes scattered around creature)
#   forces        — gather (creature pulled toward warm-amber calming field)
#   transformation — shrink (creature at 0.5× with translucent original-size ghost)
#   waveform      — oscillate (creature displaced on a sine curve)
#   chaos         — arc (Tesla-style branching lightning from orb to creature)
#   fractal       — split (smaller orb fragments beside main orb)
#   cellular      — evolve (3×3 CA cube pattern around impact)
#   branching     — grow (thin tendrils extending outward from impact)
#   swarm         — flock (independent orbs seeking creature on varied headings)

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
	var creature_scale := Vector3.ONE

	match mode:
		"forces":
			# Gather: creature pulled IN toward the orb, not pushed away.
			# Slight forward offset (positive z = toward orb origin) — the
			# calming field holds it close, not at arm's length.
			pos += Vector3(0, 0.0, 0.30)
		"transformation":
			# Shrink: creature reduced to 0.5× size, lowered to sit on
			# the ground at new scale. Ghost-outline of original size is
			# spawned separately as decoration.
			creature_scale = Vector3(0.5, 0.5, 0.5)
			pos += Vector3(0, -0.18, 0)
		"waveform":
			# Displaced on a sine arc — shifted up + slightly side. The
			# verb "oscillate" reads on the orb's path, but the creature's
			# arc offset still shows the wave-effect at impact.
			pos += Vector3(0.15, 0.25, 0)
			rot = Vector3(0, 0, deg_to_rad(15))
		"chaos":
			# Arc: creature stays at impact, undisturbed in pose. The
			# verb is in the lightning decoration, not in jitter.
			pass

	creature.position = pos
	creature.rotation = rot
	creature.scale = creature_scale
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
		"primitives":
			# Bounce-and-tint: parabolic trail of fading orb-positions from
			# orb_origin down to impact, plus a soft tinted halo around
			# the creature.
			_spawn_bounce_trail(root, orb_origin, impact_pos, mode_color)
			_spawn_tint_halo(root, impact_pos, mode_color)
		"chromatic":
			# Paint splash: small spheres of mode color spreading around impact
			_spawn_paint_splash(root, impact_pos, mode_color, 12)
		"forces":
			# Gather: warm-amber concentric rings + inward arrows holding
			# the creature in a calming field. The verb is "force as care",
			# not push.
			_spawn_gather_halo(root, impact_pos, mode_color)
		"transformation":
			# Shrink: translucent original-size ghost-outline beside the
			# shrunken creature, so before-and-after is in the frame.
			_spawn_ghost_outline(root, impact_pos, mode_color)
		"chaos":
			# Arc: Tesla-style branching lightning from orb to creature.
			_spawn_lightning_arc(root, orb_origin, impact_pos, mode_color)
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
			# Flock: 8 small orbs scattered between orb and creature, all
			# headed toward the creature on independent paths.
			_spawn_flock(root, orb_origin, impact_pos, mode_color)


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


func _spawn_flock(root: Node3D, orb_origin: Vector3, target: Vector3, color: Color) -> void:
	# 8 boid spheres scattered between orb and creature, each on its own
	# heading toward the target. Tiny tail-line behind each boid shows
	# its velocity direction. Independent agents — not orbiting.
	# Perpendicular spread biased toward ±X so the boids splay sideways
	# from the camera-occluded orb→creature line.
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xF10C  # stable across runs
	var to_target := target - orb_origin
	for i in range(8):
		# Place each boid at a random fraction along the orb→target axis,
		# scattered widely perpendicular to it.
		var t := rng.randf_range(0.15, 0.80)
		var on_axis: Vector3 = orb_origin + to_target * t
		# X-spread is the largest — boids sweep wide left/right so they
		# read as a swarm-on-approach, not a tight column.
		var perp_x := rng.randf_range(-0.70, 0.70)
		var perp_y := rng.randf_range(-0.25, 0.35)
		var perp_z := rng.randf_range(-0.10, 0.10)
		var boid_pos: Vector3 = on_axis + Vector3(perp_x, perp_y, perp_z)

		var s := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		s.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color * 1.1
		s.material_override = mat
		s.position = boid_pos
		root.add_child(s)

		# Velocity tail — short line from a step behind the boid to the
		# boid itself, oriented along (target - boid).
		var to_creature: Vector3 = (target - boid_pos).normalized()
		var tail_len := 0.10
		var tail := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.008
		cyl.bottom_radius = 0.008
		cyl.height = tail_len
		tail.mesh = cyl
		var tail_mat := StandardMaterial3D.new()
		tail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tail_mat.albedo_color = Color(color.r, color.g, color.b, 0.6)
		tail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tail.material_override = tail_mat
		var ref_v := Vector3.UP if abs(to_creature.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var rx := to_creature.cross(ref_v).normalized()
		var rz := rx.cross(to_creature).normalized()
		tail.transform.basis = Basis(rx, to_creature, rz)
		tail.position = boid_pos - to_creature * (tail_len * 0.5)
		root.add_child(tail)


# Bounce-and-tint trail: a parabolic chain of fading orb-positions
# from orb_origin down-and-out-then-back to impact_pos, suggesting the
# primitives orb's bounce trajectory. Apex pushed sideways so the curve
# is visible past the orb's silhouette from the FPV camera.
func _spawn_bounce_trail(root: Node3D, orb_origin: Vector3, impact: Vector3, color: Color) -> void:
	var steps := 10
	var mid := (orb_origin + impact) * 0.5
	# Bounce apex: pushed -X (to the player's left, opposite the right
	# hand) AND down toward the floor, so the trail arcs visibly around
	# the orb/creature past the hands' silhouettes.
	mid.x -= 0.65
	mid.y = min(orb_origin.y, impact.y) - 0.50
	for i in range(steps):
		var t := float(i) / float(steps - 1)
		# Quadratic Bezier: origin → mid → impact
		var one_minus := 1.0 - t
		var p: Vector3 = one_minus * one_minus * orb_origin \
			+ 2.0 * one_minus * t * mid \
			+ t * t * impact

		var s := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		# Trail fades — newer (closer to impact) is solid, older fades.
		var fade := 0.55 + 0.45 * t
		sphere.radius = 0.055 * (0.7 + 0.5 * t)
		sphere.height = sphere.radius * 2.0
		s.mesh = sphere
		# Shift the trail toward white-hot so it reads as a fast-moving
		# ball, not as more orb-mass.
		var trail_col := color.lerp(Color(1, 1, 1), 0.45)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(trail_col.r, trail_col.g, trail_col.b, fade)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = trail_col
		mat.emission_energy_multiplier = 1.6 * fade
		# Render on top of the hands/orb so the trail is legible from FPV.
		mat.no_depth_test = true
		s.material_override = mat
		s.position = p
		root.add_child(s)


# Soft tinted halo around the creature — primitives' "tint" verb. A
# small translucent sphere of mode color around the creature's core
# (not enveloping its whole volume — keeps the bounce trail readable).
func _spawn_tint_halo(root: Node3D, center: Vector3, color: Color) -> void:
	var halo := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	halo.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.22
	halo.material_override = mat
	halo.position = center + Vector3(0, 0.05, 0)
	root.add_child(halo)


# Gather halo: three concentric warm-amber rings on the horizontal
# plane around the creature, plus 4 inward-pointing arrows from the
# cardinal directions — the calming field that pulls in, not pushes.
func _spawn_gather_halo(root: Node3D, center: Vector3, color: Color) -> void:
	# Concentric rings (TorusMesh).
	var ring_radii: Array[float] = [0.45, 0.32, 0.20]
	for r in ring_radii:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.018
		torus.outer_radius = r
		ring.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(color.r, color.g, color.b, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.7
		ring.material_override = mat
		# Lay flat on the ground around the creature's base.
		ring.position = center + Vector3(0, -0.20, 0)
		root.add_child(ring)

	# Four inward-pointing arrows from cardinal directions.
	var directions: Array[Vector3] = [
		Vector3( 1, 0, 0), Vector3(-1, 0, 0),
		Vector3( 0, 0, 1), Vector3( 0, 0, -1),
	]
	for d in directions:
		var arrow_start: Vector3 = center + d * 0.65 + Vector3(0, -0.10, 0)
		var arrow_end: Vector3 = center + d * 0.40 + Vector3(0, -0.10, 0)
		_spawn_arrow_segment(root, arrow_start, arrow_end, color)


func _spawn_arrow_segment(root: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var dir := to - from
	var length := dir.length()
	if length < 0.001:
		return
	# Shaft.
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = length * 0.75
	shaft.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	shaft.material_override = mat
	var up_dir := dir.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	shaft.transform.basis = Basis(rx, up_dir, rz)
	shaft.position = from + dir * (0.75 * 0.5)
	root.add_child(shaft)
	# Tip — a small cone at the "to" end.
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.035
	cone.height = length * 0.30
	tip.mesh = cone
	tip.material_override = mat
	tip.transform.basis = shaft.transform.basis
	tip.position = to - up_dir * (length * 0.15)
	root.add_child(tip)


# Shrink ghost: translucent box at the creature's original size + shape,
# beside the shrunken creature. Shows before-and-after in one frame.
func _spawn_ghost_outline(root: Node3D, center: Vector3, color: Color) -> void:
	# Position the ghost slightly to the side of the shrunken creature
	# so they read as adjacent states.
	var ghost_pos: Vector3 = center + Vector3(0.45, 0.10, 0)
	var ghost := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.65, 0.55)
	ghost.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	ghost.material_override = mat
	ghost.position = ghost_pos
	root.add_child(ghost)


# Lightning arc: a polyline of zig-zag cylinder segments from orb_origin
# to impact, bowed sideways and upward so the arc is visible past the
# orb/creature silhouette. Two fork branches splay off mid-path.
func _spawn_lightning_arc(root: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xA2C  # stable
	var segments := 8
	var points: Array[Vector3] = []
	points.append(from)
	# A sideways bow vector — pushes the polyline out toward -X (player's
	# left) so it visibly arcs around the orb/creature mass.
	var bow := Vector3(-0.45, 0.20, 0)
	for i in range(1, segments):
		var t := float(i) / float(segments)
		var on_line: Vector3 = from.lerp(to, t)
		# Sin profile so the bow is largest at mid-path.
		var bow_amount := sin(t * PI)
		var jitter := Vector3(
			rng.randf_range(-0.06, 0.06),
			rng.randf_range(-0.08, 0.12),
			rng.randf_range(-0.05, 0.05))
		points.append(on_line + bow * bow_amount + jitter)
	points.append(to)

	for i in range(points.size() - 1):
		_spawn_arc_segment(root, points[i], points[i + 1], color, 0.022)

	# Two fork branches off the middle of the path — splayed to the side
	# where the bow already pushed the polyline.
	var fork_origin: Vector3 = points[segments / 2]
	var fork_a: Vector3 = fork_origin + Vector3(-0.35, 0.25, -0.05)
	var fork_b: Vector3 = fork_origin + Vector3(-0.30, -0.20, 0.15)
	_spawn_arc_segment(root, fork_origin, fork_a, color, 0.016)
	_spawn_arc_segment(root, fork_origin, fork_b, color, 0.016)


func _spawn_arc_segment(root: Node3D, from: Vector3, to: Vector3, color: Color, thickness: float) -> void:
	var dir := to - from
	var length := dir.length()
	if length < 0.001:
		return
	var seg := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = thickness
	cyl.bottom_radius = thickness
	cyl.height = length
	seg.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.95)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.6
	seg.material_override = mat
	var up_dir := dir.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	seg.transform.basis = Basis(rx, up_dir, rz)
	seg.position = from + dir * 0.5
	root.add_child(seg)
