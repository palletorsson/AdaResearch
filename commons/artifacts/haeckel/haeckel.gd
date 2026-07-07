extends Node3D
class_name HaeckelForm

# @identity
# essence: a single DNA-driven HAECKEL SPECIMEN — a microorganism grown as an OPEN
#   LATTICE, after Ernst Haeckel's Kunstformen der Natur. Where most artifacts stack
#   solid primitives, HaeckelForm GROWS each body as a perforated, see-through skeleton
#   of silica struts and glowing protoplasm: edges of a geodesic sphere, meridian+ring
#   struts over a surface of revolution, swept colony stems, radial ribs of a frustule.
#   Depending on its `mode` DNA it becomes one of four genera whose form is TOPOLOGY,
#   not mass: radiolarian (a hollow geodesic LATTICE sphere — subdivided-icosahedron
#   edges as ivory struts + node spheres at every vertex, long tapering radial spines
#   bursting outward through the holes, a faint translucent membrane, a warm-gold
#   nucleus glowing through the open shell), cyrtoid (a chambered LATTICE bell — a
#   gourd/amphora surface of revolution dressed with meridian + ring struts and node
#   spheres over 2-4 constriction chambers, an apical horn, basal spines splaying from
#   the wide mouth, a nucleus suspended in the widest chamber), siphonophore (a hanging
#   COLONY cluster — one swept S-curve stem hung with a varied series of translucent
#   swimming bells, glowing gonophore sacs, and dangling bezier tentacle clusters with
#   luminous tips and tiny side tentilla), and diatom (a geometric radial PERFORATED
#   disc/star — concentric ring struts + radial ribs framing open areolae cells with
#   strict m-fold symmetry, a denser centre rosette around a glowing boss, a spiky star
#   rim, a slight biconvex dome, all tilted to face the viewer). It is identity confessed
#   as the shape of its holes — the body as a grammar of perforation rather than a solid.
# desire: it wants the SKELETON to read as fine pale silica (an emission FLOOR so the
#   thin struts never collapse to black against the dark capture), the MEMBRANE to read
#   as a faint translucent protoplasm gel (alpha, two-sided, so the nucleus shows
#   through the holes), and the NUCLEUS / glowing bodies to BURN bioluminescent. Above
#   all it wants the LATTICE to stay OPEN — the triangular faces, the areolae cells, the
#   gaps between meridian and ring left empty so the form is seen-through, not sealed.
# critical_parameter: mode + seed + the colour triad (color_a MEMBRANE / color_b
#   SKELETON / accent NUCLEUS) + complexity. mode picks the lattice lineage; seed varies
#   the individual deterministically (a local seeded RNG, no global randf/randi ever);
#   complexity scales subdivision / chamber count / colony unit count / ring count.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and
#   branches on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config
#   metas, clears children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a CABINET OF KUNSTFORMEN — four ways a body can be
#   grown as a perforated lattice rather than a solid. Switch one mode and the room's
#   idea of "what a body is" shifts from mass to topology; reseed and the genus persists
#   while its individual varies.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each
#   carrying its trial's bespoke lattice machinery (geodesic edges, revolution-surface
#   struts, swept colony stem, m-fold ribs) [present]; skeleton / membrane / glow
#   materials driven by the colour triad [present]; struts batched into one ArrayMesh per
#   lattice so the AABB capture frames the open form [present].
# relationships: kin to biomech_ng (same genome shape + conventions; biomech_ng grows
#   solid surfaces, HaeckelForm grows open lattices); built on the nature_system
#   morphology engine it borrows from (MorphoPrimitive / MorphoSweep); cousin to any
#   mode-switchboard of one genome.
# truth: a body was never only a solid — Haeckel saw that the radiolaria, the diatoms,
#   the siphonophores are identities held by their HOLES, grammars of perforated and
#   clustered form. HaeckelForm holds four such organisms in one genome where the body
#   is GROWN as a lattice — a sphere of edges, a bell of struts, a colony of kin units,
#   a star of ribs — and lets a single parameter choose which perforated grammar the
#   viewer is invited to read. The silica must stay fine, the membrane faint, the
#   nucleus must glow, and above all the lattice must stay OPEN.

## A multi-mode generative Haeckel microorganism grown as an OPEN LATTICE.
##
## Built procedurally from DNA exports, after Ernst Haeckel's Kunstformen der Natur.
## The `mode` export selects one of FOUR latticed genera, each ported faithfully from
## a verified trial:
## radiolarian (a geodesic LATTICE sphere — subdivided-icosahedron edges as struts +
## node spheres + radial spines + translucent membrane + glowing nucleus), cyrtoid (a
## chambered LATTICE bell — meridian/ring struts over a gourd revolution surface +
## apical horn + basal spines + nucleus), siphonophore (a hanging COLONY cluster — a
## swept stem hung with translucent bells, glowing bodies, and bezier tentacle
## clusters), diatom (a radial PERFORATED disc/star — ring + rib struts framing open
## areolae with m-fold symmetry + centre rosette + spiky star rim + biconvex dome).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad
## (color_a MEMBRANE / color_b SKELETON / accent NUCLEUS) re-registers the same anatomy
## between palettes. Shared lattice + material helpers live under the `_hk_` prefix; the
## bespoke geodesic / strut-batching machinery from the v1 trial is carried into them so
## the lattice batches into one ArrayMesh per surface and the capture frames the open
## form. Surface generation reuses the morphology toolkit statics (MorphoPrimitive,
## MorphoSweep) for tubes, sweeps, revolutions and beziers.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## radiolarian | cyrtoid | siphonophore | diatom | plate
@export var mode: String = "radiolarian"
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 0
## Detail / element count. Scales lattice subdivision (radiolarian), chamber count
## (cyrtoid), colony unit count (siphonophore), and ring count (diatom).
@export var complexity: int = 6
## Overall height in meters (nominal full height of the organism).
@export var sculpt_height: float = 1.6
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## MEMBRANE / protoplasm — translucent inner skin shown through the lattice holes.
@export var color_a: Color = Color(0.55, 0.85, 0.80)
## SKELETON / silica lattice — struts, nodes, spines, ribs, horns.
@export var color_b: Color = Color(0.92, 0.88, 0.78)
## NUCLEUS / glow — the bioluminescent core / bodies / tips.
@export var accent: Color = Color(0.98, 0.80, 0.30)
## Silica / chitin, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.5
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k: Variant in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c: Node in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_mode"):
		mode = str(get_meta("config_mode")).to_lower().strip_edges()
	if has_meta("config_seed"):
		seed = int(str(get_meta("config_seed")))
	if has_meta("config_complexity"):
		complexity = int(str(get_meta("config_complexity")))
	if has_meta("config_sculpt_height"):
		sculpt_height = float(str(get_meta("config_sculpt_height")))
	if has_meta("config_sculpt_width"):
		sculpt_width = float(str(get_meta("config_sculpt_width")))
	if has_meta("config_color_a"):
		color_a = _parse_color(str(get_meta("config_color_a")), color_a)
	if has_meta("config_color_b"):
		color_b = _parse_color(str(get_meta("config_color_b")), color_b)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)
	if has_meta("config_metallic_amt"):
		metallic_amt = float(str(get_meta("config_metallic_amt")))
	if has_meta("config_rough_amt"):
		rough_amt = float(str(get_meta("config_rough_amt")))
	if has_meta("config_emissive"):
		emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


## Accepts an "r,g,b" / "r,g,b,a" string OR a colour name ("red", "cyan", …).
func _parse_color(raw: String, fallback: Color) -> Color:
	var s := raw.strip_edges()
	var parts := s.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	var named := Color(s.to_lower())
	if named != Color(0, 0, 0, 1) or s.to_lower() in ["black", "#000000", "000000"]:
		return named
	return fallback


# ── Build dispatch ─────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_rng.seed = seed
	match mode:
		"radiolarian":
			_build_radiolarian()
		"cyrtoid":
			_build_cyrtoid()
		"siphonophore":
			_build_siphonophore()
		"diatom":
			_build_diatom()
		"plate":
			_build_plate()
		_:
			# Unknown mode falls back to the radiolarian lattice.
			_build_radiolarian()


# ── Shared `_hk_` material helpers (the three trial materials, DNA-driven) ──────

## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _hk_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## SKELETON / silica (color_b family): pale ivory frustule struts, nodes, spines.
## Low metallic, mid roughness, with a faint emission FLOOR in its own tone so the
## fine struts read against the dark capture and never collapse to black.
func _hk_skeleton_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.5
	m.emission_energy_multiplier = _hk_glow_energy(0.12)
	return m


## MEMBRANE / protoplasm (color_a family): translucent gel — alpha-blended, two-sided,
## faint own-tone emission so the inner skin reads as living tissue and the nucleus
## glows through it. `alpha` overrides the default low translucency.
func _hk_membrane_mat(c: Color = color_a, alpha: float = 0.18) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, clampf(alpha, 0.0, 1.0))
	m.roughness = 0.45
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _hk_glow_energy(0.10)
	m.rim_enabled = true
	m.rim = 0.5
	m.rim_tint = 0.4
	return m


## NUCLEUS / glow (accent family): saturated near-unshaded bioluminescence for cores,
## bodies, tips. `energy` ~2-4; `alpha` < 1.0 turns on alpha transparency (halos).
func _hk_glow_mat(c: Color = accent, energy: float = 3.5, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _hk_glow_energy(energy)
	return m


# ── Shared `_hk_` geometry helpers ─────────────────────────────────────

## A stable orthonormal Basis whose Y axis is `forward`. X and Z span the
## perpendicular plane. Avoids the degenerate case when forward ~ UP. (From v1.)
func _hk_basis_from_forward(forward: Vector3) -> Basis:
	var f: Vector3 = forward.normalized()
	var right: Vector3
	if absf(f.dot(Vector3.UP)) < 0.99:
		right = f.cross(Vector3.UP).normalized()
	else:
		right = f.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(f).normalized()
	return Basis(right, f, up)


## A Basis with +Y aligned to `up`, stable near-vertical and near-horizontal.
func _hk_basis_from_up(up: Vector3) -> Basis:
	var y: Vector3 = up.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(y.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _hk_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
		xform: Transform3D = Transform3D.IDENTITY, node_name: String = "Part") -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xform
	parent.add_child(mi)
	return mi


## Append one strut (capless oriented cylinder) between two points to `st`. Oriented
## by a Basis built from the edge direction — NEVER look_at. Batched into one
## SurfaceTool ArrayMesh per lattice. (Carried from the v1 trial.)
func _hk_strut(st: SurfaceTool, a: Vector3, b: Vector3, radius: float, sides: int) -> void:
	var axis: Vector3 = b - a
	var length: float = axis.length()
	if length < 0.0001:
		return
	var forward: Vector3 = axis / length
	var basis: Basis = _hk_basis_from_forward(forward)
	var right: Vector3 = basis.x
	var up: Vector3 = basis.z
	for si: int in range(sides):
		var si_next: int = (si + 1) % sides
		var ang0: float = TAU * float(si) / float(sides)
		var ang1: float = TAU * float(si_next) / float(sides)
		var o0: Vector3 = (right * cos(ang0) + up * sin(ang0)) * radius
		var o1: Vector3 = (right * cos(ang1) + up * sin(ang1)) * radius
		var a0: Vector3 = a + o0
		var a1: Vector3 = a + o1
		var b0: Vector3 = b + o0
		var b1: Vector3 = b + o1
		st.add_vertex(a0); st.add_vertex(b0); st.add_vertex(a1)
		st.add_vertex(a1); st.add_vertex(b0); st.add_vertex(b1)


## Precompute a unit-sphere as a flat Array[Vector3] of triangle vertices (positions
## only). Reused by `_hk_append_sphere` to batch many small node spheres. (From v1.)
func _hk_unit_sphere_geometry(segments: int, rings: int) -> Array[Vector3]:
	var tris: Array[Vector3] = []
	for ri: int in range(rings):
		var phi0: float = PI * float(ri) / float(rings)
		var phi1: float = PI * float(ri + 1) / float(rings)
		for si: int in range(segments):
			var th0: float = TAU * float(si) / float(segments)
			var th1: float = TAU * float(si + 1) / float(segments)
			var p00: Vector3 = _hk_sphere_point(phi0, th0)
			var p01: Vector3 = _hk_sphere_point(phi0, th1)
			var p10: Vector3 = _hk_sphere_point(phi1, th0)
			var p11: Vector3 = _hk_sphere_point(phi1, th1)
			tris.append(p00); tris.append(p10); tris.append(p01)
			tris.append(p01); tris.append(p10); tris.append(p11)
	return tris


func _hk_sphere_point(phi: float, theta: float) -> Vector3:
	var s: float = sin(phi)
	return Vector3(s * cos(theta), cos(phi), s * sin(theta))


## Append a small sphere (from a unit template) at `center` scaled by `radius`.
func _hk_append_sphere(st: SurfaceTool, template: Array[Vector3], center: Vector3, radius: float) -> void:
	for p: Vector3 in template:
		st.add_vertex(center + p * radius)


## Build a geodesic sphere by subdividing an icosahedron `level` times and projecting
## every vertex to the unit sphere. Returns {verts: Array[Vector3] (unit length),
## edges: Array[Vector2i] (unique vertex-index pairs)} — the open lattice topology.
## (Carried verbatim from the v1 trial.)
func _hk_geodesic(level: int) -> Dictionary:
	var t: float = (1.0 + sqrt(5.0)) * 0.5
	var base_verts: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i: int in range(base_verts.size()):
		base_verts[i] = base_verts[i].normalized()

	var faces: Array[Vector3i] = [
		Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10), Vector3i(0, 10, 11),
		Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2), Vector3i(10, 7, 6), Vector3i(7, 1, 8),
		Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9),
		Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1)]

	var work_verts: Array[Vector3] = base_verts.duplicate()
	var midpoint_cache: Dictionary = {}

	var current_faces: Array[Vector3i] = faces
	for _s: int in range(level):
		var next_faces: Array[Vector3i] = []
		for f: Vector3i in current_faces:
			var a: int = _hk_midpoint_index(f.x, f.y, work_verts, midpoint_cache)
			var b: int = _hk_midpoint_index(f.y, f.z, work_verts, midpoint_cache)
			var c: int = _hk_midpoint_index(f.z, f.x, work_verts, midpoint_cache)
			next_faces.append(Vector3i(f.x, a, c))
			next_faces.append(Vector3i(f.y, b, a))
			next_faces.append(Vector3i(f.z, c, b))
			next_faces.append(Vector3i(a, b, c))
		current_faces = next_faces

	var out_verts: Array[Vector3] = []
	for v: Vector3 in work_verts:
		out_verts.append(v)

	var out_edges: Array[Vector2i] = []
	var seen: Dictionary = {}
	for f: Vector3i in current_faces:
		_hk_add_edge(f.x, f.y, seen, out_edges)
		_hk_add_edge(f.y, f.z, seen, out_edges)
		_hk_add_edge(f.z, f.x, seen, out_edges)

	return {"verts": out_verts, "edges": out_edges}


## Index of the (cached) midpoint of edge (i, j), projected to the unit sphere.
func _hk_midpoint_index(i: int, j: int, work_verts: Array[Vector3], cache: Dictionary) -> int:
	var lo: int = mini(i, j)
	var hi: int = maxi(i, j)
	var key: int = lo * 100000 + hi
	if cache.has(key):
		return cache[key] as int
	var mid: Vector3 = ((work_verts[i] + work_verts[j]) * 0.5).normalized()
	var idx: int = work_verts.size()
	work_verts.append(mid)
	cache[key] = idx
	return idx


func _hk_add_edge(i: int, j: int, seen: Dictionary, out_edges: Array[Vector2i]) -> void:
	var lo: int = mini(i, j)
	var hi: int = maxi(i, j)
	var key: int = lo * 100000 + hi
	if seen.has(key):
		return
	seen[key] = true
	out_edges.append(Vector2i(lo, hi))


## Compute the AABB of a node subtree IN `node`'s local space (for footing / centring
## the organism). Accumulates each MeshInstance3D's AABB through the chain of LOCAL
## transforms down from `node` — never touches global_transform, so it is independent
## of tree state and of any parent transform above `node`.
func _hk_subtree_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first: bool = true
	# Pair each node with the accumulated transform from `node` down to it.
	var stack: Array = [[node, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var current: Node = entry[0]
		var accum: Transform3D = entry[1]
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mi := current as MeshInstance3D
			var a: AABB = accum * mi.get_aabb()
			if first:
				total = a
				first = false
			else:
				total = total.merge(a)
		for child: Node in current.get_children():
			if child is Node3D:
				stack.append([child, accum * (child as Node3D).transform])
			else:
				stack.append([child, accum])
	return total


## Centre `body` horizontally at the origin so the AABB capture frames it. If `to_floor`
## the lowest point is dropped to y=0 (standing forms); otherwise the vertical centre is
## also moved to the origin (floating forms). `target_h` rescales the whole subtree to
## that height first (width_scale stretches the horizontal axes for span control).
func _hk_settle(body: Node3D, target_h: float = 0.0, width_scale: float = 1.0,
		to_floor: bool = false) -> void:
	if target_h > 0.0:
		var raw: AABB = _hk_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		var k: float = target_h / span_y
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _hk_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	var y_shift: float = -aabb.position.y if to_floor else -centre.y
	body.position += Vector3(-centre.x, y_shift, -centre.z)


## Centre `body` so a target ACROSS-SPAN (x/z) fills the frame, then centre all axes at
## the origin. Used by the diatom, which is sized by its width, not its height.
func _hk_settle_to_span(body: Node3D, target_span: float, height_scale: float = 1.0) -> void:
	if target_span > 0.0:
		var raw: AABB = _hk_subtree_aabb(body)
		var span_xz: float = maxf(maxf(raw.size.x, raw.size.z), 0.001)
		var k: float = target_span / span_xz
		body.scale = Vector3(k, k * height_scale, k)
	var aabb: AABB = _hk_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	body.position += Vector3(-centre.x, -centre.y, -centre.z)


# =============================================================================
# MODE: radiolarian — a hollow geodesic LATTICE sphere (trial v1)
# =============================================================================

const _RADI_SHELL_RADIUS: float = 0.85
const _RADI_STRUT_SIDES: int = 5


func _build_radiolarian() -> void:
	var rig := Node3D.new()
	rig.name = "Radiolarian"
	add_child(rig)
	_radiolarian_into(rig, _rng)
	# The radiolarian floats — centre on all axes, scale UNIFORMLY (it is a sphere;
	# width_scale is a horizontal stretch, so it must stay 1.0 or the shell goes oblate).
	_hk_settle(rig, maxf(sculpt_height, 0.4), 1.0, false)


## Build the radiolarian GEOMETRY under `parent` at its native size (shell_r 0.85),
## consuming the passed `rng` for all stochastic choices. No settle, no scale — pure
## local geometry, so the plate cluster can place + scale the returned rig itself.
func _radiolarian_into(parent: Node3D, rng: RandomNumberGenerator) -> Node3D:
	# Lattice subdivision scales with complexity (native 3 at complexity 6).
	var subdiv: int = clampi(1 + complexity / 3, 2, 4)
	var shell_r: float = _RADI_SHELL_RADIUS
	var strut_radius: float = shell_r * 0.015
	var node_radius: float = shell_r * 0.026
	# Spines scale with complexity (native 14 at complexity 6).
	var spine_count: int = clampi(8 + complexity, 10, 22)
	var spine_length: float = shell_r * 0.78
	var nucleus_radius: float = shell_r * 0.30

	var skeleton_mat := _hk_skeleton_mat(color_b)
	var membrane_mat := _hk_membrane_mat(color_a, 0.14)
	var nucleus_mat := _hk_glow_mat(accent, 3.5)

	# 1. Geodesic sphere — verts + unique edges (the lattice topology).
	var geo: Dictionary = _hk_geodesic(subdiv)
	var verts: Array[Vector3] = geo["verts"]
	var edges: Array[Vector2i] = geo["edges"]
	var shell_verts: Array[Vector3] = []
	for v: Vector3 in verts:
		shell_verts.append(v * shell_r)

	# 2. Struts — every unique edge as a thin oriented cylinder, batched into one
	#    ArrayMesh so the whole lattice is a single MeshInstance3D (the capture
	#    walks MeshInstance3D, so batch into ArrayMesh — not MultiMesh).
	var strut_st := SurfaceTool.new()
	strut_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for e: Vector2i in edges:
		_hk_strut(strut_st, shell_verts[e.x], shell_verts[e.y], strut_radius, _RADI_STRUT_SIDES)
	strut_st.generate_normals()
	_hk_add_mesh(parent, strut_st.commit(), skeleton_mat, Transform3D.IDENTITY, "LatticeStruts")

	# 3. Node spheres at each vertex (so the joints read), batched as one mesh.
	var node_st := SurfaceTool.new()
	node_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var node_template: Array[Vector3] = _hk_unit_sphere_geometry(6, 4)
	for v: Vector3 in shell_verts:
		_hk_append_sphere(node_st, node_template, v, node_radius)
	node_st.generate_normals()
	_hk_add_mesh(parent, node_st.commit(), skeleton_mat, Transform3D.IDENTITY, "LatticeNodes")

	# 4. Radial spines — a deterministic spread of lattice verts as directions;
	#    each spine a tapered multi_tube from inside the shell outward.
	var spine_dirs: Array[Vector3] = _radi_spine_directions(verts, spine_count, rng)
	var spine_root := Node3D.new()
	spine_root.name = "Spines"
	parent.add_child(spine_root)
	var spine_tip_st := SurfaceTool.new()
	spine_tip_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip_template: Array[Vector3] = _hk_unit_sphere_geometry(6, 4)
	for di: int in range(spine_dirs.size()):
		var dir: Vector3 = spine_dirs[di]
		var jitter: float = lerpf(0.85, 1.18, rng.randf())
		var length: float = spine_length * jitter
		var spine_mesh: Mesh = _radi_spine(dir, length, shell_r, strut_radius)
		_hk_add_mesh(spine_root, spine_mesh, skeleton_mat, Transform3D.IDENTITY, "Spine_%d" % di)
		var tip_pos: Vector3 = dir * (shell_r + length)
		_hk_append_sphere(spine_tip_st, tip_template, tip_pos, strut_radius * 1.4)
	spine_tip_st.generate_normals()
	_hk_add_mesh(parent, spine_tip_st.commit(), skeleton_mat, Transform3D.IDENTITY, "SpineTips")

	# 5. Translucent inner membrane (protoplasm) — slightly smaller sphere.
	_hk_add_mesh(parent, MorphoPrimitive.sphere(shell_r * 0.82, 32, 16), membrane_mat,
		Transform3D.IDENTITY, "Membrane")

	# 6. Glowing nucleus + a faint concentric halo at the centre.
	_hk_add_mesh(parent, MorphoPrimitive.sphere(nucleus_radius, 24, 12), nucleus_mat,
		Transform3D.IDENTITY, "Nucleus")
	var halo_mat := _hk_glow_mat(accent.lerp(Color(0.98, 0.84, 0.45), 0.4), 1.6, 0.22)
	_hk_add_mesh(parent, MorphoPrimitive.sphere(nucleus_radius * 1.55, 20, 10), halo_mat,
		Transform3D.IDENTITY, "NucleusHalo")
	return parent


## One tapered radial spine pointing along `dir`, from inside the shell out to
## (shell_r + length). Uses MorphoPrimitive.multi_tube. (From v1.)
func _radi_spine(dir: Vector3, length: float, shell_r: float, strut_radius: float) -> Mesh:
	var d: Vector3 = dir.normalized()
	var inner: float = shell_r * 0.55
	var positions: Array[Vector3] = [
		d * inner,
		d * (shell_r * 0.85),
		d * shell_r,
		d * (shell_r + length * 0.55),
		d * (shell_r + length)]
	var radii: Array[float] = [
		strut_radius * 2.2,
		strut_radius * 1.7,
		strut_radius * 1.25,
		strut_radius * 0.5,
		strut_radius * 0.04]
	return MorphoPrimitive.multi_tube(positions, radii, 6)


## Pick `count` spine directions from the lattice verts by greedy farthest-point
## selection from a deterministic random start. (From v1.)
func _radi_spine_directions(verts: Array[Vector3], count: int, rng: RandomNumberGenerator) -> Array[Vector3]:
	var chosen: Array[Vector3] = []
	if verts.is_empty():
		return chosen
	var start: int = rng.randi_range(0, verts.size() - 1)
	chosen.append(verts[start].normalized())
	for _k: int in range(count - 1):
		var best_idx: int = -1
		var best_dist: float = -1.0
		for vi: int in range(verts.size()):
			var v: Vector3 = verts[vi].normalized()
			var nearest: float = 1.0e9
			for c: Vector3 in chosen:
				var dist: float = v.distance_squared_to(c)
				nearest = minf(nearest, dist)
			if nearest > best_dist:
				best_dist = nearest
				best_idx = vi
		if best_idx < 0:
			break
		chosen.append(verts[best_idx].normalized())
	return chosen


# =============================================================================
# MODE: cyrtoid — a chambered LATTICE bell over a revolution surface (trial v2)
# =============================================================================

const _CYRT_BELL_HEIGHT: float = 1.62
const _CYRT_STRUT_SIDES: int = 5


func _build_cyrtoid() -> void:
	var rig := Node3D.new()
	rig.name = "Cyrtoid"
	add_child(rig)
	_cyrtoid_into(rig, _rng)
	# The cyrtoid stands on its base — drop to floor, scale to sculpt size.
	_hk_settle(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


## Build the cyrtoid bell GEOMETRY under `parent` at its native size (_CYRT_BELL_HEIGHT
## 1.62 tall), consuming the passed `rng`. No settle, no scale — pure local geometry, so
## the plate cluster can place + scale the returned rig itself.
func _cyrtoid_into(parent: Node3D, rng: RandomNumberGenerator) -> Node3D:
	# complexity drives chamber count + perforation density (native 3 chambers).
	var chamber_count: int = clampi(2 + complexity / 3, 2, 4)
	# Normalised density used by the trial's lattice/spine counts (native ~0.62).
	var density: float = clampf(0.40 + float(complexity) * 0.04, 0.40, 0.85)

	var skeleton_mat := _hk_skeleton_mat(color_b)
	var membrane_mat := _hk_membrane_mat(color_a, 0.18)
	var nucleus_mat := _hk_glow_mat(accent, 3.5)

	# Bell profile: (radius, y) bottom->top with constriction rings between chambers.
	var profile: Array[Vector2] = []
	var row_chamber: Array[int] = []
	var profile_info: Dictionary = _cyrt_bell_profile(chamber_count, profile, row_chamber)
	var widest_y: float = float(profile_info.get("widest_y", _CYRT_BELL_HEIGHT * 0.45))
	var widest_r: float = float(profile_info.get("widest_r", 0.45))
	var apex_r: float = float(profile_info.get("apex_r", 0.05))

	# 1. The hero: perforated strut lattice over the bell surface.
	_cyrt_lattice_wall(parent, profile, density, skeleton_mat)

	# 2. Faint translucent membrane just inside the lattice wall.
	_cyrt_membrane(parent, profile, membrane_mat)

	# 3. Apical horn at the top.
	_cyrt_apical_horn(parent, profile, apex_r, skeleton_mat, rng)

	# 4. Basal spines / feet splaying from the wide base.
	_cyrt_basal_spines(parent, profile, density, skeleton_mat, rng)

	# 5. Glowing nucleus in the main (widest) chamber.
	_hk_add_mesh(parent, MorphoPrimitive.sphere(maxf(widest_r * 0.42, 0.07), 18, 10),
		nucleus_mat, Transform3D(Basis.IDENTITY, Vector3(0.0, widest_y, 0.0)), "Nucleus")
	return parent


## Bell silhouette as (radius, y) pairs bottom->top with constriction rings between
## chambers, tagging each row's chamber id and recording the widest chamber centre
## for nucleus placement. (Ported from v2.)
func _cyrt_bell_profile(chamber_count: int, out_profile: Array[Vector2],
		out_row_chamber: Array[int]) -> Dictionary:
	var cham_max_r: Array[float] = []
	for c: int in range(chamber_count):
		var t_c: float = float(c) / float(maxi(chamber_count - 1, 1))
		var swell: float = pow(1.0 - t_c, 0.85)
		var r_c: float = lerpf(0.16, 0.50, swell)
		cham_max_r.append(r_c)

	var rows_per_chamber: int = 7
	var widest_r: float = 0.0
	var widest_y: float = 0.0
	var apex_r: float = 0.05

	var base_rim_r: float = cham_max_r[0] * 0.92
	out_profile.append(Vector2(base_rim_r, 0.0))
	out_row_chamber.append(0)

	var y_cursor: float = 0.0
	var chamber_h: float = _CYRT_BELL_HEIGHT / float(chamber_count)

	for c: int in range(chamber_count):
		var r_max: float = cham_max_r[c]
		var r_top_constrict: float = r_max * 0.34
		var r_bot: float = base_rim_r if c == 0 else (cham_max_r[c - 1] * 0.34)

		for ri: int in range(1, rows_per_chamber + 1):
			var t: float = float(ri) / float(rows_per_chamber)
			var belly: float = sin(t * PI)
			var swell_r: float = lerpf(r_bot, r_max, clampf(belly * 1.15, 0.0, 1.0))
			var neck_blend: float = smoothstep(0.62, 1.0, t)
			var r: float = lerpf(swell_r, r_top_constrict, neck_blend)
			r = maxf(r, 0.035)

			var y: float = y_cursor + t * chamber_h
			out_profile.append(Vector2(r, y))
			out_row_chamber.append(c)

			if r > widest_r:
				widest_r = r
				widest_y = y

		y_cursor += chamber_h

	apex_r = maxf(cham_max_r[chamber_count - 1] * 0.30, 0.045)
	out_profile.append(Vector2(apex_r, y_cursor))
	out_row_chamber.append(chamber_count - 1)

	return {"widest_y": widest_y, "widest_r": widest_r, "apex_r": apex_r}


## Lay struts on the (u,v) grid of the revolution surface: meridian struts running
## the profile, ring struts circling each row, node spheres at the crossings — quads
## left OPEN. Constriction rows get a thicker hoop. Struts/nodes are batched into one
## ArrayMesh each so the capture frames the see-through wall. (Ported from v2, but the
## v2 trial's MultiMesh node band is batched into an ArrayMesh here for the capture.)
func _cyrt_lattice_wall(rig: Node3D, profile: Array[Vector2], density: float,
		mat: StandardMaterial3D) -> void:
	var node := Node3D.new()
	node.name = "LatticeWall"
	rig.add_child(node)

	var meridians: int = clampi(10 + int(round(density * 8.0)), 10, 22)
	var strut_r: float = 0.012
	var node_r: float = 0.020
	var hoop_r: float = 0.018
	var rows: int = profile.size()

	# Surface sample grid: world position for each (row, meridian).
	var grid: Array[PackedVector3Array] = []
	for ri: int in range(rows):
		var p: Vector2 = profile[ri]
		var ring := PackedVector3Array()
		for mi: int in range(meridians):
			var ang: float = TAU * float(mi) / float(meridians)
			ring.append(Vector3(cos(ang) * p.x, p.y, sin(ang) * p.x))
		grid.append(ring)

	# Identify constriction rows (local radius minima between chambers).
	var is_constriction: Array[bool] = []
	for ri: int in range(rows):
		is_constriction.append(false)
	for ri: int in range(1, rows - 1):
		var rm1: float = profile[ri - 1].x
		var r0: float = profile[ri].x
		var rp1: float = profile[ri + 1].x
		if r0 < rm1 and r0 <= rp1 and r0 < 0.30:
			is_constriction[ri] = true

	# One ArrayMesh for ALL struts (ring + meridian) so the lattice is one MeshInstance3D.
	var strut_st := SurfaceTool.new()
	strut_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Ring struts: connect consecutive meridians at each row.
	for ri: int in range(rows):
		if profile[ri].x < 0.05:
			continue
		var ring: PackedVector3Array = grid[ri]
		var this_r: float = hoop_r if is_constriction[ri] else strut_r
		for mi: int in range(meridians):
			var a: Vector3 = ring[mi]
			var b: Vector3 = ring[(mi + 1) % meridians]
			_hk_strut(strut_st, a, b, this_r, _CYRT_STRUT_SIDES)

	# Meridian struts: connect each row to the next at a fixed meridian, tapering up.
	for mi: int in range(meridians):
		for ri: int in range(rows - 1):
			var a: Vector3 = grid[ri][mi]
			var b: Vector3 = grid[ri + 1][mi]
			var taper: float = lerpf(1.0, 0.7, float(ri) / float(maxi(rows - 1, 1)))
			_hk_strut(strut_st, a, b, strut_r * taper, _CYRT_STRUT_SIDES)

	strut_st.generate_normals()
	_hk_add_mesh(node, strut_st.commit(), mat, Transform3D.IDENTITY, "LatticeStruts")

	# Nodes: small spheres at every grid intersection, batched into one ArrayMesh.
	var node_st := SurfaceTool.new()
	node_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var node_template: Array[Vector3] = _hk_unit_sphere_geometry(8, 5)
	for ri: int in range(rows):
		if profile[ri].x < 0.05:
			continue
		var ring2: PackedVector3Array = grid[ri]
		for mi: int in range(meridians):
			_hk_append_sphere(node_st, node_template, ring2[mi], node_r)
	node_st.generate_normals()
	_hk_add_mesh(node, node_st.commit(), mat, Transform3D.IDENTITY, "LatticeNodes")


## A revolution surface just inside the lattice wall so a soft translucent skin shows
## through the perforations. (Ported from v2.)
func _cyrt_membrane(rig: Node3D, profile: Array[Vector2], mat: StandardMaterial3D) -> void:
	var inner: Array[Vector2] = []
	for i: int in range(profile.size()):
		var p: Vector2 = profile[i]
		inner.append(Vector2(maxf(p.x * 0.90, 0.02), p.y))
	_hk_add_mesh(rig, MorphoPrimitive.revolution(inner, 24), mat, Transform3D.IDENTITY, "Membrane")


## A tapered, slightly leaning tube horn springing from the apex. (Ported from v2.)
func _cyrt_apical_horn(rig: Node3D, profile: Array[Vector2], apex_r: float,
		mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var apex: Vector2 = profile[profile.size() - 1]
	var base_y: float = apex.y
	var horn_len: float = _CYRT_BELL_HEIGHT * 0.42
	var segs: int = 9

	var lean_dir := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	if lean_dir.length() < 0.01:
		lean_dir = Vector3(1.0, 0.0, 0.3)
	lean_dir = lean_dir.normalized()
	var lean_amt: float = horn_len * 0.16

	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in range(segs):
		var t: float = float(i) / float(segs - 1)
		var y: float = base_y + t * horn_len
		var curve: float = sin(t * PI * 0.5) * lean_amt * t
		positions.append(Vector3(lean_dir.x * curve, y, lean_dir.z * curve))
		radii.append(lerpf(maxf(apex_r * 0.85, 0.04), 0.006, pow(t, 0.8)))

	_hk_add_mesh(rig, MorphoPrimitive.multi_tube(positions, radii, 6), mat,
		Transform3D.IDENTITY, "ApicalHorn")


## Short spines splaying outward and down from the wide base. (Ported from v2.)
func _cyrt_basal_spines(rig: Node3D, profile: Array[Vector2], density: float,
		mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var node := Node3D.new()
	node.name = "BasalSpines"
	rig.add_child(node)

	var base: Vector2 = profile[0]
	var base_r: float = base.x
	var base_y: float = base.y

	var count: int = clampi(3 + int(round(density * 3.0)), 3, 6)
	var spine_len: float = base_r * 1.5
	var ang_off: float = rng.randf_range(0.0, TAU)

	for s: int in range(count):
		var ang: float = ang_off + TAU * float(s) / float(count)
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var down: float = -spine_len * 0.55
		var out: float = spine_len
		var root := Vector3(cos(ang) * base_r, base_y + 0.02, sin(ang) * base_r)
		var tip: Vector3 = root + dir * out + Vector3(0.0, down, 0.0)
		_hk_add_mesh(node, MorphoPrimitive.tube(root, tip, 0.022, 0.004, 6), mat,
			Transform3D.IDENTITY, "Foot_%d" % s)


# =============================================================================
# MODE: siphonophore — a hanging COLONY cluster strung on a stem (trial v3)
# =============================================================================

const _SIPH_COLONY_HEIGHT: float = 2.6
const _SIPH_GLOW_B: Color = Color(0.95, 0.45, 0.90)   # secondary bioluminescent magenta

# Seed-jittered stem parameters baked into locals before the path Callable uses them.
var _siph_sway_amp: float = 0.20
var _siph_sway_phase: float = -0.35
var _siph_drift_z: float = 0.08
var _siph_top_y: float = 1.30
var _siph_bottom_y: float = -1.30


func _build_siphonophore() -> void:
	var rig := Node3D.new()
	rig.name = "Siphonophore"
	add_child(rig)
	_siphonophore_into(rig, _rng)
	# The colony hangs (taller than wide) — centre on all axes, scale to sculpt size.
	_hk_settle(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), false)


## Build the siphonophore colony GEOMETRY under `parent` at its native size
## (_SIPH_COLONY_HEIGHT 2.6 tall), consuming the passed `rng`. No settle, no scale.
## NOTE: bakes the seeded stem sway into the `_siph_*` member vars that the path
## Callable reads — built sequentially, so the plate must not build two of these.
func _siphonophore_into(parent: Node3D, rng: RandomNumberGenerator) -> Node3D:
	var units: int = clampi(complexity * 2, 8, 16)

	_siph_top_y = _SIPH_COLONY_HEIGHT * 0.5
	_siph_bottom_y = -_SIPH_COLONY_HEIGHT * 0.5

	# Bake the seeded sway into locals so the path Callable captures by value.
	_siph_sway_amp = 0.20 + rng.randf() * 0.06
	_siph_sway_phase = -0.35 + rng.randf() * 0.20
	_siph_drift_z = 0.08 + rng.randf() * 0.05

	var path_func: Callable = func(t: float) -> Vector3: return _siph_path(t)
	# Stem radius: thick-ish under the bells, tapering to a thread at the tip.
	var stem_top_r: float = 0.055
	var stem_tip_r: float = 0.012
	var radius_func: Callable = func(t: float) -> float:
		var swell: float = 1.0 + sin(clampf(t * 3.2, 0.0, PI)) * 0.18
		return lerpf(stem_top_r, stem_tip_r, pow(t, 0.85)) * swell

	# Stem: a thin tube swept along the S-path, circular cross-section, no twist.
	var stem_profile: Array[Vector2] = MorphoSweep.profile_circle(10)
	var stem_mesh: Mesh = MorphoSweep.sweep(stem_profile, path_func, radius_func, 0.0, 96, false)
	_hk_add_mesh(parent, stem_mesh, _hk_membrane_mat(color_a, 1.0), Transform3D.IDENTITY, "Stem")

	# Distribute units down the stem with a seeded gradient: a bell crown up top,
	# then a descending chain of glowing bodies that shrink + space out toward the tip.
	var bell_count: int = clampi(int(round(units * 0.28)), 2, 4)
	var body_count: int = units - bell_count

	var t_top: float = 0.08
	var t_bell_end: float = 0.30
	for i: int in range(bell_count):
		var bt: float = rng.randf()
		var frac: float = float(i) / float(maxi(bell_count - 1, 1))
		var t: float = lerpf(t_top, t_bell_end, frac)
		var size: float = lerpf(0.34, 0.22, frac) * (0.94 + bt * 0.12)
		_siph_nectophore(parent, path_func, radius_func, t, size, i, rng)

	var t_chain_start: float = 0.36
	var t_chain_end: float = 0.97
	for i: int in range(body_count):
		var frac: float = float(i) / float(maxi(body_count - 1, 1))
		var eased: float = pow(frac, 1.22)
		var t: float = lerpf(t_chain_start, t_chain_end, eased)
		var jitter: float = 0.90 + rng.randf() * 0.18
		var size: float = lerpf(0.145, 0.050, frac) * jitter
		_siph_body_unit(parent, path_func, radius_func, t, size, frac, i, rng)
	return parent


## The stem path — t in [0,1] apex(top)→tip(bottom): a gentle single-lobe S leaning out
## near the middle, descending, drifting slightly forward. Uses the baked sway locals.
func _siph_path(t: float) -> Vector3:
	var y: float = lerpf(_siph_top_y, _siph_bottom_y, t)
	var lobe: float = sin(t * PI) * smoothstep(0.0, 0.30, t)
	var s: float = sin(t * PI * 0.85 + _siph_sway_phase) * lobe * _siph_sway_amp
	var z: float = sin(t * PI) * _siph_drift_z
	return Vector3(s, y, z)


## A local frame at param t along a path Callable: tangent (toward the tip), a
## horizontal side axis, and an out axis. (Ported from v3.)
func _siph_frame(path_func: Callable, t: float) -> Dictionary:
	var dt: float = 0.004
	var a: Vector3 = path_func.call(maxf(t - dt, 0.0)) as Vector3
	var b: Vector3 = path_func.call(minf(t + dt, 1.0)) as Vector3
	var tangent: Vector3 = (b - a)
	if tangent.length_squared() < 0.000001:
		tangent = Vector3.DOWN
	tangent = tangent.normalized()
	var ref: Vector3 = Vector3.UP
	if absf(tangent.dot(Vector3.UP)) > 0.95:
		ref = Vector3.FORWARD
	var side: Vector3 = tangent.cross(ref).normalized()
	var out: Vector3 = side.cross(tangent).normalized()
	return {"tangent": tangent, "side": side, "out": out}


## Cubic Bézier point at parameter t (matches MorphoPrimitive.bezier_sweep math).
func _siph_cubic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var it: float = 1.0 - t
	return it * it * it * p0 + 3.0 * it * it * t * p1 + 3.0 * it * t * t * p2 + t * t * t * p3


## Campanulate (bell) profile for revolution — closed apex on top, open mouth below.
func _siph_bell_profile() -> Array[Vector2]:
	return [
		Vector2(0.02, 0.50),
		Vector2(0.14, 0.46),
		Vector2(0.30, 0.36),
		Vector2(0.44, 0.18),
		Vector2(0.50, -0.04),
		Vector2(0.50, -0.24),
		Vector2(0.46, -0.40),
		Vector2(0.40, -0.44)]


## A NECTOPHORE (swimming bell): translucent revolution dome + inner glow nucleus +
## a faint subumbrella cone, biased apex-up with a gentle side splay. (Ported from v3.)
func _siph_nectophore(rig: Node3D, path_func: Callable, radius_func: Callable,
		t: float, size: float, idx: int, rng: RandomNumberGenerator) -> void:
	var center: Vector3 = path_func.call(t) as Vector3
	var frame: Dictionary = _siph_frame(path_func, t)
	var tangent: Vector3 = frame["tangent"]
	var side: Vector3 = frame["side"]
	var out: Vector3 = frame["out"]

	var swing: float = 1.0 if idx % 2 == 0 else -1.0
	var lean: float = 0.32 + rng.randf() * 0.12
	var bell_up: Vector3 = (Vector3.UP * 0.85 + side * swing * lean + out * 0.08).normalized()
	var basis: Basis = _hk_basis_from_up(bell_up)

	var stem_r: float = radius_func.call(t) as float
	var attach: Vector3 = center + side * swing * (stem_r + size * 0.35) + (-tangent) * (size * 0.15)

	var bell_node := Node3D.new()
	bell_node.name = "Nectophore_%d" % idx
	bell_node.transform = Transform3D(basis.scaled(Vector3(size, size, size)), attach)
	rig.add_child(bell_node)

	_hk_add_mesh(bell_node, MorphoPrimitive.revolution(_siph_bell_profile(), 22),
		_hk_membrane_mat(color_a, 0.22), Transform3D.IDENTITY, "Membrane")

	var gsph := SphereMesh.new()
	gsph.radius = 0.16
	gsph.height = 0.32
	gsph.radial_segments = 12
	gsph.rings = 8
	_hk_add_mesh(bell_node, gsph, _hk_glow_mat(accent, 1.6),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.18, 0.0)), "InnerGlow")

	var inner_profile: Array[Vector2] = [
		Vector2(0.02, 0.30), Vector2(0.30, 0.05),
		Vector2(0.42, -0.18), Vector2(0.40, -0.30)]
	_hk_add_mesh(bell_node, MorphoPrimitive.revolution(inner_profile, 18),
		_hk_membrane_mat(color_a.lerp(accent, 0.18), 0.16), Transform3D.IDENTITY, "Subumbrella")


## A GASTROZOOID / GONOPHORE body: a translucent teardrop sac with a bright glowing
## nucleus, a collar where it meets the stem, and (for most) a dangling tentacle
## cluster. Glow alternates accent / magenta down the chain. (Ported from v3.)
func _siph_body_unit(rig: Node3D, path_func: Callable, radius_func: Callable,
		t: float, size: float, frac: float, idx: int, rng: RandomNumberGenerator) -> void:
	var center: Vector3 = path_func.call(t) as Vector3
	var frame: Dictionary = _siph_frame(path_func, t)
	var tangent: Vector3 = frame["tangent"]
	var side: Vector3 = frame["side"]
	var out: Vector3 = frame["out"]
	var stem_r: float = radius_func.call(t) as float

	var swing: float = 1.0 if idx % 2 == 0 else -1.0
	var jut: float = stem_r + size * 0.55
	var hang: float = size * 0.35
	var attach: Vector3 = center + side * swing * jut + tangent * hang

	var body_up: Vector3 = (-tangent * 0.85 - side * swing * 0.3 + out * 0.05).normalized()
	var basis: Basis = _hk_basis_from_up(body_up)

	var unit := Node3D.new()
	unit.name = "Body_%d" % idx
	unit.transform = Transform3D(basis, attach)
	rig.add_child(unit)

	var glow_col: Color = accent if idx % 2 == 0 else _SIPH_GLOW_B

	# Outer SAC — translucent teardrop envelope so the nucleus glows through.
	var osph := SphereMesh.new()
	osph.radius = size
	osph.height = size * 2.0
	osph.radial_segments = 16
	osph.rings = 10
	_hk_add_mesh(unit, osph, _hk_membrane_mat(color_a.lerp(glow_col, 0.22), 0.34),
		Transform3D(Basis().scaled(Vector3(0.80, 1.28, 0.80)), Vector3.ZERO), "Sac")

	# Glowing NUCLEUS suspended inside — brighter near the top of the chain.
	var csph := SphereMesh.new()
	csph.radius = size * 0.58
	csph.height = size * 1.16
	csph.radial_segments = 12
	csph.rings = 8
	_hk_add_mesh(unit, csph, _hk_glow_mat(glow_col, lerpf(4.2, 2.8, frac)),
		Transform3D(Basis().scaled(Vector3(0.78, 1.05, 0.78)), Vector3(0.0, size * 0.02, 0.0)),
		"Nucleus")

	# Short translucent collar where the body meets the stem (perisarc cup).
	var collar_profile: Array[Vector2] = [
		Vector2(size * 0.30, size * 0.55),
		Vector2(size * 0.55, size * 0.30),
		Vector2(size * 0.50, size * 0.05)]
	_hk_add_mesh(unit, MorphoPrimitive.revolution(collar_profile, 14),
		_hk_membrane_mat(color_a.lerp(accent, 0.4), 0.18), Transform3D.IDENTITY, "Collar")

	# TENTACLE CLUSTER — denser/longer up the chain, thinning toward the tip.
	var want_cluster: bool = frac < 0.94
	if want_cluster:
		var cluster_n: int = clampi(int(round(lerpf(7.0, 3.0, frac))), 3, 8)
		var mouth: Vector3 = attach + (-body_up) * (size * 1.05)
		_siph_tentacle_cluster(rig, mouth, -body_up, side, swing, size, frac, cluster_n, idx, rng)


## A cluster of curling, drooping cubic-Bézier tentacles with glowing tips and (some)
## tiny side branchlets (tentilla). All seeded values baked into locals before the
## bezier is built (Callable-by-value safety carried over). (Ported from v3.)
func _siph_tentacle_cluster(rig: Node3D, origin: Vector3, down: Vector3, side: Vector3,
		swing: float, host_size: float, frac: float, count: int, host_idx: int,
		rng: RandomNumberGenerator) -> void:
	var cluster := Node3D.new()
	cluster.name = "Tentacles_%d" % host_idx
	rig.add_child(cluster)

	var base_len: float = lerpf(1.25, 0.52, frac) * (0.85 + host_size * 1.2)
	var ref: Vector3 = side
	var fan_axis: Vector3 = down.cross(ref).normalized()
	if fan_axis.length_squared() < 0.001:
		fan_axis = Vector3.RIGHT

	for k: int in range(count):
		var kf: float = float(k) / float(maxi(count - 1, 1))
		var ang: float = lerpf(-1.0, 1.0, kf) * (0.9 + rng.randf() * 0.3)
		var spread_dir: Vector3 = (ref * cos(ang) + fan_axis * sin(ang)).normalized()
		var edge: float = absf(lerpf(-1.0, 1.0, kf))
		var tlen: float = base_len * (0.74 + edge * 0.38 + rng.randf() * 0.30)
		var droop: float = 0.46 + rng.randf() * 0.32
		var splay: float = (0.18 + edge * 0.40) * (0.85 + rng.randf() * 0.3)
		var curl_sign: float = swing
		var thick: float = lerpf(0.018, 0.009, frac) * (0.85 + rng.randf() * 0.3)
		var tip_glow: Color = accent if (host_idx + k) % 2 == 0 else _SIPH_GLOW_B
		var has_tentilla: bool = (rng.randf() < 0.45) and (frac < 0.6)
		var branch_seed: float = rng.randf()

		var p0: Vector3 = origin
		var p1: Vector3 = origin + down * (tlen * 0.16) + spread_dir * (splay * tlen * 0.7)
		var p2: Vector3 = origin + down * (tlen * 0.52) + spread_dir * (splay * tlen) \
			+ side * (swing * 0.05 * tlen)
		var p3: Vector3 = origin + down * (tlen * (0.95 + droop * 0.28)) \
			+ spread_dir * (splay * tlen * 0.45) \
			+ side * (curl_sign * 0.04 * tlen)

		var ctrl: Array[Vector3] = [p0, p1, p2, p3]
		var cross: Array[Vector2] = _siph_circle_cross(6, thick)
		var twist: float = lerpf(-30.0, 30.0, rng.randf())
		var t_mesh: Mesh = MorphoPrimitive.bezier_sweep(ctrl, cross, 14, twist)
		_hk_add_mesh(cluster, t_mesh, _hk_membrane_mat(color_a.lerp(tip_glow, 0.10), 1.0),
			Transform3D.IDENTITY, "Tentacle_%d" % k)

		# Glowing tip bead (the fishing-filament lure).
		var tip_r: float = maxf(thick * 1.8, 0.012)
		var tsph := SphereMesh.new()
		tsph.radius = tip_r
		tsph.height = tip_r * 2.0
		tsph.radial_segments = 8
		tsph.rings = 6
		_hk_add_mesh(cluster, tsph, _hk_glow_mat(tip_glow, 3.2),
			Transform3D(Basis.IDENTITY, p3), "TentacleTip_%d" % k)

		# Tiny side branchlets (tentilla) as little glowing nodes along the curl.
		if has_tentilla:
			var nodes: int = 3 + int(branch_seed * 3.0)
			for n: int in range(nodes):
				var nt: float = lerpf(0.35, 0.85, float(n) / float(maxi(nodes - 1, 1)))
				var bp: Vector3 = _siph_cubic_bezier(p0, p1, p2, p3, nt)
				var nr: float = tip_r * 0.7
				var nsph := SphereMesh.new()
				nsph.radius = nr
				nsph.height = nr * 2.0
				nsph.radial_segments = 6
				nsph.rings = 4
				_hk_add_mesh(cluster, nsph, _hk_glow_mat(tip_glow.lerp(color_a, 0.3), 2.0),
					Transform3D(Basis.IDENTITY, bp), "Tentilla_%d_%d" % [k, n])


## Thin circular cross-section (Array[Vector2]) at a given radius — for sweeps.
func _siph_circle_cross(sides: int, radius: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i: int in range(sides):
		var a: float = TAU * float(i) / float(sides)
		pts.append(Vector2(cos(a) * radius, sin(a) * radius))
	return pts


# =============================================================================
# MODE: diatom — a radial PERFORATED disc/star with m-fold symmetry (trial v4)
# =============================================================================

const _DIAT_DISC_RADIUS: float = 1.05
const _DIAT_DOME_RISE: float = 0.20
const _DIAT_TILT_DEGREES: float = 46.0
const _DIAT_RING_THICK_OUTER: float = 0.022
const _DIAT_RING_THICK_INNER: float = 0.032
const _DIAT_RIB_THICK: float = 0.020
const _DIAT_NODE_RADIUS: float = 0.034
const _DIAT_SPIKE_BASE: float = 0.038
const _DIAT_STRUT_SIDES: int = 6


func _build_diatom() -> void:
	var rig := Node3D.new()
	rig.name = "Diatom"
	add_child(rig)
	_diatom_into(rig, _rng)
	# Size the diatom by its ACROSS-SPAN so it FILLS the frame, ornamental face tilted
	# toward the camera; then centre on all axes.
	_hk_settle_to_span(rig, maxf(sculpt_width, 0.4) * 1.7, 1.0)


## Build the diatom disc GEOMETRY under `parent` at its native size (_DIAT_DISC_RADIUS
## 1.05 across), consuming the passed `rng`. No settle, no scale — pure local geometry,
## already tilted to face +X/+Z, so the plate cluster can place + scale the returned rig.
func _diatom_into(parent: Node3D, rng: RandomNumberGenerator) -> Node3D:
	# 1. m-fold symmetry from the seed (6, 8, 10, or 12).
	var sym_choices: Array[int] = [6, 8, 10, 12]
	var m_fold: int = sym_choices[rng.randi_range(0, sym_choices.size() - 1)]
	# Ring count scales with complexity; spikes are m (or 2m) by a seed coin-flip.
	var ring_count: int = clampi(4 + complexity / 4, 5, 7)
	var spike_count: int = m_fold if rng.randf() < 0.5 else m_fold * 2
	# k sub-sectors per fold give a finer rib lattice while staying m-symmetric.
	var k: int = rng.randi_range(2, 3)

	var frustule_mat := _hk_skeleton_mat(color_b)
	var glow_mat := _hk_glow_mat(accent, 3.0)
	var membrane_mat := _hk_membrane_mat(color_a, 0.11)

	# Container we tilt so the FACE points toward the +X/+Z capture camera.
	var disc := Node3D.new()
	disc.name = "DiatomDisc"
	parent.add_child(disc)

	# 2. Radii of each concentric ring (ring 0 = inner, last = outer rim).
	var ring_radii: Array[float] = []
	for ri: int in range(ring_count):
		var t: float = float(ri) / float(ring_count - 1)
		ring_radii.append(lerpf(0.16, _DIAT_DISC_RADIUS, pow(t, 0.85)))

	# Interstitial half-rings BETWEEN the main rings — thinner, no crossing nodes.
	var inter_radii: Array[float] = []
	for ri: int in range(ring_count - 1):
		inter_radii.append((ring_radii[ri] + ring_radii[ri + 1]) * 0.5)

	var sectors: int = m_fold * k

	# One ArrayMesh for ALL struts (rings + ribs + rosette + spikes) so the lattice
	# is a single MeshInstance3D the capture frames.
	var strut_st := SurfaceTool.new()
	strut_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# RING STRUTS — each a closed polygon of strut segments (a perforation-frame loop).
	var ring_seg_count: int = sectors * 2
	for ri: int in range(ring_count):
		var r: float = ring_radii[ri]
		var z: float = _diat_dome_z(r)
		var thick: float = lerpf(_DIAT_RING_THICK_INNER, _DIAT_RING_THICK_OUTER,
			float(ri) / float(ring_count - 1))
		_diat_ring_strut(strut_st, r, z, thick, ring_seg_count)

	# Interstitial thinner rings (extra areola lattice).
	for r: float in inter_radii:
		_diat_ring_strut(strut_st, r, _diat_dome_z(r), _DIAT_RING_THICK_OUTER * 0.7, ring_seg_count)

	# RADIAL RIB STRUTS — k ribs per fold, rotate-copied m times for exact symmetry.
	var rib_inner_r: float = ring_radii[0]
	var rib_outer_r: float = ring_radii[ring_count - 1]
	var rib_steps: int = 8
	for fold: int in range(m_fold):
		var fold_ang: float = TAU * float(fold) / float(m_fold)
		for ki: int in range(k):
			var local_frac: float = float(ki) / float(k)
			var ang: float = fold_ang + local_frac * (TAU / float(m_fold))
			for s: int in range(rib_steps):
				var rt0: float = float(s) / float(rib_steps)
				var rt1: float = float(s + 1) / float(rib_steps)
				var rr0: float = lerpf(rib_inner_r, rib_outer_r, rt0)
				var rr1: float = lerpf(rib_inner_r, rib_outer_r, rt1)
				var a := Vector3(cos(ang) * rr0, sin(ang) * rr0, _diat_dome_z(rr0))
				var b := Vector3(cos(ang) * rr1, sin(ang) * rr1, _diat_dome_z(rr1))
				_hk_strut(strut_st, a, b, lerpf(_DIAT_RIB_THICK, _DIAT_RIB_THICK * 0.7, rt0),
					_DIAT_STRUT_SIDES)

	# CENTRE ROSETTE — a small hub ring + spokes binding the inner petals.
	var rosette_inner: float = ring_radii[0] * 0.4
	var rosette_outer: float = ring_radii[0] * 0.72
	var hub_z: float = _diat_dome_z(rosette_inner) + 0.012
	_diat_ring_strut(strut_st, rosette_inner, hub_z, _DIAT_RIB_THICK * 0.6, m_fold * 2)

	var centre_z: float = _diat_dome_z(0.0)
	var rosette_z: float = _diat_dome_z(rosette_outer) + 0.012
	for pi: int in range(m_fold):
		var ang: float = TAU * float(pi) / float(m_fold)
		var p_end := Vector3(cos(ang) * rosette_outer, sin(ang) * rosette_outer, rosette_z)
		_hk_strut(strut_st, Vector3(0.0, 0.0, centre_z), p_end, _DIAT_RIB_THICK * 0.6,
			_DIAT_STRUT_SIDES)

	# SPIKY STAR RIM — m (or 2m) tapered horns at the rim, pointing radially outward.
	var rim_r: float = ring_radii[ring_count - 1]
	var rim_z: float = _diat_dome_z(rim_r)
	var spike_len: float = _DIAT_DISC_RADIUS * 0.34
	var spike_steps: int = 5
	for si: int in range(spike_count):
		var ang: float = TAU * float(si) / float(spike_count)
		var base := Vector3(cos(ang) * rim_r, sin(ang) * rim_r, rim_z)
		var tip := Vector3(cos(ang) * (rim_r + spike_len), sin(ang) * (rim_r + spike_len), rim_z * 0.4)
		for s: int in range(spike_steps):
			var t0: float = float(s) / float(spike_steps)
			var t1: float = float(s + 1) / float(spike_steps)
			_hk_strut(strut_st, base.lerp(tip, t0), base.lerp(tip, t1),
				lerpf(_DIAT_SPIKE_BASE, 0.002, pow(t0, 0.7)), _DIAT_STRUT_SIDES)

	strut_st.generate_normals()
	_hk_add_mesh(disc, strut_st.commit(), frustule_mat, Transform3D.IDENTITY, "FrustuleLattice")

	# INTERSECTION + ROSETTE NODES — small spheres at the crossings, batched.
	var node_st := SurfaceTool.new()
	node_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var node_template: Array[Vector3] = _hk_unit_sphere_geometry(8, 6)
	# (ring × rib) crossings — the areola corners.
	for fold: int in range(m_fold):
		var fold_ang: float = TAU * float(fold) / float(m_fold)
		for ki: int in range(k):
			var local_frac: float = float(ki) / float(k)
			var ang: float = fold_ang + local_frac * (TAU / float(m_fold))
			for ri: int in range(ring_count):
				var r: float = ring_radii[ri]
				var scl: float = lerpf(1.15, 0.8, float(ri) / float(ring_count - 1))
				var p := Vector3(cos(ang) * r, sin(ang) * r, _diat_dome_z(r))
				_hk_append_sphere(node_st, node_template, p, _DIAT_NODE_RADIUS * scl)
	# Rosette petals — two concentric rings, outer offset by half a step.
	var rosette_rings: Array[float] = [rosette_inner, rosette_outer]
	for layer: int in range(rosette_rings.size()):
		var rr_layer: float = rosette_rings[layer]
		var zoff: float = _diat_dome_z(rr_layer) + 0.012
		var half: float = 0.5 if layer == 1 else 0.0
		var scl_layer: float = 1.1 if layer == 0 else 0.85
		for pi: int in range(m_fold):
			var ang: float = TAU * (float(pi) + half) / float(m_fold)
			var p := Vector3(cos(ang) * rr_layer, sin(ang) * rr_layer, zoff)
			_hk_append_sphere(node_st, node_template, p, _DIAT_NODE_RADIUS * 0.85 * scl_layer)
	node_st.generate_normals()
	_hk_add_mesh(disc, node_st.commit(), frustule_mat, Transform3D.IDENTITY, "AreolaNodes")

	# Central bioluminescent boss (the glow at the centre).
	_hk_add_mesh(disc, MorphoPrimitive.sphere(_DIAT_NODE_RADIUS * 1.8, 12, 8), glow_mat,
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, centre_z + 0.02)), "CentreBoss")

	# TRANSLUCENT LENS MEMBRANE — a faint biconvex glass disc behind the lattice so the
	# perforations read as holes in a real silica plate.
	var lens_profile: Array[Vector2] = []
	var lens_steps: int = 10
	for s: int in range(lens_steps + 1):
		var t: float = float(s) / float(lens_steps)
		var rr: float = lerpf(0.0, rim_r * 0.99, t)
		var hz: float = _DIAT_DOME_RISE * 0.45 * cos(clampf(rr / _DIAT_DISC_RADIUS, 0.0, 1.0) * PI * 0.5)
		lens_profile.append(Vector2(rr, hz))
	var lens_mi: MeshInstance3D = _hk_add_mesh(disc, MorphoPrimitive.revolution(lens_profile, m_fold * 4),
		membrane_mat, Transform3D.IDENTITY, "LensMembrane")
	if lens_mi != null:
		# Revolution builds around +Y; rotate so its axis becomes local +Z (the face
		# normal), sitting just BEHIND the lattice so the cells still read as holes.
		lens_mi.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)),
			Vector3(0.0, 0.0, -0.02))

	# Tilt the whole disc so its FACE points toward the +X/+Z capture camera, with a
	# small yaw so the spike pattern isn't axis-aligned to the lens.
	disc.transform = Transform3D(
		Basis(Vector3.UP, deg_to_rad(12.0)) * Basis(Vector3.RIGHT, deg_to_rad(-(90.0 - _DIAT_TILT_DEGREES))),
		Vector3.ZERO)
	return parent


## Local biconvex dome height (out-of-plane +Z offset) for a given radius.
func _diat_dome_z(r: float) -> float:
	var n: float = clampf(r / _DIAT_DISC_RADIUS, 0.0, 1.0)
	return _DIAT_DOME_RISE * cos(n * PI * 0.5)


## Append a closed ring of struts (a polygon loop) at radius `r`, out-of-plane `z`,
## strut radius `thick`, to the shared SurfaceTool `st`.
func _diat_ring_strut(st: SurfaceTool, r: float, z: float, thick: float, seg_count: int) -> void:
	for si: int in range(seg_count):
		var ang0: float = TAU * float(si) / float(seg_count)
		var ang1: float = TAU * float(si + 1) / float(seg_count)
		var a := Vector3(cos(ang0) * r, sin(ang0) * r, z)
		var b := Vector3(cos(ang1) * r, sin(ang1) * r, z)
		_hk_strut(st, a, b, thick, _DIAT_STRUT_SIDES)


# =============================================================================
# MODE: plate — a 3D Haeckel TAFEL: a composed CLUSTER of varied micro-forms
# =============================================================================
# A single composition holding a whole family of related lattices, after the plates
# of Kunstformen der Natur: several radiolaria (lattice spheres) of varied sizes, a
# couple of diatom discs, one or two small cyrtoid bells — all floating together in a
# loose, organic 3D constellation of glowing nuclei. Each sub-form is built by the same
# `_<genus>_into` geometry helpers the four solo modes use, given its OWN seeded RNG
# derived from `_rng`, then scaled small and placed: a few larger HERO forms near the
# centre with smaller SATELLITES around them, gentle 3D jitter, a touch of overlap so it
# reads as a colony, not a scatter. The whole plate is then fit + centred on all axes.

const _PLATE_RADIO_HERO_SPAN := Vector2(0.84, 1.00)   # hero lattice-sphere span range
const _PLATE_RADIO_SAT_SPAN := Vector2(0.32, 0.56)    # satellite lattice-sphere span
const _PLATE_DIATOM_SPAN := Vector2(0.46, 0.66)       # diatom disc span range
const _PLATE_CYRT_SPAN := Vector2(0.44, 0.62)         # cyrtoid bell span range


func _build_plate() -> void:
	var rig := Node3D.new()
	rig.name = "Plate"
	add_child(rig)

	# Cluster count from complexity (native 8 at complexity 7).
	var count: int = clampi(complexity + 1, 6, 12)

	# Compose the genus mix as an ordered list: HERO radiolaria first (placed central +
	# large), then a weighted body of satellites — mostly radiolaria, ~2-3 diatoms,
	# ~1-2 cyrtoids. Siphonophore is skipped (too tall/hangy to read in a cluster).
	var hero_n: int = clampi(2 + (1 if count >= 10 else 0), 2, 3)
	var diatom_n: int = clampi(2 + (1 if count >= 9 else 0), 2, 3)
	var cyrt_n: int = clampi(1 + (1 if count >= 8 else 0), 1, 2)
	var radio_sat_n: int = maxi(count - hero_n - diatom_n - cyrt_n, 0)

	# Build the kind list, then SHUFFLE the satellite tail deterministically so the
	# diatoms/bells don't clump at the end of the placement order.
	var kinds: Array[String] = []
	for _i: int in range(hero_n):
		kinds.append("radio_hero")
	var tail: Array[String] = []
	for _i: int in range(radio_sat_n):
		tail.append("radio_sat")
	for _i: int in range(diatom_n):
		tail.append("diatom")
	for _i: int in range(cyrt_n):
		tail.append("cyrtoid")
	_plate_shuffle(tail, _rng)
	for kstr: String in tail:
		kinds.append(kstr)

	# The original accent — restored after per-form variation so the plate stays clean.
	var base_accent: Color = accent
	# A warm second hue some nuclei are nudged toward, for gentle in-cluster variety.
	var accent_alt: Color = base_accent.lerp(Color(0.98, 0.45, 0.55), 1.0)

	# Placement bookkeeping (centres + radii in pre-fit local space) for soft spacing.
	var centres: Array[Vector3] = []
	var radii: Array[float] = []

	# Cluster envelope in pre-fit space: a compact rough ellipsoid, taller than wide and
	# tight in depth so the plate reads as a portrait COLONY KNOT (a Tafel) rather than a
	# wide ground scatter — but still fully 3D. Satellites hug the central heroes.
	var env := Vector3(0.84, 1.04, 0.80)

	for idx: int in range(kinds.size()):
		var kind: String = kinds[idx]
		# Each sub-form gets its OWN deterministic RNG seeded from the plate seed.
		var sub_rng := RandomNumberGenerator.new()
		sub_rng.seed = seed * 1000003 + idx * 9176 + 17

		# Per-form accent nudge: ~1 in 3 forms leans toward the alt hue.
		if sub_rng.randf() < 0.34:
			accent = base_accent.lerp(accent_alt, sub_rng.randf_range(0.25, 0.6))
		else:
			accent = base_accent

		# Three nested nodes keep placement / rotation / fit independent so none clobbers
		# another:  holder (cluster position) → rot (random orientation, no scale) → geo
		# (the fit: uniform scale + recentre of the genus geometry on its own origin).
		var holder := Node3D.new()
		holder.name = "Form_%d_%s" % [idx, kind]
		rig.add_child(holder)

		var rot := Node3D.new()
		rot.name = "Rot"
		holder.add_child(rot)

		var geo := Node3D.new()
		geo.name = "Geo"
		rot.add_child(geo)

		var span: float = _plate_build_form(geo, kind, sub_rng)
		# Grade the heroes by index so the cluster has ONE clear lead form: hero 0 stays
		# full size, later heroes shrink a step — a size hierarchy, not twins.
		if idx < hero_n and hero_n > 1:
			span *= lerpf(1.0, 0.74, float(idx) / float(hero_n - 1))
		# Recentre + uniformly scale the genus geometry to its target span on the inner
		# node, so `holder.position` is the form's true centre in cluster space.
		_plate_fit_centred(geo, span)

		# Random full 3D rotation per form (on its OWN node so the fit scale survives).
		rot.basis = _plate_random_basis(sub_rng)

		var form_r: float = span * 0.5
		var pos: Vector3 = _plate_place(idx, hero_n, env, form_r, centres, radii, sub_rng)
		holder.position = pos
		centres.append(pos)
		radii.append(form_r)

	accent = base_accent

	# Fit the whole composition to the sculpt envelope and centre on all axes (floating).
	# Uniform scale only — never stretch the sub-forms.
	_plate_fit_centred(rig, maxf(maxf(sculpt_width, sculpt_height), 0.4))


## Build ONE sub-form of `kind` under `parent` via the shared `_<genus>_into` helpers,
## using `rng`. Returns the TARGET span (max diameter) to fit the form to.
func _plate_build_form(parent: Node3D, kind: String, rng: RandomNumberGenerator) -> float:
	match kind:
		"radio_hero":
			_radiolarian_into(parent, rng)
			return rng.randf_range(_PLATE_RADIO_HERO_SPAN.x, _PLATE_RADIO_HERO_SPAN.y)
		"radio_sat":
			_radiolarian_into(parent, rng)
			return rng.randf_range(_PLATE_RADIO_SAT_SPAN.x, _PLATE_RADIO_SAT_SPAN.y)
		"diatom":
			_diatom_into(parent, rng)
			return rng.randf_range(_PLATE_DIATOM_SPAN.x, _PLATE_DIATOM_SPAN.y)
		"cyrtoid":
			_cyrtoid_into(parent, rng)
			return rng.randf_range(_PLATE_CYRT_SPAN.x, _PLATE_CYRT_SPAN.y)
		_:
			_radiolarian_into(parent, rng)
			return rng.randf_range(_PLATE_RADIO_SAT_SPAN.x, _PLATE_RADIO_SAT_SPAN.y)


## Uniformly scale `node` so its largest local span == `target_span`, then shift its
## geometry so the subtree AABB centre sits at the node origin. Uniform on all axes
## (never the non-uniform settle), so sub-forms keep their proportions. Used twice: per
## sub-form (target = its span) and for the whole plate (target = the sculpt envelope).
func _plate_fit_centred(node: Node3D, target_span: float) -> void:
	if target_span > 0.0:
		var raw: AABB = _hk_subtree_aabb(node)
		var span: float = maxf(maxf(raw.size.x, maxf(raw.size.y, raw.size.z)), 0.001)
		var k: float = target_span / span
		node.scale = Vector3(k, k, k)
	var aabb: AABB = _hk_subtree_aabb(node)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	node.position += Vector3(-centre.x, -centre.y, -centre.z)


## A deterministic position in the cluster for form `idx`. The first `hero_n` forms sit
## near the centre (small jitter); the rest are satellites on a jittered ellipsoid shell
## whose radius grows with index. A soft rejection pushes a form outward if it sits too
## deep inside an already-placed neighbour, so forms touch/overlap gently but never fully
## interpenetrate. All from `rng` — deterministic.
func _plate_place(idx: int, hero_n: int, env: Vector3, form_r: float,
		centres: Array[Vector3], radii: Array[float], rng: RandomNumberGenerator) -> Vector3:
	var pos: Vector3
	if idx < hero_n:
		# Heroes: a tight central knot, slightly offset from each other.
		var jit: float = 0.16
		pos = Vector3(
			rng.randf_range(-jit, jit) * env.x,
			rng.randf_range(-jit, jit) * env.y,
			rng.randf_range(-jit, jit) * env.z)
	else:
		# Satellites: random direction on a shell, radius ramping gently outward with
		# index but kept close so they cluster AROUND the heroes, not at the rim.
		var sat_i: int = idx - hero_n
		var ramp: float = lerpf(0.32, 0.78, float(sat_i) / float(maxi(7, 1)))
		ramp = clampf(ramp + rng.randf_range(-0.08, 0.10), 0.28, 0.86)
		var dir: Vector3 = _plate_random_dir(rng)
		pos = Vector3(dir.x * env.x, dir.y * env.y, dir.z * env.z) * ramp

	# Soft spacing: if too far inside a neighbour, push outward along the separating axis.
	# Factor < 1 lets forms touch / gently overlap so the plate reads as a colony.
	for _pass: int in range(6):
		var moved: bool = false
		for ni: int in range(centres.size()):
			var other: Vector3 = centres[ni]
			var min_d: float = (form_r + radii[ni]) * 0.56
			var delta: Vector3 = pos - other
			var d: float = delta.length()
			if d < min_d:
				var push_dir: Vector3 = (delta / d) if d > 0.0001 else _plate_random_dir(rng)
				pos = other + push_dir * min_d
				moved = true
		if not moved:
			break
	return pos


## A deterministic unit direction with full 3D spread (not biased to a plane).
func _plate_random_dir(rng: RandomNumberGenerator) -> Vector3:
	var z: float = rng.randf_range(-1.0, 1.0)
	var t: float = rng.randf_range(0.0, TAU)
	var r: float = sqrt(maxf(1.0 - z * z, 0.0))
	return Vector3(r * cos(t), z, r * sin(t))


## A deterministic random orientation Basis (orthonormal) from `rng`.
func _plate_random_basis(rng: RandomNumberGenerator) -> Basis:
	var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
	b = Basis(Vector3.RIGHT, rng.randf_range(-PI, PI)) * b
	b = Basis(Vector3.FORWARD, rng.randf_range(-PI, PI)) * b
	return b.orthonormalized()


## In-place Fisher–Yates shuffle of a String array using `rng` (deterministic).
func _plate_shuffle(arr: Array[String], rng: RandomNumberGenerator) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
