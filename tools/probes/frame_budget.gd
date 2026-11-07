extends SceneTree
## WHAT IS EATING THE FRAME? (2026-11-07, Palle: "the frame rate is lower after adding the grid ... Do we have
## something that checks every frame, what is eating memory?"). Opens one floor of the main tower as desktop play does,
## then:
##   1. BASELINE from the arrival, four ways round: frame ms (vsync off, uncapped), CPU logic, physics, render CPU/GPU
##      ms, draw calls, objects, primitives, video and static memory, nodes.
##   2. CENSUS of every part (each work on the floor, the timeline walk, the floor below seen through the shafts, the
##      building's storeys): meshes, triangles, MultiMesh instances, materials and transparent ones, lights, shadows,
##      particles, viewports, bodies, nodes that process.
##   3. COST of each part: look at it, measure, hide it (visible off, processing off), measure again. The difference is
##      what that part costs when you look at it.
## Writes <out>/budget.json. Runner: tools/frame_budget.py.
var game: Node3D
var folder := ""
var vp: RID

func _initialize() -> void:
	open_game.call_deferred()

func open_game() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--play-output="):folder=arg.trim_prefix("--play-output=")
	load("res://commons/void/room_source.gd").use_main_tower=true
	game=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene=game
	game.body.scripted_input=true;game.body.set_process_unhandled_input(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	game.scene_loaded();game.scene_visible()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	vp=root.get_viewport_rid();RenderingServer.viewport_set_measure_render_time(vp,true)
	var floor: int=game.checkpoint
	var record: Dictionary=game.building.content.data.floors[floor]
	for i in 600:
		if record.artifacts.all(func(a):return game.building.content.exhibits.has(str(floor)+"/"+a.id)):break
		await physics_frame
	# THE ARRIVAL: every frame for 14 s - its length, and which works were built in it (the floor below streams in now)
	var seen := {};var hitches: Array=[];var t_start := Time.get_ticks_usec();var last := t_start
	for key in game.building.content.exhibits:seen[key]=true
	while Time.get_ticks_usec()-t_start<14e6:
		await process_frame
		var now := Time.get_ticks_usec();var ms := (now-last)/1000.0;last=now
		var fresh: Array=[]
		for key in game.building.content.exhibits:
			if not seen.has(key):
				seen[key]=true
				var item: Dictionary=game.building.content.data.floors[int(str(key).get_slice("/",0))].artifacts.filter(func(a):return a.id==str(key).get_slice("/",1)).front() if true else {}
				fresh.append(str(key)+" ("+str(item.get("artifact","?"))+")")
		if ms>30.0 or not fresh.is_empty():
			hitches.append({"t_s":snappedf((now-t_start)/1e6,.01),"ms":snappedf(ms,.1),"built":fresh,"last_build_ms":snappedf(float(game.building.content.last_build_ms),.1),"pending":game.building.content.pending.size()})
	# what one residency pass over the floor below costs, synchronously, and a lone die: build, then each next frame
	var experiments := {}
	var fs: Node=game.floor_stream
	if fs.records.has(floor+1):
		var t := Time.get_ticks_usec();fs.records[floor+1].needs_refresh=true;fs._refresh()
		experiments["residency_refresh_ms"]=snappedf((Time.get_ticks_usec()-t)/1000.0,.1)
		t=Time.get_ticks_usec();fs.records[floor+1].refresh_pickables()
		experiments["refresh_pickables_ms"]=snappedf((Time.get_ticks_usec()-t)/1000.0,.1)
	for term in ["dice","brick"]:
		var t := Time.get_ticks_usec()
		var die: Node3D=load("res://commons/modular/composite.tscn").instantiate();die.set("term",term)
		root.add_child(die);die.global_position=game.camera.global_position-game.camera.global_basis.z*1.5
		var row := {"build_ms":snappedf((Time.get_ticks_usec()-t)/1000.0,.1),"frames_ms":[]}
		var last2 := Time.get_ticks_usec()
		for i in 4:
			await process_frame
			var now := Time.get_ticks_usec();row.frames_ms.append(snappedf((now-last2)/1000.0,.1));last2=now
		experiments["lone_"+term]=row
		die.queue_free()
	# the real path: a copy of the floor below's die built by floor_content itself, then each next frame
	var below: Dictionary=game.building.content.data.floors[floor+1] if floor+1<game.building.content.data.floors.size() else {}
	for want in ["mod_dice","association_tape"]:
		var src: Array=below.get("artifacts",[]).filter(func(a):return a.artifact==want)
		if src.is_empty():continue
		var item: Dictionary=src[0].duplicate(true);item.id="probe-"+want
		var t := Time.get_ticks_usec()
		game.building.content._build_artifact(game.building.content.roots[floor+1],floor+1,item)
		var row := {"build_ms":snappedf((Time.get_ticks_usec()-t)/1000.0,.1)}
		t=Time.get_ticks_usec();game.building.content.floor_changed.emit(floor+1)
		row["floor_changed_ms"]=snappedf((Time.get_ticks_usec()-t)/1000.0,.1)
		var frames: Array=[];var last3 := Time.get_ticks_usec()
		for i in 5:
			await process_frame
			var now := Time.get_ticks_usec();frames.append(snappedf((now-last3)/1000.0,.1));last3=now
		row["frames_ms"]=frames
		experiments["real_path_"+want]=row
	game.body.enabled=false   # stand still: the camera turns, the body does not fall or drift
	var eye: Vector3=game.camera.global_position
	# 1. baseline, four ways round
	# twice round: the first pass pays for shaders compiled the first time a material is seen, the second is the floor
	var base := {}
	var yaws: Array=[0,90,180,270]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--yaws="):yaws=Array(arg.trim_prefix("--yaws=").split(",")).map(func(v):return int(v))
	if OS.get_cmdline_user_args().has("--baseline-only"):
		pass
	for lap in ["first","again"]:
		for yaw in yaws:
			_look_yaw(deg_to_rad(yaw));await _wait(.4)
			base[lap+" "+str(yaw)]=await _measure(1.5)
	# what multiplies the draws: facing the worst way, switch off the small lamps, then shadows, then both
	var worst_yaw: int=yaws[0]
	for k in base:
		if k.begins_with("again") and int(base[k].draw_calls)>int(base["again "+str(worst_yaw)].draw_calls):worst_yaw=int(k.get_slice(" ",1))
	_look_yaw(deg_to_rad(worst_yaw));await _wait(.4)
	var lamps: Array=root.find_children("*","Light3D",true,false)
	var small: Array=lamps.filter(func(l):return l.is_visible_in_tree() and not (l is DirectionalLight3D))
	var shadowed: Array=lamps.filter(func(l):return l.is_visible_in_tree() and l.shadow_enabled)
	experiments["lights_in_view_tree"]={"small_visible":small.size(),"shadowed_visible":shadowed.size(),"directional":lamps.filter(func(l):return l is DirectionalLight3D and l.is_visible_in_tree()).map(func(l):return [str(l.get_path()),l.shadow_enabled,int(l.directional_shadow_mode)])}
	experiments["worst_yaw"]=worst_yaw
	experiments["as_is"]=await _measure(1.0)
	for l in small:l.visible=false
	await _wait(.3);experiments["no_small_lamps"]=await _measure(1.0)
	for l in small:l.visible=true
	for l in shadowed:l.shadow_enabled=false
	await _wait(.3);experiments["no_shadows"]=await _measure(1.0)
	for l in small:l.visible=false
	await _wait(.3);experiments["neither"]=await _measure(1.0)
	for l in small:l.visible=true
	for l in shadowed:l.shadow_enabled=true
	await _wait(.3)
	var per_light: Array=[]
	for l in shadowed+small.filter(func(x):return not x.shadow_enabled):
		var with := await _measure(.8)
		var was_shadow: bool=l.shadow_enabled
		if was_shadow:l.shadow_enabled=false
		else:l.visible=false
		await _wait(.3)
		var without := await _measure(.8)
		if was_shadow:l.shadow_enabled=true
		else:l.visible=true
		var vp_owner: Viewport=l.get_viewport()
		per_light.append({"path":str(l.get_path()).trim_prefix("/root/TheVoid/"),"type":l.get_class(),"toggled":"shadow" if was_shadow else "light",
			"own_world":vp_owner!=root and vp_owner.own_world_3d,"in_subviewport":vp_owner!=root,
			"range":l.get("omni_range") if l is OmniLight3D else (l.get("spot_range") if l is SpotLight3D else 0),
			"saves_ms":snappedf(with.median_ms-without.median_ms,.01),"saves_draws":with.draw_calls-without.draw_calls})
	experiments["per_light"]=per_light
	if OS.get_cmdline_user_args().has("--baseline-only"):
		FileAccess.open(folder.path_join("budget.json"),FileAccess.WRITE).store_string(JSON.stringify({"floor":floor,"title":record.get("title",""),"map":record.get("map",""),
			"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"baseline":base,"arrival":hitches,"experiments":experiments,"parts":[]},"  "))
		quit(0);return
	# 2. census + 3. cost
	var parts: Array=[]
	var content_root: Node3D=game.building.content.roots[floor]
	for key in game.building.content.exhibits:
		if not str(key).begins_with(str(floor)+"/"):continue
		parts.append({"name":str(key).trim_prefix(str(floor)+"/"),"kind":"work","node":game.building.content.exhibits[key]})
	for child in content_root.get_children():
		if child.name=="TimelineWalk":parts.append({"name":"TimelineWalk","kind":"timeline","node":child})
	if game.building.content.roots.has(floor+1):parts.append({"name":"floor %d below (preview)"%(floor+1),"kind":"floor_below","node":game.building.content.roots[floor+1]})
	for i in game.building.floors.size():
		if game.building.floors[i].visible:parts.append({"name":"storey %d (building)"%i,"kind":"storey","node":game.building.floors[i]})
	var rows: Array=[]
	for part in parts:
		var node: Node3D=part.node
		var census := _census(node)
		var row := {"name":part.name,"kind":part.kind,"census":census}
		if node.visible and census.meshes+census.lights+census.particles>0:
			var centre := _centre(node)
			if centre.distance_to(eye)>.5:_look_at(centre)
			else:_look_yaw(0)
			await _wait(.3)
			var on := await _measure(.6)
			var was_mode:=node.process_mode
			node.visible=false;node.process_mode=Node.PROCESS_MODE_DISABLED
			await _wait(.3)
			var off := await _measure(.6)
			node.visible=true;node.process_mode=was_mode
			row["distance_m"]=snappedf(centre.distance_to(eye),.1)
			row["cost"]={"frame_ms":snappedf(on.median_ms-off.median_ms,.01),"mean_ms":snappedf(on.frame_ms-off.frame_ms,.01),"render_cpu_ms":snappedf(on.render_cpu_ms-off.render_cpu_ms,.01),
				"render_gpu_ms":snappedf(on.render_gpu_ms-off.render_gpu_ms,.01),"logic_ms":snappedf(on.logic_ms-off.logic_ms,.01),
				"physics_ms":snappedf(on.physics_ms-off.physics_ms,.01),"draw_calls":on.draw_calls-off.draw_calls,"primitives":on.primitives-off.primitives}
			row["seen"]=on
		rows.append(row)
	rows.sort_custom(func(a,b):return float(a.get("cost",{}).get("frame_ms",-99))>float(b.get("cost",{}).get("frame_ms",-99)))
	var report := {"floor":floor,"title":record.get("title",""),"map":record.get("map",""),"renderer":RenderingServer.get_current_rendering_method(),
		"gpu":RenderingServer.get_video_adapter_name(),"baseline":base,"arrival":hitches,"experiments":experiments,"parts":rows}
	FileAccess.open(folder.path_join("budget.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FRAME_BUDGET done ",floor)
	quit(0)

func _measure(seconds: float) -> Dictionary:
	var times: Array[float]=[];var last := Time.get_ticks_usec()
	var frames := 0;var logic := 0.0;var physics := 0.0;var cpu := 0.0;var gpu := 0.0
	var start := Time.get_ticks_usec();var end := start+int(seconds*1e6)
	while Time.get_ticks_usec()<end:
		await process_frame
		var now := Time.get_ticks_usec();times.append((now-last)/1000.0);last=now
		frames+=1
		logic+=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		physics+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
		cpu+=RenderingServer.viewport_get_measured_render_time_cpu(vp)
		gpu+=RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var n := maxf(frames,1)
	times.sort()
	var median: float=times[times.size()/2] if not times.is_empty() else 0.0
	var worst: float=times[-1] if not times.is_empty() else 0.0
	return {"median_ms":snappedf(median,.01),"worst_ms":snappedf(worst,.01),"spikes_over_50ms":times.filter(func(t):return t>50.0).size(),"frame_ms":snappedf((Time.get_ticks_usec()-start)/1000.0/n,.01),"fps":snappedf(n/((Time.get_ticks_usec()-start)/1e6),.1),
		"logic_ms":snappedf(logic/n,.01),"physics_ms":snappedf(physics/n,.01),"render_cpu_ms":snappedf(cpu/n,.01),"render_gpu_ms":snappedf(gpu/n,.01),
		"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"objects":int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives":int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_mb":snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,.1),
		"static_mb":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,.1),
		"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}

func _census(node: Node) -> Dictionary:
	var c := {"nodes":0,"meshes":0,"triangles":0,"multimesh_instances":0,"materials":0,"transparent_materials":0,
		"lights":0,"shadow_lights":0,"particles":0,"viewports":0,"rigid":0,"soft":0,"static":0,"processing":0}
	var mats := {}
	var stack: Array=[node]
	while not stack.is_empty():
		var n: Node=stack.pop_back()
		c.nodes+=1
		if n.get_script()!=null and (n.is_processing() or n.is_physics_processing()):c.processing+=1
		if n is MeshInstance3D and n.mesh!=null:
			c.meshes+=1;c.triangles+=_tris(n.mesh)
			for m in [n.material_override]+_surface_mats(n):_note_mat(m,mats,c)
		elif n is MultiMeshInstance3D and n.multimesh!=null and n.multimesh.mesh!=null:
			c.meshes+=1;c.multimesh_instances+=n.multimesh.instance_count
			c.triangles+=_tris(n.multimesh.mesh)*n.multimesh.visible_instance_count if n.multimesh.visible_instance_count>=0 else _tris(n.multimesh.mesh)*n.multimesh.instance_count
			_note_mat(n.material_override,mats,c)
		elif n is CSGShape3D:c.meshes+=1
		elif n is Light3D:
			c.lights+=1
			if n.shadow_enabled:c.shadow_lights+=1
		elif n is GPUParticles3D or n is CPUParticles3D:c.particles+=1
		elif n is SubViewport:c.viewports+=1
		elif n is RigidBody3D:c.rigid+=1
		elif n is SoftBody3D:c.soft+=1
		elif n is StaticBody3D:c.static+=1
		for ch in n.get_children():stack.append(ch)
	return c

func _surface_mats(n: MeshInstance3D) -> Array:
	var out: Array=[]
	for i in n.mesh.get_surface_count():
		var m: Material=n.get_surface_override_material(i)
		out.append(m if m!=null else n.mesh.surface_get_material(i))
	return out

func _note_mat(m: Material, mats: Dictionary, c: Dictionary) -> void:
	if m==null or mats.has(m.get_instance_id()):return
	mats[m.get_instance_id()]=true;c.materials+=1
	if m is BaseMaterial3D and m.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:c.transparent_materials+=1

func _tris(mesh: Mesh) -> int:
	var t := 0
	for i in mesh.get_surface_count():
		if mesh is ArrayMesh or mesh is PrimitiveMesh:
			var arr: Array=mesh.surface_get_arrays(i)
			if arr.is_empty():continue
			var idx=arr[Mesh.ARRAY_INDEX]
			t+=(idx.size() if idx!=null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())/3
	return t

func _centre(node: Node3D) -> Vector3:
	var box := AABB();var first := true
	for m in node.find_children("*","VisualInstance3D",true,false):
		if not (m is GeometryInstance3D):continue
		var b: AABB=(m as VisualInstance3D).global_transform*(m as VisualInstance3D).get_aabb()
		if first:box=b;first=false
		else:box=box.merge(b)
	return box.get_center() if not first else node.global_position

func _look_yaw(yaw: float) -> void:
	game.body.rotation.y=yaw;game.camera.rotation=Vector3(-.12,0,0)

func _look_at(p: Vector3) -> void:
	var o: Vector3=p-game.camera.global_position
	game.body.rotation.y=atan2(-o.x,-o.z)
	game.camera.rotation=Vector3(clampf(atan2(o.y,Vector2(o.x,o.z).length()),-1.2,1.2),0,0)

func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<end:await process_frame
