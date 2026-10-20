extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var bench:=find_scene("/prefab_disorder.gd")
	var compartments:=find_scene("/entropy_compartments.gd")
	check("prefab and compartment instruments installed",bench!=null and compartments!=null)
	if bench==null: return
	var ghost: Node3D=bench.ghost
	ghost.auto_enabled=false;ghost.speed=8
	var original_camera:=root.get_camera_3d()
	var baseline: String=ghost.state_hash()
	check("hall initial seed remains 435",bench.experiment_seed==435)
	check("both cameras use actual museum world",ghost.observer.views.all(func(v):return v.world_3d==bench.get_world_3d()))
	check("hall rehearsal starts",ghost.start())
	for i in 2200:
		await process_frame
		if not ghost.active: break
	check("hall rehearsal completes all nine actions",ghost.report.status=="completed" and ghost.report.steps.size()==9 and ghost.report.steps.all(func(s):return s.passed))
	check("hall has four paired captures",ghost.report.observations.size()==4)
	for pair in ghost.report.observations:
		check(pair.label+" saved two views from same frame",pair.status=="saved" and pair.same_process_frame and pair.files.size()==2)
		check(pair.label+" head pose follows hall transform",bench.Hybrid.unpack(pair.head.world).is_equal_approx(bench.global_transform*bench.Hybrid.unpack(pair.head.bench)))
	check("visitor camera remains active",root.get_camera_3d()==original_camera)
	check("starting artifact state restored",ghost.state_hash()==baseline)
	check("Shannon/Boltzmann instrument unchanged",compartments.model.shannon_colour()==1 and compartments.model.multiplicity()==1)
	observations.scope="Native museum rendering and synthetic pointer rehearsal. Monoscopic eye view; no headset, comfort or learner evidence."
	observations.ghost=ghost.report
