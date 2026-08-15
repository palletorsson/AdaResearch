extends SceneTree
## Spike 09 rung 1, the assembler half, proven both ways in one boot.
##
## GATE:  a plan with no `bay` on any row leaves the tile untouched —
##        _open_bays returns the SAME array it was given (identity, not a
##        copy), so nothing downstream can differ by a byte.
## BITE:  a plan row carrying `bay` opens exactly the named interior wall
##        cells and no others; a cell on the tile's skin is refused with a
##        voice; a cell that is already floor is left alone.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_bays.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "")          # no plan at all: pure v1 dealing
	get_root().add_child(inst)
	await create_timer(0.4).timeout

	# a small tile: skin of 4s, an interior wall column at x=3, floor elsewhere
	var tile: Array = []
	for y in range(7):
		var row: Array = []
		for x in range(7):
			var edge: bool = x == 0 or x == 6 or y == 0 or y == 6
			row.append("4" if (edge or (x == 3 and y >= 1 and y <= 5)) else "1")
		tile.append(row)

	# ── GATE: no plan, no bays → identity ────────────────────────────────────
	var out0: Variant = inst.call("_open_bays", tile, "no-such-museum", "no-such-chapter")
	if not (out0 == tile):
		fails.append("no-plan case did not pass the tile through untouched")
	if not is_same(out0, tile):
		fails.append("no-plan case COPIED the tile — should be the identical array")

	# ── BITE: inject a plan row with a bay ───────────────────────────────────
	var pdb: Dictionary = inst.get("_plan_db")
	pdb["bay-test"] = {"artifacts": [
		{"token": "probe", "bay": [[3, 2], [3, 3], [3, 4], [0, 3], [1, 1]]},
	]}
	# [3,2],[3,3],[3,4] are interior wall -> open; [0,3] is skin -> refused;
	# [1,1] is already floor -> untouched
	var out1: Array = inst.call("_open_bays", tile, "bay-test", "")
	if is_same(out1, tile):
		fails.append("bay case returned the input array — the tile was mutated in place, not copied")
	for c in [[3, 2], [3, 3], [3, 4]]:
		if String((out1[c[1]] as Array)[c[0]]) != "1":
			fails.append("bay cell %s did not open" % str(c))
	if String((out1[3] as Array)[0]) != "4":
		fails.append("skin cell [0,3] was opened — the skin must never open")
	if String((out1[1] as Array)[3]) != "4" or String((out1[5] as Array)[3]) != "4":
		fails.append("cells outside the bay ([3,1] / [3,5]) were opened")
	# nothing else changed
	var diff: int = 0
	for y in range(7):
		for x in range(7):
			if String((out1[y] as Array)[x]) != String((tile[y] as Array)[x]):
				diff += 1
	if diff != 3:
		fails.append("%d cells differ from the input, expected exactly 3" % diff)
	# and the input tile itself is untouched
	if String((tile[3] as Array)[3]) != "4":
		fails.append("the INPUT tile was mutated")

	get_root().remove_child(inst)
	inst.queue_free()
	if fails.is_empty():
		print("EM BAYS: PASS — no bay = identity; a bay opens exactly its interior cells, skin refused")
	else:
		print("EM BAYS: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)
