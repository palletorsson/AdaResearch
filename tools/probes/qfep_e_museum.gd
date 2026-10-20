extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-count-the-endings/learner/e_term_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/e_term_museum.gd"

func mesh_counts(original: Node3D) -> Vector2i:
    var result := Vector2i.ZERO
    for node in original._fan_root.find_children("*","Node3D",true,false):
        result.x += int(node.get_meta("is_leaf",false))
        result.y += int(node.get_meta("is_closure",false))
    return result

func compare(original: Node3D, study: Node3D, title: String) -> void:
    var live: Dictionary = original.possibility_reading()
    var learner: Dictionary = study.model.reading()
    var same := true
    for key in ["leaves","uncut_leaves","closures","removed_leaves","equal_weights"]:
        same = same and live[key]==learner[key]
    check(title+": counts and assumption match installed fan",same and is_equal_approx(live.entropy_nats,learner.entropy_nats))
    var meshes := mesh_counts(original)
    check(title+": actual fan meshes agree with both readouts",meshes==Vector2i(learner.leaves,learner.closures) and study.tips.size()==meshes.x and study.caps.size()==meshes.y)
    observations[title]=live

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/entropy_fan.gd")
    check("installed entropy fan retained",original!=null)
    if original==null:return
    check("installed fan has four visitor controls",original._buttons.size()==4)
    if original._buttons.size()!=4:return
    original._buttons[2].pressed.emit()
    await snapshot("existing",original.global_position+Vector3(3,4,6),original.global_position+Vector3.UP,65)
    var launcher = load(LAUNCHER)
    var study = launcher.mount(hall,load(LESSON))
    await tick()
    var bodies: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner bay has floor support and clear approach",placeable(study.transform,bodies))
    var packed = load("res://doc/book/studies/qfep-lineage/e_term.tscn").instantiate()
    check("F6 scene uses tested museum adapter",packed.get_script()==launcher)
    packed.free()
    check("learner copy is inside the actual E hall",study.get_parent()==hall)
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    original._buttons[1].pressed.emit()
    compare(original,study,"ONE")
    await snapshot("opening",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    original._buttons[2].pressed.emit()
    study.buttons[2].pressed.emit()
    compare(original,study,"OPEN")
    study.buttons[4].pressed.emit()
    var evidence = study.model.kept.duplicate(true)
    await snapshot("open",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    original._buttons[3].pressed.emit()
    study.buttons[3].pressed.emit()
    compare(original,study,"PRUNE")
    check("retained paths survive actual button presses",study.model.kept==evidence and evidence.paths.size()==81)
    await snapshot("pruned",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    original._buttons[2].pressed.emit()
    study.buttons[2].pressed.emit()
    check("OPEN restores exact retained paths",study.model.leaves==evidence.paths)
    var id: int = study.point.get_instance_id()
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position = study.to_global(Vector3(-1.17,study.LOW+0.5*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()
    check("native hand independently selects sixteen endings",study.model.branch==2 and study.tips.size()==16 and is_equal_approx(study.model.reading().entropy_nats,log(16.0)))
    check("native release preserves inherited sphere",study.point.get_instance_id()==id and study.point.position.distance_to(study.point_home)<0.001)
    await snapshot("two",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    var counter := find_scene("/microstate_counter.gd")
    check("neighbouring counter loads",counter!=null)
    if counter!=null:
        counter._update_readout()
        check("counter scientific notation renders without unsupported formatter",counter._last_body.contains("x 10^") and counter._last_body.contains("J/K"))
    study.buttons[3].pressed.emit()
    await snapshot("hall",study.to_global(Vector3(-0.35,3.2,3.0)),study.to_global(Vector3(0,1.4,-0.15)),85)
    observations.tested_code={}
    for file in ["possibilities.gd","e_term_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String=LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://commons/artifacts/entropy_fan/entropy_fan.gd","res://commons/artifacts/microstate_counter/microstate_counter.gd","res://commons/maps/QFEP_E_Term/map_data.json","res://tools/probes/qfep_e_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Actual museum and freshly extracted learner code. Synthetic button signals and held-point motion; counts checked against actual fan meshes. No headset or independent learner claim."
