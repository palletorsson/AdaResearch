extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var colours: Dictionary = {}
var samples: Dictionary = {}
var output_folder := ""
var viewport: SubViewport
var camera: Camera3D
var stage := Node3D.new()

func _initialize() -> void:
    output_folder = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func sample(image: Image, position: Vector3) -> Color:
    var pixel := Vector2i(camera.unproject_position(position))
    var total := Color(0, 0, 0, 0)
    for x in range(pixel.x - 3, pixel.x + 4):
        for y in range(pixel.y - 3, pixel.y + 4):
            total += image.get_pixel(x, y)
    return total / 49.0

func run() -> void:
    root.mode = Window.MODE_MINIMIZED
    viewport = SubViewport.new()
    viewport.size = Vector2i(1100, 760)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    viewport.add_child(stage)
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.06, 0.065, 0.075)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color.WHITE
    settings.ambient_light_energy = 0.5
    environment.environment = settings
    stage.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    light.shadow_enabled = true
    stage.add_child(light)
    var floor_mesh := MeshInstance3D.new()
    var floor_shape := BoxMesh.new()
    floor_shape.size = Vector3(4, 0.1, 4)
    floor_mesh.mesh = floor_shape
    floor_mesh.position.y = -0.12
    var floor_material := StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.16, 0.17, 0.19)
    floor_mesh.material_override = floor_material
    stage.add_child(floor_mesh)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 1.9
    camera.position = Vector3(1.45, 1.3, 3.4)
    stage.add_child(camera)
    camera.look_at(Vector3(0.25, 0.3, 0.15))
    camera.current = true
    for variant in ["start", "red", "wide", "outside", "choice", "transfer"]:
        var study: Node3D = load("res://normal/" + variant + "/lesson.gd").new()
        stage.add_child(study)
        for i in 10:
            await process_frame
        RenderingServer.force_draw(false)
        var image := viewport.get_texture().get_image()
        check(variant + "/image_available", image != null and not image.is_empty())
        var colour := sample(image, Vector3(-0.35, 0.3, 0.021))
        colours[variant] = colour
        samples[variant] = [colour.r, colour.g, colour.b]
        image.save_png(output_folder.path_join(variant + ".png"))
        study.queue_free()
        await process_frame
    var initial: Color = colours.start
    check("start/red_blue_above_green", initial.r > initial.g + 0.1 and initial.b > initial.g + 0.1)
    var red: Color = colours.red
    check("red/red_dominates", red.r > red.g + 0.2 and red.r > red.b + 0.2)
    check("wide/red_reduced", colours.wide.r < initial.r - 0.04)
    check("wide/green_blue_unchanged", absf(colours.wide.g - initial.g) < 0.01 and absf(colours.wide.b - initial.b) < 0.01)
    check("outside/green_blue_above_red", colours.outside.g > colours.outside.r + 0.2 and colours.outside.b > colours.outside.r + 0.2)
    check("choice/green_above_red", colours.choice.g > colours.choice.r + 0.1)
    FileAccess.open(output_folder.path_join("render-report.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures, "samples": samples, "renderer": RenderingServer.get_video_adapter_name(), "scope": "Exact lesson variants in a supplied rendering fixture; no museum or headset capture."}, "  "))
    print("NAILS RENDER ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
