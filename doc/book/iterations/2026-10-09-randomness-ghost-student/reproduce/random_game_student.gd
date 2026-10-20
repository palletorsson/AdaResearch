extends SceneTree
var checks: Array=[]
var failures: Array=[]
var observations: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(title: String, passed: bool) -> void:
    checks.append({"name":title,"passed":passed})
    if not passed:failures.append(title)
    print("[game] ","PASS " if passed else "FAIL ",title)
func state_of(c) -> Array:
    return [c.state,c.now_ms,c.began_ms,c.until_ms,c.drawn_seconds,c.draws,c.rng.state]
func act(host, x: float) -> void:
    host.point.global_position=host.to_global(Vector3(x,0.6,0.7))
    host.point.action()
func run() -> void:
    await process_frame
    var path: String;var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):path=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var host=load(path).new();host.position=Vector3(8,0,6);host.rotation.y=PI/2
    root.add_child(host);host.set_physics_process(false)
    var c=host.cycle;var model=c.get_script()
    check("ready supplies stone collision point and initialized schedule",host.stone!=null and host.collision.shape.size==Vector3.ONE*0.6 and host.point.has_method("pick_up") and c.until_ms>0 and c.draws==1)
    check("reconstruction begins paused and supported",not host.running and c.now_ms==0 and c.supports() and not host.collision.disabled)
    var ref=load("res://commons/primitives/cubes/random_cycle_cube.gd").new()
    ref.wait_min_seconds=c.stand_band.x;ref.wait_span_seconds=c.stand_band.y
    ref.hidden_min_seconds=c.gone_band.x;ref.hidden_span_seconds=c.gone_band.y
    ref._rng.seed=c.run_seed
    var parity:=true;var bands:=true;var durations:=[]
    for i in range(200):
        var expected: float=ref._next_random_wait("stands" if i%2==0 else "gone")
        parity=parity and absf(expected-c.drawn_seconds)<0.000001 and ref._rng.state==c.rng.state
        var band: Vector2=c.stand_band if i%2==0 else c.gone_band
        bands=bands and c.drawn_seconds>=band.x and c.drawn_seconds<=band.y
        durations.append(c.drawn_seconds)
        c.advance_to(c.until_ms)
        c.advance_to(c.until_ms)
    check("200 alternating waits match the production draw and RNG state",parity)
    check("both wait bands bound every assigned duration",bands)
    observations.first_waits=durations.slice(0,8)
    c.replay();var initial:=state_of(c);var end: int=c.until_ms
    c.advance_to(end-1)
    check("just before deadline stone still stands",c.state==0 and c.wait_left_ms()==1 and c.draws==1 and c.supports())
    var before:=state_of(c)
    for i in range(20):c.cue_visible();c.wait_left_ms();c.height();c.supports()
    check("reading the cue cannot change the schedule",state_of(c)==before)
    c.cue_enabled=false;host.redraw();var hidden:=state_of(c)
    c.cue_enabled=true;host.redraw()
    check("cue toggles preserve deadline draw and RNG",state_of(c)==before and hidden==before and host.crown.visible)
    c.replay();end=c.until_ms
    c.advance_to(end-c.notice_ms-1);check("cue is off before notice window",not c.cue_visible())
    c.advance_to(end-c.notice_ms);check("cue begins exactly at notice boundary",c.cue_visible())
    c.advance_to(end);check("deadline enters LEAVES without a draw",c.state==1 and c.draws==1 and c.until_ms==end+700 and c.wait_left_ms()==0 and not c.cue_visible())
    c.advance_to(end+250);check("half sink uses sine easing",is_equal_approx(c.height(),-0.61) and c.supports())
    c.advance_to(end+699);check("sink and lag retain support",is_equal_approx(c.height(),-1.22) and c.supports() and c.state==1)
    c.advance_to(end+700);var gone_end: int=c.until_ms
    check("GONE draws once and withdraws support",c.state==2 and c.draws==2 and not c.supports() and is_equal_approx(c.height(),-1.22))
    c.advance_to(gone_end+199);check("return lead delay still has no support",c.state==3 and not c.supports() and is_equal_approx(c.height(),-1.22))
    c.advance_to(gone_end+200);check("return enables support before rising",c.supports() and is_equal_approx(c.height(),-1.22))
    c.advance_to(gone_end+300);check("half rise uses sine easing",is_equal_approx(c.height(),-0.61) and c.supports())
    c.advance_to(gone_end+400);check("next STANDS draws once and restores height",c.state==0 and c.draws==3 and is_zero_approx(c.height()) and c.supports())
    c.replay();check("replay rewinds the complete schedule",state_of(c)==initial)
    var a=model.new();var b=model.new();a.replay();b.replay()
    a.advance_to(120000)
    for t in range(0,120001,17):b.advance_to(t)
    b.advance_to(120000)
    check("coarse and fine updates retain identical schedule",state_of(a)==state_of(b))
    before=state_of(a);a.advance_to(2)
    check("ordinary updates cannot rewind time",state_of(a)==before)
    a=model.new();b=model.new();a.replay();b.replay();b.cue_enabled=false
    var same:=true
    for t in range(0,60000,137):
        a.advance_to(t);b.advance_to(t);a.cue_visible();b.cue_visible()
        same=same and state_of(a)==state_of(b)
    check("warning choice never changes sixty seconds of events",same)
    a=model.new();a.stand_band=Vector2(3,3);a.replay();var fresh:=RandomNumberGenerator.new();fresh.seed=a.run_seed
    check("fixed standing wait consumes no RNG value",a.drawn_seconds==3 and a.rng.state==fresh.state)
    a.advance_to(3700);var expected_gone:=fresh.randf_range(a.gone_band.x,a.gone_band.y)
    check("next variable wait uses first available draw",is_equal_approx(a.drawn_seconds,expected_gone) and a.rng.state==fresh.state)
    host.replay();initial=state_of(c);host._physics_process(2)
    check("paused clock remains unchanged",state_of(c)==initial and host.clock_ms==0)
    act(host,0.35)
    check("CUE action uses local point coordinates",not c.cue_enabled and state_of(c)==initial)
    act(host,1.05)
    check("quarter step advances only a paused clock",c.now_ms==250 and host.clock_ms==250)
    act(host,-0.35);host._physics_process(0.125);var run_time: int=c.now_ms
    act(host,1.05)
    check("RUN advances while step is inert during running",host.running and run_time==375 and c.now_ms==375)
    act(host,-0.35);host._physics_process(4)
    check("STOP freezes without resetting the wait",not host.running and c.now_ms==375 and c.draws==1)
    host.point.position=Vector3(0,0.6,0.7);host.point.dropped.emit(host.point);await physics_frame
    check("moving and dropping the point do not change schedule",c.now_ms==375 and not host.running)
    act(host,-1.05)
    check("point REPLAY restores paused supported first state",c.now_ms==0 and not host.running and c.supports() and is_zero_approx(c.height()) and c.draws==1)
    c.advance_to(c.until_ms+700);host.redraw();await physics_frame
    check("rendered collider follows hidden state",host.collision.disabled and host.surface.material_override.albedo_color==Color(0.15,0.16,0.2) and is_equal_approx(host.stone.position.y,1.35-1.22*0.6))
    host.replay();await physics_frame
    check("replay restores real collider and transform",not host.collision.disabled and is_equal_approx(host.stone.position.y,1.35))
    var labels:=0
    for l in host.find_children("*","Label3D",true,false):
        if (l.text=="REPLAY" and l.position.x< -0.7) or (l.text=="RUN / STOP" and l.position.x>= -0.7 and l.position.x<0) or (l.text=="CUE" and l.position.x>=0 and l.position.x<0.7) or (l.text=="+0.25 s" and l.position.x>=0.7):labels+=1
    check("four action labels lie in their trigger zones",labels==4)
    observations.scope="Source draw parity; schedule boundary/partition checks; supplied PointBody actions. Not a headset or unfamiliar learner."
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    host.free();ref.free();quit(0 if failures.is_empty() else 1)
