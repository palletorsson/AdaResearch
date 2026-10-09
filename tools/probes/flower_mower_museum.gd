extends "res://tools/probes/forces_layout.gd"
func landing_checks() -> void:
	await super.landing_checks()
	var mower=find_scene("/force_mower.gd")
	check("flower mower loaded from the museum placement",mower!=null and mower.garden_mode)
	if mower==null or not mower.garden_mode:return
	var g=mower.garden
	var deadline:=Time.get_ticks_msec()+10000
	while not g.ready_to_push and Time.get_ticks_msec()<deadline:await process_frame
	check("large lawn ready inside this hall",g.ready_to_push and g.lawn_width==20 and g.lawn_length==28)
	check("mower keeps human scale",mower.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("mower faces forward into its garden",mower.global_basis.x.dot(Vector3.BACK)>0.99)
	check("plot has museum floor at all corners",not floor_at(g.lawn.to_global(Vector3(-13,0,-9))).is_empty() and not floor_at(g.lawn.to_global(Vector3(13,0,9))).is_empty())
	camera.set_cull_mask_value(19,false)
	await snapshot("garden-before",g.lawn.to_global(Vector3(-19,10,-13)),g.lawn.to_global(Vector3(1,0.3,0)),66)
	await snapshot("mower-handle",mower.to_global(Vector3(-3.1,1.8,-1.7)),mower.to_global(Vector3(-0.3,0.65,0)),57)
	var rig:=XROrigin3D.new();rig.current=true
	var head:=XRCamera3D.new();head.name="Camera";head.position.y=1.7;rig.add_child(head)
	var hand:=XRController3D.new();rig.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	root.add_child(rig);await tick();hand.global_position=g.anchor();g.handle.pick_up(pickup)
	check("museum handle accepts real XRTools pickup",g.handle.is_picked_up())
	for i in range(540):
		var steer:=0.0
		if i>=180 and i<290:steer=0.14
		elif i>=330 and i<440:steer=-0.14
		hand.global_position=g.anchor()+mower.global_basis.x*0.36+mower.global_basis.z*steer
		await physics_frame
	g.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await create_timer(1.2).timeout
	check("actual museum drive leaves a lasting flower trail",g.cut_count>50 and g.flower_count>15)
	check("drive does measurable model work",g.work>100 and g.distance>5)
	observations["garden"]={"size_m":[g.lawn_width,g.lawn_length],"cells":g.points.size(),"cut_cells":g.cut_count,"flowers":g.flower_count,"path_m":g.distance,"model_work_j":g.work,"capture":"Production museum and Jolt mower; supplied XR hand motion; no geometry painted by the probe."}
	await snapshot("garden-after",g.lawn.to_global(Vector3(-19,12,-13)),g.lawn.to_global(Vector3(1,0.3,0)),66)
	var sample:=Vector3.ZERO
	for i in range(g.cut.size()):
		if g.cut[i]!=0 and i%3==0:sample=g.lawn.to_global(g.points[i]);break
	await snapshot("flowers-in-the-cut",sample+Vector3(-1.8,1.45,-1.7),sample+Vector3(0,0.2,1.1),58)
	rig.queue_free()
