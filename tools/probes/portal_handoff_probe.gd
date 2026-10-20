extends "res://tools/probes/portal_arrivals_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_portals(false);game._set_enabled(false)
		var span: Node3D=game.building.content.exhibits[str(floor_index)+"/sky-walk"].get_node("Artifact")
		var study: Node3D=span.get_node("ProfileToRing")
		await photograph("profile-open.png",Vector3(-15.7,floor_y+2.65,7.1),Vector3(-15.7,floor_y+1.13,4.5),55)
		study.advance_path();study.toggle_section()
		await photograph("profile-closed.png",Vector3(-15.7,floor_y+2.65,7.1),Vector3(-15.7,floor_y+1.13,4.5),55)
		await photograph("entrance.png",Vector3(-19.5,floor_y+2.4,7.6),Vector3(-12.5,floor_y+1.7,1),79)
		await photograph("limit-table.png",Vector3(4.3,floor_y+2.2,3.4),Vector3(0,floor_y+1.1,5.7),70)
		await photograph("inside-the-rings.png",Vector3(-16,floor_y+2.65,.5),Vector3(31,floor_y+3.2,.5),80)
		game.place_player(Vector3(26,floor_y+1.06,.5));await frames(90)
		await photograph("arrivals.png",Vector3(25.5,floor_y+2.65,2.4),Vector3(28.4,floor_y+1.8,0),75)
		await cleanup(false)
	else:
		for mode in [false,true]:
			await exercise_sweep(mode)
			await exercise_span(mode)
			await exercise_arrivals(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot desktop and synthetic XR physics; real pointer event dispatch. No physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func click_button(study: Node3D, title: String) -> void:
	var area: Node3D=study.get_node(title+"/InteractableAreaButton")
	XRToolsPointerEvent.pressed(game.camera,area,area.global_position)
	XRToolsPointerEvent.released(game.camera,area,area.global_position)
	await frames(3)

func mesh_topology(mesh: ArrayMesh) -> Dictionary:
	var vertices: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var points: Dictionary={};var edges: Dictionary={};var degenerate:=false
	for i in range(0,vertices.size(),3):
		var ids: Array[int]=[]
		for j in 3:
			var key:=Vector3i((vertices[i+j]*100000).round())
			if not points.has(key): points[key]=points.size()
			ids.append(points[key])
		if (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).length()<.00000001:degenerate=true
		for j in 3:
			var edge:=Vector2i(mini(ids[j],ids[(j+1)%3]),maxi(ids[j],ids[(j+1)%3]))
			edges[edge]=edges.get(edge,0)+1
	return {"closed":edges.values().all(func(n):return n==2),"euler":points.size()-edges.size()+vertices.size()/3,"degenerate":degenerate}

func exercise_sweep(use_xr: bool) -> void:
	await arrive_portals(use_xr)
	var tag:="XR: " if use_xr else "Desktop: "
	var span: Node3D=game.building.content.exhibits[str(floor_index)+"/sky-walk"].get_node("Artifact")
	var study: Node3D=span.get_node("ProfileToRing")
	for title in ["PathButton","SectionButton","ResetButton"]:
		var control: Node3D=study.get_node(title)
		var area: Area3D=control.get_node("InteractableAreaButton")
		var ray:=PhysicsRayQueryParameters3D.create(control.global_position+Vector3(0,.4,0),control.global_position,1048576)
		ray.collide_with_areas=true;ray.collide_with_bodies=false
		var hit:=game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(tag+title+" has an upward cap and reachable pointer area",control.global_basis.y.dot(Vector3.UP)>.99 and not hit.is_empty() and hit.collider==area)
	var chase: Node3D=game.building.content.exhibits[str(floor_index)+"/hall"].get_node("Artifact/AchillesAndTortoise")
	check(tag+"limit experiment buttons clear the tabletop",chase.get_node("ExperimentPanel").global_position.y-floor_y-.41>.9)
	check(tag+"carried I section starts with a capped 270-degree path",study.section.glyph=="I" and study.turn_degrees==270 and not study.body.mesh.get_meta("loop"))
	var original: Dictionary=load("res://commons/artifacts/glyph_profile_gallery/profile_sweep.gd").profile(load(study.FONT_PATH),"I")
	check(tag+"identical glyph vertices and faces from Profiles",study.section.points==original.points and study.section.faces==original.faces)
	var topo:=mesh_topology(study.body.mesh)
	check(tag+"open arc is a closed nondegenerate solid with two caps",topo.closed and topo.euler==2 and not topo.degenerate)
	await click_button(study,"PathButton")
	check(tag+"pointer press closes path while retaining I",study.turn_degrees==360 and study.section.glyph=="I" and study.body.mesh.get_meta("loop"))
	topo=mesh_topology(study.body.mesh)
	check(tag+"joined seam is watertight with one through-hole",topo.closed and topo.euler==0 and not topo.degenerate)
	await click_button(study,"SectionButton")
	check(tag+"round section retains the closed path",study.round_profile and study.turn_degrees==360 and study.section.boundary.size()==32)
	topo=mesh_topology(study.body.mesh)
	check(tag+"round sweep is a watertight torus",topo.closed and topo.euler==0 and not topo.degenerate)
	var arrays: Array=study.body.mesh.surface_get_arrays(0)
	var outward:=true
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		var p: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		var radial:=Vector3(p.x,0,p.z).normalized()
		if (p-radial*.69).normalized().dot(arrays[Mesh.ARRAY_NORMAL][i])<.98:outward=false;break
	check(tag+"torus normals face outwards",outward)
	await click_button(study,"PathButton")
	check(tag+"quarter arc changes only the path",study.turn_degrees==90 and study.round_profile and not study.body.mesh.get_meta("loop"))
	await click_button(study,"ResetButton")
	check(tag+"reset restores the carried I and open path",study.turn_degrees==270 and not study.round_profile)
	game.place_player(Vector3(11,floor_y+.06,4));await frames(15)
	for stop in game.building.content.data.floors[floor_index].route:
		var reached: bool=await move_to(Vector3(stop.position[0],floor_y,stop.position[1]),false,600)
		check(tag+"approach: "+stop.label,reached)
		if not reached:print("BLOCKED ",game.body.global_position);break
	check(tag+"approach remains on the Portals floor without damage",game.deaths==0 and game.health.get_health()==100)
	var copy: Node3D=load("res://commons/void/portal_span.tscn").instantiate();game.add_child(copy)
	copy.apply_grid_config({"only_parts":["ProfileToRing"],"parts":{"ProfileToRing":{"position":[1,0,0],"rotation":[0,90,0]}}})
	await frames(5)
	var twin: Node3D=copy.get_node("ProfileToRing")
	await click_button(twin,"PathButton")
	check(tag+"editor copy is independent after moving and turning",copy.get_child_count()==1 and twin.position==Vector3(1,0,0) and is_equal_approx(twin.rotation_degrees.y,90) and twin.turn_degrees==360 and study.turn_degrees==270)
	copy.queue_free();await frames(5)
	await cleanup(use_xr)
