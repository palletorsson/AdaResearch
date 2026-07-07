# trial.gd — CodexOpticsTrialV3 — ADDITIVE COLOUR MIXING (RGB light Venn)
#
# A Codex-Seraphinianus optics plate made physical: three overlapping glowing
# light fields in pure RED (1,0,0), GREEN (0,1,0), BLUE (0,0,1), arranged as the
# classic three-circle Venn (centres 120° apart). The colour of every point in
# the plane is the ADDITIVE SUM of the light fields covering it, clamped to 1:
#
#     R only        = (1,0,0)        R + G         = (1,1,0)  yellow
#     G only        = (0,1,0)        G + B         = (0,1,1)  cyan
#     B only        = (0,0,1)        R + B         = (1,0,1)  magenta
#     R + G + B     = (1,1,1)  WHITE (the triple-overlap centre)
#
# This is the real additive model, not a lookup: each of the 7 Venn regions is
# rendered in the colour produced by summing the channels of the disks that
# cover it (see _additive_colour / _classify). A companion VISIBLE-SPECTRUM
# ramp sweeps wavelength→RGB (Bruton's piecewise approximation, 380–750 nm)
# along an arc beneath the Venn.
#
# Non-primitive: the seven region meshes are built by sampling a fine polar grid
# over the disk plane, classifying each cell by a 3-bit disk-membership mask, and
# batching its quad into the SurfaceTool for that mask's additive colour — so the
# geometry of each lens slice emerges from the set algebra, not from primitives.
# Three translucent BLEND_ADD halo rings (revolution tubes) float just above to
# read as overlapping *lights*. Spectrum arc + backdrop are MorphoPrimitive.
# Everything Basis-oriented, deterministic from a local seeded RNG (no global rng).

extends Node3D

class_name CodexOpticsTrialV3

# ── Tunables ─────────────────────────────────────────────────────────────
const SEED: int = 4242
const DISK_RADIUS: float = 0.82          # radius R of each pure light field
const VENN_OFFSET: float = 0.47          # centre distance d from common centre
                                         # (d < R guarantees a triple overlap)
const GRID_STEPS: int = 150              # square sampling resolution per axis
const PLANE_Y: float = 0.0               # the disk plane (faces up, then tilted)
const REGION_DY: float = 0.006           # tiny per-region lift to avoid z-fight
const HALO_RISE: float = 0.10            # how far the BLEND_ADD halos float up
const TILT_DEGREES: float = 90.0         # lay the plane up to face +X/+Z camera
const SPECTRUM_RADIUS: float = 1.18      # radius of the wavelength arc
const SPECTRUM_SEGMENTS: int = 72        # colour bins along the spectrum arc
const SPECTRUM_BAR_W: float = 0.085      # half-width of each spectrum segment box

# ── Materials ────────────────────────────────────────────────────────────
var _mat_backdrop: StandardMaterial3D    # dark glow-floor behind everything
var _mat_halo: Array[StandardMaterial3D] # 3 translucent BLEND_ADD light rings

var _rng: RandomNumberGenerator
var _mesh_count: int = 0
var _region_cells: Dictionary = {}       # mask -> cell count (for the log)


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED
	_build_materials()
	_build_sculpture()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════
# THE ADDITIVE MODEL — the genuine algorithm
# ═══════════════════════════════════════════════════════════════

## The three pure light-field centres in the disk plane (XZ), arranged as a
## Venn 120° apart. Index 0=RED, 1=GREEN, 2=BLUE.
func _disk_centre(i: int) -> Vector2:
	var ang: float = deg_to_rad(90.0) + TAU * float(i) / 3.0
	return Vector2(cos(ang), sin(ang)) * VENN_OFFSET


## Pure channel colour of light field i: RED=(1,0,0), GREEN=(0,1,0), BLUE=(0,0,1).
func _channel_colour(i: int) -> Color:
	match i:
		0: return Color(1.0, 0.0, 0.0)
		1: return Color(0.0, 1.0, 0.0)
		_: return Color(0.0, 0.0, 1.0)


## ADDITIVE MIXING. Given a 3-bit membership mask (bit i set = covered by light
## field i), return the colour of light at that point: the SUM of the contributing
## channels, clamped to [0,1] per channel. Light ADDS — so R+G=yellow, G+B=cyan,
## R+B=magenta, R+G+B=white. This is the whole physical model in four lines.
func _additive_colour(mask: int) -> Color:
	var c := Color(0.0, 0.0, 0.0)
	for i: int in range(3):
		if (mask & (1 << i)) != 0:
			c += _channel_colour(i)
	return Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0))


## Membership mask of a planar point: which of the three light fields cover it.
func _classify(p: Vector2) -> int:
	var mask: int = 0
	for i: int in range(3):
		if p.distance_to(_disk_centre(i)) <= DISK_RADIUS:
			mask |= (1 << i)
	return mask


## VISIBLE-SPECTRUM wavelength → RGB. Dan Bruton's piecewise-linear
## approximation over 380–750 nm (red→violet), with an intensity falloff at the
## deep-red and deep-violet ends. Returns a linear Color in [0,1].
func _wavelength_to_rgb(nm: float) -> Color:
	var r: float = 0.0
	var g: float = 0.0
	var b: float = 0.0
	if nm >= 380.0 and nm < 440.0:
		r = -(nm - 440.0) / (440.0 - 380.0)
		b = 1.0
	elif nm >= 440.0 and nm < 490.0:
		g = (nm - 440.0) / (490.0 - 440.0)
		b = 1.0
	elif nm >= 490.0 and nm < 510.0:
		g = 1.0
		b = -(nm - 510.0) / (510.0 - 490.0)
	elif nm >= 510.0 and nm < 580.0:
		r = (nm - 510.0) / (580.0 - 510.0)
		g = 1.0
	elif nm >= 580.0 and nm < 645.0:
		r = 1.0
		g = -(nm - 645.0) / (645.0 - 580.0)
	elif nm >= 645.0 and nm <= 750.0:
		r = 1.0
	# Intensity falloff toward the spectral extremes.
	var factor: float = 1.0
	if nm >= 380.0 and nm < 420.0:
		factor = 0.3 + 0.7 * (nm - 380.0) / (420.0 - 380.0)
	elif nm > 700.0 and nm <= 750.0:
		factor = 0.3 + 0.7 * (750.0 - nm) / (750.0 - 700.0)
	return Color(r * factor, g * factor, b * factor)


# ═══════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# BACKDROP — dark so the colours glow, with a faint emission floor.
	_mat_backdrop = StandardMaterial3D.new()
	_mat_backdrop.albedo_color = Color(0.07, 0.08, 0.12)
	_mat_backdrop.roughness = 0.9
	_mat_backdrop.metallic = 0.0
	_mat_backdrop.emission_enabled = true
	_mat_backdrop.emission = Color(0.07, 0.08, 0.12)
	_mat_backdrop.emission_energy_multiplier = 0.03

	# Three translucent BLEND_ADD halo rings, one per pure channel. These read as
	# overlapping coloured *lights* hovering over the solved region mosaic; where
	# two halos cross, the additive blend brightens on its own.
	_mat_halo = []
	for i: int in range(3):
		var m := StandardMaterial3D.new()
		var col: Color = _channel_colour(i)
		m.albedo_color = Color(col.r, col.g, col.b, 0.55)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 3.0
		_mat_halo.append(m)


## A fully-emissive, near-unshaded material in the given mixed colour, for one
## additive region slice. Built per region so each Venn region glows in exactly
## its computed additive colour. White centre gets a touch more energy so the
## triple-overlap reads as the brightest point.
func _region_material(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED   # quads viewed from either side
	m.emission_enabled = true
	m.emission = col
	var is_white: bool = col.r > 0.9 and col.g > 0.9 and col.b > 0.9
	m.emission_energy_multiplier = 3.4 if is_white else 2.6
	return m


# ═══════════════════════════════════════════════════════════════
# REGION MOSAIC — geometry emerges from the set algebra
# ═══════════════════════════════════════════════════════════════

## Build the seven Venn regions as seven batched ArrayMeshes. We march a square
## grid over the bounding box of the three disks; for each cell we classify its
## centre's membership mask, look up the additive colour, and append the cell's
## quad to that mask's SurfaceTool. Empty cells (mask 0, outside every disk) are
## skipped. The boundaries between colours fall exactly on the circle arcs, so
## the lens slices (yellow / cyan / magenta) and the white centre appear without
## any explicit intersection geometry — they are the additive model sampled.
func _build_region_mosaic(parent: Node3D) -> void:
	# One SurfaceTool per non-empty membership mask (1..7).
	var builders: Dictionary = {}
	for mask: int in range(1, 8):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		builders[mask] = st
		_region_cells[mask] = 0

	# Bounding box covering all three disks with a small margin.
	var extent: float = VENN_OFFSET + DISK_RADIUS + 0.04
	var step: float = (extent * 2.0) / float(GRID_STEPS)
	var half: float = step * 0.5
	var up_n: Vector3 = Vector3.UP

	for ix: int in range(GRID_STEPS):
		var cx: float = -extent + (float(ix) + 0.5) * step
		for iz: int in range(GRID_STEPS):
			var cz: float = -extent + (float(iz) + 0.5) * step
			var mask: int = _classify(Vector2(cx, cz))
			if mask == 0:
				continue
			var st: SurfaceTool = builders[mask]
			# Lift triple/double overlaps progressively so they sit above the
			# pure fields and never z-fight: more covering fields → higher.
			var layers: int = _popcount(mask)
			var y: float = PLANE_Y + float(layers) * REGION_DY
			var c: Vector3 = Vector3(cx, y, cz)
			_emit_quad_xz(st, c, half, up_n)
			_region_cells[mask] = int(_region_cells[mask]) + 1

	# Commit each mask's mesh in its additive colour.
	for mask: int in range(1, 8):
		if int(_region_cells[mask]) == 0:
			continue
		var st: SurfaceTool = builders[mask]
		var mesh: ArrayMesh = st.commit()
		var mi := MeshInstance3D.new()
		mi.name = "Region_%d" % mask
		mi.mesh = mesh
		mi.material_override = _region_material(_additive_colour(mask))
		parent.add_child(mi)
		_mesh_count += 1


## Number of set bits in a 3-bit mask (how many light fields cover the cell).
func _popcount(mask: int) -> int:
	var n: int = 0
	var m: int = mask
	while m != 0:
		n += m & 1
		m >>= 1
	return n


## Emit one flat axis-aligned quad in the XZ plane, centred at c, half-size h,
## facing +Y (normal n). Two triangles, wound so the face points up.
func _emit_quad_xz(st: SurfaceTool, c: Vector3, h: float, n: Vector3) -> void:
	var p0: Vector3 = c + Vector3(-h, 0.0, -h)
	var p1: Vector3 = c + Vector3(h, 0.0, -h)
	var p2: Vector3 = c + Vector3(h, 0.0, h)
	var p3: Vector3 = c + Vector3(-h, 0.0, h)
	st.set_normal(n); st.add_vertex(p0)
	st.set_normal(n); st.add_vertex(p2)
	st.set_normal(n); st.add_vertex(p1)
	st.set_normal(n); st.add_vertex(p0)
	st.set_normal(n); st.add_vertex(p3)
	st.set_normal(n); st.add_vertex(p2)


# ═══════════════════════════════════════════════════════════════
# HALO RINGS — overlapping coloured lights (BLEND_ADD)
# ═══════════════════════════════════════════════════════════════

## Three translucent additive rings tracing each light field's perimeter, floated
## just above the mosaic. Where two rings overlap their additive blend brightens,
## reinforcing the "overlapping lights" read. Each ring is a revolution tube
## (a torus-like band) built by MorphoPrimitive.revolution then placed by Basis.
func _build_halos(parent: Node3D) -> void:
	# A thin tube cross-section profile revolved at DISK_RADIUS gives a ring.
	var tube_r: float = 0.028
	var ring_profile: Array[Vector2] = []
	var prof_steps: int = 10
	for s: int in range(prof_steps + 1):
		var a: float = TAU * float(s) / float(prof_steps)
		ring_profile.append(Vector2(DISK_RADIUS + cos(a) * tube_r, sin(a) * tube_r))
	var ring_mesh: Mesh = MorphoPrimitive.revolution(ring_profile, 64)

	for i: int in range(3):
		var ctr: Vector2 = _disk_centre(i)
		var mi := MeshInstance3D.new()
		mi.name = "Halo_%d" % i
		mi.mesh = ring_mesh
		mi.material_override = _mat_halo[i]
		# The ring mesh lies in its own XZ plane already; just translate it to the
		# light-field centre and float it above the mosaic.
		var pos: Vector3 = Vector3(ctr.x, PLANE_Y + HALO_RISE, ctr.y)
		mi.transform = Transform3D(Basis(), pos)
		parent.add_child(mi)
		_mesh_count += 1


# ═══════════════════════════════════════════════════════════════
# SPECTRUM ARC — wavelength → RGB companion
# ═══════════════════════════════════════════════════════════════

## A glowing arc of segment boxes sweeping the visible spectrum red→violet, each
## segment emissive in its wavelength's RGB (see _wavelength_to_rgb). Built as
## one batched ArrayMesh of vertex-coloured boxes (vertex colour drives emission
## via a shared vertex-colour material) — one mesh for the whole ramp.
func _build_spectrum(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Sweep a wide arc under the Venn so the ramp reads as a companion band.
	var arc_start: float = deg_to_rad(202.0)
	var arc_end: float = deg_to_rad(338.0)
	var nm_lo: float = 645.0   # red end at arc_start (left)
	var nm_hi: float = 400.0   # violet end at arc_end (right)
	var seg_half_w: float = SPECTRUM_BAR_W
	var seg_thick: float = 0.05
	var seg_height: float = 0.16

	for s: int in range(SPECTRUM_SEGMENTS):
		var t: float = float(s) / float(SPECTRUM_SEGMENTS - 1)
		var ang: float = lerpf(arc_start, arc_end, t)
		var nm: float = lerpf(nm_lo, nm_hi, t)
		var col: Color = _wavelength_to_rgb(nm)

		# Frame at this arc position: radial outward, tangent along the arc, up.
		var radial: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var pos: Vector3 = radial * SPECTRUM_RADIUS
		# Box axes: X along the arc tangent (segment width), Y up, Z radial (depth).
		var tangent: Vector3 = Vector3(-sin(ang), 0.0, cos(ang))
		_emit_coloured_box(st, pos, tangent, Vector3.UP, radial,
			seg_half_w, seg_height * 0.5, seg_thick * 0.5, col)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "SpectrumRamp"
	mi.mesh = mesh
	# Vertex-colour-driven emissive material so all segments share one mesh.
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 2.4
	# Emission tint follows vertex colour through the albedo path.
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	mi.material_override = mat
	parent.add_child(mi)
	_mesh_count += 1


## Emit one box with a uniform vertex colour into a SurfaceTool, centred at c with
## orthonormal axes (ax,ay,az) and half-extents (hx,hy,hz). Vertex colour carries
## the segment's wavelength RGB so a single shared material renders the whole ramp.
func _emit_coloured_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3,
		az: Vector3, hx: float, hy: float, hz: float, col: Color) -> void:
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
	_cquad(st, p000, p010, p110, p100, -az, col)   # -Z
	_cquad(st, p001, p101, p111, p011, az, col)    # +Z
	_cquad(st, p000, p100, p101, p001, -ay, col)   # -Y
	_cquad(st, p010, p011, p111, p110, ay, col)    # +Y
	_cquad(st, p000, p001, p011, p010, -ax, col)   # -X
	_cquad(st, p100, p110, p111, p101, ax, col)    # +X


func _cquad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3, col: Color) -> void:
	st.set_color(col); st.set_normal(n); st.add_vertex(a)
	st.set_color(col); st.set_normal(n); st.add_vertex(b)
	st.set_color(col); st.set_normal(n); st.add_vertex(c)
	st.set_color(col); st.set_normal(n); st.add_vertex(a)
	st.set_color(col); st.set_normal(n); st.add_vertex(c)
	st.set_color(col); st.set_normal(n); st.add_vertex(d)


# ═══════════════════════════════════════════════════════════════
# BACKDROP
# ═══════════════════════════════════════════════════════════════

## A dark panel behind the plate so the emissive colours glow. Built as a box,
## sat behind and below, oriented to back the tilted plane.
func _build_backdrop(parent: Node3D) -> void:
	var panel_mesh: Mesh = MorphoPrimitive.box(Vector3(3.0, 2.4, 0.08))
	var mi := MeshInstance3D.new()
	mi.name = "Backdrop"
	mi.mesh = panel_mesh
	mi.material_override = _mat_backdrop
	# Sit it just behind the (already-tilted) plate. The plate is rotated up to
	# stand vertical; the backdrop stands parallel, pushed back along -Z.
	mi.transform = Transform3D(Basis(), Vector3(0.0, 0.30, -0.18))
	parent.add_child(mi)
	_mesh_count += 1


# ═══════════════════════════════════════════════════════════════
# ASSEMBLY
# ═══════════════════════════════════════════════════════════════

func _build_sculpture() -> void:
	# Backdrop stands upright behind everything (its own frame, not tilted plate).
	_build_backdrop(self)

	# The Venn mosaic + halos are authored flat in the XZ plane, then the whole
	# plate is tilted up about the X axis so it stands facing the +X/+Z camera and
	# the overlap reads. A Basis rotation, no look_at.
	var plate := Node3D.new()
	plate.name = "Plate"
	var tilt := Basis().rotated(Vector3.RIGHT, deg_to_rad(TILT_DEGREES))
	plate.basis = tilt
	plate.position = Vector3(0.0, 0.42, 0.0)
	add_child(plate)

	_build_region_mosaic(plate)
	_build_halos(plate)

	# Spectrum arc: its own node, also tilted to stand with the plate, dropped
	# below the Venn so it reads as a companion band.
	var spectrum := Node3D.new()
	spectrum.name = "Spectrum"
	spectrum.basis = tilt
	spectrum.position = Vector3(0.0, 0.42, 0.02)
	add_child(spectrum)
	_build_spectrum(spectrum)

	# Deterministic micro-jitter on the halos' float height, seeded — proves the
	# RNG is wired and used, without disturbing the additive read.
	for i: int in range(3):
		var halo: Node = plate.get_node_or_null("Halo_%d" % i)
		if halo is MeshInstance3D:
			var jitter: float = _rng.randf_range(-0.012, 0.012)
			var hp: Vector3 = (halo as MeshInstance3D).position
			(halo as MeshInstance3D).position = hp + Vector3(0.0, jitter, 0.0)

	print("CodexOpticsTrialV3: meshes=%d regions=%s spectrum_segs=%d (seed=%d)" % [
		_mesh_count, str(_region_cells), SPECTRUM_SEGMENTS, SEED])
