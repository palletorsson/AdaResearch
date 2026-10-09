extends "res://tools/probes/transformation_encounters.gd"

func press(panel:Node,index:int) -> void:
	var area:Node=panel.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	area.button_pressed.emit(area)

func ray(work:Node3D,a:Vector3,b:Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(work.to_global(a),work.to_global(b),1)
	var player:CollisionObject3D=museum.get("_player")
	if player!=null:query.exclude=[player.get_rid()]
	return hall.get_world_3d().direct_space_state.intersect_ray(query)

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(0.8).timeout
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var after:bool=spec.get("after",false)
	if map_id=="CA_ExpandingSpace":
		var study:=find_scene("/proximity_study.gd")
		check("bridge study present",study!=null)
		if study==null:return
		var work:Node3D=study.work
		study.set_process(false)
		check("initial source is the visitor",study.source_mode==0)
		press(study.console,3)
		check("one SOURCE press selects PROBE / NEAR",study.source_mode==1 and study.probe_near and study.source_label.text=="PROBE / NEAR")
		press(study.console,1)
		check("RUN starts the selected experiment",study.running)
		press(study.console,1)
		check("second RUN press holds",not study.running)
		var initial:float=work.grid[study.WITNESS]
		press(study.console,0)
		check("near probe lowers witness health",work.grid[study.WITNESS]<initial)
		var back:MeshInstance3D=study.get_node("FriezeBack")
		var hit:Dictionary=ray(work,Vector3(2.6,1.4,3.6),Vector3(3.5,1.4,3.6))
		observations["frieze_hit"]=str(hit.collider.get_path()) if not hit.is_empty() else "none"
		if after:
			check("fixed frieze backing stops a body-layer ray",not hit.is_empty() and back.is_ancestor_of(hit.collider))
			check("floor sign directs to the desk side",study.get_node("BasinNote").text=="BASIN 0.60 m BELOW\nRAMPS ON RIGHT / DESK SIDE")
			for name_ in ["BasinNote","WitnessTag"]:
				var label_:Label3D=study.get_node(name_)
				check(name_+" upright for arrival along local +Z",label_.basis.y.dot(Vector3.FORWARD)<-0.99 and label_.basis.z.dot(Vector3.UP)>0.99)
		else:check("before: frieze has no backing collision",hit.is_empty())
		check("shared coloured panels remain visual only",study.get_node("HealthPanel_2_6").find_children("*","CollisionShape3D",true,false).is_empty())
		check("wall W uses the floor cell material",study.get_node("HealthPanel_2_6").material_override==work.materials[study.WITNESS])
		check("gold wall address retained",study.get_node_or_null("FriezeWitnessTag")!=null)
		check("both recovery ramps remain",study.get_node_or_null("EntryRecovery")!=null and study.get_node_or_null("ExitRecovery")!=null)
		await snapshot("arrival-directions",work.to_global(Vector3(0,1.65,-2.0)),work.to_global(Vector3(0,0.15,1.5)),85)
		await snapshot("witness-and-frieze",work.to_global(Vector3(-0.7,1.65,2.0)),work.to_global(Vector3(1.1,0.6,3.6)),90)
		if after:
			for coord in work.grid:work.grid[coord]=0.0
			work._update_visuals()
			await tick();await tick()
			hit=ray(work,Vector3(2.6,1.4,3.6),Vector3(3.5,1.4,3.6))
			check("backing persists when every bridge tile is depleted",not hit.is_empty() and back.is_ancestor_of(hit.collider))
			check("depleted W no longer supports",work.colliders[study.WITNESS].disabled)
			var walker:CharacterBody3D=museum.get("_player")
			check("museum walker available",walker!=null)
			if walker!=null:
				museum.set("_player",null);walker.set_physics_process(false);walker.set_process(false)
				walker.global_position=work.to_global(Vector3(2.65,0.05,3.6));walker.velocity=Vector3.ZERO
				for i in range(75):
					walker.velocity=work.global_basis*Vector3(1.0,-0.2,0);walker.move_and_slide();await physics_frame
				var end_:Vector3=work.to_local(walker.global_position)
				observations["walker_blocked_local"]=xyz(end_)
				check("actual body cannot pass through fixed frieze",end_.x<3.06 and end_.x>2.5)
			study.full_reset()
	else:
		var study:=find_scene("/exchange_study.gd")
		check("exchange study present",study!=null)
		if study==null:return
		study.set_process(false)
		check("seed crossing retained",study.get_node_or_null("WalkSeed")!=null)
		check("initial labels withhold the exchange answer",study.left_title.text=="A" and study.right_title.text=="B")
		check("W initially has no V on either field",study.left.v[study.WITNESS]==0.0 and study.right.v[study.WITNESS]==0.0)
		for side in range(2):
			var frame:Node3D=study.get_node("WitnessX_%d_-1"%side)
			var table:Node3D=study.get_node("TableField_%d"%side)
			check("gold frame on table "+str(side),absf(frame.position.x-table.position.x)<0.8 and absf(frame.position.z-table.position.z)<0.8 and absf(frame.position.y-table.position.y)<0.02)
		await snapshot("table-witness",study.to_global(Vector3(2.5,1.65,-0.85)),study.to_global(Vector3(2.35,0.96,0.45)),62)
		await snapshot("exchange-before-naming",study.to_global(Vector3(0,1.65,-0.6)),study.to_global(Vector3(0,2.1,4.25)),94)
		press(study.console,0)
		check("STEP brings V to W only with exchange",study.left.v[study.WITNESS]>0.0 and study.right.v[study.WITNESS]==0.0)
		press(study.console,4)
		check("EXCHANGE B reveals rendered titles",study.left_title.text=="A / EXCHANGE ON" and study.right_title.text=="B / EXCHANGE ON" and study.left_title.is_visible_in_tree() and study.right_title.is_visible_in_tree())
		check("EXCHANGE B resets both fields",study.left.ticks==0 and study.right.ticks==0)
		press(study.console,0)
		check("matched exchange gives matching fields",study.left.v==study.right.v and study.left.u==study.right.u)
		await snapshot("exchange-after-naming",study.to_global(Vector3(0,1.65,-0.6)),study.to_global(Vector3(0,2.1,4.25)),94)
		press(study.console,2)
		check("replay retains the discovered relation",study.left_title.text=="A / EXCHANGE ON" and study.right_title.text=="B / EXCHANGE ON")
		observations["revealed_titles"]=[study.left_title.text,study.right_title.text]

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Focused native museum tests, supplied console signals/body motion/cameras. No headset readability or Quest profiling claim."},"  "))
	print("CA BODY / EXCHANGE ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
