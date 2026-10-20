extends "res://tools/probes/void_game_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	for use_xr in [false,true]:
		await start(use_xr)
		var crate: Node3D = game.building.content.props["0/arrival-crate"].get_node("Prefab")
		var counter: Node3D = game.building.content.exhibits["0/clock"].get_node("Artifact")
		var mode := "XR" if use_xr else "desktop"
		var grid: MeshInstance3D = game.building.floors[0].get_node("OriginFloorGrid")
		check(mode+": floor grid is centred on world zero and clears slab depth",grid.global_position.is_equal_approx(Vector3(0,0.008,0)) and grid.mesh.size.is_equal_approx(Vector2(5.2,5.2)))
		check(mode+": black origin sphere stays at true zero",game.building.content.roots[0].get_node("WorldZero/OriginSphere").global_position.is_equal_approx(Vector3.ZERO))
		var roof_details: Node3D = game.building.floor_details[0]
		var mains := roof_details.get_children().filter(func(node): return node is MeshInstance3D and node.mesh is CylinderMesh and is_equal_approx(node.mesh.top_radius,0.14))
		var electrical := roof_details.get_children().filter(func(node): return node is MeshInstance3D and node.mesh is CylinderMesh and is_equal_approx(node.mesh.top_radius,0.07))
		check(mode+": roof keeps main pipes without pink electrical risers",electrical.is_empty() and mains.size()==2)
		check(mode+": roof has no decorative pink artifact feeds",game.building.content.roots[0].find_children("Lead_*","Node3D",false,false).is_empty() and game.building.content.roots[0].find_children("SupplyCable*","",false,false).is_empty())
		check(mode+": player starts inside crate",crate.inside(game.camera.global_position))
		check(mode+": stationary player does not break panel",not crate.broken and not crate.panel_shape.disabled)
		check(mode+": closed panel blocks sightline",sight_hit(crate).get("collider")==crate.panel_shape.get_parent())
		check(mode+": outside cannot break inward wall",not crate.strike(crate.to_global(Vector3(0,1.4,-2)),crate.to_global(Vector3(0,1.4,-1.4))))
		check(mode+": back wall does not open exit",not crate.strike(crate.to_global(Vector3(0,1.4,0)),crate.to_global(Vector3(0,1.4,1.4))))
		var before: String = counter.label.text
		if not use_xr:
			game.status.hide()
			game.notice_time = 0.0
			game.desktop_help.hide()
			if "--capture" in OS.get_cmdline_user_args(): await picture("inside-closed.png")
			var pointer: Node3D = game.body.desktop_pointer
			game.camera.look_at(crate.to_global(Vector3(0,1.45,-1.4)))
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			await frames(6)
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			Input.parse_input_event(press)
			await frames(3)
			press = InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = false
			Input.parse_input_event(press)
		else:
			# Actual XR tracker poses feed the production sweep, not a direct
			# call to the break method. Approach, settle, then strike the panel.
			hand_at(right,crate.to_global(Vector3(0.25,1.4,-1.05)))
			await frames(5)
			check("XR: hand resting near panel is not a strike",not crate.broken)
			hand_at(right,crate.to_global(Vector3(0.25,1.4,-1.34)))
		await frames(55)
		check(mode+": real input opens panel",crate.broken and crate.panel_shape.disabled and not crate.panel.visible)
		check(mode+": opening reveals clear line toward counter",sight_hit(crate).is_empty())
		check(mode+": existing counter keeps advancing",before!=counter.label.text)
		check(mode+": other walls retain collision",not crate.get_node("LeftWall").get_child(0).disabled)
		crate.break_panel()
		check(mode+": second strike is harmless",crate.broken)
		if not use_xr and "--capture" in OS.get_cmdline_user_args():
			game.camera.look_at(counter.global_position+Vector3(0,1.5,0))
			await picture("inside-open.png")
		check(mode+": player can walk through the opened side",await move_to(crate.to_global(Vector3(0,0.06,-2.3)),false,150))
		game.place_player(game.spawn_for(0))
		await frames(10)
		check(mode+": return to roof leaves opened exit usable",crate.broken and crate.panel_shape.disabled)
		if not use_xr and "--capture" in OS.get_cmdline_user_args():
			game.place_player(Vector3(4,0.06,0.4))
			game.camera.look_at(crate.to_global(Vector3(0,1.3,0)))
			await picture("roof-crate.png")
			game.place_player(Vector3(3.8,0.06,8.0))
			game.camera.look_at(crate.to_global(Vector3(0,1.5,0.8)))
			await picture("shipping-label.png")
			game.place_player(Vector3(1.9,0.06,2.65))
			game.camera.look_at(Vector3(0,0,0))
			await picture("point-zero-grid.png")
		# Simulate a lab-editor placement without writing over curated rooms.
		var entry: Dictionary = game.building.content.data.floors[0].props.filter(func(item): return item.kind=="arrival_crate")[0]
		entry.position = [-2.0,4.0]
		entry.facing = 90
		crate.get_parent().position = Vector3(-2,0,4)
		crate.get_parent().rotation_degrees.y = 90
		game.place_player(game.spawn_for(0))
		await frames(5)
		check(mode+": editor placement carries spawn and facing",crate.inside(game.camera.global_position) and game.camera.global_basis.z.dot(crate.global_basis.z)>0.99)
		game.queue_free()
		await frames(4)
		if use_xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
	quit(0 if failed.is_empty() else 1)

func sight_hit(crate: Node3D) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(crate.to_global(Vector3(0,1.65,0)),crate.to_global(Vector3(0,1.65,-3)),1)
	query.exclude = [game.body.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_ray(query)

func picture(filename: String) -> void:
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
