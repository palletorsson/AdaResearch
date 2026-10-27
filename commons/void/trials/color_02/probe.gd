extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	check(tag+"standard tower dimensions retained",game.building.spec.width==42 and game.building.spec.depth==32 and game.building.spec.storey_height==6)
	if level==1:await nails_checks(tag)
	else:await rainbow_checks(tag)

func mouse_grip() -> void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=true
	Input.parse_input_event(e);await frames(8)
	e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=false
	Input.parse_input_event(e);await frames(8)

func nails_checks(tag: String) -> void:
	# Ready and colour propagation await idle frames. A batch of physics steps
	# can happen before a single render frame on this GPU, so wait explicitly.
	for i in 6:await frames(1)
	var salon: Node3D=artifact("nail_salon")
	var nails: Node3D=artifact("nail_color_controller")
	var skin: Node3D=artifact("hand_color_controller")
	var manager: Node=root.get_node("GameManager")
	check(tag+"giant and petite use the same original hand mesh",salon.giant.mesh==salon.petite.mesh and salon.nail_materials.size()==2 and salon.skin_materials.size()==2)
	check(tag+"separate controls retain salon mounts and target surfaces",nails.target_surface==0 and skin.target_surface==1 and not nails.get_node("MeshInstance3D").visible and not skin.get_node("MeshInstance3D").visible)
	var mapper: Node3D=nails.value_mapper
	var point: Node3D=mapper.point
	await approach(nails,1.0)
	var before: Vector3=point.global_position
	if xr:
		hand_at(right,before);await frames(15);right.set_input("grip",1.0);await frames(15)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(before);await frames(15);await mouse_grip()
	check(tag+"real grip picks up the original RGB point",point.is_picked_up() if xr else game.body.desktop_pointer._held==point)
	# Capture the other channel after approach/grab, once the source's async
	# startup has settled. This tests cross-talk during manipulation, not loading.
	var prior_skin: Color=skin.get_nail_color()
	if xr:hand_at(right,before+mapper.global_basis*Vector3(.15,-.12,.08))
	else:game.camera.rotate_y(.18)
	await frames(22)
	check(tag+"moving the point changes colour on both display hands",point.global_position.distance_to(before)>.02 and salon.nail_materials.all(func(m):return m.albedo_color.is_equal_approx(nails.get_nail_color())))
	check(tag+"nail movement leaves the other RGB point unchanged",skin.get_nail_color().is_equal_approx(prior_skin))
	if xr:right.set_input("grip",0.0);await frames(12)
	else:await mouse_grip()
	check(tag+"released RGB point remains bounded",not point.is_picked_up() and point.position.x>=0 and point.position.x<=.5 and point.position.y>=0 and point.position.y<=.5 and point.position.z>=0 and point.position.z<=.5)
	for i in 6:await frames(1)
	var nail_colour: Color=manager.get_nail_color()
	await approach(skin,1.0)
	point=skin.value_mapper.point;before=point.global_position
	if xr:
		hand_at(right,before);await frames(15);right.set_input("grip",1.0);await frames(15)
	else:
		game.camera.look_at(before);await frames(15);await mouse_grip()
	check(tag+"real grip picks up the skin RGB point",point.is_picked_up() if xr else game.body.desktop_pointer._held==point)
	if xr:hand_at(right,before+skin.value_mapper.global_basis*Vector3(-.12,.1,.1))
	else:game.camera.rotate_y(-.18)
	for i in 12:await frames(1)
	check(tag+"skin grip updates both display hands without changing nails",point.global_position.distance_to(before)>.02 and salon.skin_materials.all(func(m):return m.albedo_color.is_equal_approx(skin.get_nail_color())) and manager.get_nail_color().is_equal_approx(nail_colour))
	if xr:right.set_input("grip",0.0);await frames(12)
	else:await mouse_grip()
	if xr:
		check(tag+"original controller finds both tracked player hand materials",nails.nail_material_left!=null and nails.nail_material_right!=null and skin.nail_material_left!=null and skin.nail_material_right!=null)
		check(tag+"player nails carry the selected colour",nails.nail_material_left!=null and nails.nail_material_right!=null and nails.nail_material_left.albedo_color.is_equal_approx(nail_colour) and nails.nail_material_right.albedo_color.is_equal_approx(nail_colour))
	var balls: Node3D=artifact("colorballs")
	check(tag+"original salon case and 24 physical colour balls are present",balls.ball_bodies.size()==24 and balls.ball_count==24 and balls.get_meta("config_case")=="salon")
	check(tag+"balls stay inside their case below world zero",balls.ball_bodies.all(func(b):return balls.to_local(b.global_position).y>=0 and balls.to_local(b.global_position).y<2.3))
	var escaped: RigidBody3D=balls.ball_bodies[0]
	escaped.global_position=balls.to_global(Vector3(0,-3,0))
	PhysicsServer3D.body_set_state(escaped.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,escaped.global_transform)
	await frames(12)
	check(tag+"API escaped ball resets into this case, not world origin",balls.to_local(escaped.global_position).y>0 and balls.to_local(escaped.global_position).y<2.3 and absf(balls.to_local(escaped.global_position).x)<1.2 and absf(balls.to_local(escaped.global_position).z)<1.2)
	var wall: Node3D=artifact("brick_wall_factory")
	check(tag+"source miniature brick wall keeps all palette samples",wall.get_children().filter(func(n):return n is MeshInstance3D).size()==wall.wall_width*wall.wall_height and is_equal_approx(wall.scale.x,.4))
	game.place_player(game.spawn_for(1));await frames(12)

func point_press(parent: Node3D) -> void:
	var proxy:=Node3D.new();parent.add_child(proxy)
	var area:=Node3D.new();area.name="InteractableAreaButton";proxy.add_child(area)
	var target:=Node3D.new();target.name="CollisionShape3D";area.add_child(target)
	await press(proxy);proxy.queue_free()

func rainbow_checks(tag: String) -> void:
	var rainbow: Node3D=artifact("rainbow")
	var party: Node3D=rainbow._celebration
	check(tag+"original celebration assembly and five walk pickups",party!=null and party.walk_pickups.get_child_count()==5 and party.tiles.size()==14)
	check(tag+"source starts with six bands",party.arch.rainbow_colors.size()==6 and party.mode_index==0)
	var support: Transform3D=party.get_node("CandyStep_0").global_transform
	await approach(party.get_node("PartyControls"),1.8)
	for count in [7,48,2,6]:
		await press(party.buttons[0])
		check(tag+"RE-DIVIDE selects %d bands at fixed width"%count,party.arch.rainbow_colors.size()==count and is_equal_approx(party.arch._band_thickness()*count,5.6) and party.get_node("CandyStep_0").global_transform==support)
	var celebrations: int=party.celebration_count
	await press(party.buttons[1])
	check(tag+"CELEBRATE repeats confetti independently of collection",party.celebration_count==celebrations+1 and party.confetti.visible and party.confetti.multimesh.instance_count==96 and party.collected_cubes==0)
	game.place_player(party.to_global(Vector3(0,.06,4.2)));await frames(25)
	check(tag+"walk through a wire cube releases original spark burst",party.collected_cubes==1 and party.spark_bursts.get_child_count()==1)
	game.place_player(party.to_global(Vector3(0,.06,4.2)));await frames(12)
	check(tag+"collected cube does not repeat its reward",party.collected_cubes==1)
	var monitor: Node3D=artifact("film_rainbow_partitions")
	await approach(monitor,1.8);await point_press(monitor.buttons["pause"])
	check(tag+"film pauses through original pointer target",not monitor.stage.running)
	await point_press(monitor.buttons["pause"])
	check(tag+"film resumes through original pointer target",monitor.stage.running)
	game.place_player(game.spawn_for(2));await frames(12)

func capture_floor() -> void:
	if level==1:
		var salon: Node3D=artifact("nail_salon")
		await photo("01-two-hands-one-colour",salon.to_global(Vector3(6,3.3,10)),salon.to_global(Vector3(0,2.1,1)))
		await photo("02-original-rgb-controls",salon.to_global(Vector3(-4,2.4,8)),salon.to_global(Vector3(0,1.4,4)))
	else:
		var party: Node3D=artifact("rainbow")._celebration
		await photo("03-rainbow-celebration",party.to_global(Vector3(-6.5,3.8,10)),party.to_global(Vector3(0,2,-1)))
		await photo("04-partitions-and-walk",party.to_global(Vector3(5.8,3.3,7.5)),party.to_global(Vector3(0,1.8,-2)))
