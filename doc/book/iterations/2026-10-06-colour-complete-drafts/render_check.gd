extends SceneTree

var viewport: SubViewport
var camera: Camera3D
var stage := Node3D.new()
var folder: String
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var samples: Dictionary = {}

func _initialize() -> void:
    folder = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id":id,"passed":ok})
    if not ok:
        failures.append(id)
        print("FAIL ",id)

func settle() -> void:
    for i in 8:
        await physics_frame
        await process_frame

func sample(image: Image, position: Vector3) -> Color:
    var p := Vector2i(camera.unproject_position(position))
    var colour := Color(0,0,0,0)
    for x in range(p.x-2,p.x+3):
        for y in range(p.y-2,p.y+3):
            colour += image.get_pixel(x,y)
    return colour/25.0

func capture(name: String) -> Image:
    await settle()
    RenderingServer.force_draw(false)
    var image := viewport.get_texture().get_image()
    check(name+"/image", not image.is_empty())
    image.save_png(folder.path_join(name+".png"))
    return image

func make(hall: String) -> Node3D:
    var s: Node3D = load("res://normal/"+hall+"/start/lesson.gd").new()
    stage.add_child(s)
    s.set_process(false)
    s.set_physics_process(false)
    return s

func aim(at: Vector3, target: Vector3, size: float) -> void:
    camera.position = at
    camera.size = size
    camera.look_at(target)

func run() -> void:
    root.mode = Window.MODE_MINIMIZED
    viewport = SubViewport.new()
    viewport.size = Vector2i(1100,760)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    viewport.add_child(stage)
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.11,0.12,0.15)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color.WHITE
    settings.ambient_light_energy = 0.6
    environment.environment = settings
    stage.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45,-30,0)
    stage.add_child(light)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    stage.add_child(camera)
    camera.current = true
    var s := make("Color_Rainbow")
    aim(Vector3(0,0.6,5),Vector3(0,0.6,0),2.1)
    var image: Image = await capture("rainbow")
    var a := sample(image,Vector3(0,0.8,0))
    var b := sample(image,Vector3(0,1.0,0))
    var c := sample(image,Vector3(0,1.2,0))
    check("rainbow/three_distinct_bands",a.r>a.g and b.b>b.r and c.r>c.b)
    s.queue_free()
    await settle()
    s = make("Color_Pillar")
    s._process(0)
    aim(Vector3(6.6,1.4,13),Vector3(6.6,1.4,9.6),1.8)
    image = await capture("pillar-middle")
    var middle := sample(image,Vector3(6.75,1.25,9.62))
    s.point.position.y = 1.85
    s._process(0)
    aim(Vector3(6.6,2.0,13),Vector3(6.6,2.0,9.6),1.8)
    image = await capture("pillar-high")
    var high := sample(image,Vector3(6.75,1.85,9.62))
    check("pillar/value_rises",high.g>middle.g+0.1 and high.r>middle.r+0.05)
    s.queue_free()
    await settle()
    s = make("Color_Grid_Pallet")
    aim(Vector3(1.9,2.3,2.9),Vector3(0.64,0,0.64),2.2)
    image = await capture("grid-rule")
    var before := sample(image,Vector3(0.96,0.04,0.32))
    s.select_address(Vector2i(3,1))
    s.next_palette()
    s.paint_selected()
    s.select_address(Vector2i(0,0))
    image = await capture("grid-mark")
    var after := sample(image,Vector3(0.96,0.04,0.32))
    check("grid/retained_visible_mark",after.r>after.g+0.15 and absf(after.g-before.g)>0.1)
    s.queue_free()
    await settle()
    s = make("Color_Paint")
    aim(Vector3(0,1.5,6),Vector3(0,1.5,0),3.5)
    await settle()
    s.set_held(true)
    s.set_action("spray",true)
    for i in 100:
        s.point.position = Vector3(lerpf(-1.6,1.6,i/99.0),1.5+0.6*sin(i/99.0*TAU),1.5)
        s.manual_step(0.1)
    s.set_held(false)
    # Reveal the surface without the brush in front of it.
    s.point.visible = false
    image = await capture("paint-marks")
    var ink := sample(image,Vector3(0,1.5,0.02))
    var blank := sample(image,Vector3(0,2.5,0.02))
    check("paint/mark_and_blank",ink.g<blank.g-0.1 and blank.g>0.9)
    check("paint/ray_deposits",s.canvas.deposits>=95)
    s.queue_free()
    await settle()
    s = make("Color_Walls")
    var backing := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(6,4)
    backing.mesh = quad
    backing.position = Vector3(0,1.3,-2)
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = Color.WHITE
    backing.material_override = mat
    stage.add_child(backing)
    aim(Vector3(0,1.3,5),Vector3(0,1.3,0),3.6)
    image = await capture("walls-filter")
    var filtered := sample(image,Vector3(-1,1.25,0.03))
    s.toggle_filter()
    image = await capture("walls-opaque")
    var opaque := sample(image,Vector3(-1,1.25,0.03))
    check("walls/background_contributes",filtered.r>opaque.r+0.1)
    backing.queue_free()
    s.queue_free()
    await settle()
    FileAccess.open(folder.path_join("render-report.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failure_ids":failures,"renderer":RenderingServer.get_video_adapter_name(),"scope":"Exact draft examples in an isolated supplied camera/light fixture; not museum or headset captures."},"  "))
    print("RENDER ",checks.size()-failures.size(),"/",checks.size())
    quit(0 if failures.is_empty() else 1)
