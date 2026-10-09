extends SceneTree
var checks: Array=[]
var failures: Array=[]
var scene: Node3D
var registry: Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(label: String,ok: bool) -> void:
	checks.append({"label":label,"passed":ok})
	if not ok:failures.append(label);push_error(label)
func wait_frames(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	await process_frame
	var paths=["vectors_demos.json","physics_simulation.json","catapult.json","human_catapult.json","force_vortex.json"]
	for path in paths:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/"+path))
		registry.merge(data.artifacts,true)
	var selection=JSON.parse_string(FileAccess.get_file_as_string("res://doc/vector_forces_selected.json"))
	for item in selection.artifacts:
		var id: String=item.token
		scene=load(registry[id].scene).instantiate()
		if str(item.get("config","")).contains("lesson:"):
			var lesson=str(item.config).split("lesson:")[1].split("#")[0];scene.set_meta("config_lesson",lesson)
		root.add_child(scene);await wait_frames(3)
		check(id+" builds",scene.get_child_count()>0)
		match id:
			"firework_burst":await fountain()
			"wind_room":await wind()
			"centrifuge_ring":await ring()
			"SpringSuspension":await suspension()
			"human_catapult":await catapult()
			"force_vortex":await vortex()
		scene.queue_free();await wait_frames(3)
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"physics":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"Production scenes, deterministic clocks, rigid body response, supplied desktop and XR hand events. Headset feel not tested."}
	FileAccess.open("res://ada_run/forces_selection_models.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCES SELECTION MODELS ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)

func fountain() -> void:
	var f=scene.get_node("LiveFountain");f.set_physics_process(false)
	check("fountain has forty-eight actual moving sparks",f.sparks.size()==48)
	f.step(0.4);var p: Vector3=f.sparks[0].position
	f.step(0.45);check("fountain reaches automatic hold",f.hold_time>0 and is_equal_approx(f.simulation_time,0.85))
	var held: Vector3=f.sparks[0].position;f.step(0.5)
	check("automatic hold retains actual position",f.sparks[0].position.is_equal_approx(held) and not p.is_equal_approx(held))
	check("large fountain rises over five metres",f.sparks.any(func(s):return s.position.y>5))
	f.step(2);f.step(0.2);check("automatic hold resumes",f.simulation_time>0.85)
	f.buttons["FREEZE / RESUME"].pressed.emit();held=f.sparks[0].position;f.step(0.5)
	check("nearby button freezes only fountain clock",f.manual_pause and f.sparks[0].position.is_equal_approx(held))
	f.buttons["FREEZE / RESUME"].pressed.emit();f.step(0.2)
	check("nearby button resumes fountain",not f.manual_pause and not f.sparks[0].position.is_equal_approx(held))
	var v: Vector3=f.velocity_at(0,0.6)-f.velocity_at(0,0.2)
	check("spark acceleration remains gravity",v.is_equal_approx(Vector3(0,-9.8*0.4,0)))

func wind() -> void:
	var w=scene.get_node("HandsOnWind")
	check("wind has eight real grabbable bodies",w.bodies.size()==8 and w.bodies[0].has_method("pick_up"))
	var b: RigidBody3D=w.bodies[0];b.gravity_scale=0;b.linear_damp=0;b.linear_velocity=Vector3.ZERO;b.position=Vector3(0,2,0)
	await wait_frames(30)
	check("wind changes actual rigid body velocity",b.linear_velocity.x>0.5)
	var light: Vector3=w.wind_delta(Vector3.ZERO,0.5,0.02);var heavy: Vector3=w.wind_delta(Vector3.ZERO,2.5,0.02)
	check("same wind accelerates lighter mass more",light.length()>heavy.length())
	check("matching air velocity produces no drag",w.wind_delta(w.air_velocity(),1,0.02).is_zero_approx())
	w.buttons["WIND / CALM"].pressed.emit();check("calm control removes air velocity",w.air_velocity().is_zero_approx())
	w.buttons["WIND / CALM"].pressed.emit();w.buttons.TURN.pressed.emit();check("turn control changes actual force direction",absf(w.air_velocity().z)>6)
	var player=CharacterBody3D.new();root.add_child(player);player.global_position=w.global_position+Vector3.UP
	var v: Vector3=w.carry_velocity(player,0.1,Vector3.ZERO)
	check("wind pushes the player receiver",absf(v.z)>0.3)
	player.queue_free()

func ring() -> void:
	var r=scene.get_node("HandRing")
	var rig=XROrigin3D.new();rig.current=true
	var head=XRCamera3D.new();head.name="Camera";head.position=Vector3(0.3,1.7,-0.2);rig.add_child(head)
	var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate();body.player_calibrate_height=false;rig.add_child(body)
	var hand=XRController3D.new();rig.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	root.add_child(rig);await wait_frames(3);body.set_physics_process(false)
	var pose: Transform3D=body.global_transform;pose.origin=r.to_global(Vector3(0,0.1,-3.4));body.teleport(pose)
	hand.global_position=r.handle.global_position
	r.handle.pick_up(pickup);await wait_frames(3)
	check("centrifuge handle recognizes actual XR player",r.handle.held() and r.handle.receiver()==body and r.rider==body)
	check("centrifuge installs XR motion adapter",body.get_node_or_null("FieldCarryAdapter")!=null)
	var tracked: Transform3D=head.transform
	var v: Vector3=r.carry_velocity(body,0.1,Vector3.ZERO);body.velocity=v;r.record_carry(body)
	check("held ring imparts tangential velocity",v.x>0.3 and absf(v.z)<0.3)
	check("ring leaves tracked head transform intact",head.transform.is_equal_approx(tracked))
	var started: Vector3=body.global_position
	var adapter=body.get_node("FieldCarryAdapter")
	for i in range(45):
		adapter.physics_movement(1.0/60,body,false);await physics_frame
	check("ring moves the real XR collision body",body.global_position.distance_to(started)>0.5)
	check("ring keeps the moving body near its circle",absf(Vector2(body.global_position.x,body.global_position.z).length()-3.4)<0.3)
	v=body.velocity
	r.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await wait_frames(2)
	var released: Vector3=r.carry_velocity(body,0.01,v)
	check("release retains tangent then slows",released.x>0 and released.x<v.x)
	r.buttons.SPEED.pressed.emit();check("nearby speed changes circle speed",is_equal_approx(r.speed,4))
	r.handle.action_pressed.emit(r.handle);check("held controller action also changes speed",is_equal_approx(r.speed,6))
	rig.queue_free();await wait_frames(2)

func suspension() -> void:
	check("suspension leaves museum camera and sky alone",scene.find_children("*","Camera3D",true,false).is_empty() and scene.find_children("*","WorldEnvironment",true,false).is_empty())
	check("suspension uses an actual 6DOF joint",scene.suspension is Generic6DOFJoint3D)
	var grip: Node3D=null
	for child in scene.get_children():
		if child.get_script()!=null and child.get_script().resource_path.ends_with("/constraint_grip.gd"):grip=child
	check("suspension has a force-transmitting grip",grip!=null and grip.target==scene.wheel)
	var start: float=scene.wheel.position.y
	scene.wheel.apply_central_impulse(Vector3.UP*3);await wait_frames(20)
	check("Jolt suspension responds to impulse",absf(scene.wheel.position.y-start)>0.005)

func catapult() -> void:
	var player=CharacterBody3D.new();player.add_to_group("em_walker");root.add_child(player)
	var col=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.height=1.6;shape.radius=0.27
	col.shape=shape;col.position.y=0.8;player.add_child(col)
	player.global_position=scene._basket_world_pos()+Vector3.UP*0.065
	await wait_frames(190)
	check("human catapult queues launch with movement owner",scene._flight_receiver!=null and scene._flight_receiver.flights.has(player.get_instance_id()))
	var v: Vector3=scene._flight_receiver.carry_velocity(player,0.02,Vector3.ZERO)
	check("catapult keeps upward velocity over the axle",v.y>5 and v.z< -5)
	player.queue_free();await wait_frames(2)

func vortex() -> void:
	var player=CharacterBody3D.new();root.add_child(player);player.global_position=scene.to_global(Vector3(2,0.2,0))
	scene._on_body_entered(player)
	var v: Vector3=scene.carry_velocity(player,0.02,Vector3.ZERO)
	check("vortex carries with inward and tangent components",v.x<0 and absf(v.z)>1)
	player.global_position=scene.to_global(Vector3(0.2,0.2,0));v=scene.carry_velocity(player,0.02,v)
	check("vortex ejects with movement-owned inertia",v.x>10 and v.y>5 and scene._flight_receiver.flights.has(player.get_instance_id()))
	player.queue_free();await wait_frames(2)
