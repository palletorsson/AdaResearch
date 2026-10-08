extends "res://commons/testing/probe_physical_console_halls.gd"
## Real museum placement; audio remains production code with Dummy output.
func run() -> void:
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder=spec.run; report.room="Point_One"
	report.scope="Actual museum, production radio, static clearance and ray tests. No headset or listening validation."
	museum=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","primitives"); museum.set("start_map","Point_One")
	museum.set("plan_file",folder+"em_plan.json")
	root.add_child(museum)
	var started:=Time.get_ticks_msec()
	while not museum.get("_museum_core_ready") and Time.get_ticks_msec()-started<60000: await process_frame
	museum.set("_lazy_pending",0); museum.set_process(false); museum.set_physics_process(false)
	museum.call("flush_stamps"); await create_timer(1).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and child.get_meta("em_map","")=="Point_One":hall=child;break
	check(hall!=null,"Point_One built from the current map")
	if hall==null:finish();return
	origin=hall.global_position
	var radios: Array[Node3D]=[]
	for entry in museum.get("_edit_records"):
		if entry.get("seg")==hall and entry.get("token")=="SoundscapeRadioRack" and entry.node.get_script()==load("res://commons/audio/rack_configs/SoundscapeRadioRack.gd"):
			artifact=entry.node
			if not radios.has(artifact):radios.append(artifact)
	report.radio_instances=radios.map(func(node):return {"path":str(node.get_path()),"id":node.get_instance_id(),"position":arr(node.global_position)})
	check(radios.size()==1,"Exactly one live radio in Point_One")
	if not is_instance_valid(artifact):finish();return
	walker=museum.get("_player")
	if walker:walker.set_physics_process(false)
	var front:=artifact.global_basis.z.normalized(); front.y=0; front=front.normalized()
	check(front.dot(Vector3.FORWARD)>.99,"Radio faces the minus-Z approach")
	feet=artifact.global_position+front*.78
	var floor_hit:=floor_at(feet)
	check(not floor_hit.is_empty(),"Standing position has a floor")
	if floor_hit.is_empty():finish();return
	feet.y=floor_hit.position.y
	report.artifact={"position":arr(artifact.global_position-origin),"scale":arr(artifact.global_basis.get_scale())}
	report.feet=arr(feet-origin)
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=CapsuleShape3D.new();query.shape.radius=.22;query.shape.height=1.7
	query.collision_mask=1;query.transform.origin=feet+Vector3.UP*.87
	if walker:query.exclude=[walker.get_rid()]
	var obstacles:=museum.get_world_3d().direct_space_state.intersect_shape(query)
	report.obstacles=obstacles.map(func(hit):return str(hit.collider.get_path()))
	check(obstacles.is_empty(),"Standing capsule clears plinth and neighboring geometry")
	query.transform.origin=feet+front+Vector3.UP*.87;query.motion=-front
	var motion:=museum.get_world_3d().direct_space_state.cast_motion(query)
	var level:=true
	for i in 6:
		var hit:=floor_at(feet+front*float(i)/5)
		level=level and not hit.is_empty() and absf(hit.get("position",Vector3(0,-999,0)).y-feet.y)<.05
	report.approach={"level":level,"clear_fraction":motion[0]}
	check(level and motion[0]>.99,"Last metre of approach is supported and clear")
	for control in [artifact.tuning_control,artifact.volume_control]:
		for handle in control.hinge.find_children("InteractableHandle","RigidBody3D",true,false):
			inspect_target(control,handle.global_position,str(control.name)+" "+str(handle.get_parent().name),control)
		var handle: Node3D=control.hinge.get_node("Handles/Handle1/InteractableHandle")
		var grabber:=TestGrabber.new();root.add_child(grabber)
		grabber.global_transform=handle.global_transform;grabber.held=handle;handle.pick_up(grabber)
		var rest: Vector3=control.hinge.to_local(handle.handle_origin.global_position)
		var target:=40.0 if control==artifact.tuning_control else 60.0
		grabber.global_position=control.hinge.get_parent().to_global(Basis(Vector3.RIGHT,deg_to_rad(target))*rest)
		for i in 6:await process_frame;await physics_frame
		check(absf(control.get_angle_degrees()-target)<.08,str(control.name)+" real pickup operates under map rotation")
		grabber.drop_object();grabber.queue_free()
	check(artifact.current_station==1,"Tuning reaches station two in the museum")
	check(absf(artifact.target_volume_db-remap(60,-135,135,-40,0))<.01,"Volume reading follows the museum wheel")
	camera=Camera3D.new();root.add_child(camera);camera.current=true
	if walker:walker.global_position=feet
	museum.call("_cull_artifacts")
	camera.global_position=feet+Vector3.UP*1.65;camera.fov=72;camera.look_at(artifact.global_position)
	await capture("radio-operating")
	camera.global_position=feet+front*1.7+Vector3.UP*1.65;camera.fov=80;camera.look_at(artifact.global_position-Vector3.UP*.2)
	await capture("radio-approach")
	finish()
