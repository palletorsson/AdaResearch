# TriangleVisual.gd
# Procedural mesh builder for The Loving Triangle.
# Triangles are the atom of all 3D worlds.  Every mesh reduces to triangles.
# This entity makes that visible — a single triangle that folds, tiles,
# and fills space as the player's understanding deepens.
#
# Evolution tiers follow the folding journey:
#   flat -> folded -> colored -> breathing -> self-tiling -> space-filling
extends RefCounted

# ── Tier Thresholds ──────────────────────────────────────────────────────
# Each tier unlocks when ANY sequence in the array is completed.
const TIER_SEQUENCES = [
	[],                                              # Tier 0: default
	["primitives", "transformation"],                # Tier 1: folding
	["color", "forces"],                             # Tier 2: identity
	["wavefunctions", "randomness"],                 # Tier 3: oscillation
	["fractals", "cellularautomata", "lsystems"],    # Tier 4: tiling
	["swarmintelligence"],                           # Tier 5: expansion
]

# Colors matching the catalyst's mode palette
const MODE_COLORS := {
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

# ── Tetrahedron Geometry ─────────────────────────────────────────────────
# Regular tetrahedron with circumradius r = 0.2
const TETRA_R := 0.2
# Vertices of a regular tetrahedron centered at origin
static var TETRA_VERTS: Array[Vector3] = [
	Vector3(0.0, TETRA_R, 0.0),
	Vector3(TETRA_R * 0.9428, -TETRA_R / 3.0, 0.0),
	Vector3(-TETRA_R * 0.4714, -TETRA_R / 3.0, TETRA_R * 0.8165),
	Vector3(-TETRA_R * 0.4714, -TETRA_R / 3.0, -TETRA_R * 0.8165),
]
# Face indices (4 faces, CCW winding)
const TETRA_FACES = [
	[0, 1, 2],  # front
	[0, 2, 3],  # left
	[0, 3, 1],  # right
	[1, 3, 2],  # bottom
]


# ═════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═════════════════════════════════════════════════════════════════════════

static func get_tier_from_sequences(completed: Array[String]) -> int:
	var tier := 0
	for t in range(1, TIER_SEQUENCES.size()):
		for seq in TIER_SEQUENCES[t]:
			if seq in completed:
				tier = t
				break
	return tier


static func build(parent: Node3D, tier: int, completed_modes: Array[String]) -> void:
	# Clear previous visual
	for child in parent.get_children():
		if child.is_in_group("tri_visual"):
			child.queue_free()

	var root := Node3D.new()
	root.name = "VisualRoot"
	root.add_to_group("tri_visual")
	parent.add_child(root)

	match tier:
		0: _build_tier0_flat(root)
		1: _build_tier1_tetrahedron(root)
		2: _build_tier2_colored(root, completed_modes)
		3: _build_tier3_breathing(root, completed_modes)
		4: _build_tier4_sierpinski(root, completed_modes)
		_: _build_tier5_swarm(root, completed_modes)


# ═════════════════════════════════════════════════════════════════════════
# TIER BUILDERS
# ═════════════════════════════════════════════════════════════════════════

## Tier 0: flat 2D equilateral triangle.  The atom.  Ghostly.
static func _build_tier0_flat(root: Node3D) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "FlatTriangle"
	mesh_inst.mesh = _make_flat_triangle_mesh(0.25)
	mesh_inst.material_override = _make_ghost_material(0.2, 0.3)
	root.add_child(mesh_inst)


## Tier 1: folds up into 3D tetrahedron.  2D becomes 3D.
static func _build_tier1_tetrahedron(root: Node3D) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Tetrahedron"
	mesh_inst.mesh = _make_tetrahedron_mesh()
	mesh_inst.material_override = _make_ghost_material(0.5, 0.8)
	root.add_child(mesh_inst)


## Tier 2: tetrahedron with colored faces + warmth.
static func _build_tier2_colored(root: Node3D, completed_modes: Array[String]) -> void:
	# Build tetra with per-face colors
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "ColoredTetra"
	mesh_inst.mesh = _make_colored_tetrahedron_mesh(completed_modes)
	root.add_child(mesh_inst)

	# Warm point light
	var light := OmniLight3D.new()
	light.name = "WarmLight"
	light.light_color = Color(1.0, 0.9, 0.7)
	light.light_energy = 0.8
	light.omni_range = 2.0
	root.add_child(light)

	# Center particles
	var particles := _make_center_particles()
	root.add_child(particles)


## Tier 3: pulsing edges, breathing vertices.  Rhythmic fold/unfold.
static func _build_tier3_breathing(root: Node3D, completed_modes: Array[String]) -> void:
	_build_tier2_colored(root, completed_modes)

	# Edge glow cylinders
	for i in range(4):
		for j in range(i + 1, 4):
			var edge := _make_edge_glow(TETRA_VERTS[i], TETRA_VERTS[j])
			edge.name = "Edge_%d_%d" % [i, j]
			root.add_child(edge)


## Tier 4: Sierpinski subdivision on each face.  Self-similar tiling.
static func _build_tier4_sierpinski(root: Node3D, completed_modes: Array[String]) -> void:
	_build_tier3_breathing(root, completed_modes)

	# Add Sierpinski sub-tetrahedra on each face center
	for face in TETRA_FACES:
		var center := (TETRA_VERTS[face[0]] + TETRA_VERTS[face[1]] + TETRA_VERTS[face[2]]) / 3.0
		var normal := (TETRA_VERTS[face[1]] - TETRA_VERTS[face[0]]).cross(
			TETRA_VERTS[face[2]] - TETRA_VERTS[face[0]]
		).normalized()
		var sub := MeshInstance3D.new()
		sub.name = "SierpinskiSub"
		sub.mesh = _make_tetrahedron_mesh(0.4)  # 40% scale
		sub.position = center + normal * 0.06
		sub.scale = Vector3(0.4, 0.4, 0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.7, 1.0, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.7, 1.0)
		mat.emission_energy_multiplier = 1.5
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sub.material_override = mat
		root.add_child(sub)


## Tier 5: splits into orbiting sub-triangles.  Space-filling.
static func _build_tier5_swarm(root: Node3D, completed_modes: Array[String]) -> void:
	_build_tier4_sierpinski(root, completed_modes)

	# 3 orbiting satellite triangles
	for i in 3:
		var sat := MeshInstance3D.new()
		sat.name = "Satellite_%d" % i
		sat.mesh = _make_flat_triangle_mesh(0.08)
		var angle := TAU / 3.0 * i
		sat.position = Vector3(cos(angle) * 0.35, sin(angle * 0.7) * 0.1, sin(angle) * 0.35)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.4, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.9, 0.5)
		mat.emission_energy_multiplier = 2.0
		sat.material_override = mat
		root.add_child(sat)


# ═════════════════════════════════════════════════════════════════════════
# MESH BUILDERS
# ═════════════════════════════════════════════════════════════════════════

## Flat equilateral triangle (single face) in the XZ plane
static func _make_flat_triangle_mesh(size: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	var h := size * sqrt(3.0) / 2.0
	var v0 := Vector3(0.0, 0.0, -h * 2.0 / 3.0)
	var v1 := Vector3(-size / 2.0, 0.0, h / 3.0)
	var v2 := Vector3(size / 2.0, 0.0, h / 3.0)
	var n := Vector3.UP

	# Front face
	verts.append(v0); verts.append(v1); verts.append(v2)
	normals.append(n); normals.append(n); normals.append(n)
	colors.append(Color.WHITE); colors.append(Color.WHITE); colors.append(Color.WHITE)
	# Back face
	verts.append(v0); verts.append(v2); verts.append(v1)
	normals.append(-n); normals.append(-n); normals.append(-n)
	colors.append(Color.WHITE); colors.append(Color.WHITE); colors.append(Color.WHITE)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Tetrahedron (4 triangular faces) with flat shading
static func _make_tetrahedron_mesh(scale_factor: float = 1.0) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	for face in TETRA_FACES:
		var a: Vector3 = TETRA_VERTS[face[0]] * scale_factor
		var b: Vector3 = TETRA_VERTS[face[1]] * scale_factor
		var c: Vector3 = TETRA_VERTS[face[2]] * scale_factor
		var n := (b - a).cross(c - a).normalized()
		verts.append(a); verts.append(b); verts.append(c)
		normals.append(n); normals.append(n); normals.append(n)
		colors.append(Color.WHITE); colors.append(Color.WHITE); colors.append(Color.WHITE)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Tetrahedron with per-face colors from completed modes
static func _make_colored_tetrahedron_mesh(completed_modes: Array[String]) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	# Gather colors from completed modes
	var face_colors: Array[Color] = []
	for mode_id in completed_modes:
		if MODE_COLORS.has(mode_id):
			face_colors.append(MODE_COLORS[mode_id])
	# Fill remaining with warm white
	while face_colors.size() < 4:
		face_colors.append(Color(0.8, 0.8, 0.85, 0.85))

	for fi in range(TETRA_FACES.size()):
		var face: Array = TETRA_FACES[fi]
		var a: Vector3 = TETRA_VERTS[face[0]]
		var b: Vector3 = TETRA_VERTS[face[1]]
		var c: Vector3 = TETRA_VERTS[face[2]]
		var n := (b - a).cross(c - a).normalized()
		var col: Color = face_colors[fi % face_colors.size()]
		verts.append(a); verts.append(b); verts.append(c)
		normals.append(n); normals.append(n); normals.append(n)
		colors.append(col); colors.append(col); colors.append(col)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Material that uses vertex colors
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.7, 0.8)
	mat.emission_energy_multiplier = 1.2
	mat.metallic = 0.15
	mat.roughness = 0.3

	# Assign material to the surface
	mesh.surface_set_material(0, mat)
	return mesh


# ═════════════════════════════════════════════════════════════════════════
# MATERIAL / EFFECT HELPERS
# ═════════════════════════════════════════════════════════════════════════

static func _make_ghost_material(alpha: float, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.95, alpha)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.8, 0.95)
	mat.emission_energy_multiplier = emission_energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.3
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


static func _make_center_particles() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "CenterGlow"
	particles.amount = 12
	particles.lifetime = 1.2
	particles.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.08
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 0.01
	pmat.initial_velocity_max = 0.05
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.008
	pmat.scale_max = 0.02

	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.9, 0.7, 0.6))
	grad.add_point(1.0, Color(1.0, 0.8, 0.5, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	return particles


static func _make_edge_glow(a: Vector3, b: Vector3) -> MeshInstance3D:
	var mid := (a + b) / 2.0
	var length := a.distance_to(b)
	var dir := (b - a).normalized()

	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.005
	cyl.bottom_radius = 0.005
	cyl.height = length

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = cyl
	mesh_inst.position = mid

	# Orient cylinder along edge direction
	if abs(dir.dot(Vector3.UP)) < 0.99:
		mesh_inst.look_at(mid + dir, Vector3.UP)
		mesh_inst.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	else:
		mesh_inst.rotation.z = 0.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.8, 1.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.7, 1.0)
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat

	return mesh_inst
