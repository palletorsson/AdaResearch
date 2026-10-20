extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[noise learner] ","PASS " if ok else "FAIL ",title)

func run() -> void:
    await process_frame
    var source := ""
    var report := ""
    var changed := false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report=arg.trim_prefix("--report=")
        if arg == "--changed": changed=true
    var script = load(source)
    var study = script.new()
    study.position = Vector3(4,0,7)
    study.rotation.y = PI / 3
    root.add_child(study)
    check("entry creates its own label, frame and twelve points", study.label.is_inside_tree() and study.points.size()==12 and study.get_child_count()==30)
    check("all sampled bodies are the inherited sphere and frozen pickable", study.points[0].has_method("pick_up") and study.points[0].freeze and is_equal_approx(study.points[0].get_child(0).mesh.radius,.14))
    check("all generated centres meet distance and bounds", valid_cloud(study))
    check("display and generated record agree", positioned(study))
    await create_timer(.3).timeout
    check("generated bodies remain at their homes after physics", positioned(study))
    print("POINT DIAGNOSTIC ", study.points[0].position, " expected ", study.CENTRE+study.homes[0], " frozen ", study.points[0].freeze)
    check("accounting separates candidate and place totals", study.attempts==study.homes.size()+study.refused and study.attempts<=study.requested*study.tries_per_place)
    var expected := RandomNumberGenerator.new()
    expected.seed=42
    var x:=expected.randf_range(-1.2,1.2)
    var y:=expected.randf_range(-.7,.7)
    var z:=expected.randf_range(-.06,.06)
    check("first centre uses three requests in declared order",study.homes[0].is_equal_approx(Vector3(x,y,z*(5 if changed else 1))))
    var homes: Array = study.homes.duplicate()
    var tries: int = study.attempts
    var state: int = study.rng.state
    for i in range(tries*3-3):expected.randf()
    check("three draws are spent on every candidate including refusals",study.rng.state==expected.state)
    var point_id: int = study.control.get_instance_id()
    study.control.position.x=-1.2
    study.control.action()
    check("inherited control repeats the entire recipe in rotated host",study.homes==homes and study.attempts==tries and study.rng.state==state and study.control.get_instance_id()==point_id)
    study.points[0].position=study.points[1].position
    study._process(.016)
    check("observer detects overlap without repairing it",study.close_pairs()>0 and study.points[0].position==study.points[1].position)
    check("moving points and observing keeps the original and RNG",study.homes==homes and study.rng.state==state)
    var ids: Array=[]
    for p in study.points: ids.append(p.get_instance_id())
    study.rng.randf()
    var advanced: int=study.rng.state
    study.control.position.x=1.2
    study.control.action()
    var ids_after: Array=[]
    for p in study.points:ids_after.append(p.get_instance_id())
    check("restore retains identities and current generator state",ids==ids_after and study.rng.state==advanced and positioned(study))
    study.control.position.x=.4
    study.control.action()
    check("LOAD changes only request while keeping admitted separation",study.requested==48 and study.half_size.is_equal_approx(Vector3(1.2,.7,.30 if changed else .06)) and is_equal_approx(study.separation,.34) and valid_cloud(study))
    check("crowded account preserves both totals",study.attempts==study.homes.size()+study.refused and study.homes.size()<=48 and study.attempts<=4800)
    study.control.action()
    check("returning LOAD restores initial record",study.requested==12 and study.homes==homes)
    study.control.position.x=-.4
    study.control.action()
    check("NEXT SEED advances integer and can replay",study.seed_value==43)
    var next_homes: Array=study.homes.duplicate()
    study.redraw()
    check("new seed is also reproducible",study.homes==next_homes)
    var other=script.new()
    other.seed_value=731
    root.add_child(other)
    check("instances own separate records and generators",other.rng!=study.rng and study.homes==next_homes)
    other.requested=5;other.tries_per_place=7;other.separation=3
    other.redraw()
    check("oversized spacing admits only the first point",other.homes.size()==1 and other.points.size()==1)
    check("budget is per requested place with exact refused count",other.attempts==29 and other.refused==28 and other.requested-other.homes.size()==4)
    check("readout exposes separate unfilled and refusal figures","4 unfilled" in other.label.text and "28 refused" in other.label.text)
    other.requested=0;other.redraw()
    check("zero requested places spends no attempts",other.points.is_empty() and other.attempts==0 and other.refused==0)
    other.requested=5;other.tries_per_place=0;other.redraw()
    check("zero attempt budget leaves all requests unfilled",other.homes.is_empty() and other.attempts==0 and other.refused==0)
    other.homes.assign([Vector3.ZERO]);other.separation=.34
    check("boundary distance is admitted",other.far_enough(Vector3(.34,0,0)))
    check("closer centre is refused",not other.far_enough(Vector3(.339,0,0)))
    check("depth matters even when projection overlaps",other.far_enough(Vector3(0,0,.35)))
    other.requested=3;other.tries_per_place=1;other.separation=0;other.redraw()
    other.separation=.34
    for p in other.points:p.position=Vector3(0,1.5,0)
    check("three coincident points contain exactly three unordered pairs",other.close_pairs()==3)
    other.points[1].position=Vector3(.34,1.5,0)
    other.points[2].position=Vector3(0,1.5,.34)
    check("observer does not count self or pairs at boundary",other.close_pairs()==0)
    if changed:
        check("transfer changes actual depth without shrinking the inherited body",absf(study.homes[0].z)>.06 or any_deep(study))
        check("transfer independently measured spatial distances still satisfy rule",valid_cloud(study))
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"changed":changed,"engine":Engine.get_version_info(),"scope":"Exact printed files reconstructed in prepared project. Author-informed checks and edited-program transfer; not an independent learner or headset trial."},"  "))
    file.close()
    study.free();other.free()
    quit(0 if failures.is_empty() else 1)

func valid_cloud(s: Node3D) -> bool:
    for i in range(s.homes.size()):
        var p: Vector3=s.homes[i]
        if absf(p.x)>s.half_size.x+.00001 or absf(p.y)>s.half_size.y+.00001 or absf(p.z)>s.half_size.z+.00001:return false
        for j in range(i):
            if p.distance_to(s.homes[j])<s.separation-.00001:return false
    return true
func positioned(s: Node3D) -> bool:
    for i in range(s.points.size()):
        if not s.points[i].position.is_equal_approx(s.CENTRE+s.homes[i]):return false
    return true
func any_deep(s: Node3D) -> bool:
    for p in s.homes:
        if absf(p.z)>.06:return true
    return false
