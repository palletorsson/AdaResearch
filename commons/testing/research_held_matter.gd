@tool
extends SceneTree
# Held-matter: per-mode FORM of the catalyst orb in-hand.
#
# Proves the design hypothesis that the bracelet projects different
# substances per mode, and that the player feels the matter BEFORE
# activation — not just on contact.
#
# The orb stops being one noise sphere with varying palette. Each mode
# is its own held form. The bracelet, the cupping gesture, the palette
# tint, and the self-luminosity carry the family resemblance — NOT the
# geometry.
#
# Per-mode forms:
#   primitives    — single noise sphere (the baseline, kept for reference)
#   chromatic     — marbled sphere, multi-palette swirl
#   forces        — soft volumetric haze (gather = atmosphere)
#   transformation — small dense orb (shrink = condensed)
#   waveform      — sphere wrapped in helical bands (oscillate = visible time)
#   chaos         — central spark + lightning arms (arc = barely contained)
#   fractal       — cluster of jagged shards (split = latent multiplicity)
#   cellular      — 3x3x3 cube lattice (evolve = tiled substrate)
#   branching     — vertical seed-pod with tendrils (grow = seed-with-future)
#   swarm         — 7 small bodies, no centre (flock = plural)
#
# Output: user://catalyst_runs/held_matter/<mode_id>.png

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")
const ORB_NOISE_SHADER := preload("res://commons/hazards/becoming_catalyst/orb_noise.gdshader")

const MODE_IDS := [
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
		dir.make_dir_recursive("catalyst_runs/held_matter")

	for mode in MODE_IDS:
		await _capture(mode)
	print("[held_matter] complete — %d modes" % MODE_IDS.size())
	quit()


func _capture(mode_id: String) -> void:
	var root := Node3D.new()
	root.name = "HeldMatter_%s" % mode_id

	VRCaptureRig.build_environment(root)

	var orb_origin := Vector3(0, 1.30, -0.55)
	var aim_dir := Vector3(0, -0.55, -1).normalized()
	var mode_color := VRCaptureRig.color_for_mode(mode_id)
	var palette: Array = VRCaptureRig.palette_for_mode(mode_id)

	# Same cupping gesture across all modes — the hands don't know what
	# substance is between them; they cup what's there.
	var hand_spacing := 0.20
	var left_pos := Vector3(-hand_spacing, 1.30, -0.45)
	var right_pos := Vector3(+hand_spacing, 1.30, -0.45)
	var basis := VRCaptureRig.hand_basis(aim_dir, 1.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		basis, "Cup", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF, right_pos,
		basis, "Cup", false)

	# Bracelet — unchanged. The bracelet is the unifier across all modes.
	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	var forearm_dir := Vector3(0.3, -0.1, 0.9)
	VRCaptureRig.build_bracelet(root, wrist_pos, forearm_dir, mode_color)

	# THE FORM — dispatch to mode-specific builder.
	_build_form_for(mode_id, root, orb_origin, palette, mode_color)

	# Camera
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(0, 1.05, -0.85), 85.0)
	root.add_child(cam)

	# Add to tree
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	for _i in range(40):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[held_matter] FAIL %s" % mode_id)
		return
	img.save_png("user://catalyst_runs/held_matter/%s.png" % mode_id)
	print("[held_matter] saved %s" % mode_id)


func _build_form_for(
	mode_id: String, root: Node3D, center: Vector3,
	palette: Array, mode_color: Color
) -> void:
	match mode_id:
		"primitives":
			_build_primitives_form(root, center, palette, mode_color)
		"chromatic":
			_build_chromatic_form(root, center, palette, mode_color)
		"forces":
			_build_forces_form(root, center, palette, mode_color)
		"transformation":
			_build_transformation_form(root, center, palette, mode_color)
		"waveform":
			_build_waveform_form(root, center, palette, mode_color)
		"chaos":
			_build_chaos_form(root, center, palette, mode_color)
		"fractal":
			_build_fractal_form(root, center, palette, mode_color)
		"cellular":
			_build_cellular_form(root, center, palette, mode_color)
		"branching":
			_build_branching_form(root, center, palette, mode_color)
		"swarm":
			_build_swarm_form(root, center, palette, mode_color)


# Build the noise+palette ShaderMaterial — same shader as the
# production orb, mode-specific palette. Used by most forms.
func _orb_shader_mat(palette: Array, noise_scale := 5.0,
	noise_amount := 0.06, time_scale := 0.6,
	emission_energy := 1.2) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ORB_NOISE_SHADER
	mat.set_shader_parameter("palette_a", palette[0] as Color)
	mat.set_shader_parameter("palette_b", palette[1] as Color)
	mat.set_shader_parameter("palette_c", palette[2] as Color)
	mat.set_shader_parameter("noise_scale", noise_scale)
	mat.set_shader_parameter("noise_amount", noise_amount)
	mat.set_shader_parameter("time_scale", time_scale)
	mat.set_shader_parameter("emission_energy", emission_energy)
	mat.set_shader_parameter("halo_softness", 0.4)
	return mat


func _add_orb_point_light(root: Node3D, pos: Vector3, color: Color,
	energy := 0.4, range := 0.6) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	light.position = pos
	root.add_child(light)


# ─────────────────────────────────────────────────────────────────────
# Per-mode form builders
# ─────────────────────────────────────────────────────────────────────

# Primitives: the baseline. Single noise-displaced sphere — kept as the
# reference form against which the other 9 are read. This is what every
# mode used to look like before the held_matter pass.
func _build_primitives_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	sphere.radial_segments = 48
	sphere.rings = 24
	body.mesh = sphere
	body.material_override = _orb_shader_mat(palette)
	body.position = center
	root.add_child(body)
	_add_orb_point_light(root, center, mode_color)


# Chromatic: marbled sphere — multi-palette swirl. Multiple translucent
# layered spheres each emphasising a different palette stop, so colours
# bleed through one another (oil-on-water reading). The form is pigment
# in suspension.
func _build_chromatic_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	# Outer layer: full palette, high noise so colours bleed visibly.
	var outer := MeshInstance3D.new()
	var s_outer := SphereMesh.new()
	s_outer.radius = 0.115
	s_outer.height = 0.23
	s_outer.radial_segments = 48
	s_outer.rings = 24
	outer.mesh = s_outer
	# Aggressive noise + scale so the palette stops mix turbulently.
	var mat_outer := _orb_shader_mat(palette, 12.0, 0.045, 1.2, 1.0)
	outer.material_override = mat_outer
	outer.position = center
	root.add_child(outer)

	# Inner core: same shader, different noise phase — extra colour layer
	# bleeding through.
	var inner := MeshInstance3D.new()
	var s_inner := SphereMesh.new()
	s_inner.radius = 0.075
	s_inner.height = 0.15
	s_inner.radial_segments = 32
	s_inner.rings = 16
	inner.mesh = s_inner
	# Reverse palette ordering — different colour reading.
	var inner_palette: Array = [palette[2], palette[0], palette[1]]
	inner.material_override = _orb_shader_mat(inner_palette, 7.0, 0.08, 0.9, 1.4)
	inner.position = center + Vector3(0.01, 0.005, 0.0)
	root.add_child(inner)

	_add_orb_point_light(root, center, mode_color)


# Forces (gather): soft volumetric haze. No hard surface — multiple
# concentric translucent spheres of increasing radius and decreasing
# alpha give the "atmosphere held between hands" reading. The form is
# warm-amber gradient outward.
func _build_forces_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	# Inner core — soft but visible.
	var core := MeshInstance3D.new()
	var s_core := SphereMesh.new()
	s_core.radius = 0.060
	s_core.height = 0.12
	s_core.radial_segments = 32
	s_core.rings = 16
	core.mesh = s_core
	core.material_override = _orb_shader_mat(palette, 4.0, 0.03, 0.4, 1.6)
	core.position = center
	root.add_child(core)

	# Three concentric halo shells — each more transparent than the last.
	var shell_radii: Array[float] = [0.10, 0.14, 0.18]
	var shell_alphas: Array[float] = [0.32, 0.18, 0.10]
	for i in range(shell_radii.size()):
		var shell := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = shell_radii[i]
		s.height = shell_radii[i] * 2.0
		s.radial_segments = 32
		s.rings = 16
		shell.mesh = s
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(mode_color.r, mode_color.g, mode_color.b, shell_alphas[i])
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = mode_color
		mat.emission_energy_multiplier = 0.4 - 0.10 * i
		shell.material_override = mat
		shell.position = center
		root.add_child(shell)

	_add_orb_point_light(root, center, mode_color, 0.7, 0.9)


# Transformation (shrink): small dense orb. Half the diameter of the
# others, intensely bright, condensed. Its smallness IS the verb.
func _build_transformation_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.055  # roughly half the baseline
	sphere.height = 0.11
	sphere.radial_segments = 48
	sphere.rings = 24
	body.mesh = sphere
	# Higher emission for the "condensed-and-potent" reading.
	body.material_override = _orb_shader_mat(palette, 6.0, 0.05, 0.7, 2.4)
	body.position = center
	root.add_child(body)

	# Subtle compression aura — a slightly larger but very faint shell
	# that suggests the orb has compressed something into itself.
	var aura := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.085
	s.height = 0.17
	aura.mesh = s
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(mode_color.r, mode_color.g, mode_color.b, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = mode_color
	mat.emission_energy_multiplier = 0.25
	aura.material_override = mat
	aura.position = center
	root.add_child(aura)

	_add_orb_point_light(root, center, mode_color, 0.6, 0.7)


# Waveform (oscillate): central sphere wrapped in helical bands of
# light. The form is visible time — wave-stuff that won't rest. Bands
# are torus rings at varying tilts.
func _build_waveform_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	# Core sphere — slightly smaller than baseline so bands are visible.
	var core := MeshInstance3D.new()
	var s_core := SphereMesh.new()
	s_core.radius = 0.080
	s_core.height = 0.16
	s_core.radial_segments = 32
	s_core.rings = 16
	core.mesh = s_core
	core.material_override = _orb_shader_mat(palette, 8.0, 0.04, 1.6, 1.3)
	core.position = center
	root.add_child(core)

	# Helical bands — three torus rings at varying tilts, each at a
	# slightly different palette stop so they read as time-slices.
	var tilts: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(deg_to_rad(45), 0.0, deg_to_rad(20)),
		Vector3(deg_to_rad(90), deg_to_rad(30), 0.0),
	]
	var band_colors: Array[Color] = [palette[2] as Color, palette[1] as Color, palette[2] as Color]
	for i in range(tilts.size()):
		var band := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.105
		torus.outer_radius = 0.118
		band.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = band_colors[i]
		mat.emission_enabled = true
		mat.emission = band_colors[i]
		mat.emission_energy_multiplier = 1.4
		band.material_override = mat
		band.position = center
		band.rotation = tilts[i]
		root.add_child(band)

	_add_orb_point_light(root, center, mode_color)


# Chaos (arc): plasma ball with visible discharge arms. Small inner
# core + several lightning-arm cylinders reaching outward into the air
# around the cupped hands. Barely contained — the orb is leaking.
func _build_chaos_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	# Small bright core — most of the energy lives in the arcs.
	var core := MeshInstance3D.new()
	var s_core := SphereMesh.new()
	s_core.radius = 0.065
	s_core.height = 0.13
	s_core.radial_segments = 32
	s_core.rings = 16
	core.mesh = s_core
	core.material_override = _orb_shader_mat(palette, 10.0, 0.10, 2.5, 1.8)
	core.position = center
	root.add_child(core)

	# Discharge arms — 5 zig-zag cylinder paths radiating outward.
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xCA05
	var arm_dirs: Array[Vector3] = [
		Vector3( 0.15,  0.10, -0.02),
		Vector3(-0.14,  0.08,  0.05),
		Vector3( 0.05, -0.13,  0.07),
		Vector3(-0.08, -0.10, -0.06),
		Vector3( 0.13,  0.02,  0.10),
	]
	for d in arm_dirs:
		var segments := 3
		var prev: Vector3 = center
		for i in range(1, segments + 1):
			var t := float(i) / float(segments)
			var on_line: Vector3 = center + d * t
			var jitter := Vector3(
				rng.randf_range(-0.025, 0.025),
				rng.randf_range(-0.025, 0.025),
				rng.randf_range(-0.020, 0.020))
			var next: Vector3 = on_line + jitter
			_spawn_short_arc(root, prev, next, mode_color)
			prev = next

	_add_orb_point_light(root, center, mode_color, 0.6, 0.7)


func _spawn_short_arc(root: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var dir := to - from
	var length := dir.length()
	if length < 0.001:
		return
	var seg := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.010
	cyl.bottom_radius = 0.010
	cyl.height = length
	seg.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.95)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	seg.material_override = mat
	var up_dir := dir.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	seg.transform.basis = Basis(rx, up_dir, rz)
	seg.position = from + dir * 0.5
	root.add_child(seg)


# Fractal (split): cluster of jagged shards in tight orbit. Already
# split, recombining — latent multiplicity. Each shard is a faceted
# small icosphere or box, palette-tinted, with high noise so the
# facets read as crystalline.
func _build_fractal_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xF7AC
	var shard_count := 8
	# Tight cluster — shards in close orbit suggest pre-shatter.
	for i in range(shard_count):
		var shard := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		# Low subdivision = visible facets, crystalline reading.
		sphere.radius = rng.randf_range(0.038, 0.060)
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 5  # faceted
		sphere.rings = 3
		shard.mesh = sphere
		# Stronger noise for the crystalline / pre-shatter look.
		shard.material_override = _orb_shader_mat(
			palette, 9.0 + rng.randf_range(-2.0, 2.0), 0.09, 0.4, 1.3)
		var p := Vector3(
			rng.randf_range(-0.10, 0.10),
			rng.randf_range(-0.08, 0.08),
			rng.randf_range(-0.08, 0.08))
		shard.position = center + p
		shard.rotation = Vector3(
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU),
			rng.randf_range(0, TAU))
		root.add_child(shard)

	_add_orb_point_light(root, center, mode_color, 0.5, 0.6)


# Cellular (evolve): quantised lattice — small cubic cells aggregating
# into a roughly spherical mass. Each cell visibly distinct, palette-
# tinted, alive cells brighter. The form is tiled substrate.
func _build_cellular_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xCE11
	# 4x4x4 lattice of cells, with some marked "dead" (dim).
	var dim := 4
	var cell_size := 0.045
	var spacing := 0.046  # slight gap between cells
	var origin: Vector3 = center - Vector3(
		(dim - 1) * 0.5 * spacing,
		(dim - 1) * 0.5 * spacing,
		(dim - 1) * 0.5 * spacing)
	for x in range(dim):
		for y in range(dim):
			for z in range(dim):
				# Skip outer corners to round the lattice into a sphere-ish form.
				var d2 := Vector3(x - (dim - 1) * 0.5, y - (dim - 1) * 0.5, z - (dim - 1) * 0.5).length()
				if d2 > 2.0:
					continue
				var cell := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(cell_size, cell_size, cell_size)
				cell.mesh = box

				var alive := rng.randf() > 0.30
				var mat := StandardMaterial3D.new()
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				var col: Color = (palette[2] as Color) if alive else (palette[0] as Color)
				mat.albedo_color = col
				mat.emission_enabled = true
				mat.emission = col
				mat.emission_energy_multiplier = 1.4 if alive else 0.35
				cell.material_override = mat
				cell.position = origin + Vector3(
					x * spacing, y * spacing, z * spacing)
				root.add_child(cell)

	_add_orb_point_light(root, center, mode_color)


# Branching (grow): vertical almond seed-pod with internal grain.
# Slightly elongated along Y so the form is teardrop-ish. Plus two or
# three thin tendril-cylinders extending outward from the pod.
func _build_branching_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	# Seed pod — elongated sphere via scale.
	var pod := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.075
	sphere.height = 0.15
	sphere.radial_segments = 32
	sphere.rings = 16
	pod.mesh = sphere
	pod.material_override = _orb_shader_mat(palette, 6.0, 0.05, 0.5, 1.3)
	pod.position = center
	# Stretch vertically — teardrop reading.
	pod.scale = Vector3(0.85, 1.4, 0.85)
	root.add_child(pod)

	# Tendrils — three thin cylinders extending outward from the pod.
	var tendril_dirs: Array[Vector3] = [
		Vector3( 0.05,  0.13,  0.02),
		Vector3(-0.06,  0.11, -0.03),
		Vector3( 0.02, -0.10,  0.04),
	]
	for d in tendril_dirs:
		var tendril := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.004
		cyl.bottom_radius = 0.011
		cyl.height = d.length() * 1.4
		tendril.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = palette[2] as Color
		mat.emission_enabled = true
		mat.emission = palette[2] as Color
		mat.emission_energy_multiplier = 0.8
		tendril.material_override = mat
		# Orient along d.
		var up_dir := d.normalized()
		var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var rx := up_dir.cross(ref_v).normalized()
		var rz := rx.cross(up_dir).normalized()
		tendril.transform.basis = Basis(rx, up_dir, rz)
		tendril.position = center + d * 0.5
		root.add_child(tendril)

	_add_orb_point_light(root, center, mode_color)


# Swarm (flock): 7 small palette-tinted bodies clustered between the
# cupped hands. No central body. Slight position variance so the cluster
# reads as plural-but-cohesive, not as a sphere.
func _build_swarm_form(
	root: Node3D, center: Vector3, palette: Array, mode_color: Color
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xF10C5
	var positions: Array[Vector3] = [
		Vector3( 0.00,  0.02,  0.00),
		Vector3( 0.10,  0.06, -0.04),
		Vector3(-0.11,  0.05,  0.03),
		Vector3( 0.06, -0.05,  0.05),
		Vector3(-0.08, -0.06, -0.04),
		Vector3( 0.13, -0.02, -0.06),
		Vector3(-0.13,  0.01,  0.05),
	]
	var radii: Array[float] = [0.070, 0.058, 0.060, 0.052, 0.055, 0.050, 0.054]

	for i in range(positions.size()):
		var body := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radii[i]
		sphere.height = radii[i] * 2.0
		sphere.radial_segments = 32
		sphere.rings = 16
		body.mesh = sphere
		body.material_override = _orb_shader_mat(
			palette, 5.0 + rng.randf_range(-1.5, 1.5),
			0.06, 0.6 + rng.randf_range(-0.2, 0.4), 1.2)
		body.position = center + positions[i]
		root.add_child(body)

	_add_orb_point_light(root, center, mode_color)
