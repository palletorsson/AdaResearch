extends SceneTree
var checks: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title})
	print("PASS " if ok else "FAIL ",title)

func run() -> void:
	var stages: Array[Node3D] = []
	for id in ["foundation_point","foundation_trace"]:
		var scene: PackedScene = load("res://commons/artifacts/spine_films/foundation_a/"+id+".tscn")
		check(scene!=null,id+" scene loads")
		if scene==null: continue
		seed(713)
		var expected_random := randf()
		seed(713)
		var stage: Node3D = scene.instantiate()
		root.add_child(stage)
		stages.append(stage)
		check(is_equal_approx(randf(),expected_random),id+" construction preserves global RNG")
		check(bool(stage.validation().passed),id+" initial state/geometry agree")
		check(stage.experiment_controls().size()<=4,id+" physical controls fit the monitor protocol")
		var descendants := stage.find_children("*","",true,false).size()
		var mesh_ids: Array[int] = []
		for mesh in stage.find_children("*","MeshInstance3D",true,false): mesh_ids.append(mesh.get_instance_id())
		for phase in range(4):
			for fraction in [.001,.5,.999]:
				stage.playhead = (phase+fraction)*stage.duration/4.0
				stage.refresh()
				check(bool(stage.validation().passed),id+" phase %d %.3f source invariant" % [phase,fraction])
		check(stage.find_children("*","",true,false).size()==descendants,id+" animation reuses scene nodes")
		var refreshed_ids: Array[int] = []
		for mesh in stage.find_children("*","MeshInstance3D",true,false): refreshed_ids.append(mesh.get_instance_id())
		check(mesh_ids==refreshed_ids,id+" animation reuses mesh instances")
		var before_camera: Vector3 = stage.camera.position
		stage.next_route()
		var turned_camera: Vector3 = stage.camera.position
		stage.refresh()
		check(not before_camera.is_equal_approx(turned_camera) and stage.camera.position.is_equal_approx(turned_camera),id+" camera turn survives refresh")
		stage.replay()
	if stages.size()==2:
		verify_point(stages[0])
		verify_trace(stages[1])
	var passed := true
	for row in checks: passed = passed and row.passed
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/foundation_a"))
	var report := FileAccess.open("res://ada_run/foundation_a/report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed":passed,"checks":checks,"source":"res://commons/artifacts/spine_films/foundation_source.js"},"  "))
	report.close()
	for stage in stages: stage.free()
	quit(0 if passed else 1)

func verify_point(stage: Node3D) -> void:
	check(is_equal_approx(stage.experiment_snapshot().height,1.2),"Point browser default is 1.2 m")
	stage.experiment_action("raise")
	check(is_equal_approx(stage.experiment_snapshot().height,1.3) and not stage.running,"Point raise adds 0.1 and pauses")
	stage.experiment_action("lower")
	check(is_equal_approx(stage.experiment_snapshot().height,1.2),"Point lower subtracts 0.1")
	stage.experiment_action("frame")
	check(stage.experiment_snapshot().mistake and is_equal_approx(stage.experiment_snapshot().actual,2.2),"Point frame mistake adds exactly 1 m")
	var state: Dictionary = stage.experiment_snapshot()
	stage.playhead = 23.0
	stage.refresh()
	check(stage.experiment_snapshot()==state,"Point manual state survives autoplay draw position")
	for i in range(50): stage.experiment_action("raise")
	check(is_equal_approx(stage.height_value,3.0) and is_equal_approx(stage.displayed_height(),4.0),"Point upper bound 3 m plus error 1 m")
	for i in range(50): stage.experiment_action("lower")
	check(is_zero_approx(stage.height_value) and is_equal_approx(stage.displayed_height(),1.0),"Point lower bound 0 m plus error 1 m")
	stage.experiment_action("frame")
	check(not stage.wrong_frame and is_zero_approx(stage.displayed_height()),"Point frame toggles back without changing requested height")
	stage.experiment_action("reset")
	check(is_equal_approx(stage.height_value,1.2) and not stage.wrong_frame and stage.manual_mode and not stage.running,"Point reset restores the study while remaining manual")
	check(bool(stage.validation().passed),"Point all control results agree with actual geometry")
	stage.replay()
	check(not stage.manual_mode and stage.running and is_zero_approx(stage.playhead),"Point replay clears manual state and restarts film")

func verify_trace(stage: Node3D) -> void:
	check(stage.experiment_snapshot().points==[[0.0,0.0]],"Trace starts with one supplied position")
	stage.experiment_action("join")
	check(stage.joined_count==0,"Trace cannot join before a retained neighbour exists")
	var counts := [1,2,2,3,4,4,5]
	var kept := [false,true,false,true,true,false,true]
	var origins := [0,0,2,2,4,5,5]
	for i in range(7):
		stage.experiment_action("read")
		var state: Dictionary = stage.experiment_snapshot()
		check(state.candidate==i+1 and state.points.size()==counts[i] and state.keep==kept[i] and state.last_from==origins[i],"Trace source candidate %d: keep=%s size=%d origin=%d" % [i+1,kept[i],counts[i],origins[i]])
		check(bool(stage.validation().passed),"Trace read %d geometry and list agree" % [i+1])
	check(stage.experiment_snapshot().indices==[0,2,4,5,7],"Trace final retained indices exactly match browser study")
	var complete: Dictionary = stage.experiment_snapshot()
	stage.experiment_action("read")
	check(stage.experiment_snapshot()==complete,"Trace read stops safely after the eighth candidate")
	var stored: Array = stage.experiment_snapshot().points
	for i in range(4):
		stage.experiment_action("join")
		check(stage.joined_count==i+1 and stage.experiment_snapshot().points==stored,"Trace join %d leaves stored positions unchanged" % [i+1])
		check(bool(stage.validation().passed),"Trace join %d geometry agrees" % [i+1])
	complete = stage.experiment_snapshot()
	stage.experiment_action("join")
	check(stage.experiment_snapshot()==complete,"Trace join stops after four neighbour pairs")
	stage.playhead = .1
	stage.refresh()
	check(stage.experiment_snapshot()==complete,"Trace manual record survives autoplay draw position")
	stage.experiment_action("reset")
	check(stage.candidate_index==0 and stage.retained_indices==[0] and stage.joined_count==0 and not stage.running,"Trace reset preserves original initial state and pauses")
	stage.experiment_action("read")
	stage.experiment_action("read")
	stage.experiment_action("join")
	stage.experiment_action("read")
	check(stage.retained_indices==[0,2] and stage.joined_count==1,"Trace can interleave reading and joining without replacing the list")
	stage.replay()
	check(not stage.manual_mode and stage.running and stage.candidate_index==0 and stage.joined_count==0,"Trace replay clears manual state and starts with original record")
