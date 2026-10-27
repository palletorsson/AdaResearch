extends "res://tools/probes/sine_yoke.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -14.45;scene.add_child(ground);var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(50,.2,20);ground.add_child(shape)
	var Script: GDScript = load("res://commons/artifacts/matter_reference/program_flow.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	for study in ["call-stack","if-else-loop","list-loop","prefab-loop"]:
		var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"study":study,"settings":{"n0":2} if study=="call-stack" else {"limit":4},"parts":{"SourceRack":{"position":[.2,.1,.3],"rotation":[0,5,0]}}});work.position.y = -12;scene.add_child(work);await tick(4);work.command("RUN")
		var paused_once := false
		for n in range(12000):
			if work.done:break
			if not paused_once and work.job.get("phase","")=="roll" and float(work.job.get("t",0))>.2:
				work.command("RUN");await tick(2);var clock: float = work.job.t;var saved: Dictionary = {}
				for body in work.generated:
					if is_instance_valid(body):saved[body.get_instance_id()] = {"body":body,"position":body.global_position}
				await tick(45);var stopped: bool = work.paused and not work.running and is_equal_approx(clock,float(work.job.t))
				for item in saved.values():stopped = stopped and item.body.freeze and item.body.global_position.distance_to(item.position)<.001
				check(study+" pause retains physical poses and program cursor",stopped);work.command("RUN");paused_once = true
			await tick()
		var wanted: Array = {"call-stack":["extinguisher","monitor","donut","monitor","extinguisher"],"if-else-loop":["1","0","1","0"],"list-loop":["monitor","cone","donut","extinguisher","cone","donut"],"prefab-loop":["monitor","cone","monitor","cone"]}[study]
		check(study+" source default program reaches actual exit after pause/resume",paused_once and work.done and work.errors==0 and work.outputs==wanted)
		work.command("PRESET");check(study+" preset rebuild preserves the authored rack pose",work.rack.position.distance_to(Vector3(.2,.1,.3))<.001 and absf(work.rack.rotation_degrees.y-5)<.01)
		rows.append({"study":study,"done":work.done,"errors":work.errors,"got":work.outputs,"wanted":wanted,"job":work.job,"history":work.history,"marble":work.arr(work.to_local(work.marble.global_position)) if is_instance_valid(work.marble) else []});work.queue_free();await tick(4)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows};FileAccess.open(out.path_join("program-flow-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
