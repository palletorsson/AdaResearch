extends "res://tools/probes/lines_museum_return_probe.gd"
## Native floor, original pickup systems and pointer events; no substitute scene.
const Hardware := preload("res://commons/void/lines_interface_hardware.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1); return
	for mode in ([false] if "--diagnose" in OS.get_cmdline_user_args() else [false,true]): await exercise_hardware(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native tower. Desktop pickup/hold/drop path and real mouse reset; simulated XR grip and trigger. Original scripts, geometry, rendering and physics. No physical headset test."
	},"\t"))
	print("LINES_HARDWARE_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func exercise_hardware(use_xr: bool) -> void:
	await start(use_xr)
	mode_name="XR: " if xr else "Desktop: "
	game.checkpoint=3
	game.place_player(Vector3(0,-17.94,6.9))
	await frames(50)
	var content: Node3D=game.building.content
	var deadline:=Time.get_ticks_msec()+20000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline: await frames(2)
	check(mode_name+"floor loaded",content.pending.is_empty())
	game.atmosphere.animate_sky=false
	game.atmosphere.set_sky_time(180)
	var setting: Node3D=content.exhibits["3/setting_out"].get_node("Artifact")
	var gate: Node3D=setting.get_node("MeasurementRoom")
	var plan: Node3D=setting.get_node("FloorPlanTable")
	var ruler: Node3D=setting.get_node("FullSizeRuler")
	var gate_h: Node3D=gate.get_node("ArchitecturalHardware")
	var contact: Vector3=gate_h.get_node("WallContact").global_position
	var hit:=ray(contact+Vector3(0,0,.08),contact-Vector3(0,0,.08))
	check(mode_name+"gate cabinet meets the original white wall",not hit.is_empty() and hit.position.distance_to(contact)<.005)
	check(mode_name+"gate starts closed",not gate.unlocked and not ray(gate.to_global(Vector3(0,1,-3)),gate.to_global(Vector3(0,1,-3.7))).is_empty())
	if not xr:
		await photograph("gate-closed.png",gate.to_global(Vector3(-1.9,1.7,.4)),gate.to_global(Vector3(.6,1.75,-3.3)),78)
	game.place_player(gate.to_global(Vector3(0,.06,2)))
	await frames(12)
	await grab(gate.point_b)
	await carry(gate.point_a.global_position+Vector3(.15,0,0))
	await frames(30)
	check(mode_name+"real pickup still joins points to unlock",gate.unlocked)
	await release()
	await frames(80)
	check(mode_name+"door opens and mounted original label updates",gate.gate.position.y>2.75 and gate.readout.text.begins_with("LINE / "))
	check(mode_name+"open doorway collision clears",ray(gate.to_global(Vector3(0,1,-3)),gate.to_global(Vector3(0,1,-3.7))).is_empty())
	if not xr:
		await photograph("gate-open.png",gate.to_global(Vector3(-1.9,1.7,.4)),gate.to_global(Vector3(.6,1.75,-3.3)),78)
	for tool in [plan,ruler]:
		var title: String="1:10" if tool.plan else "1:1"
		var label: Label3D=tool.readout
		var fixed: Transform3D=label.transform
		var mount: Node3D=tool.get_node("ArchitecturalHardware")
		contact=mount.get_node("StructuralSupport/SlabContact").global_position
		hit=ray(contact-Vector3.UP*.15,contact+Vector3.UP*.15)
		check(mode_name+title+" mast touches actual ceiling slab",not hit.is_empty() and hit.position.distance_to(contact)<.005)
		check(mode_name+title+" readout is above eye level",label.global_position.y-content.roots[3].global_position.y>2.25)
		check(mode_name+title+" original ruler mesh and ticks remain",tool.ruler.get_script().resource_path.ends_with("survey_ruler.gd") and tool.ruler.get_child_count()>0)
		game.place_player(tool.to_global(Vector3(0,.06,2)))
		await frames(12)
		await grab(tool.point_b)
		await carry(tool.point_a.global_position+Vector3(.8,.6,.4))
		var span: float=tool.point_a.global_position.distance_to(tool.point_b.global_position)
		check(mode_name+title+" held endpoint measures all three axes",span>.9 and is_equal_approx(tool.measured_length,span*tool.scale_factor))
		check(mode_name+title+" original readout remains fixed and live",tool.readout==label and label.transform.is_equal_approx(fixed) and label.text.contains("%.2f"%tool.measured_length))
		check(mode_name+title+" held line still lights the workspace",tool.glow.visible)
		await release()
		check(mode_name+title+" released line retains the new length",is_equal_approx(tool.measured_length,span*tool.scale_factor) and not tool.glow.visible)
	if not xr:
		await photograph("measuring-bench.png",plan.to_global(Vector3(3.5,1.8,3.1)),plan.to_global(Vector3(0,1.5,-.6)),78)
		await photograph("live-rulers.png",plan.to_global(Vector3(-3.3,1.8,2.8)),plan.to_global(Vector3(0,1.6,-.8)),78)
	var box: Node3D=gate
	game.place_player(box.to_global(Vector3(0,.06,-.6)))
	await frames(12)
	await grab(box.point_b)
	await carry(box.point_a.global_position+Vector3(0,.8,.6))
	await release()
	check(mode_name+"original black-room readout measures the moved point",box.measure_readout.text=="1.00 m")
	game.place_player(box.to_global(Vector3(1.3,.06,5.4)))
	if not xr: game.camera.position=Vector3(0,1.65,0)
	await frames(12)
	await reset_input(box.reset_button,true)
	await reset_input(box.reset_button,false)
	check(mode_name+"original rectangular reset works through pointer input",box.point_a.position.is_equal_approx(box.START_A) and box.point_b.position.is_equal_approx(box.START_B))
	if not xr:
		await photograph("wall-instrument.png",box.to_global(Vector3(-.8,1.65,-1.25)),box.to_global(Vector3(.45,1.65,1.9)),85)
	for id in ["museum-point_lines-53-24","museum-point_lines-56-9","museum-point_lines-58-6","museum-point_lines-60-2"]:
		var source: Node3D=content.exhibits["3/"+id].get_node("Artifact")
		check(mode_name+id+" original apparatus connects to grid",source.has_node("ArchitecturalHardware/HardwareSupply") and source.get_node("ArchitecturalHardware/HardwareSupply").has_meta("grid_socket"))
	var sketch: Node3D=content.exhibits["3/museum-point_lines-53-24"].get_node("Artifact")
	var elapsed: float=sketch.elapsed()
	await frames(15)
	check(mode_name+"sketch retains its live animated viewport",sketch.elapsed()>elapsed and sketch._screen.material_override.albedo_texture==sketch._viewport.get_texture())
	var workshop: Node3D=content.exhibits["3/museum-point_lines-58-6"].get_node("Artifact")
	check(mode_name+"four original film studies retained",workshop.studies.size()==4 and workshop.studies.all(func(s):return s.screen.material_override is ShaderMaterial and is_instance_valid(s.camera)))
	var science: Node3D=content.exhibits["3/museum-point_lines-56-9"].get_node("Artifact")
	check(mode_name+"science screen retains its live canvas",science._viewport!=null and science._canvas!=null and science._screen_mesh.material_override.albedo_texture==science._viewport.get_texture())
	var witness: Node3D=content.exhibits["3/museum-point_lines-60-2"].get_node("Artifact")
	var value: float=witness.measure()
	check(mode_name+"original measuring rule and witness remain functional",value>0 and is_equal_approx(value,witness.reading()) and witness._rule.has_method("is_picked_up"))
	var consequence: Node3D=content.exhibits["3/consequences"].get_node("Artifact")
	check(mode_name+"charge status remains the original signal-owned label",consequence.health_label.has_node("ArchitecturalHardware") and consequence.health_label.text.begins_with("CHARGE"))
	if not xr:
		await photograph("monitor-bank.png",workshop.to_global(Vector3(2.3,1.8,3.3)),workshop.to_global(Vector3(0,1.1,.5)),75)
		await photograph("witness-ruler.png",witness.to_global(Vector3(1.4,1.65,2.2)),witness.to_global(Vector3(0,1.1,-.2)),75)
	# Only this part moves, and its original endpoints, case and support travel
	# together. New routes must meet the building after a non-cardinal yaw.
	var original_pose: Transform3D=plan.transform
	var config: Dictionary={"interface_style":"architectural","parts":{"FloorPlanTable":{"position":[16,0,-3],"rotation":[0,37,0]}}}
	setting.apply_grid_config(config)
	await frames(8)
	var supply: Node3D=plan.get_node("ArchitecturalHardware/HardwareSupply")
	check(mode_name+"editor yaw keeps conduit aligned to building",supply.global_basis.is_equal_approx(Basis.IDENTITY))
	check(mode_name+"editor movement preserves the original readout",plan.readout.get_parent().name=="InstrumentFace" and plan.get_node("ArchitecturalHardware").get_child_count()==3)
	plan.transform=original_pose
	Hardware.attach(plan,"survey")
	var copy: Node3D=load("res://commons/void/lines_setting_out.tscn").instantiate()
	content.roots[3].add_child(copy)
	copy.position=Vector3(-8,0,-3)
	copy.apply_grid_config({"interface_style":"architectural","only_parts":["FloorPlanTable"],"parts":{"FloorPlanTable":{"position":[0,0,0],"rotation":[0,90,0]}}})
	await frames(5)
	check(mode_name+"editor copy contains one independent mounted instrument",copy.get_child_count()==1 and copy.get_node("FloorPlanTable").point_a!=plan.point_a and copy.get_node("FloorPlanTable").mounted_readout)
	copy.queue_free()
	var unmounted: Node3D=load("res://commons/artifacts/line_black_box/line_black_box.tscn").instantiate()
	root.add_child(unmounted)
	check(mode_name+"museum source stays unchanged",not unmounted.has_node("ArchitecturalHardware") and unmounted.readout.get_parent()==unmounted)
	unmounted.queue_free()
	game.queue_free()
	await frames(10)
	if xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func reset_input(port: Node3D, pressed: bool) -> void:
	if xr:
		var origin: Node3D=game.get_node("XROrigin3D")
		for i in range(15):
			var from: Vector3=game.camera.global_position+Vector3(.1,-.25,-.1)
			var pose:=Transform3D(Basis.IDENTITY,origin.to_local(from)).looking_at(origin.to_local(port.global_position),Vector3.UP)
			right.set_pose("aim",pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(1)
		if pressed: check("XR ray reaches original reset key",game.pointers[1].last_target==port)
		right.set_input("trigger_click",pressed)
	else:
		game.camera.look_at(port.global_position)
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		await frames(6)
		if pressed: check("Desktop ray reaches original reset key",game.body.desktop_pointer._last_target==port)
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		Input.parse_input_event(event)
	await frames(8)

func photograph(filename: String, at: Vector3, target: Vector3, field_of_view := 75.0) -> void:
	if "--diagnose" in OS.get_cmdline_user_args(): return
	game.body.hide()
	game.get_node("CareBody").hide()
	await super.photograph(filename,at,target,field_of_view)
	game.get_node("CareBody").show()
	game.body.show()
