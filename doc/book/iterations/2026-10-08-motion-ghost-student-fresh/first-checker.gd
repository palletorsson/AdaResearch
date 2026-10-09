extends SceneTree
## Teacher-owned checks, kept outside the fresh student's reading packet.
const BASE = "res://doc/book/iterations/2026-10-08-motion-ghost-student-fresh/attempt/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var world: Node3D
var lesson: Node3D

func _initialize() -> void:
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"label":label,"passed":passed})
    if not passed:
        failures.append(label)
        push_error(label)

func frames(n: int) -> void:
    for i in range(n):await physics_frame

func points() -> Array:
    var result: Array=[]
    for child in lesson.get_children():
        if child is RigidBody3D:result.append(child)
    result.sort_custom(func(a,b):return a.mass<b.mass)
    return result

func captions() -> String:
    var text=""
    for child in lesson.get_children():
        if child is Label3D:text+=child.text+"\n"
    return text

func start() -> bool:
    var buttons=lesson.get("buttons")
    var valid=buttons is Dictionary and buttons.size()==1
    check(lesson.name+": one supplied start button",valid)
    if valid:buttons.values()[0].pressed.emit()
    return valid

func mount(file: String, turn: float=0.0) -> bool:
    if is_instance_valid(lesson):
        lesson.queue_free()
        await process_frame
        await frames(2)
    var script=load(BASE+file)
    var valid=script!=null and script.can_instantiate()
    check(file+": compiles",valid)
    if not valid:return false
    lesson=script.new()
    lesson.name=file.get_basename()
    lesson.rotation.y=turn
    world.add_child(lesson)
    await frames(3)
    return true

func run() -> void:
    await process_frame
    world=Node3D.new()
    root.add_child(world)
    observations.physics=ProjectSettings.get_setting("physics/3d/physics_engine")
    observations.ticks_per_second=Engine.physics_ticks_per_second
    var ok=await reference()
    if ok:ok=await mass_edit()
    if ok:ok=await independent_comparison()
    if ok:ok=await independent_transfer()
    if ok:ok=await rotated_and_interrupted()
    if ok:await held_point()
    if is_instance_valid(lesson):lesson.queue_free()
    await process_frame
    finish()

func reference() -> bool:
    if not await mount("03_mass.gd"):return false
    var bodies=points()
    check("reference has three point bodies",bodies.size()==3)
    if bodies.size()!=3:return false
    check("reference masses are 1 / 2 / 4 kg",bodies[0].mass==1 and bodies[1].mass==2 and bodies[2].mass==4)
    if not start():return false
    await frames(64)
    var speed=bodies.map(func(p):return p.linear_velocity.length())
    observations.reference_speeds=speed
    check("reference pulse gives 1 / 0.5 / 0.25 m/s",absf(speed[0]-1)<0.04 and absf(speed[1]-0.5)<0.03 and absf(speed[2]-0.25)<0.02)
    await frames(15)
    check("ending the pulse retains velocity",absf(bodies[0].linear_velocity.length()-speed[0])<0.01)
    if not start():return false
    await frames(64)
    check("a second completed pulse adds to previous motion",absf(bodies[0].linear_velocity.length()-2)<0.05 and absf(bodies[2].linear_velocity.length()-0.5)<0.03)
    return true

func mass_edit() -> bool:
    if not await mount("03_mass_eight.gd"):return false
    var bodies=points()
    check("mass edit changes third body to 8 kg",bodies.size()==3 and bodies[-1].mass==8)
    if bodies.size()!=3 or not start():return false
    await frames(64)
    check("8 kg prediction survives actual integration",absf(bodies[-1].linear_velocity.length()-0.125)<0.01)
    check("caption identifies the changed mass",captions().contains("8 kg"))
    observations.mass_eight_speed=bodies[-1].linear_velocity.length()
    return true

func independent_comparison() -> bool:
    if not await mount("comparison.gd"):return false
    var bodies=points()
    check("independent comparison makes 1 kg and 2 kg",bodies.size()==2 and bodies[0].mass==1 and bodies[1].mass==2)
    if bodies.size()!=2:return false
    var origins=bodies.map(func(p):return p.global_position)
    if not start():return false
    await frames(61)
    check("independent clocks give 1 and 0.5 m/s after one second",absf(bodies[0].linear_velocity.length()-1)<0.04 and absf(bodies[1].linear_velocity.length()-0.5)<0.04)
    await frames(61)
    var distances: Array=[]
    for i in range(2):distances.append(bodies[i].global_position.distance_to(origins[i]))
    observations.comparison={"speeds":bodies.map(func(p):return p.linear_velocity.length()),"distances_at_122_steps":distances,"display":captions()}
    check("different masses and durations reach equal final speed",absf(bodies[0].linear_velocity.length()-1)<0.04 and absf(bodies[1].linear_velocity.length()-1)<0.04)
    check("equal final speeds leave approximately 1.5 m and 1 m journeys",absf(distances[0]-1.5)<0.09 and absf(distances[1]-1)<0.09)
    var snapshot=captions()
    check("comparison displays distance and velocity units",snapshot.contains("m/s") and snapshot.contains(" m"))
    await frames(24)
    check("saved distance reading survives continued coasting",captions()==snapshot)
    check("coasting remains physical motion after snapshot",bodies[0].global_position.distance_to(origins[0])>distances[0]+0.3)
    if not start():return false
    await frames(122)
    check("second comparison pulse adds another 1 m/s to each body",absf(bodies[0].linear_velocity.length()-2)<0.05 and absf(bodies[1].linear_velocity.length()-2)<0.05)
    check("another press permits a new retained measurement",captions()!=snapshot)
    return true

func independent_transfer() -> bool:
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"transfer-spec.json"))
    var mass=float(spec.mass_kg)
    var force=float(spec.force_newtons)
    var duration=float(spec.duration_seconds)
    var expected=force*duration/mass
    check("student's transfer prediction follows its chosen quantities",mass>0 and duration>0 and absf(float(spec.expected_final_speed)-expected)<0.0001)
    if not await mount("transfer.gd"):return false
    var bodies=points()
    check("transfer creates one body with its declared mass",bodies.size()==1 and absf(bodies[0].mass-mass)<0.001)
    if bodies.size()!=1 or not start():return false
    var origin=bodies[0].global_position
    await frames(int(ceil(duration*Engine.physics_ticks_per_second))+3)
    var speed=bodies[0].linear_velocity.length()
    var distance=bodies[0].global_position.distance_to(origin)
    observations.transfer={"spec":spec,"measured_speed":speed,"distance_near_push_end":distance}
    check("independent transfer reaches the predicted speed",absf(speed-expected)<0.04)
    check("independent transfer follows the expected displacement",absf(distance-0.5*force/mass*duration*duration)<0.13)
    await frames(15)
    check("independent transfer also coasts",absf(bodies[0].linear_velocity.length()-speed)<0.01)
    return true

func rotated_and_interrupted() -> bool:
    if not await mount("03_mass.gd",PI/2):return false
    var body=points()[0]
    if not start():return false
    await frames(64)
    check("turning the study turns the world-space force",body.linear_velocity.distance_to(lesson.global_basis*Vector3(0,0,1))<0.04)
    if not await mount("03_mass.gd"):return false
    body=points()[0]
    if not start():return false
    await frames(30)
    if not start():return false
    await frames(64)
    observations.mid_pulse_restart_speed=body.linear_velocity.length()
    check("pressing during the pulse restarts time without erasing velocity",absf(body.linear_velocity.length()-1.5)<0.06)
    return true

func held_point() -> void:
    if not await mount("03_mass.gd"):return
    var body=points()[0]
    var origin=XROrigin3D.new()
    world.add_child(origin)
    var tracker=XRControllerTracker.new()
    tracker.name="right_hand"
    tracker.type=XRServer.TRACKER_CONTROLLER
    XRServer.add_tracker(tracker)
    var controller=XRController3D.new()
    controller.tracker="right_hand"
    origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
    controller.add_child(pickup)
    await frames(3)
    body.pick_up(pickup)
    await frames(3)
    check("real XRTools pickup marks the point held",body.is_picked_up())
    if start():
        await frames(64)
        body.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
        await frames(15)
        check("held point misses the expired pulse; zero-speed release stays still",not body.is_picked_up() and body.linear_velocity.length()<0.02)
    origin.queue_free()
    XRServer.remove_tracker(tracker)
    await process_frame

func finish() -> void:
    var data={"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Fresh packet-only AI reconstruction and two independently authored exercises, executed in Godot/Jolt; pickup uses XRTools with supplied controller input. No physical headset or human learning claim."}
    FileAccess.open("res://ada_run/motion_ghost_student_fresh.json",FileAccess.WRITE).store_string(JSON.stringify(data,"  "))
    print("FRESH GHOST STUDENT ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
