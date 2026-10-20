extends "res://tools/probes/foundations_reconstruction_museum.gd"

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    var original := find_scene("/edge_of_chaos_unlocked.gd")
    check("installed paired calculation found",original!=null)
    if original==null:return
    original.set_process(false)
    original.restart()
    for i in 200:original._advance_tick()
    original._update_texture()
    observations.original=xyz(hall.to_local(original.global_position))
    observations.rotation=xyz(original.rotation)
    observations.clear_bays=[]
    var original_bounds: AABB = museum.call("_seat_extent",original)
    observations.original_bounds={"at":xyz(original_bounds.position),"size":xyz(original_bounds.size)}
    for xi in range(22,31):
        for zi in range(10,35):
            var x := xi*0.5
            var z := zi*0.5
            for yaw:float in [0.0,PI/2.0,PI,-PI/2.0]:
                var at:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                var bench_box: AABB = hall.global_transform*at*AABB(Vector3(-1.48,0.88,-0.98),Vector3(2.96,1.7,1.96))
                if not bench_box.intersects(original_bounds) and placeable(at):observations.clear_bays.append({"at":xyz(at.origin),"yaw":yaw})
    observations.settings={"lambda":original.lambda,"comparison":original.comparison_study,"grid":original.grid_size,"time":original.model_time,"rms":original.comparison_error()}
    await snapshot("existing",original.to_global(Vector3(0,2.3,2.1)),original.to_global(Vector3(0,1.4,0)),85)
