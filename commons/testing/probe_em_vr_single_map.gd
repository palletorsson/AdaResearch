extends SceneTree

## Focused contract for the VR three-shell / one-exhibit streamer. A headless
## run has no XR eye, so this probe feeds z positions directly while using real
## museum builds, real artifact recipes, and real queue-free frame boundaries.

var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://commons/scenes/endless_museum.tscn") as PackedScene
	var museum := packed.instantiate() as Node3D
	museum.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(museum)
	var waited := 0.0
	while not bool(museum.get("_museum_ready")) and waited < 35.0:
		await create_timer(0.1).timeout
		waited += 0.1
	_expect(bool(museum.call("is_map_ready")), "the lightweight startup cell publishes readiness")
	_expect(bool(museum.get("_museum_ready")), "the first hall reaches content readiness")
	var segs: Array = museum.get("_segments")
	if segs.is_empty():
		_expect(false, "the museum built an opening hall")
		_finish(museum)
		return

	var first: Dictionary = segs[0]
	var first_z := (float(first["z0"]) + float(first["z1"])) * 0.5
	museum.call("_vr_single_map_stream", first_z, 0.1)
	segs = museum.get("_segments")
	_expect(segs.size() == 2, "the opening keeps current + one forward shell")
	_expect(museum.get("_vr_current_node") == (segs[0] as Dictionary).get("node"),
		"the opening hall owns the artifact set")
	_expect(not bool((segs[0] as Dictionary).get("shell", true)), "current hall is promoted")
	_expect(bool((segs[1] as Dictionary).get("shell", false)), "next hall is an architecture shell")
	var next_node := (segs[1] as Dictionary).get("node") as Node3D
	_expect(next_node != null and _content_roots(next_node).is_empty(),
		"the forward shell has no live artifact roots")
	_expect(next_node != null and not next_node.find_children("*", "StaticBody3D", true, false).is_empty(),
		"the forward shell already owns floor/wall collision")
	_expect(next_node != null and (next_node.get_meta("em_vr_content_blueprints", []) as Array).size() > 0,
		"the forward shell remembers its configured artifacts")

	var old_node := (segs[0] as Dictionary).get("node") as Node3D
	var next_z := (float((segs[1] as Dictionary)["z0"]) + float((segs[1] as Dictionary)["z1"])) * 0.5
	museum.call("_vr_single_map_stream", next_z, 0.1)
	await process_frame
	await process_frame
	segs = museum.get("_segments")
	_expect(segs.size() <= 3, "resident architecture never exceeds previous/current/next")
	_expect(museum.get("_vr_current_node") == next_node, "crossing transfers artifact ownership to the entered shell")
	_expect(is_instance_valid(old_node) and _content_roots(old_node).is_empty(),
		"the previous hall keeps architecture but frees its artifacts")
	_expect(_queued_only_for(museum, next_node), "only the current hall may queue artifact construction")
	_expect(String(museum.get("_vr_passage_phase")) == "" and museum.get("_vr_passage") == null,
		"crossing uses no temporary loading passage")

	# Reverse over the same live floor. The previous shell must become current
	# without reconstructing its architecture node.
	museum.call("_vr_single_map_stream", first_z, 0.1)
	await process_frame
	await process_frame
	segs = museum.get("_segments")
	_expect(museum.get("_vr_current_node") == old_node, "walking back promotes the same previous shell")
	_expect(is_instance_valid(next_node) and _content_roots(next_node).is_empty(),
		"the hall left in front releases its artifact roots")
	_expect(segs.size() <= 3, "reverse crossing also keeps at most three shells")
	_expect(_queued_only_for(museum, old_node), "reverse crossing queues only the re-entered hall's artifacts")
	_finish(museum)


func _content_roots(parent: Node) -> Array:
	var out: Array = []
	_collect_content(parent, out)
	return out


func _collect_content(parent: Node, out: Array) -> void:
	for child_v in parent.get_children():
		var child := child_v as Node
		if child.has_meta("em_vr_content") or child.has_meta("em_vr_artifact_support") \
				or child.has_meta("em_cartridge_deferred") or child.has_meta("em_showing"):
			out.append(child)
		else:
			_collect_content(child, out)


func _queued_only_for(museum: Node3D, owner: Node3D) -> bool:
	for item_v in (museum.get("_stamp_queue") as Array):
		if (item_v as Dictionary).get("seg") != owner:
			return false
	return true


func _finish(museum: Node3D) -> void:
	if museum != null and is_instance_valid(museum):
		museum.queue_free()
	if _failures.is_empty():
		print("[probe-vr-shells] PASS — three floors stay resident while one hall owns artifacts")
		quit(0)
	else:
		for failure in _failures:
			push_error("[probe-vr-shells] " + failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
