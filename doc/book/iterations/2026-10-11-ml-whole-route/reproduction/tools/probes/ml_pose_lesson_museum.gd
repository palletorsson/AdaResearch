extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    var stage := find_scene("/vogue_timeline.gd")
    check("existing dance and learning anchor present", stage != null)
    if stage == null: return
    stage.set_process(false)
    stage.render_pose(8.0)
    var old := stage.get_node("PoseLearningStation") as Node3D
    var old_transform := old.global_transform
    var launcher = load("res://doc/book/studies/ml-lineage/perception_museum.gd")
    var printed = load("res://doc/book/iterations/2026-10-11-perception-teach-a-sphere/learner/printed/pose_study.gd")
    var study: Node3D = launcher.mount(hall, printed)
    await tick()
    study.set_process(false)
    check("printed study occupies existing museum anchor",study.global_transform.is_equal_approx(old_transform))
    check("full station hidden only in lesson preview",not old.visible and old.process_mode==Node.PROCESS_MODE_DISABLED)
    var collisions_off:=true
    for body in old.find_children("*","CollisionObject3D",true,false):
        collisions_off=collisions_off and body.collision_layer==0 and body.collision_mask==0
    check("hidden full-station controls cannot intercept lesson interaction",collisions_off)
    check("preview starts empty with carried sphere",study.model.examples.is_empty() and study.sphere.has_method("is_picked_up"))
    check("native floor supports visitor before console",not floor_at(study.to_global(Vector3(0,0,1.6))).is_empty())
    check("ten controls present",study.panel.find_children("Btn_*","Node",true,false).size()==10)
    await snapshot("lesson",study.to_global(Vector3(0.4,1.7,3.1)),study.to_global(Vector3(0,1.65,-0.2)),62)
    await snapshot("room",stage.to_global(Vector3(4,20,12)),stage.to_global(Vector3(3,0,2)),60)
    # Rehearsal fixture explicitly supplied after empty-state captures.
    var centres := [[-0.6,0.15,-0.45,0.6,0.15,-0.45],[-0.22,0.85,-0.4,0.22,0.85,-0.4],[-0.25,-0.65,-0.75,0.25,-0.65,-0.75]]
    for label in 3:
        for take in 5:
            var row: Array=centres[label].duplicate()
            for i in 6:row[i]+=sin(float(take*7+i*3))*0.045
            study.model.add_example(row,label)
    study.command("TRAIN")
    for i in 150:study._process(0)
    check("printed learner trains in actual museum",study.model.trained and study.mode=="TEST")
    study.command("LIVE")
    for i in 8:study.respond(0.05,centres[2],true)
    study.message="SYNTHETIC REHEARSAL / C";study.refresh()
    check("learned C changes mesh without replacing point",study.response==2 and study.surface.scale.y>1)
    await snapshot("response",study.to_global(Vector3(0.4,1.7,3.1)),study.to_global(Vector3(0,1.65,-0.2)),62)
    observations["scope"]="Exact printed code mounted in real museum. Empty captures first, then explicitly supplied synthetic examples. Not a headset trial."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
    print("POSE MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
