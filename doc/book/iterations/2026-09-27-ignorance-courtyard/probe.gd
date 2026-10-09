extends "res://tools/probes/transformation_encounters.gd"
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	var kit: GDScript=load("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
	museum.flush_stamps();await create_timer(1.5).timeout
	var court := find_scene("/geometry_courtyard.gd")
	var atlas := find_scene("/sphere_resolution_atlas.gd")
	var reliquary := find_scene("/capsule_reliquary.gd")
	var library := find_scene("/primitive_mesh_library.gd")
	check("all four new encounters placed",court!=null and atlas!=null and reliquary!=null and library!=null)
	if court==null or atlas==null or reliquary==null or library==null:return
	observations["positions"]={"court":xyz(court.global_position),"atlas":xyz(atlas.global_position),"capsule":xyz(reliquary.global_position),"prefabs":xyz(library.global_position)}
	check("one of each of five Platonic solids",court.solids.size()==5)
	var types: Dictionary={}
	for solid in court.solids:types[solid.get_meta("solid_type")]=true
	check("five distinct source families",types.size()==5)
	check("sixteen columns in eight resolutions",court.columns.size()==16)
	check("columns start at four and end at sixty-four segments",court.columns[0].mesh.radial_segments==4 and court.columns[7].mesh.radial_segments==64)
	var inscription := false
	for label: Label3D in court.find_children("*","Label3D",true,false):
		if label.text=="LET NO ONE IGNORANT OF GEOMETRY ENTER":inscription=label.global_position.y>3
	check("motto restored above entrance headroom",inscription)
	check("twelve additional sphere constructions",atlas.specimens.size()==12)
	check("sphere atlas varies the two axes independently",atlas.specimens[0].mesh.rings==1 and atlas.specimens[2].mesh.rings==12 and atlas.specimens[9].mesh.radial_segments==32)
	check("eight pedestal tiers",reliquary.tiers.size()==8)
	var tiers_correct := true
	for i in 8:tiers_correct=tiers_correct and reliquary.tiers[i].mesh.radial_segments==i+4
	check("tier resolutions run four through eleven",tiers_correct)
	check("authored capsule retains five radial segments and five rings",reliquary.body.mesh.radial_segments==5 and reliquary.body.mesh.rings==5)
	check("capsule enlarged to 1.6 metres",is_equal_approx(reliquary.body.scale.y*reliquary.body.mesh.height,1.6))
	check("capsule rests on the top tier",absf(reliquary.capsule.position.y-0.8-1.04)<0.001)
	var yaw: float=reliquary.body.rotation.y;await create_timer(0.3).timeout
	check("existing capsule still rotates",absf(reliquary.body.rotation.y-yaw)>0.1)
	check("eight additional engine prefab scenes",library.prefabs.size()==8)
	for n in library.prefabs:
		check(str(n.kind)+" uses its named native mesh",n.specimen.mesh.get_class()==n.kind)
	check("point specimen uses a visible screen-point material",library.prefabs[4].specimen.material_override.use_point_size)
	# Shared support API: small, wide and low all retain their actual requested deck.
	for dims in [Vector2(0.1,0.7),Vector2(0.45,2.2),Vector2(0.9,1),Vector2(1.2,0.6),Vector2(0.3,4.6)]:
		var plinth: Node3D=kit.pedestal(hall,Vector3(100,0,0),dims.x,dims.y)
		var block: MeshInstance3D=plinth.get_node("MuseumBlock")
		check("plain plinth preserves %.2f m deck"%dims.x,is_equal_approx(block.mesh.size.y,dims.x) and is_equal_approx(block.position.y,dims.x*0.5))
		check("plain plinth preserves %.2f m width"%dims.y,is_equal_approx(block.mesh.size.x,dims.y))
		check("plain support has one mesh and no light",plinth.find_children("*","MeshInstance3D",true,false).size()==1 and plinth.find_children("*","Light3D",true,false).is_empty())
		plinth.queue_free()
	await snapshot("courtyard-entry",court.to_global(Vector3(0,1.7,-8.9)),court.to_global(Vector3(0,2.25,-1.0)),74)
	await snapshot("five-solids",court.to_global(Vector3(-4.6,1.7,-3.8)),court.to_global(Vector3(0,1.25,0.15)),69)
	await snapshot("resolution-chamber",reliquary.to_global(Vector3(-1.7,1.7,-7.1)),reliquary.to_global(Vector3(0,1.5,0)),82)
	await snapshot("five-on-four-to-eleven",reliquary.to_global(Vector3(-2.8,1.7,-3.3)),reliquary.to_global(Vector3(0,1.55,0)),60)
	await snapshot("sphere-atlas",atlas.to_global(Vector3(3.4,1.7,-4.1)),atlas.to_global(Vector3(0,1,0)),70)
	await snapshot("primitive-prefabs",library.to_global(Vector3(0,1.7,-6.5)),library.to_global(Vector3(0,1.35,1.1)),85)
	await snapshot("secondary-alcove",library.to_global(Vector3(8.8,1.7,-0.6)),library.to_global(Vector3(13,1.45,0.7)),86)
	await snapshot("prefab-details",library.to_global(Vector3(0,1.7,0.8)),library.to_global(Vector3(4,1.5,1.4)),60)
	# Actual pickup path with controlled pose, not an assertion of headset targeting.
	var body: RigidBody3D=court.solids[0]
	var start: Transform3D=body.global_transform
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=start
	body.pick_up(grabber);grabber.global_position+=Vector3(0,0.3,0.25);await create_timer(0.25).timeout
	check("solid can be picked up from the podium",body.global_position.distance_to(start.origin)>0.2)
	body.let_go(grabber,Vector3.ZERO,Vector3.ZERO);await create_timer(1.0).timeout
	check("released solid meets its support",body.global_position.y>0.87)
	body.freeze=true;body.global_transform=start;grabber.queue_free()
	# Body-sized sweeps through the clear court, between rooms and beside the capsule.
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var c:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=0.28;shape.height=1.6;c.shape=shape;c.position.y=0.8
	walker.add_child(c);root.add_child(walker)
	var walks=[
		[court,Vector3(4.5,0.03,-5.0),Vector3(0,0,10.0)],
		[court,Vector3(0,0.03,3.8),Vector3(0,0,5.0)],
		[reliquary,Vector3(2.2,0.03,-4.2),Vector3(0,0,7.0)],
		[library,Vector3(0,0.03,-6.0),Vector3(0,0,12.0)],
		[library,Vector3(7.0,0.03,-0.6),Vector3(3.0,0,0)]]
	for i in walks.size():
		var row: Array=walks[i];var anchor: Node3D=row[0]
		walker.global_position=anchor.to_global(row[1]);await physics_frame
		check("visitor-width route %d clear"%i,walker.move_and_collide(anchor.global_basis*row[2])==null)
		check("route %d has a landing floor"%i,not floor_at(walker.global_position).is_empty())
	walker.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum geometry, supplied pickup and body-width walks. Headset and Quest untested."},"  "))
	quit(0 if failures.is_empty() else 1)
