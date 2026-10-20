extends "res://tools/probes/transformation_encounters.gd"
var complete := false
var wing: Node3D
var overlap: Node3D

func capture(name: String, eye: Vector3, target: Vector3, fov := 70.0) -> void:
	# Photograph from the walker's actual location, without a spare player body
	# standing in the return doorway while the inspection camera moves elsewhere.
	wing.move_together(eye-wing.eye_position()); overlap.have_eye=false
	camera.global_position=eye; camera.look_at(target); camera.fov=fov; camera.current=true
	overlap.update_visibility(camera)
	await snapshot(name,eye,target,fov)

func landing_checks() -> void:
	var start := Time.get_ticks_msec()
	while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<35000:
		museum.call("_drain_stamps"); museum.call("_drain_cartridge_nodes"); await tick()
	wing=find_scene("/noneuclidean_wing.gd")
	check("installed wing loads from museum registry",wing!=null)
	if wing==null: return
	while not wing.built: await tick()
	wing.set_process(false); overlap=wing.overlap
	check("two original interiors and their four directed portals retained",overlap.interiors.size()==2 and overlap.links.size()>=4 and overlap.links[0].to==0 and overlap.links[2].to==1)
	var identity: int=wing.point.get_instance_id()
	check("carried class unchanged",FileAccess.get_file_as_string(wing.point.get_script().resource_path)==FileAccess.get_file_as_string("res://doc/book/studies/noneuclid-lineage/point_body.gd"))
	wing.visit(0)
	check("other six chambers retained",wing.rooms.size()==7)
	check("pavilion entrance and return landing have floors",not floor_at(wing.rooms[0].to_global(Vector3(-1.5,0,2.2))).is_empty() and not floor_at(overlap.interiors[0].to_global(Vector3(0,0,5.5))).is_empty())
	await capture("two-doors",wing.rooms[0].to_global(Vector3(0,1.75,5.5)),wing.rooms[0].to_global(Vector3(0,1.6,0)),75)
	check("both forward apertures visible",overlap.links[0].view.visible and overlap.links[2].view.visible)
	observations["front_culling"]=overlap.stats.duplicate()
	check("aperture cone rejects some preview meshes",overlap.stats.submitted>0 and overlap.stats.submitted<overlap.stats.candidates)
	camera.look_at(camera.global_position+Vector3.BACK); overlap.update_visibility(camera)
	check("looking away submits no portal preview",overlap.stats.portals==0 and overlap.stats.submitted==0)
	for link in overlap.links:
		check("preview has no physics bodies "+str(link.from)+"/"+str(link.to),link.view.find_children("*","PhysicsBody3D",true,false).is_empty())
	# A source hidden by another wall must not leak pixels through that wall.
	for i in range(2):
		var link: Dictionary=overlap.links[i*2]
		var source: Node3D=link.source
		await capture("door-"+str(i+1),source.to_global(Vector3(0,1.7,1.2)),source.to_global(Vector3(0,2,-8)),72)
		if DisplayServer.get_name()!="headless":
			var landmark: Vector3=link.transfer.affine_inverse()*overlap.interiors[i].to_global(Vector3(0,2.5,-5.45))
			var px := camera.unproject_position(landmark)
			var on := root.get_texture().get_image().get_pixelv(Vector2i(px))
			link.writer.visible=false
			await process_frame; await RenderingServer.frame_post_draw
			var off := root.get_texture().get_image().get_pixelv(Vector2i(px))
			check("stencil controls actual interior pixels "+str(i),Vector3(on.r-off.r,on.g-off.g,on.b-off.b).length()>0.15)
			link.writer.visible=true
			await process_frame; await RenderingServer.frame_post_draw
			var pedestal: Vector3=link.transfer.affine_inverse()*overlap.interiors[i].to_global(Vector3(0,0.55,-1.05))
			var pedestal_pixel := camera.unproject_position(pedestal)
			var pedestal_colour := root.get_texture().get_image().get_pixelv(Vector2i(pedestal_pixel))
			check("remote pedestal occludes remote floor %d"%i,maxf(pedestal_colour.r,maxf(pedestal_colour.g,pedestal_colour.b))<0.4)
			var eye_local: Vector3=source.to_local(camera.global_position)
			var target: Vector3=source.to_local(landmark)
			var at := eye_local.lerp(target,(eye_local.z-0.6)/(eye_local.z-target.z))
			var blocker=wing.B.box(source,at,Vector3(0.25,0.25,0.15),Color.GREEN)
			blocker.material_override=wing.B.material(Color.GREEN,true)
			await process_frame; await RenderingServer.frame_post_draw
			var occluded := root.get_texture().get_image().get_pixelv(Vector2i(px))
			check("foreground occludes portal pixels "+str(i),occluded.g>occluded.r*1.5 and occluded.g>occluded.b*1.5)
			blocker.queue_free(); await tick()
	# Real museum CharacterBody; sweep in both directions while holding the point.
	var walker: CharacterBody3D=museum.get("_player")
	var hand: Node3D=walker.find_child("DesktopPointer",true,false)
	if hand==null:
		for n in walker.find_children("*","Node3D",true,false):
			if n.has_method("_grab_held"): hand=n; break
	check("actual museum desktop hand found",hand!=null)
	if hand==null: return
	hand.set_process(false)
	wing.test_eye=Vector3(INF,INF,INF)
	var first: Dictionary=overlap.links[0]
	walker.global_position=first.source.to_global(Vector3(0,0.05,0.8))
	wing.point.global_position=first.source.to_global(Vector3(-0.3,1.35,-0.22))
	hand._grab_held(wing.point); overlap.have_eye=false; overlap.update(0.016)
	await capture("hand-through",wing.eye_position(),first.source.to_global(Vector3(0,1.4,-3)),75)
	check("hand-before-head shows point beyond aperture",first.point_view.visible and overlap.point_surface.material_override==overlap.point_split and overlap.sector==-1)
	var released_at: Vector3=first.transfer*wing.point.global_position
	hand._drop_held(); overlap.update(0.016)
	check("release beyond aperture transfers one real point",overlap.point_sector==0 and overlap.sector==-1 and wing.point.global_position.is_equal_approx(released_at) and wing.point.get_instance_id()==identity)
	wing.recall(); overlap.update(0.016)
	for i in range(2):
		var link: Dictionary=overlap.links[i*2]
		var source: Node3D=link.source
		walker.global_position=source.to_global(Vector3(0,0.05,3.2))
		wing.point.global_position=wing.eye_position()+Vector3(0.22,-0.25,-0.45)
		hand._grab_held(wing.point); overlap.have_eye=false
		check("native pickup owns same point %d"%i,hand._held==wing.point and wing.point.held())
		overlap.update(0.016)
		var held_offset: Vector3=wing.point.global_position-wing.eye_position()
		var collided := false
		for step in range(70):
			var d:=Vector3(0,0,-0.05)
			if walker.test_move(walker.global_transform,d): collided=true; break
			walker.global_position+=d; wing.point.global_position+=d
			overlap.update(0.016)
			if overlap.sector==i: break
		check("real walker enters gallery %d without collision"%i,not collided and overlap.sector==i)
		check("held point retains identity and hand offset %d"%i,wing.point.get_instance_id()==identity and (wing.point.global_position-wing.eye_position()).is_equal_approx(held_offset))
		check("only occupied room rendered %d"%i,not overlap.lobby.visible and overlap.interiors[i].visible and not overlap.interiors[1-i].visible)
		# Run the real carry update after a crossing: it must keep following the
		# transported museum camera, rather than springing back to the old room.
		hand._process(0.016)
		check("native hand keeps following after crossing %d"%i,wing.point.global_position.distance_to(wing.eye_position())<4.1)
		await capture("inside-"+str(i+1),overlap.interiors[i].to_global(Vector3(2.8,1.8,4.8)),overlap.interiors[i].to_global(Vector3(0,2,-2)),85)
		var back: Node3D=link.target
		await capture("return-"+str(i+1),back.to_global(Vector3(0,1.7,2.5)),back.to_global(Vector3(0,1.7,-3)),75)
		check("return doorway has its own visible view %d"%i,overlap.stats.portals==1 and overlap.links[i*2+1].view.visible)
		# Place the same object at the centre podium; walking out must not recall it.
		hand._drop_held()
		check("native drop restores pickable collision %d"%i,not wing.point.held() and wing.point.collision_layer==4)
		wing.point.global_position=overlap.interiors[i].to_global(Vector3(0,1.225,-1.8)); overlap.update(0.016)
		var kept: Vector3=wing.point.global_position
		walker.global_position=back.to_global(Vector3(0,0.05,1.0)); overlap.have_eye=false; overlap.update(0.016)
		collided=false
		for step in range(24):
			var d:=Vector3(0,0,0.05)
			if walker.test_move(walker.global_transform,d): collided=true; break
			walker.global_position+=d; overlap.update(0.016)
			if overlap.sector==-1: break
		check("real walker returns through gallery %d doorway"%i,not collided and overlap.sector==-1)
		check("left point stays in its own room %d"%i,wing.point.global_position.is_equal_approx(kept) and overlap.point_sector==i)
		await capture("point-kept-"+str(i+1),source.to_global(Vector3(0,1.65,0.8)),source.to_global(Vector3(0,1.2,-6)),70)
		check("point preview only belongs to its destination %d"%i,link.point_view.visible and not overlap.links[(1-i)*2].point_view.visible)
		# Enter again and retrieve the very same instance through the real hand API.
		overlap.cross(link); hand._grab_held(wing.point)
		check("same left point can be picked up again %d"%i,hand._held.get_instance_id()==identity)
		overlap.cross(overlap.links[i*2+1]); hand._drop_held()
		check("retrieved point returns to pavilion %d"%i,overlap.point_sector==-1)
		wing.recall(); overlap.update(0.016)
	check("wall crossings rejected",not overlap.swept(Vector3(1.4,1.6,0.1),Vector3(1.4,1.6,-0.1)))
	check("high speed crossing catches doorway",overlap.swept(Vector3(0,1.6,3),Vector3(0,1.6,-3)))
	# Back of the small exterior shell has no visible apertures.
	await capture("pavilion-above",overlap.lobby.to_global(Vector3(8,10,9)),overlap.lobby.to_global(Vector3(0,0.6,0)),65)
	await capture("pavilion-behind",overlap.lobby.to_global(Vector3(0,1.8,-4.4)),overlap.lobby.to_global(Vector3(0,1.6,0)),70)
	check("back-facing doorways submit no geometry",overlap.stats.portals==0)
	# Same apparent coordinates in the pavilion, separate physical sectors.
	var a: Transform3D=overlap.links[0].transfer.affine_inverse()*overlap.interiors[0].global_transform
	var b: Transform3D=overlap.links[2].transfer.affine_inverse()*overlap.interiors[1].global_transform
	check("apparent gallery footprints overlap",(a*AABB(Vector3(-7,0,-6),Vector3(14,6,12))).intersects(b*AABB(Vector3(-7,0,-6),Vector3(14,6,12))))
	wing.visit(1); overlap.update(0.016)
	check("leaving chamber culls every overlap preview",overlap.links.all(func(l): return not l.view.visible and not l.writer.visible))
	check("same point survives navigation onward",wing.point.get_instance_id()==identity and wing.current==1)
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["crossings"]=overlap.crossings
	observations["scope"]="Native museum walker, synthetic hold/drop, actual stencil pixels, sector/aperture culling. No physical headset acceptance. One-level views, no recursive portals."
	complete=true

func finish() -> void:
	check("overlap probe completed",complete)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("OVERLAPPING ROOMS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
