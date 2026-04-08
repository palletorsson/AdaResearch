# CatalystVisual.gd
# Builds themed procedural visuals for The Becoming Catalyst.
# Each sequence gives the crystal a unique identity — you can tell
# what a catalyst does by how it looks.
#
# Themes (determined by highest unlocked mode):
#   primitives     — Clean octahedron. Pure geometry. Pale lavender.
#   transformation — Twisted double-pyramid. Morphing purple echo.
#   chromatic      — Triangular prism. Rainbow spectrum particles.
#   forces         — Dense golden sphere. Orbiting debris ring.
#   waveform       — Teal double-torus. Flowing wave particles.
#   chaos          — Jagged fractured shards. Electric sparks.
#   cellular       — Dark cube with glowing grid cells. White.
#   fractal        — Central crystal + recursive sub-crystals. Blue.
#   branching      — Y-shaped organic tree form. Living green.
#   swarm          — Cluster of orbiting boid spheres. Warm gold.
class_name CatalystVisual
extends RefCounted

# Mode colors for visual identity (used by bracelet gems, labels, etc.)
const MODE_COLORS := {
	"voxel_editor":   Color(0.3, 0.7, 1.0),
	"primitives":     Color(0.85, 0.85, 0.9),
	"transformation": Color(0.7, 0.3, 0.85),
	"chromatic":      Color(1.0, 0.4, 0.4),
	"forces":         Color(1.0, 0.75, 0.3),
	"waveform":       Color(0.3, 0.85, 0.85),
	"chaos":          Color(0.9, 0.2, 0.5),
	"fractal":        Color(0.4, 0.7, 1.0),
	"cellular":       Color(0.95, 0.95, 0.95),
	"branching":      Color(0.4, 0.75, 0.3),
	"swarm":          Color(1.0, 0.85, 0.4),
}

# Mode order values for determining the highest unlocked mode
const MODE_ORDER := {
	"voxel_editor": 0,
	"primitives": 1,
	"transformation": 2,
	"chromatic": 3,
	"forces": 4,
	"waveform": 6,
	"chaos": 7,
	"cellular": 9,
	"fractal": 10,
	"branching": 11,
	"swarm": 14,
}


static func build_crystal(parent: Node3D, unlocked_modes: Array[String]) -> void:
	# Clear previous visual
	for child in parent.get_children():
		if child.is_in_group("catalyst_visual"):
			child.queue_free()

	var theme := _get_theme(unlocked_modes)

	match theme:
		"primitives":
			_build_primitives_crystal(parent)
		"transformation":
			_build_transformation_crystal(parent)
		"chromatic":
			_build_chromatic_crystal(parent)
		"forces":
			_build_forces_crystal(parent)
		"waveform":
			_build_waveform_crystal(parent)
		"chaos":
			_build_chaos_crystal(parent)
		"cellular":
			_build_cellular_crystal(parent)
		"fractal":
			_build_fractal_crystal(parent)
		"branching":
			_build_branching_crystal(parent)
		"swarm":
			_build_swarm_crystal(parent)
		_:
			_build_primitives_crystal(parent)


static func get_mode_color(mode_id: String) -> Color:
	return MODE_COLORS.get(mode_id, Color.WHITE)


# ═════════════════════════════════════════════════════════════════════════
# THEME DETECTION
# ═════════════════════════════════════════════════════════════════════════

static func _get_theme(unlocked_modes: Array[String]) -> String:
	var highest_mode := "primitives"
	var highest_order := 0
	for mode_id in unlocked_modes:
		var order: int = MODE_ORDER.get(mode_id, 0)
		if order > highest_order:
			highest_order = order
			highest_mode = mode_id
	return highest_mode


# ═════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════

static func _make_mat(
	albedo: Color,
	emission: Color,
	energy: float,
	metallic: float = 0.3,
	roughness: float = 0.25,
	transparent: bool = false,
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	mat.metallic = metallic
	mat.roughness = roughness
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func _add(parent: Node3D, node: Node3D) -> void:
	node.add_to_group("catalyst_visual")
	parent.add_child(node)


# ═════════════════════════════════════════════════════════════════════════
# 1. PRIMITIVES — Clean faceted octahedron. Pure geometric form.
#    The starting crystal. Simple, elegant, untouched.
# ═════════════════════════════════════════════════════════════════════════

static func _build_primitives_crystal(parent: Node3D) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.radial_segments = 6
	sphere.rings = 4
	mesh_inst.mesh = sphere
	mesh_inst.material_override = _make_mat(
		Color(0.75, 0.75, 0.85, 0.9),
		Color(0.85, 0.85, 0.9),
		1.5, 0.3, 0.25, true
	)
	_add(parent, mesh_inst)


# ═════════════════════════════════════════════════════════════════════════
# 2. TRANSFORMATION — Twisted double-pyramid with ghost echo.
#    Two crystals phase-shifted, as if caught mid-morph.
# ═════════════════════════════════════════════════════════════════════════

static func _build_transformation_crystal(parent: Node3D) -> void:
	# Elongated main crystal
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.24
	sphere.radial_segments = 5
	sphere.rings = 3
	mesh_inst.mesh = sphere
	mesh_inst.rotation = Vector3(0.2, 0.0, 0.35)
	mesh_inst.material_override = _make_mat(
		Color(0.6, 0.2, 0.75, 0.85),
		Color(0.7, 0.3, 0.85),
		1.8, 0.3, 0.2, true
	)
	_add(parent, mesh_inst)

	# Ghost echo — a second crystal at a counter-twist, semi-transparent
	var echo := MeshInstance3D.new()
	echo.name = "TransformEcho"
	var echo_sphere := SphereMesh.new()
	echo_sphere.radius = 0.065
	echo_sphere.height = 0.2
	echo_sphere.radial_segments = 5
	echo_sphere.rings = 3
	echo.mesh = echo_sphere
	echo.rotation = Vector3(-0.3, 0.5, -0.2)
	echo.material_override = _make_mat(
		Color(0.5, 0.15, 0.65, 0.35),
		Color(0.7, 0.3, 0.85),
		1.0, 0.2, 0.3, true
	)
	_add(parent, echo)


# ═════════════════════════════════════════════════════════════════════════
# 3. CHROMATIC — Triangular prism with rainbow spectrum aura.
#    Light bends through it — iridescent refraction.
# ═════════════════════════════════════════════════════════════════════════

static func _build_chromatic_crystal(parent: Node3D) -> void:
	# Triangular prism (CylinderMesh with 3 sides)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var prism := CylinderMesh.new()
	prism.top_radius = 0.07
	prism.bottom_radius = 0.07
	prism.height = 0.18
	prism.radial_segments = 3
	prism.rings = 1
	mesh_inst.mesh = prism
	mesh_inst.rotation = Vector3(0.0, 0.0, 0.15)
	var prism_mat := _make_mat(
		Color(0.9, 0.9, 0.95, 0.7),
		Color(1.0, 0.8, 0.8),
		1.5, 0.1, 0.1, true
	)
	prism_mat.rim_enabled = true
	prism_mat.rim = 0.8
	prism_mat.rim_tint = 0.5
	mesh_inst.material_override = prism_mat
	_add(parent, mesh_inst)

	# Rainbow spectrum particles
	var particles := GPUParticles3D.new()
	particles.name = "SpectrumAura"
	particles.amount = 20
	particles.lifetime = 1.8
	particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.08
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.02
	pmat.initial_velocity_max = 0.06
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.008
	pmat.scale_max = 0.02
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 0.2, 0.2, 0.9))
	grad.add_point(0.2, Color(1, 0.6, 0.1, 0.8))
	grad.add_point(0.4, Color(0.2, 1.0, 0.2, 0.7))
	grad.add_point(0.6, Color(0.2, 0.6, 1.0, 0.6))
	grad.add_point(0.8, Color(0.6, 0.2, 1.0, 0.4))
	grad.add_point(1.0, Color(1, 0.2, 0.8, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	_add(parent, particles)


# ═════════════════════════════════════════════════════════════════════════
# 4. FORCES — Dense golden sphere with orbiting debris ring.
#    Mass and gravity. Everything orbits this one.
# ═════════════════════════════════════════════════════════════════════════

static func _build_forces_crystal(parent: Node3D) -> void:
	# Heavy golden sphere — smooth, weighty
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_inst.mesh = sphere
	mesh_inst.material_override = _make_mat(
		Color(0.85, 0.6, 0.15),
		Color(1.0, 0.75, 0.3),
		1.8, 0.7, 0.2
	)
	_add(parent, mesh_inst)

	# Orbiting debris ring
	var particles := GPUParticles3D.new()
	particles.name = "DebrisRing"
	particles.amount = 20
	particles.lifetime = 2.5
	particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = 0.14
	pmat.emission_ring_inner_radius = 0.12
	pmat.emission_ring_height = 0.01
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.direction = Vector3(1, 0, 0)
	pmat.spread = 10.0
	pmat.initial_velocity_min = 0.05
	pmat.initial_velocity_max = 0.1
	pmat.gravity = Vector3.ZERO
	pmat.orbit_velocity_min = 0.6
	pmat.orbit_velocity_max = 0.8
	pmat.scale_min = 0.006
	pmat.scale_max = 0.015
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.8, 0.3, 0.9))
	grad.add_point(0.7, Color(0.8, 0.5, 0.1, 0.6))
	grad.add_point(1.0, Color(0.5, 0.3, 0.05, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	_add(parent, particles)


# ═════════════════════════════════════════════════════════════════════════
# 5. WAVEFORM — Teal double-torus. Wave-particle duality.
#    Two rings interlocked, flowing particles around them.
# ═════════════════════════════════════════════════════════════════════════

static func _build_waveform_crystal(parent: Node3D) -> void:
	# Primary torus
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.03
	torus.outer_radius = 0.09
	torus.rings = 16
	torus.ring_segments = 12
	mesh_inst.mesh = torus
	mesh_inst.rotation = Vector3(0.5, 0.0, 0.3)
	mesh_inst.material_override = _make_mat(
		Color(0.2, 0.7, 0.75, 0.85),
		Color(0.3, 0.85, 0.85),
		1.6, 0.2, 0.3, true
	)
	_add(parent, mesh_inst)

	# Second torus — counter-tilted
	var torus2 := MeshInstance3D.new()
	torus2.name = "WaveEcho"
	var t2 := TorusMesh.new()
	t2.inner_radius = 0.02
	t2.outer_radius = 0.08
	t2.rings = 16
	t2.ring_segments = 12
	torus2.mesh = t2
	torus2.rotation = Vector3(-0.4, 0.0, -0.25)
	torus2.material_override = _make_mat(
		Color(0.15, 0.55, 0.6, 0.5),
		Color(0.2, 0.7, 0.75),
		1.0, 0.2, 0.3, true
	)
	_add(parent, torus2)

	# Flowing wave particles
	var particles := GPUParticles3D.new()
	particles.name = "WaveTrail"
	particles.amount = 16
	particles.lifetime = 1.5
	particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = 0.09
	pmat.emission_ring_inner_radius = 0.06
	pmat.emission_ring_height = 0.02
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.gravity = Vector3.ZERO
	pmat.orbit_velocity_min = 0.4
	pmat.orbit_velocity_max = 0.6
	pmat.scale_min = 0.005
	pmat.scale_max = 0.012
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.3, 0.9, 0.9, 0.8))
	grad.add_point(0.5, Color(0.2, 0.7, 0.8, 0.5))
	grad.add_point(1.0, Color(0.1, 0.5, 0.6, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	_add(parent, particles)


# ═════════════════════════════════════════════════════════════════════════
# 6. CHAOS — Jagged fractured shards with electric sparks.
#    Broken apart, crackling with volatile energy.
# ═════════════════════════════════════════════════════════════════════════

static func _build_chaos_crystal(parent: Node3D) -> void:
	# Main jagged shard — very low-poly, spiky
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.19
	sphere.radial_segments = 5
	sphere.rings = 3
	mesh_inst.mesh = sphere
	mesh_inst.rotation = Vector3(0.4, 0.7, 0.2)
	mesh_inst.material_override = _make_mat(
		Color(0.75, 0.1, 0.4),
		Color(0.9, 0.2, 0.5),
		2.2, 0.15, 0.4
	)
	_add(parent, mesh_inst)

	# Second shard at wild angle — the crystal is fractured
	var shard := MeshInstance3D.new()
	shard.name = "ChaosShard"
	var s2 := SphereMesh.new()
	s2.radius = 0.05
	s2.height = 0.14
	s2.radial_segments = 4
	s2.rings = 2
	shard.mesh = s2
	shard.position = Vector3(0.04, 0.06, -0.02)
	shard.rotation = Vector3(-0.6, 0.3, 0.8)
	shard.material_override = _make_mat(
		Color(0.6, 0.05, 0.3),
		Color(0.95, 0.3, 0.7),
		2.5, 0.1, 0.5
	)
	_add(parent, shard)

	# Electric spark particles — fast, short-lived, volatile
	var particles := GPUParticles3D.new()
	particles.name = "Sparks"
	particles.amount = 14
	particles.lifetime = 0.3
	particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.06
	pmat.gravity = Vector3.ZERO
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 3.0
	pmat.direction = Vector3.ZERO
	pmat.spread = 180.0
	pmat.scale_min = 0.002
	pmat.scale_max = 0.006
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.9, 1.0, 1.0))
	grad.add_point(0.3, Color(0.9, 0.2, 0.5, 0.8))
	grad.add_point(1.0, Color(0.5, 0.0, 0.3, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	_add(parent, particles)


# ═════════════════════════════════════════════════════════════════════════
# 7. CELLULAR — Dark cube with glowing grid cells on the face.
#    The automaton as object — alive and dead states visible.
# ═════════════════════════════════════════════════════════════════════════

static func _build_cellular_crystal(parent: Node3D) -> void:
	# Dark metallic cube
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.12)
	mesh_inst.mesh = box
	mesh_inst.rotation = Vector3(0.3, 0.25, 0.15)
	mesh_inst.material_override = _make_mat(
		Color(0.12, 0.12, 0.18),
		Color(0.3, 0.3, 0.4),
		0.6, 0.8, 0.15
	)
	_add(parent, mesh_inst)

	# Glowing cubelets on the front face — 3×3 CA grid
	var cell_container := Node3D.new()
	cell_container.name = "GridCells"
	cell_container.rotation = Vector3(0.3, 0.25, 0.15)  # Match cube rotation
	var cell_size := 0.025
	var spacing := 0.042

	for row in 3:
		for col in 3:
			# Alive pattern: glider-ish
			var alive := (row + col) % 2 == 0 or (row == 1 and col == 1)
			var cell := MeshInstance3D.new()
			var cbox := BoxMesh.new()
			cbox.size = Vector3.ONE * cell_size
			cell.mesh = cbox
			cell.position = Vector3(
				(col - 1) * spacing,
				(row - 1) * spacing,
				0.065  # Just above front face
			)
			if alive:
				cell.material_override = _make_mat(
					Color(0.9, 0.9, 0.95),
					Color(0.95, 0.95, 0.95),
					2.5, 0.3, 0.4
				)
			else:
				cell.material_override = _make_mat(
					Color(0.06, 0.06, 0.1),
					Color(0.1, 0.1, 0.15),
					0.2, 0.5, 0.5
				)
			cell_container.add_child(cell)

	_add(parent, cell_container)


# ═════════════════════════════════════════════════════════════════════════
# 8. FRACTAL — Central crystal with recursive sub-crystals.
#    Self-similar at every scale. The whole in every part.
# ═════════════════════════════════════════════════════════════════════════

static func _build_fractal_crystal(parent: Node3D) -> void:
	# Main crystal
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CrystalCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.18
	sphere.radial_segments = 6
	sphere.rings = 4
	mesh_inst.mesh = sphere
	mesh_inst.material_override = _make_mat(
		Color(0.25, 0.5, 0.85, 0.85),
		Color(0.4, 0.7, 1.0),
		1.8, 0.3, 0.2, true
	)
	_add(parent, mesh_inst)

	# Mid-size sub-crystals — smaller copies at offsets
	var sub_container := Node3D.new()
	sub_container.name = "SubCrystals"
	var offsets := [
		Vector3(0.1, 0.05, 0.0),
		Vector3(-0.08, -0.04, 0.06),
		Vector3(0.03, 0.09, -0.05),
		Vector3(-0.06, 0.02, -0.08),
		Vector3(0.02, -0.08, 0.05),
	]
	for offset in offsets:
		var sub := MeshInstance3D.new()
		var sub_sphere := SphereMesh.new()
		sub_sphere.radius = 0.025
		sub_sphere.height = 0.06
		sub_sphere.radial_segments = 6
		sub_sphere.rings = 4
		sub.mesh = sub_sphere
		sub.position = offset
		sub.rotation = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		)
		sub.material_override = _make_mat(
			Color(0.3, 0.55, 0.9, 0.7),
			Color(0.5, 0.75, 1.0),
			2.0, 0.3, 0.2, true
		)
		sub_container.add_child(sub)
	_add(parent, sub_container)

	# Micro-crystals — self-similarity at a third scale
	var micro_container := Node3D.new()
	micro_container.name = "MicroCrystals"
	for i in 8:
		var micro := MeshInstance3D.new()
		var ms := SphereMesh.new()
		ms.radius = 0.01
		ms.height = 0.025
		ms.radial_segments = 4
		ms.rings = 2
		micro.mesh = ms
		var angle := TAU / 8.0 * i
		micro.position = Vector3(
			cos(angle) * 0.14,
			sin(angle * 0.7) * 0.04,
			sin(angle) * 0.14
		)
		micro.material_override = _make_mat(
			Color(0.4, 0.6, 1.0, 0.5),
			Color(0.5, 0.7, 1.0),
			1.5, 0.3, 0.25, true
		)
		micro_container.add_child(micro)
	_add(parent, micro_container)


# ═════════════════════════════════════════════════════════════════════════
# 9. BRANCHING — Y-shaped organic tree form. Living green.
#    L-system as object — trunk, branches, leaf glow.
# ═════════════════════════════════════════════════════════════════════════

static func _build_branching_crystal(parent: Node3D) -> void:
	# Central trunk
	var trunk := MeshInstance3D.new()
	trunk.name = "CrystalCore"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.04
	cyl.height = 0.16
	cyl.radial_segments = 5
	trunk.mesh = cyl
	trunk.material_override = _make_mat(
		Color(0.25, 0.55, 0.2),
		Color(0.4, 0.75, 0.3),
		1.5, 0.2, 0.4
	)
	_add(parent, trunk)

	# Branches forking out — Y shape with sub-branches
	var branch_data := [
		# Main Y
		{"pos": Vector3(0.0, 0.06, 0.0), "rot": Vector3(0.0, 0.0, 0.5), "len": 0.1, "r": 0.018},
		{"pos": Vector3(0.0, 0.06, 0.0), "rot": Vector3(0.0, 0.0, -0.5), "len": 0.1, "r": 0.018},
		# Sub-branches
		{"pos": Vector3(0.05, 0.1, 0.0), "rot": Vector3(0.0, 0.0, 0.7), "len": 0.06, "r": 0.012},
		{"pos": Vector3(-0.05, 0.1, 0.0), "rot": Vector3(0.0, 0.0, -0.7), "len": 0.06, "r": 0.012},
		{"pos": Vector3(0.03, 0.1, 0.03), "rot": Vector3(0.4, 0.0, 0.5), "len": 0.05, "r": 0.008},
	]

	for bd in branch_data:
		var branch := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = bd["r"] * 0.4
		bc.bottom_radius = bd["r"]
		bc.height = bd["len"]
		bc.radial_segments = 4
		branch.mesh = bc
		branch.position = bd["pos"]
		branch.rotation = bd["rot"]
		branch.material_override = _make_mat(
			Color(0.3, 0.6, 0.25),
			Color(0.45, 0.8, 0.35),
			1.3, 0.15, 0.45
		)
		_add(parent, branch)

	# Leaf-glow particles at the tips
	var particles := GPUParticles3D.new()
	particles.name = "LeafGlow"
	particles.amount = 12
	particles.lifetime = 2.0
	particles.emitting = true
	particles.position = Vector3(0, 0.08, 0)
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.08
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 60.0
	pmat.initial_velocity_min = 0.01
	pmat.initial_velocity_max = 0.04
	pmat.gravity = Vector3(0, -0.02, 0)
	pmat.scale_min = 0.005
	pmat.scale_max = 0.012
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.5, 0.9, 0.4, 0.8))
	grad.add_point(0.5, Color(0.3, 0.7, 0.2, 0.5))
	grad.add_point(1.0, Color(0.2, 0.5, 0.1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	_add(parent, particles)


# ═════════════════════════════════════════════════════════════════════════
# 10. SWARM — Cluster of boid spheres. Warm gold.
#     No single crystal — collective identity. The swarm IS the object.
# ═════════════════════════════════════════════════════════════════════════

static func _build_swarm_crystal(parent: Node3D) -> void:
	# Cloud of boid-like spheres in a loose cluster
	var container := Node3D.new()
	container.name = "CrystalCore"

	for i in 8:
		var boid := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.025
		sphere.height = 0.05
		sphere.radial_segments = 8
		sphere.rings = 4
		boid.mesh = sphere
		# Distribute in a loose cluster
		var angle := TAU / 8.0 * i
		var y_offset := sin(i * 1.3) * 0.04
		boid.position = Vector3(cos(angle) * 0.06, y_offset, sin(angle) * 0.06)
		boid.material_override = _make_mat(
			Color(0.9, 0.75, 0.3),
			Color(1.0, 0.85, 0.4),
			2.0, 0.4, 0.3
		)
		container.add_child(boid)
	_add(parent, container)

	# Orbiting trail particles — like a flock leaving warm traces
	var particles := GPUParticles3D.new()
	particles.name = "SwarmTrail"
	particles.amount = 24
	particles.lifetime = 1.5
	particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.07
	pmat.gravity = Vector3.ZERO
	pmat.orbit_velocity_min = 0.3
	pmat.orbit_velocity_max = 0.6
	pmat.scale_min = 0.003
	pmat.scale_max = 0.008
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.9, 0.5, 0.7))
	grad.add_point(0.5, Color(0.9, 0.65, 0.2, 0.4))
	grad.add_point(1.0, Color(0.7, 0.4, 0.1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	_add(parent, particles)
