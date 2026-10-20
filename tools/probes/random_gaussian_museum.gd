extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var sampler = find_scene("/distribution_sampler.gd")
    check("installed sampler exists",sampler != null)
    if sampler == null:return
    sampler.set_process(false)
    observations.artifacts=[]
    for rec in museum.get("_edit_records"):
        var n=rec.get("node")
        if is_instance_valid(n) and rec.get("seg")==hall:
            observations.artifacts.append({"token":rec.get("token"),"hall_local":xyz(hall.to_local(n.global_position))})
    await snapshot("hall-before",hall.to_global(Vector3(6,18,-1)),hall.to_global(Vector3(6,0,9)),65)
    sampler.set_running(false);sampler.set_sample_seed(42);sampler.set_distribution(1);sampler.set_width(0.15);sampler.set_bins(30)
    sampler.batch(300)
    var values: PackedFloat32Array=sampler.landed_values().duplicate()
    var counts: Array=sampler._bins.duplicate()
    var state: int=sampler._rng.state
    var expected:=RandomNumberGenerator.new();expected.seed=42
    var match_values:=true
    for i in range(300):
        var u:=maxf(expected.randf(),0.0001)
        var v:=expected.randf()
        var raw:=0.5+0.15*sqrt(-2*log(u))*cos(TAU*v)
        match_values=match_values and is_equal_approx(values[i],clampf(raw,0,1))
    check("installed Gaussian uses two uniform draws and clamps each value",match_values and state==expected.state)
    check("cabinet configured and batch lands300 immediately",sampler.stand=="cabinet" and sampler._total_samples==300 and sampler.in_flight()==0)
    await snapshot("sampler-gaussian",sampler.to_global(Vector3(0,1.9,2.8)),sampler.to_global(Vector3(0,1.15,0)),48)
    sampler.set_bins(60)
    check("rebin preserves sample record and generator",sampler.landed_values()==values and sampler._rng.state==state and sampler._bins.reduce(func(a,b):return a+b,0)==300)
    sampler.set_bins(30)
    check("returning to original bins restores counts",sampler._bins==counts)
    sampler.clear();sampler.batch(300)
    check("clear and equal batch replay retained values",sampler.landed_values()==values)
    sampler.set_distribution(0);sampler.batch(300)
    expected.seed=42;match_values=true
    var uniform: PackedFloat32Array=sampler.landed_values()
    for i in range(300):match_values=match_values and is_equal_approx(uniform[i],expected.randf())
    check("uniform uses one draw and law change starts fresh",match_values and sampler._rng.state==expected.state and uniform!=values)
    var expected_counts: Array=sampler.expected_counts()
    check("uniform expected bars each count10 atN300",expected_counts.all(func(v):return is_equal_approx(v,10.0)))
    await snapshot("sampler-uniform",sampler.to_global(Vector3(0,1.9,2.8)),sampler.to_global(Vector3(0,1.15,0)),48)
    sampler.clear();sampler.max_samples=10
    for i in range(4):sampler.sample()
    sampler.set_running(false);sampler.batch(100)
    check("airborne draws reserve capacity",sampler._drawn==10 and sampler._total_samples==6 and sampler.in_flight()==4)
    sampler._update_falling_samples(2.0)
    check("pause permits issued beads to land",sampler._total_samples==10 and not sampler.auto_sample)
    sampler.clear()
    check("clear removes airborne meshes and resets timer while paused",sampler._sample_markers.get_child_count()==0 and sampler._values.is_empty() and sampler._sample_timer==0 and not sampler.auto_sample)
    sampler.max_samples=1000;sampler.set_distribution(1);sampler.set_width(0.25);sampler.batch(1000)
    check("wider source run is finite bounded and accounts for clips",sampler._clipped>0 and sampler._values.size()==1000 and Array(sampler._values).all(func(v):return is_finite(v) and v>=0 and v<=1))
    sampler.cycle_width()
    check("WIDTH changes deviation and clears without resuming",is_equal_approx(sampler.gaussian_std,0.08) and sampler._drawn==0 and not sampler.auto_sample)
    var splatter=find_scene("/GaussianPaintSplatter.gd")
    check("paint refusal remains a separate installed comparison",splatter!=null and is_equal_approx(splatter.stddev,80.0) and is_equal_approx(splatter.safe_zone_radius,80.0))
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec)
    observations.scope="Production controls called explicitly. Author-informed reconstruction; no physical headset or independent reader."

func study_checks(spec: Dictionary) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(3,0,7)
    study.rotation.y=PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    check("student station floor is at root height",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,1.7))
    check("student approach has floor",not floor_at(approach).is_empty())
    var shape:=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("student approach is body-sized and clear",obstacles.is_empty())
    for i in range(3):
        study.point.position=Vector3(-0.3,1.1,0.6);study.point.action()
    check("inherited trigger produces300 retained values",study.values.size()==300)
    var saved: Array=study.values.duplicate();var state: int=study.rng.state
    await snapshot("student-ten-bins",study.to_global(Vector3(0,2.3,4)),study.to_global(Vector3(0,1.65,0)),48)
    study.point.position=Vector3(0.3,1.1,0.6);study.point.action()
    check("BINS through point preserves record and RNG",study.bin_count==20 and study.values==saved and study.rng.state==state)
    await snapshot("student-twenty-bins",study.to_global(Vector3(0,2.3,4)),study.to_global(Vector3(0,1.65,0)),48)
    study.point.position=Vector3(-0.9,1.1,0.6);study.point.action()
    check("REPLAY through point restores exact record",study.values==saved)
    study.point.position=Vector3(0.9,1.1,0.6);study.point.action()
    check("LAW through point clears to uniform",not study.gaussian and study.values.is_empty())
    for i in range(3):
        study.point.position=Vector3(-0.3,1.1,0.6);study.point.action()
    await snapshot("student-uniform",study.to_global(Vector3(0,2.3,4)),study.to_global(Vector3(0,1.65,0)),48)
    observations.interaction_scope="Inherited action method at supplied local poses; not a physical grab-driver test."
    study.free()
