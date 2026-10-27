extends "res://tools/probes/entropies_staging_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in ([false] if "--desktop-only" in OS.get_cmdline_user_args() else [false,true]):await visit_doors(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native desktop and synthetic XR; physical headset not tested."},"\t"))
	print("DOOR_CALCULATION_RESULT ",checks.size()," checks; failures ",failed)
	quit(0 if failed.is_empty() else 1)

func centre_clear(doors: Node3D) -> bool:
	for x in [-.75,0,.75]:
		for y in [.4,1.1,1.8]:
			if not ray(doors.to_global(Vector3(x,y,4.35)),doors.to_global(Vector3(x,y,-.35))).is_empty():return false
	return true

func snapshot_values(doors: Node3D) -> bool:
	for row in doors.frames:
		var n: int=doors.step_index+row.offset
		for rule in 2:
			for ghost in 2:
				var start: float=.8+(doors.GAPS[doors.gap_index] if ghost==1 else 0.0)
				var expected: float=start/pow(2,n) if rule==0 else fposmod(start*pow(2,n),1.0)
				var actual: float=-row.pairs[rule].hinges[ghost].rotation.y/(PI/2)
				if absf(actual-expected)>.000001:return false
	return true

func visit_doors(mode: bool) -> void:
	await start(mode)
	var tag: String="XR: " if xr else "Desktop: "
	var doors:=station("doors")
	check(tag+"same original door controls and state contract",doors.get_script().get_base_script().resource_path.ends_with("door_study.gd"))
	check(tag+"three frames and console are editable parts",doors.part_defaults.keys().size()==4 and doors.frames.size()==3)
	check(tag+"default snapshots are steps zero four eight",doors.step_index==0 and doors.frames.map(func(row):return row.offset)==[0,4,8] and snapshot_values(doors))
	var widths: Array=[]
	for row in doors.frames:
		for pair in row.pairs:widths.append(pair.door_width)
	check(tag+"all six pairs have one metre leaves at original height",widths.size()==6 and widths.all(func(w):return w==1.0))
	check(tag+"open centre at initial angles",centre_clear(doors))
	var console: Node3D=doors.get_node("Console")
	game.place_player(console.to_global(Vector3(0,.06,.9)));await frames(15)
	await press(doors.buttons["STEP"])
	check(tag+"STEP advances all three frames to one five nine",doors.step_index==1 and snapshot_values(doors))
	var last: Dictionary=doors.frames[2]
	check(tag+"wrapped pair rejoins at nine but retains distinct histories",is_equal_approx(last.pairs[1].hinges[0].rotation.y,last.pairs[1].hinges[1].rotation.y) and doors.symbols(doors.trajectory(9,true))!=doors.symbols(doors.trajectory(9,true,true)))
	await press(doors.buttons["GAP +"])
	check(tag+"GAP increases the shared starting difference and resets window",doors.gap_index==3 and doors.step_index==0 and snapshot_values(doors))
	await press(doors.buttons["STEP"]);await press(doors.buttons["RESET"])
	check(tag+"RESET restores zero four eight while retaining GAP",doors.gap_index==3 and doors.step_index==0 and snapshot_values(doors))
	await press(doors.buttons["GAP -"]);await press(doors.buttons["GAP -"]);await press(doors.buttons["GAP -"])
	await press(doors.buttons["STEP"])
	check(tag+"zero GAP keeps both leaves coincident at every frame",doors.gap_index==0 and doors.frames.all(func(row):return row.pairs.all(func(pair):return is_equal_approx(pair.hinges[0].rotation.y,pair.hinges[1].rotation.y))))
	var saved: Dictionary=doors.capture()
	doors.advance_doors(15)
	await press(doors.buttons["STEP"])
	check(tag+"last window is bounded and still shows calculated states",doors.step_index==15 and snapshot_values(doors))
	check(tag+"saved clock and GAP restore all frames",doors.restore(saved) and doors.step_index==saved.step and snapshot_values(doors))
	check(tag+"invalid saved state rejected",not doors.restore({"schema":"door-pairs/1","start":.8,"partition":.5,"starting_bins":1024,"gap_index":2,"step":999}))
	# Exercise the full angular envelope, not just the initial screenshot pose.
	var clear:=true
	for gap in doors.GAPS.size():
		doors.gap_index=gap
		for step in range(16):
			doors.advance_doors(step);await frames(1)
			clear=clear and centre_clear(doors)
	check(tag+"centre stays clear across every supported GAP and STEP",clear)
	doors.gap_index=2;doors.reset_study();await frames(5)
	# The genuine player's body crosses all three thresholds in both directions.
	var origin: Vector3=doors.to_global(Vector3(0,.06,4.25))
	game.place_player(origin);await frames(12)
	if not xr:
		for z in [3.15,1.45,-.35,1.45,3.15,4.25]:
			var at: Vector3=doors.to_global(Vector3(0,0,z));at.y=-431.99
			check(tag+"walk centre z="+str(z),await walk(at))
	# Serialize an editor part pose, apply it, then restore the authored assembly.
	var frame: Node3D=doors.get_node("Frame02")
	var pose: Dictionary=JSON.parse_string(JSON.stringify({"parts":{"Frame02":{"position":[.2,0,1.9],"rotation":[0,5,0]}}}))
	doors.apply_grid_config(pose);doors.step_once();await frames(3)
	check(tag+"editor frame move and turn preserve shared controls",frame.position.is_equal_approx(Vector3(.2,0,1.9)) and is_equal_approx(frame.rotation_degrees.y,5) and snapshot_values(doors))
	doors.apply_grid_config({"parts":{"Frame02":doors.part_defaults.Frame02}});doors.reset_study()
	if not xr:
		var original: Node3D=load("res://commons/artifacts/ordinary_entropies/entropy_door_dynamics.tscn").instantiate()
		original.position=Vector3(100,0,100);root.add_child(original)
		check(tag+"museum retains its three doorways and original leaf width",original.versions.size()==3 and original.versions[0].door_width==2.17 and not "part_defaults" in original)
		original.free()
		for layer in game.find_children("*","CanvasLayer",true,false):
			if layer.get_viewport()==game.get_viewport():layer.hide()
		game.status.hide();game.notice_time=-1
		game.get_node("CareBody").process_mode=Node.PROCESS_MODE_DISABLED
		for mesh in game.get_node("CareBody").find_children("*","GeometryInstance3D",true,false):mesh.hide()
		game.body.hide();game.get_node("XROrigin3D").hide()
		root.msaa_3d=Viewport.MSAA_4X
		await photograph("01-three-frames",doors.to_global(Vector3(-3.8,1.75,4.4)),doors.to_global(Vector3(0,1.25,1.6)))
		await photograph("02-through-the-calculation",doors.to_global(Vector3(0,1.75,4.6)),doors.to_global(Vector3(0,1.7,0)))
		await photograph("03-shared-controls",console.to_global(Vector3(.7,1.65,1.55)),console.to_global(Vector3(0,1.55,0)))
		doors.step_once();await frames(4)
		await photograph("04-step-nine",doors.to_global(Vector3(.3,1.65,1.25)),doors.to_global(Vector3(-1.75,1.2,0)))
	game.queue_free();await frames(10)
	if xr:
		for t in [head,left,right]:XRServer.remove_tracker(t)
