extends "res://tools/probes/wavefunctions_surface_museum.gd"

func landing_checks() -> void:
    await super.landing_checks()
    var origin := hall.global_position+Vector3(0,0,4)
    var landscape := find_scene("/algorithms/wavefunctions/sine_space/SineSpace.gd")
    var centre: float = landscape.walk_floor.global_position.x-origin.x
    var left: float = centre-landscape.walk_width/2
    var right: float = centre+landscape.walk_width/2
    var space := hall.get_world_3d().direct_space_state
    for z in [17.1,20.0,26.0,32.0,34.9]:
        for x in [left-0.5,right+0.5,right+1.5,right+2.5]:
            var query := PhysicsRayQueryParameters3D.create(origin+Vector3(x,20,z),origin+Vector3(x,-1,z),1)
            var hit := space.intersect_ray(query)
            check("solid bypass wall at %s" % Vector2(x,z),not hit.is_empty() and hit.position.y-origin.y>2.5)
    var walker: CharacterBody3D= museum.get("_player")
    check("real museum walker exists",walker!=null)
    if walker==null:return
    walker.set_process(false);walker.set_physics_process(false)
    var body_origin: Vector3=walker.global_position
    walker.global_position=origin+Vector3(centre,0.1,16)
    walker.velocity=Vector3.ZERO
    var low := 10.0
    var high := -10.0
    var samples: Array=[]
    for frame in range(780):
        await physics_frame
        var delta: float=1.0/Engine.physics_ticks_per_second
        walker.velocity=Vector3(0,0 if walker.is_on_floor() else walker.velocity.y-9.8*delta,2.0)
        walker.move_and_slide()
        var p := walker.global_position-origin
        if p.z>=17 and p.z<=35:
            low=minf(low,p.y);high=maxf(high,p.y)
            if frame%12==0:samples.append(xyz(p))
        if p.z>=36:break
    check("walker crosses wave floor and reaches far landing",walker.global_position.z-origin.z>=35.8)
    check("walker feels more than one metre of vertical range",high-low>1.0)
    check("far landing restores ground height",absf(walker.global_position.y-origin.y)<0.15)
    observations.walk={"samples":samples,"lowest":low,"highest":high,"end":xyz(walker.global_position-origin),"scope":"Actual museum CharacterBody; input script paused, controlled forward velocity through move_and_slide; no headset comfort claim."}
    for x in [left-0.5,right+1.5]:
        walker.global_position=origin+Vector3(x,0.1,16)
        walker.velocity=Vector3.ZERO
        for frame in range(80):
            await physics_frame
            walker.velocity=Vector3(0,0 if walker.is_on_floor() else walker.velocity.y-9.8/Engine.physics_ticks_per_second,2.0)
            walker.move_and_slide()
        check("walker cannot use old flat bypass at x=%s" % x,walker.global_position.z-origin.z<17)
    walker.global_position=body_origin;walker.velocity=Vector3.ZERO
    await snapshot("crossing",origin+Vector3(centre,1.7,17.2),origin+Vector3(centre,0.5,31),71)
    await snapshot("walls-above",origin+Vector3(centre-3,12,14),origin+Vector3(centre,0,27),72)
    observations.scope="Actual museum floor and solid side walls; controlled walking crosses the folds and both old bypasses are physically blocked. Headset comfort untested."
