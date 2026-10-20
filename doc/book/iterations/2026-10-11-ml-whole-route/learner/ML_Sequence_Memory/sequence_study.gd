extends "pose_study.gd"
## Keep the PointBody, tracking and coordinate function from Perception.
const Movement = preload("movement_learner.gd")
const Library = preload("phrase_library.gd")
const ONE_FILE := "user://ada_student_phrase_v1.json"
const TWO_FILE := "user://ada_student_phrase_ab_v1.json"
var one := Movement.new()
var library := Library.new()
var selected := "ONE"
var capturing := false
var phrase_time := 0.0
var pending: Array = []
var replay_time := -1.0
var replay_model: RefCounted
var result: Dictionary = {}
var rods: Array[MeshInstance3D] = []
var tips: Array[MeshInstance3D] = []
var click := AudioStreamPlayer3D.new()
var sound := true
var last_beat := -999

func _ready() -> void:
    super._ready() # Creates the same point, ring, collision, board and readout.
    if FileAccess.file_exists(SAVE_PATH): model.load_file(SAVE_PATH)
    remove_child(panel)
    panel.free()
    var rows: Array = []
    var commands: Array = []
    for names in [["ONE","A","B"],["CAPTURE","TEACH","TRAIN"],["TEST","TRY","REPLAY"],["UNDO","SAVE","LOAD"],["SOUND","STOP"]]:
        var row: Array = []
        for word in names:
            row.append({"type":"button","label":word})
            commands.append(word)
        rows.append(row)
    panel = Rack.create_panel("BOTH HANDS / A PHRASE KEPT", rows)
    panel.position = Vector3(0, 0.75, 0.8)
    panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2
    add_child(panel)
    for i in commands.size():
        var button = panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area): command(commands[i]))
    readout.position.y = 2.38
    readout.font_size = 23
    for hand in 2:
        var ink := StandardMaterial3D.new()
        ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        ink.albedo_color = Color(1,0.22,0.55) if hand==0 else Color(0.1,0.8,1)
        for i in Movement.STEPS-1:
            var rod := MeshInstance3D.new()
            var tube := CylinderMesh.new()
            tube.top_radius=0.005; tube.bottom_radius=0.005; tube.height=1
            tube.radial_segments=6
            rod.mesh=tube; rod.material_override=ink; rod.hide()
            add_child(rod); rods.append(rod)
        var tip := MeshInstance3D.new()
        var ball := SphereMesh.new(); ball.radius=0.024; ball.height=0.048
        tip.mesh=ball; tip.material_override=ink; tip.hide()
        add_child(tip); tips.append(tip)
    click.stream=make_click(); click.volume_db=-18
    click.position=Vector3(0,1.4,0.2); click.max_distance=4
    add_child(click)
    mode="TEACH"; message="ONE: record three separate four-second phrases."
    refresh()

func active_model() -> RefCounted:
    return one if selected=="ONE" else library.models[selected]

func ready_to_test() -> bool:
    return one.trained if selected=="ONE" else library.trained

func stop() -> void:
    capturing=false; pending.clear(); replay_time=-1
    click.stop(); last_beat=-999

func command(which: String) -> void:
    if which=="STOP":
        stop(); message="Stopped. No partial take kept."; draw_phrase(); refresh(); return
    if which=="SOUND": sound=not sound; refresh(); return
    if capturing: return # The target cannot change halfway through a take.
    replay_time=-1; result.clear()
    if which in ["ONE","A","B"]:
        selected=which; mode="TEACH"; message="Teach %s. Earlier sets stay." % selected
    elif which=="TEACH": mode="TEACH"; message="CAPTURE a new whole performance."
    elif which=="TRAIN":
        var ok: bool=one.fit() if selected=="ONE" else library.fit()
        if ok: mode="TEST"
        message=one.message if selected=="ONE" else library.message
    elif which in ["TEST","TRY"]:
        if ready_to_test():
            mode=which; message="CAPTURE a fresh phrase; tests never train."
            if which=="TRY": begin_phrase()
        else: message="Teach three takes per set, then TRAIN."
    elif which=="CAPTURE": begin_phrase()
    elif which=="REPLAY":
        if active_model().trained:
            replay_model=active_model(); replay_time=0; last_beat=-999
            message="PREVIEW %s / learned mean, not a recognition result." % selected
        else: message="Train the selected phrase first."
    elif which=="UNDO":
        if selected=="ONE": one.undo(); message=one.message
        else: library.undo(selected); message=library.message
        mode="TEACH"
    elif which in ["SAVE","LOAD"]:
        var store=one if selected=="ONE" else library
        var path:=ONE_FILE if selected=="ONE" else TWO_FILE
        if which=="SAVE":
            message="Saved student phrase." if store.save_file(path)==OK else "Save failed."
        else:
            message="Loaded; collect fresh tests." if store.load_file(path) else "Invalid/missing save; current data kept."
            mode="TEST" if ready_to_test() else "TEACH"
    draw_phrase(); refresh()

func begin_phrase() -> void:
    bind_tracking()
    if not tracked(): message="Head and BOTH tracked hands needed here."; return
    if mode!="TEACH" and not ready_to_test(): message="Train before testing."; return
    align() # Same feature contract; horizontal frame held for this entire take.
    if not aligned: return
    capturing=true; phrase_time=-3.0; sample_time=0; pending.clear()
    replay_time=-1; last_beat=-999
    message="READY 3 / arrange both hands, then move for eight beats."

func _process(delta: float) -> void:
    if capturing:
        var valid:=tracked()
        var x:Array=features(head.global_position,left.global_position,right.global_position,facing) if valid else []
        advance_phrase(delta,x,valid)
    elif replay_time>=0:
        replay_time+=maxf(0,delta)
        if replay_time>Movement.SECONDS: replay_time=-1; click.stop()
        else: beat(replay_time)
    draw_phrase(); refresh()

func beat(t: float) -> void:
    var index:=int(floor(t)) if t<0 else int(floor(t/0.5))
    if index!=last_beat:
        last_beat=index
        if sound and t<Movement.SECONDS:
            click.pitch_scale=1.5 if t<0 else 1.0
            click.play()

func advance_phrase(delta: float, x: Array, valid: bool) -> void:
    if not capturing: return
    if not valid or not Movement.valid_x(x) or delta>0.15 or delta<0:
        stop(); message="Tracking/timing interrupted: WHOLE take discarded."; return
    phrase_time+=delta
    if phrase_time>=Movement.SECONDS-0.000001: phrase_time=Movement.SECONDS
    beat(phrase_time)
    if phrase_time<0:
        message="READY %d / arrange hands" % ceili(-phrase_time); return
    message="%s / BEAT %d OF 8 / move BOTH hands" % [mode,mini(8,int(phrase_time/0.5)+1)]
    sample_time+=delta
    if pending.is_empty() or sample_time>=0.05 or phrase_time>=Movement.SECONDS:
        sample_time=0
        if pending.is_empty() or phrase_time>float(pending[-1].t):
            pending.append({"t":phrase_time,"x":x.duplicate()})
    if phrase_time>=Movement.SECONDS: complete_phrase()

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    stop()
    if mode=="TEACH":
        if selected=="ONE": one.add_example(take); message=one.message
        else: library.add_example(selected,take); message=library.message
        return
    result=one.test_example(take) if selected=="ONE" else library.test_example(take)
    if result.is_empty(): message="Incomplete take discarded."; return
    if selected=="ONE":
        message="%s / L %.3f / R %.3f (distance)" % ["MATCH" if result.accepted else "UNKNOWN",result.rms[0],result.rms[1]]
        replay_model=one
    else:
        message="%s / distance A %.2f / B %.2f" % [result.label,result.scores[0],result.scores[1]]
        if result.accepted: replay_model=library.models[result.label]
    if mode=="TRY" and result.accepted: replay_time=0; last_beat=-999

func miniature(x: Array, hand: int) -> Vector3:
    # Only the displayed miniature is bounded. Recognition retains full data.
    return Vector3(0,1.65,0.15)+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).limit_length(1.8)*0.4

func draw_phrase() -> void:
    var showing:bool=replay_time>=0 and replay_model!=null and replay_model.trained
    for hand in 2:
        for i in Movement.STEPS-1:
            var rod:=rods[hand*(Movement.STEPS-1)+i]
            rod.visible=showing
            if showing:
                var a:=miniature(replay_model.prototype[i],hand)
                var b:=miniature(replay_model.prototype[i+1],hand)
                var direction:=b-a
                rod.position=(a+b)*0.5
                rod.scale=Vector3(1,maxf(direction.length(),0.0001),1)
                rod.quaternion=Quaternion(Vector3.UP,direction.normalized()) if direction.length()>0.0001 else Quaternion.IDENTITY
        tips[hand].visible=showing
        if showing: tips[hand].position=miniature(replay_model.target(replay_time),hand)
    if sphere==null or sphere.is_picked_up(): return
    sphere.position=(tips[0].position+tips[1].position)*0.5 if showing else Vector3(0,1.15,0.15)
    surface.scale=Vector3.ONE
    material.albedo_color=Color(1,0.77,0.25) if showing else Color(0.75,0.78,0.82)

func refresh() -> void:
    # super._ready() calls this before the phrase panel is built.
    readout.text="BOTH HANDS / %s / %s\n" % [selected,mode]
    readout.text+="ONE %d takes / A %d / B %d\n" % [one.examples.size(),library.models.A.examples.size(),library.models.B.examples.size()]
    readout.text+=message+"\n8 BEATS / 120 BPM / 4 SECONDS\n"
    readout.text+="Fresh tests %d / sound %s" % [one.tests.size() if selected=="ONE" else library.tests.size(),"ON" if sound else "OFF"]

static func make_click() -> AudioStreamWAV:
    var wav:=AudioStreamWAV.new()
    wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=22050
    var bytes:=PackedByteArray(); bytes.resize(1102*2)
    for i in 1102:
        var t:=float(i)/wav.mix_rate
        bytes.encode_s16(i*2,int(sin(TAU*880*t)*exp(-t*100)*10000))
    wav.data=bytes
    return wav
