extends SceneTree
var output: String
var failures: Array[String] = []
var checks := 0
var measured: Array = []
func _initialize() -> void:
    output=OS.get_cmdline_user_args()[0]
    call_deferred("capture")
func check(value: bool, label: String) -> void:
    checks+=1
    if not value:failures.append(label)
func capture() -> void:
    var viewport := SubViewport.new()
    viewport.size=Vector2i(2440,1700)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d=Viewport.MSAA_4X
    root.add_child(viewport)
    var world := Node3D.new();viewport.add_child(world)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode=Environment.BG_COLOR;env.background_color=Color("f4f0e7")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color.WHITE;env.ambient_light_energy=0.55
    environment.environment=env;world.add_child(environment)
    var light := DirectionalLight3D.new()
    world.add_child(light);light.rotation_degrees=Vector3(-30,-35,0);light.light_energy=1.0
    var layout: Node3D = load("res://tools/captures/sphere_resolution_layout.gd").new()
    world.add_child(layout)
    await process_frame
    var reference: Array = JSON.parse_string(FileAccess.get_file_as_string("res://reference.json"))
    for i in range(3):
        var marked: MeshInstance3D = layout.pairs[i][0]
        var plain: MeshInstance3D = layout.pairs[i][1]
        var token: String=reference[i]["token"]
        var a: Array=marked.mesh.surface_get_arrays(0)
        var b: Array=plain.mesh.surface_get_arrays(0)
        check(a[Mesh.ARRAY_VERTEX]==b[Mesh.ARRAY_VERTEX],token+" same positions")
        check(a[Mesh.ARRAY_INDEX]==b[Mesh.ARRAY_INDEX],token+" same triangle connections")
        check(a[Mesh.ARRAY_NORMAL]==b[Mesh.ARRAY_NORMAL],token+" same shading normals")
        check(marked.material_override.albedo_color==plain.material_override.albedo_color,token+" same material colour")
        check(marked.basis.is_equal_approx(plain.basis),token+" same size and orientation")
        check(marked.get_node("MeshInspectionEdges").visible and not plain.get_node("MeshInspectionEdges").visible,token+" configured overlay difference")
        var data: Dictionary=load("res://commons/primitives/shared/mesh_inspection.gd").inspect(marked.mesh)
        measured.append({"token":token,"rings":marked.mesh.rings,"radial_segments":marked.mesh.radial_segments,"radius":marked.mesh.radius,"height":marked.mesh.height,"submitted":data.submitted,"with_area":data.surface_triangles})
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.2
    camera.position=Vector3(0,2.75,10);camera.look_at(Vector3(0,2.75,0));camera.current=true
    for i in range(10):await process_frame
    await RenderingServer.frame_post_draw
    var picture := viewport.get_texture().get_image()
    check(picture.save_png(output+"/sphere-visible-construction.png")==OK,"book figure saved")
    picture.resize(1600,1115);picture.save_jpg(output+"/sphere-visible-construction.jpg",0.92)
    var result := {"checks":checks,"failures":failures,"measured":measured,"scope":"Production artifact scenes and actual map configurations in an isolated book layout. No museum changes, headset or learner acceptance."}
    var f:=FileAccess.open(output+"/capture-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "))
    print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
