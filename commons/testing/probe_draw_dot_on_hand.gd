extends SceneTree

## probe_draw_dot_on_hand.gd — TEMPORARY VERIFIER (delete after reading)
##
## THE QUESTION: can draw_dot / draw_dot_time_domain be instantiated as a CHILD of a
## moving node (an XR controller) and draw a trail that follows that hand?
##
## Two sub-questions, both measurable headless:
##   1. GEOMETRY — the pen node is an XRToolsPickable (RigidBody3D, freeze=true,
##      freeze_mode=KINEMATIC). Does its global_position track a moving PARENT, or
##      does the physics server hold it in world space?
##   2. RECORDING — does _process actually append trail points on that path?
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_draw_dot_on_hand.gd

const DOT := "res://commons/primitives/point/draw_dot.tscn"
const TIME := "res://commons/primitives/point/draw_dot_time_domain.tscn"

var _root: Window
var _log: Array[String] = []


func _say(line: String) -> void:
	print(line)
	_log.append(line)


func _initialize() -> void:
	_run()


func _run() -> void:
	_root = get_root()
	_say("")
	_say("DRAW DOT ON HAND PROBE")
	_say("")

	await _case("A  time_domain, shipped (record_only_when_grabbed=false)", TIME, {})
	await _case("B  draw_dot, shipped (record_only_when_grabbed=true)", DOT, {})
	await _case("C  draw_dot, gate off", DOT, {"record_only_when_grabbed": false})
	await _case("D  draw_dot, gate off + fine grain", DOT,
		{"record_only_when_grabbed": false, "min_segment_distance": 0.001})

	_say("")
	_say("done")
	var f := FileAccess.open("res://ada_run/probe_draw_dot_on_hand.txt", FileAccess.WRITE)
	if f != null:
		for line in _log:
			f.store_line(line)
		f.close()
	quit(0)


func _case(label: String, scene_path: String, props: Dictionary) -> void:
	_say("---- " + label)
	var hand := Node3D.new()
	hand.name = "FakeHand"
	_root.add_child(hand)
	hand.global_position = Vector3(0.0, 1.4, 0.0)

	var inst: Node3D = (load(scene_path) as PackedScene).instantiate()
	for k in props:
		inst.set(k, props[k])
	hand.add_child(inst)

	await process_frame
	await physics_frame

	var pen: Node3D = inst.get("_draw_sphere")
	var grab: Node3D = inst.get("_grab_point")
	_say("    pen node: %s   grab node: %s   class: %s" % [
		str(pen), str(grab), (pen.get_class() if pen != null else "<null>")])
	if pen == null:
		hand.queue_free()
		return
	_say("    freeze=%s freeze_mode=%s  is_picked_up=%s" % [
		str(pen.get("freeze")), str(pen.get("freeze_mode")),
		str(pen.is_picked_up()) if pen.has_method("is_picked_up") else "n/a"])

	# Sweep the hand through a 0.3 m circle for ~2 s of process frames.
	var worst_lag := 0.0
	var t := 0.0
	for i in range(150):
		t += 0.016
		# Exactly what XRNode3D does: write the LOCAL transform each frame.
		hand.position = Vector3(0.3 * sin(t * 4.0), 1.4 + 0.2 * cos(t * 3.0), 0.3 * cos(t * 4.0))
		await process_frame
		await physics_frame
		var d: float = pen.global_position.distance_to(hand.global_position)
		if d > worst_lag:
			worst_lag = d

	var pts: Array = inst.get("_trail_points")
	var minv := Vector3(1e9, 1e9, 1e9)
	var maxv := Vector3(-1e9, -1e9, -1e9)
	for p in pts:
		minv = Vector3(minf(minv.x, p.x), minf(minv.y, p.y), minf(minv.z, p.z))
		maxv = Vector3(maxf(maxv.x, p.x), maxf(maxv.y, p.y), maxf(maxv.z, p.z))
	_say("    pen-follows-hand: worst world gap = %.4f m  (0 = rigid to the hand)" % worst_lag)
	_say("    final pen global = %s   hand global = %s" % [
		str(pen.global_position), str(hand.global_position)])
	_say("    trail points = %d" % pts.size())
	if pts.size() > 0:
		_say("    trail extent  = x %.3f..%.3f  y %.3f..%.3f  z %.3f..%.3f" % [
			minv.x, maxv.x, minv.y, maxv.y, minv.z, maxv.z])
	var trail: Node3D = inst.get("_trail_instance")
	if trail != null:
		_say("    trail top_level=%s  trail global=%s" % [
			str(trail.is_set_as_top_level()), str(trail.global_position)])
	hand.queue_free()
	await process_frame
