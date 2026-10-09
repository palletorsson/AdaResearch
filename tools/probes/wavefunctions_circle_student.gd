extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[circle] ", "PASS " if value else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := "res://doc/book/studies/wavefunctions-lineage/04_circle_coordinates.gd"
    var report := "res://doc/book/iterations/2026-10-08-unit-circle-two-coordinates/student-test.json"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="):source=argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="):report=argument.trim_prefix("--report=")
    var Lesson = load(source)
    var lesson = Lesson.new()
    lesson.position=Vector3(4,2,7);lesson.rotation.y=PI/3;lesson.running=false
    root.add_child(lesson)
    check("complete program creates sphere, graph marker and readout",lesson.point!=null and lesson.marker.mesh is BoxMesh and lesson.label.text!="")
    check("carried point remains 14 cm sphere",lesson.point.get_child(0).mesh is SphereMesh and is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    check("prescribed marker cannot be grabbed or collide",not lesson.point.enabled and lesson.point.freeze and lesson.point.collision_layer==0 and lesson.point.collision_mask==0)
    var offsets := [Vector3.RIGHT,Vector3.UP,Vector3.LEFT,Vector3.DOWN]
    for i in range(4):
        var theta := i*PI/2
        lesson.angle=theta;lesson.draw_state()
        check("quarter turn %d has correct signed offsets" % i,lesson.point.position.is_equal_approx(lesson.centre+offsets[i]))
        check("quarter turn %d graph shares height" % i,is_equal_approx(lesson.marker.position.y,lesson.point.position.y))
        check("quarter turn %d graph X measures angle" % i,is_equal_approx(lesson.marker.position.x,lesson.centre.x+1.6+i))
    check("full turn closes circle",lesson.circle_position(TAU).is_equal_approx(lesson.circle_position(0)))
    check("full turn spans four metre graph",absf(lesson.graph_position(TAU).x-lesson.graph_position(0).x-4)<0.00001)
    lesson.angle=0;lesson.running=true;lesson._process(1.0)
    check("one second is quarter turn",absf(lesson.angle-PI/2)<0.00001)
    lesson.angle=0
    for i in range(60):lesson._process(1.0/60)
    check("sixty smaller steps reach same angle",absf(lesson.angle-PI/2)<0.00001)
    lesson._process(3.25)
    check("angle wraps without growing the graph",absf(lesson.angle-PI/8)<0.00001)
    lesson.running=false
    var stopped: float=lesson.angle
    lesson._process(2)
    check("pause preserves angular state",is_equal_approx(stopped,lesson.angle))
    var variation = Lesson.new()
    variation.centre=Vector3(0.5,1.5,0);variation.radius=0.5;variation.running=false
    root.add_child(variation)
    check("independent variation predicts top position",variation.circle_position(PI/2).is_equal_approx(Vector3(0.5,2,0)))
    var constant_radius := true
    for i in range(30):constant_radius=constant_radius and absf(variation.circle_position(i*0.31).distance_to(variation.centre)-0.5)<0.00001
    check("translated centre stays outside radius multiplication",constant_radius)
    check("smaller radius retains graph angle scale",is_equal_approx(variation.graph_position(TAU).x-variation.graph_position(0).x,4))
    lesson.angle=PI/4;lesson.draw_state()
    var radius_rod: MeshInstance3D=lesson.rods[0]
    var rod_end: Vector3=radius_rod.to_global(Vector3(0,radius_rod.mesh.height/2,0))
    check("carried line endpoint meets sphere after parent rotation",rod_end.distance_to(lesson.point.global_position)<0.0001)
    check("independent instance does not mutate original radius",lesson.radius==1)
    lesson.queue_free();variation.queue_free()
    await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Printed program executed in Godot; teacher-authored tests, not an independent student or headset trial."},"  "))
    quit(0 if failures.is_empty() else 1)
