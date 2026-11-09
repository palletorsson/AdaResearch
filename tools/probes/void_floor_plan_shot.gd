extends SceneTree
## A floor of the main tower photographed from above: the plan as the game builds it, for deciding where things go.
## Run through tools/void_floor_plan_shot.py (it stages the runtime and holds the native slot); writes plan.png and
## plan.json (the camera, so a pixel can be turned back into floor-local metres) into --plan-output.
var game: Node3D

func _initialize() -> void:
	shoot.call_deferred()

func shoot() -> void:
	var folder := ""
	var height := 28.0
	var oblique := false
	var pitch := -18.0   # --pitch=deg: the walker's eyes, up positive
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--plan-output="):folder=arg.trim_prefix("--plan-output=")
		if arg.begins_with("--plan-height="):height=float(arg.trim_prefix("--plan-height="))
		if arg=="--plan-oblique":oblique=true
		if arg.begins_with("--pitch="):pitch=float(arg.trim_prefix("--pitch="))
	load("res://commons/void/room_source.gd").use_main_tower=true
	game=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene=game
	game.body.scripted_input=true;game.body.set_process_unhandled_input(false)
	game.scene_loaded();game.scene_visible()
	var floor: int=game.checkpoint
	for i in 600:
		var record: Dictionary=game.building.content.data.floors[floor]
		if record.artifacts.all(func(a):return game.building.content.exhibits.has(str(floor)+"/"+a.id)):break
		await physics_frame
	for i in 60:await physics_frame
	var base: float=game.building.spec.levels[floor]
	# --walk=x0,z0,x1,z1: the walker itself is driven from a start to a target (floor-local metres), with a photo from
	# its eyes first. A raised surface is only walkable if the capsule actually gets onto it (a ray proves nothing).
	var walk_report := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--walk="):
			var w := Array(arg.trim_prefix("--walk=").split(",")).map(func(s):return float(s))
			# a fifth number starts the walker that high above the slab (on a deck or bank), e.g. --walk=6,0,0,0,3.1
			var start := Vector3(w[0],base+.06+(w[4] if w.size()>4 else 0.0),w[1]);var target := Vector3(w[2],base,w[3])
			game.place_player(start)
			game.body.rotation.y=atan2(-(target.x-start.x),-(target.z-start.z))
			game.camera.rotation=Vector3(deg_to_rad(pitch),0,0)
			for i in 30:await physics_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("eye.png"))
			var y0: float=game.body.global_position.y
			var top := -INF
			game.body.drive=Vector2(0,-1)
			var reached := false
			for i in 900:
				await physics_frame
				top=maxf(top,game.body.global_position.y)
				if Vector2(game.body.global_position.x-target.x,game.body.global_position.z-target.z).length()<.25:reached=true;break
			game.body.drive=Vector2.ZERO
			for i in 30:await physics_frame
			walk_report={"start":[w[0],w[1]],"target":[w[2],w[3]],"reached":reached,"rise_at_end_m":snappedf(game.body.global_position.y-y0,.001),
				"highest_rise_m":snappedf(top-y0,.001),"end":[snappedf(game.body.global_position.x,.01),snappedf(game.body.global_position.z,.01)]}
			print("VOID_WALK ",JSON.stringify(walk_report))
	# A plan needs even light from above; the floor's own lamps are low and local.
	var sun := DirectionalLight3D.new();sun.rotation_degrees=Vector3(-70,25,0);sun.light_energy=1.4;root.add_child(sun)
	for canvas in root.find_children("*","CanvasLayer",true,false):canvas.hide()
	var cam := Camera3D.new();root.add_child(cam)
	cam.far=400.0;cam.current=true
	if oblique:
		cam.position=Vector3(0,base+height*.75,height*.75);cam.look_at(Vector3(0,base,0))
	else:
		# Orthographic size is the vertical extent: 22 m holds the 18 m depth, and a 2:1 window the 42 m width.
		cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=22.0
		cam.position=Vector3(0,base+height,0);cam.rotation_degrees=Vector3(-90,0,0)
		# Clip everything above this floor's ceiling (a storey is 6 m): the plan, not the slab over it.
		cam.near=height-5.4
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("plan.png"))
	var info := {"floor":floor,"base":base,"height":height,"oblique":oblique,"ortho_size":cam.size,"viewport":[root.size.x,root.size.y],"walk":walk_report}
	FileAccess.open(folder.path_join("plan.json"),FileAccess.WRITE).store_string(JSON.stringify(info,"  "))
	print("VOID_PLAN_SHOT ",JSON.stringify(info))
	quit(0)
