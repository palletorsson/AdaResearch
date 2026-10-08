extends SceneTree
var checks: Array[Dictionary] = []
var reports: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, text: String) -> void:
	checks.append({"passed":value,"test":text})
	if not value: push_error(text)

func same_except_manual(a: Dictionary,b: Dictionary) -> bool:
	var aa := a.duplicate(true)
	var bb := b.duplicate(true)
	aa.erase("manual"); bb.erase("manual")
	return aa==bb

func run() -> void:
	create_timer(120).timeout.connect(func():quit(99))
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/foundation_b/manifest.json"))
	for entry: Dictionary in manifest:
		var protected_hash := FileAccess.get_sha256(entry.source_paths[0])
		var scene = load(entry.scene)
		check(scene is PackedScene,entry.id+" scene loads")
		if not scene is PackedScene: continue
		var stage = scene.instantiate()
		seed(715923)
		var expected_random := randf()
		seed(715923)
		root.add_child(stage)
		check(stage.has_method("experiment_snapshot"),entry.id+" experiment initializes")
		if not stage.has_method("experiment_snapshot"):
			stage.free()
			continue
		var start_nodes: int = stage.find_children("*","",true,false).size()
		var phase_states: Array = []
		for phase in range(4):
			stage.playhead = stage.duration*(float(phase)+.72)/4.0
			stage.refresh()
			phase_states.append(stage.experiment_snapshot())
			check(stage.camera.transform.is_finite(),entry.id+" finite camera phase %d" % phase)
			for node in stage.find_children("*","MeshInstance3D",true,false):
				check(node.transform.is_finite() and node.mesh!=null and node.mesh.get_aabb().size.is_finite(),entry.id+" finite mesh "+str(node.name))
		var view_before: Transform3D = stage.camera.transform
		stage.next_route(); stage.refresh()
		check(not stage.camera.transform.is_equal_approx(view_before),entry.id+" view turn persists through refresh")
		stage.orbit(-.28)
		stage.experiment_action("reset")
		check(not stage.running and stage.manual,entry.id+" action pauses demonstration")
		var reset_snapshot: Dictionary = stage.experiment_snapshot()
		stage.playhead=stage.duration*.83; stage.refresh(); stage.advance(2.0)
		check(stage.experiment_snapshot()==reset_snapshot,entry.id+" manual state survives time change and refresh")
		stage.experiment_action("unknown")
		check(stage.experiment_snapshot()==reset_snapshot,entry.id+" unknown key is harmless")
		var control_states: Array = []
		if entry.id=="foundation_state":
			check(reset_snapshot.frames==0 and reset_snapshot.elapsed==0 and not reset_snapshot.near and not reset_snapshot.visited,"State reset exact")
			for i in range(1,9):
				stage.experiment_action("frame")
				var snapshot: Dictionary = stage.experiment_snapshot()
				check(snapshot.frames==i and snapshot.elapsed==i*.5,"FRAME exact count %d" % i)
				check(is_equal_approx(snapshot.travel_fraction,minf(i*.25,1.0)),"Clamped travel at step %d" % i)
				check(is_equal_approx(stage.traveller.position.x,-2.5+5.0*minf(i*.25,1.0)),"Displayed body matches step %d" % i)
				control_states.append(snapshot)
			stage.experiment_action("proximity")
			var near: Dictionary = stage.experiment_snapshot()
			check(near.near and near.visited and near.frames==8,"Approach changes two states without advancing time")
			check(is_equal_approx(near.gate_panel_width[0],.3) and is_equal_approx(near.gate_panel_width[1],.3),"Both gate openings display 70 percent")
			check(stage.experiment_controls()[1].label=="AWAY","Near control offers away")
			control_states.append(near)
			stage.experiment_action("proximity")
			var away: Dictionary = stage.experiment_snapshot()
			check(not away.near and away.visited and away.elapsed==4.0,"Away preserves visit and time")
			check(is_equal_approx(away.gate_panel_width[0],1.0) and is_equal_approx(away.gate_panel_width[1],.3),"Gate geometry shows different states")
			check(stage.experiment_controls()[1].label=="APPROACH","Away control offers approach")
			control_states.append(away)
			stage.experiment_action("reset")
			check(stage.experiment_snapshot()==reset_snapshot,"Reset clears retained visit")
		else:
			var reference: Array = reset_snapshot.reference_positions.duplicate(true)
			check(reset_snapshot.height==2.0 and reset_snapshot.sides==8,"Function reset equals browser inputs")
			for expected in [12,16,4,6,8]:
				stage.experiment_action("sides")
				var snapshot: Dictionary=stage.experiment_snapshot()
				check(snapshot.sides==expected,"Radial count cycles to %d" % expected)
				check(snapshot.output_positions.size()==2*expected,"Two rings retain 2*n inputs")
				check(snapshot.reference_positions==reference,"Side changes preserve independent reference")
				control_states.append(snapshot)
			for i in range(1,26):
				stage.experiment_action("lower")
				var snapshot: Dictionary=stage.experiment_snapshot()
				check(is_equal_approx(snapshot.height,maxf(1.0,2.0-i*.1)),"Height decrements and clamps %d" % i)
				check(snapshot.reference_positions==reference,"Height changes preserve independent reference")
			control_states.append(stage.experiment_snapshot())
			for i in range(1,36):
				stage.experiment_action("raise")
				var snapshot: Dictionary=stage.experiment_snapshot()
				check(is_equal_approx(snapshot.height,minf(3.0,1.0+i*.1)),"Height increments and clamps %d" % i)
				check(is_equal_approx(stage.reference.scale.y,2.0),"Displayed reference height remains fixed")
				check(is_equal_approx(stage.variants[int(snapshot.sides)].scale.y,snapshot.height),"Displayed editable height matches input")
			control_states.append(stage.experiment_snapshot())
		stage.replay()
		check(not stage.manual and stage.running and stage.playhead==0,"Replay restores autoplay: "+entry.id)
		stage.advance(.3)
		check(stage.playhead>0,"Autoplay advances after manual comparison: "+entry.id)
		check(stage.experiment_controls().size()<=4,"At most four controls: "+entry.id)
		check(stage.validation().passed,"Source and geometry validation: "+entry.id)
		check(stage.find_children("*","",true,false).size()==start_nodes,"Every phase and interaction reuse built nodes: "+entry.id)
		check(randf()==expected_random,"Global RNG untouched: "+entry.id)
		check(FileAccess.get_sha256(entry.source_paths[0])==protected_hash,"Source unchanged: "+entry.id)
		reports.append({"id":entry.id,"phase_states":phase_states,"control_states":control_states,"validation":stage.validation(),"node_count":start_nodes})
		root.remove_child(stage); stage.free()
		await process_frame
	var passed := true
	for test in checks: passed=passed and test.passed
	DirAccess.make_dir_recursive_absolute("res://ada_run/foundation_monitors/foundation_b")
	var report:=FileAccess.open("res://ada_run/foundation_monitors/foundation_b/report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed":passed,"checks":checks,"films":reports},"  "))
	print("FOUNDATION B ",checks.size()," checks; passed=",passed)
	quit(0 if passed else 1)
