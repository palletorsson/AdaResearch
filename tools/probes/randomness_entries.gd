extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    var stream= museum.get("_portal_stream")
    var began:=Time.get_ticks_msec()
    while stream!=null and stream.busy and Time.get_ticks_msec()-began<15000:await tick()
    check("portal coordinator exists and finishes loading",stream!=null and not stream.busy)
    if stream==null:return
    var authored: Dictionary=stream._authored_entry()
    observations.authored=authored
    observations.hall_transform=str(hall.global_transform)
    observations.stream_transform=str(stream._current.node.global_transform)
    observations.vestibule= museum.get("VESTIBULE_H")
    observations.installed_entry=stream._entry
    observations.installed_portals=stream._portals
    observations.arrival=xyz(stream._arrival)
    observations.fallback_supported=stream._supported(stream._arrival)
    var candidates:=[]
    var examined:=[]
    for z in [1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5,11.5]:
        for col in range(20):
            var x:=float(col)+0.5
            var marker: Vector3=hall.to_global(Vector3(x,0,z))
            var level: float=museum.call("_arrival_floor_y",marker.x,marker.z)
            var floor_point: Vector3=stream._nearest_floor(Vector3(marker.x,level+0.4,marker.z))
            var door: Vector3=floor_point-Vector3(0,0,1.15)
            if stream._supported(floor_point) and stream._portal_clear(door):
                candidates.append({"local":xyz(hall.to_local(floor_point)),"door":xyz(hall.to_local(door)),"walk":walk_ahead(stream,floor_point)})
            elif x==7.5 or x==8.5:
                examined.append({"local":xyz(hall.to_local(floor_point)),"support":stream._supported(floor_point),"portal":stream._portal_clear(door)})
    observations.candidates=candidates
    observations.examined=examined
    observations.user_map_override=FileAccess.file_exists("user://maps/%s/map_data.json"%map_id)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    await snapshot("overview",hall.to_global(Vector3(3,7,0.5)),hall.to_global(Vector3(7,0,9)),70)
    if spec.stage=="after":
        check("authored entry is valid",not authored.is_empty() and not authored.get("invalid",false))
        check("authored source is explicit museum spawn",authored.get("source","")=="sp")
        check("arrival uses the installed entrance without a distant fallback",stream._arrival_supported() and stream._arrival.distance_to(stream._entry.get("landing",Vector3.INF))<0.1)
        if authored.has("marker"):
            var marker: Vector3=authored.marker
            var gate: Dictionary=museum.get("_gate")
            if not gate.is_empty():
                museum.call("_open_gate")
                check("entrance scanner action grants access",float(museum.get("_gate_t"))>=0.0)
                museum.get("_mod_gate").call("step_open",gate,3.0)
                await tick();await tick()
            var visitor: Node3D=museum.get("_player")
            if visitor != null:
                observations.visitor_before_route=xyz(visitor.global_position)
                visitor.set_physics_process(false)
                visitor.set_process(false)
                visitor.global_position=Vector3(-1000,0,-1000)
                await tick();await tick()
            var walk: Dictionary=path_to_hall(stream,marker)
            observations.walk=walk
            observations.blockers=blockers(stream)
            check("supported clear route connects the landing to the hall",walk.safe)
            await snapshot("entrance",marker+Vector3(3,2.8,5),marker+Vector3(0,1,-0.6),65)
    else:
        check("diagnostic recheck produced an authored entry or explicit failure",not authored.is_empty())

func walk_ahead(stream: Node, start: Vector3) -> Dictionary:
    var steps:=[]
    var previous:=start
    var safe:=true
    for i in range(9):
        var at: Vector3=stream._nearest_floor(start+Vector3(0,0.5,float(i)*0.125))
        var valid: bool=stream._supported(at,true) and absf(at.y-previous.y)<0.3
        steps.append({"at":xyz(hall.to_local(at)),"supported":valid})
        safe=safe and valid
        previous=at
    return {"safe":safe,"steps":steps}

func path_to_hall(stream: Node, start: Vector3) -> Dictionary:
    var queue: Array[Vector2i]=[Vector2i.ZERO]
    var points: Dictionary={Vector2i.ZERO:start}
    var parents: Dictionary={}
    var visited: Dictionary={Vector2i.ZERO:true}
    var last:=Vector2i.ZERO
    var found:=false
    var cursor:=0
    while cursor<queue.size() and cursor<2200:
        var here: Vector2i=queue[cursor];cursor+=1
        var at: Vector3=points[here]
        if hall.to_local(at).z>=maxf(6.5,hall.to_local(start).z+1.0):
            last=here;found=true;break
        for offset in [Vector2i(0,1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1)]:
            var next: Vector2i=here+offset
            if visited.has(next) or absi(next.x)>24 or next.y<0 or next.y>32:continue
            visited[next]=true
            var floor_point: Vector3=stream._nearest_floor(start+Vector3(next.x*0.125,2.0,next.y*0.125))
            if absf(floor_point.y-at.y)>0.3 or not stream._supported(floor_point,true):continue
            points[next]=floor_point;parents[next]=here;queue.append(next)
    var path:=[]
    if found:
        while true:
            path.push_front(xyz(hall.to_local(points[last])))
            if last==Vector2i.ZERO:break
            last=parents[last]
    var furthest:=hall.to_local(start).z
    for p: Vector3 in points.values():furthest=maxf(furthest,hall.to_local(p).z)
    return {"safe":found,"visited":cursor,"path":path,"maximum_local_z":furthest}

func blockers(stream: Node) -> Array:
    var result:=[]
    for x in [5.5,7.5,8.5,9.5,10.5]:
        for z in [3.5,4.0,4.5,5.0,5.5]:
            var at: Vector3=stream._nearest_floor(hall.to_global(Vector3(x,0.7,z)))
            var shape:=CapsuleShape3D.new();shape.radius=0.3;shape.height=1.8
            var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3(0,0.95,0)
            var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q,8)
            var names:=[]
            for hit in hits:names.append(str(hit.collider.get_path()))
            if not names.is_empty():result.append({"local":[x,z],"bodies":names})
    return result

func finish() -> void:
    var result: Dictionary={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum arrival and local supported-route checks. Supplied scanner access action; observer parked outside geometric raycasts. No continuous player traversal or headset test."}
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    print("RANDOMNESS ENTRANCE ",map_id," ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
