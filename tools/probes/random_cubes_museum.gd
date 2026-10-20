extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.6).timeout
    var die:=find_scene("/continuing_die.gd")
    var pair:=find_scene("/paired_dice_column.gd")
    check("continuing and paired dice exist",die!=null and pair!=null)
    if die==null or pair==null:return
    observations.artifacts=[]
    for rec in museum.get("_edit_records"):
        var n=rec.get("node")
        if not is_instance_valid(n) or rec.get("seg")!=hall:continue
        observations.artifacts.append({"token":rec.get("token"),"hall_local":xyz(hall.to_local(n.global_position))})
    await snapshot("hall-before",hall.to_global(Vector3(6,15,0)),hall.to_global(Vector3(6,0,14)),70)
    await snapshot("die-before",die.to_global(Vector3(0,2,3.5)),die.to_global(Vector3(0,1.3,0)),55)
    check("live record initially empty and example separate",die.chain.is_empty() and die.total==0 and die.example_column.get_child_count()==3 and die.EXAMPLE==[6,6,3])
    die._on_landed(6)
    check("unreleased result cannot enter chain",die.chain.is_empty())
    # A real low drop onto its own tray: identity local orientation puts six up.
    var tray: Node3D=die.tray
    var body: RigidBody3D=tray._dice_body
    body.freeze=true
    body.global_transform=Transform3D(tray.global_basis.orthonormalized(),tray.to_global(Vector3(0,tray.table_height+0.2,0)))
    body.linear_velocity=Vector3.ZERO
    body.angular_velocity=Vector3.ZERO
    body.freeze=false
    tray._on_dice_dropped(null)
    var start:=Time.get_ticks_msec()
    while die.chain.is_empty() and Time.get_ticks_msec()-start<4500:await tick()
    check("physical low drop records six once and keeps chain open",die.chain==[6] and die.total==6 and not die.closed)
    await create_timer(0.8).timeout
    check("settled die does not count again while idle",die.chain==[6])
    await snapshot("die-physical-six",die.to_global(Vector3(0,2,3.5)),die.to_global(Vector3(0,1.3,0)),55)
    # Supplied event cases verify the state boundary, not a claim of thrown outcomes.
    die.new_chain()
    for face in [6,6,3]:
        die._on_released()
        die._on_landed(face)
        die._on_landed(face)
    check("supplied six six three closes at15 without double count",die.chain==[6,6,3] and die.total==15 and die.closed and not die.capped)
    check("three event sections remain visible",die.live_column.get_child_count()==4 and is_equal_approx(die.get_state().height,1.35))
    die._on_released();die._on_landed(6)
    check("closed chain ignores another released result",die.chain==[6,6,3])
    var saved: Array=die.chain.duplicate()
    tray.return_to_tray()
    check("return is not a throw and retains closed record",die.chain==saved and not die.armed)
    die.new_chain()
    check("new chain clears total and permission state",die.chain.is_empty() and die.total==0 and not die.closed and not die.capped and not die.armed)
    for i in range(5):die._on_released();die._on_landed(6)
    check("five sixes reach unfinished display limit",die.total==30 and not die.closed and die.capped and die.status.text.contains("UNFINISHED"))
    die._on_released();die._on_landed(3)
    check("capped record rejects further outcomes",die.chain.size()==5 and die.total==30)
    die.new_chain()
    for i in range(4):die._on_released();die._on_landed(6)
    die._on_released();die._on_landed(3)
    check("non-six on final place is closed not unfinished",die.total==27 and die.closed and not die.capped)
    die.new_chain()
    pair.clear_record()
    pair._on_released(0);pair._on_landed(3,0)
    check("one die waits for its partner",pair.total_pairs==0 and pair.pending==[3,0])
    pair._on_released(1);pair._on_landed(4,1)
    check("pair preserves contributions as well as sum",pair.total_pairs==1 and pair.history==[Vector2i(3,4)] and pair.last_pair.x+pair.last_pair.y==7)
    pair.return_dice()
    check("returning paired dice retains their history",pair.total_pairs==1 and pair.history==[Vector2i(3,4)])
    pair.clear_record()
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec)
    observations.scope="Real museum. One supplied low physical drop; other branches use explicit events. No headset or full-route acceptance."

func study_checks(spec: Dictionary) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(1.3,0,11.8)
    study.rotation.y=PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    observations.student_yaw_degrees=90
    check("study bay has floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,2))
    check("student approach has floor",not floor_at(approach).is_empty())
    var capsule:=CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("student approach clear of other bodies",obstacles.is_empty())
    check("complete listing initializes inside museum",study.units.size()==30 and study.history.is_empty() and not study.status.text.is_empty())
    study.seed_value=spec.example_seed
    study.reset_run()
    observations.demonstration_seed=spec.example_seed
    observations.seed_selection="Selected by search for6,6,3; replayed through the actual generator. Not a typical-run claim."
    for i in range(2):
        study.point.position.x=0
        study.point.action()
    check("point actions draw two sixes at demonstration seed",study.history==[6,6] and study.total==12 and not study.closed)
    await snapshot("student-open",study.to_global(Vector3(0,2.2,3.8)),study.to_global(Vector3(0,1.35,0)),51)
    study.point.position.x=0;study.point.action()
    check("third actual draw closes at fifteen",study.history==[6,6,3] and study.total==15 and study.closed and not study.limited)
    await snapshot("student-closed",study.to_global(Vector3(0,2.2,3.8)),study.to_global(Vector3(0,1.35,0)),51)
    var state: int=study.rng.state
    study.point.position.x=0;study.point.action()
    check("closed point action cannot grow the column",study.history==[6,6,3] and study.rng.state==state)
    study.point.position.x=-0.85;study.point.action()
    for i in range(3):study.draw_face()
    check("replay works inside the museum",study.history==[6,6,3])
    study.free()
    var short=load(spec.short).new()
    short.position=Vector3(1.3,0,11.8)
    short.rotation.y=PI/2
    short.seed_value=spec.limit_seed
    hall.add_child(short)
    for i in range(3):short.draw_face()
    check("actual three-place edit has unfinished eighteen-unit column",short.max_draws==3 and short.history==[6,6,6] and short.total==18 and short.limited and not short.closed)
    observations.limit_demonstration_seed=spec.limit_seed
    await snapshot("student-limited",short.to_global(Vector3(0,2.2,3.8)),short.to_global(Vector3(0,1.35,0)),51)
    short.free()
