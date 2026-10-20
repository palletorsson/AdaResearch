extends "res://tools/probes/qfep_introduction_student.gd"

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"possibility_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position = Vector3(12,3,-7)
    parent.rotation = Vector3(0.12,0.7,-0.08)
    root.add_child(parent)
    var study = load(folder+"e_term_study.gd").new()
    parent.add_child(study)
    await process_frame
    check("readout initialized with nats and equal weights",study.readout!=null and study.readout.text.contains("nats") and study.readout.text.contains("equal leaf weights"))
    check("five controls and one initial ending",study.buttons.size()==5 and study.tips.size()==1 and study.caps.is_empty())
    var point_id: int = study.point.get_instance_id()
    var button_id: int = study.buttons[0].get_instance_id()
    study.buttons[2].pressed.emit()
    check("OPEN draws 81 endings without caps",study.tips.size()==81 and study.caps.is_empty())
    var positions := {}
    for path in study.model.leaves: positions[path]=study.position_for(path)
    var line_count := 0
    var lines_fit := true
    for node in study.drawing.get_children():
        if node.get_script()==study.LineSkin:
            var edge: Dictionary = study.model.edges[line_count]
            var a: Vector3 = study.position_for(edge.from)
            var b: Vector3 = study.position_for(edge.to)
            lines_fit = lines_fit and node.position.distance_to((a+b)*0.5)<0.0001 and is_equal_approx(node.mesh.height,a.distance_to(b))
            var half: Vector3 = node.basis.y*node.mesh.height*0.5
            lines_fit = lines_fit and (node.position-half).distance_to(a)<0.0001 and (node.position+half).distance_to(b)<0.0001
            line_count+=1
    check("all 120 inherited cylinders end at the path nodes",line_count==120 and lines_fit)
    study.buttons[4].pressed.emit()
    var evidence = study.model.kept.duplicate(true)
    study.buttons[3].pressed.emit()
    check("PRUNE draws 27 tips and 18 caps",study.tips.size()==27 and study.caps.size()==18)
    var fixed_slots := true
    for path in study.model.leaves: fixed_slots=fixed_slots and study.position_for(path)==positions[path]
    check("surviving endings keep their positions",fixed_slots)
    check("kept full inventory survives pruning",study.model.kept==evidence and study.model.kept.paths.size()==81)
    check("readout distinguishes closures and removed endings",study.readout.text.contains("18 closures / 54 endings removed"))
    study.buttons[2].pressed.emit()
    check("OPEN restores exact path record",study.model.leaves==evidence.paths)
    await drag(study,Vector3(2,study.LOW+0.5*study.TRAVEL,-2))
    check("middle hand height chooses two under transformed parent",study.model.branch==2 and study.tips.size()==16)
    for button in study.buttons:button.pressed.emit()
    check("buttons wait for held point release",study.model.branch==2 and study.model.kept==evidence)
    study.point.on_desktop_drop(study)
    for i in 3:await physics_frame
    check("released sphere returns to branch setting",study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[3].pressed.emit()
    await drag(study,Vector3(0,study.LOW+study.TRAVEL,0))
    check("unchanged high hand does not reopen pruning",study.model.pruned and study.tips.size()==27)
    await drag(study,Vector3(0,study.LOW-1,0))
    check("low hand clamps to one and clears pruning",study.model.branch==1 and not study.model.pruned and study.tips.size()==1)
    await drag(study,Vector3(0,study.LOW+study.TRAVEL+1,0))
    check("high hand clamps to three",study.model.branch==3 and study.tips.size()==81)
    study.point.on_desktop_drop(study)
    check("tree rebuilds preserve point and button identities",study.point.get_instance_id()==point_id and study.buttons[0].get_instance_id()==button_id)
    parent.free()
    await process_frame
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Fresh printed E model and inherited bench; author-operated synthetic inputs, not an independent learner or headset test."},"  "))
    quit(0 if failures.is_empty() else 1)
