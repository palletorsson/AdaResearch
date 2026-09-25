extends SceneTree
## Render the actual artifact scene, never a separately redrawn diagram.
var output: String
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
    output = OS.get_cmdline_user_args()[0]
    call_deferred("capture")

func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failures.append(label)

func capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(2440, 1280)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_4X
    root.add_child(viewport)
    var world := Node3D.new()
    viewport.add_child(world)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("e8e4db")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color.WHITE
    env.ambient_light_energy = 0.7
    environment.environment = env
    world.add_child(environment)
    var plate: Node3D = load("res://commons/artifacts/triangle_construction_plate/triangle_construction_plate.tscn").instantiate()
    plate.set("show_mount", false)
    world.add_child(plate)
    await process_frame
    var first: Node3D = plate.get_node("Positions")
    for stage_name in ["Positions", "Boundary", "Face"]:
        var stage: Node3D = plate.get_node(stage_name)
        for letter in ["A", "B", "C"]:
            check(stage.get_node("Vertex"+letter).position.is_equal_approx(first.get_node("Vertex"+letter).position), stage_name+" same vertex "+letter)
        var expected_edges := 0 if stage_name == "Positions" else 3
        check(stage.find_children("Edge*", "MeshInstance3D", false, false).size() == expected_edges, stage_name+" edges")
        check(stage.has_node("TriangleFill") == (stage_name == "Face"), stage_name+" fill")
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.45
    camera.position = Vector3(0,1.7,6)
    camera.look_at(Vector3(0,1.7,0))
    camera.current = true
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    check(viewport.get_texture().get_image().save_png(output+"/triangle-construction.png") == OK, "book capture")
    plate.queue_free()
    await process_frame
    plate = load("res://commons/artifacts/triangle_construction_plate/triangle_construction_plate.tscn").instantiate()
    world.add_child(plate)
    var floor_mesh := MeshInstance3D.new()
    var floor_box := BoxMesh.new()
    floor_box.size = Vector3(10,0.05,8)
    floor_mesh.mesh = floor_box
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("c8c4ba")
    floor_mesh.material_override = floor_mat
    world.add_child(floor_mesh)
    floor_mesh.position.y = -0.03
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-40,-25,0)
    light.shadow_enabled = true
    world.add_child(light)
    camera.projection = Camera3D.PROJECTION_PERSPECTIVE
    camera.fov = 40
    camera.position = Vector3(1.6,2.15,4.2)
    camera.look_at(Vector3(0,1.35,0))
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    check(viewport.get_texture().get_image().save_png(output+"/triangle-plate-spatial.png") == OK, "spatial capture")
    var result := {"checks": checks, "failures": failures, "scope": "Native production illustration scene in an isolated rendering project; no headset or assembled museum observation.", "image_size": [2440,1280]}
    var f := FileAccess.open(output+"/capture-checks.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(result,"  "))
    print(JSON.stringify(result))
    quit(0 if failures.is_empty() else 1)
