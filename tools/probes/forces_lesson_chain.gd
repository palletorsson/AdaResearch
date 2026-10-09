extends SceneTree
const BASE = "res://doc/book/studies/forces-point-lineage/"
var checks: Array = []
var failures: Array = []
var world: Node3D
var lesson: Node3D

func _initialize() -> void: run.call_deferred()
func check(label: String, good: bool) -> void:
    checks.append({"label":label,"passed":good})
    if not good: failures.append(label); push_error(label)
func frames(n: int) -> void:
    for i in n: await physics_frame
func mount(file: String) -> void:
    if is_instance_valid(lesson):
        lesson.queue_free()
        await process_frame
    var script = load(BASE + file)
    if script == null or not script.can_instantiate():
        check(file + " compiles",false)
        finish()
        return
    lesson = script.new()
    world.add_child(lesson)
    await frames(2)
    check(file + " constructs inside a supplied world",is_instance_valid(lesson))

func run() -> void:
    await process_frame
    world=Node3D.new();root.add_child(world)
    for file in ["point_body.gd","free_point.gd","study.gd"]:
        var dependency=load(BASE+file)
        check(file+" loads",dependency!=null and dependency.can_instantiate())
    await mount("01_vectors.gd")
    lesson.set_process(false)
    lesson.a.position=Vector3.ZERO;lesson.b.position=Vector3(3,4,0)
    var r: Dictionary=lesson.relation()
    check("3-4 displacement has length 5 and a unit direction",is_equal_approx(r.length,5) and r.direction.is_equal_approx(Vector3(0.6,0.8,0)))
    lesson.a.position+=Vector3(7,2,1);lesson.b.position+=Vector3(7,2,1)
    check("common translation preserves displacement",lesson.relation().displacement==r.displacement)
    check("projection plus remainder returns original vector",r.along_x+r.remainder==r.displacement)
    lesson.b.position=lesson.a.position
    check("coincident endpoints return finite zero direction",lesson.relation().direction==Vector3.ZERO)
    await mount("02_launch.gd")
    lesson.set_process(false)
    check("launch begins at its stated address",lesson.at(0)==lesson.START)
    check("landing returns to launch height",absf(lesson.at(lesson.duration()).y-lesson.START.y)<0.001)
    lesson.fire();lesson._process(0.4)
    check("actual marker reaches the analytical apex",absf(lesson.point.position.y-1.8)<0.001)
    lesson._process(8)
    check("long frame clamps landing and stops playback",not lesson.running and absf(lesson.point.position.y-1)<0.001)
    lesson.initial_velocity.x=6
    check("independent doubled horizontal speed doubles range",absf(lesson.at(0.8).x-lesson.START.x-4.8)<0.001)
    await mount("03_mass.gd")
    lesson.buttons["PUSH 1 s"].pressed.emit()
    await frames(70)
    var speeds: Array=lesson.points.map(func(p):return p.linear_velocity.z)
    check("real Jolt bodies receive 1 N s with inverse-mass response",absf(speeds[0]-1)<0.04 and absf(speeds[1]-0.5)<0.03 and absf(speeds[2]-0.25)<0.02)
    await frames(12)
    check("ending the force retains velocity",absf(lesson.points[0].linear_velocity.z-speeds[0])<0.01)
    check("familiar point mesh and collision have the same radius",lesson.points[0].get_child(0).mesh.radius==lesson.points[0].get_child(1).shape.radius)
    await mount("04_field.gd")
    check("vortex has no undefined centre direction",lesson.sample(Vector3.ZERO)==Vector3.ZERO)
    check("one sample contains inward and tangential acceleration",lesson.sample(Vector3(2,0,0)).is_equal_approx(Vector3(-1.3,0,2.8)))
    var velocity: Vector3=lesson.point.linear_velocity
    await frames(12)
    check("field force changes solver velocity",lesson.point.linear_velocity.x<velocity.x-0.1 and lesson.point.linear_velocity.z>velocity.z)
    await mount("05_drag.gd")
    check("drag at rest is zero",lesson.resistance(Vector3.ZERO,1,0.02)==Vector3.ZERO)
    check("uncapped drag quadruples when speed doubles",lesson.resistance(Vector3(2,0,0),1,0.001).is_equal_approx(lesson.resistance(Vector3(1,0,0),1,0.001)*4))
    check("drag cannot deliberately reverse velocity in one step",lesson.resistance(Vector3(10,0,0),1,1).length()<=10)
    lesson.buttons.DROP.pressed.emit();await frames(50)
    print("DRAG POINT ",lesson.point.position," / ",lesson.point.linear_velocity)
    check("released point actually falls into the drag region",lesson.point.position.y<2 and lesson.point.linear_velocity.y<0)
    await mount("06_spring.gd")
    check("rest length with no velocity produces no spring force",lesson.spring_force(Vector3(0,1,0),Vector3.ZERO)==Vector3.ZERO)
    check("extension pulls towards anchor",lesson.spring_force(Vector3(0,1.5,0),Vector3.ZERO).y>0)
    check("compression pushes away from anchor",lesson.spring_force(Vector3(0,0.5,0),Vector3.ZERO).y<0)
    check("damping opposes motion even at zero offset",lesson.spring_force(Vector3.ZERO,Vector3.RIGHT).x<0)
    var x: float=lesson.point.position.x
    await frames(24)
    check("released spring point turns back towards anchor",lesson.point.position.x<x)
    await mount("07_phase.gd")
    lesson.set_process(false);lesson.angles=[0.0,0.0]
    lesson.offset();lesson._process(6)
    check("same rate preserves the chosen phase offset",absf(fposmod(lesson.angles[1]-lesson.angles[0],TAU)-PI/4)<0.001)
    lesson.angles=[0.0,0.0];lesson.drift();lesson._process(30)
    check("4 percent rate difference accumulates 72 degrees in 30 seconds",absf(fposmod(lesson.angles[1]-lesson.angles[0],TAU)-deg_to_rad(72))<0.001)
    await mount("08_attraction.gd")
    check("softened coincident pair is finite",lesson.pair_force(Vector3.ZERO)==Vector3.ZERO)
    check("pair force reverses with displacement",lesson.pair_force(Vector3.RIGHT).is_equal_approx(-lesson.pair_force(Vector3.LEFT)))
    await frames(80)
    var momentum: Vector3=lesson.a.linear_velocity*lesson.a.mass+lesson.b.linear_velocity*lesson.b.mass
    check("real isolated pair retains zero total momentum",momentum.length()<0.001)
    check("both bodies curve; no fixed source",lesson.a.linear_velocity.x>0 and lesson.b.linear_velocity.x<0)
    await mount("09_support.gd")
    await frames(45)
    check("actual contact supports the cube",absf(lesson.load.position.y-1.3)<0.05)
    lesson.buttons["REMOVE SUPPORT"].pressed.emit();await frames(30)
    check("removing support lets Jolt produce the fall",lesson.load.position.y<0.7)
    await mount("10_impulse.gd")
    lesson.buttons["ROLL ONCE"].pressed.emit();await frames(2)
    check("one 3 N s impulse gives a 1 kg point about 3 m/s",absf(lesson.point.linear_velocity.z-3)<0.03)
    lesson.roll();await frames(2)
    check("held/repeated action does not stack the one-shot impulse",absf(lesson.point.linear_velocity.z-3)<0.03)
    await frames(44)
    check("collision transfers motion to the second point",lesson.target.linear_velocity.z>0.5)
    await mount("11_flight.gd")
    await test_flight()
    await test_focus()
    finish()

func test_flight() -> void:
    var origin=XROrigin3D.new();world.add_child(origin)
    var camera=XRCamera3D.new();camera.name="Camera";origin.add_child(camera)
    var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
    body.player_calibrate_height=false;body.eye_forward_offset=0;origin.add_child(body)
    var grips: Array=[]
    for side in ["left_hand","right_hand"]:
        var tracker=XRControllerTracker.new();tracker.name=side;tracker.type=XRServer.TRACKER_CONTROLLER;XRServer.add_tracker(tracker)
        var controller=XRController3D.new();controller.tracker=side;origin.add_child(controller)
        var grip=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(grip);grips.append(grip)
    await frames(3)
    for i in 2:
        lesson.points[i].pick_up(grips[i]);lesson.points[i].action_pressed.emit(grips[i])
    await frames(2)
    check("both student points find the real XRTools receiver",lesson.points.all(func(p):return p.receiver()==body))
    var court=load("res://commons/artifacts/force_capability_lab/force_capability_lab.gd").new();world.add_child(court)
    var acceleration: Vector3=court.thrust_acceleration(body)
    check("two held points request forward 22 m/s²",acceleration.is_equal_approx(Vector3(0,0,-22)))
    var next: Vector3=court.carry_velocity(body,0.1,Vector3.ZERO)
    check("actual museum receiver applies thrust and gravity exactly once",next.is_equal_approx(Vector3(0,-0.98,-2.2)))
    for i in 2:lesson.points[i].action_released.emit(grips[i])
    check("release ends acceleration, not incoming motion",court.thrust_acceleration(body)==Vector3.ZERO and court.carry_velocity(body,0.1,Vector3(0,0,-2.2)).z< -2.19)
    for i in 2:lesson.points[i].let_go(grips[i],Vector3.ZERO,Vector3.ZERO)
    await frames(2)
    court.queue_free();origin.queue_free();await process_frame

func test_focus() -> void:
    for kind in ["springs","mutual","vortex","liquids","mass"]:
        var e=load("res://commons/artifacts/force_play/encounter.gd").new();e.kind=kind;world.add_child(e)
        await frames(3)
        if kind in ["springs","mutual","vortex"]:
            var expected=2 if kind=="mutual" else 1
            check(kind+": starts with a legible primary comparison",e.bodies.filter(func(b):return b.visible).size()==expected)
            check(kind+": hidden bodies are frozen without collision layers",e.bodies.all(func(b):return b.visible or (b.freeze and b.collision_layer==0)))
            if kind=="springs":
                check("spring focus hides and disables unused hand grips",e.grips.filter(func(g):return g.visible and g.enabled).size()==1)
                check("spring anchor remains; coupling rods are hidden",e.links.filter(func(l):return l.rod.visible).size()==1)
            e.action("PAIR / FIVE" if kind=="mutual" else "ONE / MANY");await frames(4)
            check(kind+": local control restores the whole experiment",e.bodies.all(func(b):return b.visible and not b.freeze))
            e.action("PAIR / FIVE" if kind=="mutual" else "ONE / MANY");await frames(4)
            check(kind+": reset preserves the selected starting mode",e.bodies.filter(func(b):return b.visible).size()==expected)
        if kind=="liquids":
            check("liquid starts with drag separated from buoyancy",not e.buoyancy_enabled)
            e.buttons.BUOYANCY.pressed.emit();check("nearby button adds the second force explicitly",e.buoyancy_enabled)
        if kind=="mass":
            check("mass push and reset are adjacent",e.buttons["PUSH 1 s"].position.distance_to(e.buttons.RESET.position)<1.3)
        e.queue_free();await process_frame;await frames(2)

func finish() -> void:
    var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,
        "physics":ProjectSettings.get_setting("physics/3d/physics_engine"),
        "scope":"Exact student scripts, real Jolt integration/contact, production focus controls and XRTools pickup/receiver with supplied controller poses. No physical-headset claim."}
    FileAccess.open("res://ada_run/forces_lesson_chain.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    print("FORCES LESSON CHAIN ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
