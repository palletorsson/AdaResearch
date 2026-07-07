extends Node3D
class_name GreatWave

## @identity
# essence: a single DNA-driven HERO WAVE rendered not as a sculpted lump of blue but as Hokusai's "The
#   Great Wave off Kanagawa" COMPUTED from two genuine algorithms. Where a decorative wave would be a hand-
#   shaped ridge, GreatWave grows its famous breaking lip from a LOGARITHMIC SPIRAL r = a*e^(b*theta) — the
#   same equiangular curve a nautilus and a real curling barrel both trace — lofted as a tapering tube that
#   starts wide at the wave's shoulder and winds inward, climbing up and rolling OVER into an overhanging
#   eye; and it grows the iconic spray from a RECURSIVE self-similar claw-foam, a typed recursion where each
#   foam "claw" is a curling tapered arc that spawns 2-3 smaller same-curled claws near its tip down to a
#   bounded depth, so the foam cascades in nested fingers exactly the way the woodblock's do. A deep
#   Prussian-blue body rears on the LEFT, a light-blue inner spiral and white crest ride the lip, a smaller
#   echo swell crosses the foreground, a small snow-capped Mt Fuji sits in the gap, all read ACROSS a cream
#   "paper" backdrop like the print. It is one form (no modes) — a single hero wave whose pattern IS its
#   process: a periodic swell that breaks into fractal foam.
# desire: it wants both algorithms to stay GENUINE and LEGIBLE — the lip an honest log spiral (its r =
#   a*e^(b*theta) shape never faked, only rigidly POSED to read like the print), the foam an honest
#   recursion (each claw self-similar to its parent, the cascade bottoming out at a depth set by
#   complexity). It wants the deep Prussian body to dominate the left, a clear gap centre-right for Fuji,
#   the foam to read white and curly against blue and cream, and the whole composition presented as a
#   shallow slab to the +X/+Z capture camera the way the woodblock reads across its paper. Above all it
#   wants every seeded value (the per-claw foam jitter) baked into locals BEFORE the pure recursion runs,
#   so each launch with a given seed is identical — the seed varies only the claw detail, never the
#   composition.
# critical_parameter: seed + the colour quartet (color_a DEEP WAVE body Prussian / color_b INNER+spiral
#   light-blue, with a MID blue derived by lerp(color_a, color_b, 0.5) / accent FOAM / paper_color CREAM
#   sky) + complexity. seed drives ONLY the foam/claw jitter (a local seeded RNG, never global randf) so the
#   composition stays fixed while the spray detail varies; complexity scales the recursive claw DEPTH
#   (clampi(complexity-2, 2, 5)), the claw COUNT along the crest, and the secondary-spray density — higher
#   complexity = a deeper, denser fractal foam. sculpt_height / sculpt_width settle + scale the whole piece
#   to span.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and builds the single wave;
#   apply_grid_config rewrites config metas, clears children (remove BEFORE free, guarded by `_built`), and
#   rebuilds idempotently.
# emerges: a row of palettes reads as the SAME wave re-registered — recolour the quartet and the Prussian
#   print becomes a dusk or storm wave while the spiral and the recursion persist; reseed and the foam
#   reshuffles while the curl stays put; raise complexity and the spray deepens into more nested claws. It
#   is a teaching specimen for the wavefunctions / spirals / fractals strand: the place where a traveling
#   periodic order (the swell) dissolves into self-similar chaos (the foam) at its own breaking edge.
# needs: a seeded RNG for deterministic foam [present]; the genuine log-spiral lip path + crest offset path
#   as pure Callables holding no node refs [present]; the genuine recursive claw grower accumulating into
#   ONE shared foam SurfaceTool begun BEFORE any claw is grown (the set_normal-on-null lifecycle fix carried
#   from the trial) [present]; deep/mid/light blue + foam + cream + Fuji materials driven by the colour
#   quartet, gated by `emissive` [present]; the morphology toolkit statics (MorphoSweep for the lofted
#   spiral lip, MorphoPrimitive for the body tubes / backdrop box) with a Variant-coercing merge for the
#   non-indexed / normal-less surfaces so the foam batches into one ArrayMesh [present].
# relationships: kin to codex_swarm + codex_loom + codex_glyph + codex_morph + codex_flora (the shared
#   genome shape — identity header, grouped @export, apply_grid_config + _parse_color + _built rebuild
#   guard, self-clearing idempotent _build(), seeded RNG, settle centring, the Variant-coercing mesh-merge);
#   built on the nature_system morphology engine it borrows from (MorphoSweep.sweep / MorphoPrimitive) for
#   surface generation; cousin to the seashell sweep (same log-spiral lineage) and to any fractal-recursion
#   specimen (the claw-foam IS a fractal).
# truth: the wave is a traveling order that breaks into fractal foam — a periodic swell dissolving into
#   self-similar chaos at the crest. Boundary dissolution: the edge is where structure becomes spray. The
#   curling lip is a genuine logarithmic spiral, the equiangular curve that grows by scaling itself; the
#   spray is a genuine recursion, each claw a smaller copy of the whole. Hokusai drew the exact moment a
#   coherent moving wall of water turns, at its own leading edge, into a cascade of nested claws — order
#   becoming chaos across a boundary — and that moment is what these two algorithms compute. The spiral
#   must stay an honest spiral, the recursion an honest recursion, the foam must pop, and the whole must be
#   deterministic from one seed.

## A single DNA-driven Great Wave specimen built from TWO genuine algorithms, after Hokusai's woodblock,
## for the wavefunctions / spirals / fractals curriculum strand. Refactored verbatim-in-look from the
## verified trial (GreatWaveTrialV1) — this is a structural + DNA-wiring pass, not a redesign.
##
## LEAD TECHNIQUE 1 — LOGARITHMIC-SPIRAL LIP. The breaking lip fits a logarithmic spiral r = a*e^(b*theta)
## (`_gw_lip_path` returns a pure Callable(t)->Vector3 walking that spiral in the X-Y plane). With b < 0 the
## radius SHRINKS as theta grows, so the curve winds inward while the rising angle sweeps it up and over —
## the tightening barrel of a breaking wave. MorphoSweep.sweep lofts a tapering circular profile along that
## centreline into the crest/lip tube; a light-blue body band and a white crest line ride the same spiral.
##
## LEAD TECHNIQUE 2 — RECURSIVE CLAW-FOAM. The foam fingers are self-similar. `_gw_grow_claw` is a typed
## RECURSIVE function: a foam claw is a curling tapered arc (same handed curl as the wave) that near its tip
## spawns 2-3 smaller claws (scaled ~0.58, same curl) down to depth 0. A row of root claws along the
## breaking crest makes the foam cascade in nested claws — the Great Wave's signature spray. The recursion
## DEPTH, the claw COUNT, and the secondary-spray density scale with `complexity`.
##
## A seeded RNG makes the specimen deterministic from its `seed`. The seed varies ONLY the claw/foam jitter
## (composition fixed); every seeded value is baked into locals BEFORE the pure recursion runs. The colour
## quartet re-registers the same algorithm between palettes: color_a DEEP wave body (Prussian), color_b
## INNER/spiral light-blue (a MID blue is derived by lerp(color_a, color_b, 0.5) for the body mid-tone),
## accent FOAM, paper_color CREAM sky. Shared material + geometry helpers live under the `_gw_` prefix.
## Surface generation reuses the morphology toolkit statics (MorphoSweep, MorphoPrimitive).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## Deterministic seed — drives ONLY the foam/claw jitter. Composition is fixed; the same seed always yields
## the same spray.
@export var seed: int = 0
## Detail / fractal budget. Scales the recursive claw DEPTH (clampi(complexity-2, 2, 5)), the claw COUNT
## along the breaking crest, and the secondary-spray density. Higher = a deeper, denser foam cascade.
@export var complexity: int = 6
## Overall height in meters (nominal full height of the composition). Settles + scales the whole piece.
@export var sculpt_height: float = 2.0
## Across-span width in meters. Settles + scales the whole piece (presented to the +X/+Z camera).
@export var sculpt_width: float = 3.0

@export_group("Material")
## DEEP WAVE body — Prussian blue. The towering wall of water on the left.
@export var color_a: Color = Color(0.06, 0.12, 0.30)
## INNER / spiral lip — light blue. A MID blue is derived by lerp(color_a, color_b, 0.5) for the body band.
@export var color_b: Color = Color(0.55, 0.70, 0.80)
## FOAM — the claw-spray + crest. Near-white; emissive floor so it pops against blue + cream.
@export var accent: Color = Color(0.96, 0.97, 0.94)
## CREAM paper backdrop — the sky / paper field the wave reads across.
@export var paper_color: Color = Color(0.87, 0.81, 0.66)
## Water is not metal — keep this LOW.
@export var metallic_amt: float = 0.0
@export var rough_amt: float = 0.7
## Boost emissive energies (foam + crest read hotter when true).
@export var emissive: bool = true

# ── Tunables (the genuine algorithm constants, carried verbatim from the trial) ──

# Logarithmic spiral parameters: r(theta) = _SPIRAL_A * exp(_SPIRAL_B * theta).
# _SPIRAL_B < 0 → radius SHRINKS as theta grows, so the curve winds inward as it rolls over.
const _SPIRAL_A: float = 1.05          # base radius at theta = 0 (the shoulder)
const _SPIRAL_B: float = -0.205        # decay rate (handedness + tightness)
const _SPIRAL_TURNS: float = 0.78      # how far around the lip rolls (in turns)
const _SPIRAL_THETA0: float = 0.50     # starting angle offset (radians)
const _SPIRAL_HANDED: float = -1.0     # mirror → winds clockwise (crest rises left, arcs right)
const _SPIRAL_ORIENT: float = 0.30     # rigid pose rotation (radians)

# Claw recursion. CLAW_MAX_DEPTH is derived from complexity in _build().
const _CLAW_CHILD_SCALE: float = 0.58  # child claw size ratio (~0.5-0.65)

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()
var _mesh_count: int = 0               # diagnostic: MeshInstance3D nodes emitted this build
var _claw_count: int = 0               # diagnostic: claw tubes grown this build

# Per-build derived budget (set in _build from complexity).
var _claw_max_depth: int = 4
var _claw_root_count: int = 7

# Materials (Hokusai palette, DNA-driven).
var _mat_prussian: StandardMaterial3D   # deep wave body
var _mat_midblue: StandardMaterial3D    # lighter mid-tone band
var _mat_lightblue: StandardMaterial3D  # light inner / curl underside / spiral
var _mat_foam: StandardMaterial3D       # white spray (slightly emissive)
var _mat_cream: StandardMaterial3D      # paper sky backdrop
var _mat_fuji_snow: StandardMaterial3D  # Fuji snow cap
var _mat_fuji_base: StandardMaterial3D  # Fuji dark base

# Accumulators (rebuilt each build).
var _foam_st: SurfaceTool               # accumulates ALL claw geometry
var _lip_path: Callable                 # posed great-curl centreline (for claws)


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
	if has_meta("config_paper_color"):
		paper_color = _parse_color(str(get_meta("config_paper_color")), paper_color)
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


# ── Build ──────────────────────────────────────────────────────────────

func _build() -> void:
	# Self-clear so the build is idempotent no matter who calls it: if `_ready()` fires DEFERRED (after
	# apply_grid_config has already built), a second _build() must not stack a second wave on top of the
	# first (which would double mesh counts on the capture path). Remove BEFORE freeing (queue_free is
	# deferred) so the rebuild starts from a genuinely empty subtree this frame.
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_built = true
	_mesh_count = 0
	_claw_count = 0
	_rng.seed = seed

	# complexity → fractal budget: deeper recursion + more root claws + denser spray at higher complexity.
	_claw_max_depth = clampi(complexity - 2, 2, 5)
	_claw_root_count = clampi(3 + complexity, 5, 12)

	_build_materials()
	_build_scene()


# ═══════════════════════════════════════════════════════════════
# MATERIALS  (_gw_ helpers — the trial materials, DNA-driven)
# ═══════════════════════════════════════════════════════════════

func _build_materials() -> void:
	# Mid blue derived from the deep + light extremes — the body's mid-tone band.
	var mid: Color = color_a.lerp(color_b, 0.5)
	_mat_prussian = _gw_wave_mat(color_a)
	_mat_midblue = _gw_wave_mat(mid)
	_mat_lightblue = _gw_inner_mat(color_b)
	_mat_foam = _gw_foam_mat(accent)
	_mat_cream = _gw_paper_mat(paper_color)
	# Fuji snow near-white; base a deep indigo derived from the deep wave body so the peak silhouettes
	# crisply against the cream sky.
	_mat_fuji_snow = _gw_fuji_snow_mat()
	_mat_fuji_base = _gw_fuji_base_mat(color_a)


## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _gw_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.5)


## DEEP / MID blue wave body. Woodblock-flat: an albedo-tinted emission FLOOR (albedo*0.4 at low energy)
## keeps shading flattish and crisp, the way a print reads — no specular drama.
func _gw_wave_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(maxf(rough_amt, 0.7), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _gw_glow_energy(0.08)
	return m


## LIGHT-blue spiral inner / curl underside. A slightly brighter floor than the body so the inner spiral
## catches light against the deep blue.
func _gw_inner_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(minf(rough_amt, 0.65), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _gw_glow_energy(0.10)
	return m


## FOAM (claws + crest): near-white, roughness ~0.6, a brighter emission FLOOR (~0.12) so the spray pops
## against the blue body and the cream sky. Energy gated by `emissive`.
func _gw_foam_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(minf(rough_amt, 0.6), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _gw_glow_energy(0.12)
	return m


## CREAM paper backdrop (the sky / paper field): high roughness ~0.9, a gentle emission floor (~0.10) so
## the paper reads as an even field, not a dark wall.
func _gw_paper_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(maxf(rough_amt, 0.9), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _gw_glow_energy(0.10)
	return m


## Fuji SNOW cap — near-white, a touch warm, with a bright floor so the cap reads against the sky.
func _gw_fuji_snow_mat() -> StandardMaterial3D:
	var c := Color(0.97, 0.98, 1.00)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = clampf(minf(rough_amt, 0.65), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = c * 0.4
	m.emission_energy_multiplier = _gw_glow_energy(0.16)
	return m


## Fuji BASE — a deep indigo derived from the deep wave body (darkened toward black) so the peak
## silhouettes crisply, the way the woodblock's mountain does.
func _gw_fuji_base_mat(c: Color) -> StandardMaterial3D:
	var base: Color = c.lerp(Color(0.0, 0.0, 0.0), 0.35).lerp(Color(0.10, 0.16, 0.34), 0.5)
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = clampf(maxf(rough_amt, 0.8), 0.02, 1.0)
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = base * 0.4
	m.emission_energy_multiplier = _gw_glow_energy(0.06)
	return m


# ═══════════════════════════════════════════════════════════════
# LEAD TECHNIQUE 1 — LOGARITHMIC SPIRAL LIP
# ═══════════════════════════════════════════════════════════════

## Centreline of the wave's lip as a logarithmic spiral r = a*e^(b*theta), drawn in the X-Y plane (the
## profile plane the camera reads). The angle theta runs from THETA0 forward by SPIRAL_TURNS*TAU; because
## SPIRAL_B is negative the radius SHRINKS as theta grows — the curve spirals INWARD while the rising angle
## sweeps it up and over (the overhanging barrel). The OUTER end (t=0, the shoulder) is anchored on
## `origin`; the curl rolls toward the right and tucks under. `handed` mirrors the spiral; `orient` rigid-
## rotates the whole posed curl so the genuine log spiral reads like the print without touching its
## r = a*e^(b*theta) shape. Every constant is baked into locals so the Callable holds no node references.
func _gw_lip_path(origin: Vector3, handed: float, orient: float) -> Callable:
	var a: float = _SPIRAL_A
	var b: float = _SPIRAL_B
	var theta0: float = _SPIRAL_THETA0
	var dtheta: float = _SPIRAL_TURNS * TAU
	var ox: float = origin.x
	var oy: float = origin.y
	var oz: float = origin.z
	var hd: float = handed
	var co: float = cos(orient)
	var so: float = sin(orient)
	var r0: float = a * exp(b * theta0)
	var ax0: float = r0 * cos(theta0)
	var ay0: float = r0 * sin(theta0)
	return func(t: float) -> Vector3:
		var theta: float = theta0 + t * dtheta
		var r: float = a * exp(b * theta)
		var px: float = (r * cos(theta) - ax0) * hd
		var py: float = r * sin(theta) - ay0
		var lx: float = px * co - py * so
		var ly: float = px * so + py * co
		var lz: float = sin(t * PI) * 0.16
		return Vector3(ox + lx, oy + ly, oz + lz)


## Radius of the lip tube along the curl: thick at the shoulder, tapering to a thin tucked tip.
func _gw_lip_radius() -> Callable:
	return func(t: float) -> float:
		return lerpf(0.22, 0.055, clampf(t, 0.0, 1.0))


## A copy of the spiral path nudged outward (larger radius) and forward in Z so the white crest line rides
## the leading edge of the curl. Shares the curl's handedness AND orientation so it tracks the lip exactly.
func _gw_crest_path(origin: Vector3, handed: float, orient: float) -> Callable:
	var a: float = _SPIRAL_A * 1.10
	var b: float = _SPIRAL_B
	var theta0: float = _SPIRAL_THETA0
	var dtheta: float = _SPIRAL_TURNS * TAU
	var ox: float = origin.x
	var oy: float = origin.y
	var oz: float = origin.z + 0.14
	var hd: float = handed
	var co: float = cos(orient)
	var so: float = sin(orient)
	var r0: float = a * exp(b * theta0)
	var ax0: float = r0 * cos(theta0)
	var ay0: float = r0 * sin(theta0)
	return func(t: float) -> Vector3:
		var theta: float = theta0 + t * dtheta
		var r: float = a * exp(b * theta)
		var px: float = (r * cos(theta) - ax0) * hd
		var py: float = r * sin(theta) - ay0
		var lx: float = px * co - py * so
		var ly: float = px * so + py * co
		var lz: float = sin(t * PI) * 0.16
		return Vector3(ox + lx, oy + ly, oz + lz)


func _gw_crest_radius() -> Callable:
	return func(t: float) -> float:
		return lerpf(0.10, 0.04, clampf(t, 0.0, 1.0))


## Build the curling lip as a lofted tube swept along the log-spiral centreline. Stores the posed
## centreline in `_lip_path` (so the claw-foam can spawn along the genuine leading edge) and returns the
## world-space tip position.
func _build_lip(parent: Node3D, shoulder: Vector3) -> Vector3:
	var path: Callable = _gw_lip_path(shoulder, _SPIRAL_HANDED, _SPIRAL_ORIENT)
	_lip_path = path
	var profile: Array[Vector2] = MorphoSweep.profile_circle(14)
	var lip_mesh: Mesh = MorphoSweep.sweep(profile, path, _gw_lip_radius(), 0.0, 96, false)
	var mi := MeshInstance3D.new()
	mi.name = "Lip"
	mi.mesh = lip_mesh
	mi.material_override = _mat_lightblue
	parent.add_child(mi)
	_mesh_count += 1

	# The crest edge (a thin white foam tube riding the OUTER side of the lip), swept along the same spiral
	# but offset outward — the white line of the breaking crest in the print.
	var crest_path: Callable = _gw_crest_path(shoulder, _SPIRAL_HANDED, _SPIRAL_ORIENT)
	var crest_mesh: Mesh = MorphoSweep.sweep(
		MorphoSweep.profile_circle(10), crest_path, _gw_crest_radius(), 0.0, 96, false)
	var cmi := MeshInstance3D.new()
	cmi.name = "Crest"
	cmi.mesh = crest_mesh
	cmi.material_override = _mat_foam
	parent.add_child(cmi)
	_mesh_count += 1

	# Tip of the spiral (t=1) is where the foam breaks off.
	return path.call(1.0) as Vector3


# ═══════════════════════════════════════════════════════════════
# WAVE BODY — lofted Prussian sheet rearing up into the shoulder
# ═══════════════════════════════════════════════════════════════

## The great wave body: a thick lofted ridge that rears from the trough on the left, climbs steeply, and
## curls its top edge toward the shoulder where the spiral lip takes over. Built as a multi_tube along a
## rising, leaning centreline with a fat radius, then banded with a mid-blue tube riding its front face and
## backed by a broad Prussian sheet.
func _build_wave_body(parent: Node3D, shoulder: Vector3) -> void:
	var segs: int = 22
	var positions: Array = []
	var radii: Array = []
	var trough := Vector3(shoulder.x + 0.95, shoulder.y - 1.95, shoulder.z + 0.05)
	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var x: float = lerpf(trough.x, shoulder.x, smoothstep(0.0, 1.0, t))
		var y: float = lerpf(trough.y, shoulder.y, smoothstep(0.0, 1.0, t * 0.85 + 0.075))
		var z: float = lerpf(trough.z, shoulder.z, t) + sin(t * PI) * 0.20
		positions.append(Vector3(x, y, z))
		radii.append(lerpf(0.66, 0.32, t))
	var body_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 12)
	var bmi := MeshInstance3D.new()
	bmi.name = "WaveBody"
	bmi.mesh = body_mesh
	bmi.material_override = _mat_prussian
	parent.add_child(bmi)
	_mesh_count += 1

	# Mid-blue band riding the FRONT (toward +Z, toward camera) face of the body.
	var mid_positions: Array = []
	var mid_radii: Array = []
	for i: int in range(segs + 1):
		var p: Vector3 = positions[i] as Vector3
		var r: float = radii[i] as float
		mid_positions.append(p + Vector3(0.0, 0.0, r * 0.72))
		mid_radii.append(r * 0.42)
	var mid_mesh: Mesh = MorphoPrimitive.multi_tube(mid_positions, mid_radii, 10)
	var mmi := MeshInstance3D.new()
	mmi.name = "WaveMidBand"
	mmi.mesh = mid_mesh
	mmi.material_override = _mat_midblue
	parent.add_child(mmi)
	_mesh_count += 1

	# A broad Prussian "back wall" sheet behind the tube so the wave reads as a solid mass from the camera.
	_build_wave_sheet(parent, shoulder, trough)


## A leaning curved sheet (the wave's broad face) built as a parametric ribbon: for each step up the rearing
## centreline, lay a horizontal span of width that tapers toward the crest. Emitted as one ArrayMesh of
## quads, Prussian blue.
func _build_wave_sheet(parent: Node3D, shoulder: Vector3, trough: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var u_steps: int = 20
	var v_steps: int = 6
	var rows: Array = []
	for ui: int in range(u_steps + 1):
		var t: float = float(ui) / float(u_steps)
		var cx: float = lerpf(trough.x, shoulder.x, smoothstep(0.0, 1.0, t))
		var y: float = lerpf(trough.y, shoulder.y, smoothstep(0.0, 1.0, t * 0.85 + 0.075))
		var half_w: float = lerpf(0.12, 0.95, sin(t * PI)) + 0.18
		var z_mid: float = shoulder.z - 0.02 - t * 0.08
		var row: Array = []
		for vi: int in range(v_steps + 1):
			var s: float = float(vi) / float(v_steps) - 0.5
			var px: float = cx + s * half_w * 1.85
			var pz: float = z_mid + s * 0.10
			row.append(Vector3(px, y, pz))
		rows.append(row)
	for ui: int in range(u_steps):
		var ra: Array = rows[ui] as Array
		var rb: Array = rows[ui + 1] as Array
		for vi: int in range(v_steps):
			var v00: Vector3 = ra[vi] as Vector3
			var v01: Vector3 = ra[vi + 1] as Vector3
			var v10: Vector3 = rb[vi] as Vector3
			var v11: Vector3 = rb[vi + 1] as Vector3
			var n0: Vector3 = (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n0); st.add_vertex(v00)
			st.set_normal(n0); st.add_vertex(v10)
			st.set_normal(n0); st.add_vertex(v01)
			var n1: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			st.set_normal(n1); st.add_vertex(v01)
			st.set_normal(n1); st.add_vertex(v10)
			st.set_normal(n1); st.add_vertex(v11)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "WaveSheet"
	mi.mesh = mesh
	mi.material_override = _mat_prussian
	parent.add_child(mi)
	_mesh_count += 1


# ═══════════════════════════════════════════════════════════════
# LEAD TECHNIQUE 2 — RECURSIVE CLAW-FOAM
# ═══════════════════════════════════════════════════════════════

## RECURSIVE foam claw. A claw is a curling, tapering arc swept from `base` along direction `dir`, curling
## about `curl_axis` (same handedness as the wave). It accumulates its tube into the shared _foam_st. Near
## its TIP it recursively spawns 2-3 smaller claws (scaled by _CLAW_CHILD_SCALE, same curl), down to
## `depth == 0`. The recursion is pure: it holds no global state, so the only randomness is the per-root
## jitter baked OUTSIDE it before each top-level call.
func _gw_grow_claw(base: Vector3, dir: Vector3, curl_axis: Vector3,
		length: float, radius: float, depth: int) -> void:
	if depth <= 0 or length < 0.02:
		return

	# Build the curling arc centreline by integrating a rotating direction: at each step the direction is
	# rotated a little about curl_axis (constant turn → a circular arc; same sign everywhere → same handed
	# curl as the wave's spiral). Total turn ≈ 132° over the claw.
	var steps: int = 8
	var total_turn: float = deg_to_rad(132.0)
	var d: Vector3 = dir.normalized()
	var pos: Vector3 = base
	var positions: Array = [pos]
	var radii: Array = [radius]
	var step_len: float = length / float(steps)
	for i: int in range(1, steps + 1):
		var frac: float = float(i) / float(steps)
		var ang: float = total_turn / float(steps)
		var rot := Basis(curl_axis.normalized(), ang)
		d = (rot * d).normalized()
		pos = pos + d * step_len
		positions.append(pos)
		radii.append(lerpf(radius, radius * 0.14, frac))

	var claw_mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 6)
	if claw_mesh != null:
		_gw_merge_into_foam(claw_mesh)
		_claw_count += 1

	# ── Recurse: spawn 2-3 children near the tip ──────────────────────────
	var tip: Vector3 = positions[positions.size() - 1] as Vector3
	var pre_tip: Vector3 = positions[positions.size() - 2] as Vector3
	var tip_dir: Vector3 = (tip - pre_tip).normalized()
	# 3 children at shallow depth, 2 deeper — denser cascade near the crest.
	var child_n: int = 3 if depth >= _claw_max_depth - 1 else 2
	var child_len: float = length * _CLAW_CHILD_SCALE
	var child_rad: float = radius * _CLAW_CHILD_SCALE
	for c: int in range(child_n):
		var splay: float = lerpf(-0.55, 0.55, float(c) / maxf(float(child_n - 1), 1.0))
		var fan := Basis(curl_axis.normalized(), splay)
		var side: Vector3 = curl_axis.cross(tip_dir).normalized()
		var out_of_plane: float = lerpf(-0.25, 0.25, float(c) / maxf(float(child_n - 1), 1.0))
		var child_dir: Vector3 = (fan * tip_dir + side * out_of_plane).normalized()
		var child_base: Vector3 = positions[positions.size() - 2] as Vector3
		_gw_grow_claw(child_base, child_dir, curl_axis, child_len, child_rad, depth - 1)


## Append any mesh surface into the shared foam SurfaceTool by reading its surface arrays. multi_tube
## returns an INDEXED triangle mesh with normals; we Variant-coerce the normal/index arrays, guard for
## absence (a normal-less or non-indexed surface is handled), and feed vertices+normals straight through.
## No UVs are read, so we never call generate_tangents() on this UV-less geometry. Never `as ArrayMesh` —
## surface_get_arrays works directly on the Mesh.
func _gw_merge_into_foam(mesh: Mesh) -> void:
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
				_foam_st.set_normal(norms[vi])
			_foam_st.add_vertex(verts[vi])
	else:
		for vi2: int in range(verts.size()):
			if has_norms:
				_foam_st.set_normal(norms[vi2])
			_foam_st.add_vertex(verts[vi2])


## Spawn the cascading claw-foam off the breaking crest. Root claws are seeded at samples taken ALONG the
## genuine posed lip centreline (`_lip_path`), over its leading reach (where the crest tips over). Each claw
## is thrown outward and DOWN-RIGHT — across the gap toward Fuji — so the nested recursive claws arc
## rightward/forward over the trough the way Hokusai's foam fingers do. The recursion itself
## (`_gw_grow_claw`) is untouched. Geometry lands in _foam_st. Root count + recursion depth scale with
## complexity.
func _build_claw_foam(_tip: Vector3, shoulder: Vector3) -> void:
	# Curl axis: -Z makes the claws curl CLOCKWISE in the X-Y plane (same handed gesture as the mirrored
	# great curl), so the foam reads as one motion.
	var curl_axis := Vector3(0.0, 0.0, -1.0)

	for i: int in range(_claw_root_count):
		var f: float = float(i) / float(maxf(float(_claw_root_count - 1), 1.0))
		# Walk the genuine spiral from t=0.18 (just past the shoulder) to t=0.92 (deep into the curl).
		var lt: float = lerpf(0.18, 0.92, f)
		var on_lip: Vector3 = _lip_path.call(lt) as Vector3
		# Deterministic per-claw jitter, baked OUTSIDE the pure recursion.
		var jx: float = _rng.randf_range(-0.08, 0.08)
		var jy: float = _rng.randf_range(-0.04, 0.10)
		var jz: float = _rng.randf_range(0.02, 0.16)
		var root_base: Vector3 = on_lip + Vector3(jx, jy + 0.06, jz + 0.10)
		# Spray direction: claws nearest the front (small f) reach UP-and-RIGHT off the crest; further along
		# (large f) they hang DOWN-RIGHT across the gap toward Fuji. Always strongly biased +X.
		var up_bias: float = lerpf(0.80, -0.62, f)
		var dir := Vector3(lerpf(0.70, 1.15, f), up_bias, 0.16).normalized()
		var root_len: float = lerpf(1.02, 0.55, f) * _rng.randf_range(0.92, 1.12)
		var root_rad: float = lerpf(0.082, 0.045, f)
		_gw_grow_claw(root_base, dir, curl_axis, root_len, root_rad, _claw_max_depth)

	# A few extra scattered claws spilling down the FRONT face of the wave body (secondary spray), between
	# the shoulder and the trough below it. Count scales with complexity.
	var extra: int = clampi(complexity - 2, 2, 7)
	for j: int in range(extra):
		var t: float = _rng.randf_range(0.2, 0.85)
		var bx: float = lerpf(shoulder.x + 0.15, shoulder.x + 0.95, t)
		var by: float = lerpf(shoulder.y - 0.15, shoulder.y - 1.05, t) + _rng.randf_range(0.0, 0.2)
		var base := Vector3(bx, by, shoulder.z + 0.30 + _rng.randf_range(0.0, 0.18))
		var dir2 := Vector3(_rng.randf_range(0.4, 0.8), _rng.randf_range(-0.5, 0.2), 0.25).normalized()
		_gw_grow_claw(base, dir2, curl_axis, _rng.randf_range(0.4, 0.6),
			_rng.randf_range(0.05, 0.07), maxi(_claw_max_depth - 1, 1))


# ═══════════════════════════════════════════════════════════════
# FOREGROUND SWELL — smaller echo wave front-right, with its own claws
# ═══════════════════════════════════════════════════════════════

func _build_foreground_swell(parent: Node3D) -> void:
	# A lower swell crossing the FOREGROUND left→right (front of the panel, shallow Z), its small curl
	# rising in the centre — the near crest that runs along the bottom under the great wave. Sits left of Fuji.
	var origin := Vector3(0.30, -1.20, -0.55)
	var segs: int = 16
	var positions: Array = []
	var radii: Array = []
	var trough := Vector3(origin.x - 1.85, origin.y - 0.18, origin.z - 0.05)
	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var x: float = lerpf(trough.x, origin.x, smoothstep(0.0, 1.0, t))
		var y: float = lerpf(trough.y, origin.y + 0.55, t * t)
		var z: float = lerpf(trough.z, origin.z, t) + sin(t * PI) * 0.12
		positions.append(Vector3(x, y, z))
		radii.append(lerpf(0.30, 0.13, t))
	var mesh: Mesh = MorphoPrimitive.multi_tube(positions, radii, 10)
	var mi := MeshInstance3D.new()
	mi.name = "ForegroundSwell"
	mi.mesh = mesh
	mi.material_override = _mat_midblue
	parent.add_child(mi)
	_mesh_count += 1

	# Its little curling lip — a short log-spiral, lighter blue.
	var lip_shoulder: Vector3 = positions[positions.size() - 1] as Vector3
	var small_path: Callable = _gw_small_spiral_path(lip_shoulder)
	var lip_mesh: Mesh = MorphoSweep.sweep(
		MorphoSweep.profile_circle(10), small_path, _gw_small_lip_radius(), 0.0, 48, false)
	var lmi := MeshInstance3D.new()
	lmi.name = "ForegroundLip"
	lmi.mesh = lip_mesh
	lmi.material_override = _mat_lightblue
	parent.add_child(lmi)
	_mesh_count += 1

	# Echo claws off the small lip's tip — same down-right gesture, smaller.
	var small_tip: Vector3 = small_path.call(1.0) as Vector3
	var curl_axis := Vector3(0.0, 0.0, -1.0)
	for i: int in range(3):
		var f: float = float(i) / 2.0
		var jx: float = _rng.randf_range(-0.05, 0.05)
		var jy: float = _rng.randf_range(0.0, 0.08)
		var base: Vector3 = small_tip + Vector3(jx, jy, _rng.randf_range(0.02, 0.12))
		var dir := Vector3(lerpf(0.55, 0.9, f), lerpf(0.7, -0.2, f), 0.15).normalized()
		_gw_grow_claw(base, dir, curl_axis, lerpf(0.40, 0.28, f), 0.045, maxi(_claw_max_depth - 1, 1))


## Short log-spiral for the foreground swell's lip (same r = a*e^(b*theta) form, smaller scale, fewer
## turns). Posed with the same handedness + orientation as the great curl so the near crest echoes it.
func _gw_small_spiral_path(origin: Vector3) -> Callable:
	var a: float = 0.55
	var b: float = -0.22
	var theta0: float = 0.6
	var dtheta: float = 0.85 * TAU
	var ox: float = origin.x
	var oy: float = origin.y
	var oz: float = origin.z
	var hd: float = _SPIRAL_HANDED
	var co: float = cos(_SPIRAL_ORIENT)
	var so: float = sin(_SPIRAL_ORIENT)
	var r0: float = a * exp(b * theta0)
	var ax0: float = r0 * cos(theta0)
	var ay0: float = r0 * sin(theta0)
	return func(t: float) -> Vector3:
		var theta: float = theta0 + t * dtheta
		var r: float = a * exp(b * theta)
		var px: float = (r * cos(theta) - ax0) * hd
		var py: float = r * sin(theta) - ay0
		var lx: float = px * co - py * so
		var ly: float = px * so + py * co
		var lz: float = sin(t * PI) * 0.09
		return Vector3(ox + lx, oy + ly, oz + lz)


func _gw_small_lip_radius() -> Callable:
	return func(t: float) -> float:
		return lerpf(0.12, 0.035, clampf(t, 0.0, 1.0))


# ═══════════════════════════════════════════════════════════════
# MT FUJI — flat woodblock silhouette in the mid-distance gap
# ═══════════════════════════════════════════════════════════════

## Mt Fuji built as a FLAT silhouette — a thin extruded triangle with concave stratovolcano flanks and a
## snow cap — turned to FACE the capture camera so it reads as the print's clean dark peak. The flat is
## rotated about Y by the camera azimuth (a Basis rotation; no out-of-tree look_at) so its broad face
## squares up to the +X/+Z viewpoint.
func _build_fuji(parent: Node3D) -> void:
	var fuji_pos := Vector3(1.02, -0.66, -1.12)
	var half_w: float = 0.80
	var height: float = 0.80
	var yaw: float = 0.555
	var face := Basis(Vector3.UP, yaw)

	var base_mesh: ArrayMesh = _gw_flat_mountain_mesh(half_w, height, 0.0, 1.0)
	var bmi := MeshInstance3D.new()
	bmi.name = "FujiBase"
	bmi.mesh = base_mesh
	bmi.material_override = _mat_fuji_base
	bmi.transform = Transform3D(face, fuji_pos)
	parent.add_child(bmi)
	_mesh_count += 1

	var cap_mesh: ArrayMesh = _gw_flat_mountain_mesh(half_w, height, 0.62, 1.0)
	var cmi := MeshInstance3D.new()
	cmi.name = "FujiSnow"
	cmi.mesh = cap_mesh
	cmi.material_override = _mat_fuji_snow
	cmi.transform = Transform3D(face, fuji_pos + face * Vector3(0.0, 0.0, 0.03))
	parent.add_child(cmi)
	_mesh_count += 1


## A flat extruded mountain silhouette in local space (face in the X-Y plane, thin in Z). Returns the slice
## of the triangle whose normalized height lies in [y_lo, y_hi] — so the same outline yields the dark base
## (0..1) and the white snow cap (0.62..1). Concave flanks (Fuji's profile) come from easing the half-width
## with a slight inward curve as height rises.
func _gw_flat_mountain_mesh(half_w: float, height: float, y_lo: float, y_hi: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = 10
	var depth: float = 0.06
	var rows: Array = []
	for i: int in range(steps + 1):
		var h: float = lerpf(y_lo, y_hi, float(i) / float(steps))
		var taper: float = pow(1.0 - h, 1.18)
		var w: float = half_w * taper
		var y: float = (h - 0.5) * height
		rows.append({"w": w, "y": y})
	for i: int in range(steps):
		var a: Dictionary = rows[i]
		var b: Dictionary = rows[i + 1]
		var aw: float = a["w"]
		var ay: float = a["y"]
		var bw: float = b["w"]
		var by: float = b["y"]
		_gw_quad(st, Vector3(-aw, ay, depth), Vector3(aw, ay, depth),
			Vector3(bw, by, depth), Vector3(-bw, by, depth), Vector3(0, 0, 1))
		_gw_quad(st, Vector3(aw, ay, -depth), Vector3(-aw, ay, -depth),
			Vector3(-bw, by, -depth), Vector3(bw, by, -depth), Vector3(0, 0, -1))
		_gw_quad(st, Vector3(aw, ay, depth), Vector3(aw, ay, -depth),
			Vector3(bw, by, -depth), Vector3(bw, by, depth), Vector3(1, 0, 0))
		_gw_quad(st, Vector3(-aw, ay, -depth), Vector3(-aw, ay, depth),
			Vector3(-bw, by, depth), Vector3(-bw, by, -depth), Vector3(-1, 0, 0))
	st.generate_normals()
	return st.commit()


## Emit one quad (v0→v1→v2→v3, CCW) as two triangles with a flat normal.
func _gw_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, n: Vector3) -> void:
	st.set_normal(n); st.add_vertex(v0)
	st.set_normal(n); st.add_vertex(v1)
	st.set_normal(n); st.add_vertex(v2)
	st.set_normal(n); st.add_vertex(v0)
	st.set_normal(n); st.add_vertex(v2)
	st.set_normal(n); st.add_vertex(v3)


# ═══════════════════════════════════════════════════════════════
# CREAM PAPER BACKDROP (the sky / paper field)
# ═══════════════════════════════════════════════════════════════

func _build_backdrop(parent: Node3D) -> void:
	# One large LANDSCAPE cream panel (~3:2) behind everything — the paper sky of the print. No frame: the
	# cream IS the composition field, so the wave reads ACROSS it like the woodblock.
	var panel_w: float = 5.6
	var panel_h: float = 3.7
	var panel := MeshInstance3D.new()
	panel.name = "PaperSky"
	panel.mesh = MorphoPrimitive.box(Vector3(panel_w, panel_h, 0.10))
	panel.material_override = _mat_cream
	panel.transform = Transform3D(Basis(), Vector3(0.0, 0.05, -1.55))
	parent.add_child(panel)
	_mesh_count += 1


# ═══════════════════════════════════════════════════════════════
# ASSEMBLY
# ═══════════════════════════════════════════════════════════════

func _build_scene() -> void:
	# Root composition group. The capture camera looks from +X/+Z, so X is the screen-horizontal (−X = left,
	# +X = right) and Y is up. The whole scene is composed as a SHALLOW SLAB just in front of the cream sky,
	# so it reads like the woodblock ACROSS the paper — great wave dominating the LEFT/upper-left, its log-
	# spiral lip curling OVER toward the RIGHT with cascading claw-foam, Mt Fuji small in the gap right-of-
	# centre, a foreground swell low across the front.
	var comp := Node3D.new()
	comp.name = "Composition"
	add_child(comp)

	# CRITICAL (carried from the trial): create the shared foam SurfaceTool BEFORE any builder grows a claw
	# (the great wave AND the foreground swell both append into it). If a claw is grown while _foam_st is
	# still null, set_normal crashes. One tool, begun once, holds every claw.
	_foam_st = SurfaceTool.new()
	_foam_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Cream paper sky (furthest back).
	_build_backdrop(comp)

	# Mt Fuji small in the gap, just in front of the sky.
	_build_fuji(comp)

	# The great wave: shoulder high on the LEFT and near the front of the slab; the body rears up to it and
	# the spiral lip curls from it over to the right.
	var shoulder := Vector3(-1.25, 1.18, -0.85)
	_build_wave_body(comp, shoulder)
	var tip: Vector3 = _build_lip(comp, shoulder)

	# Great-wave claw-foam: cascades off the lip's leading edge, down-right over the gap toward Fuji.
	_build_claw_foam(tip, shoulder)

	# Foreground swell across the front — its own curl + echo claws (also append into _foam_st).
	_build_foreground_swell(comp)

	# Commit ALL accumulated claws as one batched ArrayMesh.
	_foam_st.generate_normals()
	var foam_mesh: ArrayMesh = _foam_st.commit()
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		var fmi := MeshInstance3D.new()
		fmi.name = "ClawFoam"
		fmi.mesh = foam_mesh
		fmi.material_override = _mat_foam
		comp.add_child(fmi)
		_mesh_count += 1

	# Settle + scale the whole composition to the requested span, presented to the +X/+Z camera. The native
	# composition spans ~5.6 across; fit its largest axis to the larger of sculpt_width / sculpt_height and
	# then stretch the horizontal axes toward sculpt_width so the wide print proportions read.
	_gw_settle(comp)


## Centre the composition on its own centroid and scale it to the requested span. The native build spans
## ~5.6 across (X), ~3.8 tall (Y); we fit the largest axis to maxf(sculpt_width, sculpt_height) and apply a
## mild horizontal stretch toward sculpt_width so the landscape proportions are preserved. No global
## transforms touched — pure local AABB + local transform.
func _gw_settle(body: Node3D) -> void:
	var target_span: float = maxf(maxf(sculpt_width, sculpt_height), 0.4)
	var raw: AABB = _gw_subtree_aabb(body)
	var span: float = maxf(maxf(raw.size.x, maxf(raw.size.y, raw.size.z)), 0.001)
	var k: float = target_span / span
	# A gentle width stretch so a tall-but-wide request still reads as the wide print (clamped so we never
	# distort wildly).
	var width_scale: float = clampf(sculpt_width / maxf(sculpt_height, 0.001), 0.6, 1.6)
	body.scale = Vector3(k * width_scale, k, k)
	var aabb: AABB = _gw_subtree_aabb(body)
	if aabb.size == Vector3.ZERO:
		return
	var centre: Vector3 = aabb.get_center()
	body.position += -centre


## Local AABB over all MeshInstance3D descendants of `node`, accumulated through the chain of LOCAL
## transforms (never touches global_transform — independent of tree state). Used to centre + scale.
func _gw_subtree_aabb(node: Node3D) -> AABB:
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
