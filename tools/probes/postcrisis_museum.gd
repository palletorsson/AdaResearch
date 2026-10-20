extends "res://tools/probes/foundations_reconstruction_museum.gd"
const STUDENT = "res://doc/book/iterations/2026-10-12-postcrisis-reconstruction/learner/"
const RECORD = "res://doc/book/iterations/2026-10-12-postcrisis-reconstruction/native-student-pose.json"
const NOTE = "res://doc/book/iterations/2026-10-12-postcrisis-reconstruction/native-student-observation.json"
const HALL_KEYS = {"CriticalAlgorithms_Algorithmic_Bias_Visualization":"bias","CriticalAlgorithms_Applied_Ethics":"ethics","SpeculativeComputation_Paraconsistent_Engineering":"conflict","SpeculativeComputation_Situated_Computation":"situated","SpeculativeComputation_Collective_Knowledge":"collective","SpeculativeComputation_Rhizome_Network":"rhizome","AdvancedLaboratory_Lab_Equipment_Simulation":"assembly","PostCrisis_Synthesis":"synthesis"}
const SUBJECT = {"bias":"/bias_from_inside.gd","ethics":"/room_shape_demonstrator.gd","conflict":"/merge_conflict_visualizer.gd","situated":"/situated_readout.gd","collective":"/peer_production_tool.gd","rhizome":"/rhizome_grower.gd","assembly":"/MolecularDesigner.gd","synthesis":"/accountability_ledger.gd"}

func landing_checks() -> void:
    var start := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps");museum.call("_drain_cartridge_nodes");await tick()
    var key: String = HALL_KEYS[map_id]
    var original := find_scene(SUBJECT[key])
    check("existing teaching artifact remains",original!=null)
    if original==null: return
    var launcher = load("res://doc/book/studies/postcrisis-lineage/"+key+"_museum.gd")
    if key=="assembly" and FileAccess.file_exists(RECORD): DirAccess.remove_absolute(ProjectSettings.globalize_path(RECORD))
    if key=="assembly" and FileAccess.file_exists(NOTE): DirAccess.remove_absolute(ProjectSettings.globalize_path(NOTE))
    var config: Dictionary = {"record_path":RECORD,"note_path":NOTE} if key in ["assembly","synthesis"] else {}
    var study = launcher.mount(hall,load(STUDENT+key+"_study.gd"),config)
    await tick()
    var exclude: Array[RID] = []
    for body in study.find_children("*","CollisionObject3D",true,false): exclude.append(body.get_rid())
    var clear := placeable(study.transform,exclude)
    check("working copy has supported clear approach",clear)
    observations["mount"] = {"position":xyz(study.position),"yaw":study.rotation.y}
    observations["original_local"] = xyz(hall.to_local(original.global_position))
    check("working copy is inside requested museum hall",study.get_parent()==hall)
    var scene = load("res://doc/book/studies/postcrisis-lineage/"+key+".tscn").instantiate()
    check("F6 scene loads declared launcher",scene.get_script()==launcher)
    scene.free()
    await tick()
    observations["fixed_launcher"] = true
    observations["tested_code"] = {}
    for name in DirAccess.get_files_at(STUDENT):
        if name.ends_with(".gd"): observations.tested_code[STUDENT+name] = FileAccess.get_sha256(STUDENT+name)
    observations.tested_code[launcher.resource_path] = FileAccess.get_sha256(launcher.resource_path)
    var sight := PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.8,1.85)),study.to_global(Vector3(0,1.9,-.8)),1)
    sight.exclude = exclude
    check("supported viewing position sees readout without a wall",hall.get_world_3d().direct_space_state.intersect_ray(sight).is_empty())
    var point_id = study.point.get_instance_id()
    await snapshot("opening",study.to_global(Vector3(0,1.8,1.85)),study.to_global(Vector3(0,1.45,0)),84)
    match key:
        "bias":
            await drag_point(study,Vector3(.8,1.2,.55))
            observations["hand_compression"] = study.model.amount
            check("hand compresses authored positions",absf(study.model.amount-1)<.001)
            check("compression retains all six words",study.positions.size()==6)
        "ethics":
            study.buttons[1].pressed.emit()
            check("ring control changes layout only",study.circle and study.positions.size()==6)
            var seats = study.positions.duplicate()
            check("original centre criterion accepts ring",study.model.accepts(study.positions,study.minimum_gap))
            study.buttons[3].pressed.emit()
            check("new centre criterion rejects unchanged ring",not study.model.accepts(study.positions,study.minimum_gap) and study.positions==seats)
            await viewport_checks()
        "conflict":
            study.buttons[1].pressed.emit()
            check("selecting branch retains both source records",study.model.selected==0 and study.model.records.size()==2)
        "situated":
            for i in 2: study.buttons[0].pressed.emit()
            study.buttons[1].pressed.emit()
            check("cover conceals address without deleting it",study.covered and study.model.read(2,false).source=="SW")
        "collective":
            for i in 3: study.buttons[0].pressed.emit()
            study.buttons[1].pressed.emit();study.buttons[2].pressed.emit()
            check("revision retains three pieces two sources",study.model.revisions==1 and study.model.pieces.size()==3 and study.model.sources.size()==2)
        "rhizome":
            for i in 22: study.buttons[0].pressed.emit()
            study.buttons[1].pressed.emit()
            check("one-link forest readout has two groups",study.model.components()==2)
            study.buttons[3].pressed.emit();study.buttons[3].pressed.emit()
            check("cut and restore retain positions and graph",study.model.points.size()==24 and study.model.components()==2)
        "assembly":
            study.prediction = "Synthetic prediction: rerouting the hand will keep one connected body."
            study.buttons[4].pressed.emit()
            check("prediction recorded before any body edit",study.notes.read(NOTE).before.edits==0)
            await drag_point(study,study.display_position(study.model.graph.points[6]+Vector3.UP*.3))
            study.buttons[1].pressed.emit()
            await drag_point(study,study.display_position(study.model.graph.points[1]))
            check("real hand adapters produce saved changed body",study.storage.read(RECORD).ok and study.model.edits==2)
            check("changed relation isolates the hand",study.model.graph.edges[5]==Vector2i(4,1) and study.model.graph.components()==2)
            observations["saved_record"] = study.model.pack()
            observations["saved_prediction"] = study.notes.read(NOTE)
        "synthesis":
            check("new process reads preceding hall record",study.model!=null and study.model.edits==2)
            if study.model!=null:
                check("returned body retains changed relation",study.model.graph.edges[5]==Vector2i(4,1) and study.model.displaced()==1)
                observations["read_record"] = study.model.pack()
            var bytes := FileAccess.get_file_as_string(RECORD)
            study.buttons[1].pressed.emit();study.buttons[0].pressed.emit()
            check("reading retains file bytes",FileAccess.get_file_as_string(RECORD)==bytes)
            observations["read_prediction"] = study.notes.read(NOTE)
            study.observation = "Synthetic observation: the hand became a separate connected component."
            study.keep_reason = "Synthetic reason: keep this version to compare position with connection."
            study.buttons[2].pressed.emit()
            var note = study.notes.read(NOTE)
            check("note finishes a prediction from the preceding process",note.complete and note.before.edits==0 and note.after.edits==2)
            check("note preserves disconfirmed prediction",note.prediction.contains("one connected body") and note.observation.contains("separate connected component"))
            check("note matches returned body without rewriting pose",study.notes.matches(note,study.model) and FileAccess.get_file_as_string(RECORD)==bytes)
            observations["completed_note"] = note
    for i in 3: await tick()
    check("same point instance remains",point_id==study.point.get_instance_id())
    check("release returns marker to model",study.point.position.distance_to(study.point_home)<.001)
    await snapshot("result",study.to_global(Vector3(0,1.8,1.85)),study.to_global(Vector3(0,1.45,0)),84)
    check("rendered marker agrees with selected model position",study.point.position.distance_to(study.point_home)<.001)
    await snapshot("hall",study.to_global(Vector3(0,3.8,4.2)),study.global_position+Vector3.UP,72)
    observations["scope"] = "Exact printed study in real isolated hall. Synthetic buttons and desktop-hand adapters; not on-headset reach, independent learner understanding or full-route verification."

func viewport_checks() -> void:
    var packed = load("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
    var first = packed.instantiate()
    var second = packed.instantiate()
    root.add_child(first)
    root.add_child(second)
    await tick()
    var a = first.get_node("Screen").get_active_material(0)
    var b = second.get_node("Screen").get_active_material(0)
    check("viewport screen receives its own live texture",a.albedo_texture==first.get_node("Viewport").get_texture())
    check("second viewport keeps separate material and texture",a!=b and a.albedo_texture!=b.albedo_texture and b.albedo_texture==second.get_node("Viewport").get_texture())
    first.queue_free()
    second.queue_free()

func drag_point(study, target: Vector3) -> void:
    var hand := Node3D.new()
    root.add_child(hand)
    study.point.on_desktop_grab(hand)
    for i in 6:
        study.point.global_position = study.to_global(target)
        await tick()
    observations["last_drag"] = {"held":study.point.held(),"local":xyz(study.point.position),"can_process":study.can_process(),"processing":study.is_processing()}
    study.point.on_desktop_drop(hand)
    for i in 3: await tick()
    hand.queue_free()

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("POSTCRISIS MUSEUM ",map_id," ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
