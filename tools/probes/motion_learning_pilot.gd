extends SceneTree
## Teacher check: observe reconstructed code and a separately authored variation.
const PACKET = "res://doc/book/iterations/2026-10-08-motion-build-and-investigate/ghost-attempt/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var world: Node3D

func _initialize() -> void:
    run.call_deferred()

func check(label: String, condition: bool) -> void:
    checks.append({"label": label, "passed": condition})
    if not condition:
        failures.append(label)
        push_error(label)

func frames(count: int) -> void:
    for i in range(count):
        await physics_frame

func bodies(node: Node) -> Array:
    var result: Array = []
    for child in node.get_children():
        if child is RigidBody3D:
            result.append(child)
    result.sort_custom(func(a, b): return a.mass < b.mass)
    return result

func start(node: Node) -> void:
    var buttons = node.get("buttons")
    check("reconstruction has one declared start control", buttons is Dictionary and buttons.size() == 1)
    if buttons is Dictionary and not buttons.is_empty():
        buttons.values()[0].pressed.emit()

func mount(file: String) -> Node3D:
    var script = load(PACKET + file)
    check(file + " loads", script != null and script.can_instantiate())
    if script == null or not script.can_instantiate():
        return null
    var node = script.new()
    world.add_child(node)
    await frames(3)
    return node

func run() -> void:
    await process_frame
    world = Node3D.new()
    root.add_child(world)
    var original = await mount("03_mass.gd")
    if original == null:
        finish()
        return
    var points = bodies(original)
    check("printed reconstruction creates three physical points", points.size() == 3)
    if points.size() != 3:
        finish()
        return
    check("masses start at 1, 2, 4 kg", points[0].mass == 1 and points[1].mass == 2 and points[2].mass == 4)
    start(original)
    await frames(64)
    var first = points.map(func(p): return p.linear_velocity.length())
    observations.printed_speeds = first
    check("one pulse gives 1, 0.5, 0.25 m/s", absf(first[0]-1)<0.04 and absf(first[1]-0.5)<0.03 and absf(first[2]-0.25)<0.02)
    await frames(12)
    check("printed points coast after their push ends", absf(points[0].linear_velocity.length()-first[0])<0.01)
    start(original)
    await frames(64)
    check("a second completed pulse adds to existing velocity", absf(points[0].linear_velocity.length()-2)<0.05 and absf(points[1].linear_velocity.length()-1)<0.04)
    original.queue_free()
    await process_frame
    await frames(2)

    var variation = await mount("comparison.gd")
    if variation == null:
        finish()
        return
    points = bodies(variation)
    check("independent construction makes two point bodies", points.size() == 2)
    if points.size() != 2:
        finish()
        return
    check("independent masses are 1 and 2 kg", points[0].mass == 1 and points[1].mass == 2)
    var starts = points.map(func(p): return p.global_position)
    start(variation)
    await frames(61)
    var at_one = points.map(func(p): return p.linear_velocity.length())
    check("at one second the lighter point is faster", absf(at_one[0]-1)<0.04 and absf(at_one[1]-0.5)<0.04)
    await frames(61)
    var at_two = points.map(func(p): return p.linear_velocity.length())
    var distances: Array = []
    for i in range(2):
        distances.append(points[i].global_position.distance_to(starts[i]))
    observations.comparison = {"at_one_second": at_one, "at_two_seconds": at_two, "distances_after_two_seconds": distances}
    check("different duration compensates for different mass", absf(at_two[0]-1)<0.04 and absf(at_two[1]-1)<0.04)
    check("equal final speed leaves different distances", absf(distances[0]-1.5)<0.09 and absf(distances[1]-1.0)<0.09 and distances[0]>distances[1]+0.4)
    var saved_reading: String = variation.reading.text
    await frames(20)
    check("both independently timed pushes end and retain velocity", absf(points[0].linear_velocity.length()-at_two[0])<0.01 and absf(points[1].linear_velocity.length()-at_two[1])<0.01)
    check("the distance snapshot remains readable while points coast", variation.reading.text==saved_reading)
    variation.queue_free()
    await process_frame
    await frames(2)

    var exhibit = load("res://commons/artifacts/force_play/encounter.gd").new()
    exhibit.kind = "mass"
    exhibit.position.x = 50
    world.add_child(exhibit)
    await frames(3)
    check("current museum uses PUSH 1 s and RESET", exhibit.buttons.has("PUSH 1 s") and exhibit.buttons.has("RESET"))
    check("current museum uses three identical sphere sizes", exhibit.bodies.size()==3 and exhibit.bodies[0].sphere.radius==exhibit.bodies[2].sphere.radius)
    check("lanes remove downward and sideways motion", exhibit.bodies.all(func(p): return p.gravity_scale==0 and p.axis_lock_linear_y and p.axis_lock_linear_x))
    exhibit.buttons["PUSH 1 s"].pressed.emit()
    await frames(64)
    var speeds = exhibit.bodies.map(func(p): return p.linear_velocity.length())
    observations.museum_speeds = speeds
    check("actual museum preserves the same mass comparison", absf(speeds[0]-1)<0.04 and absf(speeds[1]-0.5)<0.03 and absf(speeds[2]-0.25)<0.02)
    check("museum trails actually contain movement", exhibit.trails.size()==3 and exhibit.trails.values()[0].size()>2)
    exhibit.set_physics_process(false)
    for p in exhibit.bodies:
        p.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
        p.freeze = true
    exhibit.trails.clear()
    for sample in range(80):
        exhibit.bodies[0].position.z = sample * 0.1
        exhibit.record_trails()
    var trace = exhibit.trails[exhibit.bodies[0].get_instance_id()]
    check("trace is bounded to 64 samples", trace.size()==64)
    check("bounded trace discards the first place and retains the latest", trace.front().z>1 and absf(trace.back().z-7.9)<0.01)
    exhibit.set_physics_process(true)
    check("reset offers a new beginning", exhibit.reset())
    await frames(4)
    check("reset clears velocity and restores places", exhibit.bodies.all(func(p): return p.linear_velocity.length()<0.01) and exhibit.bodies[0].position.distance_to(exhibit.homes[0].origin)<0.01)
    exhibit.queue_free()
    await process_frame
    finish()

func finish() -> void:
    var result = {"passed": failures.is_empty(), "checks": checks, "failures": failures, "observations": observations,
        "scope": "Actual Jolt integration of code reconstructed from printed lessons, an independent AI-authored variation, and the installed mass artifact. AI reconstruction is not evidence of human learning or physical headset comfort."}
    FileAccess.open("res://ada_run/motion_learning_pilot.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    print("MOTION LEARNING PILOT ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
