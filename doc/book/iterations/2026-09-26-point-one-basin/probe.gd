extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var frame := find_scene("/CoordinateSystem3M.gd")
	check("coordinate frame present", frame != null)
	if frame == null: return
	var deck: float = hall.global_position.y
	check("coordinate origin sits in the basin", absf(frame.global_position.y - deck + 0.9) < 0.02)
	var point: Node3D = frame._find_point()
	check("frame still follows the carried point", point != null and point.get_meta("coordinate_id", "") == "point_one_main")
	var space := hall.get_world_3d().direct_space_state
	var p := frame.global_position + Vector3(1.2,0,1.0)
	var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x,deck+0.2,p.z),Vector3(p.x,deck-0.3,p.z),1)
	var hit := space.intersect_ray(ray)
	check("glass supports the visitor at deck height", not hit.is_empty() and absf(hit.position.y-deck)<0.02)
	ray = PhysicsRayQueryParameters3D.create(Vector3(p.x,deck-0.15,p.z),Vector3(p.x,deck-1.3,p.z),1)
	hit = space.intersect_ray(ray)
	check("basin has a solid floor one metre down", not hit.is_empty() and absf(hit.position.y-deck+1.0)<0.02)
	var walker := CharacterBody3D.new()
	walker.collision_layer=0;walker.collision_mask=1
	var shape := CollisionShape3D.new(); var capsule := CapsuleShape3D.new()
	capsule.radius=0.32;capsule.height=1.5;shape.shape=capsule;shape.position.y=0.75
	walker.add_child(shape);root.add_child(walker)
	walker.global_position=Vector3(frame.global_position.x+2.5,deck+0.02,frame.global_position.z-6.5)
	await physics_frame
	check("visitor can cross the glass without a raised lip",walker.move_and_collide(Vector3(0,0,8.5))==null)
	check("pool crossing returns to supported floor",not floor_at(walker.global_position).is_empty())
	walker.queue_free()
	var count := 0
	for n in hall.find_children("*","Node3D",true,false):
		if "readout_channel" in n and str(n.get("readout_channel"))=="point_one_main" and n.has_method("show_coordinates"):
			count+=1
			var q: Vector3 = point.global_position if n.space=="world" else frame.to_local(point.global_position)
			check(n.space+" reports the held point in the correct frame",n.get_node("Value").text=="x = %.2f\ny = %.2f\nz = %.2f" % [q.x,q.y,q.z])
	check("both readout cards remain present",count==2)
	observations["frame_position"]=xyz(frame.global_position)
	await snapshot("basin",Vector3(frame.global_position.x+5.5,deck+1.65,frame.global_position.z-5.5),Vector3(frame.global_position.x+1.0,deck-0.2,frame.global_position.z-1.0),65)
	await snapshot("basin-close",Vector3(frame.global_position.x+3.4,deck+1.65,frame.global_position.z+2.4),Vector3(frame.global_position.x+0.9,deck-0.45,frame.global_position.z-0.8),65)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum geometry, collision and coordinate readouts. No headset acceptance claimed."},"  "))
	print("COORDINATE BASIN ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
