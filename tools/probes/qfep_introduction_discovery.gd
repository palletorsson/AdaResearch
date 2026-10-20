extends "res://tools/probes/foundations_reconstruction_museum.gd"

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    var original := find_scene("/qfep_balance_workbench.gd")
    check("installed balance workbench found", original != null)
    if original == null: return
    observations.original = xyz(hall.to_local(original.global_position))
    observations.clear_bays = []
    for x in range(-8, 15, 2):
        for z in range(3, 25, 3):
            for yaw: float in [0.0, PI/2.0, PI, -PI/2.0]:
                var at := Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                if placeable(at):
                    observations.clear_bays.append({"at":xyz(at.origin),"yaw":yaw})
    await snapshot("existing",original.global_position+Vector3(3,4,6),original.global_position+Vector3.UP,65)
    await snapshot("overview",hall.to_global(Vector3(8,18,15)),hall.to_global(Vector3(3,0,13)),75)
