extends SceneTree
## softbody_flora now spawns REAL DNA morphology: flower (Flower kingdom) +
## mushroom (Fungus kingdom) via CritterSpawner, not placeholder cylinders/spheres.
## Proves the layer spawns CritterEntity organisms of the right kingdoms.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_softbody_real.gd

const Flora = preload("res://commons/biome_layers/softbody_flora.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _initialize() -> void:
	var node := Node3D.new()
	node.set_script(Flora)
	get_root().add_child(node)
	await process_frame

	node.call("apply", {
		"grid_dims": Vector3i(12, 1, 12), "cube_size": 1.0, "grid_center": Vector3(6, 0, 6),
		"rng_seed": 7, "budget_scale": 1.0,
		"paint_layers": [
			{"element": "flower", "mode": "plane", "density": 0.4},
			{"element": "mushroom", "mode": "random", "density": 0.4},
			{"element": "plant", "mode": "random", "density": 0.4},
		],
	})
	await process_frame
	await process_frame

	var flower := 0; var fungus := 0; var tree := 0; var total := 0
	for c in node.get_children():
		if c.has_method("get_kingdom_name"):
			total += 1
			match c.get_kingdom_name():
				"flower": flower += 1
				"fungus": fungus += 1
				"tree": tree += 1
	print("spawned entities: total=%d flower=%d fungus=%d plant(tree)=%d" % [total, flower, fungus, tree])
	_ok(total > 0, "spawned real DNA CritterEntity organisms (not placeholder meshes)")
	_ok(flower > 0, "flowers are Flower-kingdom DNA")
	_ok(fungus > 0, "mushrooms are Fungus-kingdom DNA")
	_ok(tree > 0, "plants are (small, bushy) Tree-kingdom DNA")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
