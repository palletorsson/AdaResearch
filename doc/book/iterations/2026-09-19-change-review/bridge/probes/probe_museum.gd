extends "res://doc/book/iterations/2026-09-19-change-review/intro/probes/base.gd"

func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := OUT + "museum-control.json"
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", ctl + ".unused-hand")
	em.set("start_chapter", "change")
	em.set("start_map", "Change_Intro")
	var control := FileAccess.open(ctl, FileAccess.WRITE)
	control.store_string(JSON.stringify({"first_chapter": "change", "dollhouse": 0, "grid_pack": 1}))
	control.close()
	root.add_child(em)
	current_scene = em
	await create_timer(1).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	var segment: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == "Change_Intro": segment = rec.node
	check(segment != null, "actual Change_Intro museum segment loads")
	if segment == null: finish(); return
	for i in 30: await process_frame
	var player: CharacterBody3D = em.get("_player")
	player.set_physics_process(false)
	em.get("_feel").set_process(false)
	var wardrobe = em.get("_wardrobe")
	wardrobe.appearance_save_path = ""
	wardrobe.costume.visible = false
	var bridge: Node3D
	for node in segment.find_children("*", "Node3D", true, false):
		if node.get_meta("artifact_lookup_name", "") == "ftc_bridge":
			bridge = node
			break
	check(bridge != null, "authored FTC bridge exists in actual museum")
	if bridge == null: finish(); return
	for rec in em.get("_vis_records"):
		var node = rec.get("node")
		if node is Node3D and is_instance_valid(node) and segment.is_ancestor_of(node): node.visible = true
	check(bridge.reveal_on_request and bridge.evidence == "longhand", "actual map applies delayed longhand configuration")
	var comparison: Node3D = bridge.get_node("EndpointComparison")
	check(not comparison.is_visible_in_tree(), "museum entry hides numeric endpoint comparison")
	check(not visible_text(bridge).contains("rate sum"), "museum entry has no visible numeric total")
	check(visible_text(bridge).contains("∫ f'(x) dx"), "theorem remains visible as bridge identity")
	var console: Node3D = bridge.get_node("ComparisonConsole")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	query.transform.origin = console.to_global(Vector3(0, 0.85, 1.25))
	await physics_frame
	check(bridge.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "standing capsule fits in front of comparison control")
	var cam := Camera3D.new()
	em.add_child(cam)
	cam.fov = 62
	bridge.set_process(false)
	bridge._t = 0.35
	bridge._update_pulse()
	await capture(cam, bridge.to_global(Vector3(-0.5, 1.7, 5.2)), bridge.to_global(Vector3(-0.5, 1.3, 0)), "museum-predict")
	var button: Node3D = bridge._comparison_button
	button.get_node("InteractableAreaButton").emit_signal("button_pressed", button)
	await process_frame
	check(comparison.is_visible_in_tree(), "actual museum canonical button event reveals comparison")
	check(visible_text(bridge).contains("rate sum ≈ +0.00"), "museum bridge reveals finite zero total")
	check(visible_text(bridge).contains("f(a) = f(b)"), "level endpoint labels are combined legibly")
	await capture(cam, bridge.to_global(Vector3(-0.5, 1.7, 5.2)), bridge.to_global(Vector3(-0.5, 1.3, 0)), "museum-compared")
	await capture(cam, console.to_global(Vector3(0, 1.7, 1.25)), console.to_global(Vector3(0, 1.2, 0)), "museum-control")
	button.get_node("InteractableAreaButton").emit_signal("button_released", button)
	button.get_node("InteractableAreaButton").emit_signal("button_pressed", button)
	await process_frame
	check(not comparison.is_visible_in_tree(), "museum repeat event restores hidden comparison")
	finish()

func visible_text(node: Node) -> String:
	var result := ""
	if node is Label3D and node.is_visible_in_tree(): result += node.text + "\n"
	for child in node.get_children(): result += visible_text(child)
	return result

func finish() -> void:
	var file := FileAccess.open(OUT + "verification.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "headset_tested": false, "interaction": "canonical push-button signal; no physical hand or raycast simulated"}, "  "))
	file.close()
	print("BRIDGE_MUSEUM ", checks, " checks / ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
