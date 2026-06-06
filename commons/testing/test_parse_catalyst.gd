extends SceneTree
## Compile-check the catalyst script (and its biome-menu deps) headlessly — a
## syntax error makes load() return an un-instantiable script. No GPU needed.
func _initialize() -> void:
	var paths := [
		"res://commons/hazards/becoming_catalyst/becoming_catalyst.gd",
		"res://commons/hazards/becoming_catalyst/biome_brush_menu_ui.gd",
		"res://commons/hazards/becoming_catalyst/BiomeBrushController.gd",
	]
	var fails := 0
	for p in paths:
		var s = load(p)
		var ok: bool = s != null and s is GDScript and (s as GDScript).can_instantiate()
		print(("  PASS  " if ok else "  FAIL  "), p)
		if not ok: fails += 1
	print("RESULT: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(fails)
