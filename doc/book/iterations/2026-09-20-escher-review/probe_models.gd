extends SceneTree
const OUT := "res://doc/book/iterations/2026-09-20-escher-review/"
var checks: Array=[]
var evidence: Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void: checks.append({"ok":ok,"message":message})
func press(study: Node,which: String) -> void:
	study.get_node(which+"/InteractableAreaButton").button_pressed.emit(null)
func run() -> void:
	var stairs: Node3D = load("res://commons/interfaces/foundations/escher_staircase.tscn").instantiate()
	stairs.apply_grid_config({"lesson_controls":"on"})
	root.add_child(stairs)
	await process_frame
	var study: Node=stairs._study
	check(study!=null and not stairs.rotate_view,"configured study is stationary with physical controls")
	var foreign=Node3D.new();foreign.name="ExternalMapLabel";stairs.add_child(foreign)
	for form in ["none","hairline","gap","scaffold","field"]:
		check(stairs.seam==form,"FORM button reaches "+form)
		var ys: Array=[]
		for step in stairs._steps: ys.append(step.global_position.y)
		var moves: int=stairs._steps.size()
		var expected_up:=0.0;var expected_down:=0.0
		var edges: int=moves-1 if form in ["gap","scaffold"] else moves
		for i in edges:
			var dy: float=ys[(i+1)%moves]-ys[i]
			expected_up+=maxf(dy,0);expected_down+=maxf(-dy,0)
		for i in moves: press(study,"STEP")
		var marker: Node3D=stairs._study_model.get_node("StepHighlight")
		var marked_step: Node3D=stairs._steps[stairs._current_step]
		check(marker.position.is_equal_approx(marked_step.position+Vector3(0,stairs.step_height,0)),form+": visible marker follows the actual selected tread after reparenting")
		check(absf(study.ascent-expected_up)<0.00001 and absf(study.descent-expected_down)<0.00001,form+": ledger matches independently summed actual tread heights")
		if form in ["gap","scaffold"]:
			check(stairs._current_step==moves-1 and stairs._open_run_declared,form+": marker stops at actual cut end")
			press(study,"STEP")
			check(stairs._steps_climbed==edges,form+": repeated attempt does not invent an absent step")
		else:
			check(stairs._current_step==0 and absf(study.ascent-study.descent)<0.00001,form+": closed route returns with zero net height")
		evidence.append({"form":form,"centres":ys,"up":study.ascent,"down":study.descent,"display":study.screen.text})
		if form in ["gap","scaffold"]:
			press(study,"BACK")
			check(not "CUT END" in study.screen.text,form+": leaving the cut end clears its readout status")
		press(study,"RESET")
		check(stairs._current_step==0 and study.ascent==0 and study.descent==0,form+": reset clears the journey")
		press(study,"FORM")
		await process_frame
		check(is_instance_valid(foreign) and foreign.get_parent()==stairs,form+": external map node survives rebuild")
	check(stairs.seam=="none" and stairs._study==study,"all five forms cycle without replacing the controls")
	press(study,"STEP");press(study,"BACK")
	check(stairs._current_step==0 and absf(study.ascent-study.descent)<0.00001,"BACK reverses the measured transition")
	var camera:=Camera3D.new();root.add_child(camera);camera.current=true
	camera.position=Vector3(2,1.7,4)
	var camera_before:=camera.transform
	press(study,"STEP")
	check(camera.transform==camera_before,"step advances marker without moving the visitor camera")
	var legacy: Node=load("res://commons/interfaces/foundations/escher_staircase.tscn").instantiate()
	root.add_child(legacy)
	check(legacy._study==null and legacy.rotate_view,"other staircase placements remain opt-in")
	var pen: Node3D=load("res://commons/artifacts/penrose_triangle/penrose_triangle.tscn").instantiate()
	pen.apply_grid_config({"track_viewer":"on"});root.add_child(pen)
	pen.position=Vector3(2,1.5,1);pen.rotation.y=0.7
	camera.global_position=pen.to_global(Vector3(0,0,pen.size*2.5))
	camera.look_at(pen.to_global(Vector3(0,pen.size*.866*2/3,0)))
	pen._process(0.01)
	check(pen._is_at_sweet_spot,"active camera drives alignment feedback")
	var joints: Array=pen.joint_positions()
	check(joints[0].distance_to(joints[1])>0.1,"aligned endpoints are physically separate")
	check(camera.unproject_position(joints[0]).distance_to(camera.unproject_position(joints[1]))<0.01,"independent camera projection confirms endpoint alignment")
	camera.global_position+=pen.global_basis.x*0.5;pen._process(0.01)
	check(not pen._is_at_sweet_spot and pen.alignment_error_degrees(camera.global_position)>0.5,"sideways movement reveals separation")
	pen.apply_grid_config({"disclosure":"exploded"})
	camera.global_position=pen.to_global(Vector3(0,0,pen.size*2.5));pen._process(0.01)
	check(not pen._is_at_sweet_spot and pen.alignment_error_degrees(camera.global_position)>0.5,"exploded beams do not report false alignment at the former viewpoint")
	pen.apply_grid_config({"disclosure":"sealed"})
	joints=pen.joint_positions()
	check(joints[0].is_equal_approx(joints[1]),"sealed endpoints really meet")
	for i in 6: await process_frame
	var failures=checks.filter(func(c):return not c.ok)
	var f=FileAccess.open(OUT+"model-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"evidence":evidence,"failures":failures},"  "));f.close()
	print("ESCHER_MODELS ",checks.size()," checks; failures ",failures)
	stairs.free();legacy.free();pen.free();camera.free()
	quit(0 if failures.is_empty() else 1)
