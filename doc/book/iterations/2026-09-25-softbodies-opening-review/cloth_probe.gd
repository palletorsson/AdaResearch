extends "res://tools/probes/transformation_encounters.gd"
var desk:Node3D
var cloth:Node3D
var complete:=false
func positions(sb:SoftBody3D) -> Array:
	var out:Array=[]
	for i in sb.mesh.surface_get_array_len(0):out.append(PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),i))
	return out
func pinned(sb:SoftBody3D) -> Array:
	var out:Array=[]
	for i in sb.mesh.surface_get_array_len(0):
		if sb.is_point_pinned(i):out.append(i)
	return out
func delta_max(a:Array,b:Array,ids:Array=[]) -> float:
	var result:=0.0
	if ids.is_empty():ids=range(a.size())
	for i in ids:result=maxf(result,a[i].distance_to(b[i]))
	return result
func press(id:String) -> void:
	var area:Node3D=desk.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.2).timeout
func shot(name:String) -> void:
	await snapshot(name,cloth.to_global(Vector3(2.5,1.8,6)),cloth.to_global(Vector3(0,1.8,0)),52)
func landing_checks() -> void:
	desk=find_scene("/soft_workshop.gd");cloth=find_scene("/cloth_straps.gd")
	check("live hall places cloth and its desk",desk!=null and cloth!=null)
	if desk==null or cloth==null:return
	var started:=Time.get_ticks_msec()
	while not desk.ready_for_input and Time.get_ticks_msec()-started<20000:await process_frame
	check("desk bound to actual cloth and all seven controls",desk.ready_for_input and desk.model==cloth and desk.buttons.size()==7 and desk.buttons.has("SUPPORT"))
	if not desk.ready_for_input:return
	var strips:Array=desk._bodies(cloth)
	check("eight active strips",strips.size()==8)
	var sb:SoftBody3D=strips[0]
	var pins:=pinned(sb)
	check("each strip initially pins eight of 112 points",strips.all(func(b):return pinned(b).size()==8 and b.mesh.surface_get_array_len(0)==112))
	var a:=positions(sb);await create_timer(1.0).timeout;var b:=positions(sb)
	observations["initial_full_cloth_motion_1s_m"]=delta_max(a,b)
	observations["initial_pinned_motion_1s_m"]=delta_max(a,b,pins)
	await shot("gantry")
	a=positions(sb)
	await press("SUPPORT")
	check("first actual SUPPORT press removes the frame",cloth.suspension=="none" and cloth.get_node_or_null("Frame")==null)
	b=positions(sb)
	check("same cloth nodes and pinned set survive",desk._bodies(cloth)[0]==sb and pinned(sb)==pins)
	check("pinned points remain fixed when frame removed",delta_max(a,b,pins)<0.001)
	observations["frame_removed_all_points_motion_m"]=delta_max(a,b)
	await shot("no-frame")
	for rig in ["hoop","mast","wall","gantry"]:
		await press("SUPPORT")
		check("SUPPORT callback reaches "+rig,cloth.suspension==rig and pinned(sb)==pins)
	check("console readout reflects the support",desk.readout.text.contains("gantry"))
	await press("SUPPORT")
	a=positions(sb);await press("PINS")
	check("PINS callback changes eight to two per strip",strips.all(func(s):return pinned(s).size()==2))
	await create_timer(1.5).timeout
	b=positions(sb)
	var middle_motion:=0.0
	for i in pins:
		if not sb.is_point_pinned(i):middle_motion=maxf(middle_motion,a[i].distance_to(b[i]))
	observations["newly_unpinned_top_points_motion_m"]=middle_motion
	check("formerly pinned top edge actually moves",middle_motion>0.0001)
	await shot("corners")
	await press("RELEASE")
	check("RELEASE callback leaves zero pins",strips.all(func(s):return pinned(s).is_empty()))
	await create_timer(0.7).timeout;await shot("released")
	await press("REBUILD")
	started=Time.get_ticks_msec()
	while desk.busy and Time.get_ticks_msec()-started<6000:await process_frame
	check("REBUILD restores eight top-row pins",desk._bodies(cloth).all(func(s):return pinned(s).size()==8))
	await snapshot("desk",desk.to_global(Vector3(0,1.8,3.9)),desk.to_global(Vector3(0,1.1,1.85)),52)
	for path in ["commons/artifacts/timing_machines/soft_workshop.gd","commons/artifacts/timing_machines/soft_workshop.json","algorithms/softbodies/cloth_straps/cloth_straps.gd"]:observations[path]=FileAccess.get_sha256("res://"+path)
	var rebuilt:Array=desk._bodies(cloth)
	await press("STIFFNESS")
	check("STIFFNESS after REBUILD retains the full top row",rebuilt.all(func(s):return pinned(s).size()==8 and is_equal_approx(s.linear_stiffness,0.1)))
	var falls:Node3D=desk.other
	check("falling comparison starts with narrow rails",falls!=null and falls.landing=="rail" and is_equal_approx(falls.RAIL_T,0.14))
	if falls!=null:
		await create_timer(12.5).timeout
		await snapshot("rail",falls.to_global(Vector3(3,1.7,3.5)),falls.to_global(Vector3(0,0.65,0)),58)
		await press("LANDING")
		check("LANDING callback chooses pan and starts fresh falls",falls.landing=="pan" and falls.stopped_states.all(func(x):return not x))
		await create_timer(12.5).timeout
		await snapshot("pan",falls.to_global(Vector3(3,1.7,3.5)),falls.to_global(Vector3(0,0.65,0)),58)
	complete=true
func finish() -> void:
	check("review run completes",complete)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"observations":observations,"failures":failures,"passed":failures.is_empty(),"scope":"Actual isolated museum, synthetic pointer events through the existing push-button path. Sampled solver vertices and fixed-camera native captures. No physical reach, walking or headset test."},"  "))
	print("CLOTH PILOT REVIEW ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
