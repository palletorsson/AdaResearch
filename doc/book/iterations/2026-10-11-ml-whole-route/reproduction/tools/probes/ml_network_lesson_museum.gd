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
    var original:=find_scene("/neural_network_visualization.gd")
    check("original network and architecture diagrams retained",original!=null and find_scene("/NeuralNetworks_VR.gd")!=null)
    if original!=null:
        original._stop_training()
        observations["original"]={"inputs":original.training_data[0],"target":original.target_data[0],"training_rows":original.training_data.size()}
        check("original diagram visibly discloses its answer-bearing inputs",original.info_display.is_visible_in_tree() and original.info_display.text.contains("ANSWER ALREADY IN THE INPUT"))
        var panel:Node3D=original.get_node("InputAudit")
        check("low disclosure panel present on actual diagram",panel.get_node("Disclosure").is_visible_in_tree())
        var ground:=floor_at(Vector3(panel.global_position.x,hall.global_position.y,panel.global_position.z))
        check("disclosure stands above the actual museum floor",not ground.is_empty() and panel.global_position.y-ground.position.y>1.0 and panel.global_position.y-ground.position.y<2.0)
        observations["audit_position"]=xyz(panel.global_position)
        var panel_in_hall:Transform3D=hall.global_transform.affine_inverse()*panel.global_transform
        check("disclosure panel clears museum architecture",native_clear(panel_in_hall,Vector3.ZERO,Vector3(3.6,1.25,0.1)))
        var eye:=panel.to_global(Vector3(0,0.1,3))
        var unobscured:=true
        var obstructions:Array=[]
        for x:float in [-1.7,0,1.7]:
            for y:float in [-0.5,0,0.5]:
                var ray:=PhysicsRayQueryParameters3D.create(eye,panel.to_global(Vector3(x,y,0.05)),1)
                var hit:=panel.get_world_3d().direct_space_state.intersect_ray(ray)
                if not hit.is_empty():
                    unobscured=false
                    obstructions.append({"point":[x,y],"collider":str(hit.collider.get_path()),"position":xyz(hit.position)})
        check("standing view sees the whole disclosure without a wall",unobscured)
        observations["audit_obstructions"]=obstructions
        await snapshot("input-audit",eye,panel.global_position,65)
    var script_paths:Array=[]
    for n in hall.find_children("*","Node3D",true,false):
        if n.get_script()!=null:
            var p:String=n.get_script().resource_path
            if "neural" in p.to_lower() or "finetun" in p.to_lower() or "fine_tun" in p.to_lower():script_paths.append(p)
    observations["exhibit_scripts"]=script_paths
    var printed=load("res://doc/book/iterations/2026-10-11-networks-what-a-weight-keeps/learner/printed/network_study.gd")
    var launcher=load("res://doc/book/studies/ml-network/network_museum.gd")
    var study:Node3D=launcher.mount(hall,printed);study_root=study
    await tick();study.set_process(false)
    check("printed study attached to actual Neural Networks hall",study.get_parent()==hall and study.model.weights.size()==13)
    var fits:=native_clear(study.transform,Vector3(0,1.9,0.2),Vector3(4.1,2.7,2.5))
    var clear:=stance_ok(study.transform)
    check("table diagram and readout clear native architecture",fits)
    check("teaching stance has level floor and clear body space",clear)
    if not fits or not clear:
        var candidates:Array=[]
        for x in range(3,12):
            for z in range(2,25):
                for yaw:float in [0,PI/2,PI,-PI/2]:
                    var t:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                    if stance_ok(t) and native_clear(t,Vector3(0,1.9,0.2),Vector3(4.1,2.7,2.5)):candidates.append([x,z,yaw])
        observations["clear_candidates"]=candidates
    var point=study.point
    await snapshot("opening",study.to_global(Vector3(0,1.85,2.8)),study.to_global(Vector3(0,1.8,0)),75)
    await snapshot("hall",hall.to_global(Vector3(7,23,29)),hall.to_global(Vector3(7,0,12)),65)
    press(study,0)
    check("STEP signal updates actual model once",study.model.epoch==1 and study.model.loss()<0.68527)
    press(study,1)
    for i in 101:study._process(0.016)
    press(study,4)
    check("TRAIN reaches limit and stops",study.model.epoch==1000 and not study.running)
    check("CHECK uses separate inputs without additional updates",study.check_result.correct==4 and study.check_result.loss<0.01 and study.model.epoch==1000)
    observations["fitted"]={"training_loss":study.model.loss(),"check":study.check_result.duplicate(true)}
    await snapshot("fitted",study.to_global(Vector3(0,1.85,2.8)),study.to_global(Vector3(0,1.8,0)),75)
    var retained:PackedFloat64Array=study.model.weights.duplicate()
    press(study,3)
    for i in 5:await tick()
    check("same sphere follows selected input across native frames",point==study.point and point.position.distance_to(study.place(study.probe))<0.001)
    check("EXAMPLE changes query without changing fitted weights",study.probe==Vector2(-0.8,0.8) and study.model.weights==retained)
    await snapshot("probe",study.to_global(Vector3(0,1.85,2.8)),study.to_global(Vector3(0,1.8,0)),75)
    var pointer:=Node3D.new();root.add_child(pointer)
    point.on_desktop_grab(pointer);point.global_position=study.to_global(Vector3(-0.816,2,-0.312));study._process(0.1)
    check("native grab changes only local input",study.probe.distance_to(Vector2(0.3,-0.4))<0.001 and study.model.weights==retained)
    point.on_desktop_drop(pointer);study._process(0.1);pointer.queue_free()
    for i in 5:await tick()
    check("release retains query and restores sphere height",absf(point.position.y-1.03)<0.001)
    press(study,5);press(study,1)
    for i in 101:study._process(0.016)
    press(study,4)
    check("reversed convention also fits inside actual museum",study.model.flipped and study.check_result.correct==4 and study.check_result.loss<0.01)
    await snapshot("flipped",study.to_global(Vector3(0,1.85,2.8)),study.to_global(Vector3(0,1.8,0)),75)
    observations["scope"]="Actual hall and printed code; fixed synthetic inputs and desktop hand adapter. Human headset reach and comfort untested. Existing exhibits retained."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("NETWORK MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
