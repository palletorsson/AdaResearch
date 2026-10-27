extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	if level == 1: await volume_checks(tag)
	else: await tiling_checks(tag)

func flight_input(direction: Vector3, strength := 1.0) -> void:
	if direction.length()<.001:
		axes(Vector2.ZERO)
		return
	var up := Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP))>.98 else Vector3.UP
	var view := Basis.looking_at(direction,up)
	if load("res://commons/movement/museum_flight_box.gd").at_point(root.get_tree(),game.body.global_position)==null:
		if xr:
			var rig: Node3D=game.get_node("XROrigin3D")
			left.set_pose("aim",Transform3D(rig.global_basis.inverse(),Vector3(-.3,1.2,-.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		var walking: Vector3=game.body.global_basis.inverse()*direction.normalized()*strength
		axes(Vector2(walking.x,walking.z))
		return
	if xr:
		var origin: Node3D=game.get_node("XROrigin3D")
		left.set_pose("aim",Transform3D(origin.global_basis.inverse()*view,origin.to_local(game.body.global_position+Vector3(-.3,1.2,-.4))),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		left.set_input("primary",Vector2(0,strength))
	else:
		game.camera.global_basis=view
		game.body.drive=Vector2(0,-strength)

func fly_to(target: Vector3, limit := 300) -> bool:
	for i in limit:
		var offset: Vector3=target-game.body.global_position
		# Ground feet settle below the requested spawn clearance; use the same
		# walking tolerance as move_to after the flight provider releases.
		var outside: bool=load("res://commons/movement/museum_flight_box.gd").at_point(root.get_tree(),game.body.global_position)==null
		var reached: bool=Vector2(offset.x,offset.z).length()<.16 and absf(offset.y)<.16 if outside else offset.length()<.09
		if reached:
			flight_input(Vector3.ZERO);await frames(3);return true
		flight_input(offset,clampf(offset.length()*3,.25,1))
		await frames(1)
		if game.recovering:break
	flight_input(Vector3.ZERO)
	print("FLIGHT TARGET ",target," ACTUAL ",game.body.global_position)
	return false

func volume_checks(tag: String) -> void:
	var lab: Node3D=artifact("array_flight_lab")
	var flight: Node3D=lab.enclosure
	var score: int=root.get_node("GameManager").player_score
	check(tag+"original 64 addressed cubes and twelve-metre enclosure",lab.grid.get_child_count()==64 and lab.values.size()==4 and flight.edge_length==12)
	check(tag+"flight roof clears the trial ceiling at source scale",flight.to_global(Vector3(0,12,0)).y < game.building.spec.levels[0]-.36)
	var panel: Node3D=control_panel(lab)
	await approach(panel,2.2)
	await press(panel._items[0].node)
	await press(panel._items[1].node)
	await press(panel._items[2].node)
	check(tag+"three actual index buttons select [1,1,1]",lab.selected==Vector3i.ONE)
	for i in 3:await press(panel._items[0].node)
	check(tag+"X index wraps without changing Y or Z",lab.selected==Vector3i(0,1,1))
	game.place_player(flight.to_global(Vector3(0,.06,-6.9)));await frames(12)
	check(tag+"outside door uses ordinary gravity",flight.at_point(root.get_tree(),game.body.global_position)==null)
	check(tag+"walk through original doorway activates flight",await fly_to(flight.to_global(Vector3(0,.06,-5))))
	check(tag+"fly above normal storey height",await fly_to(flight.to_global(Vector3(0,8.4,-5))))
	var hovered: Vector3=game.body.global_position
	await frames(35)
	check(tag+"neutral input hovers and keeps collection live",game.body.global_position.distance_to(hovered)<.03 and game.floor_stream.focus==1 and lab.can_process())
	var cube: Node3D=lab.grid.get_node("Cube_3_3_3")
	var target: Vector3=cube.global_position-Vector3(0,.4,0)
	check(tag+"fly to a high three-axis address",await fly_to(target,430))
	await frames(35)
	check(tag+"real contact empties [3,3,3] while its address remains",lab.values[3][3][3]==0 and not is_instance_valid(cube) and lab.values[3][3].size()==4)
	check(tag+"collection scores only in isolated trial",game.trial_session.score>0 and root.get_node("GameManager").player_score==score)
	check(tag+"return to the ground doorway",await fly_to(flight.to_global(Vector3(0,.15,-5.6)),480))
	check(tag+"leave enclosure through its original door",await fly_to(flight.to_global(Vector3(0,.06,-7)),160))
	await frames(20)
	check(tag+"leaving flight restores walking",flight.at_point(root.get_tree(),game.body.global_position)==null and game.body.is_on_floor() and not game.recovering)
	game.health.reset()
	var open: Node3D=artifact("open_structures")
	await approach(open,9.2)
	check(tag+"open forms retain 25 addressed sites",open.specimen.mode==1 and open.specimen.records.size()==25)
	var origins: Array=open.specimen.records.map(func(r):return r.origin)
	await study_press(open.controls[3])
	check(tag+"RULE changes form assignment at the same sites",open.specimen.alternative and open.specimen.records.map(func(r):return r.origin)==origins and open.specimen.records.all(func(r):return r.form==r.column))
	await study_press(open.controls[0])
	check(tag+"FIVE FORMS retains five distinct constructions",open.specimen.mode==0 and open.specimen.records.size()==5)
	await study_press(open.controls[2])
	check(tag+"STACKS makes the five addressed height rules",open.specimen.mode==2 and open.specimen.records.size()>25)
	await study_press(open.controls[4])
	var hanging: Node3D=artifact("reference_suspension")
	await approach(hanging,9.2)
	var positions: Array=hanging.specimen.evidence.positions.duplicate()
	await study_press(hanging.controls[0])
	check(tag+"SMOOTHER changes fragments without moving 75 addresses",hanging.specimen.amount<1 and hanging.specimen.evidence.positions==positions and positions.size()==75)
	await study_press(hanging.controls[1])
	check(tag+"ROUGHER restores original amount",is_equal_approx(hanging.specimen.amount,1))
	game.place_player(game.spawn_for(1));await frames(12)

func study_press(button: Node3D) -> void:
	var proxy := Node3D.new();button.add_child(proxy)
	var area := Node3D.new();area.name="InteractableAreaButton";proxy.add_child(area)
	var point := Node3D.new();point.name="CollisionShape3D";area.add_child(point)
	await press(proxy);proxy.queue_free()

func tiling_checks(tag: String) -> void:
	var tiles: Node3D=artifact("tiling_principles")
	check(tag+"six original flat fields and linked 16 by 16 study",not tiles.walls and tiles.surfaces.size()==6 and tiles.rule_study.field!=null)
	var global_panel: Node3D=control_panel(tiles)
	var global_button: Node3D=global_panel._items[0].node
	await approach(global_panel,2.2)
	var textures: Array=tiles.surfaces.map(func(n):return n.material_override.albedo_texture.get_image().get_data())
	await press(global_button)
	check(tag+"TURN MOTIF updates all six receiving fields",tiles.phase==1 and range(6).all(func(i):return tiles.surfaces[i].material_override.albedo_texture.get_image().get_data()!=textures[i]))
	textures=tiles.surfaces.map(func(n):return n.material_override.albedo_texture.get_image().get_data())
	await press(global_panel._items[1].node)
	check(tag+"EXCEPTION changes only sixth field",tiles.exception and range(5).all(func(i):return tiles.surfaces[i].material_override.albedo_texture.get_image().get_data()==textures[i]) and tiles.surfaces[5].material_override.albedo_texture.get_image().get_data()!=textures[5])
	var rule: Node3D=tiles.rule_study
	await approach(rule.desk,2.8)
	var before: PackedByteArray=rule.local_texture.get_image().get_data()
	await press(rule.apply_button)
	check(tag+"APPLY changes both small crop and larger field",rule.applied and rule.local_texture.get_image().get_data()!=before and rule.field_texture==rule.field.material_override.albedo_texture)
	await press(rule.apply_button)
	check(tag+"UNDO restores exact original image",not rule.applied and rule.local_texture.get_image().get_data()==before)
	var address: Vector2i=rule.cell
	await press(rule.cell_button)
	check(tag+"NEXT TILE advances one readable address",rule.cell!=address and rule.cell_label.text.contains(str(rule.cell.x)))
	var selected: int=rule.selected
	await press(rule.next_button)
	check(tag+"NEXT RULE changes the instruction",rule.selected==(selected+1)%6)
	if xr:
		var rig: Node3D=game.get_node("XROrigin3D")
		left.set_pose("aim",Transform3D(rig.global_basis.inverse(),Vector3(-.3,1.2,-.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	var a: Vector3=tiles.to_global(Vector3(-3.2,.06,8))
	var b: Vector3=tiles.to_global(Vector3(-3.2,.06,3.4))
	game.place_player(a);await frames(15)
	var walked: bool=await move_to(b)
	if not walked:
		print("WALK VELOCITY ",game.body.velocity)
		for i in game.body.get_slide_collision_count():
			var contact=game.body.get_slide_collision(i)
			print("WALK CONTACT ",contact.get_collider().get_path()," AT ",contact.get_position()," NORMAL ",contact.get_normal())
	check(tag+"floor motifs are walkable flat surfaces",walked and absf(game.body.global_position.y-game.building.spec.levels[level])<.1)
	var monitor: Node3D=artifact("film_tiling_rule")
	await approach(monitor,2.1)
	check(tag+"original monitor has an independent live film",monitor.viewport!=null and monitor.viewport.get_texture()!=null)
	await study_press(monitor.buttons["pause"])
	check(tag+"monitor PLAY pointer changes playback",not monitor.stage.running)
	await study_press(monitor.buttons["pause"])
	check(tag+"monitor resumes playback",monitor.stage.running)
	game.place_player(game.spawn_for(2));await frames(12)

func capture_floor() -> void:
	if level==1:
		var flight: Node3D=artifact("array_flight_lab")
		await photo("01-third-index",flight.to_global(Vector3(-9,6,-12)),flight.to_global(Vector3(0,4,0)))
		var open: Node3D=artifact("open_structures")
		await photo("02-open-structures",open.to_global(Vector3(7,4,10)),open.to_global(Vector3(0,1,0)))
	else:
		var tiles: Node3D=artifact("tiling_principles")
		await photo("03-six-floor-rules",tiles.to_global(Vector3(10,7,-16)),tiles.to_global(Vector3(0,0,-3)))
		await photo("04-one-changed-instruction",tiles.rule_study.desk.to_global(Vector3(1,2.6,5)),tiles.rule_study.desk.to_global(Vector3(0,1.7,0)))

func control_panel(node: Node3D) -> Node3D:
	for child in node.get_children():
		if child.get_script()!=null and child.get_script().resource_path=="res://commons/ui/control_panel.gd":return child
	return null
