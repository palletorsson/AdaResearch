extends "res://tools/probes/void_polyhedra_probe.gd"
const Finish = preload("res://commons/artifacts/primitive_encounters/construction_finish.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await capture_building()
	else:
		await building_checks(false)
		await building_checks(true)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Polyhedra artifacts; desktop and synthetic XR pickup/movement. Not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func building_checks(use_xr: bool) -> void:
	await arrive(use_xr,false)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var closure: Node3D=content.exhibits["6/closure"].get_node("Artifact")
	for title in ["AlignTetrahedron","AlignWedge"]:
		var instrument: Node3D=closure.get_node(title)
		check(tag+title+" shows the actual corners and unique edges",instrument.guides.get_child_count()==instrument.vertices.size()-1+instrument.edges.size())
		# A wrong release cannot complete the geometry.
		instrument._released(instrument.handle);await frames(2)
		check(tag+title+" rejects an unaligned release",not instrument.complete)
		if use_xr:
			game.place_player(instrument.global_position+Vector3(0,.06,1.5));await frames(15)
			hand_at(right,instrument.handle.global_position);await frames(15)
			right.set_input("grip",1.0);await frames(20)
			check(tag+title+" loose corner is grabbable",game.pickups[1].picked_up_object==instrument.handle)
			hand_at(right,instrument.to_global(instrument.target_position));await frames(20)
			check(tag+title+" gives the release cue",instrument.instruction.text.contains("Release here"))
			right.set_input("grip",0.0)
		else:
			instrument.handle.on_desktop_grab(null)
			instrument.handle.global_position=instrument.to_global(instrument.target_position)
			await frames(3)
			check(tag+title+" gives the release cue",instrument.instruction.text.contains("Release here"))
			instrument.handle.on_desktop_drop(null)
		await frames(90)
		check(tag+title+" completes once",instrument.complete and is_instance_valid(instrument.solid_body))
		if not is_instance_valid(instrument.solid_body): continue
		var solid: RigidBody3D=instrument.solid_body
		var identity := solid.get_instance_id();instrument.finish()
		check(tag+title+" repeated completion keeps the same solid",solid.get_instance_id()==identity)
		var visible := solid.get_node("Surface") as MeshInstance3D
		check(tag+title+" stripes export as vertex colours",has_stripes(visible))
		var collision: CollisionShape3D=solid.find_children("*","CollisionShape3D",true,false)[0]
		check(tag+title+" collider uses the completed positions",(collision.shape as ConvexPolygonShape3D).points==instrument.vertices)
		check(tag+title+" falls onto the floor",solid.global_position.y> -36.1 and solid.position.y<.8)
		if use_xr:
			hand_at(right,solid.global_position+Vector3(0,.06,0));await frames(15)
			right.set_input("grip",1.0);await frames(20)
			check(tag+title+" completed solid can be held",game.pickups[1].picked_up_object==solid)
			right.set_input("grip",0.0);await frames(10)
		else:
			solid.on_desktop_grab(null);check(tag+title+" completed solid can be held",solid.held());solid.on_desktop_drop(null)
	var obstruction: Node3D=content.exhibits["6/obstruction"].get_node("Artifact")
	for name in ["TetrahedronBlocker","PyramidBlocker","WedgeBlocker"]:
		var blocker: Node3D=obstruction.get_node(name)
		var meshes := blocker.find_children("*","MeshInstance3D",true,false)
		check(tag+name+" uses solid diagonal paint",meshes.size()>0 and has_stripes(meshes[0]))
		var hit := cast(blocker.to_global(Vector3(0,.55,-2)),blocker.to_global(Vector3(0,.55,2)))
		check(tag+name+" blocks a physical ray through its body",not hit.is_empty() and blocker.is_ancestor_of(hit.collider))
	check(tag+"tetrahedron has four faces",obstruction.get_node("TetrahedronBlocker").get_meta("face_count")==4)
	check(tag+"pyramid has square base and four triangular sides",obstruction.get_node("PyramidBlocker").get_meta("vertex_count")==5 and obstruction.get_node("PyramidBlocker").get_meta("face_count")==5)
	var support: Node3D=content.exhibits["6/support"].get_node("Artifact")
	var walk: Node3D=support.get_node("WedgePlatform")
	check(tag+"deck is one metre above the slab",walk.get_meta("deck_height")==1.0)
	check(tag+"mouse setup is removed",not support.has_node("WedgeMouseModel") and not support.part_defaults.has("WedgeMouseModel"))
	var frame: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/layout.json"))
	var deck: Node3D=walk.get_node("ShaftCover")
	check(tag+"cube prefabs wait for Cube floor",deck.scene_file_path.is_empty() and walk.get_meta("construction_definition")=="wp_shaft_cover")
	var surface: MeshInstance3D=deck.find_children("*","MeshInstance3D",true,false)[0]
	var bounds: AABB=surface.global_transform*surface.get_aabb()
	check(tag+"deck footprint matches the shaft",is_equal_approx(bounds.size.x,float(frame.shaft_width)) and is_equal_approx(bounds.size.z,float(frame.shaft_depth)))
	check(tag+"editor placement stays centred on shaft A",is_equal_approx(bounds.get_center().x,float(frame.shafts[0].x)) and is_zero_approx(bounds.get_center().z))
	for ix in range(6):
		for iz in range(7):
			var at := Vector3(lerpf(bounds.position.x+.02,bounds.end.x-.02,ix/5.0),bounds.end.y,lerpf(bounds.position.z+.02,bounds.end.z-.02,iz/6.0))
			var cover_hit := cast(at+Vector3.UP*.02,at-Vector3.UP*.02)
			check(tag+"walkable cover sample "+str(ix)+","+str(iz),not cover_hit.is_empty() and deck.is_ancestor_of(cover_hit.collider))
	for ramp in walk.get_children():
		if not ramp.has_node("OriginalWP"): continue
		check(tag+str(ramp.name)+" retains original wp scene",ramp.get_node("OriginalWP").scene_file_path=="res://commons/scenes/mapobjects/walkableprism.tscn")
		for z in [-.8,0,.8]:
			var hit := cast(ramp.to_global(Vector3(0,2,z)),ramp.to_global(Vector3(0,-.1,z)))
			if not hit.is_empty() and absf(ramp.to_local(hit.position).y-(z+1)*.5)>=.015:
				print("RAMP_CONTACT ",ramp.name," z=",z," local=",ramp.to_local(hit.position)," collider=",hit.collider.get_path())
			check(tag+str(ramp.name)+" ramp height at "+str(z),not hit.is_empty() and absf(ramp.to_local(hit.position).y-(z+1)*.5)<.015)
		var high: Vector3=ramp.get_meta("high_join")
		var on_deck := cast(ramp.to_global(high+Vector3(0,1,.1)),ramp.to_global(high+Vector3(0,-.1,.1)))
		check(tag+str(ramp.name)+" high edge joins the platform",not on_deck.is_empty() and absf(walk.to_local(on_deck.position).y-1)<.015)
	# Use the actual desktop / XR player to cross the actual west ramp join.
	var half_width: float=walk.DECK_SIZE.x/2
	game.place_player(walk.to_global(Vector3(-half_width-2.6,.06,-1)));await frames(20)
	check(tag+"walk up wp onto the shaft cover",await move_to(walk.to_global(Vector3(-half_width+.35,1,-1))))
	check(tag+"walk across the covered shaft",await move_to(walk.to_global(Vector3(half_width-.35,1,-1))))
	check(tag+"walk down the opposite wp",await move_to(walk.to_global(Vector3(half_width+2.6,0,-1))))
	# Editor isolation and placement use the production assembly factory.
	var copy: Node3D=load("res://commons/void/polyhedra_obstruction.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["PyramidBlocker"],"parts":{"PyramidBlocker":{"position":[2,0,1],"rotation":[0,90,0]}}})
	check(tag+"editor can isolate and rotate the reusable pyramid",copy.get_child_count()==1 and copy.get_node("PyramidBlocker").position==Vector3(2,0,1) and is_equal_approx(copy.get_node("PyramidBlocker").rotation_degrees.y,90))
	copy.queue_free();await frames(5)
	await cleanup(use_xr)

func cast(from: Vector3, to: Vector3) -> Dictionary:
	return game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))

func has_stripes(visible: MeshInstance3D) -> bool:
	var colours: PackedColorArray=visible.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	if colours.is_empty(): return false
	for colour in colours:
		if not colour.is_equal_approx(colours[0]): return true
	return false

func capture_building() -> void:
	await arrive(false,false);game._set_enabled(false)
	await photograph("align-solids.png",Vector3(18.7,-34.3,4.3),Vector3(16,-34.6,0),76)
	await photograph("striped-blockers.png",Vector3(5.5,-33.9,1.6),Vector3(0,-35.35,5.5),74)
	var walk: Node3D=game.building.content.exhibits["6/support"].get_node("Artifact/WedgePlatform")
	await photograph("wp-platform.png",walk.global_position+Vector3(-7,3.2,6.8),walk.global_position+Vector3(0,.7,0),78)
	await photograph("shaft-cover-plan.png",walk.global_position+Vector3(0,5.5,1.5),walk.global_position,91)
	var closure: Node3D=game.building.content.exhibits["6/closure"].get_node("Artifact")
	for title in ["AlignTetrahedron","AlignWedge"]: closure.get_node(title).finish()
	await frames(90)
	await photograph("completed-solids.png",Vector3(17.9,-34.4,3.5),Vector3(16,-35.2,1.1),67)
	for name in ["align-solids","striped-blockers","wp-platform","completed-solids"]:
		check("Native screenshot: "+name,FileAccess.file_exists(out.path_join(name+".png")))
	await cleanup(false)
