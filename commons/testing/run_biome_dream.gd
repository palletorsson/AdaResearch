extends SceneTree
## run_biome_dream.gd — build one cage and make N generations pass, headless, now.
##
## The dream runner for tools/dream_biome.py: a cage at a stage, with a seed, optionally
## with words it was never taught (`--allow=branch`), stepped through N generations
## without waiting for the clock. The cage writes the lineage itself
## (ada_run/biome_lineage.jsonl, or user:// when res:// refuses); this script only
## builds, steps and reports. Determinism: the cage seeds the breeder from (seed, stage),
## so the same arguments give the same lineage.
##
##   Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off \
##     --script res://commons/testing/run_biome_dream.gd -- --stage=lsystems --seed=7 \
##     --generations=6 [--allow=select] [--size=8] [--run=baseline]
##
## Prints one JSON line `[dream] {...}` with the run's summary and exits 0.

const VITRINE := preload("res://commons/artifacts/biome_vitrine/biome_vitrine.gd")


func _arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return fallback


func _init() -> void:
	_run()


func _run() -> void:
	var stage: String = _arg("stage", "lsystems")
	var seed_v: int = int(_arg("seed", "7"))
	var gens: int = int(_arg("generations", "5"))
	var size_v: int = int(_arg("size", "8"))
	var allow: String = _arg("allow", "")
	var run_label: String = _arg("run", "dream")
	var root := Node3D.new()
	get_root().add_child(root)
	var v = VITRINE.new()
	v.stage = stage
	v.seed = seed_v
	v.size = size_v
	v.evolve = "off"          # we step by hand
	v.record = "on"
	v.allow = allow
	v.run = run_label
	root.add_child(v)
	await process_frame
	await process_frame
	await process_frame
	var before: Dictionary = v.get_state()
	var stepped := 0
	for i in range(gens):
		if v._evo == null:
			break
		v.step_generation()
		await process_frame
		stepped += 1
	var after: Dictionary = v.get_state()
	var summary := {
		"stage": stage, "seed": seed_v, "size": size_v, "allow": allow, "run": run_label,
		"generations_asked": gens, "generations_stepped": stepped,
		"closure": after.get("closure", {}), "family": after.get("family", ""),
		"kingdoms": after.get("kingdoms", []), "seeds": after.get("seeds", {}),
		"live_before": before.get("live", 0), "live_after": after.get("live", 0),
		"births": after.get("births", 0), "deaths": after.get("deaths", 0),
		"by_kingdom": after.get("by_kingdom", {}), "presence": after.get("presence", {}),
		"lineage": after.get("lineage", {}),
	}
	print("[dream] " + JSON.stringify(summary))
	quit(0)
