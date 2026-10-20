extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	game.checkpoint=2
	game.place_player(game.spawn_for(2))
	await frames(45)
	var floor: Node3D=game.building.floors[2]
	var held: Node3D=game.building.content.exhibits["2/held"].get_node("Artifact")
	check("Coordinates has no recessed basin",not floor.has_node("Basin") and floor.get_meta("basin",{}).is_empty())
	check("Point has no plinth mesh or plinth collider",not held.has_node("HeldPointPlinth") and held.find_children("PlinthCollision","StaticBody3D",true,false).is_empty())
	check("Original point remains at grabbing height",held.point==game.coordinate_point and is_equal_approx(held.point.position.y,1.12))
	for xz in [Vector2(-3,-1),Vector2(-3,2),Vector2(0,3),Vector2(2,3)]:
		var hit := ray(Vector3(xz.x,-11.5,xz.y),Vector3(xz.x,-12.15,xz.y))
		check("Solid walkable floor replaces recess at "+str(xz),not hit.is_empty() and hit.collider.get_meta("void_floor_index",-1)==2 and is_equal_approx(hit.position.y,-12.0))
	var lamp: OmniLight3D=held.point.get_node("CarriedLight")
	check("Pickup illumination remains attached to the black point",lamp.get_parent()==held.point and not lamp.visible)
	game.atmosphere.animate_sky=false
	game.atmosphere.set_sky_time(180)
	game._set_enabled(false)
	await photograph("coordinates-floor.png",Vector3(3.4,-9.8,-4.8),Vector3(-1.1,-11.1,1.5),72)
	await photograph("point-no-plinth.png",Vector3(1.8,-10.1,-2.5),held.point.global_position-Vector3(0,.3,0),68)
	game.queue_free();await frames(15)
	await coordinate_checks()
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot floor collision, real point, synthetic XR pickup/release/readouts/retry; no physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)
