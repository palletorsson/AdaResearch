extends Node3D
## A real GPU stencil test; this is not yet a traversable museum portal.
var camera: Camera3D
var mask: MeshInstance3D
var observations: Array[Dictionary] = []

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func quad(where: Vector3, size: Vector2, m: Material) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := QuadMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = m
    n.position = where
    add_child(n)
    return n

func _ready() -> void:
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.035,0.045,0.065)
    add_child(env)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 7.5
    camera.position = Vector3(0,0,8)
    add_child(camera)
    camera.current = true
    var writer := material(Color(1,1,1,0))
    writer.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    writer.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    writer.render_priority = -100
    writer.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
    writer.stencil_flags = BaseMaterial3D.STENCIL_FLAG_WRITE
    writer.stencil_reference = 1
    mask = quad(Vector3.ZERO, Vector2(3,4), writer)
    var reader := material(Color(0.1,0.55,1.0))
    reader.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    reader.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
    reader.stencil_flags = BaseMaterial3D.STENCIL_FLAG_READ
    reader.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_EQUAL
    reader.stencil_reference = 1
    quad(Vector3(0,0,-1),Vector2(10,7),reader)
    var frame := material(Color(0.92,0.86,0.77))
    for sign_value in [-1,1]:
        quad(Vector3(sign_value*1.6,0,0.2),Vector2(0.2,4.4),frame)
        quad(Vector3(0,sign_value*2.1,0.2),Vector2(3.4,0.2),frame)
    quad(Vector3(0.55,0,0.7),Vector2(0.5,1.2),material(Color(0.08,0.08,0.08)))
    var title := Label.new()
    title.text = "ADA / PORTAL FEASIBILITY\nGodot 4.6 — native stencil mask"
    title.position = Vector2(32,28)
    title.add_theme_font_size_override("font_size",25)
    add_child(title)
    var caption := Label.new()
    caption.text = "The blue plane is wider than the frame. Only its masked pixels appear.\nThe dark foreground block must still hide it. No teleportation or stereo test here."
    caption.position = Vector2(32,710)
    caption.add_theme_font_size_override("font_size",20)
    add_child(caption)
    if "--capture" in OS.get_cmdline_user_args():
        await capture()

func sample(image: Image, world: Vector3) -> Color:
    var p := camera.unproject_position(world)
    return image.get_pixel(int(p.x),int(p.y))

func blue(c: Color) -> bool:
    return c.b > 0.7 and c.b > c.r*1.4

func note(label: String, ok: bool) -> void:
    observations.append({"name":label,"passed":ok})

func capture() -> void:
    for i in range(8): await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var method := str(RenderingServer.get_current_rendering_method())
    image.save_png("res://stencil-"+method+".png")
    note("inside mask shows receiver",blue(sample(image,Vector3(-0.5,0,0))))
    note("outside mask hides receiver",not blue(sample(image,Vector3(2.2,0,0))))
    note("opaque foreground occludes masked receiver",not blue(sample(image,Vector3(0.55,0,0))))
    mask.visible = false
    for i in range(3): await get_tree().process_frame
    await RenderingServer.frame_post_draw
    image = get_viewport().get_texture().get_image()
    note("disabling writer removes receiver",not blue(sample(image,Vector3(-0.5,0,0))))
    var passed := true
    for item in observations: passed = passed and item.passed
    var output := {"passed":passed,"checks":observations,"renderer":method,"device":RenderingServer.get_video_adapter_name(),"scope":"desktop monoscopic mask only; no headset, crossing, recursive views or shadows"}
    FileAccess.open("res://stencil-"+method+".json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
    print("STENCIL FEASIBILITY: ",JSON.stringify(output))
    get_tree().quit(0 if passed else 1)
