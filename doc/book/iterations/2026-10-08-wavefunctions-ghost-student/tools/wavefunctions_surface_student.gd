extends SceneTree

var checks: Array = []
var failures: Array = []

func _initialize() -> void: run.call_deferred()

func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value: failures.append(title)
    print("[surface] ", "PASS " if value else "FAIL ", title)

func settle(frames: int) -> void:
    for i in frames: await physics_frame
    await process_frame

func run() -> void:
    await process_frame
    var source := "res://doc/book/studies/wavefunctions-lineage/03_sine_surface.gd"
    var report := "res://doc/book/iterations/2026-10-08-sine-space-a-surface/student-test.json"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--lesson="): source=argument.trim_prefix("--lesson=")
        if argument.begins_with("--report="): report=argument.trim_prefix("--report=")
    var Lesson = load(source)
    var Pickable = load("res://addons/godot-xr-tools/objects/pickable.gd")
    var lesson = Lesson.new()
    lesson.position=Vector3(4,2,7)
    lesson.rotation.y=PI/3
    root.add_child(lesson)
    lesson.point.freeze=true
    await settle(3)
    check("complete program constructs surface and collision",lesson.surface.mesh!=null and lesson.boundary.shape is ConcavePolygonShape3D)
    check("existing point class creates matching sphere and boundary",lesson.point.get_child(0).mesh is SphereMesh and is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14) and is_equal_approx(lesson.point.get_child(1).shape.radius,0.14))
    check("point returns to physics on release",lesson.point.release_mode==Pickable.ReleaseMode.UNFROZEN and lesson.point.gravity_scale==1.0)
    check("17 by 17 shared samples",lesson.points.size()==289)
    check("two triangles per cell",lesson.faces.size()==512)
    check("height at zero crossing is baseline",absf(lesson.height_at(0,0.25)-0.8)<0.00001)
    check("quarter metre reaches crest",absf(lesson.height_at(0.25,0.25)-0.98)<0.00001)
    check("half metre returns to baseline",absf(lesson.height_at(0.5,0.25)-0.8)<0.00001)
    check("opposite quarter metre reaches trough",absf(lesson.height_at(-0.25,0.25)-0.62)<0.00001)
    check("one metre repeats spatial value",absf(lesson.height_at(0.13,0.21)-lesson.height_at(1.13,0.21))<0.00001)
    check("zero Z row cancels X relief",absf(lesson.height_at(0.25,0)-0.8)<0.00001)
    var mesh_faces: PackedVector3Array = lesson.surface.mesh.get_faces()
    var shape_faces: PackedVector3Array = lesson.boundary.shape.get_faces()
    check("drawn and colliding triangles share exact positions",mesh_faces==shape_faces)
    check("mesh has expected emitted triangle vertices",mesh_faces.size()==1536)
    var up := true
    var area := 0.0
    for i in range(0,mesh_faces.size(),3):
        var normal := (mesh_faces[i+2]-mesh_faces[i]).cross(mesh_faces[i+1]-mesh_faces[i])
        up=up and normal.y>0
        area+=absf(normal.y)*0.5
    check("every triangle faces upwards",up)
    check("triangles cover four square metres in plan",absf(area-4.0)<0.00001)
    var collision_agrees := true
    for p in [Vector3(0.25,0.98,0.25),Vector3(-0.25,0.62,0.25),Vector3(0.5,0.8,0.25)]:
        var top: Vector3 = lesson.to_global(Vector3(p.x,2,p.z))
        var bottom: Vector3 = lesson.to_global(Vector3(p.x,0,p.z))
        var q := PhysicsRayQueryParameters3D.create(top,bottom,1)
        var hit: Dictionary = lesson.get_world_3d().direct_space_state.intersect_ray(q)
        collision_agrees=collision_agrees and not hit.is_empty()
        if not hit.is_empty():collision_agrees=collision_agrees and hit.position.distance_to(lesson.to_global(p))<0.001
    check("rays reach known heights after translation and rotation",collision_agrees)
    var first_mesh: PackedVector3Array = mesh_faces.duplicate()
    await settle(10)
    check("terrain does not animate with elapsed time",lesson.surface.mesh.get_faces()==first_mesh)
    var coarse = Lesson.new()
    coarse.position.x=20;coarse.cells=4
    root.add_child(coarse);coarse.point.freeze=true
    var flat := true
    for p in coarse.points:flat=flat and absf(p.y-0.8)<0.00001
    check("half-metre sampling misses the crests",flat and coarse.points.size()==25)
    check("coarse sampling does not flatten the underlying function",absf(coarse.height_at(0.25,0.25)-0.98)<0.00001)
    var slower = Lesson.new()
    slower.position.x=40;slower.frequency=0.5
    root.add_child(slower);slower.point.freeze=true
    check("half spatial frequency puts crest at half metre",absf(slower.height_at(0.5,0.5)-0.98)<0.00001)
    check("independent instance leaves first frequency intact",lesson.frequency==1.0)
    var contact = Lesson.new()
    contact.position.x=60;contact.amplitude=0.0
    root.add_child(contact)
    check("dropped point starts unfrozen",not contact.point.freeze)
    var without = Lesson.new()
    without.position.x=80;without.amplitude=0.0
    root.add_child(without)
    without.boundary.disabled=true
    await settle(120)
    check("flat receiver supports the physical sphere",absf(contact.point.position.y-0.94)<0.025 and absf(contact.point.linear_velocity.y)<0.05)
    check("removing receiver lets same sphere fall through drawing",without.point.position.y<0)
    check("contact trial does not deform geometry",contact.points.all(func(p): return absf(p.y-0.8)<0.00001))
    for n in [lesson,coarse,slower,contact,without]:n.queue_free()
    await process_frame
    var data={"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed program executed in Godot/Jolt; teacher-authored checks, not an independent student or headset test."}
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify(data,"  "))
    quit(0 if failures.is_empty() else 1)
