extends "res://tools/probes/transformation_encounters.gd"

func press(crossing, index: int) -> void:
    var area=crossing._crossing.find_child("Btn_%d" % index,true,false).get_node("InteractableAreaButton")
    area.button_pressed.emit(area)

func act(study, words: String) -> void:
    for l in study.find_children("*","Label3D",true,false):
        if l.text==words:
            study.point.global_position=study.to_global(Vector3(l.position.x,0.6,0.7))
            study.point.action()
            return

func schedule(crossing) -> Array:
    var records:=[]
    for s in crossing._stones:records.append([s._state,s._step_wait,s._step_until_ms,s._rng.state])
    return records

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var crossing=find_scene("/random_cycle_cube.gd")
    check("installed crossing and three stones exist",crossing!=null and crossing._stones.size()==3)
    if crossing==null:return
    var previous:=schedule(crossing)
    press(crossing,2)
    check("CUE button removes advance warning without changing any schedule",crossing.advance_seconds==0 and schedule(crossing)==previous)
    press(crossing,2)
    check("CUE restores advance warning without changing any schedule",is_equal_approx(crossing.advance_seconds,1.2) and schedule(crossing)==previous)
    press(crossing,0);await tick()
    var first:=[];var seeds:=[];var initial_ok:=true
    for s in crossing._stones:
        var rng:=RandomNumberGenerator.new();rng.seed=s.cycle_seed
        var expected:=rng.randf_range(crossing.CH_STANDS.x,crossing.CH_STANDS.y)
        initial_ok=initial_ok and s._state==0 and absf(s._step_wait-expected)<0.000001 and not s._collision_shape.disabled
        first.append(s._step_wait);seeds.append(s.cycle_seed)
    check("REPLAY starts supported stones from their seeded first waits",initial_ok)
    var seen:=[];var support_ok:=true;var draws_ok:=true
    var last_rng: int=crossing._rng.state;var last_state: int=crossing._state
    var began:=Time.get_ticks_msec();var return_off:=false;var return_on:=false
    while crossing._cycles_done<1 and Time.get_ticks_msec()-began<14000:
        var state: int=crossing._state
        if not seen.has(state):seen.append(state)
        if state==0 or state==1:support_ok=support_ok and not crossing._collision_shape.disabled
        if state==2:support_ok=support_ok and crossing._collision_shape.disabled
        if state==3:
            return_off=return_off or crossing._collision_shape.disabled
            return_on=return_on or not crossing._collision_shape.disabled
        if state==last_state:draws_ok=draws_ok and crossing._rng.state==last_rng
        last_state=state;last_rng=crossing._rng.state
        await tick()
    check("live stone completes all four states in order",seen==[0,1,2,3] and crossing._cycles_done>=1)
    check("production support remains through sink and leaves while hidden",support_ok)
    check("production return has collider delay before support",return_off and return_on)
    check("production frames within a phase consume no new waits",draws_ok)
    observations.first_waits=first;observations.stone_seeds=seeds;observations.states=seen
    press(crossing,0);await tick()
    var replay_ok:=true
    for i in range(3):replay_ok=replay_ok and crossing._stones[i]._step_wait==first[i] and not crossing._stones[i]._collision_shape.disabled
    check("replay restores first waits after a completed cycle",replay_ok)
    await snapshot("crossing",hall.to_global(Vector3(6,3.2,7)),hall.to_global(Vector3(9.5,0.4,10.5)),65)
    # Test reset during movement, not only while waiting.
    began=Time.get_ticks_msec()
    while crossing._state!=1 and Time.get_ticks_msec()-began<6000:await tick()
    check("source reaches a moving state for reset test",crossing._state==1)
    press(crossing,0);await tick();await create_timer(0.8).timeout
    check("replay cancels the old motion and restores support",crossing._state==0 and is_equal_approx(crossing.position.y,crossing._base_position.y) and not crossing._collision_shape.disabled and crossing._step_wait==first[1])
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    var study=load(spec.lesson).new();study.position=Vector3(3.5,0,10.5);study.rotation.y=PI/2
    hall.add_child(study);await tick()
    var approach: Vector3=study.to_global(Vector3(0,0,1.5));var hit:=floor_at(approach)
    check("study approach has existing floor",not hit.is_empty() and absf(hit.position.y-approach.y)<0.05)
    var shape:=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.92)
    var obstacles:=[]
    for item in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if item.collider!=museum.get("_player"):obstacles.append(str(item.collider.get_path()))
    check("study standing approach is clear",obstacles.is_empty())
    observations.learner_origin=xyz(study.position);observations.obstacles=obstacles
    var eye: Vector3=study.to_global(Vector3(0,1.8,3.3));var target: Vector3=study.to_global(Vector3(0,1.28,0))
    await snapshot("student-ready",eye,target,60)
    var c=study.cycle;var end: int=c.until_ms;var first_wait: float=c.drawn_seconds;var seed_state: int=c.rng.state
    act(study,"+0.25 s")
    check("point quarter step advances the stored clock",c.now_ms==250 and c.until_ms==end and c.rng.state==seed_state)
    act(study,"RUN / STOP");await create_timer(0.3).timeout;act(study,"RUN / STOP")
    check("point can run then pause the stone",not study.running and c.now_ms>450 and c.now_ms<1000 and c.until_ms==end)
    study.clock_ms=end-900;c.advance_to(int(study.clock_ms));study.redraw()
    check("advance cue reads the stored wait",study.crown.visible and c.drawn_seconds==first_wait and c.rng.state==seed_state)
    await snapshot("student-notice",eye,target,60)
    act(study,"CUE")
    check("point CUE changes ring without changing deadline",not study.crown.visible and c.until_ms==end and c.rng.state==seed_state)
    await snapshot("student-no-cue",eye,target,60)
    c.advance_to(end+700);study.clock_ms=c.now_ms;study.redraw();await tick()
    check("learner hidden state withdraws actual collision",c.state==2 and study.collision.disabled and not study.beacon.visible)
    await snapshot("student-hidden",eye,target,60)
    act(study,"REPLAY");await tick()
    check("point REPLAY restores initialized paused geometry",not study.running and c.now_ms==0 and not study.collision.disabled and is_equal_approx(study.stone.position.y,1.35) and c.drawn_seconds==first_wait)
    var short=load(spec.short_notice).new();short.position=study.position;short.rotation=study.rotation;study.free();hall.add_child(short);await tick()
    short.cycle.advance_to(short.cycle.until_ms-900);short.clock_ms=short.cycle.now_ms;short.redraw()
    check("complete short-notice edit preserves event but withholds earlier ring",short.cycle.drawn_seconds==first_wait and short.cycle.until_ms==end and not short.crown.visible)
    await snapshot("student-short-notice",eye,target,60)
    short.cycle.advance_to(end-300);short.clock_ms=short.cycle.now_ms;short.redraw()
    check("edited ring begins three tenths before the same event",short.crown.visible and short.cycle.until_ms==end)
    short.free();study=load(spec.lesson).new();study.position=Vector3(3.5,0,10.5);study.rotation.y=PI/2;hall.add_child(study);await tick()
    await snapshot("crossing-and-study",hall.to_global(Vector3(9.5,9,4.5)),hall.to_global(Vector3(7,0,10.5)),64)
    await snapshot("hall-with-study",hall.to_global(Vector3(9.5,24,-3)),hall.to_global(Vector3(9.5,0,24)),68)
    observations.study_wait=first_wait;observations.study_deadline_ms=end
