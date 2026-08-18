class_name EmMaterials
extends RefCounted
# em_materials.gd — the endless museum's PBR surface library.
#
# WHY THIS FILE EXISTS
# The museum streams hundreds of BoxMeshes per segment. In v1 every one of them
# carried a flat StandardMaterial3D with an albedo colour and nothing else. v2
# gave them procedural albedo/roughness/normal noise. Two critics then measured
# v2 and returned the same verdict from two directions:
#
#   "The terrazzo reads as DPM camouflage, not stone. Chips measure 10-15 cm at
#    the floor plane; real terrazzo is 6-20 mm. Chip-to-matrix luminance 0.12 vs
#    0.72 — three flat tones, no mid, near-maximum contrast."
#   "Every material is one octave of noise at the wrong world scale. Plaster is a
#    single 1.2-1.8 m blotch — a Photoshop clouds filter. Oak is a 1D horizontal
#    blur with no pore, no ray fleck, no end grain — MDF with a wood decal.
#    detail_albedo / detail_normal / uv2_scale are entirely unused: that is free
#    AAA and it costs one texture per role."
#
# Both are scale complaints, and v2 had no scale MODEL — it had hand-typed
# FastNoiseLite frequencies and comments guessing at what they came out as. This
# file replaces every one of those numbers with a millimetre constant and an
# arithmetic derivation. See "THE SCALE MODEL" below. scale_report() prints the
# derivation back so a reviewer can check a surface without opening Godot.
#
#
# ── THE SCALE MODEL ─────────────────────────────────────────────────────────
#
# ASSUMPTION, stated once so it can be argued with: the museum's geometry is
# authored on a 1 m grid — endless_museum.gd emits BoxMesh cells whose faces are
# whole metres, and walls are 1 m modules stretched in Y. That assumption does
# NOT enter the arithmetic, because every material here is WORLD triplanar: the
# mesh's own size, scale and UV layout are irrelevant. It only tells you the
# viewing distances involved (1-12 m) and therefore which bands must be present.
#
# What actually fixes feature size is three numbers:
#
#     tile_m = 1 / uv1_scale     metres of world spanned by one texture repeat
#     px                         texture resolution
#     f                          FastNoiseLite.frequency, in cycles per PIXEL
#
#         feature_m = tile_m / (f * px)     <=>     f = tile_m / (mm/1000 * px)
#
# _freq_for_mm() is the right-hand form and it is the ONLY place a frequency is
# produced in this file. Three consequences worth knowing:
#
#   * px comes from _sz(), which scales with quality_scale. Because f is derived
#     from px, the millimetre figures survive a quality change. Under v2 they did
#     not: halving the resolution doubled every feature in the building.
#   * A feature must land on at least ~6-8 pixels or the texture stores aliasing
#     instead of pattern. That single constraint is why the terrazzo albedo is
#     1152 px and the ceiling is 256 — resolution is bought where the millimetres
#     demand it, not uniformly. _band_octaves() enforces the Nyquist end of it.
#   * TWO MAPS DERIVED FROM ONE FIELD MUST SHARE BOTH FREQUENCY AND RESOLUTION.
#     v2 broke this everywhere and it was invisible: terr_alb was 512 px and
#     terr_rgh 256 px off the same noise at the same frequency, so the "correlated"
#     gloss was at exactly twice the world size of the chips it was supposed to
#     belong to. Same fault in marble (512/256/256) and brass (512/256/256/256) —
#     which is most of why the patina read as a decal. Every field is now built
#     once and handed to every map at one size.
#
#
# ── THREE BANDS ON EVERY ROLE ───────────────────────────────────────────────
#
#   MACRO   2.4-3.6 m, ALBEDO ONLY, +/-4-6%. Its job is to stop the eye finding
#           the repeat. It is the BASE OCTAVE of the role's fbm, and its share of
#           the total contrast is 1/sum(gain^i) — printed by scale_report() as
#           macro_share_pct so it can be checked rather than asserted.
#   MESO    the pattern the material is named for, at a verified size: 11 mm
#           terrazzo chips, 1.6 mm travertine laminae, 2.5 mm oak rings. Carried
#           by the remaining octaves of the same uv1 image.
#   MICRO   0.25-1.6 mm, NORMAL (near enough) ONLY. This is the band that makes
#           light break correctly at 1 m and it lives in the DETAIL slots.
#
# THE DETAIL SLOTS, AND THE TWO THINGS THAT BITE
#
# StandardMaterial3D gives you exactly TWO uv scales, and three bands need three.
# uv1 therefore carries macro+meso in one image (which is why uv1 tiles are
# metres and the albedo textures are large) and uv2 carries micro alone.
#
#   1. A BoxMesh has no UV2 array. detail_uv_layer = DETAIL_UV_2 alone would
#      sample a constant. uv2_triplanar + uv2_world_triplanar is what makes the
#      slot usable at all: UV2 then comes from the world vertex, not the mesh, so
#      the grain is world-locked and continues across box joints like uv1 does.
#   2. Godot's detail blend is, with no detail_mask:
#           detail      = mix(ALBEDO, ALBEDO*detail_tex.rgb, detail_tex.a)
#           detail_norm = mix(NORMAL_MAP, detail_norm_tex.rgb, detail_tex.a)
#           NORMAL_MAP  = mix(NORMAL_MAP, detail_norm, detail_tex.a)
#           ALBEDO      = detail
#      The NORMAL is mixed TWICE, so the micro band's weight is detail_tex.a
#      SQUARED, not a. At the "obvious" a = 0.35 the grain arrives at 12% and is
#      invisible; DETAIL_MIX is 0.62 for a 38% micro weight. And detail_albedo
#      must never be left null: null reads as opaque white, and under BLEND_MODE_MIX
#      that replaces ALBEDO with white. Every role sets a near-white grain albedo
#      (0.90-1.00) under BLEND_MODE_MUL, which is both safe and a legitimate
#      couple-of-percent micro albedo.
#      normal_scale scales the MIXED normal, so it governs micro and meso
#      together: meso normal_scales are ~1.6x their v2 values to hold station
#      against the 38% the micro now takes.
#
#
# ── WHAT EACH MATERIAL IS IMITATING ─────────────────────────────────────────
#   floor_stone()      Honed dark granite / basalt gallery deck. Broad-spectrum
#                      mottle 3 m -> 94 mm, crystal facet in the grain band.
#   floor_terrazzo()   Poured terrazzo. Cellular CONSTANT chips at 11 mm — see
#                      _make_terrazzo for the whole camouflage post-mortem.
#   wall_plaster(tint) Honed lime plaster: trowel chatter arcs at 100-300 mm,
#                      float texture down to 10 mm on uv1, sand and 0.3 mm grain
#                      in the detail band. Not one blotch.
#   gallery_white()    Museum-white matt emulsion, 0.885 sRGB. The building's
#                      main bounce source, so its macro band is deliberately the
#                      weakest in the set — 6% on a bounce surface reads as dirt.
#   podium_marble()    Carrara-ish. Ridged + domain-warped veins, 2.8 m -> 44 mm.
#   travertine()       Bedding laminae 1.6 mm thick and ~19 mm long (a 12:1
#                      anisotropic uv1), pores as cellular voids in the grain band.
#   concrete()         Fair-faced cast. 3.6 m -> 28 mm, sand at 1.5-12 mm.
#   trim_oak(.., axis) Oak. Rings 2.5 mm across grain / ~50 mm along, pore
#                      speckle as cellular voids in the grain band, and REAL END
#                      GRAIN — see _make_oak for how the axis argument gets a beam
#                      and its architrave to agree.
#   accent_brass()     The only metal. One field, four correlated maps, one size.
#   ceiling_plaster()  Flat bright soffit. A reflector, not a feature.
#   glass_vitrine()    Vitrine glass; roughness is a smudge map.
#   emissive_accent()  Architectural light line.
#
# NOTE ON TINT: the template palettes feeding this library are qualitative
# (chart-legend) hues — #946b3d/#3d6b94/#6b943d are the same three bytes rotated
# through the channels. Fed to a stone at full strength they turn a floor into a
# colour swatch, which is half of why the terrazzo read as brown camouflage.
# Mineral roles pass their tint through _mineral(), which cuts chroma to
# mineral_chroma and PRESERVES LUMINANCE exactly — so it cannot fight an exposure
# or bounce-light fix happening elsewhere. Set EmMaterials.mineral_chroma = 1.0
# to switch it off in one line.
#
# EDGE GRIME — the honest answer
# True curvature-driven edge darkening needs a shader input a BoxMesh does not
# have. What IS cheap: a `soil` parameter (0..1) on every architectural surface,
# skirting(kind, tint) at soil 0.75 for a 0.12 m strip at the base of a wall, and
# vertex_color_use_as_albedo (a no-op on plain BoxMesh, free edge wear the moment
# geometry is built with PbrKit.box()).
#
# CACHING — read this before you call anything in a loop
# Every getter returns a SHARED, CACHED material; do not mutate one, .duplicate().
# Tints quantise to 1/32 before becoming a cache key. Generation cost is O(roles),
# never O(boxes): a role's noise FIELD is built once and handed to its albedo,
# roughness and normal textures, and the textures cache on their own keys.
#
# EVERY ROUGHNESS NUMBER IN THIS FILE IS A MEAN
# Godot computes ROUGHNESS = roughness * texture, so hanging a 0.5-1.0 ramp on a
# material set to 0.34 gives 0.255. _rough() derives the scalar from the target
# mean and the ramp's mean, so the quoted figures are what the surface has.
#
# THREADED GENERATION
# NoiseTexture2D generates on a worker thread. Call EmMaterials.warm_up() once in
# _ready() or the first surface of each family pops from flat white to textured.

# ── tunables ─────────────────────────────────────────────────────────────────
# Resolution is bought where the millimetres demand it. A meso feature must land
# on >= ~6 px; these five sizes are the smallest that satisfy that for their role.
const TEX_FINE := 1152     # terrazzo: 11 mm chips over a 1.8 m tile = 7.0 px
const TEX_LARGE := 1024    # marble / travertine / concrete-ish / oak
const TEX_MID := 768       # plaster, concrete
const TEX_BASE := 512      # floor stone, brass
const TEX_SMALL := 256     # gallery white, ceiling, glass, and every detail map
const TEX_DETAIL := 256    # the uv2 grain band

## The uv2 (micro) tile, in metres. uv2_scale = 1/GRAIN_TILE_M = 55.6 repeats per
## metre. At TEX_DETAIL 256 that is 0.0703 mm per pixel, so a 0.30 mm grain lands
## on 4.3 px and a 1.5 mm sand grain on 21 px — the whole 0.25-3 mm band fits in
## one 256 px image per role.
const GRAIN_TILE_M := 0.018

## detail_tex.a. The micro normal arrives at a*a (Godot mixes it twice — see the
## header), so 0.62 buys a 38% micro weight and leaves 62% for the meso normal.
const DETAIL_MIX := 0.62

## Nyquist guard: an octave finer than this many cycles per pixel stores aliasing,
## not detail. _band_octaves() drops octaves until the finest one clears it.
const NYQUIST_LIMIT := 0.35

## 1.0 = the sizes above. Drop to 0.5 for standalone Quest, raise for stills.
## Feature sizes in millimetres are UNCHANGED by this, because every frequency is
## derived from the resolution actually in use. Changing it clears the cache.
static var quality_scale: float = 1.0

## Let vertex colours darken albedo. A no-op on plain BoxMesh (no COLOR array),
## so it is on by default — geometry built with PbrKit.box() gets baked edge wear.
static var vertex_wear: bool = true

## The uv2 micro band costs two extra texture fetches, tripled by triplanar. Set
## false before warm_up() on a tile-limited target; everything else still works.
static var detail_grain: bool = true

## How much of a template tint a MINERAL surface accepts. Luminance-preserving:
## 0.0 = the stone's own neutral, 1.0 = the raw palette hue. See the header note.
static var mineral_chroma: float = 0.45

static var _mat_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

# ── public API ───────────────────────────────────────────────────────────────

## Honed dark granite gallery deck. tint multiplies the base stone colour.
static func floor_stone(tint: Color = Color.WHITE, soil: float = 0.0) -> StandardMaterial3D:
	return get_material(&"floor_stone", tint, soil)

## Poured terrazzo with flat aggregate chips at 11 mm.
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
## `axis` is the WORLD axis the boards run along: &"x", &"y" or &"z". A vertical
## post takes &"y", a beam running east-west takes &"x". Read _make_oak before
## deciding you can ignore it — it is what stops a beam and its architrave
## disagreeing, and it is what puts end grain on the ends.
static func trim_oak(tint: Color = Color.WHITE, soil: float = 0.0, axis: StringName = &"x") -> StandardMaterial3D:
	return get_material(&"oak", tint, soil, axis)

## Aged brass. `patina` 0 = freshly polished, 1 = heavily oxidised.
static func accent_brass(patina: float = 0.35) -> StandardMaterial3D:
	return get_material(&"brass", Color.WHITE, patina)

## Flat bright soffit plaster.
static func ceiling_plaster(tint: Color = Color.WHITE) -> StandardMaterial3D:
	return get_material(&"ceiling", tint, 0.0)

## Vitrine / balustrade glass. Transparent — see the notes in the glass branch.
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
## `variant` is a per-kind discriminator; today only oak uses it (the grain axis).
## An unknown kind returns plaster rather than null, so a typo greys out a wall
## instead of crashing the streamer.
static func get_material(kind: StringName, tint: Color = Color.WHITE, soil: float = 0.0, variant: StringName = &"") -> StandardMaterial3D:
	var q: Color = _quantize(tint)
	var s: float = clampf(snappedf(soil, 0.125), 0.0, 1.0)
	var key: String = "%s|%s|%s|%.3f" % [str(kind), str(variant), _color_key(q), s]
	if _mat_cache.has(key):
		var cached: StandardMaterial3D = _mat_cache[key]
		return cached
	var m: StandardMaterial3D = _build(str(kind), q, s, str(variant))
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
		"detail_grain": detail_grain,
		"mineral_chroma": mineral_chroma,
		"grain_tile_mm": GRAIN_TILE_M * 1000.0,
		"grain_uv2_scale": 1.0 / GRAIN_TILE_M,
	}

## THE SCALE AUDIT. Every role's three bands as numbers, derived the same way the
## materials derive them, so a reviewer can check a surface without launching the
## renderer. `meso_px` under ~6 means the texture is storing aliasing rather than
## pattern; `macro_share_pct` is the base octave's share of the albedo contrast.
static func scale_report() -> Dictionary:
	var out: Dictionary = {}
	for row in _SCALE_TABLE:
		var role: String = row[0]
		var tile_m: float = row[1]
		var macro_mm: float = row[2]
		var meso_mm: float = row[3]
		var micro_mm: float = row[4]
		var px: int = _sz(int(row[5]))
		var gain: float = row[6]
		var lac: float = row[7]
		var f0: float = _freq_for_mm(macro_mm, tile_m, px)
		var oct: int = _band_octaves(macro_mm, meso_mm, f0, lac)
		var f_fine: float = f0 * pow(lac, float(oct - 1))
		out[role] = {
			"uv1_tile_m": tile_m,
			"px": px,
			"mm_per_px": tile_m * 1000.0 / float(px),
			"macro_mm": macro_mm,
			"meso_mm_declared": meso_mm,
			"meso_mm_actual": tile_m * 1000.0 / (f_fine * float(px)),
			"meso_px": 1.0 / f_fine,
			"micro_mm": micro_mm,
			"octaves": oct,
			"freq_base": f0,
			"freq_finest": f_fine,
			"macro_share_pct": _macro_share(oct, gain) * 100.0,
		}
	return out

static func set_quality(scale: float) -> void:
	quality_scale = clampf(scale, 0.25, 2.0)
	clear_cache()

static func clear_cache() -> void:
	_mat_cache.clear()
	_tex_cache.clear()


# ── the scale table ──────────────────────────────────────────────────────────
# role, uv1 tile (m, on the SHARP axis), macro mm, meso mm, micro mm, px, gain,
# lacunarity. The materials below read the same numbers; this array exists so
# scale_report() can print them and so the whole set is legible in one screen.
#
#   role          tile   macro    meso   micro    px    gain    lac
const _SCALE_TABLE: Array = [
	["floor_stone", 3.0, 3000.0, 94.0, 0.35, TEX_BASE, 0.72, 2.0],
	["terrazzo", 1.8, 1800.0, 11.0, 0.30, TEX_FINE, 4.00, 163.64],
	["plaster", 2.6, 2600.0, 10.2, 0.30, TEX_MID, 0.68, 2.0],
	["gallery_white", 3.2, 3200.0, 200.0, 0.30, TEX_SMALL, 0.62, 2.0],
	["marble", 2.8, 2800.0, 44.0, 0.30, TEX_LARGE, 0.55, 2.0],
	["travertine", 0.20, 200.0, 1.6, 0.80, TEX_LARGE, 0.66, 2.0],
	["concrete", 3.6, 3600.0, 28.0, 1.60, TEX_MID, 0.70, 2.0],
	["oak", 0.16, 160.0, 2.5, 0.45, TEX_LARGE, 0.58, 2.0],
	["brass", 0.9, 900.0, 14.0, 0.25, TEX_BASE, 0.62, 2.0],
	["ceiling", 3.2, 3200.0, 200.0, 0.30, TEX_SMALL, 0.62, 2.0],
	["glass", 1.2, 1200.0, 37.5, 0.15, TEX_SMALL, 0.60, 2.0],
]


# ── material construction ────────────────────────────────────────────────────

static func _build(kind: String, tint: Color, soil: float, variant: String) -> StandardMaterial3D:
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
			return _make_oak(tint, soil, variant)
		"brass":
			return _make_brass(soil)
		"ceiling":
			return _make_ceiling(tint)
		"glass":
			return _make_glass(tint)
	push_warning("EmMaterials: unknown kind `%s` — falling back to plaster" % kind)
	return _make_plaster(tint, soil)


## Honed dark granite. Albedo 0.185 sRGB sits inside the 0.10-0.25 band real dark
## stone measures at. Roughness 0.17-0.34: honed, not mirror.
##
## BANDS. v2 had three unrelated fbms at three hand-typed frequencies, and the
## roughness field ran at 8x the albedo field's world size for no stated reason.
## Now one field, one resolution, three maps:
##   macro  3.0 m base octave, 33% of a 0.20 p-p albedo ramp = +/-3.3%
##   meso   6 octaves down to 94 mm (16 px) — slab mottle and lane polish
##   micro  3.0 -> 0.35 mm crystal facet in the detail normal. Granite's crystal
##          is 2-8 mm and cannot exist on a 3 m tile at any sane resolution; the
##          detail band is where it belongs and this is the first version that
##          has it.
static func _make_floor_stone(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 3.0
	var px: int = _sz(TEX_BASE)
	var field: FastNoiseLite = _band_fbm(1201, tile_m, 3000.0, 94.0, px, 0.72, 0.0, 0.0)
	var alb: NoiseTexture2D = _tex("stone_alb", field, px, _grey_ramp(0.90, 1.10), false, 1.0, 0.12)
	# honed granite's gloss follows its mineral, so roughness rides the SAME field
	var rgh: NoiseTexture2D = _tex("stone_rgh", field, px, _grey_ramp(0.62, 1.06), false, 1.0, 0.12)
	var nrm: NoiseTexture2D = _tex("stone_nrm", field, px, null, true, 0.9, 0.12)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.185, 0.185, 0.205), _mineral(tint)), 1.00), 0.26, 0.0, _uv(tile_m), 5.0)
	m.albedo_texture = alb
	_rough(m, 0.26, rgh, 0.62, 1.06)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.30
	# sealed stone: a second, tighter specular lobe over the body reflection
	m.clearcoat_enabled = true
	m.clearcoat = 0.25
	m.clearcoat_roughness = 0.08
	_apply_grain(m, "stone", 1204, 3.0, 0.35, 2.2, 0.94, false)
	_apply_soil(m, soil)
	return m


## Terrazzo — the camouflage post-mortem.
##
## WHAT WAS MEASURED. Chips 10-15 cm at the floor plane against a real 6-20 mm.
## Chip-to-matrix luminance 0.12 vs 0.72. Three flat tones, no mid, occupying
## 30-45% of three frames. The verdict was exact: "large irregular blobs, three
## values, high contrast — precisely a disruptive camouflage pattern; the eye
## names it as fabric before stone."
##
## WHY, IN THREE PARTS, ONLY ONE OF WHICH WAS THE FREQUENCY.
##   1. SCALE. f 0.090 over 512 px spanning 1/0.5 = 2.0 m gives cells of
##      2000/(0.090*512) = 43 mm. Three times too big, but only three — not the
##      ten the critic measured.
##   2. MERGING, which is where the other 3x came from. Six CONSTANT gradient
##      stops means six flat chip tones, so roughly one neighbour in six lands in
##      the same band and merges. Merged cells percolate into clusters several
##      cells across — 43 mm cells presenting as 120 mm blobs. This is the part
##      that made it read as camouflage rather than as coarse terrazzo: real
##      terrazzo has hundreds of aggregate tones, and the blob is an artefact of
##      quantising to six.
##   3. CONTRAST. The albedo ramp ran 0.60-1.00 over an albedo_color of 0.759 —
##      a chip-to-matrix delta of 0.303, near the maximum a diffuse surface can
##      hold. High contrast is what turns a merged cluster into a SHAPE.
##
## THE FIX, addressing all three.
##   chips     43 mm -> 11 mm. tile 1.8 m, 1152 px, f = 1.8/(0.011*1152) = 0.142,
##             which is 7.0 px per cell — the floor of what a hard-edged pattern
##             can occupy before it becomes aliasing, and the reason this is the
##             largest texture in the set. 11 mm is mid-band of the real 6-20 mm.
##   tones     six stops compressed into 0.355-0.525 with a THIRD, MID stop and
##             two near-identical matrix stops. Merging now joins matrix to
##             matrix (correct: the matrix IS continuous) and any two chips that
##             merge differ by at most 0.06, so a cluster has no edge to be a
##             shape with. Delta chip-to-matrix 0.113 max, chip-to-chip 0.170.
##   macro     the base octave of a TWO-octave cellular fbm with lacunarity 163.6
##             — octave 0 at 1.8 m is the pour bay, octave 1 at 11 mm is the chip.
##             gain 4.0 puts 20% of the range in the bay, so a bay reads as a
##             region where more chips fall in the lighter bands, exactly as a
##             different pour batch does. A hard-edged bay boundary is not a
##             defect here: poured terrazzo IS laid in bays against divider strips.
##   micro     2.4 -> 0.30 mm in the detail normal — the ground-and-honed surface
##             tooth that makes a floor catch a grazing highlight at 1 m.
##
## Roughness still rides the same field at the same resolution (v2 correlated the
## field but not the RESOLUTION, running gloss at 256 px against albedo at 512:
## the chips' gloss was at twice the chips' world size, which is decorrelation
## wearing a correlation comment).
static func _make_terrazzo(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 1.8
	var px: int = _sz(TEX_FINE)
	var f_chip: float = _freq_for_mm(11.0, tile_m, px)
	var f_bay: float = _freq_for_mm(1800.0, tile_m, px)
	var lac: float = f_chip / maxf(f_bay, 0.000001)
	var field: FastNoiseLite = _cells(1301, f_bay, 1.0, FastNoiseLite.RETURN_CELL_VALUE, 2, lac, 4.0)

	# ABSOLUTE sRGB, not multipliers: albedo_color carries only the tint, so the
	# numbers below are the numbers the surface has and a reviewer can read them
	# straight off. Six stops, all inside 0.355-0.525.
	var chips: Gradient = _ramp(
		PackedFloat32Array([0.0, 0.19, 0.36, 0.52, 0.70, 0.86]),
		PackedColorArray([
			Color(0.355, 0.350, 0.345, 1.0),   # dark basalt chip
			Color(0.525, 0.518, 0.505, 1.0),   # pale marble chip
			Color(0.440, 0.437, 0.430, 1.0),   # MID chip — the third stop
			Color(0.412, 0.406, 0.392, 1.0),   # cement matrix
			Color(0.424, 0.418, 0.404, 1.0),   # cement matrix, second pass
			Color(0.482, 0.470, 0.448, 1.0),   # warm quartz chip
		]))
	chips.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT

	var alb: NoiseTexture2D = _tex("terr_alb", field, px, chips, false, 1.0, 0.08)
	# aggregate takes a different polish than the cement, and cell value is flat
	# WITHIN a cell, so a linear ramp still yields one flat gloss per chip
	var rgh: NoiseTexture2D = _tex("terr_rgh", field, px, _grey_ramp(0.30, 0.13), false, 1.0, 0.08)
	var nrm: NoiseTexture2D = _tex("terr_nrm", field, px, null, true, 0.6, 0.08)
	var m: StandardMaterial3D = _base(_mineral(tint), 0.20, 0.0, _uv(tile_m), 5.0)
	m.albedo_texture = alb
	_rough(m, 0.20, rgh, 0.30, 0.13)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.22
	m.clearcoat_enabled = true
	m.clearcoat = 0.20
	m.clearcoat_roughness = 0.10
	_apply_grain(m, "terr", 1304, 2.4, 0.30, 1.8, 0.95, false)
	_apply_soil(m, soil)
	return m


## Honed lime plaster.
##
## WHAT WAS MEASURED: "a single 1.2-1.8 m blotch — the signature of a Photoshop
## clouds filter". Correct, and the arithmetic agrees: v2 ran f 0.0040 over 512 px
## on a 1/0.42 = 2.38 m tile, so the base feature was 2380/(0.0040*512) = 1163 mm
## and gain 0.55 put 45% of the contrast in that one octave. Four more octaves
## existed but the finest reached only 73 mm. Below 73 mm the wall was perfectly
## smooth, which is why it had no incident at arm's length.
##
## Real plaster is three things and v2 had one of them:
##   trowel chatter   100-300 mm, DIRECTIONAL — arcs, not clouds
##   float texture    2-5 mm
##   aggregate grain  0.3 mm, and carried in the NORMAL, because that band is
##                    what makes light break correctly at 1 m
##
## Bands here:
##   macro  2.6 m base octave, 33% of a 0.36 p-p ramp = +/-5.9% albedo
##   meso   9 octaves, 2.6 m -> 10.2 mm (3.0 px at 768). The 100-300 mm trowel
##          chatter is octaves 4-5, and it is DIRECTIONAL by two means: an
##          anisotropic uv1 (5.72 m across, 2.6 m up — strokes 2.2x wider than
##          tall) and a domain warp at ~150 mm amplitude that bends the bands into
##          arcs instead of clouds. Declared meso mm is on the SHORT (Y) axis.
##   micro  4.8 -> 0.30 mm in the detail normal: the float texture AND the
##          aggregate grain, five octaves of it, in one 256 px map.
## Roughness rides the same field: the burnished passes are the raised ones, so
## gloss and tone cannot disagree. Mean 0.66 — at v2's 0.82 the specular lobe was
## flattened until the relief had nothing left to modulate.
static func _make_plaster(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 2.6
	var px: int = _sz(TEX_MID)
	# warp amplitude is in PIXELS, so convert from millimetres like everything else
	var warp_amp: float = 150.0 / (tile_m * 1000.0 / float(px))
	var warp_freq: float = _freq_for_mm(220.0, tile_m, px)
	var field: FastNoiseLite = _band_fbm(1401, tile_m, 2600.0, 10.2, px, 0.68, warp_amp, warp_freq)
	var alb: NoiseTexture2D = _tex("plas_alb", field, px, _grey_ramp(0.80, 1.16), false, 1.0)
	var rgh: NoiseTexture2D = _tex("plas_rgh", field, px, _grey_ramp(0.86, 0.48), false, 1.0)
	var nrm: NoiseTexture2D = _tex("plas_nrm", field, px, null, true, 1.3)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.72, 0.705, 0.675), tint), 0.98), 0.66, 0.0, _uv_aniso(tile_m, 2.2), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.66, rgh, 0.86, 0.48)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.42
	_apply_grain(m, "plas", 1404, 4.8, 0.30, 3.2, 0.94, false)
	_apply_soil(m, soil)
	return m


## Museum white. 0.885 sRGB, not 1.0: this is the brightest thing in the building
## and the dominant bounce source, and a 1.0 albedo has no headroom under any
## tonemapper.
## THE ONE ROLE THAT DELIBERATELY UNDERSHOOTS THE MACRO SPEC. A +/-6% metre-scale
## albedo swing on the bounce surface reads as staining, not as material, so this
## one runs a 0.20 p-p ramp for +/-4.2%. Its job is to stop banding across a large
## flat wall under a soft wash, and nothing more. The roller stipple, which is the
## only thing that is actually TRUE about a painted wall at 1 m, is in the grain.
static func _make_gallery_white(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 3.2
	var px: int = _sz(TEX_SMALL)
	var field: FastNoiseLite = _band_fbm(1501, tile_m, 3200.0, 200.0, px, 0.62, 0.0, 0.0)
	var alb: NoiseTexture2D = _tex("gw_alb", field, px, _grey_ramp(0.90, 1.10), false, 1.0)
	var rgh: NoiseTexture2D = _gw_rough_tex()
	var nrm: NoiseTexture2D = _tex("gw_nrm", field, px, null, true, 0.5)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.885, 0.882, 0.872), tint), 1.00), 0.93, 0.0, _uv(tile_m), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.93, rgh, 0.93, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.16
	# 1.2 -> 0.30 mm: roller stipple and emulsion tooth
	_apply_grain(m, "gw", 1504, 1.2, 0.30, 2.4, 0.96, false)
	_apply_soil(m, soil)
	return m


## Carrara-ish marble. Veins are RIDGED perlin under domain warp: ridge peaks are
## thin, connected, wandering lines, which is structurally what a vein is.
## Bands: macro 2.8 m base octave; meso 7 octaves down to 44 mm (16 px at 1024),
## which is the width a real Carrara vein branch actually is; micro 1.5 -> 0.30 mm
## honing tooth. Vein calcite is softer and takes a different polish, so
## roughness and normal ride the SAME field AT THE SAME RESOLUTION — v2 ran the
## albedo at 512 and both others at 256, i.e. the gloss veins were twice the size
## of the colour veins and sat on top of them.
static func _make_marble(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 2.8
	var px: int = _sz(TEX_LARGE)
	var field: FastNoiseLite = _band_ridged(1601, tile_m, 2800.0, 44.0, px, 0.55, 24.0)
	var vein_ramp: Gradient = _ramp(
		PackedFloat32Array([0.0, 0.55, 0.80, 0.90, 1.0]),
		PackedColorArray([
			Color(1.0, 1.0, 1.0, 1.0), Color(0.98, 0.98, 0.98, 1.0),
			Color(0.95, 0.95, 0.96, 1.0), Color(0.58, 0.58, 0.62, 1.0),
			Color(0.40, 0.40, 0.45, 1.0),
		]))
	var alb: NoiseTexture2D = _tex("marb_alb", field, px, vein_ramp, false, 1.0)
	var rgh: NoiseTexture2D = _tex("marb_rgh", field, px, _grey_ramp(0.14, 0.30), false, 1.0)
	# a polished slab is flat; the relief is only the polish taking the softer
	# calcite fractionally lower
	var nrm: NoiseTexture2D = _tex("marb_nrm", field, px, null, true, 0.35)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.80, 0.795, 0.78), _mineral(tint)), 0.92), 0.18, 0.0, _uv(tile_m), 5.0)
	m.albedo_texture = alb
	_rough(m, 0.18, rgh, 0.14, 0.30)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.18
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = 0.05
	_apply_grain(m, "marb", 1604, 1.5, 0.30, 1.2, 0.97, false)
	_apply_soil(m, soil)
	return m


## Travertine. Two things make it read: horizontal BEDDING and open PORES.
##
## v2 fixed the frequency once already and still had it an order out, because it
## reasoned in texture space instead of world space. The tile here is declared on
## the SHARP axis: 0.20 m vertically against 2.4 m horizontally, a 12:1 stretch
## (real bedding is 10-20:1, not the 3:1 v1 had). At 1024 px that is 0.195 mm per
## pixel vertically, so the 8-octave fbm's finest octave — 8 px — is a lamina
## 1.6 mm thick and, stretched by 12, about 19 mm long. Real travertine laminae
## are 1-5 mm thick. A CONSTANT ramp keeps them LINES rather than clouds.
##
## The pores moved. A pore is round, and a round thing cannot exist on a 12:1
## anisotropic uv1 — v2 put a cellular DISTANCE field there and got 12:1 smears,
## which is what read as "a bump artefact". They are now cellular voids in the
## ISOTROPIC detail band at 2.4 mm, which is both round and the right size.
static func _make_travertine(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 0.20        # the SHARP (vertical) axis
	var px: int = _sz(TEX_LARGE)
	var field: FastNoiseLite = _band_fbm(1701, tile_m, 200.0, 1.6, px, 0.66, 0.0, 0.0)
	# five flat bedding tones rather than one smooth grey wash
	var beds: Gradient = _ramp(
		PackedFloat32Array([0.0, 0.24, 0.46, 0.70, 1.0]),
		PackedColorArray([
			Color(0.84, 0.84, 0.84, 1.0), Color(1.02, 1.02, 1.02, 1.0),
			Color(0.90, 0.90, 0.90, 1.0), Color(1.10, 1.10, 1.10, 1.0),
			Color(0.94, 0.94, 0.94, 1.0),
		]))
	beds.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var alb: NoiseTexture2D = _tex("trav_alb", field, px, beds, false, 1.0)
	# a bedding plane that is softer is both duller and slightly lower, so the
	# same field drives gloss and relief
	var rgh: NoiseTexture2D = _tex("trav_rgh", field, px, _grey_ramp(0.58, 0.34), false, 1.0)
	var nrm: NoiseTexture2D = _tex("trav_nrm", field, px, null, true, 1.6)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.745, 0.705, 0.62), _mineral(tint)), 0.96), 0.45, 0.0, _uv_bedded(tile_m, 12.0), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.45, rgh, 0.58, 0.34)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.45
	# the pores: round voids, cellular DISTANCE, 2.4 mm, on the isotropic uv2
	_apply_grain(m, "trav", 1704, 2.4, 0.80, 3.0, 0.90, true)
	_apply_soil(m, soil)
	return m


## Fair-faced cast concrete. The widest roughness spread in the set: concrete's
## laitance skin polishes unevenly against the formwork and that uneven sheen is
## the material's signature.
## Bands: macro 3.6 m; meso 8 octaves to 28 mm (6 px at 768) — form panel and
## pour mottle; micro 12 -> 1.6 mm, the coarsest grain band in the set, because
## concrete's surface aggregate genuinely is millimetres and not tenths.
static func _make_concrete(tint: Color, soil: float) -> StandardMaterial3D:
	var tile_m: float = 3.6
	var px: int = _sz(TEX_MID)
	var field: FastNoiseLite = _band_fbm(1801, tile_m, 3600.0, 28.0, px, 0.70, 0.0, 0.0)
	var alb: NoiseTexture2D = _tex("conc_alb", field, px, _grey_ramp(0.84, 1.12), false, 1.0)
	var rgh: NoiseTexture2D = _tex("conc_rgh", field, px, _grey_ramp(0.72, 1.02), false, 1.0)
	var nrm: NoiseTexture2D = _tex("conc_nrm", field, px, null, true, 1.6)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.505, 0.50, 0.49), _mineral(tint)), 0.98), 0.76, 0.0, _uv(tile_m), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.76, rgh, 0.72, 1.02)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.62
	_apply_grain(m, "conc", 1804, 12.0, 1.60, 4.0, 0.90, false)
	_apply_soil(m, soil)
	return m


## Oak — and the direction problem, which is the interesting part.
##
## WHAT WAS MEASURED: "a 1D horizontal blur with no pore, no ray fleck, no end
## grain — MDF with a wood decal". All four are true of v2 and all four have
## different causes.
##
## DIRECTION CONSISTENCY, i.e. how a beam and its architrave are made to agree.
## A world-triplanar material cannot know which way a given box is long — that
## information is in the geometry, not the shader. v2 answered by stretching Y
## only (uv1_scale 0.26/2.10/0.26), which means: on a vertical face the grain runs
## horizontally, and on a HORIZONTAL face — the top of every beam — the two
## sampled axes are both 0.26, so there is no stretch at all and the grain is an
## isotropic blur. That is the "1D horizontal blur" exactly.
##
## The answer here is an explicit `axis` argument naming the WORLD axis the boards
## run along, and three cached materials rather than one (still O(roles)). The
## stretch is then declared in WORLD space, which buys three things at once:
##   * every piece sharing an axis samples the SAME world-space field, so a beam
##     and its architrave do not merely look similar — their grain lines are
##     literally continuous across the joint, the same guarantee uv1 world
##     triplanar already gives for plaster;
##   * on the two faces parallel to the run, both sampled axes carry one long and
##     one short scale, so the grain runs along the piece on the sides AND on the
##     top;
##   * on the two faces perpendicular to the run, both sampled axes carry the
##     SHORT scale — 160 mm — so the ends come out isotropic and fine-grained.
##     That is END GRAIN, and it is free.
## A caller that gets the axis wrong gets end grain down the length of a beam,
## which is loud and obvious. That is the correct failure mode for this argument.
##
## SIZES. 20:1: 3.2 m along the boards, 0.16 m across. At 1024 px the across-grain
## pixel is 0.156 mm, so the 7-octave fbm's finest octave (16 px) is a 2.5 mm ring
## across and a ~50 mm grain line along. Oak's earlywood-latewood ring spacing is
## 2-5 mm. Ridged + domain warp keeps the lines connected and bends them into
## lenses, which is as close to RAY FLECK as one field gets — true fleck is a
## second, perpendicular field and is honestly not here.
## PORE SPECKLE is cellular voids at 0.45 mm in the isotropic detail band. It
## cannot live on uv1 for the same reason travertine's pores could not: a 20:1
## uv1 turns a round pore into a 20:1 smear.
static func _make_oak(tint: Color, soil: float, axis: String) -> StandardMaterial3D:
	var across_m: float = 0.16
	var along_m: float = 3.2
	var px: int = _sz(TEX_LARGE)
	var field: FastNoiseLite = _band_ridged(1901, across_m, 160.0, 2.5, px, 0.58, 6.0)
	var alb: NoiseTexture2D = _tex("oak_alb", field, px, _grey_ramp(0.70, 1.14), false, 1.0)
	# the raised grain wears smooth and the open pores stay matt, so gloss is
	# INVERTED against the same field rather than hung on an unrelated one
	var rgh: NoiseTexture2D = _tex("oak_rgh", field, px, _grey_ramp(1.0, 0.58), false, 1.0)
	var nrm: NoiseTexture2D = _tex("oak_nrm", field, px, null, true, 1.4)
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.245, 0.155, 0.095), tint), 0.92), 0.48, 0.0, _uv_grain(along_m, across_m, axis), 4.5)
	m.albedo_texture = alb
	_rough(m, 0.48, rgh, 1.0, 0.58)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.48
	_apply_grain(m, "oak", 1904, 0.45, 0.45, 3.0, 0.90, true)
	_apply_soil(m, soil)
	return m


## Aged brass. ONE noise field, FOUR correlated maps — and, for the first time,
## AT ONE RESOLUTION. v2 generated the albedo at 512 and the metallic, roughness
## and normal at 256 off the same field at the same frequency, so the metal/oxide
## boundary in the albedo sat at half the world size of the metal/oxide boundary
## in the metallic map. The file's own comment says an uncorrelated patina reads
## as a decal; a correlation broken by resolution reads exactly the same way and
## is much harder to see in code.
## Bands: macro 0.9 m (a rail is small, so its macro tile is too); meso 7 octaves
## to 14 mm; micro 2.0 -> 0.25 mm — polishing scratch and oxide tooth.
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

	var tile_m: float = 0.9
	var px: int = _sz(TEX_BASE)
	var field: FastNoiseLite = _band_fbm(2001, tile_m, 900.0, 14.0, px, 0.62, 0.0, 0.0)
	var alb: NoiseTexture2D = _tex("brass_alb_" + pkey, field, px, alb_ramp, false, 1.0)
	var met: NoiseTexture2D = _tex("brass_met_" + pkey, field, px, met_ramp, false, 1.0)
	var rgh: NoiseTexture2D = _tex("brass_rgh_" + pkey, field, px, rgh_ramp, false, 1.0)
	var nrm: NoiseTexture2D = _tex("brass_nrm", field, px, null, true, 0.9)

	# albedo_color stays white: the ramp already carries the true colours, and a
	# tint here would desaturate the metal's F0
	var m: StandardMaterial3D = _base(Color.WHITE, 0.92, 1.0, _uv(tile_m), 4.0)
	m.albedo_texture = alb
	m.metallic_texture = met
	m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness_texture = rgh
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.34
	_apply_grain(m, "brass", 2004, 2.0, 0.25, 2.0, 0.96, false)
	return m


## Soffit plaster: brighter and flatter than the wall. A ceiling is a reflector,
## not a feature — it should disappear and give back light. 0.860/0.865/0.875
## against plaster's warm 0.72/0.705/0.675 is a deliberate hue split that survives
## a modest wash and gives the room vertical colour structure.
static func _make_ceiling(tint: Color) -> StandardMaterial3D:
	var tile_m: float = 3.2
	var px: int = _sz(TEX_SMALL)
	var field: FastNoiseLite = _band_fbm(2101, tile_m, 3200.0, 200.0, px, 0.62, 0.0, 0.0)
	var alb: NoiseTexture2D = _tex("ceil_alb", field, px, _grey_ramp(0.93, 1.07), false, 1.0)
	var nrm: NoiseTexture2D = _tex("ceil_nrm", field, px, null, true, 0.4)
	# shares gallery white's roughness field — same key, already in the cache
	var rgh: NoiseTexture2D = _gw_rough_tex()
	var m: StandardMaterial3D = _base(_lift(_tinted(Color(0.860, 0.865, 0.875), tint), 1.00), 0.94, 0.0, _uv(tile_m), 4.0)
	m.albedo_texture = alb
	_rough(m, 0.94, rgh, 0.93, 1.0)
	m.normal_enabled = true
	m.normal_texture = nrm
	m.normal_scale = 0.13
	_apply_grain(m, "ceil", 2104, 1.2, 0.30, 2.0, 0.97, false)
	return m


## Vitrine glass. The smudge map is the point: perfectly clean glass has no
## surface and reads as a hole. Roughness runs 0.018-0.10 across fingerprints;
## the grain band adds the 0.15 mm wipe tooth that catches a grazing highlight.
## NOTE the mesh author must set cast_shadow = SHADOW_CASTING_SETTING_OFF on
## glass instances, and expect transparency sort order to be per-object.
static func _make_glass(tint: Color) -> StandardMaterial3D:
	var tile_m: float = 1.2
	var px: int = _sz(TEX_SMALL)
	var field: FastNoiseLite = _band_fbm(2201, tile_m, 1200.0, 37.5, px, 0.60, 0.0, 0.0)
	var rgh: NoiseTexture2D = _tex("glass_rgh", field, px, _grey_ramp(0.18, 1.0), false, 1.0)
	var m: StandardMaterial3D = _base(Color(0.86 * tint.r, 0.90 * tint.g, 0.90 * tint.b, 0.09), 0.06, 0.0, _uv(tile_m), 4.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic_specular = 0.55          # IOR ~1.52 rather than the 1.5 default
	_rough(m, 0.06, rgh, 0.18, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_apply_grain(m, "glass", 2204, 0.80, 0.15, 0.6, 0.99, false)
	return m


# ── the scale model, in code ─────────────────────────────────────────────────

## THE one place a noise frequency is produced. feature_m = tile_m/(f*px), solved
## for f. `tile_m` is the world size of one texture repeat ON THE AXIS the
## millimetre figure refers to — for anisotropic roles that is the SHARP axis.
static func _freq_for_mm(mm: float, tile_m: float, px: int) -> float:
	return tile_m / (maxf(mm, 0.005) * 0.001 * maxf(float(px), 1.0))


## How many octaves it takes to walk from the macro feature down to the meso one,
## clamped so the finest octave never exceeds NYQUIST_LIMIT cycles per pixel. A
## texture asked for detail past that stores aliasing, and aliasing on a floor is
## the exact shimmer that reads as "game" in a headset.
static func _band_octaves(macro_mm: float, meso_mm: float, f0: float, lacunarity: float = 2.0) -> int:
	var ratio: float = maxf(macro_mm, 0.001) / maxf(meso_mm, 0.001)
	var lac: float = maxf(lacunarity, 1.0001)
	var n: int = int(round(log(maxf(ratio, 1.0)) / log(lac))) + 1
	while n > 1 and f0 * pow(lac, float(n - 1)) > NYQUIST_LIMIT:
		n -= 1
	return clampi(n, 1, 12)


## The base octave's share of the total contrast — i.e. how much of the albedo
## swing the MACRO band owns. FastNoiseLite normalises fbm by 1/sum(|gain|^i), so
## this is exact rather than an estimate. Printed by scale_report().
static func _macro_share(octaves: int, gain: float) -> float:
	var amp: float = 1.0
	var total: float = 1.0
	for i in range(1, maxi(octaves, 1)):
		amp *= absf(gain)
		total += amp
	return 1.0 / maxf(total, 0.0001)


## A role's uv1 field: base octave at `macro_mm`, finest at `meso_mm`, frequency
## derived from the resolution actually in use so quality_scale cannot move it.
static func _band_fbm(seed_value: int, tile_m: float, macro_mm: float, meso_mm: float, px: int, gain: float, warp_amp: float, warp_freq: float) -> FastNoiseLite:
	var f0: float = _freq_for_mm(macro_mm, tile_m, px)
	var oct: int = _band_octaves(macro_mm, meso_mm, f0, 2.0)
	return _fbm(seed_value, f0, oct, gain, warp_amp, warp_freq)


## Same, ridged: peaks are thin connected lines rather than blobs, which is what
## a marble vein and a wood grain structurally are.
static func _band_ridged(seed_value: int, tile_m: float, macro_mm: float, meso_mm: float, px: int, gain: float, warp: float) -> FastNoiseLite:
	var f0: float = _freq_for_mm(macro_mm, tile_m, px)
	var oct: int = _band_octaves(macro_mm, meso_mm, f0, 2.0)
	return _ridged(seed_value, f0, oct, gain, warp)


## uv1_scale for an isotropic role: repeats per metre.
static func _uv(tile_m: float) -> Vector3:
	var s: float = 1.0 / maxf(tile_m, 0.001)
	return Vector3(s, s, s)


## uv1_scale for a wall whose pattern sweeps horizontally (plaster trowel arcs).
## `tile_m` is the VERTICAL (sharp) tile; the horizontal tile is `stretch` times
## bigger, so features come out `stretch` times wider than tall.
static func _uv_aniso(tile_m: float, stretch: float) -> Vector3:
	var sv: float = 1.0 / maxf(tile_m, 0.001)
	var sh: float = sv / maxf(stretch, 0.001)
	return Vector3(sh, sv, sh)


## uv1_scale for a bedded stone: laminae `ratio`:1 longer than they are thick.
static func _uv_bedded(tile_m: float, ratio: float) -> Vector3:
	var sv: float = 1.0 / maxf(tile_m, 0.001)
	var sh: float = sv / maxf(ratio, 0.001)
	return Vector3(sh, sv, sh)


## uv1_scale for a board running along a WORLD axis. The long tile goes on that
## axis and the short tile on the other two, which is what puts grain along the
## sides and the top and END GRAIN on the ends. See _make_oak.
static func _uv_grain(along_m: float, across_m: float, axis: String) -> Vector3:
	var a: float = 1.0 / maxf(along_m, 0.001)
	var c: float = 1.0 / maxf(across_m, 0.001)
	match axis:
		"y", "Y":
			return Vector3(c, a, c)
		"z", "Z":
			return Vector3(c, c, a)
	return Vector3(a, c, c)


# ── the micro band ───────────────────────────────────────────────────────────

## THE 0.3 MM BAND. Attaches a detail normal (plus a near-white detail albedo, see
## below) on UV2 at GRAIN_TILE_M — the band that makes light break correctly at
## 1 m, and the one v2 had no slot for at all.
##
## `top_mm`/`bottom_mm` bracket the band: an fbm from the coarse end to the fine
## end, so plaster gets float texture AND aggregate grain out of one 256 px map.
## `cellular` swaps the fbm for cellular DISTANCE — round voids, for oak's pore
## speckle and travertine's pores, both of which are unrepresentable on their
## anisotropic uv1.
##
## THREE THINGS THAT WILL BITE WHOEVER EDITS THIS:
##   * detail_albedo must NEVER be null. Null samples as opaque white and, under
##     the default MIX blend, replaces ALBEDO with white. It is set here to a
##     near-white grain under BLEND_MODE_MUL: safe, and a legitimate 3-6% micro
##     albedo into the bargain.
##   * detail_tex.a is the blend weight for BOTH albedo and normal, and Godot
##     mixes the normal through it TWICE — the micro band's real weight is a*a.
##   * uv2_triplanar + uv2_world_triplanar are not optional. A BoxMesh has no UV2
##     array; without world triplanar the detail slot samples a constant.
static func _apply_grain(m: StandardMaterial3D, key: String, seed_value: int, top_mm: float, bottom_mm: float, bump: float, albedo_low: float, cellular: bool) -> void:
	if not detail_grain:
		return
	var px: int = _sz(TEX_DETAIL)
	var f_top: float = _freq_for_mm(top_mm, GRAIN_TILE_M, px)
	var grain: FastNoiseLite
	if cellular:
		grain = _cells(seed_value, f_top, 0.9, FastNoiseLite.RETURN_DISTANCE, 1, 2.0, 0.5)
	else:
		var oct: int = _band_octaves(top_mm, bottom_mm, f_top, 2.0)
		grain = _fbm(seed_value, f_top, oct, 0.62, 0.0, 0.0)
	m.detail_enabled = true
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _tex(key + "_dalb", grain, px, _grey_ramp_a(albedo_low, 1.0, DETAIL_MIX), false, 1.0)
	m.detail_normal = _tex(key + "_dnrm", grain, px, null, true, bump)
	m.uv2_scale = _uv(GRAIN_TILE_M)
	m.uv2_offset = Vector3.ZERO
	m.uv2_triplanar = true
	m.uv2_world_triplanar = true
	m.uv2_triplanar_sharpness = 4.0


# ── shared construction helpers ──────────────────────────────────────────────

## Every architectural surface starts here. World-space triplanar is not a nicety
## in this scene, it is the requirement: the museum is built from hundreds of
## separate 1 m boxes, and per-mesh UVs would stamp an identical tile of noise
## into every one — a visible grid, worse than the flat colour it replaced.
static func _base(albedo: Color, rough: float, metal: float, world_scale: Vector3, sharpness: float = 4.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.5
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	# anisotropic mipmaps: without this, a noise-mapped floor shimmers at grazing
	# angles, which is the specific tell that reads as "game" in VR. It matters
	# more now than it did: an 11 mm chip on a 7 px cell is exactly the content
	# that aliases if the sampler is allowed to point-sample it at 8 m.
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# THE CHEAP EDGE DARKENING (see header). A plain BoxMesh carries no COLOR
	# array, so the shader gets white and this flag is a no-op — costs nothing.
	m.vertex_color_use_as_albedo = vertex_wear
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = world_scale
	# sharpness is an exponent on the blend weights; 1.0 (the default) smears each
	# projection a third of the way around a box corner and turns crisp
	# architecture to mush. 4-5 keeps the corner tight.
	m.uv1_triplanar_sharpness = sharpness
	return m


## Godot computes ROUGHNESS = roughness * texture, so a material that sets
## roughness 0.34 and then hangs a 0.5-1.0 ramp on it does NOT average 0.34, it
## averages 0.255. `target` is the MEAN the surface should land on; the scalar is
## derived. Every roughness number quoted in this file is a mean, and true.
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
## same rhythm across the whole building. Sampled through each material's own
## uv1_scale (the AO slot is a uv1 consumer), so its world size is one to two
## features per tile whatever the role — which is the macro band by construction.
static func _grime_tex() -> NoiseTexture2D:
	var px: int = _sz(TEX_SMALL)
	return _tex("grime", _fbm(2301, 2.4 / float(px), 4, 0.58, 0.0, 0.0), px, _grey_ramp(0.34, 1.0), false, 1.0)


## Gallery white's roughness field, factored out because the ceiling shares it —
## and a shared field is only shared if every parameter matches, resolution
## included. Inlining this twice is how the brass and marble decorrelation bugs
## got in.
static func _gw_rough_tex() -> NoiseTexture2D:
	var px: int = _sz(TEX_SMALL)
	return _tex("gw_rgh", _fbm(1502, _freq_for_mm(60.0, 3.2, px), 3, 0.55, 0.0, 0.0), px, _grey_ramp(0.93, 1.0), false, 1.0)


## Noise textures are cached by an explicit key. Everything that varies the image
## MUST be in the key — the streamer asks for the same surface hundreds of times
## and each miss costs a threaded regeneration. Frequencies are now derived from
## `size`, and `size` is in the key, so a quality change cannot alias two
## different images onto one entry (set_quality clears the cache regardless).
static func _tex(key_base: String, noise: FastNoiseLite, size: int, ramp: Gradient, as_normal: bool, bump: float, skirt: float = 0.15) -> NoiseTexture2D:
	var mode: String = "n" if as_normal else "c"
	var key: String = "%s|%d|%s|%.2f|%.2f" % [key_base, size, mode, bump, skirt]
	if _tex_cache.has(key):
		var cached: NoiseTexture2D = _tex_cache[key]
		return cached
	var t := NoiseTexture2D.new()
	t.width = size
	t.height = size
	t.generate_mipmaps = true
	t.normalize = true
	# seamless matters because world triplanar tiles the texture across the whole
	# endless corridor; a visible seam every 1.8 m would be a ruler on the floor.
	# The skirt is a blend width and it GHOSTS low-frequency content, so roles
	# whose base octave is one feature per tile (the floors) pass a smaller one.
	t.seamless = true
	t.seamless_blend_skirt = clampf(skirt, 0.0, 1.0)
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


## `warp_amp` is in PIXELS (FastNoiseLite warps its input coordinates, and its
## input here is the pixel grid), so callers convert from millimetres through the
## same mm-per-pixel figure everything else uses. 0 disables the warp.
static func _fbm(seed_value: int, freq: float, octaves: int, gain: float = 0.5, warp_amp: float = 0.0, warp_freq: float = 0.0) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_value
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = maxi(octaves, 1)
	n.fractal_lacunarity = 2.0
	n.fractal_gain = gain
	if warp_amp > 0.0:
		n.domain_warp_enabled = true
		n.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
		n.domain_warp_amplitude = warp_amp
		n.domain_warp_frequency = warp_freq if warp_freq > 0.0 else freq * 0.6
		n.domain_warp_fractal_octaves = 2
	return n


## Ridged fractal: peaks are thin connected lines rather than blobs. Domain warp
## bends those lines so they wander like a vein or a wood grain instead of running
## straight. `warp` is the amplitude in noise units; 0 disables it.
static func _ridged(seed_value: int, freq: float, octaves: int, gain: float = 0.5, warp: float = 0.0) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.seed = seed_value
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n.fractal_octaves = maxi(octaves, 1)
	n.fractal_lacunarity = 2.0
	n.fractal_gain = gain
	if warp > 0.0:
		n.domain_warp_enabled = true
		n.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
		n.domain_warp_amplitude = warp
		n.domain_warp_frequency = freq * 0.6
		n.domain_warp_fractal_octaves = 2
	return n


## Cellular. RETURN_CELL_VALUE gives flat random cells (terrazzo chips);
## RETURN_DISTANCE gives cones, which read as pores or voids in a normal map.
##
## `octaves` > 1 is what lets terrazzo carry a macro band it could not otherwise
## have. An fbm of two cellular octaves with a large `lacunarity` puts a pour-bay
## field and a chip field in ONE image; `gain` ABOVE 1 inverts the usual weighting
## so the fine octave dominates — FastNoiseLite normalises by 1/sum(|gain|^i), so
## gain 4.0 over two octaves is exactly 20% bay and 80% chip. That is the only
## way to get three bands out of a material that has two uv scales and a meso
## pattern (hard-edged chips) that cannot be summed with anything.
static func _cells(seed_value: int, freq: float, jitter: float, ret: int, octaves: int = 1, lacunarity: float = 2.0, gain: float = 0.5) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.seed = seed_value
	n.frequency = freq
	if octaves > 1:
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = octaves
		n.fractal_lacunarity = lacunarity
		n.fractal_gain = gain
	else:
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
## offsets 0 and 1, so recolouring them in place is all that is needed. `low` may
## exceed `high` (oak inverts its roughness against the grain).
static func _grey_ramp(low: float, high: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(low, low, low, 1.0))
	g.set_color(1, Color(high, high, high, 1.0))
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	return g


## Same, with an ALPHA — which the detail slot reads as its blend weight for both
## albedo and normal. NoiseTexture2D writes the gradient's alpha straight through
## into an RGBA8 image, so this is how DETAIL_MIX reaches the shader.
static func _grey_ramp_a(low: float, high: float, alpha: float) -> Gradient:
	var g := Gradient.new()
	var a: float = clampf(alpha, 0.0, 1.0)
	g.set_color(0, Color(low, low, low, a))
	g.set_color(1, Color(high, high, high, a))
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	return g


## An albedo texture MULTIPLIES albedo_color, and a ramp whose mean is not 1.0
## shifts the result away from the measured reflectance the material was authored
## to. Pre-divide by the ramp's mean so the surface averages what the comment
## claims. Ramps in this version are written around a mean of ~1.0 for exactly
## this reason, so most calls pass 1.00 and this is a no-op that documents itself.
static func _lift(c: Color, ramp_mean: float) -> Color:
	var k: float = 1.0 / maxf(0.05, ramp_mean)
	return Color(minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0), 1.0)


static func _tinted(base: Color, tint: Color) -> Color:
	return Color(base.r * tint.r, base.g * tint.g, base.b * tint.b, 1.0)


## Mineral roles take a template tint as a HINT. The palettes feeding this library
## are qualitative chart-legend hues at full chroma; multiplied into a stone they
## produce a colour swatch, and a brown one is half of why the terrazzo read as
## camouflage rather than as aggregate. This pulls the tint toward its own
## luminance, so HUE survives, CHROMA is cut, and BRIGHTNESS is untouched — it
## therefore cannot fight an exposure or bounce-light change made elsewhere.
static func _mineral(tint: Color) -> Color:
	var k: float = clampf(mineral_chroma, 0.0, 1.0)
	var l: float = tint.get_luminance()
	return Color(
		lerpf(l, tint.r, k),
		lerpf(l, tint.g, k),
		lerpf(l, tint.b, k),
		1.0)


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
## requirement and 64-steps give finer quality control than doubling. Every
## frequency in this file is derived from the value this returns, so a
## quality_scale change moves resolution WITHOUT moving feature size.
static func _sz(base: int) -> int:
	var raw: int = int(round(float(base) * quality_scale / 64.0)) * 64
	return clampi(raw, 64, 2048)
