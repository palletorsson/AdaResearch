extends "res://tools/probes/forces_layout.gd"

func landing_checks() -> void:
    await super.landing_checks()
    var primary: Node3D
    for record in museum.get("_edit_records"):
        if record.get("seg")==hall and record.get("token")=="force_play_mass":
            primary=record.get("node")
            break
    check("actual hall has the current mass artifact",primary!=null)
    if primary==null:return
    primary.buttons["PUSH 1 s"].pressed.emit()
    await create_timer(1.15).timeout
    await snapshot("primary",primary.to_global(Vector3(-2,1.7,-6)),primary.to_global(Vector3(0,1.5,0)),75)
    var study=load("res://doc/book/iterations/2026-10-08-motion-build-and-investigate/ghost-attempt/comparison.gd").new()
    study.name="GhostStudentStudy"
    study.position=Vector3(23,0,18)
    hall.add_child(study)
    await create_timer(0.1).timeout
    check("declared study bay has a museum floor",not floor_at(study.global_position).is_empty())
    var stand=study.to_global(Vector3(0,0,-1.5))
    check("student can stand before the nearby button",not floor_at(stand).is_empty() and standing_clear(stand,study))
    check("student button is within hand reach",study.buttons.values()[0].global_position.distance_to(stand+Vector3.UP*1.2)<0.85)
    var clear_path=true
    for x in [-1.0,0.0,1.0]:
        for z in range(9):
            var at=study.to_global(Vector3(x,0,-1.5+z*0.5))
            if floor_at(at).is_empty() or not standing_clear(at,study):clear_path=false
    check("student bay has a supported clear approach and observation area",clear_path)
    var points: Array=[]
    for child in study.get_children():
        if child is RigidBody3D:points.append(child)
    points.sort_custom(func(a,b):return a.mass<b.mass)
    check("student comparison has two bodies in the real hall",points.size()==2)
    if points.size()!=2:return
    var origins=points.map(func(p):return p.global_position)
    study.buttons.values()[0].pressed.emit()
    await create_timer(2.1).timeout
    check("actual museum permits both predicted speeds",absf(points[0].linear_velocity.length()-1)<0.06 and absf(points[1].linear_velocity.length()-1)<0.06)
    check("actual museum preserves the difference in distance",points[0].global_position.distance_to(origins[0])>points[1].global_position.distance_to(origins[1])+0.4)
    await snapshot("student",study.to_global(Vector3(0,1.7,-3.5)),study.to_global(Vector3(0,1.4,1.2)),74)
    await create_timer(1.0).timeout
    check("declared bay leaves room to coast without collision",absf(points[0].linear_velocity.length()-1)<0.06 and absf(points[1].linear_velocity.length()-1)<0.06)
    observations.scope="Printed lesson reconstruction and independent AI variation placed in the actual Motion hall; floor, clearance and solver behaviour. No physical headset or human learning claim."
    observations.study_origin=[23,0,18]
    study.queue_free()

func standing_clear(at: Vector3,study: Node) -> bool:
    var shape=CapsuleShape3D.new()
    shape.radius=0.26
    shape.height=1.6
    var query=PhysicsShapeQueryParameters3D.new()
    query.shape=shape
    query.transform.origin=at+Vector3.UP*0.91
    query.collision_mask=1|4
    var walker=museum.get("_player")
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query,16):
        if study.is_ancestor_of(hit.collider):continue
        if is_instance_valid(walker) and (hit.collider==walker or walker.is_ancestor_of(hit.collider)):continue
        return false
    return true
