extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-04-resolution-reveal-monitor/"
var checks: Array[Dictionary] = []
var preview: Node3D
var monitor: Node3D
var stage: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test":title,"passed":passed})
	print("PASS " if passed else "FAIL ",title)

func run() -> void:
	root.size = Vector2i(1440,1000)
	preview = load("res://commons/artifacts/concept_monitor/resolution_reveal_preview.tscn").instantiate()
	root.add_child(preview)
	monitor = preview.get("monitor")
	stage = monitor.get("stage")
	monitor.set_process(false)
	monitor.set_physics_process(false)
	await physics_frame
	await physics_frame
	check(stage.bodies.size()==3 and stage.edges.size()==3,"Three independent native mesh specimens and their actual edges")
	check(monitor.buttons.size()==8,"Eight playback and parameter controls")
	stage.set_resolution(4,0)
	monitor.activate("segments_plus")
	check(stage.segments==5 and stage.rings==0 and not stage.running,"Segments plus changes one count and pauses")
	monitor.activate("rings_plus")
	check(stage.segments==5 and stage.rings==1,"Rings plus changes only the along count")
	monitor.activate("segments_minus")
	monitor.activate("rings_minus")
	check(stage.segments==4 and stage.rings==0,"Both counts can return independently")
	monitor.activate("segments_minus")
	monitor.activate("rings_minus")
	check(stage.segments==4 and stage.rings==0 and stage.bodies[2].mesh.rings==1,"Legal minima with explicit sphere exception")
	stage.set_resolution(64,32)
	monitor.activate("segments_plus")
	monitor.activate("rings_plus")
	check(stage.segments==64 and stage.rings==32,"Manual upper range bounded")
	var meshes: Array = []
	for body in stage.bodies: meshes.append(body.mesh)
	monitor.activate("route")
	var retained := true
	for i in range(3): retained = retained and stage.bodies[i].mesh==meshes[i] and not stage.edges[i].visible
	check(retained,"Surface toggle hides only edges, preserving geometry")
	monitor.activate("route")
	monitor.activate("replay")
	check(not stage.manual and stage.running and stage.playhead==0.0 and stage.segments==4,"Replay restarts the sweep")
	monitor.activate("step")
	check(not stage.running and stage.segments==5 and stage.rings==4,"Step advances one film setting")
	stage.playhead=16.01
	stage.refresh()
	check(stage.segments==12 and stage.rings==0,"Ring sweep holds 12 segments")
	stage.playhead=33.61
	stage.refresh()
	check(stage.segments==4 and stage.rings==0,"Pair sweep starts with the coarse combination")
	stage.replay()
	monitor.call("_physics_process",.2)
	check(monitor.gaze_active,"Looking at the screen starts the film")
	var before: float = stage.playhead
	monitor.call("_process",.1)
	check(stage.playhead>before,"Film advances while viewed")
	var eye: Camera3D = preview.get("camera")
	eye.rotation.y+=PI
	monitor.call("_physics_process",.2)
	before=stage.playhead
	monitor.call("_process",.1)
	check(not monitor.gaze_active and stage.playhead==before,"Looking away freezes the film")
	eye.look_at(Vector3(0,1.5,0))
	monitor.activate("pause")
	monitor.call("_physics_process",.2)
	monitor.call("_process",.1)
	check(stage.playhead==before,"Manual pause survives returning gaze")
	stage.set_resolution(7,9)
	stage.toggle_pause()
	stage.advance(.5)
	check(stage.segments==7 and stage.rings==9 and stage.manual,"Manual play turns the chosen combination without replacing it")
	if DisplayServer.get_name()!="headless":
		var feed: SubViewport = monitor.get("viewport")
		for item in [[4,0,"low"],[12,4,"comparison"],[12,16,"rings"],[64,32,"dense"]]:
			stage.set_resolution(item[0],item[1])
			stage.turn=.27
			stage.refresh()
			await settle(feed)
			feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+item[2]+".png"))
		stage.show_edges=false
		stage.refresh()
		await settle(feed)
		feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"smooth.png"))
		stage.show_edges=true
		stage.set_resolution(12,4)
		monitor.pause_label.text="PLAY"
		await settle(feed)
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"preview.png"))
		var args:=OS.get_cmdline_user_args()
		if not args.is_empty():
			var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
			if bool(spec.get("film",false)):
				var folder: String = spec.run+"frames/"
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
				stage.manual=false
				for i in range(596):
					stage.playhead=float(i)/12.0
					stage.turn=stage.playhead*.17
					stage.refresh()
					await settle(feed)
					feed.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"frame-%04d.png" % i))
				print("FILM: 596 frames rendered")
			await museum_capture(spec)
	var passed:=true
	for item in checks: passed=passed and bool(item.passed)
	var file:=FileAccess.open(OUT+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"))
	file.close()
	print("RESOLUTION REVEAL ","PASS" if passed else "FAIL")
	quit(0 if passed else 1)

func settle(feed: SubViewport) -> void:
	feed.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw

func museum_capture(spec: Dictionary) -> void:
	var folder: String=spec.run
	preview.hide()
	for child in preview.get_children():
		if child is Label: child.hide()
	var museum: Node3D=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","primitives")
	museum.set("start_map","Primitives_Ignorance")
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum)
	var started:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-started<65000: await process_frame
	museum.set("_lazy_pending",0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.5).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))=="Primitives_Ignorance": hall=child
	check(hall!=null,"Actual Primitive Ignorance museum hall loads")
	if hall==null:return
	var placed: Node3D
	for child in hall.find_children("*","Node3D",true,false):
		var script: Script=child.get_script()
		if script!=null and script.resource_path.ends_with("/resolution_reveal_monitor.gd"): placed=child
	check(placed!=null,"Registered resolution monitor appears in the actual hall")
	if placed==null:return
	placed.set_process(false)
	placed.set_physics_process(false)
	placed.stage.set_resolution(12,4)
	placed.pause_label.text="PLAY"
	placed.stage.turn=.27
	placed.stage.refresh()
	var eye:=Camera3D.new()
	root.add_child(eye)
	var target: Vector3=placed.screen.global_position
	eye.global_position=target+placed.global_basis.z*3.2-placed.global_basis.x*.3
	eye.look_at(target)
	eye.fov=68
	eye.make_current()
	await physics_frame
	check(placed.is_looking_at_screen(eye),"Unobstructed viewing position inside the museum")
	for corner in [Vector3(-1.24,-.68,0),Vector3(1.24,-.68,0),Vector3(-1.24,.68,0),Vector3(1.24,.68,0)]:
		var destination: Vector3=placed.screen.to_global(corner)
		var sight:=PhysicsRayQueryParameters3D.create(eye.global_position,destination.move_toward(eye.global_position,.002),1)
		var blocked:=placed.get_world_3d().direct_space_state.intersect_ray(sight)
		check(blocked.is_empty(),"Screen corner visible: "+str(corner))
		if not blocked.is_empty():print("SCREEN BLOCKER ",blocked.collider.get_path())
	for key in placed.buttons:
		var button: Node3D=placed.buttons[key]
		var from:=button.global_position+placed.global_basis.z
		var ray:=PhysicsRayQueryParameters3D.create(from,button.global_position-placed.global_basis.z*.05,1|(1<<20))
		ray.collide_with_areas=true
		var hit:=placed.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider==button,"Hall control reachable: "+key)
	await settle(placed.viewport)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"museum.png"))
	placed.viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"museum-feed.png"))
	var file:=FileAccess.open(OUT+"placement.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"monitor":str(placed.global_position),"map":"Primitives_Ignorance","cell":[1,16]},"\t"))
	file.close()
