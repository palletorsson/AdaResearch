extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message)
	print("[spectacle-gallery] ","PASS " if ok else "FAIL ",message)
func run() -> void:
	var em:Node3D=load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL","res://ada_run/spectacle-gallery-control.json")
	em.set("_overrides_path","res://ada_run/spectacle-gallery-no-overrides.json")
	em.set("_hand_path","res://ada_run/spectacle-gallery-no-hand.json")
	em.set("start_chapter","transformation")
	em.set("start_map","Trans_RotationSpectacle")
	var f:=FileAccess.open("res://ada_run/spectacle-gallery-control.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"transformation","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	await create_timer(1).timeout
	em.set_process(false);em.call("flush_stamps")
	var seg:Node3D
	for rec:Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")=="Trans_RotationSpectacle":seg=rec.node;break
	check(seg!=null,"gallery hall built")
	if seg==null:quit(1);return
	for i in range(180):await process_frame
	check(not seg.has_meta("em_simulation_stage"),"no staged simulation declaration")
	check(not seg.has_node("SimGrid_Trans_RotationSpectacle"),"no embedded GridSystem")
	check(not seg.has_node("SimulationFrame") and not seg.has_node("BasinFire"),"no basin or simulation enclosure")
	var cakes:Array[Node3D]=[]
	var tunnels:Array[Node3D]=[]
	for n in seg.find_children("*","Node3D",true,false):
		if n.get_script()==load("res://algorithms/transformation/carousel_cake/carousel_cake.gd"):cakes.append(n)
		if n.get_script()==load("res://algorithms/transformation/booleanTunnel/booleanTunnel.gd"):tunnels.append(n)
	check(cakes.size()==6,"six carousel instances installed")
	check(tunnels.size()==1,"one boolean tunnel installed")
	var profiles:Array[String]=[]
	for cake in cakes:
		profiles.append(cake.profile)
		print("[gallery-cake] ",cake.profile," at ",cake.position," scale ",cake.global_basis.get_scale())
		check(cake._gallery_clean,"profile uses a single live stack")
		check(cake.mm_inst.multimesh.instance_count==8,"eight layers in "+str(cake.profile))
		check(is_equal_approx(cake.base_rotation_speed,0.5) and is_equal_approx(cake.rotation_speed_multiplier,1.2),"same speed rule in "+str(cake.profile))
		var matches:bool=cake._collider_bodies.size()==8
		for i in range(cake._collider_bodies.size()):
			var shape:CollisionShape3D=cake._collider_bodies[i].get_child(0)
			matches=matches and is_equal_approx(shape.shape.radius,cake._vis_radii[i])
		check(matches,"collision matches the visible "+str(cake.profile)+" profile")
	profiles.sort()
	check(profiles==["cake","cake","column","flare","spindle","ziggurat"],"five distinct profiles and a repeated cake reference survive configuration")
	var left:=0
	var right:=0
	for cake in cakes:
		if cake.position.x<18.5: left+=1
		else: right+=1
	check(left==3 and right==3,"three cakes on each side of the central axis")
	if not tunnels.is_empty():
		var tunnel:=tunnels[0]
		print("[gallery-tunnel] at ",tunnel.position," scale ",tunnel.global_basis.get_scale())
		check(is_equal_approx(tunnel.position.x,18.5),"tunnel remains on the hall centreline")
		check(tunnel.num_segments==14 and tunnel.has_node("Cube13"),"tunnel has fourteen segments")
		check(is_equal_approx(tunnel.get_node("Cube13").rotation_degrees.z,130.0),"tunnel accumulates ten degrees per segment")
		var query:=PhysicsShapeQueryParameters3D.new()
		var capsule:=CapsuleShape3D.new()
		capsule.radius=0.22;capsule.height=1.6
		query.shape=capsule
		query.transform=Transform3D(Basis.IDENTITY,tunnel.to_global(Vector3(0,0.81,0)))
		query.motion=tunnel.global_basis*Vector3(0,0,43)
		var sweep:=seg.get_world_3d().direct_space_state.cast_motion(query)
		check(sweep[0]>0.99,"body-sized passage through the tunnel stays clear above the museum floor")
	var state:=seg.get_world_3d().direct_space_state
	for aisle_x in [13.5,23.5]:
		var supported:=true
		for z in range(4,52):
			var p:=seg.to_global(Vector3(aisle_x,0,em.VESTIBULE_H+z))
			var hit:=state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.3,p-Vector3.UP*0.3))
			supported=supported and not hit.is_empty()
		check(supported,"continuous museum floor along aisle "+str(aisle_x))
		var start:=seg.to_global(Vector3(aisle_x,1,em.VESTIBULE_H+4))
		var end:=seg.to_global(Vector3(aisle_x,1,em.VESTIBULE_H+51))
		check(state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end)).is_empty(),"viewing aisle "+str(aisle_x)+" is unobstructed")
	if "--capture" in OS.get_cmdline_user_args():
		var cam:=Camera3D.new();em.add_child(cam);cam.fov=55
		var target:=seg.to_global(Vector3(18,1,em.VESTIBULE_H+27))
		cam.global_position=target+Vector3(-30,35,-42);cam.look_at(target)
		for i in range(20):
			await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/Trans_RotationSpectacle_gallery.png")
	f=FileAccess.open("res://ada_run/spectacle_gallery_checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"profiles":profiles},"  "))
	print("[spectacle-gallery] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
