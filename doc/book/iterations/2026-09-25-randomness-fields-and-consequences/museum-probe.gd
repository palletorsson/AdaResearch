extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	for n in museum.find_children("*MushroomHand*","Node3D",true,false):n.visible=false
	match map_id:
		"Random_Mushrooms":await mushroom_checks()
		"Random_Space_Geometry":await geometry_checks()
		"Randomness_Examples_of_Randomness":await dart_checks()
		"Random_Pheromone":await pheromone_checks()
		"Random_Space":await space_checks()
		"Random_Game":await game_checks()

func mushroom_checks() -> void:
	var bed := find_scene("/mushrooms.gd")
	check("specimen bed present",bed!=null)
	if bed==null:return
	var leftovers: Array=[]
	for nm in ["Camera3D","FillLight","MeshInstance3D"]:
		if bed.get_node_or_null(nm)!=null:leftovers.append(nm)
	observations["leftovers"]=leftovers
	observations["population"]=bed.get_specimen_state()
	if bed.has_meta("specimen_scene_cleaned"):check("specimen staging removes its three demo leftovers",leftovers.is_empty())
	else:check("baseline contains demo leftovers",leftovers.size()==3)
	check("six templates and three edible mushrooms retained",bed.mushroom_types.size()==6 and bed.edible_count()==3)
	await snapshot("mushroom-bed",bed.to_global(Vector3(3.0,1.7,4.6)),bed.to_global(Vector3(0,0.6,0)),67)
	if bed.has_meta("specimen_scene_cleaned"):
		var before: Array=bed.instances();var ground_before: Dictionary=bed.ground_signature()
		bed.set_size_variation(false)
		var after: Array=bed.instances();var same: bool=before.size()==after.size()
		for i in mini(before.size(),after.size()):
			var a: Dictionary=before[i].duplicate();var b: Dictionary=after[i].duplicate()
			a.erase("scale");b.erase("scale");same=same and a==b
		check("SIZE retains positions, types, yaw and ground",same and ground_before==bed.ground_signature())
		bed.set_size_variation(true)
		check("SIZE returns original population",before==bed.instances())
		var legacy=load("res://algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn").instantiate()
		check("standalone scene retains camera, light and prism",legacy.get_node_or_null("Camera3D")!=null and legacy.get_node_or_null("FillLight")!=null and legacy.get_node_or_null("MeshInstance3D")!=null)
		legacy.free()

func geometry_checks() -> void:
	var bench := find_scene("/perlin_noise_bridge.gd")
	check("comparison bench present",bench!=null)
	if bench==null:return
	observations["bench_world"]=xyz(bench.global_position)
	var supports: Array=[]
	for p in [Vector3(-0.6,0.1,1.3),Vector3(0,0.1,1.3),Vector3(0.6,0.1,1.3)]:
		var hit:=floor_at(bench.to_global(p));supports.append(not hit.is_empty())
	observations["standing_support"]=supports
	check("three standing positions in front of comparison have floor",supports==[true,true,true])
	await snapshot("comparison-approach",bench.to_global(Vector3(-2.4,1.7,3.2)),bench.to_global(Vector3(0,0.9,0)),66)
	await snapshot("neighbouring-columns",bench.to_global(Vector3(0,1.7,1.3)),bench.to_global(Vector3(0,1.07,0)),48)
	var white: Array=[];var coherent: Array=[]
	for c in bench._white_columns:white.append(c.mesh.size.y)
	for c in bench._perlin_columns:coherent.append(c.mesh.size.y)
	bench._frequency*=2;bench._rebuild_grids()
	var same: bool=true;var different: bool=false
	for i in white.size():
		same=same and is_equal_approx(white[i],bench._white_columns[i].mesh.size.y)
		different=different or not is_equal_approx(coherent[i],bench._perlin_columns[i].mesh.size.y)
	check("frequency changes coherent columns while white heights hold",same and different)

func dart_checks() -> void:
	var board:=find_scene("/monte_carlo_dartboard.gd")
	check("dartboard present",board!=null)
	if board==null:return
	board.set_process(false);var n: int=board._total_count;var running: bool=board.auto_throw
	for key in [KEY_SPACE,KEY_D,KEY_R]:
		var event:=InputEventKey.new();event.keycode=key;event.pressed=true;board._input(event)
	check("museum walking keys do not change dart count or AUTO",board._total_count==n and board.auto_throw==running)
	board._throw_dart();check("sampler can still throw",board._total_count==n+1)
	var legacy=load("res://algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.tscn").instantiate()
	var original: bool=legacy.auto_throw;var space:=InputEventKey.new();space.keycode=KEY_SPACE;space.pressed=true;legacy._input(space)
	check("standalone keyboard shortcut remains available",legacy.auto_throw!=original);legacy.free()
	await snapshot("dartboard-in-gallery",board.to_global(Vector3(0,1.7,2.4)),board.to_global(Vector3(0,1.3,0)),65)

func pheromone_checks() -> void:
	var field:=find_scene("/pheromone_terrain.gd")
	check("pheromone field present",field!=null)
	if field==null:return
	check("placed field has four walkers and forty percent guidance",field.walkers.size()==4 and is_equal_approx(field.pheromone_attraction,0.4))
	field.advance_comparison(100)
	observations["guidance"]={"walkers":field.walkers.size(),"probability":field.pheromone_attraction}
	await snapshot("pheromone-visits",field.to_global(Vector3(4,1.7,5)),field.to_global(Vector3(0,0.4,0)),68)

func space_checks() -> void:
	var worley:=find_scene("/worley_noise.gd");var gauge:=find_scene("/shannon_entropy_meter.gd");var floor:=find_scene("/RandomSpace.gd")
	check("Worley, gauge and retained random ground present",worley!=null and gauge!=null and floor!=null)
	if worley==null or gauge==null:return
	check("gauge counts its own two hundred symbols",gauge.sequence_length==200 and gauge._sequence.size()==200)
	observations["positions"]={"worley":xyz(worley.global_position),"gauge":xyz(gauge.global_position),"floor":xyz(floor.global_position)}
	check("cellular field raised above the retained ground",worley.global_position.y>=0.3)
	check("gauge raised to standing reading height",gauge.global_position.y>=1.0)
	await snapshot("cellular-field",Vector3(worley.global_position.x,1.7,worley.global_position.z+1.2),worley.global_position,53)
	await snapshot("returning-gauge",Vector3(gauge.global_position.x,1.7,gauge.global_position.z+2.0),gauge.to_global(Vector3(0,0.3,0)),60)

func game_checks() -> void:
	var podium:=find_scene("/waiting_profile.gd")
	check("waiting podium present",podium!=null)
	if podium==null:return
	podium.set_process(false)
	check("five profile layers remain",podium.profiles.size()==5)
	await snapshot("waiting-and-seeing",podium.to_global(Vector3(0,1.7,-4.4)),podium.to_global(Vector3(0,1.4,0)),68)
