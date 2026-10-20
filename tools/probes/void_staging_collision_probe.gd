extends "res://tools/probes/void_motion_probe.gd"
## Load through the actual staging scene, including its persistent hidden menu.
var staging: Node3D
var inventories: Dictionary = {}

func active_shapes(body: CollisionObject3D) -> int:
	var count := 0
	for owner_id in body.get_shape_owners():
		if not body.is_shape_owner_disabled(owner_id):
			count += body.shape_owner_get_shape_count(owner_id)
	return count

func inventory(host: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for node in host.find_children("*", "CollisionObject3D", true, false):
		var body := node as CollisionObject3D
		found.append({"path":str(body.get_path()),"type":body.get_class(),"layer":body.collision_layer,
			"mask":body.collision_mask,"shapes":active_shapes(body),"visible":body.is_visible_in_tree(),
			"solid_to_player":body is PhysicsBody3D and active_shapes(body)>0 and (body.collision_layer & 1023)!=0,
			"position":str(body.global_position)})
	return found

func run() -> void:
	staging = load("res://commons/scenes/vr_staging.tscn").instantiate()
	staging.quick_transition_duration = 0.02
	staging.get_node("Scene").child_entered_tree.connect(func(child):
		child.set("force_xr", true))
	add_child(staging)
	await frames(90)
	if "--menu-baseline" in OS.get_cmdline_user_args():
		# Same production menu and preload path, with no Void scene or meter.
		staging.queue_free()
		await frames(5)
		for item in [head,left,right]: XRServer.remove_tracker(item)
		get_tree().quit()
		return
	inventories["menu_before"] = inventory(staging)
	# The same route as the button, including fades, scene lifecycle, and persistent rig.
	await staging.load_scene("res://commons/void/motion_room.tscn")
	game = staging.current_scene
	game.meter.report_directory = output
	await frames(30)
	inventories["room"] = inventory(staging)
	check("Actual staging loads the XR comparison room",game.vr and game.ready_for_play)
	var extras := []
	for item in inventories.room:
		if item.solid_to_player and not item.path.begins_with(str(game.get_path())+"/"):
			extras.append(item)
	check("No staging/menu body can obstruct the loaded player",extras.is_empty())
	check("Exactly one player capsule in real staging",staging.find_children("*","CharacterBody3D",true,false).size()==1)
	var mushroom := get_node("/root/MushroomHand")
	var hand := Node3D.new()
	hand.name = "MushroomAuditHand"
	add_child(hand)
	mushroom._build_vr_hand(hand)
	inventories["held_mushroom"] = inventory(hand)
	check("Hand mushroom creates no physics colliders",inventories.held_mushroom.is_empty())
	hand.queue_free()
	for hz in [60,90]:
		Engine.physics_ticks_per_second = hz
		await walk("real-staging room",Vector3(0,0.06,7),Vector2(0,1),"forward")
		await walk("real-staging room",Vector3(0,0.06,7),Vector2(0,0.3),"slow forward")
	# Positive control: the diagnostic must name a deliberately invisible obstacle.
	game._box("DiagnosticHiddenWall",Vector3(0,1,5),Vector3(3,2,0.2),Color.WHITE)
	var wall: Node3D = game.get_node("DiagnosticHiddenWall")
	wall.hide()
	game.place_player(Vector3(0,0.06,7))
	left.set_input("primary",Vector2(0,1))
	await frames(140)
	check("Contact diagnostic identifies an invisible wall",game.meter.latest.last_obstacle=="DiagnosticHiddenWall (hidden)")
	var wall_contacts: Array = game.meter.latest.contacts
	check("Saved evidence includes the collider path and hidden state",wall_contacts.any(func(c): return c.path.ends_with("/DiagnosticHiddenWall") and not c.visible))
	inventories["deliberate_obstacle_readout"] = game.meter.latest.duplicate(true)
	left.set_input("primary",Vector2.ZERO)
	wall.queue_free()
	await frames(5)
	var tower_script := load("res://commons/void/game.gd")
	tower_script.motion_test_requested = true
	await staging.load_scene("res://commons/void/void.tscn")
	game = staging.current_scene
	game.get_node("MotionMeter").report_directory = output
	await frames(30)
	inventories["tower"] = inventory(staging)
	check("Actual staging loads the tower with one player capsule",game.vr and game.ready_for_play and staging.find_children("*","CharacterBody3D",true,false).size()==1)
	var tower_extras := []
	for item in inventories.tower:
		if item.solid_to_player and not item.path.begins_with(str(game.get_path())+"/"):
			tower_extras.append(item)
	check("No persistent menu body obstructs the tower player",tower_extras.is_empty())
	for hz in [60,90]:
		Engine.physics_ticks_per_second = hz
		await walk("real-staging tower",Vector3(2,0.06,6),Vector2(0,1),"forward")
		await walk("real-staging tower",Vector3(2,0.06,6),Vector2(0,0.3),"slow forward")
	left.set_input("primary",Vector2.ZERO)
	await staging.return_to_main_menu()
	await frames(10)
	check("Menu visible again after actual scene exit",staging.get_node("MainMenu3D").is_visible_in_tree() and staging.current_scene==null)
	inventories["menu_return"] = inventory(staging)
	staging.queue_free()
	await frames(5)
	for item in [head,left,right]: XRServer.remove_tracker(item)
	Engine.physics_ticks_per_second = old_hz
	var passed: bool = checks.all(func(c): return c.passed)
	var file := FileAccess.open(output.path_join("staging-collisions.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"checks":checks,"trials":trials,"inventory":inventories},"\t"))
	file.close()
	get_tree().quit(0 if passed else 1)
