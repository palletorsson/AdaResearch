extends "res://tools/probes/trace_museum_return_probe.gd"
const Hardware := preload("res://commons/void/trace_interface_hardware.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	for mode in ([false] if "--diagnose" in OS.get_cmdline_user_args() else [false,true]):
		await encounters(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native tower, Mobile renderer. Desktop pickup path and mouse presses; simulated XR grip, hand movement and trigger presses. Physical headset not tested. Paint boxes use tracked hands; desktop drawing remains the existing beads, glass and black point."
	},"\t"))
	print("TRACE_HARDWARE_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func picture(file: String, at: Vector3, towards: Vector3) -> void:
	if not xr and not "--diagnose" in OS.get_cmdline_user_args():
		await photograph(file,at,towards)

func photograph(file: String, at: Vector3, towards: Vector3) -> void:
	game.body.hide()
	game.get_node("CareBody").hide()
	await super.photograph(file,at,towards)
	game.get_node("CareBody").show()
	game.body.show()

func finish_room(use_xr: bool) -> void:
	await hardware_contract()
	await super.finish_room(use_xr)

func hardware_contract() -> void:
	var content: Node3D=game.building.content
	var record: Node3D=content.exhibits["4/record"].get_node("Artifact")
	var monitor: Node3D=record.get_node("SamplingMonitor")
	for key in ["Bead10mm","Bead40mm","Bead80mm"]:
		var bead: Node3D=record.get_node(key)
		check(tag+key+" original data surface has a rigid grid connection",
			bead._data_panel.has_node("ArchitecturalHardware/HardwareSupply") and
			bead._data_panel.table==bead._data_table_label)
	var anchor: Node3D=monitor.get_node("ArchitecturalHardware/StructuralSupport/SlabContact")
	check(tag+"sampling monitor mounts exactly to the slab underside",is_equal_approx(anchor.global_position.y,-18-content.building.spec.slab_thickness))
	check(tag+"sampling monitor retains original live viewport and control heights",monitor.screen.material_override.albedo_texture==monitor.viewport.get_texture() and is_equal_approx(monitor.buttons.pause.position.y,.8))
	game.place_player(monitor.to_global(Vector3(0,.06,2)))
	if not xr: game.camera.position=Vector3(0,1.65,0)
	await frames(15)
	var was_running: bool=monitor.stage.running
	await click_control(monitor.buttons.pause)
	check(tag+"sampling pause responds to pointer press",monitor.stage.running!=was_running)
	var previous_mode: int=monitor.stage.mode
	await click_control(monitor.buttons.route)
	check(tag+"sampling mode changes on original rectangular key",monitor.stage.mode!=previous_mode)
	await click_control(monitor.buttons.replay)
	check(tag+"sampling replay keeps recorded movement",monitor.stage.record.positions.size()>40)
	var grid: Node3D=record.get_node("GridReplay/SavedTraceGrid")
	var grid_port: Node3D=grid._data_panel.get_node("AutoPages/InteractableAreaButton")
	game.place_player(Vector3(-13.1,-23.94,3.4))
	if not xr: game.camera.position=Vector3(0,1.65,0)
	await frames(15)
	var auto_before: bool=grid._archive_auto
	await click_control(grid_port)
	check(tag+"Grid auto-page key works through mounted original pointer area",grid._archive_auto!=auto_before)
	check(tag+"Grid panel is cased and connected on the solid west rim",grid._data_panel.has_node("ArchitecturalHardware/HardwareSupply") and is_equal_approx(grid._data_panel.global_position.x,-13.1))
	for id in ["museum-point_trace-21-3","museum-point_trace-21-9","paint-tube","paint-ribbon","paint-beads","paint-grid"]:
		var source: Node3D=content.exhibits["4/"+id].get_node("Artifact")
		check(tag+id+" has rigid supply connected to grid",source.has_node("ArchitecturalHardware/HardwareSupply") and source.get_node("ArchitecturalHardware/HardwareSupply").has_meta("grid_socket"))
	var telemetry: Node3D=content.exhibits["4/museum-point_trace-21-3"].get_node("Artifact")
	for side in ["left","right"]:
		var panel: Node3D=telemetry.get_node("Panel_"+side)
		check(tag+side+" telemetry retains its independent live surface",panel._screen_mesh.material_override.albedo_texture==panel._viewport.get_texture())
	check(tag+"paired hand monitor reaches ceiling",is_equal_approx(telemetry.get_node("ArchitecturalHardware/StructuralSupport/SlabContact").global_position.y,-18-content.building.spec.slab_thickness))
	await picture("hand-displays.png",telemetry.to_global(Vector3(2,0,4)),telemetry.to_global(Vector3(0,.85,0)))
	await paint_contract(content)
	var original_pose: Transform3D=monitor.transform
	record.apply_grid_config({"interface_style":"architectural","parts":{"SamplingMonitor":{"position":[10,0,-8],"rotation":[0,37,0]}}})
	await frames(8)
	check(tag+"editor rotation keeps conduit in building axes",monitor.get_node("ArchitecturalHardware/HardwareSupply").global_basis.is_equal_approx(Basis.IDENTITY))
	check(tag+"editor move preserves original live screen",monitor.screen.material_override.albedo_texture==monitor.viewport.get_texture())
	monitor.transform=original_pose
	Hardware.attach(monitor,"sampling")
	var copy: Node3D=load("res://commons/void/trace_record.tscn").instantiate()
	content.roots[4].add_child(copy)
	copy.apply_grid_config({"interface_style":"architectural","only_parts":["SamplingMonitor"],"parts":{"SamplingMonitor":{"position":[0,0,-4],"rotation":[0,90,0]}}})
	await frames(8)
	check(tag+"editor copy isolates an independent mounted monitor",copy.get_child_count()==1 and copy.get_node("SamplingMonitor").viewport!=monitor.viewport and copy.get_node("SamplingMonitor").has_node("ArchitecturalHardware/HardwareSupply"))
	copy.queue_free()
	var museum: Node3D=load("res://commons/artifacts/concept_monitor/trace_sampling_monitor.tscn").instantiate()
	root.add_child(museum)
	check(tag+"original museum scene remains unmounted",not museum.has_node("ArchitecturalHardware"))
	museum.queue_free()
	await frames(5)

func paint_contract(content: Node3D) -> void:
	for brush in ["tube","ribbon","beads","grid"]:
		var box: Node3D=content.exhibits["4/paint-"+brush].get_node("Artifact")
		game.place_player(box.to_global(Vector3(0,.06,1.4)))
		if not xr: game.camera.position=Vector3(0,1.65,0)
		await frames(10)
		if xr:
			for i in 20:
				hand_at(right,box.to_global(Vector3(-.2+i*.02,.85+i*.035,sin(i*.3)*.16)))
				await frames(3)
			hand_at(right,box.to_global(Vector3(0,1.2,.7)))
			await frames(8)
			check(tag+brush+" mounted box retains hand-drawn geometry",box.mark_count>8 and box._active.is_empty())
		var hit := ray(box.to_global(Vector3(0,1.3,.65)),box.to_global(Vector3(0,1.3,0)))
		check(tag+brush+" supply leaves drawing volume clear",hit.is_empty())
		await click_control(box.get_node("Clear/PushButton/InteractableAreaButton"))
		check(tag+brush+" original Clear key resets the box",box.mark_count==0)
	await picture("paint-controls.png",Vector3(-14.5,-22.4,6.4),Vector3(-16,-22.8,3.5))

func click_control(port: Node3D) -> void:
	for pressed in [true,false]:
		if xr:
			var origin: Node3D=game.get_node("XROrigin3D")
			for i in 15:
				var from: Vector3=game.camera.global_position+Vector3(.1,-.25,-.1)
				var pose:=Transform3D(Basis.IDENTITY,origin.to_local(from)).looking_at(origin.to_local(port.global_position),Vector3.UP)
				right.set_pose("aim",pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
				await frames(1)
			if pressed: check(tag+"ray reaches "+str(port.get_parent().name)+"/"+str(port.name),game.pointers[1].last_target==port)
			right.set_input("trigger_click",pressed)
		else:
			game.camera.look_at(port.global_position)
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
			await frames(6)
			if pressed: check(tag+"ray reaches "+str(port.get_parent().name)+"/"+str(port.name),game.body.desktop_pointer._last_target==port)
			var event:=InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=pressed
			Input.parse_input_event(event)
		await frames(8)
