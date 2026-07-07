# trial.gd — CodexOpticsTrialV2 — TWO-SOURCE WAVE INTERFERENCE (ripple tank)
#
# A frozen ripple-tank plate, in the spirit of Serafini's Codex Seraphinianus
# water plates: two point sources drop into a still pool and their circular
# waves SUPERPOSE. Where two crests coincide the water heaps up (CONSTRUCTIVE);
# where a crest lands on a trough the surface goes dead flat (DESTRUCTIVE — a
# node). The locus of nodes is a family of HYPERBOLAE with the two sources as
# foci, fanning out between them; the locus of crests is the complementary
# family. The whole plate is the classic two-slit / two-source fringe field,
# captured in standing relief.
#
# ── THE GENUINE ALGORITHM (the load-bearing physics) ────────────────────────
# Each source emits a circular travelling wave. The instantaneous surface
# height at a planar point x is the linear SUPERPOSITION (sum) of both:
#
#     r1 = |x - s1|              distance to source 1
#     r2 = |x - s2|             distance to source 2
#     A(x) = A0·sin(k·r1 - phi) + A0·sin(k·r2 - phi)
#
# with wavenumber  k = TAU / lambda  (lambda = wavelength). The phase term
# (k·r - phi) is the wave's phase at radius r for a single frozen instant; the
# sum of the two sine fields is exactly what a real ripple tank shows. The
# amplitude A(x) ranges over [-2·A0, +2·A0]: it reaches +2·A0 only where the two
# waves are perfectly IN phase (constructive antinode) and 0 along the nodal
# hyperbolae where they are exactly OUT of phase. We displace each grid vertex's
# height by A(x) and COLOUR it by the normalized amplitude (deep blue trough →
# light crest), so both the relief AND the colour carry the fringe pattern.
#
# Source spacing is deliberately a few wavelengths (d ≈ 4.5·lambda) so that
# several nodal lines fan out across the plate and the fringe field reads
# unmistakably as two-source interference rather than a single ripple.
#
# ── NON-PRIMITIVE ───────────────────────────────────────────────────────────
# The water surface is a 140×140 grid built by hand with SurfaceTool: every
# vertex is displaced by A(x), given a per-vertex colour from the ramp, and an
# ANALYTIC normal computed from the gradient of A (partial derivatives of the
# two-source field), so the relief catches light correctly. The two sources are
# MorphoPrimitive.sphere; the tank rim is MorphoPrimitive.revolution; the
# backdrop slab is MorphoPrimitive.box. Everything is oriented via Basis (no
# out-of-tree look_at) and is deterministic from a local seeded RNG.

extends Node3D

class_name CodexOpticsTrialV2

# ── Tunables ─────────────────────────────────────────────────────────────
const SEED: int = 4242

# Surface grid.
const GRID_RES: int = 140                  # vertices per axis (140×140)
const PLATE_SPAN: float = 2.80             # planar width/depth of the pool (m)

# Two-source interference field.
const WAVELENGTH: float = 0.224            # lambda — sets fringe spacing
const SOURCE_GAP: float = 1.02             # centre-to-centre source spacing (m)
const AMPLITUDE: float = 0.085             # A0 — per-source crest height (m)
const PHASE: float = 0.0                   # phi — common emission phase
# Radial envelope: a real ripple tank's waves fade with distance. A gentle
# falloff keeps the centre lively while letting the rim settle so the plate
# reads as a contained pool, not an infinite field.
const ENVELOPE_FALLOFF: float = 0.62       # 0 = no fade, 1 = strong fade

const TILT_DEGREES: float = 20.0           # tip the plate toward the camera

# Colour ramp (by normalized amplitude -1..+1).
const COL_TROUGH := Color(0.08, 0.16, 0.38)   # deep blue (destructive dip)
const COL_MID := Color(0.20, 0.42, 0.66)      # mid water
const COL_CREST := Color(0.65, 0.80, 0.92)    # light crest (constructive heap)
const COL_ACCENT := Color(0.98, 0.85, 0.35)   # source glow / antinode kiss

# ── Materials ────────────────────────────────────────────────────────────
var _mat_surface: StandardMaterial3D       # vertex-colour water surface
var _mat_source: StandardMaterial3D        # glowing source spheres
var _mat_rim: StandardMaterial3D           # tank rim + backdrop (dark)

var _rng: RandomNumberGenerator
var _mesh_count: int = 0
var _vertex_count: int = 0

# Source planar positions (XZ plane, y handled separately).
var _s1: Vector2 = Vector2.ZERO
var _s2: Vector2 = Vector2.ZERO
var _k: float = 0.0                         # wavenumber, cached


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED
	_k = TAU / WAVELENGTH
	# Sources sit symmetric about the origin on the X axis.
	_s1 = Vector2(-SOURCE_GAP * 0.5, 0.0)
	_s2 = Vector2(SOURCE_GAP * 0.5, 0.0)
	_build_materials()
	_build_scene()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════
# THE INTERFERENCE FIELD — the genuine two-source superposition
# ═══════════════════════════════════════════════════════════════

## Summed height of the two circular waves at planar point p (XZ).
## A(p) = A0·sin(k·|p-s1| - phi) + A0·sin(k·|p-s2| - phi), times a soft radial
## envelope so the pool settles toward its rim. This is the load-bearing
## physics — do not "optimise" the sum away.
func _wave_height(p: Vector2) -> float:
	var r1: float = (p - _s1).length()
	var r2: float = (p - _s2).length()
	var w1: float = sin(_k * r1 - PHASE)
	var w2: float = sin(_k * r2 - PHASE)
	var raw: float = AMPLITUDE * (w1 + w2)
	return raw * _envelope(p)


## Smooth radial envelope in [0,1]: ~1 near the plate centre, easing toward a
## floor near the rim. Uses a cosine shoulder over the plate's half-span.
func _envelope(p: Vector2) -> float:
	var half: float = PLATE_SPAN * 0.5
	var d: float = clampf(p.length() / half, 0.0, 1.0)
	# Cosine shoulder: flat in the middle, rolling off toward the edge.
	var shoulder: float = 0.5 * (cos(d * PI) + 1.0)
	return lerpf(1.0 - ENVELOPE_FALLOFF, 1.0, shoulder)


## Analytic outward normal of the displaced surface at planar p. We compute the
## partial derivatives of the height field (central differences in X and Z of
## _wave_height, which already includes the envelope) and form the surface
## normal as normalize(-dh/dx, 1, -dh/dz). Analytic > generate_normals() here
## because the field is smooth and we want crisp fringe shading.
func _wave_normal(p: Vector2) -> Vector3:
	var eps: float = PLATE_SPAN / float(GRID_RES) * 0.75
	var hx0: float = _wave_height(p + Vector2(eps, 0.0))
	var hx1: float = _wave_height(p - Vector2(eps, 0.0))
	var hz0: float = _wave_height(p + Vector2(0.0, eps))
	var hz1: float = _wave_height(p - Vector2(0.0, eps))
	var dhdx: float = (hx0 - hx1) / (2.0 * eps)
	var dhdz: float = (hz0 - hz1) / (2.0 * eps)
	return Vector3(-dhdx, 1.0, -dhdz).normalized()


## Map a normalized amplitude a in [-1, +1] to the water colour ramp:
## trough → mid → crest, with a touch of warm accent kissed into the very
## brightest antinodes so the constructive peaks glint.
func _amp_color(a: float) -> Color:
	var t: float = clampf((a + 1.0) * 0.5, 0.0, 1.0)   # 0 = trough, 1 = crest
	var base: Color
	if t < 0.5:
		base = COL_TROUGH.lerp(COL_MID, t * 2.0)
	else:
		base = COL_MID.lerp(COL_CREST, (t - 0.5) * 2.0)
	# Warm glint only on the top sliver of crests (constructive antinodes).
	var glint: float = clampf((t - 0.86) / 0.14, 0.0, 1.0)
	return base.lerp(COL_ACCENT, glint * 0.45)


# ═══════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# WATER SURFACE — vertex colour drives albedo; gentle sheen.
	_mat_surface = StandardMaterial3D.new()
	_mat_surface.vertex_color_use_as_albedo = true
	_mat_surface.albedo_color = Color(1.0, 1.0, 1.0)
	_mat_surface.roughness = 0.5
	_mat_surface.metallic = 0.0
	_mat_surface.emission_enabled = true
	_mat_surface.emission = Color(0.30, 0.45, 0.65)
	_mat_surface.emission_energy_multiplier = 0.10
	# Light both sides so the under-curl of crests does not read black.
	_mat_surface.cull_mode = BaseMaterial3D.CULL_DISABLED

	# SOURCES — glowing accent emitters, near-unshaded.
	_mat_source = StandardMaterial3D.new()
	_mat_source.albedo_color = COL_ACCENT
	_mat_source.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_source.emission_enabled = true
	_mat_source.emission = COL_ACCENT
	_mat_source.emission_energy_multiplier = 4.0

	# RIM / BACKDROP — dark so the fringes pop.
	_mat_rim = StandardMaterial3D.new()
	_mat_rim.albedo_color = Color(0.09, 0.10, 0.14)
	_mat_rim.roughness = 0.85
	_mat_rim.metallic = 0.0
	_mat_rim.emission_enabled = true
	_mat_rim.emission = Color(0.09, 0.10, 0.14)
	_mat_rim.emission_energy_multiplier = 0.04


# ═══════════════════════════════════════════════════════════════
# ASSEMBLY
# ═══════════════════════════════════════════════════════════════

func _build_scene() -> void:
	# Backdrop first (deepest), behind and below, so the plate floats on dark.
	_build_backdrop()

	# The tank: rim + displaced water surface, tilted toward the camera as one
	# rigid group so the fringe geometry tips into view without skewing the math.
	var tilt := Basis()
	tilt = tilt.rotated(Vector3(1.0, 0.0, 0.0), deg_to_rad(-TILT_DEGREES))
	var tank := Node3D.new()
	tank.name = "RippleTank"
	tank.basis = tilt
	add_child(tank)

	_build_rim(tank)
	_build_surface(tank)
	_build_sources(tank)

	print("CodexOpticsTrialV2: grid=%dx%d verts=%d meshes=%d lambda=%.3f k=%.2f gap=%.2f (d/lambda=%.2f) seed=%d" % [
		GRID_RES, GRID_RES, _vertex_count, _mesh_count,
		WAVELENGTH, _k, SOURCE_GAP, SOURCE_GAP / WAVELENGTH, SEED])


## The water surface: a GRID_RES × GRID_RES quad mesh, every vertex displaced by
## the two-source field and tinted by amplitude. Built by hand with SurfaceTool;
## per-vertex normal is the analytic field normal, per-vertex colour from the
## ramp. Two triangles per cell, UVs emitted so generate_tangents would be legal
## (we don't call it — no normal map). Committed as one batched ArrayMesh.
func _build_surface(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = PLATE_SPAN * 0.5
	var step: float = PLATE_SPAN / float(GRID_RES)

	# Precompute the lattice (positions, normals, colours, UVs) so each shared
	# edge reuses identical vertex data and the field is evaluated once per node.
	var cells: int = GRID_RES
	var pts: int = cells + 1
	var positions: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var colors: Array[Color] = []
	var uvs: Array[Vector2] = []
	positions.resize(pts * pts)
	normals.resize(pts * pts)
	colors.resize(pts * pts)
	uvs.resize(pts * pts)

	var max_amp: float = 2.0 * AMPLITUDE   # |A(x)| ceiling for colour normalize

	for iz: int in range(pts):
		var z: float = -half + float(iz) * step
		for ix: int in range(pts):
			var x: float = -half + float(ix) * step
			var p2: Vector2 = Vector2(x, z)
			var h: float = _wave_height(p2)
			var idx: int = iz * pts + ix
			positions[idx] = Vector3(x, h, z)
			normals[idx] = _wave_normal(p2)
			# Normalize amplitude to [-1,+1] for the colour ramp.
			var a_norm: float = clampf(h / maxf(max_amp, 0.0001), -1.0, 1.0)
			colors[idx] = _amp_color(a_norm)
			uvs[idx] = Vector2(float(ix) / float(cells), float(iz) / float(cells))

	# Two triangles per grid cell, winding CCW when viewed from above (+Y).
	for iz: int in range(cells):
		for ix: int in range(cells):
			var i00: int = iz * pts + ix
			var i10: int = iz * pts + (ix + 1)
			var i01: int = (iz + 1) * pts + ix
			var i11: int = (iz + 1) * pts + (ix + 1)

			_emit_vertex(st, positions[i00], normals[i00], colors[i00], uvs[i00])
			_emit_vertex(st, positions[i01], normals[i01], colors[i01], uvs[i01])
			_emit_vertex(st, positions[i10], normals[i10], colors[i10], uvs[i10])

			_emit_vertex(st, positions[i10], normals[i10], colors[i10], uvs[i10])
			_emit_vertex(st, positions[i01], normals[i01], colors[i01], uvs[i01])
			_emit_vertex(st, positions[i11], normals[i11], colors[i11], uvs[i11])

	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "WaterSurface"
	mi.mesh = mesh
	mi.material_override = _mat_surface
	parent.add_child(mi)
	_mesh_count += 1
	_vertex_count += pts * pts


## Emit one vertex with explicit normal, colour, UV.
func _emit_vertex(st: SurfaceTool, pos: Vector3, n: Vector3, c: Color, uv: Vector2) -> void:
	st.set_normal(n)
	st.set_color(c)
	st.set_uv(uv)
	st.add_vertex(pos)


## Two glowing source spheres at s1, s2, floating just above the surface where
## the waves originate. Sized small so they read as drop-points, not buoys.
func _build_sources(parent: Node3D) -> void:
	var src_r: float = 0.052
	var mesh: Mesh = MorphoPrimitive.sphere(src_r, 18, 12)
	for s: Vector2 in [_s1, _s2]:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _mat_source
		# Sit each source a touch above the local surface height at its centre.
		var surf_h: float = _wave_height(s)
		mi.position = Vector3(s.x, surf_h + src_r * 1.4, s.y)
		parent.add_child(mi)
		_mesh_count += 1


## A thin dark tank rim ringing the pool: a square frame built from four
## Basis-oriented boxes (no torus seam to fight the square plate). Sits just
## below the mean water level so crests at the edge clear it.
func _build_rim(parent: Node3D) -> void:
	var half: float = PLATE_SPAN * 0.5
	var rim_thick: float = 0.075
	var rim_h: float = 0.11
	var outer: float = half + rim_thick * 0.5
	var rim_y: float = -AMPLITUDE * 0.6           # just under the resting plane

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Four bars: two along X (front/back), two along Z (left/right). Each is a
	# box centred on its edge, oriented to world axes (no look_at needed).
	var bar_len: float = PLATE_SPAN + rim_thick * 2.0
	# Front (−Z) and back (+Z): long axis = X.
	_emit_bar(st, Vector3(0.0, rim_y, -outer), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		bar_len * 0.5, rim_h * 0.5, rim_thick * 0.5)
	_emit_bar(st, Vector3(0.0, rim_y, outer), Vector3.RIGHT, Vector3.UP, Vector3.BACK,
		bar_len * 0.5, rim_h * 0.5, rim_thick * 0.5)
	# Left (−X) and right (+X): long axis = Z.
	_emit_bar(st, Vector3(-outer, rim_y, 0.0), Vector3.BACK, Vector3.UP, Vector3.RIGHT,
		PLATE_SPAN * 0.5, rim_h * 0.5, rim_thick * 0.5)
	_emit_bar(st, Vector3(outer, rim_y, 0.0), Vector3.BACK, Vector3.UP, Vector3.RIGHT,
		PLATE_SPAN * 0.5, rim_h * 0.5, rim_thick * 0.5)

	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "TankRim"
	mi.mesh = mesh
	mi.material_override = _mat_rim
	parent.add_child(mi)
	_mesh_count += 1


## One rim bar: an oriented box centred at c with orthonormal axes (ax,ay,az)
## and half-extents (hx,hy,hz). 12 triangles, outward normals.
func _emit_bar(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
		hx: float, hy: float, hz: float) -> void:
	var ex: Vector3 = ax * hx
	var ey: Vector3 = ay * hy
	var ez: Vector3 = az * hz
	var p000: Vector3 = c - ex - ey - ez
	var p100: Vector3 = c + ex - ey - ez
	var p110: Vector3 = c + ex + ey - ez
	var p010: Vector3 = c - ex + ey - ez
	var p001: Vector3 = c - ex - ey + ez
	var p101: Vector3 = c + ex - ey + ez
	var p111: Vector3 = c + ex + ey + ez
	var p011: Vector3 = c - ex + ey + ez
	_quad(st, p000, p010, p110, p100, -az)
	_quad(st, p001, p101, p111, p011, az)
	_quad(st, p000, p100, p101, p001, -ay)
	_quad(st, p010, p011, p111, p110, ay)
	_quad(st, p000, p001, p011, p010, -ax)
	_quad(st, p100, p110, p111, p101, ax)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


## A dark backdrop slab behind and below the plate, so the bright fringes and
## glowing sources read against shadow. Built from MorphoPrimitive.box, oriented
## via Basis, set well behind the tilted tank.
func _build_backdrop() -> void:
	var slab: Mesh = MorphoPrimitive.box(Vector3(PLATE_SPAN * 2.0, PLATE_SPAN * 1.6, 0.12))
	var mi := MeshInstance3D.new()
	mi.name = "Backdrop"
	mi.mesh = slab
	mi.material_override = _mat_rim
	# Stand it up (lean slightly back) behind the pool.
	var b := Basis()
	b = b.rotated(Vector3.RIGHT, deg_to_rad(-18.0))
	mi.transform = Transform3D(b, Vector3(0.0, PLATE_SPAN * 0.35, -PLATE_SPAN * 0.85))
	add_child(mi)
	_mesh_count += 1
