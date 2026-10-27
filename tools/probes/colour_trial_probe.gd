extends "res://tools/probes/array_trial_probe.gd"
const IDS := ["one","by-shape","by-height","by-neighbour"]

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left = tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right = tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO)
		right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false)
	game = load("res://commons/void/trials/color/trial.tscn").instantiate()
	game.force_xr = xr
	root.add_child(game);current_scene=game
	if not xr: game.body.scripted_input=true
	await frames(50)
	game.scene_loaded();game.scene_visible()
	await frames(20)
	game.atmosphere.animate_sky=false

func station(id: String) -> Node3D:
	return game.building.content.exhibits["1/"+id].get_node("Artifact")

func press(button: Node3D) -> void:
	if not xr:
		await super.press(button)
		return
	# Approach the actual panel face, including a curator's quarter-turn.
	var origin: Node3D=game.get_node("XROrigin3D")
	var target: Vector3=button.global_position
	var s: Node=button
	while not s.has_method("paint_selected"):s=s.get_parent()
	var at: Vector3=target+s.global_basis*Vector3(0,.04,.65)
	var aim := Basis.looking_at(target-at)
	right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(20)
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(12)
	hand_at(right,game.body.global_position+Vector3(.3,1.2,-.4))

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	var player_before: Vector3=game.body.global_position
	game.place_player(Vector3(19,-5.94,7))
	await frames(5)
	await super.photo(filename,at,target)
	game.place_player(player_before)
	await frames(5)

func colours(s: Node3D) -> Array:
	return s.elements().map(func(p):return p.get_surface_override_material(0).albedo_color)

func geometry(s: Node3D) -> Array:
	var result: Array=[]
	for p in s.elements(): result.append([p.get_instance_id(),p.mesh.get_rid(),p.transform])
	for shape in s.get_node("Body").get_children():
		result.append([shape.get_instance_id(),shape.shape.get_rid(),shape.transform])
	return result

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	var tower_before := FileAccess.get_sha256("res://commons/void/rooms.json")
	for use_xr in [false,true]: await visit_colour(use_xr)
	check("curated tower unchanged",FileAccess.get_sha256("res://commons/void/rooms.json")==tower_before)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Actual desktop and synthetic XR pointer events, Mobile renderer, native screenshots. Physical headset not tested."
	},"\t"))
	print("COLOUR_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_colour(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"shared Void player and fixed floor",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.shafts.size()==2)
	check(tag+"all 23 independently editable pillars",game.building.content.exhibits.size()==23)
	await gallery_checks(tag)
	var reference: Node3D=station("one")
	var pieces: Array=reference.elements()
	check(tag+"original stack builder reused",reference.get_script().get_base_script().resource_path=="res://commons/artifacts/chroma_stack/chroma_stack.gd")
	var equal_geometry := true
	var materials := {}
	for id in IDS:
		var s: Node3D=station(id)
		equal_geometry=equal_geometry and s.elements().size()==5 and s.scale.is_equal_approx(Vector3.ONE)
		for i in 5:
			var p: MeshInstance3D=s.elements()[i]
			equal_geometry=equal_geometry and p.transform.is_equal_approx(pieces[i].transform) and p.mesh.get_aabb()==pieces[i].mesh.get_aabb()
			materials[p.get_surface_override_material(0).get_instance_id()]=true
		for lamp in s.find_children("WhiteStudyLight*","OmniLight3D",true,false):
			equal_geometry=equal_geometry and lamp.light_color==Color.WHITE and lamp.light_cull_mask==2
	check(tag+"same five full-size forms and matched white lamps",equal_geometry)
	check(tag+"twenty independent materials",materials.size()==20)
	check(tag+"sun excludes comparison layer",game.atmosphere.get_node("WarmSun").light_cull_mask&2==0)
	var one := colours(reference)
	var shape := colours(station("by-shape"))
	var height := colours(station("by-height"))
	var neighbour := colours(station("by-neighbour"))
	check(tag+"one coat applies to every address",one.all(func(c):return c.is_equal_approx(Color(.78,.6,.3))))
	check(tag+"shape groups separated blocks and round forms",shape[0]==shape[1] and shape[1]==shape[3] and shape[2]==shape[4] and shape[0]!=shape[2])
	check(tag+"height changes all five colours",height[0]!=height[1] and height[1]!=height[2] and height[2]!=height[3] and height[3]!=height[4] and absf(height[0].h-.58318)<.001 and absf(height[4].h-.1383)<.001)
	check(tag+"neighbour alternates complementary colours",neighbour[0].is_equal_approx(neighbour[2]) and neighbour[2].is_equal_approx(neighbour[4]) and neighbour[1].is_equal_approx(neighbour[3]) and absf(neighbour[1].h-neighbour[0].h-.5)<.001)
	if not xr:
		await photo("four-rules",Vector3(0,-4.25,4.8),Vector3(0,-3.7,-4.7))
		await photo("inside-the-tower",Vector3(-6.8,-4.3,7.8),Vector3(4,-2.8,0))
		await photo("shape-and-composition",Vector3(-16.4,-4.3,7.8),Vector3(-16.4,-2.9,-2))
		await photo("gallery-columns",Vector3(16.5,-4.3,7.8),Vector3(16.5,-1.8,-1.5))
		await photo("celebration",Vector3(0,-3.7,8),Vector3(8,-1.7,-1))
	# Mouse and controller both hit the real panel colliders.
	game.place_player(Vector3(-5.4,-5.94,-2.3));await frames(20)
	var geometry_before := geometry(reference)
	var neighbours_before := [colours(station("by-shape")),colours(station("by-height")),colours(station("by-neighbour"))]
	await press(reference.rule_button)
	check(tag+"pointer changes the actual rule",reference.rule=="by_shape" and colours(reference)==shape)
	await press(reference.part_button)
	check(tag+"pointer selects array address three",reference.selected_part==3 and reference.readout.text.begins_with("[3]"))
	var before := colours(reference)
	await press(reference.paint_button)
	var painted := colours(reference)
	check(tag+"pointer repaints only selected address",painted[3]!=before[3] and painted[0]==before[0] and painted[1]==before[1] and painted[2]==before[2] and painted[4]==before[4])
	check(tag+"neighbouring instances retain all their colours",neighbours_before==[colours(station("by-shape")),colours(station("by-height")),colours(station("by-neighbour"))])
	check(tag+"repaint leaves mesh resources, transforms and colliders intact",geometry(reference)==geometry_before)
	if not xr: await photo("paint-one-part",Vector3(-6.8,-4.35,-1.7),Vector3(-5.4,-4.1,-4.7))
	await press(reference.reset_button)
	check(tag+"RESET returns to starting rule and address",reference.rule=="one" and colours(reference)==one and reference.selected_part==2 and not reference.paint_override)
	for i in 12: reference.next_rule()
	check(tag+"repeated changes neither rebuild nor grow geometry",geometry(reference)==geometry_before and colours(reference)==one and reference.find_children("WhiteStudyLight*","OmniLight3D",true,false).size()==2)
	# A moved, quarter-turned copy uses its own local geometry and controls.
	var copy: Node3D=load("res://commons/void/trials/color/colour_station.tscn").instantiate()
	copy.set_meta("config_rule","by_height")
	copy.position=Vector3(0,-6,0);copy.rotation.y=PI/2
	game.add_child(copy);await frames(15)
	var copy_before := colours(copy)
	game.place_player(Vector3(2.3,-5.94,0));await frames(15)
	await press(copy.paint_button)
	check(tag+"relocated rotated copy responds to the same pointer",colours(copy)[2]!=copy_before[2] and colours(reference)==one)
	copy.queue_free();await frames(5)
	game.die("Retry colour");await frames(130)
	check(tag+"retry reconstructs the four authored assignments",not game.recovering and station("one").rule=="one" and station("by-shape").rule=="by_shape" and station("by-height").rule=="by_height" and station("by-neighbour").rule=="by_neighbour")
	check(tag+"retry restores 23 pillars with bounded controls and lamps",game.building.content.exhibits.size()==23 and game.find_children("ColourControls","Node3D",true,false).size()==4 and game.find_children("WhiteStudyLight*","OmniLight3D",true,false).size()==8)
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

func gallery_checks(tag: String) -> void:
	var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Color_Context_Placed/map_data.json"))
	var tokens: Array[String]=[]
	collect_tokens(original,tokens)
	var signatures: Array[String]=[]
	var retained := true
	var within := true
	var bounds_report := {}
	for item in game.building.content.data.floors[1].artifacts:
		var artifact: Node3D=station(item.id)
		var c: Dictionary=item.config
		var signature := "dna:"+str(c.study) if c.has("study") else "chroma:%s/%s/%s"%[c.get("rule","one"),c.get("stack","bauhaus"),c.get("pose","aligned")]
		signatures.append(signature)
		if item.artifact!="void_colour_station":
			retained=retained and artifact.get_script().resource_path=="res://commons/artifacts/%s/%s.gd"%[item.artifact,item.artifact]
		var bounds := AABB()
		var first := true
		for mesh in artifact.find_children("*","MeshInstance3D",true,false):
			var b: AABB=mesh.global_transform*mesh.get_aabb()
			bounds=b if first else bounds.merge(b)
			first=false
		bounds_report[item.id]={"min":[bounds.position.x,bounds.position.y,bounds.position.z],"max":[bounds.end.x,bounds.end.y,bounds.end.z]}
		within=within and bounds.end.y<2.2 and bounds.position.x>=-21 and bounds.end.x<=21 and bounds.position.z>=-9 and bounds.end.z<=9 and is_equal_approx(item.scale,1.0)
	check(tag+"all 23 original museum configurations retained",tokens.size()==23 and tokens.all(func(t):return signatures.count(t)==tokens.count(t)))
	check(tag+"nineteen gallery additions use original scripts",retained)
	check(tag+"full-size columns fit taller canopy and existing slab",within and game.building.spec.levels[0]-game.building.spec.levels[1]==9)
	var dna_heights := true
	var studies: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/color_dna_stack/studies.json"))
	for study in studies:
		var a: Node3D=station("gallery-"+study)
		var expected := 0.0
		for p in studies[study].parts:expected+=float(p.height)
		dna_heights=dna_heights and is_equal_approx(a.part_bounds.back().end.y,expected) and a.source_ids.size()==studies[study].parts.size()
	check(tag+"all eight gallery studies retain their authored heights and sources",dna_heights)
	if not xr:FileAccess.open(out.path_join("pillar-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(bounds_report,"\t"))
	game.place_player(Vector3(0,-5.94,2.5));await frames(15)
	var clear := true
	# Walk the real body around both shafts and through both pillar collections.
	for p in [Vector2(-6.6,2.5),Vector2(-6.6,7.9),Vector2(-16.5,7.9),Vector2(-16.5,-6.2),Vector2(-7,-6.2),Vector2(7,-6.2),Vector2(16.5,-6.2),Vector2(16.5,7.9),Vector2(6.8,7.9),Vector2(6.8,2.5),Vector2(0,2.5)]:
		if not await walk(Vector3(p.x,-6,p.y)):
			clear=false
			break
	check(tag+"walkable loop visits every family without a fall",clear and game.checkpoint==1 and not game.recovering)
	game.place_player(Vector3(0,-5.94,2.5));await frames(15)

func collect_tokens(value: Variant, found: Array[String]) -> void:
	if value is Dictionary:
		for v in value.values():collect_tokens(v,found)
	elif value is Array:
		for v in value:collect_tokens(v,found)
	elif value is String and (value.begins_with("chroma_stack:") or value.begins_with("color_dna_stack:")):
		var config := {}
		for part in value.split("#"):
			var pair: PackedStringArray=part.split(":")
			if pair.size()==2:config[pair[0]]=pair[1]
		found.append("dna:"+str(config.study) if config.has("study") else "chroma:%s/%s/%s"%[config.get("rule","one"),config.get("stack","bauhaus"),config.get("pose","aligned")])
