extends Node
## Two cameras in one World3D. Capture metadata immediately before the same draw.
## No root-camera takeover, duplicate simulation, or per-frame disk recording.
signal captured(receipt: Dictionary)
const SIZE := Vector2i(960,640)
const HEAD_LAYER := preload("hologram.gd").HEAD_LAYER
var bench: Node3D
var actor: Node3D
var views: Array[SubViewport]=[]
var cameras: Array[Camera3D]=[]
var outside_pose:=Transform3D.IDENTITY
var live:=false
var pending: Dictionary={}
var drawing: Dictionary={}
var context: Callable

func setup(host: Node3D, student: Node3D, capture_context: Callable) -> void:
	bench=host;actor=student;context=capture_context
	for i in 2:
		var view:=SubViewport.new();view.name="Eyes" if i==0 else "Outside"
		view.size=SIZE;view.world_3d=host.get_world_3d();view.render_target_update_mode=SubViewport.UPDATE_DISABLED
		add_child(view);views.append(view)
		var camera:=Camera3D.new();view.add_child(camera);camera.current=true
		camera.near=0.025;camera.far=80;camera.fov=78 if i==0 else 83
		camera.cull_mask=0xFFFFF & ~HEAD_LAYER if i==0 else 0xFFFFF
		cameras.append(camera)
	# Inside the prefab hall's approach strip; a distant outside view hits its wall.
	set_outside(Vector3(1.9,2.8,2.2),Vector3(0,1.85,1),100)
	RenderingServer.frame_pre_draw.connect(before_draw)
	RenderingServer.frame_post_draw.connect(after_draw)

func set_outside(eye: Vector3, target: Vector3, fov: float) -> void:
	outside_pose=Transform3D(Basis(),eye).looking_at(target)
	cameras[1].fov=fov

func set_live(enabled: bool) -> void:
	live=enabled
	if not live and pending.is_empty() and drawing.is_empty():
		for view in views: view.render_target_update_mode=SubViewport.UPDATE_DISABLED

func request_pair(folder: String, label: String) -> bool:
	if not pending.is_empty() or not drawing.is_empty(): return false
	if DisplayServer.get_name()=="headless":
		captured.emit({"folder":folder,"label":label,"status":"unavailable","reason":"Rendering is disabled in headless mode."});return false
	pending={"folder":folder,"label":label};return true

func cancel(reason: String) -> void:
	if not pending.is_empty():
		var cancelled:=pending.duplicate();pending.clear()
		cancelled.status="cancelled";cancelled.reason=reason;captured.emit(cancelled)

func before_draw() -> void:
	if not live and pending.is_empty(): return
	cameras[0].global_transform=actor.eyes.global_transform.orthonormalized()
	cameras[1].global_transform=(bench.global_transform*outside_pose).orthonormalized()
	# Node3D queues transform notifications. Flush these before this draw; otherwise
	# the first image is from the origin and later captures lag by one observation.
	for camera in cameras: camera.force_update_transform()
	for view in views: view.render_target_update_mode=SubViewport.UPDATE_ONCE
	if pending.is_empty(): return
	drawing=pending.duplicate();pending.clear()
	drawing.merge(context.call())
	drawing.schema="ghost-view-pair/1"
	drawing.status="rendering"
	drawing.captured_utc=Time.get_datetime_string_from_system(true)
	drawing.process_frame=Engine.get_process_frames()
	drawing.render_frame=Engine.get_frames_drawn()
	drawing.bench_world=pack(bench.global_transform)
	drawing.head={"world":pack(actor.head.global_transform),"bench":pack(bench.global_transform.affine_inverse()*actor.head.global_transform),"local":pack(actor.head.transform)}
	drawing.actor={"bench":pack(bench.global_transform.affine_inverse()*actor.global_transform),"hands_local":[xyz(actor.hands[0].position),xyz(actor.hands[1].position)],"shader_time_note":"Hologram scanlines use engine TIME; poses and artifact geometry are replayable, pixel-identical animation is not promised."}
	drawing.cameras=[]
	for camera in cameras:
		drawing.cameras.append({"world":pack(camera.global_transform),"bench":pack(bench.global_transform.affine_inverse()*camera.global_transform),"vertical_fov_degrees":camera.fov,"near":camera.near,"far":camera.far,"size":[SIZE.x,SIZE.y],"projection":"monoscopic perspective, KEEP_HEIGHT","cull_mask":camera.cull_mask})
	drawing.eye_offset=pack(actor.eyes.transform)

func after_draw() -> void:
	if drawing.is_empty(): return
	var receipt:=drawing;drawing={}
	receipt.completed_render_frame=Engine.get_frames_drawn()
	receipt.same_process_frame=receipt.process_frame==Engine.get_process_frames()
	receipt.files={};receipt.errors=[]
	var folder: String=receipt.folder
	var err:=prepare_folder(folder)
	if err!=OK: receipt.errors.append("Cannot create observation folder: "+error_string(err))
	if not receipt.same_process_frame: receipt.errors.append("State and images crossed a process frame.")
	if receipt.errors.is_empty():
		for i in 2:
			var name_text: String=receipt.label+("-eyes.png" if i==0 else "-outside.png")
			var picture:=views[i].get_texture().get_image()
			if picture==null or picture.is_empty(): receipt.errors.append("Empty viewport image: "+name_text);continue
			err=picture.save_png(folder+"/"+name_text)
			if err!=OK: receipt.errors.append("Cannot save "+name_text+": "+error_string(err));continue
			receipt.files["eyes" if i==0 else "outside"]={"name":name_text,"sha256":FileAccess.get_sha256(folder+"/"+name_text)}
	receipt.status="saved" if receipt.errors.is_empty() and receipt.files.size()==2 else "failed"
	receipt.record=folder+"/"+receipt.label+".json"
	var file:=FileAccess.open(receipt.record,FileAccess.WRITE)
	if file==null:
		receipt.status="failed";receipt.errors.append("Cannot save paired observation record.")
	else:
		file.store_string(JSON.stringify(receipt,"\t",true,true));file.close()
	captured.emit(receipt)

func prepare_folder(folder: String) -> Error:
	# Detect a file in the path without producing an engine error for a recoverable
	# capture failure. Preserve that file and report the failure to the caller.
	var cursor:=ProjectSettings.globalize_path(folder)
	while not cursor.is_empty() and not DirAccess.dir_exists_absolute(cursor):
		if FileAccess.file_exists(cursor): return ERR_ALREADY_EXISTS
		var parent:=cursor.get_base_dir()
		if parent==cursor: break
		cursor=parent
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))

static func xyz(p: Vector3) -> Array: return [p.x,p.y,p.z]
static func pack(t: Transform3D) -> Array:
	return xyz(t.basis.x)+xyz(t.basis.y)+xyz(t.basis.z)+xyz(t.origin)

func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(before_draw): RenderingServer.frame_pre_draw.disconnect(before_draw)
	if RenderingServer.frame_post_draw.is_connected(after_draw): RenderingServer.frame_post_draw.disconnect(after_draw)
	for view in views:
		view.render_target_update_mode=SubViewport.UPDATE_DISABLED
		view.world_3d=null
