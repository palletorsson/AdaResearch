extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[continuing-die] ","PASS " if ok else "FAIL ",title)

func visible_units(study: Node3D) -> int:
    var result:=0
    for unit in study.units:
        if unit.visible:result+=1
    return result

func run() -> void:
    await process_frame
    var source: String
    var report: String
    var mode: String="six"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg.begins_with("--mode="):mode=arg.trim_prefix("--mode=")
    var script=load(source)
    var study=script.new()
    study.position=Vector3(1.3,0,11.8)
    study.rotation.y=PI/2
    root.add_child(study)
    var cap: int=study.max_draws
    check("ready initializes bounded display and status",study.units.size()==cap*6 and study.joins.size()==cap and not study.status.text.is_empty())
    check("initial record empty with no units shown",study.history.is_empty() and study.total==0 and not study.closed and not study.limited and visible_units(study)==0)
    check("point inherits pickup and action",study.point.has_method("pick_up") and study.point.has_method("action") and study.point.freeze)
    var reference:=RandomNumberGenerator.new()
    reference.seed=42
    check("reset starts before any draw",study.rng.state==reference.state)
    var expected: Array[int]=[]
    var expected_total:=0
    var draw_matches:=true
    for i in range(cap):
        var face:=reference.randi_range(1,6)
        expected.append(face);expected_total+=face
        study.point.position.x=0
        study.point.action()
        draw_matches=draw_matches and study.history==expected and study.total==expected_total and study.rng.state==reference.state
        if face<5 or (mode=="six" and face!=6):break
    check("each accepted point action makes one correctly bounded draw",draw_matches)
    check("seeded run ends with the specified history and sum",study.history==expected and study.total==expected_total and (study.closed or study.limited))
    var state: int=study.rng.state
    var history: Array=study.history.duplicate()
    var total: int=study.total
    var stopped: int=study.draw_face()
    check("terminal press makes no draw and changes no record",stopped==0 and study.rng.state==state and study.history==history and study.total==total)
    study.draw_record();await process_frame
    check("redraw and idle do not add outcomes",study.history==history and study.total==total and study.rng.state==state)
    study.point.position.x=-0.85;study.point.action()
    var replay: Array[int]=[]
    for i in range(expected.size()):replay.append(study.draw_face())
    check("point replay repeats the stopped sequence",replay==expected)
    study.point.position.x=0.85;study.point.action()
    reference.seed=43
    check("next seed resets record before its first draw",study.seed_value==43 and study.history.is_empty() and study.rng.state==reference.state)
    study.reset_run()
    state=study.rng.state
    var invalid: bool=not study.accept_face(0) and not study.accept_face(7) and not study.accept_face(-1)
    check("invalid faces leave record and RNG untouched",invalid and study.history.is_empty() and study.total==0 and study.rng.state==state)
    study.accept_face(6);study.accept_face(6);study.accept_face(3)
    check("supplied six six three accumulates fifteen",study.history==[6,6,3] and study.total==15)
    check("noncontinuing face closes even in final place",study.closed and not study.limited and study.status.text.contains("CLOSED"))
    check("column units and equation preserve all contributions",visible_units(study)==15 and study.status.text.contains("6 + 6 + 3 = 15"))
    var joins_ok:=is_equal_approx(study.joins[0].position.y,0.3) and is_equal_approx(study.joins[1].position.y,0.3+6*study.UNIT) and is_equal_approx(study.joins[2].position.y,0.3+12*study.UNIT)
    check("joins retain the boundaries between events",joins_ok and study.joins[2].visible)
    check("successive sections remain distinguishable",study.units[0].material_override.albedo_color!=study.units[6].material_override.albedo_color and study.units[0].material_override!=study.units[1].material_override)
    check("last unit centre and size give the accumulated height",is_equal_approx(study.units[14].position.y+study.units[14].mesh.size.y/2,0.3+15*study.UNIT-0.002))
    check("supplied events do not consume generator draws",study.rng.state==state)
    check("closed record rejects a later supplied result",not study.accept_face(4) and study.history==[6,6,3])
    study.reset_run()
    for i in range(cap):study.accept_face(6)
    check("all sixes reach an unfinished limit not closure",study.history.size()==cap and study.total==cap*6 and study.limited and not study.closed and study.status.text.contains("UNFINISHED"))
    state=study.rng.state
    check("limited record rejects both input routes",study.draw_face()==0 and not study.accept_face(3) and study.rng.state==state and study.total==cap*6)
    study.reset_run()
    for i in range(cap-1):study.accept_face(6)
    study.accept_face(3)
    check("a closing result at the cap takes precedence",study.closed and not study.limited and study.total==(cap-1)*6+3)
    study.reset_run()
    study.accept_face(6);study.accept_face(5);study.accept_face(2)
    check("changed continuation rule has the predicted effect",(study.history==[6,5] and study.total==11) if mode=="six" else (study.history==[6,5,2] and study.total==13))
    var cases_ok:=true
    for face in range(1,7):
        study.reset_run();study.accept_face(face)
        var keep:=face==6 if mode=="six" else face>=5
        cases_ok=cases_ok and study.closed==not keep and study.total==face and study.history==[face]
    check("all six faces apply the declared continuation predicate",cases_ok)
    var streams_ok:=true
    for seed_id in range(64):
        study.seed_value=seed_id;study.reset_run();reference.seed=seed_id
        var want:=reference.randi_range(1,6)
        streams_ok=streams_ok and study.draw_face()==want and study.rng.state==reference.state
    check("first draws across64 seeds match six-valued reference",streams_ok)
    # Locate a reproducible demonstration, explicitly selected rather than typical.
    var example_seed: int=-1
    for seed_id in range(10000):
        reference.seed=seed_id
        var triple: Array=[reference.randi_range(1,6),reference.randi_range(1,6),reference.randi_range(1,6)]
        if triple==[6,6,3]:example_seed=seed_id;break
    check("a recorded demonstration seed produces six six three",example_seed>=0)
    var limit_seed: int=-1
    for seed_id in range(10000):
        reference.seed=seed_id
        var triple: Array=[reference.randi_range(1,6),reference.randi_range(1,6),reference.randi_range(1,6)]
        if triple==[6,6,6]:limit_seed=seed_id;break
    check("a recorded demonstration seed produces three sixes",limit_seed>=0)
    study.seed_value=example_seed;study.reset_run()
    for i in range(3):study.draw_face()
    check("chosen seed produces worked example through real draws",study.history==[6,6,3] and study.total==15 and study.closed)
    var other=script.new();other.max_draws=1;root.add_child(other)
    other.accept_face(6)
    check("one-place transfer reaches unfinished limit after six",other.history==[6] and other.total==6 and other.limited and not other.closed and visible_units(other)==6)
    other.reset_run();other.accept_face(2)
    check("one-place transfer can close normally",other.closed and not other.limited and other.total==2)
    check("separate instances retain separate records and generators",study.history==[6,6,3] and study.rng!=other.rng)
    study.reset_run()
    check("reset clears visibility and both terminal states",visible_units(study)==0 and study.history.is_empty() and study.total==0 and not study.closed and not study.limited)
    var file:=FileAccess.open(report,FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"first_history":expected,"example_seed":example_seed,"limit_seed":limit_seed,"engine":Engine.get_version_info(),"scope":"Exact printed code, supplied branch inputs, real seeded draws, authored edits. No physical headset or blind learner."},"  "))
    file.close();study.free();other.free()
    quit(0 if failures.is_empty() else 1)
