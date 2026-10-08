extends Node3D
## Desktop study controls, kept separate from the transferable CSG component.
var work: Node3D
var camera: Camera3D
var overlay: CanvasLayer

func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#dad7d3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#dcd9e6")
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-28,0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)
	work = load("res://commons/artifacts/conical_sightline/conical_sightline.tscn").instantiate()
	add_child(work)
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 62
	set_view(0)
	camera.make_current()
	overlay = CanvasLayer.new()
	add_child(overlay)
	var panel := HBoxContainer.new()
	panel.position = Vector2(24,24)
	panel.add_theme_constant_override("separation",12)
	overlay.add_child(panel)
	for choice in ["Approach", "Inside", "Offcuts", "Before / cut", "Shift cut", "Reset"]:
		var button := Button.new()
		button.text = choice
		button.custom_minimum_size = Vector2(125,44)
		button.pressed.connect(_choose.bind(choice))
		panel.add_child(button)

func _choose(choice: String) -> void:
	match choice:
		"Approach": set_view(0)
		"Inside": set_view(1)
		"Offcuts": set_view(2)
		"Before / cut": work.set_cut_enabled(not work.cut_enabled)
		"Shift cut": work.set_cut_x(0.75 if is_zero_approx(work.cut_x) else 0.0)
		"Reset":
			work.set_cut_enabled(true)
			work.set_cut_x(0)
			set_view(0)

func set_view(index: int) -> void:
	var views := [
		[Vector3(6.8,3.8,11.8),Vector3(0,2.2,-0.8)],
		[Vector3(0.0,1.7,2.5),Vector3(0,2.6,-3.4)],
		[Vector3(17,5,12),Vector3(8.4,2,0)]
	]
	camera.position = views[index][0]
	camera.look_at(views[index][1])
