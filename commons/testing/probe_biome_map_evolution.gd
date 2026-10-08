extends SceneTree
const Bridge := preload("res://commons/artifacts/biome_inheritance/biome_inheritance.gd")
var checks := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(message)

func run() -> void:
	var bridge := Bridge.new()
	bridge.evolution_stage = "Point_One"
	root.add_child(bridge)
	var ids: Array = []
	for body in bridge.sculpture._form_bodies: ids.append(body.get_instance_id())
	var archive: Dictionary = bridge.sculpture.get_state()
	var states: Array = []
	for hall in ["Point_One","Point_Triangle_Context","Trans_Translation","Trans_Rotation","Trans_Scale","Color_Context_Placed","Pattern_Foundry","Random_Mushrooms","LSystems_Growth"]:
		check(bridge.set_hall(hall),"Known hall accepted: "+hall)
		await process_frame
		var state: Dictionary = bridge.get_state()
		states.append(state)
		check(state.habitat.ladder.stage==hall,"Habitat and sculpture use the same hall")
		check(not bridge.is_processing(),"Waiting does not advance the map's state")
		check(bridge.sculpture.get_state().samples==archive.samples,"Walk archive survives map progression")
		check(bridge.sculpture.model.seed==7 and bridge.habitat.seed==7,"The specimen keeps its seed")
		for i in range(5):
			check(bridge.sculpture._form_bodies[i].get_instance_id()==ids[i],"Form identity survives map progression")
			check(bridge.sculpture._form_bodies[i].scale==Vector3.ONE,"Bodies keep unit scale")
		check(bridge._supports.size()==5,"Each map replaces rather than accumulates supports")
		var old_poses: Array = state.banners.poses.duplicate(true)
		for frame in range(260): bridge._process(.1)
		check(bridge.get_state().banners.poses==old_poses,"Time beyond the old loop duration leaves the hall unchanged")
	check(not states[0].banners.poses[0].visible and states[0].habitat.counts.tree==0,"Point One shows no future panels or trees")
	check(states[1].banners.poses[0].visible and states[1].banners.poses[0].lift_m==0,"Triangle hall introduces an unraised face")
	check(states[2].banners.poses[0].lift_m==2.35 and states[2].banners.poses[0].yaw==0,"Translation raises without borrowing rotation")
	check(not states[2].banners.poses[0].colour and not states[2].banners.poses[0].pattern,"Translation has no premature colour or pattern")
	check(is_equal_approx(float(states[3].banners.poses[0].yaw),PI*.25),"Rotation changes orientation")
	check(states[4].banners.poses[0].size[0] < states[3].banners.poses[0].size[0],"Scale changes width")
	check(states[5].banners.poses[0].colour and not states[5].banners.poses[0].pattern,"Colour arrives before pattern")
	check(states[6].banners.poses[0].pattern,"Tiling grants patterns")
	check(states[8].banners.poses[0].pattern and states[8].habitat.counts.tree>0,"Later trees retain the earlier patterned form")
	var last: Dictionary = bridge.get_state()
	check(not bridge.set_hall("nonexistent_hall"),"Unknown hall rejected")
	check(bridge.get_state().evolution==last.evolution,"Unknown hall preserves current state")
	bridge.set_hall("Point_Triangle_Context")
	check(not bridge.get_state().banners.poses[0].pattern and bridge.get_state().banners.poses[0].lift_m==0,"An explicit earlier-hall review shows its own capabilities")
	var scene: Node3D = load("res://commons/artifacts/biome_inheritance/biome_inheritance.tscn").instantiate()
	scene.apply_grid_config({"stage":"Trans_Translation"})
	root.add_child(scene)
	check(scene.get_state().evolution.stage=="Trans_Translation","Map configuration selects the stage before instancing")
	check(not scene.is_processing(),"The shipped scene does not run the preview loop")
	scene.free()
	DirAccess.make_dir_recursive_absolute("res://ada_run/biome_inheritance/evolution")
	var file := FileAccess.open("res://ada_run/biome_inheritance/evolution/probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failed,"states":states},"  "))
	file.close()
	print("[biome_map_evolution] %d checks, %d failed" % [checks,failed])
	bridge.free()
	quit(1 if failed else 0)
