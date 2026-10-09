extends SceneTree

var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[treads] ","PASS " if value else "FAIL ",title)
func settle() -> void:
    for i in range(5):await physics_frame
    await process_frame
func ray(lesson: Node3D, local: Vector3) -> Dictionary:
    var p:=lesson.to_global(local)
    return lesson.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.04,p-Vector3.UP*0.05,1))

func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var lesson=load(source).new()
    lesson.position=Vector3(7,2,-5);lesson.rotation.y=PI/3
    root.add_child(lesson);await settle()
    check("complete script builds eleven treads and its own labels",lesson.treads.size()==11 and lesson.label.text!="")
    check("first top is at the start of the circle",lesson.points[0].is_equal_approx(Vector3(2.5,0,0)))
    check("middle top reaches radius 2.95 and height 0.55",lesson.points[5].is_equal_approx(Vector3(2.95/sqrt(2.0),0.55,2.95/sqrt(2.0))))
    check("last top ends a quarter turn at height 1.10",lesson.points[10].is_equal_approx(Vector3(0,1.1,2.5)))
    var orientations:=true
    var dimensions:=true
    var top_alignment:=true
    var contacts:=true
    for i in range(11):
        var tread: StaticBody3D=lesson.treads[i]
        var radial: Vector3=Vector3(lesson.points[i].x,0,lesson.points[i].z).normalized()
        orientations=orientations and tread.basis.x.is_equal_approx(radial) and tread.basis.y.is_equal_approx(Vector3.UP)
        var mesh: MeshInstance3D=tread.get_child(0)
        var collision: CollisionShape3D=tread.get_child(1)
        dimensions=dimensions and collision.shape!=null and collision.shape.size.is_equal_approx(mesh.mesh.size)
        top_alignment=top_alignment and (tread.position+Vector3.UP*mesh.mesh.size.y/2).is_equal_approx(lesson.points[i])
        var hit:=ray(lesson,lesson.points[i])
        contacts=contacts and not hit.is_empty() and hit.collider==tread and hit.position.distance_to(lesson.to_global(lesson.points[i]))<0.002
    check("all treads face radially with level tops",orientations)
    check("each rendered box has matching solid dimensions",dimensions)
    check("sampled positions name top surfaces rather than centres",top_alignment)
    check("native ray hits every named top in translated rotated host",contacts)
    var path_lines:=0
    for child in lesson.get_children():
        if child.get_script()!=null and str(child.get_script().resource_path).ends_with("line_skin.gd"):
            path_lines+=1
            check("path segment %d is visible without collision"%path_lines,child.visible and child.get_child_count()==0)
    check("ten intervals join eleven positions",path_lines==10)
    check("outside midpoint distance exceeds inside",lesson.edge_distance(4,5,1.0)>lesson.edge_distance(4,5,-1.0))
    # Real rigid body falls onto the final tread, away from neighbouring tops.
    var ball:=RigidBody3D.new();ball.mass=1;ball.collision_layer=2;ball.collision_mask=1
    var boundary:=CollisionShape3D.new();var sphere:=SphereShape3D.new();sphere.radius=0.06;boundary.shape=sphere
    ball.add_child(boundary);ball.position=lesson.to_global(lesson.points[10]+Vector3.UP*0.5)
    root.add_child(ball)
    await create_timer(1.4).timeout
    check("released sphere rests on real tread collision",absf(ball.global_position.y-(lesson.global_position.y+1.16))<0.025 and ball.linear_velocity.length()<0.1)
    ball.queue_free()
    var variant=load(source.get_base_dir()+"/10_constant_radius.gd").new()
    variant.position=Vector3(-8,0,0);root.add_child(variant);await settle()
    var circular:=true;var preserved:=true;var variant_contact:=true
    for i in range(11):
        var p: Vector3=variant.points[i]
        circular=circular and absf(Vector2(p.x,p.z).length()-2.5)<0.00001
        preserved=preserved and absf(p.y-float(i)*0.11)<0.00001 and variant.treads[i].basis.is_equal_approx(lesson.treads[i].basis)
        variant_contact=variant_contact and not ray(variant,p).is_empty()
    check("independent zero-amplitude variation has constant radius",circular)
    check("variation keeps count, rise and orientations",preserved and variant.treads.size()==11)
    check("variation still presents real top surfaces",variant_contact)
    # Known circular chord lengths provide a separate oracle for edge measurement.
    var inner:=sqrt(pow(2*1.9*sin(PI/40.0),2)+pow(0.11,2))
    var outer:=sqrt(pow(2*3.1*sin(PI/40.0),2)+pow(0.11,2))
    check("constant-radius edge distances agree with chord geometry",absf(variant.edge_distance(4,5,-1)-inner)<0.00001 and absf(variant.edge_distance(4,5,1)-outer)<0.00001)
    lesson.queue_free();variant.queue_free();await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed construction; physical top contacts and dropped sphere; not player ascent or independent student evaluation."},"  "))
    quit(0 if failures.is_empty() else 1)
