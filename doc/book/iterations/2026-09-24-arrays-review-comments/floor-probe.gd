extends "res://tools/probes/transformation_encounters.gd"
var writer:Node3D
func landing_checks() -> void:
	seed(240924) # Repeatable fixture; production wandering remains unseeded.
	writer=find_scene("/array_floor_writer.gd")
	check("changing-floor encounter loads",writer!=null)
	if writer==null:return
	await create_timer(0.3).timeout
	check("agent uses actual containing grid",writer.grid!=null and writer.agent.current_grid==writer.grid)
	if writer.grid==null:return
	var grid:Node=writer.grid
	var actor:CharacterBody3D=museum.get("_player")
	actor.set_process(false);actor.set_physics_process(false);actor.global_position=Vector3(-100,0,-100)
	var before:Array=grid.cube_positions.duplicate()
	await create_timer(8).timeout
	check("ordinary loop writes at readable pace",writer.writes>=1 and writer.writes<=3)
	observations["natural_writes_eight_seconds"]=writer.writes
	var buttons:=writer.find_children("InteractableAreaButton","Area3D",true,false)
	check("two native entry controls exist",buttons.size()==2)
	if buttons.size()!=2:return
	XRToolsPointerEvent.pressed(camera,buttons[0],buttons[0].global_position)
	XRToolsPointerEvent.released(camera,buttons[0],buttons[0].global_position)
	await tick()
	check("pointer pauses autonomous writing",not writer.running)
	var held:int=writer.writes;await create_timer(1.0).timeout
	check("paused agent leaves cells unchanged",writer.writes==held)
	writer.agent.grid_cell_position=Vector3i(15,1,17)
	writer.agent._change_state(writer.agent.AgentState.FEEDING)
	for i in 60:writer.agent._process_feeding(1.0/60)
	check("feeding writes once, not once per frame",writer.writes==held+1)
	var removed:Array=[]
	for cell in before:
		if not grid.cube_positions.has(cell) and cell.y==0:removed.append(cell)
	check("actual floor cells consumed",not removed.is_empty())
	if not removed.is_empty():
		var cell:Vector3i=removed[0];var at:Vector3=grid.parent_node.to_global(Vector3(cell))
		var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.8,at+Vector3.DOWN*0.8,1,[writer.agent.get_rid()])
		await tick();await tick()
		var hit:=hall.get_world_3d().direct_space_state.intersect_ray(query)
		check("consumed cell loses its original supporting surface",hit.is_empty() or hit.position.y < at.y+0.1)
		observations["consumed_cell"]=[cell.x,cell.y,cell.z]
		observations["floor_ray_after_removal"]=str(hit)
		# A body in a vacancy keeps RESTORE from materialising through it.
		# Isolate the floor from contact with the paused sphere above that cell.
		var sphere_pose:Transform3D=writer.agent.global_transform
		writer.agent.global_position=Vector3(-110,0,-100)
		observations["body_probe"]="Paused agent moved aside; actual museum body and floor collision retained."
		actor.global_position=at+Vector3.UP*0.54;actor.velocity=Vector3.ZERO
		for i in 70:
			actor.velocity.y-=9.8/60.0;actor.move_and_slide();await physics_frame
		observations["body_feet_after_consumed_cell"]=xyz(actor.global_position)
		check("actual body descends to the remaining lower surface",actor.is_on_floor() and actor.global_position.y < at.y+0.1)
		check("body in vacancy is detected",writer.occupied(cell))
		writer.restore_floor();await create_timer(0.5).timeout
		check("restore waits for occupied vacancy",not grid.has_cube_at(cell.x,cell.y,cell.z) and writer.restoring)
		actor.global_position=Vector3(-100,0,-100);await create_timer(0.6).timeout
		check("restore fills vacancy after departure",grid.has_cube_at(cell.x,cell.y,cell.z) and not writer.restoring)
		await tick();hit=hall.get_world_3d().direct_space_state.intersect_ray(query)
		check("restored floor supports the same address",not hit.is_empty())
		writer.agent.global_transform=sphere_pose
	check("original grid occupancy returns",grid.cube_positions.size()==before.size() and before.all(func(c):return grid.cube_positions.has(c)))
	check("threshold and perimeter cells are outside write domain",not writer.editable(Vector3i(1,0,17)) and not writer.editable(Vector3i(10,0,1)) and not writer.editable(Vector3i(10,0,21)))
	check("Molnár pad is outside the write domain",not writer.editable(Vector3i(12,0,17)) and not writer.editable(Vector3i(10,1,16)))
	var protected:Array=[]
	for cell in before:
		if not writer.editable(cell):protected.append(cell)
	writer.agent.grid_cell_position=Vector3i(15,1,17)
	var start_writes:int=writer.writes
	for i in 5:writer.write_cell(false)
	for i in 3:writer.write_cell(true)
	check("both operations change the real floor",writer.writes>start_writes+5)
	check("protected route remains unchanged",protected.all(func(c):return grid.cube_positions.has(c)))
	for node in root.find_children("*","Node",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
			var hud:CanvasLayer=node.get("_hud")
			if hud!=null:hud.visible=false
	await snapshot("the-written-floor",writer.global_position+Vector3(-4,3,-4),writer.global_position+Vector3(0,0,-1),74)
	await snapshot("restore-at-the-entrance",writer.to_global(Vector3(-3,1.6,-17.2)),writer.to_global(Vector3(-3,1.2,-15)),68)
	XRToolsPointerEvent.pressed(camera,buttons[1],buttons[1].global_position)
	XRToolsPointerEvent.released(camera,buttons[1],buttons[1].global_position)
	await create_timer(0.8).timeout
	check("RESTORE button repairs and pauses",not writer.restoring and not writer.running and writer.changed.is_empty())
	await snapshot("floor-restored",writer.global_position+Vector3(-4,3,-4),writer.global_position+Vector3(0,0,-1),74)
	XRToolsPointerEvent.pressed(camera,buttons[0],buttons[0].global_position)
	XRToolsPointerEvent.released(camera,buttons[0],buttons[0].global_position)
	await tick()
	check("visitor can resume writing",writer.running)
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum; timed observation, supplied pointer events and explicit operation/body-overlap probes. Not headset or learner acceptance."},"  "))
	print("ARRAY FLOOR ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
