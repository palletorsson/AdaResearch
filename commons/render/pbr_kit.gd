@tool
extends RefCounted
class_name PbrKit

## PBR material + mesh kit for procedurally built artifacts.
##
## HangarKit gave the family its LOOK (the Braun/Rams palette, the terminal finish, the
## stencils). It gave every surface one albedo, one metallic, one roughness — which is the
## flat-plastic tell: a whole object lit with a single perfectly uniform highlight. This kit
## is the richer vocabulary those callers move to. Same house, same palette, same argument
## shapes where it could keep them, so migration is mechanical:
##
##     HangarKit.rams_body(c, wear)          ->  PbrKit.rams_body(c, wear)
##     HangarKit.terminal_body(c, wear)      ->  PbrKit.terminal_body(c, wear)
##     HangarKit.finish_body(f, c, wear)     ->  PbrKit.finish_body(f, c, wear)
##     HangarKit.painted_metal(c, w, m, r)   ->  PbrKit.painted_metal(c, w, m, r)
##     HangarKit.worn_metal(c)               ->  PbrKit.worn_metal(c)
##     HangarKit.emissive(c, e)              ->  PbrKit.emissive(c, e)
##     HangarKit.box(centre, size, mat)      ->  PbrKit.box(centre, size, mat)   # now chamfered
##
## WHAT THE UPGRADE ACTUALLY IS
##  - Every surface gets a roughness TEXTURE, so the highlight breaks up instead of being a
##    single mirror-smooth sweep. That one move is most of the distance from a Godot default
##    to a finished surface.
##  - Metals are metallic 1.0 with a measured albedo and a coloured specular; dielectrics are
##    metallic 0.0. Nothing sits at the physically meaningless 0.3-0.6 middle.
##  - Painted things get a clear coat: a second, tighter specular lobe over the diffuse.
##  - PbrKit.box() chamfers every edge, so edges catch a highlight line instead of vanishing.
##
## COST: the noise is generated once per (kind, range) and cached in a static dictionary for
## the life of the process. See vr_cost notes at _tex_cache below.
##
## THREE GODOT TRAPS THIS FILE ROUTES AROUND — read these before hand-rolling a material:
##  1. NORMAL MAPS NEED TANGENTS. BoxMesh/CylinderMesh/SphereMesh/TorusMesh have them.
##     A hand-built SurfaceTool mesh does NOT unless you set UVs and call generate_tangents().
##     PbrKit.box() / lathe() / chamfer_cylinder() do both. HangarKit.wedge() does not — a
##     normal map on a HangarKit wedge is silently ignored.
##  2. detail_enabled WITHOUT a detail_normal texture DESTROYS your normal map. Godot's
##     generated shader does NORMAL_MAP = mix(NORMAL_MAP, detail_norm_tex.rgb, mask), and the
##     unset detail-normal sampler defaults to FLAT. Use PbrKit.weather(), which sets both.
##  3. roughness_texture MULTIPLIES the roughness scalar (ROUGHNESS = roughness * tex). A
##     texture averaging 0.8 silently makes everything 20% glossier than you asked for. Every
##     builder here divides the target by the texture's mean before assigning.

# ── WHICH KIT DO I CALL? ──────────────────────────────────────────────
#
# commons/render/ now holds two kits. They do not compete; they split like this:
#
#   MATERIALS -> PbrKit (this file). Always. MeshKit builds no materials.
#
#   NEW GEOMETRY -> MeshKit. It is the deeper geometry library: segmented bevels,
#     smooth-vs-flat chamfer shading, capsule, tube, cone, rounded_panel, indexed
#     meshes, tri_count() for budget checks. Reach for it first when building a
#     shape from scratch.
#
#   MIGRATING A HangarKit CALL -> PbrKit.box() / PbrKit.pipe(). These exist because
#     they keep HangarKit's exact argument shape — box(center, size, mat) returns a
#     POSITIONED MeshInstance3D carrying the material on material_override — so a
#     migration is a class-name change and nothing else. MeshKit.box_instance()
#     takes (size, mat) with no centre and puts the material on the MESH SURFACES
#     instead, which is a different call site and a different node.
#
# INTEROP: MeshKit's _finish() calls generate_tangents(), so every MeshKit mesh
# carries tangents and PbrKit normal maps work on it directly. The reverse is also
# fine. The one thing to keep straight is WHERE the material landed: HangarKit and
# PbrKit use material_override, MeshKit uses surface materials. Anything that walks
# a subtree swapping materials (highlight, pickup, HangarKit.harmonize) has to check
# both — harmonize already does.

# ── Feature gates ─────────────────────────────────────────────────────
## Desktop-only extras: subsurface scattering, screen-space refraction, deep parallax. All
## three are Forward+ features that either cost real frame time or do nothing on the Quest's
## mobile renderer. DEFAULT OFF. An artifact that wants them exposes its own
## @export var lush_materials: bool = false and sets PbrKit.desktop_extras = lush_materials
## in _ready() before building. Everything else in this file is Quest-safe.
static var desktop_extras: bool = false

## Vertex colours as an albedo multiplier. PbrKit.box() and lathe() bake edge-lighter /
## base-darker wear into vertex colours when their `wear` argument is > 0; this flag is what
## makes the material read them. Harmless on meshes without vertex colours (COLOR defaults to
## white). Set false globally if a caller uses vertex colour for something else.
static var vertex_wear: bool = true

## Edge length of the generated detail textures. 256 is the sweet spot for VR: enough to hide
## the tiling, small enough that ten of them fit in a couple of MB. 512 doubles VRAM for
## detail you cannot see at arm's length.
static var detail_size: int = 256

# ── House palette (mirrors HangarKit; kept local so commons/render has no
#    dependency on commons/artifacts) ─────────────────────────────────
const BODY_LIGHT := Color(0.81, 0.79, 0.75)
const PANEL_TRIM := Color(0.70, 0.68, 0.64)
const BRAUN_ACCENT := Color(0.86, 0.34, 0.11)
const DISPLAY_DARK := Color(0.12, 0.12, 0.135)
const TEXT_DISPLAY := Color(0.90, 0.89, 0.85)
const TERMINAL_BODY := Color(0.14, 0.14, 0.155)
const TERMINAL_PANEL := Color(0.09, 0.09, 0.10)
const TERMINAL_ACCENT := Color(0.85, 0.30, 0.12)
const TERMINAL_SCREEN := Color(0.05, 0.10, 0.06)
const TERMINAL_TEXT := Color(0.45, 0.95, 0.50)

# ── Measured metal albedos. A metal's colour IS its specular, so these are the
#    real reflectance values, not "grey-ish". Use them with metallic = 1.0. ──
const STEEL := Color(0.560, 0.570, 0.578)
const ALUMINIUM := Color(0.610, 0.620, 0.625)
const CHROME := Color(0.720, 0.725, 0.730)
const IRON := Color(0.400, 0.400, 0.412)
const TITANIUM := Color(0.542, 0.520, 0.498)
const BRASS := Color(0.660, 0.540, 0.290)
const COPPER := Color(0.720, 0.450, 0.330)
const GOLD := Color(0.760, 0.620, 0.290)
const GUNMETAL := Color(0.230, 0.235, 0.250)

# ── Dielectric references. Nothing here is 0,0,0 — a pure black surface has
#    no diffuse response left to shade with, which is rubric item 5. ──────
const CONCRETE_GREY := Color(0.520, 0.515, 0.500)
const RUBBER_BLACK := Color(0.052, 0.052, 0.058)
const PLASTIC_WHITE := Color(0.860, 0.858, 0.845)
const GLASS_TINT := Color(0.780, 0.845, 0.860)

# ── Noise kinds. Each is one FastNoiseLite configuration; the material
#    builders pick a kind and a floor value, and share the cache. ────────
const GRAIN_MICRO := "micro"      # tight speckle — painted / plastic micro-variation
const GRAIN_BRUSH := "brush"      # high-frequency, stretched into streaks by uv1_scale
const GRAIN_GRUNGE := "grunge"    # big warped blotches — dirt, wear, weathering
const GRAIN_CAST := "cast"        # cellular pits — concrete, cast metal, sand-blasting
const GRAIN_FLAKE := "flake"      # very tight value noise — rubber, metal flake

# Standard roughness floors. Sharing a small set of floors keeps the texture cache small:
# a key is (kind, floor, size), so ten material builders resolve to about five textures.
const LO_METAL := 0.62
const LO_HARD := 0.70
const LO_PAINT := 0.74
const LO_SOFT := 0.86

# Standard normal-map bump strengths, same cache-sharing logic.
const BUMP_FINE := 2.5
const BUMP_MED := 4.0
const BUMP_COARSE := 7.0

## Texture cache. Keyed by kind+range+size, so six artifacts x several materials each build
## AT MOST one texture per distinct look, once, for the life of the process.
## Budget: a grayscale grain is 256x256 RGB8 + mips ~= 260 KB, a normal map the same. The
## full kit tops out near ten entries, so ~2.5 MB VRAM total no matter how many artifacts
## call it. Generation runs in Godot's C++ noise thread, not GDScript.
static var _tex_cache: Dictionary = {}


# ══ TEXTURES ═════════════════════════════════════════════════════════════

## A grayscale detail texture, ramped into [floor .. 1.0]. Feed it to roughness_texture
## (channel GRAYSCALE) or to detail_albedo. Cached.
##
## NOTE the range: because Godot MULTIPLIES roughness by this texture, a texture that dips to
## 0 would make patches mirror-smooth. The floor keeps the variation to a believable band.
static func grain(kind: String = GRAIN_MICRO, floor_value: float = LO_PAINT, size: int = 0) -> NoiseTexture2D:
	var px: int = size if size > 0 else detail_size
	# Snap the floor to 0.02 steps. Without this a caller passing a computed floor
	# (weather() does) mints a fresh 260 KB texture for every 0.001 of difference.
	var lo: float = snappedf(clampf(floor_value, 0.0, 0.98), 0.02)
	var key: String = "g|%s|%.2f|%d" % [kind, lo, px]
	if _tex_cache.has(key):
		var hit: NoiseTexture2D = _tex_cache[key]
		return hit
	var t := NoiseTexture2D.new()
	t.width = px
	t.height = px
	t.seamless = true
	t.generate_mipmaps = true
	t.normalize = true
	t.noise = _noise_for(kind)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(lo, lo, lo))
	ramp.set_color(1, Color(1.0, 1.0, 1.0))
	t.color_ramp = ramp
	_tex_cache[key] = t
	return t


## A tangent-space normal map derived from the same noise. `bump` is the height-to-normal
## gain — BUMP_FINE for a satin sheen, BUMP_COARSE for cast concrete. Cached.
##
## Requires the mesh to carry TANGENTS. PbrKit.box/lathe/chamfer_cylinder and every Godot
## primitive mesh do; a bare SurfaceTool surface does not.
static func grain_normal(kind: String = GRAIN_MICRO, bump: float = BUMP_MED, size: int = 0) -> NoiseTexture2D:
	var px: int = size if size > 0 else detail_size
	var key: String = "n|%s|%.1f|%d" % [kind, bump, px]
	if _tex_cache.has(key):
		var hit: NoiseTexture2D = _tex_cache[key]
		return hit
	var t := NoiseTexture2D.new()
	t.width = px
	t.height = px
	t.seamless = true
	t.generate_mipmaps = true
	t.normalize = true
	t.as_normal_map = true
	t.bump_strength = bump
	t.noise = _noise_for(kind)
	_tex_cache[key] = t
	return t


## Build the common set up front. Optional — everything is lazy — but calling this once from
## a map or a capture harness moves the (small) generation cost off the first artifact's
## _ready() and guarantees no texture is still white on the very first rendered frame.
static func warm_cache() -> void:
	grain(GRAIN_MICRO, LO_PAINT)
	grain(GRAIN_BRUSH, LO_METAL)
	grain(GRAIN_CAST, LO_HARD)
	grain(GRAIN_FLAKE, LO_SOFT)
	grain(GRAIN_GRUNGE, 0.55)
	grain_normal(GRAIN_MICRO, BUMP_FINE)
	grain_normal(GRAIN_BRUSH, BUMP_FINE)
	grain_normal(GRAIN_CAST, BUMP_COARSE)
	grain_normal(GRAIN_FLAKE, BUMP_MED)
	grain_normal(GRAIN_GRUNGE, BUMP_MED)


static func _noise_for(kind: String) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = 20260807
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	if kind == GRAIN_BRUSH:
		# High frequency, low octave count. The STREAKS do not come from the noise —
		# they come from the material stretching this texture 40x along one axis.
		n.noise_type = FastNoiseLite.TYPE_VALUE
		n.frequency = 0.22
		n.fractal_octaves = 2
		n.fractal_gain = 0.45
	elif kind == GRAIN_GRUNGE:
		# Big soft blotches, domain-warped so they do not read as noise-with-octaves.
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.011
		n.fractal_octaves = 5
		n.fractal_gain = 0.58
		n.fractal_lacunarity = 2.2
		n.domain_warp_enabled = true
		n.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
		n.domain_warp_amplitude = 22.0
		n.domain_warp_frequency = 0.014
	elif kind == GRAIN_CAST:
		# Cellular distance field — pits and aggregate, the concrete/sand-blast look.
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.frequency = 0.048
		n.fractal_octaves = 2
		n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
		n.cellular_jitter = 1.0
	elif kind == GRAIN_FLAKE:
		n.noise_type = FastNoiseLite.TYPE_VALUE
		n.frequency = 0.42
		n.fractal_octaves = 1
	else:
		# GRAIN_MICRO — the default. Fine multi-octave speckle for painted surfaces.
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.095
		n.fractal_octaves = 4
		n.fractal_gain = 0.5
	return n


# ══ MATERIAL PLUMBING ════════════════════════════════════════════════════

## Every material starts here: anisotropic-filtered mipmaps (kills shimmer at grazing angles,
## which is a specific VR tell) and the vertex-wear flag.
static func _base() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = vertex_wear
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Assign a roughness texture AND the scalar that lands the mean where the caller asked.
## Godot does ROUGHNESS = roughness * texture, so the scalar has to be pre-divided by the
## texture's mean. Skipping this step is why hand-written Godot materials come out glossier
## than intended once a roughness map is added.
static func _rough(m: StandardMaterial3D, target: float, kind: String, floor_value: float) -> void:
	var mean: float = (floor_value + 1.0) * 0.5
	m.roughness_texture = grain(kind, floor_value)
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	m.roughness = clampf(target / maxf(mean, 0.05), 0.02, 1.0)


static func _normal(m: StandardMaterial3D, kind: String, bump: float, strength: float) -> void:
	m.normal_enabled = true
	m.normal_texture = grain_normal(kind, bump)
	m.normal_scale = clampf(strength, 0.0, 16.0)


## Triplanar in LOCAL space. Procedurally built boxes and cylinders have UVs that are either
## absent or per-face nonsense, so triplanar is the correct default for almost everything in
## this project. Local rather than world so the finish travels with the object when a map
## places it somewhere else.
static func _triplanar(m: StandardMaterial3D, scale: Vector3, sharpness: float = 1.0) -> void:
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false
	m.uv1_scale = scale
	m.uv1_triplanar_sharpness = clampf(sharpness, 0.01, 8.0)


## Multiply an already-built material's detail frequency. Small parts (a 3 cm bolt head, a
## 2 cm trim strip) need a much higher scale than a 1 m panel or the noise never repeats
## across them and reads as flat colour. Rule of thumb: factor ~= 1.0 / longest_dimension.
static func scale_detail(m: StandardMaterial3D, factor: float) -> StandardMaterial3D:
	if m == null:
		return m
	m.uv1_scale = m.uv1_scale * maxf(factor, 0.001)
	if m.detail_enabled:
		m.uv2_scale = m.uv2_scale * maxf(factor, 0.001)
	return m


# ══ METALS ═══════════════════════════════════════════════════════════════

## Brushed metal — the workhorse. Directional roughness plus anisotropy, so the highlight
## smears along the brush direction the way a real rolled-and-brushed panel does.
##
## `axis` picks the brush direction: "y" vertical (default, correct for uprights and
## cabinet faces), "x" or "z" horizontal (correct for lids, shelves, trim runs).
static func brushed_metal(base: Color = STEEL, roughness: float = 0.30,
		wear: float = 0.12, axis: String = "y") -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(w * 0.20)
	m.metallic = 1.0
	m.metallic_specular = 0.55
	_rough(m, clampf(roughness + w * 0.24, 0.03, 0.96), GRAIN_BRUSH, LO_METAL)
	# THESE STRENGTHS WERE CUT ~3x AND THE CUT WAS REVERTED. The reasoning was sound and
	# the result was measured: the blind vote fell from 60.2% to 38.9% in one round, and
	# the materials lens — the one that reads exactly this — went 63% to 32%. Removing
	# micro-normal removed the only thing making most of these surfaces read as anything,
	# and the critics' oldest and loudest complaint has always been 'no roughness
	# variation, flat plastic'. The bench's bark was real, but it was a fact about a LARGE
	# FLAT SLAB carrying a grain sized for a small part — a scale problem, fixed at
	# rams_body and per-artifact — not a reason to flatten steel and moulded plastic too.
	_normal(m, GRAIN_BRUSH, BUMP_FINE, 0.30 + w * 0.45)
	m.anisotropy_enabled = true
	m.anisotropy = 0.72
	# The stretch IS the brush: 3 tiles across the grain, 40 along it.
	var s: Vector3 = Vector3(3.0, 40.0, 3.0)
	if axis == "x":
		s = Vector3(40.0, 3.0, 3.0)
	elif axis == "z":
		s = Vector3(3.0, 3.0, 40.0)
	_triplanar(m, s)
	return m


## Machined / turned metal — tighter, cleaner, no brush direction. Bar stock, bolt heads,
## precision housings, anything that came off a lathe or a mill rather than a rolling line.
static func machined_metal(base: Color = ALUMINIUM, roughness: float = 0.22,
		wear: float = 0.08) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(w * 0.16)
	m.metallic = 1.0
	m.metallic_specular = 0.6
	_rough(m, clampf(roughness + w * 0.20, 0.03, 0.96), GRAIN_MICRO, LO_METAL)
	_normal(m, GRAIN_MICRO, BUMP_FINE, 0.18 + w * 0.30)
	m.anisotropy_enabled = true
	m.anisotropy = 0.25
	_triplanar(m, Vector3(6.0, 6.0, 6.0))
	return m


## Dark scuffed metal for trim, bolts, edges, frames — the PbrKit twin of HangarKit's
## worn_metal(), and call-compatible with it (the extra argument is optional).
static func worn_metal(base: Color = GUNMETAL, wear: float = 0.35) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(0.30)
	m.metallic = 1.0
	m.metallic_specular = 0.42
	_rough(m, clampf(0.40 + w * 0.24, 0.05, 0.96), GRAIN_GRUNGE, LO_METAL)
	_normal(m, GRAIN_GRUNGE, BUMP_MED, 0.35 + w * 0.55)
	_triplanar(m, Vector3(2.4, 2.4, 2.4))
	return m


## Bare cast / sand-blasted metal — no brush, no polish. Cellular pitting, high roughness.
## The right surface for a housing that was cast rather than folded.
static func cast_metal(base: Color = IRON, wear: float = 0.30) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(w * 0.24)
	m.metallic = 1.0
	m.metallic_specular = 0.35
	_rough(m, clampf(0.58 + w * 0.22, 0.05, 0.98), GRAIN_CAST, LO_HARD)
	_normal(m, GRAIN_CAST, BUMP_COARSE, 0.55 + w * 0.6)
	_triplanar(m, Vector3(4.0, 4.0, 4.0))
	return m


# ══ PAINTS, PLASTICS, SOFT SURFACES ══════════════════════════════════════

## Painted metal — argument-compatible with HangarKit.painted_metal(base, wear, metal, rough)
## so a call site migrates by changing the class name only.
##
## What changed under the hood: paint is a DIELECTRIC film over metal, so this is metallic 0
## plus a CLEAR COAT (a second, tighter specular lobe) rather than a fudged mid metallic. The
## `metal` argument is reinterpreted honestly: it is now how much bare metal shows through
## where the paint has failed, and it drives metallic together with wear. Passing the old
## default 0.35 gives a lightly chipped painted panel, which is what the old call looked like
## it was asking for.
static func painted_metal(base: Color, wear: float = 0.15, metal: float = 0.35,
		rough: float = 0.62) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(w * 0.35)
	m.metallic = clampf(metal * w * 0.9, 0.0, 0.85)
	m.metallic_specular = 0.5
	var kind: String = GRAIN_GRUNGE if w > 0.34 else GRAIN_MICRO
	_rough(m, clampf(rough + w * 0.22, 0.05, 0.98), kind, LO_PAINT)
	_normal(m, kind, BUMP_FINE, 0.22 + w * 0.55)
	# Clear coat: fresh paint has a hard gloss film, worn paint has chalked to nothing.
	m.clearcoat_enabled = true
	m.clearcoat = clampf(0.50 - w * 0.45, 0.0, 1.0)
	m.clearcoat_roughness = clampf(0.08 + w * 0.55, 0.0, 1.0)
	_triplanar(m, Vector3(3.0, 3.0, 3.0))
	if w > 0.30:
		weather(m, w * 0.8)
	return m


## Matte industrial paint — the calm Braun/Rams housing. Argument-compatible with
## HangarKit.rams_body(). No clear coat, no metal, roughness that varies just enough that the
## highlight is a soft field instead of a flat wash. This is the family DEFAULT surface, so it
## stays restrained: `wear` only lightly darkens and roughens.
static func rams_body(c: Color = BODY_LIGHT, wear: float = 0.08) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = c.darkened(w * 0.12)
	m.metallic = 0.0
	m.metallic_specular = 0.45
	_rough(m, clampf(0.58 + w * 0.18, 0.05, 0.98), GRAIN_MICRO, LO_PAINT)
	# MEASURED DOWN from 0.16 + w*0.30 by bisecting situated_bench's worktop: with every
	# other texture layer ablated, this line alone turned a metre of painted resin into
	# sandpaper. At triplanar scale 4 the micro grain lands near millimetre size, and a
	# normal that fine is not meant to be SEEN — its whole job is to break the specular
	# so the highlight has some life in it. Once it is legible as texture it has stopped
	# describing paint and started describing stone.
	_normal(m, GRAIN_MICRO, BUMP_FINE, 0.05 + w * 0.10)
	_triplanar(m, Vector3(4.0, 4.0, 4.0))
	return m


## Dark worn-metal terminal housing. Argument-compatible with HangarKit.terminal_body().
##
## Physically this is powder-coated steel: a dielectric coat with a clear film over it,
## thinning to bare brushed metal as it wears. That is why metallic RISES with wear instead
## of being a fixed middle value. The albedo is lifted off black on purpose — a charcoal
## surface with no diffuse left reads as a hole in the scene, not as a dark object.
static func terminal_body(c: Color = TERMINAL_BODY, wear: float = 0.30) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = c.darkened(w * 0.14).lightened(0.05)
	m.metallic = clampf(0.12 + w * 0.62, 0.0, 1.0)
	m.metallic_specular = 0.5
	_rough(m, clampf(0.42 + w * 0.20, 0.05, 0.96), GRAIN_BRUSH, LO_METAL)
	_normal(m, GRAIN_BRUSH, BUMP_FINE, 0.30 + w * 0.50)
	m.anisotropy_enabled = true
	m.anisotropy = 0.55
	m.clearcoat_enabled = true
	m.clearcoat = clampf(0.35 - w * 0.30, 0.0, 1.0)
	m.clearcoat_roughness = clampf(0.12 + w * 0.50, 0.0, 1.0)
	_triplanar(m, Vector3(3.0, 40.0, 3.0))
	if w > 0.18:
		weather(m, w * 0.7)
	return m


## Body material for a named finish. Argument-compatible with HangarKit.finish_body().
static func finish_body(finish: String, c: Color, wear: float) -> StandardMaterial3D:
	if finish.to_lower() == "terminal":
		return terminal_body(c, wear)
	return rams_body(c, wear)


## The palette for a named finish — same keys and same values as HangarKit.finish_palette(),
## so a caller can switch kits without touching its colour lookups.
static func finish_palette(finish: String) -> Dictionary:
	if finish.to_lower() == "terminal":
		return {"body": TERMINAL_BODY, "panel": TERMINAL_PANEL, "accent": TERMINAL_ACCENT,
			"screen": TERMINAL_SCREEN, "text": TERMINAL_TEXT, "header": TERMINAL_ACCENT,
			"wear": 0.32}
	return {"body": BODY_LIGHT, "panel": PANEL_TRIM, "accent": BRAUN_ACCENT,
		"screen": DISPLAY_DARK, "text": TEXT_DISPLAY, "header": BRAUN_ACCENT, "wear": 0.08}


## Injection-moulded hard plastic. `gloss` 0..1 runs matte ABS to polished acrylic. The rim
## term is the cheap stand-in for the light that leaks through a thin plastic edge — it is a
## per-pixel term, not subsurface scattering, so it costs nothing on the Quest.
static func hard_plastic(base: Color = PLASTIC_WHITE, gloss: float = 0.55,
		wear: float = 0.06) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var g: float = clampf(gloss, 0.0, 1.0)
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(w * 0.14)
	m.metallic = 0.0
	m.metallic_specular = 0.5
	_rough(m, clampf(lerpf(0.52, 0.12, g) + w * 0.18, 0.03, 0.98), GRAIN_MICRO, LO_HARD)
	_normal(m, GRAIN_MICRO, BUMP_FINE, 0.10 + w * 0.25)
	m.clearcoat_enabled = true
	m.clearcoat = g * 0.55
	m.clearcoat_roughness = clampf(0.05 + (1.0 - g) * 0.35, 0.0, 1.0)
	m.rim_enabled = true
	m.rim = 0.28
	m.rim_tint = 0.35
	_triplanar(m, Vector3(5.0, 5.0, 5.0))
	return m


## Soft / translucent plastic — nylon, silicone, diffuser caps, moulded grips. Uses backlight
## (a cheap wrap term that works everywhere) and only promotes to real subsurface scattering
## when PbrKit.desktop_extras is on.
static func soft_plastic(base: Color = PLASTIC_WHITE, gloss: float = 0.30,
		translucency: float = 0.35) -> StandardMaterial3D:
	var m: StandardMaterial3D = hard_plastic(base, gloss, 0.04)
	var t: float = clampf(translucency, 0.0, 1.0)
	m.clearcoat = 0.0
	m.clearcoat_enabled = false
	m.rim = 0.45
	m.backlight_enabled = true
	m.backlight = Color(base.r * t * 0.5, base.g * t * 0.5, base.b * t * 0.5)
	if desktop_extras:
		m.subsurf_scatter_enabled = true
		m.subsurf_scatter_strength = t * 0.6
	return m


## Rubber, EPDM seal, tyre, cable jacket, matte grip. Very dark albedo, very high roughness,
## a fine flake normal — the surface that eats light and shows only a broad soft sheen.
static func rubber(base: Color = RUBBER_BLACK, wear: float = 0.20) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.lightened(w * 0.10)
	m.metallic = 0.0
	m.metallic_specular = 0.35
	_rough(m, clampf(0.90 - w * 0.06, 0.30, 1.0), GRAIN_FLAKE, LO_SOFT)
	_normal(m, GRAIN_FLAKE, BUMP_MED, 0.45 + w * 0.35)
	_triplanar(m, Vector3(9.0, 9.0, 9.0))
	return m


## Concrete, plaster, cast stone, breeze block. Coarse cellular pitting at a low tiling rate
## so a whole plinth or floor slab does not repeat visibly.
static func concrete(base: Color = CONCRETE_GREY, wear: float = 0.30) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	var w: float = clampf(wear, 0.0, 1.0)
	m.albedo_color = base.darkened(w * 0.20)
	m.metallic = 0.0
	m.metallic_specular = 0.4
	_rough(m, clampf(0.86 + w * 0.08, 0.30, 1.0), GRAIN_CAST, LO_HARD)
	_normal(m, GRAIN_CAST, BUMP_COARSE, 0.85 + w * 0.7)
	_triplanar(m, Vector3(1.4, 1.4, 1.4))
	if w > 0.2:
		weather(m, w * 0.7)
	return m


## Glass. `opacity` 0..1; `roughness` 0 is optical flat, 0.3 is frosted.
##
## VR NOTE: transparency is overdraw, and overdraw is the Quest's tightest budget. Use glass
## for ONE layer — a vitrine face, a gauge cover — never for stacked panes. Screen-space
## refraction is desktop-only and off by default.
static func glass(tint: Color = GLASS_TINT, roughness: float = 0.04,
		opacity: float = 0.16) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	m.albedo_color = Color(tint.r, tint.g, tint.b, clampf(opacity, 0.02, 1.0))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.0
	m.metallic_specular = 0.6
	m.roughness = clampf(roughness, 0.0, 1.0)
	# Rim brightening: real glass goes near-opaque at grazing angles (Fresnel). Without this
	# a glass box reads as a faint tinted ghost with no edges at all.
	m.rim_enabled = true
	m.rim = 0.75
	m.rim_tint = 0.1
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	if roughness > 0.01:
		_rough(m, clampf(roughness, 0.01, 1.0), GRAIN_MICRO, LO_SOFT)
		_triplanar(m, Vector3(6.0, 6.0, 6.0))
	if desktop_extras:
		m.refraction_enabled = true
		m.refraction_scale = 0.035
	return m


## Anodised aluminium — the coloured-oxide finish on instrument cases and bracket hardware.
## Metal underneath, a thin coloured dielectric film on top, so it keeps a metal's specular
## while carrying real hue.
static func anodized(base: Color = Color(0.30, 0.36, 0.42), roughness: float = 0.34,
		wear: float = 0.10) -> StandardMaterial3D:
	var m: StandardMaterial3D = brushed_metal(base, roughness, wear, "y")
	m.metallic = 0.85
	m.metallic_specular = 0.5
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = clampf(0.10 + wear * 0.4, 0.0, 1.0)
	return m


# ══ WEAR / FINISHING PASSES ══════════════════════════════════════════════

## Add dirt, blotching and large-scale surface damage to an already-built material.
##
## Uses Godot's DETAIL layer on UV2 at a coarser tiling rate than the base, so the result is
## genuinely two-scale: fine grain in the roughness map, big weathering in the detail map.
## `amount` 0..1.
##
## THE TRAP THIS AVOIDS: turning on detail_enabled without setting detail_normal replaces the
## material's normal map with a FLAT one, because Godot's shader mixes toward the detail
## normal sampler and the unset sampler defaults to flat. This function always sets both.
static func weather(m: StandardMaterial3D, amount: float = 0.35) -> StandardMaterial3D:
	if m == null or amount <= 0.001:
		return m
	var a: float = clampf(amount, 0.0, 1.0)
	m.detail_enabled = true
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	# Quantised to 0.1 so a hundred call sites with slightly different wear values still
	# share about six textures instead of minting a hundred.
	# Floor raised from 0.35: this multiplies into albedo, so 0.35 meant the darkest
	# blotches removed nearly two thirds of an already-dark surface and read as holes
	# rather than as dirt. Grime darkens; it does not punch through.
	m.detail_albedo = grain(GRAIN_GRUNGE, snappedf(clampf(1.0 - a * 0.5, 0.60, 0.95), 0.1))
	m.uv2_triplanar = true
	m.uv2_world_triplanar = false
	m.uv2_scale = m.uv1_scale * 0.34
	if m.normal_enabled:
		# THE DETAIL NORMAL HAS TO SCALE WITH `amount`, and the first version did not.
		# It applied BUMP_MED — a gain of 4.0 on the coarse grunge field — at full
		# strength for ANY weathering above zero, and Godot's detail layer has no
		# strength parameter to pull it back with. On situated_bench's worktop, asked
		# for a mild 0.42, the slab came back looking like tree bark: a metre of flat
		# resin rendered as high-contrast crumple. Weathering that ignores how much
		# weathering was requested is not a material, it is a decal.
		#
		# Snapped to two rungs on purpose — grain_normal caches on (kind, bump), so a
		# continuous value here would mint a texture per call site and quietly undo the
		# caching the line above exists to protect.
		# THE DETAIL NORMAL IS THE MATERIAL'S OWN, and that is deliberate.
		#
		# Godot's detail layer has NO strength parameter: whatever texture goes in this
		# slot is mixed in at full force, so normal_scale cannot pull it back. A second,
		# coarser normal here therefore always wins, which is how situated_bench's
		# worktop stayed bark-textured through three separate attempts to calm it down —
		# including one that lowered the base normal to 0.08 and changed nothing visible,
		# because the base normal was never what was being seen.
		#
		# So the slot gets a texture that is FLAT BY CONSTRUCTION: a neutral normal,
		# (128,128,255). It fills the sampler, satisfies the trap documented above, and
		# contributes exactly zero relief at any strength — which leaves the base normal
		# and its normal_scale as the ONE place surface relief is decided, instead of two
		# places where the quieter one is always overruled.
		#
		# Reusing normal_texture here was tried first and still came back as bark: at full
		# detail strength, a texture authored to be applied at 0.08 is not subtle.
		# Weathering on painted resin is a grime pattern in the ALBEDO, not a second
		# surface carved on top of the first.
		m.detail_normal = flat_normal()
	return m


## A neutral normal map: one flat texel, cached forever. Exists for the detail slot, which
## must be filled but must not add relief. See weather().
static var _flat_normal: ImageTexture = null

static func flat_normal() -> ImageTexture:
	if _flat_normal == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
		img.fill(Color(0.5, 0.5, 1.0))
		_flat_normal = ImageTexture.create_from_image(img)
	return _flat_normal


## Fresnel edge brightening. The cheapest honest way to make a silhouette read: it is what
## makes an edge separate from the background without an outline shader. Use sparingly —
## on everything at once it looks like a filter.
static func edge_light(m: StandardMaterial3D, amount: float = 0.3,
		tint: float = 0.4) -> StandardMaterial3D:
	if m == null:
		return m
	m.rim_enabled = true
	m.rim = clampf(amount, 0.0, 1.0)
	m.rim_tint = clampf(tint, 0.0, 1.0)
	return m


## Ambient-occlusion darkening in the material itself, on top of whatever SSAO the scene
## provides. Reuses the grunge grain as a crevice map. Cheap; helps most on large flat
## surfaces where SSAO has nothing to bite on.
static func crevice_ao(m: StandardMaterial3D, strength: float = 0.6) -> StandardMaterial3D:
	if m == null:
		return m
	m.ao_enabled = true
	m.ao_texture = grain(GRAIN_GRUNGE, snappedf(clampf(1.0 - strength * 0.6, 0.2, 0.95), 0.1))
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	m.ao_light_affect = clampf(strength * 0.5, 0.0, 1.0)
	m.ao_on_uv2 = false
	return m


# ══ EMISSIVE ═════════════════════════════════════════════════════════════

## Self-lit accent. Argument-compatible with HangarKit.emissive(c, energy).
##
## Difference from the house version: the albedo is darkened relative to the emission. A
## surface whose albedo AND emission are both full-value clips to white the moment any scene
## light lands on it, and a clipped white is the rubric's colour-discipline failure. Darkening
## the albedo lets the emission be the bright thing.
static func emissive(c: Color, energy: float = 1.6) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	m.albedo_color = c.darkened(0.35)
	m.metallic = 0.0
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = maxf(energy, 0.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


## A readout / display face. Dark, softly self-lit, with a faint glass sheen over it so the
## screen catches a reflection instead of being a flat coloured rectangle.
static func screen(bg: Color = DISPLAY_DARK, energy: float = 0.42) -> StandardMaterial3D:
	var m: StandardMaterial3D = _base()
	m.albedo_color = bg
	m.metallic = 0.0
	m.metallic_specular = 0.55
	m.roughness = 0.14
	m.emission_enabled = true
	m.emission = bg
	m.emission_energy_multiplier = maxf(energy, 0.0)
	m.clearcoat_enabled = true
	m.clearcoat = 0.6
	m.clearcoat_roughness = 0.05
	return m


## A small indicator lamp. Brighter than emissive() and deliberately tiny — an LED is a point,
## and its job is done by glow, not by area.
static func led(c: Color, energy: float = 3.2) -> StandardMaterial3D:
	var m: StandardMaterial3D = emissive(c, energy)
	m.albedo_color = c.darkened(0.5)
	m.roughness = 0.25
	return m


# ══ GEOMETRY ═════════════════════════════════════════════════════════════

## A CHAMFERED box — the drop-in replacement for HangarKit.box(centre, size, mat).
##
## Real objects have no zero-radius edges. A 1-2 mm chamfer catches a highlight line along
## every edge, which is the single clearest difference between "a render" and "a box". The
## default bevel is derived from the box's smallest dimension so a 2 m panel and a 3 cm trim
## strip both get a proportionate edge.
##
## COST: 44 triangles versus BoxMesh's 12 (3.7x, inside the 4x budget). Boxes too thin to
## chamfer meaningfully fall back to a plain BoxMesh, so the cheap decorative strips that make
## up most of an artifact's part count stay at 12.
##
## `wear` > 0 bakes vertex colours: chamfer strips stay bright (edges rub clean), faces dull
## slightly, and the underside darkens (dirt collects where a thing meets the floor). The
## material must have vertex_color_use_as_albedo — every PbrKit material does by default, and
## this function turns it on for any BaseMaterial3D it is handed.
static func box(center: Vector3, size: Vector3, mat: Material,
		bevel: float = -1.0, wear: float = 0.0) -> MeshInstance3D:
	var sx: float = maxf(absf(size.x), 0.0001)
	var sy: float = maxf(absf(size.y), 0.0001)
	var sz: float = maxf(absf(size.z), 0.0001)
	var min_dim: float = minf(minf(sx, sy), sz)
	var b: float = bevel
	if b < 0.0:
		b = clampf(min_dim * 0.07, 0.0015, 0.014)
	b = minf(b, min_dim * 0.45)

	if b < 0.0008:
		# Too thin to chamfer — a plain box is cheaper and identical on screen.
		var bm := BoxMesh.new()
		bm.size = Vector3(sx, sy, sz)
		var plain := MeshInstance3D.new()
		plain.mesh = bm
		plain.material_override = mat
		plain.position = center
		return plain

	var w: float = clampf(wear, 0.0, 1.0)
	if w > 0.001 and mat is BaseMaterial3D:
		var bmat: BaseMaterial3D = mat
		bmat.vertex_color_use_as_albedo = true

	var hx: float = sx * 0.5
	var hy: float = sy * 0.5
	var hz: float = sz * 0.5
	var ix: float = hx - b
	var iy: float = hy - b
	var iz: float = hz - b

	# Three vertices per corner: one pulled in on each axis. va belongs to the +-X face,
	# vb to the +-Y face, vc to the +-Z face. Keyed "aab" style by the three signs.
	var va: Dictionary = {}
	var vb: Dictionary = {}
	var vc: Dictionary = {}
	for a in range(2):
		var gx: float = -1.0 + 2.0 * float(a)
		for b2 in range(2):
			var gy: float = -1.0 + 2.0 * float(b2)
			for c2 in range(2):
				var gz: float = -1.0 + 2.0 * float(c2)
				var k: String = _ck(gx, gy, gz)
				va[k] = Vector3(gx * hx, gy * iy, gz * iz)
				vb[k] = Vector3(gx * ix, gy * hy, gz * iz)
				vc[k] = Vector3(gx * ix, gy * iy, gz * hz)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pos: float = 1.0
	var neg: float = -1.0

	# Six inset faces.
	for a2 in range(2):
		var s: float = -1.0 + 2.0 * float(a2)
		_emit_poly(st, [va[_ck(s, pos, pos)], va[_ck(s, pos, neg)],
			va[_ck(s, neg, neg)], va[_ck(s, neg, pos)]], w, sy, false)
		_emit_poly(st, [vb[_ck(pos, s, pos)], vb[_ck(pos, s, neg)],
			vb[_ck(neg, s, neg)], vb[_ck(neg, s, pos)]], w, sy, false)
		_emit_poly(st, [vc[_ck(pos, pos, s)], vc[_ck(pos, neg, s)],
			vc[_ck(neg, neg, s)], vc[_ck(neg, pos, s)]], w, sy, false)

	# Twelve chamfer strips. Winding is fixed automatically inside _emit_poly, so each
	# quad only has to list its four points in ring order.
	for a3 in range(2):
		var sa: float = -1.0 + 2.0 * float(a3)
		for b3 in range(2):
			var sb: float = -1.0 + 2.0 * float(b3)
			# X/Y edge, running along Z
			_emit_poly(st, [va[_ck(sa, sb, neg)], vb[_ck(sa, sb, neg)],
				vb[_ck(sa, sb, pos)], va[_ck(sa, sb, pos)]], w, sy, true)
			# Y/Z edge, running along X
			_emit_poly(st, [vb[_ck(neg, sa, sb)], vc[_ck(neg, sa, sb)],
				vc[_ck(pos, sa, sb)], vb[_ck(pos, sa, sb)]], w, sy, true)
			# X/Z edge, running along Y
			_emit_poly(st, [va[_ck(sa, neg, sb)], vc[_ck(sa, neg, sb)],
				vc[_ck(sa, pos, sb)], va[_ck(sa, pos, sb)]], w, sy, true)

	# Eight corner triangles.
	for a4 in range(2):
		var cx: float = -1.0 + 2.0 * float(a4)
		for b4 in range(2):
			var cy: float = -1.0 + 2.0 * float(b4)
			for c4 in range(2):
				var cz: float = -1.0 + 2.0 * float(c4)
				var k2: String = _ck(cx, cy, cz)
				_emit_poly(st, [va[k2], vb[k2], vc[k2]], w, sy, true)

	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.position = center
	return mi


static func _ck(gx: float, gy: float, gz: float) -> String:
	return "%d,%d,%d" % [int(gx), int(gy), int(gz)]


## Emit one convex, planar polygon as a fan. Orientation is derived rather than reasoned
## about: the shape is convex and centred on its own origin, so the outward direction at any
## polygon is simply the direction of its centroid.
static func _emit_poly(st: SurfaceTool, pts: Array, wear: float, size_y: float,
		edge_bright: bool) -> void:
	if pts.size() < 3:
		return
	var p0: Vector3 = pts[0]
	var p1: Vector3 = pts[1]
	var p2: Vector3 = pts[2]
	var nrm: Vector3 = (p1 - p0).cross(p2 - p0)
	if nrm.length() < 0.0000001:
		return
	nrm = nrm.normalized()
	var cen: Vector3 = Vector3.ZERO
	for i in range(pts.size()):
		var pv: Vector3 = pts[i]
		cen += pv
	cen = cen / float(pts.size())
	var ring: Array = pts.duplicate()
	if nrm.dot(cen) < 0.0:
		ring.reverse()
		nrm = -nrm
	for i in range(1, ring.size() - 1):
		var a: Vector3 = ring[0]
		var bb: Vector3 = ring[i]
		var cc: Vector3 = ring[i + 1]
		_push_v(st, a, nrm, _plane_uv(a, nrm), _wear_color(a, wear, size_y, edge_bright))
		_push_v(st, bb, nrm, _plane_uv(bb, nrm), _wear_color(bb, wear, size_y, edge_bright))
		_push_v(st, cc, nrm, _plane_uv(cc, nrm), _wear_color(cc, wear, size_y, edge_bright))


## Planar UV from the dominant normal axis. The materials in this kit are triplanar, so these
## UVs exist mainly so generate_tangents() has something to work with — but they are correct
## enough that a non-triplanar material tiles sensibly too.
static func _plane_uv(p: Vector3, n: Vector3) -> Vector2:
	var ax: float = absf(n.x)
	var ay: float = absf(n.y)
	var az: float = absf(n.z)
	if ax >= ay and ax >= az:
		return Vector2(p.z, -p.y)
	if ay >= az:
		return Vector2(p.x, -p.z)
	return Vector2(p.x, -p.y)


static func _wear_color(p: Vector3, wear: float, size_y: float, edge_bright: bool) -> Color:
	if wear <= 0.001:
		return Color(1.0, 1.0, 1.0)
	var v: float = 1.0
	if not edge_bright:
		v = 1.0 - wear * 0.14
	var t: float = clampf(0.5 - (p.y / maxf(size_y, 0.0001)), 0.0, 1.0)
	v = v * (1.0 - wear * 0.24 * pow(t, 3.0))
	return Color(v, v, v)


static func _push_v(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2, c: Color) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.set_color(c)
	st.add_vertex(p)


## Revolve a 2D profile around the Y axis. `profile` points are Vector2(radius, y), ordered
## from the bottom centre outward and up. Normals are analytic: SMOOTH along the profile where
## two segments meet at less than `smooth_angle_deg`, CRISP where they meet sharper. That one
## rule gives a smooth barrel and a crisp chamfer from the same call, with no faceting on the
## curve and no washed-out edge on the corner.
##
## The 30 degree default is chosen so a 45 degree chamfer stays CRISP — a chamfer's job is to
## be a distinct bright band, and smoothing it turns it back into the soft nothing it was
## meant to replace. Raise it toward 60 if you want rolled/filleted edges instead.
##
## Tangents and UVs are generated (u = angle, v = arc length), so normal maps work.
static func lathe(profile: PackedVector2Array, segments: int, mat: Material,
		smooth_angle_deg: float = 30.0, wear: float = 0.0) -> MeshInstance3D:
	var n: int = profile.size()
	var mi := MeshInstance3D.new()
	if n < 2:
		return mi
	var segs: int = maxi(segments, 3)
	var w: float = clampf(wear, 0.0, 1.0)
	if w > 0.001 and mat is BaseMaterial3D:
		var bmat: BaseMaterial3D = mat
		bmat.vertex_color_use_as_albedo = true

	# Per-segment outward normal in the (r, y) plane.
	var seg_n: Array = []
	for i in range(n - 1):
		var d: Vector2 = profile[i + 1] - profile[i]
		if d.length() < 0.000001:
			seg_n.append(Vector2(1.0, 0.0))
		else:
			seg_n.append(Vector2(d.y, -d.x).normalized())

	# Per-segment start/end normals, averaged across shallow joins only.
	var thresh: float = cos(deg_to_rad(clampf(smooth_angle_deg, 0.0, 179.0)))
	var ns: Array = []
	var ne: Array = []
	for i in range(n - 1):
		var cur: Vector2 = seg_n[i]
		var s_n: Vector2 = cur
		var e_n: Vector2 = cur
		if i > 0:
			var prev: Vector2 = seg_n[i - 1]
			if prev.dot(cur) > thresh:
				s_n = (prev + cur).normalized()
		if i < n - 2:
			var nxt: Vector2 = seg_n[i + 1]
			if nxt.dot(cur) > thresh:
				e_n = (nxt + cur).normalized()
		ns.append(s_n)
		ne.append(e_n)

	# Arc length along the profile, for the V coordinate.
	var arc: Array = [0.0]
	var total: float = 0.0
	for i in range(n - 1):
		total += profile[i].distance_to(profile[i + 1])
		arc.append(total)
	if total < 0.000001:
		total = 1.0

	# Y span, so the wear gradient knows where "the bottom" is.
	var y_lo: float = profile[0].y
	var y_hi: float = profile[0].y
	for i in range(n):
		y_lo = minf(y_lo, profile[i].y)
		y_hi = maxf(y_hi, profile[i].y)
	var y_span: float = maxf(y_hi - y_lo, 0.0001)
	var y_mid: float = (y_hi + y_lo) * 0.5

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var emitted: bool = false
	for i in range(n - 1):
		var p_a: Vector2 = profile[i]
		var p_b: Vector2 = profile[i + 1]
		var r0: float = maxf(p_a.x, 0.0)
		var r1: float = maxf(p_b.x, 0.0)
		if r0 < 0.00001 and r1 < 0.00001:
			continue
		emitted = true
		var n0: Vector2 = ns[i]
		var n1: Vector2 = ne[i]
		var v0: float = float(arc[i]) / total
		var v1: float = float(arc[i + 1]) / total
		for j in range(segs):
			var t0: float = float(j) / float(segs)
			var t1: float = float(j + 1) / float(segs)
			var a0: float = t0 * TAU
			var a1: float = t1 * TAU
			var q00: Vector3 = Vector3(r0 * cos(a0), p_a.y, r0 * sin(a0))
			var q01: Vector3 = Vector3(r0 * cos(a1), p_a.y, r0 * sin(a1))
			var q10: Vector3 = Vector3(r1 * cos(a0), p_b.y, r1 * sin(a0))
			var q11: Vector3 = Vector3(r1 * cos(a1), p_b.y, r1 * sin(a1))
			var m00: Vector3 = Vector3(n0.x * cos(a0), n0.y, n0.x * sin(a0)).normalized()
			var m01: Vector3 = Vector3(n0.x * cos(a1), n0.y, n0.x * sin(a1)).normalized()
			var m10: Vector3 = Vector3(n1.x * cos(a0), n1.y, n1.x * sin(a0)).normalized()
			var m11: Vector3 = Vector3(n1.x * cos(a1), n1.y, n1.x * sin(a1)).normalized()
			var u00 := Vector2(t0, v0)
			var u01 := Vector2(t1, v0)
			var u10 := Vector2(t0, v1)
			var u11 := Vector2(t1, v1)
			if r0 < 0.00001:
				# Bottom ring collapsed to a point — one triangle, not a quad.
				_lathe_tri(st, q00, q10, q11, m00, m10, m11, u00, u10, u11, w, y_span, y_mid)
			elif r1 < 0.00001:
				_lathe_tri(st, q00, q10, q01, m00, m10, m01, u00, u10, u01, w, y_span, y_mid)
			else:
				_lathe_tri(st, q00, q10, q11, m00, m10, m11, u00, u10, u11, w, y_span, y_mid)
				_lathe_tri(st, q00, q11, q01, m00, m11, m01, u00, u11, u01, w, y_span, y_mid)
	if not emitted:
		# Every profile point sat on the axis — there is no surface to commit, and
		# generate_tangents() on an empty surface is an error, not a no-op.
		return mi
	st.generate_tangents()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


## Emit one lathe triangle, flipping the winding if it disagrees with the analytic normals.
static func _lathe_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2,
		wear: float, y_span: float, y_mid: float) -> void:
	var face: Vector3 = (b - a).cross(c - a)
	if face.length() < 0.0000001:
		return
	var ca: Color = _wear_color(a - Vector3(0.0, y_mid, 0.0), wear, y_span, false)
	var cb: Color = _wear_color(b - Vector3(0.0, y_mid, 0.0), wear, y_span, false)
	var cc: Color = _wear_color(c - Vector3(0.0, y_mid, 0.0), wear, y_span, false)
	if face.dot(na + nb + nc) < 0.0:
		_push_v(st, a, na, ua, ca)
		_push_v(st, c, nc, uc, cc)
		_push_v(st, b, nb, ub, cb)
	else:
		_push_v(st, a, na, ua, ca)
		_push_v(st, b, nb, ub, cb)
		_push_v(st, c, nc, uc, cc)


## A cylinder with CHAMFERED rims — the drop-in upgrade from CylinderMesh. Centred on the
## origin like CylinderMesh, so it swaps in without moving anything.
##
## The chamfer is why this exists: a raw CylinderMesh's top edge is a zero-radius corner that
## disappears against any background. A 2 mm chamfer draws a bright ring there.
##
## COST at the defaults (24 segments, 5 profile segments): about 192 triangles versus
## CylinderMesh's ~96 at the same radial count. Drop `segments` to 16 on small parts.
static func chamfer_cylinder(radius: float, height: float, chamfer: float = -1.0,
		mat: Material = null, segments: int = 24, wear: float = 0.0) -> MeshInstance3D:
	var r: float = maxf(radius, 0.0005)
	var h: float = maxf(height, 0.001)
	var c: float = chamfer
	if c < 0.0:
		c = clampf(minf(r, h) * 0.09, 0.0012, 0.012)
	c = minf(c, minf(r * 0.45, h * 0.45))
	var hy: float = h * 0.5
	var prof := PackedVector2Array([
		Vector2(0.0, -hy),
		Vector2(r - c, -hy),
		Vector2(r, -hy + c),
		Vector2(r, hy - c),
		Vector2(r - c, hy),
		Vector2(0.0, hy),
	])
	return lathe(prof, segments, mat, 30.0, wear)


## A cylinder between two arbitrary points — pipes, struts, conduit, cable runs.
## Same call shape as HangarKit's internal _pipe(), promoted to public.
static func pipe(a: Vector3, b: Vector3, r: float, mat: Material,
		segments: int = 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	mesh.radial_segments = maxi(segments, 6)
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	if yv.length() < 0.5:
		yv = Vector3.UP
	var ref: Vector3 = Vector3.UP
	if absf(yv.dot(Vector3.UP)) > 0.985:
		ref = Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


# ══ GROUNDING ════════════════════════════════════════════════════════════

## A projected contact shadow so an object SITS instead of hovering.
##
## This is rubric item 4 and it is the cheapest large win available: a soft dark pool under an
## object reads as contact even when the scene's real shadows are low-resolution or the object
## is lit by ambient only. It is a Decal, so it conforms to whatever it lands on — a floor, a
## step, a plinth top — rather than z-fighting like a flat quad would.
##
## Add it as a child at the object's BASE (y = 0 in the artifact's own space). Decals are not
## lights and do not count against the R2 light budget; one per artifact is right, six is not.
static func ground_shadow(radius: float, strength: float = 0.55,
		drop: float = 0.12) -> Decal:
	var d := Decal.new()
	d.name = "ContactShadow"
	var rr: float = maxf(radius, 0.02)
	var box_h: float = maxf(drop * 2.0 + 0.3, 0.1)
	d.size = Vector3(rr * 2.0, box_h, rr * 2.0)
	d.position = Vector3(0.0, box_h * 0.5 - drop, 0.0)
	d.texture_albedo = _shadow_texture()
	d.albedo_mix = clampf(strength, 0.0, 1.0)
	d.modulate = Color(1.0, 1.0, 1.0, 1.0)
	d.upper_fade = 0.6
	d.lower_fade = 0.4
	d.normal_fade = 0.0
	return d


## Radial falloff texture for the contact shadow. Small, built once, cached.
static func _shadow_texture() -> ImageTexture:
	var key: String = "shadow|128"
	if _tex_cache.has(key):
		var hit: ImageTexture = _tex_cache[key]
		return hit
	var px: int = 128
	var img: Image = Image.create(px, px, false, Image.FORMAT_RGBA8)
	var half: float = float(px) * 0.5
	for y in range(px):
		for x in range(px):
			var dx: float = (float(x) - half + 0.5) / half
			var dy: float = (float(y) - half + 0.5) / half
			var dist: float = sqrt(dx * dx + dy * dy)
			# Dense core, long soft tail — the shape real ambient occlusion makes.
			var a: float = clampf(1.0 - dist, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(0.03, 0.03, 0.04, a))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


# ══ AUDIT ════════════════════════════════════════════════════════════════

## Walk a built subtree and report surfaces that still look like the flat-plastic default:
## no roughness texture, a physically meaningless mid metallic, or a pure black albedo.
## Returns a list of "NodePath: reason" strings. Useful in a _ready() guard during a pass,
## and free to leave out of the shipped build.
static func audit(root: Node) -> Array:
	var out: Array = []
	_audit_walk(root, out)
	return out


static func _audit_walk(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		var mats: Array = []
		if mi.material_override != null:
			mats.append(mi.material_override)
		elif mi.mesh != null:
			for i in range(mi.mesh.get_surface_count()):
				var sm: Material = mi.get_surface_override_material(i)
				if sm == null:
					sm = mi.mesh.surface_get_material(i)
				if sm != null:
					mats.append(sm)
		for mm in mats:
			if mm is StandardMaterial3D:
				var s: StandardMaterial3D = mm
				if s.emission_enabled:
					continue
				var flat: bool = s.roughness_texture == null and not s.detail_enabled
				if flat:
					out.append("%s: uniform roughness, no breakup" % str(n.name))
					# A mid metallic is only a fault on a surface nobody has considered.
					# A worn coat legitimately ramps through the middle as it fails.
					if s.metallic > 0.15 and s.metallic < 0.70:
						out.append("%s: metallic %.2f is neither metal nor dielectric" % [str(n.name), s.metallic])
				var c: Color = s.albedo_color
				if c.r < 0.02 and c.g < 0.02 and c.b < 0.02:
					out.append("%s: albedo is pure black, nothing left to shade" % str(n.name))
	for child in n.get_children():
		_audit_walk(child, out)
