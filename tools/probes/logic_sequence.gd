extends "res://tools/probes/void_transfer_probe.gd"
## New placement/progression checks; existing gate mechanisms are reused unchanged.
var take_logic_photos := false
var pointer: Node3D

func start(use_xr: bool) -> void:
	xr = use_xr;Source.use_main_tower = true
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	load("res://commons/void/game.gd").requested_floor = 20
	game = load("res://commons/void/void.tscn").instantiate();game.force_xr = xr
	root.add_child(game);current_scene = game
	if not xr:game.body.scripted_input = true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky = false;game.atmosphere.set_sky_time(180)
	pointer = Node3D.new();game.add_child(pointer)

func press_logic_button(work: Node3D,id: String) -> void:
	var area: Area3D = work.buttons[id].get_node("PushButton/InteractableAreaButton")
	var p := area.global_position
	area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,area,p,p))
	area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,area,p,p))
	await frames(3)

func truth_case(work: Node3D,bits: String) -> void:
	await press_logic_button(work,"RESET")
	if bits[0]=="1":await press_logic_button(work,"X")
	if bits.length()>1 and bits[1]=="1":await press_logic_button(work,"Y")
	await frames(45);await press_logic_button(work,"RELEASE")
	for n in 1200:
		if work.outcome>=0 or work.outcome==-2:break
		await frames(1)
	check("New Logic floor / Jolt "+work.operator+" "+bits,work.outcome==work.required_observations[bits])

func visit_logic_floor(index: int) -> void:
	level = index;game.place_player(game.spawn_for(index));game.checkpoint = index
	for n in 180:
		if game.building.content.data.floors[index].artifacts.all(func(a):return game.building.content.exhibits.has(str(index)+"/"+a.id)):break
		await frames(1)
	await frames(45)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg=="--capture":take_logic_photos = true
	DirAccess.make_dir_recursive_absolute(out);root.size = Vector2i(1440,900)
	OS.set_environment("VOID_INVENTORY_PATH",out.path_join("logic-inventory-"+str(Time.get_ticks_usec())+".json"))
	check("isolated native user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	for use_xr in [false,true]:
		await start(use_xr);var tag := "Synthetic XR / " if xr else "Desktop / "
		if not xr:check("fresh isolated gate inventory",not game.prefab_inventory.unlocked("matter_spring_and") and not game.prefab_inventory.unlocked("matter_spring_or") and not game.prefab_inventory.unlocked("matter_spring_not"))
		check(tag+"four rooms follow Transformation",game.building.content.data.floors[19].map=="Trans_Pit" and game.building.content.data.floors[24].map=="Array" and game.building.spec.levels.size()==209)
		for i in range(20,24):
			await visit_logic_floor(i)
			check(tag+"floor "+str(i)+" starts on a solid slab",game.body.is_on_floor() and not game.recovering)
			for a in game.building.content.data.floors[i].artifacts:
				var work: Node3D = station(a.id)
				check(tag+a.id+" exposes independent editable parts",work.part_defaults.size()>=7)
				var boxes: Array = [];geometry(work,boxes)
				var all: AABB = boxes[0]
				for b in boxes:all = all.merge(b)
				var y: float = game.building.spec.levels[i]
				check(tag+a.id+" stays on standard floor",all.position.x>=-21 and all.end.x<=21 and all.position.z>=-9 and all.end.z<=9 and all.position.y>=y-.15 and all.end.y<y+5.6)
				for shaft in game.building.spec.shafts:
					var hole := Rect2(shaft.x-2.5,-3,5,6)
					check(tag+a.id+" clears shaft "+shaft.name,not hole.intersects(Rect2(all.position.x,all.position.z,all.size.x,all.size.z)))
				if not xr and a.artifact.begins_with("matter_spring_"):
					for bits in work.required_observations:await truth_case(work,str(bits))
					check(a.id+" awards the existing catalogue recipe",game.prefab_inventory.unlocked(a.artifact))
					await press_logic_button(work,"RESET")
				if a.id=="logic-workshop":
					check(tag+"same twenty reusable pallet pieces",work.pieces.size()==20 and work.buttons.has("SAVE"))
			if take_logic_photos and not xr:
				var work: Node3D = station(game.building.content.data.floors[i].artifacts[0].id)
				var cam := Camera3D.new();cam.fov = 60;game.add_child(cam)
				cam.global_position = work.to_global(Vector3(3.8,3.0,6.5) if i!=20 else Vector3(-1.5,4,8))
				cam.look_at(work.to_global(Vector3(-1,1,0) if i==20 else Vector3(0,1,0)));cam.make_current()
				var shown: Array[int] = [i];game.building.show_floor_window(shown)
				await frames(3);await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(out.path_join("logic-"+str(i)+".png"))
				cam.queue_free();game.camera.make_current()
		game.queue_free();await frames(12)
		if xr:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,
		"scope":"Main Logic floors: desktop/synthetic XR loading, full bounds, shafts, existing physical truth cases through explicit diagnostic pointer events, catalogue unlocks and editable pallet pieces. Not fresh OS mouse/grip or physical-headset acceptance."}
	FileAccess.open(out.path_join("logic-sequence-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
