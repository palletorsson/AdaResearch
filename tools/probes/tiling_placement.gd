extends "res://tools/probes/transformation_encounters.gd"
var survey_complete:=false
func landing_checks()->void:
    AudioServer.set_bus_mute(0,true)
    root.size=Vector2i(1440,1000)
    var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
    var grid:Node3D=hall.get_node_or_null("SimGrid_"+map_id)
    for i in 3600:
        if grid==null or grid.has_meta("stage_grid_ready"):break
        await process_frame
    museum.call("flush_stamps")
    await create_timer(.6).timeout
    var player:Node3D=museum.get("_player")
    if player:player.hide();player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    observations["grid_transform"]=str(grid.global_transform) if grid else "not simulation grid"
    observations["artifacts"]=[]
    var candidates:Array=[]
    for n in hall.find_children("*","Node3D",true,false):
        if n.has_meta("artifact_lookup_name"):candidates.append(n)
    if grid==null:
        for r in museum.get("_edit_records"):
            if r.get("seg")==hall and is_instance_valid(r.get("node")) and r.node not in candidates:candidates.append(r.node)
    for n:Node3D in candidates:
        var extent:AABB=museum.call("_seat_extent",n)
        var id:String=str(n.get_meta("artifact_lookup_name",n.get_meta("em_token",n.name)))
        var item:Dictionary={"id":id,"path":str(hall.get_path_to(n)),"at":xyz(hall.to_local(n.global_position)),"scale":xyz(n.scale),"bounds_at":xyz(hall.to_local(extent.position)),"bounds_size":xyz(extent.size),"labels":[]}
        for label:Label3D in n.find_children("*","Label3D",true,false):
            if label.visible and item.labels.size()<8:item.labels.append({"text":label.text.left(100),"at":xyz(hall.to_local(label.global_position))})
        observations.artifacts.append(item)
        if id in ["pattern_tile_4x4","pattern_tile_mirror","pattern_tile_brick","pattern_tile_herringbone","pattern_tile_puzzle"]:
            check(id+" editor and preview above floor at hand height",item.bounds_at[1]>.7 and item.bounds_at[1]+item.bounds_size[1]<1.95)
            var cell:Node3D=n.get("_editor_cells")[0][0]
            var nearest:Dictionary=n.call("_find_nearest_cell",cell.global_position)
            check(id+" lifted editor still maps world-space release to cell 0,0",nearest.valid and nearest.x==0 and nearest.y==0)
        if id=="tiling_demo":
            var samples:=0
            for child in n.get_children():
                if str(child.name).begins_with("Tiling_") or str(child.name).begins_with("Composed_"):samples+=1
            check("eleven miniature pattern samples built",samples==11 and extent.size.length()>1)
            check("miniature uses museum lighting",n.find_children("*","WorldEnvironment",true,false).is_empty() and n.find_children("*","DirectionalLight3D",true,false).is_empty())
        if id=="wall_pattern_gallery":check("wall patterns leave floor and ceiling open",n.get("surfaces")=="walls")
    var expected:Dictionary={}
    for row in data.layers.interactables:
        for token in row:
            if not str(token).strip_edges().is_empty():
                var key:String=str(token).split("#")[0].split(":")[0]
                expected[key]=int(expected.get(key,0))+1
    for id in expected:
        var count:=0
        for n in candidates:
            if str(n.get_meta("artifact_lookup_name",""))==id:count+=1
        check("all "+id+" instances present",count==expected[id])
    check("authored artifacts load",not candidates.is_empty())
    var width:float=data.map_info.dimensions.width
    var depth:float=data.map_info.dimensions.depth
    var frame:Transform3D=hall.global_transform*Transform3D(Basis.IDENTITY,Vector3(.5,0,4.5) if grid else Vector3(0,0,4))
    var centre:Vector3=frame*Vector3(width*.5,0,depth*.5)
    await snapshot("above",centre+Vector3(0,maxf(width,depth)*1.07,depth*.18),centre,60)
    await snapshot("room",frame*Vector3(width*.5,3,2),frame*Vector3(width*.5,1.3,depth*.55),83)
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    for shot in spec.get("shots",[]):
        await snapshot(shot.name,frame*Vector3(shot.eye[0],shot.eye[1],shot.eye[2]),frame*Vector3(shot.target[0],shot.target[1],shot.target[2]),shot.get("fov",65))
    # Capsule centre follows the authored floor level; sample the named approaches.
    var shape:=CapsuleShape3D.new();shape.height=1.7;shape.radius=.25
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    observations["approaches"]=[]
    for a in spec.get("approaches",[]):
        var foot:Vector3=frame*Vector3(a.point[0],a.point[1],a.point[2])
        query.transform.origin=foot+Vector3.UP*.9
        var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,16)
        var support:=floor_at(foot)
        var supported:bool=not support.is_empty() and absf(support.position.y-foot.y)<.08
        var row={"name":a.name,"supported":supported,"clear":hits.is_empty(),"colliders":[],"floor_y":support.position.y if not support.is_empty() else null,"floor_collider":str(support.collider.get_path()) if not support.is_empty() else "none"}
        for hit in hits:row.colliders.append(str(hit.collider.get_path()))
        observations.approaches.append(row)
        check(a.name+" supported and clear",supported and hits.is_empty())
    survey_complete=true
func finish()->void:
    check("placement survey completed",survey_complete)
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Native museum placement survey and supplied approach collision samples. No physical headset or full interaction certification."},"  "))
    quit(0 if failures.is_empty() else 1)
