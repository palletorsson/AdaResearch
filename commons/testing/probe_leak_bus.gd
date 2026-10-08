extends SceneTree

## GATE — the leak bus, and carve_grid keeping what it refused.
##
## The claim the room makes: somebody following behind you will find the cut
## already made. Until now the cut died at unload, so the prose asked a question
## the game declined to answer. This drives the whole path headless.
##
## /root/LeakData is the REAL autoload here — this harness has them. A stub added
## under the same name is silently renamed LeakData2 and then the probe and the
## artifact read two different buses, with the probe green on a dead path.
##
##   A  leak:none                  -> cuts are NOT recorded (the default is untouched)
##   B  leak:keep, a cut           -> spilled on exit, with rule / room / kind intact
##   C  a second lattice arrives   -> it meets the earlier cut already carved
##   D  the restored cut           -> is not re-spilled as though freshly refused
##   E  two separate visits        -> the third lattice meets the UNION, not the latest
##   F  RESET                      -> keeps the cut before taking it back
##   G  the bus is bounded         -> MAX_POINTS caps one leak
##   H  the bus refuses a tally    -> no count/score API to optimise against

const LATTICE := "res://commons/artifacts/carve_grid/carve_grid.tscn"

var _fails: Array = []
var _bus: Node = null


func _initialize() -> void:
	await _run()
	if _fails.is_empty():
		print("\nprobe_leak_bus: ALL 8 CASES PASS")
		quit(0)
	else:
		print("\nprobe_leak_bus: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)


func _check(label: String, ok: bool, detail: String = "") -> void:
	var line: String = "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	if ok:
		print("  ok    %s" % line)
	else:
		_fails.append(line)
		print("  FAIL  %s" % line)


func _bus_up() -> void:
	if _bus != null:
		return
	_bus = root.get_node_or_null("LeakData")
	if _bus == null:
		_bus = Node.new()
		_bus.set_script(load("res://commons/globals/leak_data.gd"))
		_bus.name = "LeakData"
		root.add_child(_bus)
		print("  (no LeakData autoload; probe stood one up)")
	if root.get_node_or_null("LeakData") != _bus:
		_fails.append("bus setup: /root/LeakData is not the node the probe reads")


## A lattice small enough to reason about, with the leak key set before it enters
## the tree — which is how a map token's config actually arrives.
func _lattice(leak_value: String) -> Node3D:
	var n: Node3D = load(LATTICE).instantiate()
	n.set_meta("config_leak", leak_value)
	n.set_meta("config_cells", 5)
	n.set_meta("config_cells_y", 2)
	root.add_child(n)
	return n


## Carve by hand at the one chokepoint the body would reach. Using _kill directly
## keeps the probe about the LEAK path and not about capsule measurement.
func _carve(n: Node3D, idxs: Array) -> void:
	for i: int in idxs:
		if i < n._count and n._alive[i] == 1:
			n._kill(i)


func _carved_count(n: Node3D) -> int:
	var c: int = 0
	for i in n._count:
		if n._alive[i] == 0:
			c += 1
	return c


func _run() -> void:
	print("probe_leak_bus")
	_bus_up()
	_bus.clear_leaks()

	# --- A: the default must not record ---
	var a := _lattice("none")
	await process_frame
	_carve(a, [0, 1, 2])
	a.free()
	await process_frame
	_check("A leak:none records nothing", not _bus.has_leaks(),
		"%d leaks on the bus" % _bus.all_leaks().size())

	# --- B: the spill ---
	_bus.clear_leaks()
	var b := _lattice("keep")
	await process_frame
	_carve(b, [0, 1, 2, 3])
	_check("B nothing is spilled before the room ends", not _bus.has_leaks())
	b.free()
	await process_frame
	var leaks: Array = _bus.all_leaks()
	_check("B the cut is spilled on unload", leaks.size() == 1,
		"%d leaks" % leaks.size())
	if leaks.size() == 1:
		var l: Dictionary = leaks[0]
		_check("B the leak names its edge", str(l.get("rule", "")) == "carve_grid.bite",
			str(l.get("rule", "")))
		_check("B the leak names its kind", str(l.get("kind", "")) == "cells",
			str(l.get("kind", "")))
		_check("B the leak carries the refused cells", l.get("points", []).size() == 4,
			"%d points" % l.get("points", []).size())
		_check("B the leak names a room", str(l.get("room", "")) != "",
			str(l.get("room", "")))

	# --- C: the next arrival meets it ---
	var c := _lattice("keep")
	await process_frame
	_check("C a later lattice meets the earlier cut", _carved_count(c) == 4,
		"%d cells already carved" % _carved_count(c))

	# --- D: a restored cut is not a fresh refusal ---
	var before: int = _bus.all_leaks().size()
	c.free()
	await process_frame
	_check("D the restored cut is not re-spilled", _bus.all_leaks().size() == before,
		"%d -> %d leaks" % [before, _bus.all_leaks().size()])

	# --- E: the union, not the latest ---
	var e := _lattice("keep")
	await process_frame
	_carve(e, [10, 11])
	e.free()
	await process_frame
	var f := _lattice("keep")
	await process_frame
	_check("E the third arrival meets BOTH visits", _carved_count(f) == 6,
		"%d cells carved, wanted 4 + 2" % _carved_count(f))
	f.free()
	await process_frame

	# --- F: RESET keeps the cut before taking it back ---
	_bus.clear_leaks()
	var g := _lattice("keep")
	await process_frame
	_carve(g, [20, 21, 22])
	g.reset_lattice()
	_check("F RESET keeps the cut", _bus.has_leaks(),
		"%d leaks" % _bus.all_leaks().size())
	_check("F RESET still clears the lattice", _carved_count(g) == 0,
		"%d still carved" % _carved_count(g))
	g.free()
	await process_frame

	# --- G: bounded ---
	_bus.clear_leaks()
	var many: Array = []
	for i in range(_bus.MAX_POINTS + 500):
		many.append(Vector3(float(i), 0.0, 0.0))
	_bus.spill("Probe", "probe.bound", "cells", many)
	var kept: int = _bus.all_leaks()[0].get("points", []).size()
	_check("G one leak is capped at MAX_POINTS", kept == _bus.MAX_POINTS,
		"kept %d of %d" % [kept, many.size()])

	# --- H: no scoreboard. The bus must not hand anyone a number to optimise. ---
	var scored: Array = []
	for m in ["total", "score", "count", "leak_count", "rank", "biggest"]:
		if _bus.has_method(m):
			scored.append(m)
	_check("H the bus exposes no tally to optimise", scored.is_empty(),
		", ".join(scored))

	_bus.clear_leaks()
	await process_frame
