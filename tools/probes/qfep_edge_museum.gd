extends "res://tools/probes/foundations_reconstruction_museum.gd"
const LESSON = "res://doc/book/iterations/2026-10-12-qfep-same-time-different-steps/learner/edge_study.gd"
const LAUNCHER = "res://doc/book/studies/qfep-lineage/edge_museum.gd"

func photo(study: Node3D, name: String) -> void:
    await snapshot(name,study.to_global(Vector3(0,2.15,2.3)),study.to_global(Vector3(0,1.45,0)),75)

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("hall finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original := find_scene("/edge_of_chaos_unlocked.gd")
    check("installed paired solver and console retained",original!=null and original.comparison_study and original._controls!=null)
    if original==null:return
    # Pause automatic frames; console callbacks and scheduled steps remain real code.
    original.set_process(false)
    original.restart()
    var beginning: PackedFloat32Array = original._grid_b.duplicate()
    original._advance_tick()
    original._controls.action_pressed.emit(0)
    check("installed RESTART reproduces both beginnings and zero time",original._grid_b==beginning and original._fine_b==beginning and original.model_time==0.0)
    original._controls.action_pressed.emit(1)
    check("installed NEW SEED changes matching beginnings",original._grid_b!=beginning and original._fine_b==original._grid_b and original.model_time==0.0)
    beginning = original._grid_b.duplicate()
    original._controls.action_pressed.emit(2)
    check("installed DT halves and restarts same current seed",original.time_step==0.15 and original._grid_b==beginning and original._fine_b==beginning and original.model_time==0.0)
    original._paused=false
    original._controls.action_pressed.emit(3)
    original._process(0.1)
    check("installed HOLD prevents scheduled updates",original._paused and original.model_time==0.0)
    original._controls.action_pressed.emit(3)
    original._process(0.1)
    check("installed RUN resumes calculated time",not original._paused and original.model_time>0.0)
    var time_before: float = original.model_time
    var state_before: PackedFloat32Array = original._grid_b.duplicate()
    original._controls.parameter_changed.emit(1,1.0)
    check("installed SIM SPEED changes scheduling alone",original.sim_steps==8 and original.time_step==0.15 and original.model_time==time_before and original._grid_b==state_before)
    original._controls.parameter_changed.emit(0,0.7)
    check("installed lambda changes future parameters without advancing",is_equal_approx(original.lambda,0.7) and original.model_time==time_before and original._grid_b==state_before)
    original.lambda=0.4
    original.seed_value=original.SEED_RNG
    original.time_step=0.3
    original.restart()
    for i in 200:original._advance_tick()
    original._update_texture()
    check("installed equal-time comparison reaches sixty without fault",is_equal_approx(original.model_time,60.0) and not original.solver_fault and original.comparison_error()>0.0)
    observations.installed={"grid":original.grid_size,"time":original.model_time,"dt":original.time_step,"rms":original.comparison_error()}
    await snapshot("existing",original.to_global(Vector3(0,2.3,2.1)),original.to_global(Vector3(0,1.4,0)),85)
    var launcher = load(LAUNCHER)
    var study = launcher.mount(hall,load(LESSON))
    await tick()
    var bodies: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false):bodies.append(body.get_rid())
    check("learner bay has supported clear approach",placeable(study.transform,bodies))
    var original_bounds: AABB = museum.call("_seat_extent",original)
    var bench_bounds: AABB = hall.global_transform*study.transform*AABB(Vector3(-1.48,0.88,-0.98),Vector3(2.96,1.7,1.96))
    check("learner bench does not overlap installed display",not bench_bounds.intersects(original_bounds))
    var packed = load("res://doc/book/studies/qfep-lineage/edge.tscn").instantiate()
    check("F6 scene uses tested adapter",packed.get_script()==launcher)
    packed.free()
    check("learner bench belongs to real hall",study.get_parent()==hall and study.buttons.size()==5)
    var id: int = study.point.get_instance_id()
    var texture_id: int = study.textures[0].get_instance_id()
    await photo(study,"initial")
    for i in 10:study.buttons[0].pressed.emit()
    var first: Dictionary = study.model.reading()
    check("native batches reach equal sixty with 200 and 400 steps",first.coarse_ticks==200 and first.fine_ticks==400 and first.coarse_time==60.0 and first.fine_time==60.0)
    study.buttons[4].pressed.emit()
    var kept: Dictionary = study.model.kept.duplicate(true)
    await photo(study,"coarse")
    study.buttons[3].pressed.emit()
    for i in 10:study.buttons[0].pressed.emit()
    var refined: Dictionary = study.model.reading()
    check("native refined run doubles counts at same duration",refined.coarse_ticks==400 and refined.fine_ticks==800 and refined.coarse_time==60.0 and refined.fine_time==60.0)
    check("selected refinement reduces B disagreement",refined.rms>0 and refined.rms<first.rms)
    check("native KEEP retains earlier fields and settings",study.model.kept==kept)
    await photo(study,"refined")
    var field_before: PackedFloat32Array = study.model.coarse.b.duplicate()
    study.point.on_desktop_grab(study)
    for i in 6:
        study.point.global_position=study.to_global(Vector3(-1.17,study.LOW+0.7*study.TRAVEL,0.22))
        study._process(0.016)
        await tick()
    study.point.on_desktop_drop(study)
    for i in 3:await tick()
    check("held point changes lambda locally without changing field",is_equal_approx(study.model.weight,0.7) and study.model.coarse.b==field_before and study.model.coarse.ticks==400)
    study.buttons[1].pressed.emit()
    check("native restart keeps chosen weight and timestep",is_equal_approx(study.model.weight,0.7) and study.model.dt==0.15 and study.model.coarse.ticks==0 and study.model.fine.ticks==0)
    for i in 10:study.buttons[0].pressed.emit()
    await photo(study,"changed")
    check("same point and textures survive the study",study.point.get_instance_id()==id and study.textures[0].get_instance_id()==texture_id)
    check("learner controls leave installed solver untouched",original.lambda==0.4 and is_equal_approx(original.model_time,60.0))
    observations.mount={"position":xyz(study.position),"yaw":study.rotation.y}
    observations.comparison={"first":first,"refined":refined,"changed":study.model.reading()}
    await snapshot("hall",study.to_global(Vector3(-0.7,2.8,2.1)),study.to_global(Vector3(0.6,1.25,-0.8)),85)
    observations.tested_code={}
    for file in ["timed_field.gd","step_comparison.gd","edge_study.gd","bench.gd","point_body.gd","line_skin.gd"]:
        var path: String = LESSON.get_base_dir()+"/"+file
        observations.tested_code[path]=FileAccess.get_sha256(path)
    observations.runtime_sources={}
    for path in [LAUNCHER,"res://doc/book/studies/qfep-lineage/edge.tscn","res://commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd","res://commons/maps/QFEP_Edge_Of_Chaos/map_data.json","res://tools/probes/qfep_edge_museum.gd"]:
        observations.runtime_sources[path]=FileAccess.get_sha256(path)
    observations.scope="Actual museum; freshly extracted learner code; synthetic console/button and held-point input. Installed solver automatic frames paused for deterministic comparisons. No headset, independent learner or full walking-route claim."
