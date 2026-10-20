extends "res://tools/probes/void_columns_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_columns(false)
		game._set_enabled(false)
		await photograph("grove.png",Vector3(6.9,floor_y+1.75,3.6),Vector3(-1,floor_y+2.3,-.3),87)
		await photograph("among-columns.png",Vector3(0,floor_y+1.7,2.7),Vector3(0,floor_y+2.5,-5.5),90)
		await photograph("west-wing.png",Vector3(-16.3,floor_y+1.75,3.7),Vector3(-14.5,floor_y+2.4,-2),90)
		await cleanup(false)
	else:
		await exercise_columns(false)
		await exercise_columns(true)
		await exercise_grove(false)
		await exercise_grove(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
	quit(0 if failed.is_empty() else 1)

func exercise_grove(use_xr: bool) -> void:
	await arrive_columns(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var hall: Node3D=game.building.content.exhibits[str(floor_index)+"/hall"].get_node("Artifact")
	var columns: Array[Node3D]=[]
	for part in hall.get_children():
		if part.has_meta("grove_column"): columns.append(part)
	check(tag+"twenty added columns are separately editable",columns.size()==20 and columns.all(func(n): return hall.part_defaults.has(str(n.name))))
	for part in columns:
		var column: Node3D=part.get_node("Column")
		check(tag+str(part.name)+" collidable body reaches the ceiling",column.body!=null and absf(column.position.y+column.column_mesh.get_aabb().end.y-5.64)<.001)
		var supported := true
		for x in [-.9,.9]:
			for z in [-.9,.9]:
				var query := PhysicsRayQueryParameters3D.create(part.global_position+Vector3(x,.1,z),part.global_position+Vector3(x,-.4,z))
				query.exclude=[part.get_node("Plinth_Column").get_child(0).get_rid()]
				var hit: Dictionary=hall.get_world_3d().direct_space_state.intersect_ray(query)
				supported=supported and not hit.is_empty() and absf(hit.position.y-floor_y)<.02
		check(tag+str(part.name)+" all four support corners sit on actual solid floor",supported)
	# Three passages through the interior, connected by the existing end aisles.
	for x in [0.0,-3.35,3.35]:
		game.place_player(Vector3(x,floor_y+.06,3.7));await frames(15)
		check(tag+"walk north through grove at x="+str(x),await move_to(Vector3(x,floor_y,-3.6),false,600))
		check(tag+"walk south through grove at x="+str(x),await move_to(Vector3(x,floor_y,3.7),false,600))
	check(tag+"grove passages preserve health and checkpoint",game.deaths==0 and game.checkpoint==floor_index and is_equal_approx(game.health.get_health(),100))
	# Newly added specimens support the same part-copy operation as the comparisons.
	var copy: Node3D=hall.get_script().new();copy.hall="columns";copy.position=Vector3(0,10,0)
	root.add_child(copy)
	copy.apply_grid_config({"only_parts":["InteriorColumn_01"],"parts":{"InteriorColumn_01":{"position":[0,0,0],"rotation":[0,90,0]}}})
	await frames(3)
	check(tag+"new grove specimen copies and turns with its collision",copy.get_child_count()==1 and is_equal_approx(copy.get_node("InteriorColumn_01").rotation_degrees.y,90) and copy.get_node("InteriorColumn_01/Column").body!=null)
	copy.free()
	await cleanup(use_xr)
