extends "res://tools/probes/foundations_reconstruction_museum.gd"

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    var original := find_scene("/lambda_hall.gd")
    check("installed lambda hall found",original!=null)
    if original==null:return
    observations.original=xyz(hall.to_local(original.global_position))
    observations.rotation=xyz(original.rotation)
    observations.clear_bays=[]
    for x in range(2,17,2):
        for z in range(3,24,3):
            for yaw:float in [0.0,PI/2.0,PI,-PI/2.0]:
                var at:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                if placeable(at):observations.clear_bays.append({"at":xyz(at.origin),"yaw":yaw})
    observations.settings={"width":original.hall_width,"lambda":original.lambda_value,"recommendation":original.recommendation_position,"controls":original.recommendation_control}
    await snapshot("existing",original.to_global(Vector3(0,3,9)),original.to_global(Vector3(0,1.3,0)),80)
