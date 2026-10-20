extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await zone_contract(false)
	if "--capture" not in OS.get_cmdline_user_args(): await zone_contract(true)
	FileAccess.open(out.path_join("capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real tower, collision events and viewport; desktop and synthetic XR. Rendered evidence uses Mobile. Not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func zone_contract(use_xr: bool) -> void:
	await start(use_xr)
	game.checkpoint=5
	game.place_player(game.spawn_for(5));await frames(90)
	var area: Node3D=game.building.content.exhibits["5/surfaces"].get_node("Artifact")
	var zone: Node3D=area.get_node("MeshRevealZone")
	var prefix: String="XR / " if use_xr else "Desktop / "
	check(prefix+"uses the existing museum threshold",zone.get_script().resource_path=="res://commons/artifacts/wireframe_threshold/wireframe_threshold.gd" and area.part_defaults.has("MeshRevealZone"))
	check(prefix+"floor and props do not trigger the zone",root.debug_draw==Viewport.DEBUG_DRAW_DISABLED and zone._inside.is_empty())
	var at: Vector3=zone.global_position
	var outside: Vector3=at+Vector3(0,0,2)
	game.place_player(outside);await frames(20)
	check(prefix+"zone sits on the solid slab away from the shaft",game.body.is_on_floor() and at.x-zone.radius> -21 and at.x+zone.radius< -12.5)
	var clear: bool=true
	var volume:=AABB(at+Vector3(-zone.radius,.05,-zone.radius),Vector3(zone.radius*2,zone.height-.05,zone.radius*2))
	for title in ["FoldedStrip","SharedDiagonal","QuadPlinth","BoundaryPlinth","FourEdges"]:
		var prop: Node3D=area.get_node(title)
		clear=clear and not volume.intersects(prop.global_transform*area._mesh_bounds(prop,prop))
	check(prefix+"standing zone clears the surrounding artifacts",clear)
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("zone.png",Vector3(-20,-27.5,1),Vector3(-17,-29,-3.2),80)
		await photograph("solid.png",at+Vector3(0,1.65,0),Vector3(-12,-28.8,-5.5),85)
	check(prefix+"can walk into the threshold",await move_to(at))
	await frames(10)
	check(prefix+"body entry exposes the real mesh triangles",root.debug_draw==Viewport.DEBUG_DRAW_WIREFRAME and zone._inside.has(game.body.get_instance_id()))
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("wireframe.png",at+Vector3(0,1.65,0),Vector3(-12,-28.8,-5.5),85)
	check(prefix+"can walk out of the threshold",await move_to(outside))
	await frames(10)
	check(prefix+"leaving restores the surfaces",root.debug_draw==Viewport.DEBUG_DRAW_DISABLED and zone._inside.is_empty())
	# The editor duplicates a source part, retaining its collision and labels.
	var copy: Node3D=load("res://commons/void/triangle_surfaces.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["MeshRevealZone"],"parts":{"MeshRevealZone":{"position":[at.x,-30,at.z],"rotation":[0,90,0]}}})
	await frames(10)
	check(prefix+"editor copy retains an independent zone and its instruction",copy.get_child_count()==1 and copy.get_node("MeshRevealZone/Threshold")!=zone.get_node("Threshold") and copy.has_node("MeshRevealZone/Instruction"))
	game.place_player(at);await frames(20)
	check(prefix+"overlapping copies both detect the player",zone._holding and copy.get_node("MeshRevealZone")._holding)
	copy.queue_free();await frames(10)
	check(prefix+"removing one copy leaves the occupied original active",root.debug_draw==Viewport.DEBUG_DRAW_WIREFRAME)
	zone.queue_free();await frames(10)
	check(prefix+"removing the occupied zone restores rendering",root.debug_draw==Viewport.DEBUG_DRAW_DISABLED)
	game.queue_free();await frames(15)
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
