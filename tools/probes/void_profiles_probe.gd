extends "res://tools/probes/void_polyhedra_probe.gd"
var floor_index := 10
var floor_y := -60.0
const Source = preload("res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_profiles(false)
		game._set_enabled(false)
		await photograph("passage.png",Vector3(4.9,floor_y+1.75,6.0),Vector3(0,floor_y+2.7,1),85)
		await photograph("through-the-o.png",Vector3(0,floor_y+2.65,2),Vector3(0,floor_y+2,-5.4),85)
		await photograph("vessel-and-wells.png",Vector3(13.3,floor_y+2.2,-1.7),Vector3(17,floor_y+2.4,-4.4),88)
		await photograph("twisting-wells.png",Vector3(11.5,floor_y+2,6),Vector3(17.2,floor_y+2.6,3.5),80)
		await photograph("sections.png",Vector3(16,floor_y+2,1.9),Vector3(16.2,floor_y+.8,-.25),86)
		await photograph("curved-channel.png",Vector3(-13.3,floor_y+1.8,.2),Vector3(-16.6,floor_y+1.2,-3.8),87)
		await photograph("closed-path.png",Vector3(-13.1,floor_y+2.5,3.8),Vector3(-17,floor_y+.7,4.2),82)
		await cleanup(false)
	else:
		await exercise_profiles(false)
		await exercise_profiles(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot desktop and synthetic XR; no physical headset playtest."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive_profiles(use_xr: bool) -> void:
	await start(use_xr)
	for i in game.building.content.data.floors.size():
		if game.building.content.data.floors[i].map=="Primitives_Profiles":floor_index=i
	floor_y=-6.0*floor_index
	game.checkpoint=floor_index;game.place_player(Vector3(11,floor_y+.06,4))
	await frames(75)
	var deadline:=Time.get_ticks_msec()+20000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline:await frames(1)
	await frames(15)

func exercise_profiles(use_xr: bool) -> void:
	await arrive_profiles(use_xr)
	var tag:="XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var hall: Node3D=content.exhibits[str(floor_index)+"/hall"].get_node("Artifact")
	var font:=FontFile.new();font.load_dynamic_font(Source.FONT_PATH)
	var recipe:=Source.new()
	for i in 6:
		var id:="Profile_%d_%s"%[i+1,Source.GLYPHS[i].replace(":","Colon")]
		var part: Node3D=hall.get_node(NodePath(id))
		var sculpture: MeshInstance3D=part.get_node("Sculpture")
		var section: Dictionary=Source.Sweep.profile(font,Source.GLYPHS[i])
		var frames: Array[Transform3D]=recipe._frames(i)
		var original: ArrayMesh=Source.Sweep.make(section,frames,i==4)
		var vertices: PackedVector3Array=sculpture.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(tag+id+" uses unchanged original sweep vertices",vertices==original.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		var contacts: ConcavePolygonShape3D=sculpture.get_node("StaticCollision").get_child(0).shape
		# Godot rounds trimesh coordinates to 0.1 mm. Every triangle must
		# retain its corresponding corners within that tolerance.
		check(tag+id+" concave collision matches every original face within 0.1 mm",same_faces(contacts.get_faces(),vertices) and contacts.backface_collision)
		check(tag+id+" full-size body fits below upper floor",part.scale==Vector3.ONE and sculpture.position.y+sculpture.mesh.get_aabb().end.y<5.64)
		check(tag+id+" retained outline is separately readable",part.has_node("ReadingCard/SourceProfile") and not part.has_node("Plinth") and hall.part_defaults[id].label.length()>8)
		check(tag+id+" has a local shadowless light",not part.get_node("ProfileLight").shadow_enabled)
		# Count connected boundary cycles in the actual font: O=2, B=3,
		# C/I=1, colon=2. Never replace a glyph hole by a painted circle.
		var loops:=boundary_loops(section)
		check(tag+id+" original boundary count",loops.size()==[2,2,3,1,1,2][i])
		if i in [1,2]:
			var ordered: Array=loops.duplicate()
			ordered.sort_custom(func(a,b):return absf(area(a))>absf(area(b)))
			for j in range(1,ordered.size()):
				var centre:=Vector2.ZERO
				for point: Vector2 in ordered[j]:centre+=point
				centre/=ordered[j].size()
				var mouth: Vector3=sculpture.to_global(frames[-1]*Vector3(centre.x,centre.y,0))
				check(tag+id+" open mouth "+str(j),ray(mouth+Vector3.UP*.12,mouth-Vector3.UP*.12).is_empty())
	recipe.free()
	check(tag+"two B sections are editable",hall.part_defaults.has("WellSectionBase") and hall.part_defaults.has("WellSectionTop"))
	var passage: Node3D=hall.get_node("Profile_1_O")
	check(tag+"passage carries the original wp and metre cubes",passage.get_node("ApproachRamp").get_meta("construction_definition")=="wp" and passage.get_node("SillCube0").get_meta("construction_definition")=="structure_2")
	check(tag+"passage opening is actually clear at head height",ray(passage.to_global(Vector3(0,2.65,1.4)),passage.to_global(Vector3(0,2.65,-1.4))).is_empty())
	for stop in content.data.floors[floor_index].route:
		if stop.label=="O / far ramp":
			check(tag+"walk up onto the one-metre deck inside O",await move_to(Vector3(0,floor_y+1,1),false,720))
		var reached:=await move_to(Vector3(stop.position[0],floor_y,stop.position[1]),false,1000)
		check(tag+"walk / "+stop.label,reached)
		if not reached:break
	check(tag+"curated route stays on this floor without damage",game.deaths==0 and game.checkpoint==floor_index and is_equal_approx(game.health.get_health(),100))
	check(tag+"both shafts remain clear",ray(Vector3(-10,floor_y+.3,0),Vector3(-10,floor_y-.3,0)).is_empty() and ray(Vector3(10,floor_y+.3,0),Vector3(10,floor_y-.3,0)).is_empty())
	var film: Node3D=content.exhibits[str(floor_index)+"/museum-primitives_profiles-15-1"].get_node("Artifact")
	check(tag+"original explanatory film still plays",film.stage.frames_by_body.size()==3 and film.position==Vector3.ZERO)
	if not use_xr:
		for id in ["Profile_1_O","Profile_2_O","Profile_3_B","WellSectionTop"]:
			var copy: Node3D=hall.get_script().new();copy.hall="profiles";copy.position=Vector3(0,10,0);root.add_child(copy)
			copy.apply_grid_config({"only_parts":[id],"parts":{id:{"position":[0,0,0],"rotation":[0,90,0]}}})
			await frames(2)
			var part: Node3D=copy.get_node(NodePath(id))
			check(tag+id+" copy retains geometry and collision after move/turn",copy.get_child_count()==1 and part.position==Vector3.ZERO and is_equal_approx(part.rotation_degrees.y,90) and not part.find_children("*","CollisionShape3D",true,false).is_empty())
			copy.free()
	await cleanup(use_xr)

func boundary_loops(section: Dictionary) -> Array:
	var next: Dictionary={}
	for edge: Vector2i in section.boundary:next[edge.x]=edge.y
	var loops: Array=[]
	while not next.is_empty():
		var index: int=next.keys()[0]
		var loop: Array[Vector2]=[]
		while next.has(index):
			loop.append(section.points[index]);var following: int=next[index];next.erase(index);index=following
		loops.append(loop)
	return loops

func area(points: Array) -> float:
	var result:=0.0
	for i in points.size():result+=points[i].cross(points[(i+1)%points.size()])
	return result*.5

func same_faces(actual: PackedVector3Array, expected: PackedVector3Array) -> bool:
	if actual.size()!=expected.size():return false
	for i in actual.size():
		if actual[i].distance_to(expected[i])>.0001:return false
	return true
