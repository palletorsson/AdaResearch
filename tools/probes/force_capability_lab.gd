extends "res://tools/probes/transformation_encounters.gd"
## The production museum, production bodies and production desktop events.
func landing_checks() -> void:
	var court = find_scene("/force_capability_lab.gd")
	check("trial court loaded through the artifact registry",court != null)
	if court == null: return
	camera.set_cull_mask_value(19,false) # same first-person costume exclusion as the museum camera
	# Photograph the hall from a visitor's eye, without the probe camera crossing the parked avatar.
	var wardrobe: Node = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")):
		wardrobe.get("costume").visible = false
		wardrobe.get("costume").set_process(false)
	observations["court_world"] = xyz(court.global_position)
	observations["court_scale"] = xyz(court.global_basis.get_scale())
	check("court kept metre scale",court.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("original acceleration field retained",find_scene("/force_field_zone.gd") != null)
	check("two learned sphere points",court.points.size()==2 and is_equal_approx(court.points[0].sphere.radius,0.14))
	check("floor underneath trial court",not floor_at(court.to_global(Vector3(0,0.1,-7))).is_empty())
	check("floor continues to the final passage",not floor_at(court.to_global(Vector3(0,0.1,11))).is_empty())
	await snapshot("court-entry",court.to_global(Vector3(0,1.7,-12)),court.to_global(Vector3(0,1.6,-4)),72)
	await snapshot("thrust-points",court.to_global(Vector3(-2,1.65,-11.7)),court.to_global(Vector3(-3.8,1.25,-9)),62)
	var mortar = court.mortar
	var ring = mortar.fire()
	check("mortar waits for a clear muzzle",mortar.fire()==null and mortar.rings.size()==1)
	check("mortar fires a grabbable rigid ring",ring.has_method("pick_up") and not ring.freeze)
	check("ring collision has sixteen shapes around an open hole",ring.get_child_count()==17 and ring.get_child(1).position.length()>ring.get_child(1).shape.radius)
	var started: Vector3 = ring.global_position
	var velocity: Vector3 = ring.linear_velocity
	await create_timer(0.35).timeout
	check("ring advances on a gravity affected trajectory",ring.global_position.distance_to(started)>1.0 and ring.linear_velocity.y<velocity.y)
	for i in range(7):
		mortar.fire(); await create_timer(0.35).timeout
	check("eight shot budget stops firing without deleting misses",mortar.rings.size()==8 and mortar.fire()==null and is_instance_valid(ring))
	var clear := true
	for n in hall.find_children("DreamBody*","Node3D",true,false):
		if court._point_inside(n.global_position): clear=false
	check("authored trial court stays clear of automatic sculptures",clear)
	await snapshot("donut-cake",court.to_global(Vector3(1.7,1.75,-11.5)),court.to_global(Vector3(4,1.1,-8.7)),61)
	await create_timer(1.6).timeout
	await snapshot("rings-and-posts",court.to_global(Vector3(1.8,1.7,-5.3)),court.to_global(Vector3(4,0.5,-2.7)),64)
	var old: Vector3 = court.platform.global_position
	# An endpoint can be inside the intentional 0.4 s dwell or return near the
	# start. Observe travel through a window instead of comparing only two poses.
	var platform_travel:=0.0
	for i in range(15):
		await create_timer(0.1).timeout
		platform_travel=maxf(platform_travel,court.platform.global_position.distance_to(old))
	check("existing transport platform actually moves",platform_travel>0.1)
	var before: Basis = court.pole.global_basis
	court.buttons.HINGE.pressed.emit()
	await create_timer(3.8).timeout
	check("release lets gravity move the real hinge body",not court.pole.freeze and not court.pole.global_basis.is_equal_approx(before))
	check("pole falls into a usable low bridge",court.to_local(court.pole.to_global(Vector3(0,2,0))).y<0.85)
	check("hinge stays attached at its foot",court.hinge.global_position.distance_to(court.pole.to_global(Vector3(0,-2,0)))<0.12)
	await snapshot("hinge-aftermath",court.to_global(Vector3(-1.6,1.7,-1.8)),court.to_global(Vector3(-4,0.8,1)),66)
	court.buttons.SPRING.pressed.emit()
	var peak := 0.0
	for i in range(50):
		await physics_frame
		peak = maxf(peak,court.springs[1].linear_velocity.length())
	check("spring point transfers a push through collision",peak>0.05)
	await snapshot("spring-points",court.to_global(Vector3(3,1.55,0.7)),court.to_global(Vector3(3.8,1,3.3)),58)
	# Use the actual desktop pointer, including held trigger delivery and release hooks.
	var player := CharacterBody3D.new(); player.name = "ProbePlayer"
	player.collision_layer = 524288; player.collision_mask = 1|4
	var boundary := CollisionShape3D.new(); var capsule := CapsuleShape3D.new()
	capsule.radius=0.22; capsule.height=1.6; boundary.shape=capsule; boundary.position.y=0.8; player.add_child(boundary)
	court.add_child(player); player.position = Vector3(0,0.15,-7)
	var eye := Camera3D.new(); eye.position.y = 1.5; player.add_child(eye)
	var pointer = load("res://commons/scenes/em/em_desktop_pointer.gd").new(); pointer.cam=eye; player.add_child(pointer)
	pointer.set_process(false); pointer.set_physics_process(false)
	var point = court.points[0]
	pointer._grab_held(point)
	eye.rotation = Vector3.ZERO
	pointer._try_held_action(true)
	check("forward pointing propels forward instead of backward",point.acceleration().is_equal_approx(Vector3(0,0,-11)))
	eye.rotation.y = PI/2
	check("turning the view steers desktop thrust left",point.acceleration().is_equal_approx(Vector3(-11,0,0)))
	eye.rotation = Vector3.ZERO
	eye.rotation.x = PI/2.0
	pointer._try_held_action(true)
	check("real desktop grab identifies the player",point.held() and point.receiver()==player)
	check("aim up applies upward thrust",point.acceleration().y>10.0)
	check("reset refuses to steal a held point",not court.reset_trial())
	player.velocity = court.carry_velocity(player,0.25,Vector3.ZERO)
	court.record_carry(player)
	check("held trigger lifts against gravity",player.velocity.y>0.2)
	pointer._try_held_action(false)
	var released: Vector3 = court.carry_velocity(player,0.01,player.velocity)
	check("release stops thrust but preserves momentum",point.acceleration()==Vector3.ZERO and released.y>0.0 and released.y<player.velocity.y)
	pointer._drop_held()
	check("desktop drop leaves a physical sphere and no thrust",not point.freeze and not point.firing and not point.held())
	court.release_carry(player)
	# Step a real collision body into the pad: exercise Area.body_entered, not a direct launch.
	player.position = Vector3(0,0.2,-4); player.velocity = Vector3.ZERO
	await create_timer(0.15).timeout
	check("pad overlap queues a launch for the actual body",court._launch.has(player.get_instance_id()))
	player.velocity = court.carry_velocity(player,1.0/60.0,Vector3.ZERO)
	check("launch vector survives normal walking ownership",player.velocity.y>5.5 and player.velocity.z>3.8)
	var y0 := player.global_position.y
	for i in range(35):
		player.move_and_slide(); court.record_carry(player)
		await physics_frame
		player.velocity = court.carry_velocity(player,1.0/60.0,player.velocity)
	check("launched player actually rises through physics",player.global_position.y>y0+0.7)
	observations["launch_height_gain"] = player.global_position.y-y0
	player.queue_free(); await tick()
	await xr_receiver_checks(court)
	# Compare the same cube, same initial velocity, same lane with only drag changed.
	var cube: RigidBody3D = court.loose[2] # first loose cube after two powered points and two springs? choose by name below
	for body in court.loose:
		if body.name == "LooseCube0": cube=body; break
	var distances: Array = []
	for coefficient in [0.0,3.0]:
		cube.freeze = true; cube.global_position=court.to_global(Vector3(-3.7,1.5,7)); cube.rotation=Vector3.ZERO
		cube.linear_velocity=Vector3.ZERO; cube.angular_velocity=Vector3.ZERO
		await tick(); cube.freeze=false; cube.sleeping=false; cube.linear_damp=0.0
		cube.linear_velocity=court.global_basis.z*2.0; court.drag_coefficient=coefficient
		var start_z: float = court.to_local(cube.global_position).z
		await create_timer(0.4).timeout
		distances.append(court.to_local(cube.global_position).z-start_z)
	check("drag reduces travel for the same launch",distances[1]<distances[0]*0.9 and distances[1]>0)
	observations["drag_distances"] = distances
	court.reset_trial(); await create_timer(0.25).timeout
	check("explicit reset clears rings and restores the latched hinge",mortar.rings.is_empty() and court.pole.freeze)
	court.cargo.freeze = false; court.cargo.global_position = court.goal.global_position+Vector3.UP*0.5
	await create_timer(0.6).timeout
	check("the actual carried point triggers the destination on arrival",court.status.text.begins_with("The point reached"))
	await snapshot("drag-and-destination",court.to_global(Vector3(0.8,1.75,5.5)),court.to_global(Vector3(-2,1,8.6)),76)
	await snapshot("launch-and-platform",court.to_global(Vector3(2,1.7,-5.7)),court.to_global(Vector3(0,1,0.3)),65)
	observations["limits"] = "Desktop events and supplied player body tested; headset, Quest performance and subjective comfort need a physical VR visit."

func xr_receiver_checks(court: Node3D) -> void:
	var origin := XROrigin3D.new(); origin.name = "ProbeXROrigin"
	origin.position = court.to_global(Vector3(0,0.15,6))
	var eye := XRCamera3D.new(); eye.name = "Camera"; eye.position.y = 1.7; origin.add_child(eye)
	var body = load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	body.player_calibrate_height = false; body.eye_forward_offset = 0.0; origin.add_child(body)
	var hands: Array = []
	var controllers: Array[XRController3D] = []
	for i in range(2):
		var controller := XRController3D.new(); controller.name = "LeftHand" if i==0 else "RightHand"
		controller.position = Vector3(-0.3 if i==0 else 0.3,1.3,0)
		controller.rotation.x = PI/2.0
		var pickup = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
		controller.add_child(pickup); origin.add_child(controller); hands.append(pickup); controllers.append(controller)
	root.add_child(origin)
	await create_timer(0.25).timeout
	check("real XR body receives court movement adapter",body.get_node_or_null("FieldCarryAdapter")!=null)
	for i in range(2):
		court.points[i].global_position = controllers[i].global_position
		court.points[i].pick_up(hands[i])
		court.points[i].action()
	check("two XR grabs bind to the same real player",court.points[0].receiver()==body and court.points[1].receiver()==body)
	check("two upward pointing XR hands add upward thrust",court.thrust_acceleration(body).is_equal_approx(Vector3(0,22,0)))
	controllers[1].rotation.x=-PI/2
	check("opposed pointing hands cancel their thrust",court.thrust_acceleration(body).is_zero_approx())
	controllers[1].rotation.x=PI/2
	var y0: float = body.global_position.y
	await create_timer(0.55).timeout
	check("two held points lift the XR origin through its actual provider",body.global_position.y>y0+0.7 and origin.global_position.y>court.global_position.y+0.7)
	var v0: float = body.velocity.y
	for point in court.points: point.action_release()
	await create_timer(0.12).timeout
	check("XR trigger release preserves upward momentum while gravity slows it",body.velocity.y>0 and body.velocity.y<v0)
	for i in range(2): court.points[i].let_go(hands[i],Vector3.ZERO,Vector3.ZERO)
	check("XR drop stops firing and restores dynamic points",not court.points[0].freeze and not court.points[1].freeze and not court.points[0].held())
	observations["xr_lift_metres"] = body.global_position.y-y0
	origin.queue_free(); await tick()

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Production museum and physics, supplied desktop input and receiver; no headset acceptance claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("CAPABILITY COURT ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
