extends "res://tools/probes/shader_pink_museum.gd"
var study:Node3D
func run()->void:
    var launcher=load("res://doc/book/studies/shaders-lineage/pink_museum.gd")
    root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(115).timeout.connect(func():quit(98))
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
    museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
    launcher.configure(museum,output+"learner_control.json")
    var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output+"learner_control.json"))
    check(settings.first_map=="Shader_12_PinkExtravaganza" and not settings.has("travel") and not settings.has("resume_eye"),"Launcher creates a separate Pink entry without stale travel")
    museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
    while not bool(museum.get("_museum_core_ready")):await process_frame
    museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
    for node in museum.get_children():
        if node is Node3D and str(node.get_meta("em_map",""))=="Shader_12_PinkExtravaganza":hall=node
    check(hall!=null,"Actual Pink museum hall loads")
    if hall==null:quit(1);return
    var old:Camera3D=museum.get("_cam")
    if old:
        for timer in old.find_children("*","Timer",true,false):timer.stop()
    study=launcher.mount(hall,launcher.LESSON)
    check(study!=null,"Launcher mounts exact printed program beside composition stage")
    if study==null:quit(1);return
    stage=study.get_parent();origin=stage.global_position-hall.global_basis*Vector3(27.5,0,8.5)
    camera=Camera3D.new();root.add_child(camera);await tick()
    check(study.control.is_inside_tree() and study.readout.is_inside_tree() and study.cube.is_inside_tree(),"Learner source creates its own point, cube and label")
    check(study.amounts.is_equal_approx(Vector3(1,.6,.3)),"Rotated hall preserves local opening amounts")
    check(study.find_children("*","Camera3D",true,false).is_empty(),"Learner uses the museum's camera")
    var retained:Array=[]
    for receiver in stage.receivers:retained.append([receiver,receiver.mesh,receiver.global_transform,receiver.material_override])
    var lamps:Array=[]
    for lamp in stage.lights:lamps.append([lamp,lamp.global_transform,lamp.light_energy])
    var supported:=true;var clear:=true;var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.24
    var path:Array[Vector3]=[Vector3(0,0,6.5),Vector3(5.8,0,6.5),Vector3(6.45,0,6.3),Vector3(7.2,0,6.3),Vector3(7.2,0,4.4)]
    for i in range(1,path.size()):
        var n:=ceili(path[i-1].distance_to(path[i])/.25)
        for j in range(n+1):
            var p:Vector3=stage.to_global(path[i-1].lerp(path[i],float(j)/n))
            var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.3,p-Vector3.UP*.7,1);ray.exclude=[museum.get("_player").get_rid()]
            supported=supported and not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
            var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.86;query.exclude=ray.exclude
            var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
            for hit in hits:print("BLOCKED ",hit.collider.get_path()," at ",stage.to_local(p))
            clear=clear and hits.is_empty()
    check(supported,"Learner approach has floor support every .25m")
    check(clear,"Standing body clears learner approach, hand position and side")
    var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
    hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
    check(study.control.is_picked_up(),"Actual point accepts simulated XR pickup")
    hand.global_position=study.to_global(Vector3(-.35,1.2,1.2));await tick()
    check(study.amounts.distance_to(Vector3(0,.6,.3))<.01,"Hand movement along local X removes only dots")
    hand.global_position=study.to_global(Vector3(.65,.6,1.2));await tick()
    check(study.amounts.distance_to(Vector3(1,0,.3))<.01,"Hand movement along local Y removes only rim")
    hand.global_position=study.to_global(Vector3(.65,1.2,.9));await tick()
    check(study.amounts.distance_to(Vector3(1,.6,0))<.01,"Hand movement along local Z removes only glow")
    hand.global_position=study.to_global(Vector3(.25,1.1,1.4));await tick()
    var chosen:Vector3=study.amounts;study.control.action();await tick()
    check(study.mode==0 and study.material.get_shader_parameter("amounts")==Vector3.ZERO and study.amounts.distance_to(chosen)<.01,"Held action compares BASE without losing chosen amounts")
    study.control.action();await tick()
    check(study.mode==1 and study.material.get_shader_parameter("amounts").distance_to(chosen)<.01,"Second held action restores composition")
    study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check(study.control.freeze and not study.control.is_picked_up(),"Release freezes the carried point")
    await create_timer(.2).timeout
    check(study.amounts.distance_to(chosen)<.01,"Released recipe stays held")
    check(retained.all(func(r):return r[0].mesh==r[1] and r[0].global_transform==r[2] and r[0].material_override==r[3]),"Student controls leave the production bodies and material unchanged")
    check(lamps.all(func(l):return l[0].global_transform==l[1] and is_equal_approx(l[0].light_energy,l[2])),"Production lamps remain unchanged")
    var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(-.6,.9,1)),study.to_global(Vector3(-.6,.9,-1)),1)
    var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
    check(not hit.is_empty() and hit.collider==study.cube,"Learner cube retains collision inside the hall")
    hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
    hand.global_position=study.to_global(Vector3(.65,1.2,1.2));await tick()
    study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);xr.queue_free();await tick()
    check(study.amounts.distance_to(Vector3(1,.6,.3))<.01,"Returning the point restores the opening recipe")
    museum.get("_player").hide()
    var offset:Vector3=study.position
    await photo("composed",offset+Vector3(1.25,1.65,3.1),offset+Vector3(-.2,1.05,.25),65)
    study.control.action();await tick()
    await photo("base",offset+Vector3(1.25,1.65,3.1),offset+Vector3(-.2,1.05,.25),65)
    study.control.action();await tick()
    await photo("in-the-hall",Vector3(7.8,3.1,7),Vector3(1.6,1.5,-1),88)
    stage.act("SETTING");await photo("studio",Vector3(7.8,3.1,7),Vector3(1.6,1.5,-1),88)
    stage.act("SETTING")
    var passed:bool=checks.all(func(c):return c.passed)
    var f:=FileAccess.open(output+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Exact learner files mounted through supplied launcher in actual Pink hall; synthetic XR and collision/approach checks. Teacher-authored; no independent student, physical headset, manual F6 or onward-travel claim."},"\t"));f.close();quit(0 if passed else 1)
