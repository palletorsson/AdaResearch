extends SceneTree
## Readback for the WIDTH button on distribution_sampler (2026-09-25) and for the
## Random_Gaussian chapter's "two draws in three within one deviation": the cabinet
## placement is stood, WIDTH is cycled, and at each width 600 GAUSS draws are landed
## by BATCH and counted against the model's own sigma.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_sampler_width.gd

const OUT := "C:/Users/palle/AppData/Local/Temp/claude/C--Users-palle-Documents-GitHub-AdaResearch-46/8987ca3e-a19b-46d1-b00a-85888e1b0458/scratchpad/sampler_width.txt"
var _lines: PackedStringArray = []

func _init() -> void:
	await process_frame
	var packed: PackedScene = load("res://commons/artifacts/distribution_sampler/distribution_sampler.tscn")
	var inst: Node3D = packed.instantiate()
	inst.apply_grid_config({"stand": "cabinet", "seed": 20260925, "law": "gaussian"})
	root.add_child(inst)
	await create_timer(0.5).timeout
	inst.set_running(false)
	var panel: Node = inst.get_node_or_null("StandRoot/StandPanel")
	if panel == null:
		panel = inst.find_child("StandPanel", true, false)
	var btn4: Node = panel.find_child("Btn_4", true, false) if panel != null else null
	_say("[probe] cabinet stood: stand panel %s | Btn_4 (WIDTH) %s | start sigma %.2f | seed %d" % [
		"found" if panel != null else "MISSING", "found" if btn4 != null else "MISSING", inst.gaussian_std, inst.sample_seed])
	var all_ok := true
	for press in range(4):
		if press > 0:
			inst.cycle_width()
		var sd: float = inst.gaussian_std
		var landed_before: int = inst._total_samples
		inst.batch(600)
		var vals: PackedFloat32Array = inst.landed_values()
		var within1 := 0
		var within2 := 0
		for v in vals:
			var d: float = absf(v - inst.gaussian_mean)
			if d <= sd:
				within1 += 1
			if d <= 2.0 * sd:
				within2 += 1
		var f1: float = float(within1) / maxf(vals.size(), 1)
		var f2: float = float(within2) / maxf(vals.size(), 1)
		var law: String = inst.readout_lines()[0]
		var exp: Array = inst.expected_counts()
		var exp_peak: float = 0.0
		for e in exp:
			exp_peak = maxf(exp_peak, float(e))
		# the sentence: two in three within one sigma, nineteen in twenty within two (clipping at 0/1 trims the widest)
		var ok: bool = landed_before == 0 and vals.size() == 600 and f1 > 0.60 and f1 < 0.76 and f2 > 0.90 and law.contains("%.2f" % sd)
		all_ok = all_ok and ok
		_say("[probe] press %d: sigma %.2f | cleared before batch: %s | landed %d | within 1 sigma %.3f | within 2 sigma %.3f | law line '%s' | tallest expected bar %.1f | clipped %d | %s" % [
			press, sd, landed_before == 0, vals.size(), f1, f2, law, exp_peak, inst._clipped, "PASS" if ok else "FAIL"])
	_say("[probe] widths cycled back to %.2f (expect 0.15 after 3 presses from 0.15: 0.25, 0.08, 0.15) | %s" % [inst.gaussian_std, "PASS" if is_equal_approx(inst.gaussian_std, 0.15) else "FAIL"])
	_say("[probe] %s" % ("ALL PASS" if all_ok and is_equal_approx(inst.gaussian_std, 0.15) else "SOMETHING FAILED"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines))
		f.close()
	quit()

func _say(msg: String) -> void:
	print(msg)
	_lines.append(msg)
