extends Node
## Model B's developer exploration brain: embodied execution and evidence memory.
## Reasoning is supplied by a connected assistant, not a hidden route or a trained
## policy in this script. This first pilot pauses physics between decisions.
signal closed(reason: String)

const VERSION := 1
const ACTION_KEYS := ["forward", "strafe", "yaw_degrees", "pitch_degrees", "jump", "seconds"]
var game: Node3D
var directory := ""
var session_id := ""
var goal := {"instruction":"Explore this space and look for a route to the next floor.","target_checkpoint":-1}
var memory: Array[Dictionary] = []
var mode := "starting"
var observation_id := ""
var idle_seconds := 180.0
var _observations: Dictionary = {}
var _index := 0
var _busy := false
var _consumed := false
var _token := 0
var _last_request := 0
var _last_poll := 0
var _original_scripted := false
var _original_input := true
var _original_pause := false
var _original_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _paused_nodes: Array[Dictionary] = []
var _last_outcome: Dictionary = {}

func configure(world: Node3D, path: String, timeout_seconds := 180.0) -> void:
	game=world;directory=path;idle_seconds=timeout_seconds
	process_mode=Node.PROCESS_MODE_ALWAYS
	session_id=Crypto.new().generate_random_bytes(16).hex_encode()
	for folder in ["inbox","outbox","observations","audit"]:
		DirAccess.make_dir_recursive_absolute(directory.path_join(folder))
	_original_scripted=game.body.scripted_input
	_original_input=game.body.is_processing_unhandled_input()
	_original_pause=get_tree().paused
	_original_mouse_mode=Input.mouse_mode
	goal.target_checkpoint=game.checkpoint+1
	_last_request=Time.get_ticks_msec()
	_take_control();_pause_world();_state()
	_initial_observation.call_deferred()

func _initial_observation() -> void:
	_busy=true
	await _observe()
	_busy=false;mode="awaiting_decision";_state()
	print("MODEL_B_READY ",directory)

func _process(_delta: float) -> void:
	if game==null or mode=="closed":return
	var now := Time.get_ticks_msec()
	if now-_last_request>idle_seconds*1000:
		_handover();mode="closed";_state();closed.emit("idle_timeout");return
	if now-_last_poll<40:return
	_last_poll=now
	var inbox := directory.path_join("inbox")
	var files := DirAccess.get_files_at(inbox)
	files.sort()
	for filename in files:
		if not filename.ends_with(".json"):continue
		var file := inbox.path_join(filename)
		var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(file))
		DirAccess.remove_absolute(file)
		if not value is Dictionary:continue
		_handle(value)

func _handle(request: Dictionary) -> void:
	var id := str(request.get("id",""))
	if id.is_empty() or id.length()>80 or not id.is_valid_identifier():return
	_last_request=Time.get_ticks_msec()
	if request.get("session_id","")!=session_id:
		_respond(id,_error("wrong_session"));return
	var op := str(request.get("op",""))
	if op in ["stop","close"]:
		_handover()
		if op=="close":mode="closed"
		_state();_respond(id,{"ok":true,"mode":mode,"control_released":true})
		if op=="close":closed.emit.call_deferred("requested")
		return
	if _busy:
		_respond(id,_error("busy"));return
	_busy=true
	var result: Dictionary=await _dispatch(request)
	_busy=false;_state();_respond(id,result)

func _dispatch(request: Dictionary) -> Dictionary:
	match str(request.get("op","")):
		"observe":
			return {"ok":true,"observation":await _observe()}
		"act":
			return await _act(request)
		"resume":
			_take_control();_pause_world();mode="awaiting_decision"
			return {"ok":true,"observation":await _observe()}
		"goal":
			var instruction := str(request.get("instruction","")).strip_edges()
			if instruction.is_empty() or instruction.length()>2000:return _error("invalid_goal")
			var updated := goal.duplicate(true)
			updated.instruction=instruction
			if request.has("target_checkpoint"):
				var target: Variant=request.target_checkpoint
				if not _number(target) or target!=int(target) or target<0 or target>=game.building.spec.levels.size():return _error("invalid_target_checkpoint")
				updated.target_checkpoint=int(target)
			goal=updated
			_log({"type":"goal","goal":goal.duplicate(true)})
			return {"ok":true,"goal":goal}
		"remember":
			var kind := str(request.get("kind","hypothesis"))
			var claim := str(request.get("text","")).strip_edges()
			var evidence: Variant=request.get("evidence",[])
			if kind not in ["hypothesis","interpretation","attention"] or claim.is_empty() or claim.length()>2000:return _error("invalid_memory")
			if not evidence is Array or evidence.is_empty():return _error("evidence_required")
			for id in evidence:
				if not _observations.has(str(id)):return _error("unknown_evidence")
			var note := {"kind":kind,"text":claim,"evidence":evidence.duplicate()}
			_remember(note);return {"ok":true,"memory":note}
		"audit":
			_log({"type":"privileged_audit_requested","observation_id":observation_id})
			return {"ok":true,"privileged":true,"audit":_audit()}
	return _error("unknown_operation")

func _act(request: Dictionary) -> Dictionary:
	if mode=="handed_over":return _error("human_has_control")
	if str(request.get("observation_id",""))!=observation_id or _consumed:return _error("stale_observation")
	var action: Variant=request.get("action",{})
	if not action is Dictionary:return _error("invalid_action")
	for key in action:
		if key not in ACTION_KEYS:return _error("unknown_action_field")
	for key in ["forward","strafe","yaw_degrees","pitch_degrees","seconds"]:
		if action.has(key) and not _number(action[key]):return _error("invalid_number")
	if action.has("jump") and not action.jump is bool:return _error("invalid_jump")
	var forward := float(action.get("forward",0))
	var strafe := float(action.get("strafe",0))
	var yaw := float(action.get("yaw_degrees",0))
	var pitch := float(action.get("pitch_degrees",0))
	var seconds := float(action.get("seconds",.2))
	var leap := bool(action.get("jump",false))
	if absf(forward)>1 or absf(strafe)>1 or absf(yaw)>90 or absf(pitch)>45 or seconds<.05 or seconds>1.5:return _error("action_out_of_range")
	var drive := Vector2(strafe,-forward).limit_length()
	if game.recovering and (drive.length()>.01 or leap):return _error("body_recovering")
	if game.charge.get_charge()<=10 and (drive.length()>.01 or leap):return _error("low_charge_needs_attention")
	if leap and not game.body.is_on_floor():return _error("jump_requires_support")
	var reason := str(request.get("reason","")).strip_edges()
	if reason.is_empty() or reason.length()>2000:return _error("reason_required")
	var before := observation_id
	var position_before: Vector3=game.body.global_position
	var charge_before: float=game.charge.get_charge()
	var deaths_before: int=game.deaths
	_token+=1;var token := _token
	_consumed=true;mode="acting"
	_resume_world()
	_state()
	game.body.rotate_y(deg_to_rad(-yaw))
	game.camera.rotation.x=clampf(game.camera.rotation.x+deg_to_rad(pitch),-1.45,1.45)
	game.body.drive=drive;game.body.jump_queued=leap
	var bumped := false
	for i in maxi(1,ceili(seconds*Engine.physics_ticks_per_second)):
		await get_tree().physics_frame
		if token!=_token:return _error("interrupted_by_handover")
		for c in game.body.get_slide_collision_count():
			if absf(game.body.get_slide_collision(c).get_normal().y)<.65:bumped=true
		if game.recovering:break
	_stop_motion()
	for i in 8:
		await get_tree().physics_frame
		if token!=_token:return _error("interrupted_by_handover")
	_pause_world();mode="awaiting_decision"
	var distance: float=Vector2(game.body.global_position.x-position_before.x,game.body.global_position.z-position_before.z).length()
	_last_outcome={"moved_metres":distance,"bumped":bumped,"blocked":drive.length()>.1 and seconds>=.3 and distance<.08,
		"charge_used":charge_before-game.charge.get_charge(),"deaths":game.deaths-deaths_before}
	var observation := await _observe()
	_log({"type":"action","before":before,"after":observation.id,"action":action.duplicate(true),"reason":reason,"outcome":_last_outcome.duplicate(true)})
	_remember({"kind":"observed_outcome","text":_last_outcome.duplicate(true),"evidence":[before,observation.id]})
	observation.memory=memory.duplicate(true)
	_write(directory.path_join("observations/"+observation.id+".json"),observation)
	_write(directory.path_join("latest.json"),observation)
	return {"ok":true,"outcome":_last_outcome.duplicate(true),"observation":observation}

func _observe() -> Dictionary:
	_index+=1;observation_id="obs_%04d"%_index
	var id := observation_id
	var relative := "observations/"+id+".png"
	await RenderingServer.frame_post_draw
	var texture := game.get_viewport().get_texture()
	var image_ok := texture!=null
	if image_ok:image_ok=texture.get_image().save_png(directory.path_join(relative))==OK
	var observation := {"id":id,"image":relative if image_ok else "","image_available":image_ok,
		"identity":"Care Unit / Model B","role":"exploratory_playtester","reasoning_provider":"external_assistant",
		"simulation":"paused_between_decisions" if mode!="handed_over" else "human_control",
		"goal":goal.duplicate(true),"checkpoint_target_reached":game.checkpoint==goal.target_checkpoint and not game.recovering,
		"semantic_goal_completion":"not_assessed",
		"body":{"charge":game.charge.get_charge(),"grounded":game.body.is_on_floor(),"speed":game.body.velocity.length(),
			"checkpoint":game.checkpoint,"recovering":game.recovering,"deaths":game.deaths,
			"heading_degrees":rad_to_deg(-game.body.rotation.y),"pitch_degrees":rad_to_deg(game.camera.rotation.x)},
		"last_outcome":_last_outcome.duplicate(true),"memory":memory.duplicate(true),
		"limits":["No hidden route or floor inventory in perception.","Claims are hypotheses or interpretations, not automatic facts.","Frame-by-frame physics stays in Godot; this is a turn-based developer pilot."]}
	_observations[id]=true;_consumed=false
	_write(directory.path_join("observations/"+id+".json"),observation)
	_write(directory.path_join("audit/"+id+".json"),_audit())
	_write(directory.path_join("latest.json"),observation)
	_log({"type":"observation","id":id,"image":observation.image,"body":observation.body})
	_state();return observation

func _audit() -> Dictionary:
	var p: Vector3=game.body.global_position
	var contacts: Array=[]
	for i in game.body.get_slide_collision_count():
		var c: KinematicCollision3D=game.body.get_slide_collision(i)
		contacts.append({"collider":str(c.get_collider().get_path()),"normal":[c.get_normal().x,c.get_normal().y,c.get_normal().z]})
	return {"privileged":true,"position":[p.x,p.y,p.z],"contacts":contacts,"note":"Engine diagnostics; not Model B's visual knowledge. No route graph or editor mutation commands."}

func _take_control() -> void:
	game.body.scripted_input=true
	game.body.set_process_unhandled_input(false)
	_stop_motion();mode="awaiting_decision"
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _stop_motion() -> void:
	game.body.drive=Vector2.ZERO;game.body.jump_queued=false

func _pause_world() -> void:
	# Imported mounts intentionally use ALWAYS while loading. Make them obey
	# this isolated developer session's pause, restoring their modes on each step.
	for node in game.find_children("*","",true,false):
		if node==self:continue
		if node.process_mode in [Node.PROCESS_MODE_ALWAYS,Node.PROCESS_MODE_WHEN_PAUSED]:
			_paused_nodes.append({"node":weakref(node),"mode":node.process_mode})
			node.process_mode=Node.PROCESS_MODE_INHERIT
	get_tree().paused=true

func _resume_world() -> void:
	for entry in _paused_nodes:
		var node: Node=entry.node.get_ref()
		if is_instance_valid(node):node.process_mode=entry.mode
	_paused_nodes.clear();get_tree().paused=false

func _handover() -> void:
	_token+=1;_stop_motion();_resume_world()
	game.body.scripted_input=_original_scripted
	game.body.set_process_unhandled_input(_original_input)
	Input.mouse_mode=_original_mouse_mode
	get_tree().paused=_original_pause
	mode="handed_over"
	_log({"type":"handover","control_released":true})

func _remember(note: Dictionary) -> void:
	memory.append(note)
	while memory.size()>24:memory.pop_front()
	_write(directory.path_join("memory.json"),{"goal":goal,"entries":memory})
	_log({"type":"memory","entry":note})

func _state() -> void:
	_write(directory.path_join("session.json"),{"version":VERSION,"session_id":session_id,"mode":mode,"observation_id":observation_id,
		"pid":OS.get_process_id(),"goal":goal,"controlled":game.body.scripted_input,
		"drive":[game.body.drive.x,game.body.drive.y],"input_processing":game.body.is_processing_unhandled_input(),
		"mouse_mode":Input.mouse_mode,"simulation_paused":get_tree().paused,
		"reasoning_provider":"external_assistant","idle_seconds":idle_seconds})

func _respond(id: String, result: Dictionary) -> void:
	result=result.duplicate(true);result.id=id;result.session_id=session_id
	_write(directory.path_join("outbox/"+id+".json"),result)

func _error(code: String) -> Dictionary:
	return {"ok":false,"error":code,"mode":mode}

func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func _write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:push_error("Model B cannot write "+path);return
	file.store_string(JSON.stringify(value,"  "));file.close()
	var error := DirAccess.rename_absolute(path+".tmp",path)
	if error!=OK:push_error("Model B cannot publish "+path+": "+error_string(error))

func _log(event: Dictionary) -> void:
	event=event.duplicate(true);event.unix_time=Time.get_unix_time_from_system()
	var path := directory.path_join("events.jsonl")
	var file := FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file!=null:file.seek_end();file.store_line(JSON.stringify(event));file.close()

func _exit_tree() -> void:
	if is_instance_valid(game) and is_instance_valid(game.body):
		_stop_motion();_resume_world()
		game.body.scripted_input=_original_scripted
		game.body.set_process_unhandled_input(_original_input)
		Input.mouse_mode=_original_mouse_mode
		get_tree().paused=_original_pause
