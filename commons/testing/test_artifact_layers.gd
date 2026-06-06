extends SceneTree
## Generalized artifact layers: ANY element layer can carry an artifacts list,
## placed by its distribution (incl the new fractal mode); morphology defers.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_artifact_layers.gd

const DF = preload("res://commons/biome_layers/distribution_field.gd")
const Scatter = preload("res://commons/biome_layers/object_scatter.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _initialize() -> void:
	# 1. fractal distribution mode
	var f := DF.build_field({"mode": "fractal", "density": 1.0, "scale": 0.16, "threshold": 0.4, "octaves": 4}, 24, 24, 7)
	var nonzero := 0
	for v in f:
		if v > 0.01: nonzero += 1
	print("fractal field: %d/%d cells populated" % [nonzero, f.size()])
	_ok(nonzero > 0 and nonzero < f.size(), "fractal mode produces a varied (clumped) field")

	# 2. artifact-layer detection
	_ok(DF.is_artifact_layer({"element": "mushroom", "artifacts": ["a", "b"]}), "artifacts list ⇒ artifact layer")
	_ok(DF.is_artifact_layer({"element": "flower", "params": {"artifact": "x"}}), "params.artifact ⇒ artifact layer")
	_ok(not DF.is_artifact_layer({"element": "flower", "mode": "noise"}), "plain layer ⇒ not an artifact layer")

	# 3. morphology defers: placements_for skips an artifacts-layer, has_layer_for still suppresses the ring
	var ctx := {"paint_layers": [{"element": "flower", "mode": "plane", "density": 1.0, "artifacts": ["prefab_sculpture"]}],
		"grid_dims": Vector3i(8, 1, 8), "cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0}
	_ok(DF.placements_for(ctx, "flower").is_empty(), "placements_for skips the artifacts-flower-layer (no double-place)")
	_ok(DF.has_layer_for(ctx, "flower"), "has_layer_for still sees it (suppresses default ring)")

	# 4. object_scatter places a NON-object element's artifact list, by a fractal dist
	var node := Node3D.new()
	node.set_script(Scatter)
	get_root().add_child(node)
	await process_frame
	node.call("apply", {
		"grid_dims": Vector3i(12, 1, 12), "cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0, "stage_order": 19,
		"paint_layers": [{"element": "mushroom", "mode": "fractal", "density": 0.4, "artifacts": ["prefab_sculpture"]}],
	})
	await process_frame
	await process_frame
	print("scattered from a mushroom-element artifact list = %d" % node.get_child_count())
	_ok(node.get_child_count() > 0, "any element's artifact list scatters via object_scatter")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
