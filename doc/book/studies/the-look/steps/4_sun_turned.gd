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
