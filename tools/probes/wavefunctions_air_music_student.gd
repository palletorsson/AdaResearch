extends SceneTree

var checks: Array=[]
var failures: Array=[]
var onsets: Array[int]=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[contact] ","PASS " if value else "FAIL ",title)
func settle() -> void:
    for i in range(5):await physics_frame
    await process_frame
func move_point(lesson: Node3D, at: Vector3) -> void:
    lesson.point.global_position=lesson.to_global(at)
    await settle()

func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var lesson=load(source).new()
    lesson.position=Vector3(4,2,7);lesson.rotation.y=PI/3
    root.add_child(lesson)
    lesson.struck.connect(func(index):onsets.append(index))
    await settle()
    check("complete program builds point, two bars, players and readout",lesson.bars.size()==2 and lesson.players.size()==2 and lesson.lines.size()==64 and lesson.label.text!="")
    check("unchanged point retains sphere and pickup",lesson.point.enabled and lesson.point.freeze and is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    check("initial scene is silent",lesson.ages_now()==PackedFloat64Array([-1,-1]) and onsets.is_empty())
    check("two chosen pitches produce different clips",lesson.samples[0]!=lesson.samples[1])
    check("sound is finite three-second 16-bit mono",lesson.samples[0].size()==264600 and lesson.players[0].stream.mix_rate==44100 and not lesson.players[0].stream.stereo)
    var a: Vector3=lesson.bars[0].position
    var b: Vector3=lesson.bars[1].position
    await move_point(lesson,a)
    check("real point-area collision starts first voice",onsets==[0] and lesson.players[0].playing and not lesson.players[1].playing)
    await create_timer(0.2).timeout
    check("remaining inside does not retrigger",onsets==[0] and lesson.ages_now()[0]>0.12)
    await move_point(lesson,Vector3(0,1.05,0.8))
    var age_before: float=lesson.ages_now()[0]
    await move_point(lesson,b)
    check("second collision joins without stopping first",onsets==[0,1] and lesson.players[0].playing and lesson.players[1].playing)
    check("first voice retains its older playback age",lesson.ages_now()[0]>=age_before and lesson.ages_now()[0]>lesson.ages_now()[1]+0.15)
    await move_point(lesson,Vector3(0,1.05,0.8))
    var first_age: float=lesson.ages_now()[0]
    await move_point(lesson,b)
    check("same bar restarts one voice only",onsets==[0,1,1] and lesson.ages_now()[0]>=first_age and lesson.ages_now()[1]<0.16)
    await move_point(lesson,Vector3(0,1.05,0.8))
    lesson.point.collision_layer=lesson.point.picked_up_layer
    lesson.point.collision_mask=0
    await move_point(lesson,a)
    check("held pickup layer still reaches contact sensor",onsets==[0,1,1,0])
    await move_point(lesson,Vector3(0,1.05,0.8))
    var other:=RigidBody3D.new()
    other.freeze=true;other.collision_layer=lesson.point.collision_layer
    var col:=CollisionShape3D.new();col.shape=SphereShape3D.new();col.shape.radius=0.14
    other.add_child(col);other.position=lesson.to_global(Vector3(0,2,0))
    root.add_child(other);await settle()
    var onset_count:=onsets.size()
    other.global_position=lesson.to_global(b);await settle()
    check("another body enters sensor but is rejected",lesson.bars[1].overlaps_body(other) and onsets.size()==onset_count)
    other.queue_free()
    var ages:=PackedFloat64Array([0.137,0.319])
    var correct:=true
    var maximum:=0.0
    for i in range(80):
        var offset:=float(i)*0.000137
        var index_a:=int((ages[0]+offset)*44100)*2
        var index_b:=int((ages[1]+offset)*44100)*2
        var expected:=float(lesson.samples[0].decode_s16(index_a)+lesson.samples[1].decode_s16(index_b))/32767.0
        correct=correct and absf(lesson.sum_at(ages,offset)-expected)<0.000001
        maximum=maxf(maximum,absf(expected))
    check("display adds independent stored samples, not one shared age",correct)
    check("quiet voice contributes zero even at positive offset",lesson.sum_at(PackedFloat64Array([-1,-1]),1.2)==0.0)
    check("reading before or past finite data is safe",lesson.voice.read_sample(lesson.samples[0],-0.2)==0 and lesson.voice.read_sample(lesson.samples[0],3.0)==0)
    var peak:=0.0
    for bytes in lesson.samples:
        for j in range(0,bytes.size(),2):peak=maxf(peak,absf(float(bytes.decode_s16(j))/32767.0))
    check("each source stays within quarter scale",peak<=0.250001 and maximum<0.5)
    check("envelope approaches zero at finite end",absf(lesson.voice.sample_at(2.999,261.63))<0.0002 and lesson.voice.sample_at(3,261.63)==0)
    await create_timer(3.15).timeout
    lesson.draw_state()
    check("both voices finish without a stop event",lesson.ages_now()==PackedFloat64Array([-1,-1]) and lesson.label.text.begins_with("0 voices"))
    var flat:=true
    for line in lesson.lines:flat=flat and absf(line.position.y-1.65)<0.000001
    check("finished sum returns to baseline",flat)
    var variant=load(source.get_base_dir()+"/09_same_pitch.gd").new()
    variant.position=Vector3(12,0,0);root.add_child(variant);await settle()
    check("same-pitch variation has identical data but separate players",variant.samples[0]==variant.samples[1] and variant.players[0]!=variant.players[1])
    await move_point(variant,variant.bars[0].position)
    await create_timer(0.2).timeout
    await move_point(variant,variant.bars[1].position)
    check("same-pitch exercise retains separate ages",variant.players[0].playing and variant.players[1].playing and variant.ages_now()[0]>variant.ages_now()[1]+0.15)
    lesson.queue_free();variant.queue_free();await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Native physics contact and Dummy-driver playback of exact printed files. Teacher-authored assertions, not independent student or headset verification."},"  "))
    quit(0 if failures.is_empty() else 1)
