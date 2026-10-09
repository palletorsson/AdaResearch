extends "res://tools/probes/transformation_encounters.gd"
const EVENT=preload("res://addons/godot-xr-tools/events/pointer_event.gd")

func press(button: Node3D, pointer: Node3D) -> void:
	var area=button.get_node("InteractableAreaButton")
	EVENT.pressed(pointer,area,area.global_position)
	EVENT.released(pointer,area,area.global_position)

func landing_checks() -> void:
	museum.set_process(true);museum.set_physics_process(true)
	var portal=museum.get("_portal_stream")
	while portal.busy:await process_frame
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/force_halls/curation.json"))
	var pointer=Node3D.new();root.add_child(pointer)
	for i in plan.halls.size():
		var row: Dictionary=plan.halls[i]
		hall=portal._current.node
		var display=find_scene("/hall_display.gd")
		check("arrives at "+row.map,portal._current.map==row.map)
		check("hall has two teleport buttons",display!=null and display.buttons.has("NEXT") and display.buttons.has("PREVIOUS"))
		check("arrival floor supported",portal._arrival_supported())
		if display==null:break
		var player: CharacterBody3D=museum.get("_player")
		player.global_position=display.to_global(Vector3(2.1,0.05,1.9));player.velocity=Vector3.ZERO
		await tick()
		if i==0:
			press(display.buttons.PREVIOUS,pointer)
			check("first visit does not invent a previous room",not portal.busy)
		if i<plan.halls.size()-1:
			press(display.buttons.NEXT,pointer)
			check("pointer button starts a supported teleport",portal.busy)
			check("repeated press cannot start another crossing",not display.travel(1))
			var start=Time.get_ticks_msec()
			while portal.busy and Time.get_ticks_msec()-start<15000:await process_frame
			check("teleport finishes",not portal.busy)
			if portal.busy:break
	var last=find_scene("/hall_display.gd")
	var player: CharacterBody3D=museum.get("_player")
	player.global_position=last.to_global(Vector3(2.1,0.05,1.9));await tick()
	# The same area supports physical XR hand entry, without a second navigation path.
	last.buttons.PREVIOUS.get_node("InteractableAreaButton")._on_button_entered(pointer)
	check("hand contact starts the previous-hall teleport",portal.busy)
	var start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<15000:await process_frame
	check("returns to arena",not portal.busy and portal._current.map=="VFM_08_Arena")
	check("return is supported",portal._arrival_supported())
	await xr_crossing(portal,pointer)
	pointer.queue_free()

func xr_crossing(portal: Node3D, pointer: Node3D) -> void:
	# Reuse the real XRTools body and tracked head offset for one complete crossing.
	hall=portal._current.node
	var display=find_scene("/hall_display.gd")
	var rig=XROrigin3D.new();rig.name="TeleportTestOrigin";rig.current=true
	var head=XRCamera3D.new();head.name="Camera";head.position=Vector3(0.6,1.7,-0.4);rig.add_child(head)
	var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	body.player_calibrate_height=false;body.eye_forward_offset=0.0;rig.add_child(body)
	var hand=XRController3D.new();rig.add_child(hand);root.add_child(rig)
	await tick();body.set_physics_process(false)
	var pose: Transform3D=body.global_transform;pose.origin=display.to_global(Vector3(2.1,0.05,1.9));body.teleport(pose)
	museum.set("_vr",true);museum.set("_vr_cam",head)
	var tracked=head.position
	var teleports=[]
	body.player_teleported.connect(func(delta):teleports.append(delta))
	display.buttons.NEXT.get_node("InteractableAreaButton")._on_button_entered(hand)
	check("XR hand contact starts a real rig crossing",portal.busy)
	var start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<15000:await process_frame
	check("XR body arrives in capability court",not portal.busy and portal._current.map=="Vectors_Act5_ForceAsPlace")
	check("actual XR body teleport API was used",teleports.size()>=2)
	check("tracked head offset is retained",head.position.is_equal_approx(tracked))
	check("XR feet land on the supported arrival",body.global_position.distance_to(portal._arrival)<0.15 and portal._arrival_supported())
	check("teleport clears travel velocity",body.velocity.is_zero_approx())
	hall=portal._current.node
	var court=find_scene("/force_capability_lab.gd")
	pose.origin=court.to_global(Vector3(0,0.05,-8));body.teleport(pose)
	press(court.buttons.VISOR,pointer)
	check("court button equips the actual museum XR visitor",court.visor.worn and court.visor.body==body)
	var overlay: Node=court.visor.overlay
	display=find_scene("/hall_display.gd");press(display.buttons.PREVIOUS,pointer)
	start=Time.get_ticks_msec()
	while portal.busy and Time.get_ticks_msec()-start<15000:await process_frame
	await tick()
	check("leaving the court removes the worn overlay",not is_instance_valid(overlay))
	check("XR return reaches arena",not portal.busy and portal._current.map=="VFM_08_Arena")
	museum.set("_vr",false);museum.set("_vr_cam",null);rig.queue_free()

func finish() -> void:
	var result={"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Canonical Forces halls, real XRTools pointer events through the buttons, one hand-contact callback return, supported landings. Supplied inputs; physical headset untested."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCES TELEPORT BUTTONS ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
