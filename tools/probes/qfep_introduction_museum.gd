extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-four-inputs/learner/introduction_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/introduction_museum.gd"

func live_tuple(original: Node3D, values: Array) -> void:
    for i in 4: original._sliders[i].set_normalized_value(values[i])
    original._process(0.2)

func hand(study: Node3D, value: float) -> void:
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position = study.to_global(Vector3(0, study.LOW+study.TRAVEL*value, 0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3: await tick()

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("all hall artifacts loaded", museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/qfep_balance_workbench.gd")
    check("original workbench retained", original != null)
    if original == null: return
    check("installed workbench supplies four rails and KEEP", original._sliders.size()==4 and original._keep_button!=null)
    if original._sliders.size()!=4 or original._keep_button==null:return
    live_tuple(original,[0.4,0.2,0.5,0.5])
    original._keep_button.pressed.emit()
    check("installed KEEP records A", is_equal_approx(original._kept_qfe,0.45) and original._kept==[0.4,0.2,0.5,0.5])
    live_tuple(original,[0.6,0.6,0.5,0.5])
    check("installed B equals A without erasing retained inputs", is_equal_approx(original._compute_qfe(),0.45) and is_equal_approx(original._kept[1],0.2))
    await snapshot("existing",original.global_position+Vector3(3,4,6),original.global_position+Vector3.UP,65)
    var launcher = load(LAUNCHER)
    var study = launcher.mount(hall,load(LESSON))
    await tick()
    var bodies: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false): bodies.append(body.get_rid())
    check("learner bay has supported clear approach",placeable(study.transform,bodies))
    observations.mount = {"position":xyz(study.position),"yaw":study.rotation.y}
    var packed = load("res://doc/book/studies/qfep-lineage/introduction.tscn").instantiate()
    check("F6 scene uses the same tested museum adapter",packed.get_script()==launcher)
    packed.free()
    check("fresh printed example lives in the museum hall",study.get_parent()==hall and study.buttons.size()==5)
    var id: int = study.point.get_instance_id()
    await snapshot("opening",study.to_global(Vector3(0,1.85,2.2)),study.to_global(Vector3(0,1.5,0)),78)
    study.buttons[1].pressed.emit()
    study.buttons[3].pressed.emit()
    check("student tuple B agrees with installed arithmetic",is_equal_approx(study.model.total(study.model.values),original._compute_qfe()))
    check("student retained tuple agrees with installed KEEP",study.model.kept==original._kept)
    await snapshot("comparison",study.to_global(Vector3(0,1.85,2.2)),study.to_global(Vector3(0,1.5,0)),78)
    study.buttons[4].pressed.emit()
    study.buttons[0].pressed.emit()
    var before: float = study.model.total(study.model.values)
    await hand(study,0.85)
    check("native hand moves E with zero weight",is_equal_approx(study.model.values[1],0.85) and is_equal_approx(study.model.total(study.model.values),before))
    study.buttons[0].pressed.emit()
    await hand(study,0.4)
    check("native hand restores E's weighted contribution",is_equal_approx(study.model.total(study.model.values),0.6-0.4*0.85+0.5*0.3))
    check("native release retains sphere identity and home",study.point.get_instance_id()==id and study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[2].pressed.emit()
    study.buttons[3].pressed.emit()
    await snapshot("hall",study.to_global(Vector3(0,4.0,5.0)),study.to_global(Vector3(0,1.4,0)),70)
    observations.scope = "Actual museum, retained original exhibits, fresh printed lesson, synthetic button and hand signals. Supported bay tested. No headset ergonomics or independent learner claim."
    observations.tested_code = {}
    for file in ["balance.gd","introduction_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String = LESSON.get_base_dir()+"/"+file
        observations.tested_code[path] = FileAccess.get_sha256(path)
    observations.runtime_sources = {}
    for path in [LAUNCHER,"res://commons/artifacts/qfep_balance_workbench/qfep_balance_workbench.gd","res://commons/maps/QFEP_Introduction/map_data.json","res://tools/probes/qfep_introduction_museum.gd"]:
        observations.runtime_sources[path] = FileAccess.get_sha256(path)
