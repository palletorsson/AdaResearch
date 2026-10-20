extends SceneTree

const BASE = "res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student"

# A synthetic hand supplies a pose continuously, as a tracked hand would.
# This is test input only; it never alters the lesson's model or renderer.
class SyntheticHand extends Node3D:
    var body: Node3D
    var target_pose: Vector3
    var driving: bool = false

    func _process(_delta: float) -> void:
        if driving: body.global_position = target_pose

    func _physics_process(_delta: float) -> void:
        if driving: body.global_position = target_pose

var checks: Array = []
var samples: Array = []

func _initialize() -> void:
    run.call_deferred()

func check(id: String, passed: bool, observed: Variant = null, expected: Variant = null) -> void:
    checks.append({"id": id, "passed": passed, "observed": observed, "expected": expected})
    print(("PASS " if passed else "FAIL ") + id)

func run() -> void:
    var stage = Node3D.new()
    root.add_child(stage)
    current_scene = stage
    var hand = SyntheticHand.new()
    stage.add_child(hand)
    var host = load(BASE + "/minimal.tscn").instantiate()
    host.position = Vector3(4, 1, -3)
    host.rotation = Vector3(0.2, 0.65, -0.12)
    stage.add_child(host)
    for i in range(5): await process_frame
    hand.body = host.points[0]
    hand.target_pose = host.to_global(Vector3(1.7, 4.2, -1.4))
    hand.body.on_desktop_grab(hand)
    hand.driving = true
    for i in range(8):
        await physics_frame
        await process_frame
        samples.append({"phase": "held", "index": i, "global_point": str(hand.body.global_position), "model_a": str(host.model.points[0]), "held": hand.body.held()})
    check("continuous_grab.held", hand.body.held())
    check("continuous_grab.model_a", host.model.points[0].distance_to(Vector2(1, -1)) < 0.0001, str(host.model.points[0]), "(1,-1)")
    check("continuous_grab.body_pose", hand.body.global_position.distance_to(hand.target_pose) < 0.0001, str(hand.body.global_position), str(hand.target_pose))
    check("continuous_grab.label_projection", host.labels[0].position.distance_to(Vector3(1, 1.3, -1)) < 0.0001, str(host.labels[0].position))
    var guide_before = host.guide_on
    hand.body.action_pressed.emit(hand)
    check("continuous_grab.trigger", host.guide_on != guide_before)
    host.reset()
    check("continuous_grab.reset_refused", host.model.points[0].distance_to(Vector2(1, -1)) < 0.0001)
    hand.driving = false
    hand.body.on_desktop_drop(hand)
    for i in range(8):
        await physics_frame
        await process_frame
        samples.append({"phase": "released", "index": i, "global_point": str(hand.body.global_position), "model_a": str(host.model.points[0]), "held": hand.body.held()})
    var projected = host.to_global(Vector3(1, 1.12, -1))
    check("continuous_release.not_held", not hand.body.held())
    check("continuous_release.model_preserved", host.model.points[0].distance_to(Vector2(1, -1)) < 0.0001, str(host.model.points[0]))
    check("continuous_release.projected_pose", hand.body.global_position.distance_to(projected) < 0.0001, str(hand.body.global_position), str(projected))
    hand.body.global_position += Vector3(2, 3, 4)
    for i in range(4):
        await physics_frame
        await process_frame
    check("continuous_release.maintained_pose", hand.body.global_position.distance_to(projected) < 0.0001, str(hand.body.global_position), str(projected))
    host.reset()
    for i in range(3): await process_frame
    check("continuous_release.reset_restored", host.model.points[0].distance_to(Vector2(-0.7, 0.4)) < 0.0001)
    check("continuous_release.guide_preference_preserved", host.guide_on != guide_before)
    var failures = checks.filter(func(item): return not item.passed)
    var result = {"probe": "continuous_synthetic_grab_followup", "checks": checks, "checks_total": checks.size(), "samples": samples, "failures": failures, "passed": failures.is_empty(), "qualification": "Follow-up after primary failed one-shot body teleport. Continuous pose source is test input. Lesson source unchanged. Does not test physical XR tracking or the actual desktop pointer controller."}
    var output = FileAccess.open(BASE + "/continuous_grab_results.json", FileAccess.WRITE)
    output.store_string(JSON.stringify(result, "  "))
    output.close()
    print("GHOST_CONTINUOUS_RESULT ", JSON.stringify({"passed": result.passed, "checks_total": checks.size(), "failures": failures.size()}))
    stage.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
