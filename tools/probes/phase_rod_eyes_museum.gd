extends "res://tools/probes/forces_layout.gd"
## Exercise actual museum camera selection, moving tips and gaze in world space.

func gaze_alignment(e: Node3D, target: Vector3) -> float:
	var lowest=1.0
	for eye in e.eyes:
		var direction=target-eye.global_position
		if direction.length_squared()<0.000001:continue
		lowest=minf(lowest,(-eye.global_basis.z).normalized().dot(direction.normalized()))
	return lowest

func landing_checks() -> void:
	await super.landing_checks()
	camera.set_cull_mask_value(19,false)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	var e=find_scene("/phase_rod_array.gd")
	check("Twenty eyes replace the twenty moving tip caps",e!=null and e.eyes.size()==20)
	if e==null:return
	var walker: Node3D=museum.get("_player")
	var head: Camera3D=museum.get("_cam")
	var first_tip: Vector3=e.eyes[0].global_position
	var lowest=1.0
	e.act("WAVE")
	for at in [Vector3(-4,0,4),Vector3(4,0,4),Vector3(0,0,-5),Vector3(0,5,0)]:
		walker.global_position=e.to_global(at)
		await process_frame # The signal precedes Node._process; let gaze update.
		for i in range(16):
			await process_frame
			lowest=minf(lowest,gaze_alignment(e,head.global_position))
	check("Every moving eye faces visitor from both sides, behind and above",lowest>0.999)
	check("Eyes select actual visitor rather than detached capture camera",e._gaze_camera()==head)
	check("Phase motion still carries the eyes around the rods",first_tip.distance_to(e.eyes[0].global_position)>0.1)
	var attached=true
	for eye in e.eyes:attached=attached and eye.position.is_equal_approx(Vector3(0,0.58,0))
	check("Tracking retains attachment to every moving tip",attached)
	var rig=XROrigin3D.new();root.add_child(rig)
	var xr=XRCamera3D.new();rig.add_child(xr);xr.current=true
	var xr_lowest=1.0
	for at in [Vector3(-2,1.6,3),Vector3(2,1.8,3),Vector3(0,2.5,-3)]:
		xr.global_position=e.to_global(at)
		await process_frame;await process_frame
		xr_lowest=minf(xr_lowest,gaze_alignment(e,xr.global_position))
	check("Active tracked XR camera takes priority over desktop walker",e._gaze_camera()==xr and xr_lowest>0.999)
	xr.global_position=e.eyes[0].global_position
	e.set_process(false);e._update_eyes()
	check("Coincident eye/head position leaves a finite transform",e.eyes[0].global_transform.is_finite())
	e.set_process(true);camera.current=true;rig.queue_free();await process_frame
	observations.eyes={"count":e.eyes.size(),"desktop_min_dot":lowest,"xr_min_dot":xr_lowest,"scope":"Actual production artifact and cameras; supplied head poses, physical headset untested."}
	walker.global_position=e.to_global(Vector3(3.8,0,4.9))
	e.act("WAVE")
	await snapshot("twenty-eyes",head.global_position,e.to_global(Vector3(0,1.5,-0.1)),68)
	walker.global_position=e.to_global(Vector3(0.7,0,2.8))
	await snapshot("eyes-follow-you",head.global_position,e.to_global(Vector3(0,1.55,0.3)),68)
