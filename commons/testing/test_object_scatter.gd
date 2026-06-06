extends SceneTree
## ArtifactPalette + object_scatter: the biome can seed any registered artifact,
## palette widening with the spine, curriculum-gated per artifact.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_object_scatter.gd

const Palette = preload("res://commons/biome_layers/artifact_palette.gd")
const Scatter = preload("res://commons/biome_layers/object_scatter.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _scatter(stage: int) -> int:
	var node := Node3D.new()
	node.set_script(Scatter)
	get_root().add_child(node)
	node.call("apply", {
		"grid_dims": Vector3i(12, 1, 12), "cube_size": 1.0, "rng_seed": 7, "budget_scale": 1.0,
		"stage_order": stage,
		"paint_layers": [{"element": "object", "mode": "random", "density": 0.25,
			"params": {"artifact": "prefab_sculpture"}}],
	})
	var n := node.get_child_count()
	node.queue_free()
	return n

func _initialize() -> void:
	print("=== palette ===")
	print("registry artifacts = %d" % Palette.count())
	_ok(Palette.count() > 100, "registry scanned (many artifacts)")
	_ok(Palette.scene_for("prefab_sculpture") != null, "prefab_sculpture scene resolves")
	var early := Palette.available(1).size()
	var late := Palette.available(19).size()
	print("available @stage1=%d  @stage19=%d" % [early, late])
	_ok(late > early, "palette WIDENS as the spine progresses")

	print("=== scatter ===")
	await process_frame
	var placed := _scatter(19)
	print("scattered @stage19 = %d" % placed)
	_ok(placed > 0, "object_scatter placed prefab_sculpture artifacts")

	var gated := _scatter(0)   # prefab_sculpture unlock_order is 1 > 0 → gated out
	print("scattered @stage0 = %d" % gated)
	_ok(gated == 0, "curriculum gate: nothing scatters below the artifact's unlock stage")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
