extends SceneTree
var checks: Array=[]
var failures: Array=[]
var clamp_mode:=false
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[walk] ","PASS " if ok else "FAIL ",title)
func folded(p: Vector3, half: float, y: float) -> Vector3:
    var q:=p
    for axis in [0,2]:
        if clamp_mode: q[axis]=clampf(q[axis],-half,half)
        elif absf(q[axis])>half: q[axis]=signf(q[axis])*(2*half-absf(q[axis]))
    q.y=y
    return q
func same(a: Array, b: Array) -> bool:
    if a.size()!=b.size():return false
    for i in range(a.size()):
        if not a[i].is_equal_approx(b[i]):return false
    return true
func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--clamp":clamp_mode=true
    var script=load(source)
    var study=script.new();study.position=Vector3(3,0,7.5);study.rotation.y=PI/2
    root.add_child(study);study.set_process(false)
    var start:=Vector3(0,study.HEIGHT,0)
    check("ready creates point status and origin record",study.point!=null and not study.status.text.is_empty() and study.positions==[start] and study.steps==0 and study.trail.get_child_count()==0)
    check("point inherits pickup and frozen release",study.point.has_method("pick_up") and study.point.freeze and study.point.release_mode==XRToolsPickable.ReleaseMode.FROZEN)
    var reference:=RandomNumberGenerator.new();reference.seed=42
    check("restart leaves generator before first draw",reference.state==study.rng.state)
    var expected:=start
    var path: Array[Vector3]=[start]
    var match_all:=true
    var lengths_ok:=true
    for i in range(128):
        var angle:=reference.randf()*TAU
        var proposal: Vector3=expected+Vector3(cos(angle),0,sin(angle))*study.step_size
        var old:=expected
        expected=folded(proposal,study.HALF,study.HEIGHT)
        study.step();path.append(expected)
        match_all=match_all and study.current.is_equal_approx(expected) and study.proposed.is_equal_approx(proposal) and study.rng.state==reference.state
        lengths_ok=lengths_ok and is_equal_approx(proposal.distance_to(old),study.step_size)
    check("all128 steps accumulate then apply the declared boundary",match_all)
    check("each proposed step has the configured planar length",lengths_ok)
    check("record includes start and every accepted endpoint",same(study.positions,path) and study.positions.size()==129)
    check("one segment per accepted transition",study.trail.get_child_count()==128)
    var visuals_ok:=true
    for i in range(128):
        var line: MeshInstance3D=study.trail.get_child(i)
        var displacement:=path[i+1]-path[i]
        if displacement.length()>0.0001:
            visuals_ok=visuals_ok and line.position.is_equal_approx((path[i]+path[i+1])/2) and is_equal_approx(line.mesh.height,displacement.length()) and line.basis.y.is_equal_approx(displacement.normalized())
    check("cylinders join consecutive accepted positions",visuals_ok)
    check("point shows the last position in root local frame",study.point.global_position.is_equal_approx(study.to_global(path[-1])))
    var state: int=study.rng.state
    study.step();study._process(5)
    check("finished walk consumes no further draw or position",study.steps==128 and study.positions.size()==129 and study.rng.state==state and study.status.text.contains("COMPLETE"))
    study.restart(start)
    for i in range(128):study.step()
    check("same seed start and rule reproduce whole path",same(study.positions,path))
    var folded_corner: Vector3=study.reflect_endpoint(Vector3(0.9,8,-0.93))
    check("reflection folds two corner overshoots",folded_corner.is_equal_approx(Vector3(0.8,study.HEIGHT,-0.77)))
    study.restart(Vector3(study.HALF-0.005,study.HEIGHT,study.HALF-0.005))
    var at: Vector3=study.current
    reference.seed=42
    var angle:=reference.randf()*TAU
    var corner_proposal: Vector3=at+Vector3(cos(angle),0,sin(angle))*study.step_size
    study.step()
    check("actual edge step uses reflection or the authored clamp edit",study.current.is_equal_approx(folded(corner_proposal,study.HALF,study.HEIGHT)))
    check("endpoint chord can be shorter than proposed movement",study.current.distance_to(at)<study.step_size)
    study.restart(start)
    for i in range(20):study.step()
    var prefix: Array=study.positions.duplicate()
    study.step();var wanted: Vector3=study.current
    study.restart(start)
    for i in range(20):study.step()
    study.positions.clear()
    for line in study.trail.get_children():study.trail.remove_child(line);line.queue_free()
    check("controlled erasure really clears both records",study.positions.is_empty() and study.trail.get_child_count()==0)
    study.step()
    check("erasing history leaves next position unchanged",study.current.is_equal_approx(wanted))
    study.restart(start)
    study.point.picked_up.emit(study.point)
    state=study.rng.state
    study._process(5)
    check("held time consumes no steps or generator values",study.held and study.steps==0 and study.elapsed==0 and study.rng.state==state)
    study.point.global_position=study.to_global(Vector3(0.4,2,-0.3))
    study.point.dropped.emit(study.point)
    check("release projects global hand into local start",study.origin.is_equal_approx(Vector3(0.4,study.HEIGHT,-0.3)) and not study.held and study.steps==0 and study.positions.size()==1)
    for i in range(20):study.step()
    var offset_path: Array=study.positions.duplicate()
    check("a changed start changes the resulting path",not same(offset_path,prefix))
    study.point.picked_up.emit(study.point)
    study.point.position=Vector3(-0.6,4,0.7)
    study.point.action();study.point.dropped.emit(study.point)
    for i in range(20):study.step()
    check("trigger release replays old start instead of new hand pose",same(study.positions,offset_path) and not study.replay_requested)
    study.point.picked_up.emit(study.point)
    study.point.position=Vector3(2,4,-3)
    study.point.dropped.emit(study.point)
    check("release beyond boundary clamps start onto square",study.origin.is_equal_approx(Vector3(study.HALF,study.HEIGHT,-study.HALF)))
    study.restart(start)
    var duration: float=study.seconds_per_step*8.1
    for i in range(60):study._process(duration/60)
    var timed: Array=study.positions.duplicate()
    study.restart(start);study._process(duration)
    check("different frame partitions consume same eight steps",study.steps==8 and same(study.positions,timed))
    study.restart(start);study._process(study.seconds_per_step*0.4)
    study.point.picked_up.emit(study.point);study.point.action();study.point.dropped.emit(study.point)
    check("replay clears partial interval and geometry",study.elapsed==0 and study.trail.get_child_count()==0 and study.positions==[start])
    var other=script.new();root.add_child(other);other.set_process(false)
    check("instances own separate generators and position lists",study.rng!=other.rng)
    other.positions.append(Vector3(10,0,0))
    check("editing another record cannot alter this one",study.positions.size()==1)
    other.restart(start);other.max_steps=1;other.step();state=other.rng.state;other.step()
    check("one-step budget retains exactly two points",other.steps==1 and other.positions.size()==2 and other.rng.state==state)
    var initial_step: float=study.step_size
    study.restart(start);study.step();var first: Vector3=study.current-start
    study.step_size=initial_step*2;study.restart(start);study.step()
    check("double length doubles first displacement before boundaries",(study.current-start).is_equal_approx(first*2))
    study.step_size=initial_step;study.restart(start)
    var previous: int=study.rng.state
    study.show_status()
    check("status redraw cannot consume randomness",study.rng.state==previous and study.positions==[start])
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"path":path,"engine":Engine.get_version_info(),"scope":"Printed files, real seeded steps and source edits; explicit pickup/drop signals, not a headset driver or blind student."},"  "))
    file.close();study.free();other.free()
    quit(0 if failures.is_empty() else 1)
