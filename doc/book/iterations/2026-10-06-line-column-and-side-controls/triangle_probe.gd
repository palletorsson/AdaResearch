extends "res://doc/book/iterations/2026-10-06-triangle-lines-and-faces/probe.gd"

func landing_checks() -> void:
	await super.landing_checks()
	var twin:=find_scene("/triangle_live_twin.gd")
	if twin==null or twin.source==null:return
	var source:Node3D=twin.source
	var controls:Node3D=source.get_node("MuseumWorkbench")
	var board:MeshInstance3D=controls.get_node("ActionBoard")
	var bounds:AABB=controls.transform*board.get_aabb()
	check("whole console is beside the plinth, clear of its front",bounds.position.x>0.70)
	check("side console has a separate solid support",source.get_node_or_null("WorkbenchStand") is StaticBody3D)
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var collision:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.6
	collision.shape=capsule;collision.position.y=0.8;walker.add_child(collision);root.add_child(walker)
	walker.global_position=source.to_global(Vector3(0,-source.global_position.y+0.025,1.8));await physics_frame
	check("visitor can approach to within 5cm of the plinth front",walker.move_and_collide(source.global_basis*Vector3(0,0,-1.05))==null)
	var hit:=walker.move_and_collide(source.global_basis*Vector3(0,0,-0.3))
	check("next step meets the plinth, not the interface",hit!=null and hit.get_collider()==source.get_node("MuseumPlinth"))
	walker.queue_free()
	await snapshot("triangle-side-console",source.to_global(Vector3(2.5,0.45,2.8)),source.to_global(Vector3(0.55,-0.05,-0.5)),69)
	await snapshot("triangle-close",source.to_global(Vector3(0,0.35,0.80)),source.to_global(Vector3(0,0.05,0)),72)
	await snapshot("triangle-front",source.to_global(Vector3(0.65,0.45,2.8)),source.to_global(Vector3(0.55,-0.04,0)),67)
