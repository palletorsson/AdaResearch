extends "res://tools/probes/rotation_tower_probe.gd"
const FLOOR_Y := -102.0

func item(id: String) -> Node3D:
	return game.building.content.exhibits["17/"+id].get_node("Artifact")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated test saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for mode in ([false] if take_photos else [false,true]):
		await start(mode)
		var tag := "XR / " if mode else "Desktop / "
		check(tag+"Scale remains floor 17 with nine editable placements",game.checkpoint==17 and game.building.content.data.floors[17].artifacts.size()==9)
		var room:=item("drink-me")
		var before_frame:Transform3D=room.witness.global_transform
		var before_foundation:Transform3D=room.get_node("Foundation").global_transform
		for key in ["cake","together","opposed","spindle","flare","ziggurat","column"]:
			var carousel:=item("carousel-"+key)
			var old:Basis=carousel._collider_bodies[0].basis
			await frames(8)
			check(tag+key+" has eight actually spinning layers and matching colliders",carousel.mm_inst.multimesh.instance_count==8 and carousel._collider_bodies.size()==8 and not carousel._collider_bodies[0].basis.is_equal_approx(old))
		check(tag+"uniform and counter-turning configurations use different rules",is_equal_approx(item("carousel-together")._layer_speed(7),.3) and item("carousel-opposed")._layer_speed(1)<0 and item("carousel-opposed")._layer_speed(2)>0)
		check(tag+"original bottle, figure, food tower and thirteen serving plates present",is_instance_valid(room.bottle) and is_instance_valid(room.figure) and is_instance_valid(room.table) and room.landings.size()==13)
		if take_photos:
			game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
			root.msaa_3d=Viewport.MSAA_4X
			for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
			game.status.hide();game.charge_display.hide();game.notice_time=-1
			await photograph("carousel-floor",Vector3(-6,FLOOR_Y+3.5,-1),Vector3(12,FLOOR_Y+1.8,-4.2))
			await photograph("seven-carousels",Vector3(-20,FLOOR_Y+3.5,1),Vector3(1,FLOOR_Y+1.5,0))
			await photograph("scale-chamber-small",room.to_global(Vector3(23,15,2)),room.to_global(Vector3(0,6,8)))
			await photograph("scale-before-inside",room.to_global(Vector3(0,1.65,.3)),room.to_global(Vector3(0,1.4,2.5)))
		# Enter by walking from the actual shared floor; the middle carousel has
		# a clear route on its east side to the three-metre bridge.
		game.place_player(Vector3(4,FLOOR_Y+.06,0));await frames(20)
		check(tag+"walk past the central carousel",await walk(Vector3(4,FLOOR_Y,8)))
		check(tag+"reach the bridge",await walk(Vector3(0,FLOOR_Y,8)))
		check(tag+"walk into original small room",await walk(room.to_global(Vector3(0,.04,.6))))
		var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.22
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.exclude=[game.body.get_rid()]
		query.transform.origin=room.room.to_global(Vector3(1.2,0,3.5))+Vector3.UP*.81
		query.motion=room.global_basis*Vector3(0,0,1)
		check(tag+"ordinary body cannot cross tiny door",game.get_world_3d().direct_space_state.cast_motion(query)[0]<.99)
		var body_scale:Vector3=game.body.global_basis.get_scale()
		var charge_before:float=game.charge.get_charge()
		if mode:
			game.pickups[1]._pick_up_object(room.bottle)
		else:
			var pointer:Node=game.body.desktop_pointer
			game.camera.look_at(room.bottle.global_position)
			var target:Node3D=pointer._find_grabbable()
			check(tag+"desktop aim finds original bottle",target==room.bottle)
			pointer._grab_held(room.bottle)
		await frames(16)
		print("SCALE_STATE ",tag," enlarged ",room.enlarged," scale ",room.room.scale," consumed ",room.bottle.consumed," visible ",room.bottle.visible," feet ",game.body.global_position," top ",room.table.to_global(room.landings[0])," charge ",game.charge.get_charge()," prior ",charge_before)
		check(tag+"real pickup enlarges room fourfold and consumes bottle",room.enlarged and room.room.scale.is_equal_approx(Vector3.ONE*4) and room.bottle.consumed and not room.bottle.visible)
		check(tag+"body, outer foundation and witness door stay unchanged",game.body.global_basis.get_scale().is_equal_approx(body_scale) and room.witness.global_transform.is_equal_approx(before_frame) and room.get_node("Foundation").global_transform.is_equal_approx(before_foundation))
		var top:Vector3=room.table.to_global(room.landings[0])
		check(tag+"visitor lands on the original top plate",game.body.global_position.distance_to(top)<.16 and game.body.is_on_floor())
		check(tag+"tall room stays live as floor 17",game.floor_stream.focus==17 and game.floor_stream.records[17].mode=="live")
		check(tag+"scale cut spends no walking or falling charge",is_equal_approx(game.charge.get_charge(),charge_before) and game.deaths==0)
		query.transform.origin=room.room.to_global(Vector3(1.2,0,3.8))+Vector3.UP*.81
		query.motion=room.global_basis*Vector3(0,0,4)
		check(tag+"same body clears enlarged door and fixed witness door",game.get_world_3d().direct_space_state.cast_motion(query)[0]>.99)
		if take_photos:
			await photograph("scale-on-the-plate",game.camera.global_position,room.figure.to_global(Vector3(0,1.2,0)))
			await photograph("scale-chamber-large",room.to_global(Vector3(23,15,2)),room.to_global(Vector3(0,6,8)))
			await photograph("scale-after-inside",room.to_global(Vector3(0,1.65,1)),room.to_global(Vector3(0,4,8)))
		var descended:=true
		for i in range(1,room.landings.size()):
			var target:Vector3=room.table.to_global(room.landings[i])
			if not await walk(target):
				descended=false;break
		check(tag+"walk down all thirteen original serving plates",descended and game.deaths==0)
		# Continue through the two doors and the real exterior return route.
		if descended:
			check(tag+"step from last plate to room floor",await walk(room.to_global(Vector3(-4,.04,5))))
		check(tag+"walk around the food and figure to the exit",await walk(room.to_global(Vector3(-4,.04,2))) and await walk(room.to_global(Vector3(6.5,.04,2))) and await walk(room.to_global(Vector3(6.5,.04,15))) and await walk(room.to_global(Vector3(4.8,.04,15))))
		check(tag+"walk through both doorways",await walk(room.to_global(Vector3(4.8,0,18.5))))
		check(tag+"return along west side of enlarged room",await walk(room.to_global(Vector3(-9,0,18.5))) and await walk(room.to_global(Vector3(-9,0,-1))))
		check(tag+"return to tower across bridge",await walk(room.to_global(Vector3(0,0,-1))) and await walk(Vector3(0,FLOOR_Y,8)))
		check(tag+"Scale checkpoint survives tall exterior visit",game.checkpoint==17 and game.deaths==0)
		# The extension owns its volume, not the whole sky or another floor.
		check(tag+"ordinary tower heights still select Rotation",game.floor_stream.floor_at_position(Vector3(4,FLOOR_Y+7,0))==16)
		game.die("Retry");await frames(130)
		check(tag+"retry restores the small room and bottle on Scale",game.checkpoint==17 and not item("drink-me").enlarged and item("drink-me").bottle.visible and not game.recovering)
		game.soundscape.set_process(false)
		game.queue_free();await frames(20)
		if mode:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"physical_headset":"not tested"},"\t"))
	quit(0 if failed.is_empty() else 1)
