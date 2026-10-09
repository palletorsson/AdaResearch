extends SceneTree
var checks: Array=[]
var failures: Array=[]
var measurements: Dictionary={}
func _initialize() -> void:run.call_deferred()
func check(message: String,good: bool) -> void:
	checks.append({"name":message,"passed":good})
	if not good:failures.append(message);push_error(message)
func wait(seconds: float) -> void:await create_timer(seconds).timeout

func run() -> void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var e=load("res://commons/artifacts/force_trials/conveyor.tscn").instantiate();world.add_child(e)
	await wait(0.2)
	check("Existing conveyor scene now builds finite prefab cast",e.cargo.size()==32 and e.bodies.size()==35)
	check("Later prefabs increase size and mass together",e.cargo[17].visual_bounds.size.y>e.cargo[1].visual_bounds.size.y*1.6 and e.cargo[17].mass>e.cargo[1].mass*4)
	check("Chair keeps six separate collision parts",e.cargo[1].find_children("*","CollisionShape3D",true,false).size()==6)
	check("Unused cargo has no active collision",e.cargo.all(func(b):return b.freeze and b.collision_layer==0 and not b.visible))
	check("Gate and receiver are actual anchored hinges",e.joints.size()==2 and not e.gate.enabled and not e.receiver.enabled)
	e.action("FEED / PAUSE");await wait(12)
	measurements.feed_12={"admitted":e.admitted,"passed":e.passed_gate.size(),"spilled":e.spilled.size(),"gate":e.gate.rotation.y,"receiver":e.receiver.rotation.x}
	check("Feed admits different prefab types",e.admitted>=8)
	check("Contact belt moves cargo beyond the inlet",e.cargo.slice(0,e.admitted).any(func(b):return b.position.z> -0.5))
	check("Delivered objects remain real grabbable bodies",e.cargo[0].enabled and e.cargo[1].enabled and not e.cargo[0].freeze)
	var origin=XROrigin3D.new();world.add_child(origin)
	var controller=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=e.gate_grip.global_position;e.gate_grip.pick_up(hand)
	check("Real XRTools hand can hold gate grip",e.gate_grip.is_picked_up())
	var from=controller.global_position
	var pivot=e.joints[0].global_position
	var local_pivot=e.gate.to_local(pivot)
	var drift=0.0;var max_turn=0.0;var max_rock=0.0
	e.gate_grip.action_pressed.emit(e.gate_grip)
	for i in range(240):
		controller.global_position=from.lerp(e.to_global(Vector3(-1.6,1.8,2.8)),minf(float(i)/90,1))
		await physics_frame
		drift=maxf(drift,e.gate.to_global(local_pivot).distance_to(pivot))
		max_turn=maxf(max_turn,absf(e.gate.rotation.y));max_rock=maxf(max_rock,absf(e.receiver.rotation.x))
	measurements.gate_turn=max_turn;measurements.hinge_drift=drift;measurements.receiver_rock=max_rock
	measurements.after_hand={"admitted":e.admitted,"passed":e.passed_gate.size(),"spilled":e.spilled.size()}
	check("Pulling the grip opens the gate",max_turn>0.45)
	check("Hand does not detach hinge",drift<0.08)
	check("Held trigger selects flood",e.flood)
	check("Reset refuses a held control",not e.reset())
	e.gate_grip.action_released.emit(e.gate_grip);e.gate_grip.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	await wait(8)
	check("Flood ends when trigger and grip release",not e.flood)
	check("Cargo crosses gate through contact",e.passed_gate.size()>0)
	check("Consequences include a spill",e.spilled.size()>0)
	var admitted=e.admitted;e.feed_running=false;await wait(1)
	check("Pausing feed keeps the aftermath",e.admitted==admitted and e.cargo.slice(0,admitted).all(func(b):return b.visible and b.collision_layer==4))
	check("No body count growth or nonfinite state",e.bodies.size()==35 and e.bodies.all(func(b):return b.transform.is_finite() and b.linear_velocity.is_finite()))
	controller.global_position=e.cargo[1].global_position;e.cargo[1].pick_up(hand)
	check("Student can pick up a delivered chair",e.cargo[1].is_picked_up())
	check("Reset refuses held cargo",not e.reset())
	e.cargo[1].let_go(hand,Vector3.ZERO,Vector3.ZERO)
	check("Local reset accepted after release",e.reset())
	await wait(0.2)
	check("Reset parks cargo and clears the counters",e.admitted==0 and e.passed_gate.is_empty() and e.spilled.is_empty() and e.cargo.all(func(b):return b.freeze and not b.visible and b.collision_layer==0))
	# A blocked inlet must wait, not instantiate bodies inside another body.
	var obstacle=StaticBody3D.new();obstacle.collision_layer=4;obstacle.position=e.INLET;world.add_child(obstacle)
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3.ONE;collision.shape=shape;obstacle.add_child(collision)
	await physics_frame;await physics_frame
	check("Blocked inlet postpones delivery",not e.try_delivery() and e.admitted==0 and e.blocked)
	obstacle.queue_free();await physics_frame;await physics_frame
	check("Clear inlet accepts the next delivery",e.try_delivery() and e.admitted==1)
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"physics_engine":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"Real Jolt contact, joints, inherited XRTools pickup, supplied hand motion and reset. Not a headset comfort or Quest performance test."}
	FileAccess.open("res://ada_run/prefab_overflow_tests.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("PREFAB OVERFLOW ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
