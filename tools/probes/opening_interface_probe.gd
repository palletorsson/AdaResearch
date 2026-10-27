extends "res://tools/probes/void_charger_probe.gd"
## Original inputs/data in the real tower, with architectural mount contacts.
const Hardware := preload("res://commons/void/opening_interface_hardware.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1); return
	for use_xr in [false,true]:
		await opening(use_xr)
	await coordinate_checks()
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native tower: desktop mouse and simulated XR ray/trigger; actual XRTools point pickup. No physical headset test."
	},"\t"))
	print("OPENING_HARDWARE_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func opening(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	game.atmosphere.animate_sky=false
	game.atmosphere.set_sky_time(180)
	var content: Node3D=game.building.content
	var counter: Node3D=content.exhibits["0/clock"].get_node("Artifact")
	var label: Label3D=counter.label
	var before: String=label.text
	await frames(8)
	check(tag+"original rooftop counter still advances",counter.label==label and label.text!=before)
	var hardware: Node3D=counter.get_node("ArchitecturalHardware")
	for key in ["FloorContactLeft","FloorContactRight"]:
		var at: Vector3=hardware.get_node(key).global_position
		var contact:=ray(at+Vector3.UP*.12,at-Vector3.UP*.12)
		check(tag+"counter "+key+" meets roof",not contact.is_empty() and contact.position.distance_to(at)<.005)
	check(tag+"rooftop has floor supports, no invented ceiling mount",hardware.has_node("FloorUpright") and not hardware.has_node("SlabContact"))
	check(tag+"counter connects to overhead grid",hardware.get_node("HardwareSupply").has_meta("grid_socket"))
	var count:=counter.get_child_count()
	Hardware.attach(counter,"frame_counter_display")
	check(tag+"reapplying retrofit is idempotent",counter.get_child_count()==count)
	var original: Node3D=load("res://commons/visualaid/frame_counter/frame_counter_display.tscn").instantiate()
	root.add_child(original)
	check(tag+"museum counter keeps original casing",not original.has_node("ArchitecturalHardware") and original.get_node("Console/Casing").material_override.albedo_color.r<.1)
	original.queue_free()
	if not xr:
		await photograph("roof-counter.png",counter.global_position+Vector3(3.4,1.2,6.5),counter.global_position+Vector3(0,.3,0))
	game.place_player(game.spawn_for(1)); await frames(35)
	var light_switch: Node3D=content.props["1/point-light-switch"].get_node("Prefab")
	check(tag+"original rectangular switch retained",light_switch.lever.mesh is BoxMesh and light_switch.button.get_script().resource_path.ends_with("interactable_area_button_pointer.gd"))
	check(tag+"switch cabinet is connected to the grid",light_switch.has_node("SwitchCabinet") and light_switch.get_node("HardwareSupply").has_meta("grid_socket"))
	game.place_player(light_switch.to_global(Vector3(0,.06,1.0))); await frames(15)
	await switch_input(light_switch.button,true)
	await switch_input(light_switch.button,false)
	check(tag+"real input switches Point One lights off",not light_switch.enabled and not content.roots[1].get_meta("point_lights_enabled",true))
	var rod_lights: Array=content.roots[1].find_children("*","Node3D",true,false).filter(func(n):return n.is_in_group("void_point_rod_light"))
	check(tag+"the existing rod lamps switch off",not rod_lights.is_empty() and rod_lights.all(func(n):return not n.beam.visible))
	await switch_input(light_switch.button,true)
	await switch_input(light_switch.button,false)
	check(tag+"real input switches Point One lights on",light_switch.enabled and content.roots[1].get_meta("point_lights_enabled",false))
	if not xr:
		await photograph("point-one-switch.png",light_switch.to_global(Vector3(.8,1.75,1.8)),light_switch.to_global(Vector3(0,1.45,0)))
	game.place_player(game.spawn_for(2)); await frames(45)
	for key in ["world","local"]:
		var card: Node3D=content.exhibits["2/"+key].get_node("Artifact")
		var mount: Node3D=card.get_node("ArchitecturalHardware")
		var at: Vector3=mount.get_node("SlabContact").global_position
		var contact:=ray(at-Vector3.UP*.15,at+Vector3.UP*.15)
		check(tag+key+" hanger touches the actual slab",not contact.is_empty() and contact.position.distance_to(at)<.005)
		check(tag+key+" retains live original measuring card",card.get_node("Value")==card._label and card._caption.text==key.to_upper() and not card._label.text.contains("—"))
		check(tag+key+" feed stays scoped to Coordinates",card.readout_channel=="void_coordinates" and card.space==key)
		if not xr:
			await photograph(key+"-display.png",card.to_global(Vector3(2,1.1,4.1)),card.to_global(Vector3(0,.9,0)))
	var unmounted: Node3D=load("res://commons/primitives/point/coordinate_readout.tscn").instantiate()
	root.add_child(unmounted)
	check(tag+"museum coordinate card remains unmounted",not unmounted.has_node("ArchitecturalHardware"))
	unmounted.queue_free()
	game.queue_free();await frames(5)
	if xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)

func switch_input(port: Node3D, pressed: bool) -> void:
	if xr:
		var origin: Node3D=game.get_node("XROrigin3D")
		for i in range(15):
			var from: Vector3=game.camera.global_position+Vector3(.1,-.25,-.1)
			var pose:=Transform3D(Basis.IDENTITY,origin.to_local(from)).looking_at(origin.to_local(port.global_position),Vector3.UP)
			right.set_pose("aim",pose,Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(1)
		if pressed: check("XR ray reaches original switch",game.pointers[1].last_target==port)
		right.set_input("trigger_click",pressed)
	else:
		game.camera.look_at(port.global_position)
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		await frames(6)
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		Input.parse_input_event(event)
	await frames(8)

func photograph(filename: String, at: Vector3, target: Vector3, mask: int=1048575) -> void:
	var body_visible: bool=game.body.visible
	game.body.hide()
	await super.photograph(filename,at,target,mask)
	game.body.visible=body_visible
