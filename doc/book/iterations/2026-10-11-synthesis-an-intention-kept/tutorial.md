# Synthesis — an intention and an answer

## Learning elements

- Carry the sphere, the two-hand capture and the trained A/B phrase library.
- Declare intention before inference; keep it out of the classifier.
- Count A, B, UNKNOWN and AMBIGUOUS separately.
- Keep fresh checks separate from teaching and preview.
- Keep each result beside the exact model and take that produced it.
- Revise teaching deliberately, then evaluate with new performances.

## The same sphere, a different question

Sequence Memory asked which taught phrase a fresh movement resembles. Generative asked how another path could be produced from recorded variation. Here we ask whether the recogniser's answer agrees with what you meant to perform. A plausible generated path does not establish that agreement. We return to the saved A/B recogniser; we do not train it on generated output.

Keep all eight files from [Perception](../ML_Perception/tutorial.md), [Sequence Memory](../ML_Sequence_Memory/tutorial.md) and [Generative](../ML_Generative/tutorial.md). Add the two files printed below. synthesis_study.gd extends sequence_study.gd, where the A/B recogniser and recording loop live. This branch reuses the same PointBody, pickup, beat and both-hand paths. It adds a journal and controls; it does not build a different sphere or a new classifier.

In the ordinary museum the full CHECK station remains in Perception. Run res://doc/book/studies/ml-lineage/Synthesis.tscn to place your printed study in the actual Synthesis hall beside its existing exhibits. synthesis_museum.gd is the supplied room launcher. Camera, lighting, XR tracking, XR Tools pickup and RackTemplates buttons remain declared project infrastructure. Put the new files beside the carried ones in res://doc/book/studies/ml-lineage/. Across hall loads, class and saved data carry; one live node is not yet transported between scenes.

## Bring the model, then declare an intention

In Sequence Memory, select A or B and SAVE the trained library. Here IMPORT reads user://ada_student_phrase_ab_v1.json without overwriting it. If you have no saved library, use TEACH A and CAPTURE at least three takes, then TEACH B and CAPTURE three more. TRAIN fits both and enters CHECK. Teaching target means where examples go; it does not supply an inference answer.

Choose CHECK, then MEANT A, MEANT B or OTHER. OTHER means you intend neither taught phrase. It is your declaration, not a third trained class. Press CAPTURE. Keep the same comfortable phrase timing: a three-second count-in followed by four seconds, eight beats at 120 BPM. Both hands are recorded in the same six head-relative coordinates as before.

During the take, the intention and model are locked. The model sees the measured movement only. After prediction, the journal joins the answer to your declaration. It then clears the intention, so the next take needs a new choice. STOP or lost tracking discards the whole pending take and its intention. Neither counts as UNKNOWN: no valid inference happened.

CHECK does not move the sphere in response to a classification. REPLAY is still a preview of the selected teaching phrase; it adds no check. During capture the preview paths and count table are hidden. SOUND toggles the click. The result is a comparison you can inspect before deciding what to change.

## Read the table

Rows are what you declared: A, B or OTHER. Columns are what the model returned: A, B, UNKNOWN or AMBIGUOUS. Each completed, admissible take adds one to one cell.

- Meant A, answered A: agreement for this take under this model.
- Meant A, answered B: a mismatch to investigate.
- Meant A, answered UNKNOWN: neither prototype accepted it.
- Meant A, answered AMBIGUOUS: both accepted it too similarly to choose.
- Meant OTHER, answered A: something outside your intended labels was accepted as A.

UNKNOWN and AMBIGUOUS are not interchangeable. Neither is a verdict that your movement is bad. Intention is also not unquestionable ground truth: you could press the wrong button, change your mind or perform differently from what you intended. Keep the discrepancy visible before assigning its cause.

The table shows **counts for the current model**, plus the number retained under earlier versions. There is no combined accuracy badge. A few repeated personal checks, performed after seeing the previews, do not establish accuracy for other people or independent performances.

## What the journal keeps

Each row contains the declaration, result with distance scores, whole timed take, take identifier and model identifier. The model snapshot includes both teaching sets, fitted paths, tolerances and ambiguity policy. Its digest is a compact identifier computed from that saved data. It identifies this local snapshot; it does not certify that a model is true, or replace the code version needed to reproduce its behaviour.

The journal refuses an exact teaching take and refuses to count the same exact take twice under the same model, even under another intention. That catches accidental reuse. It cannot prove independence or detect every near-duplicate. A changed model may be compared against a kept take, but that is a repeated comparison, not a new performance. Our normal CHECK flow records a new performance every time.

EXPORT writes the complete journal, including model snapshots and takes, to user://ada_student_synthesis_checks_v1.json. It stays local. A later EXPORT overwrites that file, so copy it if you need several sessions. At 120 records the journal refuses more until you export and clear. CLEAR requires a second press within four seconds; it leaves teaching and exported files alone. Closing the scene loses unexported checks. This small lesson exports evidence; it does not import an old evaluation journal.

## Revise without erasing the question

After a mismatch, EXPORT. Choose TEACH A or TEACH B, record a deliberate **new** teaching performance and TRAIN. This invalidates the old fit before changing it. Return to CHECK and make new performances. The old rows stay linked to their earlier snapshot; the visible table counts the current one. If the full snapshot is identical, it is the same version for this journal.

SAVE writes the revised A/B library to user://ada_student_synthesis_ab_v1.json; LOAD reads that file. The earlier hall's file is only read by IMPORT. A failed load leaves the current model intact. Neither fitting, importing nor previewing changes the journal's earlier observations. Checking never calls fit or add_example.

The existing anomaly exhibit provides a comparison. Its default score sums absolute displacement from the sample mean after scaling each coordinate by its spread. A threshold raises some points. That is a rule relative to a reference population, not a check against a visitor's declared intention. Keep these questions separate when moving between the exhibits.

## Complete journal

Read record first. It checks the declaration and duplicate rules, calls predict with only the take, then stores the declaration alongside the returned result. summary groups recorded outcomes by model identifier. This is an evaluation layer over the learner you already built.

<!-- student-code:phrase_evaluation.gd -->
```gdscript
extends RefCounted
## Visitor-declared intent is evaluation data; it never enters prediction or training.
const MAX_RECORDS := 120
const INTENTS := ["A", "B", "OTHER"]
const OUTCOMES := ["A", "B", "UNKNOWN", "AMBIGUOUS"]
var records: Array = []
var models: Dictionary = {}
var message := "Choose an intention before recording a fresh take."

static func digest(value: Variant) -> String:
	return JSON.stringify(value,"",true,true).sha256_text()

func record(model: RefCounted, take: Array, intent: String) -> Dictionary:
	if intent not in INTENTS: message="Choose A, B or OTHER before capturing.";return {}
	if not model.trained: message="Train both phrases before checking.";return {}
	if records.size()>=MAX_RECORDS: message="120 checks kept. EXPORT, then CLEAR to continue.";return {}
	var data: Dictionary = model.snapshot()
	var version := digest(data)
	var take_id := digest(take)
	for label in ["A","B"]:
		for example: Array in data[label].examples:
			if digest(example)==take_id: message="That exact take was teaching data. Record a fresh performance.";return {}
	for row: Dictionary in records:
		if row.model_id==version and row.take_id==take_id:
			message="That exact take is already counted for this model.";return {}
	# Only measured movement reaches the classifier. Intent is attached afterwards.
	var result: Dictionary = model.predict(take)
	if result.is_empty(): message="Incomplete or invalid take; nothing counted.";return {}
	var row := {"model_id":version,"take_id":take_id,"intent":intent,"result":result.duplicate(true),"take":take.duplicate(true)}
	models[version]=data.duplicate(true)
	records.append(row)
	message="Meant %s / model said %s. One whole take counted."%[intent,result.label]
	return row.duplicate(true)

func summary(model: RefCounted) -> Dictionary:
	var version := digest(model.snapshot())
	var matrix := [[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	var count := 0
	for row: Dictionary in records:
		if row.model_id!=version: continue
		matrix[INTENTS.find(row.intent)][OUTCOMES.find(row.result.label)]+=1
		count+=1
	return {"matrix":matrix,"total":count,"previous":records.size()-count,"model_id":version}

func snapshot() -> Dictionary:
	return {"schema":"ada-phrase-checks-1","intent_labels":INTENTS,"result_labels":OUTCOMES,"models":models.duplicate(true),"records":records.duplicate(true),"scope":"Visitor-declared intent; repeated personal checks, not an independent accuracy estimate. No automatic training."}

func clear() -> void:
	records.clear();models.clear();message="Check history cleared. Teaching data and saved files remain."

func export_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()
```

## Extend the museum study

The host locks intention at the start, records the current model identifier and checks it again at completion. A model changed during a take cannot silently become the basis of that check. The inherited capture still discards incomplete tracking.

<!-- student-code:synthesis_study.gd -->
```gdscript
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
```

## Test the separation

First predict the answer to this experiment. Feed the same held-out fixture to two identical models, once with intention A and once with intention B, using separate empty journals. The prediction must stay the same; only the table row may change. If the answer follows the declared label, the check is leaking its answer into inference.

Then teach deliberately similar A and B phrases and collect a fresh in-between performance. Keep AMBIGUOUS as its own column. Perform a clearly displaced phrase to investigate UNKNOWN. Inspect the per-hand distances in the export; a different intention does not alter them.

Finally keep an earlier journal, change the teaching set, TRAIN and check again. Earlier rows must still reference their own model. No bad result should disappear when a fit improves. The ghost reconstruction tests these boundaries, exact teaching/duplicate rejection, interrupted takes, saving and exporting, real button signals and the same sphere in the native hall. Synthetic tests do not settle human recognition or comfort.

The sequence leaves us with several operations and their evidence: selection, fitting, grouping, recognition, generation and evaluation. For this study, keep the model, source takes, check records and relevant code revision together. Foundations Crisis follows: what has the experiment established, and what have we supplied for it to do so?
