extends SceneTree
var study: Node3D
var checks: Array = []
var views: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print("PASS " if passed else "FAIL ", label)

func capture(name: String) -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://captures/" + name + ".png")
	views.append({"file": name + ".png", "mask": study.mask, "lights": study.active_names(), "pink_material": study.pink_material})
	return image

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	root.content_scale_size = Vector2i(900, 900)
	root.size = Vector2i(900, 900)
	study = load("res://study.tscn").instantiate()
	root.add_child(study)
	await process_frame
	study.panel.visible = false
	var mesh_id: int = study.sphere.mesh.get_instance_id()
	var base_transform: Transform3D = study.sphere.transform
	var camera_transform: Transform3D = study.camera.transform
	var unique := {}
	var one_change := true
	for i in 32:
		unique[study.states[i]] = true
		var change: int = study.states[i] ^ study.states[(i + 1) % 32]
		one_change = one_change and change > 0 and (change & (change - 1)) == 0
	check("32 distinct on/off combinations", unique.size() == 32)
	check("one switch changes between successive states, including wrap", one_change)
	var fixed := true
	var rendered_distinct := {}
	var square_frames := true
	var first_tile: Image
	var sheet := Image.create(8 * 310 + 10, 4 * 310 + 10, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.94, 0.90, 0.91))
	for i in 32:
		study.set_lights(study.states[i])
		var state_image := await capture("state-%02d" % i)
		square_frames = square_frames and state_image.get_size() == Vector2i(900, 900)
		rendered_distinct[state_image.get_data().hex_encode().sha256_text()] = true
		fixed = fixed and study.sphere.mesh.get_instance_id() == mesh_id and study.sphere.transform == base_transform
		fixed = fixed and study.camera.transform == camera_transform and study.sphere_material.albedo_color == study.PALE
		for lamp in study.lights:
			fixed = fixed and lamp.light_color == study.PINK and is_equal_approx(lamp.light_energy, study.LAMP_ENERGY)
		state_image.resize(300, 300, Image.INTERPOLATE_LANCZOS)
		state_image.convert(Image.FORMAT_RGB8)
		if i == 0:
			first_tile = state_image.duplicate()
		sheet.blit_rect(state_image, Rect2i(0, 0, 300, 300), Vector2i(10 + (i % 8) * 310, 10 + (i / 8) * 310))
	sheet.save_png("res://captures/pink-light-sheet.png")
	check("square frames preserve sphere proportions in the comparison sheet", square_frames)
	check("sheet contains the captured first tile", sheet.get_region(Rect2i(10, 10, 300, 300)).get_data() == first_tile.get_data())
	check("sphere, material, view and individual light energies fixed throughout", fixed)
	check("every on/off setting changes the rendered image", rendered_distinct.size() == 32)
	study.set_lights(3)
	await capture("pink-light")
	study.set_pink_material(true)
	check("comparison exchanges light/material while preserving lamp selection", study.mask == 3 and study.sphere_material.albedo_color == study.PINK and study.lights[0].light_color == Color.WHITE)
	await capture("pink-material")
	study.set_pink_material(false)
	check("comparison restores pale material and pink lamps", study.sphere_material.albedo_color == study.PALE and study.lights[0].light_color == study.PINK)
	study.set_lights(1)
	await capture("hero")
	study.set_lights(31)
	await capture("all-lights")
	study.panel.visible = true
	root.content_scale_size = Vector2i(1200, 1000)
	root.size = Vector2i(1200, 1000)
	await capture("controls")
	var passed := true
	for result in checks:
		passed = passed and result.passed
	var report := {"passed": passed, "checks": checks, "views": views, "scope": "Native standalone study; image differences are not a perceptual threshold or learner trial.", "engine": Engine.get_version_info()}
	FileAccess.open("res://captures/report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0 if passed else 1)
