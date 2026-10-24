extends SceneTree
## The physical `if` (handover 2026-10-24, slice C): tilt_gate is a plank tilted 8° with a
## ball at its high end under the physics engine. The claim in pseudo code is
##     step(plank tilted + ball, physics)  →  the ball rolls to the LOW end
## This probe builds the term, runs the physics for a fixed number of ticks and records where
## the ball went, tick by tick — a trace of a seeded, reproducible run. Then it builds the
## mirror (tilt the other way) and expects the opposite verdict: a change to the geometry
## changes the truth condition of the machine, which is the lesson. Report:
## ada_run/tilt_gate_trace.json.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_tilt_gate.gd

const TICKS := 180
const SAMPLE := 15

func _init() -> void:
	call_deferred("_run")


func _ball_of(root: Node) -> Node3D:
	var found: Node3D = null
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is RigidBody3D:
			return n
		if n is Node3D and str(n.get_meta("term", "")) == "sphere_collider" and found == null:
			found = n
		for c in n.get_children():
			stack.append(c)
	return found


func _run_case(label: String, tilt: float) -> Dictionary:
	var scene: PackedScene = load("res://commons/modular/composite.tscn")
	var gate: Node = scene.instantiate()
	var expr := {"op": "engine", "kind": "physics", "of": {"op": "compose", "parts": [
		{"op": "transform", "of": {"t": "plank"}, "at": [0, 0.3, 0], "rot": [0, 0, tilt]},
		{"op": "transform", "of": {"t": "sphere_collider"}, "at": [-0.38 if tilt < 0 else 0.38, 0.48, 0], "scale": 0.6},
		{"op": "transform", "of": {"t": "cube"}, "at": [0, 0.1, 0], "scale": 0.5}]}}
	gate.set("expression", JSON.stringify(expr))
	root.add_child(gate)
	await process_frame
	await process_frame   # the physics engine swaps the ball for a rigid body one frame late
	var ball: Node3D = _ball_of(gate)
	var trace: Array = []
	var x0: float = ball.global_position.x if ball != null else 0.0
	for i in range(TICKS):
		await physics_frame
		if ball != null and i % SAMPLE == 0:
			trace.append({"tick": i, "x": snapped(ball.global_position.x, 0.001), "y": snapped(ball.global_position.y, 0.001)})
	var x1: float = ball.global_position.x if ball != null else 0.0
	var dx: float = x1 - x0
	var verdict: String = "right" if dx > 0.05 else ("left" if dx < -0.05 else "stayed")
	gate.queue_free()
	return {"case": label, "tilt_deg": tilt, "rigid": ball is RigidBody3D, "x0": snapped(x0, 0.001), "x1": snapped(x1, 0.001),
		"dx": snapped(dx, 0.001), "verdict": verdict, "trace": trace}


func _run() -> void:
	var a: Dictionary = await _run_case("tilt_gate as authored (-8°, ball at the high left end)", -8.0)
	var b: Dictionary = await _run_case("mirror (+8°, ball at the high right end)", 8.0)
	var ok: bool = bool(a["rigid"]) and bool(b["rigid"]) and a["verdict"] == "right" and b["verdict"] == "left"
	var report := {"probe": "tilt_gate", "ticks": TICKS, "physics_hz": Engine.physics_ticks_per_second,
		"claim": "step(plank tilted + ball, physics): the ball rolls to the low end; mirror the tilt, mirror the verdict",
		"ok": ok, "cases": [a, b]}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run"))
	var f := FileAccess.open("res://ada_run/tilt_gate_trace.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("TILT_GATE ok=%s authored=%s (dx %.3f) mirror=%s (dx %.3f) rigid=%s/%s" % [ok, a["verdict"], a["dx"], b["verdict"], b["dx"], a["rigid"], b["rigid"]])
	quit(0 if ok else 1)
