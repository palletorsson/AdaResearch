extends SceneTree

const OUT := "res://doc/book/iterations/2026-09-19-formfinding-review/diagram/"
var checks: Array = []

func check(ok: bool, message: String) -> void:
	checks.append({"ok": ok, "message": message})

func _initialize() -> void:
	run.call_deferred()

func shapes(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is MeshInstance3D:
			found.append([child.position, child.rotation, child.mesh.get_aabb()])
		found.append_array(shapes(child))
	return found

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1400, 950)
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("17202b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.85
	world.environment = env
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -30, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 0.06, 1.45)
	camera.look_at(Vector3(0, 0.06, 0))
	camera.fov = 42
	camera.make_current()
	var previous_script := GDScript.new()
	previous_script.source_code = FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-formfinding-review/before/algorithms/formfinding/settling_tremble/settling_tremble.gd").replace("class_name SettlingTremble", "")
	check(previous_script.reload() == OK, "saved prior diagram compiles")
	var before: Node3D = previous_script.new()
	var after: Node3D = load("res://algorithms/formfinding/settling_tremble/settling_tremble.gd").new()
	stage.add_child(before)
	stage.add_child(after)
	check(shapes(before) == shapes(after), "every rendered mesh transform and bound retained")
	var texts: Array = []
	for label in after.find_children("*", "Label3D", true, false): texts.append(label.text)
	check(texts.any(func(t): return t.contains("not solver output")), "offset construction explicit")
	check(texts.any(func(t): return t.contains("no motion")), "static nature explicit")
	check(texts.any(func(t): return t.contains("remainder")), "critical question preserved")
	for version in ["before", "after"]:
		before.visible = version == "before"
		after.visible = version == "after"
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT + version + ".png") == OK, "saved " + version)
	var failures := checks.filter(func(c): return not c.ok)
	var file := FileAccess.open(OUT + "check.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "scope": "Same-camera isolated actual artifact, saved original versus current source. No museum or headset run.", "headset_tested": false, "texts": texts}, "  "))
	file.close()
	print("DIAGRAM ", checks.size(), " checks; failures ", failures.size())
	stage.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
