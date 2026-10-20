extends "res://tools/probes/foundations_reconstruction_museum.gd"

func landing_checks() -> void:
    var started := Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    var original := find_scene("/qfep_reactor.gd")
    check("installed local wiring found",original!=null and original._wiring_study!=null)
    if original==null:return
    observations.artifacts=[]
    var occupied: Array[AABB]=[]
    for node in hall.get_children():
        if node is Node3D and node.get_script()!=null:
            var bounds: AABB=museum.call("_seat_extent",node)
            occupied.append(bounds)
            observations.artifacts.append({"script":node.get_script().resource_path,"at":xyz(node.position),"rotation":xyz(node.rotation)})
    observations.clear_bays=[]
    for x in range(3,12,2):
        for z in range(4,15,2):
            for yaw:float in [0,PI/2,-PI/2,PI]:
                var at:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                var box:AABB=hall.global_transform*at*AABB(Vector3(-1.48,0.88,-0.98),Vector3(2.96,1.7,1.96))
                var clear:=true
                for bounds in occupied:
                    if box.intersects(bounds):clear=false
                if clear and placeable(at):observations.clear_bays.append({"at":xyz(at.origin),"yaw":yaw})
    await snapshot("existing",original.global_position+Vector3(2,2.2,-5.4),original.global_position+Vector3(0,-0.2,-1.4),80)
