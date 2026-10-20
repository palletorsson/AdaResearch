extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-ghost-head-camera/rehearsal-regression/"
var checks: Array=[]
var failures: Array=[]
var bench: Node3D
var ghost: Node3D
var preview: Node3D
var pointer: Node3D
var screenshots: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title);print("FAIL ",title)
func wait_done(limit: int=1500) -> void:
	for i in limit:
		await process_frame
		if not ghost.active: return
	check("rehearsal finishes within bounded frames",false);ghost.stop("test timeout",true)
func shot(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+title+".png")
func inputs(kind: XRToolsPointerEvent.Type, target: Node3D, at: Vector3) -> void:
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(kind,pointer,target,at,at))
func bytes_at(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "MISSING"
func run() -> void:
	AudioServer.set_bus_mute(0,true)
	root.size=Vector2i(1600,1050)
	preview=load("res://commons/artifacts/prefab_disorder/preview.tscn").instantiate();root.add_child(preview)
	bench=preview.bench;ghost=bench.ghost;ghost.auto_enabled=false;ghost.speed=10
	pointer=Node3D.new();root.add_child(pointer)
	bench.pointer_path="user://ghost-pilot-human-test-latest.json"
	for i in 10: await process_frame
	for node in preview.get_children():
		if node is CanvasLayer: node.visible=false
	var camera: Camera3D=preview.get_node("Camera")
	camera.position=Vector3(4.9,3.5,5.8);camera.look_at(Vector3(0,1.25,0.4));camera.fov=48
	check("two hands with articulated arms",ghost.actor.hands.size()==2 and ghost.actor.arms.size()==2)
	check("ghost has no collision bodies or player groups",ghost.find_children("*","CollisionObject3D",true,false).is_empty() and not ghost.is_in_group("player"))
	bench.set_disorder(0.27);bench.keep()
	var human_path: String=bench.saved_path
	var pointer_before:=bytes_at(bench.pointer_path)
	var gallery_before:=bytes_at(bench.gallery_store.index_path)
	var human_index: String=bench.gallery_store.index_path
	var baseline: String=ghost.state_hash()
	check("start succeeds",ghost.start())
	ghost.step_observed.connect(func(index, _observation):
		if index in [1,3,8]: screenshots["step-"+str(index+1)]=true)
	var hand_shot:=false
	var arm_joints:=true
	for frame in 1800:
		await process_frame
		for arm in ghost.actor.arms:
			arm_joints=arm_joints and (arm.upper.transform*(Vector3.UP*0.5)).is_equal_approx(arm.elbow.position) and (arm.upper.transform*(Vector3.DOWN*0.5)).is_equal_approx(arm.shoulder.position) and (arm.lower.transform*(Vector3.DOWN*0.5)).is_equal_approx(arm.elbow.position)
		if not hand_shot and ghost.phase=="operate" and ghost.index==1:
			hand_shot=true;await shot("slider-contact")
			var saved_camera:=camera.transform
			camera.position=Vector3(0.8,2.0,3.0);camera.look_at(ghost.actor.position+Vector3(0,1.15,-0.35))
			await shot("hands-close");camera.transform=saved_camera
		for name_text in screenshots.keys():
			if screenshots[name_text]: screenshots[name_text]=false;await shot(name_text)
		if not ghost.active: break
	check("all nine actions completed",ghost.report.status=="completed" and ghost.report.steps.size()==9)
	check("every action produced its declared result",ghost.report.steps.all(func(step):return step.passed))
	check("physical slider reaches exact landmark despite coordinate roundoff",ghost.report.steps[1].after.disorder==0.5)
	check("pointer path actually used",ghost.pointer_count>15)
	check("hand tip reaches control contact",ghost.max_contact_error<0.001)
	check("rendered arm segments meet their actual joints",arm_joints)
	check("text excerpts and their source hashes retained",ghost.report.text_refs.size()==3 and ghost.report.text_refs.all(func(ref):return ref.found and ref.unchanged))
	check("complete rehearsal restores original state",ghost.state_hash()==baseline and ghost.report.baseline_restored)
	check("human save pointer unchanged",bytes_at(bench.pointer_path)==pointer_before)
	check("human gallery unchanged",bytes_at(human_index)==gallery_before)
	check("human save and selection unchanged",bench.saved_path==human_path and bench.gallery_selected_path==human_path)
	check("ghost keep in separate gallery",ghost.ghost_store.index_path!=human_index and ghost.ghost_store.paths.size()==1)
	check("receipt written",FileAccess.file_exists(ghost.report_path))
	FileAccess.open(DIR+"rehearsal.json",FileAccess.WRITE).store_string(JSON.stringify(ghost.report,"\t",true,true))
	await shot("complete")
	# Replay the ghost's saved form in a freshly constructed instrument.
	var fresh: Node3D=load("res://commons/artifacts/prefab_disorder/prefab_disorder.tscn").instantiate();root.add_child(fresh);fresh.ghost.auto_enabled=false
	# Let temporary native slider joints finish registering before teardown.
	for i in 3: await physics_frame;await process_frame
	check("ghost record reconstructs in a new scene",fresh.restore(ghost.kept.record))
	check("fresh replay matches kept state",fresh.ghost.state_hash()==ghost.kept.state_hash)
	fresh.queue_free();await process_frame
	# Human takeover releases the ghost slider without resetting the new gesture.
	ghost.start()
	for i in 1200:
		await process_frame
		if ghost.index==1 and ghost.phase=="operate": break
	inputs(XRToolsPointerEvent.Type.PRESSED,bench.slider,bench.slider._slider.global_position)
	check("visitor pointer takes slider ownership immediately",not ghost.active and bench.slider._interaction._pointer==pointer)
	var start: Vector3=bench.slider._slider.global_position
	var endpoint: Vector3=bench.slider._slider.get_parent().to_global(Vector3(0.14,0,0))
	inputs(XRToolsPointerEvent.Type.MOVED,bench.slider,endpoint)
	inputs(XRToolsPointerEvent.Type.RELEASED,bench.slider,endpoint)
	check("visitor movement survives handover",is_equal_approx(bench.disorder,1) and ghost.report.status=="handed to visitor" and not ghost.report.baseline_restored)
	for i in 60: await process_frame
	check("no ghost writes after handover",is_equal_approx(bench.disorder,1) and not ghost.active)
	check("human replay still selects their kept form",bench.replay_saved() and ghost.state_hash()==baseline)
	# STOP restores baseline, unlike takeover.
	ghost.start();await process_frame;ghost.watch()
	check("WATCH while active stops and restores",not ghost.active and ghost.report.status=="stopped" and ghost.state_hash()==baseline)
	# Deliberately break one control connection: the script must catch failure.
	var button: Node3D=bench.buttons["ORIGINAL"]
	var callback:=Callable(bench,"act").bind("ORIGINAL")
	button.pressed.disconnect(callback)
	ghost.start();await wait_done()
	check("disconnected ORIGINAL produces a failed observation",ghost.report.status=="action failed" and not ghost.report.steps[0].passed)
	check("failed run restores visitor state",ghost.state_hash()==baseline)
	button.pressed.connect(callback)
	check("all synthetic presses released",bench.buttons.values().all(func(b):return not b.get_node("InteractableAreaButton").pressed) and bench.slider._interaction._pointer==null)
	var watch_area: Node3D=bench.buttons["WATCH"].get_node("InteractableAreaButton")
	inputs(XRToolsPointerEvent.Type.PRESSED,watch_area,watch_area.global_position)
	inputs(XRToolsPointerEvent.Type.RELEASED,watch_area,watch_area.global_position)
	check("physical WATCH starts a rehearsal",ghost.active)
	ghost.stop("test reset",true)
	var text_ref: Dictionary=ghost.text_refs[0]
	var excerpt: String=text_ref.excerpt
	text_ref.excerpt="INTENTIONAL MISSING TEXT FIXTURE"
	check("changed text blocks an outdated script",not ghost.start() and ghost.report.status=="text needs review")
	check("outdated text does not alter the bench",ghost.state_hash()==baseline)
	text_ref.excerpt=excerpt
	# Gallery is not hijacked and human interactions prevent automatic restart.
	bench.show_gallery(true);check("no rehearsal during gallery viewing",not ghost.start());bench.show_gallery(false)
	check("visitor interaction suppresses automatic restart",ghost.human_has_used)
	ghost.human_has_used=false;ghost.auto_attempted=false;ghost.auto_enabled=true;ghost.idle_time=5.99
	camera.position=Vector3(0,1.75,-3);camera.look_at(Vector3(0,1.2,0))
	for i in 3: await process_frame
	check("no automatic rehearsal from behind the bench",not ghost.active and ghost.idle_time==0)
	camera.position=Vector3(0,1.75,3.5);camera.look_at(Vector3(0,1.2,0));ghost.idle_time=5.99
	for i in 4: await process_frame
	check("watching from the front starts one idle rehearsal",ghost.active and ghost.auto_attempted)
	ghost.stop("test reset",true);ghost.idle_time=10
	for i in 3: await process_frame
	check("automatic rehearsal runs only once per visit",not ghost.active)
	ghost.start()
	for i in 500:
		await process_frame
		if ghost.pressed: break
	var exit_receipt: String=ghost.report_path
	preview.queue_free();pointer.queue_free()
	for i in 8: await process_frame
	var exit_record=JSON.parse_string(bytes_at(exit_receipt))
	check("closing a scene records an interrupted rehearsal",exit_record is Dictionary and exit_record.status=="scene closed")
	print("GHOST PILOT ",checks.size()-failures.size(),"/",checks.size())
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures.is_empty() else 1)
