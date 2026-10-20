extends "sequence_study.gd"
## The classifier receives a take; only the journal receives an intention.
const Evaluation=preload("phrase_evaluation.gd")
var journal:=Evaluation.new()
var intent:=""
var locked_model:=""
var totals:Dictionary={}
var matrix_display:=Node3D.new()
var matrix_cells:Array[Label3D]=[]
var matrix_footer:=Label3D.new()
var clear_until:=0
var import_path:=TWO_FILE
var model_path:="user://ada_student_synthesis_ab_v1.json"
var export_path:="user://ada_student_synthesis_checks_v1.json"

func _ready() -> void:
    super._ready()
    remove_child(panel);panel.free()
    var rows:Array=[];var commands:Array=[]
    for names in [["TEACH A","TEACH B","CHECK"],["MEANT A","MEANT B","OTHER"],["CAPTURE","TRAIN","IMPORT"],["REPLAY","SAVE","LOAD"],["EXPORT","CLEAR","STOP"],["SOUND"]]:
        var row:Array=[]
        for word in names:
            row.append({"type":"button","label":word});commands.append(word)
        rows.append(row)
    panel=Rack.create_panel("CHECK / AN INTENTION KEPT",rows)
    panel.position=Vector3(-0.75,0.95,0.35);panel.rotation_degrees.x=-30
    panel.scale=Vector3.ONE*2;add_child(panel)
    for i in commands.size():
        var button=panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(commands[i]))
    add_child(matrix_display)
    for row in 4:
        for col in 5:
            var label:=Label3D.new()
            label.position=Vector3([-0.95,-0.52,-0.16,0.30,0.84][col],2.03-row*0.12,-0.35)
            label.font_size=22;label.pixel_size=0.0017
            label.text=["MEANT","A","B","UNKNOWN","AMBIGUOUS"][col] if row==0 else (Evaluation.INTENTS[row-1] if col==0 else "0")
            matrix_display.add_child(label)
            if row>0 and col>0:matrix_cells.append(label)
    matrix_footer.position=Vector3(0,1.50,-0.35)
    matrix_footer.font_size=19;matrix_footer.pixel_size=0.0017
    matrix_display.add_child(matrix_footer)
    readout.position.y=2.39;readout.font_size=21
    selected="A";mode="CHECK"
    message="IMPORT saved A+B, or TEACH A and B here."
    update_totals();refresh()

func update_totals() -> void:
    totals=journal.summary(library)

func stop() -> void:
    super.stop()
    intent="";locked_model=""

func command(which:String) -> void:
    if which=="STOP":stop();message="Stopped; no partial take counted.";draw_phrase();refresh();return
    if which=="SOUND":sound=not sound;refresh();return
    if capturing:return # Intention, data and model stay fixed for this performance.
    replay_time=-1;result.clear()
    if which!="CLEAR":clear_until=0
    if which in ["MEANT A","MEANT B","OTHER"]:
        if mode!="CHECK":message="Choose CHECK before declaring an intention."
        elif not library.trained:message="Train both phrases first."
        else:
            intent=which.trim_prefix("MEANT ")
            message="Next take: %s. This does not enter prediction."%intent
    elif which=="CAPTURE":begin_phrase()
    else:
        intent="";locked_model=""
        if which in ["TEACH A","TEACH B"]:
            selected=which.trim_prefix("TEACH ");mode="TEACH"
            message="CAPTURE a new teaching take for "+selected
        elif which=="CHECK":
            mode="CHECK";message="Choose MEANT A, MEANT B or OTHER, then CAPTURE."
        elif which=="TRAIN":
            if library.fit():mode="CHECK"
            message=library.message
        elif which=="REPLAY":
            if library.models[selected].trained:
                replay_model=library.models[selected];replay_time=0;last_beat=-999
                message="PREVIEW %s. No check counted."%selected
            else:message="Train before previewing."
        elif which=="SAVE":
            message="Saved this revision separately." if library.save_file(model_path)==OK else "Save failed."
        elif which in ["IMPORT","LOAD"]:
            if library.load_file(import_path if which=="IMPORT" else model_path):
                mode="CHECK";message="Model loaded. Earlier checks kept under their own version."
            else:message="Invalid/missing model; current data kept."
        elif which=="EXPORT":
            message="Checks + model snapshots exported locally." if journal.export_file(export_path)==OK else "Export failed; history kept."
        elif which=="CLEAR":
            if Time.get_ticks_msec()<clear_until:
                journal.clear();clear_until=0;message=journal.message
            else:clear_until=Time.get_ticks_msec()+4000;message="Press CLEAR again within four seconds. EXPORT first to retain a file."
    update_totals();draw_phrase();refresh()

func begin_phrase() -> void:
    if mode=="CHECK" and intent not in Evaluation.INTENTS:
        message="Declare your intention BEFORE capture.";return
    super.begin_phrase()
    if capturing:locked_model=Evaluation.digest(library.snapshot())

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    var declared:=intent;var version:=locked_model
    stop()
    if mode=="TEACH":
        library.add_example(selected,take);message=library.message
    elif version!=Evaluation.digest(library.snapshot()):
        message="Model changed during capture. Nothing counted."
    else:
        var row:Dictionary=journal.record(library,take,declared)
        result={} if row.is_empty() else row.result.duplicate(true)
        message=journal.message
    update_totals()

func refresh() -> void:
    # Parent ready calls this before our panel and matrix are in the tree.
    readout.text="CHECK / %s / teaching target %s\n"%[mode,selected]
    readout.text+="Intention: %s / A %d takes / B %d\n"%[intent if intent!="" else "choose before capture",library.models.A.examples.size(),library.models.B.examples.size()]
    readout.text+=message+"\n8 beats / 120 BPM / no automatic retraining"
    matrix_display.visible=not capturing and replay_time<0
    if totals.is_empty() or matrix_cells.size()!=12:return
    for i in 3:
        for j in 4:matrix_cells[i*4+j].text=str(totals.matrix[i][j])
    matrix_footer.text="%d this model / %d earlier\nColumns = model answer / counts, not a dance score"%[totals.total,totals.previous]
