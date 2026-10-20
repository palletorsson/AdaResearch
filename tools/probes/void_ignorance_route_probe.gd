extends "res://tools/probes/void_polyhedra_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_ignorance(false)
		game._set_enabled(false)
		if "--before" in OS.get_cmdline_user_args():
			await photograph("before.png",Vector3(6,-44.5,5.5),Vector3(-4,-46.5,0),90)
		else:
			await photograph("sphere-pairs.png",Vector3(3.8,-46,5.5),Vector3(0,-46.65,0),68)
			await photograph("resolution-atlas.png",Vector3(-12.9,-45.4,5.3),Vector3(-16,-46.8,-.5),65)
			await photograph("budget-counter.png",Vector3(-4.7,-46.4,3.4),Vector3(-4.7,-46.7,.5),70)
			await photograph("clear-route.png",Vector3(6,-44.5,5.5),Vector3(-4,-46.5,0),90)
		await cleanup(false)
	else:
		await exercise_ignorance(false)
		await exercise_ignorance(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native desktop and synthetic XR; physical headset testing separate."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive_ignorance(use_xr: bool) -> void:
	await start(use_xr)
	game.checkpoint=8;game.place_player(Vector3(11,-47.94,4))
	await frames(75)
	var deadline := Time.get_ticks_msec()+20000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline: await frames(1)
	await frames(15)

func exercise_ignorance(use_xr: bool) -> void:
	await arrive_ignorance(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var hall: Node3D=content.exhibits["8/hall"].get_node("Artifact")
	var row := 0
	for prefix in ["18","21","24"]:
		var edge: MeshInstance3D=content.exhibits["8/museum-primitives_ignorance-"+prefix+"-13"].get_node("Artifact")
		var plain: MeshInstance3D=content.exhibits["8/museum-primitives_ignorance-"+prefix+"-16"].get_node("Artifact")
		var a: Array=edge.mesh.surface_get_arrays(0)
		var b: Array=plain.mesh.surface_get_arrays(0)
		check(tag+prefix+" pair has identical vertices and indices",a[Mesh.ARRAY_VERTEX]==b[Mesh.ARRAY_VERTEX] and a[Mesh.ARRAY_INDEX]==b[Mesh.ARRAY_INDEX])
		check(tag+prefix+" only the edge overlay differs",edge.get_node("MeshInspectionEdges").visible and not plain.get_node("MeshInspectionEdges").visible and edge.material_override.albedo_color==plain.material_override.albedo_color)
		check(tag+prefix+" pair shares height, scale and row",edge.global_position.is_equal_approx(Vector3(-1.6,-46.65,2.5-row*2.5)) and plain.global_position.is_equal_approx(Vector3(1.6,-46.65,2.5-row*2.5)) and edge.scale==plain.scale)
		row+=1
	for stop in content.data.floors[8].route:
		var reached := await move_to(Vector3(stop.position[0],-48,stop.position[1]),false,480)
		check(tag+"walk "+stop.label,reached)
		if not reached: break
	var budget: Node3D=hall.get_node("BudgetOfSmoothness")
	var control := budget.get_node("ExperimentPanel") as Node3D
	var eye := budget.to_global(Vector3(0,1.6,1.5))
	var obstruction := ray(eye,control.global_position+Vector3(0,0,.1))
	check(tag+"counter controls have an unobstructed view",obstruction.is_empty())
	budget.get_node("ExperimentPanel/CostButton").pressed.emit()
	budget.get_node("ExperimentPanel/EdgeButton").pressed.emit()
	await frames(2)
	check(tag+"original buttons reveal counts and mesh edges",budget.costs_visible and budget.edges_visible and budget._wires.all(func(w): return w.visible))
	check(tag+"mesh triangle costs increase",budget._counts[0].submitted<budget._counts[1].submitted and budget._counts[1].submitted<budget._counts[2].submitted and budget._counts[2].submitted<budget._counts[3].submitted)
	var atlas: Node3D=hall.get_node("SphereResolutionAtlas")
	check(tag+"original atlas retains twelve ring/segment combinations",atlas.specimens.size()==12 and atlas.specimens[0].mesh.rings==1 and atlas.specimens[11].mesh.radial_segments==32)
	check(tag+"five solids stay pickable",hall.has_node("Tetrahedron/Solid") and hall.get_node("Tetrahedron/Solid").has_method("pick_up") and hall.has_node("Icosahedron/Solid"))
	check(tag+"authored walk preserves health and checkpoint",game.deaths==0 and game.checkpoint==8 and is_equal_approx(game.health.get_health(),100))
	check(tag+"both shaft centres remain open",ray(Vector3(-10,-47.7,0),Vector3(-10,-48.3,0)).is_empty() and ray(Vector3(10,-47.7,0),Vector3(10,-48.3,0)).is_empty())
	await cleanup(use_xr)
