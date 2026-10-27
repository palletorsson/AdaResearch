extends "res://tools/probes/array_trial_probe.gd"

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO)
		right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false)
		right.set_input("grip",0.0)
	game = load("res://commons/void/trials/color_flashlight/trial.tscn").instantiate()
	game.force_xr = xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(50)
	game.scene_loaded();game.scene_visible()
	await frames(20)

func station(id: String) -> Node3D:
	return game.building.content.exhibits["1/"+id].get_node("Artifact")

func press(button: Node3D) -> void:
	if not xr:
		await super.press(button)
		return
	var origin: Node3D=game.get_node("XROrigin3D")
	var target: Vector3=button.global_position
	var at: Vector3=target+button.global_basis*Vector3(0,.04,.65)
	right.set_pose("aim",Transform3D(origin.global_basis.inverse()*Basis.looking_at(target-at),origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(20)
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(12)

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	var before: Vector3=game.body.global_position
	game.place_player(Vector3(-18,-5.94,-7.5))
	await frames(5)
	await super.photo(filename,at,target)
	game.place_player(before);await frames(5)

func press_cell(button: Node3D) -> void:
	# Aim at the centre of the visible opening, not the back-bottom origin.
	var target := Marker3D.new()
	button.add_child(target)
	target.position = Vector3(0,.5,.52)
	await press(target)
	target.queue_free()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	var original := FileAccess.get_sha256("res://commons/void/rooms.json")
	for use_xr in ([false] if "--desktop-only" in OS.get_cmdline_user_args() else [false,true]):
		if "--wall-only" in OS.get_cmdline_user_args():
			await start(use_xr)
			await wall_checks(station("cube-wall"),"XR: " if use_xr else "Desktop: ")
			game.queue_free();await frames(8)
			if xr:
				for item in [head,left,right]:XRServer.remove_tracker(item)
		else:await visit_flashlight(use_xr)
	# The user may curate the main tower while this isolated trial runs.
	# Verify where this game reads/writes, not that their file stays frozen.
	check("trial layout is separate from curated tower",Source.definition("color_flashlight").rooms=="res://commons/void/trials/color_flashlight/rooms.json")
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"external_tower_edit_during_run":original!=FileAccess.get_sha256("res://commons/void/rooms.json"),
		"scope":"Native Mobile renderer, desktop and synthetic XR input. Physical headset not tested."
	},"\t"))
	print("FLASHLIGHT_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_flashlight(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"shared rig starts on safe trial floor",game.checkpoint==1 and game.body.is_on_floor())
	check(tag+"three source encounters plus sixteen-cell study",game.building.content.exhibits.size()==4 and ["lamps","rooms","pink","cube-wall"].all(func(id):return game.building.content.exhibits.has("1/"+id)))
	var lamps := station("lamps")
	var rooms := station("rooms")
	var pink := station("pink")
	check(tag+"actual player camera sees every light-room surface",rooms.find_children("*","MeshInstance3D",true,false).all(func(mesh):return (mesh.layers & game.camera.cull_mask)!=0))
	check(tag+"room lighting stays isolated while the player's own head stays hidden",not game.camera.get_cull_mask_value(20) and rooms.find_children("*","Light3D",true,false).all(func(light):return light.light_cull_mask==rooms.ROOM_LAYER) and (game.atmosphere.get_node("WarmSun").light_cull_mask & rooms.ROOM_LAYER)==0)
	check(tag+"four original grabbable lamps",lamps.find_children("*Flashlight","RigidBody3D",true,false).size()==4)
	check(tag+"two rooms independently editable",rooms.part_defaults.size()==2)
	check(tag+"white room and lightwell centred over the two shafts",rooms.white_room.global_position.is_equal_approx(Vector3(-10,-6,0)) and rooms.light_well.global_position.is_equal_approx(Vector3(10,-6,0)))
	var open_shafts := true
	for shaft in [-10,10]:
		for dx in [-2.4,0,2.4]:
			for dz in [-2.9,0,2.9]:
				var hit := ray(Vector3(shaft+dx,-5,dz),Vector3(shaft+dx,-6.5,dz))
				if not hit.is_empty() and not hit.collider.get_meta("void_landing_pad",false): open_shafts=false
	check(tag+"both 5 by 6 metre shafts stay open except the existing corner landing pad",open_shafts)
	var supported := true
	for shaft in [-10,10]:
		for offset in [Vector3(-3.0,0,0),Vector3(3.0,0,0),Vector3(0,0,-3.55),Vector3(0,0,3.65)]:
			var at: Vector3 = Vector3(shaft,-5,0)+offset
			var hit := ray(at,at-Vector3.UP*1.5)
			if hit.is_empty() or not hit.collider.get_meta("void_floor_surface",false): supported=false
	check(tag+"walkways support the visitor on all four sides of both shafts",supported)
	check(tag+"original standing canvas, cube and seven-sided receiver",lamps.mount=="standing" and lamps.receiver_sides==7 and lamps.has_node("ReceiverCube") and lamps.get_node("Canvas").size==Vector3(6,4,.1))
	check(tag+"original sphere and five switches plus material and reset",pink.specimen.get_script().resource_path=="res://commons/artifacts/spine_studies/pink_sphere.gd" and pink.specimen.lights.size()==5 and pink.controls.size()==7)
	check(tag+"original rooms retain recess, ramp and three sky apertures",rooms.has_node("WhiteRoom/ThresholdReturn") and rooms.has_node("LightWell/SlowRamp") and rooms.rim_materials.size()==3 and rooms.ring_lights.size()==6)
	rooms.running=false;rooms.set_phase(.24)
	var white_albedo: Color=rooms.white_material.albedo_color
	var light_before: Color=rooms.central_light.light_color
	rooms.set_phase(.62)
	check(tag+"light changes while white wall material stays fixed",rooms.white_material.albedo_color==white_albedo and rooms.central_light.light_color!=light_before)
	rooms.set_phase(.24)
	check(tag+"sky opening is physically open through shaft B",ray(Vector3(10,1.5,0),Vector3(10,15,0)).is_empty())
	if not xr:
		await photo("01-lamps",Vector3(-15.3,-4.35,2.3),Vector3(-20.1,-4.2,.3))
		await photo("02-white-room",Vector3(-6.4,-4.35,1.1),Vector3(-9.6,-5.6,-2.0))
		rooms.set_phase(.62)
		await photo("02-white-room-cyan",Vector3(-6.4,-4.35,1.1),Vector3(-9.6,-5.6,-2.0))
		rooms.set_phase(.24)
		await photo("03-sky-opening",Vector3(9.7,-4.35,3.5),Vector3(10,-.05,0))
		await photo("03-lightwell-walkway",Vector3(7,-4.35,3.6),Vector3(11,-6.3,-1))
		await photo("04-pink-light",Vector3(2.8,-4.35,1.2),Vector3(0,-5.1,4.6))
		await photo("05-tower",Vector3(-1,2.3,-19),Vector3(0,-3.7,0))
	await grab_checks(lamps,tag)
	await room_flashlight_checks(rooms,tag)
	# Native collision route, including both doorways and the original slow ramp.
	if xr:
		# Return the hands from the reaching pose to their normal walking pose.
		left.set_pose("aim",Transform3D(Basis.IDENTITY,Vector3(-.3,1.2,-.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		right.set_pose("aim",Transform3D(Basis.IDENTITY,Vector3(.3,1.2,-.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	game.place_player(Vector3(-16,-5.94,0));await frames(15)
	var route_ok := true
	for p in [Vector3(-13.4,-5.99,0),Vector3(-13.4,-5.99,3.65),Vector3(-6.6,-5.99,3.65),Vector3(-6.6,-5.99,-3.55),Vector3(-13.4,-5.99,-3.55),Vector3(-13.4,-5.99,0),Vector3(-13.4,-5.99,3.65),Vector3(-6.6,-5.99,3.65),Vector3(-6.6,-5.99,0),Vector3(-4,-5.99,0),Vector3(7,-5.99,0),Vector3(7,-5.99,-3.65),Vector3(13.1,-5.99,-3.65),Vector3(13.1,-5.99,3.65),Vector3(7,-5.99,3.65),Vector3(7,-5.99,0),Vector3(7,-5.99,4.8),Vector3(14.5,-5.99,4.8)]:
		if not await walk(p):route_ok=false;break
	check(tag+"walk through both doorways and a complete circuit around each shaft",route_ok and not game.recovering)
	check(tag+"original ramp reaches raised viewpoint",route_ok and await walk(Vector3(14.5,-4.8,-5.5)))
	await shaft_drop_checks(tag)
	game.place_player(Vector3(1,-5.94,.65));await frames(15)
	await press(pink.controls[1])
	check(tag+"pointer switches on left light",pink.specimen.mask==3)
	await press(pink.controls[0])
	check(tag+"pointer switches top light off",pink.specimen.mask==2)
	var sphere_before: Color=pink.specimen.sphere_material.albedo_color
	await press(pink.controls[5])
	check(tag+"pointer changes light/material comparison",pink.specimen.pink_material and pink.specimen.sphere_material.albedo_color!=sphere_before and pink.specimen.lights[1].light_color==Color.WHITE)
	var masks_ok := true
	for mask in 32:
		pink.specimen.set_lights(mask)
		for i in 5:masks_ok=masks_ok and pink.specimen.lights[i].visible==((mask&(1<<i))!=0)
	check(tag+"all 32 five-switch combinations reach actual lamps",masks_ok)
	if not xr:
		await photo("04-pink-material",Vector3(2.8,-4.35,1.2),Vector3(0,-5.1,4.6))
	await press(pink.controls[6])
	check(tag+"pointer RESET restores pink light and pale material",pink.specimen.mask==1 and not pink.specimen.pink_material)
	await wall_checks(station("cube-wall"),tag)
	if not xr:await rendered_light_checks(lamps)
	# The editor can duplicate just one room and move/turn it. Its light score
	# must tolerate the absent half rather than writing to freed references.
	for part_name in ["WhiteRoom","LightWell"]:
		var copy: Node3D=load("res://commons/void/trials/color_flashlight/light_rooms.tscn").instantiate()
		game.add_child(copy)
		copy.apply_grid_config({"only_parts":[part_name],"parts":{part_name:{"position":[40,0,0],"rotation":[0,90,0]}}})
		copy.set_phase(.5);await frames(5)
		check(tag+"editable "+part_name+" copy runs alone after move and turn",copy.get_child_count()==1 and copy.get_child(0).position.is_equal_approx(Vector3(40,0,0)) and is_equal_approx(copy.get_child(0).rotation_degrees.y,90))
		copy.queue_free();await frames(3)
	game.die("Retry Flashlight");await frames(130)
	check(tag+"retry restores all four encounters",not game.recovering and game.checkpoint==1 and station("pink").specimen.mask==1 and not station("pink").specimen.pink_material and game.building.content.exhibits.size()==4 and station("cube-wall").cells.map(func(c):return c.mask)==station("cube-wall").PRESETS)
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

func shaft_drop_checks(tag: String) -> void:
	for shaft in [-10,10]:
		game.health.reset()
		game.place_player(Vector3(shaft,-5.94,0))
		for i in 140:
			axes(Vector2(1,0) if game.body.global_position.x < shaft+3.3 else Vector2.ZERO)
			await frames(1)
			if game.recovering or (game.body.is_on_floor() and game.body.global_position.y < -11.5): break
		axes(Vector2.ZERO);await frames(20)
		check(tag+"drop through shaft %s and steer onto the next floor" % ("A" if shaft < 0 else "B"),not game.recovering and game.checkpoint==2 and game.body.is_on_floor() and absf(game.body.global_position.y+12)<.15)
		game.place_player(Vector3(0,-5.94,0));await frames(20)

func mouse_right() -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=true
	Input.parse_input_event(event);await frames(6)
	event=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=false
	Input.parse_input_event(event);await frames(6)

func room_flashlight_checks(rooms: Node3D, tag: String) -> void:
	for room in [rooms.white_room, rooms.light_well]:
		var label: String = str(room.name)
		var lamps: Array = room.find_children("*Flashlight", "RigidBody3D", true, false)
		check(tag+label+" has four museum pickable flashlights",lamps.size()==4 and lamps.all(func(l):return l.get_script().resource_path=="res://addons/godot-xr-tools/objects/pickable.gd"))
		var aimed := true
		var wall_z: float = 5.3 if room==rooms.white_room else 6.9
		for lamp in lamps:
			var spot: SpotLight3D = lamp.get_node("SpotLight3D")
			var hit := ray(spot.global_position,spot.global_position-spot.global_basis.z*5)
			# Godot renames duplicate wall nodes; check the actual struck surface.
			if hit.is_empty() or not room.is_ancestor_of(hit.collider) or absf(room.to_local(hit.position).z-wall_z)>.02:aimed=false
		check(tag+label+" beams begin aimed at its interior wall",aimed)
		var lamp: RigidBody3D = room.get_node("RedFlashlight")
		var home := lamp.global_transform
		game.place_player(room.to_global(Vector3(lamp.position.x,.06,lamp.position.z-.7)))
		await frames(15)
		if xr:
			hand_at(right,lamp.global_position);await frames(15)
			right.set_input("grip",1.0);await frames(15)
		else:
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
			game.camera.look_at(lamp.global_position);await frames(15)
			await mouse_right()
		check(tag+label+" lamp can be picked up from the walkway",lamp.is_picked_up())
		if xr:hand_at(right,home.origin+Vector3(-.3,.35,.25))
		else:game.camera.rotate_y(.4)
		await frames(20)
		check(tag+label+" carried beam follows the moved handle",lamp.global_position.distance_to(home.origin)>.15 and lamp.get_node("SpotLight3D").get_parent()==lamp)
		if xr:right.set_input("grip",0.0);await frames(15)
		else:await mouse_right()
		var released := lamp.global_position
		await frames(30)
		check(tag+label+" released lamp holds its new aim",lamp.freeze and not lamp.is_picked_up() and lamp.global_position.distance_to(released)<.02)
		lamp.global_transform=home
		PhysicsServer3D.body_set_state(lamp.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,home)
		await frames(5)
		if not xr:
			var camera_at: Vector3 = room.to_global(Vector3(0,1.8,wall_z-2.2))
			var target: Vector3 = room.to_global(Vector3(0,2,wall_z-.02))
			var albedo: Color = rooms.white_material.albedo_color
			for item in lamps:item.get_node("SpotLight3D").visible=false
			var dark := await patch(camera_at,target)
			lamp.get_node("SpotLight3D").visible=true
			var red := await patch(camera_at,target)
			room.get_node("GreenFlashlight/SpotLight3D").visible=true
			room.get_node("BlueFlashlight/SpotLight3D").visible=true
			var rgb := await patch(camera_at,target)
			check(label+" red flashlight visibly adds red to the wall",red.r>dark.r+.025)
			check(label+" overlapping RGB beams add colour without repainting",rgb.g>red.g+.025 and rgb.b>red.b+.025 and rooms.white_material.albedo_color==albedo)
			for item in lamps:item.get_node("SpotLight3D").visible=true
			await photo("11-white-wall-flashlights" if room==rooms.white_room else "12-lightwell-flashlights",room.to_global(Vector3(2.8,1.7,wall_z-2.4)),room.to_global(Vector3(0,1.65,wall_z)))

func grab_checks(lamps: Node3D, tag: String) -> void:
	var lamp: RigidBody3D=lamps.get_node("RedFlashlight")
	var home: Transform3D=lamp.global_transform
	game.place_player(Vector3(-15,-5.94,1.5));await frames(15)
	if xr:
		hand_at(right,lamp.global_position);await frames(15)
		right.set_input("grip",1.0);await frames(15)
		check(tag+"controller grip picks up original red lamp",lamp.is_picked_up())
		hand_at(right,home.origin+Vector3(-.5,.5,.35));await frames(20)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(lamp.global_position);await frames(15)
		await mouse_right()
		check(tag+"right-click picks up original red lamp",game.body.desktop_pointer._held==lamp)
		game.camera.rotate_y(.3);await frames(20)
	check(tag+"carried lamp and its light move together",lamp.global_position.distance_to(home.origin)>.2 and lamp.get_node("SpotLight3D").get_parent()==lamp)
	if xr:right.set_input("grip",0.0);await frames(15)
	else:await mouse_right()
	var released: Transform3D=lamp.global_transform
	await frames(50)
	check(tag+"released lamp holds its new position",lamp.freeze and not lamp.is_picked_up() and lamp.global_position.distance_to(released.origin)<.02)
	lamp.global_transform=home
	PhysicsServer3D.body_set_state(lamp.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,home)
	await frames(5)

func rendered_light_checks(lamps: Node3D) -> void:
	game.place_player(Vector3(18,-5.94,7.8));await frames(8)
	var spots: Array=[]
	for key in ["RedFlashlight","GreenFlashlight","BlueFlashlight","WhiteFlashlight"]:
		spots.append(lamps.get_node(key+"/SpotLight3D"))
	var canvas: CSGBox3D=lamps.get_node("Canvas")
	var before: Color=canvas.material.albedo_color
	for lamp in spots:lamp.visible=false
	var at: Vector3=lamps.to_global(Vector3(0,1.2,3.7))
	var target: Vector3=lamps.to_global(Vector3(0,1.2,-1.94))
	var dark := await patch(at,target)
	spots[0].visible=true
	var red := await patch(at,target)
	await photo("06-red-only",at,target)
	spots[1].visible=true;spots[2].visible=true
	var rgb := await patch(at,target)
	await photo("07-rgb-overlap",at,target)
	check("Rendered board becomes red under the red lamp",red.r>red.g+.04 and red.r>dark.r+.04)
	check("Rendered RGB overlap adds green and blue without repainting",rgb.g>red.g+.04 and rgb.b>red.b+.04 and canvas.material.albedo_color==before)
	FileAccess.open(out.path_join("rendered-colours.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"sample":"Mean central 40 x 40 pixels, same native camera and matte board",
		"lamps_off":[dark.r,dark.g,dark.b],"red":[red.r,red.g,red.b],"rgb":[rgb.r,rgb.g,rgb.b],
		"unchanged_albedo":[before.r,before.g,before.b]
	},"\t"))
	for lamp in spots:lamp.visible=true

func patch(at: Vector3, target: Vector3) -> Color:
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.environment=game.atmosphere.environment
	camera.global_position=at;camera.look_at(target);camera.make_current()
	await frames(5);await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var result := Color(0,0,0,0)
	var centre := picture.get_size()/2
	for y in range(centre.y-20,centre.y+20):
		for x in range(centre.x-20,centre.x+20):
			result+=picture.get_pixel(x,y)/1600.0
	camera.queue_free();game.camera.make_current()
	return result

func wall_checks(wall: Node3D, tag: String) -> void:
	check(tag+"sixteen open-front cells on a four by four grid",wall.cells.size()==16 and wall.buttons.size()==16 and wall.cells.all(func(c):return c.shell.size()==5))
	var identities: Array=wall.cells.map(func(c):return c.sphere.get_instance_id())
	var albedos: Array=wall.cells.map(func(c):return c.sphere_material.albedo_color)
	check(tag+"same pale sphere and geometry throughout",wall.cells.all(func(c):return c.sphere.mesh==wall.cells[0].sphere.mesh and c.sphere_material.albedo_color==c.PALE and not c.sphere_material.emission_enabled))
	check(tag+"five original light switches per cell with sixteen distinct preset masks",wall.cells.map(func(c):return c.mask)==wall.PRESETS and wall.cells.all(func(c):return c.lights.size()==5 and c.lights.all(func(l):return l.light_color==Color.RED and l.shadow_enabled)))
	var isolated := true
	for i in 16:
		var cell: Node3D=wall.cells[i]
		if cell.sphere.layers != (1<<(i+1)) or not cell.lights.all(func(l):return l.light_cull_mask==cell.sphere.layers): isolated=false
	check(tag+"each cell light affects only its own sphere and walls",isolated and (game.atmosphere.get_node("WarmSun").light_cull_mask & wall.CELL_LAYERS)==0)
	game.place_player(Vector3(4.5,-5.94,7.9));await frames(15)
	var access := true
	for at in [Vector3(16.5,-6,7.9),Vector3(16.5,-6,0)]:
		if not await walk(at):access=false;break
	check(tag+"wall is reachable around the lightwell without crossing a shaft",access)
	if not xr:await photo("08-cube-wall",Vector3(15,-3.25,0),wall.to_global(Vector3(0,2.7,0)))
	await press_cell(wall.buttons[0])
	check(tag+"pointer changes the first cell from top to left lighting",wall.cells[0].mask==2 and not wall.cells[0].lights[0].visible and wall.cells[0].lights[1].visible)
	check(tag+"other fifteen comparisons keep their lights",range(1,16).all(func(i):return wall.cells[i].mask==wall.PRESETS[i]))
	await press_cell(wall.buttons[15])
	check(tag+"last cell cycles from all five sources to darkness",wall.cells[15].mask==0 and wall.cells[15].lights.all(func(l):return not l.visible))
	if not xr:await photo("09-cell-dark",wall.to_global(Vector3(1.59,1.25,2.6)),wall.cells[15].sphere.global_position)
	await press_cell(wall.buttons[15])
	check(tag+"next click returns the top source",wall.cells[15].mask==1 and wall.cells[15].lights[0].visible)
	if not xr:await photo("10-cell-top",wall.to_global(Vector3(1.59,1.25,2.6)),wall.cells[15].sphere.global_position)
	check(tag+"switching never replaces or recolours the spheres",wall.cells.map(func(c):return c.sphere.get_instance_id())==identities and wall.cells.map(func(c):return c.sphere_material.albedo_color)==albedos)
	await press(wall.reset_button)
	check(tag+"RESET restores all sixteen initial lighting setups",wall.cells.map(func(c):return c.mask)==wall.PRESETS)
