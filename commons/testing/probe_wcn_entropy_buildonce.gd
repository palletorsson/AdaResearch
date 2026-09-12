extends SceneTree
## Random_Entropy, R1 follow-up (Astra's review, 2026-09-11, item 3): the shared build-once
## repair in shannon_entropy_meter.gd, exercised on the SHIPPED placement (`stand:none`), alone,
## outside the museum — configuration before _ready (the museum lane's order), after _ready
## (the standalone grid's order), and a disclosure rebuild — with one panel, ten bars at the
## ten-symbol setting, and the seeded sample preserved; and the ledger under the same orders.
## Runs headless or rendered; writes res://ada_run/waves_chance_noise/Random_Entropy/probe_entropy_buildonce.json.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_entropy_buildonce.gd
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const OUT := "res://ada_run/waves_chance_noise/Random_Entropy/"
const SCENE := "res://commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.tscn"

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-entropy-once] ", "PASS " if ok else "FAIL ", message)

## What one build leaves: the counted collections and the direct children.
func _shape(m: Node) -> Dictionary:
	var tags: int = 0
	for c in m.get_children():
		if c.name == "Tag": tags += 1
	return {"bars": (m.get("_freq_bars") as Array).size(), "labels": (m.get("_freq_labels") as Array).size(),
		"ghosts": (m.get("_expected_bars") as Array).size(), "children": m.get_child_count(), "tags": tags,
		"formula": m.get("_formula_label") != null, "origin": m.get("_origin_label") != null, "staging": m.get_node_or_null("Staging") != null,
		"disclosure": str(m.get("disclosure")), "stand": str(m.get("stand")), "symbols": int(m.get("num_symbols"))}

func run() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var ps: PackedScene = load(SCENE)

	# ── a. the shipped default, configured by nobody ──
	var a: Node = ps.instantiate()
	holder.add_child(a)
	await process_frame
	await process_frame
	var sa: Dictionary = _shape(a)
	var seq_a: Array = a.call("get_sequence")
	var h_a: float = float(a.call("get_entropy"))
	measurements["a_default"] = {"shape": sa, "entropy": h_a, "first10": seq_a.slice(0, 10)}
	check(sa["bars"] == 10 and sa["labels"] == 10 and sa["ghosts"] == 0 and sa["formula"] and not sa["origin"] and not sa["staging"], "a. the shipped default builds once: ten bars, ten labels, no ghosts, the formula (works) (%s)" % str(sa))
	check(seq_a.size() == 200 and h_a > 3.0, "a. two hundred seeded draws, H %.3f" % h_a)

	# ── b. configured BEFORE _ready, the museum lane's order: origin ──
	var b: Node = ps.instantiate()
	b.call("apply_grid_config", {"disclosure": "origin"})
	holder.add_child(b)
	await process_frame
	await process_frame
	var sb: Dictionary = _shape(b)
	measurements["b_pre_ready_origin"] = {"shape": sb, "entropy": float(b.call("get_entropy"))}
	check(sb["bars"] == 10 and sb["labels"] == 10 and sb["ghosts"] == 10 and sb["formula"] and sb["origin"], "b. config before _ready (origin): ONE panel — ten bars, ten labels, ten ghosts, the formula, the source strip (%s)" % str(sb))
	check((b.call("get_sequence") as Array) == seq_a and float(b.call("get_entropy")) == h_a, "b. the same seeded draws and H as the default")

	# ── g. the same rung configured AFTER _ready, the standalone grid's order: the shape must match b ──
	var g: Node = ps.instantiate()
	holder.add_child(g)
	await process_frame
	g.call("apply_grid_config", {"disclosure": "origin"})
	await process_frame
	await process_frame
	var sg: Dictionary = _shape(g)
	measurements["g_post_ready_origin"] = {"shape": sg}
	check(sg["bars"] == 10 and sg["ghosts"] == 10 and sg["children"] == sb["children"] and sg["tags"] == sb["tags"], "g. config after _ready (origin) leaves the same shape as before _ready: %d children, %d tags each" % [int(sg["children"]), int(sg["tags"])])
	check((g.call("get_sequence") as Array) == seq_a, "g. the same seeded draws after the rebuild")

	# ── c. configured AFTER _ready down to tally ──
	var c: Node = ps.instantiate()
	holder.add_child(c)
	await process_frame
	c.call("apply_grid_config", {"disclosure": "tally"})
	await process_frame
	var sc: Dictionary = _shape(c)
	measurements["c_post_ready_tally"] = {"shape": sc}
	check(sc["bars"] == 10 and sc["ghosts"] == 0 and not sc["formula"] and not sc["origin"] and sc["disclosure"] == "tally", "c. config after _ready (tally): ten bars, no ghosts, no formula, no strip (%s)" % str(sc))
	check((c.call("get_sequence") as Array) == seq_a, "c. the same seeded draws")

	# ── d. a disclosure rebuild through step_disclosure on b: origin → oracle → tally → ledger → works ──
	var seen: Array = []
	for k in range(4):
		b.call("step_disclosure")
		await process_frame
		seen.append(str(b.get("disclosure")))
	var sd: Dictionary = _shape(b)
	measurements["d_steps"] = {"rungs": seen, "shape": sd}
	check(seen == ["oracle", "tally", "ledger", "works"], "d. four steps walk the ladder (%s)" % str(seen))
	check(sd["bars"] == 10 and sd["ghosts"] == 0 and sd["formula"] and sd["children"] == sa["children"], "d. back at works the shape is the default's (%d children)" % int(sd["children"]))
	check((b.call("get_sequence") as Array) == seq_a and float(b.call("get_entropy")) == h_a, "d. the same seeded draws and H through every rebuild")

	# ── e. a seed configured before and after _ready gives the same draws either way ──
	var e1: Node = ps.instantiate()
	e1.call("apply_grid_config", {"seed": 7})
	holder.add_child(e1)
	await process_frame
	var e2: Node = ps.instantiate()
	holder.add_child(e2)
	await process_frame
	e2.call("apply_grid_config", {"seed": 7})
	await process_frame
	var seq_e1: Array = e1.call("get_sequence")
	var seq_e2: Array = e2.call("get_sequence")
	measurements["e_seed7"] = {"first10": seq_e1.slice(0, 10), "same_as_default": seq_e1 == seq_a, "bars_e1": (e1.get("_freq_bars") as Array).size(), "bars_e2": (e2.get("_freq_bars") as Array).size()}
	check(seq_e1 == seq_e2 and seq_e1 != seq_a and (e1.get("_freq_bars") as Array).size() == 10 and (e2.get("_freq_bars") as Array).size() == 10, "e. seed 7 before or after _ready: the same draws, different from the default's, one panel each")

	# ── f. the ledger configured before _ready (the museum's order for Random_Entropy) ──
	var f: Node = ps.instantiate()
	f.call("apply_grid_config", {"stand": "ledger", "disclosure": "ledger"})
	holder.add_child(f)
	await process_frame
	await process_frame
	var sf: Dictionary = _shape(f)
	var ribbon: MultiMeshInstance3D = f.get_node_or_null("Staging/Ribbon")
	measurements["f_pre_ready_ledger"] = {"shape": sf, "tiles": ribbon.multimesh.instance_count if ribbon != null and ribbon.multimesh != null else -1}
	check(sf["bars"] == 10 and sf["staging"] and sf["stand"] == "ledger" and sf["disclosure"] == "ledger" and not sf["formula"], "f. the ledger before _ready: one panel, ten bars, one staging, no formula at ledger (%s)" % str(sf))
	check(ribbon != null and ribbon.multimesh != null and ribbon.multimesh.instance_count == 200 and (f.call("get_sequence") as Array) == seq_a, "f. two hundred tiles, the same seeded draws")
	# and a rebuild keeps ONE staging
	f.call("step_disclosure")
	await process_frame
	var stagings: int = 0
	for ch in f.get_children():
		if ch.name == "Staging": stagings += 1
	check(stagings == 1 and (f.get("_freq_bars") as Array).size() == 10 and str(f.get("disclosure")) == "works", "f. a disclosure rebuild keeps one staging and ten bars (%d staging, %s)" % [stagings, str(f.get("disclosure"))])
	_finish()

func _finish() -> void:
	var report := {"subject": "shannon_entropy_meter alone (no museum)", "checks": checks, "failures": failures, "measurements": measurements,
		"engine": Engine.get_version_info().string}
	var fh := FileAccess.open(OUT + "probe_entropy_buildonce.json", FileAccess.WRITE)
	fh.store_string(JSON.stringify(report, "  ")); fh.close()
	print("[wcn-entropy-once] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
