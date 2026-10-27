extends "res://tools/probes/void_game_probe.gd"
## Actual main tower: collider residency and a production CharacterBody attempt.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	game=load("res://commons/void/void.tscn").instantiate();root.add_child(game);current_scene=game
	game.body.scripted_input=true;game.body.set_process_unhandled_input(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	game.scene_loaded();game.scene_visible();await frames(8)
	var tunnel: Node3D=game.building.content.exhibits["16/twisting-tunnel"].get_node("Artifact")
	await tunnel.prepare_editor_preview();await frames(4)
	var deaths: Array=[];game.died.connect(func(reason):deaths.append({"reason":reason,"at":str(game.body.global_position)}))
	var source: MeshInstance3D=tunnel.get_node("Portal20/Source/PortalResult")
	var arrays: Array=source.mesh.surface_get_arrays(0);var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	var triangle: Array[Vector3]=[]
	for k in 3:triangle.append(source.to_global(vertices[indices[k] if indices.size()>0 else k]))
	var centre: Vector3=(triangle[0]+triangle[1]+triangle[2])/3
	var normal: Vector3=(triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).normalized()
	for floor in [17,18]:
		game.place_player(Vector3(8.5,-6*floor+.06,5))
		game.floor_stream.set_focus(floor);await frames(5)
		var hit: Dictionary=get_root().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(centre+normal*.1,centre-normal*.1,1))
		if hit.is_empty():hit=get_root().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(centre-normal*.1,centre+normal*.1,1))
		check("lower portal collider remains in Jolt while visiting floor %d"%floor,not hit.is_empty() and tunnel.is_ancestor_of(hit.collider) and 16 in game.floor_stream.pinned and game.floor_stream.records[16].mode=="live")
	game.place_player(Vector3(8.5,-95.94,5));await frames(12)
	var poses: Array[Vector3]=[]
	for i in 24:poses.append(tunnel.get_node("Portal%02d/Source"%(i+1)).global_position)
	var trace: Array=[];var lowest: float=game.body.global_position.y;var collided:=false
	for frame in 900:
		var at: Vector3=game.body.global_position;lowest=minf(lowest,at.y)
		var target: Vector3=poses[0]
		if at.z>2.1 and at.y> -96.3:target=Vector3(9.5,-96,1.6)
		else:
			for point in poses:
				target=point
				if point.y<at.y+.6:break
			if at.y< -107:target=tunnel.get_node("ExitBridge").global_position+Vector3(-.2,0,1.3)
		game.body.drive=Vector2(target.x-at.x,target.z-at.z).limit_length()
		# The authored invitation is to jump into the thick portal rim.
		if frame==90 and game.body.is_on_floor():game.body.jump_queued=true
		for i in game.body.get_slide_collision_count():
			if tunnel.is_ancestor_of(game.body.get_slide_collision(i).get_collider()):collided=true
		if frame%15==0:trace.append({"frame":frame,"position":[at.x,at.y,at.z],"focus":game.floor_stream.focus,"charge":game.charge.get_charge(),"grounded":game.body.is_on_floor()})
		if game.recovering or (at.y< -107.8 and game.body.is_on_floor()):break
		await frames(1)
	game.body.drive=Vector2.ZERO;await frames(20)
	check("real player body contacts the tunnel's physical collision",collided)
	check("actual descent attempt causes no death or pain feedback",deaths.is_empty() and game.deaths==0 and game.soundscape.hurt_count==0)
	var reached: bool=game.body.global_position.y< -107.8 and game.body.is_on_floor()
	check("real player body reaches the lower exit level",reached)
	var contacts: Array=[]
	for i in game.body.get_slide_collision_count():
		var hit: KinematicCollision3D=game.body.get_slide_collision(i);contacts.append({"collider":str(hit.get_collider().get_path()),"point":str(hit.get_position()),"normal":str(hit.get_normal())})
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"deaths":deaths,"contacts":contacts,"lowest_y":lowest,"end":str(game.body.global_position),"trace":trace,"scope":"Actual main tower and production desktop CharacterBody, live Jolt triangle collision across streaming boundaries and a scripted walk/jump descent attempt. No physical headset acceptance."},"  "))
	game.queue_free();await frames(10);quit(0 if failed.is_empty() else 1)
