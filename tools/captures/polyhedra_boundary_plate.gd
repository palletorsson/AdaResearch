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
    var plate: Node3D = load("res://commons/artifacts/polyhedra_boundary_plate/polyhedra_boundary_plate.tscn").instantiate()
    plate.set("show_mount", false)
    world.add_child(plate)
    await process_frame
    var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reference.json"))
    for stage_name in ["OpenCorner", "Hull"]:
        var stage: Node3D = plate.get_node(stage_name)
        for i in range(4):
            var raw: Array = reference["vertices"][i]
            var point := Vector3(float(raw[0]),float(raw[1]),float(raw[2]))
            var expected: Vector3 = plate.diagram_basis()*point*plate.MODEL_SCALE
            check(stage.get_node("Vertex%d" % i).position.is_equal_approx(expected),stage_name+" matches production vertex %d" % i)
        check(stage.find_children("Side*","MeshInstance3D",false,false).size()==3,stage_name+" retains three sides")
        check(stage.has_node("MissingBaseClosed")== (stage_name=="Hull"),stage_name+" missing-base state")
    var same_faces: bool = plate.OPEN_FACES.size()==reference["faces"].size()
    for f in range(3):
        for v in range(3):same_faces = same_faces and plate.OPEN_FACES[f][v]==int(reference["faces"][f][v])
    check(same_faces,"production face connectivity")
    check(plate.hull_shape.points.size()==4,"convex hull receives four points")
    # Cast into the base and end inside: the open surface lets this ray in,
    # while the convex shape blocks it at the missing visible face.
    var open_body := StaticBody3D.new()
    open_body.collision_layer=2;open_body.collision_mask=0
    world.add_child(open_body);open_body.position=Vector3(20,0,0)
    var open_shape := CollisionShape3D.new()
    var surface := ConcavePolygonShape3D.new()
    var face_vertices := PackedVector3Array()
    for face in plate.OPEN_FACES:
        for i in face: face_vertices.append(plate.VERTICES[i])
    surface.set_faces(face_vertices)
    surface.backface_collision=true
    open_shape.shape=surface;open_body.add_child(open_shape)
    var hull_body := StaticBody3D.new()
    hull_body.collision_layer=2;hull_body.collision_mask=0
    world.add_child(hull_body);hull_body.position=Vector3(24,0,0)
    var hull_collision := CollisionShape3D.new()
    hull_collision.shape=plate.hull_shape;hull_body.add_child(hull_collision)
    await physics_frame
    await physics_frame
    var space := world.get_world_3d().direct_space_state
    var through_open := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(20,-1,-0.2),Vector3(20,-0.3,-0.2),2))
    var into_hull := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(24,-1,-0.2),Vector3(24,-0.3,-0.2),2))
    check(through_open.is_empty(),"surface-only ray enters through absent base")
    check(not into_hull.is_empty(),"convex hull blocks same ray")
    if not into_hull.is_empty():check(absf(into_hull["position"].y+0.6)<0.005,"hull boundary at missing base")
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.45
    camera.position = Vector3(0,1.7,6)
    camera.look_at(Vector3(0,1.7,0))
    camera.current = true
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    check(viewport.get_texture().get_image().save_png(output+"/polyhedra-boundaries.png") == OK, "book capture")
    plate.queue_free()
    await process_frame
    plate = load("res://commons/artifacts/polyhedra_boundary_plate/polyhedra_boundary_plate.tscn").instantiate()
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
    check(viewport.get_texture().get_image().save_png(output+"/polyhedra-plate-spatial.png") == OK, "spatial capture")
    var result := {"checks": checks, "failures": failures, "scope": "Native production illustration scene in an isolated rendering project; no headset or assembled museum observation.", "image_size": [2440,1280]}
    var f := FileAccess.open(output+"/capture-checks.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(result,"  "))
    print(JSON.stringify(result))
    quit(0 if failures.is_empty() else 1)
