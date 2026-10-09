extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[neighbours] ", "PASS " if value else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := "res://doc/book/studies/wavefunctions-lineage/05_neighbour_motion.gd"
    var report := "res://doc/book/iterations/2026-10-08-wave-propagation-between-points/student-test.json"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="):source=argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="):report=argument.trim_prefix("--report=")
    var Lesson = load(source)
    var lesson = Lesson.new()
    lesson.running=false;lesson.position=Vector3(8,0,7);lesson.rotation.y=PI/3
    root.add_child(lesson)
    check("complete program creates nine points, eight rods and its label",lesson.points.size()==9 and lesson.links.size()==8 and lesson.label.text!="")
    check("same PointBody geometry returns",lesson.points.all(func(p):return p.get_child(0).mesh is SphereMesh and is_equal_approx(p.get_child(0).mesh.radius,0.14)))
    check("arrays alone govern motion",lesson.points.all(func(p):return p.freeze and not p.enabled and p.collision_layer==0 and p.collision_mask==0))
    check("one raised centre is the release condition",is_equal_approx(lesson.displacement[4],0.6) and lesson.displacement.filter(func(h):return h!=0).size()==1 and lesson.velocity.all(func(v):return v==0))
    var dt := 1.0/60.0
    lesson.step(dt)
    check("centre first acceleration is -16.8 m/s squared",absf(lesson.velocity[4]+0.28)<0.000001)
    check("immediate neighbours first velocities both +0.12 m/s",absf(lesson.velocity[3]-0.12)<0.000001 and absf(lesson.velocity[5]-0.12)<0.000001)
    check("first neighbour displacement uses new velocity",absf(lesson.displacement[3]-0.002)<0.000001 and absf(lesson.displacement[5]-0.002)<0.000001)
    check("centre first height uses new velocity",absf(lesson.displacement[4]-(0.6-0.28/60.0))<0.000001)
    check("far points do not respond in this first step",lesson.displacement[2]==0 and lesson.displacement[6]==0)
    check("clock counts simulated seconds",absf(lesson.elapsed-dt)<0.000001)
    lesson.step(dt)
    check("second step reaches next neighbours",lesson.displacement[2]>0 and lesson.displacement[6]>0)
    var symmetric := true
    for frame in range(180):
        lesson.step(dt)
        for i in range(9):symmetric=symmetric and absf(lesson.displacement[i]-lesson.displacement[8-i])<0.00001
    check("propagation stays mirror symmetric",symmetric)
    lesson.draw_state()
    check("horizontal addresses remain fixed",lesson.points[0].position.x==-2 and lesson.points[8].position.x==2 and lesson.points.all(func(p):return p.position.z==0))
    check("drawing follows the retained state",absf(lesson.points[4].position.y-1.4-lesson.displacement[4])<0.000001)
    var link: MeshInstance3D=lesson.links[3]
    check("rod meets point through transformed parent",link.to_global(Vector3(0,link.mesh.height/2,0)).distance_to(lesson.points[4].global_position)<0.0001)
    var stopped: Array=lesson.displacement.duplicate()
    lesson._physics_process(2.0)
    check("paused physics callback preserves state",lesson.displacement==stopped)
    lesson.coupling=0.0;lesson.reset()
    for frame in range(120):lesson.step(dt)
    check("uncoupled neighbours remain exactly still",lesson.displacement.filter(func(h):return h!=0).size()==1)
    check("uncoupled centre still oscillates",absf(lesson.displacement[4])>0.01 and absf(lesson.displacement[4]-0.6)>0.1)
    lesson.draw_state()
    check("uncoupled rods disappear",lesson.links.all(func(l):return not l.visible))
    lesson.coupling=12;lesson.reset();lesson.draw_state()
    check("reset preserves coefficient and clears velocity/time",lesson.coupling==12 and lesson.elapsed==0 and lesson.velocity.all(func(v):return v==0))
    check("reset reconnects the drawn row",lesson.links.all(func(l):return l.visible))
    lesson.displacement.fill(0.2);lesson.velocity.fill(0.0);lesson.step(dt)
    check("equal offsets create no coupling force including ends",lesson.velocity.all(func(v):return absf(v+0.8/60.0)<0.000001))
    lesson.reset();lesson.displacement.fill(0.0);lesson.displacement[0]=0.6;lesson.step(dt)
    check("end point has one neighbour not a wrap or clamp",absf(lesson.velocity[0]+9.6/60.0)<0.000001 and lesson.velocity[8]==0)
    var full = Lesson.new();full.count=7;full.running=false;root.add_child(full)
    var half = Lesson.new();half.count=7;half.running=false;root.add_child(half)
    half.displacement[3]=0.3
    check("seven point variation has six links and centre index three",half.points.size()==7 and half.links.size()==6 and full.displacement[3]==0.6)
    var linear := true
    for frame in range(180):
        full.step(dt);half.step(dt)
        for i in range(7):linear=linear and absf(half.displacement[i]*2-full.displacement[i])<0.00001
    check("half initial displacement gives half motion at matching times",linear)
    check("variants do not share mutable arrays",full.displacement!=half.displacement and lesson.count==9)
    lesson.reset();lesson.mass=2;lesson.step(dt)
    check("same force at double mass halves acceleration",absf(lesson.velocity[4]+0.14)<0.000001)
    lesson.mass=1;lesson.reset()
    for frame in range(600):lesson.step(dt)
    check("declared step and damping keep motion bounded",lesson.displacement.all(func(h):return is_finite(h) and absf(h)<0.6))
    lesson.queue_free();full.queue_free();half.queue_free()
    await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed program in Godot. Teacher-authored behaviour checks, not independent student or headset validation."},"  "))
    quit(0 if failures.is_empty() else 1)
