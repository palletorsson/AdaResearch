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

func _ready() -> void:
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = SKY
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color.WHITE
	sky.ambient_light_energy = 0.25

	var world := WorldEnvironment.new()
	world.environment = sky
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.75, -0.75, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 0.28
	add_child(sun)

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
