extends "res://tools/probes/qfep_introduction_student.gd"

func cube_record(study: Node3D) -> Array:
    var record := []
    for cube in study.cubes:
        record.append([cube.get_instance_id(),cube.transform,cube.material_override.albedo_color])
    return record

func release(study: Node3D) -> void:
    study.point.on_desktop_drop(study)
    for i in 3:await physics_frame

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"recommendation_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position = Vector3(12,3,-7)
    parent.rotation = Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study = load(folder+"lambda_study.gd").new()
    parent.add_child(study)
    await process_frame
    check("labels initialized and separate parameter names visible",study.readout!=null and study.readout.text.contains("STRIP / L 0.50 / strip 0.35"))
    check("five actions and 24 fixed cubes created",study.buttons.size()==5 and study.cubes.size()==24)
    var point_id: int = study.point.get_instance_id()
    var strip_id: int = study.strip.get_instance_id()
    var original := cube_record(study)
    study.buttons[2].pressed.emit()
    var kept = study.model.kept.duplicate(true)
    await drag(study,Vector3(2,study.LOW+study.TRAVEL,-2))
    check("local high hand maps to route .8 under transformed parent",is_equal_approx(study.model.route,0.8) and is_equal_approx(study.strip.position.x,0.54))
    check("route edit leaves complete calculation unchanged",study.model.calculation.values==kept.parts and is_equal_approx(study.model.reading().total,kept.total))
    for button in study.buttons:button.pressed.emit()
    check("buttons cannot change mode or state while point held",not study.editing_weight and is_equal_approx(study.model.route,0.8) and study.model.kept==kept)
    await release(study)
    check("released sphere returns to selected parameter height",study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[0].pressed.emit()
    check("WEIGHT changes mode without changing either parameter",study.editing_weight and is_equal_approx(study.model.route,0.8) and study.model.calculation.values==kept.parts)
    await drag(study,Vector3(0,study.LOW+study.TRAVEL,0))
    check("weight one changes score to .35 while route remains .8",is_equal_approx(study.model.reading().total,0.35) and is_equal_approx(study.strip.position.x,0.54))
    await release(study)
    study.buttons[4].pressed.emit()
    check("ZERO L suppresses contribution but retains E input",study.model.calculation.values[1]==0.2 and study.model.calculation.values[2]==0.0 and is_equal_approx(study.model.reading().total,0.55))
    check("zero contribution readout avoids negative zero",study.readout.text.contains("-L*E +0.000"))
    study.buttons[3].pressed.emit()
    check("RETURN restores only recommendation",study.model.route==0.35 and study.model.calculation.values[2]==0.0 and study.model.kept==kept)
    study.buttons[1].pressed.emit()
    await drag(study,Vector3(0,study.LOW+0.25*study.TRAVEL,0))
    check("quarter travel gives route .35 and x minus .27",is_equal_approx(study.model.route,0.35) and is_equal_approx(study.strip.position.x,-0.27))
    await drag(study,Vector3(0,study.LOW+0.75*study.TRAVEL,0))
    check("three-quarter travel gives route .65 and x plus .27",is_equal_approx(study.model.route,0.65) and is_equal_approx(study.strip.position.x,0.27))
    await drag(study,Vector3(0,study.LOW-1,0))
    check("lower hand clamps to route .2",is_equal_approx(study.model.route,0.2))
    await drag(study,Vector3(0,study.LOW+study.TRAVEL+1,0))
    check("upper hand clamps to route .8",is_equal_approx(study.model.route,0.8))
    await release(study)
    check("all cube identities transforms and colours survived every edit",cube_record(study)==original)
    check("KEEP retains earlier weight route total and copied inputs",study.model.kept==kept and study.kept_strip.visible and is_equal_approx(study.kept_strip.position.x,-0.27))
    check("sphere and recommendation mesh identities persist",study.point.get_instance_id()==point_id and study.strip.get_instance_id()==strip_id)
    parent.free()
    await process_frame
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Printed model and four inherited files; author-operated synthetic input reconstruction, no headset or independent student evidence."},"  "))
    quit(0 if failures.is_empty() else 1)
