extends Node3D
## Standalone desktop preview for the Boolean egg component.

const EGGS := preload("res://commons/artifacts/kapoor_void_studies/boolean_eggs.tscn")

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#10111b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#aaa3c8")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var eggs := EGGS.instantiate()
	add_child(eggs)

	var key := DirectionalLight3D.new()
	key.name = "Soft museum key"
	key.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key.light_color = Color("#d9d1ff")
	key.light_energy = 1.45
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "Teal fill"
	fill.position = Vector3(3.4, 2.8, 2.1)
	fill.light_color = Color("#72b8bd")
	fill.light_energy = 0.62
	fill.omni_range = 8.0
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.name = "Violet rim"
	rim.position = Vector3(-3.2, 3.0, -1.8)
	rim.light_color = Color("#a66bdb")
	rim.light_energy = 0.8
	rim.omni_range = 7.0
	add_child(rim)

	var camera := Camera3D.new()
	camera.name = "BooleanEggsPreviewCamera"
	camera.position = Vector3(0.0, 3.25, 11.8)
	camera.fov = 42.0
	camera.near = 0.05
	camera.far = 80.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.35, 0.0), Vector3.UP)
	camera.make_current()
