extends "res://tools/probes/sine_yoke.gd"
## Calibration receipts describe motion; they are not automatic acceptance.
func fixture() -> Node3D:
	var work: Node3D = load("res://commons/artifacts/matter_experiments/leaning_together.tscn").instantiate();work.position = Vector3(0,-18,0);work.rotation.y = .37;scene.add_child(work);return work

func positions(work: Node3D) -> Dictionary:
	var data := {}
	for id in work.bodies:data[id] = work.to_local(work.bodies[id].global_position)
	return data

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -18.1;scene.add_child(ground);var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(20,.2,20);ground.add_child(shape)
	var rows: Array = []
	for id in ["none","LeftPlank","RightPlank","Cube","Ball","LeftWedge","RightWedge"]:
		var work := fixture();await tick(1800);var before := positions(work);var first: Dictionary = work.observations()
		if id!="none":
			var body: Node3D = work.bodies[id];var at: Vector3 = body.to_global(Vector3(.5,0,0)) if "Plank" in id else body.global_position+Vector3.UP*.1
			body.apply_impulse(-work.global_basis.z*body.mass*.25,at-body.global_position)
		await tick(480);var after := positions(work);var row := {"part":id,"idle":first,"before":before,"after":after,"final":work.observations()};rows.append(row);print("BRITTLE_CALIBRATE ",row)
		work.queue_free();await tick(5)
	var report := {"rows":rows,"scope":"Thirty-second idle followed by one mass-scaled 0.20 m/s contact impulse and eight seconds of native Jolt motion. Calibration only, not acceptance."}
	FileAccess.open(out.path_join("leaning-brittle-calibration.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify({"calibration":true,"rows":rows.size()}));quit()
