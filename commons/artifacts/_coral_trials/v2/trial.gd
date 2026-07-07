# trial.gd — Brain coral (Meandrina) trial v2. Route B: reaction-diffusion.
#
# A rounded boulder whose entire surface is covered in sinuous, space-filling
# MEANDERING ridges and grooves — the brain / gyrus / fingerprint pattern.
# The valleys between the ridges glow with green fluorescence (as real brain
# corals do). This is a genuine TOPOLOGY GRAMMAR, not a bump texture.
#
# ROUTE B (reaction-diffusion) — chosen after Route A (domain-warped noise) kept
# collapsing into radial rings (a smooth field on a dome has near-concentric
# iso-contours when viewed top-down). Gray-Scott RD has NO radial bias: it grows
# a true labyrinth of even-width channels — exactly brain-coral topology.
#
#   1. Simulate Gray-Scott RD ("mazes" region, F=0.029 K=0.057) once on a modest
#      grid (RD_GRID²) for RD_ITERS steps → a labyrinthine V-concentration field.
#      Substrate reused: commons/rd_grammar/rd_sim.gd (same as the RD gallery).
#   2. Build a fine icosphere (subdivided icosahedron — uniform triangle density,
#      no UV-sphere pole pinch, so ridge spacing reads evenly).
#   3. For each surface vertex, sample the RD field by a TOP-DOWN projection of
#      the vertex's horizontal (x,z) position. The labyrinth wraps the dome top
#      as winding ridges and flows down the flanks as channels — how a real
#      brain-coral boulder reads from above (the capture angle).
#   4. Sharpen the RD field into ridges (smoothstep about a threshold) and
#      DISPLACE every vertex outward along its normal by the ridge height, so the
#      meander is a real displaced ArrayMesh (SurfaceTool, normals regenerated
#      after displacement so lighting reads each ridge).
#   5. Colour crests = living tissue over pale calcite skeleton; a second inset
#      mesh paints the VALLEY floors in near-unshaded green fluorescence.
#
# Deterministic: a local seeded RandomNumberGenerator (seed 4242) seeds both the
# FastNoiseLite boulder-lump field and the RD simulation. No global randf/randi.

extends Node3D
class_name CoralTrialV2

const RDSimScript = preload("res://commons/rd_grammar/rd_sim.gd")

# ── Boulder ──────────────────────────────────────────────────────────────
const BOULDER_RADIUS: float = 1.0          # base sphere radius (m)
const ICO_SUBDIVISIONS: int = 6            # 6 → 20*4^6 = 81,920 tris (fine)
const BOULDER_LUMP_FREQ: float = 0.55      # large-scale boulder undulation
const BOULDER_LUMP_AMP: float = 0.12       # how lumpy the underlying boulder is
const BOULDER_SQUASH: float = 0.84         # vertical squash → resting dome, not ball

# ── Reaction-diffusion meander field (the hero) ──────────────────────────
const RD_GRID: int = 150                    # NxN Gray-Scott grid (modest, one-time)
const RD_ITERS: int = 5200                  # steps — enough for the maze to fill in
const RD_PRESET: String = "mazes"           # F=0.029 K=0.057 → labyrinth topology
const RD_PROJ_SCALE: float = 0.92           # maps boulder half-width → grid extent (zoom)
const RD_THRESHOLD: float = 0.32            # V above this = ridge crest line
const RIDGE_HEIGHT: float = 0.185           # outward displacement of a ridge crest (m)
const RIDGE_SHARPNESS: float = 0.18         # smoothstep half-width about the threshold
const GROOVE_DEPTH: float = 0.6             # valley floor sinks this fraction of ridge height

# ── Glow valley inset ────────────────────────────────────────────────────
const GLOW_INSET: float = 0.05             # how far above the valley floor the glow sits
const GLOW_VALLEY_GATE: float = 0.4        # faces with ridge value below this glow

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	_build_brain_coral()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════════════

func _build_brain_coral() -> void:
	# Simulate Gray-Scott RD once → the labyrinth field (the hero). Seeded from
	# the local RNG so the whole coral is deterministic.
	var rd_cfg: Dictionary = {
		"preset": RD_PRESET,
		"grid_size": RD_GRID,
		"iterations": RD_ITERS,
		"seed": _rng.randi() & 0x7fffffff,
	}
	var rd_field: PackedFloat32Array = RDSimScript.simulate(rd_cfg)
	var rd_n: int = RD_GRID

	# Boulder lump field — gentle large undulation so the base reads as a rock.
	var lump := FastNoiseLite.new()
	lump.seed = _rng.randi()
	lump.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	lump.frequency = BOULDER_LUMP_FREQ

	# Build the unit icosphere (uniform tessellation).
	var unit_verts: PackedVector3Array = PackedVector3Array()
	var faces: PackedInt32Array = PackedInt32Array()
	_build_icosphere(ICO_SUBDIVISIONS, unit_verts, faces)

	var vcount: int = unit_verts.size()

	# Per-vertex precompute: boulder surface point, ridge value, displaced point.
	var base_nrm: PackedVector3Array = PackedVector3Array()   # outward normal
	var ridged_pos: PackedVector3Array = PackedVector3Array() # crest-displaced
	var glow_pos: PackedVector3Array = PackedVector3Array()   # inset valley shell
	var ridge01: PackedFloat32Array = PackedFloat32Array()    # 0=valley .. 1=crest
	base_nrm.resize(vcount)
	ridged_pos.resize(vcount)
	glow_pos.resize(vcount)
	ridge01.resize(vcount)

	for i: int in vcount:
		var dir: Vector3 = unit_verts[i]   # already unit length

		# Boulder radius: base + lump, then vertical squash into a dome.
		var lump_v: float = lump.get_noise_3dv(dir * 2.0)
		var r: float = BOULDER_RADIUS + lump_v * BOULDER_LUMP_AMP
		var bp: Vector3 = dir * r
		bp.y *= BOULDER_SQUASH
		base_nrm[i] = dir   # close enough to the true normal for a near-sphere

		# Sample the RD labyrinth by TRIPLANAR projection. A single top-down map
		# pinches into smears near the silhouette (where dir.y dominates). Instead
		# we sample the maze on all three axis planes (XZ, XY, ZY) and blend by the
		# squared normal components, so every facing gets an undistorted maze — the
		# brain pattern wraps the whole boulder evenly, no flank drips.
		var rd_val: float = _sample_rd_triplanar(rd_field, rd_n, dir)

		# Sharpen RD value into a ridge crest about the threshold. ridge01: 0 in
		# the grooves, 1 on the ridge crest lines — the space-filling meander.
		var crest: float = smoothstep(
			RD_THRESHOLD - RIDGE_SHARPNESS, RD_THRESHOLD + RIDGE_SHARPNESS, rd_val)
		ridge01[i] = crest

		# Crest rises, groove floor sinks below the boulder for a real channel.
		var height: float = crest * RIDGE_HEIGHT - (1.0 - crest) * GROOVE_DEPTH * RIDGE_HEIGHT
		ridged_pos[i] = bp + dir * height

		# Glow shell lines the GROOVE FLOOR: it sits just above where the valley
		# bottom recedes, well below the crests, so from above it reads as the
		# network of glowing channels between the ridges.
		var valley_floor: float = -GROOVE_DEPTH * RIDGE_HEIGHT
		glow_pos[i] = bp + dir * (valley_floor + GLOW_INSET)

	# ── Surface 1: the ridged boulder ──────────────────────────────────────
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fcount: int = faces.size() / 3
	for f: int in fcount:
		var ia: int = faces[f * 3 + 0]
		var ib: int = faces[f * 3 + 1]
		var ic: int = faces[f * 3 + 2]
		_emit_vertex(st, ridged_pos[ia], ridge01[ia])
		_emit_vertex(st, ridged_pos[ib], ridge01[ib])
		_emit_vertex(st, ridged_pos[ic], ridge01[ic])
	st.generate_normals()      # AFTER displacement so lighting reads the ridges
	var ridge_mesh: ArrayMesh = st.commit()

	var ridge_mi := MeshInstance3D.new()
	ridge_mi.name = "BrainCoralRidges"
	ridge_mi.mesh = ridge_mesh
	ridge_mi.material_override = _make_ridge_material()
	add_child(ridge_mi)

	# ── Surface 2: the fluorescent valley floor (inset shell) ──────────────
	# Only the triangles whose vertices are deep in a valley are emitted, so the
	# glow shell is just the groove network, not a full second sphere.
	var gst := SurfaceTool.new()
	gst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glow_tris: int = 0
	for f: int in fcount:
		var ia: int = faces[f * 3 + 0]
		var ib: int = faces[f * 3 + 1]
		var ic: int = faces[f * 3 + 2]
		var avg: float = (ridge01[ia] + ridge01[ib] + ridge01[ic]) / 3.0
		if avg > GLOW_VALLEY_GATE:
			continue   # this face is on/near a crest — no glow here
		gst.add_vertex(glow_pos[ia])
		gst.add_vertex(glow_pos[ib])
		gst.add_vertex(glow_pos[ic])
		glow_tris += 1
	gst.generate_normals()
	var glow_mesh: ArrayMesh = gst.commit()

	if glow_tris > 0:
		var glow_mi := MeshInstance3D.new()
		glow_mi.name = "BrainCoralGlowValleys"
		glow_mi.mesh = glow_mesh
		glow_mi.material_override = _make_glow_material()
		add_child(glow_mi)

	# Rest the boulder on y≈0. Lowest ridged point → lift the whole node.
	var min_y: float = ridged_pos[0].y
	for i: int in vcount:
		min_y = minf(min_y, ridged_pos[i].y)
	position.y = -min_y

	print("CoralTrialV2: route B (Gray-Scott '%s' RD). icosphere subdiv=%d, "
		% [RD_PRESET, ICO_SUBDIVISIONS],
		"RD grid=%d^2 x %d iters, verts=%d, ridge tris=%d, glow tris=%d"
		% [RD_GRID, RD_ITERS, vcount, fcount, glow_tris])


# Emit one vertex carrying its ridge value in vertex-colour so the material can
# blend tissue (crest) ↔ skeleton (valley wall). UV.x also carries the value.
func _emit_vertex(st: SurfaceTool, p: Vector3, ridge: float) -> void:
	st.set_color(Color(ridge, ridge, ridge, 1.0))
	st.set_uv(Vector2(ridge, 0.5))
	st.add_vertex(p)


# Triplanar sample of the 2D RD maze onto a sphere direction. The maze is
# projected on the XZ, XY and ZY planes and blended by the squared normal
# components (the standard triplanar weight), so a near-undistorted labyrinth
# covers every facing of the boulder — no equatorial pinch. A small per-plane UV
# offset keeps the three projections from lining up into visible seams.
func _sample_rd_triplanar(field: PackedFloat32Array, n: int, dir: Vector3) -> float:
	var s: float = RD_PROJ_SCALE * 0.5
	# XZ plane (top/bottom faces)
	var u_xz: float = dir.x * s + 0.5
	var v_xz: float = dir.z * s + 0.5
	var c_xz: float = _sample_rd_bilinear(field, n, u_xz, v_xz)
	# XY plane (front/back faces) — offset so it doesn't echo the XZ map
	var u_xy: float = dir.x * s + 0.27
	var v_xy: float = dir.y * s + 0.61
	var c_xy: float = _sample_rd_bilinear(field, n, u_xy, v_xy)
	# ZY plane (left/right faces)
	var u_zy: float = dir.z * s + 0.73
	var v_zy: float = dir.y * s + 0.19
	var c_zy: float = _sample_rd_bilinear(field, n, u_zy, v_zy)
	# Triplanar weights: squared normal raised to a high power so the blend
	# zones are narrow — each face mostly shows ONE undistorted maze, with only
	# a thin transition, which keeps the interference at the seams minimal.
	var w := Vector3(dir.x * dir.x, dir.y * dir.y, dir.z * dir.z)
	w.x = pow(w.x, 4.0)
	w.y = pow(w.y, 4.0)
	w.z = pow(w.z, 4.0)
	var wsum: float = w.x + w.y + w.z + 0.0001
	# y weight drives the XZ map; x weight drives the ZY map; z weight the XY map.
	return (c_xz * w.y + c_xy * w.z + c_zy * w.x) / wsum


# Bilinear sample of the RD field at normalized (u, v), clamped to the grid.
# Bilinear (not nearest) keeps the ridge lines smooth across the dense mesh.
func _sample_rd_bilinear(field: PackedFloat32Array, n: int, u: float, v: float) -> float:
	var fx: float = clampf(u, 0.0, 1.0) * float(n - 1)
	var fy: float = clampf(v, 0.0, 1.0) * float(n - 1)
	var x0: int = int(floorf(fx))
	var y0: int = int(floorf(fy))
	var x1: int = mini(x0 + 1, n - 1)
	var y1: int = mini(y0 + 1, n - 1)
	var tx: float = fx - float(x0)
	var ty: float = fy - float(y0)
	var v00: float = field[y0 * n + x0]
	var v10: float = field[y0 * n + x1]
	var v01: float = field[y1 * n + x0]
	var v11: float = field[y1 * n + x1]
	var top: float = lerpf(v00, v10, tx)
	var bot: float = lerpf(v01, v11, tx)
	return lerpf(top, bot, ty)


# ═══════════════════════════════════════════════════════════════════════════
# ICOSPHERE — subdivided icosahedron, welded via a midpoint cache
# ═══════════════════════════════════════════════════════════════════════════

func _build_icosphere(subdiv: int, out_verts: PackedVector3Array,
		out_faces: PackedInt32Array) -> void:
	# 12 icosahedron vertices.
	var t: float = (1.0 + sqrt(5.0)) * 0.5
	var verts: Array[Vector3] = [
		Vector3(-1,  t,  0), Vector3( 1,  t,  0), Vector3(-1, -t,  0), Vector3( 1, -t,  0),
		Vector3( 0, -1,  t), Vector3( 0,  1,  t), Vector3( 0, -1, -t), Vector3( 0,  1, -t),
		Vector3( t,  0, -1), Vector3( t,  0,  1), Vector3(-t,  0, -1), Vector3(-t,  0,  1)]
	for i: int in verts.size():
		verts[i] = verts[i].normalized()

	# 20 icosahedron faces.
	var tris: Array[Vector3i] = [
		Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10),
		Vector3i(0, 10, 11), Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2),
		Vector3i(10, 7, 6), Vector3i(7, 1, 8), Vector3i(3, 9, 4), Vector3i(3, 4, 2),
		Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9), Vector3i(4, 9, 5),
		Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1)]

	# Subdivide: each triangle → 4, projecting new midpoints onto the unit sphere.
	# A midpoint cache keyed by the (lo,hi) vertex pair welds shared edges.
	var midpoint_cache: Dictionary = {}
	for _level: int in subdiv:
		var new_tris: Array[Vector3i] = []
		for tri: Vector3i in tris:
			var a: int = _ico_midpoint(tri.x, tri.y, verts, midpoint_cache)
			var b: int = _ico_midpoint(tri.y, tri.z, verts, midpoint_cache)
			var c: int = _ico_midpoint(tri.z, tri.x, verts, midpoint_cache)
			new_tris.append(Vector3i(tri.x, a, c))
			new_tris.append(Vector3i(tri.y, b, a))
			new_tris.append(Vector3i(tri.z, c, b))
			new_tris.append(Vector3i(a, b, c))
		tris = new_tris

	out_verts.resize(verts.size())
	for i: int in verts.size():
		out_verts[i] = verts[i]
	out_faces.resize(tris.size() * 3)
	for i: int in tris.size():
		out_faces[i * 3 + 0] = tris[i].x
		out_faces[i * 3 + 1] = tris[i].y
		out_faces[i * 3 + 2] = tris[i].z


# Return the index of the unit-sphere midpoint between two vertices, creating
# and caching it on first request so shared edges reuse one welded vertex.
func _ico_midpoint(i0: int, i1: int, verts: Array[Vector3],
		cache: Dictionary) -> int:
	var lo: int = mini(i0, i1)
	var hi: int = maxi(i0, i1)
	var key: int = lo * 1000003 + hi   # stable pair key
	if cache.has(key):
		return cache[key]
	var mid: Vector3 = ((verts[i0] + verts[i1]) * 0.5).normalized()
	var idx: int = verts.size()
	verts.append(mid)
	cache[key] = idx
	return idx


# ═══════════════════════════════════════════════════════════════════════════
# MATERIALS — coral palette (matched to brief)
# ═══════════════════════════════════════════════════════════════════════════

# Ridge surface: living TISSUE on the crests (warm coral, subsurface), pale
# calcite SKELETON in the valley walls. Vertex colour (the ridge phase) drives
# the blend; we bake the two-tone gradient into a small ramp texture.
func _make_ridge_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _build_ridge_ramp()
	# UV.x = phase → samples the ramp left (valley=skeleton) to right (crest=tissue).
	m.roughness = 0.62
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.25
	m.emission_enabled = true
	m.emission = Color(0.95, 0.45, 0.35)
	m.emission_energy_multiplier = 0.12
	return m


# Fluorescent groove floor: green, near-unshaded, strong emission. The signature.
func _make_glow_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.32, 0.14)
	m.roughness = 0.5
	m.metallic = 0.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.emission_enabled = true
	m.emission = Color(0.40, 1.00, 0.45)
	m.emission_energy_multiplier = 3.1
	return m


# A 1×64 horizontal ramp: left = pale calcite ivory skeleton (valley walls),
# right = warm coral tissue (crests). UV.x (the ridge phase) indexes it; the
# vertex colour multiplies on top to keep the crest/valley contrast strong.
func _build_ridge_ramp() -> ImageTexture:
	var skeleton := Color(0.90, 0.86, 0.78)   # pale calcite ivory
	var tissue := Color(0.95, 0.45, 0.35)     # warm living coral
	var w: int = 64
	var img := Image.create(w, 1, false, Image.FORMAT_RGBA8)
	for x: int in w:
		var u: float = float(x) / float(w - 1)
		# Bias so the tissue only takes the very tops; most wall is skeleton.
		var k: float = smoothstep(0.55, 0.95, u)
		img.set_pixel(x, 0, skeleton.lerp(tissue, k))
	return ImageTexture.create_from_image(img)
