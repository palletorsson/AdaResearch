extends SceneTree
## A book arrangement of production court scenes, using their actual map tokens.
## The three copies keep the same geometry, pigments, placements and lighting.
var output: String
var checks := 0
var failures: Array[String] = []
const PAPER := Color("f4f0e7")
const INK := Color("25333d")
var signatures: Array = []
func _initialize() -> void:
    output = OS.get_cmdline_user_args()[0]
    call_deferred("capture")
func check(ok: bool,message: String) -> void:
    checks += 1
    if not ok: failures.append(message)
func label_at(host: Node,text: String,at: Vector2,size: Vector2,font_size: int,color: Color=INK,light: bool=false) -> void:
    var label := Label.new()
    label.position = at
    label.size = size
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font",load("res://commons/font/static/Roboto-Light.ttf" if light else "res://commons/font/static/Roboto-Regular.ttf"))
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    host.add_child(label)
func material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.9
    return m
func capture() -> void:
    var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reference.json"))
    var page := SubViewport.new()
    page.size = Vector2i(2520,1420)
    page.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(page)
    var paper := ColorRect.new()
    paper.color = PAPER
    paper.size = Vector2(2520,1420)
    page.add_child(paper)
    label_at(page,"What changes when you move?",Vector2(60,56),Vector2(2400,105),76,INK,true)
    label_at(page,"Five pyramids, four cubes, one arrangement",Vector2(60,171),Vector2(2400,58),31,Color("667984"))
    for view in range(3):
        var viewport := SubViewport.new()
        viewport.size = Vector2i(780,800)
        viewport.own_world_3d = true
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        viewport.msaa_3d = Viewport.MSAA_4X
        root.add_child(viewport)
        var world := Node3D.new()
        viewport.add_child(world)
        var environment := WorldEnvironment.new()
        environment.environment = Environment.new()
        environment.environment.background_mode = Environment.BG_COLOR
        environment.environment.background_color = PAPER
        environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        environment.environment.ambient_light_color = Color.WHITE
        environment.environment.ambient_light_energy = 0.45
        world.add_child(environment)
        var sun := DirectionalLight3D.new()
        sun.rotation_degrees = Vector3(-42,-28,0)
        sun.light_energy = 0.55
        sun.shadow_enabled = false
        world.add_child(sun)
        # Match the court's 5x5-metre raised deck, with a plain book finish.
        var deck := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(5,1,5)
        deck.mesh = box
        deck.position = Vector3(5.5,0.5,5.5)
        deck.material_override = material(Color("d4cec2"))
        world.add_child(deck)
        var state: Array = []
        for row: Dictionary in reference["placements"]:
            var subject: Node3D = load(row["scene"]).instantiate()
            for key: String in row["config"]:subject.set_meta("config_"+key,row["config"][key])
            subject.position = Vector3(float(row["position"][0]),float(row["position"][1]),float(row["position"][2]))
            subject.scale = Vector3.ONE*float(row["scale"])
            subject.rotation.y = deg_to_rad(float(row["rotation"]))
            world.add_child(subject)
            for camera: Camera3D in subject.find_children("*","Camera3D",true,false):camera.current=false
            var bounds := AABB()
            var first := true
            var mesh_state: Array = []
            for mesh: MeshInstance3D in subject.find_children("*","MeshInstance3D",true,false):
                var bb: AABB = mesh.global_transform*mesh.get_aabb()
                bounds = bb if first else bounds.merge(bb)
                first = false
                var arrays: Array = mesh.mesh.surface_get_arrays(0)
                var pigment: Color = mesh.material_override.albedo_color
                mesh_state.append([mesh.global_transform,arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_INDEX],pigment])
            state.append(mesh_state)
            if view==0:
                var expected: Array = row["bounds_position"]
                var extent: Array = row["bounds_size"]
                check(bounds.position.distance_to(Vector3(expected[0],expected[1],expected[2]))<0.0001 and bounds.size.distance_to(Vector3(extent[0],extent[1],extent[2]))<0.0001,"Native court bounds match museum placement at %s" % str(row["cell"]))
        signatures.append(state)
        var camera := Camera3D.new()
        world.add_child(camera)
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = 7.4
        if view==0:
            camera.position = Vector3(5.5,2.1,-8)
            camera.look_at(Vector3(5.5,2.1,5.5))
        elif view==1:
            camera.position = Vector3(12,7,-4)
            camera.look_at(Vector3(5.5,1.8,5.5))
        else:
            camera.position = Vector3(5.5,14,5.5)
            camera.look_at(Vector3(5.5,0,5.5),Vector3(0,0,-1))
        camera.current = true
        var picture := TextureRect.new()
        picture.position = Vector2(50+view*820,290)
        picture.size = Vector2(780,800)
        picture.texture = viewport.get_texture()
        page.add_child(picture)
        label_at(page,["01   ALIGNED","02   OBLIQUE","03   PLAN"][view],Vector2(50+view*820,1110),Vector2(780,50),28,Color("a2496a"))
        label_at(page,["Two corners hide two others.","The outlines separate.","The positions become legible."][view],Vector2(50+view*820,1163),Vector2(780,55),29)
    check(signatures[0]==signatures[1] and signatures[1]==signatures[2],"All three views retain identical mesh data, transforms and pigments")
    label_at(page,"Nothing in the court moved.",Vector2(60,1300),Vector2(2400,62),35,INK,true)
    for i in range(12):await process_frame
    await RenderingServer.frame_post_draw
    var image := page.get_texture().get_image()
    check(image.save_png(output+"/melencolia-one-arrangement.png")==OK,"Native book figure saved")
    image.resize(1512,852)
    image.save_jpg(output+"/melencolia-one-arrangement.jpg",0.93)
    FileAccess.open(output+"/capture-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Nine actual production scenes/configurations; bounds match the assembled museum; identical mesh data, transforms and pigment across three book views. Deck finish and lighting are adapted for the page. No new museum object."},"  "))
    print("Melencolia court: ",checks," checks; ",failures)
    quit(0 if failures.is_empty() else 1)
