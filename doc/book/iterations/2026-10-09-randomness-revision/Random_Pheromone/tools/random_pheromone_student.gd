extends SceneTree
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[pheromone] ","PASS " if ok else "FAIL ",title)
func floats_match(a: Array, b: Array) -> bool:
    if a.size()!=b.size():return false
    for i in a.size():
        if not is_equal_approx(float(a[i]),float(b[i])):return false
    return true
func total(values: Array) -> float:
    var value:=0.0
    for v in values:value+=v
    return value
func run() -> void:
    await process_frame
    var source: String;var report: String;var extra_fade:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--extra-fade":extra_fade=true
    var script=load(source);var study=script.new()
    study.position=Vector3(8,0,6);study.rotation.y=PI/2;root.add_child(study)
    var original_guidance: float=study.guidance;var original_decay: float=study.decay_rate
    check("ready initializes two64-cell views and one inherited point",study.field.size()==64 and study.visits.size()==64 and study.tiles.size()==64 and study.columns.size()==64 and study.markers.size()==2 and study.point.has_method("pick_up"))
    check("initial position is kept without a visit",study.path==[Vector2i(4,4)] and is_zero_approx(total(study.field)) and is_zero_approx(total(study.visits)))
    check("coordinates validate before flat indexing",not study.valid(Vector2i(-1,1)) and not study.valid(Vector2i(8,1)) and not study.valid(Vector2i(1,-1)) and not study.valid(Vector2i(1,8)) and study.index(Vector2i(3,2))==19)
    # Run the production implementation in a reduced numerical configuration.
    # No scene/mesh rebuild or production source modification is needed.
    var artifact=load("res://algorithms/randomness/pheromone_terrain/pheromone_terrain.gd").new()
    artifact.mesh_instance=MeshInstance3D.new();artifact.add_child(artifact.mesh_instance)
    artifact.x_segments=7;artifact.y_segments=7;artifact.border_size=0
    artifact.sensor_distance=1;artifact.walk_seed=study.sample_seed
    artifact.pheromone_attraction=original_guidance;artifact.pheromone_decay_rate=original_decay
    artifact.pheromone_deposit=study.deposit;artifact.raise_amount=1;artifact.max_height=1000
    var parity: Dictionary={}
    for law in ["trail","avoid"]:
        artifact.rule=law;artifact._init_rng();artifact._initialize_grids()
        artifact.walkers=[{"x":4,"y":4,"active":true,"hx":1,"hy":0}]
        study.avoid=law=="avoid";study.replay()
        var positions_ok:=true;var field_ok:=true;var visits_ok:=true;var state_ok:=true
        for i in range(100):
            artifact._decay_pheromones(0.2);artifact._walk_step()
            if extra_fade:artifact._decay_pheromones(20)
            study.advance(1)
            positions_ok=positions_ok and study.at==Vector2i(artifact.walkers[0].x,artifact.walkers[0].y)
            state_ok=state_ok and study.rng.state==artifact._rng.state
            for y in range(8):
                for x in range(8):
                    field_ok=field_ok and is_equal_approx(study.field[y*8+x],artifact.pheromone_grid[y][x])
                    visits_ok=visits_ok and study.visits[y*8+x]==int(artifact.vertex_grid[y][x].y)
        check(law+"100 source steps match positions and random draw state",positions_ok and state_ok)
        check(law+"100 source steps match scent and departures",field_ok and visits_ok)
        check(law+"100 steps retain101 positions and100 departure visits",study.path.size()==101 and is_equal_approx(total(study.visits),100))
        var records: Array=study.path.duplicate();var field: Array=study.field.duplicate();var visits: Array=study.visits.duplicate();var state: int=study.rng.state
        study.replay()
        for i in range(5):study.advance(20)
        check(law+"batching preserves path signal visits and stream",study.path==records and floats_match(study.field,field) and study.visits==visits and study.rng.state==state)
        parity[law]={"scent_total":total(study.field),"unique_departures":study.visits.filter(func(v):return v>0).size(),"path":study.path}
    observations.source_comparison={"steps_per_rule":100,"grid":"8x8; border0; sensor1; one walker; height counts departures", "extra_fade":extra_fade,"runs":parity}
    study.avoid=false;study.guidance=1.0;study.replay()
    check("strict empty tie goes to first positiveX",study.choose(Vector2i(4,4))==Vector2i(5,4))
    study.avoid=true
    check("avoid blank tie also goes positiveX",study.choose(Vector2i(4,4))==Vector2i(5,4))
    check("edge skips out-of-bounds guided target",study.choose(Vector2i(7,4))==Vector2i(6,4))
    study.field.fill(0.0);study.field[study.index(Vector2i(3,4))]=2.0
    study.avoid=false
    check("attract reads strongest scent not visit height",study.choose(Vector2i(4,4))==Vector2i(3,4))
    study.visits[study.index(Vector2i(5,4))]=100;study.redraw()
    check("changing visit history alone does not change guidance",study.choose(Vector2i(4,4))==Vector2i(3,4))
    study.avoid=true
    check("avoid reads weakest rather than strongest",study.choose(Vector2i(4,4))==Vector2i(5,4))
    study.guidance=0.0;study.rng.seed=19
    var expected:=RandomNumberGenerator.new();expected.seed=19;var random_ok:=true;var stuck:=false
    for i in range(40):
        expected.randf();var d: Vector2i=study.DIRS[expected.randi()%8]
        var wanted:=Vector2i(clampi(7+d.x,0,7),clampi(7+d.y,0,7))
        var result: Vector2i=study.choose(Vector2i(7,7))
        random_ok=random_ok and result==wanted and study.rng.state==expected.state
        stuck=stuck or result==Vector2i(7,7)
    check("random branch uses eight directions then clamps including staying put",random_ok and stuck)
    study.guidance=original_guidance;study.decay_rate=original_decay;study.avoid=false;study.replay();study.advance(100)
    var saved_path: Array=study.path.duplicate();var saved_visits: Array=study.visits.duplicate();var saved_rng: int=study.rng.state
    var saved_field: Array=study.field.duplicate()
    study.decay_rate=0.2;study.fade(10000);study.redraw()
    check("fading erases scent but keeps visits path and RNG",is_zero_approx(total(study.field)) and study.visits==saved_visits and study.path==saved_path and study.rng.state==saved_rng)
    var visuals_ok:=true
    for i in range(64):
        visuals_ok=visuals_ok and study.tiles[i].material_override.albedo_color.is_equal_approx(Color(0.95,0.94,0.90))
        visuals_ok=visuals_ok and is_equal_approx(study.columns[i].scale.y,0.02+minf(saved_visits[i]*0.06,0.6))
    check("two displays separate zero scent from retained visit heights",visuals_ok)
    study.visits[0]=40;study.field[0]=9;study.redraw()
    check("visual saturation preserves uncapped records",study.visits[0]==40 and is_equal_approx(study.field[0],9) and is_equal_approx(study.columns[0].scale.y,0.62) and study.tiles[0].material_override.albedo_color.is_equal_approx(Color(0.8,0.02,0.35)))
    study.decay_rate=0;study.replay();study.advance(100)
    check("without decay100 departures leave60 scent",is_equal_approx(total(study.field),60) and is_equal_approx(total(study.visits),100))
    study.decay_rate=original_decay;study.replay();study.advance(100)
    check("replay returns original selected-rule experiment",study.path==saved_path and study.visits==saved_visits and floats_match(study.field,saved_field) and study.rng.state==saved_rng)
    study.advance(300)
    check("overlong request stops at256steps",study.path.size()==257 and is_equal_approx(total(study.visits),256))
    var capped_field: Array=study.field.duplicate();saved_rng=study.rng.state
    study.advance(20)
    check("full budget prevents decay deposits and random draws",floats_match(study.field,capped_field) and study.rng.state==saved_rng)
    study.replay();saved_rng=study.rng.state
    study.point.position=Vector3(-0.3,1.12,0.85);study.point.dropped.emit(study.point)
    await physics_frame;await process_frame
    check("moving release and idle time leave the paused experiment alone",study.path.size()==1 and study.rng.state==saved_rng)
    study.point.global_position=study.to_global(Vector3(-0.3,1.12,0.85));study.point.action()
    check("STEP action uses local frame",study.path.size()==2)
    study.point.global_position=study.to_global(Vector3(0.3,1.12,0.85));study.point.action()
    check("plus20 adds to existing steps",study.path.size()==22)
    study.point.global_position=study.to_global(Vector3(0.9,1.12,0.85));study.point.action()
    check("RULE changes policy and resets all histories",study.avoid and study.path.size()==1 and is_zero_approx(total(study.field)) and is_zero_approx(total(study.visits)))
    study.advance(1);study.point.global_position=study.to_global(Vector3(-0.9,1.12,0.85));study.point.action()
    check("REPLAY keeps selected rule",study.avoid and study.path.size()==1)
    var other=script.new();root.add_child(other);study.advance(20)
    check("instances keep independent state",other.path.size()==1 and is_zero_approx(total(other.field)) and other.rng!=study.rng)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"source":source,"engine":Engine.get_version_info(),"scope":"Author-informed exact printed reconstruction and source-rule comparison; supplied actions, not headset."},"  "))
    file.close();study.free();other.free();artifact.free();quit(0 if failures.is_empty() else 1)
