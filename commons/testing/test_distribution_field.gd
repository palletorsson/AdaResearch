extends SceneTree
## Headless unit check for DistributionField (the paint-layer engine).
## Run: godot --headless --script res://commons/testing/test_distribution_field.gd
## Verifies each mode produces in-bounds placements, budget scales count, and
## placements_for / has_layer_for route by element. No assertions framework —
## prints a PASS/FAIL line per check.

const DF = preload("res://commons/biome_layers/distribution_field.gd")

func _initialize() -> void:
	var gw := 20
	var gd := 20
	var cube := 1.0
	var fails := 0

	print("=== DistributionField — modes on a %dx%d grid ===" % [gw, gd])
	for mode in ["plane", "random", "curve", "noise", "brush"]:
		var spec := {"mode": mode, "density": 0.5}
		match mode:
			"noise": spec["scale"] = 0.18; spec["threshold"] = 0.4
			"curve": spec["axis"] = "radial"; spec["falloff"] = "ring"
			"brush": spec["brush"] = _patch_brush(gw, gd)
		var pts: Array = DF.placements(spec, gw, gd, cube, 1234, 1.0)
		var in_bounds := true
		for p in pts:
			if p.x < -cube or p.x > (gw + 1) * cube or p.z < -cube or p.z > (gd + 1) * cube:
				in_bounds = false
		var ok: bool = pts.size() > 0 and in_bounds
		if not ok: fails += 1
		print("  %-7s → %3d placements  in_bounds=%s  %s" % [mode, pts.size(), in_bounds, "PASS" if ok else "FAIL"])

	# Budget scaling — half budget should roughly halve a stochastic field.
	var ns := {"mode": "noise", "density": 0.8, "scale": 0.2, "threshold": 0.3}
	var full: int = DF.placements(ns, gw, gd, cube, 7, 1.0).size()
	var half: int = DF.placements(ns, gw, gd, cube, 7, 0.5).size()
	var budget_ok: bool = half < full and half > 0
	if not budget_ok: fails += 1
	print("  budget: full=%d half=%d  %s" % [full, half, "PASS" if budget_ok else "FAIL"])

	# Determinism — same seed, same count.
	var a: int = DF.placements(ns, gw, gd, cube, 55, 1.0).size()
	var b: int = DF.placements(ns, gw, gd, cube, 55, 1.0).size()
	var det_ok: bool = a == b
	if not det_ok: fails += 1
	print("  determinism: %d == %d  %s" % [a, b, "PASS" if det_ok else "FAIL"])

	# placements_for / has_layer_for route by element.
	var ctx := {
		"grid_dims": Vector3i(gw, 1, gd), "cube_size": cube, "rng_seed": 99, "budget_scale": 1.0,
		"paint_layers": [
			{"element": "tree", "mode": "noise", "density": 0.4, "scale": 0.2, "threshold": 0.5},
			{"element": "critter", "mode": "plane", "density": 0.3},
		],
	}
	var t: int = DF.placements_for(ctx, "tree").size()
	var c: int = DF.placements_for(ctx, "critter").size()
	var m: int = DF.placements_for(ctx, "mushroom").size()
	var route_ok: bool = t > 0 and c > 0 and m == 0 \
		and DF.has_layer_for(ctx, "tree") and not DF.has_layer_for(ctx, "mushroom")
	if not route_ok: fails += 1
	print("  route: tree=%d critter=%d mushroom=%d  %s" % [t, c, m, "PASS" if route_ok else "FAIL"])

	print("=== %s (%d failures) ===" % ["ALL PASS" if fails == 0 else "FAILURES", fails])
	quit(fails)


func _patch_brush(gw: int, gd: int) -> Array:
	# Dense 4x4 patch in the middle, 0 elsewhere.
	var brush := []
	for z in gd:
		var row := []
		for x in gw:
			row.append(1.0 if (x >= 8 and x < 12 and z >= 8 and z < 12) else 0.0)
		brush.append(row)
	return brush
