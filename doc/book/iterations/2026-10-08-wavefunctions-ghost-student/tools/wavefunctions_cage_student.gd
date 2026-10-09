extends SceneTree

var checks: Array = []
var failures: Array = []
var dispatched: Array[int] = []
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[score] ","PASS " if value else "FAIL ",title)

func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var lesson=load(source).new()
    lesson.position=Vector3(4,2,7);lesson.rotation.y=PI/3
    root.add_child(lesson);lesson.set_process(false)
    lesson.event_started.connect(func(index):dispatched.append(index))
    check("complete program makes six events, players, markers and labels",lesson.score.size()==6 and lesson.players.size()==6 and lesson.markers.size()==6 and lesson.captions.size()==6 and lesson.label.text!="")
    check("three explicit prepared voices",lesson.notes.size()==3)
    check("carried point retains pickup and frozen release",lesson.point.enabled and lesson.point.freeze and lesson.point.release_mode==lesson.point.ReleaseMode.FROZEN and lesson.point.get_child(1).shape is SphereShape3D)
    check("familiar sphere retains radius",is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    check("construction chooses a score without playing",not lesson.playing and lesson.cursor==0)
    var notes_valid:=true
    for note in lesson.notes:notes_valid=notes_valid and note.data.size()==52920 and note.mix_rate==44100 and not note.stereo
    check("clips retain the inherited 0.6-second mono format",notes_valid)
    var old=load("res://doc/book/studies/wavefunctions-lineage/06_phase_note.gd").new()
    check("new helper generates byte-identical inherited sound",old.make_note(0).data==lesson.notes[0].data and old.make_note(1).data==lesson.notes[1].data and old.make_note(3).data==lesson.notes[2].data)
    old.free()
    check("depth choices actually produce different samples",lesson.notes[0].data!=lesson.notes[1].data and lesson.notes[1].data!=lesson.notes[2].data)
    lesson.rng.seed=384
    lesson.new_score()
    var previous:=0.0
    var times_valid:=true
    var voices_valid:=true
    var positions_valid:=true
    for i in range(lesson.score.size()):
        var event: Dictionary=lesson.score[i]
        var at: float=event.at
        times_valid=times_valid and at-previous>=0.8-0.000001 and at-previous<=1.6+0.000001
        voices_valid=voices_valid and event.voice is int and event.voice>=0 and event.voice<3
        positions_valid=positions_valid and lesson.markers[i].position.is_equal_approx(Vector3(-1.8+0.35*at,0.95+0.4*event.voice,0))
        previous=at
    check("positive intervals accumulate into chronological times",times_valid)
    check("every voice address refers to a prepared clip",voices_valid)
    check("display maps seconds and voice indices to positions",positions_valid)
    var kept: Array=lesson.score.duplicate(true)
    var rng_state: int=lesson.rng.state
    lesson.point.position.x=-0.65
    lesson.point.action_pressed.emit(lesson.point)
    check("left-point trigger starts replay in a rotated translated host",lesson.playing and lesson.cursor==0 and lesson.elapsed==0)
    check("replay retains the record",lesson.score==kept)
    check("replay makes no random requests",lesson.rng.state==rng_state)
    var first: float=kept[0].at
    lesson._process(first-0.001)
    check("no event dispatched before its time",dispatched.is_empty() and lesson.cursor==0)
    lesson._process(0.0011)
    check("first event dispatched once at boundary",dispatched==[0] and lesson.cursor==1)
    check("chosen stream reaches its actual audio player",lesson.players[0].stream==lesson.notes[int(kept[0].voice)] and lesson.players[0].playing)
    check("played marker changes colour",lesson.markers[0].material_override.albedo_color==Color(1,0.5,0.7))
    lesson._process(20.0)
    check("one late frame dispatches every overdue event",dispatched==[0,1,2,3,4,5] and lesson.cursor==6)
    check("score ends without dropping overdue voices",not lesson.playing and lesson.players[5].stream==lesson.notes[int(kept[5].voice)])
    lesson._process(20.0)
    check("finished score does not repeat events",dispatched.size()==6)
    lesson.replay()
    check("replay resets only performance state",lesson.elapsed==0 and lesson.cursor==0 and lesson.score==kept and lesson.rng.state==rng_state)
    check("restart stops already sounding players",not lesson.players[0].playing and not lesson.players[5].playing)
    check("restart clears marker highlight",lesson.markers[0].material_override.albedo_color==Color(0.06,0.06,0.07))
    dispatched.clear()
    lesson._process(20)
    check("repeated performance keeps event order",dispatched==[0,1,2,3,4,5] and lesson.score==kept)
    lesson.point.position.x=0.65
    lesson.point.action_pressed.emit(lesson.point)
    check("right-point trigger draws from generator and restarts",lesson.rng.state!=rng_state and lesson.cursor==0 and lesson.elapsed==0 and lesson.playing)
    # One known seed makes this assertion deterministic; novelty is not promised for every draw.
    check("known test seed yields a changed score on NEW",lesson.score!=kept)
    var alternative=load(source.get_base_dir()+"/08_equal_intervals.gd").new()
    root.add_child(alternative);alternative.set_process(false)
    var regular:=true
    for i in range(6):regular=regular and is_equal_approx(alternative.score[i].at,float(i+1))
    check("independent equal-wait variation has timestamps 1 through 6",regular)
    alternative.replay();alternative._process(2.01)
    check("regular-pulse variation dispatches exactly two events by 2.01s",alternative.cursor==2)
    alternative._process(5)
    check("regular-pulse variation completes",alternative.cursor==6 and not alternative.playing)
    lesson.queue_free();alternative.queue_free();await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed files; teacher-authored native assertions. Not a headset, independent reconstruction or comprehension test."},"  "))
    quit(0 if failures.is_empty() else 1)
