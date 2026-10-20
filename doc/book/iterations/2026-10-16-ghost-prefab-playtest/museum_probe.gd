extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	AudioServer.set_bus_mute(0,true)
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var bench:=find_scene("/prefab_disorder.gd")
	var ledger:=find_scene("/shannon_entropy_meter.gd")
	check("prefab and next ledger installed",bench!=null and ledger!=null)
	if bench==null or ledger==null: return
	var ghost: Node3D=bench.ghost;ghost.auto_enabled=false;ghost.speed=4
	var original_camera:=root.get_camera_3d();var baseline: String=ghost.state_hash()
	check("hall rehearsal starts",ghost.start())
	for i in 5000:
		await process_frame
		if not ghost.active and not ghost.walk.requested and not ghost.walk.walking and (ghost.walk.receipt.get("status")!="arrived" or ghost.capture_marks.has("12-next-shannon")): break
	await process_frame;await RenderingServer.frame_post_draw
	check("all nine actions pass in the hall",ghost.report.status=="completed" and ghost.report.steps.size()==9 and ghost.report.steps.all(func(s):return s.passed))
	check("ghost reaches the next artifact",ghost.walk.receipt.get("status")=="arrived")
	check("ghost walks at least two metres",ghost.walk.receipt.get("travelled_metres",0)>2)
	check("prefab state restored before continuation",ghost.state_hash()==baseline)
	check("visitor camera remains active",root.get_camera_3d()==original_camera)
	check("arrival photographed",ghost.report.observations.any(func(o):return o.label=="12-next-shannon" and o.status=="saved"))
	check("floor seams are walkable",ghost.walk.clear_at(Vector3(10,0,2)))
	check("missing floor is refused",not ghost.walk.clear_at(Vector3(1000,0,1000)))
	for pair in ghost.report.observations:
		check(pair.label+" is a paired same-frame capture",pair.status=="saved" and pair.same_process_frame)
		for entry in pair.thought_stream:
			if entry.has("path"): check(pair.label+" source quote verified",FileAccess.get_file_as_string(entry.path).contains(entry.text))
	observations.ghost=ghost.report.duplicate(true)
	observations.walk=ghost.walk.receipt.duplicate(true)
	observations.scope="Native rendering, floor-clearance path and pointer rehearsal. No human learning, headset or comfort evidence."
	# An obstruction at the destination must refuse a route; no teleport fallback.
	var blocker:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.5,2,1.5);shape.shape=box;blocker.add_child(shape);hall.add_child(blocker)
	blocker.global_position=ledger.to_global(Vector3(0,1,2.35));await tick();await tick()
	ghost.walk.actor=ghost.actor;ghost.walk.destination=ledger
	check("obstructed destination is refused",not ghost.walk.plan() and ghost.walk.receipt.status=="approach obstructed")
	blocker.queue_free();await tick();await tick()
	ghost.walk.begin(ghost.actor,ledger);ghost.take_over()
	check("visitor cancels continuation immediately",not ghost.walk.requested and not ghost.walk.walking)
