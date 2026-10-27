extends "res://tools/probes/sine_yoke.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -12.1;scene.add_child(ground);var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(50,.2,20);ground.add_child(shape)
	var Script: GDScript = load("res://commons/artifacts/matter_reference/stack_queue.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	for yaw in [0.0,.5]:
		var work := Node3D.new();work.set_script(Script);work.position = Vector3(0,-12,0);work.rotation.y = yaw;scene.add_child(work);await tick(5)
		for item in ["monitor","extinguisher","cone"]:
			work.insert("stack",item);work.insert("queue",item);await tick(180)
		var stack: Array = [];var queue: Array = []
		for i in range(3):
			stack.append(work.remove_first("stack").get("item","missing"));queue.append(work.remove_first("queue").get("item","missing"));await tick(120)
		check("native stack reads highest crate first / "+str(yaw),stack==["cone","extinguisher","monitor"]);check("native queue reads furthest downhill crate first / "+str(yaw),queue==["monitor","extinguisher","cone"]);rows.append({"yaw":yaw,"stack":stack,"queue":queue});work.queue_free();await tick(4)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows};FileAccess.open(out.path_join("stack-queue-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
