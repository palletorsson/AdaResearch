extends "res://tools/probes/transformation_encounters.gd"

func press(board: Node, id: String) -> void:
    var button=board.sample_console.buttons[id]
    var area=button.get_node("InteractableAreaButton")
    area.button_pressed.emit(area)

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var board=find_scene("/monte_carlo_dartboard.gd")
    check("installed Monte Carlo board exists",board!=null)
    if board==null:return
    check("budget console starts paused",board.sample_budget and not board.auto_throw)
    check("keyboard off retained",not board.keyboard_shortcuts)
    observations.board=xyz(hall.to_local(board.global_position))
    await snapshot("hall-before",hall.to_global(Vector3(7.5,13,3)),hall.to_global(Vector3(7.5,0,17)),65)
    # Temporary seeded source comparison; production defaults and files stay intact.
    board.dart_seed=42;board._setup_seeded_stream();press(board,"REPLAY")
    check("REPLAY clears counts and stays paused",board._total_count==0 and board._inside_count==0 and not board.auto_throw)
    var rng:=RandomNumberGenerator.new();rng.seed=42
    var expected_hits:=0;var source_ok:=true
    for i in range(256):
        var x:=rng.randf();var y:=rng.randf()
        if pow(x-0.5,2)+pow(y-0.5,2)<=0.25:expected_hits+=1
        board._throw_dart()
        source_ok=source_ok and is_equal_approx(board._last_rx,x) and is_equal_approx(board._last_ry,y) and board._inside_count==expected_hits
    check("256 installed trials match ordered draws and circle tally",source_ok and board._total_count==256)
    var installed_hits: int=board._inside_count
    var seed_start:=RandomNumberGenerator.new();seed_start.seed=42
    press(board,"REPLAY")
    check("installed REPLAY rewinds generator",board._total_count==0 and board.sample_run.rng.state==seed_start.state)
    press(board,"THROW")
    check("THROW signal adds exactly one",board._total_count==1)
    press(board,"+100")
    check("plus100 extends existing record",board._total_count==101 and board.sample_run.points.size()==101)
    press(board,"FILL")
    check("installed cap is500 while picture keeps300",board._total_count==500 and board._dart_meshes.size()==300)
    var state: int=board.sample_run.rng.state;press(board,"THROW")
    check("installed full board spends no further draw",board._total_count==500 and board.sample_run.rng.state==state)
    var retained: Array=board.sample_run.points.duplicate()
    press(board,"8 SEEDS")
    check("seed comparison leaves current run intact",board.sample_console.comparison_rows.size()==8 and board.sample_run.points==retained and board.sample_run.rng.state==state)
    press(board,"NEXT SEED")
    check("next seed increments and clears",board.dart_seed==43 and board._total_count==0)
    board.dart_seed=42;press(board,"REPLAY");board.budget_add(140)
    await snapshot("installed-dartboard",board.to_global(Vector3(1.8,2.1,3.6)),board.to_global(Vector3(0,1.05,0.4)),57)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    var study=load(spec.lesson).new()
    study.position=Vector3(10.5,0,13);study.rotation.y=PI
    hall.add_child(study);await tick()
    check("learner origin has museum floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,1.35))
    check("learner approach has museum floor",not floor_at(approach).is_empty())
    var shape:=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("learner standing approach is clear",obstacles.is_empty())
    check("point starts at reachable height",study.point.position.y>0.9 and study.point.position.y<1.3)
    study.point.global_position=study.to_global(Vector3(0,1.04,0.55));study.point.action()
    check("inherited ONE action appends one sample",study.samples.size()==1)
    study.point.global_position=study.to_global(Vector3(0.8,1.04,0.55));study.point.action()
    check("inherited BATCH action appends16",study.samples.size()==17)
    study.point.global_position=study.to_global(Vector3(-0.8,1.04,0.55));study.point.action()
    check("inherited REPLAY empties samples and history",study.samples.is_empty() and study.estimates.is_empty())
    study.point.position=Vector3(0,1.04,0.55)
    study.add_samples(16)
    await snapshot("student-sixteen",study.to_global(Vector3(0,1.85,3.0)),study.to_global(Vector3(0,1.55,0)),56)
    study.add_samples(240)
    check("printed estimate matches installed tally under shared seed",study.inside==installed_hits and study.samples.size()==256)
    observations.uniform={"inside":study.inside,"estimate":study.estimates[-1]}
    await snapshot("student-uniform",study.to_global(Vector3(0,1.85,3.0)),study.to_global(Vector3(0,1.55,0)),56)
    study.x_span=0.2;study.replay();study.add_samples(256)
    observations.strip={"inside":study.inside,"estimate":study.estimates[-1]}
    check("strip edit keeps finite count but changes sample",study.samples.size()==256 and study.inside!=installed_hits)
    await snapshot("student-strip",study.to_global(Vector3(0,1.85,3.0)),study.to_global(Vector3(0,1.55,0)),56)
    study.x_span=1;study.replay();study.add_samples(256)
    await snapshot("hall-with-study",hall.to_global(Vector3(7.5,13,3)),hall.to_global(Vector3(7.5,0,17)),65)
    observations.scope="Temporary printed reconstruction in existing hall; supplied button signals and PointBody actions. No physical headset or unfamiliar student test."
    study.free()
