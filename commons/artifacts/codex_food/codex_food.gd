extends Node3D
class_name CodexFood

# @identity
# essence: a single DNA-driven CODEX FOOD specimen — an everyday edible from Luigi
#   Serafini's Codex Seraphinianus food chapter, where the vegetable is secretly a
#   machine, a flame, a seed-reliquary, or a gem geode. Where most artifacts stack
#   inert primitives, CodexFood GROWS one uncanny edible whose organic skin has been
#   fused with mechanism or torn open to reveal an impossible interior. Depending on
#   its `mode` DNA it becomes one of four specimens whose truth is the BOUNDARY between
#   organism and artifact: tuber (a lumpy brown POTATO that is plumbing — an SDF
#   smooth-union body meshed by marching cubes + ridged noise skin, brass elbow pipes
#   with a hand-wheel valve, two pressure gauges with needles + a cyan dial glow, a
#   spigot, a red mushroom-cap emergency valve crowning the top, and four hex bolt feet),
#   candleroot (a plump red RADISH/BEET that is a lit CANDLE — a revolved bulb blushing
#   pale at the base, a tapering root tail curving to a wax pool, pale wax drips riding
#   the belly, green bezier-swept leaves, and a hero teardrop FLAME with an additive halo
#   and a warm OmniLight at the crown), seedpod (a glossy green GOURD/PEPPER cut open — a
#   partial-arc revolution shell with one wedge missing, a thick flesh-coloured cut wall,
#   and the cavity PACKED with a glowing-gold cluster of ovoid SEEDS on a placenta column,
#   loose seeds spilled in front, a woody stem), and zipfruit (a purple AUBERGINE unzipping
#   along a seam — two half-shells hinged OUTWARD like a gaping book, a real metal ZIPPER
#   of interlocking teeth + a ring-pull tab, and inside NOT flesh but a glowing cyan
#   faceted CRYSTAL geode lighting the pale inner peel). It is identity confessed as the
#   moment an edible turns out to be an apparatus — the fed and the built, the same body.
# desire: it wants the organic SKIN to read as living edible matter (subsurface scatter, a
#   faint own-tone emission FLOOR so it never collapses to black against the dark capture),
#   the METAL plumbing/mechanism to read as warm brass and cool steel (an emission floor so
#   the metal reads in shade, never black), the FLAME / SEEDS / CRYSTAL CORE to BURN
#   bioluminescent (near-unshaded glow, energy 2.5–6, plus a warm OmniLight for the candle),
#   and the cut-open interiors (seedpod cavity, zipfruit peel) to be SEEN INTO (CULL_DISABLED
#   on the concave faces). Above all it wants the uncanny FUSION legible from the +X/+Z
#   capture face — the machinery, the flame, the seed-mass, the geode all presented to the lens.
# critical_parameter: mode + seed + the colour triad (color_a ORGANIC SKIN / color_b
#   SECONDARY / accent GLOW) + complexity. mode picks the specimen lineage; seed varies the
#   individual deterministically (a local seeded RNG, no global randf/randi ever). Per mode
#   the triad RE-REGISTERS the form: color_a is potato-brown / radish-red / pepper-green /
#   aubergine-purple; color_b is brass metal / leaf-green / pale inner flesh / crystal+
#   mechanism; accent is the gauge/flame/seed/core glow. complexity scales pipe + drip + seed
#   + crystal counts. sculpt_height / sculpt_width rescale the specimen to its frame.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches on
#   `mode` to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears
#   children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a CODEX PLATE — four ways an everyday food is secretly an
#   artifact. Switch one mode and the room's idea of "edible" shifts from nourishment to
#   mechanism, flame, seed, geode; reseed and the specimen persists while its individual varies.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each
#   carrying its trial's bespoke machinery (SDF marching-cubes tuber + pipes; revolved candle
#   bulb + flame + wax; partial-arc pepper shell + batched seed cluster; hinged zip half-shells
#   + batched teeth + faceted crystal core) [present]; skin / metal / glow / pale materials
#   driven by the colour triad [present]; many small parts (seeds, crystals, zipper teeth)
#   batched into one ArrayMesh so the AABB capture frames them [present].
# relationships: kin to haeckel and biomech_ng (same genome shape + conventions — a mode
#   switchboard over one genome of DNA exports); built on the nature_system morphology engine
#   it borrows from (MorphoPrimitive / MorphoModifier); cousin to any Codex specimen plate.
# truth: the Codex food chapter knows that the line between organism and artifact is porous —
#   a potato can be plumbing, a radish a candle, a pepper a seed-reliquary, an aubergine a
#   gem-geode. CodexFood holds four such edibles in one genome and lets a single parameter
#   choose which uncanny fusion the viewer is invited to read. The QFEP boundary between the
#   fed and the built is the whole subject: the skin must stay edible, the metal must read,
#   the core must glow, and the cut must be SEEN INTO.

## A multi-mode generative Codex Seraphinianus FOOD specimen — an edible that is secretly
## an artifact.
##
## Built procedurally from DNA exports, after the food/vegetable chapter of Luigi Serafini's
## Codex Seraphinianus. The `mode` export selects one of FOUR specimens, each ported
## faithfully from a verified trial:
## tuber (a lumpy POTATO fused with brass PLUMBING — SDF marching-cubes body + ridged noise
## skin, elbow pipes, hand-wheel valve, pressure gauges with needles + glow, spigot, red
## mushroom-cap valve, hex bolt feet), candleroot (a red RADISH that is a CANDLE — revolved
## bulb + root tail + wax pool + wax drips + green leaves + hero teardrop flame with additive
## halo + warm OmniLight), seedpod (a green GOURD/PEPPER sliced open — partial-arc revolution
## shell with a missing wedge + thick flesh cut wall + a glowing-gold seed cluster on a
## placenta + spilled loose seeds + stem), zipfruit (a purple AUBERGINE unzipping — two
## hinged half-shells + a metal zipper of interlocking teeth + a ring-pull tab + a glowing
## faceted CRYSTAL geode core lighting the pale inner peel).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad
## (color_a ORGANIC SKIN / color_b SECONDARY / accent GLOW) re-registers the same anatomy
## between palettes — and re-registers the FORM per mode (skin = potato/radish/pepper/
## aubergine; secondary = brass/leaf/flesh/crystal; accent = gauge/flame/seed/core glow).
## Shared material + geometry helpers live under the `_cf_` prefix; the bespoke machinery
## from each trial is carried into mode-specific `_tub_` / `_can_` / `_seed_` / `_zip_`
## sub-helpers so the seeds / crystals / zipper teeth batch into one ArrayMesh each and the
## capture frames the whole specimen. Surface generation reuses the morphology toolkit
## statics (MorphoPrimitive, MorphoModifier) for tubes, sweeps, revolutions, marching cubes.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## tuber | candleroot | seedpod | zipfruit
@export var mode: String = "tuber"
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 0
## Detail / element count. Scales pipe + gauge detail (tuber), wax drip count
## (candleroot), seed cluster density (seedpod), and crystal count (zipfruit).
@export var complexity: int = 6
## Overall height in meters (nominal full height of the specimen, including stem/flame).
@export var sculpt_height: float = 1.2
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## ORGANIC SKIN — potato brown / radish red / pepper green / aubergine purple.
@export var color_a: Color = Color(0.62, 0.46, 0.30)
## SECONDARY — tuber: brass metal; candleroot: leaf green; seedpod: pale inner flesh;
## zipfruit: crystal / mechanism.
@export var color_b: Color = Color(0.72, 0.56, 0.28)
## GLOW — gauge dial / candle flame / seed cluster / crystal core.
@export var accent: Color = Color(1.00, 0.72, 0.30)
## Metalness of the secondary metal (tuber plumbing / zipfruit mechanism).
@export var metallic_amt: float = 0.6
@export var rough_amt: float = 0.5
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()

# Siphonophore-style baked locals are not needed here; each builder bakes its own
# seeded values into function-local vars before any sdf/sweep/bezier Callable.


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
		"tuber":
			_build_tuber()
		"candleroot":
			_build_candleroot()
		"seedpod":
			_build_seedpod()
		"zipfruit":
			_build_zipfruit()
		_:
			# Unknown mode falls back to the tuber specimen.
			_build_tuber()


# ═══════════════════════════════════════════════════════════════
# Shared `_cf_` material helpers (colour-triad driven)
# ═══════════════════════════════════════════════════════════════

## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _cf_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## ORGANIC SKIN (color_a family): edible matter — potato/radish/pepper/aubergine skin.
## Mid-high roughness, subsurface scatter on, a faint own-tone emission FLOOR so the
## skin reads against the dark capture and never collapses to black.
func _cf_skin_mat(c: Color = color_a) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt + 0.25, 0.5, 0.92)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.2
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cf_glow_energy(0.10)
	return m


## METAL (color_b family): brass plumbing / steel fittings / zipper mechanism. Metalness
## from metallic_amt, roughness from rough_amt, with an EMISSION FLOOR (own-tone) so the
## metal reads in shade and never goes black against the capture.
func _cf_metal_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.roughness = clampf(rough_amt, 0.05, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.5
	m.emission_energy_multiplier = _cf_glow_energy(0.18)
	return m


## GLOW (accent family): gauge dial / flame / seed / crystal core. Saturated, near-
## UNSHADED bioluminescence. `energy` ~2.5–6; `alpha` < 1.0 turns on alpha transparency
## (additive halos handle their own blend in `_cf_halo_mat`).
func _cf_glow_mat(c: Color = accent, energy: float = 3.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cf_glow_energy(energy)
	return m


## ADDITIVE HALO (accent family): low-alpha add-blend sleeve around the candle flame so it
## reads as radiant light, not a solid shell. Unshaded, two-sided.
func _cf_halo_mat(c: Color = accent, energy: float = 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, 0.12)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cf_glow_energy(energy)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## PALE matter (inner flesh / wax / inner peel): warm off-white, matte diffuse. `two_sided`
## turns on CULL_DISABLED for concave cut interiors. Kept matte (no SSS / no emission) so it
## does not blow to white and swallow the glowing seeds/crystals — the core light lights it.
func _cf_pale_mat(c: Color = Color(0.90, 0.87, 0.78), two_sided: bool = false,
		matte: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7 if matte else 0.4
	m.metallic = 0.0
	if two_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ═══════════════════════════════════════════════════════════════
# Shared `_cf_` geometry helpers
# ═══════════════════════════════════════════════════════════════

## Orthonormal Basis whose +Y axis is `up_axis`. Used to stand pipes, feet, fittings, seeds,
## crystals and teeth along an arbitrary direction without an out-of-tree look_at.
func _cf_basis_from_up(up_axis: Vector3) -> Basis:
	var y: Vector3 = up_axis.normalized()
	if y.length_squared() < 0.0001:
		y = Vector3.UP
	var ref: Vector3 = Vector3.RIGHT
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Orthonormal Basis whose +X axis is `long_axis` — for ovoid seeds whose long axis points
## radially outward toward the cavity wall (seedpod).
func _cf_basis_long_axis(long_axis: Vector3) -> Basis:
	var x: Vector3 = long_axis.normalized()
	if x.length_squared() < 0.0001:
		x = Vector3.RIGHT
	var ref: Vector3 = Vector3.UP
	if absf(x.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var y: Vector3 = ref.cross(x).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _cf_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
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


## Emit one box into a SurfaceTool, centred at `c`, half-extents (hx,hy,hz) along orthonormal
## axes (ax,ay,az). 12 triangles, outward-facing. (For valve spokes, gauge needles, zipper
## teeth, pull-tab.)
func _cf_emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
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
	_cf_quad(st, p000, p010, p110, p100, -az)
	_cf_quad(st, p001, p101, p111, p011, az)
	_cf_quad(st, p000, p100, p101, p001, -ay)
	_cf_quad(st, p010, p011, p111, p110, ay)
	_cf_quad(st, p000, p001, p011, p010, -ax)
	_cf_quad(st, p100, p110, p111, p101, ax)


func _cf_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


## Emit one triangle with a generated flat (per-face) normal — for hand-built shells.
func _cf_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length_squared() > 0.0000001:
		n = n.normalized()
	else:
		n = Vector3.UP
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


## Emit one triangle with an explicit normal.
func _cf_tri_n(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


## Bake a source mesh's surface 0 into a SurfaceTool, transformed by `xform`. Reads positions
## + normals via MeshDataTool and re-emits triangles so many small parts batch into one
## surface (one MeshInstance3D, one draw call) — used for the seed cluster + placenta.
func _cf_bake_mesh(st: SurfaceTool, src: Mesh, xform: Transform3D) -> void:
	if src == null:
		return
	var arr: ArrayMesh
	if src is ArrayMesh:
		arr = src as ArrayMesh
	else:
		var tmp := SurfaceTool.new()
		tmp.create_from(src, 0)
		arr = tmp.commit()
	if arr == null or arr.get_surface_count() == 0:
		return
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(arr, 0) != OK:
		return
	var nbasis: Basis = xform.basis.inverse().transposed()
	for fi: int in range(mdt.get_face_count()):
		for corner: int in range(3):
			var vi: int = mdt.get_face_vertex(fi, corner)
			var v: Vector3 = xform * mdt.get_vertex(vi)
			var n: Vector3 = (nbasis * mdt.get_vertex_normal(vi)).normalized()
			st.set_normal(n)
			st.add_vertex(v)


## Compute the AABB of a node subtree IN `node`'s local space (for footing / centring the
## specimen). Accumulates each MeshInstance3D's AABB through the chain of LOCAL transforms
## down from `node` — never touches global_transform.
func _cf_subtree_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first: bool = true
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


## Centre `body` horizontally at the origin so the AABB capture frames it. If `to_floor` the
## lowest point is dropped to y=0 (standing specimens); otherwise the vertical centre is also
## moved to the origin. `target_h` rescales the whole subtree to that height first
## (`width_scale` stretches the horizontal axes for span control).
func _cf_settle(body: Node3D, target_h: float = 0.0, width_scale: float = 1.0,
		to_floor: bool = true) -> void:
	if target_h > 0.0:
		var raw: AABB = _cf_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		var k: float = target_h / span_y
		body.scale = Vector3(k * width_scale, k, k * width_scale)
	var aabb: AABB = _cf_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	var y_shift: float = -aabb.position.y if to_floor else -centre.y
	body.position += Vector3(-centre.x, y_shift, -centre.z)


# =============================================================================
# MODE: tuber — a lumpy POTATO fused with brass PLUMBING (trial v1)
# =============================================================================

const _TUB_MC_RESOLUTION: int = 60          # marching-cubes cells per axis
const _TUB_NOISE_AMOUNT: float = 0.072       # skin-grain displacement
const _TUB_PIPE_SIDES: int = 12              # tube cross-section facets

# Tuber body AABB (local), filled by _tub_body for downstream registration.
var _tub_body_centre: Vector3 = Vector3.ZERO
var _tub_body_extent: Vector3 = Vector3.ONE


func _build_tuber() -> void:
	var rig := Node3D.new()
	rig.name = "PotatoMachine"
	add_child(rig)

	# 1) Lumpy tuber body (SDF smooth-union → marching cubes → ridged noise skin).
	var body_aabb: AABB = _tub_body(rig)
	_tub_body_centre = body_aabb.get_center()
	_tub_body_extent = body_aabb.size

	# Feet hang foot_h below the body's underside; _cf_settle(to_floor) drops the lowest
	# geometry (the feet) to y=0, so no manual lift is needed here.
	var foot_h: float = 0.16

	# 2) Plumbing emerging from the flanks toward the +X/+Z camera.
	_tub_plumbing(rig)
	# 3) Red mushroom-cap valve crowning the top.
	_tub_red_knob(rig)
	# 4) Bolt feet it stands on.
	_tub_feet(rig, foot_h)
	# 5) Darker "eyes" dimpled into the skin.
	_tub_eyes(rig)

	# Stand on y=0, centre, scale to the requested sculpt size.
	_cf_settle(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


## The lumpy potato. Several offset spheres of varying radius are smooth-unioned into one
## blob (the irregular SILHOUETTE), meshed with marching_cubes, then noise_displaced for skin
## grain. All sphere centres/radii are baked into typed locals BEFORE the distance Callable is
## built, so the field is pure + deterministic. Returns the local AABB of the committed mesh.
func _tub_body(parent: Node3D) -> AABB:
	var centres: Array[Vector3] = []
	var radii: Array[float] = []
	# A potato is oblong + lumpy: a long core along X, broad shoulders, off-axis knobs.
	centres.append(Vector3(-0.10, 0.0, 0.0));          radii.append(0.255)
	centres.append(Vector3(0.16, -0.01, 0.0));         radii.append(0.245)
	centres.append(Vector3(0.40, 0.03, 0.02));         radii.append(0.205)
	centres.append(Vector3(-0.38, -0.03, -0.02));      radii.append(0.215)
	centres.append(Vector3(0.02, -0.05, 0.20));        radii.append(0.185)
	centres.append(Vector3(-0.12, 0.06, -0.20));       radii.append(0.175)
	centres.append(Vector3(0.55, -0.07, 0.07));        radii.append(0.125)
	centres.append(Vector3(-0.04, -0.15, 0.06));       radii.append(0.155)
	centres.append(Vector3(0.22, 0.13, 0.15));         radii.append(0.135)

	# Seeded jitter so it never reads as a tidy formula.
	var n_lobes: int = centres.size()
	for i: int in range(n_lobes):
		var jit := Vector3(
			_rng.randf_range(-0.03, 0.03),
			_rng.randf_range(-0.03, 0.03),
			_rng.randf_range(-0.03, 0.03))
		centres[i] = (centres[i] as Vector3) + jit
		radii[i] = (radii[i] as float) * _rng.randf_range(0.94, 1.07)

	var blend_k: float = 0.085           # tighter fillet → lumps stay distinct (baked local)

	# Compose the SDF as a pure function over the baked arrays.
	var field: Callable = MorphoPrimitive.sdf_sphere(centres[0] as Vector3, radii[0] as float)
	for i: int in range(1, n_lobes):
		var lobe: Callable = MorphoPrimitive.sdf_sphere(centres[i] as Vector3, radii[i] as float)
		field = MorphoPrimitive.sdf_smooth_union(field, lobe, blend_k)

	var bounds := AABB(Vector3(-0.80, -0.55, -0.55), Vector3(1.70, 1.05, 1.10))
	var raw_mesh: Mesh = MorphoPrimitive.marching_cubes(field, bounds, _TUB_MC_RESOLUTION)

	# Skin grain: push vertices along normals by ridged cellular noise.
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.frequency = 3.4
	noise.fractal_octaves = 3
	var skinned: ArrayMesh = MorphoModifier.noise_displace(raw_mesh, noise, _TUB_NOISE_AMOUNT)

	_cf_add_mesh(parent, skinned, _cf_skin_mat(color_a), Transform3D.IDENTITY, "Tuber")

	if skinned != null and skinned.get_surface_count() > 0:
		return skinned.get_aabb()
	return bounds


func _tub_plumbing(parent: Node3D) -> void:
	# Sockets sit on the tuber flanks facing the +X/+Z camera so the machinery reads as the
	# hero face. complexity gates the secondary gauge so denser specimens carry more apparatus.
	# Pipe A: big brass elbow out the +X shoulder, capped by a valve wheel.
	_tub_pipe_run(parent,
		Vector3(0.52, 0.05, 0.18),
		Vector3(0.85, 0.16, 0.50).normalized(),
		0.052, 0.30, true,
		Vector3(0.0, 1.0, 0.18).normalized(), 0.22, "valve")
	# Pipe B: short brass pipe out the +Z belly, tipping up into a big gauge facing the camera.
	_tub_pipe_run(parent,
		Vector3(-0.10, -0.04, 0.32),
		Vector3(-0.12, 0.42, 0.90).normalized(),
		0.040, 0.20, false, Vector3.UP, 0.0, "gauge")
	# Pipe C: short steel stub up-front ending in a second small gauge (complexity-gated).
	if complexity >= 5:
		_tub_pipe_run(parent,
			Vector3(0.22, 0.16, 0.26),
			Vector3(0.35, 0.78, 0.50).normalized(),
			0.034, 0.16, false, Vector3.UP, 0.0, "gauge_small")
	# A short spigot/tap on the -X end (still catches the 3/4 view).
	_tub_spigot(parent, Vector3(-0.52, -0.06, 0.16),
		Vector3(-0.78, -0.05, 0.45).normalized())


## One pipe run: a straight brass tube from a body socket along `dir`, optionally turning
## through a ~90° elbow, then a terminal fitting (`cap` = "valve" | "gauge" | "gauge_small").
## The whole pipe path is a polyline fed to MorphoPrimitive.multi_tube so straight+elbow are
## one mesh.
func _tub_pipe_run(parent: Node3D, socket: Vector3, dir: Vector3,
		radius: float, run_len: float, elbow: bool, elbow_dir: Vector3,
		elbow_len: float, cap: String) -> void:
	dir = dir.normalized()
	var start: Vector3 = socket - dir * 0.06          # sunk into the body
	var corner: Vector3 = socket + dir * run_len
	var positions: Array[Vector3] = [start]
	var radii: Array[float] = [radius * 1.25]          # flared collar at the body
	positions.append(socket + dir * 0.03)
	radii.append(radius * 1.12)
	positions.append(corner)
	radii.append(radius)

	var pipe_end: Vector3 = corner
	var end_dir: Vector3 = dir
	if elbow:
		end_dir = elbow_dir.normalized()
		var mid: Vector3 = corner + (dir + end_dir).normalized() * (radius * 1.3)
		positions.append(mid)
		radii.append(radius)
		pipe_end = corner + end_dir * elbow_len
		positions.append(pipe_end)
		radii.append(radius)

	var pipe_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, _TUB_PIPE_SIDES)
	var pipe_mat: StandardMaterial3D = _cf_metal_mat(color_b) if cap != "gauge_small" else _tub_steel_mat()
	_cf_add_mesh(parent, pipe_mesh, pipe_mat, Transform3D.IDENTITY, "Pipe")

	match cap:
		"valve":
			_tub_valve(parent, pipe_end, end_dir, radius)
		"gauge":
			_tub_gauge(parent, pipe_end, end_dir, 0.13, true)
		"gauge_small":
			_tub_gauge(parent, pipe_end, end_dir, 0.09, false)


## Cool STEEL fitting material (gauge rims, bolt feet) — a desaturated cousin of the brass
## metal material with the same emission floor so it reads in shade.
func _tub_steel_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.57, 0.62)
	m.metallic = clampf(maxf(metallic_amt, 0.7), 0.0, 1.0)
	m.roughness = clampf(rough_amt - 0.1, 0.05, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.55, 0.57, 0.62) * 0.5
	m.emission_energy_multiplier = _cf_glow_energy(0.14)
	return m


## RED mushroom-cap valve material — bright glossy emergency-style cap.
func _tub_red_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.18, 0.16)
	m.metallic = 0.1
	m.roughness = 0.3
	m.emission_enabled = true
	m.emission = Color(0.78, 0.18, 0.16) * 0.4
	m.emission_energy_multiplier = _cf_glow_energy(0.10)
	return m


## A valve: a hub disc + a hand-wheel torus crossed by spokes, oriented so the wheel plane
## faces along the pipe axis.
func _tub_valve(parent: Node3D, at: Vector3, axis: Vector3, pipe_r: float) -> void:
	var basis: Basis = _cf_basis_from_up(axis)
	var brass: StandardMaterial3D = _cf_metal_mat(color_b)
	var steel: StandardMaterial3D = _tub_steel_mat()

	# Hub: short brass collar where pipe meets wheel.
	var hub_profile: Array[Vector2] = [
		Vector2(pipe_r * 1.05, 0.0),
		Vector2(pipe_r * 1.25, 0.03),
		Vector2(pipe_r * 1.10, 0.07),
		Vector2(pipe_r * 0.85, 0.085)]
	_cf_add_mesh(parent, MorphoPrimitive.revolution(hub_profile, 14), brass,
		Transform3D(basis, at), "ValveHub")

	# Wheel: a torus lying in the plane perpendicular to the axis (TorusMesh rings around +Y).
	var wheel_outer: float = pipe_r * 2.4
	var wheel_inner: float = wheel_outer - pipe_r * 0.55
	var wheel_pos: Vector3 = at + axis.normalized() * 0.085
	_cf_add_mesh(parent, MorphoPrimitive.torus(wheel_inner, wheel_outer, 10, 24), steel,
		Transform3D(basis, wheel_pos), "ValveWheel")

	# Spokes: thin steel boxes across the wheel, in the wheel plane (basis X/Z), batched.
	var spoke_st := SurfaceTool.new()
	spoke_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spoke_n: int = 3
	for si: int in range(spoke_n):
		var ang: float = PI * float(si) / float(spoke_n)
		var radial_local := Vector3(cos(ang), 0.0, sin(ang))
		var spoke_dir: Vector3 = basis * radial_local
		var thick_dir: Vector3 = basis * Vector3(-sin(ang), 0.0, cos(ang))
		_cf_emit_box(spoke_st, wheel_pos, spoke_dir, basis.y, thick_dir,
			wheel_inner, pipe_r * 0.10, pipe_r * 0.10)
	spoke_st.generate_normals()
	_cf_add_mesh(parent, spoke_st.commit(), steel, Transform3D.IDENTITY, "ValveSpokes")


## A pressure gauge: a brass case + steel bezel rim around a pale enamel face disc with a dark
## needle and (on the big gauge) a faint accent glow ring. The face is laid perpendicular to
## the pipe axis and tipped toward the +X/+Z camera so the dial is legible.
func _tub_gauge(parent: Node3D, at: Vector3, axis: Vector3, dia: float, glow: bool) -> void:
	var look_axis: Vector3 = (axis.normalized() + Vector3(0.25, 0.10, 0.25)).normalized()
	var basis: Basis = _cf_basis_from_up(look_axis)
	var r: float = dia * 0.5
	var brass: StandardMaterial3D = _cf_metal_mat(color_b)
	var steel: StandardMaterial3D = _tub_steel_mat()

	# Case: short cylindrical brass body behind the face.
	var case_profile: Array[Vector2] = [
		Vector2(0.0, -0.02),
		Vector2(r * 0.95, -0.02),
		Vector2(r * 1.02, 0.01),
		Vector2(r * 1.02, 0.045),
		Vector2(r * 0.75, 0.05)]
	_cf_add_mesh(parent, MorphoPrimitive.revolution(case_profile, 22), brass,
		Transform3D(basis, at), "GaugeCase")

	# Rim: steel bezel torus at the face plane.
	var face_pos: Vector3 = at + look_axis * 0.05
	_cf_add_mesh(parent, MorphoPrimitive.torus(r * 0.86, r * 1.04, 8, 24), steel,
		Transform3D(basis, face_pos), "GaugeRim")

	# Face: a thin pale disc (flat revolution) sitting in the bezel.
	var face_profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(r * 0.90, 0.0),
		Vector2(r * 0.90, 0.006),
		Vector2(0.0, 0.006)]
	_cf_add_mesh(parent, MorphoPrimitive.revolution(face_profile, 24), _cf_gauge_face_mat(),
		Transform3D(basis, face_pos), "GaugeFace")

	# Needle: a thin dark box across the face pointing to a seeded reading.
	var read_ang: float = _rng.randf_range(-0.6, 0.9)
	var needle_dir: Vector3 = basis * Vector3(cos(read_ang), 0.0, sin(read_ang))
	var needle_thick: Vector3 = basis * Vector3(-sin(read_ang), 0.0, cos(read_ang))
	var nst := SurfaceTool.new()
	nst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var needle_centre: Vector3 = (face_pos + look_axis * 0.008) + needle_dir * (r * 0.42)
	_cf_emit_box(nst, needle_centre, needle_dir, basis.y, needle_thick,
		r * 0.5, r * 0.05, r * 0.045)
	nst.generate_normals()
	_cf_add_mesh(parent, nst.commit(), _cf_needle_mat(), Transform3D.IDENTITY, "GaugeNeedle")

	# Glow: faint accent ring just inside the rim (only on the big gauge).
	if glow:
		_cf_add_mesh(parent, MorphoPrimitive.torus(r * 0.70, r * 0.80, 6, 20),
			_cf_glow_mat(accent, 2.5), Transform3D(basis, face_pos + look_axis * 0.004), "GaugeGlow")


## Pale enamel gauge-dial face material.
func _cf_gauge_face_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.90, 0.90, 0.84)
	m.metallic = 0.0
	m.roughness = 0.25
	return m


## Dark gauge-needle material.
func _cf_needle_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.10, 0.12)
	m.metallic = 0.3
	m.roughness = 0.5
	return m


## A short spigot/tap: a small brass elbow ending in a downturned nozzle with a tiny red
## cross-handle on top. Built as a multi_tube elbow + a torus handle.
func _tub_spigot(parent: Node3D, socket: Vector3, dir: Vector3) -> void:
	dir = dir.normalized()
	var r: float = 0.030
	var out_len: float = 0.14
	var corner: Vector3 = socket + dir * out_len
	var down: Vector3 = Vector3(dir.x * 0.2, -1.0, dir.z * 0.2).normalized()
	var nozzle_end: Vector3 = corner + down * 0.11

	var positions: Array[Vector3] = [
		socket - dir * 0.04,
		socket + dir * 0.02,
		corner,
		corner + (dir + down).normalized() * (r * 1.2),
		nozzle_end]
	var radii: Array[float] = [r * 1.3, r * 1.15, r, r, r * 0.85]
	_cf_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 10), _cf_metal_mat(color_b),
		Transform3D.IDENTITY, "Spigot")

	# Cross-handle: a small red torus on top of the elbow, axis vertical (Codex pop).
	var handle_basis: Basis = _cf_basis_from_up(Vector3.UP)
	_cf_add_mesh(parent, MorphoPrimitive.torus(r * 1.1, r * 2.0, 8, 18), _tub_red_mat(),
		Transform3D(handle_basis, corner + Vector3.UP * 0.04), "SpigotHandle")


## Red mushroom-cap valve crowning the top, on a short brass neck.
func _tub_red_knob(parent: Node3D) -> void:
	var crown_y: float = _tub_body_centre.y + _tub_body_extent.y * 0.5 - 0.02
	var crown: Vector3 = Vector3(_tub_body_centre.x - 0.02, crown_y, _tub_body_centre.z + 0.04)
	var basis: Basis = _cf_basis_from_up(Vector3.UP)

	var neck_profile: Array[Vector2] = [
		Vector2(0.075, 0.0),
		Vector2(0.060, 0.05),
		Vector2(0.055, 0.10),
		Vector2(0.070, 0.12)]
	_cf_add_mesh(parent, MorphoPrimitive.revolution(neck_profile, 16), _cf_metal_mat(color_b),
		Transform3D(basis, crown), "KnobNeck")

	var cap_base_y: float = 0.12
	var cap_profile: Array[Vector2] = [
		Vector2(0.0, cap_base_y + 0.115),
		Vector2(0.055, cap_base_y + 0.112),
		Vector2(0.105, cap_base_y + 0.095),
		Vector2(0.140, cap_base_y + 0.060),
		Vector2(0.150, cap_base_y + 0.020),
		Vector2(0.140, cap_base_y - 0.010),
		Vector2(0.095, cap_base_y - 0.020),
		Vector2(0.070, cap_base_y)]
	_cf_add_mesh(parent, MorphoPrimitive.revolution(cap_profile, 28), _tub_red_mat(),
		Transform3D(basis, crown), "RedKnob")


## Four little hex bolt feet under the belly so it stands stably. Each is a tapered revolution
## (6 segments → reads as a nut) hanging below the body so its base lands on y=0 after lift.
func _tub_feet(parent: Node3D, foot_h: float) -> void:
	var belly_y: float = _tub_body_centre.y - _tub_body_extent.y * 0.5 + 0.04
	var spread_x: float = _tub_body_extent.x * 0.30
	var spread_z: float = _tub_body_extent.z * 0.30
	var foot_offsets: Array[Vector3] = [
		Vector3(spread_x, belly_y, spread_z),
		Vector3(-spread_x, belly_y, spread_z),
		Vector3(spread_x, belly_y, -spread_z),
		Vector3(-spread_x, belly_y, -spread_z)]
	var steel: StandardMaterial3D = _tub_steel_mat()

	for off: Vector3 in foot_offsets:
		var jitter := Vector3(_rng.randf_range(-0.02, 0.02), 0.0, _rng.randf_range(-0.02, 0.02))
		var top: Vector3 = off + jitter
		var basis: Basis = _cf_basis_from_up(Vector3.UP)
		var shaft_profile: Array[Vector2] = [
			Vector2(0.045, 0.0),
			Vector2(0.038, -foot_h * 0.45),
			Vector2(0.050, -foot_h * 0.55),
			Vector2(0.050, -foot_h * 0.78),
			Vector2(0.034, -foot_h * 0.86),
			Vector2(0.030, -foot_h),
			Vector2(0.0, -foot_h)]
		_cf_add_mesh(parent, MorphoPrimitive.revolution(shaft_profile, 6), steel,
			Transform3D(basis, top), "Foot")


## A few darker "eyes" / spots pressed onto the visible (+X/+Z) flank, each a squashed sphere
## sitting just proud of the skin.
func _tub_eyes(parent: Node3D) -> void:
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = color_a * 0.65
	eye_mat.roughness = 0.9
	eye_mat.metallic = 0.0
	eye_mat.emission_enabled = true
	eye_mat.emission = color_a * 0.26
	eye_mat.emission_energy_multiplier = _cf_glow_energy(0.06)

	var n_eyes: int = 7
	for i: int in range(n_eyes):
		var dir := Vector3(
			_rng.randf_range(-0.2, 1.0),
			_rng.randf_range(-0.5, 0.7),
			_rng.randf_range(-0.2, 1.0)).normalized()
		var pos: Vector3 = _tub_body_centre + dir * (_tub_body_extent.length() * 0.5 * 0.46)
		var basis: Basis = _cf_basis_from_up(dir)
		var eye_r: float = _rng.randf_range(0.028, 0.046)
		var squash := Basis().scaled(Vector3(1.0, 0.4, 1.0))
		_cf_add_mesh(parent, MorphoPrimitive.sphere(eye_r, 8, 5), eye_mat,
			Transform3D(basis * squash, pos), "Eye")


# =============================================================================
# MODE: candleroot — a red RADISH/BEET that is a lit CANDLE (trial v2)
# =============================================================================

const _CAN_BULB_MAX_RADIUS: float = 0.37
const _CAN_BULB_TOP_Y: float = 0.98
const _CAN_BULB_BOTTOM_Y: float = 0.34
const _CAN_BULB_FAT_FRAC: float = 0.66
const _CAN_BULB_SEGMENTS: int = 44
const _CAN_BULB_RINGS: int = 30
const _CAN_BULB_BUMP_AMP: float = 0.012
const _CAN_TAIL_TOP_RADIUS: float = 0.075
const _CAN_TAIL_TIP_RADIUS: float = 0.010
const _CAN_TAIL_SAMPLES: int = 9
const _CAN_TAIL_SIDES: int = 8
const _CAN_WICK_HEIGHT: float = 0.045
const _CAN_WICK_RADIUS: float = 0.010
const _CAN_FLAME_HEIGHT: float = 0.34
const _CAN_FLAME_RADIUS: float = 0.105
const _CAN_FLAME_SEGMENTS: int = 20
const _CAN_DRIP_SIDES: int = 8
const _CAN_POOL_RADIUS: float = 0.20
const _CAN_LEAF_SEGMENTS: int = 12

const _CAN_BLUSH_COLOR := Color(0.92, 0.82, 0.80)    # pale blush near the base
const _CAN_WAX_COLOR := Color(0.93, 0.90, 0.80)      # warm white wax


func _build_candleroot() -> void:
	var rig := Node3D.new()
	rig.name = "CandleRadish"
	add_child(rig)

	_can_wax_pool(rig)
	_can_root_tail(rig)
	_can_bulb(rig)
	_can_wax_drips(rig)
	_can_greens(rig)
	_can_flame(rig)

	# Rest on y=0 (lowest mesh → floor), centre, scale to sculpt size.
	_cf_settle(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


## A plump bulb: pinched neck at the bottom, swelling to its fattest girth high up, rounding
## to the crown. A revolution, nudged with gentle noise, then vertex-painted with a base→crown
## blush gradient (pale near the base). The skin material reads vertex colour as albedo.
func _can_bulb(parent: Node3D) -> void:
	var height: float = _CAN_BULB_TOP_Y - _CAN_BULB_BOTTOM_Y
	var profile: Array[Vector2] = []
	profile.append(Vector2(0.0, _CAN_BULB_BOTTOM_Y - 0.01))
	for ri: int in range(_CAN_BULB_RINGS + 1):
		var t: float = float(ri) / float(_CAN_BULB_RINGS)
		var y: float = _CAN_BULB_BOTTOM_Y + t * height
		var r: float = _can_bulb_radius(t)
		profile.append(Vector2(maxf(r, 0.0006), y))
	profile.append(Vector2(0.0, _CAN_BULB_TOP_Y + 0.004))

	var mesh: ArrayMesh = MorphoPrimitive.revolution(profile, _CAN_BULB_SEGMENTS) as ArrayMesh
	if mesh == null:
		return
	if _CAN_BULB_BUMP_AMP > 0.0:
		var lump := FastNoiseLite.new()
		lump.seed = _rng.randi()
		lump.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		lump.frequency = 1.6
		var bumped: ArrayMesh = MorphoModifier.noise_displace(mesh, lump, _CAN_BULB_BUMP_AMP)
		if bumped != null:
			mesh = bumped

	var painted: ArrayMesh = _can_paint_height_blush(mesh)
	_cf_add_mesh(parent, painted, _can_skin_mat(), Transform3D.IDENTITY, "RadishBulb")


## Radish skin material — color_a, vertex-colour blush blended in, juicy subsurface, faint
## emission floor.
func _can_skin_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_a
	m.vertex_color_use_as_albedo = true
	m.roughness = clampf(rough_amt + 0.2, 0.5, 0.9)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.25
	m.emission_enabled = true
	m.emission = color_a * 0.4
	m.emission_energy_multiplier = _cf_glow_energy(0.10)
	return m


## Radish/beet radius at normalized bulb height t (0 = neck base, 1 = crown). A plump
## top-heavy bulb: a circular-arc belly rising to its widest girth high up, then a broad
## rounded shoulder easing into a still-wide crown.
func _can_bulb_radius(t: float) -> float:
	var tt: float = clampf(t, 0.0, 1.0)
	var peak: float = _CAN_BULB_FAT_FRAC
	var arch: float
	if tt <= peak:
		var u: float = tt / maxf(peak, 0.001)
		arch = sqrt(clampf(u * (2.0 - u), 0.0, 1.0))
	else:
		var u2: float = (tt - peak) / maxf(1.0 - peak, 0.001)
		arch = lerpf(1.0, 0.46, smoothstep(0.0, 1.0, u2))
	var neck: float = _CAN_TAIL_TOP_RADIUS * 1.4
	return lerpf(neck, _CAN_BULB_MAX_RADIUS, clampf(arch, 0.0, 1.0))


## The root tail: a thin tube that leaves the bulb neck and tapers to a whisker as it curves
## down to rest in the wax pool on y=0. A gentle seeded sway (baked to locals before the loop).
func _can_root_tail(parent: Node3D) -> void:
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var top: Vector3 = Vector3(0.0, _CAN_BULB_BOTTOM_Y + 0.02, 0.0)
	var sway_ang: float = _rng.randf_range(0.0, TAU)
	var sway_dir: Vector3 = Vector3(cos(sway_ang), 0.0, sin(sway_ang))
	var sway_amt: float = _rng.randf_range(0.02, 0.05)

	for i: int in range(_CAN_TAIL_SAMPLES):
		var t: float = float(i) / float(_CAN_TAIL_SAMPLES - 1)
		var y: float = lerpf(top.y, 0.012, t)
		var bend: float = sin(t * PI) * sway_amt + t * sway_amt * 0.6
		var wob: float = sin(t * 7.0) * 0.006
		positions.append(Vector3(0.0, y, 0.0) + sway_dir * (bend + wob))
		radii.append(lerpf(_CAN_TAIL_TOP_RADIUS, _CAN_TAIL_TIP_RADIUS, pow(t, 0.7)))

	# The skin material reads vertex colour; the tail has none, so give it a plain pale-blush
	# variant (no vertex_color_use_as_albedo) tinted toward the base blush.
	_cf_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, _CAN_TAIL_SIDES),
		_can_tail_mat(), Transform3D.IDENTITY, "RootTail")


## Root-tail material — a pale-blush blend of the skin colour (no vertex colour).
func _can_tail_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_a.lerp(_CAN_BLUSH_COLOR, 0.6)
	m.roughness = clampf(rough_amt + 0.2, 0.5, 0.9)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.25
	m.emission_enabled = true
	m.emission = color_a * 0.3
	m.emission_energy_multiplier = _cf_glow_energy(0.08)
	return m


## The hero. A dark wick stub at the crown, an emissive teardrop FLAME (revolution), a fatter
## fainter additive HALO sleeve, and a warm OmniLight at the flame core so it casts a real
## little glow. Flame/halo use accent; the light is warm gold.
func _can_flame(parent: Node3D) -> void:
	var crown: Vector3 = Vector3(0.0, _CAN_BULB_TOP_Y, 0.0)

	# Wick stub — kept low so it is enveloped by the flame above.
	_cf_add_mesh(parent, MorphoPrimitive.cylinder(_CAN_WICK_RADIUS * 0.7, _CAN_WICK_RADIUS,
		_CAN_WICK_HEIGHT, 8), _can_wick_mat(),
		Transform3D(Basis.IDENTITY, crown + Vector3(0.0, _CAN_WICK_HEIGHT * 0.5, 0.0)), "Wick")

	var flame_base_y: float = crown.y - 0.01

	# Flame teardrop (revolution, rounded low then pointed) — unshaded glow.
	_cf_add_mesh(parent, MorphoPrimitive.revolution(
		_can_teardrop_profile(_CAN_FLAME_RADIUS, _CAN_FLAME_HEIGHT, flame_base_y, 0.40),
		_CAN_FLAME_SEGMENTS), _cf_glow_mat(accent, 6.0), Transform3D.IDENTITY, "Flame")

	# Additive halo sleeve: a fatter, taller teardrop, low-alpha add blend.
	_cf_add_mesh(parent, MorphoPrimitive.revolution(
		_can_teardrop_profile(_CAN_FLAME_RADIUS * 1.7, _CAN_FLAME_HEIGHT * 1.32,
			flame_base_y - 0.02, 0.46), _CAN_FLAME_SEGMENTS),
		_cf_halo_mat(accent.lerp(Color(1.0, 0.80, 0.42), 0.4), 3.0),
		Transform3D.IDENTITY, "FlameHalo")

	# Warm OmniLight at the flame core (gated by emissive).
	var light := OmniLight3D.new()
	light.name = "FlameLight"
	light.light_color = Color(1.0, 0.74, 0.42)
	light.light_energy = 2.0 if emissive else 1.0
	light.omni_range = 2.4
	light.omni_attenuation = 1.3
	light.position = Vector3(0.0, flame_base_y + _CAN_FLAME_HEIGHT * 0.4, 0.0)
	parent.add_child(light)


## Charred dark wick material.
func _can_wick_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.08, 0.07)
	m.roughness = 0.9
	m.metallic = 0.0
	return m


## Teardrop profile (radius, absolute height) bottom→top for a revolution: a point on the
## axis at base_y, swelling to max_r at bulge_frac, then tapering to a sharp point on top.
func _can_teardrop_profile(max_r: float, total_h: float, base_y: float, bulge_frac: float) -> Array[Vector2]:
	var rings: int = 14
	var profile: Array[Vector2] = []
	for i: int in range(rings + 1):
		var t: float = float(i) / float(rings)
		var y: float = base_y + t * total_h
		var r: float
		if t <= bulge_frac:
			var u: float = t / maxf(bulge_frac, 0.001)
			r = sin(u * (PI * 0.5)) * max_r
		else:
			var u2: float = (t - bulge_frac) / maxf(1.0 - bulge_frac, 0.001)
			r = max_r * pow(1.0 - u2, 1.6)
		profile.append(Vector2(maxf(r, 0.0006), y))
	return profile


## A handful of wax runs that start high on the bulb shoulder and flow down over the belly,
## riding a fixed clearance proud of the bulb surface, ending in a rounded bead. Fanned across
## the camera-facing front so they all read. complexity scales the drip count. All seeded
## angles/lengths baked to locals first.
func _can_wax_drips(parent: Node3D) -> void:
	var drip_count: int = clampi(3 + complexity / 3, 4, 7)
	var height: float = _CAN_BULB_TOP_Y - _CAN_BULB_BOTTOM_Y
	var wax_mat: StandardMaterial3D = _can_wax_mat()
	var cam_ang: float = atan2(1.0, 0.62)
	var fan: float = deg_to_rad(150.0)
	for d: int in range(drip_count):
		var slot: float = (float(d) + 0.5) / float(drip_count) - 0.5
		var ang: float = cam_ang + slot * fan + _rng.randf_range(-0.12, 0.12)
		var cos_a: float = cos(ang)
		var sin_a: float = sin(ang)
		var top_r: float = _rng.randf_range(0.020, 0.030)
		var start_t: float = _rng.randf_range(0.88, 0.96)
		var len_bias: float = 0.62 if (d % 2 == 1) else 0.40
		var run_len: float = len_bias + _rng.randf_range(-0.08, 0.12)
		var end_t: float = clampf(start_t - run_len, 0.10, start_t - 0.22)
		var y_top: float = _CAN_BULB_BOTTOM_Y + start_t * height
		var y_bot: float = _CAN_BULB_BOTTOM_Y + end_t * height
		var clearance: float = top_r * 0.55
		var tan_dir: Vector3 = Vector3(-sin_a, 0.0, cos_a)
		var drift: float = _rng.randf_range(-0.015, 0.015)
		var samples: int = 14

		var positions: Array[Vector3] = []
		var radii: Array[float] = []
		for i: int in range(samples):
			var f: float = float(i) / float(samples - 1)
			var y: float = lerpf(y_top, y_bot, f)
			var t: float = (y - _CAN_BULB_BOTTOM_Y) / maxf(height, 0.001)
			var rad_h: float = _can_bulb_radius(t) + clearance
			var radial: Vector3 = Vector3(cos_a, 0.0, sin_a) * rad_h
			positions.append(radial + Vector3(0.0, y, 0.0) + tan_dir * (drift * f))
			var rad: float = top_r * lerpf(1.0, 0.45, smoothstep(0.0, 0.85, f))
			if i == samples - 1:
				rad = top_r * 0.92
			elif i == samples - 2:
				rad = top_r * 0.62
			radii.append(rad)

		_cf_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, _CAN_DRIP_SIDES),
			wax_mat, Transform3D.IDENTITY, "WaxDrip_%d" % d)


## Warm creamy wax material — fully matte diffuse (SSS + a bright key blew the thin runs into
## broken hot specks; plain rough diffuse reads as continuous soft wax). No deprecated APIs.
func _can_wax_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = _CAN_WAX_COLOR
	m.roughness = 0.95
	m.metallic = 0.0
	return m


## A small wax pool the radish-candle stands in, on y=0. A low revolution disc with a soft
## raised lip.
func _can_wax_pool(parent: Node3D) -> void:
	var profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(_CAN_POOL_RADIUS * 0.55, 0.004),
		Vector2(_CAN_POOL_RADIUS * 0.86, 0.018),
		Vector2(_CAN_POOL_RADIUS * 1.00, 0.030),
		Vector2(_CAN_POOL_RADIUS * 0.95, 0.014),
		Vector2(_CAN_POOL_RADIUS * 0.80, 0.006)]
	_cf_add_mesh(parent, MorphoPrimitive.revolution(profile, 28), _can_wax_mat(),
		Transform3D.IDENTITY, "WaxPool")


## A few leaves sprouting near the crown, splaying up and out. Each blade is a flat tapered
## cross-section swept along an upward-arcing cubic Bézier, then tapered to a point. All
## control points + cross section baked to locals BEFORE the sweep. Uses color_b (leaf green).
func _can_greens(parent: Node3D) -> void:
	var leaf_count: int = clampi(3 + complexity / 3, 4, 6)
	var leaf_mat: StandardMaterial3D = _can_leaf_mat()
	var crown_y: float = _CAN_BULB_TOP_Y - 0.02
	var rim_r: float = _can_bulb_radius(0.985) * 0.6

	for l: int in range(leaf_count):
		var ang: float = (TAU * float(l) / float(leaf_count)) + _rng.randf_range(-0.3, 0.3)
		var cos_a: float = cos(ang)
		var sin_a: float = sin(ang)
		var out_dir: Vector3 = Vector3(cos_a, 0.0, sin_a)
		var length: float = _rng.randf_range(0.34, 0.46)
		var lean: float = _rng.randf_range(0.45, 0.72)
		var width: float = _rng.randf_range(0.045, 0.075)
		var curl: float = _rng.randf_range(0.05, 0.14)

		var base: Vector3 = Vector3(out_dir.x * rim_r, crown_y, out_dir.z * rim_r)
		var p0: Vector3 = base
		var p1: Vector3 = base + Vector3(out_dir.x * length * 0.20, length * 0.45, out_dir.z * length * 0.20)
		var p2: Vector3 = base + Vector3(out_dir.x * length * lean, length * 0.78, out_dir.z * length * lean)
		var p3: Vector3 = base + Vector3(out_dir.x * (length * lean + curl), length * 1.02, out_dir.z * (length * lean + curl))
		var control_points: Array = [p0, p1, p2, p3]

		var hw: float = width * 0.5
		var th: float = width * 0.06
		var cross_section: Array = [
			Vector2(-hw, 0.0),
			Vector2(-hw * 0.5, th),
			Vector2(0.0, th * 1.3),
			Vector2(hw * 0.5, th),
			Vector2(hw, 0.0),
			Vector2(hw * 0.5, -th),
			Vector2(0.0, -th * 1.3),
			Vector2(-hw * 0.5, -th)]

		var twist_deg: float = _rng.randf_range(-25.0, 25.0)
		var mesh: Mesh = MorphoPrimitive.bezier_sweep(control_points, cross_section,
			_CAN_LEAF_SEGMENTS, twist_deg)
		if mesh == null:
			continue
		var tapered: ArrayMesh = _can_taper_blade(mesh, p0, p3)
		_cf_add_mesh(parent, tapered if tapered != null else mesh, leaf_mat,
			Transform3D.IDENTITY, "Leaf_%d" % l)


## Leaf material — color_b (green), two-sided thin blades, faint subsurface + emission floor.
func _can_leaf_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_b
	m.roughness = 0.7
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.2
	m.emission_enabled = true
	m.emission = color_b * 0.4
	m.emission_energy_multiplier = _cf_glow_energy(0.08)
	return m


## Taper a swept blade so it narrows to a point at the tip: scale each vertex's offset from
## the base→tip axis by (1 - s)^0.65 along that axis.
func _can_taper_blade(mesh: Mesh, base: Vector3, tip: Vector3) -> ArrayMesh:
	var axis: Vector3 = tip - base
	var axis_len2: float = axis.length_squared()
	if axis_len2 < 0.0001:
		return null
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	var arr: ArrayMesh = st.commit()
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(arr, 0) != OK:
		return null
	for i: int in range(mdt.get_vertex_count()):
		var v: Vector3 = mdt.get_vertex(i)
		var s: float = clampf((v - base).dot(axis) / axis_len2, 0.0, 1.0)
		var on_axis: Vector3 = base + axis * s
		var perp: Vector3 = v - on_axis
		var sc: float = pow(1.0 - s, 0.65)
		mdt.set_vertex(i, on_axis + perp * sc)
	var out := ArrayMesh.new()
	mdt.commit_to_surface(out)
	var st2 := SurfaceTool.new()
	st2.create_from(out, 0)
	st2.generate_normals()
	return st2.commit()


## Re-emit a bulb mesh, painting each vertex's albedo with a base→crown gradient: pale BLUSH
## near the bottom, deep SKIN higher up. Welds into an ArrayMesh with regenerated normals.
func _can_paint_height_blush(mesh: Mesh) -> ArrayMesh:
	var src := SurfaceTool.new()
	src.create_from(mesh, 0)
	var arr: ArrayMesh = src.commit()
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(arr, 0) != OK:
		return arr
	var lo: float = _CAN_BULB_BOTTOM_Y
	var hi: float = _CAN_BULB_TOP_Y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f: int in range(mdt.get_face_count()):
		for k: int in range(3):
			var vi: int = mdt.get_face_vertex(f, k)
			var v: Vector3 = mdt.get_vertex(vi)
			var n: Vector3 = mdt.get_vertex_normal(vi)
			var t: float = clampf((v.y - lo) / maxf(hi - lo, 0.001), 0.0, 1.0)
			var blush: float = 1.0 - smoothstep(0.04, 0.42, t)
			var col: Color = color_a.lerp(_CAN_BLUSH_COLOR, blush)
			st.set_color(col)
			st.set_normal(n)
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# =============================================================================
# MODE: seedpod — a green GOURD/PEPPER cut open, packed with glowing SEEDS (trial v3)
# =============================================================================

const _SEED_BODY_HEIGHT: float = 1.02
const _SEED_BODY_RADIUS: float = 0.46
const _SEED_PROFILE_RINGS: int = 28
const _SEED_ARC_SEGMENTS: int = 48
const _SEED_WALL_THICK: float = 0.075
const _SEED_LOBES: int = 5
const _SEED_LOBE_DEPTH: float = 0.085
const _SEED_WEDGE_DEGREES: float = 72.0
const _SEED_CAMERA_BEARING_DEG: float = 45.0
const _SEED_SPECIMEN_YAW_DEG: float = -28.0
const _SEED_BEAD_R: float = 0.052
const _SEED_PLACENTA_RINGS: int = 7
const _SEED_PLACENTA_PER_RING: int = 11
const _SEED_LOOSE_SEEDS: int = 6

# Derived arc bounds (radians), filled in _build_seedpod.
var _seed_arc_start: float = 0.0
var _seed_arc_end: float = 0.0


func _build_seedpod() -> void:
	# Kept arc = full circle minus the wedge; the wedge is centred ON the camera bearing so
	# the OPENING faces the camera.
	var wedge: float = deg_to_rad(_SEED_WEDGE_DEGREES)
	var bearing: float = deg_to_rad(_SEED_CAMERA_BEARING_DEG)
	_seed_arc_start = bearing + wedge * 0.5
	_seed_arc_end = bearing + TAU - wedge * 0.5

	var rig := Node3D.new()
	rig.name = "GourdSpecimen"
	add_child(rig)

	var specimen := Node3D.new()
	specimen.name = "Specimen"
	# Yaw the whole specimen so the cut wedge presents as a 3/4 view to the +X/+Z camera.
	specimen.rotation.y = deg_to_rad(_SEED_SPECIMEN_YAW_DEG)
	rig.add_child(specimen)

	var skin_mat: StandardMaterial3D = _seed_skin_mat()
	var flesh_mat: StandardMaterial3D = _cf_pale_mat(_seed_flesh_color(), true, true)
	var seed_mat: StandardMaterial3D = _cf_glow_mat(accent, 2.9)

	# Outer skin (open-arc), normals outward.
	_cf_add_mesh(specimen, _seed_arc_shell(0.0, false), skin_mat, Transform3D.IDENTITY, "Skin")
	# Inner flesh wall (open-arc, pulled in by WALL_THICK), normals inward; two-sided material.
	_cf_add_mesh(specimen, _seed_arc_shell(_SEED_WALL_THICK, true), flesh_mat,
		Transform3D.IDENTITY, "InnerFlesh")
	# Skin top/bottom caps.
	_cf_add_mesh(specimen, _seed_body_caps(), skin_mat, Transform3D.IDENTITY, "BodyCaps")
	# Thick cut walls (flesh band on the two wedge faces).
	_cf_add_mesh(specimen, _seed_cut_walls(), flesh_mat, Transform3D.IDENTITY, "CutWalls")
	# Seeds + placenta + stem.
	_seed_cluster(specimen, seed_mat)
	_seed_stem(specimen)
	# Loose spilled seeds parented to the rig (world bearing) so they spill in front of the cut.
	_seed_loose(rig, seed_mat)

	# Stand on y=0, centre, scale to sculpt size (gourd profile already seats at y=0).
	_cf_settle(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


## Glossy waxy green pepper skin material (color_a), low roughness for a specular rim.
func _seed_skin_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_a
	m.roughness = clampf(rough_amt - 0.12, 0.2, 0.6)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.20
	m.emission_enabled = true
	m.emission = color_a * 0.4
	m.emission_energy_multiplier = _cf_glow_energy(0.10)
	return m


## Pale cream-green inner flesh colour, derived from the secondary colour pulled toward cream.
func _seed_flesh_color() -> Color:
	return color_b.lerp(Color(0.92, 0.94, 0.82), 0.55)


## Base body radius at normalized height t in [0,1] (0 = seat on y=0, 1 = shoulder/stem). A
## bell/gourd: pinched at the base, bulging belly low-mid, gently necking toward the shoulder.
func _seed_body_radius(t: float) -> float:
	var tt: float = clampf(t, 0.0, 1.0)
	var belly: float = sin(pow(tt, 0.85) * PI)
	var base_pinch: float = smoothstep(0.0, 0.16, tt)
	var shoulder: float = 1.0 - smoothstep(0.78, 1.0, tt) * 0.62
	var r: float = _SEED_BODY_RADIUS * (0.30 + 0.70 * belly) * base_pinch * shoulder
	return maxf(r, 0.012)


## Body height (world Y) for normalized t.
func _seed_body_y(t: float) -> float:
	return clampf(t, 0.0, 1.0) * _SEED_BODY_HEIGHT


## Per-angle lobe ripple — the vertical pepper ridges. Cosine with LOBES periods, fading near
## the seat and shoulder so the lobes live on the belly.
func _seed_lobe_factor(angle: float, t: float) -> float:
	var ridge: float = cos(angle * float(_SEED_LOBES))
	var belly_mask: float = sin(clampf(t, 0.0, 1.0) * PI)
	return ridge * _SEED_LOBE_DEPTH * belly_mask


## One open-arc shell of revolution. For each profile ring (over t) and each angular step
## across [_seed_arc_start, _seed_arc_end], place a vertex at (radius cos, y, radius sin).
## radius = base body radius * + lobe ripple - inset, so the same routine builds the OUTER
## skin (inset 0) and the INNER flesh wall (inset = WALL_THICK). `flip` reverses winding for
## the inner shell so its normals face inward. (Toolkit revolution is 360°; this sweeps < TAU.)
func _seed_arc_shell(radial_inset: float, flip: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for ri: int in range(_SEED_PROFILE_RINGS + 1):
		var t: float = float(ri) / float(_SEED_PROFILE_RINGS)
		var y: float = _seed_body_y(t)
		var base_r: float = _seed_body_radius(t)
		var row: Array[Vector3] = []
		for si: int in range(_SEED_ARC_SEGMENTS + 1):
			var a_frac: float = float(si) / float(_SEED_ARC_SEGMENTS)
			var angle: float = lerpf(_seed_arc_start, _seed_arc_end, a_frac)
			var r: float = base_r + _seed_lobe_factor(angle, t) - radial_inset
			r = maxf(r, 0.006)
			row.append(Vector3(cos(angle) * r, y, sin(angle) * r))
		rings.append(row)

	for ri: int in range(_SEED_PROFILE_RINGS):
		var row_a: Array = rings[ri] as Array
		var row_b: Array = rings[ri + 1] as Array
		for si: int in range(_SEED_ARC_SEGMENTS):
			var v00: Vector3 = row_a[si] as Vector3
			var v01: Vector3 = row_a[si + 1] as Vector3
			var v10: Vector3 = row_b[si] as Vector3
			var v11: Vector3 = row_b[si + 1] as Vector3
			if flip:
				_cf_tri(st, v00, v01, v10)
				_cf_tri(st, v01, v11, v10)
			else:
				_cf_tri(st, v00, v10, v01)
				_cf_tri(st, v01, v10, v11)

	st.generate_normals()
	return st.commit()


## Cap the body: close the bottom seat and the top shoulder so the skin shell is not an open
## tube. The radial cut edges are handled by _seed_cut_walls.
func _seed_body_caps() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var t0: float = 0.0
	var y0: float = _seed_body_y(t0)
	var centre0: Vector3 = Vector3(0.0, y0, 0.0)
	var base_r0: float = _seed_body_radius(t0)
	for si: int in range(_SEED_ARC_SEGMENTS):
		var a0: float = lerpf(_seed_arc_start, _seed_arc_end, float(si) / float(_SEED_ARC_SEGMENTS))
		var a1: float = lerpf(_seed_arc_start, _seed_arc_end, float(si + 1) / float(_SEED_ARC_SEGMENTS))
		var r0a: float = maxf(base_r0 + _seed_lobe_factor(a0, t0), 0.006)
		var r1a: float = maxf(base_r0 + _seed_lobe_factor(a1, t0), 0.006)
		var p0: Vector3 = Vector3(cos(a0) * r0a, y0, sin(a0) * r0a)
		var p1: Vector3 = Vector3(cos(a1) * r1a, y0, sin(a1) * r1a)
		_cf_tri(st, centre0, p1, p0)

	var t1: float = 1.0
	var y1: float = _seed_body_y(t1)
	var centre1: Vector3 = Vector3(0.0, y1, 0.0)
	var base_r1: float = _seed_body_radius(t1)
	for si: int in range(_SEED_ARC_SEGMENTS):
		var a0: float = lerpf(_seed_arc_start, _seed_arc_end, float(si) / float(_SEED_ARC_SEGMENTS))
		var a1: float = lerpf(_seed_arc_start, _seed_arc_end, float(si + 1) / float(_SEED_ARC_SEGMENTS))
		var r0a: float = maxf(base_r1 + _seed_lobe_factor(a0, t1), 0.006)
		var r1a: float = maxf(base_r1 + _seed_lobe_factor(a1, t1), 0.006)
		var p0: Vector3 = Vector3(cos(a0) * r0a, y1, sin(a0) * r0a)
		var p1: Vector3 = Vector3(cos(a1) * r1a, y1, sin(a1) * r1a)
		_cf_tri(st, centre1, p0, p1)

	st.generate_normals()
	return st.commit()


## The two flat CUT WALLS — the radial faces of the wedge. Each is a quad-strip up the body at
## a fixed angle, spanning from the inner-flesh radius out to the outer-skin radius, so the
## slice shows a wall of finite thickness (the flesh band). Flesh material.
func _seed_cut_walls() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for which: int in range(2):
		var angle: float = _seed_arc_start if which == 0 else _seed_arc_end
		var dir: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var tang: Vector3 = Vector3(-sin(angle), 0.0, cos(angle))
		var face_n: Vector3 = tang if which == 0 else -tang
		var prev_outer := Vector3.ZERO
		var prev_inner := Vector3.ZERO
		var have_prev: bool = false
		for ri: int in range(_SEED_PROFILE_RINGS + 1):
			var t: float = float(ri) / float(_SEED_PROFILE_RINGS)
			var y: float = _seed_body_y(t)
			var base_r: float = _seed_body_radius(t)
			var outer_r: float = maxf(base_r + _seed_lobe_factor(angle, t), 0.006)
			var inner_r: float = maxf(outer_r - _SEED_WALL_THICK, 0.004)
			var outer_p: Vector3 = dir * outer_r + Vector3.UP * y
			var inner_p: Vector3 = dir * inner_r + Vector3.UP * y
			if have_prev:
				if which == 0:
					_cf_tri_n(st, prev_inner, prev_outer, outer_p, face_n)
					_cf_tri_n(st, prev_inner, outer_p, inner_p, face_n)
				else:
					_cf_tri_n(st, prev_inner, outer_p, prev_outer, face_n)
					_cf_tri_n(st, prev_inner, inner_p, outer_p, face_n)
			prev_outer = outer_p
			prev_inner = inner_p
			have_prev = true
	st.generate_normals()
	return st.commit()


## Pack the cavity with seeds clustered on a central placenta column. Seeds in PLACENTA_RINGS
## rows up a vertical core, scaled by complexity, each an anisotropically-scaled icosphere
## (ovoid) oriented with its long axis radially outward. All baked into ONE batched ArrayMesh
## (with the placenta) so the capture frames the whole glowing mass.
func _seed_cluster(parent: Node3D, seed_mat: StandardMaterial3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bead_template: ArrayMesh = _seed_unit_icosphere()
	var complexity_scale: float = clampf(0.6 + float(complexity) * 0.07, 0.6, 1.3)
	var per_ring: int = maxi(4, int(round(float(_SEED_PLACENTA_PER_RING) * complexity_scale)))

	for row: int in range(_SEED_PLACENTA_RINGS):
		var t: float = lerpf(0.16, 0.74, float(row) / float(_SEED_PLACENTA_RINGS - 1))
		var y: float = _seed_body_y(t)
		var wall_r: float = _seed_body_radius(t) - _SEED_WALL_THICK
		var taper: float = sin(clampf((t - 0.10) / 0.70, 0.0, 1.0) * PI)
		var ring_count: int = maxi(4, int(round(float(per_ring) * (0.55 + 0.45 * taper))))
		for k: int in range(ring_count):
			var ang: float = TAU * float(k) / float(ring_count)
			ang += _rng.randf_range(-0.10, 0.10)
			var rad_frac: float = _rng.randf_range(0.42, 0.92)
			var seat_r: float = maxf(wall_r * rad_frac, 0.02)
			var jy: float = _rng.randf_range(-0.022, 0.022)
			var pos: Vector3 = Vector3(cos(ang) * seat_r, y + jy, sin(ang) * seat_r)
			var sc: float = _SEED_BEAD_R * _rng.randf_range(0.82, 1.18)
			var long_axis: float = sc * _rng.randf_range(1.35, 1.7)
			var out_dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
			out_dir = (out_dir + Vector3(
				_rng.randf_range(-0.25, 0.25),
				_rng.randf_range(-0.35, 0.35),
				_rng.randf_range(-0.25, 0.25))).normalized()
			var basis: Basis = _cf_basis_long_axis(out_dir)
			basis = basis * Basis().scaled(Vector3(long_axis, sc, sc))
			_cf_bake_mesh(st, bead_template, Transform3D(basis, pos))

	_seed_bake_placenta(st)
	st.generate_normals()
	_cf_add_mesh(parent, st.commit(), seed_mat, Transform3D.IDENTITY, "SeedCluster")


## Loose seeds spilled on the ground at the base, in front of the cut (toward the camera
## bearing). Baked into their own small batch.
func _seed_loose(parent: Node3D, seed_mat: StandardMaterial3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bead_template: ArrayMesh = _seed_unit_icosphere()
	var bearing: float = deg_to_rad(_SEED_CAMERA_BEARING_DEG)
	for i: int in range(_SEED_LOOSE_SEEDS):
		var ang: float = bearing + _rng.randf_range(-0.7, 0.7)
		var dist: float = _rng.randf_range(_SEED_BODY_RADIUS * 0.9, _SEED_BODY_RADIUS * 1.55)
		var sc: float = _SEED_BEAD_R * _rng.randf_range(0.85, 1.1)
		var long_axis: float = sc * _rng.randf_range(1.4, 1.7)
		var pos: Vector3 = Vector3(cos(ang) * dist, sc * 0.7, sin(ang) * dist)
		var flat_dir: Vector3 = Vector3(
			cos(ang + _rng.randf_range(-1.2, 1.2)),
			_rng.randf_range(-0.15, 0.15),
			sin(ang + _rng.randf_range(-1.2, 1.2))).normalized()
		var basis: Basis = _cf_basis_long_axis(flat_dir)
		basis = basis * Basis().scaled(Vector3(long_axis, sc, sc))
		_cf_bake_mesh(st, bead_template, Transform3D(basis, pos))
	st.generate_normals()
	_cf_add_mesh(parent, st.commit(), seed_mat, Transform3D.IDENTITY, "LooseSeeds")


## Thin tapered placenta column baked into the seed batch (shares glow).
func _seed_bake_placenta(st: SurfaceTool) -> void:
	var profile: Array[Vector2] = [
		Vector2(0.010, _seed_body_y(0.14)),
		Vector2(0.030, _seed_body_y(0.30)),
		Vector2(0.034, _seed_body_y(0.48)),
		Vector2(0.026, _seed_body_y(0.64)),
		Vector2(0.012, _seed_body_y(0.76))]
	var col: Mesh = MorphoPrimitive.revolution(profile, 12)
	if col != null:
		_cf_bake_mesh(st, col, Transform3D(Basis(), Vector3.ZERO))


## A short curved woody stem rising from the shoulder, built with multi_tube + a tip nub.
func _seed_stem(parent: Node3D) -> void:
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.34, 0.40, 0.20)
	stem_mat.roughness = 0.8
	stem_mat.metallic = 0.0
	var shoulder_y: float = _seed_body_y(1.0)
	var positions: Array = [
		Vector3(0.0, shoulder_y - 0.01, 0.0),
		Vector3(0.012, shoulder_y + 0.08, -0.01),
		Vector3(-0.02, shoulder_y + 0.16, 0.015),
		Vector3(0.01, shoulder_y + 0.225, 0.0)]
	var radii: Array = [0.052, 0.040, 0.030, 0.020]
	_cf_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 8), stem_mat,
		Transform3D.IDENTITY, "Stem")
	_cf_add_mesh(parent, MorphoPrimitive.sphere(0.024, 8, 5), stem_mat,
		Transform3D(Basis(), Vector3(0.01, shoulder_y + 0.235, 0.0)), "StemTip")


## A unit-radius sphere mesh, committed once and reused as the seed bead template.
func _seed_unit_icosphere() -> ArrayMesh:
	var sph: Mesh = MorphoPrimitive.sphere(1.0, 10, 6)
	var st := SurfaceTool.new()
	st.create_from(sph, 0)
	return st.commit()


# =============================================================================
# MODE: zipfruit — a purple AUBERGINE unzipping to a CRYSTAL geode (trial v4)
# =============================================================================

const _ZIP_BODY_HEIGHT: float = 1.16
const _ZIP_BODY_RADIUS: float = 0.56
const _ZIP_PROFILE_RINGS: int = 22
const _ZIP_SHELL_ARC_SEGMENTS: int = 26
const _ZIP_GAP_DEGREES: float = 40.0
const _ZIP_SEAM_HALF_ANGLE: float = 6.0
const _ZIP_SKIN_THICKNESS: float = 0.045
const _ZIP_ZIPPER_TEETH: int = 15


func _build_zipfruit() -> void:
	var rig := Node3D.new()
	rig.name = "ZipFruit"
	add_child(rig)

	# The seam runs vertically; the split bisector points toward the +X/+Z camera. Each half
	# covers ~180° minus a small seam gap, hinged about the seam axis and rotated OUTWARD.
	var seam_dir_deg: float = 45.0
	var half_span: float = PI - deg_to_rad(_ZIP_SEAM_HALF_ANGLE) * 2.0
	var seam_a: float = deg_to_rad(seam_dir_deg) + deg_to_rad(_ZIP_SEAM_HALF_ANGLE)
	var seam_b: float = deg_to_rad(seam_dir_deg) - deg_to_rad(_ZIP_SEAM_HALF_ANGLE)

	# RIGHT half: arc from seam_a forward, hinged outward, with its zipper row.
	var right_half: MeshInstance3D = _zip_half_shell(seam_a, seam_a + half_span)
	var right_hinge := Node3D.new()
	right_hinge.name = "RightHinge"
	right_hinge.basis = Basis(Vector3.UP, deg_to_rad(-_ZIP_GAP_DEGREES))
	right_hinge.add_child(right_half)
	right_hinge.add_child(_zip_zipper_row(seam_a, 0))
	rig.add_child(right_hinge)

	# LEFT half: arc from seam_b backward, hinged the other way, with its zipper row.
	var left_half: MeshInstance3D = _zip_half_shell(seam_b - half_span, seam_b)
	var left_hinge := Node3D.new()
	left_hinge.name = "LeftHinge"
	left_hinge.basis = Basis(Vector3.UP, deg_to_rad(_ZIP_GAP_DEGREES))
	left_hinge.add_child(left_half)
	left_hinge.add_child(_zip_zipper_row(seam_b, 1))
	rig.add_child(left_hinge)

	# Pull-tab at the bottom of the split (on the static fruit).
	rig.add_child(_zip_pull_tab())

	# CORE — glowing crystal cluster nested in the gap, nudged toward the camera.
	var core_pos: Vector3 = Vector3(cos(deg_to_rad(seam_dir_deg)), 0.0, sin(deg_to_rad(seam_dir_deg))) * (_ZIP_BODY_RADIUS * 0.18)
	core_pos.y = _ZIP_BODY_HEIGHT * 0.46
	_zip_core(rig, core_pos)

	# STEM / calyx at the neck.
	_zip_stem(rig, Vector3(0.0, _ZIP_BODY_HEIGHT * 0.985, 0.0))

	# Stand on y=0, centre, scale to sculpt size (profile already seats at y=0).
	_cf_settle(rig, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2), true)


## Radius of the fruit body at normalized height t (0=base, 1=stem neck). A plump aubergine:
## round fat belly low, swelling wide through the middle, drawing in to a finite neck.
func _zip_body_radius_at(t: float) -> float:
	var ct: float = clampf(t, 0.0, 1.0)
	var belly: float = pow(sin(ct * PI), 0.72)
	var skew: float = pow(1.0 - ct * 0.55, 0.4)
	var r: float = belly * skew
	r = maxf(r, lerpf(0.18, 0.10, ct))
	return r * _ZIP_BODY_RADIUS


## One fruit half-shell as a partial surface of revolution: the body profile swept over
## [ang_start, ang_end] about Y. Two surfaces emitted to one mesh — an OUTER skin and an
## inward-offset INNER peel (flipped winding) — plus rim bands joining them along the seam
## edges + a bottom band, so the cut edge reads as skin thickness. Skin = surface 0 (color_a),
## inner peel = surface 1 (pale). Both materials CULL_DISABLED (open one-sided shells).
func _zip_half_shell(ang_start: float, ang_end: float) -> MeshInstance3D:
	var st_outer := SurfaceTool.new()
	st_outer.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_inner := SurfaceTool.new()
	st_inner.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_r: Array[float] = []
	var ring_y: Array[float] = []
	for pi: int in range(_ZIP_PROFILE_RINGS):
		var t: float = float(pi) / float(_ZIP_PROFILE_RINGS - 1)
		ring_r.append(_zip_body_radius_at(t))
		ring_y.append(t * _ZIP_BODY_HEIGHT)

	var seg: int = _ZIP_SHELL_ARC_SEGMENTS
	for ri: int in range(_ZIP_PROFILE_RINGS - 1):
		var r0: float = ring_r[ri]
		var r1: float = ring_r[ri + 1]
		var y0: float = ring_y[ri]
		var y1: float = ring_y[ri + 1]
		var ir0: float = maxf(r0 - _ZIP_SKIN_THICKNESS, r0 * 0.5)
		var ir1: float = maxf(r1 - _ZIP_SKIN_THICKNESS, r1 * 0.5)
		for ai: int in range(seg):
			var a0: float = lerpf(ang_start, ang_end, float(ai) / float(seg))
			var a1: float = lerpf(ang_start, ang_end, float(ai + 1) / float(seg))
			var ca0: float = cos(a0)
			var sa0: float = sin(a0)
			var ca1: float = cos(a1)
			var sa1: float = sin(a1)
			var o00: Vector3 = Vector3(ca0 * r0, y0, sa0 * r0)
			var o10: Vector3 = Vector3(ca1 * r0, y0, sa1 * r0)
			var o01: Vector3 = Vector3(ca0 * r1, y1, sa0 * r1)
			var o11: Vector3 = Vector3(ca1 * r1, y1, sa1 * r1)
			_zip_skin_quad(st_outer, o00, o01, o11, o10)
			var i00: Vector3 = Vector3(ca0 * ir0, y0, sa0 * ir0)
			var i10: Vector3 = Vector3(ca1 * ir0, y0, sa1 * ir0)
			var i01: Vector3 = Vector3(ca0 * ir1, y1, sa0 * ir1)
			var i11: Vector3 = Vector3(ca1 * ir1, y1, sa1 * ir1)
			_zip_skin_quad(st_inner, i00, i10, i11, i01)

	_zip_rim_band(st_outer, ring_r, ring_y, ang_start, true)
	_zip_rim_band(st_outer, ring_r, ring_y, ang_end, false)
	_zip_bottom_band(st_outer, ring_r[0], ring_y[0], ang_start, ang_end)

	st_outer.generate_normals()
	st_inner.generate_normals()

	var mesh := ArrayMesh.new()
	var outer_mesh: ArrayMesh = st_outer.commit()
	var inner_mesh: ArrayMesh = st_inner.commit()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, outer_mesh.surface_get_arrays(0))
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, inner_mesh.surface_get_arrays(0))

	var mi := MeshInstance3D.new()
	mi.name = "HalfShell"
	mi.mesh = mesh
	mi.set_surface_override_material(0, _zip_skin_mat())
	mi.set_surface_override_material(1, _cf_pale_mat(Color(0.90, 0.86, 0.78), true, false))
	return mi


## Outer aubergine skin material (color_a), glossy, two-sided (open shells), emission floor.
func _zip_skin_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_a
	m.roughness = clampf(rough_amt - 0.1, 0.2, 0.7)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.2
	m.emission_enabled = true
	m.emission = color_a
	m.emission_energy_multiplier = _cf_glow_energy(0.10)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## A skin quad with generated normals; winding a→b→c→d as two triangles.
func _zip_skin_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
	st.add_vertex(a); st.add_vertex(c); st.add_vertex(d)


## Cap the cut edge at angle `ang`: bridge the outer profile point to the inner profile point
## at each vertical segment so the seam shows skin thickness. `is_start` flips winding.
func _zip_rim_band(st: SurfaceTool, ring_r: Array[float], ring_y: Array[float],
		ang: float, is_start: bool) -> void:
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	for ri: int in range(_ZIP_PROFILE_RINGS - 1):
		var r0: float = ring_r[ri]
		var r1: float = ring_r[ri + 1]
		var y0: float = ring_y[ri]
		var y1: float = ring_y[ri + 1]
		var ir0: float = maxf(r0 - _ZIP_SKIN_THICKNESS, r0 * 0.5)
		var ir1: float = maxf(r1 - _ZIP_SKIN_THICKNESS, r1 * 0.5)
		var o0: Vector3 = Vector3(ca * r0, y0, sa * r0)
		var o1: Vector3 = Vector3(ca * r1, y1, sa * r1)
		var i0: Vector3 = Vector3(ca * ir0, y0, sa * ir0)
		var i1: Vector3 = Vector3(ca * ir1, y1, sa * ir1)
		if is_start:
			_zip_skin_quad(st, o0, i0, i1, o1)
		else:
			_zip_skin_quad(st, o0, o1, i1, i0)


## Close the bottom ring of one shell (outer→inner) so the base reads solid.
func _zip_bottom_band(st: SurfaceTool, r0: float, y0: float,
		ang_start: float, ang_end: float) -> void:
	var ir0: float = maxf(r0 - _ZIP_SKIN_THICKNESS, r0 * 0.5)
	var seg: int = _ZIP_SHELL_ARC_SEGMENTS
	for ai: int in range(seg):
		var a0: float = lerpf(ang_start, ang_end, float(ai) / float(seg))
		var a1: float = lerpf(ang_start, ang_end, float(ai + 1) / float(seg))
		var o0: Vector3 = Vector3(cos(a0) * r0, y0, sin(a0) * r0)
		var o1: Vector3 = Vector3(cos(a1) * r0, y0, sin(a1) * r0)
		var i0: Vector3 = Vector3(cos(a0) * ir0, y0, sin(a0) * ir0)
		var i1: Vector3 = Vector3(cos(a1) * ir0, y0, sin(a1) * ir0)
		_zip_skin_quad(st, o0, o1, i1, i0)


## One row of zipper teeth as a batched ArrayMesh. The row runs up the seam at angular
## position `ang`, teeth alternating (staggered by `phase`) so the two rows interlock. Teeth
## are small Basis-oriented boxes in fruit-local space, just proud of the skin at each height.
func _zip_zipper_row(ang: float, phase: int) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var radial: Vector3 = Vector3(ca, 0.0, sa)
	var tangent: Vector3 = Vector3(-sa, 0.0, ca)
	var tooth_w: float = 0.030
	var tooth_h: float = 0.022
	var tooth_d: float = 0.040
	var y_lo: float = _ZIP_BODY_HEIGHT * 0.16
	var y_hi: float = _ZIP_BODY_HEIGHT * 0.86
	for ti: int in range(_ZIP_ZIPPER_TEETH):
		if (ti + phase) % 2 == 0:
			continue
		var f: float = float(ti) / float(_ZIP_ZIPPER_TEETH - 1)
		var y: float = lerpf(y_lo, y_hi, f)
		var r_here: float = _zip_body_radius_at(y / _ZIP_BODY_HEIGHT)
		var seam_pos: Vector3 = radial * (r_here + tooth_d * 0.35) + Vector3(0, y, 0)
		_cf_emit_box(st, seam_pos, tangent, Vector3.UP, radial,
			tooth_w, tooth_h, tooth_d * 0.5)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "ZipperRow"
	mi.mesh = st.commit()
	mi.material_override = _zip_metal_mat()
	return mi


## Pale-metal zipper material (color_b mechanism family) — teeth, tab. Uses the shared metal
## material so it shares the brass/steel emission-floor convention, tinted toward pale steel.
func _zip_metal_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_b.lerp(Color(0.80, 0.80, 0.84), 0.6)
	m.metallic = clampf(maxf(metallic_amt, 0.5), 0.0, 1.0)
	m.roughness = clampf(rough_amt - 0.2, 0.05, 0.6)
	m.emission_enabled = true
	m.emission = color_b * 0.4
	m.emission_energy_multiplier = _cf_glow_energy(0.14)
	return m


## The pull-tab: a slider body + stem + ring-pull (four boxes forming a square loop), parked
## low on the seam facing the camera, batched into one ArrayMesh.
func _zip_pull_tab() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ang: float = deg_to_rad(45.0)
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	var radial: Vector3 = Vector3(ca, 0.0, sa)
	var tangent: Vector3 = Vector3(-sa, 0.0, ca)
	var y: float = _ZIP_BODY_HEIGHT * 0.12
	var r_here: float = _zip_body_radius_at(y / _ZIP_BODY_HEIGHT)
	var base_pos: Vector3 = radial * (r_here + 0.05) + Vector3(0, y, 0)
	var up_dir: Vector3 = Vector3.UP

	_cf_emit_box(st, base_pos, tangent, up_dir, radial, 0.045, 0.05, 0.03)
	var stem_pos: Vector3 = base_pos - up_dir * 0.075 + radial * 0.01
	_cf_emit_box(st, stem_pos, tangent, up_dir, radial, 0.010, 0.03, 0.010)
	var ring_c: Vector3 = base_pos - up_dir * 0.135
	var rs: float = 0.045
	var bt: float = 0.009
	_cf_emit_box(st, ring_c + up_dir * rs, tangent, up_dir, radial, rs, bt, bt)
	_cf_emit_box(st, ring_c - up_dir * rs, tangent, up_dir, radial, rs, bt, bt)
	_cf_emit_box(st, ring_c + tangent * rs, tangent, up_dir, radial, bt, rs, bt)
	_cf_emit_box(st, ring_c - tangent * rs, tangent, up_dir, radial, bt, rs, bt)

	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "PullTab"
	mi.mesh = st.commit()
	mi.material_override = _zip_metal_mat()
	return mi


## The jewelled interior: a cluster of faceted crystals (each an elongated bipyramid gem,
## flat-shaded) batched into ONE ArrayMesh (color_b crystal), plus a central unshaded glow orb
## and a tight teal OmniLight that pools around the gems and lights the pale peel. complexity
## scales the crystal count.
func _zip_core(parent: Node3D, core_pos: Vector3) -> void:
	var crystal_count: int = clampi(8 + complexity, 10, 18)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ci: int in range(crystal_count):
		var dir: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-0.9, 1.0),
			_rng.randf_range(-1.0, 1.0))
		if dir.length() < 0.01:
			dir = Vector3.UP
		dir = dir.normalized()
		var seat: Vector3 = Vector3(
			_rng.randf_range(-0.05, 0.10),
			_rng.randf_range(-0.26, 0.26),
			_rng.randf_range(-0.05, 0.10))
		var length: float = _rng.randf_range(0.16, 0.30)
		var girth: float = _rng.randf_range(0.05, 0.09)
		_zip_emit_crystal(st, dir, seat, length, girth)
	# NB: do NOT generate_normals() — _zip_emit_crystal sets true face normals (flat facets).
	_cf_add_mesh(parent, st.commit(), _zip_crystal_mat(),
		Transform3D(Basis.IDENTITY, core_pos), "Crystals")

	# Central glow orb (unshaded) tucked slightly behind the cluster.
	_cf_add_mesh(parent, MorphoPrimitive.sphere(0.038, 12, 8), _cf_glow_mat(_zip_core_glow_color(), 2.5),
		Transform3D(Basis.IDENTITY, core_pos + Vector3(-0.04, -0.05, -0.04)), "CoreGlow")

	# A small teal OmniLight just behind the core (gated by emissive).
	var lamp := OmniLight3D.new()
	lamp.name = "CoreLight"
	lamp.light_color = Color(0.45, 0.92, 0.88)
	lamp.light_energy = 0.7 if emissive else 0.35
	lamp.omni_range = 0.6
	lamp.omni_attenuation = 2.4
	lamp.position = core_pos + Vector3(-0.06, 0.0, -0.06)
	parent.add_child(lamp)


## Faceted crystal material — color_b family, flat-shaded so facets catch light, with emission
## so the gems read as saturated jewels against the pale peel.
func _zip_crystal_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_b
	m.roughness = 0.12
	m.metallic = 0.5
	m.emission_enabled = true
	m.emission = color_b.lerp(accent, 0.4)
	m.emission_energy_multiplier = _cf_glow_energy(1.3)
	return m


## Inner heart-light colour — accent pushed toward cyan so the core reads as a geode glow.
func _zip_core_glow_color() -> Color:
	return accent.lerp(Color(0.50, 0.95, 0.90), 0.6)


## Emit one faceted crystal (an elongated bipyramid gem) directly into the SurfaceTool with
## true FACE normals (flat-shaded). A pentagonal girdle ring is the widest girdle; a top apex
## and a short bottom apex cap each end. Built in crystal-local space (Y = dir), seated at
## `seat`. Seeded jitter gives each gem an irregular cut.
func _zip_emit_crystal(st: SurfaceTool, dir: Vector3, seat: Vector3, length: float, girth: float) -> void:
	var basis: Basis = _cf_basis_from_up(dir)
	var facets: int = 5
	var girdle: Array[Vector3] = []
	for fi: int in range(facets):
		var ang: float = TAU * float(fi) / float(facets) + _rng.randf_range(-0.18, 0.18)
		var rm: float = girth * _rng.randf_range(0.85, 1.15)
		var ringv: Vector3 = Vector3(cos(ang) * rm, length * _rng.randf_range(0.34, 0.44), sin(ang) * rm)
		girdle.append(seat + basis * ringv)
	var top_off: Vector3 = Vector3(_rng.randf_range(-0.18, 0.18), 1.0, _rng.randf_range(-0.18, 0.18))
	var apex_top: Vector3 = seat + basis * (top_off.normalized() * length)
	var apex_bot: Vector3 = seat + basis * Vector3(0.0, -length * 0.14, 0.0)

	for fi: int in range(facets):
		var a: Vector3 = girdle[fi]
		var b: Vector3 = girdle[(fi + 1) % facets]
		_zip_face_tri(st, a, b, apex_top)
	for fi: int in range(facets):
		var a2: Vector3 = girdle[fi]
		var b2: Vector3 = girdle[(fi + 1) % facets]
		_zip_face_tri(st, b2, a2, apex_bot)


## Emit one triangle with a true face normal (flat-shaded facet).
func _zip_face_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.000001:
		n = Vector3.UP
	else:
		n = n.normalized()
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


## A short curving calyx stem seated on the shoulder, starting wide (a collar overlapping the
## neck) and tapering to a tip. Built with multi_tube.
func _zip_stem(parent: Node3D, neck_pos: Vector3) -> void:
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.30, 0.34, 0.18)
	stem_mat.roughness = 0.7
	stem_mat.metallic = 0.0
	var positions: Array = [
		neck_pos - Vector3(0.0, 0.04, 0.0),
		neck_pos + Vector3(0.015, 0.06, 0.01),
		neck_pos + Vector3(0.045, 0.14, 0.025),
		neck_pos + Vector3(0.075, 0.20, 0.04)]
	var radii: Array = [0.085, 0.052, 0.032, 0.014]
	_cf_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 8), stem_mat,
		Transform3D.IDENTITY, "Calyx")
