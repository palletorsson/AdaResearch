extends RefCounted

## THE SHADER SIDE OF THE GLOSS (2026-09-03, Palle: "add crazy queer glossy
## fetish art — materials shaders").
##
## [b]dream_skin.gd[/b] deals finishes out of StandardMaterial3D and will keep
## doing so: it is cheap, it batches, and forty-one families already wear it.
## This file is for the register a StandardMaterial3D cannot reach at all —
## interference, diffraction, a reflected environment on a plate that has none,
## and harness/lace/buckle/cage/zip drawn in the fragment over ANY body without
## a new triangle or a UV map. See dream_gloss.gdshader for why each one has to
## be a shader.
##
## STATIC AND PURE, like every builder under bodies/: give it a name and two
## colours, get a ShaderMaterial. Nothing touches the tree.
##
## ONE SHADER, MANY MATERIALS. The Shader resource is preloaded once and shared;
## each call returns its own ShaderMaterial with its own uniforms, which is how
## Godot wants this — a hundred bodies compile the program once.

const SHADER: Shader = preload("res://commons/artifacts/dream_bodies/dream_gloss.gdshader")

## The surfaces, in the shader's own uniform order. Index IS the `mode` value —
## so this array and the shader cannot drift apart the way a hand-typed registry
## block drifts from an enum.
const SURFACES: Array[String] = ["latex", "patent", "oilslick", "holo", "pvc", "chrome"]

## The harnesses, likewise: index IS the `harness` uniform.
const HARNESSES: Array[String] = ["bare", "strap", "lace", "buckle", "cage", "zip"]

const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")


## One dressed surface.
##
## `surface` and `harness` are names from the two arrays above; anything else
## falls back to index 0, so a typo gets latex rather than a null. `seed` shifts
## the film thickness, the grating phase and the reflected streaks, so two
## bodies in the same finish are not the same photograph.
static func skin(surface: String, harness: String, base: Color, accent: Color,
		seed: int = 0, leather: Color = Color(0.06, 0.05, 0.09)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("mode", maxi(0, SURFACES.find(surface)))
	m.set_shader_parameter("harness", maxi(0, HARNESSES.find(harness)))
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("accent_color", accent)
	m.set_shader_parameter("harness_color", leather)
	m.set_shader_parameter("hardware_color", Color(0.86, 0.87, 0.92))
	m.set_shader_parameter("seed_offset", float(seed % 997) * 0.37)
	m.set_shader_parameter("film_scale", 1.6 + float(seed % 7) * 0.34)
	m.set_shader_parameter("grating", 12.0 + float(seed % 11) * 2.4)
	m.set_shader_parameter("sheen", 1.0)
	m.set_shader_parameter("glow", 0.35)
	# a default that suits a standing figure; a builder with a different body
	# overrides it, and the harness follows the body instead of the object units
	m.set_shader_parameter("body_h", 1.65)
	return m


## A whole body's worth, dealt from one seed: a surface, a harness and two
## colours out of the same queer palette dream_skin.gd already uses, so a shader
## body and a StandardMaterial3D body stand in the same room without clashing.
static func outfit(rng: RandomNumberGenerator, surface: String = "", harness: String = "") -> Dictionary:
	var s: String = surface if surface != "" else SURFACES[rng.randi_range(0, SURFACES.size() - 1)]
	var h: String = harness if harness != "" else HARNESSES[rng.randi_range(0, HARNESSES.size() - 1)]
	var main: Color = Gloss.queer_colour(rng)
	var accent: Color = Gloss.queer_colour(rng)
	var tries: int = 0
	while accent.is_equal_approx(main) and tries < 6:
		accent = Gloss.queer_colour(rng)
		tries += 1
	return {
		"surface": s,
		"harness": h,
		"main": main,
		"accent": accent,
		"skin": skin(s, h, main, accent, rng.randi()),
	}
