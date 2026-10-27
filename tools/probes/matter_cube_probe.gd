extends "res://tools/probes/void_transfer_probe.gd"
## Full main-tower Cube placement, real input, isolated progression save.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	take_photos=true;level=7
	check("native checks use isolated test profile",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	for mode in [false,true]:
		xr=mode
		OS.set_environment("VOID_INVENTORY_PATH",out.path_join("test-inventory-"+("xr" if mode else "desktop")+"-"+str(Time.get_ticks_usec())+".json"))
		if xr:
			head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
			left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
			right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
			left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		game=load("res://commons/void/void.tscn").instantiate();game.force_xr=xr
		root.add_child(game);current_scene=game
		if not xr:game.body.scripted_input=true
		await frames(50);game.scene_loaded();game.scene_visible();await frames(30)
		var tag := "Synthetic XR / " if xr else "Desktop / "
		var gate: Node3D=station("matter-and")
		var inventory: Node=game.prefab_inventory
		check(tag+"main Cube floor7 actual source mount at negative height",game.trial_id.is_empty() and game.checkpoint==7 and gate.global_position.is_equal_approx(Vector3(0,-42,-.25)))
		check(tag+"starts locked; entering floor does not award recipe",not inventory.unlocked("matter_and"))
		check(tag+"binding exists once despite streaming refresh",gate.get_signal_connection_list("interaction_completed").size()==1)
		var visible_floors: Array[int]=[6,7,8]
		game.building.show_floor_window(visible_floors)
		game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
		game.atmosphere.environment.fog_enabled=false
		game.place_player(gate.to_global(Vector3(0,.06,4.7)));await frames(10)
		if not xr:await photo("01-cube-floor7-matter-and",gate.to_global(Vector3(8,4.4,8)),gate.to_global(Vector3(0,1.7,0)))
		for value in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
			await press(gate.buttons[3].get_node("PushButton"))
			if value.x:await press(gate.buttons[0].get_node("PushButton"))
			if value.y:await press(gate.buttons[1].get_node("PushButton"))
			await press(gate.buttons[2].get_node("PushButton"))
			for i in 1050:
				await frames(1)
				if gate.outcome>=0:break
			check(tag+"real input / physical case "+str(value),gate.outcome==(1 if value==Vector2i.ONE else 0))
			check(tag+"recipe earned only after final observation",inventory.unlocked("matter_and")== (value==Vector2i.ONE))
		check(tag+"four observations complete lesson",gate.lesson_complete and gate.observations.size()==4)
		var saved := FileAccess.get_file_as_string(inventory.save_path)
		inventory.reload()
		check(tag+"unlock survives inventory reload",inventory.unlocked("matter_and") and not saved.is_empty())
		inventory._lesson_completed("matter_and")
		check(tag+"repeated completion never duplicates reward",FileAccess.get_file_as_string(inventory.save_path)==saved and inventory.completed.size()==1)
		gate.reset_gate();check(tag+"reset keeps earned recipe",inventory.unlocked("matter_and"))
		# Locked placement cannot spawn an assembly. Uses the actual game guard.
		var copies_before: int=game.building.content.data.floors[7].get("copies",[]).size()
		game.place_inventory_prefab("not_earned")
		check(tag+"unknown or locked recipe cannot place",game.building.content.data.floors[7].get("copies",[]).size()==copies_before)
		if xr:game._left_button("primary_click")
		else:
			var event := InputEventKey.new();event.keycode=KEY_I;event.pressed=true
			Input.parse_input_event(event);await frames(2)
		check(tag+"inventory opens with desktop I / XR stick click",game.inventory_board.visible)
		check(tag+"inventory exposes earned assembly",game.inventory_board.readout.text.contains("UNLOCKED") and game.inventory_board.place_button.visible)
		if not xr:
			# Capture the actual player inventory, facing the camera.
			game.inventory_board.global_position=game.camera.global_position-game.camera.global_basis.z*1.35
			game.inventory_board.global_rotation=Vector3(0,game.camera.global_rotation.y,0)
			await frames(4);await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("02-earned-player-inventory.png"))
		game.queue_free();await frames(10)
		if xr:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	FileAccess.open(out.path_join("native-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Main tower floor7, real desktop mouse and synthetic XR triggers; four physical observations, completion, isolated saved reward/reload, inventory controls. No physical headset."},"  "))
	print("MATTER_CUBE_RESULT ",checks.size()," ",failed);quit(0 if failed.is_empty() else 1)
