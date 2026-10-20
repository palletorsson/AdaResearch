extends SceneTree
## Cross-hall file boundaries, using only the freshly extracted printed classes.
const FOLDER := "res://doc/book/iterations/2026-10-11-ml-whole-route/"
const Fixture = preload("res://tools/probes/movement_fixture.gd")
var checks: Array = []
var failures: Array = []
var largest_roundtrip_difference := 0.0

func same_after_json(a: Variant, b: Variant) -> bool:
    if (a is float or a is int) and (b is float or b is int):
        var difference := absf(float(a)-float(b))
        largest_roundtrip_difference=maxf(largest_roundtrip_difference,difference)
        return is_finite(float(a)) and is_finite(float(b)) and difference<1e-12
    if a is Dictionary and b is Dictionary:
        if a.size()!=b.size(): return false
        for key in a:
            if not b.has(key) or not same_after_json(a[key],b[key]): return false
        return true
    if a is Array and b is Array:
        if a.size()!=b.size(): return false
        for i in a.size():
            if not same_after_json(a[i],b[i]): return false
        return true
    return a==b

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed: failures.append(label)
    print("HANDOFF ","PASS " if passed else "FAIL ",label)

func press(study: Node, index: int) -> void:
    var button = study.panel.find_child("Btn_%d" % index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)

func mount(chapter: String, script: String) -> Node3D:
    var study: Node3D = load(FOLDER+"learner/"+chapter+"/"+script).new()
    root.add_child(study)
    study.set_process(false)
    return study

func run() -> void:
    var one_path := FOLDER+"handoff-fixtures/one.json"
    var ab_path := FOLDER+"handoff-fixtures/ab.json"
    var memory := mount("ML_Sequence_Memory","sequence_study.gd")
    for v in 3:
        memory.one.add_example(Fixture.take(v))
        memory.library.add_example("A",Fixture.take(v))
        memory.library.add_example("B",Fixture.take(v,true))
    check("Memory fits three ONE takes and three per A/B",memory.one.fit() and memory.library.fit())
    var one_data: Dictionary = memory.one.snapshot()
    var ab_data: Dictionary = memory.library.snapshot()
    check("Memory saves both real JSON formats separately",memory.one.save_file(one_path)==OK and memory.library.save_file(ab_path)==OK)
    var original_one := FileAccess.get_file_as_bytes(one_path)
    var original_ab := FileAccess.get_file_as_bytes(ab_path)
    var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(one_path))
    check("File contains all 81 timestamps and six coordinates per take",source.examples.size()==3 and source.examples[0].size()==81 and source.examples[0][40].t==2.0 and source.examples[0][40].x.size()==6)
    var expected: Dictionary = memory.library.predict(Fixture.take(11))
    memory.queue_free(); await process_frame

    var generation := mount("ML_Generative","generative_study.gd")
    var point_id: int = generation.sphere.get_instance_id()
    check("Generative starts with its own body and no silently carried training",generation.one.examples.is_empty() and not generation.generator.trained)
    # The shipped IMPORT uses ONE_FILE. Here its same load_file API reads a private
    # fixture path so the test cannot overwrite a visitor's actual saved phrase.
    check("Generative restores the Memory ONE file through the printed loader",generation.one.load_file(one_path))
    generation.invalidate_generation()
    FileAccess.open(FOLDER+"handoff-fixtures/one-debug.json",FileAccess.WRITE).store_string(JSON.stringify({"before":one_data,"after":generation.one.snapshot()},"  ",true,true))
    check("Recorded takes survive JSON to 1e-12; generated fit still requires FIT",same_after_json(generation.one.snapshot(),one_data) and not generation.generator.trained)
    var imported_one: Dictionary = generation.one.snapshot()
    press(generation,1) # FIT
    check("Actual FIT signal creates a generator from the carried recordings",generation.generator.trained and generation.generator.residuals.size()==3)
    press(generation,4) # DRAW
    var generated: Dictionary = generation.generated.duplicate(true)
    press(generation,4)
    check("Same seed repeats after a file handoff",not generated.is_empty() and generation.generated==generated)
    press(generation,5) # NEXT
    check("NEXT changes this varied sample without replacing the sphere",generation.generated.rows!=generated.rows and generation.sphere.get_instance_id()==point_id)
    check("Sampling changes neither teaching takes nor the saved Memory files",generation.one.snapshot()==imported_one and FileAccess.get_file_as_bytes(one_path)==original_one and FileAccess.get_file_as_bytes(ab_path)==original_ab)
    var retained: Dictionary = generation.one.snapshot()
    check("A/B file cannot be misread as ONE or erase the carried phrase",not generation.one.load_file(ab_path) and generation.one.snapshot()==retained)
    generation.queue_free(); await process_frame

    var synthesis := mount("ML_Synthesis","synthesis_study.gd")
    synthesis.import_path=ab_path
    synthesis.export_path=FOLDER+"handoff-fixtures/checks.json"
    point_id=synthesis.sphere.get_instance_id()
    press(synthesis,8) # IMPORT
    FileAccess.open(FOLDER+"handoff-fixtures/ab-debug.json",FileAccess.WRITE).store_string(JSON.stringify({"before":ab_data,"after":synthesis.library.snapshot(),"expected":expected,"actual":synthesis.library.predict(Fixture.take(11)),"mode":synthesis.mode},"  ",true,true))
    check("Synthesis IMPORT button restores the other Memory branch to 1e-12",same_after_json(synthesis.library.snapshot(),ab_data) and synthesis.mode=="CHECK")
    check("Imported A/B keeps fresh-take labels exact and scores within 1e-12",same_after_json(synthesis.library.predict(Fixture.take(11)),expected))
    var imported_ab: Dictionary = synthesis.library.snapshot()
    check("No generated sample has been inserted into either A/B class",synthesis.library.models.A.examples.size()==3 and synthesis.library.models.B.examples.size()==3)
    var record: Dictionary = synthesis.journal.record(synthesis.library,Fixture.take(11),"A")
    check("One fresh check retains its intent, full take and model version",not record.is_empty() and record.intent=="A" and record.take.size()==81 and synthesis.journal.models.has(record.model_id))
    press(synthesis,12) # EXPORT
    var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(synthesis.export_path))
    check("Actual EXPORT saves the check and the model used for it",exported.schema=="ada-phrase-checks-1" and exported.records.size()==1 and exported.models.has(record.model_id))
    check("Checking preserves both original files and the live model",synthesis.library.snapshot()==imported_ab and FileAccess.get_file_as_bytes(one_path)==original_one and FileAccess.get_file_as_bytes(ab_path)==original_ab and synthesis.sphere.get_instance_id()==point_id)
    synthesis.import_path=one_path; press(synthesis,8)
    check("Wrong-branch IMPORT is refused without erasing the current A/B model",synthesis.library.snapshot()==imported_ab and synthesis.message.begins_with("Invalid/missing"))
    synthesis.queue_free(); await process_frame
    var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Real serialized cross-hall handoff using exact printed classes; synthetic trajectories. Memory save and Generative import use the printed component APIs with private fixture paths. Synthesis IMPORT/EXPORT and Generative FIT/DRAW/NEXT use actual button signals. No visitor user:// save file is written. No human VR claim."}
    result["largest_roundtrip_difference"]=largest_roundtrip_difference
    FileAccess.open(FOLDER+"handoff-tests.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    quit(0 if failures.is_empty() else 1)
