extends SceneTree
const BASE = "res://doc/book/iterations/2026-10-12-postcrisis-reconstruction/learner/"
const OUT = "res://doc/book/iterations/2026-10-12-postcrisis-reconstruction/"
const PATH = OUT+"synthetic-student-pose.json"
const NOTE = OUT+"synthetic-student-observation.json"
const KEYS = ["bias","ethics","conflict","situated","collective","rhizome","assembly","synthesis"]
var checks: Array = []
var failures: Array = []

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed: failures.append(label)
    print("POSTCRISIS ","PASS " if passed else "FAIL ",label)
    assert(passed,label)

func frames(n: int = 3) -> void:
    for i in n: await physics_frame; await process_frame

func run() -> void:
    for key in KEYS:
        var suite = load(BASE+"assert_"+key+".gd").new()
        suite.run()
        for result in suite.checks: check(key+" / "+result.name,result.passed)
    if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    if FileAccess.file_exists(NOTE): DirAccess.remove_absolute(ProjectSettings.globalize_path(NOTE))
    for key in KEYS:
        var study = load(BASE+key+"_study.gd").new()
        if key in ["assembly","synthesis"]:
            study.record_path = PATH
            study.note_path = NOTE
        root.add_child(study)
        study.position = Vector3(4,2,3)
        study.rotation.y = .6
        await frames()
        var point_id = study.point.get_instance_id()
        check(key+" / initialized label",study.readout!=null and not study.readout.text.is_empty())
        match key:
            "bias":
                study.buttons[2].pressed.emit()
                check("bias / actual compress signal",is_equal_approx(study.model.amount,1))
                await drag(study,Vector3(0,1.2,.55))
                check("bias / hand measured in rotated local frame",is_equal_approx(study.model.amount,.5))
            "ethics":
                study.buttons[1].pressed.emit()
                check("ethics / actual ring signal",study.circle and study.positions.size()==6)
                var seats = study.positions.duplicate()
                check("ethics / initial criterion accepts ring",study.model.accepts(study.positions,study.minimum_gap))
                study.buttons[3].pressed.emit()
                check("ethics / changed criterion rejects unchanged ring",not study.model.accepts(study.positions,study.minimum_gap) and study.positions==seats)
            "conflict":
                study.buttons[1].pressed.emit()
                check("conflict / selection retains conflict",study.model.selected==0 and study.model.records.size()==2 and study.model.support("door-1@12:00","open")==Vector2i(1,1))
            "situated":
                study.buttons[0].pressed.emit();study.buttons[1].pressed.emit()
                check("situated / covered display preserves source",study.covered and study.model.claims.records[1].source=="NE")
            "collective":
                for i in 3: study.buttons[0].pressed.emit()
                study.buttons[1].pressed.emit();study.buttons[2].pressed.emit()
                check("collective / revision is not another piece",study.model.revisions==1 and study.model.pieces.size()==3)
            "rhizome":
                for i in 5: study.buttons[0].pressed.emit()
                study.buttons[1].pressed.emit()
                check("rhizome / forest survives visible control",study.model.links==1 and study.model.components()==2)
            "assembly":
                study.prediction = "Test prediction: rerouting the hand will keep one connected body."
                study.buttons[4].pressed.emit()
                check("assembly / prediction control saves before editing",study.notes.read(NOTE).before.edits==0)
                var destination: Vector3 = study.model.graph.points[6]+Vector3.UP*.3
                await drag(study,study.display_position(destination))
                check("assembly / local release edits selected hand",study.model.edits==1 and study.model.graph.points[6].distance_to(destination)<.00001)
                check("assembly / actual release writes disk",study.storage.read(PATH).ok and not study.storage.read(PATH).empty)
                study.buttons[1].pressed.emit()
                await drag(study,study.display_position(study.model.graph.points[1]))
                check("assembly / hand release changes relation",study.model.graph.edges[5]==Vector2i(4,1) and study.model.graph.components()==2)
            "synthesis":
                check("synthesis / independently instantiated reader keeps handoff",study.model!=null and study.model.edits==2 and study.model.graph.edges[5]==Vector2i(4,1))
                var bytes := FileAccess.get_file_as_string(PATH)
                study.buttons[1].pressed.emit()
                await drag(study,Vector3(1,1.3,.4))
                check("synthesis / reading and selecting do not change source file",FileAccess.get_file_as_string(PATH)==bytes)
                study.observation = "Test observation: the hand became a separate connected component."
                study.keep_reason = "Test reason: keep this version to compare position with connection."
                var pending := FileAccess.get_file_as_string(NOTE)
                var external = study.storage.read(PATH).body
                external.move_joint(6,external.graph.points[6]+Vector3.UP*.1)
                study.storage.save(external,PATH)
                study.buttons[2].pressed.emit()
                check("synthesis / changed disk pose refuses note until reread",study.note_message.contains("READ") and FileAccess.get_file_as_string(NOTE)==pending)
                study.storage.save(study.model,PATH)
                study.buttons[2].pressed.emit()
                var note = study.notes.read(NOTE)
                check("synthesis / note control completes the carried prediction",note.complete and note.before.edits==0 and note.after.edits==2)
                check("synthesis / recorded observation keeps the wrong prediction",note.prediction.contains("one connected body") and note.observation.contains("separate connected component"))
                check("synthesis / note belongs to current pose and preserves pose bytes",study.notes.matches(note,study.model) and FileAccess.get_file_as_string(PATH)==bytes)
        await frames()
        check(key+" / same carried sphere survives",study.point.get_instance_id()==point_id)
        check(key+" / released point returns to model position",study.point.position.distance_to(study.point_home)<.0001)
        study.queue_free()
        await frames()
    FileAccess.open(OUT+"ghost-results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code and supplied point adapters; author-operated simulation, no headset claim."},"  "))
    quit(0 if failures.is_empty() else 1)

func drag(study, target: Vector3) -> void:
    var hand := Node3D.new()
    root.add_child(hand)
    study.point.on_desktop_grab(hand)
    study.point.global_position = study.to_global(target)
    await frames()
    study.point.on_desktop_drop(hand)
    await frames()
    hand.queue_free()
