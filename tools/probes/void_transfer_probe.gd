extends "res://tools/probes/void_trial_probe.gd"
## Shared transfer acceptance. Collections override only their focused interactions.
var trial := ""
var level := 1
var measured: Array = []
var fit_notes: Array = []
var debug_focus := ""
var debug_mode := "both"

## Narrow placement probes disclose their actual coverage in the receipt.
func receipt_scope() -> Dictionary:
	return {}

## Override to expose short diagnostic cases: case name -> required floor.
## Diagnostics never replace the full acceptance run or its receipts.
func debug_cases() -> Dictionary:
	return {}

func run_debug_case(_name: String, _tag: String) -> void:
	check("diagnostic case implemented", false)

## Re-aim through process/physics settling; live mouse motion may change the camera.
func input_aim_camera(at: Vector3, count: int = 15) -> void:
	for i in count:
		game.camera.look_at(at);await frames(1)
	game.camera.look_at(at)

## Put the actual palm at a world position, compensating for the aim/grip offset.
func input_palm_at(world: Vector3) -> void:
	var aim: Vector3 = world
	for i in 20:
		hand_at(right, aim);await frames(1)
		aim += world - game.pickups[1].global_position

## Inspect the native grab contract without changing layers or forcing pickup.
func input_grab_preflight(body: Node3D, shape: CollisionShape3D) -> Dictionary:
	var mask: int = int(game.pickups[1].grab_collision_mask) if xr else 393220
	var reasons: Array = []
	if not body.has_method("pick_up") or not body.has_method("is_picked_up"):
		reasons.append("body is not a supported pickable")
	if not body is CollisionObject3D or (body.collision_layer & mask) == 0:
		reasons.append("body is outside the active grab mask")
	if shape == null or shape.shape == null or shape.disabled:
		reasons.append("missing or disabled collision shape")
	return {"passed":reasons.is_empty(), "reasons":reasons, "mask":mask,
		"layer":body.collision_layer if body is CollisionObject3D else 0}

## Real mouse/grip pickup of the named body; nearby bodies do not count as success.
## For small bodies, lift clear, cross above the display, then stop within grab
## radius above the live collider. Entering the body can push it away before grip.
## Pass the actual collider; its centre may differ from the wrapper origin.
func input_grab(tag: String, body: Node3D, shape: CollisionShape3D, lift: float = .5, hover: float = .2) -> bool:
	var preflight: Dictionary = input_grab_preflight(body, shape)
	print("INPUT_GRAB_PREFLIGHT ", tag, " ", body.get_path(), " ", preflight)
	check(tag+"grab preflight", preflight.passed)
	if not preflight.passed:return false
	var at: Vector3 = shape.global_position
	var start: Vector3 = body.global_position
	if xr:
		await input_palm_at(game.pickups[1].global_position+Vector3.UP*lift)
		await input_palm_at(at+Vector3.UP*lift)
		at=shape.global_position+Vector3.UP*hover
		await input_palm_at(at)
		var pickup: Node3D = game.pickups[1]
		print("INPUT_GRAB_XR palm_error=",pickup.global_position.distance_to(at),
			" body_moved=",body.global_position.distance_to(start),
			" closest=",str(pickup.closest_object.get_path()) if is_instance_valid(pickup.closest_object) else "none")
		right.set_input("grip",1.0);await frames(18)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		await input_aim_camera(at)
		var cam: Camera3D = game.camera
		var found: Node3D = game.body.desktop_pointer._find_grabbable()
		print("INPUT_GRAB_DESKTOP angle_error=",rad_to_deg((-cam.global_basis.z).angle_to(at-cam.global_position)),
			" hit=",str(found.get_path()) if found!=null else "none")
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=down
			Input.parse_input_event(event);await frames(10)
	var held: bool = body.is_picked_up()
	check(tag+"real "+("grip" if xr else "mouse")+" picks up intended body",held)
	return held

## Aim an already-held tool's tip. Does not teleport the tool or call its action.
## Desktop uses camera aim and the native hold-distance setting; XR moves its tracker.
func input_tip_to(tip: Node3D, world: Vector3) -> void:
	var aim: Vector3 = world
	if xr:
		for i in 24:
			hand_at(right,aim);await frames(1)
			aim+=world-tip.global_position
		await frames(4)
		return
	var cam: Camera3D = game.camera
	var hand: Node3D = game.body.desktop_pointer
	var v: Vector3 = cam.global_transform.affine_inverse()*tip.global_position-hand.grip.position
	var eye: Vector3 = cam.global_position
	var to: Vector3 = world-eye
	var lateral: float = v.x*v.x+v.y*v.y
	if to.length_squared()<=lateral:
		check("held tool target is reachable from camera",false)
		print("INPUT_TIP unreachable lateral=",sqrt(lateral)," range=",to.length())
		return
	var d: float = v.z+sqrt(to.length_squared()-lateral)
	if d<=0:
		check("held tool target is in front of grip",false);return
	var p:=Vector3(v.x,v.y,v.z-d)
	var f: Vector3 = to.normalized()
	for k in 40:
		var got: Vector3 = Basis.looking_at(f,Vector3.UP)*p
		f=(Quaternion(got.normalized(),to.normalized())*f).normalized()
	for i in 24:
		cam.look_at(eye+f);hand._hold_distance=d;await frames(1)
	print("INPUT_TIP error=",tip.global_position.distance_to(world)," hold=",d," lateral=",sqrt(lateral))

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/%s/trial.tscn"%trial).instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func station(id: String) -> Node3D:
	return game.building.content.exhibits[str(level)+"/"+id].get_node("Artifact")

func artifact(key: String) -> Node3D:
	for entry in game.building.content.data.floors[level].artifacts:
		if entry.artifact==key:return station(entry.id)
	return null

func geometry(node: Node, boxes: Array) -> void:
	if node is SubViewport:return
	if node is SoftBody3D:
		var rid: RID = node.get_physics_rid()
		if node.is_visible_in_tree() and rid.is_valid() and PhysicsServer3D.soft_body_get_space(rid).is_valid():
			# Soft-body render vertices live in world space; the original CPU
			# mesh AABB and reset node transform do not describe the live cloth.
			boxes.append(PhysicsServer3D.soft_body_get_bounds(rid))
	elif node is CSGShape3D:
		if node.is_root_shape() and node.is_visible_in_tree():boxes.append(node.global_transform*node.get_aabb())
	elif node is MeshInstance3D and node.mesh!=null and node.is_visible_in_tree() and node.layers!=0:
		boxes.append(node.global_transform*node.get_aabb())
	elif node is Sprite3D and node.texture!=null and node.is_visible_in_tree() and node.layers!=0:
		boxes.append(node.global_transform*node.get_aabb())
	elif node is MultiMeshInstance3D and node.multimesh!=null and node.is_visible_in_tree():
		boxes.append(node.global_transform*node.get_aabb())
	for child in node.get_children():geometry(child,boxes)

func inspect_floor(tag: String) -> void:
	var floor_y:float=game.building.spec.levels[level]
	var top:float=game.building.spec.levels[level-1]-game.building.spec.slab_thickness
	for entry in game.building.content.data.floors[level].artifacts:
		var node:Node3D=station(entry.id)
		var boxes:Array=[];geometry(node,boxes)
		if expected_empty_source(node):
			check(tag+entry.id+" preserves unconfigured source (no geometry)",boxes.is_empty())
		else:
			check(tag+entry.id+" original geometry",not boxes.is_empty())
		check(tag+entry.id+" source config reaches node",entry.config.keys().all(func(k):return str(node.get_meta("config_"+k,""))==str(entry.config[k])))
		if boxes.is_empty():continue
		var bounds:AABB=boxes[0]
		for box in boxes:bounds=bounds.merge(box)
		if not xr:
			measured.append({"id":entry.id,"floor":level,"min":[bounds.position.x,bounds.position.y,bounds.position.z],"max":[bounds.end.x,bounds.end.y,bounds.end.z]})
			if bounds.position.y<floor_y-.08 or bounds.end.y>top+.08:
				fit_notes.append({"id":entry.id,"slab_bottom":floor_y,"ceiling":top,"geometry_bottom":bounds.position.y,"geometry_top":bounds.end.y})
	for shaft in game.building.spec.shafts:
		var x:float=shaft.x
		check(tag+"open shaft "+str(shaft.name),ray(Vector3(x,floor_y+1,0),Vector3(x,floor_y-.5,0)).is_empty())
	check(tag+"visitor camera remains active",game.get_viewport().get_camera_3d()==game.camera)
	if game.get_viewport().get_camera_3d()!=game.camera:
		print("TRANSFER_CAMERA ",game.get_viewport().get_camera_3d().get_path() if game.get_viewport().get_camera_3d()!=null else "none")

func expected_empty_source(_node: Node3D) -> bool:
	return false

func approach(node: Node3D, distance := 2.4) -> void:
	var at:Vector3=node.to_global(Vector3(0,0,distance))
	at.y=game.building.spec.levels[level]+.06
	game.place_player(at);await frames(20)

func press(button: Node3D) -> void:
	var target:Vector3=button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	if not xr:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		for frame in 25:
			game.camera.look_at(target);await frames(1)
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
		Input.parse_input_event(event);await frames(6)
		event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
		Input.parse_input_event(event);await frames(8)
		return
	var origin:Node3D=game.get_node("XROrigin3D")
	var pointer:Node3D=game.pointers[1]
	for frame in 20:
		var at:Vector3=game.camera.global_position+Vector3(.1,-.2,0)
		var aim:=Basis.looking_at(target-at)
		at-=aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(1)
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(8)

func focused_checks(_tag: String) -> void:
	await frames(1)

func capture_floor() -> void:
	await photo("%02d-floor-overview"%(level*2-1),Vector3(8,-6*level+4,12),Vector3(0,-6*level+1,-3))

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var before:Vector3=game.body.global_position
	game.place_player(game.spawn_for(level));await frames(4)
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	var body_visual:Node3D=game.get_node_or_null("CareBody")
	var body_visible:bool=body_visual.visible if body_visual!=null else false
	if body_visual!=null:body_visual.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	if body_visual!=null:body_visual.visible=body_visible
	origin.show()
	game.place_player(before);await frames(4)

func visit(use_xr: bool) -> void:
	level=1;await start(use_xr)
	var tag:="XR: " if xr else "Desktop: "
	check(tag+"safe arrival",game.checkpoint==1 and game.body.is_on_floor())
	var last: int=game.building.content.data.floors.size()-2
	for next_level in range(1,last+1):
		level=next_level
		inspect_floor(tag);await focused_checks(tag)
		if not xr:await capture_floor()
		if level==last:break
		var upper:Node3D=station(game.building.content.data.floors[level].artifacts[0].id)
		var landing_z:float=1.9 if (level+1)%2==1 else -1.9
		game.place_player(Vector3(-8.3,game.building.spec.levels[level]+.06,landing_z));await frames(145)
		check(tag+"shaft pad reaches floor "+str(level+1),game.checkpoint==level+1 and game.body.is_on_floor())
		check(tag+"inactive collection sleeps "+str(level),not is_instance_valid(upper) or not upper.can_process())
	game.place_player(game.spawn_for(1));await frames(40)
	level=1
	var returned:Node3D=station(game.building.content.data.floors[1].artifacts[0].id)
	check(tag+"return resumes collection",returned.can_process() and game.checkpoint==1)
	game.place_player(game.spawn_for(last));await frames(30)
	game.die("Transfer retry");await frames(145)
	if game.checkpoint!=last or game.recovering:
		print("TRANSFER_RETRY floor=",last," checkpoint=",game.checkpoint," feet=",game.body.global_position," recovering=",game.recovering," reason=",game.last_death)
	check(tag+"retry returns to last floor",game.checkpoint==last and not game.recovering)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

func run() -> void:
	trial=get_script().resource_path.split("/")[-2]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
		if arg.begins_with("--focus="):debug_focus=arg.trim_prefix("--focus=")
		if arg.begins_with("--mode="):debug_mode=arg.trim_prefix("--mode=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	var acceptance: bool = debug_focus.is_empty() and debug_mode=="both"
	if acceptance:
		for use_xr in [false,true]:await visit(use_xr)
	else:
		var cases: Dictionary = debug_cases()
		check("known diagnostic case and input mode",cases.has(debug_focus) and debug_mode in ["desktop","xr","both"])
		if checks.back().passed:
			for use_xr in [false,true]:
				if debug_mode=="desktop" and use_xr:continue
				if debug_mode=="xr" and not use_xr:continue
				level=int(cases[debug_focus]);await start(use_xr)
				check("diagnostic floor exists",level>0 and level<game.building.content.data.floors.size()-1)
				if checks.back().passed:
					game.place_player(game.spawn_for(level));await frames(45)
					await run_debug_case(debug_focus,"XR: " if xr else "Desktop: ")
				game.queue_free();await frames(10)
				if xr:
					for item in [head,left,right]:XRServer.remove_tracker(item)
	var scope:="Shared native transfer acceptance: every placement, source config, shaft clearance, residency and retry, plus named focused checks. Mouse and synthetic tracked XR input; slider/API assertions are labelled separately. Not exhaustive interaction testing. Physical headset and curation pending."
	if not acceptance:scope="Diagnostic only: %s (%s). Does not establish floor, residency, retry or full acceptance."%[debug_focus,debug_mode]
	var receipt := {"passed":failed.is_empty(),"acceptance":acceptance,"focus":debug_focus,"mode":debug_mode,"checks":checks,"failed":failed,"fit_notes":fit_notes,"scope":scope}
	receipt.merge(receipt_scope(), true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	FileAccess.open(out.path_join("measured-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(measured,"\t"))
	print("TRANSFER_RESULT ",trial," ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)
