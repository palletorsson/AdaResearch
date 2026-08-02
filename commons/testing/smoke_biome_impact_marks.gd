extends SceneTree

## Verifies the catalyst impact stain on the biome grid.
##
## 1. A mark on a floor cell registers and stains the presence field.
## 2. A repeat hit on the SAME cell refreshes instead of stacking.
## 3. A mark on the void (height 0) is refused — no ground, no stain.
## 4. A mark outside the grid is refused.
## 5. Marks expire: aged past IMPACT_FADE_S they drop out of the set.
## 6. NEGATIVE (the additive gate): a projectile firing where no biome
##    layer exists must be a no-op — nothing in the group to find.

const BiomeScript := preload("res://commons/grid/GridBiomeComponent.gd")

var _fails: int = 0

func _check(label: String, ok: bool) -> void:
	print("  %s [%s]" % [label, "PASS" if ok else "FAIL"])
	if not ok:
		_fails += 1

func _initialize() -> void:
	print("=== biome impact marks ===")

	# A 6x6 floor with a void hole at (5,5).
	var structure: Array = []
	for r in 6:
		var row: Array = []
		for c in 6:
			row.append("0" if (c == 5 and r == 5) else "1")
		structure.append(row)
	# One declared seed so the layer is non-empty (the component only wakes
	# for maps that declare cells).
	var biome: Array = []
	for r in 6:
		var row: Array = []
		for c in 6:
			row.append("flora:scatter:seed" if (c == 1 and r == 1) else " ")
		biome.append(row)

	var comp = BiomeScript.new()
	var holder := Node3D.new()
	get_root().add_child(holder)
	holder.add_child(comp)
	comp.initialize(holder, 1.0, 0.0)
	comp.generate(biome, structure, 0, {"presence": true})
	await process_frame

	var step: float = 1.0
	var tint := Color(0.9, 0.3, 0.4)

	comp.mark_impact(Vector3(3 * step, 0.5, 3 * step), tint)
	var marks: Array = comp.get("_impacts")
	_check("floor impact registers a mark", marks.size() == 1)
	_check("mark lands on the hit cell",
		marks.size() == 1 and int(marks[0]["col"]) == 3 and int(marks[0]["row"]) == 3)
	_check("mark carries the mode tint",
		marks.size() == 1 and (marks[0]["color"] as Color).is_equal_approx(tint))
	_check("the stain has an overlay", comp.get("_presence_mmi") != null)

	comp.mark_impact(Vector3(3 * step, 0.5, 3 * step), Color(0.2, 0.8, 0.5))
	marks = comp.get("_impacts")
	_check("repeat hit refreshes, does not stack", marks.size() == 1)
	_check("refresh takes the newest tint",
		marks.size() == 1 and (marks[0]["color"] as Color).g > 0.7)

	comp.mark_impact(Vector3(5 * step, 0.5, 5 * step), tint)
	_check("void cell takes no stain", (comp.get("_impacts") as Array).size() == 1)

	comp.mark_impact(Vector3(99 * step, 0.5, 99 * step), tint)
	_check("off-grid hit refused", (comp.get("_impacts") as Array).size() == 1)

	# Age the surviving mark past its lifetime and let _process reap it.
	var fade: float = float(comp.get("IMPACT_FADE_S")) if "IMPACT_FADE_S" in comp else 8.0
	for m in (comp.get("_impacts") as Array):
		m["born_s"] = float(Time.get_ticks_msec()) * 0.001 - (fade + 1.0)
	comp._process(0.5)
	_check("expired mark is reaped", (comp.get("_impacts") as Array).is_empty())

	# 6 — the additive gate: with no biome component in the tree, a
	# projectile's dispatch must find nothing and do nothing.
	comp.queue_free()
	holder.queue_free()
	await process_frame
	await process_frame
	_check("no biome layer -> nothing in the biome_grid group",
		get_root().get_tree().get_nodes_in_group("biome_grid").is_empty())

	if _fails == 0:
		print("PASS: biome impact marks")
		quit(0)
	else:
		print("FAIL: %d checks failed" % _fails)
		quit(1)
