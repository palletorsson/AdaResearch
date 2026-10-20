extends "res://tools/probes/transformation_encounters.gd"
var completed := false

func landing_checks() -> void:
	var start := Time.get_ticks_msec()
	while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<35000:
		museum.call("_drain_stamps"); museum.call("_drain_cartridge_nodes"); await tick()
	var wing = find_scene("/noneuclidean_wing.gd")
	check("wing loaded from actual map and registry",wing!=null)
	if wing==null: return
	while not wing.built: await tick()
	wing.set_process(false)
	check("seven full-size chambers",wing.rooms.size()==7)
	check("existing triangle bench retained",find_scene("/triangle_curvature_workbench.gd")!=null)
	observations["entry"] = xyz(wing.position)
	observations["scale"] = xyz(wing.scale)
	var identity: int=wing.point.get_instance_id()
	check("point is byte-identical to prior PointBody",FileAccess.get_file_as_string(wing.point.get_script().resource_path)==FileAccess.get_file_as_string("res://doc/book/studies/noneuclid-lineage/point_body.gd"))
	check("runtime point dependency is exportable",str(wing.point.get_script().resource_path).begins_with("res://commons/"))
	check("source approach supported",not floor_at(wing.to_global(Vector3(0,0,1.7))).is_empty())
	# A real body can get through the doorway and past the control desk.
	var walker: CharacterBody3D=museum.get("_player")
	wing.test_eye=Vector3(INF,INF,INF)
	walker.global_position=wing.to_global(Vector3(0,0.05,1.6))
	wing.last_eye=wing.eye_position(); wing.have_eye=true; wing.crossing_cooldown=0
	var reached := false
	var source_blocked := false
	for j in range(38):
		if walker.test_move(walker.global_transform,wing.global_basis*Vector3(0,0,-0.05)):
			source_blocked=true; break
		walker.global_position+=wing.global_basis*Vector3(0,0,-0.05)
		wing._process(0.017)
		if wing.current==0: reached=true; break
	check("real walker crosses entry without obstruction",reached and not source_blocked)
	wing.sweep_count=0
	wing.visit(0)
	walker.global_position=wing.rooms[0].to_global(Vector3(0,0.05,5.5))
	var obstructed := false
	for j in range(48):
		obstructed=obstructed or walker.test_move(walker.global_transform,Vector3(0,0,-0.05))
		walker.global_position+=Vector3(0,0,-0.05)
	check("physical approach into chamber is clear",not obstructed)
	wing.leave()
	wing.sweep_count=0
	await snapshot("entry",wing.to_global(Vector3(0,1.65,4.2)),wing.to_global(Vector3(0,1.5,-2)),65)
	if DisplayServer.get_name()!="headless":
		var remote_pink := wing.to_global(Vector3(-0.44,1.4,-4.06))
		var pixel := camera.unproject_position(remote_pink)
		var picture := root.get_texture().get_image()
		var colour := picture.get_pixel(int(pixel.x),int(pixel.y))
		check("portal pixels show remote rose doorway",colour.r>colour.g*1.35 and colour.b>colour.g*1.1)
		wing.entry_writer.visible=false
		await process_frame; await RenderingServer.frame_post_draw
		picture=root.get_texture().get_image()
		var hidden := picture.get_pixel(int(pixel.x),int(pixel.y))
		check("stencil writer controls actual remote visibility",Vector3(colour.r-hidden.r,colour.g-hidden.g,colour.b-hidden.b).length()>0.15)
		wing.entry_writer.visible=true
		var eye_local := wing.to_local(camera.global_position)
		var target_local := wing.to_local(remote_pink)
		var foreground_at := eye_local.lerp(target_local,(eye_local.z-1.0)/(eye_local.z-target_local.z))
		var foreground=wing.B.box(wing,foreground_at,Vector3(0.2,0.2,0.2),Color.GREEN)
		foreground.material_override=wing.B.material(Color.GREEN,true)
		await process_frame; await RenderingServer.frame_post_draw
		picture=root.get_texture().get_image()
		var front := picture.get_pixel(int(pixel.x),int(pixel.y))
		check("opaque foreground still occludes portal",front.g>front.r*1.5)
		foreground.queue_free()
	wing.test_eye=wing.to_global(Vector3(0,1.6,0.2))
	wing.crossing_cooldown=0
	wing.last_eye=wing.test_eye; wing.have_eye=true
	wing.test_eye=wing.to_global(Vector3(0,1.6,-0.1)); wing._process(0.01)
	check("swept head crossing enters room",wing.current==0 and wing.sweep_count==1)
	check("door crossing preserves head offset",wing.rooms[0].to_local(wing.test_eye).is_equal_approx(Vector3(0,1.6,5.6)))
	wing.crossing_cooldown=0
	wing.last_eye=wing.rooms[0].to_global(Vector3(0,1.6,5.6))
	wing.test_eye=wing.rooms[0].to_global(Vector3(0,1.6,5.8)); wing._process(0.01)
	check("reverse crossing returns to museum",wing.current==-1 and wing.sweep_count==2)
	check("aperture rejects crossing through wall",not wing.swept_door(Vector3(2,1,0.2),Vector3(2,1,-0.2)))
	var marker := Node3D.new(); root.add_child(marker)
	wing.point.on_desktop_grab(marker)
	var hand_before: Vector3=wing.point.global_position-wing.test_eye
	wing.enter_by_door()
	check("held point preserves head-relative offset",(wing.point.global_position-wing.test_eye).is_equal_approx(hand_before))
	wing.point.on_desktop_drop(marker)
	for i in range(7):
		wing.visit(i); await tick()
		check("same carried instance in chamber %d"%(i+1),wing.point.get_instance_id()==identity)
		check("supported arrival %d"%(i+1),not floor_at(wing.rooms[i].to_global(Vector3(0,0,5.55))).is_empty())
		check("next control present %d"%(i+1),wing.rooms[i].has_node("Next"))
		var room: Node3D=wing.rooms[i]
		if i==2: wing.sphere_progress=3; wing.update_sphere()
		if i in [4,5]: wing.metric_step(Vector3(0.12,0.1,-0.18))
		await snapshot("space-%02d"%(i+1),room.to_global(Vector3(0,2.5,5.7)),room.to_global(Vector3(0,1.6,-1.5)),85)
		if i not in [4,5]: await snapshot("above-%02d"%(i+1),room.to_global(Vector3(10,14,14)),room.to_global(Vector3(0,0,0)),66)
	wing.visit(1); wing.crossing_cooldown=0
	wing.last_eye=wing.rooms[1].to_global(Vector3(0,1.6,-3.9))
	wing.test_eye=wing.rooms[1].to_global(Vector3(0,1.6,-4.1)); wing._process(0.01)
	check("periodic corridor wraps without turning",wing.wraps==1 and absf(wing.rooms[1].to_local(wing.test_eye).z-3.8)<0.001)
	var k = wing.K
	var arrow: Vector3=k.transport_sphere(Vector3.UP,Vector3.RIGHT,Vector3.UP)
	arrow=k.transport_sphere(arrow,Vector3.UP,Vector3.BACK)
	arrow=k.transport_sphere(arrow,Vector3.BACK,Vector3.RIGHT)
	check("spherical loop changes tangent 90 degrees",absf(arrow.dot(Vector3.UP))<0.0001 and absf(arrow.length()-1)<0.0001)
	wing.visit(3)
	var saved: Vector3=wing.disk_c
	wing.rooms[3].get_node("DiskKlein").pressed.emit()
	check("model button changes representation without changing point",wing.disk_klein and wing.disk_c==saved)
	var a: Vector4=k.from_ball(Vector3(-0.56,0,-0.32)); var b: Vector4=k.from_ball(Vector3(0.57,0,-0.24)); var c: Vector4=k.from_ball(saved)
	check("hyperbolic triangle has deficit",k.triangle_sum(a,b,c)<PI)
	wing.disk_c=Vector3(-0.56,0,-0.32); wing.redraw_disk()
	check("coincident corner refuses angle reading",wing.readouts[3].text.begins_with("No triangle"))
	wing.disk_c=saved; wing.redraw_disk()
	wing.visit(4); wing.metric_step(Vector3.UP*0.5)
	check("product height changes without a vertical boost",wing.travel_distance==0 and wing.product_height==0.5 and wing.observer==Projection.IDENTITY)
	wing.metric_step(Vector3.LEFT*0.4)
	check("product permits horizontal boost",absf(wing.travel_distance-0.4)<0.0001)
	wing.visit(5); wing.metric_step(Vector3.UP*0.5)
	check("H3 includes vertical boost",absf(wing.travel_distance-0.5)<0.0001)
	var q: Vector4=wing.observer*Vector4(0,0,0,1)
	check("observer stays on hyperboloid",absf(k.lorentz(q,q)+1)<0.0001)
	wing.visit(6)
	wing.point.on_desktop_grab(marker)
	wing.point.action()
	check("actual pickable trigger launches",wing.shooting and wing.held_trigger)
	wing.point.action_release()
	check("actual pickable trigger releases",not wing.held_trigger)
	wing.point.on_desktop_drop(marker)
	wing.shooting=false
	# Derive aim from the target in the shooter's frame, independently of display.
	var s: Vector3=Vector3(wing.shot_start.x,wing.shot_start.y,wing.shot_start.z)
	var local_target: Vector4=k.boost(wing.shot_end,s.normalized(),-k.distance(k.origin(),wing.shot_start))
	wing.shot_angle=atan2(local_target.z,local_target.x)
	wing.fire(); wing.tick_shot(4.0)
	check("metric shot hits selected target",wing.shot_hit)
	wing.shot_angle=-1.2; wing.fire(); wing.tick_shot(4.0)
	check("different direction misses target",not wing.shot_hit)
	wing.leave()
	check("return restores entry and carried point",wing.current==-1 and wing.point.get_instance_id()==identity)
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["scope"]="Real museum installation, native renders, synthetic desktop/hand controls and metric assertions. No physical headset acceptance claim."
	marker.queue_free()
	completed=true

func finish() -> void:
	check("probe reached every final assertion",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("NONEUCLIDEAN WING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
