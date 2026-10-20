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

func introduction() -> void:
    var study := make("incoming")
    check("incoming/nine_models", study.get_child_count() == 9)
    check("incoming/start", close(study.travel.position, Vector3(-4, 0.9, -1.4)))
    check("incoming/visual_dimensions", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
    check("incoming/independent_meshes", study.travel.mesh != study.grow.mesh)
    study._process(4.0)
    check("incoming/outward_four_seconds", close(study.travel.position, Vector3(-4, 0.9, 1.4)))
    study._process(4.0)
    check("incoming/return_eight_seconds", close(study.travel.position, Vector3(-4, 0.9, -1.4)))
    study.free()

func direct_checkpoint() -> void:
    var study := make("direct")
    check("direct/only_one_visual", study.get_child_count() == 1)
    study._process(2.0)
    check("direct/halfway", close(study.travel.position, Vector3(0, 2, 0)))
    study._process(2.0)
    check("direct/end", close(study.travel.position, Vector3(2, 3, 0)))
    study._process(8.0)
    check("direct/stops", close(study.travel.position, Vector3(2, 3, 0)))
    study.free()

func routes() -> void:
    for variant in ["base", "corner", "diagonal", "slow", "zero"]:
        for rate in [30, 120]:
            var study := make("complete", variant)
            var id: String = variant + "/" + str(rate)
            var first: Vector3 = Vector3(-2, 1, 0)
            var last: Vector3 = Vector3(2, 3, 2) if variant in ["diagonal", "slow"] else Vector3(2, 3, 0)
            if variant == "zero": last = first
            var half: Vector3 = Vector3(0, 2, 0) if variant == "base" else Vector3(-2, 3, 0)
            var quarter: Vector3 = Vector3(-1, 1.5, 0) if variant == "base" else Vector3(-2, 2, 0)
            var three_quarters: Vector3 = Vector3(1, 2.5, 0) if variant == "base" else Vector3(0, 3, 0)
            if variant in ["diagonal", "slow"]: three_quarters.z = 1.0
            if variant == "zero":
                half = first
                quarter = first
                three_quarters = first
            check(id + "/start", close(study.travel.position, first))
            check(id + "/same_dimensions", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
            check(id + "/one_instance", study.get_child_count() == 1 and study.travel.get_child_count() == 0)
            var mesh: Mesh = study.travel.mesh
            var before := corners(study.travel)
            var leg_time: float = 2.0 if variant == "slow" else 1.0
            advance(study, leg_time, rate)
            check(id + "/quarter", close(study.travel.position, quarter))
            advance(study, leg_time, rate)
            check(id + "/halfway", close(study.travel.position, half))
            advance(study, leg_time, rate)
            check(id + "/three_quarters", close(study.travel.position, three_quarters))
            advance(study, leg_time, rate)
            check(id + "/destination", close(study.travel.position, last))
            check(id + "/elapsed_seconds", absf(study.elapsed - leg_time * 4.0) < 0.0001)
            check(id + "/level", study.travel.basis.is_equal_approx(Basis.IDENTITY))
            check(id + "/same_mesh", study.travel.mesh == mesh)
            check(id + "/shape_fixed", rigid(before, corners(study.travel)))
            check(id + "/world_frame", close(study.travel.global_position, world.to_global(last)))
            advance(study, 10.0, rate)
            check(id + "/stays_arrived", close(study.travel.position, last))
            study.apply_pose(-2.0)
            check(id + "/lower_bound", close(study.travel.position, first))
            study.apply_pose(5.0)
            check(id + "/upper_bound", close(study.travel.position, last))
            study.free()

func pose_and_ownership() -> void:
    var study := make("complete", "corner")
    study.apply_pose(0.499999)
    var before: Vector3 = study.travel.position
    study.apply_pose(0.5)
    var at: Vector3 = study.travel.position
    study.apply_pose(0.500001)
    check("corner/no_jump", before.distance_to(at) < 0.0001 and study.travel.position.distance_to(at) < 0.0001)
    check("pose/does_not_advance_clock", study.elapsed == 0.0)
    study.apply_pose(0.0)
    var p0: Vector3 = study.travel.position
    study.apply_pose(0.25)
    var p1: Vector3 = study.travel.position
    study.apply_pose(0.5)
    var p2: Vector3 = study.travel.position
    study.apply_pose(0.75)
    var p3: Vector3 = study.travel.position
    check("corner/unequal_speed", absf(p0.distance_to(p1) - 1.0) < 0.0001 and absf(p2.distance_to(p3) - 2.0) < 0.0001)
    var another: MeshInstance3D = study.box(Vector3(0.5, 0.7, 0.9), Vector3(8, 2, 0))
    check("construction/function_still_returns_attached_visual", another.get_parent() == study and close(another.position, Vector3(8, 2, 0)))
    another.mesh.size = Vector3(9, 9, 9)
    check("construction/new_instance_owns_mesh", close(study.travel.mesh.size, Vector3(1.2, 0.2, 0.8)))
    study.free()

func run() -> void:
    var args := OS.get_cmdline_user_args()
    prefix = "res://" + args[0] + "/"
    root.add_child(world)
    world.position = Vector3(3, 0, 2)
    world.rotation.y = 0.4
    introduction()
    direct_checkpoint()
    routes()
    pose_and_ownership()
    var live := make("complete")
    live.set_process(true)
    await create_timer(0.08).timeout
    check("runtime/real_process_callback", live.elapsed > 0.0 and live.travel.position.x > -2.0)
    live.free()
    FileAccess.open(args[1], FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failure_ids": failures}, "  "))
    print("CHECKS ", checks.size(), " FAILURES ", failures.size())
    quit(0 if failures.is_empty() else 1)
