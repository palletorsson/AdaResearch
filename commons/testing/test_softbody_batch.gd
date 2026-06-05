extends SceneTree
## Proves softbody_flora batches into 2 MultiMeshInstance3D (not 2 nodes per plant)
## and the caps use the GPU wobble shader + custom data.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_softbody_batch.gd

const Flora = preload("res://commons/biome_layers/softbody_flora.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _initialize() -> void:
	var node := Node3D.new()
	node.set_script(Flora)
	get_root().add_child(node)
	node.call("apply", {
		"params": {}, "grid_dims": Vector3i(12, 1, 12), "cube_size": 1.0,
		"grid_center": Vector3(6, 0, 6), "rng_seed": 7, "budget_scale": 1.0,
		"paint_layers": [
			{"element": "flower", "mode": "plane", "density": 1.0},
			{"element": "mushroom", "mode": "plane", "density": 0.5},
		],
	})
	await process_frame

	var kids: Array = node.get_children()
	print("flora layer children = %d" % kids.size())
	_ok(kids.size() == 2, "exactly 2 nodes (stems + caps), not 2 per plant")

	var stems = node.get_node_or_null("FloraStems")
	var caps = node.get_node_or_null("FloraCaps")
	_ok(stems is MultiMeshInstance3D, "stems are a MultiMeshInstance3D")
	_ok(caps is MultiMeshInstance3D, "caps are a MultiMeshInstance3D")
	if stems and caps:
		var sc: int = stems.multimesh.instance_count
		var cc: int = caps.multimesh.instance_count
		print("stem instances = %d, cap instances = %d" % [sc, cc])
		_ok(sc > 0 and sc == cc, "instance counts match and are nonzero")
		_ok(caps.material_override is ShaderMaterial, "caps use the wobble ShaderMaterial")
		_ok(caps.multimesh.use_custom_data, "cap MultiMesh carries per-instance custom data")
		_ok(stems.multimesh.use_colors and caps.multimesh.use_colors, "per-instance colours enabled")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
