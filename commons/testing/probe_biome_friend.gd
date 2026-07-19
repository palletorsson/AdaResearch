# probe_biome_friend.gd — friend powers as grid reactions (biome-7 landing).
#
# Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_biome_friend.gd
#
# END-TO-END with a REAL CatalystFoe: four chromatic hits walk the personality
# arc to FRIEND (lineage chromatic → power "neutralizer"), then the friend's
# per-cell biome tick fires "friend.neutralizer" into a declared layer.
#
# A: grammar accepts friend | friend.<power>; rejects a malformed trigger.
# B: the real friend mutes the declared neutralizer cell it walks onto.
# C: once-per-cell — standing still does not re-fire (wildcard cell steps once).
# D: friend.bridger claim = the tendril's grid-native row (fired direct).
# E: mismatched power is a no-op (negative).
extends SceneTree

const ComponentScript = preload("res://commons/grid/GridBiomeComponent.gd")
const TokensScript = preload("res://commons/grid/BiomeGridTokens.gd")
const FoeScene = preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")

var _failures: int = 0


func _init() -> void:
	# Nodes parented during _init are NOT inside the tree yet (get_tree() is
	# null on them — the recorded probe gotcha), so the friend's group lookup
	# would silently skip. Await one frame: everything enters the tree, and
	# the probe exercises the REAL in-tree path.
	_amain()


func _amain() -> void:
	await process_frame
	_run()
	if _failures == 0:
		print("PROBE PASS: friend powers as grid reactions (all cases)")
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
	print("CASE A — grammar:")
	var t1: Dictionary = TokensScript.parse("fungus:ca:field:on=friend.neutralizer:mute")
	_check("friend.<power> parses", t1["valid"] and not t1["reactions"].is_empty(),
		"trigger=%s" % str(t1["reactions"]))
	var t2: Dictionary = TokensScript.parse("mineral:tint:seed:on=friend:step")
	_check("bare friend parses", t2["valid"], "wildcard trigger")
	var t3: Dictionary = TokensScript.parse("mineral:tint:seed:on=friendly:step")
	_check("malformed trigger rejected", not t3["valid"], "friendly is not a trigger")

	var layer: Array = [
		["mineral:tint:seed:on=friend:step", "", "", "", ""],
		["", "fungus:ca:field:on=friend.neutralizer:mute", "flora:scatter:seed:on=friend.bridger:claim", "flora:scatter:field", "meta:glow:seed:on=friend.shield:step"],
	]
	var comp: Node3D = ComponentScript.new()
	root.add_child(comp)
	comp.initialize(null, 1.0, 0.0)
	comp.generate(layer, _structure(5, 2), 0, {})
	_check("layer grammar clean", int(comp.get_stats().get("invalid", 0)) == 0, "0 invalid")

	print("CASE B — a real CatalystFoe walks the arc and mutes the cell:")
	var foe: Node3D = FoeScene.instantiate()
	root.add_child(foe)
	for _i in range(4):
		foe.hit_by_catalyst_mode(Color(0.93, 0.28, 0.60), "chromatic")
	var lineage: String = String(foe._locked_mode_id)
	_check("arc reached friend (chromatic lineage)", lineage == "chromatic",
		"locked_mode=%s personality=%s" % [lineage, str(foe._personality)])
	foe.global_position = Vector3(1.0, 1.2, 1.0)  # over the neutralizer cell (1,1)
	foe._process_friend_power(0.016)
	var muted: bool = bool(comp.get_runtime(1, 1).get("muted", false))
	_check("friend.neutralizer muted the cell", muted, "runtime muted=%s" % str(muted))

	print("CASE C — once per cell (wildcard cell steps exactly once):")
	foe.global_position = Vector3(0.0, 1.2, 0.0)  # the on=friend:step cell (0,0)
	foe._process_friend_power(0.016)
	foe._process_friend_power(0.016)  # same cell — must not re-fire
	var gen: int = int(comp.get_runtime(0, 0).get("generation", -1))
	_check("stepped once while standing", gen == 1, "generation=%d" % gen)

	print("CASE D — friend.bridger claim = the tendril's row:")
	comp.react(2, 1, "friend.bridger")
	var nstate: Dictionary = comp.get_runtime(3, 1)
	_check("field claimed by the bridger", String(nstate.get("claimed_by", "")) == "2,1",
		"claimed_by=%s" % str(nstate.get("claimed_by")))

	print("CASE E — mismatched power is a no-op:")
	foe.global_position = Vector3(4.0, 1.2, 1.0)  # cell (4,1) wants friend.shield
	foe._process_friend_power(0.016)              # chromatic fires neutralizer
	var gen_e: int = int(comp.get_runtime(4, 1).get("generation", -1))
	_check("shield cell ignored the neutralizer", gen_e == 0, "generation=%d" % gen_e)

	foe.queue_free()
	comp.queue_free()
