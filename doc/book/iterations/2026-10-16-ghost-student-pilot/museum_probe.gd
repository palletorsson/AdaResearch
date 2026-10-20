extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	root.size=Vector2i(1600,1050)
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var bench:=find_scene("/prefab_disorder.gd")
	var compartments:=find_scene("/entropy_compartments.gd")
	check("prefab and compartment instruments installed",bench!=null and compartments!=null)
	if bench==null: return
	var ghost: Node3D=bench.ghost
	ghost.auto_enabled=false;ghost.speed=8
	check("hologram installed with two hands",ghost!=null and ghost.actor.hands.size()==2)
	check("hall still uses seed 435 initially",bench.experiment_seed==435)
	var baseline: String=ghost.state_hash()
	for x in [-1.7,0.0,1.7]:
		var p: Vector3=bench.to_global(Vector3(x,0,2.12))
		var hit:=floor_at(p)
		check("supported approach "+str(x),not hit.is_empty() and absf(hit.position.y-p.y)<0.05)
		var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
		query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
		check("clear approach beside hologram "+str(x),bench.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	check("hall ghost starts",ghost.start())
	var captured:=false
	for i in 2000:
		await process_frame
		if not captured and ghost.index==2 and ghost.phase=="operate":
			captured=true
			await snapshot("hall-ghost",bench.to_global(Vector3(1.6,2.4,2.12)),bench.to_global(Vector3(0,1.35,0.3)),83)
		if not ghost.active: break
	check("hall rehearsal finishes all nine actions",ghost.report.status=="completed" and ghost.report.steps.size()==9)
	check("hall action results match text-linked procedure",ghost.report.steps.all(func(step):return step.passed))
	check("hall starting state restored",ghost.state_hash()==baseline)
	check("Shannon/Boltzmann experiment unchanged",compartments.model.shannon_colour()==1 and compartments.model.multiplicity()==1)
	observations.scope="Native museum, synthetic pointer control events, collision approaches and exact float32 geometry replay; no headset or learning evidence."
	observations.ghost=ghost.report
