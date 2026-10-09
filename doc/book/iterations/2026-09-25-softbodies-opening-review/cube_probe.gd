extends "res://tools/probes/transformation_encounters.gd"
var desk:Node3D
var cube:Node3D
func press(id:String) -> void:
	var area:Node3D=desk.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.2).timeout
	observations["after_"+id+"_"+str(desk.actions_taken)]=extent(cube._soft_body)
func shot(name:String) -> void:
	await snapshot(name,cube.to_global(Vector3(0.85,0.7,1.1)),cube.to_global(Vector3(0,0.10,0)),48)
func extent(sb:SoftBody3D) -> Array:
	var low:=Vector3(INF,INF,INF);var high:=-low
	for i in sb.mesh.surface_get_array_len(0):
		var p:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),i)
		low=low.min(p);high=high.max(p)
	return [xyz(low),xyz(high)]
func retained(sb:SoftBody3D) -> bool:
	var fixed:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),cube._anchor_index)
	for i in sb.mesh.surface_get_array_len(0):
		var p:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),i)
		if p.distance_to(fixed)>0.65:return false
	return true
func landing_checks() -> void:
	museum.flush_stamps()
	await process_frame
	var loaded_at:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-loaded_at<20000:
		desk=find_scene("/soft_workshop.gd");cube=find_scene("/jelly_cube.gd")
		if desk!=null and cube!=null:break
		await process_frame
	if desk==null or cube==null:
		observations["loaded_scripts"]=[]
		for n in hall.find_children("*","Node3D",true,false):
			if n.get_script()!=null:observations["loaded_scripts"].append(str(n.get_script().resource_path))
	check("cube and its desk placed in the requested hall",desk!=null and cube!=null)
	if desk==null or cube==null:return
	var start:=Time.get_ticks_msec()
	while not desk.ready_for_input and Time.get_ticks_msec()-start<20000:await process_frame
	check("desk bound to cube with six controls",desk.ready_for_input and desk.model==cube and desk.buttons.size()==6)
	if not desk.ready_for_input:return
	var sb:SoftBody3D=cube._soft_body
	var identity:=sb.get_instance_id()
	check("cube uses five solver passes",sb.simulation_precision==5)
	check("initial coefficients match manuscript",is_equal_approx(sb.linear_stiffness,0.5) and is_equal_approx(sb.damping_coefficient,0.01) and is_equal_approx(sb.pressure_coefficient,1.0))
	check("hall holds one upper point with a visible attachment",cube.anchor=="crown" and cube._anchor_index>=0 and sb.is_point_pinned(cube._anchor_index) and cube.get_node_or_null("CrownAnchor")!=null)
	var held_before:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),cube._anchor_index)
	var pin_count:=0
	for i in sb.mesh.surface_get_array_len(0):
		if sb.is_point_pinned(i):pin_count+=1
	check("exactly one mesh point is held",pin_count==1)
	var stem:Node3D=cube.get_node("CrownAnchor")
	check("visible stem ends at the held point",(stem.global_position-stem.global_basis.y*0.025).distance_to(held_before)<0.001)
	check("label clears the support and legacy caption is hidden",cube._info_label.position.y>cube.cube_size+0.2 and not cube.get_node("Label3D").visible)
	observations["initial_extent"]=extent(sb)
	await shot("cube-pressure-one")
	for i in 15:
		await create_timer(0.1).timeout
		observations["initial_tick_"+str(i)]=extent(sb)
	await press("STIFFNESS")
	check("STIFFNESS changes stiffness alone",is_equal_approx(sb.linear_stiffness,0.1) and is_equal_approx(sb.damping_coefficient,0.01) and is_equal_approx(sb.pressure_coefficient,1.0))
	await press("DAMPING")
	check("DAMPING changes damping alone",is_equal_approx(sb.damping_coefficient,0.05) and is_equal_approx(sb.linear_stiffness,0.1))
	await press("RESET")
	check("RESET restores coefficients in the same body",sb.get_instance_id()==identity and is_equal_approx(sb.linear_stiffness,0.5) and is_equal_approx(sb.damping_coefficient,0.01) and is_equal_approx(sb.pressure_coefficient,1.0))
	await press("PRESSURE")
	check("first PRESSURE press sets zero",is_zero_approx(sb.pressure_coefficient))
	await create_timer(3).timeout
	observations["zero_pressure_after_3s_extent"]=extent(sb)
	check("free surface stays within reach of held point at zero pressure",retained(sb))
	await shot("cube-pressure-zero")
	await press("PRESSURE")
	check("next PRESSURE press sets two",is_equal_approx(sb.pressure_coefficient,2.0))
	await create_timer(3).timeout
	observations["pressure_two_after_3s_extent"]=extent(sb)
	check("free surface stays within reach of held point at pressure two",retained(sb))
	await shot("cube-pressure-two")
	await create_timer(10).timeout
	check("body remains near held point after ten more seconds",retained(sb))
	var default_cube:Node3D=load("res://commons/artifacts/jelly_cube/jelly_cube.tscn").instantiate()
	default_cube.position=Vector3(40,2,40)
	root.add_child(default_cube)
	check("unconfigured cube retains free body and original pedestal",default_cube.anchor=="free" and default_cube._anchor_index==-1 and default_cube.get_node_or_null("PedestalCollision")!=null and default_cube.get_node_or_null("HangingSupport")==null)
	default_cube.queue_free()
	check("held point stays fixed through the setting changes",held_before.distance_to(PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),cube._anchor_index))<0.001)
	await snapshot("deformation-hall",cube.to_global(Vector3(2,1.7,4)),cube.to_global(Vector3(0,0.8,-2)),65)
	await press("MILL")
	check("MILL holds drive without disabling the soft bodies",desk.drive_held and desk._bodies(desk.other).size()>0)
	await press("MILL")
	check("MILL releases the drive",not desk.drive_held)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"observations":observations,"failures":failures,"passed":failures.is_empty(),"scope":"Native museum with completed stamp queue; supplied pointer events, solver vertex bounds and original captures. No tracked hand, force feedback or headset acceptance."},"  "))
	quit(0 if failures.is_empty() else 1)
