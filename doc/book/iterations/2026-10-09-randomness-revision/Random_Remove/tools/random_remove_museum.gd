extends "res://tools/probes/transformation_encounters.gd"

func finish_draw(bench: Node3D) -> void:
    bench.remove_one()
    await create_timer(0.06).timeout

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var bench := find_scene("/RemoveRandom.gd")
    var arena := find_scene("/removal_arena.gd")
    var hoppers := find_scene("/sampling_hoppers.gd")
    check("board arena and replacement hoppers exist", bench!=null and arena!=null and hoppers!=null)
    if bench==null or arena==null or hoppers==null: return
    check("primary remover owns its small board", bench.local_grid and bench.multimesh.instance_count==64)
    var origin := hall.global_position+Vector3(0,0,4)
    observations.artifacts = []
    for record in museum.get("_edit_records"):
        var node = record.get("node")
        if not is_instance_valid(node) or record.get("seg")!=hall: continue
        var bounds: AABB = museum.call("_seat_extent",node)
        observations.artifacts.append({"token":record.get("token"),"position":xyz(node.global_position-origin),"bounds_position":xyz(bounds.position-origin),"bounds_size":xyz(bounds.size)})
    observations.before = bench.get_state()
    await snapshot("hall-before",origin+Vector3(8,16,-1),origin+Vector3(8,0,13),70)
    await snapshot("board-before",bench.to_global(Vector3(0,2.5,3)),bench.to_global(Vector3(0,0.95,0)),52)
    var old_seed: int = bench.run_seed
    bench.set_random_seed(42)
    bench.choose_mode("Range")
    var eligible: Array = bench.initial_eligible.duplicate()
    check("installed range has sixteen original addresses starting at18", eligible.size()==16 and eligible[0]==18 and eligible[-1]==45)
    bench.remove_one()
    check("red highlight precedes deletion", bench.get_state().busy and bench.removal_log.is_empty() and bench.last_selected_index in eligible)
    var state: int = bench._rng.state
    bench.remove_one()
    check("busy action consumes no additional draw", bench._rng.state==state)
    bench.reset_and_find_instances()
    await create_timer(0.4).timeout
    check("reset cancels a pending removal", bench.active_instances==eligible and bench.removal_log.is_empty() and not bench.get_state().busy)
    bench.highlight_duration=0.005
    for i in range(16): await finish_draw(bench)
    var order: Array = bench.removal_log.duplicate()
    var sorted_order := order.duplicate()
    sorted_order.sort()
    check("installed board exhausts all sixteen eligible cubes once", sorted_order==eligible and bench.active_instances.is_empty())
    state = bench._rng.state
    await finish_draw(bench)
    check("installed empty board makes no further draw", bench._rng.state==state and bench.removal_log==order)
    await snapshot("board-empty",bench.to_global(Vector3(0,2.5,3)),bench.to_global(Vector3(0,0.95,0)),52)
    bench.reset_and_find_instances()
    for i in range(16): await finish_draw(bench)
    check("installed RESET reproduces the complete order", bench.removal_log==order)
    bench.choose_mode("Row")
    for i in range(8): await finish_draw(bench)
    var row_order: Array = bench.removal_log.duplicate()
    bench.choose_mode("Column")
    for i in range(8): await finish_draw(bench)
    var corresponding := true
    for i in range(8): corresponding = corresponding and row_order[i]%8==floori(float(bench.removal_log[i])/8)
    check("same seed gives transposed row and column orders", corresponding)
    bench.highlight_duration=0.3
    bench.set_random_seed(old_seed)
    bench.choose_mode("Range")
    hoppers.replay()
    hoppers.draw(0)
    hoppers.draw(1)
    await create_timer(2).timeout
    check("hoppers first choices agree at shared seed", hoppers.histories[0].size()==1 and hoppers.histories[0]==hoppers.histories[1])
    check("replacement retains eight choices while withdrawal leaves seven", hoppers.pools[0].size()==8 and hoppers.pools[1].size()==7)
    hoppers.replay()
    arena.set_physics_process(false)
    arena.reset_arena()
    await tick()
    check("arena begins with99 support cells", arena.colliders.size()==99 and arena.get_state().disabled_colliders==0)
    arena.remover.remove_one()
    await create_timer(0.9).timeout
    check("arena deletion disables the chosen collider", arena.get_state().removed==1 and arena.get_state().disabled_colliders==1 and arena.colliders[arena.remover.last_removed_index].disabled)
    var removed_index: int = arena.remover.last_removed_index
    var cell: Vector3 = arena.colliders[removed_index].global_position + Vector3.UP*0.3
    var under_cell := floor_at(cell)
    observations.removed_cell=xyz(cell-origin)
    observations.removed_cell_floor_hit=str(under_cell.get("collider", "none"))
    check("removed arena cell has no remaining floor support", under_cell.is_empty())
    await snapshot("arena-one-gap",arena.to_global(Vector3(0,6,-10)),arena.to_global(Vector3(0,0,0)),65)
    await snapshot("arena-gap-close",cell+Vector3(0,4,-1),cell,52)
    arena.reset_arena()
    await tick()
    check("arena replay restores visual and physical support", arena.get_state().remaining==99 and arena.get_state().disabled_colliders==0)
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"): await study_checks(spec,order)
    observations.scope="Current museum; supplied actions, selection and support checks. Temporary printed learner study. Not physical XR or a full walking-route acceptance test."

func study_checks(spec: Dictionary, board_order: Array) -> void:
    var study = load(spec.lesson).new()
    study.position = Vector3(13.2,0,8)
    study.rotation.y = -PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    observations.student_yaw_degrees=-90
    check("study stands over museum floor", not floor_at(study.global_position).is_empty())
    var approach: Vector3 = study.to_global(Vector3(0,0,2))
    check("student approach has floor", not floor_at(approach).is_empty())
    var capsule := CapsuleShape3D.new()
    capsule.radius=0.26
    capsule.height=1.6
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider): obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("student approach clear of other bodies", obstacles.is_empty())
    check("complete listing initializes in the existing hall", study.cubes.size()==64 and study.candidates.size()==16 and not study.status.text.is_empty())
    await snapshot("student-ready",study.to_global(Vector3(0,3.2,4.2)),study.to_global(Vector3(0,1.0,0.15)),50)
    for i in range(8):
        study.point.position.x=0
        study.point.action()
    check("inherited point action removes eight eligible cubes", study.history.size()==8 and study.candidates.size()==8)
    await snapshot("student-half",study.to_global(Vector3(0,3.2,4.2)),study.to_global(Vector3(0,1.0,0.15)),50)
    for i in range(8): study.remove_one()
    check("student and installed remover agree on all addresses", study.history==board_order)
    observations.student_order=study.history.duplicate()
    await snapshot("student-empty",study.to_global(Vector3(0,3.2,4.2)),study.to_global(Vector3(0,1.0,0.15)),50)
    study.point.position.x=-0.9
    study.point.action()
    check("point can reset the full set inside the museum", study.candidates.size()==16 and study.history.is_empty())
    study.free()
    var edited = load(spec.checker).new()
    edited.position=Vector3(13.2,0,8)
    edited.rotation.y=-PI/2
    hall.add_child(edited)
    check("actual checkerboard edit admits32 cells", edited.candidates.size()==32)
    await snapshot("student-checker",edited.to_global(Vector3(0,3.2,4.2)),edited.to_global(Vector3(0,1.0,0.15)),50)
    edited.free()
