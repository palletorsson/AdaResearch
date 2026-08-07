class_name EmEnvironment
extends RefCounted
# em_environment.gd — the camera pipeline for the endless museum.
#
# This file owns exactly one thing: what happens to light AFTER it has left a
# surface and BEFORE it reaches the pixel. Materials are somebody else's file,
# lights are em_lighting.gd, movement is em_feel.gd. Everything here is
# Environment + CameraAttributes + the two post passes Godot does not ship.
#
# THE PROBLEM IT SOLVES. endless_museum.gd's _setup_world() builds an
# Environment with a sky background, ambient 1.2, and nothing else — no
# tonemapper, so every value above 1.0 clips flat white; no occlusion, so a
# podium floats on the floor instead of sitting on it; no exposure model, so
# walking out of a dark vestibule into a daylit gallery looks like a lighting
# bug rather than an eye. That is the difference between a viewport dump and a
# frame. This file is the difference.
#
#   API
#     EmEnvironment.build(tier := "")            -> WorldEnvironment
#     EmEnvironment.camera_attributes(tier := "") -> CameraAttributes
#     EmEnvironment.vignette(tier := "")         -> CanvasLayer   (or null)
#     EmEnvironment.install(parent, cam, tier := "") -> WorldEnvironment
#     EmEnvironment.tier()                       -> "high" | "perf"
#     EmEnvironment.check_contract(env, contract) -> Array[String]
#     EmEnvironment.describe(tier := "")         -> String
#
#   One-line integration inside endless_museum.gd's _setup_world():
#     EmEnvironment.install(self, _cam)
#   ...replacing the six lines that build the bare WorldEnvironment. Nothing
#   else in the scene needs to know this file exists.
#
#   CLI:  --em-quality=perf   drops SSIL, SSR, volumetric fog, SDFGI and DOF.
#         --em-shot=<path>    (already parsed by the scene) additionally freezes
#                             auto-exposure — see AUTO-EXPOSURE below.
#
# ── CONTRACT WITH em_lighting.gd ─────────────────────────────────────────────
# em_lighting.gd publishes ENV_CONTRACT: the environment numbers its light
# energies were tuned against. Two files calibrated against different exposures
# produce a scene that is nobody's design. Every quantitative term of that
# contract is honoured here to the digit — ambient <= 0.30, tonemap white 6.0,
# volumetric fog density <= 0.012, SSAO/SSIL/glow on, glow threshold 1.0.
#
# The ONE deliberate divergence is the tonemapper, and it is argued below.
#
# SDFGI is em_lighting's call, not mine, but it lives on Environment where only
# this file can reach it. So build() applies SDFGI_MIRROR — a byte-identical
# copy of EmLighting.SDFGI_RECOMMENDATION — which makes a later call to
# EmLighting.apply_gi_recommendation(env) a no-op rather than a fight. If those
# numbers ever diverge, this file loses: re-copy them.
#
# ── WHY AgX AND NOT ACES ─────────────────────────────────────────────────────
# The contract asks for ACES. This file ships AgX. The reason is the subject.
#
# A museum is a room full of near-neutral, near-equal-value surfaces: plaster at
# 0.32 grey, floor at 0.16, podium at 0.23. The entire image lives inside about
# one stop. ACES applies a strong saturation boost in the midtones and pushes
# neutrals toward warm-green, then hue-shifts bright emissives toward yellow-
# white as they roll off — on a face or a sunset that reads as "filmic", on
# fifteen metres of grey plaster it reads as a colour cast, and it eats exactly
# the subtle value separation the whole room is made of.
#
# AgX (Godot 4.3+) has a much longer, more neutral toe and desaturates INTO the
# highlight instead of hue-shifting through it. Concretely: em_lighting's ember
# strip (emission_energy 1.6) and its 2700K coves stay their own colour under
# AgX where ACES pulls both toward the same warm white. Neutrals stay neutral,
# which is what lets each museum's accent hex actually read as that museum's.
#
# The price is real and paid for below: AgX is flat by design. It hands back a
# low-contrast, slightly desaturated image that MUST be graded, or it looks
# washed. Hence adjustment_contrast 1.12, adjustment_saturation 1.08, and the
# print-emulation LUT. An ungraded AgX frame is worse than an ungraded ACES one;
# a graded AgX frame is better. That is the whole trade.
#
# Exposure compensation: AgX's longer toe sits roughly 0.1 stop darker in the
# midtones than ACES at equal exposure, so the contract's tonemap_exposure 0.85
# becomes 0.92 here. Same midtone, different curve. That is not a contract
# breach, it is the translation of one.
#
# If the lighting rig turns out to have been eyeballed against ACES and the
# whole corridor now reads wrong, flip TONEMAP to Environment.TONE_MAPPER_ACES
# and TONEMAP_EXPOSURE to 0.85. One constant each. Nothing else changes.

# ── tiers ────────────────────────────────────────────────────────────────────
const TIER_HIGH := "high"
const TIER_PERF := "perf"

## Flip these two together to fall back to the contract's ACES. See header.
const TONEMAP := Environment.TONE_MAPPER_AGX
const TONEMAP_EXPOSURE := 0.92
## AgX (and ACES) map scene-linear to display; white is where the curve lands
## on 1.0. 6.0 is the contract value and the right one: it puts roughly 2.6
## stops of headroom above diffuse white, which is exactly the room the
## emissive threshold strip and em_lighting's practicals need to bloom without
## clipping. The Godot default of 1.0 would clip every one of them to paper.
const TONEMAP_WHITE := 6.0

## Mirrored from em_lighting.gd ENV_CONTRACT so this file has no hard dependency
## on that class parsing. check_contract() reads whatever dict you hand it, so
## the caller can pass EmLighting.ENV_CONTRACT and get a real diff.
const ENV_CONTRACT_MIRROR := {
	"ambient_light_energy_max": 0.30,
	"tonemap_white": 6.0,
	"ssao_enabled": true,
	"ssil_enabled": true,
	"glow_enabled": true,
	"glow_hdr_threshold": 1.0,
	"volumetric_fog_density_max": 0.012,
}

## Byte-identical to EmLighting.SDFGI_RECOMMENDATION. Applied here because SDFGI
## is an Environment property; kept identical so applying theirs afterwards is a
## no-op. y_scale 2 == Environment.SDFGI_Y_SCALE_75_PERCENT.
const SDFGI_MIRROR := {
	"min_cell_size": 0.2,
	"cascades": 4,
	"use_occlusion": true,
	"bounce_feedback": 0.5,
	"read_sky_light": false,
	"energy": 1.0,
	"normal_bias": 1.1,
	"probe_bias": 1.1,
}

## Set false to fall back to a tuned ProceduralSkyMaterial (see _procedural_sky).
static var use_shader_sky: bool = true
## Set false to skip the vignette CanvasLayer entirely.
static var use_vignette: bool = true

static var _tier_cache: String = ""


# ── THE SKY ──────────────────────────────────────────────────────────────────
# Not the default procedural blue, and not a blue sky at all.
#
# A daylit museum is lit by north light: a large, cool, low-contrast dome, with
# the sun's actual disc almost never in frame. The default ProceduralSkyMaterial
# gives a saturated cyan zenith and a white horizon band, which through a
# doorway reads as "outdoors, summer, holiday" — wrong building.
#
# This dome is: a desaturated slate zenith carrying most of the energy, a warm
# pale horizon (the atmosphere's own bounce), and a dim warm-grey lower
# hemisphere standing in for the stone plaza the building sits on. The upper/
# lower asymmetry is the whole point — it is what gives the polished floor
# something dark to reflect while the ceiling stays open. A symmetric dome makes
# every reflective surface look like it is floating in fog.
#
# Note em_lighting sets sdfgi_read_sky_light = false, so this dome feeds ambient
# and reflections but NOT global illumination. Correct for an interior: sky-fed
# GI floods sealed rooms with flat blue through the walls.
const SKY_SHADER := """
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.196, 0.239, 0.318);
uniform vec3 horizon_color : source_color = vec3(0.706, 0.706, 0.686);
uniform vec3 ground_color : source_color = vec3(0.098, 0.094, 0.090);
uniform float zenith_energy : hint_range(0.0, 8.0) = 2.10;
uniform float horizon_energy : hint_range(0.0, 8.0) = 1.30;
uniform float ground_energy : hint_range(0.0, 4.0) = 0.40;
// >1 pulls the bright horizon band UP the dome (overcast); <1 presses it flat
// to the skyline (clear). 3.4 is a bright-overcast north light.
uniform float horizon_falloff : hint_range(0.5, 16.0) = 3.4;
uniform float sun_disc_energy : hint_range(0.0, 40.0) = 6.0;
uniform float sun_softness : hint_range(0.0005, 0.4) = 0.10;
// LIGHT0_DIRECTION is the direction light TRAVELS, so the disc sits along its
// negation. If a build ever renders the sun on the wrong side of the dome, set
// this to -1.0 — it is the only sign in the file.
uniform float sun_dir_sign : hint_range(-1.0, 1.0) = 1.0;

void sky() {
	float y = clamp(EYEDIR.y, -1.0, 1.0);

	float up = clamp(y, 0.0, 1.0);
	vec3 above = mix(horizon_color * horizon_energy,
					 zenith_color * zenith_energy,
					 pow(up, 1.0 / horizon_falloff));

	float down = clamp(-y, 0.0, 1.0);
	vec3 below = mix(horizon_color * horizon_energy * 0.55,
					 ground_color * ground_energy,
					 pow(down, 0.35));

	vec3 col = mix(below, above, step(0.0, y));

	if (LIGHT0_ENABLED) {
		vec3 sun_dir = normalize(LIGHT0_DIRECTION * (-sun_dir_sign));
		float d = dot(EYEDIR, sun_dir);
		float disc = smoothstep(1.0 - sun_softness, 1.0 - sun_softness * 0.15, d);
		float halo = pow(clamp(d, 0.0, 1.0), 24.0) * 0.30;
		col += LIGHT0_COLOR * LIGHT0_ENERGY * (disc * sun_disc_energy + halo);
	}

	COLOR = col;
}
"""


# ── THE VIGNETTE ─────────────────────────────────────────────────────────────
# Godot's Environment has no vignette. There is no property to set — the effect
# genuinely does not exist in the engine, and any answer claiming otherwise is
# describing Godot 3's tonemap or somebody's addon. So it is a fullscreen
# canvas_item pass, which is the cheapest honest way to get one.
#
# What makes a vignette look cheap is a hard inner edge and a neutral black. So:
# the falloff starts at 0.46 of the half-diagonal and does not reach full until
# past the corner (outer 1.05, i.e. it is still ramping when it runs out of
# screen), and the tint is a very slightly blue-black rather than 0,0,0 — real
# lens falloff darkens toward the ambient colour of the room, not toward void.
const VIGNETTE_SHADER := """
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float vignette_amount : hint_range(0.0, 1.0) = 0.26;
uniform float vignette_inner : hint_range(0.0, 1.5) = 0.46;
uniform float vignette_outer : hint_range(0.0, 2.0) = 1.05;
uniform vec4 vignette_tint : source_color = vec4(0.015, 0.016, 0.024, 1.0);

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 1.41421356;
	float v = smoothstep(vignette_inner, vignette_outer, r);
	COLOR = vec4(vignette_tint.rgb, v * vignette_amount);
}
"""


## Which tier this process runs at. Resolved once, then cached.
## Order of authority: explicit --em-quality= argument, then VR (a 90 Hz
## stereo target cannot afford SSIL + SSR + volumetric fog and it is not close),
## then "high".
static func tier() -> String:
	if _tier_cache != "":
		return _tier_cache
	var t: String = TIER_HIGH
	var args: Array = []
	args.append_array(OS.get_cmdline_user_args())
	args.append_array(OS.get_cmdline_args())
	for a in args:
		var s: String = String(a)
		if s.begins_with("--em-quality="):
			t = s.substr(13).strip_edges().to_lower()
	if t != TIER_PERF and t != TIER_HIGH:
		push_warning("EmEnvironment: unknown quality tier `%s`, using high" % t)
		t = TIER_HIGH
	if t == TIER_HIGH and _in_vr():
		t = TIER_PERF
	_tier_cache = t
	return t


## Reset the cached tier. Only useful for tests that want to force a tier.
static func set_tier(t: String) -> void:
	_tier_cache = TIER_PERF if t == TIER_PERF else TIER_HIGH


## THE ENVIRONMENT. Everything in one node, ready to add_child.
static func build(tier_override: String = "") -> WorldEnvironment:
	var t: String = tier_override if tier_override != "" else tier()
	var high: bool = t == TIER_HIGH

	var we := WorldEnvironment.new()
	we.name = "EmEnvironment"
	var e := Environment.new()

	# ── background + ambient ────────────────────────────────────────────────
	e.background_mode = Environment.BG_SKY
	e.background_energy_multiplier = 1.0
	e.sky = _sky(high)
	# Ambient comes from the dome, not from a flat colour: a museum's fill light
	# is directional-ish (bright from above, dark from below) and a constant
	# ambient colour is precisely the thing that makes procedural interiors look
	# like they were rendered in 2009.
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 1.0
	# THE CONTRACT'S HARDEST NUMBER. em_lighting.gd builds a real rig — coves,
	# wall washers, key lights on every slot — and its energies assume ambient
	# is a floor, not a light. 0.28 (contract max 0.30) is that floor: it stops
	# unlit plaster clipping to zero without lifting the rig's shadows off the
	# wall. The baseline scene's 1.2 would erase every one of those lights.
	# On perf there is no SDFGI and no SSIL, so ambient has to carry the bounce
	# it is no longer being given — 0.62 is the compensation, and it is
	# knowingly outside the contract because the contract assumes GI exists.
	e.ambient_light_energy = 0.28 if high else 0.62
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	# ── tonemap: the single largest change to the image ─────────────────────
	e.tonemap_mode = TONEMAP
	e.tonemap_exposure = TONEMAP_EXPOSURE
	e.tonemap_white = TONEMAP_WHITE

	# ── SSAO: contact shadows are what sell scale ───────────────────────────
	# In a room of untextured boxes, ambient occlusion is doing the job a normal
	# map would do elsewhere: it is the only cue that the podium is ON the floor
	# rather than intersecting it, and the only thing that gives a 3 m wall a
	# visible base. Turn it off and the corridor reads as flat-shaded cardboard
	# no matter what the lighting does.
	e.ssao_enabled = true
	# 0.55 m, down from 1.1. One radius cannot bracket both the 0.6 m podium and
	# the 3 m wall/floor junction — stretched across both it produced a soft wide
	# term that was invisible at every seam in the building, and four proof shots
	# came back with the wall's last pixel and the floor's first pixel differing
	# by essentially nothing. This is now the TIGHT term: it does the arrises, the
	# skirting line and the podium contact. The wide term is SSIL's job.
	e.ssao_radius = 0.55
	# Above Godot's 2.0 default. Near-neutral high-albedo surfaces bounce so
	# much light back into their own corners that physically-correct AO is
	# nearly invisible on them; 2.8 is the compensation for a white museum.
	e.ssao_intensity = 2.8
	e.ssao_power = 1.5          # perceptual falloff; default, and correct
	e.ssao_detail = 0.85        # well above default — the tight radius needs it
	e.ssao_horizon = 0.06       # rejects self-occlusion on grazing faces
	e.ssao_sharpness = 0.98     # stops AO bleeding across depth discontinuities
	# AO is an AMBIENT term, and 0.1 is the physically defensible number — which
	# is exactly why there was no contact occlusion anywhere in the frame. This
	# room is lit ~95% by direct spot light over an ambient of 0.28, so an
	# ambient-only multiplier is being multiplied into approximately zero. 0.35 is
	# a lie, every shipped title tells it, and in a direct-lit room it is the only
	# corner darkening you get.
	e.ssao_light_affect = 0.35
	e.ssao_ao_channel_affect = 0.0   # no material AO maps in this scene

	# ── SSIL: short-range bounce SDFGI is too coarse to see ─────────────────
	# SDFGI's cascade 0 is 0.2 m cells; it gets the room-scale bounce right and
	# is blind to everything smaller. SSIL fills exactly that gap — the colour a
	# podium picks up from the wall 2 m behind it, the warm return under a lit
	# plinth. On an artifact standing 0.8 m off a plinth it is the difference
	# between an object in a room and an object composited into one.
	e.ssil_enabled = high
	# 4.0 m, under the 5.0 default. A gallery here is 13-17 m wide; 4 m gathers
	# from the nearest wall and the neighbouring podium and stops before it
	# starts smearing the far side of the room into the near side.
	e.ssil_radius = 4.0
	# 1.15: with the daylight family now outside the roof there is finally a real
	# bounce budget in the room. Above ~1.3 high-albedo plaster goes milky.
	e.ssil_intensity = 1.15
	e.ssil_sharpness = 0.98
	e.ssil_normal_rejection = 1.0   # full: a surface must not light itself

	# ── SSR: the polished floor ─────────────────────────────────────────────
	# A museum floor is terrazzo or polished concrete, and the single strongest
	# read of "this is a real building" is the vertical smear of the far wall in
	# it. Nothing else in the pipeline can produce that: SDFGI is diffuse-only
	# and the sky reflection is a uniform dome.
	# This does nothing until the material pass gives the floor roughness below
	# about 0.45 — SSR is invisible on a fully rough surface by definition.
	e.ssr_enabled = high
	# 64 steps at this scale traces roughly the length of one gallery, which is
	# what a corridor reflection needs; the usual advice to drop to 32 is for
	# scenes where reflections are decorative rather than load-bearing.
	e.ssr_max_steps = 64
	# Reflections start at the contact point — that is what grounds a podium.
	e.ssr_fade_in = 0.15
	# Long dissolve, so rays that run out of screen fade instead of terminating
	# in a hard horizontal line across the floor.
	e.ssr_fade_out = 2.0
	e.ssr_depth_tolerance = 0.2

	# ── SDFGI: mirrored from em_lighting, see header ────────────────────────
	# The only GI that works here. LightmapGI cannot bake geometry that is
	# streamed into existence at runtime, and VoxelGI would need a rebuild per
	# segment. SDFGI is designed for exactly this: it re-scans as the world
	# moves under it.
	e.sdfgi_enabled = high
	if high:
		e.sdfgi_cascades = int(SDFGI_MIRROR["cascades"])
		e.sdfgi_min_cell_size = float(SDFGI_MIRROR["min_cell_size"])
		e.sdfgi_use_occlusion = bool(SDFGI_MIRROR["use_occlusion"])
		e.sdfgi_bounce_feedback = float(SDFGI_MIRROR["bounce_feedback"])
		e.sdfgi_read_sky_light = bool(SDFGI_MIRROR["read_sky_light"])
		e.sdfgi_energy = float(SDFGI_MIRROR["energy"])
		e.sdfgi_normal_bias = float(SDFGI_MIRROR["normal_bias"])
		e.sdfgi_probe_bias = float(SDFGI_MIRROR["probe_bias"])
		e.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT

	# ── glow: only real highlights ──────────────────────────────────────────
	e.glow_enabled = true
	# Normalized keeps total glow energy constant as the level mix changes, so
	# the curve below is a SHAPE choice and not secretly a brightness choice.
	e.glow_normalized = true
	# Restrained. Glow is the effect that most reliably makes an image look
	# like a game rather than a photograph.
	e.glow_intensity = 0.55
	e.glow_strength = 1.0
	# THE IMPORTANT ZERO. glow_bloom adds glow to pixels BELOW the threshold —
	# i.e. to everything. Any non-zero value here hazes the whole frame and is
	# the actual cause of most "why does my Godot scene look soft" complaints.
	e.glow_bloom = 0.0
	# SCREEN, not ADDITIVE: additive is physically the right model but stacks
	# unboundedly over em_lighting's many small practicals; screen approaches
	# 1.0 asymptotically, so no amount of overlapping sources blows a hole in
	# the image. Not SOFTLIGHT (Godot's default), which is a compositing trick
	# that greys the whole frame.
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	# 1.0 exactly, per the contract. In scene-linear terms this is diffuse white
	# under full key — so lit plaster does NOT glow, and the emissive threshold
	# strip (emission_energy 1.6) and em_lighting's practicals do. That
	# boundary is the entire design of the effect.
	e.glow_hdr_threshold = 1.0
	e.glow_hdr_scale = 2.0
	e.glow_hdr_luminance_cap = 12.0   # kills single-pixel fireflies
	# The level mix IS the look. Levels 1-2 are the pixel-tight blurs that read
	# as sharpening artefacts, not as light. Levels 4-5 are the wide, low
	# halos that real glare in a real room actually looks like. So: kill the
	# tight ones, weight the wide ones, taper the widest so the glow does not
	# turn into a full-frame veil.
	# OFF BY ONE, and it errored on every single boot: set_glow_level takes an
	# INDEX 0..6 which addresses glow_levels/1..7, so the intended "kill 1 and 2,
	# weight 4 and 5, taper 7" was actually killing 2 and 3, weighting 5 and 6,
	# and calling index 7 — out of bounds, one ERROR line per launch, and the
	# widest level left at its default the whole time.
	#   ERROR: Index p_level = 7 is out of bounds (MAX_GLOW_LEVELS = 7)
	e.set_glow_level(0, 0.0)   # glow_levels/1
	e.set_glow_level(1, 0.0)   # glow_levels/2
	e.set_glow_level(2, 0.6)   # glow_levels/3
	e.set_glow_level(3, 1.0)   # glow_levels/4
	e.set_glow_level(4, 1.0)   # glow_levels/5
	e.set_glow_level(5, 0.4)   # glow_levels/6
	e.set_glow_level(6, 0.0)   # glow_levels/7

	# ── distance fog: aerial perspective, on both tiers ──────────────────────
	# Cheap, and it does something no light can: it separates the gallery you
	# are in from the two beyond it. Without it a 100 m enfilade is a flat
	# collage of equally-contrasty rooms at different sizes.
	# Exponential mode (the default) is deliberate — the depth mode's begin/end
	# ramp has to be retuned per template width, and these templates vary from
	# 13 to 17 cells.
	e.fog_enabled = true
	# 0.0035: at 30 m this is about 10% haze, at 100 m about 30%. Deep enough
	# to read as air, shallow enough that the far vestibule banner stays legible.
	e.fog_density = 0.0035
	e.fog_light_color = Color(0.62, 0.655, 0.735)   # cool, matched to the dome
	# 1.0, up from 0.6. Aerial perspective lightens distance, and a corridor whose
	# floor read 0.03-0.08 had nothing to lighten FROM, so 30 m read as "unlit"
	# rather than as "far". Raised only now that the ambient keys floor the deck.
	e.fog_light_energy = 1.0
	# The sun is contracted to <= 0.35 energy, so a big scatter term would be
	# writing a sunbeam the lighting rig never authorised.
	e.fog_sun_scatter = 0.08
	# Distant geometry takes the sky's own colour rather than a fog tint. This
	# is what makes the view through a far exit gap look like depth instead of
	# like a grey wash laid over the frame.
	e.fog_aerial_perspective = 0.8
	e.fog_height = 0.0
	e.fog_height_density = 0.0
	# 4.2+ property: keep the dome itself out of the fog, or the sky through a
	# doorway goes milky and the whole exterior reads as smog.
	_try_set(e, "fog_sky_affect", 0.25)

	# ── volumetric fog: the light shafts ────────────────────────────────────
	e.volumetric_fog_enabled = high
	# 0.010, under the contract's 0.012 ceiling and five times under Godot's
	# 0.05 default. The default is a fog machine. This is dust in a room: you
	# cannot see the medium, you can only see where a light passes through it,
	# which is the entire point of the effect.
	e.volumetric_fog_density = 0.012
	e.volumetric_fog_albedo = Color(0.92, 0.93, 0.96)
	e.volumetric_fog_emission = Color(0, 0, 0)
	# Zero, and load-bearing. Self-lit fog means shafts appear in rooms with no
	# light in them, which is the tell of a fake volumetric.
	e.volumetric_fog_emission_energy = 0.0
	# Feeds SDFGI's bounce into the medium so the air in a bounce-lit room is
	# not black. Under the 1.0 default because at 1.0 the GI washes the shafts
	# back out and the effect cancels itself.
	e.volumetric_fog_gi_inject = 0.6
	# Forward scattering. THIS is the parameter that makes a shaft brighten as
	# you turn to face the light — the view-dependence that reads as real air.
	# Above Godot's 0.2. 0.45 now that there is a shaft to be view-dependent
	# ABOUT — the budget was being spent on a froxel grid with no beam in it,
	# because every cone was a clean uninterrupted solid under a sealed lid.
	e.volumetric_fog_anisotropy = 0.45
	# 48 m, under the 64 default. Froxel count is fixed, so a shorter volume
	# spends more resolution per metre. 48 covers the current gallery plus the
	# vestibule beyond, which is everything the fog is ever asked to describe.
	e.volumetric_fog_length = 48.0
	e.volumetric_fog_detail_spread = 2.0    # bias froxels toward the camera
	e.volumetric_fog_ambient_inject = 0.25
	# NOT OPTIONAL with a moving camera. Without reprojection the froxel grid
	# visibly crawls and swims as the walker moves; it is the most common reason
	# volumetric fog gets abandoned as "too noisy".
	e.volumetric_fog_temporal_reprojection_enabled = true
	e.volumetric_fog_temporal_reprojection_amount = 0.9
	_try_set(e, "volumetric_fog_sky_affect", 0.4)

	# ── grade: restrained, and required by the AgX choice ───────────────────
	e.adjustment_enabled = true
	# Brightness stays at 1.0 on purpose. Brightness is a post-tonemap lift that
	# crushes the curve AgX just spent its whole budget shaping; exposure and
	# auto-exposure are the correct levers and they run before the tonemapper.
	e.adjustment_brightness = 1.0
	# The AgX repayment. 1.12 restores roughly the shoulder ACES would have
	# given, applied after the neutral rolloff rather than baked into it.
	e.adjustment_contrast = 1.12
	# AgX desaturates into highlights by design. Without this the museum accent
	# colours — the whole point of each building wearing its own hex — drift
	# grey. 1.08 is a lift, not a boost.
	e.adjustment_saturation = 1.08
	# A per-channel print emulation: a faint cool lift in the blacks and a faint
	# warm roll in the whites. Near-identity by construction (see
	# _color_grade_lut) — this is the two-degree tilt that separates a graded
	# frame from a raw one, not a look.
	e.adjustment_color_correction = _color_grade_lut()

	we.environment = e
	we.camera_attributes = camera_attributes(t)
	apply_render_quality(t)
	return we


## THE CAMERA. Practical rather than Physical: Physical derives depth of field
## from aperture and focal length, which is the honest model but couples the
## focus falloff to a focal length em_feel.gd is actively animating (it drives
## Camera3D.fov for the run/land response). Practical's explicit far-distance is
## independent of fov, so the blur does not breathe every time the walker
## sprints. For a still-camera hero shot Physical would be the better choice.
static func camera_attributes(tier_override: String = "") -> CameraAttributes:
	var t: String = tier_override if tier_override != "" else tier()
	var high: bool = t == TIER_HIGH
	var hero: bool = _is_shot_run()
	var ca := CameraAttributesPractical.new()

	# ── depth of field ──────────────────────────────────────────────────────
	# Off entirely on perf: DOF is a full-resolution gather and it is the first
	# thing to cut.
	ca.dof_blur_far_enabled = high
	# 26 m. The templates are up to 30 cells deep plus a 4-cell vestibule, so
	# the far wall of the gallery you are standing in sits at roughly 30 m.
	# Focusing at 26 keeps the entire room you occupy sharp and lets only the
	# NEXT room — seen through the exit gap — go soft. That is the composition:
	# what is in front of you is resolved, what is coming is not yet.
	ca.dof_blur_far_distance = 26.0
	# A long ramp, 26 m -> 40 m. Short transitions produce a visible plane of
	# focus that sweeps through the room as you walk, which reads as a bug.
	ca.dof_blur_far_transition = 14.0
	# Near DOF is OFF for walking, and this is a deliberate refusal. At a 1.65 m
	# eye height in a space you can walk through, near blur softens the podium
	# you are standing at — the thing you are looking at — and every player
	# reads that as their own eyes failing rather than as a lens. It is switched
	# on only for --em-shot proof stills, where the frame is a photograph and
	# nobody is trying to look at anything.
	ca.dof_blur_near_enabled = high and hero
	ca.dof_blur_near_distance = 0.6
	ca.dof_blur_near_transition = 0.8
	# 0.06 on a 0..1 scale. Godot's DOF is aggressive: 0.1 is already a
	# tilt-shift toy. 0.06 is roughly a fast wide-angle wide open — present in
	# the frame, invisible as an effect.
	ca.dof_blur_amount = 0.06

	# ── auto exposure ───────────────────────────────────────────────────────
	# THE EYE. em_lighting's rig is genuinely contrasty — 2700 K coves in the
	# circulation, a bright daylit gallery beyond. A fixed exposure has to pick
	# one and lose the other. Auto-exposure with a slow constant does what a
	# real eye does: step from the dark vestibule into the gallery and the room
	# is briefly too bright, then settles.
	#
	# Except in a --em-shot run. A proof still is captured 90 frames in, which
	# at this adaptation rate is PART WAY through the ramp — so the same command
	# would produce a different exposure depending on how the frames happened to
	# land. Captures must be deterministic, so a shot run freezes exposure. This
	# is the kind of thing that otherwise gets discovered as "the sweep produced
	# six slightly different tiles and nobody knows why".
	ca.auto_exposure_enabled = not hero
	# 0.45, slightly above Godot's 0.4: aims a little above mid-grey so lit
	# galleries stay bright rather than being averaged down by the dark
	# circulation that surrounds them.
	ca.auto_exposure_scale = 0.45
	# SLOW, and the requirement said so. 0.28 against a 0.5 default is roughly a
	# three-second adaptation, in the region of human photopic adaptation. Fast
	# auto-exposure is worse than none: it pumps as you turn your head.
	ca.auto_exposure_speed = 0.28
	# THE CLAMP THAT SAVES THE MOOD. Unbounded auto-exposure lifts a deliberately
	# dark vestibule to daylight and the dark room stops being dark — the classic
	# way auto-exposure destroys a lighting design. 40..500 ISO is about 3.6
	# stops of latitude: enough that your eye adjusts, not enough that the
	# building loses its dynamic range.
	ca.auto_exposure_min_sensitivity = 40.0
	ca.auto_exposure_max_sensitivity = 500.0

	# Base-class multiplier, applied before the tonemapper. Left at unity: all
	# exposure intent is expressed in tonemap_exposure so there is exactly one
	# number to turn.
	ca.exposure_multiplier = 1.0
	return ca


## The vignette pass Godot does not have. Returns null on perf, or when
## use_vignette is false. mouse_filter is IGNORE so it cannot eat the click that
## captures the mouse in endless_museum.gd's _input().
static func vignette(tier_override: String = "") -> CanvasLayer:
	var t: String = tier_override if tier_override != "" else tier()
	if not use_vignette or t != TIER_HIGH:
		return null
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh

	var rect := ColorRect.new()
	rect.name = "Vignette"
	rect.color = Color.WHITE
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ...and_offsets_preset, not set_anchors_preset: the latter moves the anchors
	# but leaves the offsets, which on a fresh Control means a zero-sized rect
	# and a vignette that silently does nothing.
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layer := CanvasLayer.new()
	layer.name = "EmVignette"
	layer.layer = 90
	layer.add_child(rect)
	return layer


## One-line integration. Adds the WorldEnvironment and the vignette to `parent`,
## and binds the camera attributes to `cam` (a camera-local override beats the
## world one, so a future second camera can carry a different lens).
static func install(parent: Node, cam: Camera3D = null, tier_override: String = "") -> WorldEnvironment:
	if parent == null:
		return null
	var t: String = tier_override if tier_override != "" else tier()
	var we: WorldEnvironment = build(t)
	parent.add_child(we)
	if cam != null:
		cam.attributes = we.camera_attributes
	var vg: CanvasLayer = vignette(t)
	if vg != null:
		parent.add_child(vg)
	print("[em_environment] %s" % describe(t).replace("\n", " | "))
	return we


## Renderer-wide quality knobs that live on RenderingServer rather than on
## Environment. These are the per-effect sample counts and blur passes; the
## Environment properties above only say WHETHER an effect runs, not how well.
## Runtime only — no project setting is written, no file is touched.
##
## Every call goes through _rs_call, which checks has_method first, so a rename
## in a future engine version degrades to a warning instead of a dead scene.
## Enum values are passed as literals for the same reason (a missing named
## constant is a PARSE error in GDScript, and a parse error here would take the
## whole museum down).
static func apply_render_quality(tier_override: String = "") -> void:
	var t: String = tier_override if tier_override != "" else tier()
	var high: bool = t == TIER_HIGH

	# EnvironmentSSAOQuality: 0 VERY_LOW, 1 LOW, 2 MEDIUM, 3 HIGH, 4 ULTRA.
	# HIGH at full resolution, not half. Half-res SSAO is where corner AO picks
	# up the stair-stepping that makes contact shadows look like dirt maps —
	# and contact shadows are the effect this whole file leans on hardest.
	# args: (quality, half_size, adaptive_target, blur_passes, fade_from, fade_to)
	_rs_call("environment_set_ssao_quality",
		[3 if high else 1, not high, 0.5, 2, 50.0, 300.0])
	# SSIL is a lower-frequency term, so half-res is nearly free of visible cost
	# even on high; MEDIUM with 4 blur passes reads smoother than HIGH with 2.
	_rs_call("environment_set_ssil_quality",
		[2 if high else 0, true, 0.5, 4, 50.0, 300.0])
	# EnvironmentSSRRoughnessQuality: 0 DISABLED, 1 LOW, 2 MEDIUM, 3 HIGH.
	# MEDIUM: the floor is polished but not a mirror, so the roughness blur is
	# doing real work and LOW banding would show in it.
	# DROPPED. has_method() still returns true for it, so the guard does not
	# catch it, and the engine answers every call with
	#   "environment_set_ssr_roughness_quality has been deprecated and no longer
	#    does anything"
	# SSR roughness quality is not a knob on this build; the comment that used to
	# live here argued for MEDIUM over LOW and was describing a setting that has
	# had no effect for several engine versions.
	# _rs_call("environment_set_ssr_roughness_quality", [2 if high else 0])
	# Bicubic glow upscale. Costs almost nothing and removes the blocky
	# stepping on the wide glow levels (4 and 5) that carry the whole effect.
	_rs_call("environment_glow_set_use_bicubic_upscale", [high])
	# The volumetric froxel grid. 128x128x64 against the default 64x64x32:
	# doubling the lateral resolution is what stops a light shaft looking like a
	# stack of translucent slabs when you walk along it.
	_rs_call("environment_set_volumetric_fog_volume_size",
		[128 if high else 64, 64 if high else 32])
	_rs_call("environment_set_volumetric_fog_filter_active", [true])
	# DOFBlurQuality: 0 VERY_LOW, 1 LOW, 2 MEDIUM, 3 HIGH. Jitter on — it trades
	# a little noise for the removal of the concentric rings that low-quality
	# bokeh gathers produce on a soft, wide falloff like ours.
	_rs_call("camera_attributes_set_dof_blur_quality", [3 if high else 1, true])
	# BOKEH: 0 BOX, 1 HEXAGON, 2 CIRCLE. Circle — a box bokeh is visible as
	# square highlights the moment a practical goes out of focus.
	_rs_call("camera_attributes_set_dof_blur_bokeh_shape", [2])
	# SDFGI convergence. 4 rays/frame over 16 frames is the quality preset; the
	# corridor is streamed, so cascades are constantly being re-scanned and a
	# fast-but-noisy setting would show as crawling bounce light on the walls.
	if high:
		_rs_call("environment_set_sdfgi_ray_count", [2])          # 2 == 32 rays
		_rs_call("environment_set_sdfgi_frames_to_converge", [3]) # 3 == 16 frames
		_rs_call("environment_set_sdfgi_frames_to_update_light", [2])  # 2 == 4


## Diff a built Environment against a contract dictionary. Pass
## EmLighting.ENV_CONTRACT to check the two files still agree; pass
## ENV_CONTRACT_MIRROR to check this file against its own copy. Returns a list
## of human-readable breaches, empty when clean — so it gates:
##   assert(EmEnvironment.check_contract(env, EmLighting.ENV_CONTRACT).is_empty())
static func check_contract(env: Environment, contract: Dictionary) -> Array:
	var out: Array = []
	if env == null:
		return ["environment is null"]
	if contract.has("ambient_light_energy_max"):
		var cap: float = float(contract["ambient_light_energy_max"])
		if env.ambient_light_energy > cap + 0.0001:
			out.append("ambient_light_energy %.3f > contract max %.3f" % [
				env.ambient_light_energy, cap])
	if contract.has("volumetric_fog_density_max"):
		var fcap: float = float(contract["volumetric_fog_density_max"])
		if env.volumetric_fog_enabled and env.volumetric_fog_density > fcap + 0.00001:
			out.append("volumetric_fog_density %.4f > contract max %.4f" % [
				env.volumetric_fog_density, fcap])
	if contract.has("tonemap_white"):
		var w: float = float(contract["tonemap_white"])
		if absf(env.tonemap_white - w) > 0.01:
			out.append("tonemap_white %.2f != contract %.2f" % [env.tonemap_white, w])
	if contract.has("glow_hdr_threshold"):
		var g: float = float(contract["glow_hdr_threshold"])
		if absf(env.glow_hdr_threshold - g) > 0.01:
			out.append("glow_hdr_threshold %.2f != contract %.2f" % [
				env.glow_hdr_threshold, g])
	# Explicit String(k): the loop variable off an untyped array literal is a
	# Variant, and Object.get() wants a StringName.
	for kv in ["ssao_enabled", "ssil_enabled", "glow_enabled"]:
		var k: String = String(kv)
		if contract.has(k) and bool(contract[k]) and not bool(env.get(k)):
			out.append("%s is false, contract requires true" % k)
	if contract.has("tonemap"):
		var want: String = String(contract["tonemap"]).to_upper()
		var got: String = "AGX" if env.tonemap_mode == Environment.TONE_MAPPER_AGX else (
			"ACES" if env.tonemap_mode == Environment.TONE_MAPPER_ACES else "OTHER")
		if want != got:
			# Informational, not a failure: the divergence is argued in the
			# header and the exposure is compensated for it.
			out.append("NOTE tonemap %s (contract said %s; see em_environment.gd header)" % [got, want])
	return out


## One-line ledger of what is actually on. Printed by install().
static func describe(tier_override: String = "") -> String:
	var t: String = tier_override if tier_override != "" else tier()
	var high: bool = t == TIER_HIGH
	var lines: Array = []
	lines.append("tier=%s" % t)
	lines.append("tonemap=%s exposure=%.2f white=%.1f" % [
		"AgX" if TONEMAP == Environment.TONE_MAPPER_AGX else "ACES",
		TONEMAP_EXPOSURE, TONEMAP_WHITE])
	lines.append("ssao=on(r0.55 i2.8 la0.35)")
	lines.append("ssil=%s" % ("on(r4.0 i1.15)" if high else "off"))
	lines.append("ssr=%s" % ("on(64 steps)" if high else "off"))
	lines.append("sdfgi=%s" % ("on(0.2m/4casc)" if high else "off"))
	lines.append("glow=on(thr1.0 screen)")
	lines.append("fog=on(0.0035) vfog=%s" % ("on(0.012)" if high else "off"))
	lines.append("dof=%s" % ("far 26m/+14m" if high else "off"))
	lines.append("autoexp=%s" % ("frozen (shot run)" if _is_shot_run() else "on(speed 0.28, ISO 40-500)"))
	lines.append("vignette=%s" % ("on(0.26)" if (high and use_vignette) else "off"))
	lines.append("sky=%s" % ("shader dome" if use_shader_sky else "procedural"))
	return "\n".join(PackedStringArray(lines))


# ── internals ────────────────────────────────────────────────────────────────

static func _sky(high: bool) -> Sky:
	var sky := Sky.new()
	# 256 on high: the dome is smooth and low-frequency, so radiance resolution
	# buys nothing above this, and 128 is enough to band a large flat wall lit
	# only by ambient.
	sky.radiance_size = Sky.RADIANCE_SIZE_256 if high else Sky.RADIANCE_SIZE_128
	# The dome never changes, so QUALITY is a one-time cost rather than a
	# per-frame one. REALTIME would pay less once and worse forever.
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.sky_material = _sky_material() if use_shader_sky else _procedural_sky()
	return sky


static func _sky_material() -> Material:
	var sh := Shader.new()
	sh.code = SKY_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("zenith_color", Color(0.196, 0.239, 0.318))
	m.set_shader_parameter("horizon_color", Color(0.706, 0.706, 0.686))
	m.set_shader_parameter("ground_color", Color(0.098, 0.094, 0.090))
	m.set_shader_parameter("zenith_energy", 2.10)
	m.set_shader_parameter("horizon_energy", 1.30)
	m.set_shader_parameter("ground_energy", 0.40)
	m.set_shader_parameter("horizon_falloff", 3.4)
	m.set_shader_parameter("sun_disc_energy", 6.0)
	m.set_shader_parameter("sun_softness", 0.10)
	m.set_shader_parameter("sun_dir_sign", 1.0)
	return m


## Fallback dome, same intent in the stock material: slate zenith, warm pale
## horizon, dark warm ground. Used when use_shader_sky is false.
static func _procedural_sky() -> Material:
	var p := ProceduralSkyMaterial.new()
	p.sky_top_color = Color(0.196, 0.239, 0.318)
	p.sky_horizon_color = Color(0.706, 0.706, 0.686)
	p.sky_curve = 0.25
	p.sky_energy_multiplier = 2.0
	p.ground_bottom_color = Color(0.098, 0.094, 0.090)
	p.ground_horizon_color = Color(0.392, 0.392, 0.380)
	p.ground_curve = 0.35
	p.ground_energy_multiplier = 0.4
	p.sun_angle_max = 12.0
	p.sun_curve = 0.12
	return p


## The print emulation LUT. Godot samples this per channel by value, so a
## gradient is a per-channel transfer curve: blue slightly above identity at the
## bottom lifts the blacks cool, red slightly above / blue slightly below at the
## top rolls the whites warm.
##
## Kept near-identity ON PURPOSE. The offsets are under 2.5% at both ends —
## enough to read as a print, small enough that if Godot's sampling convention
## is not exactly what is assumed here, the worst case is that nothing visible
## happens rather than that the image is wrecked.
static func _color_grade_lut() -> GradientTexture1D:
	var g := Gradient.new()
	# A default Gradient has two stops: 0 black, 1 white. Add the midpoint, then
	# tint the ends — never reassign offsets and colors as whole arrays, which
	# transiently mismatches their lengths.
	g.add_point(0.5, Color(0.5, 0.5, 0.5))
	g.set_color(0, Color(0.012, 0.014, 0.024))   # cool lifted black
	g.set_color(2, Color(1.000, 0.995, 0.982))   # warm white, blue pulled down
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	tex.use_hdr = false
	return tex


## True during a --em-shot capture run. Used to freeze auto-exposure so proof
## stills are deterministic.
static func _is_shot_run() -> bool:
	var args: Array = []
	args.append_array(OS.get_cmdline_user_args())
	args.append_array(OS.get_cmdline_args())
	for a in args:
		if String(a).begins_with("--em-shot="):
			return true
	return false


static func _in_vr() -> bool:
	if not Engine.has_singleton("XRServer"):
		return false
	var xr: Object = Engine.get_singleton("XRServer")
	if xr == null:
		return false
	return xr.get("primary_interface") != null


## Set a property only if this engine build has it. Used for the handful of
## Environment properties added after 4.0, so this file stays loadable on an
## older editor instead of throwing at parse time.
static func _try_set(o: Object, prop: String, v: Variant) -> void:
	if o == null:
		return
	if prop in o:
		o.set(prop, v)


## Call a RenderingServer method by name only if it exists. Named enum constants
## are resolved at COMPILE time in GDScript, so a constant that has been renamed
## is a parse error that kills the scene; a method looked up by name is a
## warning. Hence the integer literals at every call site above.
static func _rs_call(method: String, args: Array) -> void:
	if RenderingServer.has_method(method):
		RenderingServer.callv(method, args)
	else:
		push_warning("EmEnvironment: RenderingServer has no %s() on this build" % method)
