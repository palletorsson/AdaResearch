extends SceneTree

const Triangle = preload("triangle_record.gd")
const BASE = "res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student/v3"

class SyntheticHand extends Node3D:
    var body: Node3D
    var target_pose: Vector3
    var driving: bool = false

    func _process(_delta: float) -> void:
        if driving: body.global_position = target_pose

    func _physics_process(_delta: float) -> void:
        if driving: body.global_position = target_pose

var checks: Array = []
var observations: Dictionary = {}
var host
var pointer

func _initialize() -> void:
    run.call_deferred()

func check(id: String, passed: bool, observed: Variant = null, expected: Variant = null) -> void:
    checks.append({"id": id, "passed": passed, "observed": observed, "expected": expected})
    print(("PASS " if passed else "FAIL ") + id)

func near(id: String, actual: float, expected: float, tolerance: float = 0.0001) -> void:
    check(id, absf(actual - expected) <= tolerance, actual, expected)

func vector_near(id: String, actual: Vector3, expected: Vector3, tolerance: float = 0.0001) -> void:
    check(id, actual.distance_to(expected) <= tolerance, str(actual), str(expected))

func model_case(id: String, coords: Array, expected_angles: Array, expected_area: float) -> void:
    var model = Triangle.new()
    model.points.assign(coords)
    var result = model.measure()
    observations[id] = result
    check(id + ".valid", result.valid, result.valid, true)
    if result.valid:
        for i in range(3):
            near(id + ".angle_" + str(i), result.angles[i], expected_angles[i])
        near(id + ".sum", result.sum, 180.0)
        near(id + ".area", result.area, expected_area)

func invalid_case(id: String, coords: Array) -> void:
    var model = Triangle.new()
    model.points.assign(coords)
    var result = model.measure()
    check(id + ".invalid", not result.valid, result)
    check(id + ".no_angles", result.angles.is_empty(), result.angles, [])
    near(id + ".no_sum", result.sum, 0.0)

func frames(count: int = 3) -> void:
    for i in range(count):
        await process_frame

func press_button(name: String) -> void:
    var area = host.get_node(name + "/InteractableAreaButton")
    area._on_button_entered(pointer)
    check(name + ".synthetic_area_press_" + str(checks.size()), area.pressed, area.pressed, true)
    area._on_button_exited(pointer)
    check(name + ".synthetic_area_release_" + str(checks.size()), not area.pressed, area.pressed, false)

func key(code: Key, pressed: bool = true, echo: bool = false) -> void:
    var event = InputEventKey.new()
    event.keycode = code
    event.pressed = pressed
    event.echo = echo
    host._unhandled_key_input(event)

func edge_check(id: String, index: int) -> void:
    var edge = host.edges[index]
    var half = edge.basis.y * edge.mesh.height * 0.5
    var start = host.place(host.model.points[index])
    var end = host.place(host.model.points[(index + 1) % 3])
    check(id + ".visible", edge.visible, edge.visible, true)
    vector_near(id + ".start", edge.position - half, start)
    vector_near(id + ".end", edge.position + half, end)

func lowest_host_y(mesh_node: MeshInstance3D) -> float:
    var box = mesh_node.get_aabb()
    var lowest = INF
    for i in range(8):
        var local = box.position + Vector3(box.size.x if i & 1 else 0.0, box.size.y if i & 2 else 0.0, box.size.z if i & 4 else 0.0)
        lowest = minf(lowest, host.to_local(mesh_node.to_global(local)).y)
    return lowest

func presentation_checks() -> void:
    var top = host.get_child(0)
    var table_top = top.position.y + top.mesh.size.y * 0.5
    near("v3.table_top_y", table_top, 1.0)
    var text_count = 0
    var outlines_removed = true
    var zero_outline_count = 0
    for child in host.get_children():
        if child is Label3D:
            text_count += 1
            if child == host.readout:
                outlines_removed = outlines_removed and child.outline_size == 6 and child.outline_modulate == Color.WHITE
            else:
                outlines_removed = outlines_removed and child.outline_size == 0
                if child.outline_size == 0: zero_outline_count += 1
    check("v3.six_labels", text_count == 6, text_count, 6)
    check("v3.final_label_outline_policy", outlines_removed)
    check("v3.five_labels_without_outline", zero_outline_count == 5, zero_outline_count, 5)
    near("v3.readout_outline_size", host.readout.outline_size, 6.0)
    check("v3.readout_white_outline", host.readout.outline_modulate == Color.WHITE, str(host.readout.outline_modulate), "WHITE")
    for name in ["Guide", "Reset"]:
        var button = host.get_node(name)
        var cap = button.get_node("Button/ButtonMesh")
        var area = button.get_node("InteractableAreaButton")
        var local_up = host.global_basis.inverse() * cap.global_basis.y
        vector_near("v3." + name + ".cap_axis_faces_table_up", local_up.normalized(), Vector3.UP)
        near("v3." + name + ".root_height", button.position.y, 1.03)
        var rest_low = lowest_host_y(cap)
        near("v3." + name + ".rest_cap_bottom", rest_low, 1.035)
        check("v3." + name + ".rest_cap_above_table", rest_low > table_top, rest_low, table_top)
        area._on_button_entered(pointer)
        await create_timer(0.15).timeout
        var pressed_low = lowest_host_y(cap)
        near("v3." + name + ".pressed_cap_bottom", pressed_low, 1.015)
        check("v3." + name + ".pressed_cap_above_table", pressed_low > table_top, pressed_low, table_top)
        check("v3." + name + ".press_moved_down", pressed_low < rest_low - 0.019, pressed_low - rest_low, -0.02)
        area._on_button_exited(pointer)
        await create_timer(0.15).timeout
        near("v3." + name + ".released_cap_returns", lowest_host_y(cap), rest_low)

func run() -> void:
    model_case("right_triangle", [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)], [90.0, 45.0, 45.0], 0.5)
    model_case("initial", [Vector2(-0.7, 0.4), Vector2(0.7, 0.4), Vector2(0, -0.6)], [55.00797980144134, 55.00797980144134, 69.98404039711732], 0.7)
    invalid_case("coincident", [Vector2.ZERO, Vector2.ZERO, Vector2(0, 1)])
    invalid_case("collinear", [Vector2.ZERO, Vector2(1, 0), Vector2(0.5, 0)])
    invalid_case("thin_rejected", [Vector2.ZERO, Vector2(1, 0), Vector2(0.5, 0.000001)])
    invalid_case("tiny_absolute_policy", [Vector2.ZERO, Vector2(0.000001, 0), Vector2(0, 0.000001)])
    var boundary = Triangle.new()
    boundary.points.assign([Vector2.ZERO, Vector2(1, 0), Vector2(0.5, 0.00002)])
    check("thin_above_policy.valid", boundary.measure().valid, boundary.measure())
    boundary.points.assign([Vector2.ZERO, Vector2.ZERO, Vector2(0, 1)])
    check("coincident_ab.no_parallel", boundary.parallel_ends().is_empty(), boundary.parallel_ends())

    var original = Triangle.new()
    original.points.assign([Vector2.ZERO, Vector2(0.8, 0), Vector2(0.2, 0.6)])
    var doubled = Triangle.new()
    doubled.points.assign([Vector2.ZERO, Vector2(1.6, 0), Vector2(0.4, 1.2)])
    var original_result = original.measure()
    var doubled_result = doubled.measure()
    observations.scaling = {"original": original_result, "doubled": doubled_result}
    check("scale.both_valid", original_result.valid and doubled_result.valid)
    near("scale.original_area", original_result.area, 0.24)
    near("scale.doubled_area", doubled_result.area, 0.96)
    for i in range(3):
        near("scale.angle_" + str(i), doubled_result.angles[i], original_result.angles[i])
        near("scale.side_ratio_" + str(i), doubled.points[i].distance_to(doubled.points[(i + 1) % 3]) / original.points[i].distance_to(original.points[(i + 1) % 3]), 2.0)

    var stage = Node3D.new()
    stage.name = "GhostStage"
    root.add_child(stage)
    current_scene = stage
    pointer = SyntheticHand.new()
    pointer.name = "ContinuousSyntheticHand"
    stage.add_child(pointer)
    host = load(BASE + "/minimal.tscn").instantiate()
    host.position = Vector3(4, 1, -3)
    host.rotation = Vector3(0.2, 0.65, -0.12)
    stage.add_child(host)
    await frames()
    await physics_frame
    await frames()
    check("host.name", host.name == "EuclidStudy", host.name, "EuclidStudy")
    vector_near("host.unit_scale", host.scale, Vector3.ONE)
    check("host.three_points", host.points.size() == 3, host.points.size(), 3)
    check("host.three_edges", host.edges.size() == 3, host.edges.size(), 3)
    check("host.three_labels", host.labels.size() == 3, host.labels.size(), 3)
    check("host.controls", host.has_node("Guide/InteractableAreaButton") and host.has_node("Reset/InteractableAreaButton"))
    for i in range(3):
        var point = host.points[i]
        check("host.point_mesh_" + str(i), point.get_child(0) is MeshInstance3D and point.get_child(0).mesh is SphereMesh and point.get_child(0).is_visible_in_tree())
        check("host.point_collision_" + str(i), point.get_child(1) is CollisionShape3D and point.get_child(1).shape is SphereShape3D)
        check("host.point_frozen_" + str(i), point.freeze)
        vector_near("host.initial_world_point_" + str(i), point.global_position, host.to_global(host.place(host.model.points[i])))
        vector_near("host.initial_label_" + str(i), host.labels[i].position, host.place(host.model.points[i]) + Vector3(0, 0.18, 0))
        edge_check("host.initial_edge_" + str(i), i)
    check("host.initial_corner_text", host.labels[0].text == "A: 55.01°" and host.labels[1].text == "B: 55.01°" and host.labels[2].text == "C: 69.98°", [host.labels[0].text, host.labels[1].text, host.labels[2].text])
    check("host.initial_readout", host.readout.text.contains("Measured sum 180.00° / area 0.700 m²"), host.readout.text)
    check("host.initial_face", host.face.mesh != null and host.face.mesh.get_surface_count() == 1)
    var vertices = host.face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    check("host.face_three_vertices", vertices.size() == 3, vertices.size(), 3)
    for i in range(3):
        vector_near("host.face_vertex_" + str(i), vertices[i], host.place(host.model.points[i]) + Vector3.DOWN * 0.018)
    check("host.initial_guide_visible", host.guide_on and host.guide.visible)
    vector_near("host.guide_center", host.guide.position, host.place(host.model.points[2]))
    vector_near("host.guide_direction", host.guide.basis.y, Vector3.RIGHT)
    near("host.guide_length", host.guide.mesh.height, 2.5)

    var before = host.model.points.duplicate()
    var measured_before = host.model.measure()
    press_button("Guide")
    check("button.guide_hides", not host.guide_on and not host.guide.visible)
    check("button.guide_preserves_points", host.model.points == before)
    check("button.guide_preserves_measurements", host.model.measure() == measured_before)
    press_button("Guide")
    check("button.guide_shows", host.guide_on and host.guide.visible)

    var point = host.points[0]
    point.on_desktop_grab(pointer)
    var hand_local = Vector3(1.7, 4.2, -1.4)
    var hand_world = host.to_global(hand_local)
    pointer.body = point
    pointer.target_pose = hand_world
    pointer.driving = true
    point.global_position = hand_world
    host._process(0)
    check("grab.held", point.held())
    check("grab.local_projection_clamp", host.model.points[0].distance_to(Vector2(1, -1)) < 0.0001, str(host.model.points[0]), "(1,-1)")
    vector_near("grab.sphere_stays_with_hand", point.global_position, hand_world)
    vector_near("grab.label_shows_projection", host.labels[0].position, Vector3(1, 1.3, -1))
    edge_check("grab.edge_0", 0)
    edge_check("grab.edge_2", 2)
    check("grab.other_points_unchanged", host.model.points[1] == before[1] and host.model.points[2] == before[2])
    var held_record = host.model.points.duplicate()
    press_button("Reset")
    check("button.reset_while_held_is_noop", host.model.points == held_record)
    point.action_pressed.emit(pointer)
    check("held_trigger.hides_guide", not host.guide_on and not host.guide.visible)
    check("held_trigger.preserves_points", host.model.points == held_record)
    for cycle in range(8):
        await physics_frame
        await process_frame
    vector_near("grab.after_frames_sphere_stays_with_hand", point.global_position, hand_world)
    pointer.driving = false
    point.on_desktop_drop(pointer)
    check("release.no_longer_held", not point.held())
    await physics_frame
    await frames(5)
    vector_near("release.projected_world_position", point.global_position, host.to_global(Vector3(1, 1.12, -1)))
    point.global_position += Vector3(2, 3, 4)
    host._physics_process(0)
    vector_near("release.physics_maintains_position", point.global_position, host.to_global(Vector3(1, 1.12, -1)))
    press_button("Reset")
    check("button.reset_restores_all_points", host.model.points == before)
    check("button.reset_preserves_hidden_guide", not host.guide_on and not host.guide.visible)
    key(KEY_G)
    check("keyboard.g_shows_guide", host.guide_on and host.guide.visible)
    key(KEY_G, true, true)
    key(KEY_G, false)
    check("keyboard.echo_and_release_ignored", host.guide_on and host.guide.visible)
    host.model.points[2] = Vector2(0.4, -0.9)
    key(KEY_R)
    check("keyboard.r_resets", host.model.points == before)
    check("keyboard.r_preserves_guide", host.guide_on and host.guide.visible)

    host.model.points.assign([Vector2.ZERO, Vector2(1, 0), Vector2(0.5, 0)])
    host.redraw()
    check("degenerate_host.no_face", host.face.mesh == null)
    check("degenerate_host.no_guide", not host.guide.visible and host.guide_on)
    check("degenerate_host.no_angle_labels", host.labels[0].text == "A: —" and host.labels[1].text == "B: —" and host.labels[2].text == "C: —", [host.labels[0].text, host.labels[1].text, host.labels[2].text])
    check("degenerate_host.refusal_text", host.readout.text.contains("No triangle reading: corners coincide or nearly align.") and not host.readout.text.contains("Measured sum"), host.readout.text)
    host.model.points.assign([Vector2.ZERO, Vector2.ZERO, Vector2(0, 1)])
    host.redraw()
    check("coincident_host.zero_edge_hidden", not host.edges[0].visible)
    check("coincident_host.no_face_guide", host.face.mesh == null and not host.guide.visible)
    host.model.points.assign([Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)])
    host.redraw()
    check("recovery.face_and_guide", host.face.mesh != null and host.guide.visible)
    check("recovery.corner_text", host.labels[0].text == "A: 90.00°" and host.labels[1].text == "B: 45.00°" and host.labels[2].text == "C: 45.00°")
    check("recovery.readout", host.readout.text.contains("Measured sum 180.00° / area 0.500 m²"), host.readout.text)
    near("recovery.calculated_sum", host.model.measure().sum, 180.0)
    await presentation_checks()
    var failures = checks.filter(func(item): return not item.passed)
    var result = {"probe": "v3_revision_primary_same_agent", "checks": checks, "observations": observations, "passed": failures.is_empty(), "checks_total": checks.size(), "failures": failures, "scope": "Same-agent revision rerun. Headless full host, geometry, continuous synthetic hand pose, supplied area-button callbacks, keyboard method dispatch, numerical cap clearance/up-facing and outline checks. No physical XR/render claim."}
    var output = FileAccess.open(BASE + "/primary_results.json", FileAccess.WRITE)
    output.store_string(JSON.stringify(result, "  "))
    output.close()
    print("GHOST_PRIMARY_RESULT ", JSON.stringify({"passed": result.passed, "checks_total": checks.size(), "failures": failures.size()}))
    stage.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
