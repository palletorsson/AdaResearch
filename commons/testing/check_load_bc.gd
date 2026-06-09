extends SceneTree
func _initialize() -> void:
	var s = load("res://commons/hazards/becoming_catalyst/becoming_catalyst.gd")
	print("[load] becoming_catalyst.gd: ", ("OK can_instantiate=%s" % (s.can_instantiate() if s is GDScript else "?")) if s else "FAILED")
	for path in [
		"res://commons/hazards/becoming_catalyst/tabbed_editor_panel.gd",
		"res://commons/hazards/becoming_catalyst/BiomeBrushController.gd",
		"res://commons/grid/GridSystem.gd",
		"res://commons/managers/BiomeAccrualManager.gd",
		"res://commons/biome_layers/ground_substrate.gd",
		"res://commons/artifacts/pattern_loom/pattern_loom.gd",
	]:
		var r = load(path)
		print("[load] %s: %s" % [path.get_file(), "OK" if r else "FAILED"])
	quit()
