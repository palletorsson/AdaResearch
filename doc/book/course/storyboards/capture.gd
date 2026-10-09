extends "res://tools/probes/transformation_encounters.gd"
## Photographs of the actual hall. These do not validate a proposed lesson.
func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(1.2).timeout
    var map_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
    var wanted: Array[String] = []
    for row in map_data.get("layers",{}).get("interactables",[]):
        for token in row:
            if token is String and not token.strip_edges().is_empty():
                wanted.append(token.split(":")[0].split("#")[0])
    var lesson: Array = []
    for part in ["opening","early","growth","later"]:
        var sequences: Array = JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/course/storyboards/"+part+".json"))
        for seq in sequences:
            for h in seq.halls:
                if h.id == map_id: lesson = h.artifact_refs
    var records: Array = []
    for record in museum.get("_edit_records"):
        var node: Node3D = record.get("node")
        if is_instance_valid(node) and record.get("seg") == hall:
            records.append(record)
    var player: Node3D = museum.get("_player")
    if player != null: player.visible = false
    var entrance := player.global_position + Vector3.UP * 1.62 if player != null else hall.global_position + Vector3(5,1.62,5)
    if entrance.distance_to(hall.global_position) > 100:
        entrance = hall.global_position + Vector3(5,1.62,3)
    var target := entrance + Vector3(0,0,5)
    var chosen: Node3D
    var best := INF
    for record in records:
        var token: String = record.get("token", "")
        var lookup: String = token.split(":")[0].split("#")[0]
        if lookup not in wanted: continue
        if lookup in ["dark_sphere","code_display","cube_scene","exit_sign"] or "text" in lookup or "radio" in lookup: continue
        var node: Node3D = record.node
        var extent: AABB = museum.call("_seat_extent",node)
        if extent.size.length() < 0.05:
            if lookup not in lesson: continue
            # CSG and custom GPU displays need not contain a MeshInstance3D.
            extent = AABB(node.global_position,Vector3(1,2,1))
        var distance := entrance.distance_to(extent.get_center())
        if lookup in lesson: distance -= 1000.0 / float(lesson.find(lookup)+1)
        if distance < best:
            best = distance
            chosen = node
            target = extent.get_center()
            target.y = clampf(target.y,hall.global_position.y+0.8,hall.global_position.y+2.2)
            observations["encounter_token"] = token
    await snapshot("museum-entry", entrance, target, 72)
    observations["entry_eye"] = xyz(entrance)
    if chosen != null:
        # Stand near the encounter, on an existing floor, looking at its body.
        var bounds: AABB = museum.call("_seat_extent", chosen)
        target = bounds.get_center()
        target.y = clampf(target.y, hall.global_position.y + 0.8, hall.global_position.y + 2.2)
        var distance := clampf(maxf(bounds.size.x,bounds.size.z)*0.8,2.7,7.0)
        var eye := entrance
        var space := hall.get_world_3d().direct_space_state
        var best_view := -INF
        var view_number := 0
        for direction in [Vector3(0,0,-1),Vector3(1,0,-1).normalized(),Vector3(-1,0,-1).normalized(),Vector3(0,0,1),Vector3(1,0,0),Vector3(-1,0,0),Vector3(1,0,1).normalized(),Vector3(-1,0,1).normalized()]:
            var candidate: Vector3 = target + direction * distance
            var floor_ray := PhysicsRayQueryParameters3D.create(Vector3(candidate.x,hall.global_position.y+0.6,candidate.z),Vector3(candidate.x,hall.global_position.y-0.3,candidate.z),1)
            var floor_hit := space.intersect_ray(floor_ray)
            if floor_hit.is_empty(): continue
            candidate.y = floor_hit.position.y + 1.62
            var sight := PhysicsRayQueryParameters3D.create(candidate,target,1)
            var hit := space.intersect_ray(sight)
            if not hit.is_empty() and hit.position.distance_to(candidate) < 1.1: continue
            var visibility: float = 1.0 if hit.is_empty() else hit.position.distance_to(candidate)/candidate.distance_to(target)
            var rating: float = visibility - 0.005*entrance.distance_to(candidate)
            if rating > best_view:
                best_view = rating
                eye = candidate
            if map_id in ["Shader_05_Patterns","Fractal_MengerSponge"]:
                await snapshot("museum-option-"+str(view_number),candidate,target,76)
                view_number += 1
        await snapshot("museum-encounter",eye,target,70)
        observations["encounter_eye"] = xyz(eye)
        observations["encounter_target"] = xyz(target)
    observations["photographed_at"] = Time.get_datetime_string_from_system()

func finish() -> void:
    var report := {"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Actual loaded Endless Museum hall, standing camera views; no tutorial, movement, current curation or physical headset verification."}
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("STORYBOARD MUSEUM CAPTURE ",map_id)
    quit(0 if failures.is_empty() else 1)
