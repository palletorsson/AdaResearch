extends "res://tools/probes/void_transfer_probe.gd"
## Follow-up for actual inventory placement plus clearer captures. Reads an
## already earned isolated test profile; never writes the visitor's inventory.
func run() -> void:
	var inventory_file := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg.begins_with("--inventory="):inventory_file=arg.trim_prefix("--inventory=")
	assert(inventory_file.contains("matter-cube-inventory/test-inventory-desktop"))
	OS.set_environment("VOID_INVENTORY_PATH",inventory_file)
	level=7;take_photos=true
	game=load("res://commons/void/void.tscn").instantiate();root.add_child(game);current_scene=game
	game.body.scripted_input=true
	await frames(70)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180);game.atmosphere.environment.fog_enabled=false
	var gate: Node3D=station("matter-and")
	await photo("01-cube-floor7-matter-and",gate.to_global(Vector3(0,3.8,6.8)),gate.to_global(Vector3(0,1.6,-.4)))
	game.place_player(gate.to_global(Vector3(3.5,.06,2.2)));await frames(15)
	game.camera.look_at(gate.to_global(Vector3(0,1.7,-.4)))
	game.inventory_board.toggle();await frames(6)
	game.status.hide();game.notice_time=-1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("02-earned-player-inventory.png"))
	game.inventory_board.hide();await frames(4)
	var shapes: Array=game.inventory_board.find_children("*","CollisionShape3D",true,false)
	check("closed inventory leaves no active pointer colliders",shapes.all(func(s):return s.disabled))
	check("existing actual earned test save reloads on new game",game.prefab_inventory.unlocked("matter_and"))
	# Empty-bay fixture: retain the exact main-floor structural slab/shafts,
	# temporarily clear this floor's authored content in memory only. The real
	# Cube arrangement was captured above and is never written or rearranged.
	game.floor_stream.set_process(false)
	game.floor_stream.records.erase(7)
	game.building.content.reset_floor(7)
	game.building.content.data.floors[7]={"map":"Point_Animatedcube","title":"Inventory empty-bay fixture","origin":false,"walls":[],"artifacts":[],"props":[],"impact_cells":[],"route":[]}
	game.building.content.load_floor(7);await frames(8)
	game.place_player(Vector3(0,-41.95,5));await frames(6)
	game.camera.look_at(Vector3(0,-42,0))
	game.inventory_board.toggle();await frames(6)
	await press(game.inventory_board.place_button.get_node("PushButton"));await frames(15)
	var copies: Array=game.building.content.data.floors[7].get("copies",[])
	check("real inventory pointer click adds exactly one session assembly in a clear bay",copies.size()==1)
	if copies.size()==1:
		var mount: Node3D=game.building.content.exhibits["7/"+str(copies[0].id)]
		var placed: Node3D=mount.get_node("Artifact")
		check("placed recipe uses actual source and all editable parts",placed.scene_file_path=="res://commons/artifacts/matter_gates/matter_and.tscn" and placed.part_defaults.size()>=16 and not placed.fragment)
		check("placed copy retains catalogue control arrangement",placed.get_node("Controls").position.is_equal_approx(Vector3(0,0,2)))
		await photo("03-inventory-session-copy",placed.to_global(Vector3(0,3.8,7.5)),placed.to_global(Vector3(0,1.7,-.4)))
		game.place_inventory_prefab("matter_and")
		check("occupied bay refuses overlapping repeat placement",game.building.content.data.floors[7].copies.size()==1)
	var fragment: Node3D=load("res://commons/artifacts/matter_gates/matter_and.tscn").instantiate()
	game.add_child(fragment);fragment.position=Vector3(16,-42,4)
	fragment.apply_grid_config({"only_parts":["InputX"],"parts":{"InputX":{"position":[0,0,0],"rotation":[0,90,0]}}})
	check("independent editor input copy has no lesson completion controller",fragment.fragment and fragment.get_child_count()==1)
	check("independent editor input retains its saved turn",is_equal_approx(fragment.get_node("InputX").rotation_degrees.y,90))
	FileAccess.open(out.path_join("followup-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual earned isolated save, real pointer on inventory placement button; empty-bay structural fixture only for session-copy clearance. Saved Cube user arrangement unchanged."},"  "))
	print("MATTER_INVENTORY_FOLLOWUP ",failed);quit(0 if failed.is_empty() else 1)
