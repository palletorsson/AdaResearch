extends Node
## Same saved maps, camera, residency, AA and live workload in every look stage.
const Source = preload("res://commons/void/room_source.gd")
const Looks = preload("res://commons/void/visual_profile.gd")
const VIEWS := [
	{"floor":16,"name":"rotation","eye":Vector3(-3.5,5.05,4.8),"target":Vector3(.5,3.1,-1.5)},
	{"floor":30,"name":"light-room","eye":Vector3(-13.6,1.7,4.6),"target":Vector3(-8.8,1.65,-1.8)},
	{"floor":63,"name":"machines","eye":Vector3(7.2,2.5,6.7),"target":Vector3(.5,1.35,-.8)}
]
var game: Node3D
var camera: Camera3D
var look: Node
var out := "user://visual-study"
var report: Dictionary = {"checks":[],"samples":[],"views":[],"physical_headset":false}
var errors: Array[String] = []
var stereo := false
var quick := false
var photo_origin: XROrigin3D
var fixed_pose := Transform3D.IDENTITY
var fixed_tracking := false

func _process(_delta: float) -> void:
	if fixed_tracking and is_instance_valid(camera):
		photo_origin.global_transform = fixed_pose * camera.transform.affine_inverse()

func _ready() -> void:
	run.call_deferred()

func check(label: String, okay: bool) -> void:
	report.checks.append({"name":label,"passed":okay})
	if not okay: errors.append(label)

func frames(n: int) -> void:
	for i in n: await get_tree().process_frame

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--quick":quick=true
	DirAccess.make_dir_recursive_absolute(out)
	Source.use_main_tower=true
	var root := get_tree().root
	if OS.has_feature("android"):
		var interface := XRServer.find_interface("OpenXR")
		stereo = interface != null and (interface.is_initialized() or interface.initialize())
		root.use_xr=stereo
		report.physical_headset=stereo
		check("Quest OpenXR initialized",stereo)
	else:
		root.unfocusable=true
		root.position=Vector2i(80,80)
		root.size=Vector2i(1600,1000)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	report.device={"os":OS.get_name(),"model":OS.get_model_name(),"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"stereo":stereo}
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	game=load("res://commons/void/void.tscn").instantiate()
	game.requested_floor=16
	add_child(game)
	await frames(90)
	game.scene_loaded();game.scene_visible()
	await frames(60)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	if not game.vr:game.body.scripted_input=true
	game._set_enabled(false)
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	if game.desktop_help:game.desktop_help.hide()
	if game.status:game.status.hide()
	look=Looks.new();look.name="VisualProfileStudy";game.add_child(look);look.configure(game,"baseline")
	# Same root MSAA on both looks: no quality downgrade disguised as a speed gain.
	report.msaa=root.msaa_3d
	for view in VIEWS:
		if quick and view.floor!=16:continue
		await floor_study(view)
		FileAccess.open(out.path_join("progress.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	look.set_profile("baseline")
	check("baseline restore removes the unshadowed fill",not look.fill.visible)
	check("baseline restores all architectural bindings",look.bindings.all(func(b):return not is_instance_valid(b.node) or b.node.material_override==b.source))
	report.passed=errors.is_empty();report.failures=errors
	report.scope="Actual saved main-tower maps; fixed camera, live artifacts during timing; motions paused only for matched screenshots. GPU/CPU viewport measurements exclude compositor time. Quest headset tracking is held fixed for reproducible views, not a user walk."
	FileAccess.open(out.path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("VOID_VISUAL_COMPLETE ",JSON.stringify({"passed":report.passed,"out":out,"samples":report.samples.size(),"stereo":stereo}))
	get_tree().quit(0 if report.passed else 1)

func floor_study(view: Dictionary) -> void:
	var floor_index: int=view.floor
	var y: float=game.building.spec.levels[floor_index]
	game.place_player(Vector3(-18,y+.05,7.8))
	game.floor_stream.set_focus(floor_index)
	await frames(150)
	check(str(floor_index)+" actual authored map loaded",game.building.content.roots.has(floor_index))
	game.floor_stream.set_process(false)
	game.floor_stream.set_physics_process(false)
	# Keep exactly the normal nine-floor visibility window, never a solo render set.
	if stereo:
		if not is_instance_valid(photo_origin):
			photo_origin=XROrigin3D.new();game.add_child(photo_origin)
			camera=XRCamera3D.new();photo_origin.add_child(camera)
	else:
		camera=Camera3D.new();game.add_child(camera)
	camera.environment=game.atmosphere.environment;camera.make_current()
	camera.global_position=view.eye+Vector3(0,y,0)
	camera.look_at(view.target+Vector3(0,y,0));camera.fov=70
	fixed_pose=camera.global_transform
	fixed_tracking=stereo
	var camera_pose := camera.global_transform
	var root: Node=game.building.content.roots[floor_index]
	var residency_before: Dictionary=game.floor_stream.summary()
	# Pause only the comparison pictures, not the measured workload.
	var old_modes: Dictionary={}
	for node in [game]+game.find_children("*","",true,false):
		old_modes[node]=node.process_mode;node.process_mode=Node.PROCESS_MODE_DISABLED
	PhysicsServer3D.set_active(false)
	await frames(3)
	var poses := geometry_signature(root)
	for profile in Looks.NAMES:
		look.set_profile(profile)
		await frames(35)
		await RenderingServer.frame_post_draw
		var file := "%02d-%s-%s.png"%[floor_index,view.name,profile]
		get_viewport().get_texture().get_image().save_png(out.path_join(file))
		report.views.append({"floor":floor_index,"profile":profile,"file":file,"camera":str(camera_pose),"materials":look.bindings.size()})
	check(str(floor_index)+" geometry and colliders unchanged across looks",geometry_signature(root)==poses)
	for node in old_modes:node.process_mode=old_modes[node]
	PhysicsServer3D.set_active(true)
	for pass_index in (1 if quick else 2):
		var order: Array=Looks.NAMES.duplicate()
		if pass_index==1:order.reverse()
		for profile in order:
			look.set_profile(profile)
			await frames(60)
			var sample := await measure(1.0 if quick else 3.0)
			sample.floor=floor_index;sample.profile=profile;sample.pass_index=pass_index
			report.samples.append(sample)
			print("VOID_VISUAL_SAMPLE ",JSON.stringify(sample))
	check(str(floor_index)+" same camera through all samples",camera.global_transform.is_equal_approx(camera_pose))
	check(str(floor_index)+" same residency through all samples",game.floor_stream.summary().visible_frame==residency_before.visible_frame)
	look.set_profile("baseline")
	if not stereo:camera.queue_free();game.camera.make_current()
	game.floor_stream.set_process(true);game.floor_stream.set_physics_process(true)
	await frames(5)

func measure(seconds: float) -> Dictionary:
	var wall: Array[float]=[];var gpu: Array[float]=[];var cpu: Array[float]=[]
	var start := Time.get_ticks_usec();var previous := start
	var rid := get_viewport().get_viewport_rid()
	while Time.get_ticks_usec()-start<int(seconds*1000000):
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		wall.append((now-previous)/1000.0);previous=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
	return {"frames":wall.size(),"elapsed_s":(Time.get_ticks_usec()-start)/1000000.0,"frame_ms":stats(wall),"viewport_gpu_ms":stats(gpu),"viewport_cpu_ms":stats(cpu),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"vram_mb":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"viewport_size":str(get_viewport().get_visible_rect().size),"xr_active":XRServer.primary_interface!=null and XRServer.primary_interface.is_initialized()}

func stats(values: Array[float]) -> Dictionary:
	values.sort();var total := 0.0
	for value in values:total+=value
	return {"mean":total/maxi(1,values.size()),"p50":values[int(values.size()*.5)],"p95":values[mini(values.size()-1,int(values.size()*.95))],"max":values.back()}

func geometry_signature(node: Node) -> String:
	var rows: Array[String]=[]
	for item in node.find_children("*","",true,false):
		if item is Node3D:
			rows.append(str(node.get_path_to(item))+str(item.transform)+(str(item.shape) if item is CollisionShape3D else ""))
	return str(rows).sha256_text()

