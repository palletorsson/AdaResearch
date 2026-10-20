extends SceneTree
const Folder:="res://doc/book/iterations/2026-10-11-generative-a-phrase-varied/"
const Generator=preload(Folder+"learner/printed/phrase_generator.gd")
const Movement=preload(Folder+"learner/printed/movement_learner.gd")
const Fixture=preload("res://tools/probes/movement_fixture.gd")
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    if not ok: failures.append(label)
    print("GENERATIVE ","PASS " if ok else "FAIL ",label)

static func takes() -> Array:
    var data:Array=[]
    for v in 3:
        var take:=Fixture.take(0)
        for row:Dictionary in take:
            var d:float=(v-1)*0.12*(0.6+sin(PI*float(row.t)/4.0))
            row.x[1]+=d; row.x[4]+=2*d
        data.append(take)
    return data

func gap(a:Array,b:Array) -> float:
    var largest:=0.0
    for i in a.size():
        for j in 6: largest=maxf(largest,absf(float(a[i][j])-float(b[i][j])))
    return largest

func run() -> void:
    var g:=Generator.new();var data:=takes()
    var original:=data.duplicate(true)
    check("unfitted model cannot generate",g.draw(1,0.5).is_empty())
    check("fewer than three complete takes cannot fit",not g.fit(data.slice(0,2)))
    var bad:=data.duplicate(true);bad[1].remove_at(3);bad[1].remove_at(3);bad[1].remove_at(3)
    check("tracking gap prevents fitting",not g.fit(bad))
    bad=data.duplicate(true);bad[0][2].x[1]=NAN
    check("nonfinite source coordinates rejected",not g.fit(bad))
    bad=data.duplicate(true);bad[0][2].x=[1,2,3]
    check("one hand alone is not a paired performance",not g.fit(bad))
    bad=data.duplicate(true)
    for row:Dictionary in bad[0]:
        for j in range(3,6): row.x[j]=bad[0][0].x[j]
    check("stationary right hand refused as teaching",not g.fit(bad))
    check("three paired takes fit a real distribution",g.fit(data) and g.mean.size()==41 and g.residuals.size()==3)
    var base:=Movement.resample(Fixture.take(0))
    check("symmetric sources have independently known mean",gap(g.mean,base)<1e-10)
    check("fit never changes supplied recordings",data==original)
    var residual_sum_error:=0.0
    for i in 41:
        for j in 6:
            var total:=0.0
            for residual:Array in g.residuals: total+=float(residual[i][j])
            residual_sum_error=maxf(residual_sum_error,absf(total))
    check("whole residuals sum to zero, so at most N minus one are independent",residual_sum_error<1e-10)
    check("equal coefficients on all residuals add no new direction",gap(g.compose([1,1,1],1).rows,g.mean)<1e-10)
    var sample:Dictionary=g.draw(72,1)
    check("same seed data and amount repeat raw sample",sample==g.draw(72,1))
    check("new seed changes this varied fixture",gap(sample.rows,g.draw(73,1).rows)>0.001)
    check("zero amount gives mean for any seed",gap(g.draw(1,0).rows,g.mean)==0 and gap(g.draw(72,0).rows,g.mean)==0)
    check("amount outside policy is not silently clamped",g.draw(1,-1).is_empty() and g.draw(1,1.1).is_empty() and g.draw(1,NAN).is_empty())
    check("bad coefficient count and infinity rejected",g.compose([1,2],1).is_empty() and g.compose([INF,0,0],1).is_empty())
    var explicit:Dictionary=g.compose([1,0,-1],1)
    var expected:=base.duplicate(true)
    for i in 41:
        var d:float=-0.24*(0.6+sin(PI*(i*0.1)/4.0))/sqrt(2.0)
        expected[i][1]+=d;expected[i][4]+=2*d
    check("specified coefficients match independent whole-path calculation",gap(expected,explicit.rows)<1e-9)
    var paired:=true;var temporal:=true;var unchanged:=true
    var first_delta:float=sample.rows[0][1]-base[0][1]
    for i in 41:
        var dl:float=sample.rows[i][1]-base[i][1]
        var dr:float=sample.rows[i][4]-base[i][4]
        paired=paired and absf(dr-2*dl)<1e-9
        temporal=temporal and absf(dl-first_delta*(0.6+sin(PI*i*0.1/4))/0.6)<1e-9
        for j in [0,2,3,5]:unchanged=unchanged and absf(sample.rows[i][j]-base[i][j])<1e-10
    check("both hands preserve the taught two-to-one variation",paired)
    check("one coefficient persists across the complete time path",temporal)
    check("unvaried coordinates do not acquire arbitrary jitter",unchanged)
    var half:Dictionary=g.draw(72,0.5);var linear:=true
    for i in 41:
        for j in 6:linear=linear and absf((half.rows[i][j]-base[i][j])*2-(sample.rows[i][j]-base[i][j]))<1e-9
    check("halving amount halves every deviation from mean",linear)
    var minimum_gap:=INF
    for take:Array in data:minimum_gap=minf(minimum_gap,gap(sample.rows,Movement.resample(take)))
    check("generated fixture is neither a stored take nor just its mean",minimum_gap>0.001 and gap(sample.rows,base)>0.001)
    var mean_frozen:=g.mean.duplicate(true);var residuals_frozen:=g.residuals.duplicate(true)
    var sum:=0.0;var square:=0.0;var product:=0.0
    for s in 2048:
        var result:Dictionary=g.draw(s,1)
        var l:float=result.rows[10][1]-base[10][1]
        var r:float=result.rows[10][4]-base[10][4]
        sum+=l;square+=l*l;product+=l*r
    var variance:float=pow(0.12*(0.6+sin(PI/4)),2)
    evidence={"samples":2048,"empirical_mean_deviation":sum/2048,"observed_variance":square/2048,"expected_variance":variance,"observed_cross_hand_covariance":product/2048,"expected_cross_hand_covariance":2*variance}
    check("seed sweep has expected zero-centred variation within declared tolerance",absf(sum/2048)<0.015)
    check("seed sweep reproduces fitted sample variance within ten percent",absf(square/2048/variance-1)<0.1)
    check("seed sweep reproduces fitted cross-hand covariance",absf(product/2048/(2*variance)-1)<0.1)
    check("generation leaves mean residuals and sources unchanged",g.mean==mean_frozen and g.residuals==residuals_frozen and data==original)
    sample.rows[0][0]=99
    check("returned sample cannot mutate fitted mean",g.mean==mean_frozen)
    var extreme:Dictionary=g.compose([100,0,-100],1)
    check("out-of-range sample retained as raw evidence but not previewable",not extreme.previewable and absf(extreme.rows[10][1])>4)
    var identical:=Generator.new()
    identical.fit([data[0],data[0],data[0]])
    check("identical sources cannot invent unexplained variation",gap(identical.draw(1,1).rows,identical.draw(99,1).rows)<1e-10)
    var shifted:=data.duplicate(true)
    for take:Array in shifted:
        for row:Dictionary in take:row.x[1]+=0.4;row.x[4]+=0.4
    var changed:=Generator.new();changed.fit(shifted)
    var altered:Dictionary=changed.draw(72,1);var before:Dictionary=g.draw(72,1)
    check("changed source changes mean and same-seed sample",absf(changed.mean[10][1]-g.mean[10][1]-0.4)<1e-9 and absf(altered.rows[10][4]-before.rows[10][4]-0.4)<1e-9)
    check("failed refit cannot keep stale generation active",not changed.fit([]) and not changed.trained and changed.draw(72,1).is_empty())
    await scene_checks(data)
    FileAccess.open(Folder+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed exact-print reconstruction; synthetic two-hand examples, not a blind reader or human dance evaluation."},"  "))
    quit(0 if failures.is_empty() else 1)

func press(study:Node3D,index:int) -> void:
    var button=study.panel.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)

func scene_checks(data:Array) -> void:
    var script=load(Folder+"learner/printed/generative_study.gd")
    var study=script.new();root.add_child(study)
    await process_frame;study.set_process(false)
    var point_id:int=study.sphere.get_instance_id()
    var pose:Dictionary=study.model.snapshot()
    check("empty arrival inherits one point and both 3D paths",study.one.examples.is_empty() and study.sphere.has_method("is_picked_up") and study.rods.size()==80 and study.tips.size()==2)
    check("own reachable panel has fourteen real controls",study.panel.find_children("Btn_*","Node",true,false).size()==14)
    press(study,4)
    check("DRAW before fitting produces no preview",study.replay_time<0 and study.generated.is_empty())
    press(study,0)
    check("capture without tracked hands cannot silently start",not study.capturing)
    for take:Array in data:
        study.capturing=true;study.phrase_time=-0.05;study.pending.clear();study.sample_time=0
        for row:Dictionary in take:study.advance_phrase(0.05,row.x,true)
    check("inherited recording loop supplies complete paired takes",study.one.examples.size()==3 and not study.generator.trained)
    press(study,1)
    check("real FIT button estimates joint generator",study.generator.trained and study.mode=="TEACH")
    var kept:Dictionary=study.one.snapshot()
    press(study,2);study.draw_phrase()
    check("SOURCE shows first take without labelling it generated",gap(study.display_phrase.prototype,Movement.resample(study.one.examples[0]))<1e-10 and study.message.begins_with("SOURCE"))
    press(study,3)
    check("MEAN uses fitted mean without altering amount selector",gap(study.display_phrase.prototype,study.generator.mean)==0 and study.amount==0.5)
    press(study,4);study.replay_time=1;study.draw_phrase()
    var first:Dictionary=study.generated.duplicate(true)
    check("DRAW uses same sphere with two airborne timed paths",study.sphere.get_instance_id()==point_id and study.rods[0].visible and study.rods[40].visible)
    check("point follows displayed two-hand midpoint",study.sphere.position.is_equal_approx((study.tips[0].position+study.tips[1].position)*0.5))
    var old_position:Vector3=study.sphere.position
    study.replay_time=3;study.draw_phrase()
    check("generated sphere motion retains a time path",old_position.distance_to(study.sphere.position)>0.01)
    press(study,4)
    check("DRAW repeats current seed without advancing it",study.sample_seed==1 and study.generated==first)
    press(study,5)
    check("NEXT advances seed and changes sample",study.sample_seed==2 and study.generated!=first)
    for i in 6:press(study,6)
    check("LESS stops at mean",study.amount==0 and gap(study.generated.rows,study.generator.mean)==0)
    for i in 6:press(study,7)
    check("MORE stops at declared variation limit",study.amount==1)
    check("all generation controls preserve original teaching and pose model",study.one.snapshot()==kept and study.model.snapshot()==pose)
    study.capturing=true;study.pending=[{"t":0,"x":[0,0,0,0,0,0]}]
    press(study,1)
    check("fitting cannot interrupt a half-recorded take",study.capturing and study.pending.size()==1)
    press(study,13)
    check("STOP discards partial capture and stops replay",not study.capturing and study.pending.is_empty() and study.replay_time<0 and study.one.snapshot()==kept)
    study.capturing=true;study.pending=[{"t":0,"x":[0,0,0,0,0,0]}]
    study.advance_phrase(0.05,[],false)
    check("tracking loss discards a whole take without changing fit",not study.capturing and study.pending.is_empty() and study.generator.trained and study.one.snapshot()==kept)
    press(study,9)
    check("UNDO invalidates generation and removes only last source take",study.one.examples.size()==2 and not study.generator.trained and study.generated.is_empty())
    press(study,4)
    check("stale generated preview cannot return after source edit",study.replay_time<0 and study.generated.is_empty())
    check("point retains identity across every operation",study.sphere.get_instance_id()==point_id and study.sphere.get_child(1).shape is SphereShape3D)
    study.queue_free();await process_frame
