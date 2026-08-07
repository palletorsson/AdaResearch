extends RefCounted
class_name EmLighting
# em_lighting.gd — the endless museum's architectural lighting rig.
#
#   EmLighting.rig_segment(seg, w, h, accent, slots)                  # contract
#   EmLighting.rig_segment(seg, w, h, accent, slots, {"tile": tile})  # smarter
#
# WHY A RIG AND NOT MORE LIGHTS. The baseline scene is one DirectionalLight3D at
# energy 1.1 over ambient 1.2 — every surface receives roughly the same amount of
# light from roughly the same direction, which is exactly the condition under
# which a renderer produces no shape. Real museums do the opposite: they run the
# ambient DOWN and spend the whole budget on a small number of aimed sources,
# because contrast is what makes plaster read as plaster and bronze as bronze.
# This file is that spend.
#
# The rig installs six families, in the order a lighting designer specifies them:
#
#   1. AMBIENT KEY  two very low, shadowless omnis per segment — one over the
#      gallery, one over the vestibule. Not "the light": a floor under the black,
#      so unlit corners keep material information instead of crushing to zero.
#      One omni could not floor a 30-cell gallery AND a 4-cell lobby, and the
#      proof of that was a gallery deck at 0.03-0.08 carrying no material at all.
#
#   2. DAYLIGHT  cool (6800 K) top-light down the gallery axis, plus a spill at
#      the threshold gap. Kanazawa, Chichu, the Neue Nationalgalerie and the
#      Grande Galerie are all top-lit or clerestory-lit buildings, and the
#      corridor's own mechanism — an open joint between two museums — is exactly
#      where a real building puts glazing. The fixtures hang ABOVE em_detail's
#      roof and reach the room only through its 550 mm slots, and they cast, so
#      the coffer cuts the cone into bands. That is the whole family: get either
#      the height or the shadow wrong and it is a projector aimed at a soffit.
#
#   3. KEYS ON THE ART  focused spots on hero plinths and podiums. This is how a
#      museum actually lights art: a narrow beam from above and slightly in
#      FRONT of the approach, so the piece is modelled instead of flat-topped,
#      plus one cool rim behind the first hero. The rim is the difference
#      between an object photographed and an object placed in a room.
#
#   4. WALL WASH  grazing spots along the longest wall runs. In a gallery the
#      walls ARE the light source for everything else — the bounce off a washed
#      wall is what fills the room. With SDFGI on, that is literally what
#      happens here. The museum's accent enters here at 4%, and see _palette for
#      why that number came down from 10%.
#
#   5. THRESHOLD  warm (2450 K) coves in the vestibule and a three-source grazer
#      riding the ember strip. Warm at the joint against cool in the gallery is
#      the temperature contrast that makes an interior read as an interior and
#      not as a lit box.
#
#   6. FLOOR FILL  a small cool omni over each floor slot, which has no plinth
#      to key off and would otherwise sit in whatever the wall wash leaves it.
#
# COLOUR TEMPERATURE IS THE CHEAPEST QUALITY LEVER HERE. Every light is specified
# in kelvin and converted through Tanner Helland's blackbody approximation, then
# pulled TEMP_DESAT back toward white so it reads as temperature rather than as a
# coloured gel. 2450 K circulation against 6800 K galleries is roughly a real
# museum's own split between its incandescent lobbies and its north light — and
# the split is only worth stating because the frames now show it. At the old
# 0.35 desaturation over a 2700/6300 span, four proof shots measured 2-4 degrees
# of hue spread from ceiling to floor. The design was in the file and not in the
# picture.
#
# BUDGET — 26 lights per segment (hard cap), 6 of them shadow-casting (hard cap).
# By construction the families can only ask for 26: 2 ambient + 3 daylight +
# 3 hero + 1 rim + 3 podium + 2 cove + 3 grazer + 5 wall wash + 2 floor fill.
# A typical segment (w 15, h 30, ~10 slots) lands at 21-24 lights and 4-6 shadow
# casters. The caps are enforced by a counter, not by that arithmetic — a
# pathological template cannot overspend.
#
# The streamer keeps ~3 segments live (BUILD_AHEAD_M 24 / KEEP_BEHIND_M 70), so
# the worst case IN THE TREE is 72 lights and 18 shadow maps. That would be
# ruinous if it were all resident, which is why every light carries distance
# fade and every shadow-caster drops its map at 22-26 m: past that they keep
# contributing light and stop costing a render pass. What a walker actually sees
# is one segment's 24 lights and 4-6 live shadow maps — a normal budget for a
# clustered forward renderer, and comfortable on a Quest-class target once the
# fade distances are halved (pass {"scale": 0.85} and halve _fade's numbers).
#
# GI: SDFGI, NOT LightmapGI AND NOT VoxelGI. Both of those require a bake, and a
# bake requires an editor round-trip over geometry that does not exist until the
# streamer stamps it. SDFGI is fully runtime and headless-safe. Exact settings
# are in SDFGI_RECOMMENDATION, and apply_gi_recommendation() will install them on
# an Environment for whoever owns that file. Nothing here bakes or touches the
# editor; the scene still runs with --no-window.
#
# WHAT THIS RIG ASSUMES OF THE ENVIRONMENT (machine-readable in ENV_CONTRACT):
#   ambient_light_energy  <= 0.30  — the single most important number. At the
#                                    baseline's 1.2 every light below is a
#                                    rounding error and the rig will look flat.
#   tonemap_mode          ACES (or FILMIC), exposure ~0.85, white ~6.0
#   ssao_enabled + ssil_enabled    — the wall wash pays off through bounce
#   glow enabled, hdr_threshold ~1.0
#   volumetric fog density <= 0.012 (the daylight lights declare fog energy)
#   the DirectionalLight3D sun dropped to <= 0.35 energy, or culled indoors
#
# Only this file is owned here. It adds Light3D nodes as children of a segment;
# it never touches the segment's geometry, materials, collision or walk map, and
# it frees with the segment.

# ── budget ───────────────────────────────────────────────────────────────────
const MAX_LIGHTS_PER_SEGMENT := 26
const MAX_SHADOW_CASTERS := 6

# ── the room, as endless_museum.gd stamps it ─────────────────────────────────
# Wall boxes are y 0..3. em_detail.gd then builds a REAL coffered ceiling over
# them, and this file's original claim that "there is no ceiling mesh" became a
# lie the moment that landed — with SKY_Y at 2.92 every daylight fixture in the
# building was mounted 40 mm under a solid lid, and the blown ellipse smeared
# across the soffit in every proof shot was a slide projector aimed at plaster.
const WALL_H := 3.0
# Fixture plane. BELOW the wall top on purpose: the walls then occlude between
# rooms, which is what gives an enfilade its dark-bright-dark rhythm. Put the
# fixtures above 3.0 and every room lights every other room.
const RIG_Y := 2.78
# em_detail.gd's section, duplicated here rather than imported (importing it
# would be a preload cycle). If those numbers move, THESE MUST MOVE.
#   CEIL_SOFFIT 3.14   CEIL_TOP 3.40   rib underside 2.96
const CEILING_SOFFIT := 3.14
const CEILING_TOP := 3.40
# Top-light plane — a skylight sits ABOVE the roof, not under the ceiling. At
# CEILING_TOP + 0.22 the daylight family is genuinely outside the building and
# reaches the floor only through em_detail's 550 mm slots, which is what finally
# earns the banded floor light the ceiling was built for.
const SKY_Y := CEILING_TOP + 0.22
const VESTIBULE_H := 4
const LOBBY_W := 17
# Wall-washer standoff. The rule of thumb is ceiling height / 3, and 3.0 / 3 is
# 1.0 m, which is also what gets even top-to-bottom coverage on a 3 m wall.
const WASH_STANDOFF := 1.0

# ── colour temperatures (kelvin) ─────────────────────────────────────────────
# 2750, not the 2450 a real tungsten cove measures. With TEMP_DESAT down to
# 0.20 the raw blackbody curve reaches the frame far more strongly than it did,
# and at 2450 over an already-warm plaster albedo (0.72/0.705/0.675) the
# vestibule went sepia wall to wall — the first thing a walker sees. The warm/
# cool split is now carried by the DAYLIGHT end, which is finally visible.
const K_COVE := 2750.0      # threshold / circulation, incandescent
const K_KEY := 3400.0       # gallery key on art — warm, not amber
const K_PODIUM := 3200.0
const K_WASH := 4600.0      # neutral wall wash, deliberately above the coves
const K_DAYLIGHT := 6800.0  # north light through a diffusing ceiling
const K_RIM := 7200.0       # cool separation rim
const K_AMBIENT := 5400.0
const K_FLOOR := 4800.0
# Pull every temperature this far toward white. Was 0.35, which collapsed a
# 2700/6300 split into something the frame could not show — and the cost is paid
# TWICE, because AgX desaturates into the highlight as well and the grade then
# buys saturation back at 1.08. 0.20 keeps the chromatic-adaptation argument and
# stops paying for it three times.
const TEMP_DESAT := 0.26

# ── how much of the museum's own colour is allowed to be LIGHT ───────────────
# template_patterns.json's museum hexes are #946b3d / #3d6b94 / #6b943d /
# #943d6b / #3d9487 / #94873d — the same three bytes rotated through the RGB
# channels. That is a qualitative legend palette generated for distinguishability
# in a chart, and feeding it to a wall wash at 10% and a floor grazer at FULL
# strength made every museum identical in saturation and luminance and different
# only in hue. Nobody designed that; a hue wheel did.
#
# So the accent no longer colours the architecture. It drives WARMTH and LEVEL —
# the two axes real buildings actually differ on — and it is still allowed to be
# seen AS COLOUR in exactly two places: the ember strip (owned by em_materials)
# and the grazer that rides it, and even there it is pulled well toward white.
const ACCENT_IN_WASH := 0.04
const ACCENT_IN_COVE := 0.09
const ACCENT_GRAZER_WHITEN := 0.45
## Kelvin swing a museum's hue is allowed to buy, either side of each family's
## base temperature. +-550 K is about a stop of warmth — legible as a different
## building, invisible as a gel.
const MUSEUM_K_SWING := 550.0

# ── SDFGI: the only GI that survives a streamed, headless world ──────────────
# 0.2 m cells -> cascade 0 spans 0.2 * 64 = 12.8 m, which brackets a 13-17 m wide
# gallery exactly. Four cascades reach ~102 m, past the streamer's KEEP_BEHIND_M
# of 70, so no cascade boundary ever crosses the visible corridor.
# use_occlusion is mandatory here: without it light leaks straight through the
# 1 m wall boxes and the enfilade rhythm dies.
# read_sky_light is OFF because this is an interior — reading the procedural sky
# floods every room with flat blue and undoes the whole rig.
# y_scale 75% because the corridor is long and flat: spend cascade resolution on
# x/z, not on y.
const SDFGI_RECOMMENDATION := {
	"sdfgi_enabled": true,
	"sdfgi_min_cell_size": 0.2,
	"sdfgi_cascades": 4,
	"sdfgi_use_occlusion": true,
	"sdfgi_bounce_feedback": 0.5,
	"sdfgi_read_sky_light": false,
	"sdfgi_energy": 1.0,
	"sdfgi_normal_bias": 1.1,
	"sdfgi_probe_bias": 1.1,
	"sdfgi_y_scale": "SDFGI_Y_SCALE_75_PERCENT",
}

# Stated so the environment author can assert against it instead of guessing.
const ENV_CONTRACT := {
	"ambient_light_energy_max": 0.30,
	"tonemap": "ACES",
	"tonemap_exposure": 0.85,
	"tonemap_white": 6.0,
	"ssao_enabled": true,
	"ssil_enabled": true,
	"glow_enabled": true,
	"glow_hdr_threshold": 1.0,
	"volumetric_fog_density_max": 0.012,
	"directional_sun_energy_max": 0.35,
}


## THE CONTRACT. Install the full rig on one streamed segment.
##
##   seg     the segment Node3D. Lights are added as children in the SAME local
##           space the builder uses: x and z are cell coordinates + 0.5, y is
##           metres above the floor deck (floor top = 0.0).
##   w, h    the tile's width and height in cells. The tile occupies local z from
##           VESTIBULE_H to VESTIBULE_H + h; the vestibule is z 0..VESTIBULE_H.
##   accent  the museum's own colour. Full strength on the threshold grazer, 20%
##           into the coves, 10% into the wall wash — enough that two museums
##           feel different, little enough that no gallery looks gelled.
##   slots   the builder's slot list: [{x:int, y:int, top:float, rank:int}] where
##           rank 0 = hero plinth, 1 = podium, 2 = floor. `y` is already the
##           local z cell, vestibule offset included.
##   opts    OPTIONAL and fully defaulted, so the five-argument call is complete.
##           {"tile": Array} lets the rig find the museum's real interior wall
##           runs to wash instead of only the outer flanks; {"scale": float}
##           trims every energy at once for a lower-powered target.
static func rig_segment(seg: Node3D, w: int, h: int, accent: Color, slots: Array, opts: Dictionary = {}) -> void:
	if seg == null:
		return
	var tile: Array = opts.get("tile", [])
	var pal: Dictionary = _palette(accent)
	var scale: float = float(opts.get("scale", 1.0)) * float(pal["level"])
	# the budget is a live counter shared by every family; Dictionaries are
	# passed by reference, so a family that would overspend simply gets nothing
	var budget: Dictionary = {"lights": 0, "shadows": 0}

	# order is priority order: if a pathological template ever exhausts the cap,
	# what survives is the light that describes the space, then the light on the
	# art, then the decoration
	_ambient_key(seg, w, h, pal, budget, scale)
	_daylight(seg, w, h, pal, budget, scale)
	_keys(seg, slots, pal, budget, scale)
	_threshold(seg, w, pal, budget, scale)
	_wall_wash(seg, w, h, tile, pal, budget, scale)
	_floor_fill(seg, slots, pal, budget, scale)

	seg.set_meta("em_lights", int(budget["lights"]))
	seg.set_meta("em_shadow_casters", int(budget["shadows"]))


## THE MUSEUM'S COLOUR, TRANSLATED. Every light colour in the rig comes out of
## here, so there is exactly one place that decides how much of a chart-legend
## hex is allowed into a building.
##
## The only byte that genuinely varies across the eight museum hexes is HUE (all
## six are 0x94/0x6b/0x3d permutations, so value and saturation are constants and
## a level derived from them would be a constant too). Hue therefore buys two
## things through two different mappings, so warmth and level are not perfectly
## correlated: a Kelvin offset, and a small overall energy trim.
static func _palette(accent: Color) -> Dictionary:
	var hue: float = accent.h
	var k: float = (hue - 0.5) * 2.0 * MUSEUM_K_SWING
	# quarter-turn out of phase with the warmth mapping
	var level: float = 0.88 + 0.24 * (0.5 + 0.5 * sin(hue * TAU + 1.2))
	return {
		"level": level,
		"k_shift": k,
		"ambient": _kelvin(K_AMBIENT + k),
		"daylight": _kelvin(K_DAYLIGHT + k * 0.5),
		"key": _kelvin(K_KEY + k),
		"podium": _kelvin(K_PODIUM + k),
		"rim": _kelvin(K_RIM),
		"floor": _kelvin(K_FLOOR + k),
		"wash": _kelvin(K_WASH + k).lerp(accent, ACCENT_IN_WASH),
		"cove": _kelvin(K_COVE + k).lerp(accent, ACCENT_IN_COVE),
		"grazer": accent.lerp(Color.WHITE, ACCENT_GRAZER_WHITEN),
	}


## What the rig actually spent here. A cheap gate for the pipeline:
## assert EmLighting.lights_installed(seg) <= EmLighting.MAX_LIGHTS_PER_SEGMENT
static func lights_installed(seg: Node3D) -> int:
	if seg == null or not seg.has_meta("em_lights"):
		return 0
	return int(seg.get_meta("em_lights"))


static func shadow_casters_installed(seg: Node3D) -> int:
	if seg == null or not seg.has_meta("em_shadow_casters"):
		return 0
	return int(seg.get_meta("em_shadow_casters"))


## OPT-IN. Apply the SDFGI settings this rig was tuned against. Runtime only —
## no bake, no editor round-trip, safe headless. The environment author may call
## this or copy SDFGI_RECOMMENDATION; it is deliberately the only function in
## this file that touches anything outside a segment.
static func apply_gi_recommendation(env: Environment) -> void:
	if env == null:
		return
	env.sdfgi_enabled = true
	env.sdfgi_min_cell_size = 0.2
	env.sdfgi_cascades = 4
	env.sdfgi_use_occlusion = true
	env.sdfgi_bounce_feedback = 0.5
	env.sdfgi_read_sky_light = false
	env.sdfgi_energy = 1.0
	env.sdfgi_normal_bias = 1.1
	env.sdfgi_probe_bias = 1.1
	env.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT


# ── 1. ambient key ───────────────────────────────────────────────────────────
# One omni, near-flat falloff, no shadow, no GI cost. It is not lighting the
# room; it is setting the floor of the black so unlit plaster keeps its albedo
# instead of clipping, which is what makes a dark render look cheap rather than
# moody. Specular 0 — a fill must never add a highlight, only the aimed lights
# are allowed to do that.
## TWO of them now, and stronger. One omni cannot floor a 30-cell gallery AND a
## 4-cell vestibule at the same time: the proof shots came back with a gallery
## deck at 0.03-0.08 carrying no material information at all, which is the
## failure this family exists to prevent. 0.85 in the gallery, a smaller one in
## the lobby, both raised to 2.55 so the ceiling ribs do not clip them.
static func _ambient_key(seg: Node3D, w: int, h: int, pal: Dictionary, budget: Dictionary, scale: float) -> void:
	if not _afford(budget):
		return
	var l := OmniLight3D.new()
	l.name = "AmbientKey"
	l.light_color = pal["ambient"]
	l.light_energy = 1.05 * scale
	l.light_specular = 0.0
	l.omni_range = clampf(maxf(float(w), float(h)) * 0.75, 12.0, 30.0)
	# flatter than inverse-square on purpose: this stands in for bounce, and
	# bounce does not fall off like a point source
	l.omni_attenuation = 0.45
	l.shadow_enabled = false
	# never feed GI from a fake fill — it would double-count as bounce
	l.light_bake_mode = Light3D.BAKE_DISABLED
	l.position = Vector3(float(w) * 0.5, 2.55, float(VESTIBULE_H) + float(h) * 0.5)
	_fade(l, 30.0, 14.0, 0.0)
	seg.add_child(l)
	_spend(budget, false)
	if not _afford(budget):
		return
	var v := OmniLight3D.new()
	v.name = "AmbientKeyVestibule"
	v.light_color = pal["ambient"]
	v.light_energy = 0.55 * scale
	v.light_specular = 0.0
	v.omni_range = 14.0
	v.omni_attenuation = 0.45
	v.shadow_enabled = false
	v.light_bake_mode = Light3D.BAKE_DISABLED
	v.position = Vector3(float(LOBBY_W) * 0.5, 2.55, float(VESTIBULE_H) * 0.5)
	_fade(v, 26.0, 12.0, 0.0)
	seg.add_child(v)
	_spend(budget, false)


# ── 2. daylight ──────────────────────────────────────────────────────────────
# Cool top-light: one spill at the threshold gap (the joint between two buildings
# is glazed in every museum that has one) and up to two skylights down the
# gallery axis. These describe the ARCHITECTURE — long soft shadows off the wall
# boxes — so the threshold spill is the segment's one non-art shadow caster,
# with a wide blur that reads as an overcast diffuser rather than a spotlight.
##
## SHADOWS ARE NOT OPTIONAL HERE ANY MORE. A shadowless light above the roof
## passes straight through the ceiling panels and lands as an even pool, which
## is the old broken look minus the soffit blowout. The whole return on moving
## the fixture outside is that the coffer CUTS the cone — so the threshold spill
## and the first axis skylight both carry a shadow map, and the podium family
## gives one back to pay for it.
static func _daylight(seg: Node3D, w: int, h: int, pal: Dictionary, budget: Dictionary, scale: float) -> void:
	var cx: float = float(w) * 0.5
	var col: Color = pal["daylight"]
	if _afford(budget):
		var s := SpotLight3D.new()
		s.name = "DaylightThreshold"
		s.light_color = col
		# was 2.4 with the fixture 40 mm under the lid, which put three separate
		# clipped plateaus in one frame. The coffer now eats ~80% of the cone by
		# area and the slots pass the rest at full strength, so the number that
		# lands on the floor is the same order and the ceiling is no longer a
		# projection screen.
		s.light_energy = 2.1 * scale
		s.light_indirect_energy = 1.5
		s.light_specular = 0.6
		# this one earns a visible shaft: it is the only place in the corridor
		# where the fiction says there is an opening to the sky
		s.light_volumetric_fog_energy = 1.0
		# +0.7 m of mount height plus throw
		s.spot_range = 13.0
		s.spot_angle = 50.0
		# soft edge: a diffuser, not a can light
		s.spot_angle_attenuation = 0.9
		# a large source falls off slowly — 1.0, not inverse-square
		s.spot_attenuation = 1.0
		# an area source, so the slot edges throw a real penumbra. shadow_blur was
		# 2.0, which is not softness, it is haze — light_size does this properly.
		s.light_size = 0.6
		s.light_bake_mode = Light3D.BAKE_DYNAMIC
		_shadow(s, budget, 1.2, 0.03)
		_aim(s, Vector3(cx, SKY_Y, float(VESTIBULE_H) - 2.2), Vector3(cx, 0.0, float(VESTIBULE_H) + 1.2))
		_fade(s, 55.0, 16.0, 24.0)
		seg.add_child(s)
		_spend(budget, s.shadow_enabled)
	# axis skylights: one per ~14 m of gallery, capped at two
	var n: int = clampi(int(round(float(h) / 14.0)), 1, 2)
	for i in range(n):
		if not _afford(budget):
			return
		var s2 := SpotLight3D.new()
		s2.name = "DaylightAxis%d" % i
		s2.light_color = col
		s2.light_energy = 2.4 * scale
		# the skylight bounce IS the fill in a top-lit gallery
		s2.light_indirect_energy = 1.7
		s2.light_specular = 0.5
		s2.light_volumetric_fog_energy = 0.7
		s2.spot_range = 13.5
		s2.spot_angle = 52.0
		s2.spot_angle_attenuation = 0.9
		s2.spot_attenuation = 1.0
		s2.light_size = 0.5
		s2.light_bake_mode = Light3D.BAKE_DYNAMIC
		# only the FIRST axis skylight can afford a map; the second is the same
		# cone one bay further on and reads fine off the first one's bands
		if i == 0:
			_shadow(s2, budget, 1.4, 0.03)
		else:
			s2.shadow_enabled = false
		var z: float = float(VESTIBULE_H) + float(h) * (float(i) + 0.5) / float(n)
		_aim(s2, Vector3(cx, SKY_Y, z), Vector3(cx, 0.0, z))
		_fade(s2, 50.0, 16.0, 26.0)
		seg.add_child(s2)
		_spend(budget, s2.shadow_enabled)


# ── 3. keys on the art ───────────────────────────────────────────────────────
# The museum move. A narrow beam from above and 0.85 m in FRONT of the piece —
# front being the -z approach side, since the walker always arrives along +z —
# so the top of the object is not the only lit face. Shadows on: the contact
# shadow under a plinth is most of what sells the object as sitting in the room
# rather than hovering in it.
#
# THE 30-DEGREE RULE. Gallery track lighting is aimed 30 deg off vertical: any
# steeper and the piece shadows its own face, any shallower and the beam reaches
# the viewer's eye as glare and the wall behind as a hot spot. A fixture at
# RIG_Y + 0.02 = 2.80, offset 0.85 m, aiming at a hero's top + 0.45 (= 1.25) is
# 61.3 deg from horizontal — 28.7 deg off vertical. That is where the offsets
# below come from; they are not eyeballed. The podium fixture drops to 2.55 with
# a 1.05 m offset onto a 0.65 m target, which is 61.1 deg: the same band, reached
# with a lower fixture because a podium piece is smaller and closer to the eye.
static func _keys(seg: Node3D, slots: Array, pal: Dictionary, budget: Dictionary, scale: float) -> void:
	var heroes := 0
	var podiums := 0
	var rimmed := false
	for entry in slots:
		var sd: Dictionary = entry
		var rank: int = int(sd.get("rank", 2))
		if rank > 1:
			continue
		var px: float = float(int(sd.get("x", 0))) + 0.5
		var pz: float = float(int(sd.get("y", 0))) + 0.5
		var top: float = float(sd.get("top", 0.0))
		if rank == 0 and heroes < 3:
			if not _afford(budget):
				return
			var k := SpotLight3D.new()
			k.name = "HeroKey%d" % heroes
			k.light_color = pal["key"]
			k.light_energy = 3.8 * scale
			k.light_indirect_energy = 0.8
			k.light_specular = 1.0
			k.spot_range = 7.0
			# 24 deg half-angle throws a ~0.9 m pool 2 m below the fixture: it
			# covers a 1 m plinth and the overhang of a large piece, and nothing
			# else. A wider cone here is the difference between a gallery and a
			# warehouse.
			k.spot_angle = 24.0
			k.spot_angle_attenuation = 0.45
			# close to inverse-square — the falloff down the plinth is visible
			k.spot_attenuation = 1.7
			# a source with area, so the contact shadow has a real penumbra
			k.light_size = 0.35
			k.light_bake_mode = Light3D.BAKE_DYNAMIC
			_shadow(k, budget, 1.1, 0.025)
			_aim(k, Vector3(px, RIG_Y + 0.02, pz - 0.85), Vector3(px, top + 0.45, pz))
			_fade(k, 45.0, 12.0, 26.0)
			seg.add_child(k)
			_spend(budget, k.shadow_enabled)
			heroes += 1
			# one cool rim, on the first hero only. Cheap, shadowless, and the
			# single strongest "this was lit by someone" signal in the segment.
			if not rimmed and _afford(budget):
				var r := SpotLight3D.new()
				r.name = "HeroRim"
				r.light_color = pal["rim"]
				r.light_energy = 1.9 * scale
				r.light_specular = 1.0
				r.light_indirect_energy = 0.2
				r.spot_range = 5.0
				r.spot_angle = 30.0
				r.spot_angle_attenuation = 1.0
				r.spot_attenuation = 1.6
				r.shadow_enabled = false
				r.light_bake_mode = Light3D.BAKE_DISABLED
				_aim(r, Vector3(px, 2.35, pz + 1.15), Vector3(px, top + 0.55, pz))
				_fade(r, 30.0, 10.0, 0.0)
				seg.add_child(r)
				_spend(budget, false)
				rimmed = true
		elif rank == 1 and podiums < 3:
			if not _afford(budget):
				return
			var p := SpotLight3D.new()
			p.name = "PodiumKey%d" % podiums
			p.light_color = pal["podium"]
			p.light_energy = 2.7 * scale
			p.light_indirect_energy = 0.7
			p.light_specular = 0.95
			p.spot_range = 6.0
			p.spot_angle = 20.0
			p.spot_angle_attenuation = 0.5
			p.spot_attenuation = 1.8
			p.light_size = 0.22
			p.light_bake_mode = Light3D.BAKE_DYNAMIC
			# only the first two podiums are worth a shadow map
			if podiums < 1:
				_shadow(p, budget, 0.9, 0.02)
			else:
				p.shadow_enabled = false
			# 2.55 / 1.05 offset / 0.65 target = 61.1 deg, the 30-degree rule
			_aim(p, Vector3(px, 2.55, pz - 1.05), Vector3(px, top + 0.25, pz))
			_fade(p, 38.0, 12.0, 22.0)
			seg.add_child(p)
			_spend(budget, p.shadow_enabled)
			podiums += 1


# ── 4. threshold ─────────────────────────────────────────────────────────────
# Warm coves in the vestibule, plus one accent-coloured grazer riding the ember
# strip so the museum's colour lands on the FLOOR as light and not only on an
# emissive sliver. Circulation space is warm and low; the gallery beyond is cool
# and bright. Walking that gradient is most of the arrival feeling.
static func _threshold(seg: Node3D, w: int, pal: Dictionary, budget: Dictionary, scale: float) -> void:
	var warm: Color = pal["cove"]
	for i in range(2):
		if not _afford(budget):
			return
		var c := OmniLight3D.new()
		c.name = "Cove%d" % i
		c.light_color = warm
		c.light_energy = 1.7 * scale
		# a cove is nothing BUT indirect: it exists to light the ceiling plane
		# and the upper wall, and the room gets what bounces back
		c.light_indirect_energy = 1.3
		c.light_specular = 0.35
		c.omni_range = 8.0
		c.omni_attenuation = 1.2
		c.shadow_enabled = false
		c.light_bake_mode = Light3D.BAKE_DYNAMIC
		var x: float = 2.0 if i == 0 else float(LOBBY_W) - 2.0
		c.position = Vector3(x, 2.55, 1.6)
		_fade(c, 34.0, 12.0, 0.0)
		seg.add_child(c)
		_spend(budget, false)
	# THE GRAZER IS A LINE, NOT A POINT. One omni at energy 1.7, inverse-square
	# attenuation, 320 mm above the floor it was grazing is a blowtorch: it was
	# the orange-white nova on the threshold in aaa_axis and the magenta one in
	# aaa_soane, and it clipped to 255 exactly where the composition sends the
	# eye. Three weak sources spread across the opening at 750 mm with a softer
	# falloff give the same ember line and no plateau.
	for gi in range(3):
		if not _afford(budget):
			return
		var g := OmniLight3D.new()
		g.name = "AccentGrazer%d" % gi
		g.light_color = pal["grazer"]
		g.light_energy = 0.52 * scale
		g.light_indirect_energy = 0.8
		g.light_specular = 0.4
		g.omni_range = 4.6
		g.omni_attenuation = 1.35
		g.shadow_enabled = false
		g.light_bake_mode = Light3D.BAKE_DYNAMIC
		# rides the ember strip (y 0.02, z VESTIBULE_H - 0.15), spread across the
		# opening and lifted clear of it
		var t: float = (float(gi) + 0.5) / 3.0
		g.position = Vector3(1.0 + (float(w) - 2.0) * t, 0.75, float(VESTIBULE_H) - 0.30)
		_fade(g, 26.0, 8.0, 0.0)
		seg.add_child(g)
		_spend(budget, false)


# ── 5. wall wash ─────────────────────────────────────────────────────────────
# Grazing spots standing WASH_STANDOFF off a wall face, aimed at its lower middle
# so the 42 deg cone spreads across the full 3 m height. Shadows off by design: a
# wall washer that casts is a wall washer with a scallop pattern in it. These are
# the segment's largest indirect contributors (indirect 1.4) because in a real
# gallery the washed wall lights the room.
static func _wall_wash(seg: Node3D, w: int, h: int, tile: Array, pal: Dictionary, budget: Dictionary, scale: float) -> void:
	var col: Color = pal["wash"]
	var runs: Array = _wall_runs(tile, w, h)
	# the outer skin always exists (endless_museum stamps it at x = -1 and x = w),
	# so the two flanks are the guaranteed floor of this family — with no tile
	# supplied the rig still washes something real
	runs.append({"cx": -0.5, "z": float(VESTIBULE_H) + float(h) * 0.5, "side": 1, "len": h})
	runs.append({"cx": float(w) + 0.5, "z": float(VESTIBULE_H) + float(h) * 0.5, "side": -1, "len": h})
	runs.sort_custom(func(a, b): return int(a["len"]) > int(b["len"]))
	var placed := 0
	for entry in runs:
		if placed >= 5:
			return
		var r: Dictionary = entry
		var side: int = int(r.get("side", 1))
		var cx: float = float(r.get("cx", 0.0))
		var run_len: int = int(r.get("len", 4))
		var zc: float = float(r.get("z", 0.0))
		var face: float = cx + 0.5 * float(side)
		# two washers only on a long run; the budget forces wider spacing than a
		# real spec would use, which the soft cone edge below hides
		var n: int = clampi(run_len / 12, 1, 2)
		for i in range(n):
			if placed >= 5 or not _afford(budget):
				return
			var z: float = zc
			if n > 1:
				z = zc + (float(i) - 0.5) * float(run_len) * 0.42
			var s := SpotLight3D.new()
			s.name = "WallWash%d" % placed
			s.light_color = col
			s.light_energy = 1.6 * scale
			s.light_indirect_energy = 1.4
			# low specular: a grazing angle on plaster should read as roughness,
			# not as a sheen. Raise this only if the walls become polished.
			s.light_specular = 0.25
			s.spot_range = 8.0
			s.spot_angle = 42.0
			s.spot_angle_attenuation = 1.8
			s.spot_attenuation = 1.1
			s.shadow_enabled = false
			s.light_bake_mode = Light3D.BAKE_DYNAMIC
			_aim(s, Vector3(face + WASH_STANDOFF * float(side), RIG_Y, z), Vector3(face, 1.50, z))
			_fade(s, 40.0, 14.0, 0.0)
			seg.add_child(s)
			_spend(budget, false)
			placed += 1


# ── 6. floor fill ────────────────────────────────────────────────────────────
# A floor artifact has no plinth to key off. One small cool omni just above each:
# cheap, shadowless, and BAKE_DISABLED so it costs nothing in GI.
static func _floor_fill(seg: Node3D, slots: Array, pal: Dictionary, budget: Dictionary, scale: float) -> void:
	var n := 0
	for entry in slots:
		if n >= 2:
			return
		var sd: Dictionary = entry
		if int(sd.get("rank", 2)) != 2:
			continue
		if not _afford(budget):
			return
		var l := OmniLight3D.new()
		l.name = "FloorFill%d" % n
		l.light_color = pal["floor"]
		l.light_energy = 1.3 * scale
		l.light_specular = 0.4
		l.omni_range = 3.8
		l.omni_attenuation = 1.8
		l.shadow_enabled = false
		l.light_bake_mode = Light3D.BAKE_DISABLED
		l.position = Vector3(float(int(sd.get("x", 0))) + 0.5, 1.70, float(int(sd.get("y", 0))) + 0.5)
		_fade(l, 24.0, 8.0, 0.0)
		seg.add_child(l)
		_spend(budget, false)
		n += 1


# ── wall-run detection ───────────────────────────────────────────────────────
# Optional. With the tile in hand the rig can wash the museum's real interior
# walls — the ones an enfilade hangs its pictures on — instead of only the outer
# flanks. Vertical runs of "4" at least 4 cells long, each washed from whichever
# side is open floor. Returns [{cx, z, side, len}] in tile-local z (vestibule
# offset already added).
static func _wall_runs(tile: Array, w: int, h: int) -> Array:
	var out: Array = []
	if tile.is_empty():
		return out
	var rows: int = mini(h, tile.size())
	for x in range(w):
		var run_start := -1
		for y in range(rows + 1):
			var solid := false
			if y < rows:
				solid = _cell(tile, x, y) == "4"
			if solid and run_start < 0:
				run_start = y
			elif not solid and run_start >= 0:
				var run_len: int = y - run_start
				if run_len >= 4:
					var mid: int = run_start + run_len / 2
					var side: int = _open_side(tile, x, mid, w, rows)
					if side != 0:
						out.append({
							"cx": float(x) + 0.5,
							"z": float(run_start) + float(run_len) * 0.5 + float(VESTIBULE_H),
							"side": side,
							"len": run_len,
						})
				run_start = -1
	return out


static func _cell(tile: Array, x: int, y: int) -> String:
	if y < 0 or y >= tile.size():
		return ""
	var row: Array = tile[y]
	if x < 0 or x >= row.size():
		return ""
	return String(row[x])


static func _open_side(tile: Array, x: int, y: int, w: int, rows: int) -> int:
	var left: bool = _is_open(tile, x - 1, y, w, rows)
	var right: bool = _is_open(tile, x + 1, y, w, rows)
	if left and right:
		# both faces are gallery: wash the one facing the building's spine,
		# because that is the face the walker actually reads
		return 1 if float(x) < float(w) * 0.5 else -1
	if left:
		return -1
	if right:
		return 1
	return 0


static func _is_open(tile: Array, x: int, y: int, w: int, rows: int) -> bool:
	if x < 0 or x >= w or y < 0 or y >= rows:
		return false
	var c: String = _cell(tile, x, y)
	return c == "1" or c == "1s" or c == "2" or c == "2s" or c == "3s"


# ── helpers ──────────────────────────────────────────────────────────────────

## Point a light from `from` at `to`. Godot composes the `rotation` property as
## Y*X*Z, so forward (-Z) lands at (-cos(p)sin(y), sin(p), -cos(p)cos(y));
## inverting that gives pitch = asin(dy) and yaw = atan2(-dx, -dz). Derived
## rather than eyeballed, because a spot aimed one axis wrong is invisible and
## looks exactly like a spot that is switched off.
static func _aim(l: Node3D, from: Vector3, to: Vector3) -> void:
	l.position = from
	var d: Vector3 = to - from
	if d.length_squared() < 0.000001:
		d = Vector3(0.0, -1.0, 0.0)
	d = d.normalized()
	var pitch: float = asin(clampf(d.y, -1.0, 1.0))
	var yaw: float = atan2(-d.x, -d.z)
	l.rotation = Vector3(pitch, yaw, 0.0)


## Distance fade — the reason 72 lights across three live segments is affordable.
## A light stops being submitted once the camera is `begin + length` away, and a
## shadow-caster drops its map at `shadow_at` well before that. Halve every
## number here for a mobile/Quest target.
static func _fade(l: Light3D, begin: float, length: float, shadow_at: float) -> void:
	l.distance_fade_enabled = true
	l.distance_fade_begin = begin
	l.distance_fade_length = length
	l.distance_fade_shadow = shadow_at if shadow_at > 0.0 else begin


## Turn shadows on, if the shadow budget still allows it — otherwise the light is
## still installed, just shadowless. Bias is tuned for this scene's axis-aligned
## 1 m box geometry: a small constant bias plus a generous normal bias, because
## peter-panning shows immediately on a floor/wall junction with no bevel.
static func _shadow(l: Light3D, budget: Dictionary, blur: float, bias: float) -> void:
	if int(budget["shadows"]) >= MAX_SHADOW_CASTERS:
		l.shadow_enabled = false
		return
	l.shadow_enabled = true
	l.shadow_bias = bias
	l.shadow_normal_bias = 1.2
	l.shadow_blur = blur
	# never fully black: the last 5% keeps material readable inside shadow, which
	# is the same job the ambient key does for the unlit corners
	l.shadow_opacity = 0.95


## The cap is enforced, not assumed.
static func _afford(budget: Dictionary) -> bool:
	return int(budget["lights"]) < MAX_LIGHTS_PER_SEGMENT


static func _spend(budget: Dictionary, took_shadow: bool) -> void:
	budget["lights"] = int(budget["lights"]) + 1
	if took_shadow:
		budget["shadows"] = int(budget["shadows"]) + 1


## Kelvin -> Color: Tanner Helland's blackbody approximation, then pulled
## TEMP_DESAT toward white. The desaturation matters. The raw curve at 2700 K is
## a strong orange that reads as a party gel, whereas a real tungsten room reads
## as warm white because the eye chromatically adapts to it. A renderer has no
## adaptation, so the adaptation is baked in here.
static func _kelvin(k: float) -> Color:
	var t: float = clampf(k, 1500.0, 12000.0) / 100.0
	var r: float = 255.0
	var g: float = 255.0
	var b: float = 255.0
	if t <= 66.0:
		g = 99.4708025861 * log(t) - 161.1195681661
		if t <= 19.0:
			b = 0.0
		else:
			b = 138.5177312231 * log(t - 10.0) - 305.0447927307
	else:
		r = 329.698727446 * pow(t - 60.0, -0.1332047592)
		g = 288.1221695283 * pow(t - 60.0, -0.0755148492)
	var raw: Color = Color(clampf(r / 255.0, 0.0, 1.0), clampf(g / 255.0, 0.0, 1.0), clampf(b / 255.0, 0.0, 1.0))
	return raw.lerp(Color.WHITE, TEMP_DESAT)
