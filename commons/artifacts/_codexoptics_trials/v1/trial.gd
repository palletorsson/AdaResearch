# trial.gd — CodexOpticsTrialV1 — SNELL'S-LAW REFRACTION + DISPERSION
#
# A glass PRISM splitting one white beam into a rainbow SPECTRUM, in the spirit
# of Luigi Serafini's Codex Seraphinianus light/prism plates. The dispersion is
# NOT decorative — it is computed honestly from Snell's law per wavelength.
#
# ── THE GENUINE ALGORITHM ────────────────────────────────────────────────────
# A glass prism disperses white light because the refractive index n depends on
# wavelength (n_red < n_violet). A white beam hits the ENTRY face and refracts
# (air→glass), crosses the glass, hits the EXIT face and refracts again
# (glass→air). At each interface Snell's law holds:
#       n1 * sin(theta_1) = n2 * sin(theta_2)
# Because each colour has a slightly different n, each exits the second face at a
# slightly different angle — and the single white ray FANS OUT into a spectrum.
# Red (low n) bends least, violet (high n) bends most. We sample ~11 wavelengths
# red→violet, run BOTH refractions for each via vector Snell (refract()), and
# place one glowing beam per wavelength along its physically-derived exit
# direction. The fan then lands on a dark screen as a row of spectral patches.
#
# Implementation honesty:
#   * Index of refraction per wavelength via a Cauchy-style fit (_n_for_lambda),
#     calibrated so n(656nm red)~1.512 and n(405nm violet)~1.530 — real crown
#     glass dispersion.
#   * _refract() is the exact vector form of Snell's law (Heckbert), returning
#     the refracted direction or, on total internal reflection, a zero vector.
#   * Entry + exit face normals are the true geometric normals of an equilateral
#     prism cross-section, so theta_1/theta_2 at each face are physical.
#   * Wavelength→RGB via _wavelength_to_rgb (approx CIE visible-spectrum mapping).
#
# ── NON-PRIMITIVE CONSTRUCTION ───────────────────────────────────────────────
# The prism body is an EXTRUDED equilateral triangle built vert-by-vert into an
# ArrayMesh (two triangular caps + three rectangular side walls) — not a
# PrismMesh. The white beam and every spectral beam are MorphoPrimitive.multi_tube
# segments, all baked into ONE batched ArrayMesh via SurfaceTool (Variant-coerced
# non-indexed surfaces, no generate_tangents on UV-less geometry). The screen and
# backdrop are extruded quads. Beams are oriented purely by their endpoint
# positions (multi_tube derives its own frame) — no out-of-tree look_at.
# Deterministic: local RNG seeded 4242, only used for sub-pixel beam shimmer.

extends Node3D

class_name CodexOpticsTrialV1

# ── Tunables ─────────────────────────────────────────────────────────────────
const SEED: int = 4242
const PRISM_SIDE: float = 0.72            # edge length of the equilateral triangle
const PRISM_DEPTH: float = 0.46           # extrusion depth along Z
const WAVELENGTH_SAMPLES: int = 11        # spectral rays traced red→violet
const LAMBDA_RED_NM: float = 660.0        # longest wavelength sampled
const LAMBDA_VIOLET_NM: float = 410.0     # shortest wavelength sampled
const BEAM_RADIUS: float = 0.0085         # tube radius of every light beam
const BEAM_SIDES: int = 7                 # tube cross-section sides
const SCREEN_DISTANCE: float = 1.55       # how far past the prism the screen sits
const INCOMING_LEN: float = 1.05          # length of the white beam before entry
const APEX_ANGLE_DEG: float = 60.0        # equilateral prism apex angle

# ── Materials ────────────────────────────────────────────────────────────────
var _mat_glass: StandardMaterial3D
var _mat_white: StandardMaterial3D
var _mat_screen: StandardMaterial3D
var _mat_backdrop: StandardMaterial3D
# One emissive material per spectral wavelength (built on demand, cached).
var _spectral_mats: Array[StandardMaterial3D] = []

var _rng: RandomNumberGenerator
var _mesh_count: int = 0
var _beam_count: int = 0
var _patch_count: int = 0

# Geometry of the prism cross-section (XY plane), filled in _compute_prism().
var _apex: Vector2          # top vertex
var _base_left: Vector2     # lower-left vertex
var _base_right: Vector2    # lower-right vertex
var _entry_n: Vector2       # outward normal of the entry (upper-left) face
var _exit_n: Vector2        # outward normal of the exit (upper-right) face


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED
	_build_materials()
	_compute_prism()
	_build_scene()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# GLASS prism — pale, translucent, low roughness, clearcoat for a refractive
	# sheen. CULL_DISABLED so we see the back faces through the alpha.
	_mat_glass = StandardMaterial3D.new()
	_mat_glass.albedo_color = Color(0.80, 0.88, 0.95, 0.35)
	_mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_glass.roughness = 0.06
	_mat_glass.metallic = 0.0
	_mat_glass.clearcoat_enabled = true
	_mat_glass.clearcoat = 0.9
	_mat_glass.clearcoat_roughness = 0.05
	_mat_glass.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_mat_glass.emission_enabled = true
	_mat_glass.emission = Color(0.80, 0.88, 0.95)
	_mat_glass.emission_energy_multiplier = 0.12

	# WHITE incoming beam — bright, near-unshaded.
	_mat_white = StandardMaterial3D.new()
	_mat_white.albedo_color = Color(0.98, 0.98, 0.95)
	_mat_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_white.emission_enabled = true
	_mat_white.emission = Color(0.98, 0.98, 0.95)
	_mat_white.emission_energy_multiplier = 4.0

	# SCREEN — dark panel that the fan lands on (low emission floor so the
	# spectral patches still read against it).
	_mat_screen = StandardMaterial3D.new()
	_mat_screen.albedo_color = Color(0.08, 0.09, 0.13)
	_mat_screen.roughness = 0.9
	_mat_screen.metallic = 0.0
	_mat_screen.emission_enabled = true
	_mat_screen.emission = Color(0.08, 0.09, 0.13)
	_mat_screen.emission_energy_multiplier = 0.04

	# BACKDROP — even darker, so the spectral glow pops.
	_mat_backdrop = StandardMaterial3D.new()
	_mat_backdrop.albedo_color = Color(0.05, 0.06, 0.09)
	_mat_backdrop.roughness = 0.95
	_mat_backdrop.metallic = 0.0


## Emissive material whose emission IS the wavelength's RGB. Cached per index so
## beams and their landing patch share the exact same colour.
func _spectral_material(idx: int, rgb: Color) -> StandardMaterial3D:
	while _spectral_mats.size() <= idx:
		_spectral_mats.append(null)
	if _spectral_mats[idx] != null:
		return _spectral_mats[idx]
	var m := StandardMaterial3D.new()
	m.albedo_color = rgb
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = rgb
	m.emission_energy_multiplier = 3.5
	_spectral_mats[idx] = m
	return m


# ═══════════════════════════════════════════════════════════════
# PHYSICS — Snell's law + dispersion
# ═══════════════════════════════════════════════════════════════

## Refractive index n as a function of wavelength (nm), Cauchy form
## n(l) = A + B / l^2. A,B chosen so n(660nm)≈1.512 (red) and
## n(410nm)≈1.530 (violet) — typical crown-glass dispersion. Shorter
## wavelengths (violet) get a HIGHER index, so they bend more. This is the
## entire reason a prism makes a spectrum.
func _n_for_lambda(lambda_nm: float) -> float:
	# Solve A,B from the two anchor points once, inline.
	var l1: float = LAMBDA_RED_NM
	var l2: float = LAMBDA_VIOLET_NM
	var n1: float = 1.512
	var n2: float = 1.530
	var inv1: float = 1.0 / (l1 * l1)
	var inv2: float = 1.0 / (l2 * l2)
	var b_coeff: float = (n2 - n1) / (inv2 - inv1)
	var a_coeff: float = n1 - b_coeff * inv1
	var inv: float = 1.0 / (lambda_nm * lambda_nm)
	return a_coeff + b_coeff * inv


## Vector form of Snell's law (Heckbert). `incident` and `normal` are unit
## vectors; `normal` faces AGAINST the incident ray (into the medium the ray is
## leaving). eta = n1 / n2. Returns the unit refracted direction, or Vector2.ZERO
## on total internal reflection.
func _refract(incident: Vector2, normal: Vector2, eta: float) -> Vector2:
	var cos_i: float = -incident.dot(normal)
	var sin_t2: float = eta * eta * (1.0 - cos_i * cos_i)
	if sin_t2 > 1.0:
		return Vector2.ZERO                       # total internal reflection
	var cos_t: float = sqrt(1.0 - sin_t2)
	return (incident * eta + normal * (eta * cos_i - cos_t)).normalized()


## Trace one wavelength's ray through the prism. Returns a Dictionary:
##   { ok: bool, hit_entry: Vector2, hit_exit: Vector2, dir_out: Vector2 }
## All vectors in the prism's XY cross-section. The ray starts at the incoming
## beam, refracts at the entry face, travels in glass to the exit face, refracts
## again to air, and we report where it left and which way it points.
func _trace_ray(lambda_nm: float, entry_point: Vector2, dir_in: Vector2) -> Dictionary:
	var n_glass: float = _n_for_lambda(lambda_nm)

	# --- Refraction 1: air → glass at the entry (upper-left) face. ---
	# Normal must point against the incoming ray (i.e. outward, toward the air).
	var n_entry: Vector2 = _entry_n
	if n_entry.dot(dir_in) > 0.0:
		n_entry = -n_entry
	var dir_glass: Vector2 = _refract(dir_in, n_entry, 1.0 / n_glass)
	if dir_glass == Vector2.ZERO:
		return {"ok": false}

	# --- Travel through glass: intersect the exit (upper-right) face. ---
	var hit_exit: Vector2 = _ray_segment_hit(entry_point, dir_glass, _apex, _base_right)
	if hit_exit == Vector2.INF:
		# Fallback: try the base, in case geometry pushed it low (shouldn't happen).
		hit_exit = _ray_segment_hit(entry_point, dir_glass, _base_left, _base_right)
		if hit_exit == Vector2.INF:
			return {"ok": false}

	# --- Refraction 2: glass → air at the exit face. ---
	var n_exit: Vector2 = _exit_n
	if n_exit.dot(dir_glass) < 0.0:
		n_exit = -n_exit                          # normal points outward, with the ray
	# For glass→air the surface normal in Heckbert's form must oppose the ray.
	var n_exit_against: Vector2 = -n_exit
	var dir_out: Vector2 = _refract(dir_glass, n_exit_against, n_glass / 1.0)
	if dir_out == Vector2.ZERO:
		return {"ok": false}

	return {
		"ok": true,
		"hit_entry": entry_point,
		"hit_exit": hit_exit,
		"dir_out": dir_out,
	}


## Ray (origin o, unit dir d) vs segment (a→b) intersection in 2D. Returns the
## hit point, or Vector2.INF if no forward hit within the segment.
func _ray_segment_hit(o: Vector2, d: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var e: Vector2 = b - a
	var denom: float = d.x * e.y - d.y * e.x
	if absf(denom) < 0.000001:
		return Vector2.INF                        # parallel
	var diff: Vector2 = a - o
	var t: float = (diff.x * e.y - diff.y * e.x) / denom   # along ray
	var u: float = (diff.x * d.y - diff.y * d.x) / denom   # along segment
	if t <= 0.0001 or u < -0.001 or u > 1.001:
		return Vector2.INF
	return o + d * t


## Approximate visible-spectrum wavelength (nm) → RGB. Standard piecewise CIE
## fit (Bruton), with intensity falloff at the spectral edges so the deep red and
## deep violet don't read as pure black.
func _wavelength_to_rgb(lambda_nm: float) -> Color:
	var l: float = clampf(lambda_nm, 380.0, 750.0)
	var r: float = 0.0
	var g: float = 0.0
	var b: float = 0.0
	if l < 440.0:
		r = -(l - 440.0) / (440.0 - 380.0)
		g = 0.0
		b = 1.0
	elif l < 490.0:
		r = 0.0
		g = (l - 440.0) / (490.0 - 440.0)
		b = 1.0
	elif l < 510.0:
		r = 0.0
		g = 1.0
		b = -(l - 510.0) / (510.0 - 490.0)
	elif l < 580.0:
		r = (l - 510.0) / (580.0 - 510.0)
		g = 1.0
		b = 0.0
	elif l < 645.0:
		r = 1.0
		g = -(l - 645.0) / (645.0 - 580.0)
		b = 0.0
	else:
		r = 1.0
		g = 0.0
		b = 0.0
	# Intensity correction toward the vision limits.
	var factor: float = 1.0
	if l < 420.0:
		factor = 0.3 + 0.7 * (l - 380.0) / (420.0 - 380.0)
	elif l > 700.0:
		factor = 0.3 + 0.7 * (750.0 - l) / (750.0 - 700.0)
	var gamma: float = 0.85
	return Color(pow(r * factor, gamma), pow(g * factor, gamma), pow(b * factor, gamma))


# ═══════════════════════════════════════════════════════════════
# PRISM GEOMETRY
# ═══════════════════════════════════════════════════════════════

## Lay out the equilateral triangle cross-section in the XY plane and precompute
## the entry/exit face outward normals. The apex points up; the base is
## horizontal. The white beam enters the upper-LEFT face, exits the upper-RIGHT
## face, so the spectrum fans out to the +X side toward the screen.
func _compute_prism() -> void:
	var s: float = PRISM_SIDE
	var h: float = s * sqrt(3.0) * 0.5            # height of equilateral triangle
	# Centre the triangle's centroid roughly on origin in XY.
	var cy: float = h / 3.0
	_apex = Vector2(0.0, h - cy)
	_base_left = Vector2(-s * 0.5, -cy)
	_base_right = Vector2(s * 0.5, -cy)

	# Outward normal of the entry face (apex→base_left edge), pointing up-left.
	var e_entry: Vector2 = _base_left - _apex
	_entry_n = Vector2(-e_entry.y, e_entry.x).normalized()
	if _entry_n.x > 0.0:                           # force it to face the -X/up air
		_entry_n = -_entry_n

	# Outward normal of the exit face (apex→base_right edge), pointing up-right.
	var e_exit: Vector2 = _base_right - _apex
	_exit_n = Vector2(-e_exit.y, e_exit.x).normalized()
	if _exit_n.x < 0.0:                            # force it to face the +X air
		_exit_n = -_exit_n


# ═══════════════════════════════════════════════════════════════
# SCENE ASSEMBLY
# ═══════════════════════════════════════════════════════════════

func _build_scene() -> void:
	var root := Node3D.new()
	root.name = "OpticsBench"
	add_child(root)

	_build_backdrop(root)
	_build_prism_body(root)

	# Choose the entry point on the entry face: a touch above its midpoint so the
	# refracted ray crosses the body and reaches the exit face cleanly.
	var entry_mid: Vector2 = _apex.lerp(_base_left, 0.5)
	var entry_point: Vector2 = entry_mid + (_apex - _base_left).normalized() * (PRISM_SIDE * 0.06)

	# Incoming white beam: comes down-right from the upper-left toward entry_point.
	# Direction chosen so it strikes the entry face at a healthy oblique angle.
	var dir_in: Vector2 = Vector2(0.92, -0.39).normalized()
	var beam_origin: Vector2 = entry_point - dir_in * INCOMING_LEN
	_build_white_beam(root, beam_origin, entry_point)

	# Trace every wavelength, collect the segments, batch them, and find where the
	# fan lands so we can size the screen and drop patches.
	_build_spectrum(root, entry_point, dir_in)

	print("CodexOpticsTrialV1: meshes=%d beams=%d patches=%d samples=%d n=[%.3f..%.3f] (seed=%d)" % [
		_mesh_count, _beam_count, _patch_count, WAVELENGTH_SAMPLES,
		_n_for_lambda(LAMBDA_RED_NM), _n_for_lambda(LAMBDA_VIOLET_NM), SEED])


## Extruded equilateral-triangle glass prism: two triangular caps (front/back in
## Z) plus three quad side walls, built vert-by-vert into a SurfaceTool. Z is the
## extrusion axis; the cross-section is the XY triangle from _compute_prism().
func _build_prism_body(parent: Node3D) -> void:
	var z0: float = -PRISM_DEPTH * 0.5
	var z1: float = PRISM_DEPTH * 0.5

	var a0 := Vector3(_apex.x, _apex.y, z0)
	var b0 := Vector3(_base_left.x, _base_left.y, z0)
	var c0 := Vector3(_base_right.x, _base_right.y, z0)
	var a1 := Vector3(_apex.x, _apex.y, z1)
	var b1 := Vector3(_base_left.x, _base_left.y, z1)
	var c1 := Vector3(_base_right.x, _base_right.y, z1)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Front cap (facing -Z): winding so the normal points to -Z.
	_tri(st, a0, c0, b0, Vector3(0, 0, -1))
	# Back cap (facing +Z).
	_tri(st, a1, b1, c1, Vector3(0, 0, 1))

	# Three side walls (each a quad between front and back edges), outward normals
	# from the 2D edge normals so lighting reads correct.
	_wall(st, a0, b0, b1, a1, _edge_normal3(_apex, _base_left))      # entry face
	_wall(st, b0, c0, c1, b1, _edge_normal3(_base_left, _base_right)) # base
	_wall(st, c0, a0, a1, c1, _edge_normal3(_base_right, _apex))     # exit face

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "PrismBody"
	mi.mesh = mesh
	mi.material_override = _mat_glass
	parent.add_child(mi)
	_mesh_count += 1


## Outward 3D normal (XY plane, z=0) of a triangle edge a→b, flipped to point
## away from the centroid (origin-ish in XY).
func _edge_normal3(a: Vector2, b: Vector2) -> Vector3:
	var e: Vector2 = b - a
	var n: Vector2 = Vector2(-e.y, e.x).normalized()
	var mid: Vector2 = (a + b) * 0.5
	if n.dot(mid) < 0.0:
		n = -n
	return Vector3(n.x, n.y, 0.0)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


func _wall(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


## The white incoming beam, as a multi_tube between two XY points (z=0 plane).
func _build_white_beam(parent: Node3D, from2: Vector2, to2: Vector2) -> void:
	var from3 := Vector3(from2.x, from2.y, 0.0)
	var to3 := Vector3(to2.x, to2.y, 0.0)
	var mesh: Mesh = MorphoPrimitive.multi_tube([from3, to3],
		[BEAM_RADIUS * 1.25, BEAM_RADIUS * 1.25], BEAM_SIDES)
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "WhiteBeam"
	mi.mesh = mesh
	mi.material_override = _mat_white
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_mesh_count += 1
	_beam_count += 1


## Build the dispersed spectrum: trace every wavelength, draw its glass segment +
## its exiting beam to the screen plane, batch all spectral beams into ONE
## ArrayMesh per wavelength-coloured material, and place a glowing patch where
## each colour lands on the screen.
func _build_spectrum(parent: Node3D, entry_point: Vector2, dir_in: Vector2) -> void:
	# The screen is a vertical plane at a fixed X to the +X side of the prism.
	var screen_x: float = _base_right.x + SCREEN_DISTANCE

	var landings: Array[Vector2] = []           # where each colour hits the screen (XY)
	var colours: Array[Color] = []

	for i: int in range(WAVELENGTH_SAMPLES):
		var t: float = float(i) / float(WAVELENGTH_SAMPLES - 1)
		# Sample red→violet.
		var lambda_nm: float = lerpf(LAMBDA_RED_NM, LAMBDA_VIOLET_NM, t)
		var rgb: Color = _wavelength_to_rgb(lambda_nm)
		var mat: StandardMaterial3D = _spectral_material(i, rgb)

		var trace: Dictionary = _trace_ray(lambda_nm, entry_point, dir_in)
		if not bool(trace.get("ok", false)):
			continue
		var hit_exit: Vector2 = trace["hit_exit"]
		var dir_out: Vector2 = trace["dir_out"]

		# Extend the exit ray to the screen plane (x = screen_x).
		var landing: Vector2 = _extend_to_x(hit_exit, dir_out, screen_x)

		# Segment A: inside the glass (entry_point → hit_exit) — faint, tinted.
		# Segment B: the exiting coloured beam (hit_exit → landing) — bright.
		# Both baked into one per-colour batched mesh.
		_build_spectral_beam(parent, entry_point, hit_exit, landing, mat, i)

		landings.append(landing)
		colours.append(rgb)

	# Screen + the rainbow band of patches where the fan lands.
	_build_screen(parent, screen_x, landings)
	_build_patches(parent, screen_x, landings, colours)


## Extend a ray from point p along unit dir d until x == target_x. If the ray is
## near-parallel to X, just march a fixed distance so we still get a segment.
func _extend_to_x(p: Vector2, d: Vector2, target_x: float) -> Vector2:
	if absf(d.x) < 0.0001:
		return p + d * SCREEN_DISTANCE
	var t: float = (target_x - p.x) / d.x
	if t <= 0.0:
		t = SCREEN_DISTANCE
	return p + d * t


## One wavelength's beam, batched into a single ArrayMesh: the in-glass segment
## (thin) plus the exit beam (full). Two multi_tube surfaces Variant-coerced into
## one SurfaceTool so the whole colour is a single draw.
func _build_spectral_beam(parent: Node3D, entry2: Vector2, exit2: Vector2,
		land2: Vector2, mat: StandardMaterial3D, idx: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var entry3 := Vector3(entry2.x, entry2.y, 0.0)
	var exit3 := Vector3(exit2.x, exit2.y, 0.0)
	var land3 := Vector3(land2.x, land2.y, 0.0)

	# In-glass segment — thinner, so the white beam still reads as the source and
	# the colours separate visibly only AFTER the exit face.
	var glass_seg: Mesh = MorphoPrimitive.multi_tube([entry3, exit3],
		[BEAM_RADIUS * 0.55, BEAM_RADIUS * 0.7], BEAM_SIDES)
	if glass_seg != null:
		st.append_from(glass_seg, 0, Transform3D.IDENTITY)

	# Exit beam — full radius, the visible spectral ray fanning to the screen. A
	# tiny seeded shimmer on the radius keeps the fan from looking mechanical.
	var shimmer: float = 1.0 + _rng.randf_range(-0.06, 0.06)
	var exit_seg: Mesh = MorphoPrimitive.multi_tube([exit3, land3],
		[BEAM_RADIUS * 0.85 * shimmer, BEAM_RADIUS * 1.05 * shimmer], BEAM_SIDES)
	if exit_seg != null:
		st.append_from(exit_seg, 0, Transform3D.IDENTITY)

	var mesh: ArrayMesh = st.commit()
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "SpectralBeam_%d" % idx
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_mesh_count += 1
	_beam_count += 1


## The dark screen panel where the fan lands — an extruded quad (a thin slab) in
## the YZ-ish plane at x = screen_x, sized to comfortably contain the landings.
func _build_screen(parent: Node3D, screen_x: float, landings: Array[Vector2]) -> void:
	# Vertical extent from the landings, padded.
	var y_min: float = 999.0
	var y_max: float = -999.0
	for p: Vector2 in landings:
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
	if landings.is_empty():
		y_min = -0.4
		y_max = 0.4
	var pad: float = 0.35
	var cy: float = (y_min + y_max) * 0.5
	var half_h: float = maxf((y_max - y_min) * 0.5 + pad, 0.5)
	var half_d: float = PRISM_DEPTH * 0.5 + 0.18      # depth (Z) to frame the beams
	var thick: float = 0.04

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Build a thin box centred at (screen_x, cy, 0): faces +X toward the prism.
	var c := Vector3(screen_x, cy, 0.0)
	var ax := Vector3(thick, 0, 0)        # half-extent X (thin)
	var ay := Vector3(0, half_h, 0)       # half-extent Y
	var az := Vector3(0, 0, half_d)       # half-extent Z
	_box(st, c, ax, ay, az)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "Screen"
	mi.mesh = mesh
	mi.material_override = _mat_screen
	parent.add_child(mi)
	_mesh_count += 1


## The rainbow band: a glowing patch at each landing point, just in front of the
## screen (toward -X), coloured by its wavelength. Each patch is a small flat box
## so together they read as a row of spectral swatches.
func _build_patches(parent: Node3D, screen_x: float, landings: Array[Vector2],
		colours: Array[Color]) -> void:
	if landings.is_empty():
		return
	# Patch sized to slightly overlap its neighbours into a continuous band.
	var gap: float = 0.18
	if landings.size() > 1:
		gap = absf((landings[landings.size() - 1].y - landings[0].y)) / float(landings.size() - 1)
	var half_h: float = maxf(gap * 0.62, 0.03)
	var half_w: float = 0.03                         # along X (thin slab on the screen)
	var half_d: float = 0.05                         # along Z
	var patch_x: float = screen_x - 0.05             # sit just in front of the screen

	for i: int in range(landings.size()):
		var p: Vector2 = landings[i]
		var rgb: Color = colours[i]
		var mat: StandardMaterial3D = _spectral_material(i, rgb)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var c := Vector3(patch_x, p.y, 0.0)
		_box(st, c, Vector3(half_w, 0, 0), Vector3(0, half_h, 0), Vector3(0, 0, half_d))
		st.generate_normals()
		var mesh: ArrayMesh = st.commit()
		var mi := MeshInstance3D.new()
		mi.name = "Patch_%d" % i
		mi.mesh = mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		_mesh_count += 1
		_patch_count += 1


## Large dark backdrop slab behind the whole bench (-Z and low) so the spectral
## glow reads. An extruded quad standing in the XY plane, pushed back in Z.
func _build_backdrop(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3(PRISM_SIDE * 0.5, 0.0, -PRISM_DEPTH * 0.5 - 0.5)
	_box(st, c, Vector3(2.0, 0, 0), Vector3(1.4, 0, 0).rotated(Vector3(0, 0, 1), PI * 0.5),
		Vector3(0, 0, 0.04))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Backdrop"
	mi.mesh = mesh
	mi.material_override = _mat_backdrop
	parent.add_child(mi)
	_mesh_count += 1


## Emit an axis-frame box (centre c, three half-extent vectors ax/ay/az) into a
## SurfaceTool. 12 triangles, outward-facing. Shared by screen/patches/backdrop.
func _box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3) -> void:
	var p000: Vector3 = c - ax - ay - az
	var p100: Vector3 = c + ax - ay - az
	var p110: Vector3 = c + ax + ay - az
	var p010: Vector3 = c - ax + ay - az
	var p001: Vector3 = c - ax - ay + az
	var p101: Vector3 = c + ax - ay + az
	var p111: Vector3 = c + ax + ay + az
	var p011: Vector3 = c - ax + ay + az
	var nx: Vector3 = ax.normalized()
	var ny: Vector3 = ay.normalized()
	var nz: Vector3 = az.normalized()
	_quad(st, p000, p010, p110, p100, -nz)
	_quad(st, p001, p101, p111, p011, nz)
	_quad(st, p000, p100, p101, p001, -ny)
	_quad(st, p010, p011, p111, p110, ny)
	_quad(st, p000, p001, p011, p010, -nx)
	_quad(st, p100, p110, p111, p101, nx)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)
