extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.flush_stamps();await create_timer(1).timeout
	var gallery:=find_scene("/line_relations_gallery.gd")
	check("line gallery loaded",gallery!=null)
	if gallery==null:return
	var column:StaticBody3D=gallery.get_node_or_null("FollowColumn")
	check("freestanding column is present",column!=null)
	if column==null:return
	check("all 28 existing line bodies remain",gallery.lines.size()==28)
	check("column is in the central gallery aisle",absf(column.position.x)<3 and column.position.z>2 and column.position.z<7)
	var boundary:CollisionShape3D=column.find_children("*","CollisionShape3D",false,false)[0]
	check("column reaches precisely two metres above the floor",is_equal_approx(boundary.shape.size.y,2) and is_equal_approx(column.position.y,1))
	var space:=hall.get_world_3d().direct_space_state
	var centre:Vector3=gallery.FOLLOW_COLUMN_CENTRE
	for pair in [[Vector3(0,1,-2),Vector3(0,1,0)],[Vector3(0,1,2),Vector3(0,1,0)],[Vector3(0,3,0),Vector3(0,1,0)]]:
		var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(gallery.to_global(centre+pair[0]),gallery.to_global(centre+pair[1]),1))
		check("column is solid from "+str(pair[0]),not hit.is_empty() and hit.collider==column)
	var route:Node3D=gallery.get_node("FollowRoute")
	var names:=["Approach","Up","Over","Down","Continue"]
	for i in range(names.size()-1):
		var a:MeshInstance3D=route.get_node(names[i]);var b:MeshInstance3D=route.get_node(names[i+1])
		check("continuous ink: "+names[i]+" to "+names[i+1],(a.transform*a.get_aabb()).grow(0.001).intersects(b.transform*b.get_aabb()))
	check("old wall mark removed",not gallery.has_node("FollowWall") and not gallery.has_node("FollowFloor"))
	check("start and invitation appear beside the central route",gallery.has_node("FollowStart") and gallery.has_node("FollowInvitation"))
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var collision:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.6
	collision.shape=capsule;collision.position.y=0.8;walker.add_child(collision);root.add_child(walker)
	walker.global_position=gallery.to_global(centre+Vector3(0,0.025,-2.5));await physics_frame
	var obstruction:=walker.move_and_collide(gallery.global_basis*Vector3(0,0,5))
	check("walking the mark meets the column",obstruction!=null and obstruction.get_collider()==column)
	for x in [-1.15,1.15]:
		walker.global_position=gallery.to_global(centre+Vector3(x,0.025,-2.5));await physics_frame
		var hit:=walker.move_and_collide(gallery.global_basis*Vector3(0,0,5))
		check("can walk around column on side "+str(x),hit==null)
		if hit!=null:observations["blocked_side_"+str(x)]={"collider":str(hit.get_collider().get_path()),"position":xyz(hit.get_position())}
	walker.queue_free()
	observations["column_world"]=xyz(column.global_position)
	await snapshot("follow-start",gallery.to_global(centre+Vector3(0,1.65,-6.3)),gallery.to_global(centre+Vector3(0,0.95,-1)),69)
	await snapshot("follow-return",gallery.to_global(centre+Vector3(3.2,2.6,3.8)),gallery.to_global(centre+Vector3(0,0.85,0.4)),67)
	await snapshot("follow-hall",gallery.to_global(centre+Vector3(-5.0,1.65,-6.3)),gallery.to_global(centre+Vector3(0,1,0)),75)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	quit(0 if failures.is_empty() else 1)
