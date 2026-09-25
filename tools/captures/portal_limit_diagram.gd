extends SceneTree
var output: String
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
    output = OS.get_cmdline_user_args()[0]
    call_deferred("capture")
func check(ok: bool,what: String) -> void:
    checks += 1
    if not ok: failures.append(what)
func capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(2440,1320)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_4X
    root.add_child(viewport)
    var world := Node3D.new()
    viewport.add_child(world)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("f4f0e7")
    world.add_child(env)
    var diagrams: Array[Node3D] = []
    for i in range(3):
        var diagram := Node3D.new()
        diagram.set_script(load("res://commons/ui/limit_polygon_diagram.gd"))
        world.add_child(diagram)
        diagram.position.x = (i-1)*1.75
        diagram.set_sides([3,8,22][i])
        diagrams.append(diagram)
        var n: int = diagram.sides
        var vertices: PackedVector3Array = diagram.polygon.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        var measured := 0.0
        for k in range(n):
            var a := (vertices[k*6]+vertices[k*6+5])*0.5
            var b := (vertices[k*6+1]+vertices[k*6+2])*0.5
            measured += a.distance_to(b)/diagram.DRAW_RADIUS
        check(absf(measured-2.0*n*sin(PI/n))<0.00001,"Rendered chords have analytic perimeter at n=%d" % n)
        check(measured<TAU,"Finite diagram has positive perimeter gap at n=%d" % n)
        var mesh: Mesh = diagram.polygon.mesh
        diagram.set_sides(n)
        check(diagram.polygon.mesh==mesh,"Idle refresh preserves native mesh at n=%d" % n)
    var title: Label3D = diagrams[1]._label("How close is enough?",Vector3(0,1.37,0),84,Color("25333d"))
    title.font = load("res://commons/font/static/Roboto-Light.ttf")
    diagrams[1]._label("Three moments in the same comparison",Vector3(0,1.10,0),33,Color("667984"))
    diagrams[1]._label("The corner becomes harder to see. The gap remains.",Vector3(0,-1.16,0),35,Color("25333d"))
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.95
    camera.position = Vector3(0,0.14,5)
    camera.look_at(Vector3(0,0.14,0))
    camera.current = true
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    var picture := viewport.get_texture().get_image()
    check(picture.save_png(output+"/portals-visible-limit.png")==OK,"Native book capture saved")
    picture.resize(1400,757)
    picture.save_jpg(output+"/portals-visible-limit.jpg",0.92)
    FileAccess.open(output+"/capture-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Native production diagram rendered at three actual selectable counts; analytic lengths checked against rendered chords."},"  "))
    print("Diagram: ",checks," checks; ",failures)
    quit(0 if failures.is_empty() else 1)
