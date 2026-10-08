extends SceneTree
const OUT := "res://doc/reports/interfaces-2026-09-21/angular-controls/"
var checks: Array = []
var failures: Array = []
var world: Node3D
var camera: Camera3D
var variant := "after"
var pointer:Node3D
class TestGrabber extends Node3D:
	var picked_up_ranged:=false
	var held:Node3D
	func drop_object()->void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO)
		held=null
func _initialize() -> void: run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"passed":ok,"message":message})
	if not ok: failures.append(message)
	print("ANGULAR ","PASS " if ok else "FAIL ",message)
func settle()->void:
	for i in 6:
		await process_frame
		await physics_frame
func run()->void:
	if not OS.get_cmdline_user_args().is_empty(): variant=OS.get_cmdline_user_args()[0]
	world=Node3D.new()
	root.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(.09,.11,.14)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color(.9,.93,1)
	env.environment.ambient_light_energy=.8
	world.add_child(env)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-40,-25,0)
	world.add_child(light)
	camera=Camera3D.new()
	world.add_child(camera)
	camera.current=true
	root.msaa_3d=Viewport.MSAA_4X
	var controls: Array[Node3D]=[]
	for type in ["wheel","lever"]:
		var control:Node3D=load("res://commons/interactables/"+type+"_smooth.tscn").instantiate()
		control.position=Vector3(-.17 if type=="wheel" else .17,1,0)
		control.rotation_degrees.x=-35
		world.add_child(control)
		controls.append(control)
		check(control.has_method("pointer_event"),type+": root receives pointer input")
		for redirect in control.find_children("GrabPointRedirect*","",true,false):
			check(redirect.target!=null,type+": hand-pose redirect resolves")
		if type=="wheel":
			var shape:CollisionShape3D=control.get_node("Frame/CollisionShape3D")
			var body:CollisionShape3D=control.get_node("HingeOrigin/InteractableHinge/WheelBody/CollisionShape3D")
			check(body.shape!=null,"Wheel body has a collision shape")
			check(shape.shape is BoxShape3D,"Wheel mounting collider matches its rectangular backplate")
	await capture("controls",Vector3(.23,1.52,.86),Vector3(0,1,0),55)
	if variant=="after":
		pointer=Node3D.new()
		world.add_child(pointer)
		await exercise_controls(controls)
	for c in controls:c.queue_free()
	await settle()
	if variant=="after":await exercise_reference()
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"baseline":variant=="before","headset_tested":false},"\t"))
	quit(0 if variant=="before" or failures.is_empty() else 1)
func capture(tag:String,at:Vector3,target:Vector3,fov:float)->void:
	camera.position=at
	camera.fov=fov
	camera.look_at(target)
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+tag+".png")

func near(a:float,b:float)->bool:return absf(a-b)<.08
func handle_for(control:Node3D)->Node3D:
	return control.hinge.get_node("Handles/Handle1/InteractableHandle" if control.kind=="wheel" else "HandleOrigin/InteractableHandle")
func grab(handle:Node3D)->TestGrabber:
	var hand:=TestGrabber.new()
	world.add_child(hand)
	hand.global_transform=handle.global_transform
	hand.held=handle
	handle.pick_up(hand)
	return hand
func move_hand(hand:TestGrabber,control:Node3D,degrees:float)->void:
	var rest:Vector3=control.hinge.to_local(hand.held.handle_origin.global_position)
	hand.global_position=control.hinge.get_parent().to_global(Basis(Vector3.RIGHT,deg_to_rad(degrees))*rest)
func pointer_hit(control:Node3D)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(control.to_global(Vector3(.075,.02,.3)),control.to_global(Vector3(.075,.02,-.04)),(1<<20)|(1<<22))
	return world.get_world_3d().direct_space_state.intersect_ray(query)
func exercise_controls(controls:Array[Node3D])->void:
	for yaw in [0,90]:
		for control in controls:
			control.rotation_degrees.y=yaw
			control.set_angle_degrees(0)
			await settle()
			var tag:String=control.kind+" yaw "+str(yaw)
			var handle:=handle_for(control)
			var hand:=grab(handle)
			move_hand(hand,control,32)
			await settle()
			check(near(control.get_angle_degrees(),32),tag+": real XR pickup follows hand angle")
			await settle()
			check(near(control.get_angle_degrees(),32),tag+": stationary hand does not accumulate angle")
			check(control._reading.label.text=="+32°",tag+": flat reading follows the physical joint")
			# A pointer may not take the control from a physical hand.
			XRToolsPointerEvent.pressed(pointer,control,control.global_position)
			check(control._pointer==null,tag+": physical grab excludes pointer ownership")
			hand.drop_object()
			hand.queue_free()
			await settle()
			check(near(control.get_angle_degrees(),32),tag+": canonical control retains angle on release")
			check(not control.hinge.is_processing() and not handle.is_processing(),tag+": released grab stops processing")
			check(handle.position.is_equal_approx(Vector3.ZERO),tag+": released proxy returns to visible grip")
			check((handle.collision_layer & ((1<<20)|(1<<22)))==((1<<20)|(1<<22)),tag+": release preserves pointer layers on the grip")
			control.set_angle_degrees(1000)
			check(near(control.get_angle_degrees(),control.hinge.hinge_limit_max),tag+": positive limit clamps")
			control.set_angle_degrees(-1000)
			check(near(control.get_angle_degrees(),control.hinge.hinge_limit_min),tag+": negative limit clamps")
			control.set_angle_degrees(0)
			await settle()
			var hit:=pointer_hit(control)
			check(not hit.is_empty(),tag+": real ray hits the physical face")
			if not hit.is_empty():
				XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
				var end:Vector3
				if control.kind=="wheel":
					var at:Vector3=control.to_local(hit.position)
					end=control.to_global(Vector3(-at.y,at.x,at.z))
				else:end=hit.position+control.global_basis*Vector3(0,-.06,0)
				XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
				var expected:=90.0 if control.kind=="wheel" else 27.0
				check(near(control.get_angle_degrees(),expected),tag+": pointer agrees with tilted local axes")
				XRToolsPointerEvent.released(pointer,hit.collider,end)
				check(near(control.get_angle_degrees(),expected) and not control.is_processing(),tag+": pointer release retains angle and idles")
			control.hinge.hinge_steps=5
			control.set_angle_degrees(23)
			check(near(control.get_angle_degrees(),25),tag+": native optional detents remain available")
			control.hinge.hinge_steps=0
			control.set_angle_degrees(0)
	var wheel:Node3D=controls[0]
	wheel.set_angle_degrees(0)
	await settle()
	for target in [wheel.to_global(Vector3(.025,0,.034)),handle_for(wheel).global_position]:
		var query:=PhysicsRayQueryParameters3D.create(target+wheel.global_basis.z*.3,target-wheel.global_basis.z*.04,(1<<20)|(1<<22))
		var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(),"Wheel face or grip remains ray-targetable after grabbing")
		if not hit.is_empty():
			XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
			check(wheel._pointer==pointer,"Wheel face or grip forwards to its owning control")
			XRToolsPointerEvent.released(pointer,hit.collider,hit.position)
	var hand:=grab(handle_for(wheel))
	for requested in [120,175,185,270,350,370]:
		move_hand(hand,wheel,requested)
		await settle()
		check(near(wheel.get_angle_degrees(),minf(requested,360)),"Wheel continuous grab unwraps "+str(requested)+" degrees")
	hand.drop_object()
	hand.queue_free()
	wheel.set_angle_degrees(270)
	hand=grab(handle_for(wheel))
	await settle()
	check(near(wheel.get_angle_degrees(),270),"Wheel regrab preserves turn count")
	move_hand(hand,wheel,280)
	await settle()
	check(near(wheel.get_angle_degrees(),280),"Wheel regrab continues beyond the half-turn seam")
	hand.drop_object()
	hand.queue_free()
	wheel.set_angle_degrees(0)
	var left:=grab(handle_for(wheel))
	var right:=grab(wheel.hinge.get_node("Handles/Handle5/InteractableHandle"))
	move_hand(left,wheel,30)
	move_hand(right,wheel,30)
	await settle()
	check(near(wheel.get_angle_degrees(),30),"Two different wheel handles agree on one angle")
	left.drop_object()
	await settle()
	check(near(wheel.get_angle_degrees(),30) and wheel.hinge.is_processing(),"Releasing one grip keeps the other active")
	right.drop_object()
	left.queue_free()
	right.queue_free()
	check(not wheel.hinge.is_processing(),"Releasing the last wheel grip stops grab processing")
	wheel.set_angle_degrees(0)
	XRToolsPointerEvent.pressed(pointer,wheel,wheel.to_global(Vector3(.05,0,0)))
	XRToolsPointerEvent.moved(pointer,wheel,wheel.global_position,wheel.to_global(Vector3(.05,0,0)))
	check(near(wheel.get_angle_degrees(),0),"Wheel centre does not invent an angular direction")
	XRToolsPointerEvent.released(pointer,wheel,wheel.global_position)
	var lever:Node3D=controls[1]
	lever.hinge.default_on_release=true
	lever.hinge.default_position=0
	var hit:=pointer_hit(lever)
	var stranger:=Node3D.new()
	world.add_child(stranger)
	var end:Vector3=hit.position+lever.global_basis*Vector3(0,-.06,0)
	XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
	XRToolsPointerEvent.pressed(stranger,hit.collider,hit.position)
	XRToolsPointerEvent.moved(stranger,hit.collider,end,hit.position)
	check(near(lever.get_angle_degrees(),0),"Second pointer cannot steal an active lever")
	XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
	check(near(lever.get_angle_degrees(),27),"Original pointer still controls the lever")
	XRToolsPointerEvent.exited(pointer,hit.collider,end)
	check(near(lever.get_angle_degrees(),0) and not lever.is_processing(),"Pointer exit applies configured spring return")
	XRToolsPointerEvent.pressed(stranger,hit.collider,hit.position)
	XRToolsPointerEvent.moved(stranger,hit.collider,end,hit.position)
	stranger.queue_free()
	await settle()
	check(near(lever.get_angle_degrees(),0) and not lever.is_processing(),"Removed pointer releases a returning lever")
	XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
	XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
	lever.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(near(lever.get_angle_degrees(),0) and not lever.is_processing(),"Focus loss releases a returning lever")

func exercise_reference()->void:
	var floor_mesh:=MeshInstance3D.new()
	floor_mesh.mesh=PlaneMesh.new()
	floor_mesh.mesh.size=Vector2(12,12)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(.23,.26,.29)
	floor_mesh.material_override=mat
	world.add_child(floor_mesh)
	var demo:Node3D=load("res://commons/interactables/interactable_angular_demo.tscn").instantiate()
	world.add_child(demo)
	await settle()
	var ref:Node3D=demo.get_node("AngularReference")
	check(ref.controls.size()==2,"Focused InteractableDemo builds the two real controls")
	check(ref.find_children("*","Label3D",true,false).is_empty(),"All reference text is printed on flat surfaces")
	check(ref.station.global_position.z>ref.rotors[0].global_position.z,"Console stands in front of the visible receivers")
	check(absf(ref.controls[0].position.distance_to(ref.controls[1].position)-.28)<.001,"Controls grouped at 28 cm centres")
	check(not ref.is_processing(),"Receiver does not process while its speed command is zero")
	await capture("overview",Vector3(.75,1.65,2.4),Vector3(0,1.12,.15),52)
	await capture("operating",Vector3(0,1.60,1.22),Vector3(0,1.31,.14),78)
	await capture("console",Vector3(.13,1.50,1.05),ref.station.global_position,64)
	var wheel:Node3D=ref.controls[0]
	var lever:Node3D=ref.controls[1]
	var position_hand:=grab(handle_for(wheel))
	move_hand(position_hand,wheel,60)
	var speed_hand:=grab(handle_for(lever))
	move_hand(speed_hand,lever,30)
	await settle()
	check(near(ref.rotors[0].rotation_degrees.z,60),"Wheel grab sets the visible angle receiver")
	var marker:Vector3=wheel.to_local(wheel.hinge.get_node("WheelIndex").global_position)
	check(near(rad_to_deg(atan2(marker.y,marker.x)),60),"Wheel index and receiver use the same zero direction")
	check(near(ref.speed_degrees,60),"Lever grab commands 60 degrees per second")
	check(lever._reading.label.text=="+60°/s","Lever readout displays commanded speed, not handle angle")
	ref.set_process(false)
	var started:float=ref.accumulated_degrees
	ref.advance_receiver(.5)
	check(near(ref.accumulated_degrees,wrapf(started+30,-180,180)),"Half a second at 60 degrees per second adds 30 degrees")
	ref.advance_receiver(.25)
	check(near(ref.accumulated_degrees,wrapf(started+45,-180,180)),"A further quarter second adds another 15 degrees")
	check(near(ref.rotors[0].rotation_degrees.z,60),"Time does not change the position-setting receiver")
	await capture("held",Vector3(0,1.60,1.22),Vector3(0,1.31,.14),78)
	var last_angle:float=ref.accumulated_degrees
	position_hand.drop_object()
	speed_hand.drop_object()
	position_hand.queue_free()
	speed_hand.queue_free()
	await settle()
	check(near(wheel.get_angle_degrees(),60) and near(ref.rotors[0].rotation_degrees.z,60),"Released wheel and angle receiver retain their pose")
	check(near(lever.get_angle_degrees(),0) and near(ref.speed_degrees,0),"Released lever returns to zero command")
	check(not ref.is_processing(),"Zero speed command stops receiver processing")
	ref.advance_receiver(1)
	check(near(ref.accumulated_degrees,last_angle),"Stopping the command preserves the accumulated receiver angle")
	await capture("released",Vector3(0,1.60,1.22),Vector3(0,1.31,.14),78)
	# Check the reverse command through a real collider, not a setter.
	var hit:=pointer_hit(lever)
	var end:Vector3=hit.position+lever.global_basis*Vector3(0,.06,0)
	XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
	XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
	ref.set_process(false)
	check(near(ref.speed_degrees,-54),"Pointer can command reverse angular velocity")
	ref.advance_receiver(.5)
	check(near(ref.accumulated_degrees,wrapf(last_angle-27,-180,180)),"Negative velocity reverses the visible receiver")
	XRToolsPointerEvent.released(pointer,hit.collider,end)
	check(near(ref.speed_degrees,0) and not ref.is_processing(),"Pointer release stops the command like hand release")
