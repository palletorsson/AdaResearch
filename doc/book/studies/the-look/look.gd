extends Node3D

# The palette: one name for each role. A body asks for a role, not for a colour.
const SKY := Color("ff2e93")      # hot pink: the background
const GROUND := Color("32188a")   # violet: the floor
const BODY := Color("c6ff3d")     # acid lime: the made body
const SECOND := Color("22d9ff")   # cyan: a second body
const THIRD := Color("ff8b1f")    # orange: a third
const BONE := Color("f4efe6")     # off-white: a fourth; the marble
const LINE := Color("ffffff")     # white: traces and segments
const GHOST := Color("9b7bff")    # lavender: what has no collider
const INK := Color("ffffff")      # white: text
const SHADE := Color("0d0620")    # near black: what text stands on

# The filter: colours for the sky and the light, not for bodies.
const SKY_TOP := Color("5a1fd6")        # violet: the top of the sky; SKY is its horizon
const AMBIENT_TINT := Color("e2d9ff")   # faintly lavender: the light from everywhere
const FILL := Color("5fe0ff")           # pale cyan: the second light

func _ready() -> void:
	var sky := Environment.new()
	var gradient := ProceduralSkyMaterial.new()
	gradient.sky_top_color = SKY_TOP
	gradient.sky_horizon_color = SKY
	gradient.sky_curve = 0.25
	gradient.ground_horizon_color = SKY
	gradient.ground_bottom_color = GROUND
	gradient.sun_angle_max = 0.0
	gradient.sun_curve = 0.0
	sky.sky = Sky.new()
	sky.sky.sky_material = gradient
	sky.background_mode = Environment.BG_SKY
	sky.background_color = SKY
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = AMBIENT_TINT
	sky.ambient_light_energy = 0.27
	sky.adjustment_enabled = true
	sky.adjustment_saturation = 1.08
	sky.adjustment_contrast = 1.04

	var world := WorldEnvironment.new()
	world.environment = sky
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.75, -0.75, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 0.28
	sun.shadow_blur = 2.0
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(-0.5, 2.4, 0.0)
	fill.light_color = FILL
	fill.light_energy = 0.05
	add_child(fill)

	var ground_paint := StandardMaterial3D.new()
	ground_paint.albedo_color = GROUND
	ground_paint.roughness = 0.8
	$Floor.material_override = ground_paint

	var body_paint := StandardMaterial3D.new()
	body_paint.albedo_color = BODY
	body_paint.roughness = 0.8
	$Box.material_override = body_paint

	var second_paint := StandardMaterial3D.new()
	second_paint.albedo_color = SECOND
	second_paint.roughness = 0.8
	$Sphere.material_override = second_paint
