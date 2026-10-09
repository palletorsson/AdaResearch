extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[synthesis] ","PASS " if value else "FAIL ",title)
func settle() -> void:
    for i in range(3):await physics_frame
    await process_frame
func choose(lesson: Node3D, h: int, amount: float) -> void:
    var p: Vector3=lesson.points[h].position
    p.y=0.8+0.8*amount
    lesson.points[h].global_position=lesson.to_global(p)
    lesson._process(0)
func run() -> void:
    await process_frame
    var source: String;var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var lesson=load(source).new()
    lesson.position=Vector3(8,3,5);lesson.rotation.y=PI/3
    root.add_child(lesson);lesson.set_process(false);await settle()
    check("complete program builds five pickable points and six line rows",lesson.points.size()==5 and lesson.rows.size()==6 and lesson.rows.all(func(r):return r.size()==64))
    check("points retain original radius and independent meshes",lesson.points.all(func(p):return p.enabled and p.freeze and is_equal_approx(p.get_child(0).mesh.radius,0.14)) and lesson.points[0].get_child(0).mesh!=lesson.points[1].get_child(0).mesh)
    check("starts held with declared baseline",lesson.held and lesson.phase==0 and lesson.amounts==[1.0,0.5,1.0/3.0,0.25,0.2])
    check("third contribution is negative at PI/2",absf(lesson.contribution(2,PI/2)+1.0/3.0)<0.00001)
    check("known signed sum at PI/2",absf(lesson.sum_at(PI/2)-(1-1.0/3.0+0.2))<0.00001)
    check("second harmonic has two returns",absf(lesson.contribution(1,PI/4)-0.5)<0.00001 and absf(lesson.contribution(1,3*PI/4)+0.5)<0.00001)
    choose(lesson,2,0)
    check("removing negative contribution raises total",absf(lesson.sum_at(PI/2)-1.2)<0.00001)
    check("working edits preserve the original baseline",absf(lesson.baseline[2]-1.0/3.0)<0.00001)
    lesson.points[4].action()
    check("actual H5 action restores all coefficients and handle heights",lesson.amounts==[1.0,0.5,1.0/3.0,0.25,0.2] and absf(lesson.points[2].position.y-(0.8+0.8/3))<0.00001)
    for h in range(1,5):choose(lesson,h,0)
    var pure:=true
    for i in range(61):
        var a:=TAU*i/60.0
        pure=pure and absf(lesson.sum_at(a)-sin(a))<0.00001
    check("one coefficient recovers a pure sine",pure)
    choose(lesson,0,0)
    check("zero amounts produce a zero signal",absf(lesson.sum_at(0.37))<0.00001 and absf(lesson.sum_at(1.1))<0.00001)
    choose(lesson,1,0.42)
    check("height mapping uses local frame in translated rotated host",absf(lesson.amounts[1]-0.42)<0.00001)
    lesson.points[1].position.x=8;lesson._process(0)
    check("horizontal movement does not change identity or amount",absf(lesson.amounts[1]-0.42)<0.00001 and lesson.amounts[0]==0)
    choose(lesson,1,-10);choose(lesson,3,10)
    check("coefficient range clamps both ends",lesson.amounts[1]==0 and lesson.amounts[3]==1)
    lesson.restore_baseline();lesson.phase=0.31;lesson._process(1)
    check("held time stops while amounts remain editable",is_equal_approx(lesson.phase,0.31))
    lesson.points[0].action();lesson._process(0.5)
    check("actual H1 action runs common fundamental at 0.2 Hz",not lesson.held and absf(lesson.phase-(0.31+TAU*0.1))<0.00001)
    lesson.points[0].action();var stored_phase: float=lesson.phase
    choose(lesson,2,0.7);lesson.points[4].action()
    check("baseline action preserves phase and hold state",lesson.held and lesson.phase==stored_phase)
    lesson.held=false;lesson.restore_baseline()
    check("baseline action preserves running state too",not lesson.held and lesson.phase==stored_phase)
    lesson.phase=TAU-0.1;lesson._process(1)
    check("running phase wraps without changing cycle",absf(lesson.phase-(TAU*0.2-0.1))<0.00001)
    lesson.held=true;lesson.phase=0;lesson.restore_baseline()
    var periodic:=true
    for i in range(61):
        var a:=TAU*i/60.0
        periodic=periodic and absf(lesson.sum_at(a+TAU)-lesson.sum_at(a))<0.00001
    check("integer harmonics repeat over a fundamental cycle",periodic)
    var raw: float=lesson.sum_at(PI/2)
    check("sum and components share declared gain",absf(lesson.plot_position(5,0.25).y-lesson.row_height(5)-0.16*raw)<0.00001 and absf(lesson.plot_position(0,0.25).y-lesson.row_height(0)-0.16)<0.00001)
    var geometry:=true
    for row in range(6):
        for i in range(64):
            var a: Vector3=lesson.plot_position(row,float(i)/64)
            var b: Vector3=lesson.plot_position(row,float(i+1)/64)
            var line: MeshInstance3D=lesson.rows[row][i]
            geometry=geometry and line.position.is_equal_approx((a+b)*0.5) and absf(line.mesh.height-a.distance_to(b))<0.00001
    check("every rendered segment joins its two sampled positions",geometry)
    check("readout states current recipe hold phase and gain",lesson.label.text.contains("H3 0.333") and lesson.label.text.contains("HOLD") and lesson.label.text.contains("0.16 m"))
    var odd=load(source.get_base_dir()+"/12_odd_recipe.gd").new()
    odd.position=Vector3(-10,0,0);root.add_child(odd);odd.set_process(false);await settle()
    var reversal:=true
    for i in range(61):
        var a:=TAU*i/60.0
        reversal=reversal and absf(odd.sum_at(a+PI)+odd.sum_at(a))<0.00001
    check("independent odd recipe reverses after half a cycle",reversal and odd.amounts[1]==0 and odd.amounts[3]==0)
    check("even terms break that symmetry in original recipe",absf(lesson.sum_at(PI/4)+lesson.sum_at(PI/4+PI))>0.9)
    var old_value: float=lesson.sum_at(0.42)
    lesson.sum_at(1.1);lesson.sum_at(2.8)
    check("sampling history never accumulates into next sum",lesson.sum_at(0.42)==old_value)
    lesson.queue_free();odd.queue_free();await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed files; native numeric, action and rendering checks. Teacher-authored, not independent student or headset evidence."},"  "))
    quit(0 if failures.is_empty() else 1)
