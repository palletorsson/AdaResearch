extends "res://tools/probes/sine_yoke.gd"
var filter := ""
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg.begins_with("--study="):filter = arg.trim_prefix("--study=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -18.1;scene.add_child(ground);var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = Vector3(60,.2,30);ground.add_child(hit)
	var Script: GDScript = load("res://commons/artifacts/matter_reference/material_program.gd")
	if Script.reload()!=OK:quit(1);return
	var cases: Array = []
	for s in ["if","ifelse"]:
		for b in [0,1]:cases.append({"study":s,"bit":b})
	for i in range(6):cases.append({"study":"array","index":i})
	for n in range(1,6):cases.append({"study":"loop","n":n})
	for k in ["map","filter","reduce","chain"]:cases.append({"study":"pipeline_"+k,"auto_pull":true})
	var rows: Array = []
	for c in cases:
		if not filter.is_empty() and c.study!=filter:continue
		var work := Node3D.new();work.set_script(Script);work.apply_grid_config(c);work.position.y = -18;scene.add_child(work);await tick(4);work.inputs.X = bool(c.get("bit",true));work.release_take()
		for n in range(2300):
			if work.result>=0:break
			await tick()
		var good := false;var reading := {}
		if c.study.begins_with("pipeline_"):
			reading = work.pipeline_read();var cups: Array = [];var trays: Array = [];var sum := 0;var kind: String = c.study.trim_prefix("pipeline_")
			for value in [3,1,4,1,5]:
				var x: int = value+int(kind in ["map","chain"]);var pour: bool = kind=="reduce" or kind in ["filter","chain"] and x>=(3 if kind=="filter" else 4);cups.append(0 if pour else x);trays.append(x if pour and kind=="filter" else 0)
				if pour and kind in ["reduce","chain"]:sum+=x
			good = reading.cups==cups and reading.trays==trays and reading.rail==sum and reading.lost==0
			reading.wanted = {"cups":cups,"trays":trays,"rail":sum}
		elif c.study in ["if","ifelse"]:good = work.events.has("then" if c.bit else "else") and not work.events.has("else" if c.bit else "then") and work.events.has("end") and (work.events.has("thenDone") if c.bit else not work.events.has("thenDone")) and (c.study=="if" or bool(work.events.has("elseDone"))==not bool(c.bit))
		elif c.study=="array":good = work.events.keys().filter(func(s):return str(s).begins_with("read"))==["read"+str(c.index)]
		else:reading = {"bucket":work.bucket_count()};good = reading.bucket==c.n and work.events.has("exit") and work.events.has("tipped")
		if work.graph.refs.has("pc"):reading.pc = work.arr(work.local_position(work.graph.refs.pc));reading.velocity = work.arr(work.bodies[work.graph.refs.pc].linear_velocity)
		rows.append({"case":c,"events":work.events.duplicate(),"reading":reading,"passed":good});print("MATERIAL_PROGRAM_ROW ",JSON.stringify(rows[-1]));check(JSON.stringify(c)+" actual physical result",good);work.queue_free();await tick(4)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows};FileAccess.open(out.path_join("material-program-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
