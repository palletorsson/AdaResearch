extends SceneTree
var OUT := ""
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):OUT=arg.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("KINETIC FORCES ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="Vectors_Act4a_KineticForces"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=OUT+"kinetic-forces-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","forces");em.set("start_map",map_name)
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for r in em.get("_segments"):
		if r.node.get_meta("em_map","")==map_name:seg=r.node;break
	check(seg!=null,"hall loads: "+map_name)
	if not seg:quit(1);return
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var cam=Camera3D.new();em.add_child(cam);cam.fov=65
	var ui=seg.find_child("KineticDrag",true,false);check(ui!=null,"drag chamber loads")
	if not ui:quit(1);return
	check(ui.bodies.size()==3 and ui.global_basis.get_scale().is_equal_approx(Vector3.ONE),"three metre-scale rigid-body probes")
	check(ui.bodies.all(func(b):return b is RigidBody3D and b.gravity_scale==0 and b.linear_damp==0),"explicit force model excludes hidden gravity and damping")
	press(ui,"FIRE",cam);await create_timer(1).timeout
	var speeds=[]
	for i in 3:
		speeds.append(ui.bodies[i].linear_velocity.length())
		var prediction=4*exp(-ui.COEFFICIENTS[i]*ui.elapsed)
		check(absf(speeds[i]-prediction)<0.11,"measured speed matches drag decay "+ui.NAMES[i]+": "+str(speeds[i]))
	check(speeds[0]>speeds[1] and speeds[1]>speeds[2],"resistance orders the three speeds")
	check(ui.bodies[0].position.x>ui.bodies[1].position.x and ui.bodies[1].position.x>ui.bodies[2].position.x,"resistance orders travelled distance")
	press(ui,"MASS",cam);check(ui.mass_value==2 and not ui.active and ui.bodies[0].freeze,"mass change resets and holds probes")
	press(ui,"FIRE",cam);await create_timer(1).timeout
	check(ui.bodies[2].linear_velocity.length()>speeds[2]*3,"same drag coefficient slows heavier body less")
	press(ui,"PARTS",cam);press(ui,"RULE",cam)
	var nodes=ui.get_child_count();await create_timer(0.2).timeout
	check(ui.get_child_count()==nodes and ui.arrows.size()==3,"force arrows reuse geometry")
	check(ui.board.text.contains("separate adapter"),"readout distinguishes physical drag from locomotion mapping")
	check(ui.walk_multiplier(ui.to_global(Vector3(0,0,0)))==1,"walk adaptation starts disabled")
	press(ui,"WALK",cam)
	for i in 3:check(absf(ui.walk_multiplier(ui.to_global(Vector3(0,0,float(i-1)*3)))-1/(1+ui.COEFFICIENTS[i]))<0.00001,"correct walk multiplier "+ui.NAMES[i])
	check(ui.walk_multiplier(ui.to_global(Vector3(2,0,0)))==1 and ui.walk_multiplier(ui.to_global(Vector3(0,0,5)))==1,"side bypass and exit restore ordinary movement")
	# Exercise the real desktop controller before move_and_slide.
	var feel=em.get("_feel");em.set("_feel",null);em.set("_autopilot",0)
	var key=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=true;Input.parse_input_event(key);Input.flush_buffered_events()
	ui.walk_enabled=false;player.global_position=ui.to_global(Vector3(0,0.1,3));em._physics_process(1.0/60)
	var ordinary=Vector2(player.velocity.x,player.velocity.z).length()
	ui.walk_enabled=true;player.global_position=ui.to_global(Vector3(0,0.1,3));em._physics_process(1.0/60)
	var slowed=Vector2(player.velocity.x,player.velocity.z).length()
	check(ordinary>1 and absf(slowed/ordinary-1/4.2)<0.01,"actual desktop movement applies honey mapping: ordinary="+str(ordinary)+" slowed="+str(slowed)+" W="+str(Input.is_key_pressed(KEY_W))+" factor="+str(ui.walk_multiplier(player.global_position)))
	var released=key.duplicate();released.pressed=false;Input.parse_input_event(released);Input.flush_buffered_events();em.set("_feel",feel)
	# Construct an XRTools body without requiring an HMD and inspect its provider path.
	var origin=XROrigin3D.new();var eye=XRCamera3D.new();origin.add_child(eye);eye.position.y=1.7;root.add_child(origin)
	var xr=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate();origin.add_child(xr);xr.set_physics_process(false);xr.global_position=ui.to_global(Vector3(0,0,3))
	await process_frame
	var adapter=xr.get_node_or_null("KineticMediumAdapter")
	check(adapter!=null and xr._movement_providers.has(adapter),"late XR body receives registered movement adapter")
	if adapter:
		xr.ground_control_velocity=Vector2(0,3);adapter.physics_movement(1.0/60,xr,false)
		check(absf(xr.ground_control_velocity.length()-3/4.2)<0.001,"XR stick request uses the same medium mapping")
		xr.ground_control_velocity=Vector2(0,3);adapter.physics_movement(1.0/60,xr,true)
		check(xr.ground_control_velocity.length()==3,"exclusive XR movement is left alone")
		ui.install_xr_adapter();check(xr.get_children().filter(func(n):return n.name=="KineticMediumAdapter").size()==1,"XR adapter installs once")
	origin.queue_free()
	ui.set_physics_process(false);ui.bodies[0].freeze=false;ui.bodies[0].position.x=4.1;ui.active=true;ui._physics_process(1.0/60)
	check(ui.exited[0] and ui.bodies[0].freeze,"observation frame freezes outgoing body")
	var ring;var mower
	for n in seg.find_children("*","Node",true,false):
		if n.get_meta("artifact_lookup_name","")=="centrifuge_ring":ring=n
		if n.get_meta("artifact_lookup_name","")=="force_mower":mower=n
	check(ring!=null and mower!=null,"other two primaries remain placed")
	if ring:
		ring.set_process(false);var phase=ring._phase;var v=lerpf(2,9,ring.speed);ring._process(0.1)
		check(absf((ring._phase-phase)*ring.radius/0.1-v)<0.0001,"ring angular motion matches displayed speed")
		check(absf(ring.global_basis.get_scale().x-1)<0.001,"ring world scale preserves metre readout")
		var child_count=ring._vectors.get_child_count();ring._process(0.1);check(ring._vectors.get_child_count()==child_count,"ring vectors reused while moving")
		var a=v*v/ring.radius;phase=ring._phase;press(ring._controls,"SPEED",cam);await process_frame
		var next_v=lerpf(2,9,ring.speed);check(absf(next_v-4)<0.001 and absf((next_v*next_v/ring.radius)/a-4)<0.001,"doubling speed quadruples required centripetal acceleration")
		check(ring._phase==phase,"speed edit retains phase")
	if mower:
		mower.set_process(false);mower.set_physics_process(false);mower._measurement_started=false;mower._process(0)
		var before=mower._work;var d=mower._dist;var direction=mower.global_basis.x.normalized();var blades=mower._blades.size()
		mower.global_position+=direction;mower._process(0.1)
		check(mower._work>before and absf(mower._dist-d-1)<0.001,"forward movement adds nominal work and path")
		mower.global_position-=direction;mower._process(0.1)
		check(absf(mower._work-before)<0.001 and absf(mower._dist-d-2)<0.001,"return cancels signed nominal work but adds path")
		check(mower._blades.size()<=blades,"return does not restore cut grass")
		var side=mower.global_basis.z.normalized();mower.global_position+=side;mower._process(0.1)
		check(absf(mower._work-before)<0.001,"sideways displacement contributes zero nominal work")
		check(mower._readout.text.contains("not measured hand effort"),"mower labels the force as nominal")
	if mower: mower.global_position-=mower.global_basis.z.normalized()
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()];q.collision_mask=1
	await physics_frame
	for z in [-4.0,-2.0,0.0,2.0,4.0]:
		q.transform.origin=ui.to_global(Vector3(0,1.0,z));check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear centre passage "+str(z))
	for specimen in [ring,mower]:
		for offset in [Vector3(0,1.1,-3),Vector3(3,1.1,0)]:
			q.transform.origin=specimen.to_global(offset);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear primary approach "+str(specimen.name)+str(offset))
	check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"controls at standing height")
	ui.mass_value=1;ui.set_physics_process(true);press(ui,"FIRE",cam);await create_timer(0.8).timeout
	ui.set_physics_process(false)
	for b in ui.bodies:b.freeze=true
	cam.global_position=ui.to_global(Vector3(5,5,-7));cam.look_at(ui.to_global(Vector3(0,1,0)))
	for i in 15:await process_frame;cam.make_current()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"kinetic_drag_overview.png")
	cam.global_position=ui.to_global(Vector3(0,1.7,-4));cam.look_at(ui.to_global(Vector3(0,1.5,3)))
	for i in 15:await process_frame;cam.make_current()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"kinetic_drag_inside.png")
	if ring:
		cam.global_position=ring.to_global(Vector3(6,4,0));cam.look_at(ring.to_global(Vector3(0,1,0)))
		for i in 15:await process_frame;cam.make_current()
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"kinetic_ring.png")
	if mower:
		cam.global_position=mower.global_position+Vector3(3,2,3);cam.look_at(mower.global_position+Vector3(0,0.6,0))
		for i in 15:await process_frame;cam.make_current()
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"kinetic_mower.png")
	f=FileAccess.open(OUT+"kinetic_forces_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("KINETIC FORCES COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
