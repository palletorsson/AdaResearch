extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    observations.artifacts = []
    var primary: Node3D = find_scene("/seed_replay_demo.gd")
    var origin := hall.global_position + Vector3(0, 0, 4)
    for record in museum.get("_edit_records"):
        var node = record.get("node")
        if not is_instance_valid(node) or record.get("seg") != hall: continue
        var bounds: AABB = museum.call("_seat_extent", node)
        observations.artifacts.append({"token": record.get("token"), "position": xyz(node.global_position-origin), "bounds_position": xyz(bounds.position-origin), "bounds_size": xyz(bounds.size)})
    check("seed comparison present in actual hall", primary != null)
    if primary != null:
        observations.primary_local = xyz(primary.global_position-hall.global_position)
        observations.primary_basis = str(primary.global_basis)
        var before: PackedFloat32Array = primary.raw_prefix(0, 6)
        check("raw seeded prefix repeats", before == primary.raw_prefix(0, 6))
        await snapshot("primary", primary.to_global(Vector3(0,2.1,4.7)), primary.to_global(Vector3(0,1.7,0)), 57)
    await snapshot("above", origin + Vector3(4,14,1), origin + Vector3(7,0,11), 70)
    await snapshot("entry", origin + Vector3(6,1.7,1), origin + Vector3(6,1.5,12), 75)
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "spec.json"))
    if spec.has("lesson"):
        await study_checks(spec, primary)
    observations.scope = "Current museum and primary; controlled native capture, no headset acceptance."

func study_checks(spec: Dictionary, primary: Node3D) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(10.5,0,18.5)
    study.rotation.y=-PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    observations.student_yaw_degrees=-90
    check("study stands over museum floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,1.5))
    check("approach has floor",not floor_at(approach).is_empty())
    var capsule:=CapsuleShape3D.new()
    capsule.radius=0.26
    capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("approach clear of other bodies",obstacles.is_empty())
    check("complete study initializes its labels and grids inside the museum",study.label.is_inside_tree() and study.grids.size()==2 and not study.label.text.is_empty())
    if primary!=null:
        primary.restore_museum_state({"seed":42,"extra_on":false})
        check("first sixteen colours agree with installed instrument",PackedColorArray(study.samples[0])==primary.column_colors(0).slice(0,16))
    await snapshot("student-matched",study.to_global(Vector3(0,1.65,3.7)),study.to_global(Vector3(0,1.4,0)),52)
    study.point.position.x=0
    study.point.action()
    check("carried point action changes the right panel",study.discard_first and study.samples[0]!=study.samples[1])
    if primary!=null:
        primary.toggle_extra_draw()
        check("shifted assignment agrees with installed instrument",PackedColorArray(study.samples[1])==primary.column_colors(1).slice(0,16))
    await snapshot("student-shifted",study.to_global(Vector3(0,1.65,3.7)),study.to_global(Vector3(0,1.4,0)),52)
    observations.lesson=spec.lesson
    study.queue_free()
