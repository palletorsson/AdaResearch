extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	var agent: Node3D = find_scene("/grid_agent_base.gd")
	check("secondary grid agent is instantiated",agent!=null)
	if agent==null:return
	observations["agent_position"]=xyz(agent.global_position)
	observations["initial_grid"]=str(agent.current_grid.get_path()) if agent.current_grid!=null else "null"
	observations["initial_state"]=agent.current_state
	var grid:Node=agent.current_grid
	if grid==null:
		await create_timer(5).timeout
		observations["grid_after_wait"]=str(agent.current_grid.get_path()) if agent.current_grid!=null else "null"
		await snapshot("grid-agent-current",agent.global_position+Vector3(-3,2,-3),agent.global_position,65)
		return
	var before:Array=grid.cube_positions.duplicate()
	await create_timer(8).timeout
	var after:Array=grid.cube_positions.duplicate()
	var removed:Array=[];var added:Array=[]
	for cell in before:
		if not after.has(cell):removed.append([cell.x,cell.y,cell.z])
	for cell in after:
		if not before.has(cell):added.append([cell.x,cell.y,cell.z])
	observations["natural_eight_seconds"]={"removed":removed,"added":added,"agent_cell":str(agent.grid_cell_position)}
	agent.set_physics_process(false)
	var cells:Array=grid.cube_positions.duplicate()
	agent.grid_cell_position=Vector3i(15,1,17);agent.state_timer=0
	agent._process_feeding(1.0/60)
	await tick();await tick()
	var forced:Array=[]
	for cell in cells:
		if not grid.cube_positions.has(cell):forced.append([cell.x,cell.y,cell.z])
	observations["supplied_feeding_at_source_cell"]=forced
	await snapshot("grid-agent-current",agent.global_position+Vector3(-3,2,-3),agent.global_position,65)
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"scope":"Diagnostic of the current secondary agent, not acceptance; natural observation then explicitly supplied feeding."},"  "))
	quit(0 if failures.is_empty() else 1)
