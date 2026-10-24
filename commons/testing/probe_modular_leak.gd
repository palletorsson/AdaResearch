extends SceneTree
## Does the scaffold leak? Builds mod_tape through the composite (the line inside the tape is
## scaffold, freed when the build is done) and reads the LeakData bus: one entry, kind
## "scaffold", rule "composite.scaffold:tape", with the removed parts' points. Then a term with
## no scaffold (point) must add nothing — a rule that refused nothing has no edge to report.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_modular_leak.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bus: Node = root.get_node_or_null("/root/LeakData")
	if bus == null:
		print("MODULAR_LEAK no LeakData autoload")
		quit(1)
		return
	var before: int = (bus.get("leaks") as Array).size()
	var scene: PackedScene = load("res://commons/modular/composite.tscn")
	var tape: Node = scene.instantiate()
	tape.set("term", "tape")
	root.add_child(tape)
	await process_frame
	var after_tape: Array = bus.get("leaks") as Array
	var ok := after_tape.size() == before + 1
	var entry: Dictionary = after_tape[-1] if after_tape.size() > before else {}
	ok = ok and str(entry.get("kind", "")) == "scaffold" and str(entry.get("rule", "")) == "composite.scaffold:tape"
	var pts: int = (entry.get("points", []) as Array).size()
	ok = ok and pts >= 3   # the line node, its two points and its stroke: at least three positions
	var point: Node = scene.instantiate()
	point.set("term", "point")
	root.add_child(point)
	await process_frame
	var after_point: int = (bus.get("leaks") as Array).size()
	ok = ok and after_point == after_tape.size()
	print("MODULAR_LEAK ok=%s tape_entry=%s points=%d point_added=%d" % [ok, entry.get("rule", "none"), pts, after_point - after_tape.size()])
	quit(0 if ok else 1)
