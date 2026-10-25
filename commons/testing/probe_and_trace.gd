extends SceneTree
## Diagnostic for the AND gate: build the A + B case from a terms file and print both balls'
## positions and speeds every 3 physics ticks, so the path of the second ball can be read.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_and_trace.gd -- --terms=res://ada_run/terms_b080_wall.json

var _terms_path := "res://commons/modular/terms.json"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--terms="):
			_terms_path = a.trim_prefix("--terms=")
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(_terms_path, FileAccess.READ)
	var terms: Dictionary = (JSON.parse_string(f.get_as_text()) as Dictionary)["terms"]
	var logic: Dictionary = terms["and_gate"]["logic"]
	var parts: Array = [{"t": logic["frame"]}]
	for name in ["A", "B"]:
		parts.append({"op": "transform", "of": {"t": "ball"}, "at": logic["inputs"][name]["at"]})
	var expr := {"op": "engine", "kind": "physics", "free": ["ball"], "of": {"op": "compose", "parts": parts}}
	var thing: Node = (load("res://commons/modular/composite.tscn") as PackedScene).instantiate()
	thing.set("expression", JSON.stringify(expr))
	root.add_child(thing)
	await process_frame
	await process_frame
	var balls: Array = []
	var stack: Array = [thing]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is RigidBody3D:
			balls.append(n)
		for c in n.get_children():
			stack.append(c)
	for i in range(90):
		await physics_frame
		if i % 3 == 0:
			var line := "t%03d" % i
			for b in balls:
				var p: Vector3 = b.global_position
				var v: Vector3 = (b as RigidBody3D).linear_velocity
				line += "  (%.3f, %.3f) v=(%.2f, %.2f)" % [p.x, p.y, v.x, v.y]
			print("TRACE ", line)
	quit(0)
