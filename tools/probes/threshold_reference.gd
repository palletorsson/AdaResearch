extends "res://tools/probes/sine_yoke.gd"
var focus := ""
var variant := 0
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--kind="):focus = arg.trim_prefix("--kind=")
		if arg.begins_with("--variant="):variant = int(arg.trim_prefix("--variant="))
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -18.1;scene.add_child(ground);var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = Vector3(60,.2,30);ground.add_child(hit)
	var Script: GDScript = load("res://commons/artifacts/matter_reference/thresholds.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	for kind in ["again","almost","just","barely","still","descent"]:
		if not focus.is_empty() and kind!=focus:continue
		var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"threshold":kind,"variant":variant,"auto_feed":true});work.position.y = -18;scene.add_child(work);await tick(4);work.release_take()
		for n in range(2500):
			if work.result>=0:break
			await tick()
		check(kind+" provides finite physical observation",not work.reading.is_empty() and work.result>=0);rows.append({"kind":kind,"reading":work.reading.duplicate(),"result":work.result});work.queue_free();await tick(4)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows,"scope":"Actual Jolt threshold observations, not Cannon threshold agreement or deterministic completion of every noisy take."};FileAccess.open(out.path_join("threshold-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
