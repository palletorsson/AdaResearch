extends SceneTree
## Diagnostic (2026-09-10): the Intro probe cannot find the control pendulum's
## BobSphere in the museum. Instantiate the artifact bare, with the museum's
## configuration order (apply_grid_config BEFORE add_child), and record the tree.
## stdout does not survive the watchdog, so the findings go to a JSON file:
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_intro_bob_diag.gd
##   -> res://ada_run/waves_chance_noise/WaveFunctions_Intro/bob_diag.json
const OUT := "res://ada_run/waves_chance_noise/WaveFunctions_Intro/bob_diag.json"
var out: Dictionary = {}

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var stage := Node3D.new(); root.add_child(stage); current_scene = stage
	var ps: PackedScene = load("res://commons/artifacts/control_pendulum/control_pendulum.tscn")
	var p: Node3D = ps.instantiate()
	p.set_meta("config_reference", "plumb"); p.set_meta("config_evidence", "trace")
	if p.has_method("apply_grid_config"):
		p.call("apply_grid_config", {"reference": "plumb", "evidence": "trace"})
	stage.add_child(p)
	for i in range(3): await process_frame
	out["museum_order_tree"] = _tree(p, 0)
	out["museum_order_find_child"] = str(p.find_child("BobSphere", true, false))
	out["museum_order_bob_like"] = _names(p.find_children("*Bob*", "", true, false))
	out["museum_order_grab_like"] = _names(p.find_children("*Grab*", "", true, false))
	out["museum_order_bob_var"] = str(p.get("_bob_sphere"))
	var q: Node3D = ps.instantiate(); q.position.x = 3
	stage.add_child(q)
	for i in range(2): await process_frame
	q.call("apply_grid_config", {"reference": "plumb", "evidence": "trace"})
	for i in range(3): await process_frame
	out["grid_order_tree"] = _tree(q, 0)
	out["grid_order_find_child"] = str(q.find_child("BobSphere", true, false))
	out["grid_order_bob_var"] = str(q.get("_bob_sphere"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ")); f.close()
	quit(0)

func _names(a: Array) -> Array:
	var o: Array = []
	for n in a: o.append(str((n as Node).get_path()))
	return o

func _tree(n: Node, depth: int) -> Array:
	var o: Array = []
	for c in n.get_children():
		var line: String = "  ".repeat(depth) + c.name + " (" + c.get_class() + ")"
		if c.get_script() != null: line += " " + str(c.get_script().resource_path).get_file()
		o.append(line)
		if depth < 2: o.append_array(_tree(c, depth + 1))
	return o
