## Quick capture: filter_screen + line_demo — 3/4 view showing both
extends SceneTree

func _init():
	var filter_scn = load("res://commons/artifacts/filter_screen/filter_screen.tscn")
	var line_scn = load("res://commons/primitives/snappoint/demos/line_demo.tscn")

	# Place filter screen at origin
	var filter = filter_scn.instantiate()
	root.add_child(filter)

	# Place line demo 2m in front of screen
	var line = line_scn.instantiate()
	line.position = Vector3(0, 0, 2.0)
	root.add_child(line)

	# Floor
	var floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mesh.mesh = plane
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.1, 0.1, 0.13)
	floor_mesh.material_override = floor_mat
	root.add_child(floor_mesh)

	# Lighting
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 45, 0)
	light.light_energy = 1.5
	root.add_child(light)

	# Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.06, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.8

	# Camera: 3/4 view, see screen face AND line demo behind it
	var cam = Camera3D.new()
	cam.fov = 55
	cam.global_position = Vector3(2.0, 1.4, -0.5)
	cam.look_at(Vector3(0, 0.8, 1.0), Vector3.UP)
	cam.environment = env
	root.add_child(cam)
	cam.make_current()

	# Wait for rendering
	for i in 15:
		await process_frame

	var img = root.get_viewport().get_texture().get_image()
	img.save_png("user://filter_with_line_3q.png")
	print("3/4 view: " + ProjectSettings.globalize_path("user://filter_with_line_3q.png"))

	# Shot 2: close-up of filter screen face
	cam.global_position = Vector3(0.3, 0.9, -1.0)
	cam.look_at(Vector3(0, 0.8, 0), Vector3.UP)
	for i in 5:
		await process_frame
	var img2 = root.get_viewport().get_texture().get_image()
	img2.save_png("user://filter_screen_closeup.png")
	print("Closeup: " + ProjectSettings.globalize_path("user://filter_screen_closeup.png"))

	quit(0)
