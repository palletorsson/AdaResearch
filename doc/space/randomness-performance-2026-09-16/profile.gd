extends SceneTree
## Desktop ablation of actual museum placements. GPU readings are this machine's,
## not Quest measurements. The museum streamer is stopped after one hall builds.
const OUT := "res://doc/space/randomness-performance-2026-09-16/"
const MANIFEST := "res://doc/space/randomness-staging-2026-09-16/manifest.json"
var hall := "Random_Definition"
var em: Node3D
var camera: Camera3D
var metrics: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): hall = arg.trim_prefix("--map=")
	run.call_deferred()

func summarize(values: Array) -> Dictionary:
	values.sort()
	if values.is_empty(): return {}
	return {"median":values[values.size()/2], "p95":values[mini(values.size()-1, int(values.size()*0.95))], "max":values[-1]}

func sample() -> Dictionary:
	var samples := {"frame_interval_ms":[], "process_ms":[], "physics_ms":[], "render_cpu_ms":[], "gpu_ms":[], "draw_calls":[], "primitives":[]}
	var start := Time.get_ticks_usec()
	var last := start
	while Time.get_ticks_usec()-start < 2000000 or samples.frame_interval_ms.size() < 90:
		camera.make_current()
		await process_frame
		var now := Time.get_ticks_usec()
		samples.frame_interval_ms.append((now-last)/1000.0); last=now
		samples.process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		samples.physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
		if RenderingServer.has_method("viewport_get_measured_render_time_gpu"):
			samples.gpu_ms.append(RenderingServer.call("viewport_get_measured_render_time_gpu",root.get_viewport_rid()))
			samples.render_cpu_ms.append(RenderingServer.call("viewport_get_measured_render_time_cpu",root.get_viewport_rid()))
		samples.draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		samples.primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var result := {}
	for key in samples: result[key]=summarize(samples[key])
	result["frames"] = samples.frame_interval_ms.size()
	return result

func inventory(n: Node) -> Dictionary:
	var counts := {"nodes":0,"meshes":0,"multimeshes":0,"multimesh_instances":0,"labels":0,"rigid_bodies":0,"collision_objects":0,"processing_nodes":0,"particles":0,"viewports":0}
	var queue: Array[Node] = [n]
	while not queue.is_empty():
		var node: Node = queue.pop_back()
		counts.nodes += 1
		if node is MeshInstance3D: counts.meshes += 1
		if node is MultiMeshInstance3D:
			counts.multimeshes += 1
			if node.multimesh: counts.multimesh_instances += node.multimesh.instance_count
		if node is Label3D: counts.labels += 1
		if node is RigidBody3D: counts.rigid_bodies += 1
		if node is CollisionObject3D: counts.collision_objects += 1
		if node.is_processing() or node.is_physics_processing(): counts.processing_nodes += 1
		if node is GPUParticles3D or node is CPUParticles3D: counts.particles += 1
		if node is SubViewport: counts.viewports += 1
		for child in node.get_children(): queue.append(child)
	return counts

func suspend(n: Node3D) -> Array:
	var saved: Array = []
	var queue: Array[Node] = [n]
	while not queue.is_empty():
		var node: Node = queue.pop_back()
		saved.append([node,node.process_mode,node.visible if node is Node3D else null])
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is Node3D: node.visible=false
		for child in node.get_children(): queue.append(child)
	# The legacy spawner owns a list of world-parented projectiles.
	if n.get("active_projectiles") != null:
		for projectile in n.get("active_projectiles"):
			if is_instance_valid(projectile): saved.append_array(suspend(projectile))
	return saved

func restore(saved: Array) -> void:
	for row in saved:
		if is_instance_valid(row[0]):
			row[0].process_mode = row[1]
			if row[2] != null: row[0].visible = row[2]

func run() -> void:
	Engine.max_fps=120
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if RenderingServer.has_method("viewport_set_measure_render_time"):
		RenderingServer.call("viewport_set_measure_render_time",root.get_viewport_rid(),true)
	var room: Dictionary = {}
	for row in JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)):
		if row.map == hall: room=row
	var ctl := OUT+hall+"-control.json"
	var f := FileAccess.open(ctl,FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"randomness","dollhouse":0,"grid_pack":1}));f.close()
	em=load(OUT+"measured_museum.gd").new()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","randomness");em.set("start_map",hall)
	var boot := Time.get_ticks_usec()
	root.add_child(em);current_scene=em
	await create_timer(1.0).timeout
	em.set_process(false);em.set_physics_process(false)
	var flush_start := Time.get_ticks_usec()
	em.call("flush_stamps")
	metrics["remaining_flush_ms"]=(Time.get_ticks_usec()-flush_start)/1000.0
	metrics["setup_wall_ms"]=(Time.get_ticks_usec()-boot)/1000.0
	var player: Node3D=em.get("_player")
	if player:
		player.set_process(false);player.set_physics_process(false);player.global_position.y+=30
	var seg: Node3D
	for record in em.get("_segments"):
		if record.node.get_meta("em_map","")==hall: seg=record.node
	if seg==null: push_error("Missing segment "+hall);quit(1);return
	var arts := {}
	for placement in room.placements:
		for node in seg.find_children("*","Node3D",true,false):
			if node.get_meta("artifact_lookup_name","")==placement.lookup:
				arts[placement.lookup]=node;break
	if arts.size()!=room.placements.size(): push_error("Incomplete artifact inventory");quit(1);return
	var hp: Dictionary={}
	for placement in room.placements:
		if placement.lookup==room.hero:hp=placement
	var origin: Vector3=arts[room.hero].global_position-Vector3(hp.x,0,hp.z)
	origin.y=seg.global_position.y
	camera=Camera3D.new();em.add_child(camera);camera.fov=90
	camera.global_position=origin+Vector3(room.size.width/2.0,4.0,0.5)
	camera.look_at(origin+Vector3(room.size.width/2.0,1.0,room.size.depth*0.6));camera.make_current()
	await create_timer(3.0).timeout
	metrics["map"]=hall;metrics["device"]=RenderingServer.get_video_adapter_name()
	metrics["renderer"]=RenderingServer.get_current_rendering_method()
	metrics["engine"]=Engine.get_version_info().string
	metrics["resolution"]="1280x800";metrics["headset_verified"]=false
	metrics["whole_segment"]=inventory(seg)
	metrics["stamp_times"]=em.get("stamp_times")
	metrics["segment_times"]=em.get("segment_times")
	metrics["full_before"]=await sample()
	metrics["artifacts"]=[]
	for key in arts:
		var row := {"lookup":key,"inventory":inventory(arts[key])}
		if "--quick" in OS.get_cmdline_user_args():
			metrics.artifacts.append(row)
			continue
		var state:=suspend(arts[key])
		await create_timer(0.35).timeout
		row["without"]=await sample()
		restore(state)
		await create_timer(0.35).timeout
		metrics.artifacts.append(row)
	metrics["full_after"]=await sample()
	var all_state: Array=[]
	for key in arts:all_state.append_array(suspend(arts[key]))
	await create_timer(0.35).timeout
	metrics["without_artifacts"]=await sample()
	restore(all_state)
	for i in range(15):
		camera.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+hall+"-view.png")
	f=FileAccess.open(OUT+hall+".json",FileAccess.WRITE);f.store_string(JSON.stringify(metrics,"  "));f.close()
	print("[randomness-performance] ",hall," complete")
	quit(0)
