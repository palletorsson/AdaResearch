extends "res://tools/probes/qfep_introduction_student.gd"

func release(study: Node3D) -> void:
    study.point.on_desktop_drop(study)
    for i in 3:await physics_frame

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"change_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position = Vector3(12,3,-7)
    parent.rotation = Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study = load(folder+"phi_study.gd").new()
    parent.add_child(study)
    await process_frame
    check("initialized readout declares authored pair and average rate",study.readout!=null and study.readout.text.contains("AUTHORED pair 0.20 -> 0.70 over 2s") and study.readout.text.contains("+0.250 per s"))
    check("all five declared actions present",study.buttons.size()==5)
    var point_id: int = study.point.get_instance_id()
    await drag(study,Vector3(2,study.LOW+study.TRAVEL,-2))
    check("local high hand maps to phi one under transformed parent",is_equal_approx(study.model.phi,1.0) and is_equal_approx(study.model.reading().contribution,0.5))
    var before = study.model.reading()
    for button in study.buttons:button.pressed.emit()
    check("buttons wait while the point is held",study.model.reading()==before and study.model.kept.is_empty() and not study.labels_revealed)
    await release(study)
    check("released sphere rests at parameter height",study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[2].pressed.emit()
    var kept = study.model.kept.duplicate()
    await drag(study,Vector3(0,study.LOW,0))
    check("negative weight reverses product without editing readings",is_equal_approx(study.model.phi,-1.0) and is_equal_approx(study.model.reading().contribution,-0.5) and study.model.earlier==0.2 and study.model.later==0.7)
    await release(study)
    before = study.model.reading()
    study.buttons[4].pressed.emit()
    check("earlier labels appear without changing any model value",study.labels_revealed and study.readout.text.contains("RESIST (-) / EMBRACE (+)") and study.model.reading()==before)
    study.buttons[4].pressed.emit()
    check("hiding labels also leaves model intact",not study.labels_revealed and study.model.reading()==before)
    study.buttons[1].pressed.emit()
    check("doubling interval halves rate but preserves difference and product",is_equal_approx(study.model.reading().rate,0.125) and study.model.reading().difference==before.difference and study.model.reading().contribution==before.contribution)
    study.buttons[0].pressed.emit()
    check("reverse pair yields positive product from two negatives",is_equal_approx(study.model.reading().difference,-0.5) and is_equal_approx(study.model.reading().contribution,0.5) and study.model.interval==4.0)
    study.buttons[3].pressed.emit()
    check("zero weight removes contribution not difference",study.model.phi==0.0 and study.model.reading().contribution==0.0 and is_equal_approx(study.model.reading().difference,-0.5))
    check("zero display has no negative zero",study.readout.text.contains("PHI +0.00 x change = +0.000"))
    study.model.set_pair(0.1,0.9)
    await drag(study,Vector3(0,study.LOW+0.75*study.TRAVEL,0))
    check("independent pair and three-quarter hand predict product .4",is_equal_approx(study.model.phi,0.5) and is_equal_approx(study.model.reading().contribution,0.4) and is_equal_approx(study.model.reading().rate,0.2))
    await drag(study,Vector3(0,study.LOW-1,0))
    check("low hand clamps at negative one",is_equal_approx(study.model.phi,-1.0))
    await drag(study,Vector3(0,study.LOW+study.TRAVEL+1,0))
    check("high hand clamps at positive one",is_equal_approx(study.model.phi,1.0))
    await release(study)
    check("KEEP survives every later edit and retains interval",study.model.kept==kept and study.model.kept.interval==2.0)
    check("one point identity survives redraws and returns home",study.point.get_instance_id()==point_id and study.point.position.distance_to(study.point_home)<0.001)
    study.model.set_pair(0.0,1.0)
    for weight: float in [-1.0,1.0]:
        study.model.set_phi(weight)
        study.redraw()
        var visible_product := false
        for mesh in study.drawing.find_children("*","MeshInstance3D",true,false):
            if mesh.mesh is BoxMesh and mesh.material_override.albedo_color.is_equal_approx(Color("f087b4")):
                visible_product = mesh.position.y-mesh.mesh.size.y*0.5 >= 0.999 and mesh.position.y+mesh.mesh.size.y*0.5 <= 1.801
        check("full-range product %+.0f stays above the tabletop" % weight,visible_product)
    parent.free()
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Author-operated fresh printed code with synthetic hand/button input; not an independent learner or headset test."},"  "))
    quit(0 if failures.is_empty() else 1)
