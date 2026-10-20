extends Node3D
var checks: Array = []
var observations: Dictionary = {}
var hall := ""
var variant := ""
var run_id := ""
var out_dir := ""
var study
var failed := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		match args[i]:
			"--hall": hall = args[i+1]
			"--variant": variant = args[i+1]
			"--run-id": run_id = args[i+1]
	out_dir = "res://%s/%s/runs/%s" % [hall, variant, run_id]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(3.5, 4.4, 6.6)
	camera.look_at(Vector3(0, 1.25, 0.4))
	if hall == "CA_Introduction":
		camera.position = Vector3(1.3, 2.2, 2.8)
		camera.look_at(Vector3(0, 1.08, 0))
	elif hall == "CA_ElementaryRules":
		camera.position = Vector3(1.6, 2.4, 3.4)
		camera.look_at(Vector3(0, 1.3, 0))
	elif hall == "CA_GameOfLife":
		camera.position = Vector3(-2, 2.9, 4)
		camera.look_at(Vector3(0.1, 1.25, 0.9))
	elif hall == "CA_ExpandingSpace":
		camera.position = Vector3(-1.7, 2.8, 3.1)
		camera.look_at(Vector3(0, 1.15, 0.8))
	camera.current = true
	camera.fov = 43
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.2
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("263440")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var hosts := {"CA_Introduction":"row.gd", "CA_ElementaryRules":"volume.gd", "CA_GameOfLife":"history.gd", "CA_BeyondBinary":"life.gd", "CA_ExpandingSpace":"presence.gd", "CA_SoftRules":"exchange.gd", "CA_AgentsCircuits":"comparison.gd", "CA_EdgeOfChaos":"difference.gd"}
	var script = load("res://%s/%s/%s" % [hall, variant, hosts[hall]])
	check(script != null and script.can_instantiate(), "printed_host_loads")
	if failed: return
	study = script.new()
	study.name = "PointStudy"
	add_child(study)
	await settle()
	check(study.point != null, "printed_point_constructed")
	check(study.point is XRToolsPickable, "real_declared_xrtools_pickable")
	check(study.point.get_child_count() >= 2, "point_mesh_and_collision")
	var spec = load("res://tests/%s.gd" % hall).new()
	await spec.run(study, self, variant == "variation")
	await settle()
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	check(shot.get_width() == 1280 and shot.get_height() == 960, "rendered_viewport_dimensions")
	var save_error := shot.save_png(out_dir + "/screenshot.png")
	check(save_error == OK, "screenshot_saved")
	finish()
	get_tree().quit(1 if failed else 0)

func settle() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame

func check(condition: bool, label: String) -> void:
	checks.append({"name":label,"passed":condition})
	print("CHECK ", label, " ", "PASS" if condition else "FAIL")
	if not condition:
		failed = true
		push_error("STUDENT ASSERTION: " + label)
		finish()
		get_tree().quit(1)
	assert(condition, label)

func near(actual: float, expected: float, label: String, tolerance: float = 0.00001) -> void:
	check(absf(actual - expected) <= tolerance, label + " got=" + str(actual) + " expected=" + str(expected))

func active(row: Array) -> Array:
	var result: Array = []
	for i in row.size():
		if row[i]: result.append(i)
	return result

func observe(label: String, value) -> void:
	observations[label] = value

func finish() -> void:
	var file := FileAccess.open(out_dir + "/checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"hall":hall,"variant":variant,"checks":checks,"observations":observations,"passed":not failed}, "  "))
