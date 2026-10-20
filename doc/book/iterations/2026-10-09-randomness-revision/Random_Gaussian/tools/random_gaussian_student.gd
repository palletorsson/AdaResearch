extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[gaussian] ","PASS " if ok else "FAIL ",title)
func total(a: Array) -> int:
    var sum:=0
    for v in a:sum+=v
    return sum
func same(a: Array,b: Array) -> bool:
    if a.size()!=b.size():return false
    for i in range(a.size()):
        if not is_equal_approx(a[i],b[i]):return false
    return true
func bins_for(values: Array,n: int) -> Array[int]:
    var out: Array[int]=[];out.resize(n);out.fill(0)
    for raw in values:
        var v: float=clampf(raw,0,1)
        var j:=n-1 if v==1 else int(floor(v*n))
        out[j]+=1
    return out
func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var script=load(source)
    var study=script.new();study.position=Vector3(4,0,7);study.rotation.y=PI/2;root.add_child(study)
    var reference:=RandomNumberGenerator.new();reference.seed=42
    check("ready initializes labels point empty record and bins",study.point.has_method("pick_up") and not study.status.text.is_empty() and study.values.is_empty() and total(study.counts)==0 and study.bars.get_child_count()==0)
    check("initialization draws nothing",study.rng.state==reference.state)
    var limit: int=study.sample_limit
    study.batch(100);var prefix: Array=study.values.duplicate()
    study.batch(100);study.batch(100)
    check("batch respects authored limit",study.values.size()==limit and prefix.size()==100)
    var expected: Array[float]=[]
    for i in range(limit):
        var u:=maxf(reference.randf(),0.0001);var v:=reference.randf()
        expected.append(study.mean+study.deviation*sqrt(-2*log(u))*cos(TAU*v))
    check("Gaussian record matches two-draw source recipe",same(study.values,expected) and study.rng.state==reference.state)
    check("adding a batch preserves earlier prefix",same(study.values.slice(0,100),prefix))
    check("all raw values finite",study.values.all(func(v):return is_finite(v)))
    check("all samples counted exactly once",study.counts==bins_for(expected,study.bin_count) and total(study.counts)==limit)
    var state: int=study.rng.state
    study.batch(100);study.batch(-10)
    check("full or negative batches consume no draw",study.rng.state==state and study.values.size()==limit)
    var saved: Array=study.values.duplicate();var before: Array=study.counts.duplicate()
    var previous_clipped: int=study.clipped
    study.cycle_bins()
    check("bin toggle increases resolution and preserves raw record",study.bin_count>10 and study.values==saved)
    check("rebin cannot advance generator or change clipped total",study.rng.state==state and study.clipped==previous_clipped)
    check("new partition has correct counts",study.counts==bins_for(saved,study.bin_count))
    study.cycle_bins()
    check("return to10 restores the original counts",study.bin_count==10 and study.counts==before)
    study.replay()
    check("replay restores values amount bins and RNG state",same(study.values,saved) and study.counts==before and study.rng.state==state)
    var nonzero:=0;var geometry_ok:=true;var peak: int=study.counts.max()
    for i in range(study.bin_count):
        if study.counts[i]==0:continue
        var bar: MeshInstance3D=study.bars.get_child(nonzero)
        var height: float=float(study.counts[i])/peak
        geometry_ok=geometry_ok and is_equal_approx(bar.mesh.size.y,height) and is_equal_approx(bar.position.y-height/2,study.BOTTOM) and is_equal_approx(bar.position.x,-study.WIDTH/2+(i+0.5)*study.WIDTH/study.bin_count)
        nonzero+=1
    check("only occupied bins draw correctly sized cubes",geometry_ok and nonzero==study.bars.get_child_count() and study.peak_label.text.contains(str(peak)))
    study.redraw()
    check("redrawing consumes no samples",study.rng.state==state and study.values==saved)
    study.rebin(20);study.clear()
    reference.seed=42
    check("clear resets seed records counts and bars but keeps bins",study.rng.state==reference.state and study.values.is_empty() and total(study.counts)==0 and study.bars.get_child_count()==0 and study.bin_count==20)
    study.values.assign([-0.2,0.0,0.05,0.49,0.5,0.99,1.0,1.3])
    var fixture: Array=study.values.duplicate()
    study.rebin(2)
    check("two-bin fixture counts boundaries and endpoints",study.counts==[4,4] and study.clipped==2)
    study.rebin(10)
    check("ten-bin fixture counts correct intervals",study.counts==[3,0,0,0,1,1,0,0,0,3])
    check("clipping preserves raw values and does not double-count clips",study.values==fixture and study.clipped==2)
    study.rebin(1);var lower: int=study.bin_count
    study.rebin(1000)
    check("bin requests stay within supported bounds",lower==2 and study.bin_count==60 and total(study.counts)==8)
    study.switch_law();study.batch(limit)
    reference.seed=42;expected.clear()
    for i in range(limit):expected.append(reference.randf())
    check("switching law clears and uniform consumes one draw",not study.gaussian and same(study.values,expected) and study.rng.state==reference.state)
    study.switch_law();study.deviation=0.5;study.batch(limit)
    reference.seed=42;expected.clear()
    for i in range(limit):
        var u:=maxf(reference.randf(),0.0001);var v:=reference.randf()
        expected.append(study.mean+0.5*sqrt(-2*log(u))*cos(TAU*v))
    check("wide Gaussian keeps out-of-display raw values",same(study.values,expected) and study.clipped>0 and study.values.any(func(v):return v<0 or v>1))
    study.deviation=0.15;study.clear();study.batch(limit);var narrow: Array=study.values.duplicate()
    study.deviation=0.30;study.clear();study.batch(limit)
    var double_ok:=true
    for i in range(limit):double_ok=double_ok and is_equal_approx(study.values[i]-study.mean,2*(narrow[i]-study.mean))
    check("doubling deviation doubles each raw offset",double_ok)
    study.clear()
    study.point.global_position=study.to_global(Vector3(-0.3,1.1,0.6));study.point.action()
    check("point trigger in batch zone adds100",study.values.size()==100)
    state=study.rng.state;saved=study.values.duplicate();var old_bins: int=study.bin_count
    study.point.global_position=study.to_global(Vector3(0.3,1.1,0.6));study.point.action()
    check("point bin action uses rotated local frame without drawing",study.bin_count!=old_bins and study.values==saved and study.rng.state==state)
    study.point.global_position=study.to_global(Vector3(-0.9,1.1,0.6));study.point.action()
    check("point replay preserves sample",same(study.values,saved))
    study.point.global_position=study.to_global(Vector3(0.9,1.1,0.6));study.point.action()
    check("point law action clears and changes rule",not study.gaussian and study.values.is_empty())
    state=study.rng.state
    study.point.position=Vector3(-0.3,1.1,0.6);study.point.dropped.emit(study.point)
    await physics_frame;await process_frame
    check("moving releasing and waiting do not draw",study.values.is_empty() and study.rng.state==state)
    var other=script.new();root.add_child(other);other.batch(1)
    check("instances own independent samples and generators",study.values.is_empty() and study.rng!=other.rng)
    study.values.assign([0.23]);study.rebin(10)
    check("one observation makes a full-height bar but N remains1",study.bars.get_child_count()==1 and is_equal_approx(study.bars.get_child(0).mesh.size.y,1.0) and study.status.text.contains("N 1 /"))
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"engine":Engine.get_version_info(),"scope":"Printed program and source edits; inherited action method at supplied poses, not a headset or blind student."},"  "))
    file.close();study.free();other.free();quit(0 if failures.is_empty() else 1)
