extends "res://tools/probes/void_polyhedra_probe.gd"

var floor_index := 12
var floor_y := -72.0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_melencolia(false)
		game._set_enabled(false)
		if "--before" in OS.get_cmdline_user_args():
			await photograph("before.png",Vector3(6,floor_y+3.8,5),Vector3(-5,floor_y+1.6,-1),82)
			await photograph("before-composition.png",Vector3(4,floor_y+2.7,7),Vector3(4,floor_y+1,4.5),68)
		else:
			await photograph("pyramid-court.png",Vector3(5.8,floor_y+3.4,4),Vector3(0,floor_y+2.3,-2),67)
			await photograph("court-and-tableau.png",Vector3(6,floor_y+3.8,5),Vector3(-5,floor_y+1.6,-1),82)
			await photograph("winged-skull.png",Vector3(-11.8,floor_y+2.1,.6),Vector3(-15.8,floor_y+2.1,-2.3),60)
			await photograph("durer-tableau.png",Vector3(-11.8,floor_y+3.2,1.5),Vector3(-16,floor_y+2.4,-1),78)
		await cleanup(false)
	else:
		await exercise_court(false)
		await exercise_court(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot with desktop and synthetic XR. No physical headset claim."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive_melencolia(use_xr: bool) -> void:
	await start(use_xr)
	for i in game.building.content.data.floors.size():
		if game.building.content.data.floors[i].map=="Primitives_Melencolia":floor_index=i
	floor_y=-6.0*floor_index
	game.checkpoint=floor_index;game.place_player(Vector3(11,floor_y+.06,4))
	await frames(75)
	var deadline := Time.get_ticks_msec()+20000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline: await frames(1)
	await frames(10)

func exercise_court(use_xr: bool) -> void:
	await arrive_melencolia(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	var hall: Node3D=content.exhibits[str(floor_index)+"/hall"].get_node("Artifact")
	var engraving: Node3D=hall.get_node("MelencoliaEngraving")
	check(tag+"winged skull replaces the main seated human",engraving.has_node("SkullStudy/Skull") and engraving.has_node("SkullStudy/LeftWing") and engraving.has_node("SkullStudy/RightWing") and not engraving.has_node("Melencolia"))
	check(tag+"Durer solid and magic square retained",engraving.has_node("Polyhedron/TruncatedRhombohedron") and engraving.NUMBERS[0].reduce(func(a,b):return a+b,0)==34)
	var pyramids := 0
	var cubes := 0
	for item in content.data.floors[floor_index].artifacts:
		if item.artifact=="pyramid":
			pyramids+=1
			check(tag+item.id+" at a court corner",absf(float(item.position[0]))==2 and absf(float(item.position[1])+2)==2 and is_equal_approx(item.height,1))
			var shape: Node3D=content.exhibits[str(floor_index)+"/"+item.id].get_node("Artifact")
			check(tag+item.id+" uses original pyramid mesh",shape.scene_file_path.ends_with("pyramid/pyramid.tscn") and shape.pyramid_height==2.4)
		if item.artifact=="cube_scene":
			cubes+=1
			check(tag+item.id+" ochre cross supported at one metre",is_equal_approx(item.height,1.4) and is_equal_approx(item.scale,.8))
	check(tag+"four corners and four cross blocks",pyramids==4 and cubes==4)
	var tall: Node3D=content.exhibits[str(floor_index)+"/museum-primitives_melencolia-5-5"].get_node("Artifact")
	check(tag+"pink centre uses original spire and pedestal",tall.scene_file_path.ends_with("pyramidlong.tscn") and tall.pedestal_height==.8 and tall.global_position.is_equal_approx(Vector3(0,floor_y+1,-2)))
	for point in [Vector3(7,0,4),Vector3(7,0,2.7),Vector3(0,0,2.7),Vector3(0,1,0),Vector3(-1,1,0),Vector3(-1,1,-.9),Vector3(0,1,0),Vector3(0,0,3),Vector3(-6,0,4),Vector3(-13,0,4)]:
		check(tag+"walk "+str(point),await move_to(point+Vector3(0,floor_y,0),false,480))
	check(tag+"walks preserve health and last-floor checkpoint",game.deaths==0 and game.checkpoint==floor_index and is_equal_approx(game.health.get_health(),100))
	for name in ["CourtDeck","CourtRampLeft","CourtRampRight","MelencoliaEngraving"]:
		check(tag+name+" is editable",hall.part_defaults.has(name))
	await cleanup(use_xr)
