extends "res://tools/probes/triangle_shaft_quad_probe.gd"
const ProfileSource = preload("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	if "--capture-only" in OS.get_cmdline_user_args():
		await start(false)
		game.body.hide()
		game.get_node("CareBody").hide()
		for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
		await photograph("ceiling-i-spool",Vector3(14.2,-57.5,0),Vector3(17,-55.7,0))
		await photograph("b-wells-through-shaft",Vector3(6.7,-54.65,2.7),Vector3(10,-56.2,0))
		quit(0)
		return
	for mode in [false,true]:
		await start(mode)
		var tag := "XR: " if xr else "Desktop: "
		game.checkpoint = 10
		game.place_player(Vector3(-2.7,-59.94,1.7))
		await frames(45)
		var hall: Node3D=game.building.content.exhibits["10/hall"].get_node("Artifact")
		var originals := ProfileSource.new()
		var font := FontFile.new()
		font.load_dynamic_font(ProfileSource.FONT_PATH)
		for i in 6:
			var id := "Profile_%d_%s"%[i+1,ProfileSource.GLYPHS[i].replace(":","Colon")]
			var mesh: Mesh = hall.get_node(NodePath(id+"/Sculpture")).mesh
			var expected := ProfileSource.Sweep.make(ProfileSource.Sweep.profile(font,ProfileSource.GLYPHS[i]),originals._frames(i),i==4)
			check(tag+id+" museum geometry unchanged",mesh.get_faces()==expected.get_faces())
		originals.free()
		for id in ["SuspendedShaft_O","SuspendedShaft_B","HangingChannel_C","HangingSpool_I"]:
			var part: Node3D=hall.get_node(NodePath(id))
			var visual: MeshInstance3D=part.get_node("GlyphSweep")
			var box := visual.mesh.get_aabb()
			check(tag+id+" real glyph mesh, collision and independent part",visual.mesh.get_meta("glyph")==part.get_meta("profile_glyph") and visual.has_node("WalkableProfile/CollisionShape3D") and hall.part_defaults.has(id))
			check(tag+id+" attached to ceiling below upper slab",is_equal_approx(part.position.y+part.get_node("CeilingHangerLeft").position.y+part.get_node("CeilingHangerLeft").mesh.height/2,5.62) if id.begins_with("Hanging") else part.position.y+box.end.y<5.64)
			if id.begins_with("SuspendedShaft"):
				check(tag+id+" body descends through shaft and fits its plan",part.position.y+box.position.y<-.8 and box.position.x> -2.5 and box.end.x<2.5 and box.position.z> -3 and box.end.z<3)
			else:
				check(tag+id+" body hangs above head clearance",part.position.y+box.position.y>2.5)
		check(tag+"O shaft centre remains an open descent",ray(Vector3(-10,-54.9,0),Vector3(-10,-61.5,0)).is_empty())
		var tyre: RigidBody3D=hall.get_node("RollingTyre_O")
		check(tag+"tire is an O closed sweep with compound rim",tyre.section.glyph=="O" and tyre.get_node("RubberGlyph").mesh.get_meta("loop") and tyre.get_children().filter(func(n):return n is CollisionShape3D).size()==32)
		check(tag+"tire has an actual open hub",ray(tyre.global_position+Vector3.FORWARD,tyre.global_position+Vector3.BACK).is_empty())
		var initial := tyre.global_position
		var orientation := tyre.global_basis
		axes(Vector2(-1,0))
		await frames(80)
		axes(Vector2.ZERO)
		await frames(30)
		print("LETTER_TYRE_ROLL ",tag," start=",initial," now=",tyre.global_position," spin=",tyre.angular_velocity," visitor=",game.body.global_position)
		check(tag+"walking into tire rolls it without scripted launch",tyre.global_position.distance_to(initial)>.35 and not tyre.global_basis.is_equal_approx(orientation))
		check(tag+"visitor stays alive on Profiles",game.deaths==0 and game.checkpoint==10)
		# A moved/rotated part is rebuilt from the same source and keeps its collision.
		var copy: Node3D=hall.get_script().new()
		copy.hall="profiles"
		copy.position=Vector3(40,-60,0)
		root.add_child(copy)
		copy.apply_grid_config({"only_parts":["SuspendedShaft_O"],"parts":{"SuspendedShaft_O":{"position":[0,2,0],"rotation":[0,90,0]}}})
		await frames(2)
		check(tag+"hanging glyph copy moves and turns with collision",copy.get_child_count()==1 and copy.get_node("SuspendedShaft_O").position==Vector3(0,2,0) and is_equal_approx(copy.get_node("SuspendedShaft_O").rotation_degrees.y,90))
		copy.free()
		if not xr:
			game.body.hide()
			game.get_node("CareBody").hide()
			for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
			await photograph("hanging-letter-shafts",Vector3(-3,-57.6,7.4),Vector3(0,-58.3,-.2))
			await photograph("suspended-o-through-floor",Vector3(-6.4,-57.4,4.5),Vector3(-10,-58.1,0))
			await photograph("large-ceiling-letters",Vector3(13.8,-57.8,5.8),Vector3(17,-55.7,0))
			# Return wheel for a legible shape view; this does not write the layout.
			tyre.freeze=true
			tyre.global_transform=Transform3D(Basis.IDENTITY,initial)
			PhysicsServer3D.body_set_state(tyre.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,tyre.global_transform)
			await photograph("o-letter-tire",Vector3(-2.8,-58.7,3.8),initial)
		game.queue_free()
		await frames(15)
		if xr:
			for tracker_item in [head,left,right]: XRServer.remove_tracker(tracker_item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual tower floor 10: original glyph fidelity, physical hanging meshes, open shafts, real desktop/synthetic-XR walking contact rolls compound O tire; editor part copies. No physical headset."},"\t"))
	print("PROFILES_SUSPENDED_RESULT ",checks.size()," ",failed)
	quit(0 if failed.is_empty() else 1)
