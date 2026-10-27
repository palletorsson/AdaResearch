extends "res://tools/probes/sine_yoke.gd"
var substeps := 1
var rocker_drag := -log(.7)
var marble_drag := 1.0
func tick(n := 1) -> void:
	for i in n*substeps:await physics_frame;await process_frame
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--240":substeps = 4;Engine.physics_ticks_per_second = 240
		if arg.begins_with("--rocker-drag="):rocker_drag = float(arg.trim_prefix("--rocker-drag="))
		if arg.begins_with("--marble-drag="):marble_drag = float(arg.trim_prefix("--marble-drag="))
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var Script: GDScript = load("res://commons/artifacts/matter_reference/marble_boards.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	for kind in ["and","or","xor","not","half","count"]:
		if kind=="count":
			var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"kind":kind,"rocker_drag":rocker_drag,"marble_drag":marble_drag});work.position.y = -18;scene.add_child(work);await tick(3)
			for n in range(1,9):
				work.drop("in");await tick(480);var got: Dictionary = work.read();rows.append({"kind":kind,"n":n,"got":got});check("physical binary counter "+str(n),got.value==n%8 and got.over==int(n>=8))
			work.queue_free();await tick(3)
			continue
		for bits in (["0","1"] if kind=="not" else ["00","01","10","11"]):
			var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"kind":kind,"rocker_drag":rocker_drag,"marble_drag":marble_drag});work.position.y = -18;scene.add_child(work);await tick(3)
			if bits[0]=="1":work.drop("X");await tick(48 if kind in ["and","or"] else 78)
			if bits.length()>1 and bits[1]=="1":work.drop("Y")
			await tick(360);var got: Dictionary = work.read();var x := int(bits[0]);var y := int(bits[1]) if bits.length()>1 else 0
			var wanted: Dictionary = {"and":{"Z":x&y},"or":{"Z":x|y},"xor":{"Z":x^y},"not":{"Z":1-x},"half":{"S":x^y,"C":x&y}}[kind]
			var good := true
			for key in wanted:
				if got[key]!=wanted[key]:good = false
			var row := {"kind":kind,"inputs":bits,"wanted":wanted,"got":got,"balls":[]};
			for b in work.marbles:row.balls.append(work.arr(work.to_local(b.global_position)))
			rows.append(row);print("MARBLE_ROW ",JSON.stringify(row));check(kind+" physical "+bits,good);work.queue_free();await tick(3)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows,"scope":"Original marble hole and hinged flip-flops with original geometry/mass; outputs read physical occupied trays and rocker angle."}
	FileAccess.open(out.path_join("marble-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
