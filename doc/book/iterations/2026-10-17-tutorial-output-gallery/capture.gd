extends SceneTree
# The capture stage supplies only presentation and deterministic interaction inputs.
# All objects and labels in the study are produced by unchanged learner scripts.
var output: String
var stage: Node3D
var camera: Camera3D
var floor_mesh: MeshInstance3D
var study: Node3D
var hall: String
var frames: Array = []
var checks: Array = []
var halls: Array = []
var trace_info := {}
var archive_hash := ""

func _initialize() -> void:
    output = OS.get_cmdline_user_args()[0]
    run.call_deferred()

func check(ok: bool, label: String) -> void:
    checks.append({"id": label, "passed": ok})
    if not ok:
        push_error(label)
        quit(1)

func stage_setup() -> void:
    stage = Node3D.new()
    root.add_child(stage)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.105, 0.125, 0.15)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.79, 0.90)
    env.ambient_light_energy = 0.7
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -28, 0)
    key.light_color = Color(1, 0.94, 0.88)
    key.light_energy = 1.7
    key.shadow_enabled = true
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25, 140, 0)
    fill.light_color = Color(0.7, 0.82, 1)
    fill.light_energy = 0.5
    stage.add_child(fill)
    floor_mesh = MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(200, 200)
    floor_mesh.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.20, 0.23, 0.28)
    material.roughness = 0.8
    floor_mesh.material_override = material
    floor_mesh.position.y = -0.03
    stage.add_child(floor_mesh)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.near = 0.01
    camera.far = 300
    stage.add_child(camera)
    camera.make_current()

func frame_view(target: Vector3, size: float, direction := Vector3(0.12, 0.16, 1)) -> void:
    camera.size = size
    camera.position = target + direction.normalized() * 12.0
    camera.look_at(target)

func begin(id: String, script_name := "lesson.gd") -> void:
    if is_instance_valid(study):
        study.free()
    hall = id
    halls.append(hall)
    study = load("res://sources/" + hall + "/" + script_name).new()
    stage.add_child(study)
    study.set_process(false)
    floor_mesh.position.y = -0.03
    camera.make_current()
    check(study.is_node_ready(), hall + "/ready")

func snap(state: String, action: String, values := {}) -> void:
    for i in range(4):
        await process_frame
    await RenderingServer.frame_post_draw
    var img := root.get_texture().get_image()
    var filename := hall + "--" + state + ".png"
    check(img.get_width() == 1200 and img.get_height() == 900, hall + "/" + state + "/dimensions")
    check(img.save_png(output + "/images/" + filename) == OK, hall + "/" + state + "/saved")
    frames.append({"hall": hall, "state": state, "file": "images/" + filename, "input": action,
        "values": values, "camera": str(camera.transform), "view_size": camera.size, "stage_floor_y": floor_mesh.position.y})
    print("CAPTURE ", hall, " / ", state)

func synthetic_pickup(point: Node3D) -> Node3D:
    var controller := XRController3D.new()
    stage.add_child(controller)
    controller.global_position = point.global_position
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    controller.add_child(pickup)
    await process_frame
    pickup._pick_up_object(point)
    check(point.is_picked_up(), hall + "/real_xrtools_pickup")
    return pickup

func run() -> void:
    stage_setup()
    begin("Point_Zero", "counter.gd")
    frame_view(Vector3.ZERO, 1.7, Vector3(0,0.02,1))
    floor_mesh.position.y = -0.7
    study.set_process(true)
    await snap("running", "Actual engine frame counter after startup; no replacement label.")
    check(study.label.text.is_valid_int(), "Point_Zero/count_is_integer")

    begin("Point_One", "point.gd")
    frame_view(Vector3(0,1.12,0), 1.1, Vector3(0.35,0.4,1))
    await snap("body", "Default script: sphere mesh and collider created in code.")
    check(study.point.get_child_count() == 2, "Point_One/mesh_and_shape")

    begin("Point_Coordinates", "point.gd")
    frame_view(Vector3(0,1.35,0), 2.6, Vector3(0,0.04,1))
    study._process(0)
    await snap("placed", "Default local/world readout.")
    var hand := await synthetic_pickup(study.point)
    hand.get_parent().global_position += Vector3(0.5,0.25,0)
    for i in range(4): await physics_frame
    hand.drop_object()
    study._process(0)
    check(study.point.position.distance_to(Vector3(0,1.12,0)) > 0.1, "Point_Coordinates/hand_moved_point")
    await snap("released", "Real XRTools pickup, synthetic controller moved +(.5,.25,0), then drop.")
    hand.get_parent().free()
    study.position = Vector3(2,0,0)
    study._process(0)
    frame_view(Vector3(2,1.35,0), 2.6, Vector3(0,0.04,1))
    await snap("reference-frames", "Move the study parent +2 m in world X. Point local coordinates stay unchanged.")

    begin("Point_Lines", "line.gd")
    frame_view(Vector3(0.5,1.35,0), 2.9, Vector3(0,0.06,1))
    study._process(0)
    await snap("two-ends", "Default endpoints; the line derives from their difference.")
    study.point_b.position = Vector3(1,1.8,0)
    study._process(0)
    await snap("new-end", "Assign endpoint B=(1,1.8,0); unchanged line code recalculates.")

    begin("Point_Trace", "trace.gd")
    frame_view(Vector3(0,1.35,0), 2.9, Vector3(0,0.06,1))
    var samples: Array[Vector3] = [Vector3(-0.6,1.12,0), Vector3(0.1,1.9,0),
        Vector3(0.65,1.25,0.25), Vector3(0.25,0.8,0.45), Vector3(-0.65,0.75,0.25), Vector3(-0.9,1.5,0.1)]
    for p in samples:
        study.point.position = p
        study._process(0)
        await process_frame
    var before: int = study.positions.size()
    study.point.position = study.positions[-1] + Vector3(0.01,0,0)
    study._process(0)
    check(study.positions.size() == before, "Point_Trace/subthreshold_not_recorded")
    # Use the real release signal and the supplied save callback; this is not a fixture archive.
    study.point.dropped.emit(study.point)
    for i in range(4): await process_frame
    var archive_path := "user://ada_student_trace.scn"
    check(FileAccess.file_exists(archive_path), "Point_Trace/release_saved_archive")
    archive_hash = FileAccess.get_sha256(archive_path)
    DirAccess.make_dir_recursive_absolute(output + "/generated")
    check(DirAccess.copy_absolute(ProjectSettings.globalize_path(archive_path), output + "/generated/ada_student_trace.scn") == OK, "Point_Trace/archive_exported")
    trace_info = {"sha256": archive_hash, "positions": str(study.positions), "count": study.positions.size(),
        "frame": "PointStudy local metres", "producer": "Point_Trace", "consumers": ["Point_Line_Grid", "Point_Triangle_Context", "Primitives_Polythedra"]}
    var original: Array[Vector3] = study.positions.duplicate()
    check(study.trail.get_child_count() == original.size() - 1, "Point_Trace/one_segment_per_pair")
    await snap("recorded", "Six deterministic positions fed to the real recorder; +.01 m ignored; synthetic dropped signal saves.", {"points": study.positions.size()})

    begin("Point_Line_Grid", "grid.gd")
    frame_view(Vector3(-0.1,1.4,0), 4.6, Vector3(0,0.12,1))
    check(study.positions == PackedVector3Array(original), "Point_Line_Grid/same_original_record")
    await snap("quarter-grid", "Load Trace archive; original pink and independent green snapped copy; step=.25 m.")
    study.grid_step = 0.5
    study._place_on_grid()
    check(study.positions == PackedVector3Array(original), "Point_Line_Grid/original_kept_after_edit")
    await snap("half-grid", "Change grid_step to .5 m; re-place only the copy.")
    check(FileAccess.get_sha256(archive_path) == archive_hash, "Point_Line_Grid/archive_unchanged")

    begin("Point_Triangle_Context")
    study._process(0)
    check(study.points == original.slice(0,3), "Triangle/same_first_three_positions")
    frame_view(Vector3(-0.15,1.5,0), 2.3, Vector3(0,0.05,1))
    await snap("face", "Load the same archive; use its first three positions for one face.")
    check(FileAccess.get_sha256(archive_path) == archive_hash, "Triangle/archive_unchanged")

    begin("Primitives_Polythedra")
    check(study.points.slice(0,3) == original.slice(0,3) and study.points.size() == 4, "Polyhedra/three_carried_one_added")
    frame_view(Vector3(-0.15,1.4,-0.2), 2.4, Vector3(0.65,0.3,1))
    await snap("enclosure", "Same first three recorded positions; add fourth position .6 m behind their plane.")
    check(FileAccess.get_sha256(archive_path) == archive_hash, "Polyhedra/archive_unchanged")
    trace_info["unchanged_after_consumers"] = true

    begin("Point_Animatedcube")
    frame_view(Vector3(0,1.2,0), 3.4, Vector3(0.25,0.3,1))
    await snap("diagonals", "Two face-list cubes; change the front diagonal of the second, retaining its corners.")

    begin("Primitives_Ignorance")
    frame_view(Vector3(0,1.1,0), 3.1, Vector3(0.28,0.3,1))
    await snap("generated", "One opposite-axis position rule evaluated at radii .3 and .6.")

    begin("Primitives_Godot")
    frame_view(Vector3(0,1.3,0), 1.8, Vector3(0,0.12,1))
    study._process(0)
    await snap("smooth", "Two independent SphereMesh resources at the initial resolution.")
    hand = await synthetic_pickup(study.point)
    study.point.advance(4.5)
    hand.drop_object()
    study._process(0)
    check(study.point.sphere.radial_segments == 4 and study.point.sphere.rings == 1, "Primitives_Godot/held_reduces_resolution")
    check(study.comparison.sphere.radial_segments == 32, "Primitives_Godot/neighbour_independent")
    await snap("held", "Real XRTools pickup; feed 4.5 s to advance; release. The comparison retains its resolution.")
    hand.get_parent().free()

    begin("Primitives_Columns")
    frame_view(Vector3(0,1.1,0), 5.5, Vector3(0.22,0.3,1))
    await snap("family", "Same six-ring profile and 2.2 m height; 4, 6, 8, 12, 16 sides, left to right.")

    begin("Primitives_Profiles")
    frame_view(Vector3(0.25,1.1,0.8), 2.9, Vector3(-0.25,0.18,-1))
    await snap("letter", "Font O outline, including its hole, swept across five supplied frames.")

    begin("Primitives_Portals")
    frame_view(Vector3(0,1.3,0), 2.8, Vector3(0,0.65,1))
    await snap("bounded", "Run the bounded resolution search at tolerance .01 m, budget 96.", {"sides":study.sides,"error":study.error,"met":study.met})
    check(study.met and study.sides <= 96, "Primitives_Portals/tolerance_inside_budget")

    begin("Primitives_Melencolia")
    frame_view(Vector3(-0.05,0.5,0), 3.1, Vector3(0.4,0.4,1))
    await snap("arrangement", "Place two existing CubeBody instances and one PointBody; no new mesh generator.")

    begin("Trans_Pre")
    frame_view(Vector3(0,1.3,0), 2.8, Vector3(0.35,0.3,1))
    study._process(0)
    await snap("start", "BoxBody replaces the earlier face-list cube. Evaluate the running body's initial pose.")
    study._process(1)
    await snap("one-second", "Feed one second to the unchanged _process; position, rotation and scale vary together.")

    begin("Trans_Introduction")
    floor_mesh.position.y = -1.1
    frame_view(Vector3(0,0.7,0), 10.2, Vector3(0.18,0.5,1))
    study.apply_pose(0)
    await snap("start", "Three studies at t=0. Stage floor lowered to show the complete centred scaling box.")
    study.apply_pose(1)
    await snap("end", "Same three studies at t=1: travel, grow, turn. Same comparison camera.")

    begin("Trans_Translation")
    frame_view(Vector3(0,2,0), 6.2, Vector3(0,0.2,1))
    for t in [0.0, 0.5, 1.0]:
        study.apply_pose(t)
        await snap("direct-" + str(int(t * 100)), "Evaluate apply_pose at t=" + str(t) + "; direct route.", {"t":t,"position":str(study.travel.position)})
    study.via_corner = true
    study.apply_pose(0.5)
    await snap("corner-50", "Set via_corner=true; same endpoints, different route at t=.5.")

    begin("Trans_Rotation")
    frame_view(Vector3(0,1.2,0), 2.5, Vector3(0.3,0.65,1))
    study.apply_pose(0)
    await snap("zero", "Same slab dimensions; parent pivot and visible mark, t=0.")
    study.apply_pose(0.25)
    await snap("quarter-turn", "Change only t to .25; rotate parent by 90 degrees.")

    begin("Trans_Scale")
    frame_view(Vector3(0.55,1.3,0), 4.9, Vector3(0.25,0.22,1))
    for pose in [Vector3.ONE, Vector3.ONE * 4, Vector3(4,1,1)]:
        study.apply_pose(pose)
        var id := "small" if pose == Vector3.ONE else ("large" if pose.y == 4 else "width")
        await snap(id, "Reuse BoxBody and parent pattern; new three-piece doorway. apply_pose(" + str(pose) + "). Sphere unchanged.")

    begin("Trans_Body")
    frame_view(Vector3(0.55,1.3,0), 4.9, Vector3(0.25,0.22,1))
    var input_camera := Camera3D.new()
    stage.add_child(input_camera)
    for distance in [4.0, 2.5, 1.0]:
        input_camera.position = Vector3(0,1.65,distance)
        input_camera.make_current()
        study._process(0)
        camera.make_current()
        var expected := lerpf(4.0, 1.0, (distance-1.0)/3.0)
        check(is_equal_approx(study.pivot.scale.x, expected), "Trans_Body/camera_response_" + str(distance))
        await snap("distance-" + str(distance).replace(".", "_"), "Real viewport camera input at horizontal distance " + str(distance) + " m; switch to fixed presentation camera after computing pose.", {"distance":distance,"scale":expected})
    input_camera.free()
    study.free()
    study = null
    var report := {"passed":true,"halls":halls,"frames":frames,"checks":checks,"trace":trace_info}
    var file := FileAccess.open(output + "/native.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  "))
    file.close()
    print("GALLERY PASS ", frames.size(), " frames; ", checks.size(), " checks")
    quit(0)
