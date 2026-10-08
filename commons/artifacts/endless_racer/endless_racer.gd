extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Museum boarding bay + a bounded, scrolling arcade road in the same World3D.
## Physical head tracking remains live. Only the road moves; no imposed head roll.
const MODEL=preload("res://commons/artifacts/endless_racer/race_model.gd")
const ROAD=preload("res://commons/artifacts/endless_racer/road.gd")
const GRIP=preload("res://commons/artifacts/endless_racer/wheel_grip.gd")
const SEAT=preload("res://commons/artifacts/endless_racer/seat_provider.gd")
var model=MODEL.new()
var rider: CharacterBody3D
var return_pose:=Transform3D.IDENTITY
var museum: Node
var return_look:=Vector2.ZERO
var arena: Node3D
var road: Node3D
var car: Node3D
var wheel: Node3D
var wheel_frame: Node3D
var hud: Label3D
var grips: Array=[]
var grip_states: Dictionary={}
var controllers: Array[XRController3D]=[]
var seat_adapter: Node
var wheel_angle:=0.0
var best:=0.0
var countdown:=0.0
var event_time:=0.0
var last_crashes:=0
var last_cubes:=0
var cue: Label3D
var stage_label: Label3D
var saved_camera: Camera3D
var saved_camera_position:=Vector3.ZERO

func _ready() -> void:
	set_meta("em_keep_scale",true)
	add_to_group("ada_museum_carry")
	box(Vector3(0,0.025,0.3),Vector3(5.6,0.05,5.2),material("172331"))
	var preview=Node3D.new();add_child(preview);build_car(preview,false)
	stage_label=label("ENDLESS DRIVE",Vector3(0,2.7,-1.3),0.004)
	label("A road with no last room",Vector3(0,2.32,-1.3),0.0018)
	var b=make_button(self,Vector3(1.65,1.0,1.65),"DRIVE",board_nearest)
	box(b.position-Vector3.UP*0.50,Vector3(0.18,0.92,0.18),material("edf0df"),true)
	label("GRIP THE WHEEL · RIGHT TRIGGER: GO\nLEFT TRIGGER: BRAKE\nDesktop: W / S · A / D",Vector3(0,1.75,1.65),0.00105)
	var bay_light=OmniLight3D.new();bay_light.position=Vector3(0,2.8,1);bay_light.omni_range=5;bay_light.light_energy=1.6;add_child(bay_light)

func make_button(host: Node3D,at: Vector3,title: String,callback: Callable) -> Node3D:
	var button=PUSH.instantiate();button.position=at;host.add_child(button);button.pressed.connect(callback)
	var caption=Label3D.new();caption.text=title;caption.font_size=36;caption.pixel_size=0.0008
	caption.position=at+Vector3(0,0.13,0.07);host.add_child(caption)
	return button

func rod(host: Node3D,a: Vector3,b: Vector3,radius: float,mat: Material) -> MeshInstance3D:
	var node=MeshInstance3D.new();var mesh=CylinderMesh.new()
	mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=12
	node.mesh=mesh;node.material_override=mat;host.add_child(node)
	node.position=(a+b)*0.5;node.basis=Basis(Quaternion(Vector3.UP,(b-a).normalized()));return node

func build_car(host: Node3D,interactive: bool) -> void:
	var dark=material("171c27");var pink=material("e976ac");var cream=material("e6e4d9");var glow=material("7beddc",true)
	box(Vector3(0,0.27,-0.35),Vector3(1.60,0.25,2.7),dark,false,host)
	box(Vector3(0,0.68,-1.15),Vector3(1.6,0.48,1.03),pink,false,host)
	box(Vector3(0,0.95,-0.92),Vector3(1.5,0.08,0.43),dark,false,host)
	for x in [-0.74,0.74]:box(Vector3(x,0.53,0.10),Vector3(0.18,0.40,1.7),pink,false,host)
	box(Vector3(0,0.52,0.26),Vector3(0.7,0.12,0.60),cream,false,host)
	box(Vector3(0,0.85,0.55),Vector3(0.70,0.75,0.12),cream,false,host)
	for x in [-0.9,0.9]:
		for z in [-1.15,0.60]:
			rod(host,Vector3(x-0.13,0.30,z),Vector3(x+0.13,0.30,z),0.30,dark)
	for x in [-0.6,0.6]:box(Vector3(x,0.70,-1.69),Vector3(0.25,0.06,0.025),glow,false,host)
	var frame=Node3D.new();host.add_child(frame);frame.position=Vector3(0,0.93,-0.62);frame.rotation.x=deg_to_rad(-18)
	var rim=Node3D.new();frame.add_child(rim)
	var mesh=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=0.25;torus.outer_radius=0.29;torus.rings=32;torus.ring_segments=8
	mesh.mesh=torus;mesh.material_override=dark;mesh.rotation.x=PI/2;rim.add_child(mesh)
	rod(rim,Vector3(-0.26,0,0),Vector3(0.26,0,0),0.025,cream)
	rod(rim,Vector3(0,-0.26,0),Vector3.ZERO,0.025,cream)
	rod(host,Vector3(0,0.82,-0.98),frame.position,0.04,dark)
	if not interactive:return
	wheel=rim;wheel_frame=frame
	for side in [-1,1]:
		var grip=GRIP.new();arena.add_child(grip);grips.append(grip);grip.set_meta("side",side)
	box(Vector3(0,1.17,-1.32),Vector3(0.66,0.22,0.03),dark,false,host)
	hud=Label3D.new();hud.font_size=40;hud.pixel_size=0.00065;hud.position=Vector3(0,1.17,-1.30);host.add_child(hud)
	make_button(host,Vector3(-0.59,0.96,-0.70),"RESTART",restart)
	make_button(host,Vector3(0.59,0.96,-0.70),"MUSEUM",leave)
	cue=Label3D.new();cue.position=Vector3(0,1.95,-5);cue.font_size=64;cue.pixel_size=0.008;cue.modulate=Color("f7d0e0");host.add_child(cue)

func board_nearest() -> void:
	if is_instance_valid(rider):return
	var navigation=get_tree().get_first_node_in_group("museum_portal_navigation")
	if navigation!=null:
		museum=navigation.museum
		if not bool(museum.get("_vr")):
			board(museum.get("_player"));return
	for body in get_tree().get_nodes_in_group("player_body"):
		if body is XRToolsPlayerBody and global_position.distance_to(body.global_position)<5:
			board(body);return

func board(body: CharacterBody3D) -> bool:
	if is_instance_valid(rider) or body==null or body.global_position.distance_to(global_position)>5:return false
	# Release carried tools before transferring the visitor to the cockpit.
	if body is XRToolsPlayerBody:
		for n in body.origin_node.find_children("*","Node",true,false):
			if n.has_method("drop_object"):n.drop_object()
	else:
		for n in body.find_children("*","Node",true,false):
			if n.has_method("_drop_held") and n.has_method("is_holding") and n.is_holding():n._drop_held()
	rider=body;return_pose=body.global_transform
	if museum!=null:return_look=Vector2(museum.get("_yaw"),museum.get("_pitch"))
	var eye: Camera3D=body.camera_node if body is XRToolsPlayerBody else body.find_child("*Camera*",true,false)
	if eye==null and museum!=null:eye=museum.get("_cam")
	var eye_height: float=1.65 if eye==null else eye.global_position.y-body.global_position.y
	arena=Node3D.new();arena.name="EndlessDrivePocket";get_tree().root.add_child(arena)
	# Same z as the hall: museum streaming does not change the current room.
	arena.global_transform=Transform3D(global_basis.orthonormalized(),global_position+Vector3(2048,0,0))
	road=ROAD.new();arena.add_child(road)
	box(Vector3(0,-0.06,0),Vector3(7,0.12,7),material("19202d"),true,arena)
	var floor_body=arena.get_child(arena.get_child_count()-1)
	if floor_body is StaticBody3D:floor_body.collision_layer=1|524288
	car=Node3D.new();arena.add_child(car)
	car.position.y=clampf(eye_height-1.36,-0.12,0.75)
	road.position.y=car.position.y
	build_car(car,true)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-42,-25,0);light.light_energy=0.8;arena.add_child(light)
	var pose=Transform3D(arena.global_basis,arena.global_position)
	if body is XRToolsPlayerBody:
		var current_yaw: float=body.camera_node.global_rotation.y
		pose.basis=Basis(Vector3.UP,arena.global_rotation.y-current_yaw)*body.global_basis
		body.teleport(pose)
		seat_adapter=SEAT.new();seat_adapter.race=self;body.add_child(seat_adapter)
		body._movement_providers.append(seat_adapter);body._movement_providers.sort_custom(body.sort_by_order)
		for n in body.origin_node.find_children("*","XRController3D",true,false):controllers.append(n)
	else:
		body.global_transform=pose
		if museum!=null:
			museum.set("_yaw",arena.global_rotation.y);museum.set("_pitch",0.0)
			saved_camera=museum.get("_cam");saved_camera_position=saved_camera.position;saved_camera.rotation=Vector3.ZERO
			var feel: Node=museum.get("_feel")
			if is_instance_valid(feel):feel.teleported();feel.resync_view(body.rotation.y,0.0)
	body.velocity=Vector3.ZERO
	restart();return true

func restart() -> void:
	if not is_instance_valid(rider):return
	best=maxf(best,model.distance);model.reset();wheel_angle=0;grip_states.clear()
	countdown=3;last_crashes=0;last_cubes=0;event_time=0
	road.sync(model);sync_grips()

func leave() -> void:
	if not is_instance_valid(rider):return
	best=maxf(best,model.distance)
	for grip in grips:
		if is_instance_valid(grip) and grip.is_picked_up():grip.drop()
	if is_instance_valid(seat_adapter):
		rider._movement_providers.erase(seat_adapter);seat_adapter.queue_free()
	seat_adapter=null
	if rider is XRToolsPlayerBody:rider.teleport(return_pose)
	else:
		rider.global_transform=return_pose
		if museum!=null:
			museum.set("_yaw",return_look.x);museum.set("_pitch",return_look.y);museum.set("_vy",0.0)
			if is_instance_valid(saved_camera):saved_camera.position=saved_camera_position;saved_camera.rotation=Vector3(return_look.y,0,0)
			var feel: Node=museum.get("_feel")
			if is_instance_valid(feel):feel.teleported();feel.resync_view(rider.rotation.y,return_look.y)
	rider.velocity=Vector3.ZERO;rider=null;controllers.clear();grips.clear();grip_states.clear()
	if is_instance_valid(arena):arena.queue_free()
	arena=null;stage_label.text="ENDLESS DRIVE\nBEST %d m"%int(best)

func _physics_process(dt: float) -> void:
	if not is_instance_valid(rider):return
	if not is_instance_valid(arena):leave();return
	if arena.to_local(rider.global_position).length()>2.5:leave();return
	var controls:=read_controls(dt)
	countdown=maxf(0,countdown-dt)
	if countdown<=0:model.advance(dt,controls.x,controls.y,controls.z)
	road.sync(model);wheel.rotation.z=wheel_angle;sync_grips()
	if model.crashes!=last_crashes or model.cubes!=last_cubes:
		event_time=0.8
		for controller in controllers:
			if is_instance_valid(controller) and controller.get_is_active():controller.trigger_haptic_pulse("haptic",0,0.35,0.09,0)
	last_crashes=model.crashes;last_cubes=model.cubes;event_time=maxf(0,event_time-dt)
	hud.text="%02d km/h     %04d m\nCUBES %02d   HITS %02d"%[roundi(model.speed*3.6),int(model.distance),model.cubes,model.crashes]
	cue.text=str(ceili(countdown)) if countdown>0 else (model.last_event if event_time>0 else "")

func read_controls(dt: float) -> Vector3:
	var steer:=float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))
	var throttle:=float(Input.is_key_pressed(KEY_W));var brake:=float(Input.is_key_pressed(KEY_S))
	var angles: Array[float]=[]
	for grip in grips:
		var id=grip.get_instance_id()
		if not grip.held():grip_states.erase(id);continue
		var p=wheel_frame.to_local(grip.global_position)
		var angle=atan2(p.y,p.x)
		if not grip_states.has(id):grip_states[id]={"hand":angle,"wheel":wheel_angle}
		var start: Dictionary=grip_states[id]
		angles.append(clampf(float(start.wheel)+wrapf(angle-float(start.hand),-PI,PI),-1.05,1.05))
	if not angles.is_empty():
		wheel_angle=0
		for a in angles:wheel_angle+=a/angles.size()
		steer=-wheel_angle/1.05
	else:wheel_angle=move_toward(wheel_angle,-steer*1.05,2.5*dt)
	for controller in controllers:
		if not is_instance_valid(controller):continue
		if XRServer.primary_interface!=null and XRServer.primary_interface.is_initialized() and not controller.get_is_active():continue
		var value=clampf(controller.get_float("trigger"),0,1)
		if controller.is_button_pressed("trigger_click"):value=1
		if str(controller.tracker).contains("left"):brake=maxf(brake,value)
		else:throttle=maxf(throttle,value)
	return Vector3(steer,throttle,brake)

func sync_grips() -> void:
	for grip in grips:
		if not grip.held():
			grip.freeze=true;grip.global_position=wheel.to_global(Vector3(float(grip.get_meta("side"))*0.27,0,0))

func _point_inside(world: Vector3) -> bool:
	return is_instance_valid(rider) and rider.global_position.distance_to(world)<0.4
func carry_velocity(body: CharacterBody3D,_dt: float,incoming: Vector3) -> Vector3:return Vector3.ZERO if body==rider else incoming
func record_carry(_body: CharacterBody3D) -> void:pass
func release_carry(_body: CharacterBody3D) -> void:pass

func _input(event: InputEvent) -> void:
	if not is_instance_valid(rider) or not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_BACKSPACE:leave();get_viewport().set_input_as_handled()
	elif event.keycode==KEY_R:restart();get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(rider):leave()
	elif is_instance_valid(arena):arena.queue_free()
