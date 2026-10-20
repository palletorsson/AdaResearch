extends "res://doc/book/iterations/2026-09-28-disco-colour-in-step/probe.gd"
var student_completed := false

func landing_checks()->void:
    await super.landing_checks()
    if not completed:return
    var player= museum.get("_player")
    if player is Node3D:
        player.hide();player.set_process(false);player.set_physics_process(false)
        player.global_position=Vector3(0,-100,0)
    if driver:
        driver.release();driver.set_physics_process(false)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var study=load(spec.lesson).new()
    study.position=Vector3(14.5,0,7.0)
    hall.add_child(study);study.set_process(false)
    var foot:Vector3=study.to_global(Vector3(0,0,2.5))
    var support:=floor_at(foot)
    check("learner approach is supported",not support.is_empty() and absf(support.position.y-foot.y)<.05)
    var shape:=CapsuleShape3D.new();shape.height=1.7;shape.radius=.28
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=shape;query.collision_mask=1|4;query.transform.origin=foot+Vector3.UP*.88
    check("learner approach has standing clearance",hall.get_world_3d().direct_space_state.intersect_shape(query,4).is_empty())
    await create_timer(.3).timeout
    check("carried point stays at its authored local position",study.control.position.is_equal_approx(Vector3(0,1,1.9)))
    await snapshot("student-pink",study.to_global(Vector3(0,2.2,3.0)),study.to_global(Vector3(0,1,.7)),54)
    var geometry:Array=[]
    for i in 25:geometry.append(study.grid.instances.get_instance_transform(i))
    study.palettes[1].colours.assign([Color(.4,.4,.4),Color(.4,.4,.4)])
    study.paint()
    var before_value:int=study.value_at(Vector2i.ZERO)
    study.step()
    check("grey-pair step still exchanges the underlying value",study.value_at(Vector2i.ZERO)==1-before_value)
    var grey:=true;var same:=true
    for address in study.grid.cells:
        var c:Color=study.grid.read(address)
        grey=grey and absf(c.r-.4)<.005 and absf(c.g-.4)<.005 and absf(c.b-.4)<.005
    for i in 25:same=same and study.grid.instances.get_instance_transform(i).is_equal_approx(geometry[i])
    check("grey colour hides pattern without moving geometry",grey and same)
    await snapshot("student-grey",study.to_global(Vector3(0,2.2,3.0)),study.to_global(Vector3(0,1,.7)),54)
    await grip_check(study)
    observations["student"]={"temporary_host_hall_local":[14.5,0,7],"yaw":0,"printed_source":spec.lesson,"scope":"Printed study added temporarily to existing museum; changed pair exercised separately. Simulated grip, no headset claim."}
    study.queue_free()
    student_completed=true

func finish()->void:
    check("printed student reconstruction completed",student_completed)
    super.finish()

func grip_check(study:Node3D)->void:
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
    controller.add_child(pickup)
    controller.global_transform=study.control.global_transform
    study.control.pick_up(pickup)
    await tick()
    controller.global_position=study.to_global(Vector3(-.6,1.15,1.9))
    for i in 6:await tick()
    check("point follows hand into the palette region",study.control.is_picked_up() and study.control.position.x<-.3 and study.control.global_position.distance_to(controller.global_position)<.05)
    var phase_before:int=study.phase
    study.control.action()
    check("held left trigger selects next pair at same phase",study.palette_index==2 and study.phase==phase_before)
    controller.global_position=study.to_global(Vector3(.6,1.15,1.9))
    for i in 6:await tick()
    study.control.action()
    check("held right trigger starts the local clock",study.playing)
    study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
    await tick()
    check("control stays frozen after release",study.control.freeze and not study.control.is_picked_up())
    origin.queue_free()
