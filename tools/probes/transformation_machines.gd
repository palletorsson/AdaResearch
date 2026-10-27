extends "res://tools/probes/void_transfer_probe.gd"
## Physical consequences and a disconnected counterfactual, in real negative
## world coordinates. No cargo is translated to its predicted destination.
var machines:Dictionary={}
var observations:Dictionary={}
var scene:Node3D

func tick(count:int) -> void:
	for i in count:await physics_frame
	await process_frame

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	var floor_body:=StaticBody3D.new();floor_body.position.y=-90.1;scene.add_child(floor_body)
	var floor_shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(42,.2,18);floor_shape.shape=box;floor_body.add_child(floor_shape)
	var positions={"crank":Vector3(-3.5,-90,-4.5),"lever":Vector3(-3.5,-90,1.8),"suspended":Vector3(3.5,-90,1.8),"sorter":Vector3(3.5,-90,-4.5)}
	for id in positions:
		var n:Node3D=load("res://commons/artifacts/transformation_machines/%s.tscn"%id).instantiate()
		n.position=positions[id];scene.add_child(n);machines[id]=n
	await tick(90)
	var crank:Node3D=machines.crank
	check("actual hinge motor and slider guide",crank.motor is HingeJoint3D and crank.find_child("ActualPistonGuide",true,false) is SliderJoint3D)
	check("piston is a real rigid body",crank.members.piston is RigidBody3D and not crank.members.piston.freeze)
	check("constrained bodies cannot be picked up directly",not crank.members.piston.enabled and not crank.members.rotor.enabled)
	check("crank offers the existing force proxy grip",crank.grips.size()==1 and crank.grips[0].target==crank.members.rotor)
	var low:=INF;var high:=-INF;var error:=0.0
	crank.action("MOTOR / PAUSE")
	machines.sorter.action("RELEASE")
	for i in range(720):
		await tick(1)
		var piston:RigidBody3D=crank.members.piston
		low=minf(low,piston.position.x);high=maxf(high,piston.position.x)
		var a:Vector3=crank.members.rotor.to_global(Vector3(.65,0,0))
		var b:Vector3=crank.members.rod.to_global(Vector3(-1,0,0))
		error=maxf(error,a.distance_to(b))
	check("rotation physically produces a substantial piston stroke",high-low>1.0 and high-low<1.6)
	check("connected crank pin stays attached",error<.1)
	check("piston contacts and delivers the ball",crank.outputs.get("delivered",false))
	observations.crank={"stroke":high-low,"pin_error":error,"delivered":crank.outputs.get("delivered",false)}
	var sorter:Node3D=machines.sorter
	check("sorter changes size and keeps equal masses",sorter.members.balls.all(func(b):return b.mass==1))
	check("all three gravity exits actually observed",sorter.drops.size()==3)
	if sorter.drops.size()==3:check("larger spheres leave later along identical diverging rails",float(sorter.drops["0"])<float(sorter.drops["1"])-.2 and float(sorter.drops["1"])<float(sorter.drops["2"])-.2)
	observations.gravity_exits=sorter.drops.duplicate(true)
	# Remove the physical coupling. The motor can still turn, but nothing in
	# the script drives the piston as a function of its angle.
	crank.reset();await tick(6)
	crank.action("PIN / UNPIN");await tick(3)
	crank.action("MOTOR / PAUSE")
	var start:float=crank.members.piston.position.x
	var rotation:Basis=crank.members.rotor.basis
	await tick(240)
	check("disconnected motor still turns",not crank.members.rotor.basis.is_equal_approx(rotation))
	check("disconnected piston does not fake the rotation relation",absf(crank.members.piston.position.x-start)<.08)
	observations.disconnected_piston_drift=absf(crank.members.piston.position.x-start)
	crank.reset();await tick(6)
	check("RESET restores the physical crank connection",is_instance_valid(crank.members.pin_joint) and not crank.motor_running)

	var lever:Node3D=machines.lever
	var lifts:Array=[]
	for arm in [.4,2.0]:
		lever.reset();await tick(6)
		var highest:float=-INF
		for i in range(180):
			await physics_frame
			var beam:RigidBody3D=lever.members.beam
			beam.apply_force(Vector3.DOWN*10,beam.global_basis*Vector3(-arm,0,0))
			highest=maxf(highest,lever.members.load.position.y)
		lifts.append(highest)
	check("same force farther from the pivot lifts more load",lifts[1]>lifts[0]+.12)
	observations.lever_lift_heights=lifts
	var rope:Node3D=machines.suspended
	rope.reset();await tick(6)
	rope.members.load.apply_central_impulse(Vector3(3,0,0))
	var swing:=0.0;var pin_error:=0.0
	for i in range(240):
		await tick(1)
		swing=maxf(swing,absf(rope.members.load.position.x))
		pin_error=maxf(pin_error,rope.bodies[3].to_global(Vector3(0,-.4,0)).distance_to(rope.members.load.to_global(Vector3(0,.5,0))))
	check("hanging cube swings under a physical impulse",swing>.3)
	check("jointed rope keeps the load attached",pin_error<.12)
	observations.suspended={"sideways":swing,"pin_error":pin_error}
	FileAccess.open(out.path_join("native.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Actual joint/contact/gravity simulation at world Y=-90, force-distance comparison and disconnected crank counterfactual. Physical headset/input playthrough not tested."},"  "))
	print("TRANSFORMATION_MACHINES ",failed)
	scene.queue_free();await tick(2);quit(0 if failed.is_empty() else 1)
