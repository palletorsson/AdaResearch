extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[sound] ", "PASS " if value else "FAIL ", title)

func run() -> void:
    await process_frame
    var source := ""
    var report := ""
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="):source=argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="):report=argument.trim_prefix("--report=")
    var lesson = load(source).new()
    lesson.position=Vector3(4,2,7);lesson.rotation.y=PI/3
    root.add_child(lesson)
    lesson.set_process(false)
    check("complete script creates point, audio, retained note and readout",lesson.point!=null and lesson.player!=null and lesson.reference!=null and lesson.label.text!="")
    check("carried point is pickable and keeps its 14 cm radius",lesson.point.enabled and lesson.point.freeze and is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14))
    check("label and curve contain no hidden scene dependency",lesson.rods.size()==96 and lesson.label.is_inside_tree())
    for pair in [[0.7,0.0],[1.0,0.0],[1.3,2.0],[1.6,4.0],[1.9,4.0]]:
        lesson.point.position.y=pair[0]
        check("height %.1f maps to depth %.1f in rotated local frame" % pair,absf(lesson.phase_depth()-pair[1])<0.00001)
    lesson.point.position=Vector3(1.8,1.3,-2)
    check("sideways and depth movement do not select another parameter",absf(lesson.phase_depth()-2)<0.00001)
    var t := 1.0/(8.0*440.0)
    var env := (t/0.01)
    var wanted := 0.5*tanh(0.8*sin(PI/4+2.0*exp(-t/0.25))*env)
    check("nested phase gives the predicted signed sample",absf(lesson.sample_at(t,2)-wanted)<0.000001)
    var unmodulated := 0.5*tanh(0.8*sin(PI/4)*env)
    check("zero depth removes the modulator contribution",absf(lesson.sample_at(t,0)-unmodulated)<0.000001)
    var changed: AudioStreamWAV=lesson.make_note(2)
    var reference: AudioStreamWAV=lesson.reference
    check("mono 16-bit buffer declares its sample rate",changed.format==AudioStreamWAV.FORMAT_16_BITS and not changed.stereo and changed.mix_rate==44100)
    check("0.6 seconds contains exactly 26460 signed samples",changed.data.size()==52920)
    check("buffer duration matches its declared rate",absf(changed.get_length()-0.6)<0.000001)
    check("first sample starts at zero",changed.data.decode_s16(0)==0)
    check("final sample approaches silence",absf(changed.data.decode_s16(changed.data.size()-2)/32767.0)<0.001)
    var max_error := 0.0
    var peak := 0
    var positive := false
    var negative := false
    for i in range(26460):
        var pcm := changed.data.decode_s16(i*2)
        positive=positive or pcm>0;negative=negative or pcm<0
        peak=maxi(peak,absi(pcm))
        max_error=maxf(max_error,absf(pcm/32767.0-lesson.sample_at(float(i)/44100.0,2)))
    check("every encoded sample matches the signal within one quantisation step",max_error<=1.0001/32767.0)
    check("PCM preserves both signs",positive and negative)
    check("bounded synthesis avoids clipping",peak>1000 and peak<16384)
    check("modulated note differs from retained reference",changed.data!=reference.data)
    var saved := reference.data.duplicate()
    lesson.point.position=Vector3(0,1.3,0)
    var prepared: PackedByteArray = lesson.make_note(lesson.phase_depth()).data
    lesson.point.action_pressed.emit(lesson.point)
    check("real pickable action signal starts reference A",lesson.busy and lesson.player.stream==reference and lesson.player.playing)
    lesson.point.position.y=1.6
    lesson.point.action_pressed.emit(lesson.point)
    check("second trigger cannot interrupt prepared pair",is_equal_approx(lesson.last_index,2.0) and lesson.player.stream==reference)
    await create_timer(0.90).timeout
    check("after reference and gap B uses the value at press",lesson.player.stream.data==prepared and lesson.player.playing)
    check("moving the point does not rewrite reference bytes",lesson.reference.data==saved)
    await create_timer(0.65).timeout
    check("pair finishes and accepts another trigger",not lesson.busy)
    lesson.draw_state()
    var end: Vector3=lesson.rods[-1].to_global(Vector3(0,lesson.rods[-1].mesh.height/2,0))
    check("scope endpoint uses the carried line in the study frame",end.distance_to(lesson.to_global(lesson.graph_point(96,4)))<0.0001)
    check("scope spans two carrier periods rather than the whole note",is_equal_approx(lesson.graph_point(0,0).x,-1.1) and is_equal_approx(lesson.graph_point(96,0).x,1.1))
    var variation=load(source).new();variation.ratio=1.5
    root.add_child(variation);variation.set_process(false)
    check("independent variation keeps carrier 440 and selects modulator 660",variation.frequency==440 and variation.frequency*variation.ratio==660)
    check("ratio change is silent at zero depth",variation.reference.data==saved)
    check("ratio change affects a modulated note",variation.make_note(2).data!=changed.data)
    check("second instrument does not change original reference or ratio",lesson.ratio==2 and lesson.reference.data==saved)
    if failures.is_empty():
        reference.save_to_wav(report.get_base_dir().path_join("baseline.wav"))
        changed.save_to_wav(report.get_base_dir().path_join("modulated.wav"))
    lesson.queue_free();variation.queue_free()
    await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"max_pcm_error":max_error,"peak_pcm":peak,"scope":"Exact printed code in Godot. Teacher-authored assertions; no listening, learner or physical-controller acceptance claim."},"  "))
    quit(0 if failures.is_empty() else 1)
