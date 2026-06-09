extends SceneTree
func _initialize() -> void:
	var s = load("res://commons/hazards/becoming_catalyst/becoming_catalyst.gd")
	print("[load] becoming_catalyst.gd: ", ("OK can_instantiate=%s" % (s.can_instantiate() if s is GDScript else "?")) if s else "FAILED")
	var p = load("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.gd")
	print("[load] tabbed_editor_panel.gd: ", "OK" if p else "FAILED")
	var t = load("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.tscn")
	print("[load] tabbed_editor_panel.tscn: ", "OK" if t else "FAILED")
	quit()
