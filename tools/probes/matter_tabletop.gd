extends "res://tools/probes/matter_gates_probe.gd"
## Actual main-floor miniature mechanics and existing reward; isolated inventory.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	level=7;take_photos=true
	for mode in [false,true]:
		xr=mode
		OS.set_environment("VOID_INVENTORY_PATH",out.path_join("isolated-"+str(mode)+"-"+str(Time.get_ticks_usec())+".json"))
		if xr:
			head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
			left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
			right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
			left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		game=load("res://commons/void/void.tscn").instantiate();game.force_xr=xr
		root.add_child(game);current_scene=game
		if not xr:game.body.scripted_input=true
		await frames(60);game.scene_loaded();game.scene_visible();await frames(30)
		game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180);game.atmosphere.environment.fog_enabled=false
		var gate: Node3D=station("matter-and")
		var tag := "Synthetic XR / " if xr else "Desktop / "
		game.place_player(gate.to_global(Vector3(.08,.06,1.0)));await frames(15)
		var stance: Vector3=game.body.global_position
		check(tag+"saved floor7 position and root scale preserved",gate.global_position.is_equal_approx(Vector3(0,-42,-.25)) and gate.scale.is_equal_approx(Vector3.ONE))
		check(tag+"1.8 by 0.85 m supported timber tabletop",gate.get_node("Tabletop").body_size.is_equal_approx(Vector3(1.8,.06,.85)) and gate.has_node("TableSupportLeft") and gate.has_node("TableSupportRight"))
		check(tag+"12 cm input colliders use unit rigid-body transforms",gate.cubes.all(func(c):return c.scale.is_equal_approx(Vector3.ONE) and c.get_node("CubeCollision").shape.size.is_equal_approx(Vector3.ONE*.12)))
		check(tag+"human sized lift grip and front control spacing",gate.ball_box.handle.get_node("GripCollision").shape.size.z>=.09 and absf(gate.buttons[1].position.x-gate.buttons[0].position.x)>=.2)
		check(tag+"AND starts locked",not game.prefab_inventory.unlocked("matter_and"))
		if not xr:await photo("01-tabletop-ready",gate.to_global(Vector3(1.8,2.0,2.2)),gate.to_global(Vector3(.05,.95,0)))
		for value in [Vector2i.ZERO,Vector2i(0,1),Vector2i(1,0),Vector2i.ONE]:
			await press(gate.buttons[3].get_node("PushButton"))
			if value.x:await press(gate.buttons[0].get_node("PushButton"))
			if value.y:await press(gate.buttons[1].get_node("PushButton"))
			await press(gate.buttons[2].get_node("PushButton"))
			await await_result(gate)
			print("TABLETOP_PATH ",tag,value," outcome=",gate.outcome," ball=",gate.to_local(gate.ball.global_position)," cubes=",gate.cubes.map(func(c):return c.position))
			check(tag+"real controls / physical AND "+str(value),gate.outcome==(1 if value==Vector2i.ONE else 0))
			check(tag+"outcome is actual arrival or an actual fall, never a stalled timeout",gate.outcome==1 or gate.to_local(gate.ball.global_position).y<gate.TABLE_HEIGHT+.5*gate.UNIT)
			check(tag+"reward follows final physical observation",game.prefab_inventory.unlocked("matter_and")==(value==Vector2i.ONE))
		check(tag+"all controls usable from the same standing place",game.body.global_position.distance_to(stance)<.02)
		game.prefab_inventory.reload()
		check(tag+"earned assembly survives inventory reload",gate.lesson_complete and game.prefab_inventory.unlocked("matter_and"))
		if not xr:await photo("02-tabletop-arrival",gate.to_global(Vector3(.4,1.65,1.8)),gate.to_global(Vector3(.05,1.05,-.05)))
		await prepare_both(gate)
		var box: Node3D=gate.ball_box
		var grip: CollisionShape3D=box.handle.get_node("GripCollision")
		var closed: Vector3=grip.global_position
		if await input_grab(tag+"retained lever / ",box.handle,grip,.35,.04):
			await input_tip_to(grip,closed+Vector3.UP*.11)
			await let_go()
			check(tag+"real hand pull opens retained tabletop gate",box.opened and box.track.slider_position>.07)
			await await_result(gate)
			check(tag+"hand lifted release preserves physical arrival",gate.outcome==1)
		await prepare_both(gate)
		var shape: CollisionShape3D=gate.ball.get_child(0)
		if await input_grab(tag+"marble / ",gate.ball,shape,.3,.045):
			await input_tip_to(shape,box.to_global(Vector3(.09,.09,0)))
			await let_go()
			await await_result(gate)
			check(tag+"hand dropped marble reaches receiver",gate.outcome==1 and not box.opened)
		# Complete construction must retain physics after editor pose changes.
		gate.position+=Vector3(0,0,-.5);gate.rotation_degrees.y=25;gate._sync_bodies(gate)
		gate.reset_gate();gate.set_gate(0,true);gate.set_gate(1,true);gate.release_ball();await await_result(gate)
		check(tag+"moved and rotated tabletop still computes AND",gate.outcome==1)
		game.queue_free();await frames(10)
		if xr:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual main floor7, real desktop mouse and synthetic XR trigger/grip, four physical ball outcomes, same control stance, hand release/drop, saved reward, moved/rotated layout. No physical headset."},"  "))
	print("MATTER_TABLETOP_RESULT ",checks.size()," ",failed);quit(0 if failed.is_empty() else 1)

func prepare_both(gate: Node3D) -> void:
	await press(gate.buttons[3].get_node("PushButton"))
	for i in 2:await press(gate.buttons[i].get_node("PushButton"))
	await frames(60)
