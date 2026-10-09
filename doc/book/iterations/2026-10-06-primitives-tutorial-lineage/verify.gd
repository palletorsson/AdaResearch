extends SceneTree
# Native assertions against the exact printed programs. Synthetic input, not a headset test.
var checks: Array[Dictionary] = []
var failed: Array[String] = []
var world := Node3D.new()
var folder: String
var hall: String
var output: String

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, id: String) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failed.append(id)

func vertices(body: Node3D) -> PackedVector3Array:
    var surface: MeshInstance3D = body.surface
    if surface.mesh == null:
        return PackedVector3Array()
    return surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func normals(body: Node3D) -> PackedVector3Array:
    return body.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]

func closed(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    var edges := {}
    var centre := Vector3.ZERO
    for p in points:
        centre += p / points.size()
    for f in faces:
        var a := points[f.x]
        var b := points[f.y]
        var c := points[f.z]
        if (c - a).cross(b - a).dot((a + b + c) / 3.0 - centre) <= 0.000001:
            return false
        for e in [Vector2i(f.x, f.y), Vector2i(f.y, f.z), Vector2i(f.z, f.x)]:
            edges[e] = edges.get(e, 0) + 1
    for e in edges:
        if edges[e] != 1 or edges.get(Vector2i(e.y, e.x), 0) != 1:
            return false
    return true

func rendered_matches(body: Node3D, points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    var actual := vertices(body)
    if actual.size() != 3 * faces.size():
        return false
    var at := 0
    for f in faces:
        for i in [f.x, f.y, f.z]:
            if not actual[at].is_equal_approx(points[i]):
                return false
            at += 1
    return true

func frames(n: int = 5) -> void:
    for i in n:
        await physics_frame
        await process_frame

func seed_trace() -> void:
    # Use the actual preceding recorder. These test positions are declared synthetic input.
    var trace: Node3D = load("res://trace/trace.gd").new()
    world.add_child(trace)
    trace.set_process(false)
    for p in [Vector3(-0.45, 1.12, 0), Vector3(0, 1.8, 0), Vector3(0.45, 1.12, 0), Vector3(0, 1.5, 0.35)]:
        trace.point.position = p
        trace._process(0.016)
        await process_frame
    trace._save_trace(trace.point)
    await frames(2)
    var archive = load("res://trace/trace_archive.gd")
    var saved: Node3D = archive.load_drawing()
    check(saved != null and saved.get_child_count() == trace.positions.size() - 1, "incoming/real_trace_saves_geometry")
    saved.free()
    trace.free()

func face_recipe(a: int, b: int, c: int) -> Array[Vector3i]:
    return [Vector3i(a, b, c)]

func triangle(lesson: Node3D) -> void:
    # Initial indices can be collinear: explicitly choose another recorded triple through a variant.
    check(lesson.handles.size() == 3, "triangle/three_original_point_handles")
    check(lesson.points == [Vector3(0, 1.12, 0), Vector3(-0.45, 1.12, 0), Vector3(0, 1.8, 0)], "triangle/saved_entries_exact")
    lesson.handles[2].position = Vector3(0.45, 1.12, 0)
    lesson._process(0.0)
    check(lesson.face.surface.mesh == null, "triangle/collinear_is_empty")
    lesson.handles[2].position = Vector3(0, 1.8, 0)
    lesson._process(0.0)
    check(vertices(lesson.face).size() == 3, "triangle/one_rendered_face")
    check(lesson.face.edges.get_child_count() == 3, "triangle/three_edges")
    check(rendered_matches(lesson.face, lesson.points, [Vector3i(0, 1, 2)]), "triangle/vertices_match_handles")
    var first_normal := normals(lesson.face)[0]
    lesson.face.show_faces(lesson.points, face_recipe(0, 2, 1))
    check(normals(lesson.face)[0].dot(first_normal) < -0.9999, "triangle/reverse_front")
    check(lesson.face.surface.material_override.cull_mode == BaseMaterial3D.CULL_BACK, "triangle/front_is_one_sided")
    check(not lesson.face.show_faces(lesson.points, face_recipe(0, 0, 2)) and vertices(lesson.face).is_empty(), "triangle/duplicate_rejected")
    check(not lesson.face.show_faces(lesson.points, face_recipe(0, 9, 2)), "triangle/out_of_range_rejected")
    for point in lesson.handles:
        check(point.has_method("is_picked_up") and point.RADIUS == 0.14, "triangle/familiar_point_" + str(point.get_index()))
    var controller := XRController3D.new()
    world.add_child(controller)
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    controller.add_child(pickup)
    controller.global_position = lesson.handles[2].global_position
    await frames()
    pickup._pick_up_object(lesson.handles[2])
    controller.position += Vector3(0.2, 0.1, 0.1)
    await frames()
    check(lesson.handles[2].is_picked_up() and lesson.handles[2].global_position.is_equal_approx(controller.global_position), "triangle/real_pickup_moves_corner")
    lesson._process(0)
    check(rendered_matches(lesson.face, lesson.points, [Vector3i(0, 1, 2)]), "triangle/held_corner_redraws_face")
    pickup.drop_object()
    controller.free()

func polyhedra(lesson: Node3D) -> void:
    check(lesson.points.size() == 4 and lesson.faces.size() == 4, "polyhedra/four_vertices_four_faces")
    if lesson.points.size() != 4:
        return
    check(closed(lesson.points, lesson.faces), "polyhedra/closed_outward_tetrahedron")
    check(rendered_matches(lesson.body, lesson.points, lesson.faces), "polyhedra/rendered_connectivity")
    var base: Vector3 = (lesson.points[2] - lesson.points[0]).cross(lesson.points[1] - lesson.points[0]).normalized()
    var centre: Vector3 = (lesson.points[0] + lesson.points[1] + lesson.points[2]) / 3
    check(is_equal_approx((lesson.points[3] - centre).dot(base), -0.6), "polyhedra/apex_off_base_plane")
    var old := vertices(lesson.body)
    lesson.points[3] -= base * 0.2
    lesson.body.show_faces(lesson.points, lesson.faces)
    var now := vertices(lesson.body)
    var changed := 0
    for i in old.size():
        if not old[i].is_equal_approx(now[i]):
            changed += 1
    check(changed == 3, "polyhedra/shared_apex_updates_three_faces")
    check(closed(lesson.points, lesson.faces), "polyhedra/edited_apex_still_enclosed")
    check(lesson.find_children("*", "CollisionShape3D", true, false).is_empty(), "polyhedra/no_implied_collision")

func cube(lesson: Node3D) -> void:
    var a: Node3D = lesson.first
    var b: Node3D = lesson.second
    check(a.surface.get_parent() == a and a.edges.get_parent() == a and b.surface.get_parent() == b, "cube/visible_children_attached")
    check(a.points.size() == 8 and a.faces.size() == 12, "cube/eight_twelve")
    check(closed(a.points, a.faces) and closed(b.points, b.faces), "cube/both_closed_outward")
    check(a.points == b.points and a.faces != b.faces, "cube/diagonal_only_connectivity")
    check(rendered_matches(a, a.points, a.faces) and rendered_matches(b, b.points, b.faces), "cube/render_matches_recipes")
    var before := vertices(a)
    var saved_points: Array[Vector3] = a.points.duplicate()
    b.points[6] += Vector3(0, 0, 0.25)
    b.show_faces(b.points, b.faces)
    check(a.points == saved_points and vertices(a) == before, "cube/independent_instances")
    check(rendered_matches(b, b.points, b.faces), "cube/deformed_render")
    a.position += Vector3(2, 0, 1)
    check(a.points == saved_points and vertices(a) == before, "cube/placement_leaves_local_data")
    var c: Node3D = load(folder + "/cube_body.gd").new()
    world.add_child(c)
    check(c.points == saved_points and c.surface.mesh != a.surface.mesh, "cube/third_instance_from_class")
    c.free()

func generator(lesson: Node3D) -> void:
    for radius in [0.3, 0.45, 0.6]:
        var points: Array[Vector3] = lesson.octahedron_positions(radius)
        check(points.size() == 6, "generator/count_" + str(radius))
        for i in [0, 2, 4]:
            check(points[i].is_equal_approx(-points[i + 1]) and is_equal_approx(points[i].length(), radius), "generator/opposite_" + str(radius) + "/" + str(i))
        check(closed(points, lesson.FACES), "generator/outward_" + str(radius))
    var prior: Array[Vector3] = lesson.large_points.duplicate()
    lesson.small_points[0] += Vector3(0, 0.1, 0)
    check(lesson.large_points == prior, "generator/results_independent")
    check(lesson.octahedron_positions(0.3)[0] == Vector3(0.3, 0, 0), "generator/rule_unchanged_by_result_edit")

func resolution(lesson: Node3D) -> void:
    var point: Node3D = lesson.point
    var controller := XRController3D.new()
    world.add_child(controller)
    var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode = 4
    controller.add_child(pickup)
    controller.global_position = point.global_position
    await frames()
    var collider: SphereShape3D = point.find_children("*", "CollisionShape3D", true, false)[0].shape
    var radius := collider.radius
    check(point.find_children("*", "MeshInstance3D", true, false)[0].mesh == point.sphere, "resolution/controlled_resource_is_visible_resource")
    point.advance(5.0)
    check(point.sphere.rings == 16 and point.sphere.radial_segments == 32, "resolution/released_pauses")
    pickup._pick_up_object(point)
    check(point.is_picked_up(), "resolution/real_pickup")
    for dt in [0.04, 0.06, 0.2]:
        point.advance(dt)
    check(point.sphere.rings == 14 and point.sphere.radial_segments == 30, "resolution/two_time_steps")
    var counts := Vector2i(point.sphere.rings, point.sphere.radial_segments)
    point.reset_resolution()
    point.advance(0.3)
    check(Vector2i(point.sphere.rings, point.sphere.radial_segments) == counts, "resolution/frame_schedule_independent")
    point.advance(0.05)
    var remainder: float = point.elapsed
    pickup.drop_object()
    point.advance(10)
    check(is_equal_approx(point.elapsed, remainder) and point.sphere.rings == 14, "resolution/release_preserves_partial_interval")
    pickup._pick_up_object(point)
    point.advance(0.1)
    check(point.sphere.rings == 13, "resolution/regrab_continues")
    point.advance(20)
    check(point.sphere.rings == 1 and point.sphere.radial_segments == 4, "resolution/valid_lower_bounds")
    check(is_equal_approx(point.sphere.radius, 0.14) and is_equal_approx(point.sphere.height, 0.28) and collider.radius == radius, "resolution/size_and_collider_unchanged")
    check(lesson.comparison.sphere.rings == 16 and lesson.comparison.sphere.radial_segments == 32 and lesson.comparison.sphere != point.sphere, "resolution/neighbour_independent")
    point.reset_resolution()
    check(point.elapsed == 0 and point.sphere.rings == 16 and point.sphere.radial_segments == 32, "resolution/reset_geometry_and_clock")
    pickup.drop_object()
    lesson._process(0)
    check(lesson.message.text == "RINGS 16   SEGMENTS 32", "resolution/readout_matches_mesh")
    for name in ["rings_only", "segments_only"]:
        var variant: Node3D = load("res://variants/" + name + "/resolution_point.gd").new()
        world.add_child(variant)
        controller.global_position = variant.global_position
        pickup._pick_up_object(variant)
        variant.advance(1.2)
        var expected := Vector2i(8, 32) if name == "rings_only" else Vector2i(16, 24)
        check(Vector2i(variant.sphere.rings, variant.sphere.radial_segments) == expected, "resolution/" + name)
        pickup.drop_object()
        variant.free()
    controller.free()

func columns(lesson: Node3D) -> void:
    for sides in [4, 6, 8, 12, 16]:
        var points: Array[Vector3] = lesson.column_positions(lesson.PROFILE, 2.2, sides)
        check(points.size() == 6 * sides, "columns/count_" + str(sides))
        var ok := true
        for ring in range(6):
            for side in range(sides):
                var p := points[ring * sides + side]
                ok = ok and is_equal_approx(p.y, 2.2 * ring / 5) and is_equal_approx(Vector2(p.x, p.z).length(), lesson.PROFILE[ring])
        check(ok, "columns/height_and_profile_" + str(sides))
        var mesh: ArrayMesh = load(folder + "/column_surface.gd").make(points, sides)
        check(mesh.surface_get_array_len(0) == (5 * sides * 2 + sides * 2) * 3, "columns/sides_and_caps_" + str(sides))
        check(mesh_closed(mesh), "columns/closed_mesh_" + str(sides))
    var profile: Array[float] = [0.2, 0.5, 0.2]
    var changed: Array[Vector3] = lesson.column_positions(profile, 1.4, 8)
    check(changed.size() == 24 and is_equal_approx(changed[-1].y, 1.4) and is_equal_approx(changed[8].length(), Vector2(0.5, 0.7).length()), "columns/independent_profile_height_variant")

func key(p: Vector3) -> String:
    return "%d,%d,%d" % [roundi(p.x * 10000), roundi(p.y * 10000), roundi(p.z * 10000)]

func mesh_closed(mesh: ArrayMesh) -> bool:
    var a: Array = mesh.surface_get_arrays(0)
    var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
    var idx := PackedInt32Array()
    if a[Mesh.ARRAY_INDEX] != null:
        idx = a[Mesh.ARRAY_INDEX]
    var edges := {}
    var count := v.size() if idx.is_empty() else idx.size()
    for i in range(0, count, 3):
        var tri: Array[String] = []
        for j in 3:
            tri.append(key(v[i+j] if idx.is_empty() else v[idx[i+j]]))
        for j in 3:
            var e := tri[j] + ":" + tri[(j+1)%3]
            edges[e] = edges.get(e, 0) + 1
    for e in edges:
        var parts: PackedStringArray = e.split(":")
        if edges[e] != edges.get(parts[1] + ":" + parts[0], 0):
            return false
    return not edges.is_empty()

func profiles(lesson: Node3D) -> void:
    check(lesson.frames.size() == 5 and lesson.section["glyph"] == "O", "profiles/declared_outline_and_frames")
    check(lesson.frames[0].origin == Vector3(0, 1.1, 0) and lesson.frames[-1].origin == Vector3(0.5, 1.1, 1.6), "profiles/route_endpoints")
    check(mesh_closed(lesson.body.mesh), "profiles/closed_material_boundary")
    # Native physics ray against the produced mesh verifies the opening, not a hand-drawn proxy.
    var wall := StaticBody3D.new()
    var boundary := CollisionShape3D.new()
    boundary.shape = lesson.body.mesh.create_trimesh_shape()
    wall.add_child(boundary)
    world.add_child(wall)
    await frames()
    var space := world.get_world_3d().direct_space_state
    var axis := Vector3(0.5, 0, 1.6).normalized()
    var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1.1, 0) - axis, Vector3(0.5, 1.1, 1.6) + axis)
    ray.hit_back_faces = true
    check(space.intersect_ray(ray).is_empty(), "profiles/open_through_centre")
    ray.from = Vector3(0, 0.42, -0.2)
    ray.to = Vector3(0.5, 0.42, 1.8)
    check(not space.intersect_ray(ray).is_empty(), "profiles/lower_sill_exists")
    var original: Dictionary = lesson.section.duplicate(true)
    var route: Array[Transform3D] = []
    for f in lesson.frames:
        f.origin.x = -f.origin.x
        route.append(f)
    var changed: ArrayMesh = load(folder + "/profile_sweep.gd").make(lesson.section, route)
    check(lesson.section == original and mesh_closed(changed), "profiles/route_variant_keeps_outline")
    check(lesson.find_children("*", "CollisionShape3D", true, false).is_empty(), "profiles/lesson_does_not_claim_collision")
    wall.free()

func limits(lesson: Node3D) -> void:
    var circle = load(folder + "/circle_samples.gd")
    check(is_equal_approx(lesson.perimeter(circle.make(6, 1.0)), 6.0), "limits/hexagon_closing_edge")
    var previous := 0
    for tolerance in [0.05, 0.005]:
        lesson.choose_resolution(tolerance, 96)
        check(lesson.met and lesson.error <= tolerance and lesson.sides <= 96, "limits/tolerance_" + str(tolerance))
        check(lesson.sides >= previous, "limits/tighter_is_no_coarser_" + str(tolerance))
        previous = lesson.sides
    lesson.choose_resolution(0.000001, 12)
    check(not lesson.met and lesson.sides == 12 and lesson.error > 0.000001, "limits/budget_reports_unmet")
    lesson.choose_resolution(0.000001, 7)
    check(lesson.sides == 7, "limits/non_power_budget_respected")
    lesson.choose_resolution(10, 3)
    check(lesson.met and lesson.sides == 3, "limits/first_polygon_can_suffice")

func composition(lesson: Node3D) -> void:
    check(lesson.cubes.size() == 2 and lesson.point.has_method("is_picked_up"), "composition/known_bodies")
    var a: Node3D = lesson.cubes[0]
    var b: Node3D = lesson.cubes[1]
    check(closed(a.points, a.faces) and a.points == b.points, "composition/original_cube_geometry")
    check(a.position == lesson.places[0] and b.position == lesson.places[1], "composition/places_used")
    var before := vertices(a)
    var other := vertices(b)
    a.position = Vector3(1, 0, 0.4)
    b.position = Vector3(-0.5, 0, -0.6)
    check(vertices(a) == before and vertices(b) == other and a.surface.mesh != b.surface.mesh, "composition/arrangement_keeps_construction")
    check(is_equal_approx(lesson.point.position.y, 0.14) and lesson.point.freeze, "composition/sphere_rests_at_radius")
    var second: Node3D = load(folder + "/lesson.gd").new()
    world.add_child(second)
    check(second.cubes[0].position == second.places[0] and second.cubes[0].points == a.points, "composition/restart_reconstructs_script")
    second.free()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    hall = args[0]
    folder = "res://" + args[1]
    output = args[2]
    root.add_child(world)
    await seed_trace()
    var trace_hash := FileAccess.get_sha256("user://ada_student_trace.scn")
    var lesson: Node3D = load(folder + "/lesson.gd").new()
    world.add_child(lesson)
    lesson.set_process(false)
    if hall == "Point_Triangle_Context":
        lesson._process(0)
    await frames()
    match hall:
        "Point_Triangle_Context": await triangle(lesson)
        "Primitives_Polythedra": polyhedra(lesson)
        "Point_Animatedcube": cube(lesson)
        "Primitives_Ignorance": generator(lesson)
        "Primitives_Godot": await resolution(lesson)
        "Primitives_Columns": columns(lesson)
        "Primitives_Profiles": await profiles(lesson)
        "Primitives_Portals": limits(lesson)
        "Primitives_Melencolia": composition(lesson)
    check(FileAccess.get_sha256("user://ada_student_trace.scn") == trace_hash, "carry/original_trace_file_unchanged")
    var result := {"hall": hall, "checks": checks, "failure_ids": failed, "passed": failed.is_empty()}
    FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
    print(JSON.stringify({"hall": hall, "passed": failed.is_empty(), "checks": checks.size(), "failures": failed}))
    world.free()
    quit(0 if failed.is_empty() else 1)

