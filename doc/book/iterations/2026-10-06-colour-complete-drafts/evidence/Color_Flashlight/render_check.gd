extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
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
    for x in range(pixel.x - 4, pixel.x + 5):
        for y in range(pixel.y - 4, pixel.y + 5):
            total += image.get_pixel(x, y)
    return total / 81.0

func rgb(value: Color) -> Array:
    return [value.r, value.g, value.b]

func run() -> void:
    root.mode = Window.MODE_MINIMIZED
    viewport = SubViewport.new()
    viewport.size = Vector2i(960, 640)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    viewport.add_child(stage)
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.035, 0.035, 0.045)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color.WHITE
    settings.ambient_light_energy = 0.035
    environment.environment = settings
    stage.add_child(environment)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 5.2
    camera.position = Vector3(0, 1.5, 5)
    stage.add_child(camera)
    camera.look_at(Vector3(0, 1.5, 0))
    camera.current = true
    var colours: Dictionary = {}
    for variant in ["separate", "blue", "overlap", "away", "choice"]:
        var study: Node3D = load("res://normal/" + variant + "/lesson.gd").new()
        stage.add_child(study)
        for i in 8:
            await process_frame
        RenderingServer.force_draw(false)
        var image := viewport.get_texture().get_image()
        check(variant + "/image_available", image != null and not image.is_empty())
        var left := sample(image, Vector3(-1, 1.5, 0.06))
        var right := sample(image, Vector3(1, 1.5, 0.06))
        colours[variant] = [left, right]
        samples[variant] = {"left_rgb": rgb(left), "right_rgb": rgb(right)}
        image.save_png(output_folder.path_join(variant + ".png"))
        study.free()
    var left: Color = colours.separate[0]
    var right: Color = colours.separate[1]
    check("separate/left_red", left.r > left.g + 0.15 and left.r > left.b + 0.15)
    check("separate/right_green", right.g > right.r + 0.15 and right.g > right.b + 0.15)
    var blue: Color = colours.blue[0]
    check("blue/left_changes_channel", blue.b > blue.r + 0.15 and blue.b > blue.g + 0.15)
    check("blue/green_pool_kept", colours.blue[1].is_equal_approx(right))
    var overlap: Color = colours.overlap[1]
    check("overlap/red_joins_green", overlap.r > right.r + 0.15 and overlap.g > overlap.b + 0.15 and overlap.r > overlap.b + 0.15)
    check("overlap/left_loses_red", colours.overlap[0].r < left.r - 0.15)
    check("away/left_loses_red", colours.away[0].r < left.r - 0.15)
    check("away/green_pool_kept", colours.away[1].is_equal_approx(right))
    FileAccess.open(output_folder.path_join("render-report.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures, "samples": samples, "renderer": RenderingServer.get_video_adapter_name(), "scope": "Isolated supplied rendering fixture; exact lesson variants. This does not test museum illumination or headset appearance."}, "  "))
    print("FLASHLIGHT RENDER ", checks.size() - failures.size(), "/", checks.size())
    quit(0 if failures.is_empty() else 1)
