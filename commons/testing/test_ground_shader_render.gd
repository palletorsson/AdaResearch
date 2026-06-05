extends SceneTree
## Real GPU render of the BiomeGroundSubstrate with the new biome_ground.gdshader
## (height bands + paint_tex overlay). Confirms the shader COMPILES on geometry and
## the shader-paint + plant-bleed overlay shows. Saves to user:// (NOT the repo).
## Run (needs GPU — use --no-window, NOT --headless):
##   godot --no-window --xr-mode off --path . --script res://commons/testing/test_ground_shader_render.gd

const Sub = preload("res://commons/biome_layers/biome_ground_substrate.gd")

func _initialize() -> void:
	call_deferred("_run")

func _disc(gw: int, gd: int, cx: int, cz: int, rad: int) -> Array:
	var rows: Array = []
	for z in gd:
		var row: Array = []
		for x in gw:
			var d := sqrt(float((x - cx) * (x - cx) + (z - cz) * (z - cz)))
			row.append(1.0 if d <= float(rad) else 0.0)
		rows.append(row)
	return rows

func _run() -> void:
	var gw := 16
	var gd := 16
	var root := get_root()
	root.world_3d = World3D.new()

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.11, 0.14)
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	e.ambient_light_energy = 1.0
	env.environment = e
	root.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -40, 0)
	root.add_child(light)

	# A gentle height field so the bands show too.
	var field := PackedFloat32Array()
	field.resize(gw * gd)
	for z in gd:
		for x in gw:
			field[z * gw + x] = 0.5 + 0.5 * sin(float(x) * 0.6) * cos(float(z) * 0.6)

	var sub = Sub.new()
	sub.configure(gw, gd, 1.0, Vector3(8, 1.0, 8))   # center.y 1.0 → ground at y≈0
	sub.set_field(field, gw, gd, 1.2)
	sub.set_paint_layers([
		{"element": "shader", "mode": "brush", "color": [0.15, 0.65, 0.85],
		 "brush": _disc(gw, gd, 4, 11, 3)},                                   # cyan disc
		{"element": "flower", "mode": "noise", "density": 0.7, "scale": 0.35, "threshold": 0.45},
	], 7)
	root.add_child(sub)

	var cam := Camera3D.new()
	root.add_child(cam)
	# look_at needs the node in-tree; look_at_from_position avoids the ordering trap.
	cam.look_at_from_position(Vector3(8, 17, 17), Vector3(8, 0.5, 8), Vector3.UP)
	cam.make_current()

	# Let the shader compile + a few frames render.
	for i in 6:
		await process_frame
	await create_timer(0.3).timeout

	var img := root.get_texture().get_image()
	img.save_png("user://ground_shader_render.png")
	print("RENDER SAVED ", ProjectSettings.globalize_path("user://ground_shader_render.png"))
	quit(0)
