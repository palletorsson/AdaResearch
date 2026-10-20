extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	root.size=Vector2i(1600,1050)
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var bench:=find_scene("/prefab_disorder.gd")
	var accounts:=find_scene("/entropy_compartments.gd")
	check("prefab study and Shannon/Boltzmann instrument both installed",bench!=null and accounts!=null)
	if bench==null: return
	bench.pointer_path="user://prefab-disorder-museum-test-latest.json"
	observations.position=xyz(bench.global_position)
	check("four source objects and fifty mesh parts",bench.inventory.size()==4 and bench.pieces.size()==50)
	check("study faces the entrance",is_equal_approx(fposmod(bench.rotation_degrees.y,360),180))
	for x in [-1.7,0.0,1.7]:
		var p: Vector3=bench.to_global(Vector3(x,0,2.12))
		var hit:=floor_at(p)
		check("supported approach "+str(x),not hit.is_empty() and absf(hit.position.y-p.y)<0.05)
		var shape:=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
		query.transform=Transform3D(Basis(),p+Vector3.UP*0.85)
		check("clear standing space "+str(x),bench.get_world_3d().direct_space_state.intersect_shape(query).is_empty())
	var sy: float=bench.slider.global_position.y-bench.global_position.y
	check("slider within standing reach band",sy>=0.7 and sy<=1.4)
	await snapshot("hall-zero",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	bench.slider.set_normalized_value(0.5);bench.slider.slider_moved.emit(Vector3.ZERO)
	check("real slider callback changes the installed study",is_equal_approx(bench.disorder,0.5))
	await snapshot("hall-half",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	bench.set_disorder(1)
	await snapshot("hall-full",bench.to_global(Vector3(0,2.3,2.12)),bench.to_global(Vector3(0,1.30,-0.10)),74)
	bench.keep();bench.act("ZERO");bench.replay_saved()
	check("saved slider and offsets reopen in the hall",is_equal_approx(bench.disorder,1) and bench.experiment_seed==435)
	check("Shannon/Boltzmann inventory and readings remain intact",accounts.model.shannon_colour()==1 and accounts.model.multiplicity()==1)
	observations.scope="Actual hall, native controls, approach collision checks and saved replay; no headset trial."
