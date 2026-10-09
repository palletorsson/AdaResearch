extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func clear_approach(owner: Node3D, at: Vector3, title: String) -> void:
    var hit:=floor_at(at)
    check(title+" has level floor",not hit.is_empty() and absf(hit.position.y-at.y)<0.06)
    var capsule:=CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for h in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if h.collider!=museum.get("_player") and (owner==null or not owner.is_ancestor_of(h.collider)):obstacles.append(str(h.collider.get_path()))
    check(title+" has body clearance",obstacles.is_empty())
    observations[title]=obstacles

func landing_checks() -> void:
    await super.landing_checks()
    var rig:=find_scene("/BerniniColumns.gd")
    check("existing procedural columns present",rig!=null)
    if rig==null:return
    var origin:=hall.global_position+Vector3(0,0,4)
    # Follow a continuous path between columns, rather than sample through a shaft.
    var path: Array[Vector3]=[Vector3(11.5,0,2),Vector3(11.5,0,8),Vector3(9.5,0,9.5),Vector3(9.5,0,24),Vector3(11.5,0,25),Vector3(11.5,0,27)]
    for i in range(path.size()-1):
        var steps:=int(ceil(path[i].distance_to(path[i+1])/0.4))
        for j in range(steps+1):
            var at: Vector3=origin+path[i].lerp(path[i+1],float(j)/steps)
            clear_approach(null,at,"walk %d/%d" % [i,j])
    check("all nine columns retain the grid arrangement",rig.columns.size()==9 and rig.colonnade=="grid")
    var first: Node3D=rig.columns[0]
    var rotating: Node3D=first.get_node("RotatingRoot")
    var surface: MeshInstance3D=rotating.get_child(0)
    var stored: PackedVector3Array=surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].duplicate()
    check("full-size production shaft remains eight metres tall",is_equal_approx(rig.column_height,8.0))
    var before: Transform3D=rotating.transform
    rig._process(0.5)
    check("production shaft still rotates as a whole",not rotating.transform.is_equal_approx(before))
    check("production rotation does not rewrite its mesh",surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==stored)
    rig.rotate_columns=false
    var paused: Transform3D=rotating.transform
    rig._process(0.5)
    check("controlled pause leaves the generated form intact",rotating.transform.is_equal_approx(paused) and surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==stored)
    rig.rotate_columns=true
    var expected: Dictionary={"bernini_columns":1,"ElphabaDress":1,"dark_sphere":1,"vowel_sound_board":1}
    var present: Dictionary={}
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token: String=str(record.get("token"))
        if not expected.has(token):continue
        present[token]=int(present.get(token,0))+1
        var bounds: AABB=museum.call("_seat_extent",record.node)
        if token=="ElphabaDress":check("dress visible above its one-metre plinth",absf(bounds.position.y-origin.y-1)<0.04)
        if token=="bernini_columns":check("column bases meet museum floor",absf(bounds.position.y-origin.y)<0.04)
        if token=="vowel_sound_board":check("voice lowered to reachable height",record.node.global_position.y-origin.y>=1.2 and record.node.global_position.y-origin.y<1.6)
    check("four authored exhibits retained",present==expected)
    observations.preserved_artifacts=present
    await snapshot("aisle",origin+Vector3(9.5,1.65,9.5),origin+Vector3(11.5,4.0,17),72)
    await snapshot("gallery",origin+Vector3(-1,20,-2),origin+Vector3(11,1,17),70)
    await snapshot("entry-after",origin+Vector3(11.5,1.65,2),origin+Vector3(11.5,3.2,17),73)
    observations.scope="Real museum with unchanged column generation. Dense supported-route samples and capsule clearance; synthetic control events. No physical headset or independent learner trial."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(5,0,10);lesson.rotation.y=PI
    hall.add_child(lesson);await tick();lesson.set_process(false)
    clear_approach(lesson,lesson.to_global(Vector3(0.7,0,1.4)),"student approach")
    check("exact printed shaft constructed in museum",lesson.points.size()==138 and lesson.faces.size()==272 and lesson.point.enabled)
    lesson.point.position.y=1.2;lesson._process(0)
    var stored: Array=lesson.points.duplicate()
    lesson.point.action_pressed.emit(lesson.point);lesson._process(0.4)
    check("real carried trigger starts rotation in museum",lesson.running and absf(lesson.shaft.rotation.y)>0.1)
    lesson.point.action_pressed.emit(lesson.point);lesson._process(0.4)
    check("second trigger stops without rewriting the twist",not lesson.running and lesson.points==stored)
    lesson.shaft.rotation.y=0
    var eye: Vector3=lesson.to_global(Vector3(2.6,2.1,4.5))
    var target: Vector3=lesson.to_global(Vector3(0.4,1.65,0))
    var ray:=PhysicsRayQueryParameters3D.create(eye,target,1)
    check("learner shaft sightline is clear",hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
    await snapshot("student",eye,target,49)
    lesson.point.position.y=0.8;lesson._process(0)
    await snapshot("straight",eye,target,49)
    lesson.point.position.y=1.6;lesson._process(0)
    await snapshot("full-turn",eye,target,49)
    observations.student_bay=[5,0,10]
    observations.student_bay_yaw=180
    lesson.queue_free();await tick()
