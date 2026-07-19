# probe_biome_reactivity.gd — biome-7 gate: the reactivity runtime, wired.
#
# Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_biome_reactivity.gd
#
# A: typed catalyst trigger steps the CA cell; wrong mode is a no-op (negative).
# B: react_at_world maps a world position to the right cell.
# C: claim expands into the adjacent field cell and stages it.
# D: the vacuum opens — ::mute:on=catalyst.fractal:unmute/seed renders on hit.
# E: tick fires through _process; the clock only runs when declared (additive).
# F: mutate.color routes to a GridMutatorBase in the scene; an unknown channel
#    is counted unrouted, not silent (negative).
#
# GridSystem/catalyst files are not bare-load()ed (autoload-referencing scripts
# cannot compile in --script mode); their gate is the live map-load.
extends SceneTree

const ComponentScript = preload("res://commons/grid/GridBiomeComponent.gd")
const StubMutator = preload("res://commons/testing/stub_color_mutator.gd")

var _failures: int = 0


func _init() -> void:
	_run()
	if _failures == 0:
		print("PROBE PASS: biome-7 reactivity (all cases)")
		quit(0)
	else:
		print("PROBE FAIL: %d case(s)" % _failures)
		quit(1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("  ok   %s — %s" % [name, detail])
	else:
		print("  FAIL %s — %s" % [name, detail])
		_failures += 1


func _structure(cols: int, rows: int) -> Array:
	var s: Array = []
	for _r in range(rows):
		var line: Array = []
		for _c in range(cols):
			line.append("1")
		s.append(line)
	return s


func _run() -> void:
	var layer: Array = [
		["::mute:on=catalyst.fractal:unmute/seed", "", "", "", ""],
		["", "fungus:ca:seed:rule=110:on=catalyst.fractal:step", "", "", ""],
		["", "", "flora:scatter:seed:on=catalyst.chromatic:claim", "flora:scatter:field", ""],
		["", "mineral:tint:seed:on=tick:step", "", "", ""],
		["", "", "meta:glow:seed:on=touch:mutate.color/mutate.nonesuch", "", ""],
	]
	var comp: Node3D = ComponentScript.new()
	root.add_child(comp)
	var stub: Node = StubMutator.new()
	stub.name = "StubColorMutator"
	root.add_child(stub)
	comp.initialize(null, 1.0, 0.0)
	comp.generate(layer, _structure(5, 5), 0, {"tick_seconds": 0.2})
	var invalid: int = int(comp.get_stats().get("invalid", 0))
	_check("grammar", invalid == 0, "0 invalid expected, got %d" % invalid)

	print("CASE A — typed catalyst trigger + wrong-mode negative:")
	var applied: Array = comp.react(1, 1, "catalyst.fractal")
	var gen: int = int(comp.get_runtime(1, 1).get("generation", -1))
	_check("catalyst.fractal steps the CA", applied == ["step"] and gen == 1,
		"applied=%s generation=%d" % [str(applied), gen])
	var wrong: Array = comp.react(1, 1, "catalyst.swarm")
	_check("catalyst.swarm is a no-op here", wrong.is_empty() and
		int(comp.get_runtime(1, 1).get("generation", -1)) == 1,
		"applied=%s generation stays 1" % str(wrong))

	print("CASE B — react_at_world maps position -> cell:")
	var applied_w: Array = comp.react_at_world(Vector3(1.0, 1.2, 1.0), "catalyst.fractal")
	_check("world hit lands on (1,1)", applied_w == ["step"] and
		int(comp.get_runtime(1, 1).get("generation", -1)) == 2,
		"generation now %d" % int(comp.get_runtime(1, 1).get("generation", -1)))

	print("CASE C — claim expands into the adjacent field:")
	var before: int = comp.get_child_count()
	comp.react(2, 2, "catalyst.chromatic")
	var nstate: Dictionary = comp.get_runtime(3, 2)
	_check("field claimed", String(nstate.get("claimed_by", "")) == "2,2" and bool(nstate.get("active", false)),
		"claimed_by=%s" % str(nstate.get("claimed_by")))
	_check("claimed cell staged", comp.get_child_count() > before,
		"children %d -> %d" % [before, comp.get_child_count()])

	print("CASE D — the vacuum opens (unmute/seed renders):")
	var before_d: int = comp.get_child_count()
	comp.react(0, 0, "catalyst.fractal")
	var vstate: Dictionary = comp.get_runtime(0, 0)
	_check("unmuted + active", not bool(vstate.get("muted", true)) and bool(vstate.get("active", false)),
		"muted=%s active=%s" % [str(vstate.get("muted")), str(vstate.get("active"))])
	_check("opened vacuum staged", comp.get_child_count() > before_d,
		"children %d -> %d" % [before_d, comp.get_child_count()])

	print("CASE E — tick through the clock (and the clock is declared-only):")
	_check("clock ON when declared", comp.is_processing(), "is_processing")
	comp._process(0.3)
	var tgen: int = int(comp.get_runtime(1, 3).get("generation", -1))
	_check("tick stepped the mineral", tgen >= 1, "generation=%d" % tgen)
	var quiet: Node3D = ComponentScript.new()
	root.add_child(quiet)
	quiet.initialize(null, 1.0, 0.0)
	quiet.generate([["flora:scatter:seed"]], _structure(1, 1), 0, {})
	_check("clock OFF when nothing asks", not quiet.is_processing(), "no touch/dwell/tick declared")
	quiet.queue_free()

	print("CASE F — mutate routing (real + unrouted negative):")
	comp.react(2, 4, "touch")
	_check("mutate.color advanced the stub", stub.advances == 1, "advances=%d" % stub.advances)
	var st: Dictionary = comp.get_stats()
	_check("nonesuch counted unrouted", int(st.get("mutations_unrouted", 0)) == 1,
		"unrouted=%d routed=%d" % [int(st.get("mutations_unrouted", 0)), int(st.get("mutations_routed", 0))])
	comp.queue_free()
	stub.queue_free()
