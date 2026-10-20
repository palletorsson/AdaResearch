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
        for z:float in [1.9,2.2,2.5]:
            var p:=hall.to_global(t*Vector3(x,0,z));var hit:=floor_at(p)
            if hit.is_empty() or absf(hit.position.y-p.y)>0.04:return false
    return native_clear(t,Vector3(0,0.94,2.2),Vector3(1.3,1.75,0.8))

func landing_checks() -> void:
    var start:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps");museum.call("_drain_cartridge_nodes");await tick()
    check("deferred museum exhibits finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var comparator:=find_scene("/loss_function_comparator.gd")
    var race:=find_scene("/gradient_descent_visualization.gd")
    check("existing loss comparator and optimizer race retained",comparator!=null and race!=null)
    if comparator!=null:
        observations["comparator"]={"samples":comparator._data_x.size(),"surfaces":comparator._terrains.size(),"tail":comparator.tail}
    var printed=load("res://doc/book/iterations/2026-10-11-gradient-a-line-and-a-loss/learner/printed/gradient_study.gd")
    var launcher=load("res://doc/book/studies/ml-gradient/gradient_museum.gd")
    var study:Node3D=launcher.mount(hall,printed);study_root=study
    await tick();study.set_process(false)
    check("printed line fit belongs to actual Gradient hall",study.get_parent()==hall and study.fit.data.size()==5)
    var fits:=native_clear(study.transform,Vector3(-0.2,1.9,0.1),Vector3(4.4,2.3,2.9))
    var clear:=stance_ok(study.transform)
    check("surface and observations clear native walls",fits)
    check("teaching stance has level floor and clear body space",clear)
    if not fits or not clear:
        var candidates:Array=[]
        for x in range(3,11):
            for z in range(2,23):
                for yaw:float in [0,PI/2,PI,-PI/2]:
                    var t:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                    if stance_ok(t) and native_clear(t,Vector3(-0.2,1.9,0.1),Vector3(4.4,2.3,2.9)):candidates.append([x,z,yaw])
        observations["clear_candidates"]=candidates
    var point=study.point
    await snapshot("opening",study.to_global(Vector3(0,2.35,4.6)),study.to_global(Vector3(-0.15,1.65,-0.1)),58)
    await snapshot("hall",hall.to_global(Vector3(6,20,25)),hall.to_global(Vector3(6,0,10)),65)
    var button=study.find_child("Btn_5",true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)
    check("actual OUTLIER signal changes one observation",study.outlier and study.fit.data[4]==Vector2(1,4.7))
    for i in 1500:
        if not study.fit.step():break
    study.redraw();var mse:Vector2=study.fit.p
    await snapshot("mse",study.to_global(Vector3(0,2.35,4.6)),study.to_global(Vector3(-0.15,1.65,-0.1)),58)
    check("paused MSE point remains on its fitted parameter height after native frames",point.position.distance_to(study.surface_position(study.fit.p)+Vector3.UP*0.085)<0.001)
    button=study.find_child("Btn_4",true,false).get_node("InteractableAreaButton");button.button_pressed.emit(button)
    check("actual HUBER control keeps parameters for score comparison",study.fit.p==mse and study.fit.robust)
    study.command("RESET")
    for i in 1500:
        if not study.fit.step():break
    study.redraw();var huber:Vector2=study.fit.p
    check("rendered comparison matches two distinct line fits",mse.distance_to(Vector2(2.1,1))<0.005 and huber.distance_to(Vector2(1.5,0.7))<0.008)
    check("same carried point survives the comparison",study.point==point)
    await snapshot("huber",study.to_global(Vector3(0,2.35,4.6)),study.to_global(Vector3(-0.15,1.65,-0.1)),58)
    check("paused Huber point remains on its fitted parameter height after native frames",point.position.distance_to(study.surface_position(study.fit.p)+Vector3.UP*0.085)<0.001)
    var pointer:=Node3D.new();root.add_child(pointer)
    point.on_desktop_grab(pointer);point.global_position=study.to_global(Vector3(1.08,2,0.13));study._process(0.1)
    check("native hand adapter sets both local parameters",study.fit.p.distance_to(Vector2(0.5,0.5))<0.001 and not study.running)
    point.on_desktop_drop(pointer);study._process(0.1);pointer.queue_free()
    observations["fits"]={"mse":[mse.x,mse.y],"huber":[huber.x,huber.y],"outlier":true}
    observations["scope"]="Actual hall with printed code and synthetic fit; desktop hand adapter. Human VR and wider room arrangement untested."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("GRADIENT MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
