extends "res://tools/probes/transformation_encounters.gd"
const EVENT=preload("res://addons/godot-xr-tools/events/pointer_event.gd")

func press(button: Node3D, pointer: Node3D) -> void:
	var area=button.get_node("InteractableAreaButton")
	EVENT.pressed(pointer,area,area.global_position)
	EVENT.released(pointer,area,area.global_position)

func save_view(name: String, view: Camera3D) -> void:
	if DisplayServer.get_name()=="headless":return
	view.current=true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+name+".png"))

func landing_checks() -> void:
	var court=find_scene("/force_capability_lab.gd")
	check("real court loaded",court!=null)
	if court==null:return
	var navigator=museum.get("_portal_stream")
	while navigator.busy:await process_frame
	var walker: CharacterBody3D=museum.get("_player")
	var eye: Camera3D=museum.get("_cam")
	var marker=Node3D.new();root.add_child(marker)
	walker.global_position=court.to_global(Vector3(0,0.08,-8))
	walker.velocity=Vector3.ZERO;eye.look_at(court.to_global(Vector3(0,1.5,5)))
	var visor=court.visor
	check("visor starts off",not visor.worn)
	check("visor button faces its approach",court.buttons.VISOR.basis.y.normalized().dot(Vector3.FORWARD)>0.99)
	press(court.buttons.VISOR,marker)
	check("real pointer button wears the display",visor.worn and visor.overlay.get_parent()==eye)
	check("overlay reads the actual visitor",visor.body==walker and visor.overlay.visible)
	walker.velocity=Vector3(3,4,0);visor.update_reading()
	check("velocity comes from the actual body",visor.last_sample.velocity.is_equal_approx(walker.velocity) and visor.channels.velocity.value.text=="5.00")
	check("unheld points produce zero thrust",visor.last_sample.thrust==Vector3.ZERO)
	check("gravity is acceleration not a fabricated force",visor.last_sample.gravity==Vector3(0,-9.8,0))
	var initial: Basis=eye.global_basis
	eye.rotate_y(PI/2);visor.update_reading()
	check("world arrow holds its direction when the head turns",visor.channels.velocity.arrow.global_basis.y.normalized().dot(walker.velocity.normalized())>0.999)
	check("head turn does not change world components",visor.last_sample.velocity==Vector3(3,4,0))
	eye.global_basis=initial;walker.velocity=Vector3.ZERO;visor.update_reading()
	check("zero vector hides its direction",not visor.channels.velocity.arrow.visible)
	court.queue_launch(walker,Vector3(0,6,4));visor.update_reading()
	check("pad is labelled an initial velocity",visor.last_sample.launch_recent and visor.state_line.text.contains("INITIAL VELOCITY"))
	court.release_carry(walker)
	var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new()
	pointer.cam=eye;walker.add_child(pointer);pointer.set_process(false);pointer.set_physics_process(false)
	pointer._grab_held(court.points[0]);eye.rotation.x=PI/2;pointer._try_held_action(true)
	visor.update_reading()
	check("desktop held action feeds the same thrust as movement",visor.last_sample.thrust.y>10.9 and visor.last_sample.thrust==court.thrust_acceleration(walker))
	pointer._try_held_action(false);pointer._drop_held();pointer.queue_free()
	eye.global_basis=initial;visor.update_reading()
	await save_view("body-visor-standing",eye)
	walker.global_position=court.to_global(Vector3(0,0,-15));visor.update_reading()
	check("display hides outside its court",not visor.overlay.visible)
	walker.global_position=court.to_global(Vector3(0,0.08,-8));visor.update_reading()
	check("display returns inside the court",visor.overlay.visible)
	press(court.buttons.VISOR,marker)
	check("second press removes the overlay",not visor.worn and not visor.overlay.visible)
	var key=InputEventKey.new();key.keycode=KEY_F8;key.pressed=true
	court._unhandled_key_input(key)
	check("desktop F8 toggles the same wearable",visor.worn)
	court._unhandled_key_input(key)
	await xr_trial(court)
	await snapshot("visor-dock",court.to_global(Vector3(-0.1,1.75,-12.3)),court.to_global(Vector3(1.8,1.65,-10.8)),61)
	var display=find_scene("/hall_display.gd")
	var b=display.buttons.NEXT
	observations.button_up=xyz(b.basis.y)
	observations.button_position=xyz(b.position)
	observations.cap_position=xyz(display.to_local(b.get_node("Button/ButtonMesh").global_position))
	observations.base_position=xyz(display.to_local(b.get_node("ButtonBase/BaseMesh").global_position))
	observations.cap_colour=str(b.get_node("Button/ButtonMesh").get_surface_override_material(0).albedo_color)
	check("teleport button faces its approach",b.basis.y.normalized().dot(Vector3.FORWARD)>0.99)
	var aim: Vector3=b.get_node("InteractableAreaButton/CollisionShape3D").global_position
	var query=PhysicsRayQueryParameters3D.create(display.to_global(Vector3(b.position.x,1.65,1.8)),aim,1|4|1048576)
	query.collide_with_areas=true
	var hit=hall.get_world_3d().direct_space_state.intersect_ray(query)
	check("teleport pointer reaches the button before the plinth",not hit.is_empty() and b.is_ancestor_of(hit.collider))
	await snapshot("teleport-console",display.to_global(Vector3(2.1,1.7,1.25)),display.to_global(Vector3(2.1,1.2,3)),60)
	marker.queue_free()

func xr_trial(court: Node3D) -> void:
	var rig=XROrigin3D.new();rig.name="BodyVisorXRTest"
	rig.position=court.to_global(Vector3(0,0.2,-7));rig.rotation.y=PI
	var head=XRCamera3D.new();head.name="Camera";head.position.y=1.7;head.fov=76;rig.add_child(head)
	var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	body.player_calibrate_height=false;body.eye_forward_offset=0.0;rig.add_child(body)
	var hands=[];var controllers=[]
	for i in range(2):
		var hand=XRController3D.new();hand.position=Vector3(-0.3 if i==0 else 0.3,1.2,0)
		hand.rotation.x=-PI/2
		var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
		hand.add_child(pickup);rig.add_child(hand);hands.append(pickup);controllers.append(hand)
	root.add_child(rig);await create_timer(0.25).timeout
	check("XR movement adapter present",body.get_node_or_null("FieldCarryAdapter")!=null)
	check("XR visitor can wear the same visor",court.wear_visor(body) and court.visor.overlay.get_parent()==head)
	for i in range(2):
		court.points[i].global_position=controllers[i].global_position
		court.points[i].pick_up(hands[i]);court.points[i].action()
	var start: float=body.global_position.y
	await create_timer(0.45).timeout
	court.visor.update_reading()
	check("two real held points sum in the visor",court.visor.last_sample.thrust.is_equal_approx(Vector3(0,22,0)))
	check("display velocity matches integrated XR body",court.visor.last_sample.velocity.is_equal_approx(body.velocity) and body.velocity.y>0)
	check("actual XR body rises while wearing it",body.global_position.y>start+0.35)
	observations.xr_velocity=xyz(body.velocity);observations.xr_height_gain=body.global_position.y-start
	await save_view("body-visor-flight",head)
	var before: float=body.velocity.y
	for point in court.points:point.action_release()
	await create_timer(0.1).timeout;court.visor.update_reading()
	check("release removes thrust but not upward velocity",court.visor.last_sample.thrust==Vector3.ZERO and body.velocity.y>0 and body.velocity.y<before)
	for i in range(2):court.points[i].let_go(hands[i],Vector3.ZERO,Vector3.ZERO)
	court.visor.set_worn(false)
	var attached: Node=court.visor.overlay
	court.visor.clear_overlay();await tick()
	check("detached visor frees its camera child",not is_instance_valid(attached))
	rig.queue_free();await tick()

func finish() -> void:
	var result={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Production court and player, real pointer events, supplied XRTools rig and pickups. Numeric readings and real lift. No headset comfort or Quest timing claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("BODY VISOR ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
