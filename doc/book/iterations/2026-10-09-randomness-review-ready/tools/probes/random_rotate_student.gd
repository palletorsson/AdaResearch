extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[turns] ", "PASS " if ok else "FAIL ", title)
func same(a: Array, b: Array) -> bool:
    if a.size() != b.size(): return false
    for i in range(a.size()):
        if not is_equal_approx(a[i],b[i]): return false
    return true
func run() -> void:
    await process_frame
    var source: String
    var report: String
    var fixed := false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source = arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
        if arg == "--fixed": fixed = true
    var script = load(source)
    var study = script.new()
    study.position = Vector3(9.5,0,7.5); study.rotation.y = -PI/2
    root.add_child(study);study.set_process(false)
    var reference := RandomNumberGenerator.new()
    reference.seed = 42
    var expected: Array[float] = []
    for i in range(study.step_count): expected.append(deg_to_rad(reference.randf_range(-study.limit_degrees,study.limit_degrees)))
    if fixed: expected.assign([deg_to_rad(10),deg_to_rad(10),deg_to_rad(-5)])
    var original: Array = study.turns.duplicate()
    check("ready creates both marked cubes and the status", study.assigned != null and study.accumulated != null and study.assigned.get_child_count() == 1 and study.accumulated.get_child_count() == 1 and not study.status.text.is_empty())
    check("point retains pickup and action", study.point.has_method("pick_up") and study.point.has_method("action") and study.point.freeze)
    check("record matches declared generator or supplied values", same(study.turns,expected))
    var state: int = study.rng.state
    check("initial poses and cursor are zero", study.cursor == 0 and study.latest == 0 and study.total == 0 and study.assigned.basis == Basis.IDENTITY and study.accumulated.basis == Basis.IDENTITY)
    study.point.position.x = 0; study.point.action()
    check("first event uses one shared entry", study.cursor == 1 and is_equal_approx(study.latest,expected[0]) and is_equal_approx(study.total,expected[0]))
    study.point.action()
    check("second event assigns latest but retains sum", study.cursor == 2 and is_equal_approx(study.latest,expected[1]) and is_equal_approx(study.total,expected[0]+expected[1]))
    check("playback consumes no new draws", study.rng.state == state)
    var left_before: Vector3 = study.assigned.position
    var right_before: Vector3 = study.accumulated.position
    # A known cancellation example is independent of any generator implementation.
    study.turns.assign([deg_to_rad(10),deg_to_rad(10),deg_to_rad(-5)])
    study.replay()
    for i in range(3): study.step()
    check("ten ten minus five leaves latest minus five and sum fifteen", is_equal_approx(rad_to_deg(study.latest),-5) and is_equal_approx(rad_to_deg(study.total),15))
    check("both poses use the chosen unit axis", study.assigned.basis.is_equal_approx(Basis(study.TURN_AXIS,deg_to_rad(-5))) and study.accumulated.basis.is_equal_approx(Basis(study.TURN_AXIS,deg_to_rad(15))))
    check("rotation keeps centre mesh size and scale", study.assigned.position == left_before and study.accumulated.position == right_before and study.assigned.mesh.size == Vector3.ONE*0.6 and study.accumulated.basis.get_scale().is_equal_approx(Vector3.ONE))
    check("record completion is explicit", study.cursor == 3 and not study.playing and study.status.text.contains("RECORD COMPLETE"))
    study.step()
    check("completed record cannot advance or draw", study.cursor == 3 and is_equal_approx(rad_to_deg(study.total),15) and study.rng.state == state)
    var kept: Array = study.turns.duplicate()
    study.point.position.x = -0.8;study.point.action()
    check("replay retains record and generator", same(study.turns,kept) and study.rng.state == state)
    check("replay clears both values cursor clock and playback", study.cursor == 0 and study.latest == 0 and study.total == 0 and study.elapsed == 0 and not study.playing)
    # Frame partitions: same elapsed time, same record, including a slow frame.
    study.turns.assign(original);study.replay();study.playing = true
    for i in range(243): study._process(1.0/60.0)
    var count60: int = study.cursor
    var total60: float = study.total
    study.replay();study.playing = true
    for i in range(122): study._process(4.05/122.0)
    check("equal elapsed time at different frame rates reads same prefix", study.cursor == count60 and is_equal_approx(study.total,total60) and count60 == mini(5,original.size()))
    study.replay();study.playing = true;study._process(4.05)
    check("one slow frame consumes every complete interval", study.cursor == count60 and is_equal_approx(study.total,total60))
    study.replay();study.point.position.x = 0.8;study.point.action()
    study._process(study.seconds_per_step*0.6)
    study.point.action();study._process(9.0)
    check("pause retains fractional interval and no events", study.cursor == 0 and is_equal_approx(study.elapsed,study.seconds_per_step*0.6) and not study.playing)
    study.point.action();study._process(study.seconds_per_step*0.41)
    check("resume continues the retained interval", study.cursor == 1 and study.playing)
    study.point.position.x = 0;study.point.action()
    check("manual step pauses and clears partial interval", study.cursor == 2 and study.elapsed == 0 and not study.playing)
    study.replay();study.playing = true;study._process(100.0)
    check("long frame stops at end of finite record", study.cursor == original.size() and not study.playing and study.rng.state == state)
    study.point.position.x = 0.8;study.point.action()
    check("play after completion starts same record from zero", study.cursor == 0 and study.playing and same(study.turns,original))
    study.playing = false;study.show_angles()
    check("display redraw does not change record or RNG", same(study.turns,original) and study.rng.state == state)
    study.turns.assign([PI,PI]);study.replay();study.step();study.step()
    check("full turn retains total even when orientation returns", is_equal_approx(study.total,TAU) and study.accumulated.basis.is_equal_approx(Basis.IDENTITY))
    study.turns.assign([0.4,-0.4]);study.replay();study.step();study.step()
    check("opposite increments cancel", is_zero_approx(study.total) and is_equal_approx(study.latest,-0.4))
    study.turns.clear();study.replay();study.step()
    check("empty record is a valid completed display", study.cursor == 0 and study.total == 0 and study.status.text.contains("RECORD COMPLETE"))
    study.make_record()
    check("rebuilding seed restores original record", same(study.turns,original))
    var other = script.new();root.add_child(other);other.set_process(false)
    check("separate instances own separate generators", study.rng != other.rng)
    other.turns[0] = 3.0
    check("separate instances own separate lists", is_equal_approx(study.turns[0],original[0]))
    if not fixed:
        study.limit_degrees *= 2.0;study.make_record()
        var doubled := true
        for i in range(original.size()): doubled = doubled and is_equal_approx(study.turns[i],original[i]*2)
        check("amplitude edit doubles same seeded samples", doubled)
    else: check("supplied record retains its three named contributions", same(study.turns,expected))
    var file := FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"initial_turns":original,"engine":Engine.get_version_info(),"scope":"Exact printed code and explicit source edits. Authored checks; no blind reader or headset."},"  "))
    file.close();study.free();other.free()
    quit(0 if failures.is_empty() else 1)
