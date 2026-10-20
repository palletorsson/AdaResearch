extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-change-has-a-sign/learner/phi_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/phi_museum.gd"

func pattern_record(pattern: Node3D) -> Array:
    var record := [pattern._time,pattern.transform_speed,pattern.concert,pattern.phase_lock]
    for cell in pattern._cells:
        record.append([cell.get_instance_id(),cell.transform,cell.material_override.albedo_color,cell.material_override.emission_energy_multiplier])
    return record

func move_rail(original: Node3D, pattern: Node3D, value: float) -> void:
    var before := pattern_record(pattern)
    original._slider.slider_moved.emit((value+1.0)*0.5*original.rail_length)
    check("installed phi %+.2f event leaves pattern state untouched" % value,pattern_record(pattern)==before)

func hold_at(study: Node3D, fraction: float) -> void:
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position = study.to_global(Vector3(-1.17,study.LOW+fraction*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()

func photo(study: Node3D, name: String) -> void:
    await snapshot(name,study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/phi_slider.gd")
    var pattern := find_scene("/transforming_pattern.gd")
    check("installed signed rail and independent pattern retained",original!=null and pattern!=null)
    if original==null or pattern==null:return
    check("installed placement uses isolated sign study",original.sign_study and not original.is_in_group("qfep_phi_controllers"))
    check("installed starts at zero with emission stopped",is_zero_approx(original.phi) and not original._particles.emitting)
    var material: ParticleProcessMaterial = original._particles.process_material
    move_rail(original,pattern,0.5)
    check("positive half-weight emits upward at .1 m per s",original._particles.emitting and material.direction==Vector3.UP and is_equal_approx(material.initial_velocity_min,0.1) and material.initial_velocity_min==material.initial_velocity_max)
    var speed: float = material.initial_velocity_max
    var amount: int = original._particles.amount
    await snapshot("existing-positive",original.to_global(Vector3(0.25,1.2,3)),original.to_global(Vector3(0.25,0.1,0)),65)
    move_rail(original,pattern,-0.5)
    check("equal negative magnitude has same speed amount and zero gravity",original._particles.emitting and material.direction==Vector3.DOWN and material.initial_velocity_min==speed and material.initial_velocity_max==speed and original._particles.amount==amount and material.gravity==Vector3.ZERO)
    var previous := pattern_record(pattern)
    var particle_state := [original.phi,material.direction,material.initial_velocity_max,original._particles.emitting]
    original._reading_button.get_node("InteractableAreaButton").button_pressed.emit(null)
    check("earlier labels change text alone",original._labels_revealed and original._interpretation.text.contains("RESIST") and pattern_record(pattern)==previous and particle_state==[original.phi,material.direction,material.initial_velocity_max,original._particles.emitting])
    await snapshot("existing-negative",original.to_global(Vector3(0.25,1.2,3)),original.to_global(Vector3(0.25,0.1,0)),65)
    original._reading_button.get_node("InteractableAreaButton").button_pressed.emit(null)
    check("earlier labels can be hidden without changing phi",not original._labels_revealed and original.phi==-0.5)
    move_rail(original,pattern,0.0)
    check("zero stops new particles and lifetime remains two seconds",not original._particles.emitting and material.initial_velocity_max==0.0 and original._particles.lifetime==2.0)
    var phase: float = pattern._time
    var pose: Transform3D = pattern._cells[0].transform
    await create_timer(0.2).timeout
    check("pattern keeps moving while phi stays zero",pattern._time>phase and pattern._cells[0].transform!=pose and original.phi==0.0)
    var launcher = load(LAUNCHER)
    var study = launcher.mount(hall,load(LESSON))
    await tick()
    var bodies: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner bay has supported clear approach",placeable(study.transform,bodies))
    var packed = load("res://doc/book/studies/qfep-lineage/phi.tscn").instantiate()
    check("F6 scene uses tested adapter",packed.get_script()==launcher)
    packed.free()
    check("learner bench belongs to existing hall",study.get_parent()==hall and study.buttons.size()==5)
    var id: int = study.point.get_instance_id()
    await hold_at(study,1.0)
    study.buttons[2].pressed.emit()
    var kept = study.model.kept.duplicate()
    check("native positive weight gives plus .5",is_equal_approx(study.model.reading().contribution,0.5))
    await photo(study,"positive")
    await hold_at(study,0.0)
    check("native negative weight gives minus .5 on same pair",is_equal_approx(study.model.reading().contribution,-0.5) and study.model.earlier==0.2 and study.model.later==0.7)
    await photo(study,"negative")
    var before = study.model.reading()
    study.buttons[1].pressed.emit()
    check("native doubled interval changes only rate and interval",is_equal_approx(study.model.reading().rate,0.125) and study.model.reading().contribution==before.contribution and study.model.reading().difference==before.difference and study.model.phi==before.phi)
    await photo(study,"longer")
    study.buttons[0].pressed.emit()
    check("native reversed pair produces positive product from negatives",is_equal_approx(study.model.reading().difference,-0.5) and is_equal_approx(study.model.reading().contribution,0.5) and study.model.interval==4.0)
    await photo(study,"reversed")
    study.buttons[3].pressed.emit()
    check("native zero suppresses product while preserving difference",study.model.reading().contribution==0.0 and is_equal_approx(study.model.reading().difference,-0.5))
    check("kept evidence and point identity survive all controls",study.model.kept==kept and study.point.get_instance_id()==id)
    for i in 3:await tick()
    check("same point settles at selected height",study.point.position.distance_to(study.point_home)<0.001)
    check("bench edits never reach original phi",original.phi==0.0)
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    observations.comparison={"kept":kept,"current":study.model.reading(),"installed_speed_at_half":speed,"particle_lifetime":original._particles.lifetime}
    await snapshot("hall",study.to_global(Vector3(-1.1,2.8,2.1)),study.to_global(Vector3(0.3,1.35,-0.8)),85)
    observations.tested_code={}
    for file in ["signed_change.gd","phi_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String = LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://commons/interfaces/qfep/phi_slider.gd","res://commons/interfaces/qfep/transforming_pattern.gd","res://commons/maps/QFEP_Phi_Term/map_data.json","res://tools/probes/qfep_phi_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Native museum; fresh printed learner code; synthetic slider/button and held-point inputs. Installed waves remain independent. No headset, full walking route or independent learner claim."
