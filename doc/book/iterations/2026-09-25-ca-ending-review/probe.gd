extends "res://tools/probes/transformation_encounters.gd"

func press(panel:Node,i:int) -> void:
	var area:Node=panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
	area.button_pressed.emit(area)

func landing_checks() -> void:
	museum.flush_stamps();await create_timer(0.8).timeout
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if map_id=="CA_AgentsCircuits":
		var work:=find_scene("/ca_rule_explorer.gd")
		var study:=find_scene("/neighbour_study.gd")
		check("explorer and current floor comparison loaded",work!=null and study!=null and study.floor_history!=null)
		if work==null or study==null:return
		press(work._control_panel,1);press(work._control_panel,4)
		for i in range(15):press(study.get_node("StudyControls"),0)
		check("Rule 90 comparison retains fifteen generations",work.neighbourhood_readback().generation==15)
		await snapshot("remembered-gap",study.floor_history.to_global(Vector3(0,1.65,-3.6)),study.floor_history.to_global(Vector3(0,0,0)),86)
		press(study.get_node("StudyControls"),0)
		check("Rule 90 single seed vanishes on step sixteen",work._current_row.all(func(v):return not v))
		for number in [222,190]:
			work._rule_slider.set_normalized_value(float(number)/255.0)
			work._rule_slider.slider_moved.emit(Vector3.ZERO)
			press(work._control_panel,4)
			check("actual slider selects "+str(number),work.rule==number)
			var rows:Array=[]
			for i in range(35):
				press(study.get_node("StudyControls"),0);rows.append(work._current_row.duplicate())
			observations[str(number)+"_rows"]=rows
			if number==222:
				check("222 settles with one dark address",rows[31]==rows[32] and rows[34].count(false)==1)
				await snapshot("one-dark-address",work.to_global(Vector3(0,0.85,2.5)),work.to_global(Vector3(0,0,0)),72)
		press(work._control_panel,2)
		check("110 preset exists",work.rule==110)
	else:
		var study:=find_scene("/difference_study.gd")
		check("difference study loaded",study!=null)
		if study==null:return
		study.set_process(false)
		var shape:=BoxShape3D.new();shape.size=Vector3(2.8,2.8,2.8)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
		query.transform=Transform3D(Basis(),study.to_global(Vector3(-2.8,1.85,1.6)))
		var hits:Array=hall.get_world_3d().direct_space_state.intersect_shape(query,16)
		observations["volume_region_colliders"]=hits.map(func(h):return str(h.collider.get_path()))
		check("current authored volume region is clear of piers",hits.is_empty())
		await snapshot("volume-and-pier",study.to_global(Vector3(-0.5,1.65,-1.7)),study.to_global(Vector3(-2.8,1.85,1.6)),70)
		await snapshot("inside-comparison",study.to_global(Vector3(0,1.65,-0.7)),study.to_global(Vector3(0,2.2,5.5)),94)
		press(study.console,6);press(study.console,8)
		check("chapter beginning uniform/no drive",study.model.disturbance==0.0 and not study.model.scattered and study.model.coupling==0.25)
		press(study.console,0)
		check("integer storage removes initial difference",study.model.report().different==0)
		press(study.console,9);press(study.console,0)
		var d:Dictionary=study.model.report()
		check("fractional storage spreads to 27 addresses",d.different==27)
		check("fractional maximum is 0.75",is_equal_approx(d.max_difference,0.75))
		var before:PackedFloat64Array=study.model.a.duplicate();var clock:int=study.model.tick
		press(study.console,10)
		check("slice selection changes neither time nor values",study.model.tick==clock and study.model.a==before)
		for i in range(10):press(study.console,10)
		await snapshot("fractional-difference",study.to_global(Vector3(0,1.65,2.8)),study.to_global(Vector3(-2,2.5,6.5)),91)
		press(study.console,4);press(study.console,0)
		check("zero pull retains one undiminished difference",study.model.report().different==1 and is_equal_approx(study.model.report().max_difference,1.0))
		press(study.console,3);press(study.console,7)
		for i in range(4):press(study.console,0)
		check("matched runs remain equal under shared drive",study.model.a==study.model.b)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum, supplied slider/button signals, collision query and interior camera. No headset, Quest or learner acceptance."},"  "))
	print("CA ENDING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
