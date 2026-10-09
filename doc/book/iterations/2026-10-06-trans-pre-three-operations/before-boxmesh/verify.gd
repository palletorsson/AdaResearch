extends SceneTree
## Runs the printed main and edited variants. No lesson-owned nodes are supplied.
var world := Node3D.new()
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var prefix: String

func _initialize() -> void:
    run.call_deferred()

func check(id: String, passed: bool) -> void:
    checks.append({"id": id, "passed": passed})
    if not passed:
        failures.append(id)

func make(variant: String) -> Node3D:
    var study: Node3D = load(prefix + variant + "/lesson.gd").new()
    world.add_child(study)
    study.set_process(false)
    return study

func vertices(study: Node3D) -> PackedVector3Array:
    return study.cube.surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func corners(study: Node3D) -> PackedVector3Array:
    var result := PackedVector3Array()
    for p in study.cube.points:
        result.append(study.cube.to_global(p))
    return result

func distances_equal(a: PackedVector3Array, b: PackedVector3Array, factor: float = 1.0) -> bool:
    for i in a.size():
        for j in range(i + 1, a.size()):
            if absf(b[i].distance_to(b[j]) - a[i].distance_to(a[j]) * factor) > 0.00001:
                return false
    return true

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://" + args[0] + "/"
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    var baseline := make("still")
    var saved := vertices(baseline)
    var base_corners := corners(baseline)
    check("still/owns_visible_cube", baseline.cube.get_parent() == baseline and saved.size() == 36 and baseline.cube.edges.get_child_count() == 36)
    check("still/eight_twelve", baseline.cube.points.size() == 8 and baseline.cube.faces.size() == 12)
    check("still/starting_pose", baseline.cube.position.is_equal_approx(Vector3(0, 1, 0)) and baseline.cube.basis.is_equal_approx(Basis.IDENTITY))
    baseline._process(5.0)
    check("still/clock_does_not_require_motion", is_equal_approx(baseline.elapsed, 5.0) and corners(baseline) == base_corners)
    check("still/visual_not_physical", baseline.find_children("*", "CollisionShape3D", true, false).is_empty())

    var translated := make("translate")
    var moved := corners(translated)
    var displacement_ok := true
    for i in moved.size():
        displacement_ok = displacement_ok and (moved[i] - base_corners[i]).is_equal_approx(Vector3.RIGHT)
    check("translation/equal_displacement_all_corners", displacement_ok)
    check("translation/orientation_and_size_kept", translated.cube.basis.is_equal_approx(baseline.cube.basis) and distances_equal(base_corners, moved))
    check("translation/construction_kept", vertices(translated) == saved)

    var turned := make("turn")
    check("rotation/declared_y_axis", turned.cube.basis.is_equal_approx(Basis(Vector3.UP, PI / 4)))
    check("rotation/corner_moves", not corners(turned)[0].is_equal_approx(base_corners[0]))
    check("rotation/all_pair_distances_kept", distances_equal(base_corners, corners(turned)))
    check("rotation/origin_kept", turned.cube.position.is_equal_approx(baseline.cube.position))
    check("rotation/construction_kept", vertices(turned) == saved)

    var larger := make("scale")
    check("scale/every_distance_times_factor", distances_equal(base_corners, corners(larger), 1.5))
    check("scale/bottom_centre_fixed", larger.cube.position.is_equal_approx(baseline.cube.position))
    check("scale/top_reaches_2_5", larger.cube.to_global(Vector3(0, 1, 0)).is_equal_approx(world.to_global(Vector3(0, 2.5, 0))))
    check("scale/construction_kept", vertices(larger) == saved)

    var independent := make("other-angle")
    check("transfer/new_angle_on_same_body", independent.cube.basis.is_equal_approx(Basis(Vector3.UP, -PI / 6)) and distances_equal(base_corners, corners(independent)))
    check("transfer/neighbour_unaffected", vertices(baseline) == saved and baseline.cube.basis.is_equal_approx(Basis.IDENTITY))

    var half_positions := []
    for fps in [30, 120]:
        var rising := make("rise")
        for frame in range(1, int(fps * 2.5) + 1):
            rising._process(1.0 / fps)
            if frame in [int(fps / 2.0), fps, fps * 2, int(fps * 2.5)]:
                var seconds: float = float(frame) / fps
                var expected := Vector3(0, 1 + minf(seconds / 2.0, 1.0), 0)
                check("time/" + str(fps) + "/" + str(seconds), rising.cube.position.distance_to(expected) < 0.00001)
                if frame == fps:
                    half_positions.append(rising.cube.position)
        check("time/keeps_facing_size_and_data/" + str(fps), rising.cube.basis.is_equal_approx(Basis.IDENTITY) and vertices(rising) == saved and distances_equal(base_corners, corners(rising)))
    check("time/equal_elapsed_equal_pose", half_positions[0].is_equal_approx(half_positions[1]))

    var slower := make("slow")
    slower._process(2.0)
    check("time/double_duration_halfway", slower.cube.position.is_equal_approx(Vector3(0, 1.5, 0)))
    slower._process(2.0)
    check("time/double_duration_same_destination", slower.cube.position.is_equal_approx(Vector3(0, 2, 0)))

    var combined := make("combine")
    combined._process(1.0)
    check("combine/rise_in_study_y", combined.cube.position.is_equal_approx(Vector3(0, 1.5, 0)))
    check("combine/fixed_turn_and_size", combined.cube.basis.is_equal_approx(Basis(Vector3.UP, PI / 4).scaled(Vector3.ONE * 1.5)))
    check("combine/original_construction", vertices(combined) == saved)
    var restored := make("still")
    check("restore/rerun_original_values", corners(restored) == base_corners)

    # Godot itself must call _process, beyond controlled-delta comparisons.
    var automatic := make("rise")
    automatic.set_process(true)
    await create_timer(0.08).timeout
    automatic.set_process(false)
    check("engine/actual_process_callback", automatic.elapsed > 0 and automatic.cube.position.y > 1.0)
    var expected_y := 1.0 + minf(automatic.elapsed / 2.0, 1.0)
    check("engine/callback_uses_elapsed", absf(automatic.cube.position.y - expected_y) < 0.00001)
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("ASSERTIONS ", checks.size(), "; failures ", failures)
    world.free()
    quit(0 if failures.is_empty() else 1)
