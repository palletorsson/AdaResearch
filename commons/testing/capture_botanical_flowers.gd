# capture_botanical_flowers.gd
# Quick capture script for testing BotanicalFlower class.
# Spawns one of each preset species in a row and takes a screenshot.
#
# Usage:
#   godot_console --path . --xr-mode off --script res://commons/testing/capture_botanical_flowers.gd

extends SceneTree

var FlowerScript = load("res://commons/flora/botanical_flower.gd")
var _frame_count := 0


func _init() -> void:
	# Create root scene
	var root := Node3D.new()
	root.name = "BotanicalFlowerTest"
	get_root().add_child(root)

	# Camera — looking at the flower row from front
	var cam := Camera3D.new()
	cam.name = "TestCamera"
	cam.position = Vector3(0, 1.2, 3.0)
	cam.rotation_degrees = Vector3(-20, 0, 0)
	cam.fov = 75
	root.add_child(cam)

	# Lighting
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.light_energy = 1.2
	root.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_color = Color(0.7, 0.75, 0.9)
	fill.light_energy = 0.3
	root.add_child(fill)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.18, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.42, 0.45)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)

	# Ground plane
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(10, 4)
	ground.mesh = plane_mesh
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.15, 0.25, 0.1)
	ground.material_override = ground_mat
	root.add_child(ground)

	# Test MultiMesh garden (batched) — bluebell flock
	var garden1: Node3D = FlowerScript.create_garden(15, 1.5, 42, "bluebell")
	garden1.name = "BluebellGarden"
	garden1.position = Vector3(-2.0, 0, -0.5)
	root.add_child(garden1)

	# Mixed species garden
	var garden2: Node3D = FlowerScript.create_garden(12, 1.2, 99, "")
	garden2.name = "MixedGarden"
	garden2.position = Vector3(1.5, 0, -0.5)
	root.add_child(garden2)

	# Single preset flowers in a row for comparison
	var presets: Array = FlowerScript.PRESETS.keys()
	var spacing := 0.4
	var start_x := -float(presets.size() - 1) * spacing * 0.5

	for i in presets.size():
		var preset_name: String = presets[i]
		var flower: Node3D = FlowerScript.new()
		flower.name = "Test_%s" % preset_name
		flower.preset = preset_name
		flower.config["overall_scale"] = 1.5
		flower.config["seed"] = i * 42

		flower.position = Vector3(start_x + i * spacing, 0, 0.8)
		root.add_child(flower)

		var label := Label3D.new()
		label.text = preset_name
		label.font_size = 18
		label.pixel_size = 0.001
		label.position = Vector3(start_x + i * spacing, -0.05, 0.95)
		label.modulate = Color(0.8, 0.85, 0.9, 0.8)
		root.add_child(label)

	print("BotanicalFlower test: %d presets + 2 MultiMesh gardens" % presets.size())


func _process(delta: float) -> bool:
	_frame_count += 1
	if _frame_count == 5:
		_take_screenshot()
		return true  # quit
	return false


func _take_screenshot() -> void:
	var viewport := get_root().get_viewport()
	var img := viewport.get_texture().get_image()
	var out_path := "user://botanical_flower_test.png"
	img.save_png(out_path)
	var abs_path := ProjectSettings.globalize_path(out_path)
	print("Screenshot saved: %s" % abs_path)
