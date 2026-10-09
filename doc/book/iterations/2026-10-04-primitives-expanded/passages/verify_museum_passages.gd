extends SceneTree
## Actual one-hall museum portal transitions, in run_encounter_probe's private snapshot.
## Checks native standing-body space and support; does not claim headset comfort.

const ROUTE: Array[String] = ["Primitives_Ignorance", "Primitives_Godot", "Primitives_Columns", "Primitives_Profiles", "Primitives_Portals"]
var checks: Array = []
var halls: Array = []
var crossings: Array = []
var failures: Array[String] = []
var museum: Node3D
var navigation: Node3D
var folder: String

func _initialize() -> void:
    run.call_deferred()

func check(label: String, passed: bool) -> void:
    checks.append({"check": label, "passed": passed})
    if not passed:
        failures.append(label)
    print("[passage-proof] ", "PASS " if passed else "FAIL ", label)

func xyz(value: Vector3) -> Array:
    return [value.x, value.y, value.z]

func idle() -> bool:
    var started := Time.get_ticks_msec()
    while Time.get_ticks_msec() - started < 60000:
        if navigation != null and str(navigation.get("phase")) == "error":
            return false
        if navigation != null and not bool(navigation.get("busy")) and str(navigation.get("phase")) == "idle":
            await physics_frame
            return true
        await process_frame
    return false

func run() -> void:
    var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    folder = str(spec.run)
    museum = (load(folder + "museum_snapshot.tscn") as PackedScene).instantiate()
    museum.set("EM_CONTROL", folder + "control.json")
    museum.set("_hand_path", folder + "necklace_hand.json")
    museum.set("_overrides_path", folder + "em_overrides.json")
    museum.set("start_chapter", "primitives")
    museum.set("start_map", ROUTE[0])
    museum.set("plan_file", folder + "plan.json")
    root.add_child(museum)
    current_scene = museum
    var started := Time.get_ticks_msec()
    while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 60000:
        await process_frame
    navigation = museum.get("_portal_stream")
    check("Default portal coordinator exists", navigation != null)
    if navigation == null:
        finish()
        return
    # Disable automatic near-door detection; invoke the same crossing entrypoint explicitly.
    navigation.set_process(false)
    museum.call("flush_stamps")
    var ready := await idle()
    check("Initial hall reaches supported ready state", ready)
    if not ready:
        finish()
        return
    for i in ROUTE.size():
        await inspect_hall(ROUTE[i])
        if i == ROUTE.size() - 1:
            break
        var before := Time.get_ticks_msec()
        var accepted: bool = navigation.call("request_crossing", 1)
        check("Crossing accepted: " + ROUTE[i] + " -> " + ROUTE[i+1], accepted)
        var arrived := await idle() if accepted else false
        var current: Dictionary = navigation.get("_current")
        var actual := str(current.get("map", ""))
        check("Destination ready: " + ROUTE[i+1], arrived and actual == ROUTE[i+1])
        crossings.append({"from": ROUTE[i], "expected": ROUTE[i+1], "actual": actual,
            "accepted": accepted, "ready": arrived, "elapsed_ms": Time.get_ticks_msec()-before,
            "phase": navigation.get("phase"), "failure": navigation.get("failure")})
        if not arrived or actual != ROUTE[i+1]:
            break
    finish()

func inspect_hall(expected: String) -> void:
    var current: Dictionary = navigation.get("_current")
    var actual := str(current.get("map", ""))
    check("Resident hall is " + expected, actual == expected)
    check("Only one hall resident: " + expected, (museum.get("_segments") as Array).size() == 1)
    check("Supported arrival: " + expected, bool(navigation.call("_arrival_supported")))
    check("Loading-cell support: " + expected, bool(navigation.call("_supported", navigation.get("_cell_floor"))))
    var entry: Dictionary = navigation.get("_entry")
    var exit_data: Dictionary = navigation.get("_exit")
    check("Authored entry usable: " + expected, not bool(entry.get("invalid", false)))
    check("Authored exit usable: " + expected, not bool(exit_data.get("invalid", false)))
    var portals: Array = navigation.get("_portals")
    check("Forward doorway installed: " + expected, portals.any(func(p: Dictionary): return int(p.direction) == 1))
    var probes: Array = []
    var space: PhysicsDirectSpaceState3D = museum.get_world_3d().direct_space_state
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.7
    var excluded: Array[RID] = []
    var player: Node = museum.get("_player")
    if player is CollisionObject3D:
        excluded.append(player.get_rid())
    for portal: Dictionary in portals:
        var floor_ok := true
        var clearance_ok := true
        var obstructions: Array = []
        for step in range(10):
            var distance := 0.10 + 0.24 * step
            var p: Vector3 = portal.position + portal.inward * distance
            var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.25, p - Vector3.UP * 0.25, 1)
            ray.exclude = excluded
            var support := space.intersect_ray(ray)
            floor_ok = floor_ok and not support.is_empty() and float(support.get("normal", Vector3.ZERO).y) > 0.8
            var query := PhysicsShapeQueryParameters3D.new()
            query.shape = capsule
            query.transform.origin = p + Vector3.UP * 0.9
            query.collision_mask = 1
            query.exclude = excluded
            var hits := space.intersect_shape(query, 4)
            clearance_ok = clearance_ok and hits.is_empty()
            if not hits.is_empty():
                obstructions.append({"distance_inward": distance, "at": xyz(p),
                    "collider": str(hits[0].collider.get_path())})
        var label := expected + (" exit" if int(portal.direction) > 0 else " entrance")
        check("Continuous 2.26 m doorway approach floor: " + label, floor_ok)
        check("1.7 m standing capsule clears doorway approach: " + label, clearance_ok)
        probes.append({"direction": portal.direction, "doorway": xyz(portal.position),
            "inward": xyz(portal.inward), "floor_passed": floor_ok, "clearance_passed": clearance_ok,
            "obstructions": obstructions})
    halls.append({"map": actual, "arrival": xyz(navigation.get("_arrival")),
        "entry": str(entry), "exit": str(exit_data), "doorway_probes": probes})

func finish() -> void:
    var report := {"passed": failures.is_empty() and halls.size() == ROUTE.size(), "checks": checks,
        "failures": failures, "halls": halls, "crossings": crossings,
        "navigation_failure": navigation.get("failure") if navigation != null else "no coordinator",
        "events": navigation.get("events") if navigation != null else [],
        "scope": "Native actual-museum default portal coordinator and collision geometry, private runtime snapshot, explicit crossing requests. Not a headset, controller-input, frame-rate or comfort test."}
    FileAccess.open(folder + "report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
    print("PASSAGE PROOF ", checks.size()-failures.size(), "/", checks.size(), " checks; ", halls.size(), " halls")
    quit(0 if report.passed else 1)
