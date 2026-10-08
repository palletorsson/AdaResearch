extends SceneTree
var checks: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func record(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title})
	print("PASS " if ok else "FAIL ",title)

func run() -> void:
	var args:=OS.get_cmdline_user_args()
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	create_timer(180+spec.films.size()*120).timeout.connect(func(): push_error("Film probe timed out"); quit(99))
	var all_results: Array = []
	for item: Dictionary in spec.films:
		checks=[]
		var out: String=spec.output+item.id+"/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
		print("FILM BEGIN ",item.id)
		var viewport:=SubViewport.new()
		viewport.size=Vector2i(1024,576)
		viewport.own_world_3d=true
		viewport.world_3d=World3D.new()
		viewport.msaa_3d=Viewport.MSAA_2X
		root.add_child(viewport)
		var resource: PackedScene=load(item.scene)
		if resource==null:
			record(false,"Scene loads")
			all_results.append({"id":item.id,"passed":false,"checks":checks.duplicate(true)})
			viewport.queue_free()
			continue
		var stage: Node3D=resource.instantiate()
		viewport.add_child(stage)
		await process_frame
		if stage.get("phases")==null or stage.get("display")==null:
			record(false,"Stage script initializes")
			all_results.append({"id":item.id,"passed":false,"checks":checks.duplicate(true)})
			viewport.queue_free()
			continue
		record(stage.get("display")!=null and stage.get("camera")!=null,"3D stage and camera exist")
		record(stage.get("phases").size()>=2,"Multiple construction phases")
		if stage.has_method("validation"):
			var validation: Dictionary=stage.call("validation")
			if validation.has("passed"):
				record(bool(validation.passed),"Source-specific validation")
			else:
				record(not validation.get("evidence",{}).is_empty(),"Source evidence exposed for specialist probe")
			var file:=FileAccess.open(out+"validation.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(validation,"\t"))
			file.close()
		var duration: float=stage.get("duration")
		stage.set("running",false)
		var old: float=stage.get("playhead")
		stage.call("advance",.2)
		record(stage.get("playhead")==old,"Manual pause stops time")
		stage.call("replay")
		record(stage.get("playhead")==0 and stage.get("running"),"Replay returns to beginning")
		stage.call("step_sample")
		record(stage.get("playhead")>0 and not stage.get("running"),"Step advances one phase and pauses")
		var phase_count: int=stage.get("phases").size()
		var any_geometry:=false
		for phase in range(phase_count):
			stage.set("playhead",duration*(float(phase)+.72)/phase_count)
			stage.call("refresh")
			var meshes:=stage.find_children("*","MeshInstance3D",true,false)
			meshes.append_array(stage.find_children("*","MultiMeshInstance3D",true,false))
			var visible_count:=0
			for node in meshes:
				var has_mesh: bool = (node.mesh != null) if node is MeshInstance3D else (node.multimesh != null and node.multimesh.mesh != null and node.multimesh.instance_count > 0)
				if node.visible and has_mesh:
					visible_count+=1
					var bounds: AABB=node.get_aabb()
					record(bounds.position.is_finite() and bounds.size.is_finite(),"Finite mesh: phase %d / %s" % [phase,node.name])
			any_geometry=any_geometry or visible_count>0
			if DisplayServer.get_name()!="headless":
				await settle(viewport)
				viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(out+"phase-%02d.png" % phase))
				if phase==phase_count-1:viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(out+"poster.png"))
		record(any_geometry,"Film contains 3D mesh geometry")
		var camera: Camera3D=stage.get("camera")
		var prior:=camera.transform
		stage.call("next_route")
		record(not camera.transform.is_equal_approx(prior),"Turn view changes camera")
		stage.call("refresh")
		record(not camera.transform.is_equal_approx(prior),"Turn view survives the next animation refresh")
		stage.call("orbit",-.28)
		if bool(spec.get("film",false)) and DisplayServer.get_name()!="headless":
			var frames_path: String=spec.frames+item.id+"/"
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_path))
			var fps: float=spec.get("fps",12.0)
			var count:=int(ceil(duration*fps))
			for i in range(count):
				stage.set("playhead",float(i)/fps)
				stage.call("refresh")
				await settle(viewport)
				viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(frames_path+"frame-%04d.png" % i))
			print("FILM FRAMES ",item.id," ",count)
		var passed:=true
		for c in checks:passed=passed and bool(c.passed)
		var result: Dictionary={"id":item.id,"passed":passed,"checks":checks.duplicate(true),"duration":duration,"phases":stage.get("phases"),"evidence":stage.get("evidence"),"source_paths":stage.get("source_paths")}
		all_results.append(result)
		var report:=FileAccess.open(out+"report.json",FileAccess.WRITE)
		report.store_string(JSON.stringify(result,"\t"))
		report.close()
		viewport.queue_free()
		await process_frame
		await process_frame
		print("FILM END ",item.id," ",passed)
	var overall:=true
	for result in all_results:overall=overall and bool(result.passed)
	var summary:=FileAccess.open(spec.report,FileAccess.WRITE)
	summary.store_string(JSON.stringify({"passed":overall,"films":all_results},"\t"))
	summary.close()
	quit(0 if overall else 1)

func settle(viewport: SubViewport) -> void:
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for i in range(2):await process_frame
	await RenderingServer.frame_post_draw
