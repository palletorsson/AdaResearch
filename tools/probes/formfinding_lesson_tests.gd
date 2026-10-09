extends SceneTree
const DIR = "res://doc/book/studies/formfinding-lineage/"
var checks: Array = []
var observations: Dictionary = {}
var study: Node3D
func _initialize() -> void: run.call_deferred()
func check(title: String, passed: bool) -> void:
    checks.append({"name":title,"passed":passed})
    print("PASS " if passed else "FAIL ",title)
func instance(file: String) -> Node3D:
    var n=load(DIR+file).new()
    root.add_child(n)
    n.set_process(false)
    n.set_physics_process(false)
    return n
func run() -> void:
    study=instance("01_descent.gd")
    var field=load(DIR+"landscape.gd")
    check("bowl gradient matches analytic x/2,z/2",field.gradient(Vector2(2,-1),false).distance_to(Vector2(1,-0.5))<0.0001)
    study.step_once()
    check("descent first point is predicted (-1.82,-1.3)",study.address.distance_to(Vector2(-1.82,-1.3))<0.0001)
    for i in 40:study.step_once()
    check("bowl stops at small slope",study.status=="SMALL SLOPE" and study.address.length()<0.16)
    study.restart();study.rate=5;study.step_once()
    check("outside proposal not clamped or committed",study.status=="LEFT FRAME" and study.address==Vector2(-2.8,-2))
    study.restart();study.steps=160;study.step_once()
    check("step budget distinct",study.status=="STEP LIMIT")
    study.restart();study.rate=0.2;study.valleys=true
    for i in 160:study.step_once()
    check("left start stays in lower left basin",study.address.x<-1.8 and field.cost(study.address,true)<0)
    study.queue_free()
    study=instance("02_curve.gd")
    check("curve exact first endpoint",study.curve.sample(0,0).distance_to(study.ends[0].position)<0.00001)
    check("curve exact last endpoint",study.curve.sample(0,1).distance_to(study.ends[1].position)<0.00001)
    check("two-metre span midpoint is 1.225 m",absf(study.curve.sample(0,0.5).y-1.225)<0.00001)
    study.sag=0;study.rebuild()
    check("zero sag gives straight line",absf(study.curve.sample(0,0.5).y-1.6)<0.00001)
    study.ends[1].position=Vector3(1,2,0.5);study.rebuild()
    check("moved 3D endpoint retained",study.curve.sample(0,1).distance_to(Vector3(1,2,0.5))<0.00001)
    study.ends[1].position=study.ends[0].position;study.rebuild()
    check("coincident endpoints hide zero rods",study.segments.all(func(s):return not s.visible))
    study.queue_free()
    study=instance("03_relaxation.gd")
    for budget in [1,12]:
        study.passes=budget;study.restart()
        for i in 420:study.step_once()
        observations[str(budget)+"pass"]={"error":study.worst_error(),"middle_y":study.positions[3].y}
        check("pins retained "+str(budget),study.positions[0]==Vector3(-1,1.7,0) and study.positions[6]==Vector3(1,1.7,0))
        check("chain hangs without nonfinite values "+str(budget),study.positions[3].y<1.6 and study.positions.all(func(p):return p.is_finite()))
    check("higher correction budget reduces final length error",observations["12pass"].error<observations["1pass"].error)
    study.positions[2]=study.positions[1];study.correct_pair(1,2)
    check("zero-distance correction remains finite",study.positions[1].is_finite() and study.positions[2].is_finite())
    study.restart();study.points[0].position.x=-0.8;study.step_once()
    check("held endpoint becomes new pin",is_equal_approx(study.positions[0].x,-0.8))
    study.queue_free()
    study=instance("04_balance.gd")
    for pair in [Vector2(1,2),Vector2(4,2),Vector2(3,7)]:
        study.masses=pair;study.rebuild()
        check("arm span retained "+str(pair),is_equal_approx(study.distances.x+study.distances.y,2))
        check("opposed mass moments equal "+str(pair),absf(pair.x*study.distances.x-pair.y*study.distances.y)<0.00001)
        check("heavier mass has shorter arm "+str(pair),(study.distances.x<study.distances.y)==(pair.x>pair.y))
    study.queue_free()
    study=instance("05_annealing.gd")
    study.temperature=0.2
    check("improvement always accepted",study.accepts(-0.05,0.999))
    check("uphill accepted below threshold",study.accepts(0.05,0.7))
    check("uphill rejected above threshold",not study.accepts(0.05,0.9))
    study.temperature=0
    check("zero temperature never accepts worse",not study.accepts(0.05,0))
    study.restart()
    var best_cost: float=field.cost(study.best,true)
    var monotonic=true;var bounded=true;var saw_worse=false
    for i in 240:
        var old_cost: float=field.cost(study.current,true)
        study.step_once()
        var now: float=field.cost(study.best,true)
        monotonic=monotonic and now<=best_cost+0.000001
        bounded=bounded and absf(study.current.x)<=3 and absf(study.current.y)<=3
        saw_worse=saw_worse or field.cost(study.current,true)>old_cost+0.000001
        best_cost=now
    check("best retained monotonically",monotonic)
    check("current can worsen",saw_worse)
    check("bounded proposal and finite stopping",bounded and study.attempts<=240 and study.status=="STOPPED")
    var endpoint: Vector2=study.current
    study.restart()
    for i in 240:study.step_once()
    check("seeded reset repeats experiment",study.current==endpoint)
    observations.annealing_best=xyz2(study.best)
    study.queue_free()
    study=instance("06_criterion.gd")
    for i in 180:study.observe(0.2,true,1.0/60)
    check("quiet low heap rejected",not study.accepted and study.credit==0)
    for i in 30:study.observe(0.6,true,1.0/60)
    check("tall short observation insufficient",not study.accepted and study.credit>0.49)
    study.observe(0.6,false,0.1)
    check("movement drains twice as fast",absf(study.credit-0.3)<0.00001)
    study.observe(0.2,true,0.1)
    check("lost height clears credit",study.credit==0)
    for i in 91:study.observe(0.6,true,1.0/60)
    check("tall quiet interval accepted",study.accepted)
    study.restart()
    check("reset clears acceptance",not study.accepted and study.credit==0)
    # Actual Jolt bodies on a native floor, not only supplied predicate values.
    var floor_body=StaticBody3D.new()
    var collision=CollisionShape3D.new();var box=BoxShape3D.new()
    box.size=Vector3(8,0.2,8);collision.shape=box;floor_body.position.y=-0.1
    floor_body.add_child(collision);root.add_child(floor_body)
    study.set_physics_process(true)
    for i in 3:study.cubes[i].position=Vector3(0,0.11+i*0.205,0)
    await create_timer(3.5).timeout
    check("real three-cube Jolt stack reaches criterion",study.accepted)
    study.restart()
    await create_timer(2.5).timeout
    check("real separate floor cubes remain rejected",not study.accepted)
    study.queue_free();floor_body.queue_free()
    await process_frame
    var failures=checks.filter(func(c):return not c.passed)
    var report={"checks":checks,"observations":observations,"passed":failures.is_empty(),"count":checks.size(),"failures":failures}
    FileAccess.open("res://doc/book/iterations/2026-10-08-formfinding-build-and-investigate/native-checks.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("FORMFINDING ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
func xyz2(p: Vector2) -> Array:return [p.x,p.y]
