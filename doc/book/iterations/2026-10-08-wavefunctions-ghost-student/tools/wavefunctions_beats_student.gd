extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[beats] ","PASS " if value else "FAIL ",title)
func settle() -> void:
    for i in range(3):await physics_frame
    await process_frame
func peak(lesson: Node3D, time: float) -> float:
    var maximum:=0.0
    for i in range(257):maximum=maxf(maximum,absf(lesson.values_at(time,TAU*i/256.0).z))
    return maximum
func choose(lesson: Node3D, height: float) -> void:
    lesson.point.global_position=lesson.to_global(Vector3(-2.1,height,0.5))
    lesson.point.action()

func run() -> void:
    await process_frame
    var source: String;var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var lesson=load(source).new()
    lesson.position=Vector3(8,3,5);lesson.rotation.y=PI/3
    root.add_child(lesson);lesson.set_process(false);await settle()
    check("complete program builds three rows and both labels",lesson.rows.size()==3 and lesson.rows.all(func(r):return r.size()==64) and lesson.label.text!="" and lesson.values_label.text!="")
    check("carried PointBody remains pickable at its original radius",lesson.point.enabled and lesson.point.freeze and is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    choose(lesson,1.7)
    check("initial pair is 4 and 4.5 Hz",is_equal_approx(lesson.frequency_a,4.0) and is_equal_approx(lesson.frequency_b,4.5))
    check("shared start reinforces to raw amplitude two",lesson.values_at(0,PI/2).is_equal_approx(Vector3(1,1,2)))
    check("one second cancels substantial opposing sources",lesson.values_at(1,PI/2).is_equal_approx(Vector3(1,-1,0)))
    check("two seconds restores alignment",absf(peak(lesson,2)-2)<0.001)
    check("opposition applies across the entire row",peak(lesson,1)<0.0001)
    check("halfway envelope agrees with cosine identity",absf(peak(lesson,0.5)-sqrt(2.0))<0.001)
    lesson.elapsed=0;lesson.draw_state()
    check("gain is applied only to plotted sum",absf(lesson.plot_position(2,0.125).y-1.37)<0.00001 and lesson.values_at(0,PI/2).z>1.99)
    check("row labels explicitly identify half sum",lesson.get_children().any(func(n):return n is Label3D and n.text=="(A+B) / 2"))
    var line_ok:=true
    for row in range(3):
        for i in range(64):
            var a: Vector3=lesson.plot_position(row,float(i)/64)
            var b: Vector3=lesson.plot_position(row,float(i+1)/64)
            var line: MeshInstance3D=lesson.rows[row][i]
            line_ok=line_ok and line.position.is_equal_approx((a+b)*0.5) and absf(line.mesh.height-a.distance_to(b))<0.00001
    check("every line joins the calculated displayed samples",line_ok)
    lesson.elapsed=0.4
    lesson.point.global_position=lesson.to_global(Vector3(-2.1,1.45,0.5));lesson.draw_state()
    check("moving the point previews without changing running pair",is_equal_approx(lesson.candidate_frequency(),4.25) and is_equal_approx(lesson.frequency_b,4.5) and is_equal_approx(lesson.elapsed,0.4))
    lesson.point.action()
    check("actual pickup action applies local height and resets clock",is_equal_approx(lesson.frequency_b,4.25) and lesson.elapsed==0)
    check("smaller gap cancels at two seconds and aligns at four",peak(lesson,2)<0.0001 and absf(peak(lesson,4)-2)<0.001)
    check("readout names four-second beat",lesson.label.text.contains("4.00 s"))
    choose(lesson,0.95)
    check("reversing frequency order keeps beat period",is_equal_approx(lesson.frequency_b,3.75) and peak(lesson,2)<0.0001 and absf(peak(lesson,4)-2)<0.001)
    choose(lesson,1.2)
    check("equal frequencies avoid division by zero",lesson.label.text.contains("equal frequencies") and not lesson.label.text.contains("inf"))
    var equal:=true
    for t in [0.137,0.54,1.72,8.03]:
        var v: Vector3=lesson.values_at(t,0.73)
        equal=equal and absf(v.z-2*v.x)<0.00001
    check("equal-frequency pair retains shared phase",equal)
    choose(lesson,100)
    check("high point clamps frequency preview",is_equal_approx(lesson.frequency_b,4.5))
    choose(lesson,-100)
    check("low point clamps frequency preview",is_equal_approx(lesson.frequency_b,3.5))
    choose(lesson,1.7);lesson._process(0.25)
    check("process advances one shared clock",is_equal_approx(lesson.elapsed,0.25))
    var variant=load(source.get_base_dir()+"/11_faster_pair.gd").new()
    variant.position=Vector3(-10,0,0);root.add_child(variant);variant.set_process(false);await settle()
    check("independent faster-pair script chooses 5 and 5.25 Hz",is_equal_approx(variant.frequency_a,5) and is_equal_approx(variant.frequency_b,5.25))
    check("faster sources retain four-second envelope",peak(variant,2)<0.0001 and absf(peak(variant,4)-2)<0.001 and variant.label.text.contains("4.00 s"))
    check("higher carrier changes intermediate source value",absf(variant.values_at(0.07,0).x-lesson.values_at(0.07,0).x)>0.1)
    lesson.queue_free();variant.queue_free();await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed files; actual pickup action callback, numeric and rendered signal checks. No headset or independent-student claim."},"  "))
    quit(0 if failures.is_empty() else 1)
