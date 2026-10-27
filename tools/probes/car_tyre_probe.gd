extends "res://tools/probes/triangle_shaft_quad_probe.gd"
## One short real walking push, followed by free rolling with no contact force.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in [false,true]:
		await start(mode)
		var tag := "XR: " if xr else "Desktop: "
		game.checkpoint=10
		var hall: Node3D=game.building.content.exhibits["10/hall"].get_node("Artifact")
		var tyre: RigidBody3D=hall.get_node("RollingTyre_O")
		game.place_player(Vector3(-3.3,-59.94,1.7))
		await frames(35)
		var size: Vector3=tyre.get_node("RubberGlyph").mesh.get_aabb().size
		check(tag+"car tire diameter and width",size.y>.65 and size.y<.75 and size.z>.20 and size.z<.24)
		check(tag+"rests on floor at wheel radius",absf(tyre.global_position.y+60-size.y/2)<.04)
		check(tag+"hub stays physically open",ray(tyre.global_position+Vector3.FORWARD,tyre.global_position+Vector3.BACK).is_empty())
		var start: Vector3=tyre.global_position
		axes(Vector2(-1,0))
		await frames(50)
		axes(Vector2.ZERO)
		var released: Vector3=tyre.global_position
		check(tag+"walking contact pushes the tire",released.x<start.x-.25)
		# Take the visitor away: subsequent travel cannot come from another push.
		game.place_player(Vector3(-2.2,-59.94,3.8))
		var basis_before := tyre.global_basis
		await frames(70)
		var travel: float=released.distance_to(tyre.global_position)
		print("CAR_TIRE_ROLL ",tag," size=",size," initial=",start," release=",released," final=",tyre.global_position," free_travel=",travel," speed=",tyre.linear_velocity.length())
		check(tag+"rolls away after the push ends",travel>.4 and not tyre.global_basis.is_equal_approx(basis_before))
		check(tag+"visitor stays safe",game.deaths==0 and game.checkpoint==10)
		if not xr:
			game.body.hide()
			game.get_node("CareBody").hide()
			for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
			tyre.freeze=true
			tyre.global_transform=Transform3D(Basis.IDENTITY,start)
			PhysicsServer3D.body_set_state(tyre.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,tyre.global_transform)
			await photograph("car-sized-o-tire",Vector3(-2.8,-58.55,3.8),start)
		game.queue_free()
		await frames(12)
		if xr:
			for tracker_item in [head,left,right]: XRServer.remove_tracker(tracker_item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real desktop and synthetic-XR walking push followed by free rolling with visitor moved away. No physical headset."},"\t"))
	quit(0 if failed.is_empty() else 1)
