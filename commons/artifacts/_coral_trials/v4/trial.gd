# trial.gd — CoralTrialV4 — FAVIA / faviid coral (cerioid cup cluster)
#
# A boulder/cushion whose entire top surface is a packed mosaic of CUP
# CORALLITES — many round cups packed together (cerioid, sharing walls like a
# honeycomb), each a shallow bowl with RADIAL SEPTA inside and a glowing
# fluorescent mouth at the centre. The signature is the CLUSTER of glowing
# mouths — a meadow of radial cups across the dome.
#
# Non-primitive: the dome and every cup bowl are built with
# MorphoPrimitive.revolution(); septa are Basis-oriented thin boxes fanning to
# each cup centre; mouths are small unshaded glowing spheres. One cup is built
# by _build_cup() and instanced many times at packed positions, each oriented
# to the dome surface normal via a Basis (no look_at). Deterministic from seed.

extends Node3D

class_name CoralTrialV4

# ── Tunables ─────────────────────────────────────────────────────────────
const SEED: int = 4242
const COMPLEXITY: float = 1.0           # scales corallite count
const DOME_RADIUS: float = 1.05         # planar radius of the cushion
const DOME_HEIGHT: float = 0.68         # rise of the dome from base to crown
const DOME_SEGMENTS: int = 48           # revolution segments for base dome
const CUP_RINGS: int = 5                # profile rings per cup bowl
const TILT_DEGREES: float = 12.0        # tilt cluster toward +X/+Z camera

# ── Materials ────────────────────────────────────────────────────────────
var _mat_skeleton: StandardMaterial3D    # cup walls + septa (color_b — ivory)
var _mat_tissue: StandardMaterial3D      # living tissue lining cups (color_a)
var _mat_fluor: StandardMaterial3D       # glowing mouths (accent)

var _rng: RandomNumberGenerator
var _mesh_count: int = 0
var _corallite_count: int = 0
var _septa_total: int = 0


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED
	_build_materials()
	_build_coral()


func apply_grid_config(_c: Dictionary) -> void:
	pass


# ═══════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# SKELETON / cup walls + septa — pale calcite ivory.
	_mat_skeleton = StandardMaterial3D.new()
	_mat_skeleton.albedo_color = Color(0.90, 0.86, 0.78)
	_mat_skeleton.roughness = 0.7
	_mat_skeleton.metallic = 0.0
	_mat_skeleton.emission_enabled = true
	_mat_skeleton.emission = Color(0.90, 0.86, 0.78) * 0.4
	_mat_skeleton.emission_energy_multiplier = 0.10

	# TISSUE — living tissue lining the cups, warm coral.
	_mat_tissue = StandardMaterial3D.new()
	_mat_tissue.albedo_color = Color(0.95, 0.45, 0.35)
	_mat_tissue.roughness = 0.6
	_mat_tissue.metallic = 0.0
	_mat_tissue.subsurf_scatter_enabled = true
	_mat_tissue.subsurf_scatter_strength = 0.25
	_mat_tissue.emission_enabled = true
	_mat_tissue.emission = Color(0.95, 0.45, 0.35) * 0.5
	_mat_tissue.emission_energy_multiplier = 0.12

	# FLUORESCENCE — the glowing cup mouths (the signature meadow).
	_mat_fluor = StandardMaterial3D.new()
	_mat_fluor.albedo_color = Color(0.40, 1.00, 0.45)
	_mat_fluor.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_fluor.emission_enabled = true
	_mat_fluor.emission = Color(0.40, 1.00, 0.45)
	_mat_fluor.emission_energy_multiplier = 4.0


# ═══════════════════════════════════════════════════════════════
# DOME GEOMETRY — analytic height + normal so cups sit on the surface
# ═══════════════════════════════════════════════════════════════

## Dome height for a planar radius r in [0, DOME_RADIUS]: a smooth cosine
## cushion — flat-ish crown, falling to 0 at the rim.
func _dome_height(r: float) -> float:
	var rr: float = clampf(r / DOME_RADIUS, 0.0, 1.0)
	return DOME_HEIGHT * 0.5 * (cos(rr * PI) + 1.0)


## Outward surface normal of the dome at planar radius r, in the radial plane
## that contains the point. dy/dr of the cushion gives the slope; the normal is
## (-dy/dr along radial, 1 along up) normalized, rebuilt in 3D from the planar
## direction.
func _dome_normal(planar: Vector3) -> Vector3:
	var r: float = Vector2(planar.x, planar.z).length()
	if r < 0.0001:
		return Vector3.UP
	var rr: float = clampf(r / DOME_RADIUS, 0.0, 1.0)
	# d/dr of DOME_HEIGHT*0.5*(cos(pi*r/R)+1) = -DOME_HEIGHT*0.5*pi/R*sin(pi*r/R)
	var dydr: float = -DOME_HEIGHT * 0.5 * (PI / DOME_RADIUS) * sin(rr * PI)
	var radial_dir: Vector3 = Vector3(planar.x, 0.0, planar.z).normalized()
	# Surface tangent along radial is (radial_dir, dydr); normal is perpendicular
	# in that plane, tilted outward and up.
	var n: Vector3 = (Vector3.UP - radial_dir * dydr).normalized()
	return n


## Build an orthonormal Basis whose Y axis is `up_axis`. Used to orient each cup
## (and its septa) to the dome surface normal without look_at.
func _basis_from_up(up_axis: Vector3) -> Basis:
	var y: Vector3 = up_axis.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


# ═══════════════════════════════════════════════════════════════
# CORALLITE PACKING — jittered hex grid clipped to the dome disc
# ═══════════════════════════════════════════════════════════════

## Generate packed cup centres (planar Vector3, y=0) across the dome top using a
## jittered hexagonal lattice with relaxation-ish jitter, clipped to a disc
## slightly inside the rim. Returns Array[Vector3] of planar centres.
func _pack_centres(spacing: float) -> Array[Vector3]:
	var centres: Array[Vector3] = []
	var row_h: float = spacing * sqrt(3.0) * 0.5
	var max_r: float = DOME_RADIUS - spacing * 0.30     # cups cover out near the rim
	var rows: int = int(ceil((max_r * 2.0) / row_h)) + 2
	var cols: int = int(ceil((max_r * 2.0) / spacing)) + 2
	for ri: int in range(-rows, rows + 1):
		var z: float = float(ri) * row_h
		var x_offset: float = (spacing * 0.5) if (ri % 2 != 0) else 0.0
		for ci: int in range(-cols, cols + 1):
			var x: float = float(ci) * spacing + x_offset
			# Jitter so the packing reads organic, not gridded.
			var jx: float = _rng.randf_range(-spacing * 0.18, spacing * 0.18)
			var jz: float = _rng.randf_range(-spacing * 0.18, spacing * 0.18)
			var px: float = x + jx
			var pz: float = z + jz
			var r: float = Vector2(px, pz).length()
			if r > max_r:
				continue
			centres.append(Vector3(px, 0.0, pz))
	return centres


# ═══════════════════════════════════════════════════════════════
# ONE CUP — reusable sub-build (bowl + radial septa + glowing mouth)
# ═══════════════════════════════════════════════════════════════

## Build a single cup corallite at planar centre `centre`, sized `cup_r`, with
## `septa_n` radial septa. The cup sits on the dome oriented to the surface
## normal via a Basis. Adds three MeshInstance3D children (bowl, septa-batch,
## mouth) under `parent`. Returns the number of septa actually placed.
func _build_cup(parent: Node3D, centre: Vector3, cup_r: float, septa_n: int) -> int:
	var surf_y: float = _dome_height(Vector2(centre.x, centre.z).length())
	var surf_pos: Vector3 = Vector3(centre.x, surf_y, centre.z)
	var normal: Vector3 = _dome_normal(centre)
	var basis: Basis = _basis_from_up(normal)

	var cup_depth: float = cup_r * 0.58
	var wall_h: float = cup_r * 0.42

	# ── Bowl: revolution of a cup profile (rim up, depression in middle). ──
	# Profile (radius, height), bottom→top so it is a true open cup: a deep
	# floor at the axis, walls climbing to a thin raised rim crest (the shared
	# calcite wall), then a short outer flank dropping back to the dome seat.
	var bowl_profile: Array[Vector2] = [
		Vector2(0.0, -cup_depth),                # floor centre (deepest)
		Vector2(cup_r * 0.28, -cup_depth * 0.86),
		Vector2(cup_r * 0.55, -cup_depth * 0.52),
		Vector2(cup_r * 0.80, -cup_depth * 0.05),# inner wall climbing past seat
		Vector2(cup_r * 0.96, wall_h),           # rim crest (shared wall, thin)
		Vector2(cup_r * 1.02, wall_h * 0.62),    # outer flank
		Vector2(cup_r * 0.98, 0.0),              # back down to dome seat
	]
	var bowl_mesh: Mesh = MorphoPrimitive.revolution(bowl_profile, 18)
	var bowl_mi := MeshInstance3D.new()
	bowl_mi.mesh = bowl_mesh
	bowl_mi.material_override = _mat_tissue
	bowl_mi.transform = Transform3D(basis, surf_pos)
	parent.add_child(bowl_mi)
	_mesh_count += 1

	# ── Radial septa: thin Basis-oriented boxes fanning to the centre. ──
	# Each septum is a flat wall standing radially inside the cup, from near the
	# wall toward (not quite reaching) the centre, ivory skeleton material. They
	# are batched into one SurfaceTool mesh for cheapness, all in cup-local
	# space then placed by the cup transform.
	var septa_mesh: ArrayMesh = _build_septa_mesh(cup_r, cup_depth, wall_h, septa_n)
	if septa_mesh != null:
		var septa_mi := MeshInstance3D.new()
		septa_mi.mesh = septa_mesh
		septa_mi.material_override = _mat_skeleton
		septa_mi.transform = Transform3D(basis, surf_pos)
		parent.add_child(septa_mi)
		_mesh_count += 1

	# ── Glowing fluorescent mouth at the centre. ──
	var mouth_r: float = cup_r * 0.24
	var mouth_mesh: Mesh = MorphoPrimitive.sphere(mouth_r, 10, 6)
	var mouth_mi := MeshInstance3D.new()
	mouth_mi.mesh = mouth_mesh
	mouth_mi.material_override = _mat_fluor
	# Sit the mouth just above the bowl floor, on the cup axis, slightly squashed
	# so it reads as a glowing oral disc rather than a full ball.
	var mouth_local: Vector3 = Vector3(0.0, -cup_depth * 0.40, 0.0)
	var squash := Basis().scaled(Vector3(1.0, 0.6, 1.0))
	mouth_mi.transform = Transform3D(basis * squash, surf_pos + basis * mouth_local)
	parent.add_child(mouth_mi)
	_mesh_count += 1

	return septa_n


## Build all radial septa for one cup as a single batched ArrayMesh in cup-local
## space (Y = cup axis). Each septum is a thin vertical wall (a box) rotated
## about the cup axis to its angular slot — oriented via Basis, no look_at.
func _build_septa_mesh(cup_r: float, cup_depth: float, wall_h: float, septa_n: int) -> ArrayMesh:
	if septa_n <= 0:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var inner_r: float = cup_r * 0.12          # stop short of the mouth
	var outer_r: float = cup_r * 0.88          # reach to the inner wall
	var sep_len: float = outer_r - inner_r
	var sep_thick: float = cup_r * 0.045       # thin wall
	var sep_height: float = cup_depth * 0.62   # rises from floor toward rim

	for si: int in range(septa_n):
		var ang: float = TAU * float(si) / float(septa_n)
		# Septum frame: X = radial (length), Y = up (cup axis), Z = thickness.
		var radial: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var thick_dir: Vector3 = Vector3(-sin(ang), 0.0, cos(ang))
		var up_dir: Vector3 = Vector3.UP
		var mid_r: float = (inner_r + outer_r) * 0.5
		# Floor height follows the bowl: deeper near centre, shallower at wall.
		var floor_y: float = -cup_depth * 0.72
		var centre_pos: Vector3 = radial * mid_r + up_dir * (floor_y + sep_height * 0.5)
		_emit_box(st, centre_pos, radial, up_dir, thick_dir,
			sep_len * 0.5, sep_height * 0.5, sep_thick * 0.5)

	st.generate_normals()
	return st.commit()


## Emit one axis-aligned-in-local-frame box into a SurfaceTool. The box is
## centred at `c`, with half-extents (hx,hy,hz) along the orthonormal axes
## (ax, ay, az). 12 triangles, outward-facing.
func _emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
		hx: float, hy: float, hz: float) -> void:
	var ex: Vector3 = ax * hx
	var ey: Vector3 = ay * hy
	var ez: Vector3 = az * hz
	# 8 corners.
	var p000: Vector3 = c - ex - ey - ez
	var p100: Vector3 = c + ex - ey - ez
	var p110: Vector3 = c + ex + ey - ez
	var p010: Vector3 = c - ex + ey - ez
	var p001: Vector3 = c - ex - ey + ez
	var p101: Vector3 = c + ex - ey + ez
	var p111: Vector3 = c + ex + ey + ez
	var p011: Vector3 = c - ex + ey + ez
	# 6 faces (two tris each), CCW outward.
	_quad(st, p000, p010, p110, p100, -az)   # -Z
	_quad(st, p001, p101, p111, p011, az)    # +Z
	_quad(st, p000, p100, p101, p001, -ay)   # -Y
	_quad(st, p010, p011, p111, p110, ay)    # +Y
	_quad(st, p000, p001, p011, p010, -ax)   # -X
	_quad(st, p100, p110, p111, p101, ax)    # +X


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


# ═══════════════════════════════════════════════════════════════
# ASSEMBLY
# ═══════════════════════════════════════════════════════════════

func _build_coral() -> void:
	# Keep the boulder upright; the capture camera already looks down from
	# +X/+Z. A small tilt toward that camera tips the packed mouths into view
	# without collapsing the dome into a flap.
	var tilt := Basis()
	tilt = tilt.rotated(Vector3(1.0, 0.0, -1.0).normalized(), deg_to_rad(TILT_DEGREES))
	var colony := Node3D.new()
	colony.name = "Colony"
	colony.basis = tilt
	add_child(colony)

	_build_base_dome(colony)

	# Corallite spacing scales with complexity → ~30-50 cups across the dome.
	var spacing: float = lerpf(0.30, 0.205, clampf(COMPLEXITY, 0.0, 1.0))
	var centres: Array[Vector3] = _pack_centres(spacing)
	_corallite_count = centres.size()

	for centre: Vector3 in centres:
		# Seed-jittered per-cup size and septa count. cup_r ~ half the spacing
		# so neighbour rims nearly touch (cerioid — shared walls).
		var size_jit: float = _rng.randf_range(0.94, 1.06)
		var cup_r: float = spacing * 0.62 * size_jit
		var septa_n: int = 8 + (_rng.randi() % 9)          # 8..16 septa
		_septa_total += _build_cup(colony, centre, cup_r, septa_n)

	print("CoralTrialV4: corallites=%d meshes=%d septa_total=%d (seed=%d)" % [
		_corallite_count, _mesh_count, _septa_total, SEED])


## Low domed cushion/boulder — a revolution of a clean, monotone bottom→top
## profile: flat underside on y=0, a short rounded skirt up to the rim, then the
## analytic dome surface up to the crown. No profile fold (no jagged teeth).
func _build_base_dome(parent: Node3D) -> void:
	var profile: Array[Vector2] = []
	var base_y: float = -DOME_HEIGHT * 0.42       # underside sits below the rim
	# Underside disc: centre out to near the rim (so it caps the bottom).
	profile.append(Vector2(0.0, base_y))
	profile.append(Vector2(DOME_RADIUS * 0.70, base_y))
	# Rounded skirt: bulge out slightly then up to the rim.
	profile.append(Vector2(DOME_RADIUS * 1.00, base_y * 0.55))
	profile.append(Vector2(DOME_RADIUS * 1.02, base_y * 0.18))
	profile.append(Vector2(DOME_RADIUS * 1.00, 0.0))      # rim
	# Dome surface rim→crown (height rises, radius falls) — monotone in y.
	var samples: int = DOME_SEGMENTS
	for i: int in range(1, samples + 1):
		var r: float = DOME_RADIUS * float(samples - i) / float(samples)
		profile.append(Vector2(r, _dome_height(r)))

	var dome_mesh: Mesh = MorphoPrimitive.revolution(profile, DOME_SEGMENTS)
	var dome_mi := MeshInstance3D.new()
	dome_mi.name = "BaseDome"
	dome_mi.mesh = dome_mesh
	dome_mi.material_override = _mat_skeleton
	parent.add_child(dome_mi)
	_mesh_count += 1
