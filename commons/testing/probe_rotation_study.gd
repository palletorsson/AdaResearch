extends SceneTree

## GATE — random_decay_multimesh #study:rotation (Random_Rotate_Random_XYZ).
##
## The hall's two stacks shipped at unequal rates (cubes 0.3, prisms 0.1), with
## drift, sinking and darkening on, so the chapter could only propose a matched,
## rotation-only comparison. The key makes it. Checked against the simulation state
## in _layers (a headless MultiMesh reads back identity), stepping _process by hand:
##
##   A  default           -> unchanged: rates 0.3 / 0.1, colour 0.35 / 0.16, pieces drift
##   B  study, museum     -> configured BEFORE _ready: rates matched, colour 0, no drift,
##                           no sinking, and both stacks turn
##   C  study, grid       -> configured AFTER _ready: the same, and exactly two layers
##   D  the prism grid    -> under the study, twelve evenly spaced columns; the shipped
##                           snap is measured too (negative control)
##   E  the stream        -> with one seed, the study turns every cube exactly as a matched
##                           run with all channels on: channels were removed, draws were not
##   F  the comparison    -> mean turn per piece in each stack, study vs shipped

const SCENE := "res://algorithms/randomness/randomdecay/scenes/random_decay_multimesh.tscn"
const DT := 1.0 / 60.0
const STEPS := 1800   # 30 s: past the 4 s delay and the 10 s ramp

var _fails: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, ok: bool, detail: String = "") -> void:
	var line := "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	print(("  ok    " if ok else "  FAIL  ") + line)
	if not ok:
		_fails.append(line)


func _make(config: Dictionary, before_ready: bool, seed_v: int, extra: Dictionary = {}) -> Node3D:
	var n: Node3D = load(SCENE).instantiate()
	n.set("random_seed", seed_v)
	for k in extra.keys():
		n.set(k, extra[k])
	if before_ready and not config.is_empty():
		n.apply_grid_config(config)
	root.add_child(n)
	n.set_process(false)
	n.set_process_input(false)
	if not before_ready and not config.is_empty():
		n.apply_grid_config(config)
	return n


func _step(n: Node3D) -> void:
	for i in STEPS:
		n.call("_process", DT)


func _layer_stats(layer: Dictionary) -> Dictionary:
	var offs: Array = layer.get("offsets", [])
	var angs: Array = layer.get("angles", [])
	var dec: Array = layer.get("decay_values", [])
	var max_off := 0.0
	var mean_turn := 0.0
	var mean_decay := 0.0
	for i in offs.size():
		max_off = maxf(max_off, (offs[i] as Vector3).length())
		mean_turn += absf((angs[i] as Vector3).z)
		mean_decay += float(dec[i])
	var n := maxf(1.0, float(offs.size()))
	return {"max_off": max_off, "mean_turn_deg": rad_to_deg(mean_turn / n), "mean_decay": mean_decay / n,
		"speed": float(layer.get("speed_scale", -1.0)), "mix": float(layer.get("color_decay_mix", -1.0)),
		"count": offs.size()}


func _columns(layer: Dictionary) -> Array:
	var xs: Dictionary = {}
	for p in layer.get("base_positions", []):
		xs[snappedf((p as Vector3).x, 0.001)] = true
	var out := xs.keys()
	out.sort()
	return out


func _run() -> void:
	print("probe_rotation_study")

	# --- A: default ---
	var a: Node3D = _make({"stack_fit": 10}, true, 7)
	_step(a)
	var a0: Dictionary = _layer_stats(a.get("_layers")[0])
	var a1: Dictionary = _layer_stats(a.get("_layers")[1])
	_check("A the default placement is unchanged",
		is_equal_approx(a0.speed, 0.3) and is_equal_approx(a1.speed, 0.1) and is_equal_approx(a0.mix, 0.35)
			and is_equal_approx(a1.mix, 0.16) and a0.max_off > 0.0,
		"rates %.2f / %.2f, colour %.2f / %.2f, cube drift up to %.3f" % [a0.speed, a1.speed, a0.mix, a1.mix, a0.max_off])

	# --- B: study, configured before _ready (museum) ---
	var b: Node3D = _make({"stack_fit": 10, "study": "rotation"}, true, 7)
	_step(b)
	var b0: Dictionary = _layer_stats(b.get("_layers")[0])
	var b1: Dictionary = _layer_stats(b.get("_layers")[1])
	var b_sink: float = float(b.get("sink_distance"))
	_check("B study before _ready: rates matched, colour off, no drift, no sinking",
		is_equal_approx(b0.speed, b1.speed) and is_equal_approx(b0.speed, 0.3) and b0.mix == 0.0 and b1.mix == 0.0
			and b0.max_off == 0.0 and b1.max_off == 0.0 and b_sink == 0.0,
		"rates %.2f / %.2f, colour %.2f / %.2f, drift %.4f / %.4f, sink %.2f" % [b0.speed, b1.speed, b0.mix, b1.mix, b0.max_off, b1.max_off, b_sink])
	_check("B and both stacks turn", b0.mean_turn_deg > 0.5 and b1.mean_turn_deg > 0.5,
		"mean turn %.2f deg cubes, %.2f deg prisms" % [b0.mean_turn_deg, b1.mean_turn_deg])

	# --- B2: the museum bench stamp passes only the token's first key, with the rest of
	#         the string attached. The hall's token is #study:rotation alone; the study
	#         must fit the display to 10 m by itself and survive a trailing tail.
	var b2: Node3D = _make({"study": "rotation#stack_fit:10"}, true, 7)
	var fit_b2: float = float(b2.get("_stack_fit"))
	_step(b2)
	var b20: Dictionary = _layer_stats(b2.get("_layers")[0])
	_check("B2 the study alone fits the display and survives a trailing tail",
		is_equal_approx(fit_b2, 10.0) and b20.max_off == 0.0 and is_equal_approx(b20.speed, 0.3),
		"stack_fit %.1f, drift %.4f, rate %.2f" % [fit_b2, b20.max_off, b20.speed])
	b2.queue_free()

	# --- C: study, configured after _ready (grid lane) ---
	var c: Node3D = _make({"stack_fit": 10, "study": "rotation"}, false, 7)
	var layer_nodes := 0
	for ch in c.get_children():
		if ch is MultiMeshInstance3D and String(ch.name).begins_with("DecayLayer_"):
			layer_nodes += 1
	_step(c)
	var c0: Dictionary = _layer_stats(c.get("_layers")[0])
	var c1: Dictionary = _layer_stats(c.get("_layers")[1])
	_check("C study after _ready: the same settings, two layers, both turn",
		layer_nodes == 2 and is_equal_approx(c0.speed, c1.speed) and c0.max_off == 0.0 and c1.max_off == 0.0
			and c0.mix == 0.0 and c1.mean_turn_deg > 0.5,
		"%d layer nodes; rates %.2f / %.2f; drift %.4f / %.4f; turn %.2f / %.2f deg" % [layer_nodes, c0.speed, c1.speed, c0.max_off, c1.max_off, c0.mean_turn_deg, c1.mean_turn_deg])

	# --- D: the prism grid ---
	var cols_study: Array = _columns(b.get("_layers")[1])
	var cols_ship: Array = _columns(a.get("_layers")[1])
	var even := true
	for i in range(1, cols_study.size() - 1):
		if absf((float(cols_study[i + 1]) - float(cols_study[i])) - (float(cols_study[1]) - float(cols_study[0]))) > 0.002:
			even = false
	_check("D under the study the prisms stand in twelve evenly spaced columns",
		cols_study.size() == 12 and even, "%d distinct columns, even %s" % [cols_study.size(), str(even)])
	_check("D negative control: the shipped snap does not give twelve", cols_ship.size() != 12,
		"%d distinct columns as shipped" % cols_ship.size())

	# --- E: the stream. Matched run with all channels on, same seed, same layout.
	var m: Node3D = _make({"stack_fit": 10}, true, 7, {"prism_decay_speed_scale": 0.3, "snap_to_grid_on_spawn": false})
	_step(m)
	var ang_s: Array = b.get("_layers")[0].get("angles")
	var ang_m: Array = m.get("_layers")[0].get("angles")
	var worst := 0.0
	for i in ang_s.size():
		worst = maxf(worst, absf((ang_s[i] as Vector3).z - (ang_m[i] as Vector3).z))
	_check("E the study turns each cube exactly as the matched run does", worst < 1e-5,
		"largest difference %.9f rad over %d cubes" % [worst, ang_s.size()])

	# --- F: the comparison, reported ---
	print("       shipped: cubes turn %.2f deg on average, prisms %.2f (rates 0.3 / 0.1)" % [a0.mean_turn_deg, a1.mean_turn_deg])
	print("       study:   cubes turn %.2f deg on average, prisms %.2f (rate 0.3 both)" % [b0.mean_turn_deg, b1.mean_turn_deg])
	print("       mean hidden value after 30 s: shipped %.2f / %.2f, study %.2f / %.2f" % [a0.mean_decay, a1.mean_decay, b0.mean_decay, b1.mean_decay])

	for n in [a, b, c, m]:
		n.queue_free()
	await process_frame
	if _fails.is_empty():
		print("\nprobe_rotation_study: ALL CHECKS PASS")
		quit(0)
	else:
		print("\nprobe_rotation_study: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)
