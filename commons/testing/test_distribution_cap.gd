extends SceneTree
## Proves placements_for caps the per-element UNION + dedupes coincident cells, so
## sequence accrual (many same-element layers) can't blow up the organism count.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_distribution_cap.gd

const DF = preload("res://commons/biome_layers/distribution_field.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _initialize() -> void:
	# 12 stacked tree layers (plane @ density 1.0) on 16×16 = up to ~1920 raw.
	var layers: Array = []
	for i in 12:
		layers.append({"element": "tree", "mode": "plane", "density": 1.0})
	var ctx := {"paint_layers": layers, "grid_dims": Vector3i(16, 1, 16),
		"cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0}
	var pts: Array = DF.placements_for(ctx, "tree")
	print("12 plane tree layers on 16×16 → %d placements" % pts.size())
	_ok(pts.size() <= 160, "union capped ≤160 (raw would be ~1920)")
	_ok(pts.size() >= 120, "still a full field, not over-pruned")

	# 5 stacked flower layers on 10×10 (100 cells) → dedupe to one per cell.
	var l2: Array = []
	for i in 5:
		l2.append({"element": "flower", "mode": "plane", "density": 1.0})
	var ctx2 := {"paint_layers": l2, "grid_dims": Vector3i(10, 1, 10),
		"cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0}
	var p2: Array = DF.placements_for(ctx2, "flower")
	print("5 plane flower layers on 10×10 → %d (expect ≈100 deduped, not 500)" % p2.size())
	_ok(p2.size() <= 100, "deduped to ≤ one per cell")
	_ok(p2.size() >= 80, "kept ~all cells")

	# Budget scales the cap.
	var ctx3 := ctx.duplicate(); ctx3["budget_scale"] = 0.5
	var p3: Array = DF.placements_for(ctx3, "tree")
	print("budget 0.5 → %d" % p3.size())
	_ok(p3.size() <= 81, "budget halves the union cap (≤80)")

	# Single layer unchanged (no cap kick-in below ceiling).
	var ctx4 := {"paint_layers": [{"element": "tree", "mode": "plane", "density": 1.0}],
		"grid_dims": Vector3i(10, 1, 10), "cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0}
	var p4: Array = DF.placements_for(ctx4, "tree")
	print("single plane layer on 10×10 → %d" % p4.size())
	_ok(p4.size() == 100, "single layer fills the grid normally")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
