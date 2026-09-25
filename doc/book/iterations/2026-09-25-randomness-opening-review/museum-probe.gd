extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	for n in museum.find_children("*MushroomHand*", "Node3D", true, false): n.visible=false
	observations["loaded_tile"]=hall.get_meta("em_tile",[])
	match map_id:
		"Random_Entropy":await entropy_checks()
		"Random_Remove":await removal_checks()
		"Randomness_10_PRINT_Algorithm":await print_checks()
	# Let queued museum resources leave the tree before SceneTree shutdown.
	museum.queue_free()
	await process_frame
	await process_frame

func entropy_checks() -> void:
	var ruin := find_scene("/entropy_ruin.gd")
	check("ruin exists in the actual museum",ruin!=null)
	if ruin==null:return
	ruin.set_process(false)
	check("runtime field has no interior template piers",no_interior_piers())
	observations["arrival"]={"running":ruin.running,"displaced":ruin.history.size(),"readout":ruin.readout.text}
	var revised := FileAccess.get_file_as_string("res://commons/artifacts/randomness_space/entropy_ruin.gd").contains("@export var autostart")
	if revised:
		check("map opts out of autostart",not ruin.autostart)
		check("visitor arrives before any stone falls",not ruin.running and ruin.history.is_empty())
		for i in 900:ruin._process(0.1)
		check("ninety supplied seconds leave the ruin intact",ruin.history.is_empty())
	else:
		check("baseline starts without the visitor",ruin.running)
		for i in 750:ruin._process(0.1)
		check("baseline has already dismantled its upper courses",ruin.history.size()==84)
		await snapshot("ruin-unattended",ruin.to_global(Vector3(-1.9,1.7,-5.0)),ruin.to_global(Vector3(0,1.5,0.2)),60)
		ruin.restore()
	await snapshot("ruin-waiting",ruin.to_global(Vector3(-1.9,1.7,-5.0)),ruin.to_global(Vector3(0,1.5,0.2)),60)
	var one: Node=ruin.find_child("Btn_1",true,false)
	one.pressed.emit()
	check("ONE STONE leaves 115 pieces in place and one displaced",ruin.history.size()==1 and ruin.pieces.size()==116 and not ruin.running)
	var first: int=ruin.history[0]
	check("single stone lands with collision restored",ruin.pieces[first].age<0 and ruin.pieces[first].body.collision_layer==1)
	ruin.find_child("Btn_2",true,false).pressed.emit()
	check("RESTORE returns all 116 stones and waits",ruin.history.is_empty() and not ruin.running and ruin.pieces.all(func(p):return p.node.transform.is_equal_approx(p.home)))
	one.pressed.emit()
	check("RESTORE repeats the first seeded choice",ruin.history[0]==first)
	ruin.find_child("Btn_0",true,false).pressed.emit()
	check("RUN resumes the ruin",ruin.running)
	for i in 180:ruin._process(0.1)
	await snapshot("ruin-after-choices",ruin.to_global(Vector3(-1.9,1.7,-5.0)),ruin.to_global(Vector3(0,1.5,0.2)),60)
	ruin.find_child("Btn_0",true,false).pressed.emit()
	var held: int=ruin.history.size()
	for i in 100:ruin._process(0.1)
	check("PAUSE holds the number displaced",ruin.history.size()==held)
	observations["after_choices"]={"displaced":held,"total":ruin.pieces.size()}
	check("approach retains museum floor",not floor_at(ruin.to_global(Vector3(0,0,-3.2))).is_empty())
	if revised:
		var legacy=load("res://commons/artifacts/randomness_space/entropy_ruin.gd").new()
		legacy.position=Vector3(1000,1000,1000);root.add_child(legacy);legacy.set_process(false)
		check("unconfigured placements retain the running default",legacy.autostart and legacy.running)
		legacy.queue_free()

func removal_checks() -> void:
	var arena := find_scene("/removal_arena.gd")
	check("owned removal floor exists",arena!=null)
	if arena==null:return
	var player: Node3D=museum.get("_player")
	check("desktop museum body exists",player!=null)
	if player==null:return
	player.set_physics_process(false);player.set_process(false)
	player.global_position=arena.to_global(Vector3(0,0.2,-6))
	await tick();await tick()
	arena.reset_arena();await tick()
	check("all 99 cells begin with support",arena.get_state().remaining==99 and arena.get_state().disabled_colliders==0)
	await snapshot("floor-before-entry",arena.to_global(Vector3(-3.4,1.7,-6.0)),arena.to_global(Vector3(0,0,1)),68)
	player.global_position=arena.to_global(Vector3(0,0.2,-4))
	await create_timer(0.25).timeout
	check("actual body entering the zone requests removal",arena.entered and arena.get_state().busy)
	await create_timer(1.0).timeout
	check("entry removes one cell and its collider",arena.get_state().remaining==98 and arena.get_state().disabled_colliders==1)
	player.global_position=arena.to_global(Vector3(0.7,0.2,-4))
	await create_timer(1.3).timeout
	check("moving the body 0.7 m requests another cell",arena.get_state().remaining==97 and arena.get_state().disabled_colliders==2)
	var held: int=arena.get_state().remaining
	await create_timer(1.0).timeout
	check("standing still does not remove another cell",arena.get_state().remaining==held)
	var gone: Array=[]
	for i in arena.colliders.size():
		if arena.colliders[i].disabled:gone.append(i)
	observations["entry_and_step"]={"remaining":held,"removed_indices":gone,"state":arena.get_state()}
	await snapshot("floor-after-entry",arena.to_global(Vector3(-3.4,1.7,-6.0)),arena.to_global(Vector3(0,0,1)),68)
	check("apron still supports the visitor",not floor_at(arena.to_global(Vector3(-5,0,0))).is_empty())
	player.global_position=arena.to_global(Vector3(0,0.2,-6));await tick();await tick()
	arena.find_child("Btn_0",true,false).pressed.emit();await tick()
	check("REPLAY restores all 99 colliders",arena.get_state().remaining==99 and arena.get_state().disabled_colliders==0)
	check("runtime tile has no interior template piers",no_interior_piers())

func no_interior_piers() -> bool:
	var tile: Array=hall.get_meta("em_tile",[])
	var count: int=0
	var authored: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
	for z in range(1,authored.layers.structure.size()-1):
		for x in range(1,tile[z].size()-1):
			if str(tile[z][x]).begins_with("4"):count+=1
	observations["interior_wall_cells"]=count
	return count==0

func print_checks() -> void:
	var structures: Array=[]
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/ten_print_structure.gd"):structures.append(n)
	check("both floor and wall print structures are loaded",structures.size()==2)
	var wall: Node3D
	var floor_field: Node3D
	for n in structures:
		if n.form=="wall":wall=n
		if n.form=="floor":floor_field=n
	check("map's wall field replaces the stale screen",wall!=null and find_scene("/science_screen.gd")==null)
	if wall==null:return
	check("wall has four columns and three rows",wall.get_dims()==Vector2i(4,3))
	check("all twelve wall slabs are printed",wall.get_cells().size()==12)
	check("each wall slab has a collision shape",wall.solid_body()!=null and wall.solid_body().get_child_count()==12)
	check("walls are 2.4 m high",is_equal_approx(wall.slab_height(),2.4))
	observations["wall"]={"dimensions":str(wall.get_dims()),"slab_height":wall.slab_height(),"cells":str(wall.get_cells()),"position":xyz(wall.global_position)}
	await snapshot("printed-walls",wall.to_global(Vector3(2.2,1.7,5.4)),wall.to_global(Vector3(2.2,1.4,1.2)),72)
	await snapshot("inside-printed-walls",wall.to_global(Vector3(0.15,1.7,1.3)),wall.to_global(Vector3(2.4,1.3,1.65)),72)
	if floor_field!=null:
		check("floor field shows seven rows",floor_field.get_dims().y==7)
		check("floor field receives the hall printer",floor_field.linked_interface()!=null)
		check("printed floor remains without collision",floor_field.solid_body()==null)
		await snapshot("printed-floor",floor_field.to_global(Vector3(4.7,1.7,4.8)),floor_field.to_global(Vector3(4.7,0.1,1.5)),72)
