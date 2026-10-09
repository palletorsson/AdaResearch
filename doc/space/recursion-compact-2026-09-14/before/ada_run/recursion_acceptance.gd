func desk_press(driver: Node, desk: Node3D, id: String) -> void:
	var button: Node3D = desk.buttons[id]
	var stand: Vector3 = button.get_parent().to_global(Vector3(button.position.x, 0.05, 2.92))
	var rec: Dictionary = await driver.press(button, stand)
	check(rec.hover != "nothing", "%s / %s receives desktop pointer input" % [desk.kind,id])
	await get_tree().create_timer(0.14).timeout

func cube_record(cube: Node3D) -> Array:
	var out: Array = []
	for node: Node3D in cube.all_cubes:
		out.append([str(node.position),str(node.scale),cube.cube_depths[node]])
	return out

func review_works(works:Dictionary,seg:Node3D,em:Node3D,cam:Camera3D,vest:int)->void:
	em.set_physics_process(false)
	var desks: Dictionary = {}
	for token in ["fractal_recursion_2","example_8_3_recursion_circles_vr","cube_subdivision","recursive_chair"]:
		var desk: Node3D = works[token].get_node_or_null("RecursionLesson")
		check(desk != null,token+" has its lesson desk")
		if desk == null: return
		desks[desk.kind] = desk
		check(absf(seg.to_local(desk.global_position).y)<0.001,"desk feet meet the museum floor / "+desk.kind)
		check(desk.buttons.size()==6,"six physical controls / "+desk.kind)
	var wall_text := ""
	for label_node: Label3D in seg.find_children("*", "Label3D", true, false):
		wall_text += label_node.text + "\n"
	check("The chair was not simply waiting" in wall_text and "chair was always inside" not in wall_text, "actual wall labels use the current book")
	var light_count := 0
	for lamp: DirectionalLight3D in seg.find_children("*","DirectionalLight3D",true,false):
		if lamp.is_visible_in_tree(): light_count+=1
	check(light_count==0,"standalone demonstration suns do not wash out the shared hall")
	await shot(cam,seg.to_global(Vector3(8.5,1.65,1.2+vest)),seg.to_global(Vector3(8.5,1.6,9+vest)),"entrance",78)
	var driver = load("res://commons/testing/wcn_desktop_driver.gd").new()
	add_child(driver);driver.spawn(seg.to_global(Vector3(8.5,0.05,2+vest)),em)
	await get_tree().create_timer(0.2).timeout
	check(driver.is_ready(),"standalone DesktopPlayer pointer is active inside the museum")
	var square: Node3D = works.fractal_recursion_2
	check(square._mesh_instances.size()==1,"one square waits for input")
	for count in range(2,8):
		await desk_press(driver,desks.one,"MORE")
		check(square._mesh_instances.size()==count,"one call produces %d squares"%count)
	await desk_press(driver,desks.one,"MORE")
	check(square.depth==7,"square desk stops at depth seven")
	await desk_press(driver,desks.one,"LAYOUT")
	check(square._mesh_instances.size()==7 and square.recession=="abreast","layout changes without adding terms")
	await shot(cam,seg.to_global(Vector3(4.5,2.0,1.4+vest)),square.global_position,"one-call-row",68)
	await desk_press(driver,desks.one,"COLLAPSE")
	check(square._mesh_instances.size()==7 and square.recession=="collapsed","collapsed drawing retains all seven terms")
	await desk_press(driver,desks.one,"LESS")
	await desk_press(driver,desks.one,"RULE")
	check(desks.one.show_rule and "d - 1" in desks.one.readout.text,"square source appears on request")
	await desk_press(driver,desks.one,"BEGIN")
	check(square.depth==1 and square.recession=="nested","square returns to its beginning")
	var rings: Node3D = works.example_8_3_recursion_circles_vr
	check(rings._circles.size()==1 and rings.rotation_speed==0,"one face-on ring waits for input")
	for total in [5,21,85,341]:
		await desk_press(driver,desks.branch,"MORE")
		check(rings._circles.size()==total,"four calls produce %d rings"%total)
	for i in range(3): await desk_press(driver,desks.branch,"PACKING")
	check(rings.depth==5 and rings.packing=="dust" and rings._circles.size()==85,"DUST depth five stops on minimum radius, not the depth allowance")
	await desk_press(driver,desks.branch,"PACKING")
	await desk_press(driver,desks.branch,"LESS")
	await desk_press(driver,desks.branch,"PACKING")
	check(rings.packing=="contact" and rings._circles.size()==85,"packing changes geometry while keeping 85 rings")
	await shot(cam,seg.to_global(Vector3(12.5,2.1,0.8+vest)),rings.global_position,"four-calls",64)
	await desk_press(driver,desks.branch,"TURN")
	await get_tree().create_timer(0.4).timeout
	check(rings.rotation_speed>0 and absf(rings._circles[0].node.rotation.z)>0.05,"TURN visibly tumbles the ring plane")
	await desk_press(driver,desks.branch,"TURN")
	check(absf(rings._circles[0].node.rotation.x-PI/2)<0.01,"stopping returns to the face-on comparison")
	await desk_press(driver,desks.branch,"RULE")
	check(desks.branch.show_rule,"ring explanation is available")
	await desk_press(driver,desks.branch,"BEGIN")
	check(rings._circles.size()==1 and rings.packing=="fused","ring beginning restores matched conditions")
	var cube: Node3D = works.cube_subdivision
	check(cube.all_cubes.size()==1 and not cube.is_subdividing,"cube waits instead of spending its budget automatically")
	await desk_press(driver,desks.spend,"DRILL")
	for i in range(12): desks.spend.act("SPLIT")
	check(cube.all_cubes.size()==85 and cube.cube_depths.values().max()==12,"12 concentrated splits: 85 cells, deepest level 12")
	await desk_press(driver,desks.spend,"SPLIT")
	check(cube.subdivision_count==12 and cube.all_cubes.size()==85,"extra split cannot exceed the budget")
	await desk_press(driver,desks.spend,"SPREAD")
	for i in range(12): desks.spend.act("SPLIT")
	check(cube.all_cubes.size()==85 and cube.cube_depths.values().max()==3,"same budget spread across cells reaches level three")
	await shot(cam,seg.to_global(Vector3(6.5,2.2,8+vest)),cube.global_position,"selected-subdivision",60)
	await desk_press(driver,desks.spend,"LOTS")
	for i in range(8): desks.spend.act("SPLIT")
	var first: Array = cube_record(cube)
	await desk_press(driver,desks.spend,"BEGIN")
	for i in range(8): desks.spend.act("SPLIT")
	check(first==cube_record(cube),"the fixed seed exactly replays the selected positions, sizes and depths")
	await desk_press(driver,desks.spend,"RULE")
	check(desks.spend.show_rule,"selected-cell explanation is available")
	var chair: Node3D = works.recursive_chair
	check(chair.step==0 and chair.all_cubes.size()==1 and not chair.is_animating,"chair waits at the uncut cube")
	await desk_press(driver,desks.cut,"NEXT")
	await desk_press(driver,desks.cut,"GHOST")
	check(chair.step==1 and chair.all_cubes.size()==16 and chair._removed_nodes.size()==11,"first cut: 16 retained cells and 11 ghost cells")
	await shot(cam,seg.to_global(Vector3(10.0,1.85,9.3+vest)),chair.global_position+Vector3.UP*1.3,"chair-exclusions",63)
	await desk_press(driver,desks.cut,"SCAR")
	check(chair.step==1 and chair._removed_nodes.size()==11 and chair.removal=="scar","scar preserves the current construction stage")
	await desk_press(driver,desks.cut,"GONE")
	check(chair._removed_nodes.is_empty() and chair.all_cubes.size()==16,"hide the markers without changing retained cells")
	for i in range(4): await desk_press(driver,desks.cut,"NEXT")
	check(chair.step==5 and chair.all_cubes.size()==20,"five authored stages produce twenty parts")
	await desk_press(driver,desks.cut,"NEXT")
	check(chair.step==5 and chair.all_cubes.size()==20,"next does not duplicate armrests after completion")
	await desk_press(driver,desks.cut,"RULE")
	check(desks.cut.show_rule and "No self-call" in desks.cut.readout.text,"chair identifies its authored construction honestly")
	await shot(cam,seg.to_global(Vector3(14.5,1.7,9+vest)),chair.global_position+Vector3.UP*1.0,"chair-built",67)
	await desk_press(driver,desks.cut,"BEGIN")
	check(chair.step==0 and chair.all_cubes.size()==1,"chair can restart cleanly")
	measurements["desktop_input"]=driver.log
	# Walk the middle aisle using the real DesktopPlayer's movement/collision.
	driver.rig.global_position=seg.to_global(Vector3(8.5,0.05,1.3+vest))
	driver.aim_at(seg.to_global(Vector3(8.5,1.6,23+vest)))
	var moved: Vector3 = await driver.walk("ui_up",270)
	check(moved.z>12 and absf(driver.rig.global_position.y-seg.global_position.y)<0.2,"visitor walks more than twelve metres along the central aisle")
	measurements["aisle_displacement"]=str(moved)
	driver.rig.set_physics_process(false)
	# Leave representative states for the final collection photograph.
	square.apply_grid_config({"depth":6,"recession":"abreast"})
	rings.apply_grid_config({"depth":4,"packing":"open"});desks.branch.face_rings()
	desks.cut.chair_at(5);desks.cut.refresh()
	await get_tree().create_timer(1.0).timeout
	await shot(cam,seg.to_global(Vector3(8.5,2.4,3+vest)),seg.to_global(Vector3(8.5,1.7,12+vest)),"collection",80)
	await shot(cam,seg.to_global(Vector3(8.5,1.8,16+vest)),seg.to_global(Vector3(4.5,2.1,22+vest)),"retained-collection",75)
