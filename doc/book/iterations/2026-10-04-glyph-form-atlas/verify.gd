extends SceneTree
var out: String
var checks: Array = []
var evidence: Array = []
var room

func _initialize() -> void:
    out = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"check":label,"passed":passed})
    if not passed:
        push_error(label)

func frames(n: int = 3) -> void:
    for i in n:
        await physics_frame
    await process_frame
    await RenderingServer.frame_post_draw

func component(parent: Array[int], start: int) -> int:
    var p := start
    while parent[p]!=p:
        parent[p] = parent[parent[p]]
        p = parent[p]
    return p

func topology(mesh: ArrayMesh) -> Dictionary:
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var lookup := {}
    var parents: Array[int] = []
    var edges := {}
    var finite := true
    var min_area := INF
    var min_normal := INF
    var tiny_faces := 0
    for i in range(0,vertices.size(),3):
        var face: Array[int] = []
        var area := (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).length()
        min_area = minf(min_area,area)
        tiny_faces += 1 if area < .00000001 else 0
        finite = finite and area > .00000001
        for j in 3:
            var key := Vector3i((vertices[i+j]*100000).round())
            finite = finite and vertices[i+j].is_finite() and normals[i+j].is_finite() and normals[i+j].length() > .99
            min_normal = minf(min_normal,normals[i+j].length())
            if not lookup.has(key):
                lookup[key] = parents.size()
                parents.append(parents.size())
            face.append(lookup[key])
        for j in 3:
            var a := face[j]
            var b := face[(j+1)%3]
            parents[component(parents,a)] = component(parents,b)
            var key := Vector2i(mini(a,b),maxi(a,b))
            if not edges.has(key):
                edges[key] = [0,0]
            edges[key][0] += 1
            edges[key][1] += 1 if a<b else -1
    var roots := {}
    for i in parents.size():
        roots[component(parents,i)] = true
    var closed := true
    var oriented := true
    for e in edges.values():
        closed = closed and e[0]==2
        oriented = oriented and e[1]==0
    var chi := parents.size()-edges.size()+vertices.size()/3
    return {"closed_edges":closed,"oriented_edges":oriented,"finite_nondegenerate":finite,
        "components":roots.size(),"euler":chi,"total_genus":(2*roots.size()-chi)/2,
        "triangles":vertices.size()/3,"vertices_welded":parents.size(),"min_double_area":min_area,"min_normal_length":min_normal,"tiny_faces":tiny_faces}

func capture(file: String, at: Vector3, target: Vector3, fov: float = 52) -> void:
    room.camera.position = at
    room.camera.look_at(target)
    room.camera.fov = fov
    await frames(12)
    check("Native capture: "+file,root.get_texture().get_image().save_png(out.path_join(file))==OK)

func run() -> void:
    room = load("res://atlas.tscn").instantiate()
    root.add_child(room)
    await frames(24)
    var expect := [[1,1],[1,1],[1,2],[1,0],[1,1],[2,0]]
    for i in room.specimens.size():
        var mesh: ArrayMesh = room.specimens[i].mesh
        var data := topology(mesh)
        data["glyph"] = room.GLYPHS[i]
        data["name"] = room.TITLES[i]
        evidence.append(data)
        check("Body %d: each welded edge has two faces"%i,data.closed_edges)
        check("Body %d: consistent face winding"%i,data.oriented_edges)
        check("Body %d: finite vertices and nondegenerate triangles"%i,data.finite_nondegenerate)
        check("Body %d: expected separate components and handles"%i,data.components==expect[i][0] and data.total_genus==expect[i][1])
    # I's source has no hole: its new handle comes from closing the path.
    var straight: Array[Transform3D] = [Transform3D.IDENTITY,Transform3D(Basis.IDENTITY,Vector3(0,0,.5))]
    var straight_i: ArrayMesh = room.Sweep.make(room.sections[4],straight)
    check("Straight I has no handle; closing its sweep creates one",topology(straight_i).total_genus==0 and evidence[4].total_genus==1)
    # Real physics shapes for selected uses. This is not a player/VR test.
    var body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    shape.shape = room.specimens[0].mesh.create_trimesh_shape()
    body.add_child(shape)
    root.add_child(body)
    await frames()
    var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
    check("O preserves an open sightline through its centre",space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,2.7,3),Vector3(0,2.7,-3))).is_empty())
    check("O retains a solid lower rim",not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,.15,3),Vector3(0,.15,-3))).is_empty())
    var capsule := CapsuleShape3D.new()
    capsule.radius = .22
    capsule.height = 1.7
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = capsule
    query.transform = Transform3D(Basis.IDENTITY,Vector3(0,2.7,0))
    check("A raised 1.7m capsule fits in the O opening",space.intersect_shape(query).is_empty())
    query.transform.origin.y = .85
    check("A capsule at floor level meets the O sill",not space.intersect_shape(query).is_empty())
    body.queue_free()
    await frames()
    room.canvas.hide()
    await capture("overview.png",Vector3(19,21,29),Vector3(0,2.5,0),53)
    var files := ["passage.png","vessel.png","wells.png","channel.png","loop.png","two-bodies.png"]
    for i in 6:
        var centre: Vector3 = room.specimens[i].position
        var offset := Vector3(6.8,6.0,9.0)
        if i==3:
            offset = Vector3(-7.5,6.5,8.3)
        elif i==4:
            offset = Vector3(5.8,8,8.5)
        elif i==1 or i==2:
            offset = Vector3(6.2,8.5,8.4)
        await capture(files[i],centre+offset,centre+Vector3(0,2.0 if i!=4 else .65,0))
    await capture("inside-o.png",room.specimens[0].position+Vector3(0,2.7,1.7),room.specimens[0].position+Vector3(0,2.7,-6),78)
    var passed := true
    for item in checks:
        passed = passed and item.passed
    var report := {"passed":passed,"checks":checks,"bodies":evidence,"scope":"Native geometry and selected physics checks; no general self-intersection, fabrication or XR certification"}
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
    print(JSON.stringify({"passed":passed,"checks":checks.size(),"bodies":evidence}))
    room.queue_free()
    await frames()
    quit(0 if passed else 1)
