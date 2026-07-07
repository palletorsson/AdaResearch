# trial.gd — CodexOpticsTrialV4 — QUANTUM WAVE PACKET ψ (wavefunction)
#
# A localized travelling wave — the genuine quantum wave packet — rendered as a
# Codex Seraphinianus field plate. After Serafini's abstract wave/field pages,
# but every curve here is COMPUTED, not drawn: a superposition of plane waves
# under a Gaussian envelope, plus its Born-rule probability cloud.
#
# ── THE GENUINE ALGORITHM ────────────────────────────────────────────────
# A quantum wave packet is a superposition of plane waves that interfere into a
# single localized travelling lump:
#
#     ψ(x) = exp( -(x-x0)^2 / (2*sigma^2) ) * [ cos(k*x) + i*sin(k*x) ]
#            └────────── Gaussian envelope ──────┘ └── complex plane wave e^{ikx} ──┘
#
#   Re(ψ)(x) = G(x) * cos(k*x)      — the cyan ribbon
#   Im(ψ)(x) = G(x) * sin(k*x)      — the magenta ribbon
#   |ψ(x)|^2 = G(x)^2               — the probability DENSITY (Born rule):
#                                      where the "particle" probably IS.
#
# Re and Im are two ribbons winding down the x-axis a quarter-period out of
# phase — a complex helix-like wave: tight oscillation in the middle (the carrier
# k), fading toward both ends (the envelope G localizes it). The Gaussian
# ENVELOPE ±G(x) is drawn as two faint enclosing curves, showing the packet's
# localization. |ψ|^2 = G(x)^2 is a smooth bell rendered as a glowing band of
# beads along the base — brightest at the centre x0, the most probable position.
#
# This is a genuine wave packet: localized superposition + Born-rule density.
#
# ── NON-PRIMITIVE CONSTRUCTION ───────────────────────────────────────────
# ψ(x) is sampled into typed local point arrays (Array[Vector3] / Array[float])
# BEFORE any sweep Callable runs. Re/Im ribbons and the two envelope curves are
# lofted with MorphoSweep.sweep along path Callables that read those baked
# points. The density beads are MorphoPrimitive.sphere instances scaled by
# |ψ|^2. The axis + backdrop are MorphoPrimitive.box. Every ribbon/curve mesh
# is merged into ONE batched ArrayMesh per material (Variant-coercing the
# non-indexed / UV-less surfaces; no generate_tangents). Deterministic from a
# local seeded RNG (seed 4242) — the seed only jitters faint bead twinkle, never
# the wavefunction.

extends Node3D

class_name CodexOpticsTrialV4

# ── Tunables: the genuine wave-packet math ───────────────────────────────
const SEED: int = 4242

# Carrier wave number k and envelope width sigma over the local x-domain
# x ∈ [X_MIN, X_MAX]. k sets how many oscillations the carrier packs; sigma sets
# how tightly the Gaussian localizes them around x0. Tuned so the centre reads
# as dense oscillation that visibly fades at both ends.
const X_MIN: float = -1.45              # local domain start (left)
const X_MAX: float = 1.45               # local domain end   (right)
const X0: float = 0.0                   # packet centre (most probable position)
const K_WAVE: float = 11.5              # carrier wave number (oscillation rate)
const SIGMA: float = 0.52               # Gaussian envelope width (localization)
const SAMPLES: int = 168                # ψ(x) samples along x (120-200)
const AMP: float = 0.62                 # vertical amplitude of Re/Im in metres

# Geometry / presentation.
const RIBBON_R: float = 0.034           # Re/Im ribbon tube radius
const ENV_R: float = 0.013              # envelope curve tube radius (thin)
const RIBBON_SIDES: int = 7             # cross-section sides for ribbon tubes
const ENV_SIDES: int = 5                # cross-section sides for envelope tubes
const Z_RE: float = -0.16              # Re ribbon depth offset (toward back)
const Z_IM: float = 0.16               # Im ribbon depth offset (toward front)
const DENSITY_BEADS: int = 56          # number of |ψ|^2 probability beads
const DENSITY_Y: float = -0.92         # base level where the density cloud sits
const BEAD_MAX_R: float = 0.072        # bead radius at the |ψ|^2 peak
const BEAD_MIN_R: float = 0.006        # bead radius in the tails

# ── Materials ────────────────────────────────────────────────────────────
var _mat_re: StandardMaterial3D         # Re(ψ) ribbon — cyan-blue
var _mat_im: StandardMaterial3D         # Im(ψ) ribbon — magenta
var _mat_env: StandardMaterial3D        # Gaussian envelope — faint blue-grey
var _mat_density: StandardMaterial3D    # |ψ|^2 cloud — gold, near-unshaded glow
var _mat_axis: StandardMaterial3D       # baseline axis + backdrop — dark

var _rng: RandomNumberGenerator
var _mesh_count: int = 0


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED
	_build_materials()
	_build_packet()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════
# THE WAVE-PACKET MATH — pure functions over the local x-domain
# ═══════════════════════════════════════════════════════════════

## Gaussian envelope G(x) = exp(-(x-x0)^2 / (2 sigma^2)). The localization that
## turns an infinite plane wave into a packet. Peaks at 1.0 at x0, decays to the
## tails. Uses exp() (never powf) for the Gaussian.
func _gaussian(x: float) -> float:
	var d: float = x - X0
	return exp(-(d * d) / (2.0 * SIGMA * SIGMA))


## Real part Re(ψ)(x) = G(x) * cos(k*x). The carrier cosine under the envelope.
func _re_psi(x: float) -> float:
	return _gaussian(x) * cos(K_WAVE * x)


## Imag part Im(ψ)(x) = G(x) * sin(k*x). The carrier sine — a quarter period out
## of phase with Re, so together they trace the complex helix e^{ikx}.
func _im_psi(x: float) -> float:
	return _gaussian(x) * sin(K_WAVE * x)


# ═══════════════════════════════════════════════════════════════
# ASSEMBLY
# ═══════════════════════════════════════════════════════════════

func _build_packet() -> void:
	# Map the local sample index i∈[0,SAMPLES] to world x∈[X_MIN,X_MAX] so the
	# wave runs left→right toward the +X/+Z camera. y carries Re/Im amplitude;
	# z separates the two ribbons into depth so the helix reads.

	# ── Bake ψ(x) into typed local arrays BEFORE any sweep Callable. ────────
	# These are the genuine sampled wavefunction; sweep paths only index them.
	var re_pts: Array[Vector3] = []
	var im_pts: Array[Vector3] = []
	var env_hi: Array[Vector3] = []     # +G(x) upper envelope curve
	var env_lo: Array[Vector3] = []     # -G(x) lower envelope curve
	var dens_x: Array[float] = []       # x positions for density beads
	var dens_v: Array[float] = []       # |ψ|^2 value at each bead

	for i: int in range(SAMPLES + 1):
		var t: float = float(i) / float(SAMPLES)
		var x: float = lerpf(X_MIN, X_MAX, t)
		var g: float = _gaussian(x)
		var re: float = _re_psi(x)
		var im: float = _im_psi(x)
		re_pts.append(Vector3(x, re * AMP, Z_RE))
		im_pts.append(Vector3(x, im * AMP, Z_IM))
		# Envelope rides slightly above the ribbon depth-centre, on its own plane.
		env_hi.append(Vector3(x, g * AMP, 0.0))
		env_lo.append(Vector3(x, -g * AMP, 0.0))

	# Density bead samples (|ψ|^2 = G^2), a coarser row than the ribbons.
	for b: int in range(DENSITY_BEADS):
		var tb: float = float(b) / float(DENSITY_BEADS - 1)
		var xb: float = lerpf(X_MIN, X_MAX, tb)
		var gb: float = _gaussian(xb)
		dens_x.append(xb)
		dens_v.append(gb * gb)          # Born-rule probability density

	# ── Re(ψ) and Im(ψ) ribbons — swept tubes along the baked points. ──────
	var re_mesh: ArrayMesh = _sweep_ribbon(re_pts, RIBBON_R, RIBBON_SIDES)
	_add_mesh(re_mesh, _mat_re, "Re_psi")
	var im_mesh: ArrayMesh = _sweep_ribbon(im_pts, RIBBON_R, RIBBON_SIDES)
	_add_mesh(im_mesh, _mat_im, "Im_psi")

	# ── Gaussian envelope — two faint thin curves enclosing the packet. ────
	# Batched into ONE ArrayMesh (both curves share the envelope material).
	var env_batch := SurfaceTool.new()
	env_batch.begin(Mesh.PRIMITIVE_TRIANGLES)
	_merge_into(env_batch, _sweep_ribbon(env_hi, ENV_R, ENV_SIDES))
	_merge_into(env_batch, _sweep_ribbon(env_lo, ENV_R, ENV_SIDES))
	var env_mesh: ArrayMesh = _commit(env_batch)
	_add_mesh(env_mesh, _mat_env, "Envelope")

	# ── |ψ|^2 probability density — glowing bell of beads along the base. ──
	_build_density_cloud(dens_x, dens_v)

	# ── Baseline axis + dark backdrop. ────────────────────────────────────
	_build_axis_and_backdrop()

	print("CodexOpticsTrialV4: meshes=%d samples=%d k=%.2f sigma=%.2f beads=%d (seed=%d)" % [
		_mesh_count, SAMPLES, K_WAVE, SIGMA, DENSITY_BEADS, SEED])


## Sweep a circular profile along a baked point array, building a tube that
## follows the wavefunction. The path Callable closes over a LOCAL COPY of the
## points (baked values, no node refs) and linearly samples them by parameter t.
## Radius tapers toward the ends so the ribbons fade where the envelope vanishes.
func _sweep_ribbon(points: Array[Vector3], radius: float, sides: int) -> Mesh:
	if points.size() < 2:
		return null
	var baked: Array[Vector3] = points.duplicate()    # local copy for the Callable
	var n: int = baked.size()
	var last: int = n - 1

	# Path: map t∈[0,1] to an interpolated position along the baked polyline.
	var path_func: Callable = func(t: float) -> Vector3:
		var ft: float = clampf(t, 0.0, 1.0) * float(last)
		var i0: int = int(floor(ft))
		var i1: int = mini(i0 + 1, last)
		var frac: float = ft - float(i0)
		return (baked[i0] as Vector3).lerp(baked[i1] as Vector3, frac)

	# Radius: gently taper to ~30% at the very ends so the swept tube thins as
	# the packet fades, echoing the envelope without hiding the carrier.
	var radius_func: Callable = func(t: float) -> float:
		var edge: float = sin(clampf(t, 0.0, 1.0) * PI)     # 0 at ends, 1 mid
		return radius * lerpf(0.30, 1.0, edge)

	# One sweep segment per sample span → faithful to the oscillation.
	return MorphoSweep.sweep(
		MorphoSweep.profile_circle(sides),
		path_func,
		radius_func,
		0.0,
		last,
		false)


## Build the |ψ|^2 probability cloud as a row of glowing gold beads along the
## base, each sphere scaled by the local probability density (Born rule). The
## bell shape of G(x)^2 makes the beads swell at the centre x0 (most probable
## position) and shrink to nothing in the tails. A faint seeded twinkle in the
## vertical lift is the ONLY use of the RNG — it never touches the wavefunction.
func _build_density_cloud(dens_x: Array[float], dens_v: Array[float]) -> void:
	var bead_proto: Mesh = MorphoPrimitive.sphere(1.0, 10, 6)   # unit, scaled per bead
	var transforms: Array = []
	for b: int in range(dens_x.size()):
		var v: float = clampf(dens_v[b], 0.0, 1.0)
		# Radius interpolates between a near-invisible tail bead and the peak.
		var r: float = lerpf(BEAD_MIN_R, BEAD_MAX_R, v)
		# Faint deterministic vertical twinkle, baked from the seeded RNG.
		var twinkle: float = _rng.randf_range(-0.012, 0.012) * v
		var pos := Vector3(dens_x[b], DENSITY_Y + twinkle, 0.0)
		# Squash slightly in y so the cloud reads as a band hugging the base.
		var basis := Basis().scaled(Vector3(r, r * 0.78, r))
		transforms.append(Transform3D(basis, pos))

	var mmi: MultiMeshInstance3D = MorphoPrimitive.multimesh_scatter(bead_proto, transforms)
	mmi.name = "DensityCloud"
	mmi.material_override = _mat_density
	add_child(mmi)
	_mesh_count += 1

	# A thin connecting gold ribbon UNDER the beads traces the smooth |ψ|^2 bell
	# itself (the continuous probability density), so the cloud reads as a curve,
	# not just dots. Built from the same baked density values.
	var bell_pts: Array[Vector3] = []
	for b2: int in range(dens_x.size()):
		var vy: float = dens_v[b2]
		# Lift the bell curve a touch above the base so it sits within the beads.
		bell_pts.append(Vector3(dens_x[b2], DENSITY_Y + vy * 0.20, 0.0))
	var bell_mesh: Mesh = _sweep_ribbon(bell_pts, 0.012, 5)
	_add_mesh(bell_mesh, _mat_density, "DensityBell")


## Baseline axis along x and a dark backdrop slab so the wave glows in front.
func _build_axis_and_backdrop() -> void:
	# Axis: a thin dark bar running the full x-span at the density base level,
	# the "x-axis" the packet travels along.
	var axis_len: float = (X_MAX - X_MIN) + 0.18
	var axis_mesh: Mesh = MorphoPrimitive.box(Vector3(axis_len, 0.012, 0.012))
	var axis_mi := MeshInstance3D.new()
	axis_mi.name = "Axis"
	axis_mi.mesh = axis_mesh
	axis_mi.material_override = _mat_axis
	axis_mi.position = Vector3((X_MIN + X_MAX) * 0.5, DENSITY_Y - 0.07, 0.0)
	add_child(axis_mi)
	_mesh_count += 1

	# Backdrop: a large dark slab behind the wave (−Z), so emissive ribbons and
	# the gold cloud read against darkness.
	var back_mesh: Mesh = MorphoPrimitive.box(Vector3(axis_len + 0.6, 2.5, 0.05))
	var back_mi := MeshInstance3D.new()
	back_mi.name = "Backdrop"
	back_mi.mesh = back_mesh
	back_mi.material_override = _mat_axis
	back_mi.position = Vector3((X_MIN + X_MAX) * 0.5, DENSITY_Y * 0.5 + 0.15, -0.55)
	add_child(back_mi)
	_mesh_count += 1


# ═══════════════════════════════════════════════════════════════
# MESH BATCHING — Variant-coercing merge of MorphoSweep surfaces
# ═══════════════════════════════════════════════════════════════

## Add a single mesh as its own MeshInstance3D child with the given material.
func _add_mesh(mesh: Mesh, mat: StandardMaterial3D, node_name: String) -> void:
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	_mesh_count += 1


## Merge any mesh surface into a shared SurfaceTool by reading its surface
## arrays. MorphoSweep returns an INDEXED mesh with normals (and UVs we ignore);
## we Variant-coerce the vertex/normal/index arrays, guard for absence, and feed
## vertices+normals straight through. No UVs are read, so we never call
## generate_tangents() on this UV-less batched geometry. Never `as ArrayMesh` —
## surface_get_arrays works directly on the Mesh.
func _merge_into(st: SurfaceTool, mesh: Mesh) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var arrays: Array = mesh.surface_get_arrays(0)
	var v_raw: Variant = arrays[Mesh.ARRAY_VERTEX]
	if not (v_raw is PackedVector3Array):
		return
	var verts: PackedVector3Array = v_raw
	var n_raw: Variant = arrays[Mesh.ARRAY_NORMAL]
	var has_norms: bool = n_raw is PackedVector3Array
	var norms := PackedVector3Array()
	if has_norms:
		norms = n_raw
	var i_raw: Variant = arrays[Mesh.ARRAY_INDEX]
	var indices := PackedInt32Array()
	if i_raw is PackedInt32Array:
		indices = i_raw

	if indices.size() > 0:
		for ii: int in range(indices.size()):
			var vi: int = indices[ii]
			if has_norms:
				st.set_normal(norms[vi])
			st.add_vertex(verts[vi])
	else:
		for vi2: int in range(verts.size()):
			if has_norms:
				st.set_normal(norms[vi2])
			st.add_vertex(verts[vi2])


## Commit a batched SurfaceTool to an ArrayMesh, generating normals only if the
## merge produced none (the merged surfaces already carry normals).
func _commit(st: SurfaceTool) -> ArrayMesh:
	return st.commit()


# ═══════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# Re(ψ) — cyan-blue ribbon, emissive floor so it glows on the dark slab.
	_mat_re = StandardMaterial3D.new()
	_mat_re.albedo_color = Color(0.30, 0.70, 0.95)
	_mat_re.roughness = 0.42
	_mat_re.metallic = 0.0
	_mat_re.emission_enabled = true
	_mat_re.emission = Color(0.30, 0.70, 0.95)
	_mat_re.emission_energy_multiplier = 0.12

	# Im(ψ) — magenta ribbon, matching emissive floor.
	_mat_im = StandardMaterial3D.new()
	_mat_im.albedo_color = Color(0.95, 0.45, 0.70)
	_mat_im.roughness = 0.42
	_mat_im.metallic = 0.0
	_mat_im.emission_enabled = true
	_mat_im.emission = Color(0.95, 0.45, 0.70)
	_mat_im.emission_energy_multiplier = 0.12

	# Gaussian envelope — faint blue-grey, thin, low glow.
	_mat_env = StandardMaterial3D.new()
	_mat_env.albedo_color = Color(0.70, 0.75, 0.85)
	_mat_env.roughness = 0.6
	_mat_env.metallic = 0.0
	_mat_env.emission_enabled = true
	_mat_env.emission = Color(0.70, 0.75, 0.85)
	_mat_env.emission_energy_multiplier = 0.08

	# |ψ|^2 density — gold, near-UNSHADED, bright glow (the probability cloud).
	_mat_density = StandardMaterial3D.new()
	_mat_density.albedo_color = Color(0.98, 0.85, 0.35)
	_mat_density.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_density.emission_enabled = true
	_mat_density.emission = Color(0.98, 0.85, 0.35)
	_mat_density.emission_energy_multiplier = 3.5

	# Axis + backdrop — dark, rough, barely emissive.
	_mat_axis = StandardMaterial3D.new()
	_mat_axis.albedo_color = Color(0.08, 0.09, 0.13)
	_mat_axis.roughness = 0.9
	_mat_axis.metallic = 0.0
	_mat_axis.emission_enabled = true
	_mat_axis.emission = Color(0.08, 0.09, 0.13)
	_mat_axis.emission_energy_multiplier = 0.04
