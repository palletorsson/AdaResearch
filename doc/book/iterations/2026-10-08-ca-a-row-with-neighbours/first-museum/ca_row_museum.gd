extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false); stream.set_physics_process(false)
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide(); walker.set_process(false); walker.set_physics_process(false)
		walker.global_position = Vector3(0,-100,0)
	var previous = museum.get("_cam")
	if previous is Node3D: previous.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").hide()
	var work := find_scene("/ca_rule_explorer.gd")
	check("Installed explorer found in CA opening",work != null)
	if work==null: return
	var desk = work.get_node("NeighbourStudy")
	var reader = desk.get_node("HandPoint")
	check("Existing table now has the PointBody reader",reader.point is XRToolsPickable)
	work.rule=90; work.auto_run=false; work._reset()
	for i in 16: work.step()
	desk.refresh()
	var eye: Vector3 = work.to_global(Vector3(-.7,1.25,2.5))
	var target: Vector3 = work.to_global(Vector3(.15,.12,.05))
	reader.hide()
	await snapshot("before",eye,target,62)
	reader.show()
	await snapshot("after",eye,target,62)
	var approach: Vector3 = work.to_global(Vector3(0,-1.04,1.95))
	var hit := floor_at(approach)
	check("Reader approach has museum floor",not hit.is_empty())
	check("Reader stays at hand height above the hall floor",reader.point.global_position.y-hall.global_position.y>1.0 and reader.point.global_position.y-hall.global_position.y<1.5)
	var pose: Vector3 = reader.point.global_position
	reader.point.on_desktop_grab(camera)
	reader.point.global_position=reader.to_global(Vector3(-.8,.2,1.45))
	await create_timer(.2).timeout
	check("Actual hall hand reader reaches address zero",work.sample_cell==0)
	var before: int = work.generation
	reader.point.action(); await create_timer(.2).timeout
	check("Hand step advances one shared generation",work.generation==before+1 and desk.room_ring.rendered==work._grid)
	reader.point.on_desktop_drop(camera); await create_timer(.2).timeout
	check("Reader release remains on local rail",absf(reader.point.position.z-1.45)<.0001)
	await snapshot("boundary",work.to_global(Vector3(-.7,1.0,1.85)),work.to_global(Vector3(.3,.15,.1)),72)
	await snapshot("ring",work.to_global(Vector3(1.6,.7,2.8)),work.to_global(Vector3(1.6,1.8,.5)),70)
	work.rule=30; work._reset(); for i in 16: work.step()
	desk.refresh()
	await snapshot("rule-30",eye,target,62)
	# The exact printed study is temporarily placed at the same desk, not installed as a duplicate.
	work.hide()
	var study=load("res://doc/book/iterations/2026-10-08-ca-a-row-with-neighbours/printed/row.gd").new()
	hall.add_child(study)
	study.global_transform=work.global_transform
	study.global_position.y-=.95
	for i in 16: study.step()
	await create_timer(.2).timeout
	check("Exact printed study runs inside the existing hall",study.generation==16 and study.history.size()==17 and study.point != null)
	var colour_ok := true
	for row in study.history.size():
		for col in 32:
			var want := Color("87dca5") if study.history[row][col] else Color("243238")
			var got: Color=study.tiles.get_instance_color(row*32+col)
			colour_ok=colour_ok and absf(want.r-got.r)<.004 and absf(want.g-got.g)<.004 and absf(want.b-got.b)<.004
	check("Museum rendering retains the exact printed history",colour_ok)
	await snapshot("printed-study",study.to_global(Vector3(-.45,2.25,2.6)),study.to_global(Vector3(0,1.1,0)),58)
	observations["scope"]="Actual CA_Introduction museum. Before/after same Rule 90 state with reader hidden/shown; supplied desktop hand event; exact printed reconstruction temporarily mounted. No physical headset or human learner evaluation."
	observations["reader_world"]=xyz(pose)
	observations["work_world"]=xyz(work.global_position)
	observations["floor_hit"]=xyz(hit.position) if not hit.is_empty() else []
	study.queue_free(); work.show()
