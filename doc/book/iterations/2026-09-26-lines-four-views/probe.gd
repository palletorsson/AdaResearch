extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	if map_id=="Point_One":await basin_checks()
	else:await gallery_checks()

func basin_checks() -> void:
	var frame := find_scene("/CoordinateSystem3M.gd")
	check("coordinate frame present",frame!=null)
	if frame==null:return
	check("coordinate origin is at floor height",absf(frame.global_position.y-hall.global_position.y)<0.015)
	var space := hall.get_world_3d().direct_space_state
	for leg in [Vector3(2,0,0),Vector3(0,0,-2)]:
		var q: Vector3=frame.global_position+leg
		var ray:=PhysicsRayQueryParameters3D.create(q+Vector3(0,-0.15,0),q+Vector3(0,-1.3,0),1)
		var hit:=space.intersect_ray(ray)
		check("pool follows axis "+str(leg),not hit.is_empty() and absf(hit.position.y-hall.global_position.y+1.0)<0.02)
	var corner: Vector3=frame.global_position+Vector3(2,0,-2)
	check("inside the L stays ordinary floor",not floor_at(corner).is_empty())
	check("same point still feeds the coordinate system",frame._find_point()!=null)
	await snapshot("l-basin",frame.global_position+Vector3(5.5,1.65,-5.5),frame.global_position+Vector3(1,-0.15,-1),65)

func gallery_checks() -> void:
	var gallery := find_scene("/line_relations_gallery.gd")
	check("new gallery loads inside Point Lines",gallery!=null)
	if gallery==null:return
	check("twenty line bodies in four views",gallery.lines.size()==20)
	var skins: Dictionary={}
	for rod in gallery.lines:
		skins[rod.skin]=true
		check(rod.name+" is on the VR pickup layer",(rod.collision_layer & 4)!=0)
		check(rod.name+" keeps its declared span",absf(rod.endpoints()[0].distance_to(rod.endpoints()[1])-rod.span)<0.01)
	check("five visible skins available",skins.size()==5)
	var held: Node3D=gallery.lines[0]
	var home: Transform3D=held.global_transform
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=home
	held.pick_up(grabber);grabber.global_position+=Vector3(0.35,0.25,0.45)
	for i in range(12):await physics_frame
	check("production pickup moves a line",held.is_picked_up() and held.global_position.distance_to(home.origin)>0.4)
	held.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	var released: Transform3D=held.global_transform
	for i in range(12):await physics_frame
	check("new arrangement stays after release",not held.is_picked_up() and held.freeze and held.global_transform.is_equal_approx(released))
	gallery.restore_arrangements();grabber.queue_free()
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=0.3;capsule.height=1.6;shape.shape=capsule;shape.position.y=0.8
	walker.add_child(shape);root.add_child(walker)
	walker.global_position=gallery.to_global(Vector3(-4,0.025,-9))
	await physics_frame
	check("walk opens directly into gallery",walker.move_and_collide(Vector3(0,0,5))==null)
	for x in [-8.0,-3.0,2.0,7.0]:
		walker.global_position=gallery.to_global(Vector3(x,0.025,-6))
		await physics_frame
		check("open walking path "+str(x),walker.move_and_collide(Vector3(0,0,17))==null)
		check("floor supports path "+str(x),not floor_at(walker.global_position).is_empty())
	walker.global_position=gallery.to_global(Vector3(10.5,0.025,13.7))
	await physics_frame
	check("followed line meets a real wall",walker.move_and_collide(Vector3(4,0,0))!=null)
	observations["wall_stop"]=xyz(walker.global_position)
	walker.queue_free()
	observations["gallery_position"]=xyz(gallery.global_position)
	await snapshot("four-views",gallery.to_global(Vector3(-0.5,1.65,-7)),gallery.to_global(Vector3(-0.5,1.1,3)),78)
	await snapshot("plus-and-cross",gallery.to_global(Vector3(-6.2,1.65,-2.8)),gallery.to_global(Vector3(-8,1.3,2)),63)
	await snapshot("parallel-and-grid",gallery.to_global(Vector3(-3,1.65,-3)),gallery.to_global(Vector3(2,1.2,2)),75)
	await snapshot("follow-to-wall",gallery.to_global(Vector3(4.0,1.65,17.0)),gallery.to_global(Vector3(12.4,0.7,13.7)),65)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum geometry, production pickup with supplied grabber, collision paths, and screenshots. No headset acceptance claimed."},"  "))
	print("FOUR VIEWS ",map_id," ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
