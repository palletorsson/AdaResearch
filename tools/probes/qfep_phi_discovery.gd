extends "res://tools/probes/foundations_reconstruction_museum.gd"

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    var original := find_scene("/phi_slider.gd")
    var pattern := find_scene("/transforming_pattern.gd")
    check("installed signed control and pattern found",original!=null and pattern!=null)
    if original==null:return
    observations.original=xyz(hall.to_local(original.global_position))
    observations.rotation=xyz(original.rotation)
    observations.pattern=xyz(hall.to_local(pattern.global_position))
    observations.clear_bays=[]
    for x in range(2,17,2):
        for z in range(3,24,3):
            for yaw:float in [0.0,PI/2.0,PI,-PI/2.0]:
                var at:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                if placeable(at):observations.clear_bays.append({"at":xyz(at.origin),"yaw":yaw})
    observations.settings={"phi":original.phi,"sign_study":original.sign_study,"emitting":original._particles.emitting}
    await snapshot("existing",original.to_global(Vector3(0.25,1.2,3)),original.to_global(Vector3(0.25,0.1,0)),65)
