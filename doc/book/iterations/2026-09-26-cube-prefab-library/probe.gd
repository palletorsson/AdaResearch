extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps();await create_timer(1.0).timeout
	var library:=find_scene("/prefab_box_library.gd")
	check("library placed in the Cube hall",library!=null)
	if library==null:return
	check("six columns and four shelves hold 24 copies",library.items.size()==24 and library.catalog.columns.size()==6)
	if library.items.size()!=24:return
	check("copies share 12 declared source/configuration editions",library.cache.size()==12)
	var same := true
	for column in 4:
		var first: Node3D=library.items[column*4]
		for row in range(1,4):
			var next: Node3D=library.items[column*4+row]
			same=same and first!=next and first.get_node("Prefab/BatchedGeometry").mesh==next.get_node("Prefab/BatchedGeometry").mesh
	check("repeated copies are distinct bodies sharing one edition mesh",same)
	check("last columns alter the same source rather than disguising new sources",library.items[16].get_meta("prefab_source")==library.items[4].get_meta("prefab_source") and library.items[20].get_meta("prefab_source")==library.items[12].get_meta("prefab_source"))
	check("altered editions retain distinct configurations",library.items[16].get_meta("edition_key")!=library.items[17].get_meta("edition_key"))
	var geometry_count := 0;var surface_count := 0
	for item: Node3D in library.items:
		geometry_count+=item.find_children("*","MeshInstance3D",true,false).size()
		surface_count+=item.get_node("Prefab/BatchedGeometry").mesh.get_surface_count()
	check("authored meshes are batched into one geometry node per copy",geometry_count==24)
	observations["render_surfaces"]=surface_count
	observations["library_world"]=xyz(library.global_position)
	await snapshot("library-in-the-hall",library.to_global(Vector3(-3.5,1.7,7.3)),library.to_global(Vector3(0,1.8,0)),72)
	await snapshot("repetitions-and-variations",library.to_global(Vector3(0,1.7,6.2)),library.to_global(Vector3(0,1.9,0)),78)
	await snapshot("crate-editions",library.to_global(Vector3(2.4,1.6,2.5)),library.to_global(Vector3(2.3,1.75,0)),66)
	var body: RigidBody3D=library.items[12]
	var other: Node3D=library.items[13]
	var other_pose: Transform3D=other.global_transform
	var original: Transform3D=body.global_transform
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=body.global_transform
	body.pick_up(grabber)
	grabber.global_position=library.to_global(Vector3(2.05,1.22,2.3))
	await create_timer(0.3).timeout
	check("production pickup moves one copy away from its shelf",body.global_position.distance_to(original.origin)>1.5 and body.get_meta("held"))
	check("other copies stay in place",other.global_transform.is_equal_approx(other_pose))
	body.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	await create_timer(1.8).timeout
	var shape: BoxShape3D=body.get_node("CollisionShape3D").shape
	var at: Vector3=library.to_local(body.global_position)
	check("released copy rests on the worktop",absf(at.y-(0.775+shape.size.y*0.5))<0.03)
	# Take a second original crate and put it alongside the carton.
	var crate: RigidBody3D=library.items[4]
	grabber.global_transform=crate.global_transform;crate.pick_up(grabber)
	grabber.global_position=library.to_global(Vector3(2.9,1.22,2.3))
	await create_timer(0.25).timeout
	crate.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	await create_timer(1.8).timeout
	check("different prefab can join the new arrangement",absf(library.to_local(crate.global_position).z-2.3)<0.08)
	var second: RigidBody3D=library.items[13]
	grabber.global_transform=second.global_transform;second.pick_up(grabber)
	grabber.global_position=library.to_global(Vector3(2.05,1.98,2.3))
	await create_timer(0.25).timeout
	second.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	await create_timer(2.0).timeout
	check("two copies physically stack without passing through each other",absf(second.global_position.y-body.global_position.y-shape.size.y)<0.04)
	await snapshot("another-arrangement",library.to_global(Vector3(3.4,1.7,4.9)),library.to_global(Vector3(1.9,1.5,1)),65)
	grabber.queue_free()
	# Test the entire gallery approach with a body-sized capsule.
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var collision:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.6
	collision.shape=capsule;collision.position.y=0.8;walker.add_child(collision);root.add_child(walker)
	walker.global_position=library.to_global(Vector3(-4,0.025,1.15))
	await physics_frame
	check("visitor can walk along the full shelf",walker.move_and_collide(library.global_basis*Vector3(8,0,0))==null)
	walker.queue_free()
	check("worktable approach has floor",not floor_at(library.to_global(Vector3(2.4,0,3.3))).is_empty())
	var manifest := {"columns":library.catalog.columns,"copies":24,"editions":library.cache.size(),"surfaces":surface_count}
	FileAccess.open(folder+"library-manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  "))

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum render, supplied production pickup/release, separate instance state, shared meshes, collision and visitor-width access. Headset use remains untested."},"  "))
	quit(0 if failures.is_empty() else 1)
