extends RefCounted
## The look of MY ROOM: its sky, its ground, its light and its colours. This
## file is yours. Change a colour here and the room changes: SKY is the
## background, GROUND the floor, SHADE the squares of the places, INK the
## numbers. room.gd asks this file for all of them.
## It starts as a copy of supplied/look.gd, the look every kit has. The parts in
## supplied/ (the walker, the marble) keep that look, and a guest brings its own
## colours with it: this file is the room's, not theirs.
##   paint(color)      a material in that colour, matt
##   ghost()           GHOST, half seen through
##   environment()     the sky: SKY as background, a white ambient light
##   sun()             a new DirectionalLight3D with shadows
##   label(text)       a new Label3D: INK letters with a SHADE edge
## If you change the light: in this renderer a sun that casts shadows lights a
## face about three times as brightly as its energy says, which is why
## SUN_ENERGY is 0.28 and not 1. A brighter sun turns the colours to white.

const SKY := Color("ff2e93")      # hot pink: the background
const GROUND := Color("32188a")   # violet: the floor
const BODY := Color("c6ff3d")     # acid lime: the made body
const SECOND := Color("22d9ff")   # cyan: a second body; the walker
const THIRD := Color("ff8b1f")    # orange: a third
const BONE := Color("f4efe6")     # off-white: the marble, a fourth
const LINE := Color("ffffff")     # white: traces and segments
const GHOST := Color("9b7bff")    # lavender: anything translucent or without a collider
const INK := Color("ffffff")      # white: text
const SHADE := Color("0d0620")    # near black: what text stands on

const BODIES: Array[Color] = [BODY, SECOND, THIRD, BONE]

# The light, measured in the Compatibility renderer of Godot 4.6: with these
# three numbers a face turned up to the sun shows the colour it was given.
# The energy is low on purpose. There a sun that casts shadows lit a face
# about three times as brightly as its energy says, and the same sun with its
# shadows off less than half as brightly as that: leave shadow_enabled on.
const SUN_TURN := Vector3(-0.75, -0.75, 0.0)   # radians: the sun stands 43 degrees up, to the left, behind the fixed camera
const SUN_ENERGY := 0.28
const AMBIENT_ENERGY := 0.25                   # the light that reaches a face the sun does not

# The filter: what a RUNNING scene adds to the plain look. Measured by eye on ten
# variants in the Compatibility renderer: a gradient sky helped most; fog and
# glow washed the bodies out and are left off; the filmic and AgX tonemaps moved
# lime toward yellow and are not used.
const SKY_TOP := Color("5a1fd6")          # violet: the top of the sky; SKY is its horizon
const AMBIENT_TINT := Color("e2d9ff")     # the ambient light of a running scene, faintly lavender
const SHOW_AMBIENT_ENERGY := 0.27
const FILL := Color("5fe0ff")             # the fill light's colour
const FILL_ENERGY := 0.05
const FILL_TURN := Vector3(-0.5, 2.4, 0.0)
const SHADOW_BLUR := 2.0                  # a softer shadow edge
const SATURATION := 1.08
const CONTRAST := 1.04

static func paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.metallic = 0.0
	return material

static func ghost() -> StandardMaterial3D:
	var material := paint(Color(GHOST, 0.45))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

static func environment() -> Environment:
	var sky := studio_environment()
	var gradient := ProceduralSkyMaterial.new()
	gradient.sky_top_color = SKY_TOP
	gradient.sky_horizon_color = SKY
	gradient.sky_curve = 0.25
	gradient.ground_horizon_color = SKY
	gradient.ground_bottom_color = GROUND
	gradient.ground_curve = 0.02
	gradient.sun_angle_max = 0.0
	gradient.sun_curve = 0.0
	sky.sky = Sky.new()
	sky.sky.sky_material = gradient
	sky.background_mode = Environment.BG_SKY
	sky.ambient_light_color = AMBIENT_TINT
	sky.ambient_light_energy = SHOW_AMBIENT_ENERGY
	sky.adjustment_enabled = true
	sky.adjustment_saturation = SATURATION
	sky.adjustment_contrast = CONTRAST
	return sky

## The plain sky of the sheet's studio: SKY flat, a white ambient light, nothing
## else. A still made here measures the body and not the filter.
static func studio_environment() -> Environment:
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = SKY
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color.WHITE
	sky.ambient_light_energy = AMBIENT_ENERGY
	sky.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	return sky

static func sun() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation = SUN_TURN
	light.light_energy = SUN_ENERGY
	light.shadow_enabled = true
	return light

## A second, weak light from the other side, with no shadow: it puts a little
## cyan into the faces the sun does not reach.
static func fill() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation = FILL_TURN
	light.light_color = FILL
	light.light_energy = FILL_ENERGY
	light.shadow_enabled = false
	return light

static func label(text: String) -> Label3D:
	var words := Label3D.new()
	words.text = text
	words.pixel_size = 0.004
	words.font_size = 48
	words.modulate = INK
	words.outline_modulate = SHADE
	words.outline_size = 12
	return words
