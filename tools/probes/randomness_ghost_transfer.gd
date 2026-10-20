extends SceneTree
## Predictions from the printed lesson; no production-artifact oracle.
var checks: Array=[]
var failures: Array=[]
var observations: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(title: String, passed: bool) -> void:
    checks.append({"name":title,"passed":passed})
    if not passed: failures.append(title)
    print("[ghost] ","PASS " if passed else "FAIL ",title)
func near(a: float,b: float) -> bool: return absf(a-b)<0.00001
func sum_values(values) -> float:
    var total:=0.0
    for value in values: total+=value
    return total
func run() -> void:
    var source: String;var changed: String;var report: String;var hall:=0
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--changed="):changed=arg.trim_prefix("--changed=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg.begins_with("--hall="):hall=int(arg.trim_prefix("--hall="))
    var a=load(source).new();var b=load(changed).new()
    a.position=Vector3(8,0,6);a.rotation.y=PI/2;root.add_child(a)
    b.position=Vector3(-8,0,6);b.rotation.y=-PI/2;root.add_child(b)
    a.set_process(false);a.set_physics_process(false)
    b.set_process(false);b.set_physics_process(false)
    check("both printed and changed programs initialize their own lesson objects",a.get_child_count()>0 and b.get_child_count()>0 and a.point!=null and b.point!=null)
    match hall:
        0:
            var channels:=true
            for i in range(64):
                var x: Color=a.samples[0][i];var y: Color=b.samples[0][i]
                channels=channels and near(y.r,x.b) and near(y.g,x.g) and near(y.b,x.r)
            check("channel permutation preserves values and draw state",channels and a.rng.state==b.rng.state)
            b.set_side(5);var saved=b.samples.duplicate(true);b.set_side(8);b.set_side(5)
            check("a new five by five size can be reconstructed",b.samples==saved and b.samples[0].size()==25)
            b.discard_first=true;b.replay()
            check("discard still shifts the underlying stream after reinterpretation",near(b.samples[1][0].b,b.samples[0][0].g) and near(b.samples[1][0].g,b.samples[0][0].r))
        1:
            check("authored blocks retain equal shares and two bits",b.counts_of(b.record)==[4,4,4,4] and near(b.entropy_of(b.counts_of(b.record)),2))
            check("block arrangement has only three unlike neighbours",b.neighbour_changes(b.record)==3)
            var cyclic: Array[int]=[]
            for i in range(16):cyclic.append(i%4)
            check("different arrangement has same entropy but fifteen changes",near(b.entropy_of(b.counts_of(cyclic)),2) and b.neighbour_changes(cyclic)==15)
            var original=b.record.duplicate();b.sorted_view=true;b.draw_state()
            check("sorting cannot change the original",b.record==original)
        2:
            var expected: Array[int]=[0,9,18,27,36,45,54,63]
            var removed: Array[int]=[]
            for i in range(8):removed.append(b.remove_one())
            removed.sort();check("diagonal eligibility supplies exactly eight distinct addresses",removed==expected)
            var state: int=b.rng.state
            check("exhaustion consumes no extra random request",b.remove_one()==-1 and b.rng.state==state)
            var order=b.history.duplicate();b.reset_run()
            for i in range(8):b.remove_one()
            check("replay restores both candidate set and order",b.history==order)
        3:
            check("threshold edit rereads identical samples",a.samples==b.samples and a.rng.state==b.rng.state)
            var monotone:=true;var count:=0
            for i in range(64):
                monotone=monotone and (not b.marks[i] or a.marks[i])
                count+=int(b.marks[i])
            check("lower threshold cannot add a backslash",monotone)
            check("expected count is24 while actual is measured",near(b.probability*64,24) and b.status.text.contains("Actual: %d"%count))
            observations.actual_backslashes=count
        4:
            a.reset_run();b.reset_run()
            a.accept_face(2);b.accept_face(2);b.accept_face(4);b.accept_face(3)
            check("the changed continuation rule closes after an odd face",a.total==2 and a.closed and b.total==9 and b.history==[2,4,3] and b.closed)
            check("a closed run refuses another result",not b.accept_face(6) and b.total==9)
            b.reset_run();b.max_draws=2;b.accept_face(2);b.accept_face(4)
            check("display limit is distinct from rule closure",b.limited and not b.closed and not b.accept_face(2))
        5:
            for i in range(3):b.step()
            check("cancelling turns produce zero total but a negative latest",near(b.total,0) and near(rad_to_deg(b.latest),-8) and b.cursor==3)
            check("assignment and accumulation are visibly different",not b.assigned.basis.is_equal_approx(b.accumulated.basis))
            var state: int=b.rng.state;b.replay()
            for i in range(3):b.step()
            check("record replay does not ask the generator",near(b.total,0) and b.rng.state==state)
        6:
            for i in range(4):a.step();b.step()
            check("before the boundary halving step length halves displacement",(a.current-a.origin).is_equal_approx((b.current-b.origin)*2) and a.rng.state==b.rng.state)
            a.restart(a.origin);b.step_size=a.step_size;b.restart(a.origin)
            for i in range(6):a.step();b.step()
            b.positions[0]=Vector3(100,100,100)
            a.step();b.step()
            check("editing an old trace entry does not steer the walk",a.current==b.current and a.rng.state==b.rng.state)
            b.on_pickup(b.point);var saved: int=b.rng.state;var steps: int=b.steps;b._process(4)
            check("held time keeps both step count and stream",b.rng.state==saved and b.steps==steps)
        7:
            b.values.assign([-0.2,0.0,0.05,0.49,0.5,0.99,1.0,1.3]);var saved=b.values.duplicate();var state: int=b.rng.state
            b.rebin(6)
            check("six-bin fixture includes endpoint1 in final bin",b.counts==[3,0,1,1,0,3] and b.clipped==2)
            b.rebin(2);check("two bins preserve all observations",b.counts==[4,4] and b.values==saved and b.rng.state==state)
            b.rebin(6);check("returning the bins recovers the classification",b.counts==[3,0,1,1,0,3] and b.values==saved)
        8:
            var prefix: bool=b.records.size()==7
            for i in range(b.records.size()):
                var x=a.records[i];var y=b.records[i]
                prefix=prefix and x.kind==y.kind and x.position==y.position and near(x.yaw,y.yaw) and near(y.size-1,(x.size-1)*2)
            check("smaller population and wider size range preserve recipe assignments",prefix)
            var saved=b.records.duplicate(true);var state: int=b.rng.state;b.toggle_size()
            var unscaled:=true
            for body in b.bodies:unscaled=unscaled and body.scale==Vector3.ONE
            check("SIZE changes expression without losing sample",unscaled and b.records==saved and b.rng.state==state)
            b.toggle_size();b.rebuild();check("rebuilding retains records and stream",b.records==saved and b.rng.state==state)
        9:
            check("display spacing changes no data or measure",a.records==b.records and a.rng.state==b.rng.state and near(a.neighbour_gap("field"),b.neighbour_gap("field")))
            check("the cubes have actually moved",a.columns[0].position!=b.columns[0].position)
            for row in b.records:row.white=(row.at.x+row.at.y)%2;row.field=row.white
            check("checkerboard fixture has unit neighbour gap",near(b.neighbour_gap("white"),1))
            for row in b.records:row.white=0.0 if row.at.x<4 else 1.0
            check("half-plane fixture has eight unlike edges of112",near(b.neighbour_gap("white"),1.0/14))
        10:
            a.replay();b.replay()
            for i in range(256):a.add_samples(1)
            for i in range(37):b.add_samples(b.BATCH)
            check("seven-at-a-time retains the full individual sample and estimate history",a.samples==b.samples and a.estimates==b.estimates and b.samples.size()==256)
            var hits:=0
            for p in b.samples:
                if p.x*p.x+p.y*p.y<=1:hits+=1
            check("estimate is the declared area ratio",b.inside==hits and near(b.estimates.back(),4.0*hits/256))
            var state: int=b.rng.state;b.add_samples(7)
            check("budget exhaustion makes no extra draws",b.samples.size()==256 and b.rng.state==state)
        11:
            b.advance(40);var path=b.path.duplicate();var state: int=b.rng.state
            check("forty departures keep41positions and40visits",b.path.size()==41 and near(sum_values(b.visits),40))
            b.replay()
            for i in range(b.field.size()):b.field[i]=float(i)*1000.0
            b.advance(40)
            check("guidance0 makes a different scent field irrelevant to the path",b.path==path and b.rng.state==state)
            a.guidance=1;a.replay();a.advance(1)
            check("empty-neighbour tie selects east and deposits at departure",a.at==Vector2i(5,4) and near(a.field[a.index(Vector2i(4,4))],0.6) and a.visits[a.index(Vector2i(4,4))]==1)
            a.advance(1);check("attraction reads the previously deposited neighbour",a.at==Vector2i(4,4) and near(a.field[a.index(Vector2i(4,4))],0.56))
        12:
            check("zero later weights retain three parts but only the first contributes",b.parts.size()==3 and b.raw==a.raw and near(sum_values(b.parts[1]),0) and near(sum_values(b.parts[2]),0))
            var saved=b.raw.duplicate();var offsets=b.offsets.duplicate();var state: int=b.rng.state
            b.lacunarity=3;b.sample_fields()
            check("frequency of zero-weight parts does not change the sum",b.raw==saved and b.offsets==offsets and b.rng.state==state)
            b.redraw();check("drawing neither redraws offsets nor changes the record",b.raw==saved and b.rng.state==state)
        13:
            var x=a.cycle;var y=b.cycle;var end: int=x.until_ms
            check("notice edit keeps first duration and RNG",end==y.until_ms and x.rng.state==y.rng.state)
            x.advance_to(end-600);y.advance_to(end-600)
            check("only longer notice is visible600ms before sinking",x.cue_visible() and not y.cue_visible())
            x.advance_to(end-300);y.advance_to(end-300)
            check("both notices visible300ms before sinking",x.cue_visible() and y.cue_visible())
            x.replay();y.replay();var parity:=true
            for t in range(0,60001,113):
                x.advance_to(t);y.advance_to(t)
                parity=parity and x.state==y.state and x.until_ms==y.until_ms and x.supports()==y.supports() and near(x.height(),y.height()) and x.rng.state==y.rng.state
            check("sixty seconds of events and support agree despite different notice",parity)
    a.free();b.free()
    var data={"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations}
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
    quit(0 if failures.is_empty() else 1)
