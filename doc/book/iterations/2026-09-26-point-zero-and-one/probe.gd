extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.5).timeout
	if map_id == "Point_Zero":
		await zero_checks()
	else:
		await one_checks()

func zero_checks() -> void:
	var shaft := find_scene("/arrival_shaft.gd")
	var counter := find_scene("/frame_counter_display.gd")
	var origin := find_scene("/origin.gd")
	var fold := find_scene("/animated_folding_past.gd")
	check("arrival shaft, frame counter, folding and origin present", shaft != null and counter != null and origin != null and fold != null)
	if shaft == null or counter == null or origin == null: return
	check("Point zero label belongs to origin", origin.beam_label == "Point zero")
	var arrival: Vector3 = museum._drop_point()
	check("arrival aligned inside shaft", Vector2(arrival.x-shaft.global_position.x,arrival.z-shaft.global_position.z).length() < 0.1)
	check("counter ahead of falling visitor", counter.global_position.z > shaft.global_position.z and absf(counter.global_position.x-shaft.global_position.x) < 0.1)
	var floor := floor_at(shaft.global_position)
	check("floor below open shaft", not floor.is_empty())
	var ray := PhysicsRayQueryParameters3D.create(shaft.global_position+Vector3(0,6,0),shaft.global_position+Vector3(0,0.1,0),1)
	var walker: CharacterBody3D = museum.get("_player")
	ray.exclude = [walker.get_rid()]
	var hit := shaft.get_world_3d().direct_space_state.intersect_ray(ray)
	observations["shaft_ray"] = {"hit":str(hit.get("collider","none")),"position":str(hit.get("position","none"))}
	check("shaft has no blocking cap", hit.is_empty())
	walker.global_position = arrival
	walker.velocity = Vector3.ZERO
	museum.set_physics_process(true)
	await create_timer(2.0).timeout
	museum.set_physics_process(false)
	check("real museum walker falls onto arrival floor",absf(walker.global_position.y-shaft.global_position.y)<0.05 and walker.is_on_floor())
	observations["landed"] = xyz(walker.global_position)
	observations["arrival"] = xyz(arrival)
	observations["counter"] = xyz(counter.global_position)
	await snapshot("arrival-counter",shaft.global_position+Vector3(0,1.65,-0.5),counter.global_position,64)
	await snapshot("falling",shaft.global_position+Vector3(0,3.9,0),counter.global_position,66)
	await snapshot("origin",origin.global_position+Vector3(-1.6,0.7,-2.5),origin.global_position+Vector3(0,0.2,0),55)
	await snapshot("folding",fold.global_position+Vector3(-1.5,0.0,2.0),fold.global_position+Vector3(0,0,-4.0),62)

func one_checks() -> void:
	var stations: Dictionary = {}
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("/point_condition.gd"):
			stations[n.condition] = n
	check("all five point conditions placed",stations.size()==5)
	if stations.size()!=5:return
	for kind in stations:
		check(kind+" uses the same Point one label",stations[kind].get_node("PointOneLabel").text=="Point one")
	check("empty station has no point mesh or collision",stations.absent.find_children("*","MeshInstance3D",true,false).is_empty() and stations.absent.find_children("*","CollisionShape3D",true,false).is_empty())
	check("white mesh sizes identical",is_equal_approx(stations.visible.point.mesh.radius,stations.solid.point.mesh.radius))
	check("visible point has no collision shape",stations.visible.find_children("*","CollisionShape3D",true,false).is_empty())
	for kind in ["visible","solid"]:
		var p: Vector3 = stations[kind].point.global_position
		var ray := PhysicsRayQueryParameters3D.create(p+Vector3(0,0,-0.7),p+Vector3(0,0,0.7),1)
		var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
		check(kind+" physical ray matches condition",hit.is_empty() if kind=="visible" else (not hit.is_empty() and hit.collider==stations.solid.get_node("PointCollision")))
		var walker := CharacterBody3D.new()
		walker.collision_layer=0;walker.collision_mask=1
		var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new()
		capsule.radius=0.32;capsule.height=1.5;shape.shape=capsule;shape.position.y=0.75
		walker.add_child(shape);root.add_child(walker)
		walker.global_position=Vector3(p.x,stations[kind].global_position.y+0.02,p.z-1.0)
		await physics_frame
		var collision := walker.move_and_collide(Vector3(0,0,2.0))
		check(kind+" capsule passage matches condition",collision==null if kind=="visible" else collision!=null)
		walker.queue_free();await physics_frame
	var walk := CharacterBody3D.new();walk.collision_layer=0;walk.collision_mask=1
	var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new()
	capsule.radius=0.32;capsule.height=1.5;shape.shape=capsule;shape.position.y=0.75
	walk.add_child(shape);root.add_child(walk)
	walk.global_position=stations.held.global_position+Vector3(1.5,0.02,0)
	await physics_frame
	var route: Array[Vector3]=[Vector3(0,0,2.0),Vector3(1.5,0,0),Vector3(0,0,14.0)]
	var clear := true
	for leg in route:
		if walk.move_and_collide(leg)!=null:clear=false;break
	check("walking capsule can approach the final pedestal from the corridor",clear)
	check("pedestal approach has a supporting floor",not floor_at(walk.global_position).is_empty())
	walk.queue_free();await physics_frame
	var held: Node3D=stations.held.point
	check("black point uses production pickup",held.has_method("pick_up") and held.has_method("let_go"))
	check("black point has exact coordinate identity",held.get_meta("coordinate_id","")=="point_one_main" and held.is_in_group("ada_coordinate_point"))
	check("black point matches the white sphere size",is_equal_approx(held.get_node("MeshInstance3D").mesh.radius,stations.visible.point.mesh.radius))
	check("black point material is dark",held.get_node("MeshInstance3D").material_override.albedo_color.r < 0.02)
	var frame := find_scene("/coordinate_system_3m.gd")
	# Record the real frame script, whose spelling is not assumed here.
	for n in hall.find_children("*","Node3D",true,false):
		if "external_point_id" in n and str(n.get("external_point_id"))=="point_one_main": frame=n;break
	check("coordinate frame configured to follow corridor point",frame!=null)
	if frame != null:check("Point zero sign removed from coordinate frame",frame.get_node_or_null("OriginSign")==null)
	if frame != null:
		check("coordinate frame adopts the actual black point",frame._find_point()==held)
		var grabber := SuppliedGrabber.new();root.add_child(grabber)
		var home: Transform3D = held.global_transform
		grabber.global_transform = home
		held.pick_up(grabber)
		grabber.global_position += Vector3(0.4,0.15,0.25)
		for i in range(12):await physics_frame
		check("actual grab driver carries the point",held.is_picked_up() and held.global_position.distance_to(home.origin)>0.3)
		var cards: Array = []
		for n in hall.find_children("*","Node3D",true,false):
			if "readout_channel" in n and str(n.get("readout_channel"))=="point_one_main" and n.has_method("show_coordinates"):cards.append(n)
		check("two coordinate cards available",cards.size()==2)
		for card in cards:
			var q: Vector3 = held.global_position if card.space=="world" else frame.to_local(held.global_position)
			var expected := "x = %.2f\ny = %.2f\nz = %.2f" % [q.x,q.y,q.z]
			check(card.space+" reports actual carried point",card.get_node("Value").text==expected)
		var target := find_scene("/drag_point_target.gd")
		if target != null:
			grabber.global_position = target.global_position+Vector3(0,target.catch_height,0)
			for i in range(12):await physics_frame
			check("carried point activates existing target",target._inside and target._fired and target._balls.get_child_count()>0)
		held.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
		check("point releases and remains available",not held.is_picked_up() and held.enabled)
		held.global_transform=home
		grabber.queue_free()
		await physics_frame
	check("closing sphere diameter is 1.3 m",is_equal_approx(stations.pedestal.point.mesh.radius*2,1.3))
	check("closing sphere sits exactly on pedestal",is_equal_approx(stations.pedestal.point.position.y-stations.pedestal.point.mesh.radius,0.75))
	observations["stations"]={}
	for kind in stations:observations.stations[kind]=xyz(stations[kind].global_position)
	await snapshot("corridor",stations.absent.global_position+Vector3(1.0,1.65,-1.8),stations.solid.global_position+Vector3(0,1.1,0),64)
	for kind in ["absent","visible","solid","held"]:
		await snapshot(kind,stations[kind].global_position+Vector3(0.6,1.65,-1.55),stations[kind].global_position+Vector3(0,1.05,0),52)
	if frame != null:await snapshot("coordinates",frame.global_position+Vector3(4,1.2,-4),frame.global_position,62)
	await snapshot("pedestal",stations.pedestal.global_position+Vector3(1.4,1.65,-2.8),stations.pedestal.global_position+Vector3(0,1.15,0),55)

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum render, physical rays and capsule motion; pickup availability and coordinate identity inspected. No headset acceptance claimed."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("OPENING CONDITIONS ",map_id," ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
