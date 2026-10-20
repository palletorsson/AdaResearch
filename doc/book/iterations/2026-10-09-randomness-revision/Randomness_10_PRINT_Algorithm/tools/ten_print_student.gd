extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok: failures.append(title)
    print("[two-diagonals] ","PASS " if ok else "FAIL ",title)

func geometry_ok(study: Node3D) -> bool:
    for i in range(study.rods.size()):
        var rod: MeshInstance3D=study.rods[i]
        var c: int=i%study.columns
        var r: int=i/study.columns
        var centre:=Vector3((c+0.5-study.columns/2.0)*study.cell_size,1.9+(study.rows/2.0-r-0.5)*study.cell_size,0)
        if not rod.position.is_equal_approx(centre):return false
        var tip: Vector3=rod.basis.y*rod.mesh.height/2
        if not is_equal_approx(absf(tip.x),study.cell_size/2) or not is_equal_approx(absf(tip.y),study.cell_size/2):return false
        if not is_zero_approx(tip.z):return false
        # A backslash seen from +Z has upper end to the left.
        if (tip.x<0)!=study.marks[i] or tip.y<=0:return false
    return true

func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var script=load(source)
    var study=script.new()
    study.position=Vector3(3.5,0,10)
    study.rotation.y=PI/2
    root.add_child(study)
    var n: int=study.columns*study.rows
    var p: float=study.probability
    var first: Array=study.marks.duplicate()
    var samples: Array=study.samples.duplicate()
    check("ready initializes every cell and both records",study.rods.size()==n and samples.size()==n and first.size()==n)
    check("point retains inherited pickup and action",study.point.has_method("pick_up") and study.point.has_method("action") and study.point.freeze)
    check("materials belong to individual rods",study.rods[0].material_override!=study.rods[1].material_override)
    var reference:=RandomNumberGenerator.new()
    reference.seed=42
    var exact:=true
    var interpreted:=true
    var colour:=true
    var count:=0
    for i in range(n):
        var draw:=reference.randf()
        exact=exact and samples[i]==draw
        interpreted=interpreted and first[i]==(p>=1 or draw<p)
        colour=colour and study.rods[i].material_override.albedo_color==(study.PINK if first[i] else study.INK)
        if first[i]:count+=1
    check("one ordered random request per address",exact and study.rng.state==reference.state)
    check("threshold interprets the same raw numbers",interpreted)
    check("rotation joins cell corners with the declared diagonal",geometry_ok(study))
    check("colour agrees with the stored choice",colour)
    check("status reports measured count and expected mean",study.status.text.contains("Actual: %d of %d"%[count,n]) and study.status.text.contains("expected mean: %.2f"%(n*p)))
    var state: int=study.rng.state
    study.draw_pattern()
    await process_frame
    check("redraw and idle do not consume draws or change marks",study.rng.state==state and study.marks==first and study.samples==samples)
    study.point.position.x=-0.75
    study.point.action()
    check("point replay restores the exact field",study.marks==first and study.samples==samples and study.rng.state==state)
    study.point.position.x=0
    study.point.action()
    check("bias action changes threshold but reuses raw draws",is_equal_approx(study.probability,p+0.25) and study.samples==samples)
    var grows:=true
    for i in range(n):grows=grows and (not first[i] or study.marks[i])
    check("raising threshold cannot remove a backslash",grows)
    study.probability=0
    check("zero threshold excludes even sample zero",not study.choose_backslash(0) and not study.choose_backslash(1))
    study.build_pattern()
    check("zero threshold gives no backslashes",study.marks.count(true)==0)
    study.probability=1
    check("unit threshold includes sample one",study.choose_backslash(0) and study.choose_backslash(1))
    study.build_pattern()
    check("unit threshold gives only backslashes",study.marks.count(true)==n)
    study.point.position.x=0
    study.point.action()
    check("bias above one wraps to zero",study.probability==0 and study.marks.count(true)==0)
    study.probability=0.5
    check("threshold boundary belongs to slash",study.choose_backslash(0.499) and not study.choose_backslash(0.5) and not study.choose_backslash(0.501))
    study.probability=p
    study.build_pattern()
    check("returning to original threshold restores field",study.marks==first and study.samples==samples)
    study.point.position.x=0.75
    study.point.action()
    check("right action advances the seed",study.seed_value==43)
    var next: Array=study.marks.duplicate()
    var next_samples: Array=study.samples.duplicate()
    study.point.position.x=-0.75
    study.point.action()
    check("new seed replays without requiring novelty",study.marks==next and study.samples==next_samples)
    var other=script.new()
    other.columns=3
    other.rows=4
    other.cell_size=0.3
    other.probability=p
    root.add_child(other)
    check("rectangular transfer creates twelve cells",other.rods.size()==12 and other.marks.size()==12)
    check("another row width keeps the stream prefix",other.samples==samples.slice(0,12) and other.marks==first.slice(0,12))
    check("larger cells still join exact corners",geometry_ok(other))
    check("instances do not share generator or records",study.rng!=other.rng and study.samples==next_samples and study.marks==next)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"first_count":count,"size":[study.columns,study.rows],"probability":p,"engine":Engine.get_version_info(),"scope":"Exact printed code; authored edits; inherited action at scripted poses. Not a blind learner or headset test."},"  "))
    file.close()
    study.free()
    other.free()
    quit(0 if failures.is_empty() else 1)
