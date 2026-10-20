extends "res://tools/probes/void_ignorance_route_probe.gd"
var floor_index := -1
var floor_y := 0.0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_columns(false)
		game._set_enabled(false)
		await photograph("overview.png",Vector3(6,floor_y+3.3,3.6),Vector3(-3,floor_y+2,-3.5),90)
		await photograph("sides.png",Vector3(0,floor_y+2.4,1.5),Vector3(0,floor_y+2.3,-5.5),100)
		await photograph("outlines.png",Vector3(-13.4,floor_y+2.4,1.5),Vector3(-18.5,floor_y+2.2,0),105)
		await photograph("heights.png",Vector3(13.3,floor_y+2.4,1.5),Vector3(18.5,floor_y+2.2,0),105)
		await photograph("profile-divisions.png",Vector3(0,floor_y+1.8,-1),Vector3(0,floor_y+1.7,5.5),100)
		await cleanup(false)
	else:
		await exercise_columns(false)
		await exercise_columns(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive_columns(use_xr: bool) -> void:
	await start(use_xr)
	for i in game.building.content.data.floors.size():
		if game.building.content.data.floors[i].map=="Primitives_Columns": floor_index=i
	assert(floor_index>=0)
	floor_y=-6.0*floor_index
	game.checkpoint=floor_index;game.place_player(Vector3(11,floor_y+.06,4))
	await frames(75)
	var deadline := Time.get_ticks_msec()+20000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline: await frames(1)
	await frames(15)

func exercise_columns(use_xr: bool) -> void:
	await arrive_columns(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var hall: Node3D=content.exhibits[str(floor_index)+"/hall"].get_node("Artifact")
	var families := {"sides":[],"divisions":[],"outline":[],"height":[],"composition":[]}
	for group in hall.get_children():
		if not group.has_meta("comparison"): continue
		families[group.get_meta("comparison")].append(group)
		var column: Node3D=group.get_node("Column")
		var box: AABB=column.column_mesh.get_aabb()
		check(tag+str(group.name)+" actual mesh reaches its stated height",absf(box.position.y)<.0001 and absf(box.size.y-column.column_height)<.0001)
		check(tag+str(group.name)+" real column meets the ceiling",absf(group.position.y+column.position.y+box.end.y-5.64)<.001 and group.position.y>=0)
		var expected: int=column.radial_segments*(10*column.profile_rings+26)
		var actual := 0
		for surface in column.column_mesh.get_surface_count():
			actual+=column.column_mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()/3
		check(tag+str(group.name)+" mesh and collider share the sampling budget",actual==expected and column.triangle_count==actual and column.body.get_child(0).shape.get_faces().size()==actual*3)
	for family in families:
		check(tag+family+" has five separately editable specimens",families[family].size()==5 and families[family].all(func(n): return hall.part_defaults.has(str(n.name))))
	var counts := [4,6,8,12,16]
	for i in 5:
		var sides: Node3D=families.sides[i].get_node("Column")
		var rings: Node3D=families.divisions[i].get_node("Column")
		var outline: Node3D=families.outline[i].get_node("Column")
		var height_column: Node3D=families.height[i].get_node("Column")
		check(tag+"sides "+str(counts[i])+": only angular sampling changes",sides.radial_segments==counts[i] and sides.profile_rings==8 and sides.profile_kind==0 and is_equal_approx(sides.column_height,5.42) and sides.width_factor==1)
		var angles := {}
		for vertex in sides.column_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if absf(vertex.y)<.0001 and Vector2(vertex.x,vertex.z).length()>.1:
				angles[Vector2i(roundi(vertex.x*10000),roundi(vertex.z*10000))]=true
		check(tag+"sides "+str(counts[i])+": count actual corners",angles.size()==counts[i])
		check(tag+"divisions "+str(counts[i])+": only profile sampling changes",rings.profile_rings==counts[i] and rings.radial_segments==16 and rings.profile_kind==0 and is_equal_approx(rings.column_height,5.42) and rings.width_factor==1)
		var heights := {}
		for vertex in rings.column_mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX]: heights[roundi(vertex.y*100000)]=true
		check(tag+"divisions "+str(counts[i])+": count actual section levels",heights.size()==counts[i]+1)
		check(tag+"outline "+str(i)+": height, width and sampling fixed",outline.profile_kind==i and outline.radial_segments==16 and outline.profile_rings==8 and is_equal_approx(outline.column_height,5.42) and outline.width_factor==1)
		check(tag+"height "+str(i)+": same body repeats to the ceiling",height_column.profile_kind==0 and height_column.radial_segments==16 and height_column.profile_rings==8 and is_equal_approx(height_column.column_height,5.42) and height_column.width_factor==1)
		var base: Node3D=families.height[0].get_node("Column")
		var equal_normalized := true
		for surface in 9:
			var a: PackedVector3Array=base.column_mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var b: PackedVector3Array=height_column.column_mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for v in a.size():
				equal_normalized=equal_normalized and Vector3(a[v].x,a[v].y/base.column_height,a[v].z).is_equal_approx(Vector3(b[v].x,b[v].y/height_column.column_height,b[v].z))
		check(tag+"height "+str(i)+": same actual outline after normalizing height",equal_normalized)
		if i>0:
			check(tag+"outline "+str(i)+": different actual vertex profile",outline.column_mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX]!=families.outline[i-1].get_node("Column").column_mesh.surface_get_arrays(2)[Mesh.ARRAY_VERTEX])
	for stop in content.data.floors[floor_index].route:
		var reached := await move_to(Vector3(stop.position[0],floor_y,stop.position[1]),false,1500)
		check(tag+"walk "+stop.label,reached)
		if not reached: break
	check(tag+"route preserves health and checkpoint",game.deaths==0 and game.checkpoint==floor_index and is_equal_approx(game.health.get_health(),100))
	check(tag+"both shaft centres remain open",ray(Vector3(-10,floor_y+.3,0),Vector3(-10,floor_y-.3,0)).is_empty() and ray(Vector3(10,floor_y+.3,0),Vector3(10,floor_y-.3,0)).is_empty())
	check(tag+"original foundation film retained",content.exhibits.has(str(floor_index)+"/museum-primitives_columns-14-1"))
	# The same part isolation used by lab-editor copies must preserve mesh and physics.
	for family in families:
		var original: Node3D=families[family][2]
		var copy: Node3D=hall.get_script().new();copy.hall="columns";copy.position=Vector3(0,10,0)
		root.add_child(copy)
		copy.apply_grid_config({"only_parts":[str(original.name)],"parts":{str(original.name):{"position":[0,0,0],"rotation":[0,90,0]}}})
		await frames(3)
		var part: Node3D=copy.get_node(NodePath(str(original.name)))
		check(tag+family+" copy contains only the requested movable part",copy.get_child_count()==1 and part.position==Vector3.ZERO and is_equal_approx(part.rotation_degrees.y,90))
		check(tag+family+" copy retains source mesh, card and collision",part.get_node("Column").triangle_count==original.get_node("Column").triangle_count and part.get_node("Column").body!=null and part.has_node("Plaque_Column"))
		copy.free()
	await cleanup(use_xr)
