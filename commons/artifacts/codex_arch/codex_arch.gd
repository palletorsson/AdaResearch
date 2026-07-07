extends Node3D
class_name CodexArch

# @identity
# essence: a single DNA-driven CODEX ARCH — a piece of impossible architecture after
#   the architecture chapter of Luigi Serafini's Codex Seraphinianus, where buildings
#   disobey building: arches that lean where no arch leans, masonry bent like taffy yet
#   load-bearing in the dream, vaults plunging into overlong perspective, and stone that
#   has quietly become a body. Where most artifacts stack solid primitives, CodexArch
#   GENERATES surreal swept architecture — every span a true swept masonry surface, not a
#   box. Depending on its `mode` DNA it becomes one of four impossible structures:
#   arcade (a CURVING colonnade of repeating voussoir arches on tapered columns under a
#   continuous entablature, warped in REVERSE perspective so the far bays loom large and
#   the near bays shrink, each bay tilting, a soft warm aperture glowing inside every
#   opening), vault (a ribbed pointed-barrel VAULT tunnel receding into impossible depth
#   — a concave interior you look INTO, transverse rib-arches at each bay, a ridge rib +
#   springing stringcourses running the length, solid side piers, a warm glowing throat at
#   the far end, the shell culled on both faces so the inside renders toward the eye),
#   warp (a single hero archway whose span TWISTS and MORPHS as it rises — a hand-rolled
#   morphing sweep carrying its cross-section from a chunky SQUARE foot through a tumbling
#   re-orientation to a flattened DIAMOND blade at the crown, a heavy continuous twist, an
#   out-of-plane lean with an S in the ascent, a whole-body post twist + bend, chunky
#   plinth feet, a floating keystone EYE, a soft glow disc beneath), and organic (a rounded
#   horseshoe vault clad in overlapping curved GREEN SCALES tiled like roof tiles / pinecone
#   plates over the whole body, with gnarled ROOTS and a small twisted tree growing up
#   through the opening, gripping tendrils arching onto the legs, a diamond-tiled base, and a
#   soft green-gold glow nestled in the hollow — architecture fused with organism). It is
#   the boundary between BUILT and GROWN drawn as a single switchable genome.
# desire: it wants the STONE to read as warm terracotta / ochre masonry (an emission FLOOR
#   so the thin ribs and far bays never collapse to black against the dark capture), the
#   TRIM to read as pale limestone (or, in organic mode, as a saturated LIVING GREEN skin
#   so the lit scales read green, not washed sandstone), and the APERTURE GLOW to be a
#   SOFT warm light filling each opening — restrained, never neon. Above all it wants each
#   piece to read as IMPOSSIBLE: the arcade's reverse perspective, the vault's plunging
#   concave throat, the warp's tumbling section, the organic gate's stone-become-creature.
# critical_parameter: mode + seed + the colour triad (color_a MASONRY / color_b TRIM-or-
#   GREEN-SKIN / accent APERTURE GLOW) + complexity. mode picks the architectural lineage;
#   seed varies the individual deterministically (a local seeded RNG, no global randf/randi
#   ever); complexity scales bay count / rib count / twist detail / scale-cladding density.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and branches
#   on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config metas, clears
#   children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: a row of these reads as a CABINET OF CODEX ARCHITECTURE — four ways a structure
#   can disobey building. Switch one mode and the room's idea of "what a building is" shifts
#   from order to dream; reseed and the structure persists while its individual varies.
# needs: a seeded RNG for deterministic individuals [present]; four build branches each
#   carrying its trial's bespoke machinery (warped baseline + voussoir sweep, concave vault
#   shell, hand-rolled morphing sweep, scale-cladding from surface frames) [present]; stone /
#   trim / glow materials driven by the colour triad [present]; swept surfaces + batched
#   scale/strut ArrayMeshes so the AABB capture frames each piece [present].
# relationships: kin to haeckel (same genome shape + conventions; haeckel grows open
#   lattices, CodexArch generates surreal architecture); built on the nature_system
#   morphology engine it borrows from (MorphoSweep / MorphoPrimitive / MorphoModifier);
#   cousin to any mode-switchboard of one genome.
# truth: a building was never only an ordered solid — Serafini saw that architecture in a
#   dream can lean wrong, recede impossibly, morph as it rises, and quietly grow a skin and
#   roots until the line between BUILT and GROWN dissolves. CodexArch holds four such
#   impossible structures in one genome where every span is GENERATED as a swept surface — a
#   warped colonnade, a plunging vault, a twisting arch, a scaled living gate — and lets a
#   single parameter choose which impossibility the viewer is invited to read. The stone must
#   stay warm, the glow soft, and the boundary between structure and body must stay porous.

## A multi-mode generative CODEX ARCH — impossible swept architecture from DNA exports.
##
## Built procedurally after the architecture chapter of Luigi Serafini's Codex
## Seraphinianus. The `mode` export selects one of EIGHT impossible structures, each ported
## faithfully from a verified trial:
## arcade (a curving REVERSE-perspective colonnade of swept voussoir arches on tapered
## columns under a continuous entablature, with glowing apertures), vault (a ribbed
## pointed-barrel tunnel receding into impossible depth — concave shell + transverse ribs +
## longitudinal courses + piers + a far glowing throat), warp (a single hero arch that
## TWISTS and MORPHS square->diamond along a hand-rolled morphing sweep + post twist/bend,
## with plinth feet, a floating keystone eye, and an under-arch glow), organic (a rounded
## horseshoe vault clad in overlapping GREEN SCALES with roots/a tree growing through the
## opening, a diamond-tiled base, and a glow in the hollow — architecture fused with body),
## ribarch (a monumental arch of CONCENTRIC STRIPED RIBBED BANDS — pink/green/white/cream
## alternating along each arc — springing from SPINDLY TAPERED LEGS, a dark crown finial at
## the apex, pale elliptical foam-cells on the ground), foambridge (a gently-arched span that
## is a FOAM / CELLULAR MEMBRANE — mostly elliptical holes bounded by thin pale struts, a few
## jewel-tinted cells, masonry anchors at both ends, a pendant teardrop hanging from mid-span;
## every cell wall + edge rail batched into one ArrayMesh), oculus (a BRICK WALL with a great
## circular dentil-ringed OCULUS, a row of POINTED ARCHES below, a striped TOOTHED COLUMN
## beside it, a BLOOD-RED POOL with stepping stones + green moss at its base), rainbowspan (a
## great curving ARC BRIDGE springing over a river to a TERRACED HILL-TOWN whose stacked
## buildings glitter with warm window-lights, tree-blobs on the banks — built ONLY under the
## artifact's own rig, never touching the global capture environment).
##
## A seeded RNG makes every individual deterministic from its `seed`. The colour triad
## (color_a MASONRY / color_b TRIM-or-GREEN-SKIN / accent APERTURE GLOW) re-registers the
## same architecture between palettes. Shared material + sweep + orient helpers live under
## the `_cx_` prefix; the bespoke machinery from each trial (warped baseline, concave vault
## winding, hand-rolled morphing sweep, scale-cladding from parallel-transport frames) is
## carried into the mode builders. Surface generation reuses the morphology toolkit statics
## (MorphoSweep, MorphoPrimitive, MorphoModifier).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## arcade | vault | warp | organic | ribarch | foambridge | oculus | rainbowspan
@export var mode: String = "arcade"
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 0
## Detail / element count. Scales bay count (arcade), rib stations (vault), twist /
## sweep detail (warp), and scale-cladding density (organic).
@export var complexity: int = 6
## Overall height in meters (nominal full height of the structure).
@export var sculpt_height: float = 2.4
## Footprint / across-span width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## MASONRY / stone — warm terracotta / ochre voussoirs, shafts, vault shell, arch body.
@export var color_a: Color = Color(0.74, 0.52, 0.36)
## TRIM / rib / limestone (or, in organic mode, the GREEN SCALED SKIN) — capitals,
## keystones, ribs, piers, courses, plinths / scales.
@export var color_b: Color = Color(0.86, 0.82, 0.72)
## APERTURE GLOW — the soft warm light filling each opening / throat / hollow.
@export var accent: Color = Color(0.98, 0.82, 0.50)
## Stone, not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.85
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()

# Seed-jittered warp-path locals, baked BEFORE any sweep Callable closes over them.
var _warp_apex_bias: float = 0.16
var _warp_lean: float = 0.62
var _warp_swobble: float = 0.30
var _warp_z_centre: float = -0.10


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
		"arcade":
			_build_arcade()
		"vault":
			_build_vault()
		"warp":
			_build_warp()
		"organic":
			_build_organic()
		"ribarch":
			_build_ribarch()
		"foambridge":
			_build_foambridge()
		"oculus":
			_build_oculus_wall()
		"rainbowspan":
			_build_rainbowspan()
		_:
			# Unknown mode falls back to the arcade colonnade.
			_build_arcade()


# ── Shared `_cx_` material helpers (the three trial materials, DNA-driven) ──────

## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _cx_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## STONE / masonry (color_a family): warm terracotta / ochre voussoirs, shafts, vault
## shell, arch body. Low metallic, high roughness, with a faint emission FLOOR in its own
## tone so the thin ribs and far bays read against the dark capture and never go black.
func _cx_stone_mat(c: Color = color_a) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cx_glow_energy(0.10)
	return m


## TRIM / limestone (color_b family): pale entablature, capitals, keystones, ribs, piers,
## courses, plinths. Slightly smoother than masonry, same faint emission floor.
func _cx_trim_mat(c: Color = color_b) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(rough_amt * 0.94, 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _cx_glow_energy(0.10)
	return m


## GREEN LIVING SKIN (organic mode, color_b family read as scales): a saturated, slightly
## subsurface green so the lit front face reads green rather than washing to sandstone
## under the bright capture rig. A deeper green self-cast (higher emission floor than
## trim), two-sided (each scale is a thin open dome), with per-scale vertex tint as albedo.
## (Carries the v4 trial's worked-out values.)
func _cx_skin_mat(c: Color = color_b) -> StandardMaterial3D:
	# Push the trim colour toward a saturated Codex green so even a pale color_b reads as
	# living skin. If color_b is already green this deepens it; if it is limestone this
	# overrides toward the trial's green so the organic mode never washes to sandstone.
	var green := Color(0.30, 0.47, 0.22).lerp(Color(c.r, c.g, c.b, 1.0), 0.18)
	var m := StandardMaterial3D.new()
	m.albedo_color = green
	m.roughness = clampf(rough_amt * 0.94, 0.02, 1.0)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.2
	m.emission_enabled = true
	m.emission = green * 0.5
	m.emission_energy_multiplier = _cx_glow_energy(0.34)
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## APERTURE GLOW (accent family): soft warm aperture light for openings, throats, hollows.
## `energy` ~2.0 (SOFT), near-unshaded. `two_sided` turns on CULL_DISABLED for planes seen
## from both faces; `alpha` < 1.0 turns on alpha transparency (for the arcade's quad glow).
func _cx_glow_mat(c: Color = accent, energy: float = 2.0, two_sided: bool = false,
		alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _cx_glow_energy(energy)
	if two_sided or alpha < 1.0:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ── Shared `_cx_` geometry / orient helpers ────────────────────────────

## Orthonormal Basis whose Y axis is `up_axis` — stable near-vertical and near-horizontal.
## Used by columns, capitals, bases, keystones that tilt with a warping baseline. (NEVER
## look_at — placed pieces own an explicit Basis.)
func _cx_basis_from_up(up_axis: Vector3) -> Basis:
	var y: Vector3 = up_axis.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) > 0.95 else Vector3.UP
	if absf(y.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Wrap a Mesh in a MeshInstance3D with material + local transform, parented to `parent`.
func _cx_add_mesh(parent: Node3D, mesh: Mesh, mat: Material,
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


## Sweep a profile along an arch/curve path Callable into a MeshInstance3D under `parent`.
## A thin wrapper over MorphoSweep.sweep so every mode shares one arch-sweep entry point.
## (MorphoSweep emits UVs, so generate_tangents would be safe — but we never call it.)
func _cx_arch_sweep(parent: Node3D, profile: Array[Vector2], path_func: Callable,
		radius_func: Callable, segments: int, mat: Material,
		node_name: String = "Sweep") -> MeshInstance3D:
	var mesh: Mesh = MorphoSweep.sweep(profile, path_func, radius_func, 0.0, segments, false)
	return _cx_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, node_name)


## Compute the AABB of a node subtree IN `node`'s local space (for footing / centring).
## Accumulates each MeshInstance3D's AABB through the chain of LOCAL transforms down from
## `node` — never touches global_transform, so it is independent of tree state. (From
## haeckel's `_hk_subtree_aabb`.)
func _cx_subtree_aabb(node: Node3D) -> AABB:
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


## Scale `body` UNIFORMLY so its height fills `target_h`, then drop its lowest point to
## y=0 and centre it horizontally so the AABB capture frames it. Mirrors haeckel's
## `_hk_settle` but always scales uniformly (no horizontal squash) — `width_scale` nudges
## the chosen target slightly so a mode can lean wider/narrower without distorting the
## stone. (Each mode does its own yaw/centre BEFORE this; this only scales + re-floors.)
func _cx_settle(body: Node3D, target_h: float, width_scale: float = 1.0) -> void:
	if target_h > 0.0:
		var raw: AABB = _cx_subtree_aabb(body)
		var span_y: float = maxf(raw.size.y, 0.001)
		# Uniform scale to the target height; width_scale gently biases overall size so a
		# wider footprint reads bigger without a non-uniform stretch.
		var k: float = (target_h / span_y) * (0.85 + 0.15 * clampf(width_scale, 0.2, 2.0))
		body.scale = Vector3(k, k, k)
	var aabb: AABB = _cx_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	body.position += Vector3(-centre.x, -aabb.position.y, -centre.z)


# =============================================================================
# MODE: arcade — a curving reverse-perspective colonnade (trial v1)
# =============================================================================

const _ARC_SPAN_TOTAL: float = 2.7      # rough overall plan span (X), metres
const _ARC_ARCH_SEG: int = 44           # ring count along each swept arch rib
const _ARC_ENTAB_SEG: int = 110         # ring count along the entablature sweep
const _ARC_COLUMN_SEG: int = 18         # revolution segments for column shafts
const _ARC_STILT_FRAC: float = 0.42     # fraction of arch height that is vertical jamb
const _ARC_SPRING_Y: float = 0.92       # base height of the springing line (near end)
const _ARC_RECEDE_LIFT: float = 0.26    # how much the far end lifts (warp)

# Materials baked once per arcade build (mode-local, set in _build_arcade).
var _arc_masonry: StandardMaterial3D
var _arc_trim: StandardMaterial3D
var _arc_glow: StandardMaterial3D
var _arc_bays: int = 5


func _build_arcade() -> void:
	# complexity drives bay count (native 5 at complexity 6).
	_arc_bays = clampi(3 + complexity / 2, 3, 8)
	_arc_masonry = _cx_stone_mat(color_a)
	_arc_trim = _cx_trim_mat(color_b)
	# Arcade aperture is a two-sided alpha quad so it reads whichever way the bay turns.
	_arc_glow = _cx_glow_mat(accent, 2.2, true, 0.9)

	var arcade := Node3D.new()
	arcade.name = "Arcade"
	add_child(arcade)

	# Springing points: one per pier, at bay boundaries (BAYS+1 piers for BAYS spans).
	var pier_tops: Array[Vector3] = []
	for i: int in range(_arc_bays + 1):
		var s: float = float(i) / float(_arc_bays)
		pier_tops.append(_arc_baseline(s))

	# ── Piers (columns) ──
	for i: int in range(pier_tops.size()):
		var s: float = float(i) / float(_arc_bays)
		var pscale: float = _arc_recede_scale(s)
		var lean: float = lerpf(0.0, 5.0, 1.0 - s) + _rng.randf_range(-0.9, 0.9)
		_arc_build_pier(arcade, pier_tops[i], pscale, lean)

	# ── Arch spans + keystones + aperture glows ──
	for i: int in range(_arc_bays):
		var s_mid: float = (float(i) + 0.5) / float(_arc_bays)
		var rib_depth: float = _arc_depth(s_mid)
		var tilt: float = lerpf(0.0, 7.0, 1.0 - s_mid) + _rng.randf_range(-1.3, 1.3)
		_arc_build_arch(arcade, pier_tops[i], pier_tops[i + 1], rib_depth, tilt)

	# ── Continuous entablature / parapet capping the curve ──
	_arc_build_entablature(arcade)

	# Recentre on the origin (XZ centre, foot on y≈0) and yaw so the colonnade presents
	# its sweep broadside to the +X/+Z capture camera.
	var aabb: AABB = _cx_subtree_aabb(arcade)
	var centre: Vector3 = aabb.get_center()
	var shift := Vector3(-centre.x, -aabb.position.y, -centre.z)
	var yaw := Basis(Vector3.UP, deg_to_rad(-34.0))
	arcade.transform = Transform3D(yaw, yaw * shift)

	# Scale uniformly to the sculpt height (yaw + floor already applied).
	_cx_settle(arcade, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## Plan-and-elevation position of the springing line (pier-top baseline) at normalized
## parameter s in [0,1]. The arcade sweeps around a gentle plan arc AND rises as it
## recedes; reverse-perspective X spacing makes far bays wide and near bays compressed.
## (Ported from v1's `_baseline`.)
func _arc_baseline(s: float) -> Vector3:
	var xfrac: float = 1.0 - pow(1.0 - clampf(s, 0.0, 1.0), 1.28)
	var x: float = lerpf(-_ARC_SPAN_TOTAL * 0.5, _ARC_SPAN_TOTAL * 0.5, xfrac)
	var z: float = -cos((s - 0.5) * PI) * _ARC_SPAN_TOTAL * 0.14
	var y: float = _ARC_SPRING_Y + (1.0 - clampf(s, 0.0, 1.0)) * _ARC_RECEDE_LIFT
	return Vector3(x, y, z)


## Recede depth: 0 at the far-back end (s→0), 1 at the near end (s→1).
func _arc_depth(s: float) -> float:
	return clampf(s, 0.0, 1.0)


## Per-position anamorphic scale: LARGEST at the far-back end, shrinking toward the viewer.
func _arc_recede_scale(s: float) -> float:
	return lerpf(1.0, 0.58, _arc_depth(s))


## Local bay half-span at s: half the planar (XZ) distance between baseline points a half
## bay either side of s. (Ported from v1.)
func _arc_local_half_span(s: float) -> float:
	var ds: float = 0.5 / float(_arc_bays)
	var lo: Vector3 = _arc_baseline(clampf(s - ds, 0.0, 1.0))
	var hi: Vector3 = _arc_baseline(clampf(s + ds, 0.0, 1.0))
	var span: float = Vector2(hi.x - lo.x, hi.z - lo.z).length()
	return maxf(span * 0.5, 0.05)


## Local arch crown height above the springing line at s: stilt jamb + semicircle rise.
func _arc_local_crown_height(s: float) -> float:
	var radius: float = _arc_local_half_span(s)
	var stilt_h: float = (radius * 2.0) * _ARC_STILT_FRAC
	return stilt_h + radius * 1.20


## Build one arch span as a swept voussoir rib from pier top `a` to pier top `b`, with a
## keystone and an aperture glow. The path is a STILTED semicircle in the plane of the two
## pier tops + world up. All seeded/geometry values baked into locals before the Callables
## close over them. (Ported from v1's `_build_arch`.)
func _arc_build_arch(parent: Node3D, a: Vector3, b: Vector3, depth_scale: float,
		tilt_deg: float) -> void:
	var springing_a: Vector3 = a
	var springing_b: Vector3 = b
	var chord: Vector3 = springing_b - springing_a
	var mid: Vector3 = (springing_a + springing_b) * 0.5
	var flat: Vector3 = chord.normalized()
	var rise: Vector3 = Vector3.UP
	var pointiness: float = 1.0 + _rng.randf_range(0.06, 0.20)
	var radius: float = chord.length() * 0.5
	var stilt_h: float = (radius * 2.0) * _ARC_STILT_FRAC
	var f_jamb: float = 0.22
	var f_arc: float = 1.0 - 2.0 * f_jamb

	var path := func(t: float) -> Vector3:
		var along: float
		var up: float
		if t < f_jamb:
			var lt: float = t / f_jamb
			along = -radius
			up = lt * stilt_h
		elif t > 1.0 - f_jamb:
			var rt: float = (t - (1.0 - f_jamb)) / f_jamb
			along = radius
			up = (1.0 - rt) * stilt_h
		else:
			var at: float = (t - f_jamb) / f_arc
			var ang: float = lerpf(PI, 0.0, at)
			along = cos(ang) * radius
			up = stilt_h + sin(ang) * radius * pointiness
		return mid + flat * along + rise * up

	var rib_w: float = lerpf(0.165, 0.135, clampf(depth_scale, 0.0, 1.0))
	var rib_d: float = lerpf(0.32, 0.255, clampf(depth_scale, 0.0, 1.0))
	var profile: Array[Vector2] = MorphoSweep.profile_rectangle(rib_d, rib_w)
	var radius_func := func(t: float) -> float:
		return 1.0 + sin(clampf(t, 0.0, 1.0) * PI) * 0.10

	var rib_mesh: Mesh = MorphoSweep.sweep(profile, path, radius_func, 0.0, _ARC_ARCH_SEG, false)
	if rib_mesh == null:
		return
	var tilt: Basis = Basis(flat, deg_to_rad(tilt_deg))
	_cx_add_mesh(parent, rib_mesh, _arc_masonry, Transform3D(tilt, mid - tilt * mid), "ArchRib")

	# Keystone: a trim wedge straddling the crown.
	var crown_pos: Vector3 = path.call(0.5) as Vector3
	var key_basis: Basis = _cx_basis_from_up(rise)
	var key_mesh: Mesh = MorphoPrimitive.box(Vector3(rib_d * 0.6, rib_w * 2.1, rib_d * 1.2))
	var key_lift: Vector3 = rise * (rib_w * 0.65)
	var key_pos: Vector3 = crown_pos + key_lift
	_cx_add_mesh(parent, key_mesh, _arc_trim,
		Transform3D(tilt * key_basis, _arc_apply_tilt(tilt, mid, key_pos)), "Keystone")

	# Aperture glow: a soft warm plane filling the opening, set back inside the bay.
	_arc_build_glow(parent, springing_a, springing_b, stilt_h, radius * pointiness,
		flat, rise, tilt, mid)


## Apply the bay tilt (rotation about chord through `pivot`) to a world point.
func _arc_apply_tilt(tilt: Basis, pivot: Vector3, p: Vector3) -> Vector3:
	return tilt * (p - pivot) + pivot


## Soft aperture glow: a vertical quad set back behind the arch plane, sized to fill the
## stilted opening. (Ported from v1's `_build_glow`.)
func _arc_build_glow(parent: Node3D, a: Vector3, b: Vector3, stilt_h: float, arc_rise: float,
		flat: Vector3, rise: Vector3, tilt: Basis, pivot: Vector3) -> void:
	var mid: Vector3 = (a + b) * 0.5
	var half_span: float = (b - a).length() * 0.5
	var depth_dir: Vector3 = flat.cross(rise).normalized()
	var glow_w: float = half_span * 1.55
	var glow_h: float = stilt_h + arc_rise * 0.92
	var quad: Mesh = MorphoPrimitive.quad(Vector2(glow_w, glow_h))
	var gx: Vector3 = flat
	var gy: Vector3 = rise
	var gz: Vector3 = gx.cross(gy).normalized()
	var glow_basis := Basis(gx, gy, gz)
	var glow_centre: Vector3 = mid + rise * (glow_h * 0.5 - 0.02) - depth_dir * 0.10
	var gpos: Vector3 = _arc_apply_tilt(tilt, pivot, glow_centre)
	_cx_add_mesh(parent, quad, _arc_glow, Transform3D(tilt * glow_basis, gpos), "Aperture")


## Build one pier under springing point `top`, dropping to the ground at y=0: a tapered
## revolution shaft with entasis, a flared capital, and a stepped base. The whole pier
## tilts slightly with the warp. (Ported from v1's `_build_pier`.)
func _arc_build_pier(parent: Node3D, top: Vector3, scale_amt: float, lean_deg: float) -> void:
	var foot: Vector3 = Vector3(top.x, 0.0, top.z)
	var shaft_h: float = maxf(top.y - foot.y, 0.2)
	var col_r: float = lerpf(0.14, 0.105, clampf(1.0 - scale_amt, 0.0, 1.0))

	var up_axis: Vector3 = Vector3(0.0, 1.0, 0.0)
	var lean := Basis(Vector3.RIGHT, deg_to_rad(lean_deg))
	up_axis = (lean * up_axis).normalized()
	var basis: Basis = _cx_basis_from_up(up_axis)

	# Tapered shaft with entasis.
	var seg_n: int = 8
	var profile: Array[Vector2] = []
	for i: int in range(seg_n + 1):
		var t: float = float(i) / float(seg_n)
		var h: float = t * shaft_h
		var taper: float = lerpf(1.0, 0.82, t)
		var entasis: float = 1.0 + sin(t * PI) * 0.05
		profile.append(Vector2(col_r * taper * entasis, h))
	_cx_add_mesh(parent, MorphoPrimitive.revolution(profile, _ARC_COLUMN_SEG), _arc_masonry,
		Transform3D(basis, foot), "PierShaft")

	# Capital: flared revolution under the springing point.
	var cap_r: float = col_r * 0.86
	var cap_h: float = col_r * 1.6
	var cap_profile: Array[Vector2] = [
		Vector2(cap_r * 0.92, 0.0),
		Vector2(cap_r * 1.02, cap_h * 0.22),
		Vector2(cap_r * 1.45, cap_h * 0.62),
		Vector2(cap_r * 1.62, cap_h * 0.80),
		Vector2(cap_r * 1.66, cap_h)]
	var cap_seat: Vector3 = top - up_axis * cap_h
	_cx_add_mesh(parent, MorphoPrimitive.revolution(cap_profile, _ARC_COLUMN_SEG), _arc_trim,
		Transform3D(basis, cap_seat), "Capital")

	# Base: a short stepped revolution at the foot.
	var base_r: float = col_r * 1.5
	var base_h: float = col_r * 0.9
	var base_profile: Array[Vector2] = [
		Vector2(base_r, 0.0),
		Vector2(base_r * 1.04, base_h * 0.28),
		Vector2(base_r * 0.78, base_h * 0.60),
		Vector2(col_r * 1.04, base_h)]
	_cx_add_mesh(parent, MorphoPrimitive.revolution(base_profile, _ARC_COLUMN_SEG), _arc_trim,
		Transform3D(basis, foot), "PierBase")


## A continuous entablature + architrave band swept along the warping baseline, raised
## above the local arch crowns so it caps wide and narrow bays alike. (Ported from v1.)
func _arc_build_entablature(parent: Node3D) -> void:
	var gap: float = 0.12
	var crown_floor: float = _arc_local_crown_height(0.55) * 0.9
	var path := func(t: float) -> Vector3:
		var s: float = lerpf(-0.05, 1.05, t)
		var base: Vector3 = _arc_baseline(s)
		var crown: float = maxf(_arc_local_crown_height(s), crown_floor)
		return base + Vector3.UP * (crown + gap)
	var profile: Array[Vector2] = MorphoSweep.profile_rectangle(0.42, 0.16)
	var radius_func := func(_t: float) -> float: return 1.0
	_cx_arch_sweep(parent, profile, path, radius_func, _ARC_ENTAB_SEG, _arc_trim, "Cornice")

	# A thinner masonry architrave band just under the cornice.
	var band_gap: float = gap - 0.15
	var path2 := func(t: float) -> Vector3:
		var s: float = lerpf(-0.04, 1.04, t)
		var base: Vector3 = _arc_baseline(s)
		var crown: float = maxf(_arc_local_crown_height(s), crown_floor)
		return base + Vector3.UP * (crown + band_gap)
	var profile2: Array[Vector2] = MorphoSweep.profile_rectangle(0.34, 0.12)
	_cx_arch_sweep(parent, profile2, path2, radius_func, _ARC_ENTAB_SEG, _arc_masonry, "Architrave")


# =============================================================================
# MODE: vault — a ribbed barrel vault receding into impossible depth (trial v2)
# =============================================================================

const _VLT_LENGTH: float = 2.55         # tunnel depth (receding, into -Z)
const _VLT_DESCENT: float = 0.92        # plunge of the throat over the run (steep)
const _VLT_MOUTH_HALF_W: float = 0.92   # half-width of the arch at the mouth
const _VLT_MOUTH_SPRING_H: float = 0.70 # springing-line height at the mouth
const _VLT_MOUTH_RISE: float = 1.18     # apex height above springing at mouth
const _VLT_FAR_SCALE: float = 0.40      # arch scale at the far end (forced persp.)
const _VLT_YAW_DEG: float = 32.0        # align tunnel axis to camera sightline
const _VLT_ARCH_SAMPLES: int = 40       # cross-section resolution (per side)
const _VLT_LEN_SEG: int = 64            # rings along the tunnel
const _VLT_PIER_HEIGHT: float = 0.70    # solid base the vault springs from
const _VLT_PIER_THICK: float = 0.26     # pier wall thickness (X)
var _vlt_bays: int = 6


func _build_vault() -> void:
	# complexity drives transverse rib station count (native 6 at complexity 6).
	_vlt_bays = clampi(4 + complexity / 3, 4, 9)
	var masonry := _cx_stone_mat(color_a)
	# CRITICAL: the vault shell is concave — cull DISABLED so the inside renders toward
	# the camera looking down the throat (the shell is not a closed lump).
	masonry.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rib := _cx_trim_mat(color_b)
	rib.cull_mode = BaseMaterial3D.CULL_DISABLED
	var glow := _cx_glow_mat(accent, 2.2, true, 1.0)

	# Outer node carries the yaw; inner geo node is centred first so the yaw spins the
	# tunnel about its own middle. (Ported from v2's _build_vault.)
	var vault := Node3D.new()
	vault.name = "Vault"
	add_child(vault)
	var geo := Node3D.new()
	geo.name = "Geo"
	vault.add_child(geo)

	_vlt_build_shell(geo, masonry)
	_vlt_build_piers(geo, rib)
	_vlt_build_transverse_ribs(geo, rib)
	_vlt_build_longitudinal_ribs(geo, rib)
	_vlt_build_aperture(geo, glow)

	# Centre the run on X/Z and lift so the lowest point rests on y=0.
	var aabb: AABB = _cx_subtree_aabb(geo)
	geo.position = Vector3(
		-(aabb.position.x + aabb.size.x * 0.5),
		-aabb.position.y,
		-(aabb.position.z + aabb.size.z * 0.5))

	# Yaw so the tunnel mouth opens toward the +X/+Z capture camera and the throat plunges
	# away into the depth. (Carries v2's yaw-to-camera.)
	vault.rotate_y(deg_to_rad(_VLT_YAW_DEG))

	# Scale uniformly to the sculpt height (centre + floor + yaw already applied).
	_cx_settle(vault, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## Tunnel centreline at longitudinal parameter t in [0,1]: from the mouth (z=0) into -Z,
## descending (the Piranesi plunge), with a faint sideways drift. (Ported from v2.)
func _vlt_centre(t: float) -> Vector3:
	var z: float = -_VLT_LENGTH * t
	var y: float = -_VLT_DESCENT * (t * t)
	var x: float = sin(t * PI) * 0.06
	return Vector3(x, y, z)


## Forced-perspective scale of the arch at station t: 1.0 at the mouth → FAR_SCALE far.
func _vlt_arch_scale(t: float) -> float:
	var e: float = pow(clampf(t, 0.0, 1.0), 1.15)
	return lerpf(1.0, _VLT_FAR_SCALE, e)


## The transverse pointed-arch cross-section as an OPEN curve of (horizontal, vertical):
## floor-left → up the haunch → apex → down → floor-right. (Ported from v2.)
func _vlt_arch_profile(scale_amt: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var hw: float = _VLT_MOUTH_HALF_W * scale_amt
	var spring: float = _VLT_MOUTH_SPRING_H * scale_amt
	var apex: float = (_VLT_MOUTH_SPRING_H + _VLT_MOUTH_RISE) * scale_amt
	var foot: float = -_VLT_PIER_HEIGHT * 0.12 * scale_amt
	pts.append(Vector2(-hw, foot))
	pts.append(Vector2(-hw, spring))
	for i: int in range(1, _VLT_ARCH_SAMPLES + 1):
		var u: float = float(i) / float(_VLT_ARCH_SAMPLES)
		pts.append(_vlt_point_arch_point(u, hw, spring, apex))
	for i: int in range(_VLT_ARCH_SAMPLES - 1, -1, -1):
		var u: float = float(i) / float(_VLT_ARCH_SAMPLES)
		var p: Vector2 = _vlt_point_arch_point(u, hw, spring, apex)
		pts.append(Vector2(-p.x, p.y))
	pts.append(Vector2(hw, foot))
	return pts


## One point on the LEFT half of the pointed arch, u in [0,1] springing→apex. (Ported v2.)
func _vlt_point_arch_point(u: float, hw: float, spring: float, apex: float) -> Vector2:
	var ang: float = u * PI * 0.5
	var x: float = -hw * cos(ang)
	var rise: float = apex - spring
	var y: float = spring + rise * pow(sin(ang), 0.78)
	return Vector2(x, y)


## Orthonormal frame at station t: [origin, right, up, forward]. (Ported from v2.)
func _vlt_frame(t: float) -> Array:
	var dt: float = 0.001
	var t0: float = maxf(t - dt, 0.0)
	var t1: float = minf(t + dt, 1.0)
	var forward: Vector3 = (_vlt_centre(t1) - _vlt_centre(t0)).normalized()
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	var up_ref: Vector3 = Vector3.UP
	var right: Vector3 = forward.cross(up_ref)
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	right = right.normalized()
	var up: Vector3 = right.cross(forward).normalized()
	return [_vlt_centre(t), right, up, forward]


## Map an arch-profile point (h, v) into world space at station t. (Ported from v2.)
func _vlt_arch_to_world(t: float, h: float, v: float) -> Vector3:
	var frame: Array = _vlt_frame(t)
	var origin: Vector3 = frame[0]
	var right: Vector3 = frame[1]
	var up: Vector3 = frame[2]
	return origin + right * h + up * v


## Build the continuous vault shell directly: lay the scaled arch profile in each ring's
## frame and triangulate consecutive rings. Normals point OUTWARD (away from the throat);
## the masonry material culls nothing so the concave interior renders toward the camera.
## The profile is OPEN across the bottom so the floor stays open. (Ported from v2.)
func _vlt_build_shell(parent: Node3D, mat: StandardMaterial3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: Array = []
	for ri: int in range(_VLT_LEN_SEG + 1):
		var t: float = float(ri) / float(_VLT_LEN_SEG)
		var prof: Array[Vector2] = _vlt_arch_profile(_vlt_arch_scale(t))
		var ring: Array[Vector3] = []
		for p: Vector2 in prof:
			ring.append(_vlt_arch_to_world(t, p.x, p.y))
		rings.append(ring)

	var v_count: int = (rings[0] as Array).size()
	for ri: int in range(_VLT_LEN_SEG):
		var ring_a: Array = rings[ri] as Array
		var ring_b: Array = rings[ri + 1] as Array
		for vi: int in range(v_count - 1):
			var a0: Vector3 = ring_a[vi] as Vector3
			var a1: Vector3 = ring_a[vi + 1] as Vector3
			var b0: Vector3 = ring_b[vi] as Vector3
			var b1: Vector3 = ring_b[vi + 1] as Vector3
			var n0: Vector3 = (b0 - a0).cross(a1 - a0).normalized()
			st.set_normal(n0); st.add_vertex(a0)
			st.set_normal(n0); st.add_vertex(b0)
			st.set_normal(n0); st.add_vertex(a1)
			var n1: Vector3 = (b1 - a1).cross(b0 - a1).normalized()
			st.set_normal(n1); st.add_vertex(a1)
			st.set_normal(n1); st.add_vertex(b0)
			st.set_normal(n1); st.add_vertex(b1)

	_cx_add_mesh(parent, st.commit(), mat, Transform3D.IDENTITY, "VaultShell")


## At each bay station, sweep a small box along that station's arch curve → a rib-arch
## standing proud of the shell. (Ported from v2's `_build_transverse_ribs`.)
func _vlt_build_transverse_ribs(parent: Node3D, mat: StandardMaterial3D) -> void:
	var rib_profile: Array[Vector2] = MorphoSweep.profile_rectangle(0.085, 0.11)
	for b: int in range(_vlt_bays):
		var t: float = lerpf(0.04, 0.96, float(b) / float(_vlt_bays - 1))
		var scale_amt: float = _vlt_arch_scale(t)
		var hw: float = _VLT_MOUTH_HALF_W * scale_amt
		var spring: float = _VLT_MOUTH_SPRING_H * scale_amt
		var apex: float = (_VLT_MOUTH_SPRING_H + _VLT_MOUTH_RISE) * scale_amt
		var frame: Array = _vlt_frame(t)
		var origin: Vector3 = frame[0]
		var right: Vector3 = frame[1]
		var up: Vector3 = frame[2]
		var thick_jit: float = _rng.randf_range(0.9, 1.12)

		var path_func := func(p: float) -> Vector3:
			var h: float
			var v: float
			if p < 0.5:
				var u: float = p * 2.0
				var pt: Vector2 = _vlt_point_arch_point(u, hw, spring, apex)
				h = pt.x
				v = pt.y
			else:
				var u: float = (1.0 - p) * 2.0
				var pt: Vector2 = _vlt_point_arch_point(u, hw, spring, apex)
				h = -pt.x
				v = pt.y
			return origin + right * h + up * v

		var radius_func := func(_p: float) -> float: return thick_jit
		var rib_mesh: Mesh = MorphoSweep.sweep(rib_profile, path_func, radius_func, 0.0, 40, false)
		_cx_add_mesh(parent, rib_mesh, mat, Transform3D.IDENTITY, "Rib_%d" % b)


## Sweep a small box along the centreline three times: a ridge rib riding the apex, and
## two stringcourses at the left/right springing lines. (Ported from v2.)
func _vlt_build_longitudinal_ribs(parent: Node3D, mat: StandardMaterial3D) -> void:
	var course_profile: Array[Vector2] = MorphoSweep.profile_rectangle(0.07, 0.07)
	var radius_func := func(_t: float) -> float: return 1.0

	var ridge_path := func(t: float) -> Vector3:
		var scale_amt: float = _vlt_arch_scale(t)
		var apex: float = (_VLT_MOUTH_SPRING_H + _VLT_MOUTH_RISE) * scale_amt
		return _vlt_arch_to_world(t, 0.0, apex)
	_cx_arch_sweep(parent, course_profile, ridge_path, radius_func, _VLT_LEN_SEG, mat, "RidgeRib")

	var left_path := func(t: float) -> Vector3:
		var scale_amt: float = _vlt_arch_scale(t)
		var hw: float = _VLT_MOUTH_HALF_W * scale_amt
		var spring: float = _VLT_MOUTH_SPRING_H * scale_amt
		return _vlt_arch_to_world(t, -hw, spring)
	_cx_arch_sweep(parent, course_profile, left_path, radius_func, _VLT_LEN_SEG, mat, "CourseLeft")

	var right_path := func(t: float) -> Vector3:
		var scale_amt: float = _vlt_arch_scale(t)
		var hw: float = _VLT_MOUTH_HALF_W * scale_amt
		var spring: float = _VLT_MOUTH_SPRING_H * scale_amt
		return _vlt_arch_to_world(t, hw, spring)
	_cx_arch_sweep(parent, course_profile, right_path, radius_func, _VLT_LEN_SEG, mat, "CourseRight")


## Two solid piers running the length under the springing line, one per side, built as a
## swept box strip that tapers with the forced perspective and descends with the floor.
## (Ported from v2's `_build_piers`.)
func _vlt_build_piers(parent: Node3D, mat: StandardMaterial3D) -> void:
	for side: int in [-1, 1]:
		var sgn: float = float(side)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rings: Array = []
		for ri: int in range(_VLT_LEN_SEG + 1):
			var t: float = float(ri) / float(_VLT_LEN_SEG)
			var scale_amt: float = _vlt_arch_scale(t)
			var hw: float = _VLT_MOUTH_HALF_W * scale_amt
			var spring: float = _VLT_MOUTH_SPRING_H * scale_amt
			var frame: Array = _vlt_frame(t)
			var origin: Vector3 = frame[0]
			var right: Vector3 = frame[1]
			var up: Vector3 = frame[2]
			var base_v: float = -_VLT_PIER_HEIGHT * 0.55 * scale_amt
			var inner_h: float = hw
			var outer_h: float = hw + _VLT_PIER_THICK * scale_amt * sgn
			var ib: Vector3 = origin + right * (inner_h * sgn) + up * base_v
			var ob: Vector3 = origin + right * (outer_h * sgn) + up * base_v
			var ot: Vector3 = origin + right * (outer_h * sgn) + up * spring
			var it: Vector3 = origin + right * (inner_h * sgn) + up * spring
			rings.append([ib, ob, ot, it])
		_vlt_emit_box_strip(st, rings)
		_cx_add_mesh(parent, st.commit(), mat, Transform3D.IDENTITY, "Pier_%d" % side)


## Triangulate a longitudinal box strip given per-ring 4 corners, with end caps. (v2.)
func _vlt_emit_box_strip(st: SurfaceTool, rings: Array) -> void:
	var n: int = rings.size()
	for ri: int in range(n - 1):
		var a: Array = rings[ri] as Array
		var b: Array = rings[ri + 1] as Array
		for ci: int in range(4):
			var cn: int = (ci + 1) % 4
			_vlt_quad_auto(st, a[ci] as Vector3, a[cn] as Vector3, b[cn] as Vector3, b[ci] as Vector3)
	var first: Array = rings[0] as Array
	var last: Array = rings[n - 1] as Array
	_vlt_quad_auto(st, first[0] as Vector3, first[1] as Vector3, first[2] as Vector3, first[3] as Vector3)
	_vlt_quad_auto(st, last[3] as Vector3, last[2] as Vector3, last[1] as Vector3, last[0] as Vector3)


## Emit a quad with an auto-computed geometric normal, two triangles. (v2.)
func _vlt_quad_auto(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


## A glowing arch-shaped aperture closing the deep end: a filled fan over the far ring's
## arch profile, unshaded warm light, set just behind the last ring. (Ported from v2.)
func _vlt_build_aperture(parent: Node3D, mat: StandardMaterial3D) -> void:
	var t: float = 1.0
	var scale_amt: float = _vlt_arch_scale(t) * 0.95
	var prof: Array[Vector2] = _vlt_arch_profile(scale_amt)
	var frame: Array = _vlt_frame(t)
	var origin: Vector3 = frame[0] + (frame[3] as Vector3) * 0.06
	var right: Vector3 = frame[1]
	var up: Vector3 = frame[2]
	var fwd: Vector3 = frame[3]

	var verts: Array[Vector3] = []
	var centroid := Vector2.ZERO
	for p: Vector2 in prof:
		centroid += p
	centroid /= float(prof.size())
	var c_world: Vector3 = origin + right * centroid.x + up * centroid.y
	for p: Vector2 in prof:
		verts.append(origin + right * p.x + up * p.y)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(verts.size() - 1):
		var a: Vector3 = verts[i]
		var b: Vector3 = verts[i + 1]
		st.set_normal(fwd); st.add_vertex(c_world)
		st.set_normal(fwd); st.add_vertex(a)
		st.set_normal(fwd); st.add_vertex(b)
	_cx_add_mesh(parent, st.commit(), mat, Transform3D.IDENTITY, "Aperture")


# =============================================================================
# MODE: warp — a single hero arch that twists and morphs (trial v3)
# =============================================================================

const _WRP_SPAN: float = 2.35           # horizontal distance foot→foot (X)
const _WRP_RISE: float = 2.45           # crown height of the arch path
const _WRP_PROFILE_SIDES: int = 4       # square ↔ diamond (4 corners)
const _WRP_SWEEP_SEGMENTS: int = 132    # rings along the arch span
const _WRP_SWEEP_TWIST_DEG: float = 192.0  # heavy continuous twist of the section
const _WRP_FOOT_HALF: float = 0.235     # half-size of the chunky square foot
const _WRP_CROWN_HALF: float = 0.205    # half-size scaling at the crown blade
const _WRP_POST_TWIST_DEG: float = 26.0 # extra anamorphic twist on whole mesh
const _WRP_POST_BEND_DEG: float = 18.0  # extra lean/bend on whole mesh


func _build_warp() -> void:
	var masonry := _cx_stone_mat(color_a)
	var trim := _cx_trim_mat(color_b)
	var glow := _cx_glow_mat(accent, 2.0, false, 1.0)

	# Bake the seeded path jitter into the warp locals BEFORE _warp_point closes over
	# them (Callables capture by value via these members; the sweep is built sequentially).
	_warp_apex_bias = 0.16 + _rng.randf_range(-0.03, 0.03)
	_warp_lean = 0.62 + _rng.randf_range(-0.06, 0.06)
	_warp_swobble = 0.30 + _rng.randf_range(-0.05, 0.05)
	_warp_z_centre = -0.10

	# Twist detail scales gently with complexity (native 192° at complexity 6).
	var twist_total: float = _WRP_SWEEP_TWIST_DEG * lerpf(0.85, 1.12, clampf(float(complexity) / 9.0, 0.0, 1.0))

	var root := Node3D.new()
	root.name = "WarpArch"
	add_child(root)

	# The hero: hand-rolled morphing + twisting sweep along the warped path.
	var arch_mesh: ArrayMesh = _wrp_build_morph_sweep(_WRP_SWEEP_SEGMENTS, twist_total)

	# Extra anamorphic warp on the committed mesh: a whole-body twist then a forward bend.
	var warped: ArrayMesh = arch_mesh
	var twisted: ArrayMesh = MorphoModifier.twist(warped, Vector3.UP, _WRP_POST_TWIST_DEG)
	if twisted != null:
		warped = twisted
	var bent: ArrayMesh = MorphoModifier.bend(warped, Vector3.FORWARD, _WRP_POST_BEND_DEG, Vector3.ZERO)
	if bent != null:
		warped = bent
	_cx_add_mesh(root, warped, masonry, Transform3D.IDENTITY, "ArchBody")

	# Feet: chunky plinths at each foot of the (pre-warp) path.
	var left_foot: Vector3 = _warp_point(0.0)
	var right_foot: Vector3 = _warp_point(1.0)
	_wrp_build_foot(root, left_foot, _WRP_FOOT_HALF * 1.55, trim)
	_wrp_build_foot(root, right_foot, _WRP_FOOT_HALF * 1.55, trim)

	# Under-arch glow disc + floating keystone eye.
	_wrp_build_glow(root, glow)
	_wrp_build_keystone_eye(root, trim, glow)

	# Scale uniformly to the sculpt height + centre + floor. The warp already presents its
	# best (forward-leaning) face to +X/+Z, so no extra yaw.
	_cx_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## Position along the arch for t in [0,1]: an out-of-plane, asymmetric, S-curved span. Uses
## the baked warp locals so the sweep Callable captures no node state. (Ported from v3.)
func _warp_point(t: float) -> Vector3:
	var tc: float = clampf(t, 0.0, 1.0)
	var x_lin: float = lerpf(-_WRP_SPAN * 0.5, _WRP_SPAN * 0.5, tc)
	var apex_bias: float = -_WRP_SPAN * _warp_apex_bias * sin(tc * PI)
	var x: float = x_lin + apex_bias
	var skew: float = pow(tc, 0.82)
	var y: float = maxf(_WRP_RISE * sin(skew * PI), 0.0)
	var lean: float = _warp_lean * sin(tc * PI)
	var s_wobble: float = _warp_swobble * sin(tc * TAU * 1.0)
	var z: float = lean + s_wobble + _warp_z_centre
	return Vector3(x, y, z)


## The cross-section SHAPE at parameter t, returned as _WRP_PROFILE_SIDES corners in the
## local (normal, binormal) plane BEFORE the per-ring twist: a chunky SQUARE at the feet
## morphing to a flattened DIAMOND BLADE at the crown. (Ported from v3's `_section_profile`.)
func _wrp_section_profile(t: float) -> Array[Vector2]:
	var tc: float = clampf(t, 0.0, 1.0)
	var crown: float = sin(tc * PI)
	var half: float = lerpf(_WRP_FOOT_HALF, _WRP_CROWN_HALF, crown * 0.7)
	var corner_off: float = deg_to_rad(45.0) * smoothstep(0.0, 1.0, crown)
	var aspect_w: float = lerpf(1.0, 1.62, crown)
	var aspect_d: float = lerpf(1.0, 0.40, crown)
	var pts: Array[Vector2] = []
	for i: int in range(_WRP_PROFILE_SIDES):
		var ang: float = deg_to_rad(45.0) + TAU * float(i) / float(_WRP_PROFILE_SIDES) + corner_off
		var cx: float = cos(ang) * half * aspect_w
		var cy: float = sin(ang) * half * aspect_d
		pts.append(Vector2(cx, cy))
	return pts


## Hand-rolled morphing sweep: mirrors MorphoSweep's parallel-transport frames but re-
## samples the cross-section SHAPE per ring (square→diamond) and applies the heavy twist on
## top, bridging rings into a UV'd ArrayMesh. (Ported from v3's `_build_morph_sweep`.)
func _wrp_build_morph_sweep(segments: int, twist_total_deg: float) -> ArrayMesh:
	var sides: int = _WRP_PROFILE_SIDES
	var u_steps: int = segments

	var centers: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var binormals: Array[Vector3] = []
	var prev_normal: Vector3 = Vector3.ZERO

	for ui: int in range(u_steps + 1):
		var u: float = float(ui) / float(u_steps)
		var center: Vector3 = _warp_point(u)
		var dt: float = 0.0008
		var u_next: float = minf(u + dt, 1.0)
		var u_prev: float = maxf(u - dt, 0.0)
		var tangent: Vector3 = (_warp_point(u_next) - _warp_point(u_prev))
		if tangent.length_squared() < 0.000001:
			tangent = Vector3.UP
		tangent = tangent.normalized()

		var normal: Vector3
		if prev_normal == Vector3.ZERO:
			var ref: Vector3 = Vector3.RIGHT
			normal = tangent.cross(ref)
			if normal.length_squared() < 0.001:
				normal = tangent.cross(Vector3.UP)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001:
				normal = prev_normal
			else:
				normal = normal.normalized()
		var binormal: Vector3 = tangent.cross(normal).normalized()
		prev_normal = normal

		centers.append(center)
		normals.append(normal)
		binormals.append(binormal)

	var rings: Array = []
	for ui: int in range(u_steps + 1):
		var u: float = float(ui) / float(u_steps)
		var fnormal: Vector3 = normals[ui]
		var fbinormal: Vector3 = binormals[ui]
		var center: Vector3 = centers[ui]
		var profile: Array[Vector2] = _wrp_section_profile(u)
		var twist_frac: float = smoothstep(0.06, 0.94, u)
		var twist_rad: float = deg_to_rad(twist_total_deg * twist_frac)
		var cos_tw: float = cos(twist_rad)
		var sin_tw: float = sin(twist_rad)
		var ring: Array[Vector3] = []
		for vi: int in range(sides):
			var pt: Vector2 = profile[vi]
			var rx: float = pt.x * cos_tw - pt.y * sin_tw
			var ry: float = pt.x * sin_tw + pt.y * cos_tw
			var offset: Vector3 = fnormal * rx + fbinormal * ry
			ring.append(center + offset)
		rings.append(ring)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_count: int = rings.size()
	for ri: int in range(ring_count - 1):
		var ring_a: Array = rings[ri]
		var ring_b: Array = rings[ri + 1]
		var ua: float = float(ri) / float(ring_count - 1)
		var ub: float = float(ri + 1) / float(ring_count - 1)
		for vi: int in range(sides):
			var vn: int = (vi + 1) % sides
			var sa: float = float(vi) / float(sides)
			var sb: float = float(vi + 1) / float(sides)
			var a: Vector3 = ring_a[vi]
			var b: Vector3 = ring_a[vn]
			var c: Vector3 = ring_b[vi]
			var d: Vector3 = ring_b[vn]
			var n1: Vector3 = (c - a).cross(b - a).normalized()
			st.set_normal(n1); st.set_uv(Vector2(sa, ua)); st.add_vertex(a)
			st.set_normal(n1); st.set_uv(Vector2(sa, ub)); st.add_vertex(c)
			st.set_normal(n1); st.set_uv(Vector2(sb, ua)); st.add_vertex(b)
			var n2: Vector3 = (d - c).cross(b - c).normalized()
			st.set_normal(n2); st.set_uv(Vector2(sa, ub)); st.add_vertex(c)
			st.set_normal(n2); st.set_uv(Vector2(sb, ub)); st.add_vertex(d)
			st.set_normal(n2); st.set_uv(Vector2(sb, ua)); st.add_vertex(b)

	_wrp_cap_ring(st, rings[0] as Array, true)
	_wrp_cap_ring(st, rings[ring_count - 1] as Array, false)
	st.generate_normals()
	return st.commit()


## Triangulate a ring as a flat cap (fan from its centroid). `flip` reverses winding for
## the start cap so both caps face outward. Emits UVs. (Ported from v3's `_cap_ring`.)
func _wrp_cap_ring(st: SurfaceTool, ring: Array, flip: bool) -> void:
	var centroid: Vector3 = Vector3.ZERO
	for p: Vector3 in ring:
		centroid += p
	centroid /= float(ring.size())
	var sides: int = ring.size()
	for vi: int in range(sides):
		var vn: int = (vi + 1) % sides
		var a: Vector3 = ring[vi]
		var b: Vector3 = ring[vn]
		var na: Vector3 = (a - centroid).cross(b - centroid).normalized()
		if flip:
			st.set_normal(-na); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(centroid)
			st.set_normal(-na); st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(b)
			st.set_normal(-na); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(a)
		else:
			st.set_normal(na); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(centroid)
			st.set_normal(na); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(a)
			st.set_normal(na); st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(b)


## A short stepped plinth (revolution) seated at planar `pos` on the ground. (Ported v3.)
func _wrp_build_foot(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var h: float = radius * 1.35
	var profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(radius * 1.05, 0.0),
		Vector2(radius * 1.05, h * 0.32),
		Vector2(radius * 0.92, h * 0.40),
		Vector2(radius * 0.92, h * 0.74),
		Vector2(radius * 0.74, h * 0.86),
		Vector2(radius * 0.70, h),
		Vector2(0.0, h)]
	_cx_add_mesh(parent, MorphoPrimitive.revolution(profile, 10), mat,
		Transform3D(Basis.IDENTITY, Vector3(pos.x, 0.0, pos.z)), "Foot")


## Soft warm glow disc + an OmniLight3D in the opening below the crown. (Ported from v3.)
func _wrp_build_glow(parent: Node3D, mat: Material) -> void:
	var crown: Vector3 = _warp_point(0.5)
	var glow_pos: Vector3 = Vector3(crown.x * 0.4, _WRP_RISE * 0.42, crown.z * 0.35)
	var disc_profile: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(0.34, 0.0),
		Vector2(0.40, 0.012),
		Vector2(0.40, -0.012)]
	var b := Basis()
	b = b.rotated(Vector3.RIGHT, deg_to_rad(64.0))
	b = b.rotated(Vector3.UP, deg_to_rad(-32.0))
	_cx_add_mesh(parent, MorphoPrimitive.revolution(disc_profile, 28), mat,
		Transform3D(b, glow_pos), "GlowDisc")

	var light := OmniLight3D.new()
	light.name = "GlowLight"
	light.light_color = accent
	light.light_energy = _cx_glow_energy(1.6)
	light.omni_range = 3.4
	light.omni_attenuation = 1.4
	light.position = glow_pos
	parent.add_child(light)


## A small surreal keystone EYE floating at the crown — a pale sclera + a glowing iris,
## a nod to the Codex's living masonry. (Ported from v3's `_build_keystone_eye`.)
func _wrp_build_keystone_eye(parent: Node3D, sclera_mat: Material, iris_mat: Material) -> void:
	var crown: Vector3 = _warp_point(0.46)
	var eye_pos: Vector3 = crown + Vector3(0.16, 0.02, 0.34)
	var sclera_r: float = 0.165
	var squash := Basis().scaled(Vector3(1.0, 0.82, 0.62))
	_cx_add_mesh(parent, MorphoPrimitive.sphere(sclera_r, 14, 8), sclera_mat,
		Transform3D(squash, eye_pos), "KeystoneSclera")
	var iris_r: float = sclera_r * 0.52
	_cx_add_mesh(parent, MorphoPrimitive.sphere(iris_r, 12, 7), iris_mat,
		Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.6)), eye_pos + Vector3(0.04, 0.0, 0.085)),
		"KeystoneIris")


# =============================================================================
# MODE: organic — a scaled living gate, half-building half-creature (trial v4)
# =============================================================================

const _ORG_ARCH_SPAN: float = 2.35      # outer distance between the two legs
const _ORG_ARCH_HEIGHT: float = 2.5     # crown height above y=0
const _ORG_LEG_HEIGHT: float = 1.0      # straight portion before the arc starts
const _ORG_BODY_RADIUS: float = 0.37    # nominal surface radius (scales seat here)
const _ORG_BODY_CORE_SCALE: float = 0.84  # core mesh shrunk so scales form the skin
const _ORG_BODY_FLATTEN: float = 0.92   # cross-section squash in Z (bulging slab)
const _ORG_BODY_SIDES: int = 20         # cross-section resolution
const _ORG_PATH_SEGMENTS: int = 120     # rings along the arch path
const _ORG_SCALE_ROWS_AROUND: int = 16  # scale columns around the cross-section
const _ORG_SCALE_LEN: float = 0.38      # along-path size of one scale cap
const _ORG_SCALE_WIDE: float = 0.34     # across size of one scale cap
const _ORG_SCALE_RISE: float = 0.12     # how far a scale domes off the surface
const _ORG_SCALE_OVERLAP: float = 1.8   # >1 => scales overlap like roof tiles
const _ORG_SCALE_PROFILE_RINGS: int = 5 # revolution rings per scale cap
const _ORG_ROOT_COUNT: int = 5          # primary roots rising through the hole
const _ORG_ROOT_SEGMENTS: int = 14      # rings per root tube

# Parallel-transport frames along the organic arch path (built per organic build).
var _org_frames: Array[Dictionary] = []
# Cladding density factor, derived from complexity, baked before _build_scales.
var _org_density: float = 1.0


func _build_organic() -> void:
	# complexity drives scale density + root branching (native ~1.0 at complexity 6).
	_org_density = clampf(0.45 + float(complexity) * 0.09, 0.45, 1.0)
	var skin := _cx_skin_mat(color_b)
	var stone := _cx_stone_mat(color_a)
	# Roots are a woody brown derived from masonry (darker, less saturated).
	var root_mat := _cx_stone_mat(Color(color_a.r * 0.52, color_a.g * 0.55, color_a.b * 0.58))
	root_mat.emission_energy_multiplier = _cx_glow_energy(0.06)
	# Hollow glow leans green-gold: blend accent toward the skin green.
	var glow := _cx_glow_mat(accent.lerp(Color(0.70, 0.95, 0.55), 0.45), 2.2, false, 1.0)

	_org_build_frames()

	var root := Node3D.new()
	root.name = "OrganicArch"
	add_child(root)

	_org_build_base(root, stone)
	_org_build_body(root, stone)
	_org_build_scales(root, skin)
	_org_build_roots(root, root_mat)
	_org_build_glow(root, glow)

	# Scale uniformly to the sculpt height + centre + floor. The arch faces +X/+Z (thin
	# in Z, the scaled front toward the camera) so no extra yaw.
	_cx_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## The arch centreline t in [0,1]: left leg up → semicircular crown → right leg down.
## (Ported from v4's `_arch_path`.)
func _org_arch_path(t: float) -> Vector3:
	var half_span: float = _ORG_ARCH_SPAN * 0.5 - _ORG_BODY_RADIUS
	var arc_r: float = half_span
	var arc_centre_y: float = _ORG_LEG_HEIGHT
	var leg_len: float = _ORG_LEG_HEIGHT
	var arc_len: float = PI * arc_r
	var total: float = leg_len + arc_len + leg_len
	var d: float = t * total
	if d < leg_len:
		return Vector3(-half_span, d, 0.0)
	elif d < leg_len + arc_len:
		var ad: float = d - leg_len
		var ang: float = PI - (ad / arc_len) * PI
		var x: float = arc_r * cos(ang)
		var y: float = arc_centre_y + arc_r * sin(ang)
		return Vector3(x, y, 0.0)
	else:
		var rd: float = d - leg_len - arc_len
		return Vector3(half_span, _ORG_LEG_HEIGHT - rd, 0.0)


## Precompute a {center, tangent, normal, binormal} frame at each station along the arch.
## Mirrors MorphoSweep's frame math so scales placed from these sit on the swept body.
## (Ported from v4's `_build_frames`.)
func _org_build_frames() -> void:
	_org_frames.clear()
	var u_steps: int = _ORG_PATH_SEGMENTS
	var prev_normal: Vector3 = Vector3.ZERO
	for ui: int in range(u_steps + 1):
		var u: float = float(ui) / float(u_steps)
		var center: Vector3 = _org_arch_path(u)
		var dt: float = 0.0008
		var u_next: float = minf(u + dt, 1.0)
		var u_prev: float = maxf(u - dt, 0.0)
		var tangent: Vector3 = (_org_arch_path(u_next) - _org_arch_path(u_prev)).normalized()
		if tangent.length_squared() < 0.001:
			tangent = Vector3.UP
		var normal: Vector3
		if prev_normal == Vector3.ZERO:
			var ref: Vector3 = Vector3.FORWARD
			normal = tangent.cross(ref)
			if normal.length_squared() < 0.001:
				normal = tangent.cross(Vector3.UP)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001:
				normal = prev_normal
			else:
				normal = normal.normalized()
		var binormal: Vector3 = tangent.cross(normal).normalized()
		prev_normal = normal
		_org_frames.append({
			"center": center,
			"tangent": tangent,
			"normal": normal,
			"binormal": binormal})


## Surface point + outward normal on the swept body at along-path u and around-section phi,
## from the precomputed frame (squashed circle of radius BODY_RADIUS). (Ported from v4.)
func _org_surface_point(u: float, phi: float) -> Array:
	var fi: int = clampi(int(round(u * float(_ORG_PATH_SEGMENTS))), 0, _org_frames.size() - 1)
	var fr: Dictionary = _org_frames[fi]
	var center: Vector3 = fr["center"]
	var n: Vector3 = fr["normal"]
	var b: Vector3 = fr["binormal"]
	var cphi: float = cos(phi)
	var sphi: float = sin(phi)
	var radial: Vector3 = n * cphi + b * (sphi * _ORG_BODY_FLATTEN)
	var point: Vector3 = center + radial * _ORG_BODY_RADIUS
	var nrm: Vector3 = (n * cphi + b * (sphi / maxf(_ORG_BODY_FLATTEN, 0.05))).normalized()
	return [point, nrm]


## The chunky rounded vault body via MorphoSweep.sweep, core shrunk inside the scale layer
## so the green domes are the visible skin. (Ported from v4's `_build_body`.)
func _org_build_body(parent: Node3D, mat: Material) -> void:
	var profile: Array[Vector2] = []
	for i: int in range(_ORG_BODY_SIDES):
		var a: float = TAU * float(i) / float(_ORG_BODY_SIDES)
		profile.append(Vector2(cos(a), sin(a) * _ORG_BODY_FLATTEN))
	var path_func: Callable = func(t: float) -> Vector3: return _org_arch_path(t)
	var core_r: float = _ORG_BODY_RADIUS * _ORG_BODY_CORE_SCALE
	var radius_func: Callable = func(_t: float) -> float: return core_r
	var body_mesh: Mesh = MorphoSweep.sweep(profile, path_func, radius_func, 0.0, _ORG_PATH_SEGMENTS, false)
	_cx_add_mesh(parent, body_mesh, mat, Transform3D.IDENTITY, "ArchBody")


## A single scale cap as a half-ellipsoid teardrop revolution (lip at y=0, domed crown).
## (Ported from v4's `_scale_cap_mesh`.)
func _org_scale_cap_mesh() -> ArrayMesh:
	var profile: Array[Vector2] = []
	var rings: int = _ORG_SCALE_PROFILE_RINGS
	for i: int in range(rings + 1):
		var t: float = float(i) / float(rings)
		var r: float = cos(t * PI * 0.5)
		var h: float = sin(t * PI * 0.5)
		profile.append(Vector2(r * 0.5, h))
	return MorphoPrimitive.revolution(profile, 14) as ArrayMesh


## Build an orthonormal Basis whose Y axis is `up_axis` (the scale's dome axis = surface
## normal) and whose Z axis aligns with `along_hint` (the path tangent), so scales tilt
## down-path like roof tiles. (Ported from v4's `_scale_basis`.)
func _org_scale_basis(up_axis: Vector3, along_hint: Vector3) -> Basis:
	var y: Vector3 = up_axis.normalized()
	var z_ref: Vector3 = along_hint - y * along_hint.dot(y)
	if z_ref.length_squared() < 0.0001:
		z_ref = Vector3.RIGHT - y * Vector3.RIGHT.dot(y)
		if z_ref.length_squared() < 0.0001:
			z_ref = Vector3.FORWARD
	z_ref = z_ref.normalized()
	var x: Vector3 = y.cross(z_ref).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Clad the swept body in overlapping scales: walk along-path in rows and around-section in
## columns, placing one scale cap per (row, col) with half-row brick offset, each tilted
## down-path so rows lap like roof tiles. Everything is appended into ONE ArrayMesh with
## per-vertex tint so the whole skin is a single MeshInstance3D. Per-triangle outward
## winding is forced (the cap's revolution winding is not camera-safe once instanced).
## (Ported from v4's `_build_scales`, with seeded jitter baked into locals per scale.)
func _org_build_scales(parent: Node3D, mat: Material) -> void:
	var cap: ArrayMesh = _org_scale_cap_mesh()
	if cap == null or cap.get_surface_count() == 0:
		return
	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(cap, 0) != OK:
		return
	var cap_verts: PackedVector3Array = PackedVector3Array()
	for vi: int in range(mdt.get_vertex_count()):
		cap_verts.append(mdt.get_vertex(vi))
	var cap_faces: PackedInt32Array = PackedInt32Array()
	for fi: int in range(mdt.get_face_count()):
		cap_faces.append(mdt.get_face_vertex(fi, 0))
		cap_faces.append(mdt.get_face_vertex(fi, 1))
		cap_faces.append(mdt.get_face_vertex(fi, 2))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var path_len_est: float = _org_estimate_path_length()
	var row_step: float = _ORG_SCALE_LEN / _ORG_SCALE_OVERLAP
	var rows: int = maxi(int(round(path_len_est / row_step)), 8)
	rows = int(round(float(rows) * lerpf(0.7, 1.0, clampf(_org_density, 0.0, 1.0))))
	var cols: int = _ORG_SCALE_ROWS_AROUND

	for ri: int in range(rows + 1):
		var u: float = float(ri) / float(rows)
		var fi: int = clampi(int(round(u * float(_ORG_PATH_SEGMENTS))), 0, _org_frames.size() - 1)
		var tangent: Vector3 = (_org_frames[fi] as Dictionary)["tangent"]
		var row_offset: float = 0.5 if (ri % 2 == 1) else 0.0
		for ci: int in range(cols):
			var phi: float = TAU * (float(ci) + row_offset) / float(cols)
			# Bake all seeded jitter into locals BEFORE building the transform.
			var size_jit: float = _rng.randf_range(0.9, 1.12)
			var rise_jit: float = _rng.randf_range(0.9, 1.15)
			var tint_jit: float = _rng.randf_range(-0.06, 0.06)
			var phi_jit: float = _rng.randf_range(-0.05, 0.05)
			var u_jit: float = _rng.randf_range(-0.004, 0.004)

			var sp: Array = _org_surface_point(clampf(u + u_jit, 0.0, 1.0), phi + phi_jit)
			var pos: Vector3 = sp[0]
			var nrm: Vector3 = sp[1]
			var under: float = clampf(nrm.dot(Vector3.DOWN), 0.0, 1.0)
			var sz: float = size_jit * lerpf(1.0, 0.85, under)
			var lap_axis: Vector3 = (nrm + tangent * 0.35).normalized()
			var basis: Basis = _org_scale_basis(lap_axis, tangent)
			var scaled_basis := basis * Basis().scaled(
				Vector3(_ORG_SCALE_WIDE * sz, _ORG_SCALE_RISE * rise_jit, _ORG_SCALE_LEN * sz))
			var seat: Vector3 = pos
			var xform := Transform3D(scaled_basis, seat)

			var row_t: float = float(ri) / float(rows)
			var warm: float = _rng.randf_range(0.0, 1.0)
			var warm_push: float = 0.18 if warm > 0.82 else 0.0
			var tint := Color(
				clampf(1.0 + tint_jit * 1.8 - row_t * 0.10 + warm_push, 0.62, 1.28),
				clampf(1.0 + tint_jit * 1.1 + row_t * 0.06 + warm_push * 0.5, 0.62, 1.28),
				clampf(1.0 + tint_jit * 1.4 - row_t * 0.12 - warm_push * 0.6, 0.5, 1.22))

			var dome_dir: Vector3 = xform.basis.y.normalized()
			var tri: int = 0
			while tri < cap_faces.size():
				var ia: int = cap_faces[tri]
				var ib: int = cap_faces[tri + 1]
				var ic: int = cap_faces[tri + 2]
				var wa: Vector3 = xform * cap_verts[ia]
				var wb: Vector3 = xform * cap_verts[ib]
				var wc: Vector3 = xform * cap_verts[ic]
				var face_n: Vector3 = (wb - wa).cross(wc - wa)
				var centroid: Vector3 = (wa + wb + wc) / 3.0
				var outward_ref: Vector3 = (centroid - seat).normalized() + dome_dir * 0.5
				if face_n.dot(outward_ref) < 0.0:
					var tmp: Vector3 = wb
					wb = wc
					wc = tmp
				var tn: Vector3 = (wb - wa).cross(wc - wa).normalized()
				st.set_color(tint); st.set_normal(tn); st.add_vertex(wa)
				st.set_color(tint); st.set_normal(tn); st.add_vertex(wb)
				st.set_color(tint); st.set_normal(tn); st.add_vertex(wc)
				tri += 3

	_cx_add_mesh(parent, st.commit(), mat, Transform3D.IDENTITY, "ScaleSkin")


## Rough numeric arc length of the arch path (sampled), for row counting. (Ported v4.)
func _org_estimate_path_length() -> float:
	var prev: Vector3 = _org_arch_path(0.0)
	var acc: float = 0.0
	var n: int = 80
	for i: int in range(1, n + 1):
		var p: Vector3 = _org_arch_path(float(i) / float(n))
		acc += p.distance_to(prev)
		prev = p
	return acc


## The organic growth in the hollow: ROOT_COUNT primary roots rising through the opening,
## each a wandering multi_tube with a child branch; the hero trunk adds a small crown of
## upper branches; gripping tendrils arch onto the legs. All seeded params baked into
## locals up front. (Ported from v4's `_build_roots`.)
func _org_build_roots(parent: Node3D, mat: Material) -> void:
	var half_span: float = _ORG_ARCH_SPAN * 0.5 - _ORG_BODY_RADIUS
	var inner_w: float = half_span - _ORG_BODY_RADIUS * 0.6
	# Root count scales gently with density.
	var root_n: int = clampi(int(round(float(_ORG_ROOT_COUNT) * lerpf(0.7, 1.1, _org_density))), 3, 7)
	for i: int in range(root_n):
		var is_hero: bool = (i == 0)
		var base_x: float
		var base_r: float
		var top_y: float
		if is_hero:
			base_x = _rng.randf_range(-0.12, 0.12)
			base_r = _rng.randf_range(0.16, 0.20)
			top_y = _rng.randf_range(_ORG_ARCH_HEIGHT * 0.78, _ORG_ARCH_HEIGHT * 0.92)
		else:
			base_x = lerpf(-inner_w, inner_w, float(i) / float(maxi(root_n - 1, 1)))
			base_x += _rng.randf_range(-0.10, 0.10)
			base_r = _rng.randf_range(0.075, 0.115)
			top_y = _rng.randf_range(_ORG_ARCH_HEIGHT * 0.55, _ORG_ARCH_HEIGHT * 0.8)
		var base_z: float = _rng.randf_range(-0.18, 0.18)
		var lean_x: float = _rng.randf_range(-0.30, 0.30) + signf(base_x) * 0.18
		if is_hero:
			lean_x = _rng.randf_range(-0.18, 0.18)
		var wig: float = _rng.randf_range(0.10, 0.26)
		var wig_f: float = _rng.randf_range(2.0, 3.4)
		var phase: float = _rng.randf_range(0.0, TAU)
		var branch_dir: float = signf(_rng.randf_range(-1.0, 1.0))
		var branch_lift: float = _rng.randf_range(0.30, 0.55)

		var positions: Array[Vector3] = []
		var radii: Array[float] = []
		var segs: int = _ORG_ROOT_SEGMENTS
		for s: int in range(segs):
			var t: float = float(s) / float(segs - 1)
			var x: float = lerpf(base_x, base_x + lean_x, t) + sin(t * PI * wig_f + phase) * wig * (1.0 - t * 0.4)
			var y: float = t * top_y
			var z: float = lerpf(base_z, base_z * 0.3, t) + cos(t * PI * (wig_f * 0.8) + phase) * wig * 0.5 * (1.0 - t * 0.5)
			positions.append(Vector3(x, y, z))
			radii.append(lerpf(base_r, base_r * 0.18, t))
		_cx_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 7), mat,
			Transform3D.IDENTITY, "RootTrunk_%d" % i)

		# A child branch peeling off the upper trunk.
		var bi: int = clampi(int(float(segs) * lerpf(0.45, 0.65, _rng.randf())), 1, positions.size() - 2)
		var bstart: Vector3 = positions[bi]
		var bstart_r: float = radii[bi] * 0.85
		var b_positions: Array[Vector3] = []
		var b_radii: Array[float] = []
		var bsegs: int = 8
		var b_end: Vector3 = bstart + Vector3(branch_dir * _rng.randf_range(0.25, 0.5),
			branch_lift, _rng.randf_range(-0.15, 0.15))
		var b_ctrl: Vector3 = bstart + Vector3(branch_dir * 0.12, branch_lift * 0.4, 0.0)
		for s2: int in range(bsegs):
			var t2: float = float(s2) / float(bsegs - 1)
			var a: Vector3 = bstart.lerp(b_ctrl, t2)
			var bb: Vector3 = b_ctrl.lerp(b_end, t2)
			b_positions.append(a.lerp(bb, t2))
			b_radii.append(lerpf(bstart_r, bstart_r * 0.2, t2))
		_cx_add_mesh(parent, MorphoPrimitive.multi_tube(b_positions, b_radii, 6), mat,
			Transform3D.IDENTITY, "RootBranch_%d" % i)

		# The hero trunk sprouts a small crown of upper branches into the hollow.
		if is_hero:
			var crown_n: int = 3
			for cb: int in range(crown_n):
				var cidx: int = clampi(positions.size() - 2 - cb, 1, positions.size() - 2)
				var cstart: Vector3 = positions[cidx]
				var cstart_r: float = radii[cidx] * 0.8
				var cdir: float = -1.0 if (cb % 2 == 0) else 1.0
				var clen: float = _rng.randf_range(0.35, 0.6)
				var clift: float = _rng.randf_range(0.25, 0.45)
				var cz: float = _rng.randf_range(-0.18, 0.22)
				var c_end: Vector3 = cstart + Vector3(cdir * clen, clift, cz)
				var c_ctrl: Vector3 = cstart + Vector3(cdir * clen * 0.4, clift * 0.7, cz * 0.5)
				var c_positions: Array[Vector3] = []
				var c_radii: Array[float] = []
				var csegs: int = 8
				for s3: int in range(csegs):
					var t3: float = float(s3) / float(csegs - 1)
					var ca: Vector3 = cstart.lerp(c_ctrl, t3)
					var cbb: Vector3 = c_ctrl.lerp(c_end, t3)
					c_positions.append(ca.lerp(cbb, t3))
					c_radii.append(lerpf(cstart_r, cstart_r * 0.16, t3))
				_cx_add_mesh(parent, MorphoPrimitive.multi_tube(c_positions, c_radii, 6), mat,
					Transform3D.IDENTITY, "RootCrown_%d" % cb)

	_org_build_tendrils(parent, half_span, mat)


## Thin tendrils that arch from inside the opening up to grip the arch legs — bezier_sweep
## tubes oriented by their own path frames. (Ported from v4's `_build_tendrils`.)
func _org_build_tendrils(parent: Node3D, half_span: float, mat: Material) -> void:
	var tendril_n: int = 3
	for i: int in range(tendril_n):
		var side: float = -1.0 if (i % 2 == 0) else 1.0
		var sx: float = _rng.randf_range(-0.2, 0.2)
		var sy: float = _rng.randf_range(0.2, 0.6)
		var grip_y: float = _rng.randf_range(_ORG_LEG_HEIGHT * 0.4, _ORG_LEG_HEIGHT + 0.4)
		var thick: float = _rng.randf_range(0.03, 0.05)
		var bow: float = _rng.randf_range(0.3, 0.6)
		var p0: Vector3 = Vector3(sx, sy, _rng.randf_range(-0.1, 0.1))
		var p3: Vector3 = Vector3(side * (half_span - _ORG_BODY_RADIUS * 0.5), grip_y, _rng.randf_range(0.05, 0.2))
		var p1: Vector3 = p0 + Vector3(side * bow * 0.5, bow, 0.0)
		var p2: Vector3 = p3 + Vector3(-side * bow * 0.3, bow * 0.4, 0.1)
		var cross: Array[Vector2] = []
		var cn: int = 6
		for c: int in range(cn):
			var a: float = TAU * float(c) / float(cn)
			cross.append(Vector2(cos(a) * thick, sin(a) * thick))
		var ctrl: Array[Vector3] = [p0, p1, p2, p3]
		_cx_add_mesh(parent, MorphoPrimitive.bezier_sweep(ctrl, cross, 16, 40.0), mat,
			Transform3D.IDENTITY, "Tendril_%d" % i)


## A low diamond-tiled slab base: a revolution disc + a grid of small raised diamond tile
## caps batched into one mesh, clipped to the disc. (Ported from v4's `_build_base`.)
func _org_build_base(parent: Node3D, mat: Material) -> void:
	var base_r: float = _ORG_ARCH_SPAN * 0.62
	var slab_profile: Array[Vector2] = [
		Vector2(0.0, -0.10),
		Vector2(base_r * 0.96, -0.10),
		Vector2(base_r * 1.0, -0.04),
		Vector2(base_r * 0.98, 0.0),
		Vector2(0.0, 0.0)]
	_cx_add_mesh(parent, MorphoPrimitive.revolution(slab_profile, 40), mat,
		Transform3D.IDENTITY, "BaseSlab")

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tile: float = 0.34
	var n: int = int(ceil(base_r * 2.0 / tile)) + 2
	var placed: int = 0
	for ix: int in range(-n, n + 1):
		for iz: int in range(-n, n + 1):
			var cx: float = float(ix) * tile
			var cz: float = float(iz) * tile
			if iz % 2 != 0:
				cx += tile * 0.5
			if Vector2(cx, cz).length() > base_r * 0.92:
				continue
			var half: float = tile * 0.40
			var apex: Vector3 = Vector3(cx, 0.05, cz)
			var n0: Vector3 = Vector3(cx + half, 0.0, cz)
			var n1: Vector3 = Vector3(cx, 0.0, cz + half)
			var n2: Vector3 = Vector3(cx - half, 0.0, cz)
			var n3: Vector3 = Vector3(cx, 0.0, cz - half)
			_org_tri(st, apex, n0, n1)
			_org_tri(st, apex, n1, n2)
			_org_tri(st, apex, n2, n3)
			_org_tri(st, apex, n3, n0)
			placed += 1
	if placed > 0:
		_cx_add_mesh(parent, st.commit(), mat, Transform3D.IDENTITY, "DiamondTiles")


func _org_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var nrm: Vector3 = (b - a).cross(c - a).normalized()
	st.set_normal(nrm); st.add_vertex(a)
	st.set_normal(nrm); st.add_vertex(b)
	st.set_normal(nrm); st.add_vertex(c)


## A soft emissive glow pod + a faint OmniLight nestled under the crown's inner curve,
## slightly forward so the camera sees it through the opening. (Ported from v4's glow.)
func _org_build_glow(parent: Node3D, mat: Material) -> void:
	var gy: float = _ORG_LEG_HEIGHT + (_ORG_ARCH_SPAN * 0.5 - _ORG_BODY_RADIUS) * 0.55
	_cx_add_mesh(parent, MorphoPrimitive.sphere(0.26, 14, 8), mat,
		Transform3D(Basis().scaled(Vector3(1.2, 0.85, 1.2)), Vector3(0.0, gy, 0.10)), "HollowGlow")

	var lamp := OmniLight3D.new()
	lamp.name = "HollowLight"
	lamp.light_color = accent.lerp(Color(0.70, 0.95, 0.55), 0.45)
	lamp.light_energy = _cx_glow_energy(1.1)
	lamp.omni_range = 2.2
	lamp.position = Vector3(0.0, gy, 0.10)
	parent.add_child(lamp)


# =============================================================================
# MODE: ribarch — concentric striped ribbed bands on spindly legs (trial v1)
# =============================================================================

const _RIB_SEGMENTS_PER_BAND: int = 16   # stripe segments along each band's arc
const _RIB_SEG_RINGS: int = 5            # sweep rings per short stripe segment
const _RIB_PROFILE_STEPS: int = 14       # samples around the rounded-rect profile
const _RIB_INNER_SPAN: float = 0.92      # half-span of the INNERMOST band (X)
const _RIB_SPAN_STEP: float = 0.255      # span growth per outward band (rainbow gap)
const _RIB_INNER_RISE: float = 1.62      # apex height of innermost band (Y)
const _RIB_RISE_STEP: float = 0.255      # rise growth per outward band
const _RIB_HORSESHOE: float = 0.10       # how far the springing tucks under
const _RIB_BAND_DEPTH: float = 0.115     # rib thickness along Z
const _RIB_BAND_WIDTH: float = 0.165     # rib width across the arc face (thin = bands read apart)
const _RIB_Z_STEP: float = 0.018         # tiny Z offset per band (near-coplanar)
const _RIB_LEG_HEIGHT: float = 0.92      # springing sits at this Y; legs run down to 0
const _RIB_LEG_TOP_R: float = 0.115      # leg radius where it meets the arch
const _RIB_LEG_TIP_R: float = 0.012      # leg radius at the ground point (spike)
const _RIB_LEG_SPLAY: float = 0.46       # outward splay of leg feet (X+Z)

# Materials baked once per ribarch build, derived from the colour triad.
var _rib_bands: int = 5                   # nested concentric bands (from complexity)
var _rib_legs: int = 6                    # spindly stilts
var _rib_mat_primary: StandardMaterial3D  # PINK/coral — color_a
var _rib_mat_secondary: StandardMaterial3D  # GREEN stripe — color_b
var _rib_mat_white: StandardMaterial3D    # white stripe (lighten primary toward white)
var _rib_mat_cream: StandardMaterial3D    # cream voussoir (lighten secondary toward cream)
var _rib_mat_leg: StandardMaterial3D      # warm-stone legs (derive from color_a)
var _rib_mat_crown: StandardMaterial3D    # dark crown finial (dark derive)
var _rib_mat_cell: StandardMaterial3D     # pale foam ground cells (derive)


## ribarch DNA mapping: color_a = rib PRIMARY (pink/coral), color_b = stripe SECONDARY
## (green); white/cream are lightened derives; legs a warm-stone derive; crown a dark derive;
## accent a soft under-glow. complexity scales band count + leg count.
func _build_ribarch() -> void:
	_rib_bands = clampi(3 + complexity / 2, 3, 7)
	_rib_legs = clampi(4 + complexity / 3, 4, 8)

	# Stripe materials reuse the trim shape (matte + faint emission floor) but recolour.
	_rib_mat_primary = _cx_trim_mat(color_a)
	_rib_mat_secondary = _cx_trim_mat(color_b)
	_rib_mat_white = _cx_trim_mat(color_a.lerp(Color(1.0, 1.0, 0.96), 0.72))
	_rib_mat_cream = _cx_trim_mat(color_b.lerp(Color(0.95, 0.90, 0.74), 0.70))
	# Legs: a warm-stone derive of the masonry tone.
	_rib_mat_leg = _cx_stone_mat(color_a.lerp(Color(0.78, 0.62, 0.46), 0.55))
	# Crown finial: a dark derive of the secondary, low glow.
	var crown_c: Color = Color(color_b.r * 0.26, color_b.g * 0.24, color_b.b * 0.32)
	_rib_mat_crown = _cx_stone_mat(crown_c)
	_rib_mat_crown.emission_energy_multiplier = _cx_glow_energy(0.10)
	# Ground foam cells: a pale, near-white matte (no emission floor — soft).
	_rib_mat_cell = StandardMaterial3D.new()
	_rib_mat_cell.albedo_color = color_b.lerp(Color(0.88, 0.86, 0.80), 0.6)
	_rib_mat_cell.roughness = clampf(rough_amt * 1.05, 0.02, 1.0)
	_rib_mat_cell.metallic = 0.0

	var root := Node3D.new()
	root.name = "RibArch"
	add_child(root)

	# Whole arch group lifted onto the legs; bands built in arch-local space (springing at
	# y=0) then raised by leg height. Broad striped face points toward +Z.
	var arch := Node3D.new()
	arch.name = "Bands"
	arch.position = Vector3(0.0, _RIB_LEG_HEIGHT, 0.0)
	root.add_child(arch)
	# Outer bands first (further back) so inner bands draw in front of them.
	for band: int in range(_rib_bands - 1, -1, -1):
		_rib_build_band(arch, band)

	var legs := Node3D.new()
	legs.name = "Legs"
	root.add_child(legs)
	_rib_build_legs(legs)

	var crown := Node3D.new()
	crown.name = "Crown"
	root.add_child(crown)
	_rib_build_crown(crown)

	var ground := Node3D.new()
	ground.name = "GroundCells"
	root.add_child(ground)
	_rib_build_ground_cells(ground)

	_rib_build_glow(root)

	# Centre + floor + scale to the sculpt height (the broad face already presents to +X/+Z).
	_cx_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## A round / horseshoe arch point in the X-Y plane at t in [0,1]: t=0 LEFT foot, sweeping up
## over the crown to t=1 RIGHT foot. (Ported from v1's `_arch_point`.)
func _rib_arch_point(t: float, half_span: float, rise: float, z: float) -> Vector3:
	var extra: float = _RIB_HORSESHOE
	var ang: float = lerpf(PI + extra, -extra, t)
	var r: float = half_span
	var x: float = cos(ang) * r
	var y_circle: float = sin(ang) * r
	var apex: float = r
	var y: float = y_circle * (rise / maxf(apex, 0.0001))
	return Vector3(x, y, z)


## Rounded-rectangle cross-section for a rib band: WIDE across the arch face, DEEP through the
## layer, corners eased. (Ported from v1's `_rib_profile`.)
func _rib_profile(width: float, depth: float, steps: int) -> Array[Vector2]:
	var hw: float = width * 0.5
	var hd: float = depth * 0.5
	var corner: float = minf(hw, hd) * 0.55
	var pts: Array[Vector2] = []
	var per_corner: int = maxi(2, int(steps / 4))
	var centres: Array[Vector2] = [
		Vector2(hw - corner, hd - corner),
		Vector2(-(hw - corner), hd - corner),
		Vector2(-(hw - corner), -(hd - corner)),
		Vector2(hw - corner, -(hd - corner))]
	var start_angles: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5]
	for ci: int in range(4):
		var c: Vector2 = centres[ci]
		var sa: float = start_angles[ci]
		for k: int in range(per_corner):
			var a: float = sa + (PI * 0.5) * float(k) / float(per_corner)
			pts.append(c + Vector2(cos(a), sin(a)) * corner)
	return pts


## One nested band, striped into short swept segments — each segment its own MeshInstance3D
## with one stripe material. Seeded cream voussoir decisions pre-rolled into a typed local so
## the path closures stay value-only. (Ported from v1's `_build_rib`.)
func _rib_build_band(parent: Node3D, band: int) -> void:
	var half_span: float = _RIB_INNER_SPAN + _RIB_SPAN_STEP * float(band)
	var rise: float = _RIB_INNER_RISE + _RIB_RISE_STEP * float(band)
	var z: float = -_RIB_Z_STEP * float(band)
	var prof: Array[Vector2] = _rib_profile(_RIB_BAND_WIDTH, _RIB_BAND_DEPTH, _RIB_PROFILE_STEPS)
	var seg_count: int = _RIB_SEGMENTS_PER_BAND

	var is_cream: Array[bool] = []
	for s: int in range(seg_count):
		is_cream.append(_rng.randf() < 0.16)

	for s: int in range(seg_count):
		var t0: float = float(s) / float(seg_count)
		var t1: float = float(s + 1) / float(seg_count)
		var hs: float = half_span
		var rs: float = rise
		var zz: float = z
		var seg_path: Callable = func(u: float) -> Vector3:
			return _rib_arch_point(lerpf(t0, t1, u), hs, rs, zz)
		var seg_radius: Callable = func(_u: float) -> float:
			return 1.0
		var seg_mesh: Mesh = MorphoSweep.sweep(prof, seg_path, seg_radius, 0.0, _RIB_SEG_RINGS, false)
		if seg_mesh == null:
			continue
		_cx_add_mesh(parent, seg_mesh, _rib_stripe_material(band, s, is_cream[s]),
			Transform3D.IDENTITY, "BandSeg_%d_%d" % [band, s])


## Choose the stripe material for segment `s` of `band`: primary ↔ (secondary/white checker);
## seeded cream blocks override as voussoirs; green/white phase-shifts per band. (Ported v1.)
func _rib_stripe_material(band: int, s: int, cream: bool) -> StandardMaterial3D:
	if cream:
		return _rib_mat_cream
	if s % 2 == 0:
		return _rib_mat_primary
	if (s + band) % 4 == 1:
		return _rib_mat_secondary
	return _rib_mat_white


## Spindly tapered stilts under the two springing points, fanned across the band-stack depth.
## (Ported from v1's `_build_legs`.)
func _rib_build_legs(parent: Node3D) -> void:
	var outer_span: float = _RIB_INNER_SPAN + _RIB_SPAN_STEP * float(_rib_bands - 1)
	var mid_z: float = -_RIB_Z_STEP * float(_rib_bands - 1) * 0.5
	var per_side: int = maxi(1, _rib_legs / 2)
	for side: int in [-1, 1]:
		var foot_x: float = float(side) * outer_span
		for j: int in range(per_side):
			var f: float = 0.0
			if per_side > 1:
				f = float(j) / float(per_side - 1) - 0.5
			var top: Vector3 = Vector3(
				foot_x,
				_RIB_LEG_HEIGHT,
				mid_z + f * (_RIB_Z_STEP * float(_rib_bands) * 0.9))
			var foot: Vector3 = Vector3(
				foot_x + float(side) * _RIB_LEG_SPLAY * (0.6 + 0.5 * absf(f)),
				0.0,
				mid_z + f * (_RIB_Z_STEP * float(_rib_bands) * 2.4))
			_rib_build_one_leg(parent, top, foot)


## One spindly leg: a bowed multi_tube tapering top→tip (near-point at the ground). (v1.)
func _rib_build_one_leg(parent: Node3D, top: Vector3, foot: Vector3) -> void:
	var rings: int = 8
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var bow_dir: Vector3 = Vector3(signf(foot.x - top.x), 0.0, 0.0)
	for i: int in range(rings):
		var t: float = float(i) / float(rings - 1)
		var p: Vector3 = top.lerp(foot, t)
		var bow: float = sin(t * PI) * 0.10
		p += bow_dir * bow
		positions.append(p)
		var r: float = lerpf(_RIB_LEG_TOP_R, _RIB_LEG_TIP_R, pow(t, 1.25))
		radii.append(r)
	_cx_add_mesh(parent, MorphoPrimitive.multi_tube(positions, radii, 7), _rib_mat_leg,
		Transform3D.IDENTITY, "Leg")


## A small dark spiky coronet at the crown of the outermost band: a ring of tapered spikes
## fanning up-and-out, plus a taller central crest. (Ported from v1's `_build_crown`.)
func _rib_build_crown(parent: Node3D) -> void:
	var outer_rise: float = _RIB_INNER_RISE + _RIB_RISE_STEP * float(_rib_bands - 1)
	var outer_span: float = _RIB_INNER_SPAN + _RIB_SPAN_STEP * float(_rib_bands - 1)
	var front_z: float = _RIB_BAND_DEPTH * 0.5 + 0.03
	var apex_local: Vector3 = _rib_arch_point(0.5, outer_span, outer_rise, front_z)
	var apex: Vector3 = apex_local + Vector3(0.0, _RIB_LEG_HEIGHT + _RIB_BAND_WIDTH * 0.4, 0.0)

	var spikes: int = 9
	var base_r: float = 0.058
	var ring_r: float = 0.135
	for i: int in range(spikes):
		var ang: float = TAU * float(i) / float(spikes)
		var lean := Vector3(cos(ang) * ring_r, 0.0, sin(ang) * ring_r * 0.7)
		var base: Vector3 = apex + lean
		var height: float = lerpf(0.20, 0.34, 0.5 + 0.5 * sin(ang * 2.0))
		var tip: Vector3 = base + Vector3(lean.x * 0.8, height, lean.z * 0.8)
		_rib_build_spike(parent, base, tip, base_r)
	_rib_build_spike(parent, apex, apex + Vector3(0.0, 0.46, 0.0), base_r * 1.2)


## One crown spike: a short multi_tube tapering to a near-point. (Ported from v1.)
func _rib_build_spike(parent: Node3D, base: Vector3, tip: Vector3, base_r: float) -> void:
	var rings: int = 5
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in range(rings):
		var t: float = float(i) / float(rings - 1)
		positions.append(base.lerp(tip, t))
		radii.append(lerpf(base_r, 0.004, pow(t, 1.1)))
	var mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 6)
	if mesh == null:
		return
	_cx_add_mesh(parent, mesh, _rib_mat_crown, Transform3D.IDENTITY, "CrownSpike")


## A handful of flat elliptical foam discs scattered around the feet — flattened revolutions,
## very low, slightly overlapping. (Ported from v1's `_build_ground_cells`.)
func _rib_build_ground_cells(parent: Node3D) -> void:
	var count: int = 9
	var outer_span: float = _RIB_INNER_SPAN + _RIB_SPAN_STEP * float(_rib_bands - 1)
	for i: int in range(count):
		var cx: float = _rng.randf_range(-outer_span - 0.5, outer_span + 0.5)
		var cz: float = _rng.randf_range(-0.7, 0.9)
		var rad: float = _rng.randf_range(0.22, 0.46)
		var aspect: float = _rng.randf_range(0.6, 0.95)
		var profile: Array[Vector2] = [
			Vector2(0.0, 0.022),
			Vector2(rad * 0.6, 0.016),
			Vector2(rad * 0.92, 0.006),
			Vector2(rad, 0.0)]
		var mesh: Mesh = MorphoPrimitive.revolution(profile, 18)
		if mesh == null:
			continue
		var basis := Basis().scaled(Vector3(1.0, 1.0, aspect))
		_cx_add_mesh(parent, mesh, _rib_mat_cell,
			Transform3D(basis, Vector3(cx, 0.001, cz)), "FoamCell_%d" % i)


## A small restrained warm glow sphere in the central opening, midway up the inner rise.
## (Ported from v1's `_build_glow`, recoloured to the accent triad.)
func _rib_build_glow(parent: Node3D) -> void:
	var glow_mat: StandardMaterial3D = _cx_glow_mat(accent, 2.0, false, 1.0)
	_cx_add_mesh(parent, MorphoPrimitive.sphere(0.10, 12, 6), glow_mat,
		Transform3D(Basis.IDENTITY, Vector3(0.0, _RIB_LEG_HEIGHT + _RIB_INNER_RISE * 0.42, 0.0)),
		"InnerGlow")


# =============================================================================
# MODE: foambridge — a foam / cellular membrane span (trial v2)
# =============================================================================

const _FOAM_SPAN_LENGTH: float = 2.62    # X extent of the bridge
const _FOAM_SPAN_WIDTH: float = 0.66     # Z extent (deck depth)
const _FOAM_ARCH_RISE: float = 0.34      # how far mid-span bows up
const _FOAM_DECK_THICK: float = 0.085    # vertical thickness of the membrane slab
const _FOAM_STRUT_RADIUS: float = 0.020  # in-plane half-thickness of each cell wall
const _FOAM_RING_SIDES: int = 6          # cross-section sides of rail / thread tubes
const _FOAM_RING_SEGMENTS: int = 24      # segments around one ellipse cell wall
const _FOAM_CELL_COLS: int = 14          # cell-lattice columns along the span
const _FOAM_CELL_ROWS: int = 4           # cell-lattice rows across the width
const _FOAM_CELL_OVERLAP: float = 1.34   # >1 grows ellipses so neighbours fuse into froth
const _FOAM_SUBCELL_CHANCE: float = 0.7  # chance a gap gets an extra small cell
const _FOAM_TINT_CHANCE: float = 0.15    # fraction of cells given a jewel tint

# Materials baked once per foambridge build, derived from the colour triad.
var _foam_mat_membrane: StandardMaterial3D  # pale strut tone — color_a (pale bone)
var _foam_mat_anchor: StandardMaterial3D    # ANCHOR stone — color_b
var _foam_mat_tint_a: StandardMaterial3D    # jewel cell tint A (derive from accent)
var _foam_mat_tint_b: StandardMaterial3D    # jewel cell tint B (derive from color_a)
var _foam_mat_thread: StandardMaterial3D    # pendant thread (pale)
var _foam_mat_drop: StandardMaterial3D      # glowing teardrop (accent)


## One foam cell: parametric centre (u along span, w across width in [-1,1]), ellipse
## semi-axes, an in-plane orientation, and a tint index. (Ported from v2's FoamCell.)
class _FoamCell:
	var u: float
	var w: float
	var a: float          # semi-axis along the span (u-direction, world m)
	var b: float          # semi-axis across the width (w-direction, world m)
	var angle: float      # in-plane rotation of the ellipse (radians)
	var tint: int         # 0 none, 1 tint_a, 2 tint_b


## foambridge DNA mapping: color_a = MEMBRANE / strut tone (pale bone), color_b = ANCHOR
## stone; jewel cell tints derived from accent + color_a; accent = pendant glow.
func _build_foambridge() -> void:
	# MEMBRANE / struts — pale bone, faint emission floor (trim shape on color_a).
	_foam_mat_membrane = _cx_trim_mat(color_a)
	# ANCHORS — warm stone, matte (no emission floor; chunky masonry).
	_foam_mat_anchor = StandardMaterial3D.new()
	_foam_mat_anchor.albedo_color = color_b
	_foam_mat_anchor.roughness = clampf(rough_amt * 1.05, 0.02, 1.0)
	_foam_mat_anchor.metallic = clampf(metallic_amt, 0.0, 1.0)
	# Jewel tints: one from accent (warm), one from color_a pushed cool.
	_foam_mat_tint_a = _cx_trim_mat(accent.lerp(Color(0.80, 0.55, 0.55), 0.45))
	_foam_mat_tint_a.emission_energy_multiplier = _cx_glow_energy(0.14)
	_foam_mat_tint_b = _cx_trim_mat(color_a.lerp(Color(0.55, 0.62, 0.74), 0.55))
	_foam_mat_tint_b.emission_energy_multiplier = _cx_glow_energy(0.14)
	# Pendant thread — pale, matte.
	_foam_mat_thread = StandardMaterial3D.new()
	_foam_mat_thread.albedo_color = color_a.lerp(Color(0.86, 0.82, 0.72), 0.4)
	_foam_mat_thread.roughness = 0.8
	_foam_mat_thread.metallic = 0.0
	# Pendant drop — soft warm accent glow.
	_foam_mat_drop = _cx_glow_mat(accent, 2.0, false, 1.0)

	var root := Node3D.new()
	root.name = "FoamBridge"
	add_child(root)

	var cells: Array[_FoamCell] = _foam_bake_cells()

	# The froth: bone struts batched into one mesh; tinted cells split into their own batches.
	var bone_st := SurfaceTool.new()
	bone_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tint_a_st := SurfaceTool.new()
	tint_a_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tint_b_st := SurfaceTool.new()
	tint_b_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tint_a_used: bool = false
	var tint_b_used: bool = false

	for cell: _FoamCell in cells:
		match cell.tint:
			1:
				_foam_emit_ellipse_ring(tint_a_st, cell, _FOAM_STRUT_RADIUS * 1.08)
				tint_a_used = true
			2:
				_foam_emit_ellipse_ring(tint_b_st, cell, _FOAM_STRUT_RADIUS * 1.08)
				tint_b_used = true
			_:
				_foam_emit_ellipse_ring(bone_st, cell, _FOAM_STRUT_RADIUS)

	# Long edge rails tie the ragged outer cells into a clean spanning silhouette.
	_foam_emit_edge_rails(bone_st)
	bone_st.generate_normals()
	_cx_add_mesh(root, bone_st.commit(), _foam_mat_membrane, Transform3D.IDENTITY, "FoamStruts")

	if tint_a_used:
		tint_a_st.generate_normals()
		_cx_add_mesh(root, tint_a_st.commit(), _foam_mat_tint_a, Transform3D.IDENTITY, "FoamTintA")
	if tint_b_used:
		tint_b_st.generate_normals()
		_cx_add_mesh(root, tint_b_st.commit(), _foam_mat_tint_b, Transform3D.IDENTITY, "FoamTintB")

	# Anchors at each end + a pendant drop from the mid-span underside.
	_foam_build_anchor(root, 0.0)
	_foam_build_anchor(root, 1.0)
	_foam_build_pendant(root)

	# Centre + floor + scale to the sculpt height.
	_cx_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## Centreline of the span at u in [0,1] (left→right): X marches the length, Y bows as a sine
## arch. (Ported from v2's `_span_point`.)
func _foam_span_point(u: float) -> Vector3:
	var x: float = lerpf(-_FOAM_SPAN_LENGTH * 0.5, _FOAM_SPAN_LENGTH * 0.5, u)
	var y: float = _FOAM_ARCH_RISE * sin(u * PI)
	return Vector3(x, y, 0.0)


## Unit tangent of the centreline at u. (Ported from v2's `_span_tangent`.)
func _foam_span_tangent(u: float) -> Vector3:
	var dydu: float = _FOAM_ARCH_RISE * PI * cos(u * PI)
	return Vector3(_FOAM_SPAN_LENGTH, dydu, 0.0).normalized()


## Orthonormal frame at u mapping local-X→forward, local-Y→deck-normal, local-Z→across-width
## so an ellipse drawn in local XZ lies flat in the deck plane. (Ported from v2's `_span_frame`.)
func _foam_span_frame(u: float) -> Basis:
	var forward: Vector3 = _foam_span_tangent(u)
	var side: Vector3 = Vector3(0.0, 0.0, 1.0)
	var up: Vector3 = side.cross(forward).normalized()
	side = forward.cross(up).normalized()
	return Basis(forward, up, side)


## Bake the full set of foam cells deterministically: a primary jittered lattice of
## large/medium ovals + opportunistic small sub-cells in the gaps. All randomness pulled into
## typed locals first. (Ported from v2's `_bake_cells`.)
func _foam_bake_cells() -> Array[_FoamCell]:
	var cells: Array[_FoamCell] = []
	var half_w_world: float = _FOAM_SPAN_WIDTH * 0.5
	for ci: int in range(_FOAM_CELL_COLS):
		var u_base: float = (float(ci) + 0.5) / float(_FOAM_CELL_COLS)
		var row_off: float = 0.5 if (ci % 2 == 1) else 0.0
		for ri: int in range(_FOAM_CELL_ROWS):
			var w_base: float = (float(ri) + 0.5 + row_off) / float(_FOAM_CELL_ROWS) * 2.0 - 1.0
			if absf(w_base) > 1.05:
				continue
			var ju: float = _rng.randf_range(-0.20, 0.20) / float(_FOAM_CELL_COLS)
			var jw: float = _rng.randf_range(-0.16, 0.16) / float(_FOAM_CELL_ROWS) * 2.0
			var u: float = clampf(u_base + ju, 0.03, 0.97)
			var w: float = clampf(w_base + jw, -0.96, 0.96)
			var end_fade: float = 0.88 + 0.12 * sin(clampf(u, 0.0, 1.0) * PI)
			var size_jit: float = _rng.randf_range(0.85, 1.22)
			var a: float = (_FOAM_SPAN_LENGTH / float(_FOAM_CELL_COLS)) * 0.5 * _FOAM_CELL_OVERLAP * size_jit * end_fade
			var b: float = (half_w_world / float(_FOAM_CELL_ROWS)) * (_FOAM_CELL_OVERLAP * 0.82) * _rng.randf_range(0.82, 1.18) * end_fade
			var cell := _FoamCell.new()
			cell.u = u
			cell.w = w
			cell.a = a
			cell.b = b
			cell.angle = _rng.randf_range(-0.6, 0.6)
			cell.tint = _foam_pick_tint()
			cells.append(cell)

			if _rng.randf() < _FOAM_SUBCELL_CHANCE:
				var sub := _FoamCell.new()
				sub.u = clampf(u + _rng.randf_range(-0.5, 0.5) / float(_FOAM_CELL_COLS), 0.05, 0.95)
				sub.w = clampf(w + _rng.randf_range(-0.6, 0.6) / float(_FOAM_CELL_ROWS), -0.9, 0.9)
				sub.a = a * _rng.randf_range(0.34, 0.52)
				sub.b = b * _rng.randf_range(0.34, 0.52)
				sub.angle = _rng.randf_range(-0.9, 0.9)
				sub.tint = _foam_pick_tint()
				cells.append(sub)
	return cells


## Pick a sparse jewel tint for a cell: mostly none, rarely tint_a / tint_b. (Ported v2.)
func _foam_pick_tint() -> int:
	if _rng.randf() < _FOAM_TINT_CHANCE:
		return 1 if _rng.randf() < 0.5 else 2
	return 0


## Emit one elliptical cell WALL for `cell` into `st`: a thin VERTICAL membrane following the
## ellipse — a closed ribbon of inner+outer faces extruded ±half deck-thickness, capped top
## and bottom, oriented in the span's tangent plane via Basis (no look_at). (Ported v2.)
func _foam_emit_ellipse_ring(st: SurfaceTool, cell: _FoamCell, strut_r: float) -> void:
	var frame: Basis = _foam_span_frame(cell.u)
	var centre: Vector3 = _foam_span_point(cell.u)
	var side_axis: Vector3 = frame.z
	var up_axis: Vector3 = frame.y
	var fwd_axis: Vector3 = frame.x
	centre += side_axis * (cell.w * _FOAM_SPAN_WIDTH * 0.5)

	var ca: float = cos(cell.angle)
	var sa: float = sin(cell.angle)
	var half_h: float = _FOAM_DECK_THICK * 0.5
	var wall_t: float = strut_r
	var n: int = _FOAM_RING_SEGMENTS

	var pts: Array[Vector3] = []
	var nrms: Array[Vector3] = []
	for si: int in range(n):
		var t: float = TAU * float(si) / float(n)
		var ex: float = cos(t) * cell.a
		var ez: float = sin(t) * cell.b
		var rx: float = ex * ca - ez * sa
		var rz: float = ex * sa + ez * ca
		pts.append(centre + fwd_axis * rx + side_axis * rz)
		var lnx: float = cos(t) / maxf(cell.a, 0.0001)
		var lnz: float = sin(t) / maxf(cell.b, 0.0001)
		var rnx: float = lnx * ca - lnz * sa
		var rnz: float = lnx * sa + lnz * ca
		nrms.append((fwd_axis * rnx + side_axis * rnz).normalized())

	for si: int in range(n):
		var sj: int = (si + 1) % n
		var p0: Vector3 = pts[si]
		var p1: Vector3 = pts[sj]
		var n0: Vector3 = nrms[si]
		var n1: Vector3 = nrms[sj]
		var o0_t: Vector3 = p0 + n0 * wall_t + up_axis * half_h
		var o0_b: Vector3 = p0 + n0 * wall_t - up_axis * half_h
		var o1_t: Vector3 = p1 + n1 * wall_t + up_axis * half_h
		var o1_b: Vector3 = p1 + n1 * wall_t - up_axis * half_h
		var i0_t: Vector3 = p0 - n0 * wall_t + up_axis * half_h
		var i0_b: Vector3 = p0 - n0 * wall_t - up_axis * half_h
		var i1_t: Vector3 = p1 - n1 * wall_t + up_axis * half_h
		var i1_b: Vector3 = p1 - n1 * wall_t - up_axis * half_h
		_foam_quad(st, o0_b, o0_t, o1_t, o1_b, n0)
		_foam_quad(st, i1_b, i1_t, i0_t, i0_b, -n0)
		_foam_quad(st, i0_t, o0_t, o1_t, i1_t, up_axis)
		_foam_quad(st, o0_b, i0_b, i1_b, o1_b, -up_axis)


## Two long edge rails (one per long side) as swept tubes along the arch. (Ported v2.)
func _foam_emit_edge_rails(st: SurfaceTool) -> void:
	var rail_r: float = _FOAM_STRUT_RADIUS * 1.05
	var sides: Array[float] = [0.985, -0.985]
	var samples: int = 44
	for w_frac: float in sides:
		var path: Array[Vector3] = []
		for i: int in range(samples + 1):
			var u: float = float(i) / float(samples)
			var frame: Basis = _foam_span_frame(u)
			var p: Vector3 = _foam_span_point(u)
			p += frame.z * (w_frac * _FOAM_SPAN_WIDTH * 0.5)
			path.append(p)
		_foam_emit_open_tube(st, path, rail_r)


## Emit an OPEN (non-looped) tube of radius `r` along centreline `path`, parallel-transported
## frames. (Ported from v2's `_emit_open_tube`.)
func _foam_emit_open_tube(st: SurfaceTool, path: Array[Vector3], r: float) -> void:
	var n: int = path.size()
	if n < 2:
		return
	var rings: Array = []
	var prev_normal: Vector3 = Vector3.ZERO
	for i: int in range(n):
		var p: Vector3 = path[i]
		var tangent: Vector3
		if i == 0:
			tangent = (path[1] - path[0]).normalized()
		elif i == n - 1:
			tangent = (path[n - 1] - path[n - 2]).normalized()
		else:
			tangent = (path[i + 1] - path[i - 1]).normalized()
		if tangent.length_squared() < 0.0001:
			tangent = Vector3.RIGHT
		var nrm: Vector3
		if prev_normal == Vector3.ZERO:
			var ref: Vector3 = Vector3.UP
			if absf(tangent.dot(ref)) > 0.95:
				ref = Vector3.RIGHT
			nrm = tangent.cross(ref).normalized()
		else:
			nrm = prev_normal - tangent * tangent.dot(prev_normal)
			if nrm.length_squared() < 0.0001:
				nrm = tangent.cross(Vector3.UP)
			nrm = nrm.normalized()
		var binrm: Vector3 = tangent.cross(nrm).normalized()
		prev_normal = nrm
		var ring: Array[Vector3] = []
		for si: int in range(_FOAM_RING_SIDES):
			var ang: float = TAU * float(si) / float(_FOAM_RING_SIDES)
			ring.append(p + (nrm * cos(ang) + binrm * sin(ang)) * r)
		rings.append(ring)

	for i: int in range(n - 1):
		var ra: Array = rings[i] as Array
		var rb: Array = rings[i + 1] as Array
		for si: int in range(_FOAM_RING_SIDES):
			var sj: int = (si + 1) % _FOAM_RING_SIDES
			var v00: Vector3 = ra[si] as Vector3
			var v01: Vector3 = ra[sj] as Vector3
			var v10: Vector3 = rb[si] as Vector3
			var v11: Vector3 = rb[sj] as Vector3
			st.add_vertex(v00); st.add_vertex(v10); st.add_vertex(v01)
			st.add_vertex(v01); st.add_vertex(v10); st.add_vertex(v11)


## A chunky stone anchor ledge at span end `u_end` (0.0 = left, 1.0 = right): a few stacked,
## slightly tilted masonry boxes. A SEPARATE local block-RNG (seeded off the main seed) keeps
## the anchor jitter independent of cell-bake draw order. (Ported from v2's `_build_anchor`.)
func _foam_build_anchor(parent: Node3D, u_end: float) -> void:
	var frame: Basis = _foam_span_frame(u_end)
	var end_pt: Vector3 = _foam_span_point(u_end)
	var outward: Vector3 = frame.x * (1.0 if u_end > 0.5 else -1.0)
	var anchor_centre: Vector3 = end_pt + outward * 0.16
	anchor_centre.y -= 0.30

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng_block := RandomNumberGenerator.new()
	rng_block.seed = seed + int(u_end * 1000.0) + 7

	var block_n: int = 4
	for bi: int in range(block_n):
		var fy: float = float(bi) / float(block_n)
		var bw: float = lerpf(0.40, 0.30, fy) * rng_block.randf_range(0.9, 1.1)
		var bd: float = lerpf(_FOAM_SPAN_WIDTH * 0.9, _FOAM_SPAN_WIDTH * 0.7, fy) * rng_block.randf_range(0.9, 1.05)
		var bh: float = 0.16 * rng_block.randf_range(0.85, 1.15)
		var by: float = -0.02 + fy * 0.56
		var jitter_x: float = rng_block.randf_range(-0.04, 0.04)
		var jitter_z: float = rng_block.randf_range(-0.03, 0.03)
		var bc: Vector3 = anchor_centre + Vector3(jitter_x, by, jitter_z) + outward * (fy * 0.06)
		var tilt: float = rng_block.randf_range(-0.08, 0.08)
		var ax: Vector3 = Vector3(cos(tilt), sin(tilt) * 0.4, 0.0).normalized()
		var ay: Vector3 = Vector3(-sin(tilt) * 0.4, cos(tilt), 0.0).normalized()
		var az: Vector3 = Vector3(0.0, 0.0, 1.0)
		_foam_emit_box(st, bc, ax, ay, az, bw * 0.5, bh * 0.5, bd * 0.5)

	st.generate_normals()
	_cx_add_mesh(parent, st.commit(), _foam_mat_anchor, Transform3D.IDENTITY,
		"Anchor_%s" % ("R" if u_end > 0.5 else "L"))


## A thin pendant thread + a glowing teardrop hanging from the mid-span underside. (v2.)
func _foam_build_pendant(parent: Node3D) -> void:
	var u_hang: float = 0.46
	var frame: Basis = _foam_span_frame(u_hang)
	var anchor_pt: Vector3 = _foam_span_point(u_hang)
	anchor_pt += frame.z * (-0.10 * _FOAM_SPAN_WIDTH)
	anchor_pt -= frame.y * (_FOAM_DECK_THICK * 0.5)

	var drop_len: float = 0.46
	var drop_bottom: Vector3 = anchor_pt + Vector3(0.0, -drop_len, 0.0)

	var thread_st := SurfaceTool.new()
	thread_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_foam_emit_open_tube(thread_st, [anchor_pt, drop_bottom], 0.006)
	thread_st.generate_normals()
	_cx_add_mesh(parent, thread_st.commit(), _foam_mat_thread, Transform3D.IDENTITY, "PendantThread")

	var dr: float = 0.072
	var teardrop_profile: Array[Vector2] = [
		Vector2(0.0, dr * 1.30),
		Vector2(dr * 0.28, dr * 0.95),
		Vector2(dr * 0.62, dr * 0.50),
		Vector2(dr * 0.92, dr * 0.02),
		Vector2(dr * 0.96, -dr * 0.46),
		Vector2(dr * 0.60, -dr * 0.92),
		Vector2(0.0, -dr * 1.06)]
	var drop_mesh: Mesh = MorphoPrimitive.revolution(teardrop_profile, 16)
	_cx_add_mesh(parent, drop_mesh, _foam_mat_drop,
		Transform3D(Basis.IDENTITY, drop_bottom + Vector3(0.0, -dr * 1.30, 0.0)), "PendantDrop")


## Emit one box centred at `c` with half-extents (hx,hy,hz) along orthonormal axes. (v2.)
func _foam_emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
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
	_foam_quad(st, p000, p010, p110, p100, -az)
	_foam_quad(st, p001, p101, p111, p011, az)
	_foam_quad(st, p000, p100, p101, p001, -ay)
	_foam_quad(st, p010, p011, p111, p110, ay)
	_foam_quad(st, p000, p001, p011, p010, -ax)
	_foam_quad(st, p100, p110, p111, p101, ax)


func _foam_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


# =============================================================================
# MODE: oculus — a brick ruin wall with a dentil-ringed eye (trial v3)
# =============================================================================

const _OCUL_WALL_W: float = 2.30         # wall width (X)
const _OCUL_WALL_H: float = 2.35         # wall height (Y)
const _OCUL_WALL_T: float = 0.34         # wall thickness (Z)
const _OCUL_COURSE_COUNT: int = 22       # horizontal brick courses up the face
const _OCUL_OUTER: float = 0.62          # oculus ring outer radius
const _OCUL_INNER: float = 0.46          # oculus ring inner radius (the hole)
const _OCUL_CY: float = 1.62             # oculus centre height
const _OCUL_DENTIL_COUNT: int = 30       # blocks studding the inner rim
const _OCUL_ARCH_COUNT: int = 5          # pointed arches in the base arcade
const _OCUL_ARCH_TOP: float = 0.96       # arcade springing + rise
const _OCUL_COLUMN_H: float = 2.20       # toothed column height
const _OCUL_COLUMN_R: float = 0.155      # toothed column radius
const _OCUL_COLUMN_TOOTH_ROWS: int = 7   # rows of teeth up the column
const _OCUL_POOL_R: float = 1.05         # blood-pool nominal radius

# Materials baked once per oculus build, derived from the colour triad + constants.
var _ocul_mat_brick: StandardMaterial3D
var _ocul_mat_course: StandardMaterial3D
var _ocul_mat_stone: StandardMaterial3D
var _ocul_mat_col_dark: StandardMaterial3D
var _ocul_mat_col_stripe: StandardMaterial3D
var _ocul_mat_tooth: StandardMaterial3D
var _ocul_mat_pool: StandardMaterial3D
var _ocul_mat_moss: StandardMaterial3D
var _ocul_mat_sky: StandardMaterial3D
var _ocul_mat_land: StandardMaterial3D


## oculus DNA mapping: color_a = BRICK, color_b = pale STONE (oculus ring / dentils / arch
## frames / toothed-column pale stripe), accent = the BLOOD-RED POOL + its faint glow (accent
## recolours the pool so the DNA can tint it); green moss + dark column derived from constants.
func _build_oculus_wall() -> void:
	# BRICK — color_a, rough, faint emission floor.
	_ocul_mat_brick = _cx_stone_mat(color_a)
	_ocul_mat_brick.roughness = clampf(rough_amt * 1.06, 0.02, 1.0)
	# COURSE — a darker mortar derive of brick.
	_ocul_mat_course = _cx_stone_mat(Color(color_a.r * 0.84, color_a.g * 0.78, color_a.b * 0.76))
	_ocul_mat_course.emission_energy_multiplier = _cx_glow_energy(0.08)
	# STONE — pale limestone, color_b.
	_ocul_mat_stone = _cx_trim_mat(color_b)
	# COLUMN DARK — a dark, slightly cool body (derive from color_a toward near-black).
	var col_dark: Color = Color(0.24, 0.22, 0.26).lerp(Color(color_a.r, color_a.g, color_a.b, 1.0), 0.12)
	_ocul_mat_col_dark = _cx_stone_mat(col_dark)
	_ocul_mat_col_dark.emission = col_dark * 0.5
	_ocul_mat_col_dark.emission_energy_multiplier = _cx_glow_energy(0.12)
	# COLUMN STRIPE — pale bands, from color_b.
	_ocul_mat_col_stripe = _cx_trim_mat(color_b.lerp(Color(0.78, 0.74, 0.70), 0.5))
	# TOOTH — white wedge teeth (lighten color_b toward white), faint glow.
	_ocul_mat_tooth = _cx_trim_mat(color_b.lerp(Color(0.95, 0.93, 0.88), 0.7))
	_ocul_mat_tooth.emission_energy_multiplier = _cx_glow_energy(0.14)
	# POOL — accent recolours the blood-red liquid (a touch glossy, sinister glow).
	_ocul_mat_pool = StandardMaterial3D.new()
	_ocul_mat_pool.albedo_color = accent
	_ocul_mat_pool.roughness = 0.5
	_ocul_mat_pool.metallic = 0.1
	_ocul_mat_pool.emission_enabled = true
	_ocul_mat_pool.emission = accent
	_ocul_mat_pool.emission_energy_multiplier = _cx_glow_energy(0.5)
	# MOSS — a green bank derive (constant green nudged by color_b).
	var moss_c: Color = Color(0.40, 0.52, 0.34).lerp(Color(color_b.r, color_b.g, color_b.b, 1.0), 0.12)
	_ocul_mat_moss = _cx_stone_mat(moss_c)
	_ocul_mat_moss.emission_energy_multiplier = _cx_glow_energy(0.12)
	# SKY GLOW behind the eye — soft cool accent-neutral (derive from color_b toward sky).
	_ocul_mat_sky = _cx_glow_mat(color_b.lerp(Color(0.60, 0.78, 0.86), 0.7), 0.9, true, 1.0)
	# LANDSCAPE behind the arches — soft green (the moss-green family, brighter).
	_ocul_mat_land = _cx_glow_mat(moss_c.lerp(Color(0.42, 0.56, 0.36), 0.6), 0.7, true, 1.0)

	var root := Node3D.new()
	root.name = "OculusRuin"
	add_child(root)

	# Distant backplanes first (seen through the oculus + arch bays).
	_ocul_build_backdrops(root)
	_ocul_build_wall(root)
	_ocul_build_oculus(root)
	_ocul_build_arcade(root)
	_ocul_build_toothed_column(root)
	_ocul_build_pool(root)

	# Yaw to three-quarter, then centre + floor + scale.
	root.rotate_y(deg_to_rad(-16.0))
	_cx_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## The wall as two side piers + a sill + a lintel framing a genuine OPENING the oculus nests
## in, capped by a pale capstone, then clad in horizontal coursing. (Ported from v3.)
func _ocul_build_wall(parent: Node3D) -> void:
	var wall := Node3D.new()
	wall.name = "Wall"
	parent.add_child(wall)

	var half_w: float = _OCUL_WALL_W * 0.5
	var open_half: float = _OCUL_OUTER + 0.05
	var open_lo: float = _OCUL_CY - open_half
	var open_hi: float = _OCUL_CY + open_half
	var pier_w: float = (_OCUL_WALL_W - open_half * 2.0) * 0.5

	for side: int in [-1, 1]:
		var sgn: float = float(side)
		var pier_cx: float = sgn * (half_w - pier_w * 0.5)
		_cx_add_mesh(wall, MorphoPrimitive.box(Vector3(pier_w, _OCUL_WALL_H, _OCUL_WALL_T)),
			_ocul_mat_brick, Transform3D(Basis.IDENTITY, Vector3(pier_cx, _OCUL_WALL_H * 0.5, 0.0)),
			"Pier_%d" % side)

	var sill_h: float = open_lo
	var mid_w: float = open_half * 2.0
	if sill_h > 0.01:
		_cx_add_mesh(wall, MorphoPrimitive.box(Vector3(mid_w, sill_h, _OCUL_WALL_T)),
			_ocul_mat_brick, Transform3D(Basis.IDENTITY, Vector3(0.0, sill_h * 0.5, 0.0)), "Sill")

	var lintel_h: float = _OCUL_WALL_H - open_hi
	if lintel_h > 0.01:
		_cx_add_mesh(wall, MorphoPrimitive.box(Vector3(mid_w, lintel_h, _OCUL_WALL_T)),
			_ocul_mat_brick,
			Transform3D(Basis.IDENTITY, Vector3(0.0, open_hi + lintel_h * 0.5, 0.0)), "Lintel")

	_cx_add_mesh(wall, MorphoPrimitive.box(Vector3(_OCUL_WALL_W + 0.06, 0.10, _OCUL_WALL_T + 0.06)),
		_ocul_mat_stone, Transform3D(Basis.IDENTITY, Vector3(0.0, _OCUL_WALL_H + 0.03, 0.0)), "Capstone")

	_ocul_build_coursing(wall, open_lo, open_hi, open_half)


## Stack thin proud darker COURSE ridges across the front face; courses crossing the oculus
## opening split into two side-pier segments. Batched into MultiMeshInstances. (Ported v3.)
func _ocul_build_coursing(parent: Node3D, open_lo: float, open_hi: float, open_half: float) -> void:
	var courses := Node3D.new()
	courses.name = "Coursing"
	parent.add_child(courses)

	var half_w: float = _OCUL_WALL_W * 0.5
	var ridge_t: float = 0.022
	var ridge_h: float = (_OCUL_WALL_H / float(_OCUL_COURSE_COUNT)) * 0.30
	var face_z: float = _OCUL_WALL_T * 0.5 + ridge_t * 0.5 - 0.002
	var pier_w: float = (_OCUL_WALL_W - open_half * 2.0) * 0.5

	var full_xforms: Array[Transform3D] = []
	var seg_xforms: Array[Transform3D] = []
	for i: int in range(1, _OCUL_COURSE_COUNT):
		var y: float = (_OCUL_WALL_H / float(_OCUL_COURSE_COUNT)) * float(i)
		var jh: float = ridge_h * _rng.randf_range(0.85, 1.15)
		var inside_opening: bool = y > open_lo - jh and y < open_hi + jh
		if not inside_opening:
			var basis_full := Basis().scaled(Vector3(_OCUL_WALL_W - 0.02, jh, ridge_t))
			full_xforms.append(Transform3D(basis_full, Vector3(0.0, y, face_z)))
		else:
			for side: int in [-1, 1]:
				var sgn: float = float(side)
				var seg_cx: float = sgn * (half_w - pier_w * 0.5)
				var basis_seg := Basis().scaled(Vector3(pier_w - 0.02, jh, ridge_t))
				seg_xforms.append(Transform3D(basis_seg, Vector3(seg_cx, y, face_z)))

	var unit_box: Mesh = MorphoPrimitive.box(Vector3.ONE)
	_ocul_flush_multimesh(courses, unit_box, full_xforms, _ocul_mat_course, "CourseRidges_full")
	_ocul_flush_multimesh(courses, unit_box, seg_xforms, _ocul_mat_course, "CourseRidges_seg")


## The great eye: a sky-glow disc behind, a torus ring (rotated so the hole faces +Z), and a
## cogged ring of small dentil blocks studding the inner rim. (Ported from v3's `_build_oculus`.)
func _ocul_build_oculus(parent: Node3D) -> void:
	var oculus := Node3D.new()
	oculus.name = "Oculus"
	parent.add_child(oculus)

	var centre := Vector3(0.0, _OCUL_CY, 0.0)
	var ring_minor: float = (_OCUL_OUTER - _OCUL_INNER) * 0.5

	var sky_disc: Mesh = _ocul_disc_mesh(_OCUL_INNER * 1.04, 28)
	_cx_add_mesh(oculus, sky_disc, _ocul_mat_sky,
		Transform3D(Basis.IDENTITY, centre + Vector3(0.0, 0.0, -_OCUL_WALL_T * 0.5 - 0.04)), "SkyGlow")

	var ring: Mesh = MorphoPrimitive.torus(_OCUL_INNER, _OCUL_OUTER, 14, 48)
	var ring_basis := Basis(Vector3.RIGHT, deg_to_rad(90.0))
	_cx_add_mesh(oculus, ring, _ocul_mat_stone, Transform3D(ring_basis, centre), "OculusRing")

	var dentil_xforms: Array[Transform3D] = []
	var d_w: float = 0.046
	var d_h: float = 0.075
	var tooth_z: float = ring_minor * 0.55
	for i: int in range(_OCUL_DENTIL_COUNT):
		var ang: float = TAU * float(i) / float(_OCUL_DENTIL_COUNT)
		var radial := Vector3(cos(ang), sin(ang), 0.0)
		var tangent := Vector3(-sin(ang), cos(ang), 0.0)
		var jit: float = _rng.randf_range(0.82, 1.12)
		var d_len: float = ring_minor * 0.95 * jit
		var bx: Vector3 = tangent
		var by: Vector3 = -radial
		var bz: Vector3 = bx.cross(by).normalized()
		var basis := Basis(bx, by, bz).scaled(Vector3(d_w, d_len, d_h))
		var rim_r: float = _OCUL_INNER + 0.005
		var pos: Vector3 = centre + radial * (rim_r - d_len * 0.5) + Vector3(0.0, 0.0, tooth_z)
		dentil_xforms.append(Transform3D(basis, pos))

	var unit_box: Mesh = MorphoPrimitive.box(Vector3.ONE)
	_ocul_flush_multimesh(oculus, unit_box, dentil_xforms, _ocul_mat_stone, "Dentils")


## A row of pointed (lancet) arches across the base, each a swept rib frame on a pier with an
## apex finial, leaving openings onto the green landscape backplane. All seed-jittered geometry
## baked into locals before the path Callable closes. (Ported from v3's `_build_arcade`.)
func _ocul_build_arcade(parent: Node3D) -> void:
	var arcade := Node3D.new()
	arcade.name = "Arcade"
	parent.add_child(arcade)

	var span: float = _OCUL_WALL_W - 0.10
	var bay_w: float = span / float(_OCUL_ARCH_COUNT)
	var x0: float = -span * 0.5
	var arch_z: float = _OCUL_WALL_T * 0.5 + 0.11
	var spring_h: float = _OCUL_ARCH_TOP * 0.34
	var half_bay: float = bay_w * 0.5 - 0.062
	var rib_w: float = 0.05
	var rib_d: float = 0.082

	for b: int in range(_OCUL_ARCH_COUNT):
		var cx: float = x0 + bay_w * (float(b) + 0.5)
		var lancet: float = 1.5 + _rng.randf_range(0.0, 0.35)
		var hw: float = half_bay
		var sh: float = spring_h
		var base := Vector3(cx, 0.0, arch_z)
		var d_off: float = lancet * hw
		var arc_r: float = d_off + hw
		var apex_y: float = sh + sqrt(maxf(arc_r * arc_r - d_off * d_off, 0.0001))
		var apex_ang: float = atan2(apex_y - sh, -d_off)
		var f_jamb: float = 0.20
		var f_arc: float = 0.5 - f_jamb
		var path := func(t: float) -> Vector3:
			var x: float
			var y: float
			if t < f_jamb:
				var lt: float = t / f_jamb
				x = -hw
				y = lt * sh
			elif t < 0.5:
				var u: float = (t - f_jamb) / f_arc
				var ang: float = lerpf(PI, apex_ang, u)
				x = d_off + arc_r * cos(ang)
				y = sh + arc_r * sin(ang)
			elif t < 1.0 - f_jamb:
				var u: float = (t - 0.5) / f_arc
				var ang: float = lerpf(PI - apex_ang, 0.0, u)
				x = -d_off + arc_r * cos(ang)
				y = sh + arc_r * sin(ang)
			else:
				var rt: float = (t - (1.0 - f_jamb)) / f_jamb
				x = hw
				y = (1.0 - rt) * sh
			return base + Vector3(x, y, 0.0)

		var profile: Array[Vector2] = MorphoSweep.profile_rectangle(rib_d, rib_w)
		var radius_func := func(_t: float) -> float: return 1.0
		var rib_mesh: Mesh = MorphoSweep.sweep(profile, path, radius_func, 0.0, 56, false)
		_cx_add_mesh(arcade, rib_mesh, _ocul_mat_stone, Transform3D.IDENTITY, "ArchRib_%d" % b)

		var apex_pos: Vector3 = base + Vector3(0.0, apex_y, 0.0)
		var fin_basis := Basis(Vector3.RIGHT, Vector3.UP, Vector3.FORWARD).scaled(
			Vector3(rib_d * 1.05, 0.16, rib_d * 1.05))
		_cx_add_mesh(arcade, MorphoPrimitive.cone(1.0, 1.0, 6), _ocul_mat_stone,
			Transform3D(fin_basis, apex_pos - Vector3(0.0, 0.03, 0.0)), "ArchFinial_%d" % b)

		var pier_h: float = spring_h
		var pier: Mesh = MorphoPrimitive.box(Vector3(0.085, pier_h, rib_d * 1.3))
		_cx_add_mesh(arcade, pier, _ocul_mat_brick,
			Transform3D(Basis.IDENTITY, Vector3(cx - hw - 0.045, pier_h * 0.5, arch_z)), "ArchPier_%d" % b)
		if b == _OCUL_ARCH_COUNT - 1:
			_cx_add_mesh(arcade, pier, _ocul_mat_brick,
				Transform3D(Basis.IDENTITY, Vector3(cx + hw + 0.045, pier_h * 0.5, arch_z)), "ArchPier_end")


## A dark striped column to the +X side of the wall: a banded revolution drum stack, a rounded
## cap, and rows of white wedge teeth (cones) jutting sideways. Teeth batched into a
## MultiMeshInstance. (Ported from v3's `_build_toothed_column`.)
func _ocul_build_toothed_column(parent: Node3D) -> void:
	var column := Node3D.new()
	column.name = "ToothedColumn"
	parent.add_child(column)

	var col_x: float = _OCUL_WALL_W * 0.5 + 0.42
	var col_base := Vector3(col_x, 0.0, _OCUL_WALL_T * 0.5 + 0.06)

	var drums: int = 14
	var drum_h: float = _OCUL_COLUMN_H / float(drums)
	for d: int in range(drums):
		var y0: float = drum_h * float(d)
		var t: float = float(d) / float(drums - 1)
		var swell: float = 1.0 + sin(t * PI) * 0.10
		var r: float = _OCUL_COLUMN_R * swell
		var profile: Array[Vector2] = [
			Vector2(r, 0.0),
			Vector2(r * 1.02, drum_h * 0.5),
			Vector2(r, drum_h)]
		var mat: StandardMaterial3D = _ocul_mat_col_dark if d % 2 == 0 else _ocul_mat_col_stripe
		_cx_add_mesh(column, MorphoPrimitive.revolution(profile, 16), mat,
			Transform3D(Basis.IDENTITY, col_base + Vector3(0.0, y0, 0.0)), "Drum_%d" % d)

	_cx_add_mesh(column, MorphoPrimitive.sphere(_OCUL_COLUMN_R * 1.05, 12, 7), _ocul_mat_col_dark,
		Transform3D(Basis.IDENTITY, col_base + Vector3(0.0, _OCUL_COLUMN_H, 0.0)), "ColumnCap")

	var tooth_xforms: Array[Transform3D] = []
	var per_row: int = 2
	for row: int in range(_OCUL_COLUMN_TOOTH_ROWS):
		var ty: float = lerpf(_OCUL_COLUMN_H * 0.12, _OCUL_COLUMN_H * 0.92, float(row) / float(_OCUL_COLUMN_TOOTH_ROWS - 1))
		var swell: float = 1.0 + sin((ty / _OCUL_COLUMN_H) * PI) * 0.10
		var r_here: float = _OCUL_COLUMN_R * swell
		var row_roll: float = float(row) * 0.7 + _rng.randf_range(-0.15, 0.15)
		for k: int in range(per_row):
			var ang: float = row_roll + PI * float(k) + _rng.randf_range(-0.25, 0.25)
			var radial := Vector3(cos(ang), 0.0, sin(ang))
			var tlen: float = _rng.randf_range(0.16, 0.24)
			var trad: float = _rng.randf_range(0.045, 0.065)
			var by: Vector3 = radial
			var bx: Vector3 = Vector3.UP.cross(by)
			if bx.length_squared() < 0.0001:
				bx = Vector3.RIGHT
			bx = bx.normalized()
			var bz: Vector3 = bx.cross(by).normalized()
			var basis := Basis(bx, by, bz)
			var pos: Vector3 = col_base + Vector3(0.0, ty, 0.0) + radial * (r_here * 0.85)
			var sbasis := basis.scaled(Vector3(trad, tlen, trad))
			tooth_xforms.append(Transform3D(sbasis, pos))

	var unit_cone: Mesh = MorphoPrimitive.cone(1.0, 1.0, 8)
	_ocul_flush_multimesh(column, unit_cone, tooth_xforms, _ocul_mat_tooth, "ColumnTeeth")


## A low irregular flat blood-red pool with dark stepping-stone islands + green moss patches.
## (Ported from v3's `_build_pool`.)
func _ocul_build_pool(parent: Node3D) -> void:
	var pool := Node3D.new()
	pool.name = "RedPool"
	parent.add_child(pool)

	var pool_centre := Vector3(0.06, 0.012, _OCUL_WALL_T * 0.5 + 0.72)
	_cx_add_mesh(pool, _ocul_blob_disc_mesh(_OCUL_POOL_R, 40, 0.22), _ocul_mat_pool,
		Transform3D(Basis.IDENTITY, pool_centre), "PoolSurface")

	var stone_count: int = 5
	for s: int in range(stone_count):
		var ang: float = TAU * float(s) / float(stone_count) + _rng.randf_range(-0.4, 0.4)
		var rr: float = _OCUL_POOL_R * _rng.randf_range(0.25, 0.72)
		var sx: float = pool_centre.x + cos(ang) * rr
		var sz: float = pool_centre.z + sin(ang) * rr * 0.78
		var sr: float = _rng.randf_range(0.10, 0.17)
		var sh: float = _rng.randf_range(0.05, 0.09)
		var sprofile: Array[Vector2] = [
			Vector2(sr, 0.0),
			Vector2(sr * 0.96, sh * 0.7),
			Vector2(sr * 0.6, sh)]
		_cx_add_mesh(pool, MorphoPrimitive.revolution(sprofile, 10), _ocul_mat_col_dark,
			Transform3D(Basis.IDENTITY, Vector3(sx, 0.012, sz)), "Stone_%d" % s)

	var moss_count: int = 6
	for m: int in range(moss_count):
		var ang: float = TAU * float(m) / float(moss_count) + _rng.randf_range(-0.3, 0.3)
		var rr: float = _OCUL_POOL_R * _rng.randf_range(0.92, 1.18)
		var mx: float = pool_centre.x + cos(ang) * rr
		var mz: float = pool_centre.z + sin(ang) * rr * 0.82
		var mrad: float = _rng.randf_range(0.12, 0.22)
		var basis := Basis().scaled(Vector3(mrad, mrad * 0.4, mrad))
		_cx_add_mesh(pool, MorphoPrimitive.sphere(1.0, 8, 5), _ocul_mat_moss,
			Transform3D(basis, Vector3(mx, 0.01, mz)), "Moss_%d" % m)


## A soft luminous sky plane + a green hill band behind the wall (seen through the eye + bays),
## both kept just behind and only modestly wider than the wall. (Ported from v3.)
func _ocul_build_backdrops(parent: Node3D) -> void:
	var back := Node3D.new()
	back.name = "Backdrop"
	parent.add_child(back)

	var back_z: float = -_OCUL_WALL_T * 0.5 - 0.40
	var sky_w: float = _OCUL_WALL_W * 1.55
	_cx_add_mesh(back, MorphoPrimitive.quad(Vector2(sky_w, _OCUL_WALL_H * 1.45)), _ocul_mat_sky,
		Transform3D(Basis.IDENTITY, Vector3(0.0, _OCUL_WALL_H * 0.60, back_z)), "Sky")

	var hill_top: float = _OCUL_CY - _OCUL_OUTER * 0.35
	var hill_h: float = hill_top + 1.0
	var hill_w: float = sky_w * 0.96
	_cx_add_mesh(back, MorphoPrimitive.quad(Vector2(hill_w, hill_h)), _ocul_mat_land,
		Transform3D(Basis.IDENTITY, Vector3(0.0, hill_top - hill_h * 0.5, back_z + 0.04)), "Hills")


## A flat filled disc in the XY plane (faces +Z), fan-triangulated. (Ported from v3.)
func _ocul_disc_mesh(r: float, segments: int) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3.FORWARD * -1.0
	for i: int in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var p0 := Vector3(cos(a0) * r, sin(a0) * r, 0.0)
		var p1 := Vector3(cos(a1) * r, sin(a1) * r, 0.0)
		st.set_normal(n); st.add_vertex(Vector3.ZERO)
		st.set_normal(n); st.add_vertex(p0)
		st.set_normal(n); st.add_vertex(p1)
	return st.commit()


## A flat irregular blob disc in the XZ plane (faces +Y), seeded wobbly outline. (Ported v3.)
func _ocul_blob_disc_mesh(r: float, segments: int, wobble: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3.UP
	var radii: Array[float] = []
	for i: int in range(segments):
		var lobe: float = sin(float(i) * 0.7) * 0.5 + 0.5
		radii.append(r * (1.0 - wobble * 0.5 + wobble * lobe * _rng.randf_range(0.6, 1.0)))
	for i: int in range(segments):
		var i1: int = (i + 1) % segments
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i1) / float(segments)
		var p0 := Vector3(cos(a0) * radii[i], 0.0, sin(a0) * radii[i])
		var p1 := Vector3(cos(a1) * radii[i1], 0.0, sin(a1) * radii[i1])
		st.set_normal(n); st.add_vertex(Vector3.ZERO)
		st.set_normal(n); st.add_vertex(p0)
		st.set_normal(n); st.add_vertex(p1)
	return st.commit()


## Commit a bucket of transforms into one MultiMeshInstance3D from a template. (Ported v3.)
func _ocul_flush_multimesh(parent: Node3D, template: Mesh, xforms: Array[Transform3D],
		mat: Material, node_name: String) -> void:
	if xforms.is_empty():
		return
	var generic: Array = []
	for xf: Transform3D in xforms:
		generic.append(xf)
	var mmi: MultiMeshInstance3D = MorphoPrimitive.multimesh_scatter(template, generic)
	mmi.name = node_name
	mmi.material_override = mat
	parent.add_child(mmi)


# =============================================================================
# MODE: rainbowspan — an arc bridge to a glittering terraced hill-town (trial v4)
# =============================================================================
#
# CRITICAL: unlike the v4 trial, this builder NEVER touches the global capture
# environment or any sibling node. The trial walked to the scene root and darkened
# the shared WorldEnvironment + suns to fake night — an artifact MUST NOT do that
# (it would darken any map it is placed in). Here the town reads as glittering under
# the NORMAL capture lighting via bright UNSHADED emissive windows + darker building
# albedos. Everything is built strictly under this artifact's own root node.

const _SPAN_BRIDGE_START := Vector3(-1.45, 0.06, 0.60)   # near wooded bank (west)
const _SPAN_BRIDGE_END := Vector3(0.92, 0.46, -0.20)     # lands on the town's near slope
const _SPAN_ARC_HEIGHT: float = 2.25     # crown rise above the chord
const _SPAN_ARC_SWAY: float = 0.58       # lateral bow (anamorphic, in plan)
const _SPAN_DECK_HALF_W: float = 0.115   # half-width of the road deck
const _SPAN_DECK_HALF_H: float = 0.028   # half-thickness of the deck slab
const _SPAN_BRIDGE_SEGMENTS: int = 88    # rings along the arc sweep
const _SPAN_TOWN_CENTER := Vector3(1.42, 0.0, -0.50)
const _SPAN_HILL_RADIUS: float = 0.92    # planar radius of the town footprint
const _SPAN_HILL_HEIGHT: float = 1.05    # crown height of the hill
const _SPAN_BUILDINGS_BASE: int = 52     # building count at native complexity
const _SPAN_RIVER_LEVEL: float = 0.015
const _SPAN_RIVER_HALF: float = 2.05     # modest so it does not blow up the AABB

# Materials baked once per rainbowspan build, derived from the colour triad.
var _span_mat_stone: StandardMaterial3D   # BRIDGE stone — color_a
var _span_mat_wall: StandardMaterial3D    # building walls — color_b (darkened to read under day light)
var _span_mat_roof_a: StandardMaterial3D  # warm roof tint (derive from color_a)
var _span_mat_roof_b: StandardMaterial3D  # cool roof tint (derive from color_b)
var _span_mat_window: StandardMaterial3D  # WINDOW-LIGHT glow — accent, bright unshaded
var _span_mat_river: StandardMaterial3D   # dark water
var _span_mat_tree: StandardMaterial3D    # dark green canopy
var _span_mat_trunk: StandardMaterial3D   # dark trunk
var _span_mat_ground: StandardMaterial3D  # hill / bank earth
var _span_complexity_f: float = 1.0       # building/tree-count scale from complexity


## rainbowspan DNA mapping: color_a = BRIDGE stone, color_b = BUILDING walls, accent =
## WINDOW-LIGHT glow. complexity scales building + tree counts.
func _build_rainbowspan() -> void:
	# complexity 6 → ~1.0; scales counts within the trial's safe clamp.
	_span_complexity_f = clampf(0.5 + float(complexity) * 0.083, 0.4, 1.5)

	# BRIDGE STONE — color_a, warm, faintly self-lit.
	_span_mat_stone = _cx_stone_mat(color_a)
	_span_mat_stone.emission_energy_multiplier = _cx_glow_energy(0.18)
	# BUILDING WALLS — color_b darkened so the lit windows pop against them under day light.
	var wall_c: Color = Color(color_b.r * 0.46, color_b.g * 0.44, color_b.b * 0.52)
	_span_mat_wall = _cx_stone_mat(wall_c)
	_span_mat_wall.emission = wall_c * 0.5
	_span_mat_wall.emission_energy_multiplier = _cx_glow_energy(0.12)
	# ROOFS — a warm derive of color_a and a cool derive of color_b, both darkened.
	var roof_a_c: Color = Color(color_a.r * 0.54, color_a.g * 0.40, color_a.b * 0.40)
	_span_mat_roof_a = _cx_stone_mat(roof_a_c)
	_span_mat_roof_a.emission = roof_a_c * 0.5
	_span_mat_roof_a.emission_energy_multiplier = _cx_glow_energy(0.12)
	var roof_b_c: Color = Color(color_b.r * 0.38, color_b.g * 0.40, color_b.b * 0.50)
	_span_mat_roof_b = _cx_stone_mat(roof_b_c)
	_span_mat_roof_b.emission = roof_b_c * 0.5
	_span_mat_roof_b.emission_energy_multiplier = _cx_glow_energy(0.12)
	# WINDOW LIGHTS — the hero glow. Bright warm UNSHADED quads (energy lifted so the town
	# still glitters under the bright capture rig, since we no longer fake night).
	_span_mat_window = _cx_glow_mat(accent, 4.5, true, 1.0)
	# RIVER — a dark cool water, faint sheen (derive toward deep blue).
	var river_c: Color = Color(0.12, 0.16, 0.26).lerp(Color(color_b.r, color_b.g, color_b.b, 1.0), 0.12)
	_span_mat_river = StandardMaterial3D.new()
	_span_mat_river.albedo_color = river_c
	_span_mat_river.roughness = 0.3
	_span_mat_river.metallic = 0.2
	_span_mat_river.emission_enabled = true
	_span_mat_river.emission = river_c * 0.5
	_span_mat_river.emission_energy_multiplier = _cx_glow_energy(0.20)
	# TREES — dark green canopy + darker trunk (kept dim as night masses).
	_span_mat_tree = StandardMaterial3D.new()
	_span_mat_tree.albedo_color = Color(0.13, 0.22, 0.15)
	_span_mat_tree.roughness = 0.95
	_span_mat_tree.metallic = 0.0
	_span_mat_tree.emission_enabled = true
	_span_mat_tree.emission = Color(0.13, 0.22, 0.15) * 0.4
	_span_mat_tree.emission_energy_multiplier = _cx_glow_energy(0.05)
	_span_mat_trunk = StandardMaterial3D.new()
	_span_mat_trunk.albedo_color = Color(0.16, 0.13, 0.12)
	_span_mat_trunk.roughness = 0.95
	_span_mat_trunk.metallic = 0.0
	# GROUND — hill + banks, dark earthy dusk.
	_span_mat_ground = StandardMaterial3D.new()
	_span_mat_ground.albedo_color = Color(0.14, 0.15, 0.16)
	_span_mat_ground.roughness = 0.95
	_span_mat_ground.metallic = 0.0
	_span_mat_ground.emission_enabled = true
	_span_mat_ground.emission = Color(0.14, 0.15, 0.16) * 0.5
	_span_mat_ground.emission_energy_multiplier = _cx_glow_energy(0.08)

	var root := Node3D.new()
	root.name = "RainbowSpan"
	add_child(root)

	# Build the scene strictly under `root` — no global env, no sibling mutation.
	_span_build_river(root)
	_span_build_banks_and_hill(root)
	_span_build_bridge(root)
	_span_build_town(root)
	_span_build_trees(root)

	# Centre + floor + scale to the sculpt height.
	_cx_settle(root, maxf(sculpt_height, 0.4), maxf(sculpt_width, 0.2))


## A low dark river plane winding below the arc. (Ported from v4's `_build_river`.)
func _span_build_river(parent: Node3D) -> void:
	_cx_add_mesh(parent, MorphoPrimitive.plane(Vector2(_SPAN_RIVER_HALF * 2.0, _SPAN_RIVER_HALF * 2.0), 1, 1),
		_span_mat_river, Transform3D(Basis.IDENTITY, Vector3(0.0, _SPAN_RIVER_LEVEL, 0.10)), "River")


## Two earth domes: the near wooded bank and the steep town hill. (Ported from v4.)
func _span_build_banks_and_hill(parent: Node3D) -> void:
	_cx_add_mesh(parent, _span_dome_mesh(0.85, 0.34, 28), _span_mat_ground,
		Transform3D(Basis.IDENTITY, Vector3(-1.55, 0.0, 0.70)), "NearBank")
	_cx_add_mesh(parent, _span_dome_mesh(_SPAN_HILL_RADIUS, _SPAN_HILL_HEIGHT, 40), _span_mat_ground,
		Transform3D(Basis.IDENTITY, _SPAN_TOWN_CENTER), "TownHill")


## A smooth cosine cushion dome of planar `radius` + crown `height`, sitting on y=0, built as
## a revolution. (Ported from v4's `_dome_mesh`.)
func _span_dome_mesh(radius: float, height: float, segments: int) -> Mesh:
	var profile: Array[Vector2] = []
	profile.append(Vector2(0.0, -0.04))
	profile.append(Vector2(radius * 0.96, -0.02))
	profile.append(Vector2(radius, 0.0))
	var samples: int = 22
	for i: int in range(1, samples + 1):
		var rr: float = float(samples - i) / float(samples)
		var r: float = radius * rr
		var h: float = height * 0.5 * (cos(rr * PI) + 1.0)
		profile.append(Vector2(r, h))
	return MorphoPrimitive.revolution(profile, segments)


## Analytic height of the town hill at a world XZ point (matches `_span_dome_mesh`). (v4.)
func _span_hill_height(world_xz: Vector3) -> float:
	var local := Vector2(world_xz.x - _SPAN_TOWN_CENTER.x, world_xz.z - _SPAN_TOWN_CENTER.z)
	var rr: float = clampf(local.length() / _SPAN_HILL_RADIUS, 0.0, 1.0)
	return _SPAN_HILL_HEIGHT * 0.5 * (cos(rr * PI) + 1.0)


## The hero ARC BRIDGE: sweep a flat road profile along a tall anamorphic arc (asymmetric in
## plan), two parapet rails on the deck edges, a few viaduct piers near the bank-side spring.
## Every value the path Callable needs is baked into locals first. (Ported from v4's `_build_bridge`.)
func _span_build_bridge(parent: Node3D) -> void:
	var p_start := _SPAN_BRIDGE_START
	var p_end := _SPAN_BRIDGE_END
	var arc_h: float = _SPAN_ARC_HEIGHT
	var sway: float = _SPAN_ARC_SWAY
	var crown_bias: float = _rng.randf_range(0.42, 0.52)
	var sway_phase: float = _rng.randf_range(0.85, 1.15)

	var arc_path := func(t: float) -> Vector3:
		var base: Vector3 = p_start.lerp(p_end, t)
		var skew: float = pow(t, log(0.5) / log(crown_bias))
		var lift: float = sin(skew * PI) * arc_h
		var bow: float = sin(t * PI * sway_phase) * sway
		return base + Vector3(0.0, lift, 0.0) + Vector3(0.0, 0.0, -bow)

	var deck_profile: Array[Vector2] = MorphoSweep.profile_rectangle(_SPAN_DECK_HALF_W * 2.0, _SPAN_DECK_HALF_H * 2.0)
	var deck_mesh: Mesh = MorphoSweep.sweep(deck_profile, arc_path, MorphoSweep.radius_constant(1.0),
		0.0, _SPAN_BRIDGE_SEGMENTS, false)
	_cx_add_mesh(parent, deck_mesh, _span_mat_stone, Transform3D.IDENTITY, "BridgeDeck")

	for side: int in [-1, 1]:
		var edge_off: float = float(side) * (_SPAN_DECK_HALF_W - 0.012)
		var rail_lift: float = _SPAN_DECK_HALF_H + 0.045
		var rail_path := func(t: float) -> Vector3:
			var c: Vector3 = arc_path.call(t) as Vector3
			return c + Vector3(0.0, rail_lift, 0.0) + _span_lateral_offset(p_start, p_end, edge_off)
		var rail_profile: Array[Vector2] = MorphoSweep.profile_circle(7)
		var rail_mesh: Mesh = MorphoSweep.sweep(rail_profile, rail_path, MorphoSweep.radius_constant(0.022),
			0.0, _SPAN_BRIDGE_SEGMENTS, false)
		_cx_add_mesh(parent, rail_mesh, _span_mat_stone, Transform3D.IDENTITY, "Parapet%d" % side)

	var pier_ts: Array[float] = [0.10, 0.20, 0.30]
	for pt: float in pier_ts:
		var top: Vector3 = arc_path.call(pt) as Vector3
		top.y -= _SPAN_DECK_HALF_H
		var foot := Vector3(top.x, _SPAN_RIVER_LEVEL, top.z)
		if top.y - foot.y < 0.12:
			continue
		_cx_add_mesh(parent, MorphoPrimitive.tube(foot, top, 0.05, 0.035, 7), _span_mat_stone,
			Transform3D.IDENTITY, "Pier_%0.2f" % pt)


## Lateral offset perpendicular to the bridge chord (in the XZ plane), scaled by `amount`.
## Pure, no state. (Ported from v4's `_lateral_offset`.)
func _span_lateral_offset(a: Vector3, b: Vector3, amount: float) -> Vector3:
	var chord := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	var perp := Vector3(-chord.z, 0.0, chord.x)
	return perp * amount


## The packed hill-town: stacked little towers climbing the hill in dense radial rings, biased
## toward the camera quadrant, each window-studded. Bodies/roofs/windows batch into shared
## meshes (windows into one unshaded glowing mesh). (Ported from v4's `_build_town`.)
func _span_build_town(parent: Node3D) -> void:
	var n_buildings: int = int(round(float(_SPAN_BUILDINGS_BASE) * _span_complexity_f))

	var walls_st := SurfaceTool.new()
	walls_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_a_st := SurfaceTool.new()
	roof_a_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_b_st := SurfaceTool.new()
	roof_b_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var win_st := SurfaceTool.new()
	win_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var placed: int = 0
	var rings: Array[float] = [0.98, 0.86, 0.74, 0.62, 0.50, 0.38, 0.26, 0.14]
	var front_ang: float = atan2(-0.65, 0.78)
	var ring_idx: int = 0
	while placed < n_buildings and ring_idx < rings.size():
		var ring_r: float = rings[ring_idx] * _SPAN_HILL_RADIUS
		var ring_count: int = int(round(lerpf(14.0, 4.0, float(ring_idx) / float(rings.size() - 1))))
		for k: int in range(ring_count):
			if placed >= n_buildings:
				break
			var spread: float = deg_to_rad(250.0)
			var frac: float = (float(k) + 0.5) / float(ring_count)
			var base_ang: float = front_ang + (frac - 0.5) * spread
			var ang: float = base_ang + _rng.randf_range(-0.10, 0.10)
			var rr: float = ring_r * _rng.randf_range(0.92, 1.05)
			var fx: float = _SPAN_TOWN_CENTER.x + cos(ang) * rr
			var fz: float = _SPAN_TOWN_CENTER.z + sin(ang) * rr
			var ground_y: float = _span_hill_height(Vector3(fx, 0.0, fz))
			var height_bias: float = lerpf(0.85, 1.9, float(rings.size() - 1 - ring_idx) / float(rings.size() - 1))
			var bw: float = _rng.randf_range(0.075, 0.125)
			var bd: float = _rng.randf_range(0.075, 0.125)
			var bh: float = _rng.randf_range(0.14, 0.32) * height_bias
			var face_y_rot: float = ang + _rng.randf_range(-0.4, 0.4)
			_span_emit_building(walls_st, roof_a_st, roof_b_st, win_st,
				Vector3(fx, ground_y, fz), bw, bd, bh, face_y_rot)
			placed += 1
		ring_idx += 1

	var crown_n: int = 9
	for c: int in range(crown_n):
		var ca: float = TAU * float(c) / float(crown_n) + 0.4
		var cr: float = _SPAN_HILL_RADIUS * _rng.randf_range(0.04, 0.22)
		var cx: float = _SPAN_TOWN_CENTER.x + cos(ca) * cr
		var cz: float = _SPAN_TOWN_CENTER.z + sin(ca) * cr
		var cy: float = _span_hill_height(Vector3(cx, 0.0, cz))
		var cbw: float = _rng.randf_range(0.070, 0.105)
		var cbh: float = _rng.randf_range(0.28, 0.50)
		_span_emit_building(walls_st, roof_a_st, roof_b_st, win_st,
			Vector3(cx, cy, cz), cbw, cbw, cbh, _rng.randf_range(-0.5, 0.5))

	_span_commit_batch(parent, walls_st, _span_mat_wall, "TownWalls")
	_span_commit_batch(parent, roof_a_st, _span_mat_roof_a, "TownRoofsA")
	_span_commit_batch(parent, roof_b_st, _span_mat_roof_b, "TownRoofsB")
	_span_commit_batch(parent, win_st, _span_mat_window, "TownWindows")


## Commit a SurfaceTool batch as one MeshInstance3D under `parent` (skips empty batches). (v4.)
func _span_commit_batch(parent: Node3D, st: SurfaceTool, mat: StandardMaterial3D, node_name: String) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	_cx_add_mesh(parent, mesh, mat, Transform3D.IDENTITY, node_name)


## Emit one little tower into the shared batches in world space: a box body, a pitched OR flat
## roof, and a grid of glowing window quads on all four faces, oriented upright with a seeded
## Y-rotation (Basis, no look_at). (Ported from v4's `_emit_building`.)
func _span_emit_building(walls_st: SurfaceTool, roof_a_st: SurfaceTool, roof_b_st: SurfaceTool,
		win_st: SurfaceTool, base: Vector3, bw: float, bd: float, bh: float, y_rot: float) -> void:
	var cos_r: float = cos(y_rot)
	var sin_r: float = sin(y_rot)
	var ax := Vector3(cos_r, 0.0, sin_r)
	var ay := Vector3(0.0, 1.0, 0.0)
	var az := Vector3(-sin_r, 0.0, cos_r)

	var hw: float = bw * 0.5
	var hd: float = bd * 0.5
	var body_center: Vector3 = base + ay * (bh * 0.5)
	_span_emit_box(walls_st, body_center, ax, ay, az, hw, bh * 0.5, hd)

	var pitched: bool = _rng.randf() < 0.62
	var roof_warm: bool = _rng.randf() < 0.5
	var roof_top: Vector3 = base + ay * bh
	if pitched:
		var ridge_h: float = _rng.randf_range(0.05, 0.10)
		_span_emit_gable_roof(roof_a_st if roof_warm else roof_b_st, roof_top, ax, ay, az, hw, hd, ridge_h)
	else:
		var cap_c: Vector3 = roof_top + ay * 0.012
		_span_emit_box(roof_a_st if roof_warm else roof_b_st, cap_c, ax, ay, az, hw * 1.08, 0.012, hd * 1.08)

	_span_emit_windows(win_st, base, ax, ay, az, hw, hd, bh, az * -1.0)
	_span_emit_windows(win_st, base, ax, ay, az, hw, hd, bh, az)
	_span_emit_windows(win_st, base, az, ay, ax, hd, hw, bh, ax * -1.0)
	_span_emit_windows(win_st, base, az, ay, ax, hd, hw, bh, ax)


## A two-slope gable roof on a box top of half-extents (hw, hd), ridge along local X, built as
## two sloped quads + two gable-end triangles. (Ported from v4's `_emit_gable_roof`.)
func _span_emit_gable_roof(st: SurfaceTool, top_center: Vector3, ax: Vector3, ay: Vector3,
		az: Vector3, hw: float, hd: float, ridge_h: float) -> void:
	var c_pp: Vector3 = top_center + ax * hw + az * hd
	var c_pn: Vector3 = top_center + ax * hw - az * hd
	var c_np: Vector3 = top_center - ax * hw + az * hd
	var c_nn: Vector3 = top_center - ax * hw - az * hd
	var r_p: Vector3 = top_center + ax * hw + ay * ridge_h
	var r_n: Vector3 = top_center - ax * hw + ay * ridge_h

	var n_zp: Vector3 = (c_pp - r_p).cross(c_np - c_pp).normalized()
	_span_tri(st, c_np, c_pp, r_p, n_zp)
	_span_tri(st, c_np, r_p, r_n, n_zp)
	var n_zn: Vector3 = (c_nn - r_n).cross(c_pn - c_nn).normalized()
	_span_tri(st, c_pn, c_nn, r_n, n_zn)
	_span_tri(st, c_pn, r_n, r_p, n_zn)
	_span_tri(st, c_pn, c_pp, r_p, ax)
	_span_tri(st, c_np, c_nn, r_n, ax * -1.0)


## Lay a grid of small glowing window quads on one face, facing `out_dir`. Some windows are
## skipped (seeded) so they read as scattered lit rooms. (Ported from v4's `_emit_windows`.)
func _span_emit_windows(st: SurfaceTool, base: Vector3, u_dir: Vector3, v_dir: Vector3,
		_w_dir: Vector3, half_u: float, half_depth: float, bh: float, out_dir: Vector3) -> void:
	var cols: int = clampi(int(round(half_u / 0.045)), 1, 4)
	var rows: int = clampi(int(round(bh / 0.075)), 1, 5)
	var win_w: float = half_u * 0.34
	var win_h: float = (bh / float(rows)) * 0.42
	var face_center: Vector3 = base + out_dir * (half_depth + 0.004)
	for ci: int in range(cols):
		var cu: float = lerpf(-half_u * 0.6, half_u * 0.6, (float(ci) + 0.5) / float(cols)) if cols > 1 else 0.0
		for ri: int in range(rows):
			if _rng.randf() < 0.24:
				continue
			var rv: float = lerpf(bh * 0.16, bh * 0.86, (float(ri) + 0.5) / float(rows)) if rows > 1 else bh * 0.5
			var center: Vector3 = face_center + u_dir * cu + v_dir * rv
			_span_emit_quad_panel(st, center, u_dir, v_dir, out_dir, win_w * 0.5, win_h * 0.5)


## A single flat window quad centred at `c`, half-extents (hu, hv), facing `n`. Two triangles.
## (Ported from v4's `_emit_quad_panel`.)
func _span_emit_quad_panel(st: SurfaceTool, c: Vector3, u_dir: Vector3, v_dir: Vector3,
		n: Vector3, hu: float, hv: float) -> void:
	var eu: Vector3 = u_dir * hu
	var ev: Vector3 = v_dir * hv
	var a: Vector3 = c - eu - ev
	var b: Vector3 = c + eu - ev
	var cc: Vector3 = c + eu + ev
	var d: Vector3 = c - eu + ev
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(cc)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(cc)
	st.set_normal(n); st.add_vertex(d)


## Dark tree blobs clustered along the banks + town skirt; canopies + trunks each batched into
## one mesh. (Ported from v4's `_build_trees`.)
func _span_build_trees(parent: Node3D) -> void:
	var canopy_st := SurfaceTool.new()
	canopy_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk_st := SurfaceTool.new()
	trunk_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var n_trees: int = int(round(28.0 * _span_complexity_f))
	var zones: Array[Dictionary] = [
		{"c": Vector3(-1.55, 0.0, 0.70), "r": 0.80, "n": 0.42},
		{"c": Vector3(0.55, 0.0, 0.95), "r": 0.75, "n": 0.32},
		{"c": _SPAN_TOWN_CENTER, "r": _SPAN_HILL_RADIUS * 1.08, "n": 0.26}]

	for z: Dictionary in zones:
		var zc: Vector3 = z["c"] as Vector3
		var zr: float = z["r"] as float
		var portion: float = z["n"] as float
		var count: int = int(round(float(n_trees) * portion))
		for i: int in range(count):
			var ang: float = _rng.randf_range(0.0, TAU)
			var rad: float = sqrt(_rng.randf()) * zr
			var tx: float = zc.x + cos(ang) * rad
			var tz: float = zc.z + sin(ang) * rad
			var ty: float = 0.0
			var to_town: float = Vector2(tx - _SPAN_TOWN_CENTER.x, tz - _SPAN_TOWN_CENTER.z).length()
			if to_town < _SPAN_HILL_RADIUS:
				ty = _span_hill_height(Vector3(tx, 0.0, tz))
			_span_emit_tree(canopy_st, trunk_st, Vector3(tx, ty, tz))

	_span_commit_batch(parent, canopy_st, _span_mat_tree, "TreeCanopies")
	_span_commit_batch(parent, trunk_st, _span_mat_trunk, "TreeTrunks")


## One stylized tree: a short trunk box + a clustered canopy of 1-3 low-poly spheres. (v4.)
func _span_emit_tree(canopy_st: SurfaceTool, trunk_st: SurfaceTool, base: Vector3) -> void:
	var trunk_h: float = _rng.randf_range(0.05, 0.10)
	var trunk_r: float = _rng.randf_range(0.012, 0.020)
	var ax := Vector3(1, 0, 0)
	var ay := Vector3(0, 1, 0)
	var az := Vector3(0, 0, 1)
	var trunk_c: Vector3 = base + ay * (trunk_h * 0.5)
	_span_emit_box(trunk_st, trunk_c, ax, ay, az, trunk_r, trunk_h * 0.5, trunk_r)

	var blobs: int = 1 + (_rng.randi() % 3)
	var canopy_base: Vector3 = base + ay * trunk_h
	for b: int in range(blobs):
		var br: float = _rng.randf_range(0.06, 0.11) * (1.0 - 0.12 * float(b))
		var off := Vector3(
			_rng.randf_range(-0.04, 0.04),
			float(b) * 0.05 + br * 0.6,
			_rng.randf_range(-0.04, 0.04))
		_span_emit_icosphere(canopy_st, canopy_base + off, br)


## Emit one box centred at `c`, half-extents (hx,hy,hz) along orthonormal axes. (Ported v4.)
func _span_emit_box(st: SurfaceTool, c: Vector3, ax: Vector3, ay: Vector3, az: Vector3,
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
	_span_quad(st, p000, p010, p110, p100, az * -1.0)
	_span_quad(st, p001, p101, p111, p011, az)
	_span_quad(st, p000, p100, p101, p001, ay * -1.0)
	_span_quad(st, p010, p011, p111, p110, ay)
	_span_quad(st, p000, p001, p011, p010, ax * -1.0)
	_span_quad(st, p100, p110, p111, p101, ax)


func _span_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(c)
	st.set_normal(n); st.add_vertex(d)


func _span_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(a)
	st.set_normal(n); st.add_vertex(b)
	st.set_normal(n); st.add_vertex(c)


## Emit a small low-poly UV sphere (cheap canopy blob) into a batch, radius `r` at `c`. (v4.)
func _span_emit_icosphere(st: SurfaceTool, c: Vector3, r: float) -> void:
	var rings: int = 4
	var segs: int = 6
	var grid: Array = []
	for ri: int in range(rings + 1):
		var v: float = float(ri) / float(rings)
		var phi: float = lerpf(-PI * 0.5, PI * 0.5, v)
		var row: Array[Vector3] = []
		for si: int in range(segs + 1):
			var u: float = float(si) / float(segs)
			var theta: float = u * TAU
			var p := Vector3(cos(phi) * cos(theta), sin(phi), cos(phi) * sin(theta)) * r
			row.append(c + p)
		grid.append(row)
	for ri: int in range(rings):
		var row_a: Array = grid[ri] as Array
		var row_b: Array = grid[ri + 1] as Array
		for si: int in range(segs):
			var v00: Vector3 = row_a[si] as Vector3
			var v01: Vector3 = row_a[si + 1] as Vector3
			var v10: Vector3 = row_b[si] as Vector3
			var v11: Vector3 = row_b[si + 1] as Vector3
			var n0: Vector3 = (v00 - c).normalized()
			var n1: Vector3 = (v10 - c).normalized()
			var n2: Vector3 = (v01 - c).normalized()
			var n3: Vector3 = (v11 - c).normalized()
			st.set_normal(n0); st.add_vertex(v00)
			st.set_normal(n1); st.add_vertex(v10)
			st.set_normal(n2); st.add_vertex(v01)
			st.set_normal(n2); st.add_vertex(v01)
			st.set_normal(n1); st.add_vertex(v10)
			st.set_normal(n3); st.add_vertex(v11)
