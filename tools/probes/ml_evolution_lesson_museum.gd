extends "res://tools/probes/transformation_encounters.gd"
var study_root:Node3D

func body_clear(p:Vector3) -> bool:
    var shape:=CapsuleShape3D.new();shape.radius=0.25;shape.height=1.75
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
    query.transform.origin=p+Vector3.UP*0.94;query.collision_mask=1
    var player:=museum.get_node_or_null("Walker") as CollisionObject3D
    if player!=null:query.exclude=[player.get_rid()]
    return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func furniture_clear(t:Transform3D) -> bool:
    var shape:=BoxShape3D.new();shape.size=Vector3(2.75,1.3,2.95)
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
    query.transform=hall.global_transform*t*Transform3D(Basis.IDENTITY,Vector3(0,1.3,0.25));query.collision_mask=1
    var player:=museum.get_node_or_null("Walker") as CollisionObject3D
    var exclude:Array[RID]=[]
    if player!=null:exclude.append(player.get_rid())
    if study_root!=null:
        for item in study_root.find_children("*","CollisionObject3D",true,false):exclude.append(item.get_rid())
    query.exclude=exclude
    return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func landing_checks() -> void:
    var start:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<30000:
        museum.call("_drain_stamps");museum.call("_drain_cartridge_nodes");await tick()
    check("deferred museum exhibits finished loading",museum.get("_stamp_queue").is_empty() and museum.get("_cartridge_pending_nodes").is_empty())
    var drift:=find_scene("/non_teleological_evolution.gd")
    var creatures:=find_scene("/evolvedcreatures.gd")
    var flowers:=find_scene("/evolvingflowers.gd")
    check("existing live selection and scored comparison exhibits retained",drift!=null and creatures!=null and flowers!=null)
    if drift!=null:
        observations["drift"]={"selection":drift.selection,"cells":drift.grid_resolution*drift.grid_resolution,"population":drift._creatures.size(),"scene":drift.get_script().resource_path}
        check("original population exposes simulation-time renewal",drift._stats_label.is_visible_in_tree() and drift._stats_label.text.contains("2 simulated seconds"))
        var target:=drift.to_global(Vector3(0,0.5,0))
        var eye:=target+Vector3(0,0.5,1.8)
        var visible:=false
        for offset:Vector3 in [Vector3(0,0.6,-1.8),Vector3(-1.8,0.6,0),Vector3(1.8,0.6,0),Vector3(0,0.6,1.8),Vector3(0,2.3,0.1)]:
            var candidate:=target+offset
            var ray:=PhysicsRayQueryParameters3D.create(target,candidate,1)
            if hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
                eye=candidate;visible=true;break
        check("renewal capture has clear architecture sightline",visible)
        observations["renewal_camera"]={"target":xyz(target),"eye":xyz(eye)}
        await snapshot("renewal-clock",eye,target,65)
    var printed=load("res://doc/book/iterations/2026-10-11-evolution-what-keeps-a-body/learner/printed/environment_study.gd")
    var launcher=load("res://doc/book/studies/ml-environment/evolution_museum.gd")
    var study:Node3D=launcher.mount(hall,printed)
    study_root=study
    await tick();study.set_process(false)
    check("printed study belongs to actual Evolution hall",study.get_parent()==hall and study.world.bodies.size()==12)
    var floor_ok:=true;var clear:=true
    for x:float in [-0.5,0.0,0.5]:
        for z:float in [1.95,2.25,2.55]:
            var p:=study.to_global(Vector3(x,0,z))
            var hit:=floor_at(p)
            floor_ok=floor_ok and not hit.is_empty() and absf(hit.position.y-p.y)<0.04
            clear=clear and body_clear(p)
    check("teaching stance has level native floor",floor_ok)
    check("standing capsule clears teaching area",clear)
    var fits:=furniture_clear(study.transform)
    check("table and controls clear native walls",fits)
    if not clear or not floor_ok or not fits:
        var candidates:Array=[]
        for x in range(2,13):
            for z in range(-3,22):
                for yaw:float in [0.0,PI/2,PI,-PI/2]:
                    var t:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z));var good:=true
                    for dx:float in [-0.5,0.0,0.5]:
                        for dz:float in [1.7,2.0,2.3]:
                            var p:=hall.to_global(t*Vector3(dx,0,dz));var h:=floor_at(p)
                            good=good and not h.is_empty() and absf(h.position.y-p.y)<0.04 and body_clear(p)
                    if good and furniture_clear(t):candidates.append([x,z,yaw])
        observations["clear_candidates"]=candidates
    await snapshot("opening",study.to_global(Vector3(0.4,2.6,3.5)),study.to_global(Vector3(0,1.1,0)),56)
    await snapshot("hall",hall.to_global(Vector3(7,20,24)),hall.to_global(Vector3(7,0,9)),65)
    var point=study.point
    for i in 900:study.world.step()
    study.redraw()
    var finite:int=study.world.bodies.size()
    check("finite scene renders a view for every surviving ID",study.views.size()==finite)
    await snapshot("finite",study.to_global(Vector3(0.4,2.6,3.5)),study.to_global(Vector3(0,1.1,0)),56)
    var button=study.find_child("Btn_4",true,false).get_node("InteractableAreaButton")
    button.button_pressed.emit(button)
    check("real RETURN button resets condition and preserves point",study.world.renewal and study.world.ticks==0 and study.point==point)
    for i in 900:study.world.step()
    study.redraw()
    check("renewal scene accounts for every living body",study.views.size()==study.world.bodies.size() and study.world.bodies.size()==study.world.born-study.world.died)
    check("same thirty-second comparison changes surviving population",study.world.bodies.size()!=finite)
    await snapshot("return",study.to_global(Vector3(0.4,2.6,3.5)),study.to_global(Vector3(0,1.1,0)),56)
    observations["thirty_seconds"]={"seed":17,"finite_alive":finite,"return_alive":study.world.bodies.size(),"return_born":study.world.born,"return_died":study.world.died,"return_meals":study.world.meals}
    observations["scope"]="Actual museum with exact printed learner code. Simulated comparison and supplied controls; human headset comfort untested. Original drift exhibit now has fixed simulation timing and an explicit renewal label."

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
    print("EVOLUTION MUSEUM ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
