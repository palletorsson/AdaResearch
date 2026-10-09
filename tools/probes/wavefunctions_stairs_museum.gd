extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func clear_approach(at: Vector3, title: String) -> void:
    var hit:=floor_at(at)
    check(title+" has level floor",not hit.is_empty() and absf(hit.position.y-at.y)<0.06)
    var capsule:=CapsuleShape3D.new();capsule.radius=0.26;capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91);query.collision_mask=1|4
    var obstacles: Array=[]
    for h in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if h.collider!=museum.get("_player"):obstacles.append(str(h.collider.get_path()))
    check(title+" has body clearance",obstacles.is_empty())
    if not obstacles.is_empty():observations[title]=obstacles

func landing_checks() -> void:
    await super.landing_checks()
    var origin:=hall.global_position+Vector3(0,0,4)
    var stair:=find_scene("/sine_cylinder_staircase.gd")
    check("existing full stair has eighty generated treads",stair!=null and stair.get("STEP_COUNT")==80)
    if stair==null:return
    check("full stair retains uniform rise and radius modulation",is_equal_approx(stair.get("STEP_RISE"),0.11) and is_equal_approx(stair.get("WAVE_AMPLITUDE"),0.45))
    observations.stair_origin=xyz(stair.global_position-origin)
    check("first full-stair tread starts at floor",absf(stair.global_position.y)<0.01)
    for i in range(45):clear_approach(origin+Vector3(12.5,0,2+0.5*i),"central route %d"%i)
    for x in [10.8,11.5,12.2]:clear_approach(origin+Vector3(x,0,14.7),"lower stair approach %.1f"%x)
    var expected: Dictionary={"cube_scene":1,"dark_sphere":1,"sine_cylinder_staircase":1,"math_objects":1}
    var present: Dictionary={}
    for record in museum.get("_edit_records"):
        if record.get("seg")!=hall or not is_instance_valid(record.get("node")):continue
        var token: String=str(record.get("token"))
        if expected.has(token):present[token]=int(present.get(token,0))+1
    check("all four authored placements retained",present==expected)
    var gallery:=find_scene("/math_objects_gallery.gd")
    if gallery!=null:
        var bodies:=gallery.find_children("*","RigidBody3D",true,false)
        var low:=INF;var high:=-INF
        for body in bodies:
            low=minf(low,body.global_position.y);high=maxf(high,body.global_position.y)
        observations.specimens={"count":bodies.size(),"low":low,"high":high,"root":xyz(gallery.global_position-origin)}
        check("specimen bodies stay above floor",bodies.size()>0 and low>0.8)
        for z in [14.0,17.0,20.0]:
            var top:=floor_at(origin+Vector3(19.5,1,z))
            check("specimen support %.1f"%z,not top.is_empty() and absf(top.position.y-1.0)<0.05)
        await snapshot("specimens",gallery.global_position+Vector3(-3,2,-3),gallery.global_position,65)
    await snapshot("stair",stair.global_position+Vector3(8,5,-9),stair.global_position+Vector3(0,3.9,0),61)
    await snapshot("gallery",origin+Vector3(0,23,-1),origin+Vector3(12,1.5,14),66)
    await snapshot("entry-after",origin+Vector3(12.5,1.65,2),origin+Vector3(10,3,16),75)
    observations.scope="Existing hall layout and floor-level access; printed short study; full ascent and headset unverified."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(16,0,10);hall.add_child(lesson)
    for i in range(5):await physics_frame
    check("printed eleven-tread study builds inside museum",lesson.treads.size()==11 and lesson.label.is_inside_tree())
    clear_approach(lesson.to_global(Vector3(2.5,0,-1)),"student lower approach")
    clear_approach(lesson.to_global(Vector3(0,0,1)),"student inner view")
    var eye: Vector3=lesson.to_global(Vector3(5,3.0,5))
    var target: Vector3=lesson.to_global(Vector3(1.5,0.9,1.3))
    await snapshot("student",eye,target,62)
    observations.student_bay=[16,0,10]
    lesson.queue_free();await tick()
