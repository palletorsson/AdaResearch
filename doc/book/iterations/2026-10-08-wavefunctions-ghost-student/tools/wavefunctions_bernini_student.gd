extends SceneTree

var checks: Array = []
var failures: Array = []
func _initialize() -> void:run.call_deferred()
func check(title: String, value: bool) -> void:
    checks.append({"name":title,"passed":value})
    if not value:failures.append(title)
    print("[shaft] ","PASS " if value else "FAIL ",title)

func geometry_checks(lesson: Node3D, title: String) -> void:
    var edges: Dictionary = {}
    var valid := true
    var area := true
    for f: Vector3i in lesson.faces:
        valid = valid and f.x>=0 and f.y>=0 and f.z>=0 and f.x<lesson.points.size() and f.y<lesson.points.size() and f.z<lesson.points.size()
        if not valid:continue
        var a: Vector3=lesson.points[f.x]
        var b: Vector3=lesson.points[f.y]
        var c: Vector3=lesson.points[f.z]
        area=area and (b-a).cross(c-a).length()>0.00001
        for e in [Vector2i(f.x,f.y),Vector2i(f.y,f.z),Vector2i(f.z,f.x)]:
            var key:=Vector2i(mini(e.x,e.y),maxi(e.x,e.y))
            edges[key]=int(edges.get(key,0))+1
    var closed: bool=not edges.is_empty()
    for count in edges.values():closed=closed and count==2
    check(title+" valid corner indices",valid)
    check(title+" no degenerate triangles",area)
    check(title+" closed seam and caps: every logical edge has two faces",closed)
    check(title+" sphere topology V-E+F=2",lesson.points.size()-edges.size()+lesson.faces.size()==2)

func run() -> void:
    await process_frame
    var source: String
    var report: String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    var Lesson=load(source)
    var lesson=Lesson.new()
    lesson.position=Vector3(4,2,7);lesson.rotation.y=PI/3
    root.add_child(lesson);lesson.set_process(false)
    check("complete program creates shaft, control and readout",lesson.surface.mesh is ArrayMesh and lesson.point.enabled and lesson.label.text!="")
    check("carried sphere keeps its size and frozen release",is_equal_approx(lesson.point.get_child(0).mesh.radius,0.14) and lesson.point.freeze and lesson.point.release_mode==lesson.point.ReleaseMode.FROZEN)
    check("17 rings plus two centres give 138 positions",lesson.points.size()==138)
    check("sides and caps give 272 triangles",lesson.faces.size()==272)
    check("rendered mesh contains every triangle",lesson.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==816)
    geometry_checks(lesson,"half-turn shaft")
    check("bottom keeps its starting corner",lesson.ring_position(0,0).is_equal_approx(Vector3(0.4,0.25,0)))
    check("half-height turns first corner ninety degrees",lesson.ring_position(8,0).is_equal_approx(Vector3(0,1.45,-0.4)))
    check("top turns first corner one hundred eighty degrees",lesson.ring_position(16,0).is_equal_approx(Vector3(-0.4,2.65,0)))
    check("oval has unequal radii",lesson.ring_position(0,2).is_equal_approx(Vector3(0,0.25,0.2)))
    check("local height works after translated and rotated host",is_equal_approx(lesson.turns_from_height(),0.5))
    var original_faces: Array=lesson.faces.duplicate()
    var old_mesh: Mesh=lesson.surface.mesh
    lesson._process(0.1)
    check("unchanged hand does not rebuild geometry",lesson.surface.mesh==old_mesh)
    lesson.point.position.y=0.8;lesson._process(0)
    check("lower endpoint removes twist",is_zero_approx(lesson.turns) and lesson.ring_position(8,0).is_equal_approx(Vector3(0.4,1.45,0)))
    lesson.point.position.y=1.6;lesson._process(0)
    check("upper endpoint makes one complete turn",is_equal_approx(lesson.turns,1) and lesson.ring_position(4,0).is_equal_approx(Vector3(0,0.85,-0.4)))
    check("changing turn keeps connectivity",lesson.faces==original_faces)
    geometry_checks(lesson,"full-turn shaft")
    lesson.point.position.y=3;check("control clamps above range",lesson.turns_from_height()==1)
    lesson.point.position.y=-2;check("control clamps below range",lesson.turns_from_height()==0)
    lesson.point.position=Vector3(1.1,1.2,0.4);lesson._process(0)
    var stored_points: Array=lesson.points.duplicate()
    old_mesh=lesson.surface.mesh
    var world_before: Vector3=lesson.surface.to_global(lesson.points[0])
    lesson.point.action_pressed.emit(lesson.point)
    check("carried trigger starts whole-object rotation",lesson.running)
    lesson._process(1)
    check("rotation advances at 0.4 radians per second",is_equal_approx(lesson.shaft.rotation.y,0.4))
    check("rotation moves the rendered body in world space",world_before.distance_to(lesson.surface.to_global(lesson.points[0]))>0.05)
    check("rotation leaves stored vertices and mesh resource unchanged",lesson.points==stored_points and lesson.surface.mesh==old_mesh)
    lesson.point.action_pressed.emit(lesson.point)
    var paused: Transform3D=lesson.shaft.transform
    lesson._process(1)
    check("second trigger stops at current pose",not lesson.running and lesson.shaft.transform.is_equal_approx(paused))
    check("pausing does not untwist the form",is_equal_approx(lesson.turns,0.5) and lesson.points==stored_points)
    var rod: MeshInstance3D=lesson.witness[5]
    check("witness follows stored first corner under parent rotation",rod.to_global(Vector3(0,-rod.mesh.height/2,0)).distance_to(lesson.shaft.to_global(lesson.points[5*lesson.sides]))<0.0001)
    var alternative=load(source.get_base_dir()+"/07_taller_shaft.gd").new()
    root.add_child(alternative);alternative.set_process(false)
    check("independent height/ring-resolution variation builds 206 positions",alternative.points.size()==206 and alternative.faces.size()==408)
    check("taller form keeps top turn and changes height",alternative.ring_position(16,0).is_equal_approx(Vector3(-0.4,3.85,0)))
    check("variation preserves original height and geometry",is_equal_approx(lesson.height,2.4) and lesson.points==stored_points)
    geometry_checks(alternative,"taller twelve-sided shaft")
    # Test the outward normals independently on the straight version, including both caps.
    alternative.point.position.y=0.8;alternative._process(0)
    var arrays: Array=alternative.surface.mesh.surface_get_arrays(0)
    var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    var outward := true
    var side_count: int=alternative.spans*alternative.sides*6
    for i in range(side_count):outward=outward and normals[i].dot(Vector3(positions[i].x,0,positions[i].z))>0
    for i in range(side_count,positions.size()):
        var expected:=Vector3.DOWN if positions[i].y<1 else Vector3.UP
        outward=outward and normals[i].dot(expected)>0.99
    check("actual generated normals face outward on sides and caps",outward)
    lesson.queue_free();alternative.queue_free();await process_frame
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed files; teacher-authored native assertions. Not a headset or comprehension test."},"  "))
    quit(0 if failures.is_empty() else 1)
