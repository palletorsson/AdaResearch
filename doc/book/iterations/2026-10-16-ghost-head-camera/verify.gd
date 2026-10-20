extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-ghost-head-camera/"
var checks: Array=[]
var failures: Array=[]
var pairs: Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures.append(label);print("FAIL ",label)
func run() -> void:
	AudioServer.set_bus_mute(0,true)
	root.size=Vector2i(1600,1050)
	var preview: Node3D=load("res://commons/artifacts/prefab_disorder/preview.tscn").instantiate();root.add_child(preview)
	var bench: Node3D=preview.bench
	var ghost: Node3D=bench.ghost
	var rig: Node=ghost.observer
	ghost.auto_enabled=false;ghost.speed=8
	for i in 5: await process_frame
	var main_camera: Camera3D=preview.get_node("Camera")
	check("both cameras share the live artifact world",rig.views.all(func(v):return v.world_3d==bench.get_world_3d()))
	check("adding observers does not replace the visitor camera",root.get_camera_3d()==main_camera)
	check("observers do not render continuously by default",rig.views.all(func(v):return v.render_target_update_mode==SubViewport.UPDATE_DISABLED))
	check("eye marker is inside the moving head",ghost.actor.eyes.get_parent()==ghost.actor.head and ghost.actor.eyes.position==Vector3(0,0,-0.08))
	check("head shell excluded only from eye view",rig.cameras[0].cull_mask & ghost.actor.HEAD_LAYER==0 and rig.cameras[1].cull_mask & ghost.actor.HEAD_LAYER!=0)
	check("hands retained in eye view",ghost.actor.hands[0].get_child(0).layers & rig.cameras[0].cull_mask!=0)
	rig.captured.connect(func(receipt):pairs.append(receipt))
	check("rehearsal begins",ghost.start())
	for i in 2200:
		await process_frame
		if not ghost.active: break
	check("all actions still work while cameras record",ghost.report.status=="completed" and ghost.report.steps.size()==9 and ghost.report.steps.all(func(s):return s.passed))
	check("exactly four automatic paired observations",pairs.size()==4 and ghost.report.observations.size()==4)
	var saved: Array=pairs.duplicate(true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR+"captures"))
	for pair in saved:
		check(pair.label+": both PNGs and receipt saved",pair.status=="saved" and pair.files.size()==2 and FileAccess.file_exists(pair.record))
		check(pair.label+": state and pixels use one process frame",pair.same_process_frame)
		check(pair.label+": receipt contains full replayable state",bench.valid_record(pair.artifact_state))
		for channel in ["eyes","outside"]:
			var source: String=pair.folder+"/"+pair.files[channel].name
			var image:=Image.load_from_file(source)
			check(pair.label+" "+channel+": image size and hash match",image!=null and image.get_size()==rig.SIZE and FileAccess.get_sha256(source)==pair.files[channel].sha256)
			DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(DIR+"captures/"+pair.files[channel].name))
		DirAccess.copy_absolute(ProjectSettings.globalize_path(pair.record),ProjectSettings.globalize_path(DIR+"captures/"+pair.label+".json"))
	check("before-touch capture precedes ORIGINAL input",saved[0].step==1 and saved[0].phase=="reach")
	check("separation state is the midpoint",saved[1].artifact_state.disorder==0.5)
	check("new seed state is a fully formed hybrid",saved[2].artifact_state.seed=="436" and saved[2].artifact_state.disorder==1.0)
	check("replayed capture matches the kept form",saved[3].state_hash==ghost.kept.state_hash and is_equal_approx(saved[3].artifact_state.disorder,0.82))
	check("observer cameras never replace the root camera",root.get_camera_3d()==main_camera)
	# Reconstruct each captured arrangement in a fresh instrument.
	var fresh: Node3D=load("res://commons/artifacts/prefab_disorder/prefab_disorder.tscn").instantiate();root.add_child(fresh);fresh.ghost.auto_enabled=false
	# Let native slider joints finish registering before destroying this fixture.
	# Creating and freeing it before its first physics updates crashed on shutdown.
	for i in 3: await physics_frame;await process_frame
	for pair in saved:
		check(pair.label+": exact fresh-instance replay",fresh.restore(pair.artifact_state) and fresh.ghost.state_hash()==pair.state_hash)
	fresh.queue_free();await process_frame
	# Follow a head rotation and a moved/rotated host without taking over main camera.
	var original:=bench.transform
	bench.position=Vector3(3,0,2);bench.rotation.y=0.7
	rig.set_live(true)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	check("eye view follows head translation and rotation in a moved hall",rig.cameras[0].global_transform.is_equal_approx(ghost.actor.eyes.global_transform))
	check("outside view follows the host's coordinates",rig.cameras[1].global_transform.is_equal_approx(bench.global_transform*rig.outside_pose))
	# A marker fixed to the actual eye anchor must be centred in the rendered image,
	# not merely in the camera metadata (catches queued transform notification lag).
	var marker:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(0.025,0.025);marker.mesh=quad
	var ink:=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color.MAGENTA;marker.material_override=ink
	ghost.actor.eyes.add_child(marker);marker.position=Vector3(0,0,-0.15)
	bench.position+=Vector3(0.5,0,0.8);bench.rotation.y+=0.25
	rig.request_pair(DIR+"calibration","moved-head")
	await process_frame;await RenderingServer.frame_post_draw
	var calibration:=Image.load_from_file(DIR+"calibration/moved-head-eyes.png")
	var centre:=calibration.get_pixel(480,320)
	check("rendered eye camera matches the current head pose, without one-frame lag",centre.r>0.9 and centre.b>0.9 and centre.g<0.1)
	marker.queue_free();await process_frame
	bench.transform=original;rig.set_live(false)
	check("turning comparison off stops extra rendering",rig.views.all(func(v):return v.render_target_update_mode==SubViewport.UPDATE_DISABLED))
	# Manual capture from an idle instrument still carries the actual current state.
	bench.set_disorder(0.61)
	rig.request_pair(DIR+"manual","idle")
	await process_frame;await RenderingServer.frame_post_draw
	check("manual pair saves idle artifact state",pairs.back().status=="saved" and pairs.back().artifact_state.disorder==0.61)
	# A bad destination is reported as failed, never as a successful saved pair.
	rig.request_pair(DIR+"verify.gd/cannot-be-a-folder","write-failure")
	await process_frame;await RenderingServer.frame_post_draw
	check("unwritable destination produces a failed observation",pairs.back().status=="failed" and not pairs.back().errors.is_empty())
	# A visitor arrives before a pending request renders.
	ghost.start();rig.request_pair(DIR+"cancelled","pending")
	ghost.take_over()
	check("handover cancels unrendered request",pairs.back().status=="cancelled" and rig.pending.is_empty() and not ghost.active)
	check("handover retains visitor state",bench.disorder==0.61)
	# Render the real desktop comparison UI for visual inspection.
	ghost.start();ghost.speed=4
	for i in 1000:
		await process_frame
		if ghost.phase=="observe" and ghost.index==3: break
	preview.comparison.show();rig.set_live(true)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+"live-comparison.png")
	ghost.stop("test complete",true)
	var callbacks_before:=RenderingServer.frame_pre_draw.get_connections().size()
	preview.queue_free()
	for i in 4: await process_frame
	check("observer disconnects render callbacks when scene closes",RenderingServer.frame_pre_draw.get_connections().size()<callbacks_before)
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"pairs":saved},"\t",true,true))
	print("HEAD CAMERAS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
