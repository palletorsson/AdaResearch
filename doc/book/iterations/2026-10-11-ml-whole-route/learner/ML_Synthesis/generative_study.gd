extends "sequence_study.gd"
## Carry the sphere, tracked capture, beat and two airborne paths.
const Generator=preload("phrase_generator.gd")
const GENERATION_FILE:="user://ada_student_generation_takes_v1.json"
var generator:=Generator.new()
var sample_seed:=1
var amount:=0.5
var generated:Dictionary={}
var display_phrase:=Movement.new()

func _ready() -> void:
    super._ready()
    remove_child(panel); panel.free()
    var rows:Array=[]; var commands:Array=[]
    for names in [["CAPTURE","FIT","SOURCE"],["MEAN","DRAW","NEXT"],["LESS","MORE","IMPORT"],["UNDO","SAVE","LOAD"],["SOUND","STOP"]]:
        var row:Array=[]
        for word in names:
            row.append({"type":"button","label":word}); commands.append(word)
        rows.append(row)
    panel=Rack.create_panel("SAME PHRASE / ANOTHER POSSIBILITY",rows)
    panel.position=Vector3(0,0.75,0.8); panel.rotation_degrees.x=-30
    panel.scale=Vector3.ONE*2; add_child(panel)
    for i in commands.size():
        var button=panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(commands[i]))
    mode="TEACH"; message="IMPORT saved ONE or CAPTURE 3 takes, then FIT."
    refresh()

func invalidate_generation() -> void:
    generator.clear(); generated.clear(); replay_time=-1
    display_phrase.invalidate()

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    stop()
    if one.add_example(take): invalidate_generation()
    message=one.message

func command(which:String) -> void:
    if which=="STOP": stop(); message="Stopped; no partial take kept."; draw_phrase(); refresh(); return
    if which=="SOUND": sound=not sound; refresh(); return
    if capturing: return
    stop()
    if which=="CAPTURE": mode="TEACH"; begin_phrase()
    elif which=="FIT":
        generated.clear(); generator.fit(one.examples); message=generator.message
    elif which=="SOURCE":
        generated.clear()
        if not one.examples.is_empty():
            show_rows(Movement.resample(one.examples[0]))
            message="SOURCE / first recorded take, resampled for display."
        else: message="Record or import a take first."
    elif which=="MEAN": preview(0.0)
    elif which=="DRAW": preview(amount)
    elif which=="NEXT": sample_seed+=1; preview(amount)
    elif which=="LESS": amount=maxf(0,amount-0.25); preview(amount)
    elif which=="MORE": amount=minf(1,amount+0.25); preview(amount)
    elif which=="UNDO":
        if one.undo(): invalidate_generation()
        message=one.message
    elif which=="SAVE":
        message="Saved source takes separately." if one.save_file(GENERATION_FILE)==OK else "Save failed."
    elif which in ["LOAD","IMPORT"]:
        var path:=ONE_FILE if which=="IMPORT" else GENERATION_FILE
        if one.load_file(path):
            invalidate_generation(); message="Source takes loaded. FIT before generating."
        else: message="Missing/invalid source file; current model kept."
    draw_phrase(); refresh()

func preview(strength:float) -> void:
    generated=generator.draw(sample_seed,strength)
    if generated.is_empty(): message="FIT valid teaching takes first."; return
    message=generated.reason
    if generated.previewable:
        show_rows(generated.rows)
        message="MEAN / no variation" if strength==0 else "GENERATED / seed %d / amount %.2f"%[sample_seed,strength]

func show_rows(rows:Array) -> void:
    display_phrase.prototype=rows.duplicate(true)
    display_phrase.trained=true # Playback adapter, not a fitted recogniser.
    replay_model=display_phrase; replay_time=0; last_beat=-999

func refresh() -> void:
    readout.text="A PHRASE VARIED / %d source takes\n"%one.examples.size()
    readout.text+="Fitted %s / seed %d / amount %.2f\n"%["YES" if generator.trained else "NO",sample_seed,amount]
    readout.text+=message+"\nSOURCE = recording / MEAN = fit / DRAW = sample\n"
    readout.text+="8 beats / 120 BPM / sound "+("ON" if sound else "OFF")
