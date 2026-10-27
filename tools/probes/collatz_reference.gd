extends "res://tools/probes/sine_yoke.gd"
const Nat = preload("res://commons/artifacts/matter_reference/natural_number.gd")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	check("arbitrary precision half beyond int64",Nat.divide("79228162514264337593543950336",2).quotient=="39614081257132168796771975168")
	check("arbitrary precision 3n+1 beyond int64",Nat.next("79228162514264337593543950337")=="237684487542793012780631851012")
	check("Collatz7 full source trajectory",Nat.trajectory("7")==["7","22","11","34","17","52","26","13","40","20","10","5","16","8","4","2","1"])
	var Script: GDScript = load("res://commons/artifacts/matter_reference/collatz.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	for study in ["collatz-marble-machine","collatz-knitting"]:
		var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"study":study,"start":"7"});work.position.y = -18;scene.add_child(work);await tick(3)
		if study=="collatz-marble-machine":
			work.running = true
			for n in range(14000):
				if work.stopped:break
				await tick()
			check("source paths and arithmetic reach 1, sixteen parity stitches",work.stopped and work.n=="1" and work.parity.size()==16)
			work.command("RUN");check("RUN restarts a finished Collatz take",work.running and not work.stopped and work.step_index==0)
			work.command("STEP");work.command("CLEAR");check("CLEAR clears the pending single-step latch",not work.step_once and not work.running)
		else:
			check("written pattern and punch/base6 cards exist as separate editable panels",work.panels.size()==3 and work.part_defaults.has("WrittenPattern") and work.digit_rows.size()==17 and work.marks.size()==17)
			check("source base-six first row encodes seven",work.digit_rows[0][0]==1 and work.digit_rows[0][1]==1)
			# Reconstruct source arithmetic from each base-six row after its read mark.
			var decoded: Array = []
			for i in work.digit_rows.size():
				var value := "0"
				for q in range(work.digit_rows[i].size()-1,work.marks[i]-1,-1):value = Nat.add(Nat.multiply(value,6),int(work.digit_rows[i][q]))
				decoded.append(value)
			check("every six-state automaton row decodes to the source Collatz trajectory",decoded==work.values)
			work.pending.parts = {"WrittenPattern":{"position":[-3.8,2.1,.2],"rotation":[0,10,0]}};work.apply_poses(work.pending);work.command("PAGE");work.command("METHOD")
			var panel: Node3D = work.get_node_or_null("WrittenPattern")
			check("PAGE and METHOD retain editable panel names and authored pose",panel!=null and work.has_node("PunchCard") and work.has_node("BaseSix") and panel.position.distance_to(Vector3(-3.8,2.1,.2))<.001 and absf(panel.rotation_degrees.y-10)<.01)
		rows.append({"study":study,"trajectory":work.values,"steps":work.step_index,"digits":work.digit_rows.size()});work.queue_free();await tick(3)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows};FileAccess.open(out.path_join("collatz-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
