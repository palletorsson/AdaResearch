extends SceneTree
var failures: Array = []
func check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ")+label)
	if not ok:failures.append(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var study: Node3D = load("res://coordinates.tscn").instantiate()
	root.add_child(study)
	await process_frame
	check("first marker receives A",study.get_node("A").position.is_equal_approx(Vector3(-0.75,1.12,0)))
	check("second marker receives B",study.get_node("B").position.is_equal_approx(Vector3(0.75,1.12,0)))
	check("both visible",study.get_node("A").visible and study.get_node("B").visible)
	var before: Vector3=study.get_node("A").position
	study.position.x=2.0
	check("changing reference preserves local point",study.get_node("A").position.is_equal_approx(before))
	check("changing reference changes world point",study.get_node("A").global_position.is_equal_approx(before+Vector3(2,0,0)))
	study.get_node("B").position=before
	check("two nodes can share one position",study.get_node("A").get_instance_id()!=study.get_node("B").get_instance_id() and study.get_node("A").global_position.is_equal_approx(study.get_node("B").global_position))
	print("COORDINATE STUDY: ",6-failures.size(),"/6")
	quit(0 if failures.is_empty() else 1)
