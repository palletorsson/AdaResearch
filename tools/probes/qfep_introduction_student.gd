extends SceneTree
## Supplied synthetic-input harness. The lesson files are extracted from the book.
var checks: Array = []
var failures: Array = []
var receipt: String

func _initialize() -> void:
    run.call_deferred()

func check(title: String, ok: bool) -> void:
    checks.append({"name": title, "passed": ok})
    if not ok: failures.append(title)
    print("[qfep-student] ", "PASS " if ok else "FAIL ", title)

func drag(study: Node3D, at: Vector3) -> void:
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position = study.to_global(at)
        study._process(0.016)
        await physics_frame
        await process_frame

func run() -> void:
    var args := OS.get_cmdline_user_args()
    var folder: String = args[0]
    receipt = args[1]
    load(folder+"balance_checks.gd").new().run()
    var parent := Node3D.new()
    parent.position = Vector3(12, 3, -7)
    parent.rotation = Vector3(0.12, 0.7, -0.08)
    root.add_child(parent)
    var study = load(folder+"introduction_study.gd").new()
    parent.add_child(study)
    await process_frame
    check("readout initialized before interaction", study.readout != null and study.readout.text.contains("0.450"))
    check("five declared actions created", study.buttons.size()==5)
    var id: int = study.point.get_instance_id()
    study.buttons[1].pressed.emit()
    study.buttons[3].pressed.emit()
    check("PAIR B preserves A's tuple", study.model.kept == [0.4,0.2,0.5,0.5] and study.model.values == [0.6,0.6,0.5,0.5])
    check("same total remains visible", study.readout.text.contains("Kept 0.450") and study.readout.text.contains("+0.000"))
    study.buttons[4].pressed.emit()
    study.buttons[0].pressed.emit()
    var before: float = study.model.total(study.model.values)
    await drag(study, Vector3(2,study.LOW+0.8*study.TRAVEL,-2))
    check("transformed bench maps hand height locally", is_equal_approx(study.model.values[1],0.8))
    check("zero weight leaves E editable with unchanged total", is_equal_approx(study.model.total(study.model.values),before))
    var frozen = study.model.values.duplicate()
    for button in study.buttons: button.pressed.emit()
    check("all actions wait for release", study.selected==1 and study.model.values==frozen and study.model.kept==[0.4,0.2,0.5,0.5])
    await drag(study,Vector3(1,study.LOW+study.TRAVEL+1,1))
    check("upper drag clamps to one", is_equal_approx(study.model.values[1],1.0))
    await drag(study,Vector3(-1,study.LOW-1,-1))
    check("lower drag clamps to zero", is_zero_approx(study.model.values[1]))
    study.point.on_desktop_drop(study)
    for i in 3: await physics_frame
    check("release returns sphere to selected rail", study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[2].pressed.emit()
    # A new tuple, formed without the PAIR B action, demonstrates transfer.
    study.buttons[0].pressed.emit()
    study.buttons[0].pressed.emit()
    study.buttons[0].pressed.emit()
    check("TERM wraps selection back to F", study.selected==0)
    await drag(study,Vector3(0,study.LOW+0.3*study.TRAVEL,0))
    study.point.on_desktop_drop(study)
    study.buttons[0].pressed.emit()
    await drag(study,Vector3(0,study.LOW,0))
    study.point.on_desktop_drop(study)
    check("hand controls form a third equal-total tuple", is_equal_approx(study.model.total(study.model.values),0.45) and is_equal_approx(study.model.values[0],0.3) and is_zero_approx(study.model.values[1]))
    study.buttons[1].pressed.emit()
    check("KEEP can replace earlier evidence", study.model.kept==study.model.values)
    check("every edit retains the same inherited sphere", study.point.get_instance_id()==id)
    parent.free()
    await process_frame
    FileAccess.open(receipt,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Fresh printed code plus declared museum dependencies. Author-operated synthetic hand and button inputs; no headset or independent learner claim."},"  "))
    quit(0 if failures.is_empty() else 1)
