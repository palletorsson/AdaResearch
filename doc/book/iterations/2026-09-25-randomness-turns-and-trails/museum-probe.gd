extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	for n in museum.find_children("*MushroomHand*","Node3D",true,false):n.visible=false
	match map_id:
		"Random_Rotate_Random_XYZ":await rotation_field_checks()
		"Random_Gaussian":await gaussian_checks()

func rotation_field_checks() -> void:
	var field := find_scene("/SlopeGradientCubes.gd")
	check("tilt field is present in actual museum",field!=null)
	if field==null:return
	field.set_process(false)
	field._process(0)
	var poses: Array=[]
	for c in field._cubes:poses.append(c.transform)
	field._process(1.7)
	var unchanged: bool=true
	for i in field._cubes.size():unchanged=unchanged and poses[i].is_equal_approx(field._cubes[i].transform)
	observations["field"]={"grid_size":str(field.grid_size),"cube_count":field._cubes.size(),"animate_slope":field.animate_slope,"unchanged_after_update":unchanged,"world_position":xyz(field.global_position),"scale":xyz(field.scale)}
	check("this placed field is static",not field.animate_slope and unchanged)
	var compact: bool=field.has_meta("compact_study")
	var outside: int=0
	var bounds := AABB()
	var first: bool=true
	for c in field._cubes:
		var mesh: MeshInstance3D=c.find_child("CubeBaseMesh",true,false)
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
		if box.position.x<1.0 or box.end.x>12.0 or box.position.z<1.0 or box.end.z>15.0:outside+=1
	observations["field"]["world_bounds"]=str(bounds)
	observations["field"]["outside_interior"]=outside
	if compact:
		var floor_hit := floor_at(Vector3(9.5,0.1,13.5))
		check("field is wholly above the actual floor",not floor_hit.is_empty() and bounds.position.y >= floor_hit.position.y - 0.005)
		observations["field"]["floor_height"] = floor_hit.get("position",Vector3.ZERO).y
		check("all 25 cubes lie inside the hall",field._cubes.size()==25 and outside==0)
		check("first and last rows are level",absf(field._cubes[0].rotation.x)<0.00001 and absf(field._cubes[4].rotation.x)<0.00001)
		check("middle row reaches thirty degrees",is_equal_approx(absf(field._cubes[2].rotation.x),deg_to_rad(30)))
	else:check("baseline field extends beyond the hall",outside>0)
	await snapshot("tilt-field",Vector3(10.8,1.7,13.3),Vector3(6,0.42,13),65)
	if compact:
		var original=load("res://algorithms/randomness/SlopeGradientCubes.tscn").instantiate()
		original.position=Vector3(1000,1000,1000);root.add_child(original);original.set_process(false)
		check("other placements retain seven by thirty",original.grid_size==Vector2i(7,30) and original._cubes.size()==210)
		original.queue_free()

func gaussian_checks() -> void:
	var sampler := find_scene("/distribution_sampler.gd")
	check("sampler cabinet is present in actual museum",sampler!=null)
	if sampler==null:return
	sampler.set_running(false)
	sampler._clear_samples()
	sampler.batch(300)
	var values: PackedFloat32Array=sampler.landed_values().duplicate()
	check("three batches retain 300 values",values.size()==300)
	var bins: int=sampler.num_bins
	var plate: Node3D=sampler._readout.get_parent()
	var mark: Node3D=sampler.find_child("StandingPosition",true,false)
	check("compact console has a marked standing place",mark!=null)
	if mark==null:return
	var eye: Vector3=mark.global_position+Vector3.UP*1.7
	observations["readout"]={"world":xyz(plate.global_position),"standing_eye":xyz(eye),"lines":sampler.readout_lines(),"plate_local":xyz(plate.position)}
	await snapshot("sampler-standing",eye,sampler.to_global(Vector3(0,1.05,0)),52)
	await snapshot("sampler-readout",eye,plate.global_position,30)
	await snapshot("sampler-overview",eye,sampler.to_global(Vector3(-0.2,1.05,0.2)),72)
	var button_3: Node=sampler._stand_panel.find_child("Btn_3",true,false).get_node("InteractableAreaButton")
	button_3.button_pressed.emit(button_3)
	check("BINS button regroups the retained values",sampler.num_bins!=bins and sampler.landed_values()==values)
	var width: float=sampler.gaussian_std
	var button_4: Node=sampler._stand_panel.find_child("Btn_4",true,false).get_node("InteractableAreaButton")
	button_4.button_pressed.emit(button_4)
	check("WIDTH button changes spread and clears values",not is_equal_approx(sampler.gaussian_std,width) and sampler.landed_values().is_empty())
	observations["width_cycle"]={"before":width,"after":sampler.gaussian_std}

	var original = load("res://commons/artifacts/distribution_sampler/distribution_sampler.tscn").instantiate()
	original.position=Vector3(1000,1000,1000)
	original.apply_grid_config({"stand":"cabinet"})
	root.add_child(original)
	original.set_running(false)
	check("other cabinets retain the original readout",not original._readout_wing and is_equal_approx(original._readout.get_parent().position.x,0.0))
	original.batch(100)
	var before_relayout: PackedFloat32Array=original.landed_values().duplicate()
	original.apply_grid_config({"readout":"wing"})
	check("readout can move after ready without clearing values",original._readout_wing and original._readout.get_parent().position.x < -0.8 and original.landed_values()==before_relayout)
	original.queue_free()
