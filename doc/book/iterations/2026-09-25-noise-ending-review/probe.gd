extends "res://tools/probes/transformation_encounters.gd"

func values(work: Node3D) -> Array:
	var result: Array = []
	for x in range(-3,4):
		for z in range(-3,4): result.append(work.sample_at(x*0.5,z*0.5))
	return result

func heights(work: Node3D) -> Array:
	var result: Array = []
	for cube in work.noise_field.noise_cubes: result.append(cube.position.y)
	return result

func colours(work: Node3D) -> Array:
	var result: Array = []
	for cube in work.noise_field.noise_cubes: result.append(cube.material_override.albedo_color)
	return result

func press(panel: Node, index: int) -> void:
	var area: Node = panel.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	area.button_pressed.emit(area)

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(0.8).timeout
	var work := find_scene("/SimplexNoise.gd")
	var study := find_scene("/pair_study.gd")
	check("Simplex and the shared comparison are present",work != null and study != null)
	if work == null or study == null: return
	check("both walk-through arches remain",study.arches.size()==2)
	var declared: int = work.seed_value
	var initial: Array = values(work)
	press(work._panel_node,0)
	var regenerated: int = work.current_seed()
	var field: Array = values(work)
	var generator: Dictionary = work.generator_readback()
	var relief: Array = heights(work)
	var finish: Array = colours(work)
	check("actual REGEN signal changes seed",regenerated != declared)
	check("REGEN changes sampled values",field != initial)
	work.apply_grid_config({"readout":"plate"})
	check("readout-only configuration preserves regenerated seed",work.current_seed()==regenerated)
	check("readout-only configuration preserves all 49 sampled values",values(work)==field)
	check("readout-only configuration preserves generator properties",work.generator_readback()==generator)
	check("plate flattens every displayed cube",heights(work).all(func(y):return is_zero_approx(y)))
	check("display colours survive flattening",colours(work)==finish)
	work.apply_grid_config({"readout":"relief"})
	check("return to relief restores all cube heights",heights(work)==relief)
	check("return to relief preserves field",values(work)==field and work.current_seed()==regenerated)
	work.apply_grid_config({})
	work.apply_grid_config({"readout":"relief"})
	work.apply_grid_config({"unrelated":"unchanged"})
	check("empty, unchanged and unrelated configurations preserve generator",work.generator_readback()==generator)
	work.apply_grid_config({"seed":declared+17,"readout":"plate"})
	check("explicit seed and view change remain effective",work.current_seed()==declared+17 and work.readout=="plate")
	check("explicit seed changes the field",values(work)!=field)
	work.apply_grid_config({"seed":declared,"readout":"relief"})
	check("explicit restoration reproduces original field",values(work)==initial)
	press(work._panel_node,0)
	regenerated=work.current_seed();field=values(work)
	study.refresh()
	var arch: Node3D = study.arches[0]
	var arch_values: PackedFloat32Array = arch.raw.duplicate()
	var arch_colours: PackedColorArray = arch.colours.duplicate()
	press(study.get_node("Controls"),1)
	check("actual shared VIEW signal selects plate",study.plate)
	check("shared VIEW preserves regenerated field",work.current_seed()==regenerated and values(work)==field)
	check("arch retains sampled values and colours",arch.raw==arch_values and arch.colours==arch_colours)
	check("plate arch retains its supplied curve",arch.displaced==arch.vertices)
	press(study.get_node("Controls"),1)
	check("shared VIEW restores relief",not study.plate and arch.displaced!=arch.vertices)
	press(study.get_node("Controls"),2)
	check("actual MATCH signal restores declared Simplex field",work.current_seed()==declared and values(work)==initial)
	check("MATCH restores the Perlin seed too",study.pair[1].current_seed()==study.pair[1].seed_value)
	check("matched seeds do not make the two bases equal",values(study.pair[0])!=values(study.pair[1]))
	var fresh: Node3D = load("res://algorithms/randomness/simplexnoise/simplexnoise.tscn").instantiate()
	fresh.apply_grid_config({"seed":12345,"size":4,"readout":"plate","frequency":3.0,"octaves":2,"ramp":"shared"})
	fresh.position=Vector3(0,-100,0);root.add_child(fresh)
	check("configuration before ready retains declared seed and size",fresh.current_seed()==12345 and fresh.noise_field.noise_cubes.size()==16)
	check("configuration before ready retains display and parameters",fresh.readout=="plate" and heights(fresh).all(func(y):return is_zero_approx(y)) and fresh.contract().frequency==3.0 and fresh.octaves==2)
	fresh.queue_free()
	var origin: Vector3 = hall.global_position+Vector3(0,0,4)
	await snapshot("arches-relief",origin+Vector3(6,1.65,4.95),origin+Vector3(6,1.65,8.4),100)
	press(study.get_node("Controls"),1)
	await snapshot("arches-colour",origin+Vector3(6,1.65,4.95),origin+Vector3(6,1.65,8.4),100)
	press(study.get_node("Controls"),1)
	await snapshot("inside-simplex",arch.to_global(Vector3(0,1.65,-0.5)),arch.to_global(Vector3(-1,2.0,0.25)),90)
	observations={"initial_seed":declared,"regenerated_seed":regenerated,"sample_count":field.size(),"final_generator":work.generator_readback(),"arch_count":study.arches.size(),"scope":"Real isolated museum. Supplied actual console signals, config API, sample/geometry readback and native cameras; no headset traversal claim."}

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	print("NOISE ENDING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
