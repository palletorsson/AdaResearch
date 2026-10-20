extends "res://tools/probes/transformation_encounters.gd"

func clear_person(p: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=0.3;shape.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	query.transform=Transform3D(Basis(),p+Vector3.UP*0.95)
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var doors=find_scene("/ordinary_entropies/door_study.gd")
	var guess=find_scene("/ordinary_entropies/one_guess.gd")
	check("installed door wrapper resolves to interactive study",doors!=null)
	check("installed min-entropy ID resolves to One guess",guess!=null)
	if doors==null or guess==null:return
	check("three doorways in wall retained",doors.get_node_or_null("DoorWall")!=null and doors.versions.size()==3)
	check("four chair tables installed",guess.versions.size()==4)
	check("both independently placed at full scene scale",doors.scale.is_equal_approx(Vector3.ONE) and guess.scale.is_equal_approx(Vector3.ONE))
	for step in 16:
		doors.advance_doors(step);await physics_frame
		for z in [-2.5,-1.0,0,1.0,2.5]:
			var p: Vector3=doors.to_global(Vector3(0,0,z))
			check("centre doorway clear step %d z %s" % [step,z],clear_person(p) and not floor_at(p).is_empty())
	for local in [Vector3(2.25,0,1.25),Vector3(-4.5,0,3.3),Vector3(4.5,0,3.3)]:
		var p: Vector3=doors.to_global(local)
		check("door control/history approach "+str(local),clear_person(p) and not floor_at(p).is_empty())
	var area=doors.buttons.STEP.get_node("InteractableAreaButton")
	doors.reset_study();area.button_pressed.emit(area);await process_frame;await process_frame
	check("installed STEP callback works",doors.step_index==1)
	doors.advance_doors(7)
	await snapshot("doors-in-hall",doors.to_global(Vector3(0,2.0,6.0)),doors.to_global(Vector3(0,1.2,0)),105)
	for i in 4:
		var table=guess.versions[i]
		var p: Vector3=table.to_global(Vector3(0,0,2.0))
		check("table approach clear and supported "+str(i),clear_person(p) and not floor_at(p).is_empty())
		for x in [-1.35,1.35]:
			for z in [-1.05,1.05]:check("table corner has floor %d %s %s" % [i,x,z],not floor_at(table.to_global(Vector3(x,0,z))).is_empty())
		check("table contains sixteen actual chairs "+str(i),table.chairs.size()==16)
		await snapshot("table-"+str(i+1),table.to_global(Vector3(0,1.7,3.1)),table.to_global(Vector3(0,0.7,0)),64)
	var b=guess.versions[1]
	b.buttons["BLACK+ARMS"].get_node("InteractableAreaButton").button_pressed.emit(b.buttons["BLACK+ARMS"].get_node("InteractableAreaButton"))
	await process_frame;await process_frame
	b.buttons.DRAW.get_node("InteractableAreaButton").button_pressed.emit(b.buttons.DRAW.get_node("InteractableAreaButton"))
	await process_frame;await process_frame
	check("installed guess precedes installed draw",b.model.guess==2 and b.model.draws==1)
	await snapshot("chairs-in-hall",guess.to_global(Vector3(0,2.2,5.2)),guess.to_global(Vector3(0,0.8,0)),108)
	observations["doors"]={"step":doors.step_index,"gap":doors.GAPS[doors.gap_index],"position":xyz(doors.global_position)}
	observations["tables"]=[]
	for table in guess.versions:observations.tables.append(table.model.readings())
	observations["scope"]="Installed scene, canonical button path, supported approaches and centre doorway. Headset interaction/comfort untested."
