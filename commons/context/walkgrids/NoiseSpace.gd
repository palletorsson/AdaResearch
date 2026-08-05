# NoiseSpace.gd - Algorithmic disruption
# @identity
# essence: height(x,z) = FastNoiseLite.get_noise_2d(x × noise_scale, z × noise_scale) × height_scale — fractal noise as a walkable terrain substrate
# desire: to walk across a landscape that is simultaneously random and smooth — to feel that the ground underfoot is coherent without being designed
# critical_parameter: noise_scale — at low values the terrain is a gentle undulation; at high values it becomes violently jagged; the sweet spot is where walking feels organic
# triggers: changing octaves changes how many scales of detail are superimposed; the organic green material reinforces the disruption aesthetic of non-Euclidean space
# emerges: the TopologySpace base class provides the mesh infrastructure; the noise generates height variation that makes this space feel like resistance — harder to traverse than a flat grid
# needs: no VR controls [missing]; all parameters are export-only; the terrain is generated once at startup and does not update dynamically [has]
# relationships: extends TopologySpace alongside other walkgrid substrates (FractalSpace, ErosionSpace, WaveInterferenceSpace); contrasts with flat SineSpace; used as the noise_space map substrate
# truth: a noise landscape is the simplest possible proof that order and randomness are not opposites — every point in this terrain is deterministically computed yet no two regions feel the same
extends TopologySpace
class_name NoiseSpace

## STAGE-2 DNA PROMOTION (2026-08-05). The artifact is named for its noise and never said
## which noise: `noise_type` was never assigned at all, so the ground has always been
## whatever basis FastNoiseLite happens to default to. The three exports it did carry were
## unreachable from a map — TopologySpace has no apply_grid_config and neither did this —
## so every placement got the identical landscape and map_data could not say otherwise.
## The runner refused it as NO TURNABLE KNOBS on exactly that ground.
##
##   generator  which basis fills the field        simplex · perlin · value · cellular
##   octaves    how many scales are superimposed   1 · 2 · 3 · 4
##
## generator is the SAME axis, with the same four values in the same order and the same
## default, as perlin_noise, simplex_noise, shader_noise_space and noise_terrain. The noise
## sequence is built on comparing bases; if each artifact spells the comparison its own way
## there is nothing to compare. cellular, not worley, for the same reason.
##
## `readout` (relief · plate · column) is DECLINED here, for the reason noise_terrain
## recorded when it declined the same word: readout asks a geometric question about a
## tabletop field, and this is a walkable substrate with a trimesh collider under it, so
## `plate` and `column` would change what the player STANDS ON rather than what the field
## claims to be. noise_terrain's `legend` is declined too, and for the opposite reason —
## there both encodings already existed in the file and only a 2D button chose between
## them; here there is exactly one material, a flat organic green with no height encoding
## at all, so the shipped look is neither contours nor relief nor mood and taking the word
## would mean inventing a fourth value to hold the thing that actually ships.
##
## Usage in map_data.json:
##   "noise_space#generator:cellular"
##   "noise_space#octaves:1"

## DNA axis: which noise basis the height field is sampled from.
@export_enum("simplex", "perlin", "value", "cellular") var generator: String = "simplex"

## DNA axis: how many octaves of fractal detail are summed. The ladder stops at 4 and not
## at simplex_noise's 6 because of this artifact's own mesh: base wavelength is ~2 m
## (frequency 0.1 against coordinates pre-multiplied by noise_scale 5.0), so octave k has
## wavelength 2 / 2^(k-1) — 2.0, 1.0, 0.5, 0.25 m — while the surface is sampled at
## resolution 100 across a 10 m space, i.e. every 0.1 m. Octave 5 lands at 0.125 m, below
## the 0.2 m Nyquist wavelength of the mesh, so 5 and 6 add aliasing at a sixteenth of the
## amplitude and nothing a still frame can distinguish from 4. Four rungs that all resolve
## beat six where two are mush.
@export var octaves: int = 4

@export var noise_scale: float = 5.0

## Not an axis — a REPAIR. persistence has been exported since the file was written and was
## never spent on anything; it is the fBm gain, the amplitude ratio between successive
## octaves. It is wired now, but only away from its own shipped value: at 0.5 the noise
## object is left untouched, so every placement that never named it gets the field it
## always got no matter what FastNoiseLite's own default gain happens to be.
@export var persistence: float = 0.5

const GENERATORS: PackedStringArray = ["simplex", "perlin", "value", "cellular"]

var noise: FastNoiseLite

## True once _ready has built the terrain. apply_grid_config must not regenerate before it.
var _built: bool = false

func _ready():
	_build_noise()
	super._ready()
	_built = true

func _valid(value: String, allowed: PackedStringArray, fallback: String) -> String:
	return value if allowed.has(value) else fallback

## SHORT-CIRCUIT AT THE DEFAULT, deliberately. The shipped file set frequency and octaves
## and never touched noise_type, so `simplex` here means "leave the basis alone" rather
## than "assign TYPE_SIMPLEX". Assigning it would be a silent correction that reshapes the
## ground under every existing placement. The branch therefore asserts NOTHING about which
## enum member the engine defaults to: it assigns nothing, so whatever that default is
## survives. The name is honest because the default is in the simplex family
## (TYPE_SIMPLEX_SMOOTH), which is already what noise_compare_bench.gd labels simplex.
func _build_noise() -> void:
	noise = FastNoiseLite.new()
	noise.frequency = 0.1
	noise.fractal_octaves = octaves
	var chosen: String = _valid(generator, GENERATORS, "simplex")
	if chosen == "perlin":
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
	elif chosen == "value":
		noise.noise_type = FastNoiseLite.TYPE_VALUE
	elif chosen == "cellular":
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	if not is_equal_approx(persistence, 0.5):
		noise.fractal_gain = persistence

func generate_space():
	var heights = []

	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x/2
			var world_z = (z / float(resolution)) * space_size.y - space_size.y/2

			# Fractal noise - spaces of resistance
			var height = noise.get_noise_2d(world_x * noise_scale, world_z * noise_scale)
			heights.append(height * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)

	# Rough material for disruption aesthetic
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 0.4) # Organic green
	material.roughness = 0.9
	material.metallic = 0.1
	mesh_instance.material_override = material


## GUARDED. Config can arrive before _ready (the grid stamps it on the node it is about to
## add) or after. Before the first build, assignment is enough — _ready reads the new values
## on its way through. After it, only a value that actually MOVED may pay for a 10,201-vertex
## regenerate and a fresh trimesh collider. None of the 11 mentions of this token in map_data
## passes any of these keys, so none of them rebuilds anything.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var field_changed: bool = false

	if config.has("generator"):
		var g: String = _valid(str(config["generator"]).strip_edges().to_lower(), GENERATORS, generator)
		if g != generator:
			generator = g
			field_changed = true
	if config.has("octaves"):
		var o: int = clampi(int(config["octaves"]), 1, 12)
		if o != octaves:
			octaves = o
			field_changed = true
	if config.has("noise_scale"):
		var s: float = float(config["noise_scale"])
		if not is_equal_approx(s, noise_scale):
			noise_scale = s
			field_changed = true
	if config.has("persistence"):
		var p: float = float(config["persistence"])
		if not is_equal_approx(p, persistence):
			persistence = p
			field_changed = true

	if not _built:
		return
	if field_changed:
		_build_noise()
		generate_space()
