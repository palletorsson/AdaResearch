extends RefCounted

## THE QUEER GLOSS (2026-09-03, Palle: "add super glossy and queer materials").
##
## One material library for every dream body, so a family does not have to invent
## its own idea of shine. Nothing here is subtle: these are latex, patent, oil
## slick, holographic foil, candy glaze, chrome and pearl - surfaces that announce
## themselves, that look wet, that change colour as you walk past. The corpus
## already knows the two traps and both are handled here:
##
##   ACES EATS SATURATED PINK. The museum renders ACES with tonemap_white 6.0 and
##   compresses saturated reds and magentas toward a washed orange-grey - the
##   sledgehammer photographed hot pink on the bench and read grey in the hall.
##   So the hot colours are carried by EMISSION as well as albedo, and the museum
##   has glow on, which is what makes them bloom instead of flatten.
##
##   A MIRROR PHOTOGRAPHS BLACK. metallic 1.0 with nothing to reflect renders
##   near-black in a bare capture scene (gehry_metal's own note). Every metal here
##   carries a painted streak texture and a trace of emission so it has something
##   to be bright with.
##
## Iridescence is real here, not a colour choice: RIM and its tint give the
## grazing-angle shift a foil has, and the painted sweep texture puts the second
## and third hue INTO the surface, so one body shows magenta at the shoulder and
## cyan at the hip from a single standpoint.
##
## STATIC AND PURE. Give it a name and a colour, get a material. Nothing touches
## the tree, nothing loads from disk, textures are painted in code - the same
## contract every builder under bodies/ works to.

const FINISHES: Array[String] = ["latex", "patent", "oilslick", "holo", "candy",
	"chrome", "pearl", "neon", "wet", "matte"]

## The palette these bodies are allowed to be loud in.
const QUEER: Dictionary = {
	"hot_pink": Color(1.0, 0.18, 0.62),
	"magenta": Color(0.86, 0.12, 0.78),
	"violet": Color(0.55, 0.24, 0.92),
	"cyan": Color(0.15, 0.85, 0.95),
	"acid": Color(0.62, 0.95, 0.20),
	"tangerine": Color(1.0, 0.45, 0.10),
	"lemon": Color(0.98, 0.85, 0.14),
	"lilac": Color(0.78, 0.62, 0.95),
	"mint": Color(0.42, 0.95, 0.72),
	"blood": Color(0.85, 0.06, 0.24),
	"cream": Color(0.97, 0.93, 0.86),
	"ink": Color(0.06, 0.05, 0.09),
}


## One colour from the palette, dealt.
static func queer_colour(rng: RandomNumberGenerator) -> Color:
	var keys: Array = QUEER.keys()
	return QUEER[keys[rng.randi_range(0, keys.size() - 1)]]


## A finish, by name, in a colour.
##
## `finish` is one of FINISHES; anything else falls back to a plain gloss, so a
## builder passing a typo gets a surface rather than a null.
static func skin(finish: String, base: Color, rng: RandomNumberGenerator = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	match finish:
		"latex":
			# Rubber: deep colour, tight bright highlight, a soft edge glow.
			m.roughness = 0.14
			m.metallic = 0.0
			m.clearcoat_enabled = true
			m.clearcoat = 0.85
			m.clearcoat_roughness = 0.06
			m.rim_enabled = true
			m.rim = 0.75
			m.rim_tint = 0.5
			m.emission_enabled = true
			m.emission = base
			m.emission_energy_multiplier = 0.12
		"patent":
			# Patent leather: a mirror over a colour, hardest highlight of all.
			m.roughness = 0.045
			m.metallic = 0.25
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.02
			m.rim_enabled = true
			m.rim = 0.55
		"oilslick":
			# The film on water: base near-black, the colour all in the sweep.
			m.albedo_color = Color(base.r * 0.25, base.g * 0.25, base.b * 0.3)
			m.albedo_texture = sweep_texture(base, rng, 3)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.55, 0.55, 0.55)
			m.roughness = 0.08
			m.metallic = 0.85
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.03
			m.rim_enabled = true
			m.rim = 1.0
			m.rim_tint = 1.0
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission_energy_multiplier = 0.55
		"holo":
			# Holographic foil: a bright sweep of the whole palette, lit from inside.
			m.albedo_texture = sweep_texture(base, rng, 5)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.42, 0.42, 0.42)
			m.roughness = 0.06
			m.metallic = 0.6
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.02
			m.rim_enabled = true
			m.rim = 1.0
			m.rim_tint = 1.0
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission_energy_multiplier = 0.9
		"candy":
			# Sugar glaze: light colour, thick clearcoat, a warm inner glow.
			m.roughness = 0.09
			m.metallic = 0.0
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.04
			m.emission_enabled = true
			m.emission = base
			m.emission_energy_multiplier = 0.3
			m.rim_enabled = true
			m.rim = 0.45
		"chrome":
			# A mirror that cannot photograph black: streaks and a trace of glow.
			m.albedo_color = Color(0.88, 0.89, 0.93).lerp(base, 0.18)
			m.albedo_texture = brushed_texture(rng)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3(0.7, 0.7, 0.7)
			m.metallic = 1.0
			m.roughness = 0.12
			m.emission_enabled = true
			m.emission = base
			m.emission_energy_multiplier = 0.10
		"pearl":
			# Nacre: pale body, the colour showing only at the grazing angle.
			m.albedo_color = Color(0.96, 0.94, 0.95).lerp(base, 0.22)
			m.roughness = 0.16
			m.metallic = 0.35
			m.clearcoat_enabled = true
			m.clearcoat = 0.9
			m.clearcoat_roughness = 0.08
			m.rim_enabled = true
			m.rim = 1.0
			m.rim_tint = 1.0
			m.emission_enabled = true
			m.emission = base
			m.emission_energy_multiplier = 0.16
		"neon":
			# A lit tube: the colour IS the light.
			m.albedo_color = base
			m.roughness = 0.25
			m.emission_enabled = true
			m.emission = base
			m.emission_energy_multiplier = 3.2
			m.rim_enabled = true
			m.rim = 0.8
			m.rim_tint = 1.0
		"wet":
			# Just poured: a colour under a film of water.
			m.roughness = 0.05
			m.metallic = 0.1
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.01
			m.rim_enabled = true
			m.rim = 0.9
			m.rim_tint = 0.8
			m.emission_enabled = true
			m.emission = base
			m.emission_energy_multiplier = 0.08
		"matte":
			m.roughness = 0.92
			m.metallic = 0.0
		_:
			m.roughness = 0.18
			m.clearcoat_enabled = true
			m.clearcoat = 0.8
	return m


## The iridescent sweep: a band of the palette rolling across the surface, so one
## body shows two or three hues from a single standpoint. Seamless in u, because
## triplanar wraps it round a limb and a visible join reads as a crack.
static func sweep_texture(base: Color, rng: RandomNumberGenerator, bands: int = 4) -> ImageTexture:
	var r := rng if rng != null else RandomNumberGenerator.new()
	var w := 192
	var h := 192
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var keys: Array = QUEER.keys()
	var picks: Array = []
	picks.append(base)
	for i in range(maxi(1, bands - 1)):
		picks.append(QUEER[keys[r.randi_range(0, keys.size() - 1)]])
	var phase: float = r.randf() * TAU
	var tilt: float = r.randf_range(0.4, 1.6)
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			# integer frequencies in u so the tile wraps
			var t: float = 0.5 + 0.5 * sin(u * TAU * 2.0 + v * TAU * tilt + phase)
			var f: float = t * float(picks.size())
			var i0: int = int(floor(f)) % picks.size()
			var i1: int = (i0 + 1) % picks.size()
			var k: float = f - floor(f)
			var c: Color = (picks[i0] as Color).lerp(picks[i1] as Color, smoothstep(0.0, 1.0, k))
			# a fine ripple, so the sweep has grain and does not band
			var g: float = 0.94 + 0.06 * sin(u * TAU * 17.0 + v * TAU * 11.0)
			img.set_pixel(x, y, Color(clampf(c.r * g, 0, 1), clampf(c.g * g, 0, 1), clampf(c.b * g, 0, 1)))
	return ImageTexture.create_from_image(img)


## Brushed metal: what stops a mirror photographing black.
static func brushed_texture(rng: RandomNumberGenerator = null) -> ImageTexture:
	var r := rng if rng != null else RandomNumberGenerator.new()
	var w := 128
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in range(h):
		for x in range(w):
			var streak: float = 0.86 + 0.14 * sin(float(x) * 0.9 + sin(float(y) * 0.12) * 2.0)
			var grain: float = 0.97 + 0.03 * r.randf()
			var v: float = clampf(streak * grain, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, minf(1.0, v * 1.02)))
	return ImageTexture.create_from_image(img)


## A whole body's worth of finishes, dealt from one seed: the main surface, a
## second for accents, and the finish name, so a builder can stay consistent.
static func outfit(rng: RandomNumberGenerator, finish: String = "") -> Dictionary:
	var f: String = finish
	if f == "":
		f = FINISHES[rng.randi_range(0, FINISHES.size() - 2)]   # never "matte" by accident
	var main: Color = queer_colour(rng)
	var accent: Color = queer_colour(rng)
	var tries: int = 0
	while accent.is_equal_approx(main) and tries < 6:
		accent = queer_colour(rng)
		tries += 1
	return {
		"finish": f,
		"main": main,
		"accent": accent,
		"skin": skin(f, main, rng),
		"accent_skin": skin(f, accent, rng),
	}
