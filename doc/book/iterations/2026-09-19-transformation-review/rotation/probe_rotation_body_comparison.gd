extends SceneTree
var failures: Array[String] = []
var checks := 0
var first_results: Dictionary = {}
const OUT := "res://doc/book/iterations/2026-09-19-transformation-review/rotation"
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[rotation-bodies] ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world);current_scene = world
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.map_name = "Trans_Rotation"
	grid.bare_world = true
	grid.skip_player_spawn = true
	grid.position.y = -0.5
	var built := [false]
	grid.build_finished.connect(func(): built[0] = true, CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(2400):
		if built[0]: break
		await process_frame
	check(built[0], "actual Trans_Rotation source grid builds")
	var arrays: Node3D
	for n in grid.find_children("*", "Node3D", true, false):
		if n.get_script() == load("res://commons/artifacts/rotation_studies/array_compare.gd"): arrays = n
	check(arrays != null, "existing primary array instantiated")
	if arrays == null: quit(1);return
	var study: Node3D = arrays.body_comparison
	check(study != null, "body comparison built on existing array")
	if study == null: quit(1);return
	var player := CharacterBody3D.new()
	player.name = "DesktopPlayerSentinel"
	var player_shape := CollisionShape3D.new()
	var player_capsule := CapsuleShape3D.new()
	player_capsule.radius = 0.3; player_capsule.height = 1.6
	player_shape.shape = player_capsule; player_shape.position.y = 0.8
	player.add_child(player_shape)
	world.add_child(player)
	player.position = Vector3(7.5, 0, 24.0)
	study.auto_repeat = false
	study.restart()
	for i in range(3600):
		await physics_frame
		if study.phase == "complete": break
	check(study.results.size() == 2, "both real physics passes completed")
	first_results = study.results.duplicate(true)
	check(study.walkers.size() == 4, "at most four active witnesses, one per band")
	for trial: Dictionary in study.walkers:
		check(trial.body.collision_layer == 0 and trial.body.collision_mask == 1, str(trial.band.id) + " ghost layer, world collision mask")
		check(player in trial.body.get_collision_exceptions(), str(trial.band.id) + " ignores desktop player on world layer")
	for width_id: String in study.results:
		var rows: Array = study.results[width_id]
		check(rows.size() == 4, width_id + " records all four bands")
		for result: Dictionary in rows:
			check(result.height_m == 1.6 and result.speed_m_s == 2.0 and result.forward_input, width_id + " " + result.band + " movement constants identical")
			check(result.travel_m > 1.0, width_id + " " + result.band + " reaches the array rather than blocking on the stand")
	# Control: zero rotation must allow both widths along this same first column.
	arrays.row_angle_step = 0.0
	arrays.apply_gradient()
	study.restart()
	for i in range(3600):
		await physics_frame
		if study.phase == "complete": break
	var control: Dictionary = study.results.duplicate(true)
	for width_id: String in control:
		for result: Dictionary in control[width_id]:
			check(result.reason == "ARRIVED", "flat control " + width_id + " " + result.band + " arrives")
	# Replay is the real installed button, not a special test API.
	var button: Node = study.get_node("ComparisonPanel/Replay")
	button.pressed.emit()
	await physics_frame
	await physics_frame
	check(study.results.is_empty() and study.pass_index == -1, "physical REPLAY clears measurements and schedules fresh narrow pass")
	var report := {"checks":checks, "failures":failures, "gradient":first_results, "flat_control":control,
		"rules":{"radii_m":[0.22,0.6],"height_m":1.6,"speed_m_s":2.0,"gravity_m_s2":9.8,"slope_limit_degrees":45,"floor_snap_m":0.15},
		"limits":["Source grid collision, not player headset traversal", "Constant forward input permits collision sliding", "First stopping positions depend on shape and movement settings; no general route impossibility claim"]}
	FileAccess.open(OUT + "/rotation-body-comparison-checks.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("[rotation-bodies] RESULTS ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
