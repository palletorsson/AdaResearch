extends SceneTree
## Actual Jolt bodies, timer cadence, hand ownership and reset races.
var checks: Array=[]
var failures: Array=[]
var measurements: Dictionary={}
var e: Node3D

func _initialize() -> void:run.call_deferred()
func check(message: String,good: bool) -> void:
	checks.append({"name":message,"passed":good})
	if not good:failures.append(message);push_error(message)
func wait(seconds: float) -> void:await create_timer(seconds).timeout

func run() -> void:
	e=load("res://commons/artifacts/force_play/friction.tscn").instantiate();root.add_child(e)
	var initial_count=e.bodies.size()
	await wait(6.8)
	check("Automatic drop waits seven seconds",e.slope_drop_count==0)
	await wait(0.4)
	check("First interval drops exactly one body",e.slope_drop_count==1 and e.slope_drop_lane==1 and not e.members.runners[0].freeze)
	check("Other three comparison bodies wait their turn",e.members.runners.slice(1).all(func(b):return b.freeze))
	var first_height=e.members.runners[0].position.y
	await wait(0.5)
	check("Dropped body falls under real gravity",e.members.runners[0].position.y<first_height-0.15)
	await wait(6.5)
	check("Second interval advances to the ball lane",e.slope_drop_count==2 and e.slope_drop_lane==2)
	await wait(14)
	check("Four intervals cover all four lanes",e.slope_drop_count==4 and e.slope_drop_lane==0)
	measurements.after_28_seconds=e.members.runners.map(func(b):return [str(b.position),str(b.linear_velocity)])
	check("Repeated drops stay bounded and finite",e.bodies.size()==initial_count and e.members.runners.all(func(b):return b.position.is_finite() and b.linear_velocity.length()<20))
	e.buttons["AUTO / PAUSE"].pressed.emit()
	await wait(7.2)
	check("Pause prevents automatic drops",e.slope_drop_count==4 and not e.slope_auto)
	e.buttons["AUTO / PAUSE"].pressed.emit()
	check("Resume gives a fresh seven-second interval",e.slope_auto and e.slope_drop_clock<0.1)
	# Accelerate only these edge-case checks; the four timed intervals above
	# used real engine ticks. Keep hand-owned objects out of recycling.
	e.members.runners[0].set_meta("capability_desktop_held",true)
	var held_transform=e.members.runners[0].transform
	e.slope_drop_clock=6.98;await wait(0.1)
	check("Held body is skipped and next lane drops",e.slope_drop_lane==2 and e.slope_drop_count==5)
	check("Drop scheduler does not move a held body",e.members.runners[0].transform.origin.distance_to(held_transform.origin)<0.1)
	e.members.runners[0].remove_meta("capability_desktop_held")
	for b in e.members.runners:b.set_meta("capability_desktop_held",true)
	e.slope_drop_clock=6.98;await wait(0.1)
	check("All bodies held means no forced release",e.slope_drop_count==5)
	for b in e.members.runners:b.remove_meta("capability_desktop_held")
	e.drop_next_slope_body();e.reset()
	await physics_frame;await physics_frame;await process_frame
	check("Reset cancels a pending drop and restarts the cycle",e.slope_drop_count==0 and e.slope_drop_lane==0 and e.slope_auto)
	check("Pending release cannot unfreeze the reset bodies",e.members.runners.all(func(b):return b.freeze))
	e.buttons["RELEASE"].pressed.emit()
	check("Manual comparison releases together and pauses auto",not e.slope_auto and e.members.runners.all(func(b):return not b.freeze))
	await wait(3)
	check("Smooth cube still travels farther than rough cube",e.members.runners[0].position.z>e.members.runners[2].position.z+0.5)
	check("Rough ball still rolls",e.members.runners[3].angular_velocity.length()>0.5)
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"physics_engine":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"Real physics-tick drop cadence and Jolt motion; simulated hand ownership. Museum walk test is separate."}
	FileAccess.open("res://ada_run/slope_access_and_drops.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("SLOPE DROPS ",checks.size()-failures.size(),"/",checks.size())
	e.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
