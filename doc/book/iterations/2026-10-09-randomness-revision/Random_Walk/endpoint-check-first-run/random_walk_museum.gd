extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var tank = find_scene("/random_walk_terrarium.gd")
    check("installed terrarium exists", tank != null)
    if tank == null: return
    tank.set_process(false)
    observations.artifacts = []
    for rec in museum.get("_edit_records"):
        var n = rec.get("node")
        if not is_instance_valid(n) or rec.get("seg") != hall: continue
        observations.artifacts.append({"token":rec.get("token"),"hall_local":xyz(hall.to_local(n.global_position))})
    await snapshot("hall-before",hall.to_global(Vector3(10,23,-1)),hall.to_global(Vector3(10,0,18)),68)
    check("logbook has private seed five walkers and controls", tank.stand == "logbook" and tank.walk_seed >= 0 and tank.num_walkers == 5 and tank._control_panel != null)
    tank.set_walk_seed(42);tank.set_mode(0)
    var reference := RandomNumberGenerator.new();reference.seed = 42
    var expected: Array[Vector3] = []
    for i in range(5):
        var a := reference.randf()*TAU
        expected.append(Vector3(cos(a),0,sin(a))*0.015+Vector3(0,0.2,0))
    tank._step_all_walkers()
    var matches := true
    for i in range(5): matches = matches and tank._walker_positions[i].is_equal_approx(expected[i])
    check("one planar batch uses one draw per walker in order", matches and tank._rng.state == reference.state)
    for i in range(99): tank._step_all_walkers()
    var history: PackedVector3Array = tank._walker_trails[0].duplicate()
    var saved: Array = tank._walker_positions.duplicate()
    check("planar trail holds previous positions and bead is current", history.size() == 100 and history[0].is_equal_approx(Vector3(0,0.2,0)) and tank._total_steps == 100)
    tank._step_all_walkers()
    var next: Array = tank._walker_positions.duplicate()
    tank.reset()
    for i in range(100): tank._step_all_walkers()
    check("reset replays equal step count", tank._walker_positions == saved)
    for i in range(tank.num_walkers): tank._walker_trails[i] = PackedVector3Array()
    check("controlled erasure removes the stored trail",tank._walker_trails[0].is_empty())
    tank._step_all_walkers()
    check("erasing trails does not steer next step", tank._walker_positions == next)
    var state: int = tank._rng.state
    tank.set_follow_one(false)
    check("ALL changes emphasis without stepping or drawing", tank._walker_positions == next and tank._rng.state == state and not tank.follow_one)
    tank.set_follow_one(true)
    tank._step_timer = 0.013;tank.reset()
    check("installed reset retains partial step timer", is_equal_approx(tank._step_timer,0.013))
    tank._step_timer = 0;tank._process(2.0)
    check("two second frame accepts five batches and drops excess time", tank._total_steps == 5 and is_equal_approx(tank._run_clock,2.0) and tank._step_timer < 0.0001)
    check("wall overshoot folds rather than clamps", tank._reflect_boundaries(Vector3(0.27,0.2,0)).is_equal_approx(Vector3(0.23,0.2,0)))
    tank.reset()
    for i in range(300): tank._step_all_walkers()
    check("installed history is a200-position window", tank._walker_trails[0].size() == 200)
    var bounds_ok := true
    for p in tank._walker_positions: bounds_ok = bounds_ok and absf(p.x) <= 0.25 and absf(p.z) <= 0.25 and is_equal_approx(p.y,0.2)
    check("planar walker centres remain inside configured box",bounds_ok)
    tank._update_trails();tank._update_stats();tank._update_logbook()
    await snapshot("terrarium-planar",tank.to_global(Vector3(0,2,2.4)),tank.to_global(Vector3(0,1.1,0)),46)
    tank.set_mode(1)
    reference.seed = 42
    for i in range(10):reference.randf()
    tank._step_all_walkers()
    check("3D consumes two draws per walker", tank._rng.state == reference.state)
    for i in range(149): tank._step_all_walkers()
    tank._update_trails();tank._update_stats();tank._update_logbook()
    await snapshot("terrarium-volume",tank.to_global(Vector3(0.9,1.7,1.6)),tank.to_global(Vector3(0,1.1,0)),45)
    tank.set_mode(2)
    reference.seed = 42
    for i in range(15):reference.randf()
    tank._step_all_walkers()
    check("long step consumes three draws per walker",tank._rng.state == reference.state)
    var previous_seed: int = tank.walk_seed
    tank.new_seed()
    check("NEW SEED changes current number and resets positions",tank.walk_seed != previous_seed and tank._total_steps == 0)
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec)
    observations.scope = "Museum production code with explicit mode/reset calls and supplied steps. No headset or unfamiliar-reader claim."

func study_checks(spec: Dictionary) -> void:
    var study = load(spec.lesson).new()
    study.position = Vector3(4,0,7)
    hall.add_child(study);study.set_process(false)
    await tick()
    observations.student_bay = xyz(study.position)
    check("learner bay has floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3 = study.to_global(Vector3(0,0,1.7))
    check("learner approach has floor",not floor_at(approach).is_empty())
    var shape := CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query := PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("learner body-sized approach is clear",obstacles.is_empty())
    check("printed point and trail initialize in museum",study.positions.size()==1 and study.steps==0)
    for i in range(64):study.step()
    check("sixty-four steps retain65 positions and64 segments",study.positions.size()==65 and study.trail.get_child_count()==64)
    await snapshot("student-trail",study.to_global(Vector3(0,3.6,3.8)),study.to_global(Vector3(0,1.12,0)),46)
    check("point remains at current endpoint after rendering and physics",study.point.position.is_equal_approx(study.current))
    var end: Vector3=study.current
    study.point.picked_up.emit(study.point)
    study._process(2.0)
    check("supplied pickup pauses random stepping",study.steps==64 and study.current==end)
    study.point.position=Vector3(0.3,2,0.2)
    study.point.action()
    study.point.dropped.emit(study.point)
    for i in range(64):study.step()
    check("trigger and release replays from saved origin",study.steps==64 and study.current.is_equal_approx(end))
    study.point.picked_up.emit(study.point)
    study.point.position=Vector3(0.5,2,-0.2)
    study.point.dropped.emit(study.point)
    check("ordinary release chooses projected starting position",study.origin.is_equal_approx(Vector3(0.5,study.HEIGHT,-0.2)) and study.steps==0)
    for i in range(64):study.step()
    await snapshot("student-new-start",study.to_global(Vector3(0,3.6,3.8)),study.to_global(Vector3(0,1.12,0)),46)
    observations.endpoint_after_render={"point":xyz(study.point.position),"current":xyz(study.current),"distance":study.point.position.distance_to(study.current),"root":xyz(study.global_position)}
    check("released point remains on replay endpoint after rendering",study.point.position.is_equal_approx(study.current))
    observations.student_steps=64
    observations.interaction_scope="Pickup/drop signals and inherited point.action supplied explicitly; physical grab driver not simulated."
    study.free()
