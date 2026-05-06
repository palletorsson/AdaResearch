extends SceneTree

## Verifies catalyst_foe per-mode dispatch.
##
## All 4 cases run synchronously (no awaits) so we exit before any
## autoload-driven polling can keep the SceneTree alive.

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")

func _initialize() -> void:
	var root := Node3D.new()
	root.add_to_group("player")  # foe needs SOMETHING in the player group
	get_root().add_child(root)

	var cases: Array = [
		{"mode": "primitives",     "expected": 0, "label": "GOO"},
		{"mode": "transformation", "expected": 1, "label": "TRANSPORT"},
		{"mode": "swarm",          "expected": 2, "label": "SWARM"},
		{"mode": "cellular",       "expected": 3, "label": "DRAINFRIEND"},
		{"mode": "chromatic",      "expected": 0, "label": "GOO (chromatic falls through)"},
	]
	print("=== catalyst_foe per-mode dispatch ===")
	var fails: int = 0
	for c in cases:
		var f: Node = FOE_SCENE.instantiate()
		root.add_child(f)
		f.call("hit_by_catalyst_mode", Color(0.5, 0.5, 0.5), c["mode"])
		var got: int = int(f.get("foe_mode"))
		var ok: bool = got == int(c["expected"])
		print("  mode='%s' -> foe_mode=%d (expected %d, %s) [%s]"
			% [c["mode"], got, int(c["expected"]),
			   c["label"], "PASS" if ok else "FAIL"])
		if not ok:
			fails += 1
	if fails == 0:
		print("PASS: %d / %d dispatches correct" % [cases.size(), cases.size()])
		quit(0)
	else:
		print("FAIL: %d / %d wrong" % [fails, cases.size()])
		quit(1)
