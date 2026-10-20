extends SceneTree

var observations: Array = []
var vp: SubViewport
var space: Node3D
var camera: Camera3D
var study: Node3D
var probe_quad: MeshInstance3D
var mode := "original"
var lesson := ""
var folder := ""
var errors := 0

func _initialize() -> void:
    if "variation" in OS.get_cmdline_user_args(): mode = "variation"
    call_deferred("_run")
    call_deferred("watchdog")

func watchdog() -> void:
    await create_timer(45.0).timeout
    check(false,"harness reached 45 second watchdog")
    finish()

func setup(which: String) -> void:
    lesson = which
    folder = "res://doc/book/iterations/2026-10-10-shaders-ghost-student/student/" + lesson + "/"
    vp = SubViewport.new()
    vp.size = Vector2i(512,512)
    vp.own_world_3d = true
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    space = Node3D.new()
    vp.add_child(space)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.03,0.03,0.03)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color.WHITE
    env.environment.ambient_light_energy = 0.3
    env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    space.add_child(env)
    var lamp := DirectionalLight3D.new()
    lamp.rotation_degrees = Vector3(-25,-25,0)
    lamp.light_energy = 1.0
    space.add_child(lamp)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.0
    camera.position = Vector3(5,0,4)
    space.add_child(camera)
    camera.look_at(Vector3(5,0,0))
    camera.current = true
    var script = load(folder+mode+"/shaping.gd")
    if script == null:
        check(false,"original host loads")
        finish()
        return
    study = script.new()
    space.add_child(study)

func make_quad(material: Material) -> void:
    probe_quad = MeshInstance3D.new()
    var q := QuadMesh.new()
    q.size = Vector2(2,2)
    probe_quad.mesh = q
    probe_quad.material_override = material
    probe_quad.position = Vector3(5,0,0)
    space.add_child(probe_quad)

func frame(count: int = 3) -> void:
    for i in count:
        await process_frame
        await RenderingServer.frame_post_draw

func move_control(at: Vector3) -> void:
    await physics_frame
    study.control.position = at
    PhysicsServer3D.body_set_state(study.control.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,study.control.global_transform)
    study.update_rule()

func capture(label: String) -> Image:
    await frame()
    var image := vp.get_texture().get_image()
    image.save_png(folder+mode+"-"+label+".png")
    return image

func pixel(image: Image, uv: Vector2) -> Color:
    return image.get_pixel(clampi(int(uv.x*512),0,511),clampi(int(uv.y*512),0,511))

func difference(a: Image,b: Image) -> float:
    var total := 0.0
    for y in range(0,512,4):
        for x in range(0,512,4):
            var ca := a.get_pixel(x,y); var cb := b.get_pixel(x,y)
            total += absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)
    return total / (128.0*128.0*3.0)

func check(ok: bool, label: String, detail = null) -> void:
    observations.append({"check":label,"passed":ok,"detail":detail})
    if not ok: errors += 1

func note(label: String, value) -> void:
    observations.append({"observation":label,"value":value})

func finish() -> void:
    print("GHOST_JSON:"+JSON.stringify({"lesson":lesson,"mode":mode,"errors":errors,"observations":observations}))
    quit(0 if errors == 0 else 2)
