extends "res://tools/probes/transformation_encounters.gd"

func press(desk:Node,key:String) -> void:
	desk.buttons[key].pressed.emit()

func landing_checks() -> void:
	museum.flush_stamps();await create_timer(0.8).timeout
	if map_id == "Fractal_Recursion":
		var square := find_scene("/example_8_2_recursion_vr.gd")
		var rings := find_scene("/example_8_3_recursion_circles_vr.gd")
		var cells := find_scene("/cube_subdivision.gd")
		check("three comparison instruments loaded",square!=null and rings!=null and cells!=null)
		if square==null or rings==null or cells==null:return
		var one:Node=square.find_child("RecursionLesson",true,false)
		var branch:Node=rings.find_child("RecursionLesson",true,false)
		var spend:Node=cells.find_child("RecursionLesson",true,false)
		check("three lesson desks attached",one!=null and branch!=null and spend!=null)
		if one==null or branch==null or spend==null:return
		for i in range(6):press(one,"MORE")
		check("seven allowed calls leave seven squares",square._mesh_instances.size()==7)
		await snapshot("seven-squares",one.to_global(Vector3(1.2,1.65,3.9)),one.to_global(Vector3(0,2.1,0)),70)
		press(one,"COLLAPSE")
		check("collapse keeps all seven stored squares",square._mesh_instances.size()==7 and square.recession=="collapsed")
		await snapshot("seven-coincident",one.to_global(Vector3(1.2,1.65,3.9)),one.to_global(Vector3(0,2.1,0)),70)
		for i in range(4):press(branch,"MORE")
		check("five ring levels leave 341 rings",rings._circles.size()==341)
		for i in range(3):press(branch,"PACKING")
		check("dust cutoff omits requested fifth level",rings.packing=="dust" and rings.depth==5 and rings._circles.size()==85)
		for mode in ["DRILL","SPREAD"]:
			press(spend,mode)
			for i in range(12):press(spend,"SPLIT")
			var deepest:int=0
			for d in cells.cube_depths.values():deepest=maxi(deepest,int(d))
			check(mode+" spends twelve splits on 85 cells",cells.all_cubes.size()==85 and cells.subdivision_count==12)
			check(mode+" depth matches the reading",deepest==(12 if mode=="DRILL" else 3))
			await snapshot(mode.to_lower(),spend.to_global(Vector3(2.4,1.65,3.5)),spend.to_global(Vector3(0,1.6,0)),66)
	else:
		var growth:=find_scene("/recursivetree/recursive_tree.gd")
		var block:=find_scene("/recursive_tree/recursive_tree.gd")
		var grammar:=find_scene("/example_8_9_lsystem_tree_vr.gd")
		check("three differently constructed trees placed",growth!=null and block!=null and grammar!=null)
		if growth==null or block==null or grammar==null:return
		var desk:Node=growth.get_node("TreeLesson")
		check("growth begins with one stationary trunk",growth.segment_count==1 and not growth.add_randomness and not growth.is_growing)
		for i in range(4):press(desk,"GROW")
		check("four binary generations have 31 segments",growth.segment_count==31 and growth.current_depth==4)
		await snapshot("two-descendants",desk.to_global(Vector3(1.2,1.65,4.1)),desk.to_global(Vector3(0,2.1,0)),68)
		press(desk,"ANGLE")
		check("opening angle changes placement without adding segments",growth.segment_count==31 and growth.branch_angle_min==65)
		press(desk,"ANGLE");press(desk,"ANGLE")
		press(desk,"FORKS")
		check("third child raises count to 121",growth.segment_count==121 and growth.branch_count==3)
		await snapshot("three-descendants",desk.to_global(Vector3(1.2,1.65,4.1)),desk.to_global(Vector3(0,2.1,0)),68)
		check("tree branches have no physical support",growth.generated.find_children("*","CollisionObject3D",true,false).is_empty())
		var red_desk:Node=block.get_node("TreeLesson")
		press(red_desk,"STRATA")
		check("red tree strata is a view of its fixed seed",block.aftermath=="strata" and block.random_seed==12345)
		await snapshot("red-tree-strata",red_desk.to_global(Vector3(1.2,1.65,4.1)),red_desk.to_global(Vector3(0,2.1,0)),68)
		observations["grammar_source"]=str(grammar.get_script().resource_path)
		await snapshot("grammar-tree",grammar.global_position+Vector3(2.3,1.65,-3.5),grammar.global_position+Vector3(0,1.8,0),66)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum and supplied existing button signals; interior camera. No headset, controller reach, Quest performance or learner acceptance."},"  "))
	print("FRACTALS OPENING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
