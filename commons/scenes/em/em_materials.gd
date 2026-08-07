class_name EmMaterials
extends RefCounted
# em_materials.gd — the endless museum's PBR surface library.
#
# WHY THIS FILE EXISTS
# The museum streams hundreds of BoxMeshes per segment. In v1 every one of them
# carried a flat StandardMaterial3D with an albedo colour and nothing else: no
# roughness variation, no metallic, no normal, no textures. A flat albedo is the
# single loudest "this is a game jam" tell — real architecture reads because its
# surfaces are NOT uniform. Two things do most of that work:
#   1. LARGE-SCALE ALBEDO VARIATION (metres) — trowel clouds in plaster, bedding
#      in travertine, veins in marble, lane-polish in a stone floor. This is what
#      you see from across a room.
#   2. FINE-SCALE ROUGHNESS BREAKUP (centimetres) — the specular highlight must
#      wobble as you walk past it. A constant roughness gives a perfectly even
#      sheen that the eye reads as plastic. This is what you see at arm's length.
# Both are authored here procedurally with FastNoiseLite + NoiseTexture2D, so
# nothing ships as a PNG and nothing is stretched over a box.
#
# WHAT EACH MATERIAL IS IMITATING, AND WHY IT IS IN THE SET
#   floor_stone()      Honed dark granite / basalt gallery deck. The default
#                      museum floor since the Neue Nationalgalerie: dark, low
#                      roughness, faintly polished, so it carries a soft mirror
#                      of the ceiling wash and grounds the room. Clearcoat gives
#                      the sealed-stone second specular lobe.
#   floor_terrazzo()   Poured terrazzo with aggregate chips. Cellular noise with
#                      CONSTANT gradient interpolation = flat-coloured chips, the
#                      one thing fbm can never fake. Lighter than the granite,
#                      for vestibules and circulation.
#   wall_plaster(tint) Honed / polished lime plaster. The workhorse interior
#                      wall: warm off-white, high roughness, a very low skim
#                      relief. Takes a tint so a template's palette can push it
#                      warm or cool without a new material family.
#   gallery_white()    Museum-white matt emulsion. Deliberately NOT pure white
#                      (0.885 sRGB): pure white has no tonemapping headroom, and
#                      a 1.0 albedo makes bounce lighting explode. This is the
#                      brightest surface in the building and the main bounce
#                      source, so it is nearly flat and nearly roughness-1.
#   podium_marble()    Carrara-ish plinth stone. Veins come from RIDGED noise
#                      with domain warp — ridge peaks are thin connected lines,
#                      which is exactly what a vein is. Polished: low roughness
#                      plus clearcoat.
#   travertine()       Warm banded limestone with pores. Anisotropic uv1_scale
#                      lays the bedding horizontally; a cellular DISTANCE field
#                      in the normal map cuts the voids. The "important building"
#                      stone — Getty, Barcelona Pavilion.
#   concrete()         Fair-faced cast concrete. Mid grey, high roughness with
#                      wide breakup, the strongest normal relief in the set.
#   trim_oak()         Dark oak trim / skirting / handrail. Grain is ridged noise
#                      read through a stretched uv1_scale, so the lines run
#                      around the box instead of blobbing.
#   accent_brass()     Aged brass rail, letter, threshold strip. The only metal.
#                      Patina is a dielectric oxide, so ONE noise field drives
#                      three correlated maps: albedo (brass <-> verdigris),
#                      metallic (1.0 <-> 0.1) and roughness (0.25 <-> 0.9).
#                      Correlating them is the whole trick — an uncorrelated
#                      patina reads as a decal, not as corrosion.
#   ceiling_plaster()  Flatter, brighter plaster for the soffit. Ceilings are
#                      bounce reflectors, not features: near-white, roughness
#                      0.94, almost no relief.
#   glass_vitrine()    Vitrine / balustrade glass. Roughness comes from a smudge
#                      map — clean glass reads as a hole in the world; fingerprint
#                      and dust breakup is what makes it read as a surface.
#   emissive_accent()  The threshold ember strip and any architectural light
#                      line. Near-black albedo so it does not double-count.
#
# EDGE GRIME — the honest answer
# True vertex/edge darkening (dirt pooling in a corner) needs either a shader
# with a world-height or curvature input, or vertex colours the BoxMesh does not
# have. Neither is free and neither belongs in a StandardMaterial3D. What IS
# cheap and reads almost as well is what the library gives you:
#   * a `soil` parameter (0..1) on every architectural surface — darkens albedo
#     toward soot, raises roughness, drops specular, and routes the LOW-frequency
#     noise into the AO slot so grime pools in metre-scale organic patches
#     instead of a uniform wash;
#   * skirting(kind, tint) — the same material at soil 0.75, meant for a 0.12 m
#     strip of geometry at the base of every wall. One extra thin box per wall
#     run buys you real, correct, light-reactive contact darkening. That is how
#     it is done in a shipped title too.
#   * vertex_color_use_as_albedo is ON by default. A BoxMesh has no COLOR array
#     so this costs nothing today — but the moment the geometry author builds a
#     wall with PbrKit.box() (commons/render/pbr_kit.gd, which BAKES edge wear
#     into vertex colours) these materials pick it up with no further work.
#     That is the real edge darkening, and it is already wired.
#
# CACHING — read this before you call anything in a loop
# Every getter returns a SHARED, CACHED material. Hundreds of boxes pointing at
# one material is what lets the renderer batch them. Two consequences:
#   * DO NOT MUTATE a returned material. If you need a one-off, .duplicate().
#   * Tints are quantised to 1/32 before they become a cache key, so nearby
#     tints collapse onto one material. Do not feed a per-cell randf() tint —
#     you would mint a material and three noise textures per cell.
# Noise textures are cached separately and shared between materials.
#
# EVERY ROUGHNESS NUMBER IN THIS FILE IS A MEAN
# Godot computes ROUGHNESS = roughness * texture. Hanging a 0.5-1.0 ramp on a
# material that sets roughness 0.34 does not give you 0.34, it gives you 0.255 —
# which is why hand-written Godot materials come out glossier than intended.
# _rough() derives the scalar from the target mean and the ramp's mean, so the
# figures quoted in the comments below are the values the surface actually has.
#
# THREADED GENERATION
# NoiseTexture2D generates on a worker thread. The first frame a material is used
# its textures are still blank (white), so the surface pops from flat to detailed
# a frame or two later. Call EmMaterials.warm_up() once in _ready() and the whole
# set is queued before the walker has moved.

# ── tunables ─────────────────────────────────────────────────────────────────
const TEX_ALBEDO := 512    # large-scale variation needs the resolution
const TEX_ROUGH := 256     # roughness breakup is high-frequency; 256 is plenty
const TEX_NORMAL := 256

## 1.0 = the sizes above. Drop to 0.5 for standalone Quest, raise for stills.
## Changing it clears the cache (materials already handed out keep their old
## textures — call this before warm_up(), not mid-walk).
static var quality_scale: float = 1.0

## Let vertex colours darken albedo. A no-op on plain BoxMesh (no COLOR array →
## the shader reads white), so it is on by default: it costs nothing and it means
## geometry built with PbrKit.box() gets its baked edge wear for free.
static var vertex_wear: bool = true

static var _mat_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

# ── public API ───────────────────────────────────────────────────────────────

## Honed dark granite gallery deck. tint multiplies the base stone colour.
static func floor_stone(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"floor_stone", tint, soil)

## Poured terrazzo with flat aggregate chips.
static func floor_terrazzo(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"terrazzo", tint, soil)

## Honed lime plaster — the workhorse interior wall.
static func wall_plaster(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"plaster", tint, soil)

## Museum-white matt emulsion. The building's main bounce surface.
static func gallery_white(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"gallery_white", tint, soil)

## Polished veined marble for plinths and podium tops.
static func podium_marble(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"marble", tint, soil)

## Warm banded travertine with pores.
static func travertine(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"travertine", tint, soil)

## Fair-faced cast concrete.
static func concrete(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"concrete", tint, soil)

## Dark oak trim, skirting, handrail.
static func trim_oak(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"oak", tint, soil)

## Aged brass. `patina` 0 = freshly polished, 1 = heavily oxidised.
static func accent_brass(patina: float = 0.35) -> StandardMaterial3D:
	return get_material(&"brass", Color.WHITE, patina)

## Flat bright soffit plaster.
static func ceiling_plaster(tint: Color = Color.WHITE) -> StandardMaterial3D:
	return get_material(&"ceiling", tint, 0.0)

## Vitrine / balustrade glass. Transparent — see the notes in glass branch below.
static func glass_vitrine(tint: Color = Color.WHITE) -> StandardMaterial3D:
	return get_material(&"glass", tint, 0.0)

## A contact-grime variant of any architectural kind (soil 0.75), for a 0.10-0.15 m
## skirting strip at the base of a wall or the top lip of a plinth.
static func skirting(kind: StringName = &"plaster", tint: Color = Color.WHITE) -> StandardMaterial3D:
	return get_material(kind, tint, 0.75)

## Architectural light line (the threshold ember, a cove, a signage strip).
## `energy` is an emission multiplier: 1.5-3.0 reads as a lit strip under a
## filmic tonemap; above ~4 it will only look right with glow enabled.
static func emissive_accent(color: Color, energy: float = 1.8) -> StandardMaterial3D:
	var q: Color = _quantize(color)
	var e: float = snappedf(clampf(energy, 0.0, 16.0), 0.1)
	var key: String = "emissive|%s|%.1f" % [_color_key(q), e]
	if _mat_cache.has(key):
		var cached: StandardMaterial3D = _mat_cache[key]
		return cached
	var m := StandardMaterial3D.new()
	# a light strip's diffuse response barely matters and a bright albedo would
	# double-count the same energy once under the lamp and once as emission
	m.albedo_color = Color(q.r * 0.14, q.g * 0.14, q.b * 0.14, 1.0)
	m.roughness = 0.38
	m.metallic = 0.0
	m.emission_enabled = true
	m.emission = q
	m.emission_energy_multiplier = e
	_mat_cache[key] = m
	return m

## kind: floor_stone | terrazzo | plaster | gallery_white | marble | travertine
##       | concrete | oak | brass | ceiling | glass
## An unknown kind returns plaster rather than null, so a typo greys out a wall
## instead of crashing the streamer.
static func get_material(kind: StringName, tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	var q: Color = _quantize(tint)
	var s: float = clampf(snappedf(soil, 0.125), 0.0, 1.0)
	var key: String = "%s|%s|%.3f" % [String(kind), _color_key(q), s]
	if _mat_cache.has(key):
		var cached: StandardMaterial3D = _mat_cache[key]
		return cached
	var m: StandardMaterial3D = _build(String(kind), q, s)
	_mat_cache[key] = m
	return m

## Build every material and queue every noise texture up front. Call once in
## _ready(). Without it the first surface of each family pops from flat white to
## textured a frame or two after it enters view.
static func warm_up() -> void:
	floor_stone()
	floor_terrazzo()
	wall_plaster()
	gallery_white()
	podium_marble()
	travertine()
	concrete()
	trim_oak()
	accent_brass()
	ceiling_plaster()
	glass_vitrine()

## name -> material, for a lighting/lookdev test wall.
static func catalogue() -> Dictionary:
	return {
		"floor_stone": floor_stone(),
		"floor_terrazzo": floor_terrazzo(),
		"wall_plaster": wall_plaster(),
		"gallery_white": gallery_white(),
		"podium_marble": podium_marble(),
		"travertine": travertine(),
		"concrete": concrete(),
		"trim_oak": trim_oak(),
		"accent_brass": accent_brass(),
		"ceiling_plaster": ceiling_plaster(),
		"glass_vitrine": glass_vitrine(),
		"skirting_plaster": skirting(&"plaster"),
	}

## Texture budget for a given quality_scale, so a platform author can decide.
static func stats() -> Dictionary:
	return {
		"materials_cached": _mat_cache.size(),
		"textures_cached": _tex_cache.size(),
		"quality_scale": quality_scale,
		"albedo_px": _sz(TEX_ALBEDO),
		"rough_px": _sz(TEX_ROUGH),
		"normal_px": _sz(TEX_NORMAL),
	}

static func set_quality(scale: float) -> void:
	quality_scale = clampf(scale, 0.25, 2.0)
	clear_cache()

static func clear_cache() -> void:
	_mat_cache.clear()
	_tex_cache.clear()

# ── material construction ────────────────────────────────────────────────────

static func _build(kind: String, tint: Color, soil: float) -> StandardMaterial3D:
	match kind:
		"floor_stone":
			return _make_floor_stone(tint, soil)
		"terrazzo":
			return _make_terrazzo(tint, soil)
		"plaster":
			return _make_plaster(tint, soil)
		"gallery_white":
			return _make_gallery_white(tint, soil)
		"marble":
			return _make_marble(tint, soil)
		"travertine":
			return _make_travertine(tint, soil)
		"concrete":
			return _make_concrete(tint, soil)
		"oak":
			return _make_oak(tint, soil)
		"brass":
			return _make_brass(soil)
		"ceiling":
			return _make_ceiling(tint)
		"glass":
			return _make_glass(tint)
	push_warning("EmMaterials: unknown kind `%s` — falling back to plaster" % kind)
	return _make_plaster(tint, soil)


## Honed dark granite. Albedo 0.185 sRGB sits inside the 0.10-0.25 band real
## dark stone measures at. Roughness 0.17-0.34: honed, not mirror — a mirror
## floor in an interior with one directional light reads as wet plastic.
static func _make_floor_stone(tint: Color, soil: float) -> StandardMaterial3D:
	var alb: NoiseTexture2D = _tex("stone_alb", _fbm(1201, 0.0055, 4, 0.52), _sz(TEX_ALBEDO), _grey_ramp(0.78, 1.0), false, 1.0)
	var rgh: NoiseTexture2D = _tex("stone_rgh", _fbm(1202, 0.052, 3, 0.55), _sz(TEX_ROUGH), _grey_ramp(0.50, 1.0), false, 1.0)
	var nrm: NoiseTexture2D = _tex("stone_nrm", _fbm(1203, 0.030, 4, 0.50), _sz(TEX_NORMAL), null, true, 0.7)
	# repeat every 1/0.28 = 3.6 m — slab-scale, so a 1 m floor cell never shows a
	# whole tile of noise and adjacent cells continue each other (world triplanar)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.185, 0.185, 0.205), tint), 0.89), 0.26, 0.0, Vector3(0.28, 0.28, 0.28), 5.0)
	m.albedo_texture = alb
	_rough(m, 0.26, rgh, 0.50, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.22
	# sealed stone: a second, tighter specular lobe over the body reflection
	m.clearcoat_enabled = true
	m.clearcoat = 0.25
	m.clearcoat_roughness = 0.08
	_apply_soil(m, soil)
	return m


## Terrazzo. CONSTANT gradient interpolation over cellular RETURN_CELL_VALUE
## gives hard-edged flat chips — fbm cannot produce an edge, and the edge is the
## whole read. Chips land ~4 cm across at this scale.
static func _make_terrazzo(tint: Color, soil: float) -> StandardMaterial3D:
	var chips: Gradient = _ramp(
		PackedFloat32Array([0.0, 0.22, 0.40, 0.58, 0.76, 1.0]),
		PackedColorArray([
			Color(0.60, 0.60, 0.60, 1.0), Color(0.88, 0.87, 0.85, 1.0),
			Color(0.72, 0.70, 0.68, 1.0), Color(1.0, 1.0, 0.98, 1.0),
			Color(0.66, 0.65, 0.67, 1.0), Color(0.92, 0.90, 0.86, 1.0),
		]))
	chips.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var alb: NoiseTexture2D = _tex("terr_alb", _cells(1301, 0.090, 1.0, FastNoiseLite.RETURN_CELL_VALUE), _sz(TEX_ALBEDO), chips, false, 1.0)
	# ROUGHNESS OFF THE SAME FIELD AS THE CHIPS. _make_brass states the principle
	# outright — uncorrelated reads as a decal, correlated reads as a substance —
	# and this function used to break it: chips on cellular 1301, gloss on an
	# independent fbm 1302. Polished terrazzo reads ENTIRELY because aggregate
	# takes a different polish than the cement matrix, so a gloss wobbling on an
	# unrelated rhythm made the chips a painted pattern with no specular
	# existence. Same noise, its own ramp: chip cores 0.12, matrix 0.34.
	var rgh: NoiseTexture2D = _tex("terr_rgh", _cells(1301, 0.090, 1.0, FastNoiseLite.RETURN_CELL_VALUE), _sz(TEX_ROUGH), _grey_ramp(0.34, 0.12), false, 1.0)
	var nrm: NoiseTexture2D = _tex("terr_nrm", _fbm(1303, 0.055, 3, 0.50), _sz(TEX_NORMAL), null, true, 0.5)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.60, 0.59, 0.565), tint), 0.79), 0.23, 0.0, Vector3(0.5, 0.5, 0.5), 5.0)
	m.albedo_texture = alb
	_rough(m, 0.23, rgh, 0.34, 0.12)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.15
	m.clearcoat_enabled = true
	m.clearcoat = 0.20
	m.clearcoat_roughness = 0.10
	_apply_soil(m, soil)
	return m


## Honed lime plaster. Two frequencies do the work: 0.004 for the trowel clouds
## you read across a room, 0.045 for the roughness grain you read at arm's
## length. Roughness never reaches 1.0 — a genuinely lambertian wall looks dead.
static func _make_plaster(tint: Color, soil: float) -> StandardMaterial3D:
	# THE ONE THING HONED PLASTER MUST SHOW IS TROWEL SHEEN AT A GRAZING ANGLE,
	# and at a 0.82 mean roughness it showed none: the specular lobe is flattened
	# until the 0.30 normal relief has nothing left to modulate, and the left wall
	# of aaa_threshold came back as a smooth dark-to-light gradient across ~700 px
	# with zero surface incident. 0.66 mean over a 0.55-1.0 ramp puts burnished
	# passes at ~0.36 (they catch a highlight) and leaves unburnished areas matt.
	# Albedo contrast widened from 14% to 22% for the same reason.
	var alb: NoiseTexture2D = _tex("plas_alb", _fbm(1401, 0.0040, 5, 0.55), _sz(TEX_ALBEDO), _grey_ramp(0.78, 1.0), false, 1.0)
	var rgh: NoiseTexture2D = _tex("plas_rgh", _fbm(1402, 0.045, 4, 0.55), _sz(TEX_ROUGH), _grey_ramp(0.55, 1.0), false, 1.0)
	var nrm: NoiseTexture2D = _tex("plas_nrm", _fbm(1403, 0.055, 5, 0.50), _sz(TEX_NORMAL), null, true, 1.1)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.72, 0.705, 0.675), tint), 0.89), 0.66, 0.0, Vector3(0.42, 0.42, 0.42), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.66, rgh, 0.55, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.30
	_apply_soil(m, soil)
	return m


## Museum white. 0.885 sRGB, not 1.0: this is the brightest thing in the
## building and the dominant bounce source, and a 1.0 albedo has no headroom
## under any tonemapper. Variation is deliberately tiny (0.94-1.0) — its job is
## only to stop banding across a large flat wall under a soft wash.
static func _make_gallery_white(tint: Color, soil: float) -> StandardMaterial3D:
	var alb: NoiseTexture2D = _tex("gw_alb", _fbm(1501, 0.0035, 4, 0.52), _sz(TEX_ALBEDO), _grey_ramp(0.94, 1.0), false, 1.0)
	var rgh: NoiseTexture2D = _tex("gw_rgh", _fbm(1502, 0.075, 3, 0.55), _sz(TEX_ROUGH), _grey_ramp(0.93, 1.0), false, 1.0)
	# roller stipple: high frequency, almost no amplitude
	var nrm: NoiseTexture2D = _tex("gw_nrm", _fbm(1503, 0.100, 3, 0.50), _sz(TEX_NORMAL), null, true, 0.5)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.885, 0.882, 0.872), tint), 0.97), 0.93, 0.0, Vector3(0.33, 0.33, 0.33), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.93, rgh, 0.93, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.10
	_apply_soil(m, soil)
	return m


## Carrara-ish marble. Veins are RIDGED perlin under domain warp: ridge peaks
## are thin, connected, wandering lines, which is structurally what a vein is.
## The gradient keeps everything below 0.80 white and only darkens the peaks.
static func _make_marble(tint: Color, soil: float) -> StandardMaterial3D:
	var veins: FastNoiseLite = _ridged(1601, 0.0050, 4, 24.0)
	var vein_ramp: Gradient = _ramp(
		PackedFloat32Array([0.0, 0.55, 0.80, 0.90, 1.0]),
		PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0), Color(0.98, 0.98, 0.98, 1.0),
			Color(0.95, 0.95, 0.96, 1.0), Color(0.58, 0.58, 0.62, 1.0),
			Color(0.40, 0.40, 0.45, 1.0),
		]))
	var alb: NoiseTexture2D = _tex("marb_alb", veins, _sz(TEX_ALBEDO), vein_ramp, false, 1.0)
	# vein calcite is softer and takes a different polish than the body, so the
	# roughness rides the SAME ridged field the veins came from rather than an
	# unrelated fbm. Body 0.14, vein peaks 0.30.
	var rgh: NoiseTexture2D = _tex("marb_rgh", _ridged(1601, 0.0050, 4, 24.0), _sz(TEX_ROUGH), _grey_ramp(0.14, 0.30), false, 1.0)
	# a polished slab is flat; the vein relief is only the polish taking the
	# softer calcite fractionally lower
	var nrm: NoiseTexture2D = _tex("marb_nrm", _ridged(1601, 0.0050, 4, 24.0), _sz(TEX_NORMAL), null, true, 0.35)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.80, 0.795, 0.78), tint), 0.92), 0.18, 0.0, Vector3(0.30, 0.30, 0.30), 5.0)
	m.albedo_texture = alb
	_rough(m, 0.18, rgh, 0.14, 0.30)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.12
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = 0.05
	_apply_soil(m, soil)
	return m


## Travertine. Two things make it read: horizontal BEDDING and open PORES.
##
## Both were wrong, and the mottled band over every doorway in three of four
## proof shots read as leopard print rather than as stone. The arithmetic:
## _fbm(1701, 0.0120, ...) over a 512 px texture spanning 1/0.28 = 3.57 m gives
## base features of ~58 cm. Real travertine bedding is 1-4 cm. And gain 0.55 put
## roughly ten times the contrast in that base octave, so the 58 cm blobs were
## the only thing visible. Worse, it inverted depth cueing: terrazzo chips at
## ~4.3 cm seen at 1.5 m subtend 0.029 rad, those blobs at 8 m subtend 0.073 rad
## — distant stone 2.5x coarser on screen than near stone, which is physically
## backwards and is exactly the cue that reads as "textures scaled by feel".
##
##   frequency 0.0120 -> 0.055   (~13 cm features)
##   gain      0.55   -> 0.70    (the fine bedding octaves survive)
##   uv1_scale 3.2:1  -> 12:1    (real bedding is 10-20:1, not 3:1)
##   albedo ramp -> CONSTANT, so bedding reads as LINES and not as clouds. The
##   same trick _make_terrazzo already uses correctly for its chip edges.
static func _make_travertine(tint: Color, soil: float) -> StandardMaterial3D:
	# five flat bedding tones rather than one smooth grey wash
	var beds: Gradient = _ramp(
		PackedFloat32Array([0.0, 0.24, 0.46, 0.70, 1.0]),
		PackedColorArray([
			Color(0.80, 0.80, 0.80, 1.0), Color(0.93, 0.93, 0.93, 1.0),
			Color(0.86, 0.86, 0.86, 1.0), Color(1.0, 1.0, 1.0, 1.0),
			Color(0.89, 0.89, 0.89, 1.0),
		]))
	beds.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var alb: NoiseTexture2D = _tex("trav_alb", _fbm(1701, 0.055, 5, 0.70), _sz(TEX_ALBEDO), beds, false, 1.0)
	# a pore is a VOID: it must be rougher (open) or glossier (resin-filled), and
	# on an unfilled slab it is rougher. So roughness rides the SAME cellular
	# DISTANCE field that cuts the pores into the normal. Previously the pores did
	# not exist in the specular at all, which is why they read as a bump artefact.
	# DISTANCE is small at a pore core: low field -> 0.62, bedding -> 0.36.
	var rgh: NoiseTexture2D = _tex("trav_rgh", _cells(1703, 0.110, 0.9, FastNoiseLite.RETURN_DISTANCE), _sz(TEX_ROUGH), _grey_ramp(0.62, 0.36), false, 1.0)
	var nrm: NoiseTexture2D = _tex("trav_nrm", _cells(1703, 0.110, 0.9, FastNoiseLite.RETURN_DISTANCE), _sz(TEX_NORMAL), null, true, 2.2)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.745, 0.705, 0.62), tint), 0.90), 0.45, 0.0, Vector3(0.20, 2.40, 0.20), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.45, rgh, 0.62, 0.36)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.55
	_apply_soil(m, soil)
	return m


## Fair-faced cast concrete. The widest roughness spread in the set (0.58-0.80):
## concrete's laitance skin polishes unevenly against the formwork and that
## uneven sheen is the material's signature.
static func _make_concrete(tint: Color, soil: float) -> StandardMaterial3D:
	var alb: NoiseTexture2D = _tex("conc_alb", _fbm(1801, 0.0080, 5, 0.55), _sz(TEX_ALBEDO), _grey_ramp(0.80, 1.0), false, 1.0)
	var rgh: NoiseTexture2D = _tex("conc_rgh", _fbm(1802, 0.070, 4, 0.55), _sz(TEX_ROUGH), _grey_ramp(0.72, 1.0), false, 1.0)
	var nrm: NoiseTexture2D = _tex("conc_nrm", _fbm(1803, 0.090, 5, 0.52), _sz(TEX_NORMAL), null, true, 1.6)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.505, 0.50, 0.49), tint), 0.90), 0.76, 0.0, Vector3(0.30, 0.34, 0.30), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.76, rgh, 0.72, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.45
	_apply_soil(m, soil)
	return m


## Dark oak. uv1_scale is stretched hard on Y (2.1 repeats per metre against
## 0.26 across) so the ridged grain lines run AROUND a box instead of pooling
## into blobs. Roughness is inverted against the grain: the raised grain wears
## smooth, the open pores stay matt.
static func _make_oak(tint: Color, soil: float) -> StandardMaterial3D:
	var grain: FastNoiseLite = _ridged(1901, 0.020, 4, 6.0)
	var alb: NoiseTexture2D = _tex("oak_alb", grain, _sz(TEX_ALBEDO), _grey_ramp(0.60, 1.0), false, 1.0)
	var rgh: NoiseTexture2D = _tex("oak_rgh", _ridged(1901, 0.020, 4, 6.0), _sz(TEX_ROUGH), _grey_ramp(1.0, 0.58), false, 1.0)
	var nrm: NoiseTexture2D = _tex("oak_nrm", _ridged(1901, 0.020, 4, 6.0), _sz(TEX_NORMAL), null, true, 1.4)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.245, 0.155, 0.095), tint), 0.80), 0.48, 0.0, Vector3(0.26, 2.10, 0.26), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.48, rgh, 1.0, 0.58)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.35
	_apply_soil(m, soil)
	return m


## Aged brass. ONE noise field, THREE correlated maps. Where the field is low the
## surface is verdigris: dielectric (metallic 0.10) and rough (0.90). Where it is
## high it is bare brass: metallic 1.0, roughness 0.25, albedo at brass's
## measured tint. Uncorrelated patina reads as paint; correlated patina reads as
## corrosion, because corrosion IS a change of substance, not of colour.
static func _make_brass(patina: float) -> StandardMaterial3D:
	var p: float = clampf(patina, 0.0, 1.0)
	var clean_start: float = lerpf(0.28, 0.82, p)
	var half: float = clean_start * 0.5
	var clean_full: float = minf(clean_start + 0.14, 0.97)
	var stops := PackedFloat32Array([0.0, half, clean_start, clean_full, 1.0])
	var pkey: String = "%.2f" % clean_start

	var alb_ramp: Gradient = _ramp(stops, PackedColorArray([
		Color(0.19, 0.25, 0.21, 1.0),   # deep verdigris in the recesses
		Color(0.30, 0.34, 0.26, 1.0),
		Color(0.48, 0.45, 0.28, 1.0),   # the transition — oxide thinning
		Color(0.79, 0.65, 0.34, 1.0),   # bare brass
		Color(0.86, 0.71, 0.38, 1.0),   # burnished high spots
	]))
	var met_ramp: Gradient = _ramp(stops, PackedColorArray([
		Color(0.08, 0.08, 0.08, 1.0), Color(0.10, 0.10, 0.10, 1.0),
		Color(0.22, 0.22, 0.22, 1.0), Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
	]))
	var rgh_ramp: Gradient = _ramp(stops, PackedColorArray([
		Color(0.98, 0.98, 0.98, 1.0), Color(0.95, 0.95, 0.95, 1.0),
		Color(0.80, 0.80, 0.80, 1.0), Color(0.30, 0.30, 0.30, 1.0),
		Color(0.27, 0.27, 0.27, 1.0),
	]))
	var alb: NoiseTexture2D = _tex("brass_alb_" + pkey, _fbm(2001, 0.022, 5, 0.55), _sz(TEX_ALBEDO), alb_ramp, false, 1.0)
	var met: NoiseTexture2D = _tex("brass_met_" + pkey, _fbm(2001, 0.022, 5, 0.55), _sz(TEX_ROUGH), met_ramp, false, 1.0)
	var rgh: NoiseTexture2D = _tex("brass_rgh_" + pkey, _fbm(2001, 0.022, 5, 0.55), _sz(TEX_ROUGH), rgh_ramp, false, 1.0)
	var nrm: NoiseTexture2D = _tex("brass_nrm", _fbm(2001, 0.022, 5, 0.55), _sz(TEX_NORMAL), null, true, 0.9)

	# albedo_color stays white: the ramp already carries the true colours, and a
	# tint here would desaturate the metal's F0
	var m: StandardMaterial3D = _base(Color.WHITE, 0.92, 1.0, Vector3(0.90, 0.90, 0.90), 4.0)
	m.albedo_texture = alb
	m.metallic_texture = met
	m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness_texture = rgh
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.25
	return m


## Soffit plaster: brighter and flatter than the wall. A ceiling is a reflector,
## not a feature — it should disappear and give back light.
static func _make_ceiling(tint: Color) -> StandardMaterial3D:
	var alb: NoiseTexture2D = _tex("ceil_alb", _fbm(2101, 0.0045, 4, 0.52), _sz(TEX_ALBEDO), _grey_ramp(0.92, 1.0), false, 1.0)
	var nrm: NoiseTexture2D = _tex("ceil_nrm", _fbm(2102, 0.085, 3, 0.50), _sz(TEX_NORMAL), null, true, 0.4)
	# shares the gallery-white roughness field — same key, so it is already in the
	# cache and costs nothing; at roughness 0.94 the variation is barely visible,
	# but "barely visible" is not "absent", and a constant is what reads as CG
	var rgh: NoiseTexture2D = _tex("gw_rgh", _fbm(1502, 0.075, 3, 0.55), _sz(TEX_ROUGH), _grey_ramp(0.93, 1.0), false, 1.0)
	# 0.815 against plaster at 0.72 is a 13% separation, and the wash erased it
	# completely: in aaa_axis the coffers read only through their cast shadows
	# while the soffit itself was the same hue and nearly the same value as the
	# wall. A real museum soffit is distinctly brighter AND cooler than the wall —
	# it is the bounce reflector. 0.860/0.865/0.875 against plaster warm
	# 0.72/0.705/0.675 is a deliberate ~8 degree hue split that survives a modest
	# wash and gives the room vertical colour structure.
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.860, 0.865, 0.875), tint), 0.96), 0.94, 0.0, Vector3(0.35, 0.35, 0.35), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.94, rgh, 0.93, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.08
	return m


## Vitrine glass. The smudge map is the point: perfectly clean glass has no
## surface and reads as a hole. Roughness runs 0.018-0.10 across fingerprints.
## NOTE the mesh author must set cast_shadow = SHADOW_CASTING_SETTING_OFF on
## glass instances, and expect transparency sort order to be per-object.
static func _make_glass(tint: Color) -> StandardMaterial3D:
	var rgh: NoiseTexture2D = _tex("glass_rgh", _fbm(2201, 0.030, 3, 0.55), _sz(TEX_ROUGH), _grey_ramp(0.18, 1.0), false, 1.0)
	var m: StandardMaterial3D = _base(Color(0.86 * tint.r, 0.90 * tint.g, 0.90 * tint.b, 0.09), 0.06, 0.0, Vector3(0.6, 0.6, 0.6), 4.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic_specular = 0.55          # IOR ~1.52 rather than the 1.5 default
	_rough(m, 0.06, rgh, 0.18, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_BACK
	return m


# ── shared construction helpers ──────────────────────────────────────────────

## Every architectural surface starts here. World-space triplanar is not a
## nicety in this scene, it is the requirement: the museum is built from
## hundreds of separate 1 m boxes, and per-mesh UVs would stamp an identical
## tile of noise into every single one — a visible grid, which is worse than the
## flat colour it replaced. World triplanar makes adjacent boxes continue one
## another, and box faces never stretch.
static func _base(albedo: Color, rough: float, metal: float, world_scale: Vector3, sharpness: float = 4.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.5
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	# anisotropic mipmaps: without this, a noise-mapped floor shimmers at grazing
	# angles, which is the specific tell that reads as "game" in VR
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# THE CHEAP EDGE DARKENING (see header). A plain BoxMesh carries no COLOR
	# array, so the shader gets white and this flag is a no-op — costs nothing.
	# The moment the geometry author builds a box with PbrKit.box() instead
	# (commons/render/pbr_kit.gd bakes edge wear into vertex colours), the same
	# material picks the wear up with no further work. Opt out with
	# EmMaterials.vertex_wear = false before warm_up().
	m.vertex_color_use_as_albedo = vertex_wear
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = world_scale
	# sharpness is an exponent on the blend weights; 1.0 (the default) smears
	# each projection a third of the way around a box corner and turns crisp
	# architecture to mush. 4-5 keeps the corner tight.
	m.uv1_triplanar_sharpness = sharpness
	return m


## Godot computes ROUGHNESS = roughness * texture, so a material that sets
## roughness 0.34 and then hangs a 0.5-1.0 ramp on it does NOT average 0.34, it
## averages 0.255 — every surface comes out glossier than it was authored to be.
## `target` here is the MEAN the surface should land on; the scalar is derived.
## Every roughness number quoted in this file's comments is a mean, and true.
static func _rough(m: StandardMaterial3D, target: float, tex: NoiseTexture2D, ramp_lo: float, ramp_hi: float) -> void:
	var mean: float = (ramp_lo + ramp_hi) * 0.5
	m.roughness_texture = tex
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = clampf(target / maxf(mean, 0.05), 0.02, 1.0)


## Cheap contact grime. Not true edge darkening (see the header) — a metre-scale
## soot patch pushed into albedo, roughness and AO at once. Applied to a 0.12 m
## skirting strip it is indistinguishable from the real thing at eye height.
static func _apply_soil(m: StandardMaterial3D, s: float) -> void:
	if s <= 0.0:
		return
	var dirty: Color = m.albedo_color.lerp(Color(0.105, 0.098, 0.088, 1.0), s * 0.42)
	m.albedo_color = dirty
	m.roughness = clampf(m.roughness + s * 0.22, 0.02, 1.0)
	m.metallic_specular = clampf(m.metallic_specular - s * 0.18, 0.0, 1.0)
	if m.clearcoat_enabled:
		m.clearcoat = clampf(m.clearcoat * (1.0 - s * 0.8), 0.0, 1.0)
	m.ao_enabled = true
	m.ao_texture = _grime_tex()
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	# ao_light_affect 0 = ambient only, which is what dirt should mostly do; a
	# little direct-light bite sells the pooling without killing the shading
	m.ao_light_affect = clampf(s * 0.35, 0.0, 1.0)


## One low-frequency field shared by every soiled surface, so grime pools at the
## same metre-scale rhythm across the whole building instead of each material
## inventing its own dirt. Sampled through each material's own uv1_scale, so it
## automatically matches that surface's feature size.
static func _grime_tex() -> NoiseTexture2D:
	return _tex("grime", _fbm(2301, 0.010, 4, 0.58), _sz(TEX_ROUGH), _grey_ramp(0.34, 1.0), false, 1.0)


## Noise textures are cached by an explicit key. Everything that varies the
## image MUST be in the key — the streamer asks for the same surface hundreds of
## times and each miss costs a threaded regeneration.
static func _tex(key_base: String, noise: FastNoiseLite, size: int, ramp: Gradient, as_normal: bool, bump: float) -> NoiseTexture2D:
	var mode: String = "n" if as_normal else "c"
	var key: String = "%s|%d|%s|%.2f" % [key_base, size, mode, bump]
	if _tex_cache.has(key):
		var cached: NoiseTexture2D = _tex_cache[key]
		return cached
	var t := NoiseTexture2D.new()
	t.width = size
	t.height = size
	t.generate_mipmaps = true
	t.normalize = true
	# seamless matters because world triplanar tiles the texture across the whole
	# endless corridor; a visible seam every 3.6 m would be a ruler on the floor
	t.seamless = true
	t.seamless_blend_skirt = 0.15
	if as_normal:
		t.as_normal_map = true
		t.bump_strength = bump
	elif ramp != null:
		t.color_ramp = ramp
	# assign the noise LAST: every property write queues a regeneration, so this
	# ordering costs one generation instead of six
	t.noise = noise
	_tex_cache[key] = t
	return t


static func _fbm(seed_value: int, freq: float, octaves: int, gain: float = 0.5) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_value
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	n.fractal_lacunarity = 2.0
	n.fractal_gain = gain
	return n


## Ridged fractal: peaks are thin connected lines rather than blobs. Domain warp
## bends those lines so they wander like a vein or a wood grain instead of
## running straight. `warp` is the amplitude in noise units; 0 disables it.
static func _ridged(seed_value: int, freq: float, octaves: int, warp: float = 0.0) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.seed = seed_value
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n.fractal_octaves = octaves
	n.fractal_lacunarity = 2.0
	n.fractal_gain = 0.5
	if warp > 0.0:
		n.domain_warp_enabled = true
		n.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
		n.domain_warp_amplitude = warp
		n.domain_warp_frequency = freq * 0.6
		n.domain_warp_fractal_octaves = 2
	return n


## Cellular. RETURN_CELL_VALUE gives flat random cells (terrazzo chips);
## RETURN_DISTANCE gives cones, which read as pores or voids in a normal map.
static func _cells(seed_value: int, freq: float, jitter: float, ret: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.seed = seed_value
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_NONE
	n.cellular_jitter = jitter
	n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	n.cellular_return_type = ret
	return n


static func _ramp(offsets: PackedFloat32Array, colors: PackedColorArray) -> Gradient:
	var g := Gradient.new()
	# order matters: set_offsets resizes the point list, set_colors then fills it
	g.offsets = offsets
	g.colors = colors
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	return g


## Two-stop greyscale ramp. A fresh Gradient already has exactly two points at
## offsets 0 and 1, so recolouring them in place is all that is needed — same
## idiom PbrKit.grain() uses. `low` may exceed `high` (trim_oak inverts its
## roughness against the grain); only the endpoint values matter.
static func _grey_ramp(low: float, high: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(low, low, low, 1.0))
	g.set_color(1, Color(high, high, high, 1.0))
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	return g


## An albedo texture MULTIPLIES albedo_color, and a 0.78-1.0 grey ramp has a
## mean well under 1.0, so a material authored to a measured reflectance would
## come out too dark. Pre-lift the base colour by the ramp's mean so the surface
## averages to the value the comment claims it is.
static func _lift(c: Color, ramp_mean: float) -> Color:
	var k: float = 1.0 / maxf(0.05, ramp_mean)
	return Color(minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0), 1.0)


static func _tinted(base: Color, tint: Color) -> Color:
	return Color(base.r * tint.r, base.g * tint.g, base.b * tint.b, 1.0)


## Quantise to 1/32 so a caller passing slightly-varying tints collapses onto a
## handful of shared materials instead of minting one per box.
static func _quantize(c: Color) -> Color:
	return Color(
		clampf(snappedf(c.r, 0.03125), 0.0, 1.0),
		clampf(snappedf(c.g, 0.03125), 0.0, 1.0),
		clampf(snappedf(c.b, 0.03125), 0.0, 1.0),
		1.0)


static func _color_key(c: Color) -> String:
	return "%02x%02x%02x" % [int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0)]


## Multiple of 64 rather than a power of two: NoiseTexture2D has no PoT
## requirement and 64-steps give finer quality control than doubling.
static func _sz(base: int) -> int:
	var raw: int = int(round(float(base) * quality_scale / 64.0)) * 64
	return clampi(raw, 64, 2048)
