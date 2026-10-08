extends SceneTree
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print(("PASS " if ok else "FAIL ") + message)

func move_pen(pen: Node3D, at: Vector3) -> void:
	pen.get_node("GrabPoint").global_position = at
	pen.call("_process", 0.2)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://ada_run/trace_data_panel")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var pen: Node3D = load("res://commons/primitives/point/draw_dot.tscn").instantiate()
	pen.position = Vector3(-0.45, 1.25, 0)
	pen.call("apply_grid_config", {"ink":"cyan", "resolution":"10"})
	world.add_child(pen)
	pen.set_process(false)
	pen.set("record_only_when_grabbed", false)
	pen.set("data_table_update_interval", 0.0)
	var panel: Node3D = pen.get("_data_panel")
	var count: Label = pen.get("_data_count_label")
	var table: Label = pen.get("_data_table_label")
	check(not panel.visible, "empty trace has no obsolete panel")
	for i in range(1, 19):
		move_pen(pen, Vector3(-0.45 + i * 0.055, 1.25 + sin(i * 0.35) * 0.1, 0))
	var points: Array = pen.get("_trail_points")
	check(points.size() == 18 and count.text == "18 POINTS", "large count equals actual line vertices")
	check(table.text.contains("Retained: 18 / 4096"), "capacity remains explicit")
	check(table.text.contains(" 9:") and table.text.contains("18:") and not table.text.contains(" 1:"), "last ten rows retain their current-line indices")
	check(table.text.contains("WORLD POSITIONS (m)") and table.text.contains("Grid: 10"), "coordinate frame, units and grid remain explicit")
	check(table.get_parent() == panel.get("viewport") and count.get_parent() == panel.get("viewport") and panel.has_node("PanelSurface"), "count and coordinates share one backed plane")
	check(panel.global_basis.z.y > 0.5 and panel.global_basis.z.z > 0.7, "panel tilted upward 35 degrees, not horizontal or billboarded")
	var pose := panel.global_transform
	pen.call("_on_grab_point_dropped", pen.get_node("GrabPoint"))
	check(panel.visible and panel.global_transform.is_equal_approx(pose), "released trace keeps its readable panel in place")
	await process_frame
	await process_frame
	var surface: MeshInstance3D = panel.get_node("PanelSurface")
	var backing := surface.get_aabb()
	check(table.position.y + table.get_minimum_size().y <= panel.get("viewport").size.y-25,
		"last coordinate row fits on the fixed backing")
	check(table.position.x + table.get_minimum_size().x <= panel.get("viewport").size.x-25,
		"coordinate columns fit on the fixed backing")
	var casing: Node3D = panel.get_node("Casing")
	var shell: MeshInstance3D = casing.get_node("Shell")
	check(shell.get_aabb().size.z > 0.06, "casing has physical depth")
	check(shell.get_aabb().size.x > backing.size.x and shell.get_aabb().size.y > backing.size.y,
		"casing surrounds the complete fitted readout")
	check((casing.get_node("InkInlay").material_override as StandardMaterial3D).albedo_color.is_equal_approx(pen.get("trail_color")),
		"casing inlay identifies the pen's ink")
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(0.28, 1.8, 1.65)
		camera.look_at(Vector3(0.18, 1.04, 0.12))
		camera.current = true
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.14, 0.16, 0.20)
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.8
		world.add_child(environment)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/trace_data_panel/preview.png")
	pen.set("trail_max_points", 18)
	move_pen(pen, Vector3(0.7, 1.25, 0))
	check(count.text == "18 POINTS" and (pen.get("_trail_points") as Array).size() == 18, "count follows capacity eviction")
	check(panel.global_transform.is_equal_approx(pose), "evicting the oldest vertex does not move the panel")
	pen.call("clear_trail")
	check(not panel.visible and not table.visible, "clear hides the whole display")
	pen.rotation_degrees.y = 270
	move_pen(pen, Vector3(2,1.25,2))
	check(count.text == "1 POINT" and panel.visible, "new trace resets count and panel")
	check(panel.global_basis.z.x < -0.7 and panel.global_basis.z.y > 0.5, "rotated pen gets corresponding tilted panel orientation")
	check(not panel.global_transform.is_equal_approx(pose), "new trace establishes a new anchor")
	# Large world offsets must not grow the case or silently lose precision.
	var fixed_size: Vector2 = panel.get("screen").mesh.size
	pen.call("clear_trail")
	for i in 14: move_pen(pen, Vector3(-12345.678+i*.025, 1.234, 9876.543+i*.02))
	await process_frame
	await process_frame
	check(panel.get("screen").mesh.size == fixed_size, "large signed coordinates do not enlarge the instrument")
	check(table.text.contains("-12345.") and table.get_minimum_size().x <= panel.get("viewport").size.x-64, "large coordinates remain complete and fit")
	# The inherited clock recorder adds a row and must keep its distinct gate.
	var timed: Node3D = load("res://commons/primitives/point/draw_dot_time_domain.tscn").instantiate()
	world.add_child(timed)
	timed.set_process(false)
	timed.set("record_only_when_grabbed",false)
	timed.set("data_table_update_interval",0.0)
	for i in 14: timed.call("_process",.05)
	await process_frame
	await process_frame
	var timed_label: Label = timed.get("_data_table_label")
	var timed_panel: Node3D = timed.get("_data_panel")
	check(timed_label.text.contains("Sample gate:") and timed_label.text.contains("Z drift:"), "time recorder preserves its own sampling contract")
	check(timed_label.get_minimum_size().y <= timed_panel.get("viewport").size.y-140, "clock recorder's additional row fits the fixed surface")
	var report := {"checks":checks,"failures":failures,"scope":"Real recorder with supplied positions; screenshot is one trace, not a headset reading test."}
	var f := FileAccess.open("res://ada_run/trace_data_panel/checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
