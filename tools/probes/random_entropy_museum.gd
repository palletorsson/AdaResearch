extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var primary:=find_scene("/shannon_entropy_meter.gd")
    var origin:=hall.global_position+Vector3(0,0,4)
    observations.artifacts=[]
    for record in museum.get("_edit_records"):
        var node=record.get("node")
        if not is_instance_valid(node) or record.get("seg")!=hall:continue
        var bounds: AABB=museum.call("_seat_extent",node)
        observations.artifacts.append({"token":record.get("token"),"position":xyz(node.global_position-origin),"bounds_position":xyz(bounds.position-origin),"bounds_size":xyz(bounds.size)})
    check("existing ledger present",primary!=null)
    if primary!=null:
        observations.primary_local=xyz(primary.global_position-hall.global_position)
        observations.initial_ledger=primary.get_ledger_state()
        primary.set_contrast(false)
        primary.set_sorted(false)
        var original: Array=primary.get_sequence()
        var counts: Array=primary.get_counts()
        var entropy: float=primary.get_entropy()
        observations.original_symbols=original
        check("ledger retains 200 draws and ten categories",original.size()==200 and counts.size()==10)
        await snapshot("ledger-drawn",primary.to_global(Vector3(0,2.2,4.5)),primary.to_global(Vector3(0,1.0,0)),57)
        primary.toggle_sort()
        await create_timer(1.3).timeout
        check("installed SORT retains the original list",primary.get_sequence()==original)
        check("installed SORT retains counts and entropy",primary.get_counts()==counts and is_equal_approx(primary.get_entropy(),entropy))
        check("installed sorted copy actually has ascending symbols",primary.sorted_copy()!=original and primary.sorted_copy()[0]<=primary.sorted_copy()[-1])
        await snapshot("ledger-sorted",primary.to_global(Vector3(0,2.2,4.5)),primary.to_global(Vector3(0,1.0,0)),57)
        primary.toggle_contrast()
        observations.contrast_ledger=primary.get_ledger_state()
        check("contrast changes the counts",primary.get_counts()!=counts)
        primary.toggle_contrast()
        check("contrast returns the cached original sample",primary.get_sequence()==original)
        primary.set_sorted(false)
    await snapshot("above",origin+Vector3(4,17,0),origin+Vector3(12,0,22),70)
    await snapshot("entry",origin+Vector3(12.5,1.7,2),origin+Vector3(12.5,1.6,18),75)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec,primary)
    observations.scope="Current museum; scripted controls and captures. No full-route, physical headset or learner acceptance."

func study_checks(spec: Dictionary,primary: Node3D) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(14.8,0,8.0)
    study.rotation.y=-PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    observations.student_yaw_degrees=-90
    observations.lesson=spec.lesson
    check("study stands over museum floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,1.5))
    check("approach has floor",not floor_at(approach).is_empty())
    var capsule:=CapsuleShape3D.new()
    capsule.radius=0.26
    capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("approach clear of other bodies",obstacles.is_empty())
    check("complete study initializes inside the museum",study.rows.size()==2 and study.bars.size()==4 and not study.title.text.is_empty())
    var original: Array=study.record.duplicate()
    var counts: Array=study.counts_of(study.record)
    var entropy: float=study.entropy_of(counts)
    var rng_state: int=study.rng.state
    observations.student_counts=counts
    observations.student_entropy=entropy
    if primary!=null:
        var installed_script=primary.get_script()
        check("counts agree with installed ledger calculation",installed_script.counts_of(original,4)==counts)
        check("entropy agrees with installed ledger calculation",is_equal_approx(installed_script.entropy_of(counts,original.size()),entropy))
    await snapshot("student-drawn",study.to_global(Vector3(0,1.7,4.8)),study.to_global(Vector3(0,1.65,0)),50)
    study.point.position.x=0
    study.point.action()
    check("carried point sorts a copy",study.sorted_view and study.shown!=original and study.record==original)
    check("sorting retains counts entropy and generator state",study.counts_of(study.shown)==counts and is_equal_approx(study.entropy_of(study.counts_of(study.shown)),entropy) and study.rng.state==rng_state)
    await snapshot("student-sorted",study.to_global(Vector3(0,1.7,4.8)),study.to_global(Vector3(0,1.65,0)),50)
    study.record.clear()
    for i in range(study.sample_count):study.record.append(i%study.palette.size())
    study.sorted_view=false
    study.draw_state()
    await snapshot("student-cycle",study.to_global(Vector3(0,1.7,4.8)),study.to_global(Vector3(0,1.65,0)),50)
    observations.point_before_cycle_action=xyz(study.point.position)
    study.point.position.x=0
    study.point.action()
    check("regular cycle gives maximum marginal entropy",is_equal_approx(study.entropy_of(study.counts_of(study.record)),2.0))
    check("cycle and sorted copy have different neighbours",study.neighbour_changes(study.record)==15 and study.neighbour_changes(study.shown)==3)
    await snapshot("student-cycle-sorted",study.to_global(Vector3(0,1.7,4.8)),study.to_global(Vector3(0,1.65,0)),50)
    study.queue_free()
