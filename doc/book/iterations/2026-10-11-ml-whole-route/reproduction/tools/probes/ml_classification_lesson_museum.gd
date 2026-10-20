extends "res://tools/probes/transformation_encounters.gd"
var study_root:Node3D

func native_clear(t:Transform3D,where:Vector3,size:Vector3) -> bool:
    var shape:=BoxShape3D.new();shape.size=size
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
    query.transform=hall.global_transform*t*Transform3D(Basis.IDENTITY,where);query.collision_mask=1
    var exclude:Array[RID]=[]
    var player:=museum.get_node_or_null("Walker") as CollisionObject3D
    if player!=null:exclude.append(player.get_rid())
    if study_root!=null:
        for item in study_root.find_children("*","CollisionObject3D",true,false):exclude.append(item.get_rid())
    query.exclude=exclude
    return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func stance_ok(t:Transform3D) -> bool:
    for x:float in [-0.5,0,0.5]:
        for z:float in [2.05,2.3,2.55]:
            var p:=hall.to_global(t*Vector3(x,0,z));var hit:=floor_at(p)
            if hit.is_empty() or absf(hit.position.y-p.y)>0.04:return false
    return native_clear(t,Vector3(0,0.94,2.3),Vector3(1.3,1.75,0.8))

func press(study,index:int) -> void:
    var button=study.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)

func landing_checks() -> void:
    var start:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps");museum.call("_drain_cartridge_nodes");await tick()
    check("deferred museum exhibits finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var original:=find_scene("/enhanced_kmeans.gd")
    var svm:=find_scene("/svm_visualization.gd")
    var forest:=find_scene("/random_forest_visualization.gd")
    check("existing K-means SVM and forest retained",original!=null and svm!=null and forest!=null)
    if original!=null:
        original._lesson_reset()
        observations["original"]={"points":original.data_points.size(),"centres":original.centroids.size(),"natural_clusters":original.natural_cluster_count,"lesson_controls":original._lesson_controls!=null}
    var printed=load("res://doc/book/iterations/2026-10-11-classification-a-group-without-a-name/learner/printed/cluster_study.gd")
    var launcher=load("res://doc/book/studies/ml-classification/classification_museum.gd")
    var study:Node3D=launcher.mount(hall,printed);study_root=study
    await tick();study.set_process(false)
    check("printed study is attached to actual Classification hall",study.get_parent()==hall and study.model.data.size()==12)
    var fits:=native_clear(study.transform,Vector3(0,1.6,0.2),Vector3(3.3,1.8,3.7))
    var clear:=stance_ok(study.transform)
    check("table and readout clear native architecture",fits)
    check("teaching stance has level floor and clear body space",clear)
    if not fits or not clear:
        var candidates:Array=[]
        for x in range(3,12):
            for z in range(2,22):
                for yaw:float in [0,PI/2,PI,-PI/2]:
                    var t:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                    if stance_ok(t) and native_clear(t,Vector3(0,1.6,0.2),Vector3(3.3,1.8,3.7)):candidates.append([x,z,yaw])
        observations["clear_candidates"]=candidates
    var point=study.point;var data:PackedVector2Array=study.model.data.duplicate()
    await snapshot("opening",study.to_global(Vector3(0,2.65,4.9)),study.to_global(Vector3(0,1.2,0)),55)
    await snapshot("hall",hall.to_global(Vector3(7,23,29)),hall.to_global(Vector3(7,0,12)),65)
    press(study,0);var before:float=study.model.score();var centres:PackedVector2Array=study.model.centres.duplicate()
    check("ASSIGN signal sets all twelve groups without moving observations",study.model.groups.size()==12 and study.model.data==data)
    await snapshot("assigned",study.to_global(Vector3(0,2.65,4.9)),study.to_global(Vector3(0,1.2,0)),55)
    press(study,1)
    check("MEAN signal moves centres and lowers current SSE",study.model.centres!=centres and study.model.score()<before and study.model.data==data)
    for i in 8:press(study,0);press(study,1)
    await snapshot("means",study.to_global(Vector3(0,2.65,4.9)),study.to_global(Vector3(0,1.2,0)),55)
    check("sphere follows selected centre after native physics frames",point.position.distance_to(study.place(study.model.centres[study.selected],1.12))<0.001)
    observations["point_after_means"]={"actual":str(point.position),"expected":str(study.place(study.model.centres[study.selected],1.12))}
    press(study,6);press(study,7)
    for i in 10:press(study,0);press(study,1)
    check("RINGS comparison uses four centres on same two ring geometries",study.model.dataset==1 and study.model.data.size()==24 and study.model.k==4)
    check("comparisons retain the same carried sphere",study.point==point)
    await snapshot("rings",study.to_global(Vector3(0,2.65,4.9)),study.to_global(Vector3(0,1.2,0)),55)
    var pointer:=Node3D.new();root.add_child(pointer)
    point.on_desktop_grab(pointer);point.global_position=study.to_global(Vector3(0.375,2,0.5));study._process(0.1)
    check("native hand adapter changes selected centre and clears old colours",study.model.centres[study.selected].distance_to(Vector2(0.3,0.4))<0.001 and study.model.groups.is_empty())
    point.on_desktop_drop(pointer);study._process(0.1);pointer.queue_free()
    check("release returns sphere to table height",absf(point.position.y-1.12)<0.001)
    observations["scope"]="Actual hall with printed code; fixed synthetic data and desktop hand adapter. Human headset reach and comfort untested. Existing exhibits retained."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("CLASSIFICATION MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)

