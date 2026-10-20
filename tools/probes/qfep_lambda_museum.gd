extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-move-the-recommendation/learner/lambda_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/lambda_museum.gd"

func surroundings(original: Node3D) -> Array:
    var record := []
    for row in original.find_children("LambdaRow_*","MultiMeshInstance3D",true,false):
        var values := [row.get_instance_id(),row.transform,row.material_override.albedo_color,row.material_override.emission,row.material_override.emission_energy_multiplier]
        for i in row.multimesh.instance_count:
            values.append(row.multimesh.get_instance_transform(i))
            values.append(row.multimesh.get_instance_color(i))
        record.append(values)
    for drifter in original._drifters:
        record.append([drifter.node.get_instance_id(),drifter.node.transform])
    record.append([original._time,original._build_settings(),original.get_node("CaptureCamera").transform])
    return record

func move_rail(original: Node3D, fraction: float) -> void:
    var before := surroundings(original)
    original._slider.set_normalized_value(fraction)
    original._slider.slider_moved.emit(fraction)
    check("rail %.2f preserves rows colours animation clock and camera" % fraction,surroundings(original)==before)

func cube_record(study: Node3D) -> Array:
    var record := []
    for cube in study.cubes:record.append([cube.get_instance_id(),cube.transform,cube.material_override.albedo_color])
    return record

func hold_at(study: Node3D, fraction: float) -> void:
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position = study.to_global(Vector3(-1.17,study.LOW+fraction*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/lambda_hall.gd")
    check("installed walk-in spectrum retained",original!=null)
    if original==null:return
    check("installed rail and RETURN control available",original._slider!=null and original._reset_button!=null and original.recommendation_control)
    if original._slider==null:return
    check("six installed rows available for invariant comparison",original.find_children("LambdaRow_*","MultiMeshInstance3D",true,false).size()==6)
    original._reset_button.pressed.emit()
    await snapshot("existing",original.to_global(Vector3(0,3,9)),original.to_global(Vector3(0,1.3,0)),80)
    move_rail(original,1.0)
    check("installed high rail maps to .8 and 2.1 metres",is_equal_approx(original.recommendation_position,0.8) and is_equal_approx(original._recommendation.position.x,2.1))
    check("installed structural lambda stays at .35",is_equal_approx(original.lambda_value,0.35))
    await snapshot("existing-moved",original.to_global(Vector3(0,3,9)),original.to_global(Vector3(0,1.3,0)),80)
    var before := surroundings(original)
    original._reset_button.pressed.emit()
    check("installed RETURN restores only recommendation",is_equal_approx(original.recommendation_position,0.35) and surroundings(original)==before)
    var t: float = original._time
    var pose: Transform3D = original._drifters[0].node.transform
    await create_timer(0.15).timeout
    check("installed animation continues after RETURN",original._time>t and original._drifters[0].node.transform!=pose)
    move_rail(original,0.0)
    check("installed lower rail maps to .2 and minus 2.1 metres",is_equal_approx(original.recommendation_position,0.2) and is_equal_approx(original._recommendation.position.x,-2.1))
    original._reset_button.pressed.emit()
    var launcher = load(LAUNCHER)
    var study = launcher.mount(hall,load(LESSON))
    await tick()
    var bodies: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner bay has supported clear approach",placeable(study.transform,bodies))
    var packed = load("res://doc/book/studies/qfep-lineage/lambda.tscn").instantiate()
    check("F6 scene uses tested adapter",packed.get_script()==launcher)
    packed.free()
    check("learner bench is inside the existing museum hall",study.get_parent()==hall and study.cubes.size()==24)
    var fixed := cube_record(study)
    var id: int = study.point.get_instance_id()
    study.buttons[2].pressed.emit()
    var kept = study.model.kept.duplicate(true)
    await snapshot("opening",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    await hold_at(study,1.0)
    move_rail(original,1.0)
    check("same recommendation fraction scales to each width",is_equal_approx(study.model.route,original.recommendation_position) and is_equal_approx(study.strip.position.x/study.WIDTH,original._recommendation.position.x/original.hall_width))
    check("native strip edit keeps total and entire cube record",is_equal_approx(study.model.reading().total,0.45) and cube_record(study)==fixed)
    await snapshot("strip-moved",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    study.buttons[0].pressed.emit()
    await hold_at(study,1.0)
    check("native weight edit changes contribution without moving strip",is_equal_approx(study.model.reading().total,0.35) and is_equal_approx(study.strip.position.x,0.54) and cube_record(study)==fixed)
    await snapshot("weight-changed",study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)
    var weight_before_return: float = study.model.calculation.values[2]
    study.buttons[3].pressed.emit()
    check("native RETURN keeps new weight and old evidence",study.model.route==0.35 and study.model.calculation.values[2]==weight_before_return and study.model.kept==kept)
    check("native point identity and resting height retained",study.point.get_instance_id()==id and study.point.position.distance_to(study.point_home)<0.001)
    check("miniature strip has no collider",study.strip.find_children("*","CollisionObject3D",true,false).is_empty())
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    observations.comparison={"width_installed":original.hall_width,"width_learner":study.WIDTH,"kept":kept,"current":study.model.reading()}
    await snapshot("hall",study.to_global(Vector3(0,3.2,2.7)),study.to_global(Vector3(0,1.35,-0.3)),85)
    observations.tested_code={}
    for file in ["recommendation.gd","lambda_study.gd","balance.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String=LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://commons/artifacts/lambda_hall/lambda_hall.gd","res://commons/maps/QFEP_Lambda_Spectrum/map_data.json","res://tools/probes/qfep_lambda_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Native museum; fresh printed learner code; synthetic button/slider and held-point inputs. Existing spectrum retains its animation. No headset, complete walking route or independent learner claim."
