extends SceneTree
const Folder:="res://doc/book/iterations/2026-10-11-synthesis-an-intention-kept/"
const Evaluation=preload(Folder+"learner/printed/phrase_evaluation.gd")
const Library=preload(Folder+"learner/printed/phrase_library.gd")
const Fixture=preload("res://tools/probes/movement_fixture.gd")
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    if not ok:failures.append(label)
    print("SYNTHESIS ","PASS " if ok else "FAIL ",label)

static func offset_take(amount:float,variation:int=11) -> Array:
    var take:=Fixture.take(variation)
    for row:Dictionary in take:row.x[1]+=amount;row.x[4]+=amount
    return take

static func taught(overlap:bool=false) -> RefCounted:
    var lib:=Library.new()
    for v in 3:
        lib.add_example("A",Fixture.take(v))
        lib.add_example("B",offset_take(0.04,v) if overlap else Fixture.take(v,true))
    lib.fit();return lib

func run() -> void:
    var lib:=taught();var journal:=Evaluation.new()
    var take:=Fixture.take(11)
    var frozen:Dictionary=lib.snapshot();var frozen_take:=take.duplicate(true)
    check("empty journal begins with a three-by-four zero matrix",journal.summary(lib).matrix==[[0,0,0,0],[0,0,0,0],[0,0,0,0]])
    check("undeclared intent cannot be counted",journal.record(lib,take,"").is_empty() and journal.records.is_empty())
    check("unknown declaration refused",journal.record(lib,take,"C").is_empty())
    check("unfitted library refused",journal.record(Library.new(),take,"A").is_empty())
    check("incomplete take is not an UNKNOWN inference",journal.record(lib,take.slice(0,25),"A").is_empty() and journal.records.is_empty())
    check("exact A teaching performance cannot count as fresh",journal.record(lib,lib.models.A.examples[0],"A").is_empty())
    check("exact B teaching performance refused under OTHER too",journal.record(lib,lib.models.B.examples[0],"OTHER").is_empty())
    var row:Dictionary=journal.record(lib,take,"A")
    check("held-out A joins declaration to independently predicted A",row.intent=="A" and row.result==lib.predict(take) and row.result.label=="A")
    check("complete take and exact model snapshot retained",row.take==take and journal.models[row.model_id]==frozen and row.take_id==Evaluation.digest(take))
    check("one check increments exactly one cell",journal.summary(lib).matrix==[[1,0,0,0],[0,0,0,0],[0,0,0,0]])
    check("same exact take cannot be relabelled and counted again",journal.record(lib,take,"B").is_empty() and journal.records.size()==1)
    var second:=Evaluation.new();var other:=second.record(lib,take,"B")
    check("same take with different intent keeps identical inference",other.result==row.result and other.intent!=row.intent and second.summary(lib).matrix==[[0,0,0,0],[1,0,0,0],[0,0,0,0]])
    journal.record(lib,Fixture.take(12,true),"B")
    journal.record(lib,Fixture.take(13),"B")
    journal.record(lib,offset_take(1,14),"A")
    journal.record(lib,Fixture.take(15),"OTHER")
    check("agreements mismatches refusals and OTHER acceptance keep separate cells",journal.summary(lib).matrix==[[1,0,1,0],[1,1,0,0],[1,0,0,0]])
    check("checking changes no learner parameters or learner test buffer",lib.snapshot()==frozen and lib.tests.is_empty() and lib.models.A.tests.is_empty() and take==frozen_take)
    row.take[0].x[0]=99;row.result.clear()
    check("returned record cannot corrupt stored take or result",journal.records[0].take==take and journal.records[0].result.has("label"))
    var overlap:=taught(true);var amb:=journal.record(overlap,offset_take(0.02),"A")
    check("AMBIGUOUS remains distinct from UNKNOWN",amb.result.label=="AMBIGUOUS" and journal.summary(overlap).matrix==[[0,0,0,1],[0,0,0,0],[0,0,0,0]])
    check("summary filters by exact model version",journal.summary(overlap).total==1 and journal.summary(overlap).previous==5 and journal.summary(lib).total==5)
    var old_records:=journal.records.duplicate(true);var old_models:=journal.models.duplicate(true)
    lib.add_example("A",offset_take(0.08,20));lib.fit()
    check("changed teaching has a distinct model identifier",Evaluation.digest(lib.snapshot())!=Evaluation.digest(frozen))
    check("refitting starts new-model counts without erasing earlier checks",journal.summary(lib).total==0 and journal.summary(lib).previous==6 and journal.records==old_records and journal.models==old_models)
    var repeated:Dictionary=journal.record(lib,take,"A")
    check("same kept take may compare a different model but is visibly the same take",not repeated.is_empty() and repeated.take_id==journal.records[0].take_id and repeated.model_id!=journal.records[0].model_id)
    var exported:="user://ada_synthesis_journal_test_fixture.json"
    check("real local export succeeds",journal.export_file(exported)==OK)
    var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(exported))
    check("export contains all versioned rows model snapshots and declared schema",saved.schema=="ada-phrase-checks-1" and saved.records.size()==7 and saved.models.size()==3 and saved.intent_labels==Evaluation.INTENTS and saved.result_labels==Evaluation.OUTCOMES)
    check("exported model can restore same numerical inference",restored_prediction(saved.models[repeated.model_id],take).label==repeated.result.label)
    var copy:=journal.snapshot();copy.records.clear();copy.models.clear()
    check("export snapshot is not mutable access to live evidence",journal.records.size()==7 and journal.models.size()==3)
    var retained_model:Dictionary=lib.snapshot();journal.clear()
    check("clearing journal leaves model and exported file intact",journal.records.is_empty() and journal.models.is_empty() and lib.snapshot()==retained_model and FileAccess.file_exists(exported))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(exported))
    var capped:=Evaluation.new();var counted:=true
    for i in 120:counted=counted and not capped.record(lib,Fixture.take(i+100),"A").is_empty()
    check("capacity keeps 120 complete records",counted and capped.records.size()==120)
    check("capacity never silently drops older evidence",capped.record(lib,Fixture.take(500),"A").is_empty() and capped.records.size()==120)
    evidence={"first_model_matrix":[[1,0,1,0],[1,1,0,0],[1,0,0,0]],"separate_ambiguous_model_matrix":[[0,0,0,1],[0,0,0,0],[0,0,0,0]],"scope":"Deterministic synthetic held-out performances; declarations are not human ground truth."}
    await scene_checks()
    FileAccess.open(Folder+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed exact-print reconstruction, not a blind reader. Synthetic trajectories and supplied XR trackers; no human accuracy or comfort claim."},"  "))
    quit(0 if failures.is_empty() else 1)

func restored_prediction(data:Dictionary,take:Array) -> Dictionary:
    var lib:=Library.new()
    if not lib.restore(data):return {}
    return lib.predict(take)

func press(study:Node3D,index:int) -> void:
    var button=study.panel.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)

func perform(study:Node3D,take:Array) -> void:
    study.capturing=true;study.phrase_time=-0.05;study.pending.clear();study.sample_time=0
    study.locked_model=Evaluation.digest(study.library.snapshot())
    for row:Dictionary in take:study.advance_phrase(0.05,row.x,true)
    study.draw_phrase();study.refresh()

func scene_checks() -> void:
    var script=load(Folder+"learner/printed/synthesis_study.gd")
    var study=script.new();root.add_child(study);await process_frame;study.set_process(false)
    var point_id:int=study.sphere.get_instance_id()
    var pose:Dictionary=study.model.snapshot()
    study.import_path="user://ada_synthesis_import_fixture.json"
    study.model_path="user://ada_synthesis_model_fixture.json"
    study.export_path="user://ada_synthesis_export_fixture.json"
    check("empty arrival keeps one PointBody and sixteen controls",study.sphere.has_method("is_picked_up") and study.panel.find_children("Btn_*","Node",true,false).size()==16 and study.journal.records.is_empty())
    press(study,6)
    check("capture requires intention before starting",not study.capturing and study.intent=="" and study.message.begins_with("Declare"))
    var fitted:=taught();fitted.save_file(study.import_path)
    press(study,8)
    check("IMPORT restores saved A+B without invented examples",study.library.trained and study.library.models.A.examples.size()==3 and study.mode=="CHECK")
    var frozen:Dictionary=study.library.snapshot()
    press(study,4);perform(study,Fixture.take(11))
    check("MEANT B with an A performance records an uncorrected mismatch",study.result.label=="A" and study.journal.records[0].intent=="B" and study.totals.matrix[1][0]==1)
    check("completion clears intention and withholds sphere actuation",study.intent=="" and study.locked_model=="" and study.replay_time<0 and not study.rods[0].visible and study.sphere.position.is_equal_approx(Vector3(0,1.15,0.15)))
    check("checking does not fit or change pose model",study.library.snapshot()==frozen and study.model.snapshot()==pose)
    press(study,6)
    check("next check needs a fresh explicit intention",not study.capturing)
    press(study,3);study.capturing=true;study.pending=[{"t":0,"x":Fixture.coordinates(0)}]
    press(study,4);press(study,7);press(study,8)
    check("capture locks declaration fitting and loading",study.intent=="A" and study.library.snapshot()==frozen and study.capturing)
    study.advance_phrase(0.2,Fixture.coordinates(0),true)
    check("long frame discards partial take and clears intention",not study.capturing and study.intent=="" and study.pending.is_empty() and study.journal.records.size()==1)
    press(study,3);study.capturing=true;study.pending=Fixture.take(12);study.locked_model="stale"
    study.complete_phrase()
    check("external model change during a take refuses evidence",study.journal.records.size()==1 and study.message.begins_with("Model changed"))
    press(study,4);study.capturing=true;study.pending=[{"t":0,"x":Fixture.coordinates(0)}]
    study.advance_phrase(0.05,[],false)
    check("lost tracking is not counted as UNKNOWN",study.intent=="" and study.journal.records.size()==1)
    press(study,3);press(study,9)
    check("REPLAY clears pending intention and counts no check",study.replay_time==0 and study.intent=="" and study.journal.records.size()==1)
    var original_rows:Array=study.journal.records.duplicate(true)
    press(study,0);perform(study,offset_take(0.08,20));press(study,7)
    check("new teaching and TRAIN preserve previous evidence",study.library.models.A.examples.size()==4 and study.mode=="CHECK" and study.totals.total==0 and study.totals.previous==1 and study.journal.records==original_rows)
    press(study,5);perform(study,offset_take(1,12))
    check("OTHER fresh check keeps UNKNOWN in its own column",study.result.label=="UNKNOWN" and study.totals.matrix[2][2]==1 and study.intent=="")
    press(study,10);var before_load:Dictionary=study.library.snapshot()
    study.library=taught(true);press(study,11)
    check("SAVE then LOAD restores revision without erasing check journal",study.library.predict(Fixture.take(11)).label=="A" and study.library.models.A.examples.size()==4 and study.journal.records.size()==2)
    FileAccess.open(study.model_path,FileAccess.WRITE).store_string("{bad-json")
    var before_invalid:Dictionary=study.library.snapshot();press(study,11)
    check("invalid saved library cannot replace current model",study.library.snapshot()==before_invalid and study.journal.records.size()==2)
    press(study,12)
    var export:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(study.export_path))
    check("EXPORT button writes complete local journal",export.records.size()==2 and export.models.size()==2)
    press(study,13)
    check("one CLEAR press only arms clearing",study.journal.records.size()==2)
    press(study,2);press(study,13)
    check("another command cancels pending clear confirmation",study.journal.records.size()==2)
    press(study,13)
    check("second consecutive CLEAR clears journal only",study.journal.records.is_empty() and study.library.trained and FileAccess.file_exists(study.export_path))
    await tracked_check(study)
    check("same sphere and inherited pose data survive all operations",study.sphere.get_instance_id()==point_id and study.model.snapshot()==pose)
    for path:String in [study.import_path,study.model_path,study.export_path]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    study.queue_free();await process_frame

func tracked_check(study:Node3D) -> void:
    var origin:=XROrigin3D.new();root.add_child(origin)
    var eye:=Vector3(0,1.6,1.8)
    var head:=XRPositionalTracker.new();head.name=&"head";head.type=XRServer.TRACKER_HEAD
    head.set_pose(&"default",Transform3D(Basis.IDENTITY,eye),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
    XRServer.add_tracker(head)
    var camera:=XRCamera3D.new();origin.add_child(camera)
    var trackers:Array=[]
    for side in [&"left_hand",&"right_hand"]:
        var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
        tr.set_pose(&"default",Transform3D(Basis.IDENTITY,eye+Vector3(0,-0.3,-0.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
        XRServer.add_tracker(tr);trackers.append(tr)
        var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
    await process_frame;await process_frame
    press(study,2);press(study,3);press(study,6)
    check("supplied XR CAPTURE starts count-in with intent and model locked",study.capturing and study.phrase_time==-3 and study.intent=="A" and study.locked_model==Evaluation.digest(study.library.snapshot()))
    for i in 142:
        var x:=Fixture.coordinates(maxf(0,study.phrase_time+0.05),31)
        for hand in 2:
            var at:=eye+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2])*0.65
            trackers[hand].set_pose(&"default",Transform3D(Basis.IDENTITY,at),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
        await process_frame;study._process(0.05)
    check("whole supplied-XR take counted once with both hands and declaration",study.journal.records.size()==1 and study.journal.records[0].intent=="A" and study.journal.records[0].take[-1].t==4 and study.intent=="" and not study.capturing)
    press(study,3);press(study,6);press(study,14)
    check("STOP cancels both pending movement and declaration",not study.capturing and study.intent=="" and study.pending.is_empty() and study.journal.records.size()==1)
    for tr in trackers:XRServer.remove_tracker(tr)
    XRServer.remove_tracker(head);origin.queue_free();await process_frame
