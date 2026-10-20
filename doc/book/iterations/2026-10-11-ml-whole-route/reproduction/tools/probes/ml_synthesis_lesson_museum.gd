extends "res://tools/probes/transformation_encounters.gd"
const Fixture=preload("res://tools/probes/movement_fixture.gd")

func body_clear(p: Vector3) -> bool:
    var shape:=CapsuleShape3D.new();shape.radius=0.25;shape.height=1.75
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=shape;query.transform.origin=p+Vector3.UP*0.94;query.collision_mask=1
    var walker:=museum.get_node_or_null("Walker") as CollisionObject3D
    if walker!=null:query.exclude=[walker.get_rid()]
    return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func landing_checks() -> void:
    # The shared probe pauses processing at core-ready. Finish the actual
    # deferred exhibit queue before inspecting this hall's contents.
    var start:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    check("deferred museum exhibits finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    await tick()
    var anomaly:=find_scene("/AnomalyDetection.gd")
    var walker:=find_scene("/joint_learn_walk.gd")
    observations["artifact_scripts"]=[]
    for node in hall.find_children("*","Node3D",true,false):
        if node.get_script()!=null:observations["artifact_scripts"].append(str(node.get_script().resource_path))
    observations["outside_artifacts"]=[]
    for node in root.find_children("*","Node3D",true,false):
        if node.get_script()!=null and (str(node.get_script().resource_path).ends_with("/AnomalyDetection.gd") or str(node.get_script().resource_path).ends_with("/joint_learn_walk.gd")):
            observations["outside_artifacts"].append(str(node.get_path()))
    check("existing anomaly and joint-learning exhibits remain",anomaly!=null and walker!=null)
    if anomaly!=null:
        var sample:Dictionary=anomaly.get("_samples")[0]
        var mean:Vector2=anomaly.get("_mean");var spread:Vector2=anomaly.get("_std")
        var p:Vector2=sample.position
        var expected:=absf((p.x-mean.x)/spread.x)+absf((p.y-mean.y)/spread.y)
        check("reflection matches actual default anomaly arithmetic",anomaly.detection_mode==0 and absf(sample.score-expected)<0.00001)
    var printed=load("res://doc/book/iterations/2026-10-11-synthesis-an-intention-kept/learner/printed/synthesis_study.gd")
    var launcher=load("res://doc/book/studies/ml-lineage/synthesis_museum.gd")
    var study:Node3D=launcher.mount(hall,printed)
    await tick();study.set_process(false)
    check("printed study mounted in actual Synthesis hall",study.get_parent()==hall)
    check("empty arrival has no invented checks or models",study.journal.records.is_empty() and not study.library.trained)
    var floor_ok:=true;var clear:=true
    for x:float in [-0.6,0.0,0.6]:
        for z:float in [1.3,1.8,2.3]:
            var p:=study.to_global(Vector3(x,0,z))
            var hit:=floor_at(p)
            floor_ok=floor_ok and not hit.is_empty()
            clear=clear and body_clear(p)
    check("teaching stance supported by native museum floor",floor_ok)
    check("standing player capsule clears teaching area",clear)
    if not clear:
        var shape:=CapsuleShape3D.new();shape.radius=0.25;shape.height=1.75
        var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
        observations["collisions"]=[]
        for x:float in [-0.6,0.0,0.6]:
            for z:float in [1.3,1.8,2.3]:
                query.transform.origin=study.to_global(Vector3(x,0,z))+Vector3.UP*0.94
                for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):observations["collisions"].append(str(hit.collider.get_path()))
        var available:Array=[]
        for x in range(2,12):
            for z in range(5,14):
                for yaw:float in [0.0,PI/2,PI,-PI/2]:
                    var transform:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                    var okay:=true
                    for dx:float in [-0.6,0.0,0.6]:
                        for dz:float in [1.3,1.8,2.3]:
                            var p:=hall.to_global(transform*Vector3(dx,0,dz))
                            okay=okay and not floor_at(p).is_empty() and body_clear(p)
                    if okay:available.append([x,z,yaw])
        observations["clear_study_candidates"]=available
    await snapshot("empty",study.to_global(Vector3(0.3,1.8,3.1)),study.to_global(Vector3(0,1.7,-0.2)),62)
    await snapshot("hall",hall.to_global(Vector3(6.5,20,24)),hall.to_global(Vector3(6.5,0,9)),65)
    for v in 3:
        study.library.add_example("A",Fixture.take(v))
        study.library.add_example("B",Fixture.take(v,true))
    study.command("TRAIN")
    var kept:Dictionary=study.library.snapshot()
    study.command("MEANT B")
    check("declared intention has its own field",study.intent=="B" and study.library.snapshot()==kept)
    study.capturing=true;study.phrase_time=-0.05;study.pending.clear();study.sample_time=0
    study.locked_model=study.Evaluation.digest(study.library.snapshot())
    for row:Dictionary in Fixture.take(11):study.advance_phrase(0.05,row.x,true)
    study.draw_phrase();study.refresh()
    check("fresh synthetic A stays an A answer despite declared B",study.result.label=="A" and study.journal.records[0].intent=="B" and study.totals.matrix[1][0]==1)
    check("checking keeps sphere still and model unchanged",study.replay_time<0 and study.library.snapshot()==kept and study.intent=="")
    for v in 3:
        var declaration:String=["A","B","OTHER"][v]
        var take:Array=Fixture.take(v+21,v==1)
        if v==2:
            for row:Dictionary in take:row.x[1]+=1;row.x[4]+=1
        study.journal.record(study.library,take,declaration)
    study.update_totals();study.refresh()
    check("table displays counts for current model and distinguishes refusals",study.totals.matrix==[[1,0,0,0],[1,1,0,0],[0,0,1,0]] and study.matrix_display.visible)
    await snapshot("checks",study.to_global(Vector3(0.3,1.8,3.1)),study.to_global(Vector3(0,1.7,-0.2)),62)
    var old:Dictionary=study.journal.snapshot()
    study.library.add_example("A",Fixture.take(50));study.command("TRAIN")
    check("revision retains earlier check records separately",study.totals.total==0 and study.totals.previous==4 and study.journal.snapshot()==old)
    await snapshot("revision",study.to_global(Vector3(0.3,1.8,3.1)),study.to_global(Vector3(0,1.7,-0.2)),62)
    observations["scope"]="Exact-print Synthesis study in actual museum; empty arrival then explicit synthetic fixtures. No human or headset validation."


func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
    print("SYNTHESIS MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
