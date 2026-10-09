extends "res://tools/probes/forces_layout.gd"
## Fresh submission temporarily installed in the already existing museum.
func landing_checks() -> void:
    await super.landing_checks()
    var script=load("res://doc/book/iterations/2026-10-08-motion-ghost-student-fresh/attempt/comparison.gd")
    check("fresh student comparison can instantiate in the museum",script!=null and script.can_instantiate())
    if script==null or not script.can_instantiate():return
    var study=script.new()
    study.name="FreshGhostStudentComparison"
    study.position=Vector3(23,0,18)
    hall.add_child(study)
    await create_timer(0.1).timeout
    var bodies: Array=[]
    for child in study.get_children():
        if child is RigidBody3D:bodies.append(child)
    bodies.sort_custom(func(a,b):return a.mass<b.mass)
    check("fresh student produces two spheres in the actual hall",bodies.size()==2)
    if bodies.size()!=2:return
    check("fresh student working position has floor support",not floor_at(study.global_position).is_empty())
    var origins=bodies.map(func(p):return p.global_position)
    study.buttons.values()[0].pressed.emit()
    await create_timer(2.1).timeout
    check("fresh comparison reaches equal final speed in the actual museum",absf(bodies[0].linear_velocity.length()-1)<0.06 and absf(bodies[1].linear_velocity.length()-1)<0.06)
    var distance: Array=[]
    for i in range(2):distance.append(bodies[i].global_position.distance_to(origins[i]))
    check("actual museum preserves the unequal distance",distance[0]>distance[1]+0.4)
    observations.fresh_student={"speeds":bodies.map(func(p):return p.linear_velocity.length()),"distances_at_observation":distance,"study_origin":[23,0,18]}
    await snapshot("student",study.to_global(Vector3(0,1.7,-3.5)),study.to_global(Vector3(0,1.4,1.2)),74)
    study.queue_free()
