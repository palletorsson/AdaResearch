extends SceneTree
## Exercises configured door constraints in the actual Trans_Translation museum grid.
var checks: Array = []
var failures: Array = []

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, passed: bool, value: Variant = null) -> void:
	checks.append({"name":label,"passed":passed,"value":value})
	if not passed: failures.append(label)
	print("[permissions] ", "PASS " if passed else "FAIL ",label," ",value)

func _run() -> void:
	var museum: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var prefix := "res://ada_run/_trial_translation_permissions"
	var f := FileAccess.open(prefix+"_control.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation","first_map":"Trans_Translation","dollhouse":0,"grid_pack":1}))
	f.close()
	museum.set("EM_CONTROL",prefix+"_control.json")
	museum.set("_overrides_path",prefix+"_overrides.json")
	museum.set("_hand_path",prefix+"_hand.json")
	museum.set("start_chapter","transformation")
	museum.set("start_map","Trans_Translation")
	root.add_child(museum)
	current_scene=museum
	var grid: Node3D
	for i in 900:
		await process_frame
		grid=museum.find_child("SimGrid_Trans_Translation",true,false)
		if grid != null: break
	check("actual museum grid exists",grid!=null)
	if grid==null:
		finish()
		return
	museum.set_process(false)
	for i in 180:
		await physics_frame
		await process_frame
	var demos: Array[Node3D]=[]
	for n in grid.find_children("*","Node3D",true,false):
		if n.get_script()!=null and n.get_script().resource_path.ends_with("/translation_cube_demo.gd"): demos.append(n)
	check("two door studies instantiated",demos.size()==2,demos.size())
	for demo in demos:
		var mode: String=demo.course
		check("authored course arrived intact",mode in ["lift_lateral","free"],mode)
		check("authored yaw preserved",absf(absf(demo.rotation_degrees.y)-180.0)<0.1,demo.rotation_degrees.y)
		var left=demo._left_door
		var knob=left._knob
		var relative_height:float=knob.global_position.y-(grid.global_position.y+0.5)
		check(mode+" handle within standing reach",relative_height>=1.1 and relative_height<=1.5,relative_height)
		knob.freeze=true
		left.set_physics_process(false)
		knob.picked_up.emit(knob)
		check(mode+" pickup signal accepted",left._is_grabbed)
		var start:Vector3=left._knob_start()
		var target:Vector3=start+left.phase1_dir*left.target_y+left.phase2_dir*left.target_x
		if mode=="lift_lateral":
			knob.position=start+Vector3(-0.1,0.05,0)
			left._physics_process(1.0/60.0)
			check("guided first leg refuses sideways movement",is_equal_approx(knob.position.x,start.x) and knob.position.y>start.y)
			knob.position=start+left.phase1_dir*left.target_y
			left._physics_process(1.0/60.0)
			check("lift unlocks sideways leg",left.get_phase()==2)
		else:
			knob.position=start+Vector3(-0.1,0.05,0)
			left._physics_process(1.0/60.0)
			check("free study permits simultaneous components",knob.position.x<start.x-0.09 and knob.position.y>start.y+0.04)
		knob.position=target
		left._physics_process(1.0/60.0)
		check(mode+" reaches shared displacement",left.is_goal_reached() and knob.position.is_equal_approx(target),str(target-start))
		knob.dropped.emit(knob)
		check(mode+" release signal accepted",not left._is_grabbed)
		left.reset()
		check(mode+" resets for next visitor",not left.is_goal_reached() and knob.position.is_equal_approx(start))
	finish()

func finish() -> void:
	var f:=FileAccess.open("res://ada_run/translation-permissions-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"actual_endless_museum":true,"headset_tested":false},"  "))
	f.close()
	quit(0 if failures.is_empty() else 1)
