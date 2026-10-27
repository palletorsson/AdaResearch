extends "res://tools/probes/lines_combined_room_probe.gd"
## Focused real-body descent and scene trigger, with the two native input rigs.
func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO)
		right.set_input("primary",Vector2.ZERO)
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = xr
	root.add_child(game)
	current_scene = game
	if not xr: game.body.scripted_input = true
	await frames(45)
	game.scene_loaded()
	game.scene_visible()
	await frames(30)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	if "--capture-only" in OS.get_cmdline_user_args():
		await start(false)
		game.body.hide()
		game.get_node("CareBody").hide()
		for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
		var quad: Node3D = game.building.content.exhibits["5/surfaces"].get_node("Artifact/ShaftQuad")
		quad.drop_test_points()
		await frames(8)
		await photograph("white-points-released-from-above",Vector3(-13.2,-27.1,5),Vector3(-10,-30.8,0))
		await frames(35)
		await photograph("construction-wood-quad",Vector3(-11.5,-29.2,2.9),Vector3(-10,-31.65,0))
		quit(0)
		return
	for mode in [false,true]:
		await start(mode)
		var tag := "XR: " if xr else "Desktop: "
		game.checkpoint = 5
		game.place_player(Vector3(-10,-29.94,4.2))
		await frames(70)
		var content: Node3D = game.building.content
		var surfaces: Node3D = content.exhibits["5/surfaces"].get_node("Artifact")
		var quad: Node3D = surfaces.get_node("ShaftQuad")
		check(tag+"quad has four source vertices and two triangles",quad.vertex_positions.size()==4 and quad.surface_shape.get_faces().size()==6)
		check(tag+"quad uses original artifact geometry",quad.triangle_mesh_a_front.mesh.get_faces().size()==6 and quad.triangle_mesh_b_front.mesh.get_faces().size()==6)
		check(tag+"construction wood is textured matte timber",quad.wood_finish.albedo_texture!=null and quad.wood_finish.roughness>.8 and quad.wood_finish.metallic==0 and quad.panel_edges.mesh.get_faces().size()==24)
		check(tag+"starts below Triangle in shaft A",quad.global_position.distance_to(Vector3(-10,-31.65,0))<.01 and is_equal_approx(quad.rotation_degrees.x,-25))
		check(tag+"slope is real shared collision",quad.support.collision_layer==1 and quad.support.get_meta("void_slippery_surface"))
		check(tag+"gravity test waits for the jump",quad.ball_test.balls.is_empty())
		await move_to(Vector3(-10,-30,3.7))
		axes(Vector2(0,-1))
		press_jump()
		await frames(2)
		release_jump()
		var touched := false
		var slid := false
		var jumping_from_quad := false
		var slide_start := Vector3.ZERO
		for i in 380:
			var pos: Vector3 = game.body.global_position
			var query := PhysicsRayQueryParameters3D.create(pos+Vector3.UP*.12,pos-Vector3.UP*.28,1)
			query.exclude = [game.body.get_rid()]
			var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit.collider==quad.support and (game.body.on_ground if xr else game.body.is_on_floor()):
				if not touched:
					touched = true
					slide_start = pos
					axes(Vector2.ZERO)
				if pos.z < slide_start.z-.5: slid = true
				if pos.z < -2.2 and not jumping_from_quad:
					jumping_from_quad = true
					press_jump()
					axes(Vector2(0,-1))
			elif jumping_from_quad:
				release_jump()
			if game.recovering: break
			if game.body.global_position.y < -35.8 and (game.body.on_ground if xr else game.body.is_on_floor()): break
			await frames(1)
		axes(Vector2.ZERO)
		await frames(25)
		print("QUAD_DESCENT ",tag," feet=",game.body.global_position," touched=",touched," slid=",slid," jump=",jumping_from_quad," deaths=",game.deaths)
		check(tag+"jump lands on tilted quad",touched)
		check(tag+"standing still slides downhill",slid)
		check(tag+"can jump off the quad",jumping_from_quad)
		check(tag+"jump into void releases fifteen gravity points",quad.ball_test.releases>0 and quad.ball_test.balls.size()==15)
		check(tag+"all test balls are white and use real gravity",quad.ball_test.balls.all(func(b):return b.gravity_scale==1.0 and b.get_node("WhitePoint").material_override.albedo_color==Color.WHITE))
		check(tag+"surface-test balls do not push the player",quad.ball_test.balls.all(func(b):return (b.collision_layer & game.body.collision_mask)==0 and (b.collision_mask & game.body.collision_layer)==0))
		check(tag+"real balls contacted the quad",quad.ball_test.contacts.has(quad.support.get_instance_id()))
		check(tag+"balls roll off toward the next floor",quad.ball_test.balls.any(func(b):return b.global_position.y< -35.4))
		check(tag+"reach Polyhedra floor below alive",not game.recovering and game.deaths==0 and game.checkpoint==6 and game.body.global_position.y< -35.8)
		check(tag+"authored descent stays live across floor change",5 in game.floor_stream.pinned)
		if not xr:
			quad.ball_test.cooldown = 0
			quad.drop_test_points()
			await frames(40)
			game.body.hide()
			game.get_node("CareBody").hide()
			for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
			await photograph("triangle-quad-descent",Vector3(-14,-27.8,5.3),Vector3(-9.9,-32.2,-.5))
			await photograph("quad-gravity-points",Vector3(-9.6,-31.3,5.8),Vector3(-10,-33,-1.3))
		var pose: Transform3D = quad.transform
		quad.position.x += .2
		quad.rotation.y = .1
		await frames(3)
		check(tag+"collision follows editable quad",quad.support.global_transform.is_equal_approx(quad.global_transform))
		quad.transform = pose
		game.queue_free()
		await frames(15)
		if xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual main tower, desktop and synthetic XR jump/slide/descent and physical white surface-test balls. No physical headset."},"\t"))
	print("TRIANGLE_QUAD_RESULT ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)
