extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[mushrooms] ","PASS " if ok else "FAIL ",title)
func node_ids(study) -> Array:
    var ids:=[]
    for body in study.bodies:ids.append(body.get_instance_id())
    return ids
func same_except_scale(a: Array,b: Array) -> bool:
    if a.size()!=b.size():return false
    for i in range(a.size()):
        var x: Dictionary=a[i].duplicate();var y: Dictionary=b[i].duplicate()
        x.erase("size");y.erase("size")
        if x!=y:return false
    return true
func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var script=load(source)
    var study=script.new();study.position=Vector3(8,0,6);study.rotation.y=PI/2;root.add_child(study)
    var amount: int=study.count
    check("ready supplies actual bodies labels and inherited point",study.records.size()==amount and study.bodies.size()==amount and not study.status.text.is_empty() and study.point.has_method("pick_up"))
    var expected:=RandomNumberGenerator.new();expected.seed=42
    var draws_ok:=true
    for r in study.records:
        var k:=expected.randi_range(0,study.recipes.size()-1)
        var yaw:=expected.randf()*TAU
        var u:=expected.randf()
        draws_ok=draws_ok and r.kind==k and is_equal_approx(r.yaw,yaw) and is_equal_approx(r.size,study.size_low+(study.size_high-study.size_low)*u)
    check("records preserve named kind turn and sampled scale",draws_ok and study.rng.state==expected.state)
    var positions:=[];var geometry_ok:=true;var roots_ok:=true
    for i in range(amount):
        var body: Node3D=study.bodies[i];var record: Dictionary=study.records[i]
        var recipe: Dictionary=study.recipes[record.kind]
        positions.append(body.position)
        roots_ok=roots_ok and body.position==record.position and is_equal_approx(body.position.y,0.9) and body.scale.is_equal_approx(Vector3.ONE*record.size)
        var stem: MeshInstance3D=body.get_child(0);var cap: MeshInstance3D=body.get_child(1)
        geometry_ok=geometry_ok and is_equal_approx(stem.mesh.height,recipe.stem) and is_equal_approx(stem.position.y,recipe.stem/2.0) and is_equal_approx(cap.mesh.radius,recipe.cap) and is_equal_approx(cap.position.y,recipe.stem) and is_equal_approx(cap.scale.y,0.5)
    check("bodies use the selected recipe dimensions",geometry_ok)
    check("origins stay on table and scales follow records",roots_ok)
    var unique: Dictionary={}
    for at in positions:unique[at]=true
    check("fixed slots are unique",unique.size()==amount)
    check("four-column grid has expected first and last address",positions[0].is_equal_approx(Vector3(-1.05,0.9,-0.65)) and positions[-1].is_equal_approx(Vector3(((amount-1)%4-1.5)*0.7,0.9,(int((amount-1)/4)-1)*0.65)))
    var saved: Array=study.records.duplicate(true);var state: int=study.rng.state
    var ids:=node_ids(study)
    study.toggle_size()
    check("SIZE keeps records and generator",study.records==saved and study.rng.state==state)
    check("SIZE keeps existing body identities",node_ids(study)==ids)
    check("SIZE sets every parent to unit scale",study.bodies.all(func(b):return b.scale.is_equal_approx(Vector3.ONE)))
    check("SIZE labels recipe sizes as retained",study.status.text.contains("recipe sizes kept"))
    study.toggle_size()
    var restored:=true
    for i in range(amount):restored=restored and study.bodies[i].scale.is_equal_approx(Vector3.ONE*saved[i].size)
    check("SIZE restores sampled scale without moving",restored and study.records==saved)
    study.rebuild();study.rebuild()
    check("reconstruction reads record without new draws",study.rng.state==state and study.records==saved and study.bodies.size()==amount)
    study.regrow()
    check("REPLAY restores every field and generator",study.records==saved and study.rng.state==state)
    study.toggle_size();study.regrow()
    check("REPLAY while SIZE off still records same draws",study.records==saved and study.rng.state==state and not study.vary_size and study.bodies.all(func(b):return b.scale.is_equal_approx(Vector3.ONE)))
    study.next_seed()
    check("NEXT SEED advances named seed and retains SIZE setting",study.population_seed==43 and study.records!=saved and not study.vary_size)
    study.population_seed=42;study.regrow()
    check("returning to seed restores population",study.records==saved)
    study.count=6;study.regrow()
    check("short population is same six-record prefix",study.records==saved.slice(0,6))
    study.count=12;study.size_low=0.7;study.size_high=1.3;study.regrow()
    var narrow: Array=study.records.duplicate(true);state=study.rng.state
    study.size_low=0.4;study.size_high=1.6;study.regrow()
    var wider:=same_except_scale(narrow,study.records)
    for i in range(12):wider=wider and is_equal_approx(study.records[i].size-1.0,2.0*(narrow[i].size-1.0))
    check("wider range doubles offsets while other decisions stay",wider and study.rng.state==state)
    study.count=0;study.regrow()
    check("empty population makes no bodies or draws",study.bodies.is_empty() and study.records.is_empty())
    expected.seed=42
    check("empty population resets RNG without consuming",study.rng.state==expected.state)
    study.count=-3;study.regrow()
    check("negative count also empty",study.records.is_empty())
    study.count=99;study.regrow()
    check("large count is bounded to twelve slots",study.records.size()==12 and study.bodies.size()==12)
    study.records.assign([
        {"kind":0,"position":Vector3(-0.4,0.9,0),"yaw":0.0,"size":0.7},
        {"kind":0,"position":Vector3(0.4,0.9,0),"yaw":0.0,"size":1.3}
    ])
    study.vary_size=true;study.rebuild()
    var h0: float=study.bodies[0].get_child(0).mesh.height*study.bodies[0].scale.y
    var h1: float=study.bodies[1].get_child(0).mesh.height*study.bodies[1].scale.y
    check("supplied sizes give known stem heights",is_equal_approx(h0,0.105) and is_equal_approx(h1,0.195))
    study.toggle_size()
    check("same recipe becomes equal while origins stay",study.bodies[0].scale.is_equal_approx(study.bodies[1].scale) and is_equal_approx(study.bodies[0].position.x,-0.4) and is_equal_approx(study.bodies[1].position.x,0.4))
    study.records[1].kind=1;study.rebuild()
    check("different recipes at scale one remain unequal",is_equal_approx(study.bodies[0].get_child(0).mesh.height,0.15) and is_equal_approx(study.bodies[1].get_child(0).mesh.height,0.1))
    study.recipes.append({"cap":0.12,"stem":0.35,"colour":Color(0.9,0.9,0.8)})
    var third: Node3D=study.make_mushroom(study.recipes.size()-1)
    check("new recipe builds tall stem and narrow cap",is_equal_approx(third.get_child(0).mesh.height,0.35) and is_equal_approx(third.get_child(1).mesh.radius,0.12))
    third.free();study.count=12;study.regrow()
    check("all categorical choices remain valid",study.records.all(func(r):return r.kind>=0 and r.kind<study.recipes.size()))
    saved=study.records.duplicate(true);state=study.rng.state
    var setting: bool=study.vary_size
    study.point.global_position=study.to_global(Vector3(0,1.1,1));study.point.action()
    check("trigger SIZE follows rotated local frame",study.vary_size!=setting and study.records==saved and study.rng.state==state)
    study.point.global_position=study.to_global(Vector3(-0.8,1.1,1));study.point.action()
    check("trigger REPLAY uses inherited point",study.records==saved)
    var old_seed: int=study.population_seed
    study.point.global_position=study.to_global(Vector3(0.8,1.1,1));study.point.action()
    check("trigger NEXT SEED uses inherited point",study.population_seed==old_seed+1)
    saved=study.records.duplicate(true);state=study.rng.state
    study.point.position=Vector3(0,1.1,1);study.point.dropped.emit(study.point)
    await physics_frame;await process_frame
    check("moving dropping and waiting do not sample",study.records==saved and study.rng.state==state)
    var other=script.new();root.add_child(other)
    var other_records: Array=other.records.duplicate(true);study.next_seed()
    check("instances own independent records and generators",other.records==other_records and study.rng!=other.rng)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"engine":Engine.get_version_info(),"scope":"Author-informed exact printed code, source edits and supplied inherited actions; not headset or blind student."},"  "))
    file.close();study.free();other.free();quit(0 if failures.is_empty() else 1)
