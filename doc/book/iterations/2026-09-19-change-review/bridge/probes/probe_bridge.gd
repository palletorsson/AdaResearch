extends SceneTree

const OUT := "res://doc/book/iterations/2026-09-19-change-review/bridge/runtime/"
var checks: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var camera: Camera3D
var world: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks.append({"ok": ok, "message": message})
	print("[bridge] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("26313e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -20, 0)
	world.add_child(light)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.fov = 55
	camera.position = Vector3(-0.35, 1.7, 6.7)
	camera.look_at(Vector3(-0.35, 1.3, 0))
	camera.make_current()
	var old := GDScript.new()
	old.source_code = FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-change-review/bridge/before/algorithms/change/ftc_bridge.gd").replace("class_name FTCBridge", "")
	check(old.reload() == OK, "before-source snapshot compiles")
	var original: Node3D = old.new()
	original.apply_grid_config({"evidence": "longhand"})
	world.add_child(original)
	original.set_process(false)
	original._t = 0.35
	original._update_pulse()
	check(visible_text(original).contains("∫ f' dx = +0.00"), "before: configured longhand prints zero total immediately")
	await capture("before-longhand")
	world.remove_child(original)
	original.queue_free()
	var scene: PackedScene = load("res://algorithms/change/ftc_bridge.tscn")
	var default_bridge: Node3D = scene.instantiate()
	world.add_child(default_bridge)
	check(not default_bridge.has_node("ComparisonConsole") and not default_bridge.has_node("EndpointComparison"), "bare/default result placement has no new control or comparison")
	default_bridge.apply_grid_config({"evidence": "longhand"})
	check(default_bridge.get_node("EndpointComparison").is_visible_in_tree() and not default_bridge.has_node("ComparisonConsole"), "legacy longhand stays visible without opt-in")
	world.remove_child(default_bridge)
	default_bridge.queue_free()
	var bridge: Node3D = scene.instantiate()
	bridge.apply_grid_config({"evidence": "longhand", "reveal_on_request": "true"})
	world.add_child(bridge)
	bridge.set_process(false)
	bridge._t = 0.35
	bridge._update_pulse()
	for i in 10: await process_frame
	var reading: Node3D = bridge.get_node("EndpointComparison")
	check(not reading.is_visible_in_tree(), "opt-in initial comparison is hidden")
	check(not visible_text(bridge).contains("rate sum"), "initial visible labels contain no numeric total")
	check(visible_text(bridge).contains("f'(x)") and visible_text(bridge).contains("∫ f'(x) dx"), "signed rate plot label and theorem title remain visible for observation")
	check(bridge._arch_segments_nodes.size() == 24, "arch retains its 24 deck segments")
	check(rate_strip_count(bridge) == 40, "all 40 signed strips remain visible before reveal")
	await capture("after-predict")
	var button: Node3D = bridge._comparison_button
	check(button.get_node("InteractableAreaButton").has_signal("button_pressed"), "canonical XR/desktop push-button interaction exists")
	button.get_node("InteractableAreaButton").emit_signal("button_pressed", button)
	await process_frame
	check(reading.is_visible_in_tree(), "canonical button event reveals endpoint comparison")
	check(bridge._comparison_status.text == "Press again to hide", "revealed state explains the repeat action")
	check(visible_text(bridge).contains("rate sum ≈ +0.00"), "revealed zero sum is marked as an approximation")
	await capture("after-compared")
	bridge.apply_grid_config({"evidence": "longhand", "reveal_on_request": "true"})
	check(reading.is_visible_in_tree(), "reapplying identical config retains learner reveal state")
	button.get_node("InteractableAreaButton").emit_signal("button_released", button)
	button.get_node("InteractableAreaButton").emit_signal("button_pressed", button)
	await process_frame
	check(not reading.is_visible_in_tree() and not visible_text(bridge).contains("rate sum"), "second button event hides comparison for another prediction")
	for curve in ["wave", "hump", "ramp", "spike", "step"]:
		bridge.apply_grid_config({"curve": curve})
		for i in 5: await process_frame
		var total: float = bridge._integrate_slope()
		var difference: float = bridge._curve_h(1.0) - bridge._curve_h(0.0)
		samples.append({"curve": curve, "trapezoid_sum": total, "endpoint_difference": difference, "error": total - difference})
		check(absf(total - difference) < 0.005, curve + ": finite trapezoid estimate agrees at displayed precision")
		check(not bridge.get_node("EndpointComparison").is_visible_in_tree(), curve + ": changed curve restores prediction stage")
	bridge.apply_grid_config({"reveal_on_request": "false"})
	for i in 5: await process_frame
	check(bridge.get_node("EndpointComparison").is_visible_in_tree() and not bridge.has_node("ComparisonConsole"), "disabling opt-in restores immediate legacy longhand")
	var result := {"checks": checks, "samples": samples, "scope": "Godot 4.6 artifact scene and canonical button event; not a headset, hand reach, or learner test", "camera": {"position": str(camera.position), "fov": camera.fov}}
	var file := FileAccess.open(OUT + "verification.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	var failed := checks.filter(func(row): return not row.ok).size()
	print("[bridge] ", checks.size(), " checks, ", failed, " failures")
	quit(1 if failed else 0)

func visible_text(node: Node) -> String:
	var result := ""
	if node is Label3D and node.is_visible_in_tree(): result += node.text + "\n"
	for child in node.get_children(): result += visible_text(child)
	return result

func rate_strip_count(bridge: Node3D) -> int:
	var result := 0
	for child in bridge.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			if is_equal_approx(child.mesh.size.x, bridge.bridge_span / 40.0 * 0.9) and is_equal_approx(child.mesh.size.z, 0.02): result += 1
	return result

func capture(name: String) -> void:
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "capture " + name)
