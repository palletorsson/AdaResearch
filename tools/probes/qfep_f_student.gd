extends "res://tools/probes/qfep_introduction_student.gd"

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"prediction_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position = Vector3(12,3,-7)
    parent.rotation = Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study = load(folder+"f_term_study.gd").new()
    parent.add_child(study)
    await process_frame
    check("initialized readout distinguishes H and expected error",study.readout!=null and study.readout.text.contains("bits/symbol") and study.readout.text.contains("expected error"))
    check("five actions and 64 cells are ready",study.buttons.size()==5 and study.cells.size()==64 and study.marks.size()==64)
    var point_id: int = study.point.get_instance_id()
    var cell_id: int = study.cells[0].get_instance_id()
    var draws = study.model.draws.duplicate()
    study.buttons[4].pressed.emit()
    var evidence = study.model.kept.duplicate(true)
    study.buttons[1].pressed.emit()
    check("p presets retain draws and equal source H",study.model.draws==draws and is_equal_approx(study.model.entropy(),evidence.source_h))
    check("same predictor has larger expected error at .9",is_equal_approx(study.model.reading().expected_error,0.9))
    var outcomes = study.model.bits()
    var colours: Array = []
    for cell in study.cells: colours.append(cell.material_override.albedo_color)
    var before: int = study.model.reading().mistakes
    study.buttons[3].pressed.emit()
    check("EXPECT 1 keeps p and the exact bits",study.model.p==0.9 and study.model.bits()==outcomes)
    var colour_unchanged := true
    var visible_marks := 0
    for i in 64:
        colour_unchanged = colour_unchanged and colours[i]==study.cells[i].material_override.albedo_color
        visible_marks += int(study.marks[i].visible)
    check("changing guess retains every visible bit colour",colour_unchanged)
    check("amber marks match observed mistakes",visible_marks==study.model.reading().mistakes)
    check("opposite guesses partition the 64 outcomes",before+visible_marks==64)
    check("KEEP retains its source guess and bits",study.model.kept==evidence)
    await drag(study,Vector3(2,study.LOW+0.35*study.TRAVEL,-2))
    check("same hand mapping works under a transformed parent",is_equal_approx(study.model.p,0.35))
    for button in study.buttons: button.pressed.emit()
    check("buttons do not compete with a held hand",is_equal_approx(study.model.p,0.35) and study.model.prediction==1 and study.model.kept==evidence)
    study.point.on_desktop_drop(study)
    for i in 3: await physics_frame
    check("released sphere returns to probability height",study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[2].pressed.emit()
    before = study.model.reading().mistakes
    study.buttons[3].pressed.emit()
    check("student-selected probability also has complementary counts",before+study.model.reading().mistakes==64)
    check("chosen p .35 favours constant zero in expectation",is_equal_approx(study.model.reading().expected_error,0.65))
    await drag(study,Vector3(0,study.LOW-1,0))
    check("lower hand endpoint is a certain zero source",study.model.p==0.0 and study.model.entropy()==0.0 and study.model.reading().mistakes==64)
    await drag(study,Vector3(0,study.LOW+study.TRAVEL+1,0))
    check("upper hand endpoint is a certain one source",study.model.p==1.0 and study.model.entropy()==0.0 and study.model.reading().mistakes==0)
    study.point.on_desktop_drop(study)
    study.buttons[0].pressed.emit()
    check("returning to p .1 reconstructs kept bits",study.model.bits()==evidence.bits)
    check("edits preserve sphere and cell identities",study.point.get_instance_id()==point_id and study.cells[0].get_instance_id()==cell_id)
    parent.free()
    await process_frame
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Fresh printed model and inherited bench, author-operated synthetic inputs. No independent learner or headset claim."},"  "))
    quit(0 if failures.is_empty() else 1)
