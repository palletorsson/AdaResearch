extends "res://tools/probes/transformation_encounters.gd"
## All ten artifacts in the real museum, replacing only the test-bay contents.
var trial: Node3D
func run() -> void:
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder=spec.run;map_id=spec.room
	museum=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","forces_review");museum.set("start_map",map_id)
	museum.set("_order_file","res://commons/artifacts/force_trials/review_order.json")
	museum.set("plan_file","res://commons/artifacts/force_trials/review_plan.json")
	root.add_child(museum);current_scene=museum
	var start=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<60000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false)
	await create_timer(1).timeout
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))==map_id:hall=child;break
	check("requested museum hall loaded",hall!=null)
	if hall==null:finish();return
	camera=Camera3D.new();root.add_child(camera)
	var previous: Camera3D=museum.get("_cam")
	if previous!=null:
		for timer in previous.find_children("*","Timer",true,false):timer.stop()
	await landing_checks();finish()
func press(id: String) -> void:
	trial.buttons[id].pressed.emit()
	await tick()
func wait_seconds(t: float) -> void: await create_timer(t).timeout

func landing_checks() -> void:
	trial=find_scene("/force_trials/trial.gd")
	check("first review artifact placed at full size",trial!=null and trial.scale.is_equal_approx(Vector3.ONE))
	if trial==null:return
	var site=trial.global_transform
	var kinds=["mass","vortex","roll","pipe","conveyor","attractor","threebody","support","bowling","catapult"]
	for k in kinds:
		if k!="mass":
			trial.queue_free();await tick()
			trial=load("res://commons/artifacts/force_trials/"+k+".tscn").instantiate()
			hall.add_child(trial);trial.global_transform=site;await tick()
		check(k+": existing point/cube bodies and visible controls",trial.bodies.size()>0 and trial.buttons.size()>=2)
		check(k+": solid visitor approach",not floor_at(trial.to_global(Vector3(0,0,-4.9))).is_empty())
		await snapshot(k+"-before",trial.to_global(Vector3(-5.6,3.8,-7.8)),trial.to_global(Vector3(0,1.0,0)),62)
		match k:
			"mass":
				await press("PUSH");await wait_seconds(0.6)
				var v0=trial.bodies[0].linear_velocity.length();var v1=trial.bodies[1].linear_velocity.length();var v2=trial.bodies[2].linear_velocity.length()
				check("mass: equal force makes inverse mass acceleration",absf(v0/v1-2)<0.08 and absf(v1/v2-2)<0.08)
				await wait_seconds(0.5);var retained=trial.bodies[0].linear_velocity.length();await wait_seconds(0.25)
				check("mass: motion persists after force ends",trial.pulse<=0 and absf(trial.bodies[0].linear_velocity.length()-retained)<0.08)
			"vortex":
				await press("SPIRAL");await wait_seconds(1.8)
				check("vortex: tangential motion curves inward",trial.bodies[0].position.x<2.0 and trial.bodies[0].position.z>0.3)
				check("vortex: path accumulates actual positions",trial.markers.size()>20)
			"roll":
				await press("RELEASE");await wait_seconds(2)
				check("roll: free ball gains angular velocity",trial.bodies[1].angular_velocity.length()>0.3)
				check("roll: locked ball cannot rotate",trial.bodies[0].angular_velocity.length()<0.01)
				check("roll: equal ramp leaves different outcomes",trial.bodies[0].position.distance_to(trial.homes[0].origin)<trial.bodies[1].position.distance_to(trial.homes[1].origin))
			"pipe":
				await press("LAUNCH");await wait_seconds(2.5)
				check("pipe: contacts carry the point around the bend",trial.bodies[0].position.z>-1.2 and trial.bodies[0].position.x> -0.6)
				check("pipe: point falls after channel exit",trial.bodies[0].position.y<0.8)
			"conveyor":
				await press("FEED");await wait_seconds(7.8)
				check("conveyor: finite supply enters while receiver is closed",trial.emissions==12 and trial.collected==0)
				var moved=0
				for b in trial.bodies:
					if b.position.z> -1:moved+=1
				check("conveyor: contact surface transports real boxes",moved>=3)
				await snapshot("conveyor-backlog",trial.to_global(Vector3(-4.6,3.4,-5.7)),trial.to_global(Vector3(0,1,0)),60)
				await press("GATE");await wait_seconds(3)
				check("conveyor: open receiver processes the remaining queue",trial.collected>0)
			"attractor":
				await press("SELECTED");await wait_seconds(1.5)
				var stop=trial.members.stop.position
				var door_angle=trial.members.door.rotation.y
				check("attractor: selected point responds",trial.members.wanted.position.z>-0.8)
				await press("ALL");await wait_seconds(1.5)
				check("attractor: wider filter moves the doorstop",trial.members.stop.position.distance_to(stop)>0.1)
				check("attractor: the released door can turn further",absf(trial.members.door.rotation.y-door_angle)>0.05)
			"threebody":
				await press("RELEASE");await wait_seconds(3)
				var momentum=Vector3.ZERO
				for i in range(3):momentum+=trial.bodies[i].linear_velocity
				check("threebody: internal pair forces conserve net momentum",momentum.length()<0.015)
				check("threebody: initial change survives into distinct positions",((trial.bodies[0].position-Vector3(-2,0,0))-(trial.bodies[3].position-Vector3(2,0,0))).length()>0.01)
			"support":
				await press("SETTLE");await wait_seconds(1.0)
				var before=trial.members.slab.rotation.length();await press("PULL FOOT");await wait_seconds(2)
				check("support: removing loaded corner tilts slab",trial.members.slab.rotation.length()>before+0.1)
				check("support: displaced support persists",trial.members.foot.position.distance_to(trial.homes[2].origin)>0.5)
			"bowling":
				await press("FREE");await wait_seconds(0.08)
				check("bowling: launch and recoil have opposite signs",trial.members.ball.linear_velocity.dot(trial.global_basis.z)>0 and trial.members.cart.linear_velocity.dot(trial.global_basis.z)<0)
				await wait_seconds(1.4)
				var knocked=0
				for i in range(2,trial.bodies.size()):
					if trial.bodies[i].rotation.length()>0.1:knocked+=1
				check("bowling: physical contacts disturb pins",knocked>0)
			"catapult":
				await press("FIRE");await wait_seconds(0.3)
				check("catapult: torque turns a real hinged arm",trial.arm.angular_velocity.length()>0.2)
				check("catapult: arm contact gives point velocity",trial.members.ball.linear_velocity.length()>1)
				await wait_seconds(0.8)
		await snapshot(k+"-after",trial.to_global(Vector3(-5.6,3.8,-7.8)),trial.to_global(Vector3(0,1.0,0)),62)
		# Real reset event restores source transforms and finite state. Held reset must refuse.
		trial.bodies[0].set_meta("capability_desktop_held",true)
		await press("RESET")
		check(k+": reset refuses held object",trial.active)
		trial.bodies[0].remove_meta("capability_desktop_held")
		await press("RESET");await tick()
		var restored=true
		for i in trial.bodies.size():restored=restored and trial.bodies[i].transform.is_equal_approx(trial.homes[i])
		check(k+": reset restores all bodies",restored and not trial.active and trial.emissions==0)
	observations["scope"]="Production scenes inside the actual museum; real rigid bodies, joints, contacts and supplied button events. Images are from this run. Headset comfort and tracked hands still need the user's VR trial."
