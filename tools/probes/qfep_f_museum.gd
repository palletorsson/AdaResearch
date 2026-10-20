extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-change-the-guess/learner/f_term_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/f_term_museum.gd"

func live_p(original: Node3D, value: float) -> void:
    original._slider.set_normalized_value(value)
    original._slider.slider_moved.emit(Vector3.ZERO)
    original._process(0.2)

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/shannon_workbench.gd")
    check("installed workbench retained",original!=null)
    if original==null:return
    check("installed predictor controls available",original._prediction_buttons.size()==2)
    if original._prediction_buttons.size()!=2:return
    live_p(original,0.9)
    original._prediction_buttons[0].pressed.emit()
    var live_draws: PackedFloat32Array = original._draws.duplicate()
    var before: Dictionary = original.prediction_reading()
    original._prediction_buttons[1].pressed.emit()
    var after: Dictionary = original.prediction_reading()
    check("installed guess switches without resampling",original._draws==live_draws and before.p==after.p and before.source_h==after.source_h)
    check("installed observed counts complement",before.observed_errors+after.observed_errors==after.sample_count)
    await snapshot("existing",original.global_position+Vector3(3,4,6),original.global_position+Vector3.UP,65)
    var launcher = load(LAUNCHER)
    var study = launcher.mount(hall,load(LESSON))
    await tick()
    var bodies: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner placement has supported clear approach",placeable(study.transform,bodies))
    var packed = load("res://doc/book/studies/qfep-lineage/f_term.tscn").instantiate()
    check("F6 scene uses this tested adapter",packed.get_script()==launcher)
    packed.free()
    check("working copy uses the real hall",study.get_parent()==hall and study.cells.size()==64)
    var same_prefix: bool = original._draws.size()>=64
    for i in 64: same_prefix = same_prefix and original._draws[i]==study.model.draws[i]
    check("64 learner draws match installed sample prefix",same_prefix)
    observations.sample_sizes={"learner":64,"installed":original._draws.size()}
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    study.buttons[4].pressed.emit()
    await snapshot("opening",study.to_global(Vector3(0,2.05,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    study.buttons[1].pressed.emit()
    check("source entropy matches installed workbench",is_equal_approx(study.model.entropy(),after.source_h))
    check("expected error changes with the guess",is_equal_approx(study.model.reading().expected_error,0.9))
    var before_bits = study.model.bits()
    await snapshot("expect-zero",study.to_global(Vector3(0,2.05,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    study.buttons[3].pressed.emit()
    var prefix_mistakes := 0
    for i in 64: prefix_mistakes += int(int(original._draws[i]<original._p)!=original._prediction)
    check("learner count equals installed prefix count",study.model.reading().mistakes==prefix_mistakes)
    check("predictor edit preserves displayed bit record",study.model.bits()==before_bits)
    var marks := 0
    for mark in study.marks: marks+=int(mark.visible)
    check("visible amber marks equal observed count",marks==prefix_mistakes)
    await snapshot("expect-one",study.to_global(Vector3(0,2.05,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    var id: int = study.point.get_instance_id()
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position = study.to_global(Vector3(-1.08,study.LOW+0.35*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()
    check("native hand selects another probability",is_equal_approx(study.model.p,0.35))
    check("native release retains the inherited sphere",study.point.get_instance_id()==id and study.point.position.distance_to(study.point_home)<0.001)
    study.buttons[1].pressed.emit()
    await snapshot("hall",study.to_global(Vector3(0,4,5)),study.to_global(Vector3(0,1.4,0)),70)
    observations.tested_code={}
    for file in ["prediction.gd","f_term_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String=LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://commons/artifacts/shannon_workbench/shannon_workbench.gd","res://commons/maps/QFEP_F_Term/map_data.json","res://tools/probes/qfep_f_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Actual museum and freshly extracted learner code. Synthetic button signals and held-point motion. Installed sample 256, learner prefix 64. No headset or independent learner claim."
