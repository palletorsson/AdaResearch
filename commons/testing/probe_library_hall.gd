extends "res://commons/testing/probe_physical_console_halls.gd"
func run() -> void:
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder=spec.run;report.room=spec.room
	report.scope="Real Gallery_Furniture map and museum builder, standing clearance and pointer checks. No headset validation."
	museum=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json");museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json");museum.set("plan_file",folder+"em_plan.json")
	museum.set("start_chapter",spec.sequence);museum.set("start_map",spec.room)
	root.add_child(museum)
	var started:=Time.get_ticks_msec()
	while not museum.get("_museum_core_ready") and Time.get_ticks_msec()-started<60000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false)
	museum.call("flush_stamps");await create_timer(1).timeout
	var hall:Node3D
	for child in museum.get_children():
		if child is Node3D and child.get_meta("em_map","")==spec.room:hall=child;break
	check(hall!=null,"Actual Gallery_Furniture hall loaded")
	if hall==null:finish();return
	origin=hall.global_position
	var instances:Array=[]
	for entry in museum.get("_edit_records"):
		if entry.get("seg")==hall and entry.get("token")==spec.token and entry.node.get_script()==load("res://commons/ui/demo/vr_component_demo.gd"):
			artifact=entry.node
			if not instances.has(artifact):instances.append(artifact)
	check(instances.size()==1,"One production component library in the hall")
	if not is_instance_valid(artifact):finish();return
	walker=museum.get("_player")
	if walker:walker.set_physics_process(false)
	var front:=artifact.global_basis.z.normalized();front.y=0;front=front.normalized()
	feet=artifact.global_position+front*.6
	var hit:=floor_at(feet)
	check(not hit.is_empty(),"Operating position is supported")
	if hit.is_empty():finish();return
	feet.y=hit.position.y
	check(absf(artifact.global_position.y-feet.y)<.05,"Floor-mounted library sits at floor level")
	check(artifact.global_basis.get_scale().is_equal_approx(Vector3.ONE),"Controls keep metre scale")
	var capsule:=PhysicsShapeQueryParameters3D.new();capsule.shape=CapsuleShape3D.new();capsule.shape.radius=.22;capsule.shape.height=1.7
	capsule.collision_mask=1;capsule.transform.origin=feet+Vector3.UP*.87
	if walker:capsule.exclude=[walker.get_rid()]
	var obstacles:=museum.get_world_3d().direct_space_state.intersect_shape(capsule)
	report.obstacles=obstacles.map(func(item):return str(item.collider.get_path()))
	check(obstacles.is_empty(),"Standing capsule clears the library and adjacent furniture")
	capsule.transform.origin=feet+front+Vector3.UP*.87;capsule.motion=-front
	var clear:=museum.get_world_3d().direct_space_state.cast_motion(capsule)[0]
	var level:=true
	for i in 6:
		var support:=floor_at(feet+front*float(i)/5)
		level=level and not support.is_empty() and absf(support.get("position",Vector3(0,-999,0)).y-feet.y)<.05
	check(level and clear>.99,"Last metre of approach is supported and clear")
	report.feet=arr(feet-origin);report.library=arr(artifact.global_position-origin)
	if walker:walker.global_position=feet
	museum.call("_cull_artifacts")
	for button in artifact.station.find_children("*","Node3D",true,false):
		if button.get_script()==load("res://commons/interactables/push_button.gd"):
			inspect_target(button,button.get_node("InteractableAreaButton/CollisionShape3D").global_position,str(button.name),button)
	camera=Camera3D.new();root.add_child(camera);camera.current=true
	camera.global_position=feet+Vector3.UP*1.65;camera.fov=75;camera.look_at(artifact.to_global(Vector3(0,1.15,0)))
	await capture("library-operating")
	artifact.show_page(8);await create_timer(.3).timeout
	check(artifact.controls.size()==2,"Both audio faders load in the museum")
	for control in artifact.controls:
		var joint:Node3D=control.get_node("SliderOrigin/InteractableSlider")
		var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
		inspect_target(control,handle.global_position,str(control.name),control)
		var grabber:=TestGrabber.new();root.add_child(grabber);grabber.global_transform=handle.global_transform;grabber.held=handle;handle.pick_up(grabber)
		var rest:Vector3=joint.to_local(handle.handle_origin.global_position)
		var target:float=lerpf(joint.slider_limit_min,joint.slider_limit_max,.8)
		grabber.global_position=joint.get_parent().to_global(rest+Vector3.RIGHT*target)
		for i in 6:await process_frame;await physics_frame
		check(absf(joint.slider_position-target)<.001,str(control.name)+" native grip works in the museum")
		if is_instance_valid(grabber.held):grabber.drop_object()
		grabber.queue_free()
	await capture("library-faders")
	camera.global_position=feet+front*1.5+Vector3.UP*1.65;camera.fov=80;camera.look_at(artifact.to_global(Vector3(0,.85,0)))
	await capture("library-approach")
	finish()
