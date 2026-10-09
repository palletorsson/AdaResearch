extends SceneTree
var out: String
var checks: Array = []
var evidence := {}
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

func closed(mesh: ArrayMesh) -> bool:
    var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    var edges := {}
    for i in range(0,vertices.size(),3):
        for pair in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,0)]:
            var a := Vector3i((vertices[i+pair.x]*100000).round())
            var b := Vector3i((vertices[i+pair.y]*100000).round())
            var key := "%s|%s" % [a,b] if a<b else "%s|%s" % [b,a]
            edges[key] = int(edges.get(key,0))+1
    for count in edges.values():
        if count!=2:
            return false
    return true

func run() -> void:
    room = load("res://study.tscn").instantiate()
    root.add_child(room)
    await frames(12)
    for i in room.specimens.size():
        var mesh: ArrayMesh = room.specimens[i].mesh
        check("Specimen %d has closed welded topology" % (i+1),closed(mesh))
        var arrays := mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var valid := true
        for j in vertices.size():
            valid = valid and vertices[j].is_finite() and normals[j].is_finite() and normals[j].length()>.99
        check("Specimen %d has finite nondegenerate geometry" % (i+1),valid)
    check("B outline changes before extrusion",room.specimens[0].mesh.get_aabb().size.x != room.specimens[1].mesh.get_aabb().size.x)
    check("B deformation retains cap triangle and boundary edge counts",room.specimens[0].mesh.get_meta("cap_triangles")==room.specimens[1].mesh.get_meta("cap_triangles") and room.specimens[0].mesh.get_meta("boundary_edges")==room.specimens[1].mesh.get_meta("boundary_edges"))
    var ts := TextServerManager.get_primary_interface()
    var rid: RID = room.font.get_rids()[0]
    for letter in ["O","B"]:
        var index := ts.font_get_glyph_index(rid,48,letter.unicode_at(0),0)
        var contours := ts.font_get_glyph_contours(rid,48,index)
        evidence[letter] = {"points":contours.points.size(),"contours":contours.contours.size()}
        check(letter+" exposes its outer outline and holes",contours.contours.size()==(2 if letter=="O" else 3))
    var body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    shape.shape = room.specimens[2].mesh.create_trimesh_shape()
    body.add_child(shape)
    root.add_child(body)
    await frames()
    var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
    check("O hole remains open through custom extrusion",space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,0,3),Vector3(0,0,-1))).is_empty())
    check("O rim is a solid surface",not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,.83,3),Vector3(0,.83,-1))).is_empty())
    body.queue_free()
    await frames(10)
    check("Native overview saved",root.get_texture().get_image().save_png(out.path_join("overview.png"))==OK)
    room.camera.position = Vector3(-1.7,2.5,6.3)
    room.camera.fov = 65
    room.camera.look_at(Vector3(-4.85,1.0,0))
    await frames(10)
    check("Before and after saved",root.get_texture().get_image().save_png(out.path_join("outline-change.png"))==OK)
    room.camera.position = Vector3(7.4,6.1,6.5)
    room.camera.look_at(Vector3(4.8,1.3,.05))
    await frames(10)
    check("Cross-section and twist saved",root.get_texture().get_image().save_png(out.path_join("profiles-above.png"))==OK)
    # A symbol-font probe uses the user's installed font, never copies it into
    # the distributable project. Confirm a real glyph before producing a mesh.
    var symbol_path := "C:/Windows/Fonts/seguisym.ttf"
    if FileAccess.file_exists(symbol_path):
        var symbols := FontFile.new()
        check("Local Segoe UI Symbol font loads",symbols.load_dynamic_font(symbol_path)==OK)
        var srid: RID = symbols.get_rids()[0]
        var selected := ""
        for cp in [0x2605]:
            var glyph := ts.font_get_glyph_index(srid,48,cp,0)
            if glyph==0:
                continue
            var contours := ts.font_get_glyph_contours(srid,48,glyph)
            if contours.has("points") and contours.points.size()>3:
                selected = String.chr(cp)
                evidence["symbol_font"] = {"font":symbols.get_font_name(),"code_point":"U+%04X" % cp,"contours":contours.contours.size(),"outline_points":contours.points.size(),"font_redistributed":false}
                break
        check("The symbol has usable vector contours",not selected.is_empty())
        if not selected.is_empty():
            var solid: ArrayMesh = load("res://glyph_solid.gd").make(symbols,selected,.65,true)
            check("Dingbat extrudes with closed topology",closed(solid))
            room.specimens[2].mesh = solid
            for child in room.get_children():
                if child is Label3D and child.text.begins_with("03 /"):
                    child.text = "03 / UNICODE SYMBOL"
            room.camera.position = Vector3(2.1,2.5,4.8)
            room.camera.look_at(Vector3(0,1.25,.1))
            await frames(10)
            check("Native dingbat capture saved",root.get_texture().get_image().save_png(out.path_join("dingbat.png"))==OK)
    var passed := true
    for item in checks:
        passed = passed and item.passed
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"glyphs":evidence,"scope":"Native prototype; not a general font importer or an XR interaction test"},"\t"))
    print(JSON.stringify({"passed":passed,"checks":checks.size(),"glyphs":evidence}))
    room.queue_free()
    await frames()
    quit(0 if passed else 1)
