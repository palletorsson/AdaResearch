extends SceneTree

var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}

func _initialize() -> void: run.call_deferred()

func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[estimate] ", "PASS " if ok else "FAIL ", title)

func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="): source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="): report=arg.trim_prefix("--report=")
    var script=load(source)
    var study=script.new();study.position=Vector3(8,0,6);study.rotation.y=PI/2;root.add_child(study)
    var original_seed: int=study.sample_seed
    check("empty ready has initialized label and inherited point",study.samples.is_empty() and study.estimates.is_empty() and study.status.text.contains("--") and study.point.has_method("pick_up"))
    study.add_samples(0)
    var expected:=RandomNumberGenerator.new();expected.seed=original_seed
    check("empty request does not draw or divide",study.samples.is_empty() and study.rng.state==expected.state)
    study.add_samples(256)
    var expected_hits:=0;var positions_ok:=true;var counts_ok:=true;var pictures_ok:=true
    var latest:=0.0
    var worsening:=0
    for i in range(256):
        var x:=expected.randf_range(-study.x_span,study.x_span)
        var y:=expected.randf_range(-1.0,1.0)
        positions_ok=positions_ok and study.samples[i].is_equal_approx(Vector2(x,y))
        var hit:=x*x+y*y<=1.0
        if hit:expected_hits+=1
        var value:=float(expected_hits)/float(i+1)*4
        counts_ok=counts_ok and is_equal_approx(study.estimates[i],value)
        if i>0 and absf(value-PI)>absf(latest-PI):worsening+=1
        latest=value
        var mark: MeshInstance3D=study.marks[i*2]
        var history: MeshInstance3D=study.marks[i*2+1]
        var colour:=Color(0.04,0.42,0.37) if hit else Color(0.8,0.12,0.23)
        pictures_ok=pictures_ok and mark.position.is_equal_approx(Vector3(-0.65+x*0.6,1.7+y*0.6,0.06)) and mark.material_override.albedo_color.is_equal_approx(colour)
        pictures_ok=pictures_ok and history.position.is_equal_approx(Vector3(0.15+i*1.1/255,1.1+value*0.25,0.06))
    check("two ordered uniform draws per retained position",positions_ok and study.rng.state==expected.state)
    check("circle verdict and every floating ratio agree with independent tally",counts_ok and study.inside==expected_hits)
    check("every sample mark and history dot matches retained data",pictures_ok and study.marks.size()==512)
    check("label shows final count and ratio",study.status.text.contains("%d / 256" % expected_hits) and study.status.text.contains("%.4f" % latest))
    observations.first_run={"seed":original_seed,"x_span":study.x_span,"inside":expected_hits,"estimate":latest,"steps_farther_from_pi":worsening}
    var saved: Array=study.samples.duplicate();var history: Array=study.estimates.duplicate();var state: int=study.rng.state
    study.add_samples(100)
    check("full board spends no further draws",study.samples==saved and study.estimates==history and study.rng.state==state and study.marks.size()==512)
    var children: int=study.get_child_count()
    study.replay()
    check("replay clears all three records and frees all dynamic marks",study.samples.is_empty() and study.estimates.is_empty() and study.inside==0 and study.marks.is_empty() and study.get_child_count()==children-512)
    expected.seed=original_seed
    check("replay rewinds its private generator",study.rng.state==expected.state)
    for i in range(16):study.add_samples(1)
    var prefix: Array=study.samples.duplicate();var prefix_history: Array=study.estimates.duplicate()
    study.replay();study.add_samples(16)
    check("one batch equals sixteen individual draws",study.samples==prefix and study.estimates==prefix_history)
    check("prefix survives adding more samples",prefix==saved.slice(0,16) and prefix_history==history.slice(0,16))
    study.add_samples(238);study.add_samples(16)
    check("partial final batch stops exactly at limit",study.samples==saved and study.estimates==history and study.rng.state==state)
    study.sample_seed=original_seed+1;study.replay();study.add_samples(256)
    check("changed seed changes retained positions",study.samples!=saved)
    study.sample_seed=original_seed;study.replay();study.add_samples(256)
    check("returning seed recovers complete record",study.samples==saved and study.estimates==history)
    var original_span: float=study.x_span
    study.x_span=0.2;study.replay();study.add_samples(256)
    var in_strip:=true
    for p in study.samples:in_strip=in_strip and absf(p.x)<=0.2 and absf(p.y)<=1
    check("strip edit changes sampling support",in_strip)
    observations.strip={"inside":study.inside,"estimate":study.estimates[-1],"positions":study.samples.size()}
    study.x_span=original_span;study.replay()
    var no_draw: int=study.rng.state
    study.point.position=Vector3(0.8,1.04,0.55);study.point.dropped.emit(study.point)
    await physics_frame;await process_frame
    check("movement release and waiting do not sample",study.samples.is_empty() and study.rng.state==no_draw)
    study.point.global_position=study.to_global(Vector3(0,1.04,0.55));study.point.action()
    check("one action follows transformed local frame",study.samples.size()==1 and study.samples[0]==saved[0])
    study.point.global_position=study.to_global(Vector3(0.8,1.04,0.55));study.point.action()
    check("batch action adds the declared count",study.samples.size()==1+study.BATCH and study.samples==saved.slice(0,1+study.BATCH))
    study.point.global_position=study.to_global(Vector3(-0.8,1.04,0.55));study.point.action()
    check("replay action empties record without replacing point",study.samples.is_empty() and study.point.get_parent()==study)
    var other=script.new();root.add_child(other)
    var other_state: int=other.rng.state
    study.add_samples(5)
    check("instances own independent records and generators",other.samples.is_empty() and other.rng.state==other_state and other.rng!=study.rng)
    study.replay()
    for i in range(ceili(256.0/study.BATCH)):study.add_samples(study.BATCH)
    check("declared batches reconstruct identical full record",study.samples==saved and study.estimates==history and study.get_child_count()==children)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"source":source,"engine":Engine.get_version_info(),"scope":"Exact printed code, whole edited programs, supplied PointBody actions; author-informed, no headset."},"  "))
    file.close();study.free();other.free();quit(0 if failures.is_empty() else 1)
