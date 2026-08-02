extends SceneTree

## Verifies that a catalyst hit advances its mode's SUBSTRATE CHANNEL —
## the colour gun writes colour, transformation writes transform, cellular
## writes visibility — through the existing mutator family, not a second
## mechanism.
##
## 1. The canonical table covers every real mode and only names channels
##    that exist as mutators on disk.
## 2. NEGATIVE (the gate): a map that has NOT opted in routes nothing, no
##    matter how many catalyst hits land. Every existing map is untouched.
## 3. Opted in: a catalyst hit advances the matching mutator.
## 4. The mode decides the channel — chromatic moves the colour mutator and
##    leaves the transform mutator alone, and vice versa.
## 5. A non-catalyst trigger never routes; an unknown mode never routes.

const BiomeScript := preload("res://commons/grid/GridBiomeComponent.gd")
const Binding := preload("res://commons/hazards/catalyst_sequence_binding.gd")
# Stubs, not the real mutators: the real ones await a 1 s timer and start
# cycling timers in _ready, which a unit test should not depend on. These
# satisfy exactly what _route_mutate needs — a name carrying the channel and
# an advance_to_next_pattern() — so the ROUTING contract is what gets tested.
# Real mutators responding is proven by the live map-load test instead.
const ColorMutator := preload("res://commons/testing/stub_color_mutator.gd")
const TransformMutator := preload("res://commons/testing/stub_transform_mutator.gd")

var _fails: int = 0

func _check(label: String, ok: bool) -> void:
	print("  %s [%s]" % [label, "PASS" if ok else "FAIL"])
	if not ok:
		_fails += 1

func _build(opt_in: bool) -> Array:
	# holder carries the mutators; the component is a child, so the
	# component's ancestor-walk finds them exactly as it does in a real map
	var holder := Node3D.new()
	get_root().add_child(holder)
	var cm = ColorMutator.new()
	cm.name = "ColorMutator"
	holder.add_child(cm)
	var tm = TransformMutator.new()
	tm.name = "TransformMutator"
	holder.add_child(tm)
	var comp = BiomeScript.new()
	holder.add_child(comp)
	comp.initialize(holder, 1.0, 0.0)
	var structure: Array = []
	var biome: Array = []
	for r in 4:
		var srow: Array = []
		var brow: Array = []
		for c in 4:
			srow.append("1")
			brow.append("flora:scatter:seed" if (c == 1 and r == 1) else " ")
		structure.append(srow)
		biome.append(brow)
	var meta: Dictionary = {"presence": false}
	if opt_in:
		meta["catalyst_mutates"] = true
	comp.generate(biome, structure, 0, meta)
	return [holder, comp, cm, tm]

func _initialize() -> void:
	print("=== catalyst substrate mutation ===")

	# 1 — the table is honest
	var modes := ["primitives", "transformation", "chromatic", "forces", "waveform",
		"chaos", "cellular", "fractal", "branching", "swarm"]
	var covered: bool = true
	for m in modes:
		if Binding.mutate_channel_for_mode(m).is_empty():
			covered = false
			print("    uncovered mode: %s" % m)
	_check("every mode names a channel", covered)
	var real_channels := ["color", "transform", "visibility", "glyph", "part"]
	var all_real: bool = true
	for m in modes:
		var ch: String = Binding.mutate_channel_for_mode(m)
		if not (ch in real_channels):
			all_real = false
			print("    mode %s names non-existent channel '%s'" % [m, ch])
	_check("channels all exist as mutators", all_real)
	_check("editor tools route nothing", Binding.mutate_channel_for_mode("voxel_editor").is_empty())

	# 2 — NEGATIVE: no opt-in, no routing
	var off: Array = _build(false)
	var comp_off = off[1]
	for i in 5:
		comp_off.react_at_world(Vector3(2, 0, 2), "catalyst.chromatic")
	var stats_off: Dictionary = comp_off.get("_stats")
	_check("NEGATIVE: map without catalyst_mutates routes nothing",
		int(stats_off.get("catalyst_mutations", 0)) == 0)
	(off[0] as Node).queue_free()
	await process_frame

	# 3/4 — opted in, and the MODE picks the channel
	var on: Array = _build(true)
	var comp = on[1]
	var cm = on[2]
	var tm = on[3]
	var cm_before: int = int(cm.advances)
	var tm_before: int = int(tm.advances)

	var applied: Array = comp.react_at_world(Vector3(2, 0, 2), "catalyst.chromatic")
	_check("chromatic hit reports its channel", applied.has("mutate.color"))
	_check("chromatic advanced the COLOUR mutator",
		int(cm.advances) != cm_before)
	_check("chromatic left the TRANSFORM mutator alone",
		int(tm.advances) == tm_before)

	var tm_mid: int = int(tm.advances)
	var cm_mid: int = int(cm.advances)
	applied = comp.react_at_world(Vector3(2, 0, 2), "catalyst.transformation")
	_check("transformation hit reports its channel", applied.has("mutate.transform"))
	_check("transformation advanced the TRANSFORM mutator",
		int(tm.advances) != tm_mid)
	_check("transformation left the COLOUR mutator alone",
		int(cm.advances) == cm_mid)

	# 5 — only catalyst triggers, only known modes
	var stats_before: int = int((comp.get("_stats") as Dictionary).get("catalyst_mutations", 0))
	comp.react_at_world(Vector3(2, 0, 2), "dwell")
	comp.react_at_world(Vector3(2, 0, 2), "catalyst.not_a_mode")
	comp.react_at_world(Vector3(2, 0, 2), "catalyst.voxel_editor")
	_check("non-catalyst + unknown modes route nothing",
		int((comp.get("_stats") as Dictionary).get("catalyst_mutations", 0)) == stats_before)

	if _fails == 0:
		print("PASS: catalyst substrate mutation")
		quit(0)
	else:
		print("FAIL: %d checks failed" % _fails)
		quit(1)
