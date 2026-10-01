extends Node3D

func _ready() -> void:
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("ff2e93")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color.WHITE
	sky.ambient_light_energy = 0.25

	var world := WorldEnvironment.new()
	world.environment = sky
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.75, -0.75, 0.0)
	sun.shadow_enabled = true
	add_child(sun)

	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color("32188a")
	ground.roughness = 0.8
	$Floor.material_override = ground

	var lime := StandardMaterial3D.new()
	lime.albedo_color = Color("c6ff3d")
	lime.roughness = 0.8
	$Box.material_override = lime

	var cyan := StandardMaterial3D.new()
	cyan.albedo_color = Color("22d9ff")
	cyan.roughness = 0.8
	$Sphere.material_override = cyan
