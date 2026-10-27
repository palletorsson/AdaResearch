extends "res://tools/probes/sine_yoke.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -24.1;scene.add_child(ground);var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = Vector3(60,.2,30);ground.add_child(hit)
	var Script: GDScript = load("res://commons/artifacts/matter_reference/tyre_chain.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	for yaw in [0.0,.6]:
		var work := Node3D.new();work.set_script(Script);work.rotation.y = yaw;work.position = Vector3(0,-24,0);scene.add_child(work);await tick(4);work.release_take()
		var marks := {}
		for n in range(1200):
			await tick();var p: Vector3 = work.to_local(work.bodies[work.graph.tyre].global_position)
			for key in {"off_ramp":-3.25,"off_plank":-.45,"wedge_end":1.25}:
				if p.x>{"off_ramp":-3.25,"off_plank":-.45,"wedge_end":1.25}[key] and not marks.has(key):marks[key] = n/60.0
			if work.stack_contact and not marks.has("stack"):marks.stack = n/60.0
		var top: Node3D = work.bodies[work.graph.stack[-1]];var drop: float = work.homes[work.graph.stack[-1]].origin.y-work.to_local(top.global_position).y
		var plank_id := "body_4";var plank_shift: float = work.to_local(work.bodies[plank_id].global_position).distance_to(work.homes[plank_id].origin)
		rows.append({"yaw":yaw,"marks":marks,"top_drop":drop,"plank_shift":plank_shift,"tyre":work.arr(work.to_local(work.bodies[work.graph.tyre].global_position))});check("chain yaw "+str(yaw)+" reaches and topples stack with loose plank stable",marks.has("stack") and drop>.6 and plank_shift<.3)
		work.queue_free();await tick(4)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows};FileAccess.open(out.path_join("chain-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
