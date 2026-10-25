extends SceneTree
## Does the rope hold? (handover 24 Oct: a tie must be an actual relation, not a drawing.)
## `pendulum` is a cube held high with a ball beside it, tied with a rope, under the physics
## engine. The ball should fall until the rope is taut and then swing: after the run its
## distance to the cube stays within the rope's length (plus a little give), and it has
## dropped. The CONTROL is the same two bodies without the tie: the ball falls away, the
## distance grows. A rod must keep the distance; a spring must pull it back towards the
## rest length. Report: ada_run/tied_rope_trace.json.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_tied_rope.gd

const TICKS := 150
const SAMPLE := 15

func _init() -> void:
	call_deferred("_run")


func _find(root: Node, pred: Callable) -> Node3D:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Node3D and pred.call(n):
			return n
		for c in n.get_children():
			stack.append(c)
	return null


func _case(label: String, kind: String) -> Dictionary:
	var parts := [
		{"op": "transform", "of": {"t": "cube"}, "at": [0, 1.2, 0], "scale": 0.4},
		{"op": "transform", "of": {"t": "sphere_collider"}, "at": [0.5, 1.2, 0], "scale": 0.6}]
	var inner: Dictionary = {"op": "compose", "parts": parts}
	if kind != "none":
		inner = {"op": "connect", "a": 0, "b": 1, "kind": kind, "of": inner}
	var expr := {"op": "engine", "kind": "physics", "of": inner}
	var scene: PackedScene = load("res://commons/modular/composite.tscn")
	var thing: Node = scene.instantiate()
	thing.set("expression", JSON.stringify(expr))
	root.add_child(thing)
	await process_frame
	await process_frame
	var ball: Node3D = _find(thing, func(n): return n is RigidBody3D)
	var anchor: Node3D = _find(thing, func(n): return str(n.get_meta("term", "")) == "cube")
	var joint: Node3D = _find(thing, func(n): return n is Joint3D)
	var d0: float = ball.global_position.distance_to(anchor.global_position) if ball and anchor else -1.0
	var y0: float = ball.global_position.y if ball else 0.0
	var trace: Array = []
	for i in range(TICKS):
		await physics_frame
		if ball and anchor and i % SAMPLE == 0:
			trace.append({"tick": i, "dist": snapped(ball.global_position.distance_to(anchor.global_position), 0.001), "y": snapped(ball.global_position.y, 0.001)})
	var d1: float = ball.global_position.distance_to(anchor.global_position) if ball and anchor else -1.0
	var y1: float = ball.global_position.y if ball else 0.0
	var dmax: float = 0.0
	for t in trace:
		dmax = max(dmax, float(t["dist"]))
	thing.queue_free()
	return {"case": label, "kind": kind, "rigid_ball": ball is RigidBody3D, "joint": joint != null, "joint_type": joint.get_class() if joint else "",
		"d0": snapped(d0, 0.001), "d1": snapped(d1, 0.001), "d_max": snapped(dmax, 0.001), "y0": snapped(y0, 0.001), "y1": snapped(y1, 0.001), "trace": trace}


func _run() -> void:
	var rope: Dictionary = await _case("pendulum: rope", "rope")
	var none: Dictionary = await _case("control: no tie", "none")
	var rod: Dictionary = await _case("rod", "rod")
	var give := 0.12
	var rope_ok: bool = bool(rope["joint"]) and float(rope["d_max"]) <= float(rope["d0"]) + give and float(rope["y1"]) < float(rope["y0"]) - 0.12
	var none_ok: bool = not bool(none["joint"]) and float(none["d1"]) > float(none["d0"]) + 0.5
	var rod_ok: bool = bool(rod["joint"]) and abs(float(rod["d1"]) - float(rod["d0"])) <= give
	var ok := rope_ok and none_ok and rod_ok
	var report := {"probe": "tied_rope", "ticks": TICKS, "physics_hz": Engine.physics_ticks_per_second,
		"claim": "a rope keeps the ball within its length while it falls and swings; without the tie the ball falls away; a rod keeps the distance",
		"ok": ok, "rope_ok": rope_ok, "control_ok": none_ok, "rod_ok": rod_ok, "cases": [rope, none, rod]}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run"))
	var f := FileAccess.open("res://ada_run/tied_rope_trace.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("TIED_ROPE ok=%s rope(d0 %.2f dmax %.2f y %.2f->%.2f joint=%s) control(d1 %.2f) rod(d0 %.2f d1 %.2f)" % [
		ok, rope["d0"], rope["d_max"], rope["y0"], rope["y1"], rope["joint_type"], none["d1"], rod["d0"], rod["d1"]])
	quit(0 if ok else 1)
