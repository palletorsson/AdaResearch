extends "res://tools/probes/foundations_reconstruction_museum.gd"
func landing_checks() -> void:
    var started:=Time.get_ticks_msec()
    while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-started<30000:
        museum.call("_drain_stamps")
        museum.call("_drain_cartridge_nodes")
        await tick()
    var occupied:Array[AABB]=[]
    observations.artifacts=[]
    for child in hall.find_children("*","Node3D",true,false):
        if child.has_meta("artifact_lookup_name"):
            var bounds:AABB=museum.call("_seat_extent",child)
            occupied.append(bounds)
            observations.artifacts.append({"name":str(child.get_meta("artifact_lookup_name")),"at":xyz(hall.to_local(child.global_position))})
    observations.candidates=[]
    observations.physically_clear=[]
    for xi in range(4,28):
        for zi in range(4,35):
            var x:float=xi*0.5
            var z:float=zi*0.5
            for yaw:float in [0.0,PI/2,PI,-PI/2]:
                var at:=Transform3D(Basis(Vector3.UP,yaw),Vector3(x,0,z))
                if not placeable(at):continue
                observations.physically_clear.append({"at":xyz(at.origin),"yaw":yaw})
                var box:AABB=hall.global_transform*at*AABB(Vector3(-1.48,0.88,-0.98),Vector3(2.96,1.7,1.96))
                var clear:=true
                for bounds in occupied:clear=clear and not box.intersects(bounds)
                if clear:observations.candidates.append({"at":xyz(at.origin),"yaw":yaw})
    await snapshot("overview",hall.to_global(Vector3(7,18,16)),hall.to_global(Vector3(7,0,7)),70)
