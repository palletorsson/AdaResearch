# Illustration fixture. Loads the unchanged, tested learner script.
# The floor, grid, camera and lights belong to this capture host only.
extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var world := Node3D.new()
    root.add_child(world)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.105, 0.12, 0.125)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.85, 0.88, 0.91)
    environment.environment.ambient_light_energy = 0.7
    environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45, -35, 0)
    sun.light_energy = 1.8
    world.add_child(sun)
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(5, 5)
    floor.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.21, 0.23, 0.24)
    material.roughness = 0.85
    floor.material_override = material
    world.add_child(floor)
    var skin = load("res://line_skin.gd")
    for i in range(-8, 9):
        for axis in 2:
            var line: MeshInstance3D = skin.new()
            line.mesh.top_radius = 0.002
            line.mesh.bottom_radius = 0.002
            line.material_override.albedo_color = Color(0.32, 0.35, 0.36)
            world.add_child(line)
            var a := Vector3(i * 0.25, 0.005, -2) if axis == 0 else Vector3(-2, 0.005, i * 0.25)
            var d := Vector3(0, 0, 4) if axis == 0 else Vector3(4, 0, 0)
            line.show_segment(a, d, 4.0)
    var lesson: Node3D = load("res://grid.gd").new()
    world.add_child(lesson)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.3
    camera.position = Vector3(1.0, 2.0, 5)
    world.add_child(camera)
    camera.look_at(Vector3(0, 1.15, 0))
    camera.current = true
    var route: Array[Vector3] = [Vector3(0.33,1.12,0.2), Vector3(0.78,0.93,0.14), Vector3(0.85,0.60,0.11), Vector3(0.1,0.52,0.27), Vector3(-0.6,0.62,-0.16), Vector3(-0.73,1.17,-0.08), Vector3(-0.27,1.37,0.04), Vector3(-0.1,1.0,0.38)]
    for p in route:
        lesson.point.position = p
        for frame in 3:
            await process_frame
    var output := OS.get_cmdline_user_args()[0]
    for pitch in [0.25, 0.5]:
        lesson.grid_step = pitch
        lesson._redraw_grid()
        for frame in 8:
            await process_frame
        await RenderingServer.frame_post_draw
        var destination := output.path_join("pitch-025.png" if pitch == 0.25 else "pitch-050.png")
        root.get_texture().get_image().save_png(destination)
    quit()
