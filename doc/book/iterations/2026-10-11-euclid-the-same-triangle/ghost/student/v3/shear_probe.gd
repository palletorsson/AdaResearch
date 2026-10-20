extends SceneTree

const Triangle = preload("triangle_record.gd")
const BASE = "res://doc/book/iterations/2026-10-11-euclid-the-same-triangle/ghost/student/v3"
var checks: Array = []

func _initialize() -> void:
    run.call_deferred()

func check(id: String, passed: bool, observed: Variant = null, expected: Variant = null) -> void:
    checks.append({"id": id, "passed": passed, "observed": observed, "expected": expected})
    print(("PASS " if passed else "FAIL ") + id)

func near(id: String, actual: float, expected: float) -> void:
    check(id, absf(actual - expected) < 0.0001, actual, expected)

func run() -> void:
    var original = Triangle.new()
    original.points.assign([Vector2.ZERO, Vector2(0.8, 0), Vector2(0.2, 0.6)])
    var transformed = Triangle.new()
    transformed.points.clear()
    for point in original.points:
        transformed.points.append(Vector2(point.x + 0.5 * point.y, point.y))
    var before = original.measure()
    var after = transformed.measure()
    check("shear.valid", before.valid and after.valid)
    check("shear.predicted_coordinates", transformed.points[2].distance_to(Vector2(0.5, 0.6)) < 0.0001, str(transformed.points))
    var original_angles = [71.56505117707799, 45.0, 63.43494882292201]
    var expected_angles = [50.19442890773481, 63.43494882292201, 66.37062226934319]
    var original_lengths = [0.8, sqrt(0.72), sqrt(0.4)]
    var expected_lengths = [0.8, sqrt(0.45), sqrt(0.61)]
    for i in range(3):
        near("shear.base_angle_" + str(i), before.angles[i], original_angles[i])
        near("shear.transformed_angle_" + str(i), after.angles[i], expected_angles[i])
        check("shear.angle_changed_" + str(i), absf(after.angles[i] - before.angles[i]) > 1.0)
        near("shear.base_length_" + str(i), original.points[i].distance_to(original.points[(i + 1) % 3]), original_lengths[i])
        near("shear.transformed_length_" + str(i), transformed.points[i].distance_to(transformed.points[(i + 1) % 3]), expected_lengths[i])
    near("shear.base_area", before.area, 0.24)
    near("shear.transformed_area", after.area, 0.24)
    near("shear.base_sum", before.sum, 180.0)
    near("shear.transformed_sum", after.sum, 180.0)
    var ends = transformed.parallel_ends()
    check("shear.guide_has_ends", ends.size() == 2)
    check("shear.guide_center", ((ends[0] + ends[1]) * 0.5).distance_to(transformed.points[2]) < 0.0001)
    near("shear.guide_parallel_cross", (ends[1] - ends[0]).cross(transformed.points[1] - transformed.points[0]), 0.0)
    near("shear.guide_length", ends[0].distance_to(ends[1]), 2.5)
    var failures = checks.filter(func(item): return not item.passed)
    var result = {"probe": "v3_repeat_of_previously_predicted_shear", "before": before, "after": after, "checks": checks, "checks_total": checks.size(), "passed": failures.is_empty(), "failures": failures, "transfer_scope": "Independent selection, prediction and execution of nonuniform area-preserving shear. Preserved area and sum do not imply preserved individual angles or lengths. Experienced coding AI; no claim of novice learning or invention of copied lesson code."}
    var output = FileAccess.open(BASE + "/shear_results.json", FileAccess.WRITE)
    output.store_string(JSON.stringify(result, "  "))
    output.close()
    print("GHOST_SHEAR_RESULT ", JSON.stringify({"passed": result.passed, "checks_total": checks.size(), "failures": failures.size()}))
    quit(0 if failures.is_empty() else 1)
