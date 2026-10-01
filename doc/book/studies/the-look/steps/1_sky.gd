extends Node3D

func _ready() -> void:
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("ff2e93")

	var world := WorldEnvironment.new()
	world.environment = sky
	add_child(world)
