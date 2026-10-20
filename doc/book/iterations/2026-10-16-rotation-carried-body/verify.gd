extends SceneTree

var world := Node3D.new()
var prefix := "res://normal/"
var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
    run.call_deferred()

func check(id: String, ok: bool) -> void:
    checks.append({"id": id, "passed": ok})
    if not ok:
        failures.append(id)
        print("FAIL ", id)

func close(a: Vector3, b: Vector3) -> bool:
    return a.distance_to(b) < 0.0001

func make(state: String, variant := "base") -> Node3D:
    var scene: PackedScene = load(prefix + state + "/" + variant + "/study.tscn")
    var study: Node3D = scene.instantiate()
    world.add_child(study)
    study.set_process(false)
    return study

func advance(study: Node3D, seconds: float, rate: int) -> void:
    for i in int(round(seconds * rate)):
        study._process(1.0 / rate)

func corners(body: MeshInstance3D) -> PackedVector3Array:
    var points := PackedVector3Array()
    for i in 8:
        points.append(body.to_global(body.mesh.get_aabb().get_endpoint(i)))
    return points

func rigid(before: PackedVector3Array, after: PackedVector3Array) -> bool:
    for i in 8:
        for j in range(i + 1, 8):
            if absf(before[i].distance_to(before[j]) - after[i].distance_to(after[j])) > 0.0001:
                return false
    return true

func same_outline(before: PackedVector3Array, after: PackedVector3Array) -> bool:
    for point in before:
        var found := false
        for candidate in after:
            if close(point, candidate): found = true
        if not found: return false
    return true

func incoming_translation() -> void:
    var study := make("incoming")
    check("incoming/dimensions", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
    check("incoming/start", close(study.travel.position, Vector3(-2, 1, 0)))
    study._process(2.0)
    check("incoming/direct_halfway", close(study.travel.position, Vector3(0, 2, 0)))
    study._process(2.0)
    check("incoming/direct_arrival", close(study.travel.position, Vector3(2, 3, 0)))
    study._process(8.0)
    check("incoming/clamped_arrival", close(study.travel.position, Vector3(2, 3, 0)))
    study.via_corner = true
    study.apply_pose(0.5)
    check("incoming/corner_halfway", close(study.travel.position, Vector3(-2, 3, 0)))
    check("incoming/still_level", study.travel.basis.is_equal_approx(Basis.IDENTITY))
    study.free()

func turn_checkpoint() -> void:
    var study := make("turn")
    check("turn/pivot_exists", study.pivot.get_parent() == study)
    check("turn/child_exists", study.travel.get_parent() == study.pivot)
    check("turn/no_mark_yet", study.travel.get_child_count() == 0)
    study._process(2.0)
    check("turn/centre_fixed", close(study.travel.global_position, study.to_global(Vector3(0, 1.2, 0))))
    check("turn/quarter_orientation", close(study.pivot.basis.x, Vector3(0, 0, -1)))
    study._process(6.0)
    check("turn/full_return", study.pivot.basis.is_equal_approx(Basis.IDENTITY))
    study.free()

func turns() -> void:
    for variant in ["base", "orbit", "vertical", "slow", "axis_length"]:
        for rate in [30, 120]:
            var study := make("complete", variant)
            var id: String = variant + "/" + str(rate)
            var vertical: bool = variant in ["vertical", "slow"]
            var centre := Vector3(0, 1.2, 0)
            var initial := Vector3.ZERO if variant == "base" else Vector3(2, 0, 0)
            var direction := Vector3(0, -1, 0) if vertical else Vector3(0, 0, -1)
            var quarter := Vector3.ZERO if variant == "base" else direction * 2.0
            var quarter_seconds := 4.0 if variant == "slow" else 2.0
            var mark: MeshInstance3D = null
            # Identify the lesson's second BoxBody without supplying or repairing it.
            for node in study.find_children("*", "MeshInstance3D", true, false):
                if node != study.travel: mark = node
            check(id + "/mark_exists", mark != null)
            check(id + "/pivot_parent", study.pivot.get_parent() == study)
            check(id + "/body_parent", study.travel.get_parent() == study.pivot)
            check(id + "/mark_parent", mark != null and mark.get_parent() == study.travel)
            check(id + "/initial_centre", close(study.travel.global_position, study.to_global(centre + initial)))
            check(id + "/dimensions_retained", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
            var mesh: Mesh = study.travel.mesh
            var before := corners(study.travel)
            var mark_start: Vector3 = mark.global_position if mark != null else Vector3.ZERO
            advance(study, quarter_seconds, rate)
            check(id + "/quarter_direction", close(study.pivot.basis.x, direction))
            check(id + "/quarter_centre", close(study.travel.global_position, study.to_global(centre + quarter)))
            check(id + "/fixed_local_offset", close(study.travel.position, initial))
            check(id + "/child_basis_inherited", study.travel.basis.is_equal_approx(Basis.IDENTITY))
            check(id + "/radius", absf(study.travel.global_position.distance_to(study.pivot.global_position) - initial.length()) < 0.0001)
            check(id + "/rigid_body", rigid(before, corners(study.travel)))
            check(id + "/same_mesh", study.travel.mesh == mesh)
            if mark != null:
                var witness := Vector3(0.11, -0.35, 0.2) if vertical else Vector3(0.2, 0.11, -0.35)
                check(id + "/mark_quarter_position", close(mark.global_position, study.to_global(centre + quarter + witness)))
                check(id + "/mark_local_fixed", close(mark.position, Vector3(0.35, 0.11, 0.2)))
                check(id + "/dark_mark", mark.material_override != null and mark.material_override.albedo_color.r < 0.1)
                check(id + "/mark_own_mesh", mark.mesh != mesh)
            advance(study, quarter_seconds, rate)
            check(id + "/half_centre", close(study.travel.global_position, study.to_global(centre - initial)))
            if variant == "base":
                check(id + "/outline_half_return", same_outline(before, corners(study.travel)))
                check(id + "/mark_has_not_returned", mark != null and not close(mark.global_position, mark_start))
            advance(study, quarter_seconds * 2.0, rate)
            check(id + "/full_centre_return", close(study.travel.global_position, study.to_global(centre + initial)))
            check(id + "/full_orientation_return", study.pivot.basis.is_equal_approx(Basis.IDENTITY))
            check(id + "/mark_full_return", mark != null and close(mark.global_position, mark_start))
            advance(study, quarter_seconds, rate)
            check(id + "/continues", close(study.pivot.basis.x, direction))
            check(id + "/elapsed_seconds", absf(study.elapsed - quarter_seconds * 5.0) < 0.0001)
            study.free()

func ownership_and_pose() -> void:
    var study := make("complete", "vertical")
    study.position.y = 2.0
    study.apply_pose(0.25)
    check("placement/raised_vertical_quarter", close(study.travel.global_position, world.to_global(Vector3(0, 1.2, 0))))
    var at: Transform3D = study.travel.global_transform
    study.apply_pose(0.25)
    check("pose/repeat_is_same_pose", study.travel.global_transform.is_equal_approx(at))
    check("pose/does_not_advance_clock", study.elapsed == 0.0)
    var another: MeshInstance3D = study.box(Vector3(0.5, 0.7, 0.9), Vector3(8, 2, 0))
    check("box/still_attaches_to_study", another.get_parent() == study and close(another.position, Vector3(8, 2, 0)))
    another.mesh.size = Vector3(9, 9, 9)
    check("box/independent_resources", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
    study.free()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://" + args[0] + "/"
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    world.rotation.y = 0.4
    incoming_translation()
    turn_checkpoint()
    turns()
    ownership_and_pose()
    var live := make("complete")
    live.set_process(true)
    await create_timer(0.08).timeout
    check("runtime/real_process_callback", live.elapsed > 0.0 and not live.pivot.basis.is_equal_approx(Basis.IDENTITY))
    live.free()
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size(), " FAILURES ", failures.size())
    quit(0 if failures.is_empty() else 1)
