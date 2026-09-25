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
    var plate: Node3D = load("res://commons/artifacts/cube_diagonal_plate/cube_diagonal_plate.tscn").instantiate()
    plate.set("show_mount", false)
    world.add_child(plate)
    await process_frame
    var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reference.json"))
    for stage_name in ["FlatFace", "MovedFace"]:
        var moved: bool = stage_name=="MovedFace"
        var stage: Node3D = plate.get_node(stage_name)
        var expected: Array[Vector3] = []
        for i in range(4,8):
            var raw: Array = reference["vertices"][i]
            var p := Vector3(float(raw[0]),float(raw[1]),float(raw[2]))
            if moved and i==6: p+=Vector3(0,0,0.55)
            expected.append(p)
            var actual: Vector3 = stage.get_node("Vertex%d" % i).position-Vector3(0,0,0.009)
            check(actual.is_equal_approx(plate.project_point(p)), stage_name+" uses builder vertex %d" % i)
        for t in range(2):
            var face: MeshInstance3D = stage.get_node("Triangle%d" % t)
            var actual: PackedVector3Array = face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            for k in range(3):
                var index: int = int(reference["faces"][t][k])-4
                check(actual[k].is_equal_approx(plate.project_point(expected[index])),stage_name+" rendered connectivity %d:%d" % [t,k])
    var before: Array[Vector3] = plate.specimen_points(false)
    var after: Array[Vector3] = plate.specimen_points(true)
    var n0 := (before[1]-before[0]).cross(before[3]-before[0]).normalized()
    var n1 := (after[1]-after[0]).cross(after[3]-after[0]).normalized()
    var tilted := (after[2]-after[1]).cross(after[3]-after[1]).normalized()
    check(n0.is_equal_approx(n1),"triangle 4-5-7 stays fixed")
    check(n1.angle_to(tilted)>0.2,"triangle 5-6-7 tilts out of the initial plane")
    check(before[1]==after[1] and before[3]==after[3],"shared edge 5-7 stays fixed")
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.45
    camera.position = Vector3(0,1.7,6)
    camera.look_at(Vector3(0,1.7,0))
    camera.current = true
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    var clean := viewport.get_texture().get_image()
    check(clean.save_png(output+"/cube-hidden-diagonal.png") == OK, "book capture")
    clean.resize(1600,840)
    clean.save_jpg(output+"/cube-hidden-diagonal.jpg",0.9)
    plate.queue_free()
    await process_frame
    plate = load("res://commons/artifacts/cube_diagonal_plate/cube_diagonal_plate.tscn").instantiate()
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
    check(viewport.get_texture().get_image().save_png(output+"/cube-plate-spatial.png") == OK, "spatial capture")
    var result := {"checks": checks, "failures": failures, "scope": "Native production illustration scene in an isolated rendering project; no headset or assembled museum observation.", "image_size": [2440,1280]}
    var f := FileAccess.open(output+"/capture-checks.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(result,"  "))
    print(JSON.stringify(result))
    quit(0 if failures.is_empty() else 1)
