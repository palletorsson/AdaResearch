extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("PLACE ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/force-as-place-control.json"
	var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","forces");em.set("start_map","Vectors_Act5_ForceAsPlace")
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for r in em.get("_segments"):
		if r.node.get_meta("em_map","")=="Vectors_Act5_ForceAsPlace":seg=r.node;break
	check(seg!=null,"actual museum hall loads")
	if seg==null:quit(1);return
	var zone;var machine;var cubes=[]
	for n in seg.find_children("*","Node3D",true,false):
		if n.get_script()==null:continue
		var path=n.get_script().resource_path
		if path.ends_with("force_field_zone.gd"):zone=n
		if path.ends_with("vector_machine.gd"):machine=n
		if path.ends_with("force_cube.gd"):cubes.append(n)
	check(zone!=null and machine!=null and cubes.size()==3,"machine, field and three probes retained")
	if zone==null or machine==null:quit(1);return
	print("PLACE POS ",zone.global_position," machine ",machine.global_position," scale ",zone.global_basis.get_scale())
	check(zone.is_carry_lesson() and machine.is_carry_lesson(),"lesson configuration reaches runtime")
	check(zone.is_in_group("ada_museum_carry"),"field opts into controller receiver group")
	check(zone.global_position.distance_to(Vector3(8.5,0,12.5))<0.01,"field remains at authored pit centre")
	check(machine._console.get_parent()==machine and machine._sliders.size()==3,"one console owns exactly three sliders")
	check(machine._sliders.all(func(s):return s.global_position.y>0.8 and s.global_position.y<1.5),"three controls stand within reachable height band")
	var hill=seg.find_child("InvisibleHill",true,false)
	check(hill!=null,"existing invisible-hill supporting exhibit restored by registry")
	if hill!=null:
		check(hill._pucks.size()==10,"hill retains its bounded pool of ten pucks")
		check(absf(hill.global_basis.get_scale().x-0.68)<0.001,"supporting hill fits its alcove at declared scale")
	machine.set_process(false);zone.set_physics_process(false)
	check(zone.field_vector.distance_to(Vector3(0,-9.8,0))<0.02,"opening machine supplies downward acceleration")
	machine._set_slider(0,0.75);machine._set_slider(1,0);machine._set_slider(2,0.5);machine._process(0)
	check(zone.field_vector.distance_to(Vector3(0,1,1).normalized()*7.5)<0.02,"actual sliders aim up and forward")
	check(zone._readout.text.contains("m/s²"),"field names acceleration units")
	var local_v=zone.field_vector
	var other=Node3D.new();other.set_meta("em_map","OtherHall");root.add_child(other)
	var other_zone=load("res://commons/artifacts/force_field_zone/force_field_zone.gd").new();other_zone.set_meta("config_lesson","force_as_place");other.add_child(other_zone);other_zone.set_physics_process(false)
	machine._process(0)
	check(other_zone.field_vector.is_equal_approx(Vector3(0,-9.8,0)),"local machine cannot command another hall")
	var legacy=load("res://commons/artifacts/vector_machine/vector_machine.gd").new();other.add_child(legacy);legacy.set_process(false);legacy._set_slider(2,0);legacy._update()
	check(zone.field_vector.is_equal_approx(local_v),"legacy machine cannot overwrite scoped hall")
	var late=load("res://commons/artifacts/force_field_zone/force_field_zone.gd").new();late.set_meta("config_lesson","force_as_place");late.position=Vector3(100,100,0);seg.add_child(late);late.set_physics_process(false);machine._process(0)
	check(late.field_vector.is_equal_approx(local_v),"late-loaded local field binds without a slider edit")
	late.queue_free();other.queue_free();await process_frame
	check(zone._point_inside(zone.to_global(Vector3.ZERO)),"field includes its floor")
	check(not zone._point_inside(zone.to_global(Vector3(2.5,1,0))),"side boundary is strict")
	check(not zone._point_inside(zone.to_global(Vector3(0,-0.03,0))),"below-floor point excluded")
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	var feel=em.get("_feel");em.set("_feel",null);em.set("_autopilot",0)
	zone.set_field_vector(Vector3(0,2,3));player.global_position=zone.to_global(Vector3(0,2,0));player.velocity=Vector3.ZERO;em.set("_vy",0)
	for i in 30:
		await physics_frame
		em._physics_process(1.0/60)
	print("PLACE DESKTOP ",player.velocity," vy ",em.get("_vy")," pos ",zone.to_local(player.global_position)," history ",zone._carry)
	check(player.velocity.distance_to(Vector3(0,1,1.5))<0.001,"actual desktop controller accumulates acceleration for 0.5 seconds")
	check(absf(float(em.get("_vy"))-1)<0.001,"desktop vertical state matches carried velocity without double gravity")
	zone.set_field_vector(Vector3.ZERO)
	check(not zone._central.visible,"zero acceleration has no directional centre arrow")
	var v=player.velocity;em._physics_process(1.0/60)
	check(player.velocity.is_equal_approx(v),"zero acceleration retains incoming motion")
	player.global_position=zone.to_global(Vector3(6,1,0));em._physics_process(1.0/60)
	check(not zone._carry.has(player.get_instance_id()),"exit clears carry state and returns ordinary movement")
	check(absf(player.velocity.z)<0.001,"outside field ordinary no-input locomotion owns horizontal speed")
	player.global_position=zone.to_global(Vector3(0,2,0));player.velocity=Vector3(0,0,0.25);em._physics_process(1.0/60)
	check(absf(player.velocity.z-0.25)<0.001,"re-entry uses current incoming velocity, not old field history")
	player.global_position=zone.to_global(Vector3(6,2,-6));zone.release_carry(player);em.set("_feel",feel)
	# A real crossing, entering from the plank with a declared incoming speed.
	em.set("_feel",null);zone.set_field_vector(Vector3(0,1,1).normalized()*7.5)
	player.global_position=zone.to_global(Vector3(0,0.02,-2.49));player.velocity=Vector3(0,0,2);em.set("_vy",0)
	var highest=0.0
	for i in 150:
		await physics_frame
		em._physics_process(1.0/60)
		highest=maxf(highest,player.global_position.y-zone.global_position.y)
	check(highest>1,"real desktop crossing lifts the visitor above the plank")
	check(zone.to_local(player.global_position).z>2.5 and player.is_on_floor(),"visitor exits far face and lands on far shore")
	print("PLACE CROSSING ",zone.to_local(player.global_position)," highest ",highest)
	player.global_position=zone.to_global(Vector3(6,2,-6));zone.release_carry(player);em.set("_feel",feel)
	# Real area membership, with integration called once for an independent impulse check.
	var probes=[]
	for mass_value in [1.0,4.0]:
		var b=RigidBody3D.new();b.mass=mass_value;b.gravity_scale=0.7;b.freeze=true
		var cs=CollisionShape3D.new();cs.shape=SphereShape3D.new();b.add_child(cs);root.add_child(b)
		b.global_position=zone.to_global(Vector3(-1+probes.size()*2,2,0));probes.append(b)
	await physics_frame;await physics_frame
	zone.set_field_vector(Vector3(2,3,4))
	for b in probes:b.freeze=false;b.linear_velocity=Vector3.ZERO
	await physics_frame;await physics_frame
	for b in probes:b.linear_velocity=Vector3.ZERO
	zone._physics_process(0.1)
	for b in probes:
		check(b.gravity_scale==0 and b.linear_velocity.distance_to(Vector3(0.2,0.3,0.4))<0.0001,"field supplies same acceleration to mass "+str(b.mass))
	probes[0].freeze=true;zone._physics_process(0)
	check(absf(probes[0].gravity_scale-0.7)<0.001,"held/frozen receiver gets its original gravity back")
	probes[1].global_position=zone.to_global(Vector3(10,2,0));await physics_frame;await physics_frame;zone._physics_process(0)
	check(absf(probes[1].gravity_scale-0.7)<0.001,"leaving area restores original gravity scale")
	for b in probes:b.queue_free()
	var removal_body=RigidBody3D.new();root.add_child(removal_body);removal_body.freeze=true;removal_body.gravity_scale=0
	var removal_zone=load("res://commons/artifacts/force_field_zone/force_field_zone.gd").new();root.add_child(removal_zone);removal_zone.set_physics_process(false);removal_zone._restore[removal_body]=0.6
	removal_zone.free();check(absf(removal_body.gravity_scale-0.6)<0.001,"removing a field restores captured gravity")
	removal_body.queue_free()
	for cube in cubes:
		check(cube._resting_force()==Vector3.ZERO,"stationary lesson probe does not invent a resting force")
		check(cube.falls==1 and absf(cube.linear_damp-0.3)<0.0001,"probe keeps gravity and damping outside field")
	# Real XRTools body/provider dispatch, without an HMD.
	var origin=XROrigin3D.new();var eye=XRCamera3D.new();origin.add_child(eye);eye.position.y=1.7;root.add_child(origin)
	var xr=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate();origin.add_child(xr);xr.set_physics_process(false);xr.global_position=zone.to_global(Vector3(0,2,0));await process_frame
	var adapter=xr.get_node_or_null("FieldCarryAdapter")
	check(adapter!=null and xr._movement_providers.has(adapter),"late XR body receives registered provider")
	if adapter!=null:
		xr.velocity=Vector3.ZERO
		check(not adapter.physics_movement(0.1,xr,true) and xr.velocity==Vector3.ZERO,"XR respects an earlier exclusive provider")
		# move_player is a physics-provider-only API; mirror the real dispatch guard.
		xr._in_physics_movement=true
		check(adapter.physics_movement(0.1,xr,false),"XR field takes exclusive movement ownership inside")
		xr._in_physics_movement=false
		check(xr.velocity.distance_to(Vector3(0.2,0.3,0.4))<0.01,"XR move_player receives field acceleration once")
		xr.global_position=zone.to_global(Vector3(10,2,0))
		check(not adapter.physics_movement(0.1,xr,false) and not zone._carry.has(xr.get_instance_id()),"XR exit releases movement and history")
		zone.install_carry_adapter();check(xr.get_children().filter(func(n):return n.name=="FieldCarryAdapter").size()==1,"XR provider installs once")
	origin.queue_free()
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	machine._set_slider(0,0.75);machine._set_slider(1,0);machine._set_slider(2,0.5);machine._process(0)
	var cam=Camera3D.new();em.add_child(cam);cam.fov=67
	cam.global_position=machine.global_position+Vector3(0.6,1.9,-1.6);cam.look_at(machine.global_position+Vector3(0,1,0))
	for i in 10:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/place_machine.png")
	cam.global_position=zone.global_position+Vector3(0,2.4,-4.5);cam.look_at(zone.global_position+Vector3(0,1.8,0))
	for i in 10:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/place_crossing.png")
	if hill!=null:
		cam.global_position=hill.global_position+Vector3(0,3,-2.8);cam.look_at(hill.global_position)
		for i in 10:await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/place_hill.png")
	f=FileAccess.open("res://ada_run/force_as_place_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("PLACE COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
