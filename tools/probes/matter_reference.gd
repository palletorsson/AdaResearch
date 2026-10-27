extends "res://tools/probes/sine_yoke.gd"
var kinds: Array = ["and","or","xor","not","nor","nand"]
var hinge_drag := 50.0
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--kinds="):kinds = arg.trim_prefix("--kinds=").split(",")
		if arg.begins_with("--hinge-drag="):hinge_drag = float(arg.trim_prefix("--hinge-drag="))
	var script: GDScript = load("res://commons/artifacts/matter_reference/matter_reference.gd")
	if script.reload()!=OK:
		FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":false,"failures":["runtime does not compile"]}));quit(1);return
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.name = "SourceGround";ground.position.y = -12.1;scene.add_child(ground);var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = Vector3(60,.2,20);ground.add_child(hit)
	var rows: Array = []
	for kind in kinds:
		for bits in (["0","1"] if kind=="not" else ["00","01","10","11"]):
			var work := Node3D.new();work.set_script(script);work.apply_grid_config({"kind":kind,"hinge_drag":hinge_drag});work.position.y = -12;scene.add_child(work);await tick(4)
			work.inputs.X = bits[0]=="1";work.inputs.Y = bits.length()>1 and bits[1]=="1";work.release_take()
			for i in range(1100):
				if work.result>=0:break
				await tick()
			var x := int(bits[0]);var y := int(bits[1]) if bits.length()>1 else 0
			var wanted: int = {"and":x&y,"or":x|y,"xor":x^y,"not":1-x,"nor":1-(x|y),"nand":1-(x&y)}[kind]
			var positions := {}
			for id in work.bodies:
				if work.bodies[id] is RigidBody3D:positions[id] = {"at":work.arr(work.to_local(work.bodies[id].global_position)),"rotation":work.arr(work.bodies[id].rotation_degrees)}
			var row := {"kind":kind,"inputs":bits,"wanted":wanted,"got":work.result,"first_z":work.first_z,"elapsed":work.elapsed,"bodies":positions,"contacts":work.hit_log.size()};rows.append(row);print("SOURCE_GATE_ROW ",JSON.stringify(row));check(kind+" / "+bits+" actual Jolt result",work.result==wanted)
			work.queue_free();await tick(4)
	observations.rows = rows
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"observations":observations,"scope":"Canonical button-started source body graphs and masses; native Jolt results read from target tilt or XOR ball escape. These rows do not assert truth tables for arbitrary hand rearrangements."}
	for name in ["checks.json","gate-checks.json"]:FileAccess.open(out.path_join(name),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
